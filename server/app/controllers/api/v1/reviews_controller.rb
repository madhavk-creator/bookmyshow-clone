module Api
  module V1
    class ReviewsController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/movies/:movie_id/reviews
      def index
        result = run Reviews::Index, params: index_params do |operation_result|
          return render json: {
            movie_id: operation_result[:movie].id,
            average_rating: operation_result[:average_rating],
            total_reviews: operation_result[:total_reviews],
            reviews: Reviews::Serializer.many(operation_result[:records]),
            pagination: operation_result[:pagination]
          }, status: :ok
        end

        render_operation_errors(result)
      end

      # GET /api/v1/movies/:movie_id/reviews/:id
      def show
        result = run Reviews::Show, params: { id: params[:id], movie_id: params[:movie_id] } do |operation_result|
          return render json: Reviews::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/movies/:movie_id/reviews
      def create
        result = run Reviews::Create, params: review_params.to_h.deep_symbolize_keys.merge(movie_id: params[:movie_id]) do |operation_result|
          return render json: Reviews::Serializer.call(operation_result[:model]), status: :created
        end

        render_operation_errors(result)
      end

      # PATCH /api/v1/movies/:movie_id/reviews/:id
      def update
        result = run Reviews::Update, params: review_params.to_h.deep_symbolize_keys.merge(id: params[:id], movie_id: params[:movie_id]) do |operation_result|
          return render json: Reviews::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # DELETE /api/v1/movies/:movie_id/reviews/:id
      def destroy
        result = run Reviews::Destroy, params: { id: params[:id], movie_id: params[:movie_id] } do
          return render json: { message: "Review deleted successfully" }
        end

        render_operation_errors(result)
      end

      private

      def review_params
        params.require(:review).permit(:rating, :description)
      end

      def index_params
        params.permit(:movie_id, :page, :per_page, review: {}).to_h.deep_symbolize_keys
      end
    end
  end
end
