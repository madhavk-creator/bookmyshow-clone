# index / show  → public
# create        → authenticated user who has a valid ticket for the movie
# update        → own review only
# destroy       → own review, or admin

class ReviewPolicy < ApplicationPolicy
  def index?   = true
  def show?    = true
  def create?  = current_user.present?
  def update?  = own_review?
  def destroy? = own_review? || current_user&.admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end

  private

  def own_review?
    current_user&.id == record.user_id
  end
end
