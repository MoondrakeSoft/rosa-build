module PaginateHelper

  def paginate_params
    per_page = params[:per_page].to_i
    per_page = 20 if per_page < 1
    per_page = 100 if per_page >100
    page = params[:page].to_i
    page = nil if page == 0
    {page: page, per_page: per_page}
  end

  def will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a? Hash
      options, collection_or_options = collection_or_options, nil
    end
    options.merge!(renderer: BootstrapLinkRenderer) unless options[:renderer]
    options.merge!(next_label: I18n.t('datatables.next_label')) unless options[:next_label]
    options.merge!(previous_label: I18n.t('datatables.previous_label')) unless options[:previous_label]
    super *[collection_or_options, options].compact
  end

  def angularjs_paginate(options = {})
    options.reverse_merge!(
      {
        per_page:    params[:per_page].to_i > 0 ? params[:per_page] : 20,
        total_items: 'total_items',
        page:        'page',
        select_page: "goToPage(page)",
        rd_widget_footer: false
      }
    )

    render 'shared/angularjs_paginate', options
  end
end
