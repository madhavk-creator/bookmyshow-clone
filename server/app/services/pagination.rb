module Pagination
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 50

  module_function

  def page(params)
    value = params[:page].to_i
    value > 0 ? value : 1
  end

  def per_page(params)
    value = params[:per_page].to_i
    value = DEFAULT_PER_PAGE if value <= 0
    [ value, MAX_PER_PAGE ].min
  end

  def apply(scope, params)
    current_page = page(params)
    current_per_page = per_page(params)
    total_count = scope.count
    total_pages = (total_count.to_f / current_per_page).ceil

    [
      scope.offset((current_page - 1) * current_per_page).limit(current_per_page),
      {
        page: current_page,
        per_page: current_per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    ]
  end
end
