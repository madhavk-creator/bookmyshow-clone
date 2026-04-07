module Api
  module V1
    class TheatresController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/theatres
      # Public. Supports ?city_id= and ?vendor_id= filters.
      def index
        result = run Theatres::Index, params: index_params do |operation_result|
          return render json: {
            theatres: Theatres::Serializer.many(operation_result[:records]),
            pagination: operation_result[:pagination]
          }, status: :ok
        end

        render_operation_errors(result)
      end

      # GET /api/v1/theatres/:id
      # Public.
      def show
        result = run Theatres::Show, params: { id: params[:id] } do |operation_result|
          return render json: Theatres::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/theatres
      # Vendor or Admin.
      def create
        result = run Theatres::Create, params: theatre_params.to_h.deep_symbolize_keys do |operation_result|
          return render json: Theatres::Serializer.call(operation_result[:model]), status: :created
        end

        render_operation_errors(result)
      end

      # PATCH /api/v1/theatres/:id
      # Owning vendors or Admin.
      def update
        result = run Theatres::Update, params: theatre_params.to_h.deep_symbolize_keys.merge(id: params[:id]) do |operation_result|
          return render json: Theatres::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # DELETE /api/v1/theatres/:id
      # Owning vendors or Admin.
      def destroy
        result = run Theatres::Destroy, params: { id: params[:id] } do
          return render json: { message: "Theatre deleted successfully" }
        end

        render_operation_errors(result)
      end

      private

      def theatre_params = params.require(:theatre).permit(
        :name, :building_name, :street_address, :pincode,
        :city_id, :city_name, :city_state, :vendor_id
      )

      def index_params
        params.permit(:city_id, :vendor_id, :page, :per_page).to_h.deep_symbolize_keys
      end

      def render_operation_errors(result)
        errors = result[:errors].presence || { base: [ "Theatre request failed" ] }
        render json: { errors: errors }, status: error_status_for(errors)
      end

      def error_status_for(errors)
        messages = errors.values.flatten.map(&:to_s)
        return :not_found if messages.any? { |message| message.downcase.include?("not found") }
        return :forbidden if messages.any? { |message| message.start_with?("Not authorized") || message == "Forbidden" }

        :unprocessable_entity
      end
    end
  end
end
