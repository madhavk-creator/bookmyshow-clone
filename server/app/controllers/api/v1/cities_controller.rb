module Api
  module V1
    class CitiesController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/cities
      # Public. Supports ?state= filter.
      def index
        result = run(Cities::Index, current_user: current_user, params: { state: params[:state] }) do |operation_result|
          return render json: serialize_many(operation_result[:records])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # GET /api/v1/cities/:id
      # Public.
      def show
        city = City.find_by(id: params[:id])
        return not_found unless city

        render json: serialize(city)
      end

      # POST /api/v1/cities
      # Admin or Vendor.
      def create
        authorize City

        result = run(Cities::Create, params: city_params.to_h) do |operation_result|
          return render json: serialize(operation_result[:model]), status: :created
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/cities/:id
      # Admin only (enforced in CityPolicy).
      def update
        city = City.find_by(id: params[:id])
        return not_found unless city

        authorize city

        result = run(Cities::Update, params: city_params.to_h.merge(id: params[:id])) do |operation_result|
          return render json: serialize(operation_result[:model])
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # DELETE /api/v1/cities/:id
      # Admin only.
      def destroy
        city = City.find_by(id: params[:id])
        return not_found unless city

        authorize city

        result = run(Cities::Destroy, params: { id: params[:id] }) do
          return render json: { message: 'City deleted successfully' }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def city_params
        params.require(:city).permit(:name, :state)
      end

      def serialize(city)
        {
          id:    city.id,
          name:  city.name,
          state: city.state
        }
      end

      def serialize_many(cities)
        cities.map { |c| serialize(c) }
      end

      def not_found
        render json: { error: 'City not found' }, status: :not_found
      end
    end
  end
end
