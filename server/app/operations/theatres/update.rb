class Theatre
  class Update < Trailblazer::Operation
    step :find_theatre
    step :update_attributes
    step :persist
    fail :collect_errors

    private

    def find_theatre(ctx, params:, **)
      ctx[:model] = Theatre.find_by(id: params[:id])
      unless ctx[:model]
        ctx[:errors] = { base: ['Theatre not found'] }
        return false
      end
      
      true
    end

    def update_attributes(ctx, params:, model:, **)
      allowed = %i[name building_name street_address pincode]
      model.assign_attributes(params.slice(*allowed).compact)
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= {}
      ctx[:errors].merge!(ctx[:model].errors.messages) if ctx[:model]
    end
  end
end