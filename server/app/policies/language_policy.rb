class LanguagePolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = admin_or_vendor?
  def update?  = admin_or_vendor?
  def destroy? = admin_or_vendor?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end

  private

  def admin_or_vendor?
    current_user&.admin? || current_user&.vendor?
  end
end