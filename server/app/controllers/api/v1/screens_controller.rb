module Api
  module V1
    class ScreensController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]
      before_action :find_theatre

      # GET /api/v1/theatres/:theatre_id/screens
      # Public.
      def index
        screens = policy_scope(Screen)
                    .where(theatre: @theatre)
                    .includes(:formats)
                    .order(:name)

        render json: screens.map { |s| serialize(s) }
      end

      # GET /api/v1/theatres/:theatre_id/screens/:id
      # Public.
      def show
        screen = @theatre.screens.find_by(id: params[:id])
        return not_found unless screen

        render json: serialize(screen)
      end

      # POST /api/v1/theatres/:theatre_id/screens
      # Vendor (own theatre) or Admin.
      def create
        authorize Screen

        result = Screen::Create.call(
          params:       screen_params.to_h.merge(theatre_id: @theatre.id),
          current_user: current_user
        )

        if result.success?
          render json: serialize(result[:model]), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/theatres/:theatre_id/screens/:id
      # Vendor (own theatre) or Admin.
      def update
        screen = @theatre.screens.find_by(id: params[:id])
        return not_found unless screen

        authorize screen

        result = Screen::Update.call(
          params: screen_params.to_h.merge(id: screen.id)
        )

        if result.success?
          render json: serialize(result[:model])
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/theatres/:theatre_id/screens/:id
      # Vendor (own theatre) or Admin.
      def destroy
        screen = @theatre.screens.find_by(id: params[:id])
        return not_found unless screen

        authorize screen

        result = Screen::Destroy.call(params: { id: screen.id })

        if result.success?
          render json: { message: 'Screen deleted successfully' }
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
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