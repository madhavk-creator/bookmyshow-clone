module Api
  module V1
    class ScreensController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/theatres/:theatre_id/screens
      # Public.
      def index
        result = run Screens::Index, params: { theatre_id: params[:theatre_id] } do |operation_result|
          return render json: Screens::Serializer.many(operation_result[:records]), status: :ok
        end

        render_operation_errors(result)
      end

      # GET /api/v1/theatres/:theatre_id/screens/:id
      # Public.
      def show
        result = run Screens::Show, params: { theatre_id: params[:theatre_id], id: params[:id] } do |operation_result|
          return render json: Screens::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/theatres/:theatre_id/screens
      # Vendor (own theatres) or Admin.
      def create
        result = run Screens::Create, params: screen_params.to_h.deep_symbolize_keys.merge(theatre_id: params[:theatre_id]) do |operation_result|
          return render json: Screens::Serializer.call(operation_result[:model]), status: :created
        end

        render_operation_errors(result)
      end

      # PATCH /api/v1/theatres/:theatre_id/screens/:id
      # Vendor (own theatres) or Admin.
      def update
        result = run Screens::Update, params: screen_params.to_h.deep_symbolize_keys.merge(theatre_id: params[:theatre_id], id: params[:id]) do |operation_result|
          return render json: Screens::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      # DELETE /api/v1/theatres/:theatre_id/screens/:id
      # Vendor (own theatres) or Admin.
      def destroy
        result = run Screens::Destroy, params: { theatre_id: params[:theatre_id], id: params[:id] } do
          return render json: { message: "Screen deleted successfully" }
        end

        render_operation_errors(result)
      end

      private

      def screen_params
        params.require(:screen).permit(
          :name, :status, :total_rows, :total_columns,
          format_ids: []   # array param
        )
      end
    end
  end
end
