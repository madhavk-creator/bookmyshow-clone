module Api
  module V1
    class ShowsController < ApplicationController
      before_action :authenticate!, only: %i[create update cancel]

      # GET /api/v1/shows
      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/shows
      # Public. Defaults to scheduled shows only. All filters optional.
      def index
        result = run Shows::Index, params: index_params do |operation_result|
          return render json: {
            shows: Shows::Serializer.many(operation_result[:records]),
            pagination: operation_result[:pagination]
          }, status: :ok
        end

        render_operation_errors(result)
      end

      # GET /api/v1/shows/:id
      # GET /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id
      # Public. Full detail including section prices.
      def show
        result = run Shows::Show, params: show_lookup_params do |operation_result|
          return render json: Shows::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/shows
      def create
        result = run Shows::Create, params: show_params.to_h.deep_symbolize_keys.merge(screen_id: params[:screen_id]) do |operation_result|
          return render json: Shows::Serializer.call(operation_result[:model], detailed: true), status: :created
        end

        render_operation_errors(result)
      end

      # PATCH /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id
      # Only start_time and section_prices are mutable after creation.
      def update
        result = run Shows::Update, params: show_params.to_h.deep_symbolize_keys.merge(id: params[:id], screen_id: params[:screen_id]) do |operation_result|
          return render json: Shows::Serializer.call(operation_result[:model], detailed: true), status: :ok
        end

        render_operation_errors(result)
      end

      # POST /api/v1/theatres/:theatre_id/screens/:screen_id/shows/:id/cancel
      def cancel
        result = run Shows::Cancel, params: { id: params[:id], screen_id: params[:screen_id] } do |operation_result|
          return render json: Shows::Serializer.call(operation_result[:model]), status: :ok
        end

        render_operation_errors(result)
      end

      private

      def index_params
        params.permit(:screen_id, :status, :movie_id, :date, :language, :format, :city_id, :page, :per_page).to_h.deep_symbolize_keys
      end

      def show_lookup_params
        params.permit(:id, :screen_id, :theatre_id).to_h.deep_symbolize_keys
      end

      def show_params
        params.require(:show).permit(
          :movie_id, :seat_layout_id, :movie_language_id,
          :movie_format_id, :start_time,
          section_prices: [ :seat_section_id, :base_price ]
        )
      end

      def render_errors(errors, status: :unprocessable_entity)
        render json: { errors: errors }, status: status
      end

      def render_operation_errors(result)
        render_errors(result[:errors], status: error_status_for(result[:errors]))
      end

      def error_status_for(errors)
        flat_errors = errors.to_h.values.flatten
        return :not_found if flat_errors.include?("Not found") || flat_errors.include?("Show not found")
        return :forbidden if flat_errors.any? { |message| message.to_s.start_with?("Not authorized") }

        :unprocessable_entity
      end

    end
  end
end
