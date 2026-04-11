# Full booking creation flow in one atomic step:
#   1. Find and validate the show
#   2. Validate and resolve coupon (optional)
#   3. Lock the requested seats via ShowSeatState::Lock
#   4. Calculate total from section prices + coupon discount
#   5. Create BOOKING (pending)
#   6. Create TICKET rows (one per seat)
#   7. Create PAYMENT record (pending)
#   8. Record coupon usage if applicable
#
# Params:
#   show_id, seat_ids: [uuid], coupon_code: (optional)
#
# The booking expires in 5 minutes if payment is not confirmed.
# ExpireSeatLocksJob handles cleanup.

module Bookings
  class Create < ::Trailblazer::Operation
    include CouponSupport

    step :authorize_create
    step :find_show
    step :find_existing_pending_booking
    step :validate_requested_seats
    step :resolve_coupon
    step :build_lock_token
    step :lock_seats
    step :calculate_total
    step :persist_booking_bundle
    fail :release_locks_on_failure
    fail :collect_errors

    def authorize_create(ctx, current_user:, **)
      return true if Pundit.policy!(current_user, ::Booking).create?

      ctx[:errors] = { base: [ "Not authorized to create booking" ] }
      false
    end

    def find_show(ctx, params:, **)
      ctx[:show] = ::Show.includes(
        seat_layout: { seat_sections: {} },
        show_section_prices: {}
      ).find_by(id: params[:show_id])

      unless ctx[:show]&.status_scheduled?
        ctx[:errors] = { show: [ "Show not found or not available for booking" ] }
        return false
      end

      unless ctx[:show].start_time > Time.current
        ctx[:errors] = { show: [ "This show has already started" ] }
        return false
      end

      true
    end

    def find_existing_pending_booking(ctx, current_user:, show:, **)
      show.release_expired_locks!

      active_locked_states = ::ShowSeatState
        .active_locks
        .where(show_id: show.id, locked_by_user_id: current_user.id)
        .where.not(lock_token: nil)
        .order(:created_at)
        .to_a

      ctx[:existing_booking] = nil
      ctx[:existing_locked_states] = []
      ctx[:existing_locked_seat_ids] = []
      ctx[:lock_expires_at] = nil

      return true if active_locked_states.empty?

      booking = ::Booking
        .includes(:tickets, :payments, :coupon)
        .where(
          user_id: current_user.id,
          show_id: show.id,
          status: "pending",
          lock_token: active_locked_states.map(&:lock_token).uniq
        )
        .order(created_at: :desc)
        .first

      return true unless booking

      booking_states = active_locked_states.select { |state| state.lock_token == booking.lock_token }

      ctx[:existing_booking] = booking
      ctx[:existing_locked_states] = booking_states
      ctx[:existing_locked_seat_ids] = booking_states.map(&:seat_id)
      ctx[:lock_expires_at] = booking_states.map(&:locked_until).compact.min
      true
    end

    def validate_requested_seats(ctx, params:, show:, existing_locked_seat_ids: [], **)
      requested_seat_ids = Array(params[:seat_ids]).compact.map(&:to_s)
      locked_seat_ids = Array(existing_locked_seat_ids).map(&:to_s)
      seat_ids = (locked_seat_ids + requested_seat_ids).uniq

      if requested_seat_ids.uniq.size != requested_seat_ids.size
        ctx[:errors] = { seat_ids: [ "contains duplicate seat IDs" ] }
        return false
      end

      if seat_ids.empty?
        ctx[:errors] = { seat_ids: [ "must include at least one seat" ] }
        return false
      end

      section_by_seat = show.seat_layout.seats
                            .where(id: seat_ids)
                            .includes(:seat_section)
                            .index_by(&:id)

      missing_seat_ids = seat_ids.map(&:to_s) - section_by_seat.keys.map(&:to_s)
      if missing_seat_ids.any?
        ctx[:errors] = { seat_ids: [ "Unknown seat IDs: #{missing_seat_ids.join(', ')}" ] }
        return false
      end

      inactive_seat_ids = section_by_seat.values.reject(&:is_active).map(&:id)
      if inactive_seat_ids.any?
        ctx[:errors] = { seat_ids: [ "Inactive seat IDs: #{inactive_seat_ids.join(', ')}" ] }
        return false
      end

      price_by_section = show.show_section_prices.index_by(&:seat_section_id)
      unpriced_section_ids = section_by_seat.values
                                            .map(&:seat_section_id)
                                            .uniq
                                            .reject { |section_id| price_by_section.key?(section_id) }

      if unpriced_section_ids.any?
        ctx[:errors] = { seat_ids: [ "Missing prices for section IDs: #{unpriced_section_ids.join(', ')}" ] }
        return false
      end

      ctx[:requested_seat_ids] = requested_seat_ids
      ctx[:seat_ids] = seat_ids
      ctx[:seat_ids_to_lock] = seat_ids - locked_seat_ids
      ctx[:section_by_seat] = section_by_seat
      ctx[:price_by_section] = price_by_section
      true
    end

    def resolve_coupon(ctx, params:, current_user:, existing_booking: nil, **)
      if params[:coupon_code].blank?
        ctx[:coupon] = existing_booking&.coupon
        return true
      end

      coupon = resolve_coupon_by_code(ctx, coupon_code: params[:coupon_code])
      return false if coupon.nil?

      ctx[:coupon] = coupon
      true
    end

    def build_lock_token(ctx, existing_booking: nil, **)
      ctx[:lock_token] = existing_booking&.lock_token || SecureRandom.uuid
    end

    def lock_seats(ctx, current_user:, show:, lock_token:, seat_ids_to_lock:, lock_expires_at: nil, existing_locked_states: [], **)
      if seat_ids_to_lock.empty?
        ctx[:locked_states] = existing_locked_states
        ctx[:newly_locked_seat_ids] = []
        return true
      end

      result = ShowSeatStates::Lock.call(
        params: {
          show_id:    show.id,
          seat_ids:   seat_ids_to_lock,
          user_id:    current_user.id,
          lock_token: lock_token,
          locked_until: lock_expires_at
        }
      )

      unless result.success?
        ctx[:errors] = result[:errors]
        return false
      end

      ctx[:locked_states] = existing_locked_states + result[:locked_states]
      ctx[:newly_locked_seat_ids] = seat_ids_to_lock
    end

    def calculate_total(ctx, seat_ids:, section_by_seat:, price_by_section:, coupon:, current_user:, **)
      subtotal = seat_ids.sum(0.0) do |seat_id|
        seat    = section_by_seat[seat_id]
        section = seat&.seat_section
        price   = price_by_section[section&.id]&.base_price || 0
        price.to_f
      end

      if coupon && !validate_coupon_for_user(ctx:, coupon:, current_user:, subtotal:)
        return false
      end

      ctx[:subtotal]     = subtotal
      ctx[:total_amount] = coupon_total(subtotal, coupon)
      true
    end

    def persist_booking_bundle(ctx, current_user:, show:, coupon:, subtotal:, total_amount:, lock_token:, seat_ids:, section_by_seat:, price_by_section:, existing_booking: nil, **)
      booking_persisted = false

      ActiveRecord::Base.transaction do
        coupon = lock_and_validate_coupon!(
          ctx:          ctx,
          coupon:       coupon,
          current_user: current_user,
          subtotal:     subtotal
        )

        raise ActiveRecord::Rollback if ctx[:errors].present?
        raise ActiveRecord::Rollback unless validate_coupon_global_usage!(ctx:, coupon:, exclude_booking_id: nil)

        total_amount = coupon_total(subtotal, coupon)

        booking = existing_booking || ::Booking.create!(
          user:         current_user,
          show:         show,
          coupon:       coupon,
          total_amount: total_amount,
          status:       "pending",
          lock_token:   lock_token
        )

        booking.update!(
          coupon: coupon,
          total_amount: total_amount
        ) if existing_booking

        sync_tickets!(
          booking:          booking,
          show:             show,
          seat_ids:         seat_ids,
          section_by_seat:  section_by_seat,
          price_by_section: price_by_section
        )

        payment = upsert_pending_payment!(
          booking: booking,
          current_user: current_user,
          total_amount: total_amount
        )

        ctx[:model] = booking
        ctx[:payment] = payment
        booking_persisted = true
      end

      booking_persisted
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = { base: [ e.message ] }
      false
    end

    def sync_tickets!(booking:, show:, seat_ids:, section_by_seat:, price_by_section:)
      existing_valid_tickets = booking.tickets.where(status: "valid").index_by(&:seat_id)

      seat_ids.each do |seat_id|
        next if existing_valid_tickets.key?(seat_id)

        seat    = section_by_seat[seat_id]
        section = seat&.seat_section
        price   = price_by_section[section&.id]&.base_price.to_f

        ::Ticket.create!(
          booking:      booking,
          show:         show,
          seat:         seat,
          seat_label:   seat.label,
          section_name: section&.name,
          price:        price,
          status:       "valid"
        )
      end
    end

    def upsert_pending_payment!(booking:, current_user:, total_amount:)
      payment = booking.payments.where(status: "pending").order(created_at: :desc).first

      if payment
        payment.update!(amount: total_amount)
        return payment
      end

      ::Payment.create!(
        booking: booking,
        user: current_user,
        amount: total_amount,
        status: "pending"
      )
    end

    # If any step after lock_seats fails, release the acquired locks
    # so those seats become available again immediately.
    def release_locks_on_failure(ctx, lock_token: nil, newly_locked_seat_ids: [], **)
      return unless lock_token
      return if newly_locked_seat_ids.empty?

      ShowSeatStates::Release.call(
        params: {
          lock_token: lock_token,
          seat_ids: newly_locked_seat_ids
        }
      )
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Booking could not be created" ] }
    end
  end
end
