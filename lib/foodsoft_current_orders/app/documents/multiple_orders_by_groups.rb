# encoding: utf-8
class MultipleOrdersByGroups < OrderPdf

  def filename
    I18n.t('documents.multiple_orders_by_groups.filename', count: @order.count) + '.pdf'
  end

  def title
    I18n.t('documents.multiple_orders_by_groups.title', count: @order.count)
  end

  def body
    # Start rendering
    Ordergroup.joins(:orders).where(:orders => {:id => @order}).select('distinct(groups.id) AS id, groups.name AS name').reorder(:name).each do |ordergroup|

      total = 0
      rows = []
      dimrows = []

      GroupOrderArticle.ordered.joins(:group_order => :order).where(:group_orders =>{:ordergroup_id => ordergroup.id}).where(:orders => {id: @order}).includes(:order_article).reorder('orders.id').each do |goa|
        price = goa.order_article.price.fc_price
        sub_total = price * goa.result
        total += sub_total
        rows <<  [goa.order_article.article.name,
                  goa.order_article.article.unit,
                  goa.group_order.order.name.truncate(10, omission: ''),
                  "#{goa.quantity} + #{goa.tolerance}",
                  goa.result,
                  number_to_currency(price),
                  number_to_currency(sub_total)]
        dimrows << rows.length if goa.result == 0
      end
      next if rows.length == 0
      rows << [I18n.t('documents.order_by_groups.sum'), nil, nil, nil, nil, nil, number_to_currency(total)]
      rows.unshift [OrderArticle.human_attribute_name(:name),
                    OrderArticle.human_attribute_name(:unit),
                    OrderArticle.human_attribute_name(:supplier),
                    I18n.t('shared.articles.ordered'),
                    I18n.t('shared.articles.received'),
                    OrderArticle.human_attribute_name(:price),
                    I18n.t('shared.articles_by.price_sum')]

      text ordergroup.name, size: fontsize(9), style: :bold
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

        table.column(0).width = 180
        table.column(2).width = 60
        table.column(4).font_style = :bold
        table.columns(3..5).align = :right
        table.column(6).align = :right
        table.column(6).font_style = :bold

        # dim rows which were ordered but not received
        dimrows.each { |ri| table.row(ri).text_color = '999999' }
      end

      down_or_page 15
    end

  end
end
