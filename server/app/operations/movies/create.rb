module Movies
  class Create < Trailblazer::Operation
    step :build_movie
    step :validate_languages
    step :validate_formats
    step :validate_cast_members
    step :persist_changes
    fail :collect_errors

    private

    def build_movie(ctx, params:, **)
      ctx[:model] = ::Movie.new(
        title:        params[:title],
        genre:        params[:genre],
        rating:       params[:rating],
        description:  params[:description],
        director:     params[:director],
        running_time: params[:running_time],
        release_date: params[:release_date]
      )
    end

    def validate_languages(ctx, params:, **)
      entries = Array(params[:language_entries])
      return true if entries.empty?

      language_ids = entries.map { |e| e[:language_id] || e['language_id'] }.uniq
      valid_ids    = Language.where(id: language_ids).pluck(:id)
      invalid      = language_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { language_entries: ["Unknown languages IDs: #{invalid.join(', ')}"] }
        return false
      end

      valid_types = %w[original dubbed subtitled]
      entries.each do |entry|
        type = entry[:type] || entry['type']
        unless valid_types.include?(type.to_s)
          ctx[:errors] = { language_entries: ["Invalid type '#{type}'. Must be one of: #{valid_types.join(', ')}"] }
          return false
        end
      end

      ctx[:language_entries] = entries.map do |entry|
        {
          language_id: entry[:language_id] || entry['language_id'],
          language_type: entry[:type] || entry['type']
        }
      end

      true
    end

    def validate_formats(ctx, params:, **)
      format_ids = Array(params[:format_ids]).uniq
      return true if format_ids.empty?

      valid_ids = Format.where(id: format_ids).pluck(:id)
      invalid   = format_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { format_ids: ["Unknown formats IDs: #{invalid.join(', ')}"] }
        return false
      end

      ctx[:format_ids] = format_ids

      true
    end

    def validate_cast_members(ctx, params:, **)
      members = Array(params[:cast_members])
      return true if members.empty?

      valid_roles = %w[actor director producer writer composer]

      members.each do |member|
        role = member[:role] || member['role']
        unless valid_roles.include?(role.to_s)
          ctx[:errors] = { cast_members: ["Invalid role '#{role}'. Must be one of: #{valid_roles.join(', ')}"] }
          return false
        end
      end

      ctx[:cast_members] = members.map do |member|
        {
          name: member[:name] || member['name'],
          role: member[:role] || member['role'],
          character_name: member[:character_name] || member['character_name']
        }
      end

      true
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
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      ctx[:errors] = extract_errors(e, model)
      false
    end

    def extract_errors(error, model)
      record = error.respond_to?(:record) ? error.record : nil
      return record.errors.to_hash(true) if record&.errors&.any?

      model.errors.to_hash(true).presence || { base: [error.message] }
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
