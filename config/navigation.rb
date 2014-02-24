# -*- coding: utf-8 -*-
# Configures your navigation

SimpleNavigation::Configuration.run do |navigation|

  # allow engines to add to the menu - https://gist.github.com/mjtko/4873ee0c112b6bd646f8
  engines = Rails.application.railties.engines.select { |e| e.respond_to?(:navigation) }
  # to include an engine but keep it from modifying the menu:
  #engines.reject! { |e| e.instance_of? FoodsoftMyplugin::Engine }

  detect_pin = Proc.new { FoodsoftAdyen.detect_pin(request) if defined? FoodsoftAdyen }

  navigation.items do |primary|
    primary.dom_class = 'nav'

    # TODO get rid of 'id: nil' on every line - somehow simple_navigation creates them by default, breaking stuff

    #primary.item :dashboard_nav_item, I18n.t('navigation.dashboard'), root_path(anchor: '')

    primary.item :prepare, I18n.t('navigation.stage.prepare'), '#', id: nil,
                 highlights_on: %r[/(orders(?!.*/receive)|suppliers)\b] do |subnav|
      subnav.item :suppliers, I18n.t('navigation.suppliers'), suppliers_path, id: nil
      subnav.item :orders, I18n.t('navigation.orders.title'), orders_path, id: nil, if: Proc.new { current_user.role_orders? }
    end

    primary.item :distribute, I18n.t('navigation.stage.distribute'), '#', id: nil,
                 highlights_on: %r[/(current_orders/articles|current_orders/receive|orders/.*/receive)\b],
                 if: Proc.new { current_user.role_orders? } do |subnav|
      subnav.item :receive, I18n.t('navigation.receive'), receive_current_orders_orders_path, id: nil
      subnav.item :order_articles, I18n.t('navigation.current_orders.articles'), current_orders_articles_path, id: nil
    end

    primary.item :pickup, I18n.t('navigation.stage.pickup'), '#', id: nil,
                 highlights_on: %r[/(current_orders/ordergroups)\b],
                 if: Proc.new { current_user.role_orders? or current_user.role_finance? } do |subnav|
      subnav.item :member_orders, I18n.t('navigation.current_orders.ordergroups'), current_orders_ordergroups_path, id: nil
      # PIN on mobile, member payments otherwise
      subnav.item :pin_terminal, 'PIN', detect_payments_adyen_pin_path, id: nil, if: Proc.new { detect_pin.call } if defined? FoodsoftAdyen
      subnav.item :accounts, I18n.t('navigation.member_payments'), finance_ordergroups_path, id: nil, highlights_on: lambda {false}, if: Proc.new { current_user.role_finance? and not detect_pin.call }
    end

    primary.item :post_admin, I18n.t('navigation.stage.post_admin'), '#', id: nil,
                 highlights_on: %r[/(finance/balancing|finance/invoices)\b], if: Proc.new { current_user.role_finance? } do |subnav|
      subnav.item :balancing, I18n.t('navigation.balancing'), finance_order_index_path, id: nil
      subnav.item :accounts, I18n.t('navigation.member_payments'), finance_ordergroups_path, id: nil, highlights_on: lambda {false}
    end

    primary.item :stage_divider, nil, nil, class: 'divider-vertical', id: nil

    #primary.item :finance, I18n.t('navigation.finances.title'), '#', id: nil, if: Proc.new { current_user.role_finance? } do |subnav|
      #subnav.item :finance_home, I18n.t('navigation.finances.home'), finance_root_path
      #subnav.item :accounts, I18n.t('navigation.finances.accounts'), finance_ordergroups_path, id: nil
      #subnav.item :balancing, I18n.t('navigation.finances.balancing'), finance_order_index_path, id: nil
      #subnav.item :invoices, I18n.t('navigation.finances.invoices'), finance_invoices_path, id: nil
    #end

    primary.item :admin, I18n.t('navigation.membership'), '#', id: nil,
                 hightlights_on: %r[/(admin)\b], if: Proc.new { current_user.role_admin? } do |subnav|
      subnav.item :admin_home, I18n.t('navigation.admin.home'), admin_root_path, id: nil
      subnav.item :users, I18n.t('navigation.admin.users'), admin_users_path, id: nil
      subnav.item :ordergroups, I18n.t('navigation.admin.ordergroups'), admin_ordergroups_path, id: nil
      subnav.item :workgroups, I18n.t('navigation.admin.workgroups'), admin_workgroups_path, id: nil
   end

   primary.item :others, I18n.t('navigation.other'), '#' do |subnav|
      subnav.item :accounts, I18n.t('navigation.member_payments'), finance_ordergroups_path, id: nil, if: Proc.new { current_user.role_finance? and detect_pin.call }
      subnav.item :finance_home, I18n.t('navigation.financial_overview'), finance_root_path, id: nil, if: Proc.new { current_user.role_finance? }
      subnav.item :invoices, I18n.t('navigation.finances.invoices'), finance_invoices_path, id: nil, if: Proc.new { current_user.role_finance? }
      subnav.item :categories, I18n.t('navigation.articles.categories'), article_categories_path, id: nil, if: Proc.new { current_user.role_admin? }
      subnav.item :pin_terminal, I18n.t('payments.navigation.pin'), detect_payments_adyen_pin_path, id: nil, unless: Proc.new { detect_pin.call } if defined? FoodsoftAdyen
    end

    engines.each { |e| e.navigation(primary, self) }
  end

end
