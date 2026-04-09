module Api
  module V1
    class VendorsController < ApplicationController
      before_action :authenticate!, only: %i[income shows_summary]

      # GET /api/v1/vendors
      # Public.
      def index
        result = run(::Vendors::Index) do |operation_result|
          return render json: { vendors: ::Vendors::Serializer.many(operation_result[:records]) }
        end

        render_operation_errors(result)
      end

      # GET /api/v1/vendors/:id/income
      # Vendor (self) or Admin.
      def income
        result = run(::Vendors::Income, params:) do |operation_result|
          return render json: ::Vendors::IncomeSerializer.call(operation_result[:vendor], operation_result)
        end

        render_operation_errors(result)
      end

      # GET /api/v1/vendors/:id/shows_summary
      # Vendor (self) or Admin.
      def shows_summary
        result = run(::Vendors::ShowsSummary, params:) do |operation_result|
          return render json: {
            shows: ::Vendors::ShowsSummarySerializer.many(operation_result[:records])
          }, status: :ok
        end

        render_operation_errors(result)
      end
    end
  end
end
