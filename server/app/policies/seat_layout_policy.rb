# index / show  → public (vendors and users need to see layouts)
# create        → vendor who owns the screen's theatre, or admin
# update        → same, and only on draft layouts
# publish       → same as update
# archive       → same as update
# sync_sections → same as update
# sync_seats    → same as update

class SeatLayoutPolicy < ApplicationPolicy
  def index?  = true
  def show?
    published_or_admin_or_owns_screen?
  end

  def create?
    admin_or_owns_screen?
  end

  def update?
    admin_or_owns_screen? && record.status_draft?
  end

  # Publish transitions draft → published.
  # Blocked if layout is already published or archived.
  def publish?
    admin_or_owns_screen? && record.status_draft?
  end

  # Archive transitions published → archived.
  def archive?
    admin_or_owns_screen? && record.status_published?
  end

  def sync_sections?
    admin_or_owns_screen? && record.status_draft?
  end

  def sync_seats?
    admin_or_owns_screen? && record.status_draft?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if current_user&.admin?

      if current_user&.vendor?
        return scope.left_outer_joins(screen: :theatre)
                    .where("seat_layouts.status = ? OR theatres.vendor_id = ?", "published", current_user.id)
      end

      scope.where(status: "published")
    end
  end

  private

  def admin_or_owns_screen?
    return false unless current_user
    return true if current_user.admin?
    return false unless record.respond_to?(:screen) && record.screen

    current_user.vendor? &&
      record.screen.theatre.vendor_id == current_user.id
  end

  def published_or_admin_or_owns_screen?
    return true if record.status_published?

    admin_or_owns_screen?
  end
end
