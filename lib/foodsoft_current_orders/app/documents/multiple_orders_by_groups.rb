# encoding: utf-8
class MultipleOrdersByGroups < OrderPdf
  include OrdersHelper

  # optimal value depends on the number of articles ordered on average by each
  #   ordergroup as well as the available memory
  BATCH_SIZE = 50

  attr_reader :order

  def filename
    I18n.t('documents.multiple_orders_by_groups.filename', count: order.count) + '.pdf'
  end

  def title
    I18n.t('documents.multiple_orders_by_groups.title', count: order.count)
  end

  def body
    # Start rendering
    each_ordergroup do |ordergroup|
      down_or_page 15

      totals = {net_price: 0, deposit: 0, gross_price: 0, fc_price: 0, fc_markup_price: 0}
      taxes = Hash.new {0}
      rows = []
      dimrows = []
      has_tolerance = false

      each_group_order_article_for(ordergroup) do |goa|
        has_tolerance = true if goa.order_article.price.unit_quantity > 1
        price = goa.order_article.price
        goa_totals = goa.total_prices(goa.order_article, goa.quantity, goa.tolerance, ordergroup)
        totals[:net_price] += goa_totals[:net_price]
        totals[:deposit] += goa_totals[:deposit]
        totals[:gross_price] += goa_totals[:gross_price]
        totals[:fc_price] += goa_totals[:price]
        totals[:fc_markup_price] += goa_totals[:fc_markup_price]
        taxes[goa.order_article.price.tax.to_f.round(2)] += goa_totals[:fc_tax_price]
        rows <<  [goa.order_article.article.name,
                  goa.group_order.order.name.truncate(10, omission: ''),
                  number_to_currency(price.fc_price(ordergroup)),
                  goa.order_article.article.unit,
                  goa.tolerance > 0 ? "#{goa.quantity} + #{goa.tolerance}" : goa.quantity,
                  goa.result,
                  result_in_units(goa),
                  number_to_currency(goa_totals[:price]),
                  goa.order_article.price.unit_quantity]
        dimrows << rows.length if goa.result == 0
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
      price_details << "#{Article.human_attribute_name :fc_share_short} #{number_to_percentage ordergroup.markup_pct} #{number_to_currency totals[:fc_markup_price]}"
      rows << [{content: ('  ' + price_details.join('; ') if totals[:fc_price] > 0), colspan: 8}, nil]

      # table header
      rows.unshift I18n.t('documents.order_by_groups.rows').dup
      rows.first.insert(1, Article.human_attribute_name(:supplier))
      rows.first[5] = {content: rows.first[5], colspan: 2}
      rows.first[-1] = {image: "#{Rails.root}/app/assets/images/package-bg.png", scale: 0.6, position: :center}

      # last column showing unit_quantity is useless if they're all one
      rows.each {|row| row[-1] = nil} unless has_tolerance

      text show_group(ordergroup), size: fontsize(13), style: :bold
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
        table.row(rows.length-1).height = 0 unless totals[:fc_price] > 0

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
    end
  end

  private

  def pdf_add_page_breaks?
    super 'order_by_groups'
  end

  def ordergroups
    s = Ordergroup.
          joins(:group_orders).
          where(group_orders: {order_id: order}).
          group('groups.id').
          reorder(:name)
    s = s.where(id: @options[:ordergroup]) if @options[:ordergroup]
    s
  end

  def each_ordergroup
    ordergroups.find_in_batches_with_order(batch_size: BATCH_SIZE) do |ordergroups|
      @group_order_article_batch = GroupOrderArticle.
        joins(:group_order).
        where(group_orders: {order_id: order}).
        where(group_orders: {ordergroup_id: ordergroups.map(&:id)}).
        order('group_orders.order_id, group_order_articles.id').
        preload(group_order: {order: :supplier}).
        preload(order_article: [:article, :article_price, :order])
      ordergroups.each {|ordergroup| yield ordergroup }
    end
  end

  def group_order_articles_for(ordergroup)
    @group_order_article_batch.select {|goa| goa.group_order.ordergroup_id == ordergroup.id }
  end

  def each_group_order_article_for(ordergroup)
    group_order_articles_for(ordergroup).each {|goa| yield goa }
  end

end
