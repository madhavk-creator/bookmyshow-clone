module Api
  module V1
    class ScreensController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]
      before_action :find_theatre

      # GET /api/v1/theatres/:theatre_id/screens
      # Public.
      def index
        result = run(Screens::Index, current_user: current_user, params: { theatre_id: @theatre.id }) do |operation_result|
          return render json: operation_result[:records].map { |screen| serialize(screen) }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # GET /api/v1/theatres/:theatre_id/screens/:id
      # Public.
      def show
        screen = @theatre.screens.find_by(id: params[:id])
        return not_found unless screen

        render json: serialize(screen)
      end

      # POST /api/v1/theatres/:theatre_id/screens
      # Vendor (own theatres) or Admin.
      def create
        authorize Screen

        result = run(
          Screens::Create,
          params:       screen_params.to_h.deep_symbolize_keys.merge(theatre_id: @theatre.id),
          current_user: current_user
        ) do |operation_result|
          return render json: serialize(operation_result[:model]), status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/theatres/:theatre_id/screens/:id
      # Vendor (own theatres) or Admin.
      def update
        screen = @theatre.screens.find_by(id: params[:id])
        return not_found unless screen

        authorize screen

        result = run(
          Screens::Update,
          params: screen_params.to_h.deep_symbolize_keys.merge(id: screen.id)
        ) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # DELETE /api/v1/theatres/:theatre_id/screens/:id
      # Vendor (own theatres) or Admin.
      def destroy
        screen = @theatre.screens.find_by(id: params[:id])
        return not_found unless screen

        authorize screen

        result = run(Screens::Destroy, params: { id: screen.id }) do
          return render json: { message: 'Screen deleted successfully' }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def find_theatre
        @theatre = Theatre.find_by(id: params[:theatre_id])
        render json: { error: 'Theatre not found' }, status: :not_found unless @theatre
      end

      def screen_params
        params.require(:screen).permit(
          :name, :status, :total_rows, :total_columns,
          format_ids: []   # array param
        )
      end

      def serialize(screen)
        {
          id:            screen.id,
          theatre_id:    screen.theatre_id,
          name:          screen.name,
          status:        screen.status,
          total_rows:    screen.total_rows,
          total_columns: screen.total_columns,
          total_seats:   screen.total_seats,
          formats:       screen.formats.map { |f| { id: f.id, name: f.name, code: f.code } },
          created_at:    screen.created_at
        }
      end

      def not_found
        render json: { error: 'Screen not found' }, status: :not_found
      end
    end
  end
end
