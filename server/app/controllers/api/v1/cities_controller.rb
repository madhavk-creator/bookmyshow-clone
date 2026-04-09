module Api
  module V1
    class CitiesController < BaseReferenceController
      private

      def model_class       = City
      def index_operation   = Cities::Index
      def create_operation  = Cities::Create
      def update_operation  = Cities::Update
      def destroy_operation = Cities::Destroy

      def serialize(city)
        {
          id: city.id,
          name: city.name,
          state: city.state
        }
      end

      def permitted_params = params.require(:city).permit(:name, :state)
      def index_params = params.permit(:state, city: {}).to_h.deep_symbolize_keys
    end
  end
end
