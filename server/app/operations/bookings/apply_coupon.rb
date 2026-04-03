module Bookings
  class ApplyCoupon < Trailblazer::Operation
    step :find_booking
    step :verify_status
    step :resolve_and_validate_coupon
    step :apply_and_persist
    fail :collect_errors

    def find_booking(ctx, params:, current_user:, **)
      ctx[:booking] = ::Booking.includes(:tickets, :coupon, :payments).find_by(id: params[:id], user_id: current_user.id)
      unless ctx[:booking]
        ctx[:errors] = { booking: ['Not found'] }
        return false
      end
      true
    end

    def verify_status(ctx, booking:, **)
      unless booking.status == 'pending'
        ctx[:errors] = { booking: ['Can only apply coupons to pending bookings'] }
        return false
      end
      true
    end

    def resolve_and_validate_coupon(ctx, params:, current_user:, booking:, **)
      return true if params[:coupon_code].blank?

      coupon = ::Coupon.find_by(code: params[:coupon_code].upcase.strip)
      unless coupon
        ctx[:errors] = { coupon_code: ['Coupon not found'] }
        return false
      end

      # Calculate original subtotal excluding the current coupon deduction
      subtotal = booking.tickets.sum(&:price)

      unless coupon.applicable?(subtotal)
        ctx[:errors] = { coupon_code: ['Coupon is not applicable to this booking'] }
        return false
      end

      # If the coupon is the exact same, no-op
      return true if booking.coupon_id == coupon.id

      if coupon.max_uses_per_user.present?
        used_count = ::UserCouponUsage.where(coupon: coupon, user: current_user).where.not(booking_id: booking.id).count
        if used_count >= coupon.max_uses_per_user
          ctx[:errors] = { coupon_code: ["You have already used this coupon the maximum number of times"] }
          return false
        end
      end

      ctx[:coupon] = coupon
      ctx[:subtotal] = subtotal
      true
    end

    def apply_and_persist(ctx, booking:, current_user:, params:, **)
      subtotal = booking.tickets.sum(&:price)
      coupon = ctx[:coupon]

      ActiveRecord::Base.transaction do
        # Removing coupon if it's blank
        if params[:coupon_code].blank?
          booking.update!(coupon: nil, total_amount: subtotal)
          booking.payments.where(status: 'pending').each { |p| p.update!(amount: subtotal) }
          ::UserCouponUsage.where(booking_id: booking.id).destroy_all
          ctx[:model] = booking
          return true
        end

        # Lock the coupon to avoid race conditions on global uses
        coupon.lock!

        # Final check if total uses reached globally
        if coupon.max_total_uses.present?
          global_uses = ::UserCouponUsage.where(coupon_id: coupon.id).where.not(booking_id: booking.id).count
          if global_uses >= coupon.max_total_uses
            ctx[:errors] = { coupon_code: ['This coupon has reached its maximum global redemptions'] }
            raise ActiveRecord::Rollback
          end
        end

        total_amount = coupon.apply(subtotal)
        
        booking.update!(coupon: coupon, total_amount: total_amount)
        booking.payments.where(status: 'pending').each { |p| p.update!(amount: total_amount) }
        
        # Rewrite the usage row
        ::UserCouponUsage.where(booking_id: booking.id).destroy_all
        ::UserCouponUsage.create!(
          coupon: coupon,
          user: current_user,
          booking: booking,
          used_at: Time.current
        )

        ctx[:model] = booking
        true
      end
    rescue ActiveRecord::Rollback
      false
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || { base: ['Failed to apply coupon'] }
    end
  end
end
