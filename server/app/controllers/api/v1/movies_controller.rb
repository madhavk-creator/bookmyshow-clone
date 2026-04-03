module Api
  module V1
    class MoviesController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

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
        movie = Movie.includes(:languages, :formats, :cast_members).find_by(id: params[:id])
        return not_found unless movie

        render json: serialize(movie, detailed: true)
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
        movie = Movie.find_by(id: params[:id])
        return not_found unless movie

        authorize movie

        result = run(
          Movies::Update,
          params: movie_params.to_h.deep_symbolize_keys,
          model: movie
        ) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # DELETE /api/v1/movies/:id
      # Admin only.
      def destroy
        movie = Movie.find_by(id: params[:id])
        return not_found unless movie

        authorize movie

        result = run(Movies::Destroy, params: { id: params[:id], model: movie }) do
          return render json: { message: 'Movie deleted successfully' }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def movie_params
        params.require(:movie).permit(
          :title, :genre, :rating, :description,
          :director, :running_time, :release_date,
          format_ids: [],
          language_entries: [:language_id, :type],
          cast_members: [:id, :name, :role, :character_name]
        )
      end

      def serialize(movie, detailed: false)
        base = {
          id:           movie.id,
          title:        movie.title,
          genre:        movie.genre,
          rating:       movie.rating,
          director:     movie.director,
          running_time: movie.running_time,
          release_date: movie.release_date,
          languages:    movie.languages.map { |l|
            entry = movie.movie_languages.find { |ml| ml.language_id == l.id }
            {
              id: l.id,
              movie_language_id: entry&.id,
              name: l.name,
              code: l.code,
              type: entry&.language_type
            }
          },
          formats:      movie.formats.map { |f|
            entry = movie.movie_formats.find { |mf| mf.format_id == f.id }
            {
              id: f.id,
              movie_format_id: entry&.id,
              name: f.name,
              code: f.code
            }
          }
        }

        if detailed
          base.merge!(
            description:  movie.description,
            cast_members: movie.cast_members.map { |c|
              { id: c.id, name: c.name, role: c.role, character_name: c.character_name }
            }
          )
        end

        base
      end

      def not_found
        render json: { error: 'Movie not found' }, status: :not_found
      end
    end
  end
end
