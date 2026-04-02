module Api
  module V1
    class LanguagesController < BaseReferenceController
      private

      def model_class       = Language
      def index_operation   = Languages::Index
      def create_operation  = Languages::Create
      def update_operation  = Languages::Update
      def destroy_operation = Languages::Destroy

      def serialize(language)
        { id: language.id, name: language.name, code: language.code }
      end
    end
  end
end
