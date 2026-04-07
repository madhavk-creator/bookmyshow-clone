module Api
  module V1
    class ReviewsController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]
      before_action :find_movie

      # GET /api/v1/movies/:movie_id/reviews
      def index
        result = Reviews::Index.call(
          current_user: current_user,
          params: {
            movie_id: @movie.id,
            page: params[:page],
            per_page: params[:per_page]
          }
        )

        if result.success?
          render json: {
            movie_id: @movie.id,
            average_rating: result[:average_rating],
            total_reviews: result[:total_reviews],
            reviews: result[:records].map { |review| serialize(review) },
            pagination: result[:pagination]
          }
        else
          render_errors(result)
        end
      end

      # GET /api/v1/movies/:movie_id/reviews/:id
      def show
        result = Reviews::Show.call(
          current_user: current_user,
          params: { id: params[:id], movie_id: @movie.id }
        )

        if result.success?
          render json: serialize(result[:model])
        else
          render_not_found_or_errors(result)
        end
      end

      # POST /api/v1/movies/:movie_id/reviews
      def create
        authorize Review

        result = Reviews::Create.call(
          current_user: current_user,
          params: review_params.to_h.merge(movie_id: @movie.id)
        )

        if result.success?
          render json: serialize(result[:model]), status: :created
        else
          render_not_found_or_errors(result)
        end
      end

      # PATCH /api/v1/movies/:movie_id/reviews/:id
      def update
        result = Reviews::Update.call(
          current_user: current_user,
          params: review_params.to_h.merge(id: params[:id], movie_id: @movie.id)
        )

        if result.success?
          authorize result[:model]
          render json: serialize(result[:model])
        else
          render_not_found_or_errors(result)
        end
      end

      # DELETE /api/v1/movies/:movie_id/reviews/:id
      def destroy
        result = Reviews::Destroy.call(
          current_user: current_user,
          params: { id: params[:id], movie_id: @movie.id }
        )

        if result.success?
          render json: { message: "Review deleted successfully" }
        else
          render_not_found_or_errors(result)
        end
      end

      private

      def find_movie
        @movie = Movie.find_by(id: params[:movie_id])
        return if @movie

        render json: { errors: { movie: [ "Movie not found" ] } }, status: :not_found
      end

      def review_params
        params.require(:review).permit(:rating, :description)
      end

      def serialize(review)
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

      def render_errors(result, status: :unprocessable_entity)
        render json: {
          errors: result[:errors] || { base: [ "Request failed" ] }
        }, status: status
      end

      def render_not_found_or_errors(result)
        errors = result[:errors] || {}
        messages = errors.values.flatten.map(&:to_s)

        status =
          if errors[:movie]&.include?("Movie not found") || errors[:review]&.include?("Review not found")
            :not_found
          elsif messages.any? { |message| message.start_with?("Not authorized") }
            :forbidden
          else
            :unprocessable_entity
          end

        render_errors(result, status: status)
      end
    end
  end
end
