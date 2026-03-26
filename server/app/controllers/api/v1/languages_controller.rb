module Api
  module V1
    class LanguagesController < BaseReferenceController
      private

      def model_class       = Language
      def create_operation  = Language::Create
      def update_operation  = Language::Update
      def destroy_operation = Language::Destroy

      def serialize(language)
        { id: language.id, name: language.name, code: language.code }
      end
    end
  end
end