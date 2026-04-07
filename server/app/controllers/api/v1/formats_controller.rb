module Api
  module V1
    class FormatsController < BaseReferenceController
      private

      def model_class       = Format
      def index_operation   = Formats::Index
      def create_operation  = Formats::Create
      def update_operation  = Formats::Update
      def destroy_operation = Formats::Destroy

      def serialize(format) = { id: format.id, name: format.name, code: format.code }
    end
  end
end
