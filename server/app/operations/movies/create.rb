class Movie
  class Create < Trailblazer::Operation
    step :build_movie
    step :persist_movie
    step :sync_languages
    step :sync_formats
    step :sync_cast
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

    def persist_movie(ctx, model:, **)
      model.save
    end

    def sync_languages(ctx, params:, model:, **)
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
      true
      end

      entries.each do |entry|
        model.movie_languages.create!(
          language_id: entry[:language_id] || entry['language_id'],
          language_type: entry[:type] || entry['type']
        )
      end

      true
    end

    def sync_formats(ctx, params:, model:, **)
      format_ids = Array(params[:format_ids]).uniq
      return true if format_ids.empty?

      valid_ids = Format.where(id: format_ids).pluck(:id)
      invalid   = format_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { format_ids: ["Unknown formats IDs: #{invalid.join(', ')}"] }
        return false
      end

      format_ids.each do |fid|
        model.movie_formats.create!(format_id: fid)
      end

      true
    end

    def sync_cast(ctx, params:, model:, **)
      members = Array(params[:cast_members])
      return true if members.empty?

      valid_roles = %w[actor director producer writer composer]

      members.each do |member|
        role = member[:role] || member['role']
        unless valid_roles.include?(role.to_s)
          ctx[:errors] = { cast_members: ["Invalid role '#{role}'. Must be one of: #{valid_roles.join(', ')}"] }
          return false
        end
      true
      end

      members.each do |member|
        model.cast_members.create!(
          name:           member[:name]           || member['name'],
          role:           member[:role]           || member['role'],
          character_name: member[:character_name] || member['character_name']
        )
      end

      true
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
