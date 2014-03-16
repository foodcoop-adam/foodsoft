# -*- coding: utf-8 -*-
# Configures your navigation

SimpleNavigation::Configuration.run do |navigation|

  # allow engines to add to the menu - https://gist.github.com/mjtko/4873ee0c112b6bd646f8
  engines = Rails.application.railties.engines.select { |e| e.respond_to?(:navigation) }
  # to include an engine but keep it from modifying the menu:
  #engines.reject! { |e| e.instance_of? FoodsoftMyplugin::Engine }

  use_adyen = -> { FoodsoftAdyen.enabled? rescue nil }
  detect_pin = -> { FoodsoftAdyen.detect_pin(request) if use_adyen.call }

  navigation.items do |primary|
    primary.dom_class = 'nav'

    #primary.item :dashboard_nav_item, I18n.t('navigation.dashboard'), root_path(anchor: '')

    primary.item :prepare, I18n.t('navigation.prepare._title'), '#',
                 highlights_on: %r[/(orders(?!.*/receive)|suppliers)\b],
                 if: -> { current_user.role_orders? or current_user.role_article_meta? or current_user.role_suppliers? } do |subnav|
      subnav.item :suppliers, I18n.t('navigation.prepare.suppliers'), suppliers_path, if: -> { current_user.role_article_meta? or current_user.role_suppliers? }
      subnav.item :orders, I18n.t('navigation.prepare.orders'), orders_path, if: -> { current_user.role_orders? }
    end

    primary.item :distribute, I18n.t('navigation.distribute._title'), '#',
                 highlights_on: %r[/(current_orders/articles|current_orders/receive|orders/.*/receive)\b],
                 if: -> { current_user.role_orders? } do |subnav|
      subnav.item :receive, I18n.t('navigation.distribute.receive'), receive_current_orders_orders_path
      subnav.item :order_articles, I18n.t('navigation.distribute.articles'), current_orders_articles_path
      subnav.item :stage_divider, nil, nil, class: 'divider'
      subnav.item :member_orders, I18n.t('navigation.distribute.ordergroups'), current_orders_ordergroups_path
    end

    primary.item :finances, I18n.t('navigation.finances._title'), '#',
                 highlights_on: %r[/(finance/balancing|finance/invoices)\b], if: -> { current_user.role_finance? } do |subnav|
      subnav.item :balancing, I18n.t('navigation.finances.balancing'), finance_order_index_path
      subnav.item :accounts, I18n.t('navigation.finances.accounts'), finance_ordergroups_path
      #subnav.item :stage_divider
      #subnav.item :invoices, I18n.t('navigation.finances.invoices'), finance_invoices_path
      #subnav.item :finance_home, I18n.t('navigation.finances.home'), finance_root_path
      subnav.item :pin_terminal, I18n.t('payments.navigation.pin'), detect_payments_adyen_pin_path, if: use_adyen if defined? FoodsoftAdyen
    end

    primary.item :stage_divider, nil, nil, class: 'divider-vertical'

    primary.item :admin, I18n.t('navigation.admin._title'), '#',
                 hightlights_on: %r[/(admin(?!/workgroups))\b], if: -> { current_user.role_admin? } do |subnav|
      #subnav.item :admin_home, I18n.t('navigation.admin.home'), admin_root_path
      subnav.item :users, I18n.t('navigation.admin.users'), admin_users_path
      subnav.item :ordergroups, I18n.t('navigation.admin.ordergroups'), admin_ordergroups_path
   end

   primary.item :config, I18n.t('navigation.config._title'), '#',
                highlights_on: %r[/(article_categories|admin/workgroups)\b],
                if: -> { current_user.role_finance? or current_user.role_article_meta? or defined? FoodsoftAdyen } do |subnav|
      subnav.item :categories, I18n.t('navigation.articles.categories'), article_categories_path, if: -> { current_user.role_article_meta? }
      subnav.item :workgroups, I18n.t('navigation.admin.workgroups'), admin_workgroups_path
      subnav.item :config, I18n.t('navigation.admin.config'), admin_config_path
    end

    engines.each { |e| e.navigation(primary, self) }
  end

end
