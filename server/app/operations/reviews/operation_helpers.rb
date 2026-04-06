module Reviews
  module OperationHelpers
    private

    def extract_errors(error, model)
      record = error.respond_to?(:record) ? error.record : nil
      return record.errors.to_hash(true) if record&.errors&.any?

      model&.errors&.to_hash(true).presence || { base: [ error.message ] }
    end

    def collect_default_errors(ctx, model: nil, fallback: "Request failed", **)
      ctx[:errors] ||= model&.errors&.to_hash(true).presence || { base: [ fallback ] }
    end
  end
end
