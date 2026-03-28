class CastMember < ApplicationRecord
  belongs_to :movie

  enum :role, {
    actor: "actor",
    director: "director",
    producer: "producer",
    writer: "writer",
    composer: "composer"
  }, prefix: true

  validates :name, :role, presence: true
end
