# lock / release       → called internally from booking operations, no direct policy needed

class ShowSeatStatePolicy < ApplicationPolicy
  # The seat map endpoint is public — users need it before logging in to browse.
  def availability? = true

  # Only admins can manually block/unblock seats.
  def block?   = current_user&.admin?
  def unblock? = current_user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end