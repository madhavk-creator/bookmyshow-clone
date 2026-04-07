module Movies
  module Serializer
    module_function

    def call(movie, detailed: false)
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

      return base unless detailed

      base[:description] = movie.description
      base[:cast_members] = movie.cast_members.map do |member|
        {
          id: member.id,
          name: member.name,
          role: member.role,
          character_name: member.character_name
        }
      end

      base
    end

    def many(movies, detailed: false)
      movies.map { |movie| call(movie, detailed: detailed) }
    end
  end
end
