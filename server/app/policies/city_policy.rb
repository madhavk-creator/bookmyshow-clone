class CityPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true

  def create?
    current_user&.admin? || current_user&.vendor?
  end

  def update?  = current_user&.admin?
  def destroy? = current_user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
