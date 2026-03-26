module Api
  module V1
    class BaseReferenceController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/languages  or  /api/v1/formats
      # Public. Optional ?q= search on name.
      def index
        records = policy_scope(model_class).order(:name)
        records = records.where('name ILIKE ?', "%#{params[:q]}%") if params[:q].present?
        render json: records.map { |r| serialize(r) }
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

        result = create_operation.call(params: permitted_params.to_h)

        if result.success?
          render json: serialize(result[:model]), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/languages/:id  or  /api/v1/formats/:id
      # Admin or Vendor.
      def update
        record = model_class.find_by(id: params[:id])
        return not_found unless record

        authorize record

        result = update_operation.call(params: permitted_params.to_h.merge(id: params[:id]))

        if result.success?
          render json: serialize(result[:model])
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/languages/:id  or  /api/v1/formats/:id
      # Admin or Vendor.
      def destroy
        record = model_class.find_by(id: params[:id])
        return not_found unless record

        authorize record

        result = destroy_operation.call(params: { id: params[:id] })

        if result.success?
          render json: { message: "#{model_class.name} deleted successfully" }
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      private

      def model_class       = raise NotImplementedError
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