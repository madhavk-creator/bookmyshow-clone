class UserPolicy < ApplicationPolicy
  # Any authenticated users can view their own profile.
  # Admins can view any profile.
  def show?
    own_record? || current_user.admin?
  end

  # Admins can list all users. Vendors and users cannot.
  def index?
    current_user.admin?
  end

  # Users can update their own profile. Admins can update anyone.
  def update?
    own_record? || current_user.admin?
  end

  # Only admins can deactivate accounts.
  def deactivate?
    current_user.admin?
  end

  # Only admins can promote/change roles.
  def change_role?
    current_user.admin?
  end

  def income?
    own_record? || current_user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_user.admin?
        scope.all                         # admins see everyone
      else
        scope.where(id: current_user.id)  # users only see themselves
      end
    end
  end

  private

  def own_record?
    record.id == current_user.id
  end
end
