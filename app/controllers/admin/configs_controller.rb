class Admin::ConfigsController < Admin::BaseController

  before_filter :get_tabs, only: [:show, :list]

  def show
    @current_tab = @tabs.include?(params[:tab]) ? params[:tab] : @tabs.first
    @cfg = FoodsoftConfig
  end

  def list
    @current_tab = 'list'
    @cfg = FoodsoftConfig
    @dfl = FoodsoftConfig.config
    @keys = FoodsoftConfig.keys.select {|k| FoodsoftConfig.allowed_key?(k)}.sort
  end

  def update
    # turn recurring rules into something palatable
    if p = params[:config][:order_schedule]
      for k in [:pickup, :ends] do
        if p[k] and p[k][:recurr]
          p[k][:recurr] = ActiveSupport::JSON.decode(p[k][:recurr])
          p[k][:recurr] = FoodsoftDateUtil.rule_from(p[k][:recurr]).to_ical if p[k][:recurr]
        end
      end
    end
    # store configuration
    ActiveRecord::Base.transaction do
      # TODO support nested configuration keys
      params[:config].each do |key, val|
        FoodsoftConfig[key] = val
      end
    end
    flash[:notice] = I18n.t('admin.configs.update.notice')
    redirect_to action: 'show'
  end

  protected

  # Set configuration tab names as `@tabs`
  def get_tabs
    @tabs = %w(foodcoop schedule membership payment messages layout language others) # removed tasks for now
    # allow engines to modify this list
    engines = Rails::Engine.subclasses.map(&:instance).select { |e| e.respond_to?(:configuration) }
    engines.each { |e| e.configuration(@tabs, self) }
    @tabs.uniq!
  end

end
