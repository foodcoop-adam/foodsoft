# encoding: utf-8
class OrderFax < OrderPdf

  def filename
    I18n.t('documents.order_fax.filename', foodcoop: FoodsoftConfig[:name], supplier: @order.name, date: @order.ends.to_date) + '.pdf'
  end

  def title
    false
  end

  def body
    contact = FoodsoftConfig[:contact].symbolize_keys

    # From paragraph
    bounding_box [margin_box.right-200,margin_box.top], width: 200 do
      text FoodsoftConfig[:name], size: fontsize(9), align: :right
      move_down 5
      text contact[:street], size: fontsize(9), align: :right
      move_down 5
      text "#{contact[:zip_code]} #{contact[:city]}", size: fontsize(9), align: :right
      move_down 5
      unless @order.supplier.try(:customer_number).blank?
        text "#{Supplier.human_attribute_name :customer_number}: #{@order.supplier[:customer_number]}", size: fontsize(9), align: :right
        move_down 5
      end
      unless contact[:phone].blank?
        text "#{Supplier.human_attribute_name :phone}: #{contact[:phone]}", size: fontsize(9), align: :right
        move_down 5
      end
      unless contact[:email].blank?
        text "#{Supplier.human_attribute_name :email}: #{contact[:email]}", size: fontsize(9), align: :right
      end
    end

    # Recipient
    bounding_box [margin_box.left,margin_box.top-60], width: 200 do
      text @order.name
      move_down 5
      text @order.supplier.try(:address).to_s
      unless @order.supplier.try(:fax).blank?
        move_down 5
        text "#{Supplier.human_attribute_name :fax}: #{@order.supplier[:fax]}"
      end
    end

    text I18n.t('documents.order_fax.date', date: Date.today.strftime(I18n.t('date.formats.default'))), align: :right, size: fontsize(9)
    move_down 5

    if @options[:delivered_before]
      move_down 10
      date = @options[:delivered_before]
      date = format_time(date) if date.kind_of? Time
      text I18n.t('mailer.order_result_supplier.line_delivered_before', when: date)
      if @options[:order_contact_name]
        text I18n.t('mailer.order_result_supplier.line_delivered_before_note', name: @options[:order_contact_name]), size: 9, color: '444444'
      end
      move_down 10
    end

    unless @options[:order_contact_name] or @options[:delivery_contact_name]
      # legacy, this is confusing when we have an order and delivery contact
      contact = @order.supplier.try(:contact_person)
      unless contact.blank?
        text "#{Supplier.human_attribute_name :contact_person}: #{@order.supplier[:contact_person]}"
        move_down 10
      end
    end

    contact = @options[:order_contact_name]
    unless contact.blank?
      text I18n.t('mailer.order_result_supplier.line_order_contact', name: contact, phone: @options[:order_contact_phone])
      move_down 10
    end
    contact = @options[:delivery_contact_name]
    unless contact.blank?
      text I18n.t('mailer.order_result_supplier.line_delivery_contact', name: contact, phone: @options[:delivery_contact_phone])
      move_down 10
    end

    # Articles
    total_net = total_deposit = total_tax = total_gross = 0
    data = [[
      Article.human_attribute_name(:order_number_short),
      Article.human_attribute_name(:name),
      I18n.t('documents.order_fax.price'),
      Article.human_attribute_name(:deposit),
      Article.human_attribute_name(:tax),
      Article.human_attribute_name(:unit),
      {image: "#{Rails.root}/app/assets/images/package-bg.png", scale: 0.6, position: :center},
      OrderArticle.human_attribute_name(:units_to_order_short),
      I18n.t('documents.order_fax.subtotal')]]
    data += @order.order_articles.ordered.all(include: :article).collect do |a|
      subtotal = a.units_to_order * a.price.unit_quantity * a.price.price
      total_net += subtotal
      total_deposit += a.units_to_order * a.price.unit_quantity * a.price.deposit
      total_tax += a.units_to_order * a.price.unit_quantity * a.price.tax_price
      total_gross += a.units_to_order * a.price.unit_quantity * a.price.gross_price
      [a.article.order_number,
       a.article.name,
       number_to_currency(a.price.price),
       a.price.deposit != 0 ? number_to_currency(a.price.deposit) : nil,
       number_to_percentage(a.price.tax),
       a.article.unit,
       a.article.unit_quantity > 1 ? "× #{a.article.unit_quantity}" : nil,
       a.units_to_order,
       number_to_currency(subtotal)]
    end

    # Hide columns if no data present
    data[0][3] = nil unless data[1..-1].select {|r| r[3].present?}.any?
    data[0][6] = nil unless data[1..-1].select {|r| r[6].present?}.any?

    foot = []
    foot << [{colspan: 8, content: I18n.t('documents.order_fax.total_net')}, number_to_currency(total_net)]
    foot << [{colspan: 8, content: Article.human_attribute_name(:deposit)}, number_to_currency(total_deposit)] if total_deposit > 0
    foot << [{colspan: 8, content: Article.human_attribute_name(:tax)}, number_to_currency(total_tax)] if total_tax > 0
    foot << [{colspan: 8, content: I18n.t('documents.order_fax.total_gross')}, number_to_currency(total_gross)] if total_gross != total_net

    table data+foot, cell_style: {size: fontsize(8), overflow: :shrink_to_fit} do
      cells.borders        = [:bottom]
      cells.border_width   = 0.02
      cells.border_color   = 'dddddd'

      header = true
      rows(0).border_width   = 1
      rows(0).border_color   = '666666'
      rows(0).font_style     = :bold
      row(-foot.count).borders      = [:top]
      row(-foot.count).border_width = 1
      row(-foot.count).border_color = '666666'
      row(-foot.count).font_style   = :bold
      row(-1).font_style            = :bold
      rows((-foot.count+1)..-1).borders     = [] unless foot.count==1
      rows((-foot.count+2)..-1).padding_top = 0 unless foot.count==1

      columns(5).align        = :right
      columns(6).padding_left = 0
      columns(7).font_style   = :bold
      columns(7).align        = :center
      columns(7).rows(0..(-foot.count-1)).background_color = 'eeeeee'
      columns(2..4).align     = :right
      columns(-1).align       = :right
    end
  end

end
