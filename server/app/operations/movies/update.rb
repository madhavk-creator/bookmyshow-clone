module Movies
  class Update < Trailblazer::Operation
    step :assign_attributes
    step :validate_languages
    step :validate_formats
    step :validate_cast_members
    step :persist_changes
    fail :collect_errors

    private
    def assign_attributes(ctx, params:, model:, **)
      allowed = %i[title genre rating description director running_time release_date]
      model.assign_attributes(params.slice(*allowed).compact)
      true
    end

    def validate_languages(ctx, params:, **)
      return true unless params.key?(:language_entries)

      entries      = Array(params[:language_entries])
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
          language_id:   entry[:language_id] || entry['language_id'],
          language_type: entry[:type] || entry['type']
        }
      end

      true
    end

    def validate_formats(ctx, params:, **)
      return true unless params.key?(:format_ids)

      format_ids = Array(params[:format_ids]).uniq
      valid_ids  = Format.where(id: format_ids).pluck(:id)
      invalid    = format_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { format_ids: ["Unknown formats IDs: #{invalid.join(', ')}"] }
        return false
      end

      ctx[:format_ids] = format_ids

      true
    end

    def validate_cast_members(ctx, params:, model:, **)
      return true unless params.key?(:cast_members)

      members     = Array(params[:cast_members])
      valid_roles = %w[actor director producer writer composer]
      existing_ids = model.cast_members.pluck(:id)
      provided_ids = []

      members.each do |member|
        cast_member_id = member[:id] || member['id']
        role = member[:role] || member['role']

        if cast_member_id.present?
          unless existing_ids.include?(cast_member_id)
            ctx[:errors] = { cast_members: ["Unknown cast member ID: #{cast_member_id}"] }
            return false
          end

          if provided_ids.include?(cast_member_id)
            ctx[:errors] = { cast_members: ["Duplicate cast member ID: #{cast_member_id}"] }
            return false
          end

          provided_ids << cast_member_id
        end

        unless valid_roles.include?(role.to_s)
          ctx[:errors] = { cast_members: ["Invalid role '#{role}'. Must be one of: #{valid_roles.join(', ')}"] }
          return false
        end
      end

      ctx[:cast_members] = members.map do |member|
        {
          id: member[:id] || member['id'],
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
        sync_languages!(model, ctx[:language_entries]) if ctx.key?(:language_entries)
        sync_formats!(model, ctx[:format_ids]) if ctx.key?(:format_ids)
        sync_cast_members!(model, ctx[:cast_members]) if ctx.key?(:cast_members)
      end

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
      ctx[:errors] = extract_errors(e, model)
      false
    end

    def sync_languages!(model, entries)
      incoming_language_ids = entries.map { |e| e[:language_id] }

      model.movie_languages.where.not(language_id: incoming_language_ids).destroy_all
      existing_records = model.movie_languages.index_by(&:language_id)

      entries.each do |entry|
        existing_record = existing_records[entry[:language_id]]

        if existing_record
          if existing_record.language_type != entry[:language_type]
            existing_record.update!(language_type: entry[:language_type])
          end
        else
          model.movie_languages.create!(entry)
        end
      end
    end

    def sync_formats!(model, incoming_format_ids)
      existing_format_ids = model.movie_formats.pluck(:format_id)

      to_delete = existing_format_ids - incoming_format_ids
      to_add    = incoming_format_ids - existing_format_ids

      model.movie_formats.where(format_id: to_delete).destroy_all if to_delete.any?

      to_add.each do |format_id|
        model.movie_formats.create!(format_id: format_id)
      end
    end

    def sync_cast_members!(model, members) # diff-based update
      existing_members = model.cast_members.index_by(&:id)
      incoming_ids = members.filter_map { |member| member[:id] }

      model.cast_members.where.not(id: incoming_ids).destroy_all

      members.each do |member|
        attributes = member.slice(:name, :role, :character_name)

        if member[:id].present?
          existing_members.fetch(member[:id]).update!(attributes)
        else
          model.cast_members.create!(attributes)
        end
      end
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
