# encoding: utf-8
class OrderByGroups < OrderPdf

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
      rows = []
      dimrows = []

      group_order_articles = group_order.group_order_articles.ordered
      has_tolerance = !group_order_articles.select {|goa| goa.order_article.price.unit_quantity > 1}.empty?

      group_order_articles.each do |goa|
        price = goa.order_article.price.fc_price(group_order.ordergroup)
        sub_total = price * goa.result
        total += sub_total
        rows <<  [goa.order_article.article.name,
                  goa.order_article.article.unit,
                  goa.tolerance > 0 ? "#{goa.quantity} + #{goa.tolerance}" : goa.quantity,
                  goa.result,
                  number_to_currency(price),
                  number_to_currency(sub_total),
                  (goa.order_article.price.unit_quantity if has_tolerance)]
        dimrows << rows.length if goa.result == 0
      end
      next if rows.length == 0

      # total
      rows << [{content: I18n.t('documents.order_by_groups.sum'), colspan: 5}, number_to_currency(total), nil]

      # table header
      rows.unshift I18n.t('documents.order_by_groups.rows').dup
      if has_tolerance
        rows.first[6] = {image: "#{Rails.root}/app/assets/images/package-bg.png", scale: 0.6, position: :center}
      else
        rows.first[6] = nil
      end

      text group_order.ordergroup.name, size: fontsize(9), style: :bold
      table rows, width: 500, cell_style: {size: fontsize(8), overflow: :shrink_to_fit} do |table|
        # borders
        table.cells.borders = [:bottom]
        table.cells.border_width = 0.02
        table.cells.border_color = 'dddddd'
        table.rows(0).border_width = 1
        table.rows(0).border_color = '666666'
        table.row(rows.length-2).border_width = 1
        table.row(rows.length-2).border_color = '666666'
        table.row(rows.length-1).borders = []

        table.column(0).width = 190
        table.column(3).font_style = :bold
        table.columns(2..5).align = :center
        table.column(4).align = :right
        table.column(5).align = :right
        table.column(5).font_style = :bold
        table.column(6).align = :center
        # dim rows not relevant for members
        table.column(2).text_color = '999999'
        table.column(6).text_color = '999999'
        # hide unit_quantity if there's no tolerance anyway
        table.column(6).width = has_tolerance ? 25 : 0

        # dim rows which were ordered but not received
        dimrows.each { |ri| table.row(ri).text_color = '999999' }
      end

      down_or_page 15
    end

  end
end
