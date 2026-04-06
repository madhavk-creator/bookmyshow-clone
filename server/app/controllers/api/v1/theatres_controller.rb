module Api
  module V1
    class TheatresController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/theatres
      # Public. Supports ?city_id= and ?vendor_id= filters.
      def index
        result = run(
          Theatres::Index,
          current_user: current_user,
          params: {
            city_id: params[:city_id],
            vendor_id: params[:vendor_id],
            page: params[:page],
            per_page: params[:per_page]
          }
        ) do |operation_result|
          return render json: {
            theatres: serialize_many(operation_result[:records]),
            pagination: operation_result[:pagination]
          }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
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

        result = run(Theatres::Create, params: theatre_params.to_h, current_user: current_user) do |operation_result|
          return render json: serialize(operation_result[:model]), status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/theatres/:id
      # Owning vendors or Admin.
      def update
        theatre = Theatre.find_by(id: params[:id])
        return not_found unless theatre

        authorize theatre

        result = run(Theatres::Update, params: theatre_params.to_h.merge(id: params[:id])) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # DELETE /api/v1/theatres/:id
      # Owning vendors or Admin.
      def destroy
        theatre = Theatre.find_by(id: params[:id])
        return not_found unless theatre

        authorize theatre

        result = run(Theatres::Destroy, params: { id: params[:id] }) do
          return render json: { message: "Theatre deleted successfully" }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def theatre_params = params.require(:theatre).permit(
        :name, :building_name, :street_address, :pincode,
        :city_id, :city_name, :city_state, :vendor_id
      )

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

      def serialize_many(theatres) = theatres.map { |t| serialize(t) }

      def not_found = render(json: { error: "Theatre not found" }, status: :not_found)
    end
  end
end
