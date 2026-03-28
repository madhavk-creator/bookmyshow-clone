# Handles city resolution inline:
#   - If city_id is provided, use it directly.
#   - If city name + state are provided, find-or-create the city.
# This lets vendors register a theatre in a new city without a separate API call.

class Theatre
  class Create < Trailblazer::Operation
    step :resolve_city
    step :build_theatre
    step :persist
    fail :collect_errors

    private

    def resolve_city(ctx, params:, current_user:, **)
      if params[:city_id].present?
        ctx[:city] = City.find_by(id: params[:city_id])
        unless ctx[:city]
          ctx[:errors] = { city_id: ['City not found'] }
          return false
        end
      elsif params[:city_name].present? && params[:city_state].present?
        ctx[:city] = City.find_or_create_by(
          name:  params[:city_name].strip.titleize,
          state: params[:city_state].strip.titleize
        )
        unless ctx[:city].persisted?
          ctx[:errors] = { city: ctx[:city].errors.full_messages }
          return false
        end
      else
        ctx[:errors] = { city: ['Provide either city_id or city_name + city_state'] }
        return false
      end

      true
    end

    def build_theatre(ctx, params:, current_user:, **)
      ctx[:model] = Theatre.new(
        vendor_id:      current_user.id,
        city:           ctx[:city],
        name:           params[:name],
        building_name:  params[:building_name],
        street_address: params[:street_address],
        pincode:        params[:pincode]
      )
    end

    def persist(ctx, model:, **)
      model.save
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= {}
      ctx[:errors].merge!(ctx[:model].errors.to_hash(true)) if ctx[:model]
    end
  end  
end