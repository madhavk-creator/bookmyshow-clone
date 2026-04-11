module Bookings
  class ApplyCoupon < ::Trailblazer::Operation
    include CouponSupport

    step :find_booking
    step :verify_status
    step :resolve_and_validate_coupon
    step :apply_and_persist
    fail :collect_errors

    def find_booking(ctx, params:, current_user:, **)
      ctx[:booking] = ::Booking.includes(:tickets, :coupon, :payments).find_by(id: params[:id], user_id: current_user.id)
      unless ctx[:booking]
        ctx[:errors] = { booking: [ "Not found" ] }
        return false
      end
      true
    end

    def verify_status(ctx, booking:, **)
      unless booking.status == "pending"
        ctx[:errors] = { booking: [ "Can only apply coupons to pending bookings" ] }
        return false
      end
      true
    end

    def resolve_and_validate_coupon(ctx, params:, current_user:, booking:, **)
      return true if params[:coupon_code].blank?

      coupon = resolve_coupon_by_code(ctx, coupon_code: params[:coupon_code])
      return false if coupon.nil?

      subtotal = booking.valid_tickets_subtotal

      # If the coupon is the exact same, no-op
      if booking.coupon_id == coupon.id
        ctx[:coupon] = coupon
        ctx[:subtotal] = subtotal
        return true
      end

      return false unless validate_coupon_for_user(
        ctx:,
        coupon:,
        current_user:,
        subtotal:,
        exclude_booking_id: booking.id
      )

      ctx[:coupon] = coupon
      ctx[:subtotal] = subtotal
      true
    end

    def apply_and_persist(ctx, booking:, current_user:, params:, **)
      subtotal = booking.valid_tickets_subtotal
      coupon = ctx[:coupon]

      ActiveRecord::Base.transaction do
        # Removing coupon if it's blank
        if params[:coupon_code].blank?
          booking.update!(coupon: nil, total_amount: subtotal)
          booking.payments.where(status: "pending").each { |p| p.update!(amount: subtotal) }
          ctx[:model] = booking
          return true
        end

        coupon = lock_and_validate_coupon!(
          ctx:,
          coupon:,
          current_user:,
          subtotal:,
          exclude_booking_id: booking.id
        )

        raise ActiveRecord::Rollback if ctx[:errors].present?
        raise ActiveRecord::Rollback unless validate_coupon_global_usage!(ctx:, coupon:, exclude_booking_id: booking.id)

        total_amount = coupon_total(subtotal, coupon)

        booking.update!(coupon: coupon, total_amount: total_amount)
        booking.payments.where(status: "pending").each { |p| p.update!(amount: total_amount) }

        ctx[:model] = booking
        true
      end
    rescue ActiveRecord::Rollback
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: [ "Failed to apply coupon" ] }
    end
  end
end
