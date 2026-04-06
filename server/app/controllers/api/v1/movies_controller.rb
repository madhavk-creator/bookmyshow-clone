module Api
  module V1
    class MoviesController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]
      before_action :find_movie, only: %i[show update destroy]

      # GET /api/v1/movies
      # Public. Supports genre, languages, formats, city_id filters.
      def index
        result = run(
          Movies::Index,
          current_user: current_user,
          params: {
            genre: params[:genre],
            language: params[:language],
            format: params[:format],
            city_id: params[:city_id],
            page: params[:page],
            per_page: params[:per_page]
          }
        ) do |operation_result|
          return render json: {
            movies: operation_result[:records].map { |movie| serialize(movie) },
            pagination: operation_result[:pagination]
          }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # GET /api/v1/movies/:id
      # Public. Returns full detail including languages, formats, cast.
      def show
        render json: serialize(@movie, detailed: true)
      end

      # POST /api/v1/movies
      # Admin only.
      def create
        authorize Movie

        result = run(Movies::Create, params: movie_params.to_h.deep_symbolize_keys) do |operation_result|
          return render json: serialize(operation_result[:model]), status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/movies/:id
      # Admin only.
      def update
        authorize @movie

        result = run(
          Movies::Update,
          params: movie_params.to_h.deep_symbolize_keys,
          model: @movie
        ) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # DELETE /api/v1/movies/:id
      # Admin only.
      def destroy
        authorize @movie

        result = run(Movies::Destroy, model: @movie) do
          return render json: { message: "Movie deleted successfully" }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def find_movie
        @movie = Movie.includes(:movie_languages, :movie_formats, :languages, :formats, :cast_members).find_by(id: params[:id])
        return if @movie

        not_found
      end

      def movie_params
        params.require(:movie).permit(
          :title, :genre, :rating, :description,
          :director, :running_time, :release_date,
          format_ids: [],
          language_entries: [ :language_id, :type ],
          cast_members: [ :id, :name, :role, :character_name ]
        )
      end

      def serialize(movie, detailed: false)
        # Nested arrays in PATCH are full replacements:
        # language_entries and format_ids replace their full sets,
        # and cast_members replaces the full set while updating any provided IDs.
        movie_languages_by_id = movie.movie_languages.index_by(&:language_id)
        movie_formats_by_id   = movie.movie_formats.index_by(&:format_id)

        base = {
          id: movie.id,
          title: movie.title,
          genre: movie.genre,
          rating: movie.rating,
          director: movie.director,
          running_time: movie.running_time,
          release_date: movie.release_date,
          languages: movie.languages.map do |language|
            entry = movie_languages_by_id[language.id]
            {
              id: language.id,
              movie_language_id: entry&.id,
              name: language.name,
              code: language.code,
              type: entry&.language_type
            }
          end,
          formats: movie.formats.map do |format|
            entry = movie_formats_by_id[format.id]
            {
              id: format.id,
              movie_format_id: entry&.id,
              name: format.name,
              code: format.code
            }
          end
        }

        if detailed
          base[:description] = movie.description
          base[:cast_members] = movie.cast_members.map do |member|
            {
              id: member.id,
              name: member.name,
              role: member.role,
              character_name: member.character_name
            }
          end
        end

        base
      end

      def not_found = render(json: { error: "Movie not found" }, status: :not_found)
    end
  end
end
