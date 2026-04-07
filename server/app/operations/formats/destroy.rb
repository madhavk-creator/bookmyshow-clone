module Formats
  class Destroy < ::Trailblazer::Operation
    step :destroy
    fail :collect_errors

    def destroy(ctx, model:, **)
      model.destroy
    end

    def collect_errors(ctx, model:, **)
      ctx[:errors] ||= model.errors.to_hash(true).presence || { base: [ "Could not delete format" ] }
    end
  end
end
