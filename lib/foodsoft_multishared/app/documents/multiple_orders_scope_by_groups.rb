# encoding: utf-8
class MultipleOrdersScopeByGroups < OrderPdf
  include OrdersHelper

  def filename
    I18n.t('documents.multiple_orders_scope_by_groups.filename', count: @order.count) + '.pdf'
  end

  def title
    I18n.t('documents.multiple_orders_scope_by_groups.title', count: @order.count)
  end

  def scopes
    @scopes ||= Ordergroup.joins(:orders).where(orders: {id: @order}).group('groups.scope').order('groups.scope').count
  end

  def body
    # Start rendering
    scopes.each_pair do |scope, groups_in_scope|

      totals = {net_price: 0, deposit: 0, gross_price: 0, fc_price: 0}
      taxes = Hash.new {0}
      rows = []
      dimrows = []

      order_articles = OrderArticle.joins(group_order_articles: {group_order: :ordergroup}).where('group_order_articles.result > 0').where(groups: {scope: scope}).where(order_id: @order).includes(:article_price, :order).includes(article: :supplier).reorder(:order_id).uniq
      has_tolerance = order_articles.where('article_prices.unit_quantity > 1').any?

      order_articles.each do |order_article|
        goa = rails3_pluck(GroupOrderArticle.joins(group_order: :ordergroup).where(groups: {scope: scope}).where(order_article_id: order_article), ['SUM(group_order_articles.quantity) AS quantity', 'SUM(group_order_articles.tolerance) AS tolerance', 'SUM(group_order_articles.result) AS result']).first
        price = order_article.price
        goas = GroupOrderArticle.joins(group_order: :ordergroup).where(groups: {scope: scope}).where(order_article_id: order_article)
        total_prices = goas.map(&:total_prices)
        goa_totals = Hash[total_prices.first.keys.map {|k| [k, total_prices.collect{|p| p[k]}.sum] }]
        totals[:net_price] += goa_totals[:net_price]
        totals[:deposit] += goa_totals[:deposit]
        totals[:gross_price] += goa_totals[:gross_price]
        totals[:fc_price] += goa_totals[:price]
        taxes[price.tax.to_f.round(2)] += goa_totals[:tax_price]
        rows <<  [order_article.article.name,
                  order_article.order.name.truncate(10, omission: ''),
                  number_to_currency(price.fc_price),
                  order_article.article.unit,
                  goa[:tolerance] > 0 ? "#{goa[:quantity]} + #{goa[:tolerance]}" : goa[:quantity],
                  goa[:result],
                  result_in_units(goa[:result], order_article.article),
                  number_to_currency(goa_totals[:price]),
                  (price.unit_quantity if has_tolerance)]
        dimrows << rows.length if goa[:result] == 0
      end
      next if rows.length == 0

      # total
      rows << [{content: I18n.t('documents.order_by_groups.sum'), colspan: 7}, number_to_currency(totals[:fc_price]), nil]
      # price details
      price_details = []
      price_details << "#{Article.human_attribute_name :price} #{number_to_currency totals[:net_price]}" if totals[:net_price] > 0
      price_details << "#{Article.human_attribute_name :deposit} #{number_to_currency totals[:deposit]}" if totals[:deposit] > 0
      taxes.each do |tax, tax_price|
        price_details << "#{Article.human_attribute_name :tax} #{number_to_percentage tax} #{number_to_currency tax_price}" if tax_price > 0
      end
      price_details << "#{Article.human_attribute_name :fc_share_short} #{number_to_currency (totals[:fc_price]-totals[:gross_price])}"
      rows << [{content: ('  ' + price_details.join('; ') if totals[:fc_price] > 0), colspan: 8}]

      # table header
      rows.unshift I18n.t('documents.order_by_groups.rows').dup
      rows.first.insert(1, Article.human_attribute_name(:supplier))
      rows.first[5] = {content: rows.first[5], colspan: 2}
      if has_tolerance
        rows.first[-1] = {image: "#{Rails.root}/app/assets/images/package-bg.png", scale: 0.6, position: :center}
      else
        rows.first[-1] = nil
      end

      table [[
        {content: scope.to_s, align: :left, size: fontsize(13)},
        {content: "#{groups_in_scope} #{Ordergroup.model_name.human count: groups_in_scope}", size: fontsize(8), align: :right, text_color: '999999'}
      ]], width: bounds.width, cell_style: {font_style: :bold, borders: []}
      if scope.present? and scope != '*' and scope_address = FoodsoftMultishared::get_scope_config(scope)[:contact]
        text FoodsoftMultishared::address_line(scope_address), size: fontsize(8), style: :bold, color: '999999'
      end

      table rows, width: bounds.width, cell_style: {size: fontsize(8), overflow: :shrink_to_fit} do |table|
        # borders
        table.cells.borders = [:bottom]
        table.cells.border_width = 0.02
        table.cells.border_color = 'dddddd'
        table.rows(0).border_width = 1
        table.rows(0).border_color = '666666'
        table.rows(0).column(5).font_style = :bold
        table.row(rows.length-3).border_width = 1
        table.row(rows.length-3).border_color = '666666'
        table.row(rows.length-2).borders = []
        table.row(rows.length-1).borders = []

        # bottom row with price details
        table.row(rows.length-1).text_color = '999999'
        table.row(rows.length-1).size = fontsize(7)
        table.row(rows.length-1).padding = [0, 5, 0, 5]
        table.row(rows.length-1).height = 0 if totals[:fc_price] == 0

        table.column(0).width = 150 # @todo would like to set minimum width here
        table.column(1).width = 62
        table.column(2).align = :right
        table.column(5..7).font_style = :bold
        table.columns(3..5).align = :center
        table.column(6..7).align = :right
        table.column(8).align = :center
        # dim rows not relevant for members
        table.column(4).text_color = '999999'
        table.column(8).text_color = '999999'
        # hide unit_quantity if there's no tolerance anyway
        table.column(-1).width = has_tolerance ? 20 : 0

        # dim rows which were ordered but not received
        dimrows.each do |ri|
          table.row(ri).text_color = 'aaaaaa'
          table.row(ri).columns(0..-1).font_style = nil
        end
      end

      down_or_page 15
    end

  end

  private
  def rails3_pluck(query, *cols)
    cols.each {|col| query = query.select(col)}
    # Rails 3 - http://meltingice.net/2013/06/11/pluck-multiple-columns-rails/
    ActiveRecord::Base.connection.select_all(query).map(&:symbolize_keys)
  end

  def pdf_add_page_breaks?
    super 'order_by_groups'
  end

end
