class SeatLayout < ApplicationRecord
  belongs_to :screen
  has_many :seat_sections, dependent: :destroy
  has_many :seats, through: :seat_sections
  has_many :shows, dependent: :restrict_with_error

  enum :status, { draft: "draft", published: "published", archived: "archived" }, prefix: true

  validates :name, presence: true
  validates :version_number, uniqueness: { scope: :screen_id }
  validates :total_rows, :total_columns, numericality: { only_integer: true, greater_than: 0 }
  validates :total_seats, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :only_one_published_per_screen, if: :status_published?
  before_validation :assign_version_number, on: :create
  before_validation :sync_dimensions_from_screen

  private

  def assign_version_number
    return if version_number.present?
    last = SeatLayout.where(screen_id: screen_id).maximum(:version_number) || 0
    self.version_number = last + 1
  end

  def only_one_published_per_screen
    return unless SeatLayout.where(screen_id: screen_id, status: "published")
                            .where.not(id: id).exists?
    errors.add(:status, "another layout is already published for this screens")
  end

  def sync_dimensions_from_screen
    return unless screen

    self.total_rows = screen.total_rows
    self.total_columns = screen.total_columns
  end

  scope :published_first, -> { order(published_at: :desc, created_at: :desc) }
end
