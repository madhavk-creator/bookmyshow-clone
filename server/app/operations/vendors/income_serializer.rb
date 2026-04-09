module Vendors
  module IncomeSerializer
    module_function

    def call(vendor, result)
      {
        vendor: {
          id: vendor.id,
          name: vendor.name,
          email: vendor.email
        },
        theatres_count: result[:theatres_count],
        completed_bookings_count: result[:completed_bookings_count],
        tickets_sold_count: result[:tickets_sold_count],
        gross_income: result[:gross_income].to_f,
        refund_amount: result[:refund_amount].to_f,
        total_income: result[:total_income].to_f
      }
    end
  end
end
