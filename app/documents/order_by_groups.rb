# encoding: utf-8
class OrderByGroups < OrderPdf
  include OrdersHelper

  def filename
    I18n.t('documents.order_by_groups.filename', :name => @order.name, :date => @order.ends.to_date) + '.pdf'
  end

  def title
    I18n.t('documents.order_by_groups.title', :name => @order.name,
      :date => @order.ends.strftime(I18n.t('date.formats.default')))
  end

  def body
    # Start rendering
    @order.group_orders.ordered.each do |group_order|
      total = 0
      taxes = Hash.new {0}
      rows = []
      dimrows = []

      group_order_articles = group_order.group_order_articles.ordered
      has_tolerance = !group_order_articles.select {|goa| goa.order_article.price.unit_quantity > 1}.empty?

      group_order_articles.each do |goa|
        price = goa.order_article.price.fc_price(group_order.ordergroup)
        sub_total = price * goa.result
        total += sub_total
        taxes[goa.order_article.price.tax.to_f.round(2)] += goa.result * goa.order_article.price.tax_price
        rows <<  [goa.order_article.article.name,
                  number_to_currency(price),
                  goa.order_article.article.unit,
                  goa.tolerance > 0 ? "#{goa.quantity} + #{goa.tolerance}" : goa.quantity,
                  goa.result,
                  result_in_units(goa),
                  number_to_currency(sub_total),
                  (goa.order_article.price.unit_quantity if has_tolerance)]
        dimrows << rows.length if goa.result == 0
      end
      next if rows.length == 0

      # total
      rows << [{content: I18n.t('documents.order_by_groups.sum'), colspan: 6}, number_to_currency(total), nil]
      # price details (old orders may not have these details set)
      price_details = []
      price_details << "#{Article.human_attribute_name :price} #{number_to_currency group_order.net_price}" if group_order.net_price > 0
      price_details << "#{Article.human_attribute_name :deposit} #{number_to_currency group_order.deposit}" if group_order.deposit.to_f > 0
      taxes.each do |tax, tax_price|
        price_details << "#{Article.human_attribute_name :tax} #{number_to_percentage tax} #{number_to_currency tax_price}" if tax_price > 0
      end
      price_details << "#{Article.human_attribute_name :fc_share_short} #{number_to_percentage group_order.ordergroup.markup_pct} #{number_to_currency (group_order.price - group_order.gross_price)}" if group_order.gross_price > 0
      rows << [{content: '  ' + price_details.join('; '), colspan: 7}]

      # table header
      rows.unshift I18n.t('documents.order_by_groups.rows').dup
      rows.first[4] = {content: rows.first[4], colspan: 2}
      if has_tolerance
        rows.first[-1] = {image: "#{Rails.root}/app/assets/images/package-bg.png", scale: 0.6, position: :center}
      else
        rows.first[-1] = nil
      end

      text show_group(group_order.ordergroup), size: fontsize(13), style: :bold
      table rows, width: bounds.width, cell_style: {size: fontsize(8), overflow: :shrink_to_fit} do |table|
        # borders
        table.cells.borders = [:bottom]
        table.cells.border_width = 0.02
        table.cells.border_color = 'dddddd'
        table.rows(0).border_width = 1
        table.rows(0).border_color = '666666'
        table.rows(0).column(4).font_style = :bold
        table.row(rows.length-3).border_width = 1
        table.row(rows.length-3).border_color = '666666'
        table.row(rows.length-2).borders = []
        table.row(rows.length-1).borders = []

        # bottom row with price details
        table.row(rows.length-1).text_color = '999999'
        table.row(rows.length-1).size = fontsize(7)
        table.row(rows.length-1).padding = [0, 5, 0, 5]

        table.column(0).width = 200 # @todo would like to set minimum width here
        table.column(1).align = :right
        table.columns(2..4).align = :center
        table.columns(4..6).font_style = :bold
        table.columns(5..6).align = :right
        table.column(7).align = :center
        # dim columns not relevant for members
        table.column(3).text_color = '999999'
        table.column(7).text_color = '999999'
        # hide unit_quantity if there's no tolerance anyway
        table.column(7).width = has_tolerance ? 25 : 0

        # dim rows which were ordered but not received
        dimrows.each do |ri|
          table.row(ri).text_color = 'aaaaaa'
          table.row(ri).columns(0..-1).font_style = nil
        end
      end

      down_or_page 15
    end

  end
end
