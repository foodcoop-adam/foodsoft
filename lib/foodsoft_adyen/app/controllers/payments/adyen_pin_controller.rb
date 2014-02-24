require 'base64'

class Payments::AdyenPinController < ApplicationController

  layout 'adyen_mobile'

  before_filter :find_ordergroup
  before_filter :find_ordergroups, only: [:index, :created]

  skip_before_filter :authenticate
  before_filter do
    authenticate_or_token(['foodsoft_adyen', 'pin'])
  end

  # show list of ordergroups
  def index
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end

  # open mobile app or index, depending on platform
  def detect
    mode = params[:mode]
    mode = 'mobile' if mode.nil? and FoodsoftAdyen.detect_pin(request)
    if mode == 'mobile'
      # redirect to mobile app to set this foodsoft website as its home
      opts = {
        base: root_url,
        path: 'payments/adyen/pin',
        name: FoodsoftConfig[:name],
        # TODO put user in token, so that we can check he still has access
        token: TokenVerifier.new(['foodsoft_adyen', 'pin']).generate
      }
      redirect_to "foodsoft://set-default?#{opts.to_query}"
    else
      redirect_to payments_adyen_pin_path
    end
  end

  # show form for initiating a new payment
  def new
    #@adyen_pin_url = adyen_pin_url(@ordergroup.id, 4.99, 'hi there')
    create
  end

  # initiate pin payment using Adyen app
  def create
    redirect_to adyen_pin_url(@ordergroup, [-@ordergroup.get_available_funds, 0].max)
  end

  # callback url after payment
  def created
    render :index
  end


  protected

  def find_ordergroup
    @ordergroup = (Ordergroup.find(params[:ordergroup_id]) rescue nil)
  end

  def find_ordergroups
    @ordergroups = Ordergroup.undeleted
    @ordergroups = @ordergroups.where('name LIKE ?', "%#{params[:query]}%") unless params[:query].nil?
  end

  private

  def adyen_pin_url(ordergroup, amount)
    callback = created_payments_adyen_pin_url(:ordergroup_id => ordergroup.id)
    # mobile app wants return path to itself, where it can do the request
    if (params[:mobile_app] or session[:mobile_app]).to_i != 0
      callback = "foodsoft://payment-return/#{ERB::Util.url_encode callback}"
    end
    opts = {
      currency: FoodsoftConfig[:adyen]['currency'],
      amount: (amount * 100).to_i,
      description: FoodsoftAdyen.encode_notification_data({g: ordergroup.id}, ordergroup.name),
      callback: callback,
      callbackAutomatic: 0,
      #start_immediately: 1  # enable this to skip the enter amount screen in the Adyen app
    }
    if FoodsoftAdyen.get_mobile(request) == 'Android'
      return "http://www.adyen.com/android-app/payment?#{opts.to_query}"
    else
      return "adyen://payment?#{opts.to_query}"
    end
  end

end
