module Api
  module V1
    class CitiesController < ApplicationController
      before_action :authenticate!, only: %i[create update destroy]

      # GET /api/v1/cities
      # Public. Supports ?state= filter.
      def index
        cities = policy_scope(City)
                   .then { |q| params[:state].present? ? q.where(state: params[:state].titleize) : q }
                   .order(:state, :name)

        render json: serialize_many(cities)
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

        result = City::Create.call(params: city_params.to_h)

        if result.success?
          render json: serialize(result[:model]), status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/cities/:id
      # Admin only (enforced in CityPolicy).
      def update
        city = City.find_by(id: params[:id])
        return not_found unless city

        authorize city

        result = City::Update.call(params: city_params.to_h.merge(id: params[:id]))

        if result.success?
          render json: serialize(result[:model])
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/cities/:id
      # Admin only.
      def destroy
        city = City.find_by(id: params[:id])
        return not_found unless city

        authorize city

        result = City::Destroy.call(params: { id: params[:id] })

        if result.success?
          render json: { message: 'City deleted successfully' }
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
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