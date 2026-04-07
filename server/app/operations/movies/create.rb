module Movies
  class Create < ::Trailblazer::Operation
    include AssociationValidationSupport

    step :authorize_create
    step :build_movie
    step :validate_languages
    step :validate_formats
    step :validate_cast_members
    step :persist_changes
    fail :collect_errors

    def authorize_create(ctx, current_user:, **)
      return true if Pundit.policy!(current_user, ::Movie).create?

      ctx[:errors] = { base: [ "Not authorized to create movie" ] }
      false
    end

    def build_movie(ctx, params:, **)
      ctx[:model] = ::Movie.new(movie_attributes(params))
      true
    end

    def validate_languages(ctx, params:, **)
      valid, payload = validate_language_entries(ctx, params[:language_entries])
      ctx[:language_entries] = payload if valid
      valid
    end

    def validate_formats(ctx, params:, **)
      valid, payload = validate_format_ids(ctx, params[:format_ids])
      ctx[:format_ids] = payload if valid
      valid
    end

    def validate_cast_members(ctx, params:, **)
      valid, payload = validate_cast_member_entries(ctx, params[:cast_members])
      ctx[:cast_members] = payload.map { |member| member.except(:id) } if valid
      valid
    end

    def persist_changes(ctx, model:, **)
      Movie.transaction do
        model.save!

        Array(ctx[:language_entries]).each do |entry|
          model.movie_languages.create!(entry)
        end

        Array(ctx[:format_ids]).each do |format_id|
          model.movie_formats.create!(format_id: format_id)
        end

        Array(ctx[:cast_members]).each do |member|
          model.cast_members.create!(member)
        end
      end

      true
    rescue ActiveRecord::ActiveRecordError => e
      ctx[:errors] = extract_errors(e, model)
      false
    end

    def extract_errors(error, model)
      record = error.respond_to?(:record) ? error.record : nil
      return record.errors.to_hash(true) if record&.errors&.any?

      model.errors.to_hash(true).presence || { base: [ error.message ] }
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end

    private

    def movie_attributes(params)
      {
        title: params[:title],
        genre: params[:genre],
        rating: params[:rating],
        description: params[:description],
        director: params[:director],
        running_time: params[:running_time],
        release_date: params[:release_date]
      }
    end
  end
end
