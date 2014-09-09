class PayordersController < GroupOrdersController

  def confirm
    # always confirm currently open orders
    GroupOrderArticleQuantity.confirm_open!(@current_user.ordergroup)
    # redirect to current orders or specified page
    return_to = params[:return_to]
    if return_to.present? and (return_to.starts_with?(root_path) or return_to.starts_with?(root_url))
      redirect_to return_to
    else
      redirect_to group_order_path(:current)
    end
  end

end
