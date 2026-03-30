module Api
  module V1
    class TheatresController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/theatres
      # Public. Supports ?city_id= and ?vendor_id= filters.
      def index


        conditions ={}
        conditions[:city_id] = params[:city_id] if params[:city_id].present?
        conditions[:vendor_id] = params[:vendor_id] if params[:vendor_id].present?

        theatres = policy_scope(Theatre)
                     .includes(:city, :vendor)
                      .where(conditions)
                     .order(:name)

        render json: serialize_many(theatres)
      end

      # GET /api/v1/theatres/:id
      # Public.
      def show
        theatre = Theatre.find_by(id: params[:id])
        return not_found unless theatre

        render json: serialize(theatre)
      end

      # POST /api/v1/theatres
      # Vendor or Admin.
      def create
        authorize Theatre

        result = Theatre::Create.call(params: theatre_params.to_h, current_user: current_user)

        if result.success?
          render json: serialize(result[:model]), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/theatres/:id
      # Owning vendor or Admin.
      def update
        theatre = Theatre.find_by(id: params[:id])
        return not_found unless theatre

        authorize theatre

        result = Theatre::Update.call(params: theatre_params.to_h.merge(id: params[:id]))

        if result.success?
          render json: serialize(result[:model])
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/theatres/:id
      # Owning vendor or Admin.
      def destroy
        theatre = Theatre.find_by(id: params[:id])
        return not_found unless theatre

        authorize theatre

        result = Theatre::Destroy.call(params: { id: params[:id] })

        if result.success?
          render json: { message: 'Theatre deleted successfully' }
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      private

      def theatre_params
        params.require(:theatre).permit(
          :name, :building_name, :street_address, :pincode,
          :city_id, :city_name, :city_state
        )
      end

      def serialize(theatre)
        {
          id:             theatre.id,
          vendor_id:      theatre.vendor_id,
          name:           theatre.name,
          building_name:  theatre.building_name,
          street_address: theatre.street_address,
          city:           { id: theatre.city.id, name: theatre.city.name, state: theatre.city.state },
          pincode:        theatre.pincode,
          created_at:     theatre.created_at
        }
      end

      def serialize_many(theatres)
        theatres.map { |t| serialize(t) }
      end

      def not_found
        render json: { error: 'Theatre not found' }, status: :not_found
      end
    end
  end
end
