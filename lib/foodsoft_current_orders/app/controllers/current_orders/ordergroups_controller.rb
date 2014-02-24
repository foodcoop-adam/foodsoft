# encoding: utf-8
class CurrentOrders::OrdergroupsController < ApplicationController
  
  before_filter :authenticate_orders
  before_filter :find_group_orders, only: [:index, :show]

  def index
    @all_ordergroups = Ordergroup.undeleted.order(:name).all
    # sometimes need to pass id as parameter for forms
    if @ordergroup
      render 'show'
    end
  end

  def show
    @all_ordergroups = Ordergroup.undeleted.order(:name).all
  end

  def show_on_group_order_article_create
    @goa = GroupOrderArticle.find(params[:group_order_article_id])
  end

  def show_on_group_order_article_update
    #@goa = GroupOrderArticle.find(params[:group_order_article_id])
    @group_order = GroupOrder.find(params[:group_order_id])
    @ordergroup = @group_order.ordergroup
  end

  protected

  def find_group_orders
    @order_ids = Order.finished_not_closed.map(&:id)
    @ordergroup = Ordergroup.find(params[:id]) unless params[:id].nil?
    @goas = GroupOrderArticle.includes(:group_order, :order_article => [:article, :article_price]).
              where(group_orders: {order_id: @order_ids, ordergroup_id: @ordergroup.id}).ordered.all unless @ordergroup.nil?
  end

end
