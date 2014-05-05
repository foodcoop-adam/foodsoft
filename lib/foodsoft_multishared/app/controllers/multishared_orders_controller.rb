class MultisharedOrdersController < ApplicationController

  before_filter :authenticate_orders

  def foodcoop_doc
    @order_ids = if params[:id] and params[:id] != 'current'
                   params[:id].split('+').map(&:to_i)
                 else
                   Order.finished_not_closed.all.map(&:id)
                 end
    @view = (params[:view] or 'default').gsub(/[^-_a-zA-Z0-9]/, '')

    respond_to do |format|
      format.pdf do
        pdf = case params[:document]
                  when 'groups' then MultipleOrdersScopeByGroups.new(@order_ids)
                  when 'articles' then MultipleOrdersScopeByArticles.new(@order_ids)
              end
        send_data pdf.to_pdf, filename: pdf.filename, type: 'application/pdf'
      end
    end
  end

end
