# encoding: utf-8
module OrdersHelper

  def update_articles_link(order, text, view, options={})
    options = {remote: true, id: "view_#{view}_btn", class: ''}.merge(options)
    options[:class] += ' active' if view.to_s == @view.to_s
    link_to text, order_path(order, view: view), options
  end

  # @param order [Order]
  # @param document [String] Document to display, one of +groups+, +articles+, +fax+, +matrix+
  # @param text [String] Link text
  # @return [String] Link to order document
  # @see OrdersController#show
  def order_pdf(order, document, text)
    link_to text, order_path(order, document: document, format: :pdf), title: I18n.t('helpers.orders.order_pdf')
  end

  def options_for_suppliers_to_select
    options = [[I18n.t('helpers.orders.option_choose')]]
    options += Supplier.all.map {|s| [ s.name, url_for(action: "new", supplier_id: s)] }
    options += [[I18n.t('helpers.orders.option_stock'), url_for(action: 'new', supplier_id: 0)]]
    options_for_select(options)
  end

  # "1×2 ordered, 2×2 billed, 2×2 received"
  def units_history_line(order_article, order=nil, options={})
    order ||= order_article.order
    if order.open?
      nil
    else
      units_info = []
      [:units_to_order, :units_billed, :units_received].map do |unit|
        if n = order_article.send(unit)
          line = n.to_s + ' '
          line += pkg_helper(order_article.price, options) + ' ' unless n == 0
          line += OrderArticle.human_attribute_name("#{unit}_short", count: n)
          units_info << line
        end
      end
      units_info.join(', ').html_safe
    end
  end

  # @param article [Article]
  # @option options [String] :icon +false+ to hide the icon
  # @option options [String] :plain +true+ to not use HTML (implies +icon+=+false+)
  # @option options [String] :soft_uq +true+ to hide unit quantity specifier on small screens.
  #   Sensible in tables with multiple columns.
  # @return [String] Text showing unit and unit quantity when applicable.
  def pkg_helper(article, options={})
    return '' if not article or article.unit_quantity == 1
    uq_text = "× #{article.unit_quantity}"
    uq_text = content_tag(:span, uq_text, class: 'hidden-phone') if options[:soft_uq]
    if options[:plain]
      uq_text
    elsif options[:icon].nil? or options[:icon]
      pkg_helper_icon(uq_text)
    else
      pkg_helper_icon(uq_text, tag: :span)
    end
  end
  # @param c [Symbol, String] Tag to use
  # @option options [String] :class CSS class(es) (in addition to +package+)
  # @return [String] Icon used for displaying the unit quantity
  def pkg_helper_icon(c=nil, options={})
    options = {tag: 'i', class: ''}.merge(options)
    if c.nil?
      c = "&nbsp;".html_safe
      options[:class] += " icon-only"
    end
    content_tag(options[:tag], c, class: "package #{options[:class]}").html_safe
  end
  
  def article_price_change_hint(order_article, gross=false)
    return nil if order_article.article.price == order_article.price.price
    title = "#{t('helpers.orders.old_price')}: #{number_to_currency order_article.article.price}"
    title += " / #{number_to_currency order_article.article.gross_price}" if gross
    content_tag(:i, nil, class: 'icon-asterisk', title: j(title)).html_safe
  end
  
  def receive_input_field(form)
    order_article = form.object
    units_expected = (order_article.units_billed or order_article.units_to_order) *
      1.0 * order_article.article.unit_quantity / order_article.article_price.unit_quantity
    
    input_classes = 'input input-nano units_received'
    input_classes += ' package' unless order_article.article_price.unit_quantity == 1
    input_html = form.text_field :units_received, class: input_classes,
      data: {'units-expected' => units_expected},
      disabled: order_article.result_manually_changed?,
      autocomplete: 'off'
    
    if order_article.result_manually_changed?
      input_html = content_tag(:span, class: 'input-prepend intable', title: t('.field_locked_title', default: '')) {
        button_tag(nil, type: :button, class: 'btn unlocker') {
          content_tag(:i, nil, class: 'icon icon-unlock')
        } + input_html
      }
    end

    input_html.html_safe
  end

  # @param order [Order]
  # @return [String] Number of ordergroups participating in order with groups in title.
  def ordergroup_count(order)
    group_orders = order.group_orders.includes(:ordergroup)
    txt = "#{group_orders.count} #{Ordergroup.model_name.human count: group_orders.count}"
    if group_orders.count == 0
      return txt
    else
      desc = group_orders.all.map {|g| show_group(g.ordergroup)}.join(', ')
      content_tag(:abbr, txt, title: desc).html_safe
    end
  end

  # @param order_or_supplier [Order, Supplier] Order or supplier to link to
  # @return [String] Link to order or supplier, showing its name.
  def supplier_link(order_or_supplier)
    if order_or_supplier.kind_of?(Order) and order_or_supplier.stockit?
      link_to(order_or_supplier.name, stock_articles_path).html_safe
    else
      order_or_supplier = order_or_supplier.supplier if order_or_supplier.kind_of?(Order)
      link_to(order_or_supplier.name, supplier_path(order_or_supplier)).html_safe
    end
  end

  def order_checks(order)
    result = [] # array of [true/false/:warn/nil, message]
    # need articles to order
    if order.order_articles.ordered.count == 0
      result << [false, I18n.t('helpers.orders.order_checks.none_ordered', count: order.order_articles.ordered.count)]
    elsif not order.stockit?
      # minimum order quantity
      case order.min_order_quantity_reached
      when true # satisfied
        result << [true, I18n.t('helpers.orders.order_checks.min_quantity_reached', sum: number_to_currency(order.sum(:gross)),
                                min_quantity: number_to_currency(order.supplier.min_order_quantity_price)) ]
      when false # present but not satisfied
        result << [false, I18n.t('helpers.orders.order_checks.min_quantity_not_reached', sum: number_to_currency(order.sum(:gross)),
                                min_quantity: number_to_currency(order.supplier.min_order_quantity_price)) ]
      else if not order.supplier.min_order_quantity.blank? # present, but as free-form text
        result << [:warn, I18n.t('helpers.orders.order_checks.min_quantity_check', text: order.supplier.min_order_quantity,
                                link: link_to(I18n.t('helpers.orders.order_checks.min_quantity_check_link'), order_path(order)))]
      else
        # not filled in for supplier, don't show anything
      end end
    end

    result
  end

  # @param order_article [OrderArticle]
  # @return [String] CSS class for +OrderArticle+ in table for admins (+used+, +partused+, +unused+ or +unavailable+).
  def order_article_class(order_article)
    if order_article.units > 0
      if order_article.missing_units == 0
        'used'
      else
        'partused'
      end
    elsif order_article.quantity > 0
      'unused'
    else
      'unavailable'
    end
  end

  # Returns article result in units when relevant.
  #
  #   Result    Article unit     Return value
  #   ------    ------------     ------------
  #   6         0.5 kg           3 kg
  #   2         1 pc             (nil)
  #   2         3 pc             6 pc
  #   0         (anything)       (nil)
  #   8         Foo bar          (nil)
  #   2         50 ml            100 ml
  #
  # @param group_order_article [GroupOrderArticle, Number] Group order article to get result from, the the result as number.
  # @param article [Article] Article (to retrieve unit), or +nil+ to get from +group_order_article+.
  # @option options [Symbol] :type See {GroupOrderArticle#result}.
  # @return [String] Article result in units or +nil+.
  # @see GroupOrderArticle#result
  def result_in_units(group_order_article, article = nil, options = {})
    article ||= group_order_article.order_article.article
    r = group_order_article
    r = r.result(options[:type] || :total) if r.is_a? GroupOrderArticle
    unit = (::Unit.new(article.unit) rescue nil)
    # nothing at all
    if r == 0
      nil
    # no unit, we can't give info
    elsif unit.nil?
      nil
    # if the unit is one piece, it gives no more information
    elsif unit.scalar == 1 and unit =~ 'piece'
      nil
    # now we know the total in base units is useful to show
    else
      unit * r
    end
  end

end
