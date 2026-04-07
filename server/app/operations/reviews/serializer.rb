module Reviews
  module Serializer
    module_function

    def call(review)
      {
        id: review.id,
        user: {
          id: review.user_id,
          name: review.user.name
        },
        rating: review.rating,
        description: review.description,
        reviewed_on: review.reviewed_on
      }
    end

    def many(reviews)
      reviews.map { |review| call(review) }
    end
  end
end
