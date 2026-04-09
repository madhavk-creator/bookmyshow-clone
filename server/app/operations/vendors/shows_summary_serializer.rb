module Vendors
  module ShowsSummarySerializer
    module_function

    def call(record)
      record.merge(
        gross_income: record[:gross_income].to_f,
        refund_amount: record[:refund_amount].to_f,
        total_income: record[:total_income].to_f
      )
    end

    def many(records)
      records.map { |record| call(record) }
    end
  end
end
