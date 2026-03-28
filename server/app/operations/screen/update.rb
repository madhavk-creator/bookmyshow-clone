class Screen
  class Update < Trailblazer::Operation
    step :find_screen
    step :assign_attributes
    step :persist
    step :sync_capabilities
    fail :collect_errors

    private

    def find_screen(ctx, params:, **)
      ctx[:model] = ::Screen.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Screen not found'] }
        return false
      end
      true
    end

    def assign_attributes(ctx, params:, model:, **)
      allowed = %i[name status total_rows total_columns]
      model.assign_attributes(params.slice(*allowed).compact)
    end

    def persist(ctx, model:, **)
      model.save
    end

    def sync_capabilities(ctx, params:, model:, **)
      return true unless params[:format_ids].present?

      format_ids = Array(params[:format_ids]).uniq
      valid_ids  = Format.where(id: format_ids).pluck(:id)
      invalid    = format_ids - valid_ids

      if invalid.any?
        ctx[:errors] = { format_ids: ["Unknown format IDs: #{invalid.join(', ')}"] }
        return false
      end

      model.screen_capabilities.destroy_all
      valid_ids.each { |fid| model.screen_capabilities.create!(format_id: fid) }

      true
    end

    def collect_errors(ctx, model: nil, **)
      ctx[:errors] ||= model&.errors&.to_hash(true) || {}
    end
  end
end