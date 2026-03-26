module Api
  module V1
    class FormatsController < BaseReferenceController
      private

      def model_class       = Format
      def create_operation  = Format::Create
      def update_operation  = Format::Update
      def destroy_operation = Format::Destroy

      def serialize(format)
        { id: format.id, name: format.name, code: format.code }
      end
    end
  end
end