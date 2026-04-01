class Screen
  class Create < Trailblazer::Operation
    step :find_theatre
    step :authorize_theatre_ownership
    step :build_screen
    step :persist
    step :sync_capabilities
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
        ctx[:errors] = { base: ['You do not own this theatre'] }
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

    def persist(ctx, model:, **)
      model.save
    end

    def sync_capabilities(ctx, params:, model:, **)
      return true unless params[:format_ids].present?

      format_ids = Array(params[:format_ids]).uniq

      # Validate all format_ids exist before touching the DB
      valid_ids = Format.where(id: format_ids).pluck(:id)
      invalid   = format_ids - valid_ids
      if invalid.any?
        ctx[:errors] = { format_ids: ["Unknown formats IDs: #{invalid.join(', ')}"] }
        return false
      end

      model.screen_capabilities.destroy_all
      valid_ids.each do |fid|
        model.screen_capabilities.create!(format_id: fid)
      end

      true
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end