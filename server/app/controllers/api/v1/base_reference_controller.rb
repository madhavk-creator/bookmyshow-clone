module Api
  module V1
    class BaseReferenceController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/languages  or  /api/v1/formats
      # Public. Optional ?q= search on name.
      def index
        result = run(index_operation, params: index_params) do |operation_result|
          return render json: operation_result[:records].map { |record| serialize(record) }
        end

        render_operation_errors(result)
      end

      # GET /api/v1/languages/:id  or  /api/v1/formats/:id
      # Public.
      def show
        record = model_class.find_by(id: params[:id])
        return not_found unless record

        render json: serialize(record)
      end

      # POST /api/v1/languages  or  /api/v1/formats
      # Admin or Vendor.
      def create
        result = run(create_operation, params: permitted_params.to_h.deep_symbolize_keys) do |operation_result|
          return render json: serialize(operation_result[:model]), status: :created
        end

        render_operation_errors(result)
      end

      # PATCH /api/v1/languages/:id  or  /api/v1/formats/:id
      # Admin or Vendor.
      def update
        result = run(
          update_operation,
          params: permitted_params.to_h.deep_symbolize_keys.merge(id: params[:id])
        ) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render_operation_errors(result)
      end

      # DELETE /api/v1/languages/:id  or  /api/v1/formats/:id
      # Admin or Vendor.
      def destroy
        result = run(destroy_operation, params: { id: params[:id] }) do
          return render json: { message: "#{model_class.name} deleted successfully" }
        end

        render_operation_errors(result)
      end

      private

      def model_class       = raise NotImplementedError

      def index_operation   = raise NotImplementedError

      def create_operation  = raise NotImplementedError

      def update_operation  = raise NotImplementedError

      def destroy_operation = raise NotImplementedError

      def serialize(_)      = raise NotImplementedError

      def permitted_params = params.require(model_class.name.downcase.to_sym).permit(:name, :code)
        
      def index_params = params.permit(:q).to_h.deep_symbolize_keys

      def render_operation_errors(result)
        errors = result[:errors].presence || { base: [ "#{model_class.name} operation failed" ] }
        render json: { errors: errors }, status: error_status_for(errors)
      end

      def error_status_for(errors)
        flat_errors = errors.to_h.values.flatten.map(&:to_s)
        return :not_found if flat_errors.any? { |message| message.downcase.include?("not found") }
        return :forbidden if flat_errors.any? { |message| message.downcase.start_with?("not authorized") || message.downcase == "forbidden" }

        :unprocessable_entity
      end

      def not_found = render(json: { error: "#{model_class.name} not found" }, status: :not_found)
    end
  end
end
