module Api
  module V1
    class BaseReferenceController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/languages  or  /api/v1/formats
      # Public. Optional ?q= search on name.
      def index
        result = run(index_operation, current_user: current_user, params: { q: params[:q] }) do |operation_result|
          return render json: operation_result[:records].map { |record| serialize(record) }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
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
        authorize model_class

        result = run(create_operation, params: permitted_params.to_h) do |operation_result|
          return render json: serialize(operation_result[:model]), status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/languages/:id  or  /api/v1/formats/:id
      # Admin or Vendor.
      def update
        record = model_class.find_by(id: params[:id])
        return not_found unless record

        authorize record

        result = run(
          update_operation,
          params: permitted_params.to_h, 
          model: record 
        ) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # DELETE /api/v1/languages/:id  or  /api/v1/formats/:id
      # Admin or Vendor.
      def destroy
        record = model_class.find_by(id: params[:id])
        return not_found unless record

        authorize record

        result = run(destroy_operation, model: record) do
          return render json: { message: "#{model_class.name} deleted successfully" }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def model_class       = raise NotImplementedError
      def index_operation   = raise NotImplementedError
      def create_operation  = raise NotImplementedError
      def update_operation  = raise NotImplementedError
      def destroy_operation = raise NotImplementedError
      def serialize(_)      = raise NotImplementedError

      def permitted_params
        params.require(model_class.name.downcase.to_sym).permit(:name, :code)
      end

      def not_found
        render json: { error: "#{model_class.name} not found" }, status: :not_found
      end
    end
  end
end
