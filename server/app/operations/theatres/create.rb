# Handles city resolution inline:
#   - If city_id is provided, use it directly.
#   - If city name + state are provided, find-or-create the city.
# This lets vendors register their own theatre, while admins can create one
# on behalf of an existing vendor, without a separate city-management call.

module Theatres
  class Create < ::Trailblazer::Operation
    step :resolve_city
    step :resolve_vendor
    step :build_theatre
    step :persist
    fail :collect_errors

    def resolve_city(ctx, params:, current_user:, **)
      if params[:city_id].present?
        ctx[:city] = City.find_by(id: params[:city_id])
        unless ctx[:city]
          ctx[:errors] = { city_id: [ "City not found" ] }
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
        ctx[:errors] = { city: [ "Provide either city_id or city_name + city_state" ] }
        return false
      end

      true
    end

    def resolve_vendor(ctx, params:, current_user:, **)
      if current_user.vendor?
        ctx[:vendor] = current_user
        return true
      end

      vendor = User.find_by(id: params[:vendor_id])
      unless vendor&.vendor?
        ctx[:errors] = { vendor_id: [ "Vendor not found or is not a vendor account" ] }
        return false
      end

      ctx[:vendor] = vendor
    end

    def build_theatre(ctx, params:, vendor:, **)
      ctx[:model] = Theatre.new(
        vendor:         vendor,
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
