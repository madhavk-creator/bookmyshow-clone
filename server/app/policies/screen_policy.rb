class ScreenPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true

  def create?
    current_user&.admin? || current_user&.vendor?
  end

  def update?
    admin_or_owns_theatre?
  end

  def destroy?
    admin_or_owns_theatre?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end

  private

  def admin_or_owns_theatre?
    return false unless current_user
    current_user.admin? ||
      (current_user.vendor? && record.theatre.vendor_id == current_user.id)
  end
end