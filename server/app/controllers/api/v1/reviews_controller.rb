module Api
  module V1
    class ReviewsController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]
      before_action :find_movie

      # GET /api/v1/movies/:movie_id/reviews
      # Public. Returns reviews ordered by most recent, with aggregate stats.
      def index
        result = run(
          Reviews::Index,
          current_user: current_user,
          params: { movie_id: @movie.id, page: params[:page], per_page: params[:per_page] }
        ) do |operation_result|
          return render json: {
            movie_id:       @movie.id,
            average_rating: operation_result[:average_rating],
            total_reviews:  operation_result[:total_reviews],
            reviews:        operation_result[:records].map { |review| serialize(review) },
            pagination:     operation_result[:pagination]
          }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # GET /api/v1/movies/:movie_id/reviews/:id
      # Public.
      def show
        review = find_review
        return unless review

        render json: serialize(review)
      end

      # POST /api/v1/movies/:movie_id/reviews
      def create
        authorize Review

        result = Reviews::Create.call(
          params:       review_params.to_h.merge(movie_id: @movie.id),
          current_user: current_user
        )

        if result.success?
          render json: serialize(result[:model]), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/movies/:movie_id/reviews/:id
      def update
        review = find_review
        return unless review

        authorize review

        result = Reviews::Update.call(
          params:       review_params.to_h.merge(id: review.id),
          current_user: current_user
        )

        if result.success?
          render json: serialize(result[:model])
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/movies/:movie_id/reviews/:id
      def destroy
        review = find_review
        return unless review

        authorize review

        result = Reviews::Destroy.call(params: { id: review.id })

        if result.success?
          render json: { message: 'Review deleted successfully' }
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      private

      def find_movie
        @movie = Movie.find_by(id: params[:movie_id])
        render json: { error: 'Movie not found' }, status: :not_found unless @movie
      end

      def find_review
        review = @movie.reviews.find_by(id: params[:id])
        render json: { error: 'Review not found' }, status: :not_found unless review
        review
      end

      def review_params
        params.require(:review).permit(:rating, :description)
      end

      def serialize(review)
        {
          id:          review.id,
          user:        { id: review.user_id, name: review.user.name },
          rating:      review.rating,
          description: review.description,
          reviewed_on: review.reviewed_on
        }
      end
    end
  end
end
