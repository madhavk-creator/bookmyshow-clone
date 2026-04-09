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

    def validate_requested_seats(ctx, params:, show:, **)
      seat_ids = Array(params[:seat_ids]).compact

      if seat_ids.empty?
        ctx[:errors] = { seat_ids: [ "must include at least one seat" ] }
        return false
      end

      if seat_ids.uniq.size != seat_ids.size
        ctx[:errors] = { seat_ids: [ "contains duplicate seat IDs" ] }
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

      ctx[:seat_ids] = seat_ids
      ctx[:section_by_seat] = section_by_seat
      ctx[:price_by_section] = price_by_section
      true
    end

    def resolve_coupon(ctx, params:, current_user:, **)
      ctx[:coupon] = nil
      return true if params[:coupon_code].blank?

      coupon = resolve_coupon_by_code(ctx, coupon_code: params[:coupon_code])
      return false if coupon.nil?

      ctx[:coupon] = coupon
      true
    end

    def build_lock_token(ctx, **)
      ctx[:lock_token] = SecureRandom.uuid
    end

    def lock_seats(ctx, current_user:, show:, lock_token:, seat_ids:, **)
      result = ShowSeatStates::Lock.call(
        params: {
          show_id:    show.id,
          seat_ids:,
          user_id:    current_user.id,
          lock_token: lock_token
        }
      )

      unless result.success?
        ctx[:errors] = result[:errors]
        return false
      end

      ctx[:locked_states] = result[:locked_states]
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

    def persist_booking_bundle(ctx, current_user:, show:, coupon:, subtotal:, total_amount:, lock_token:, seat_ids:, section_by_seat:, price_by_section:, **)
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

        booking = ::Booking.create!(
          user:         current_user,
          show:         show,
          coupon:       coupon,
          total_amount: total_amount,
          status:       "pending",
          lock_token:   lock_token
        )

        create_tickets!(
          booking:          booking,
          show:             show,
          seat_ids:         seat_ids,
          section_by_seat:  section_by_seat,
          price_by_section: price_by_section
        )

        payment = ::Payment.create!(
          booking: booking,
          user:    current_user,
          amount:  total_amount,
          status:  "pending"
        )

        rewrite_coupon_usage!(booking:, coupon:, current_user:)

        ctx[:model] = booking
        ctx[:payment] = payment
        booking_persisted = true
      end

      booking_persisted
    rescue ActiveRecord::RecordInvalid => e
      ctx[:errors] = { base: [ e.message ] }
      false
    end

    def create_tickets!(booking:, show:, seat_ids:, section_by_seat:, price_by_section:)
      seat_ids.each do |seat_id|
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

    # If any step after lock_seats fails, release the acquired locks
    # so those seats become available again immediately.
    def release_locks_on_failure(ctx, lock_token: nil, **)
      return unless lock_token
      ShowSeatStates::Release.call(params: { lock_token: lock_token })
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Booking could not be created" ] }
    end
  end
end
