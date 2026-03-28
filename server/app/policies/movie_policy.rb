# Languages and formats are managed through the movie — no separate policies needed.

class MoviePolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = current_user&.admin?
  def update?  = current_user&.admin?
  def destroy? = current_user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end