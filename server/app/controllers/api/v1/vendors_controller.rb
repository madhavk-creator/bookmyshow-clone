module Api
  module V1
    class VendorsController < ApplicationController
      before_action :authenticate!, only: %i[income]

      # GET /api/v1/vendors
      # Public.
      def index
        result = run(::Vendors::Index) do |operation_result|
          return render json: { vendors: serialize_many(operation_result[:records]) }
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      # GET /api/v1/vendors/:id/income
      # Vendor (self) or Admin.
      def income
        vendor = User.find_by(id: params[:id], role: :vendor)
        return not_found unless vendor

        authorize vendor, :income?

        result = run(::Vendors::Income, vendor: vendor) do |operation_result|
          return render json: serialize_income(vendor, operation_result)
        end

        render json: { errors: result[:errors] }, status: :unprocessable_entity
      end

      private

      def serialize(vendor)
        {
          id: vendor.id,
          name: vendor.name,
          email: vendor.email,
          phone: vendor.phone,
          is_active: vendor.is_active,
          theatres_count: vendor.theatres.size,
          created_at: vendor.created_at
        }
      end

      def serialize_many(vendors) = vendors.map { |vendor| serialize(vendor) }

      def serialize_income(vendor, operation_result)
        {
          vendor: {
            id: vendor.id,
            name: vendor.name,
            email: vendor.email
          },
          theatres_count: operation_result[:theatres_count],
          completed_bookings_count: operation_result[:completed_bookings_count],
          tickets_sold_count: operation_result[:tickets_sold_count],
          gross_income: operation_result[:gross_income].to_s("F"),
          refund_amount: operation_result[:refund_amount].to_s("F"),
          total_income: operation_result[:total_income].to_s("F")
        }
      end

      def not_found = render(json: { error: "Vendor not found" }, status: :not_found)
    end
  end
end
