class Movie
  class Update < Trailblazer::Operation
    step :find_movie
    step :assign_attributes
    step :persist_movie
    step :sync_languages
    step :sync_formats
    step :sync_cast
    fail :collect_errors

    private

    def find_movie(ctx, params:, **)
      ctx[:model] = ::Movie.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Movie not found'] }
        return false
      end
    end

    def assign_attributes(ctx, params:, model:, **)
      allowed = %i[title genre rating description director running_time release_date]
      model.assign_attributes(params.slice(*allowed).compact)
    end

    def persist_movie(ctx, model:, **)
      model.save
    end

    def sync_languages(ctx, params:, model:, **)
      return true unless params.key?(:language_entries)

      entries      = Array(params[:language_entries])
      language_ids = entries.map { |e| e[:language_id] || e['language_id'] }.uniq
      valid_ids    = Language.where(id: language_ids).pluck(:id)
      invalid      = language_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { language_entries: ["Unknown language IDs: #{invalid.join(', ')}"] }
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

      model.movie_languages.destroy_all
      entries.each do |entry|
        model.movie_languages.create!(
          language_id:   entry[:language_id] || entry['language_id'],
          language_type: entry[:type]        || entry['type']
        )
      end

      true
    end

    def sync_formats(ctx, params:, model:, **)
      return true unless params.key?(:format_ids)

      format_ids = Array(params[:format_ids]).uniq
      valid_ids  = Format.where(id: format_ids).pluck(:id)
      invalid    = format_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { format_ids: ["Unknown format IDs: #{invalid.join(', ')}"] }
        return false
      end

      model.movie_formats.destroy_all
      format_ids.each { |fid| model.movie_formats.create!(format_id: fid) }

      true
    end

    def sync_cast(ctx, params:, model:, **)
      return true unless params.key?(:cast_members)

      members     = Array(params[:cast_members])
      valid_roles = %w[actor director producer writer composer]

      members.each do |member|
        role = member[:role] || member['role']
        unless valid_roles.include?(role.to_s)
          ctx[:errors] = { cast_members: ["Invalid role '#{role}'. Must be one of: #{valid_roles.join(', ')}"] }
          return false
        end
      end

      model.cast_members.destroy_all
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