module Screens
  class Update < ::Trailblazer::Operation
    step :find_theatre
    step :find_screen
    step :authorize_screen
    step :assign_attributes
    step :validate_format_ids
    step :persist_changes
    fail :collect_errors

    def find_theatre(ctx, params:, **)
      ctx[:theatre] = ::Theatre.find_by(id: params[:theatre_id])
      unless ctx[:theatre]
        ctx[:errors] = { theatre: [ "Theatre not found" ] }
        return false
      end
      true
    end

    def find_screen(ctx, params:, theatre:, **)
      ctx[:model] = theatre.screens.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { screen: [ "Screen not found" ] }
        return false
      end
      true
    end

    def authorize_screen(ctx, model:, current_user:, **)
      return true if Pundit.policy!(current_user, model).update?

      ctx[:errors] = { base: [ "Not authorized to update this screen" ] }
      false
    end

    def assign_attributes(ctx, params:, model:, **)
      allowed = %i[name status total_rows total_columns]
      model.assign_attributes(params.slice(*allowed).compact)
      true
    end

    def validate_format_ids(ctx, params:, **)
      return true unless params.key?(:format_ids)

      format_ids = Array(params[:format_ids]).uniq
      valid_ids  = Format.where(id: format_ids).pluck(:id)
      invalid    = format_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { format_ids: [ "Unknown formats IDs: #{invalid.join(', ')}" ] }
        return false
      end

      ctx[:format_ids] = valid_ids

      true
    end

    def persist_changes(ctx, model:, **)
      Screen.transaction do
        model.save!
        sync_capabilities!(model, ctx[:format_ids]) if ctx.key?(:format_ids)
      end

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      ctx[:errors] = extract_errors(e, model)
      false
    end

    def sync_capabilities!(model, format_ids)
      model.screen_capabilities.destroy_all
      Array(format_ids).each { |format_id| model.screen_capabilities.create!(format_id: format_id) }
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
