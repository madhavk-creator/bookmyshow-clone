class TheatrePolicy < ApplicationPolicy
  def index?  = true
  def show?   = true

  def create?
    current_user.present?
  end

  def update?
    own_theatre? || current_user&.admin?
  end

  def destroy?
    own_theatre? || current_user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def own_theatre?
    current_user&.vendor? && record.vendor_id == current_user.id
  end
end