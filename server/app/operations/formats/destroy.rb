module Formats
  class Destroy < Trailblazer::Operation
    step :destroy
    fail :collect_errors

    private

    def destroy(ctx, model:, **)
      model.destroy
    end

    def collect_errors(ctx, **)
      ctx[:errors] ||= ctx[:model].errors.to_hash(true)
    end
  end
end
