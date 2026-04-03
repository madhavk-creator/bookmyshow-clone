# create          → any authenticated user
# show / index    → own bookings only, or admin sees all
# cancel          → booking owner only (before show starts), or admin
# cancel_ticket   → booking owner only (before show starts), or admin
# confirm_payment → booking owner only

class BookingPolicy < ApplicationPolicy
  def index?          = true   # scoped via BookingPolicy::Scope
  def show?           = own_booking? || current_user&.admin?
  def create?         = current_user.present?
  def update?         = own_booking?
  def cancel?         = (own_booking? && before_show_starts?) || current_user&.admin?
  def cancel_ticket?  = (own_booking? && before_show_starts?) || current_user&.admin?
  def confirm_payment? = own_booking?
  def apply_coupon?   = own_booking?

  class Scope < ApplicationPolicy::Scope
    def resolve
      current_user.admin? ? scope.all : scope.where(user_id: current_user.id)
    end
  end

  private

  def own_booking?
    current_user&.id == record.user_id
  end

  def before_show_starts?
    record.show.start_time > Time.current
  end
end