# index / shows  → public
# create        → vendors who owns the screens's theatres, or admins
# update        → same, and only on scheduled shows
# cancel        → same as update

class ShowPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true

  def create?
    admin_or_owns_screen?
  end

  def update?
    admin_or_owns_screen? && record.status_scheduled?
  end

  def cancel?
    admin_or_owns_screen? && record.status_scheduled?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end

  private

  def admin_or_owns_screen?
    return false unless current_user
    return true if current_user.admin?
    return false unless record.respond_to?(:screen) && record.screen

    current_user.vendor? &&
      record.screen.theatre.vendor_id == current_user.id
  end
end
