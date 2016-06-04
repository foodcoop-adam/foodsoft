# encoding: utf-8
class MultipleOrdersByArticles < OrderPdf
  include OrdersHelper

  # optimal value depends on the average number of ordergroups ordering an article
  #   as well as the available memory
  BATCH_SIZE = 50

  attr_reader :order

  def filename
    I18n.t('documents.multiple_orders_by_articles.filename', count: order.count) + '.pdf'
  end

  def title
    I18n.t('documents.multiple_orders_by_articles.title', count: order.count)
  end

  def body
    each_order_article do |order_article|
      down_or_page

      rows = []
      dimrows = []
      has_units_str = ''
      sum_result = 0
      each_group_order_article_for(order_article) do |goa|
        units = result_in_units(goa, order_article.article)
        rows << [goa.group_order.ordergroup.name,
                 goa.tolerance > 0 ? "#{goa.quantity} + #{goa.tolerance}" : goa.quantity,
                 goa.result,
                 units,
                 number_to_currency(goa.total_price(order_article))]
        dimrows << rows.length if goa.result == 0
        has_units_str = units.to_s if units.to_s.length > has_units_str.length # hack for prawn line-breaking units cell
        sum_result += goa.result
      end
      next if rows.length == 0
      rows.unshift I18n.t('documents.order_by_articles.rows').dup # table header
      rows[0][2] = {content: rows[0][2], colspan: 2}

      rows << [I18n.t('documents.order_by_groups.sum'),
               order_article.tolerance > 0 ? "#{order_article.quantity} + #{order_article.tolerance}" : order_article.quantity,
               sum_result,
               result_in_units(sum_result, order_article.article),
               nil] #number_to_currency(sum[:price])]

      text "<b>#{order_article.article.name}</b> " +
           "(#{order_article.article.unit}; #{number_to_currency order_article.price.fc_price}; " +
           units_history_line(order_article, nil, plain: true) + ')',
           size: fontsize(10), inline_format: true
      s = ::OrderByArticles.article_info(order_article.article) and text s, size: fontsize(8), inline_format: true
      table rows, cell_style: {size: fontsize(8), overflow: :shrink_to_fit} do |table|
        # borders
        table.cells.borders = [:bottom]
        table.cells.border_width = 0.02
        table.cells.border_color = 'dddddd'
        table.rows(0).border_width = 1
        table.rows(0).border_color = '666666'
        table.row(rows.length-2).border_width = 1
        table.row(rows.length-2).border_color = '666666'
        table.row(rows.length-1).borders = []

        table.column(0).width = 200
        table.columns(1..2).align = :center
        table.column(2..3).font_style = :bold
        table.columns(3).width = width_of(has_units_str)
        table.columns(3..4).align = :right

        # dim rows which were ordered but not received
        dimrows.each { |ri| table.row(ri).text_color = '999999' }
      end
    end
  end

  protected

  def pdf_add_page_breaks?
    super 'order_by_articles'
  end

  def order_articles
    OrderArticle.where(order_id: order).ordered.
      includes(:article).
      reorder('order_articles.order_id, articles.name').
      preload(:article_price). # preload not join, just in case it went missing
      preload(:order => :supplier, :group_order_articles => {:group_order => :ordergroup})
  end

  def each_order_article
    order_articles.find_each_with_order(batch_size: BATCH_SIZE) {|oa| yield oa }
  end

  def group_order_articles_for(order_article)
    goas = order_article.group_order_articles.to_a
    goas.sort_by! {|goa| goa.group_order.ordergroup.name }
    goas
  end

  def each_group_order_article_for(group_order)
    group_order_articles_for(group_order).each {|goa| yield goa }
  end

end
