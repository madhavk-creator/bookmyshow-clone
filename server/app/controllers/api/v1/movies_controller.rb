module Api
  module V1
    class MoviesController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/movies
      # Public. Supports genre, languages, formats, city_id filters.
      def index
        result = run Movies::Index, params: index_params do |operation_result|
          return render json: {
            movies: Movies::Serializer.many(operation_result[:records]),
            pagination: operation_result[:pagination]
          }, status: :ok
        end

        render_operation_errors(result)
      end

      # GET /api/v1/movies/:id
      # Public. Returns full detail including languages, formats, cast.
      def show
        result = run Movies::Show, params: { id: params[:id] } do |operation_result|
          return render json: Movies::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/movies
      # Admin only.
      def create
        result = run(Movies::Create, params: movie_params.to_h.deep_symbolize_keys) do |operation_result|
          return render json: Movies::Serializer.call(operation_result[:model], detailed: true), status: :created
        end

        render_operation_errors(result)
      end

      # PATCH /api/v1/movies/:id
      # Admin only.
      def update
        result = run Movies::Update, params: movie_params.to_h.deep_symbolize_keys.merge(id: params[:id]) do |operation_result|
          return render json: Movies::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # DELETE /api/v1/movies/:id
      # Admin only.
      def destroy
        result = run(Movies::Destroy, params: { id: params[:id] }) do
          return render json: { message: "Movie deleted successfully" }
        end

        render_operation_errors(result)
      end

      private

      def movie_params
        params.require(:movie).permit(
          :title, :genre, :rating, :description,
          :director, :running_time, :release_date,
          format_ids: [],
          language_entries: [ :language_id, :type ],
          cast_members: [ :id, :name, :role, :character_name ]
        )
      end

      def index_params
        params.permit(:genre, :language, :format, :city_id, :page, :per_page, movie: {}).to_h.deep_symbolize_keys
      end

      def not_found = render(json: { error: "Movie not found" }, status: :not_found)
    end
  end
end
