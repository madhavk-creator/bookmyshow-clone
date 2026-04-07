module Movies
  class Update < ::Trailblazer::Operation
    include AssociationValidationSupport

    step :find_movie
    step :authorize_movie
    step :assign_attributes
    step :validate_languages
    step :validate_formats
    step :validate_cast_members
    step :persist_changes
    fail :collect_errors

    def find_movie(ctx, params:, model: nil, **)
      return true if model.present?

      ctx[:model] = ::Movie.includes(:movie_languages, :movie_formats, :cast_members).find_by(id: params[:id])
      return true if ctx[:model]

      ctx[:errors] = { base: [ "Movie not found" ] }
      false
    end

    def authorize_movie(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update this movie" ] }
      false
    end

    def assign_attributes(ctx, params:, model:, **)
      allowed = %i[title genre rating description director running_time release_date]
      model.assign_attributes(params.slice(*allowed).compact)
      true
    end

    def validate_languages(ctx, params:, **)
      return true unless params.key?(:language_entries)

      valid, payload = validate_language_entries(ctx, params[:language_entries])
      ctx[:language_entries] = payload if valid
      valid
    end

    def validate_formats(ctx, params:, **)
      return true unless params.key?(:format_ids)

      valid, payload = validate_format_ids(ctx, params[:format_ids])
      ctx[:format_ids] = payload if valid
      valid
    end

    def validate_cast_members(ctx, params:, model:, **)
      return true unless params.key?(:cast_members)

      valid, payload = validate_cast_member_entries(
        ctx,
        params[:cast_members],
        model: model,
        allow_existing_ids: true
      )
      ctx[:cast_members] = payload if valid
      valid
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

    # PATCH treats nested cast_members as a full replacement set:
    # provided IDs are updated, omitted existing members are removed,
    # and entries without IDs are created.
    def sync_cast_members!(model, members)
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

      model.errors.to_hash(true).presence || { base: [ error.message ] }
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end
