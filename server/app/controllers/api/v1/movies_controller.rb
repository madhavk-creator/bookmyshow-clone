module Api
  module V1
    class MoviesController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/movies
      # Public. Supports genre, language, format, city_id filters.
      def index
        movies = policy_scope(Movie)
                   .includes(:languages, :formats)

        movies = filter_by_genre(movies)
        movies = filter_by_language(movies)
        movies = filter_by_format(movies)
        movies = filter_by_city(movies)

        render json: movies.order(:title).map { |m| serialize(m) }
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

        result = Movie::Create.call(params: movie_params.to_h.deep_symbolize_keys)

        if result.success?
          render json: serialize(result[:model]), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/movies/:id
      # Admin only.
      def update
        movie = Movie.find_by(id: params[:id])
        return not_found unless movie

        authorize movie

        result = Movie::Update.call(
          params: movie_params.to_h.deep_symbolize_keys.merge(id: params[:id])
        )

        if result.success?
          render json: serialize(result[:model])
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/movies/:id
      # Admin only.
      def destroy
        movie = Movie.find_by(id: params[:id])
        return not_found unless movie

        authorize movie

        result = Movie::Destroy.call(params: { id: params[:id] })

        if result.success?
          render json: { message: 'Movie deleted successfully' }
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      private

      def filter_by_genre(scope)
        return scope unless params[:genre].present?
        scope.where('genre ILIKE ?', params[:genre])
      end

      def filter_by_language(scope)
        return scope unless params[:language].present?
        scope.joins(:languages).where(languages: { code: params[:language].downcase })
      end

      def filter_by_format(scope)
        return scope unless params[:format].present?
        scope.joins(:formats).where(formats: { code: params[:format].downcase })
      end

      # Movies with at least one scheduled (non-cancelled) show
      # in a screen belonging to a theatre in the given city.
      def filter_by_city(scope)
        return scope unless params[:city_id].present?
        scope.joins(shows: { screen: :theatre })
             .where(theatres: { city_id: params[:city_id] })
             .where(shows: { status: 'scheduled' })
             .distinct
      end

      def movie_params
        params.require(:movie).permit(
          :title, :genre, :rating, :description,
          :director, :running_time, :release_date,
          format_ids: [],
          language_entries: [:language_id, :type],
          cast_members: [:name, :role, :character_name]
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
            { id: l.id, name: l.name, code: l.code, type: entry&.language_type }
          },
          formats:      movie.formats.map { |f| { id: f.id, name: f.name, code: f.code } }
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