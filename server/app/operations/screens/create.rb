module Screens
  class Create < Trailblazer::Operation
    step :find_theatre
    step :authorize_theatre_ownership
    step :build_screen
    step :validate_format_ids
    step :persist_changes
    fail :collect_errors

    private

    def find_theatre(ctx, params:, **)
      ctx[:theatre] = Theatre.find_by(id: params[:theatre_id])
      unless ctx[:theatre]
        ctx[:errors] = { theatre: ['Theatre not found'] }
        return false
      end
      true
    end

    # Vendor can only add screens to their own theatres.
    # Admins bypass this check.
    def authorize_theatre_ownership(ctx, current_user:, theatre:, **)
      return true if current_user.admin?

      unless theatre.vendor_id == current_user.id
        ctx[:errors] = { base: ['You do not own this theatres'] }
        return false
      end
      true
    end

    def build_screen(ctx, params:, theatre:, **)
      ctx[:model] = ::Screen.new(
        theatre:       theatre,
        name:          params[:name],
        status:        params[:status] || 'active',
        total_rows:    params[:total_rows],
        total_columns: params[:total_columns],
        total_seats:   0   # seeded from seat layout, not set manually
      )
    end

    def validate_format_ids(ctx, params:, **)
      return true unless params.key?(:format_ids)

      format_ids = Array(params[:format_ids]).uniq

      # Validate all format_ids exist before touching the DB
      valid_ids = Format.where(id: format_ids).pluck(:id)
      invalid   = format_ids - valid_ids
      if invalid.any?
        ctx[:errors] = { format_ids: ["Unknown formats IDs: #{invalid.join(', ')}"] }
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
      Array(format_ids).each do |format_id|
        model.screen_capabilities.create!(format_id: format_id)
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
