# encoding: utf-8
class MultipleOrdersByArticles < OrderPdf

  include OrdersHelper

  def filename
    I18n.t('documents.multiple_orders_by_articles.filename', count: @order.count) + '.pdf'
  end

  def title
    I18n.t('documents.multiple_orders_by_articles.title', count: @order.count)
  end

  def body
    OrderArticle.joins(:order, :article).where(:orders => {:id => @order}).ordered.order('orders.id, articles.name').each do |order_article|

      rows = []
      dimrows = []

      for goa in order_article.group_order_articles.ordered
        rows << [goa.group_order.ordergroup.name,
                 "#{goa.quantity} + #{goa.tolerance}",
                 goa.result,
                 number_to_currency(order_article.price.fc_price * goa.result)]
        dimrows << rows.length if goa.result == 0
      end
      next if rows.length == 0
      sum = order_article.group_orders_sum
      rows << [I18n.t('documents.order_by_groups.sum'),
               "#{order_article.quantity} + #{order_article.tolerance}",
               sum[:quantity],
               nil] #number_to_currency(sum[:price])]
      rows.unshift [GroupOrder.human_attribute_name(:ordergroup),
                    I18n.t('shared.articles.ordered'),
                    I18n.t('shared.articles.received'),
                    I18n.t('shared.articles_by.price_sum')]


      text "<b>#{order_article.article.name}</b> " +
           "(#{order_article.article.unit}, #{number_to_currency order_article.price.fc_price}, " +
           units_history_line(order_article, plain: true) + ')',
           size: fontsize(10), inline_format: true
      table rows, cell_style: {size: fontsize(8), overflow: :shrink_to_fit} do |table|
        table.cells.borders = [:bottom]
        table.cells.border_width = 0.02
        table.cells.border_color = 'dddddd'
        table.rows(0).border_width = 1
        table.rows(0).border_color = '666666'
        table.row(rows.length-2).border_width = 1
        table.row(rows.length-2).border_color = '666666'
        table.row(rows.length-1).borders = []

        table.column(0).width = 200
        table.columns(1..3).align = :right
        table.column(2).font_style = :bold

        # dim rows which were ordered but not received
        dimrows.each { |ri| table.row(ri).text_color = '999999' }
      end

      down_or_page 15
    end
  end

end
