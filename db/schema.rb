# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150923190747) do

  create_table "adyen_notifications", :force => true do |t|
    t.boolean  "live",                                :default => false, :null => false
    t.string   "event_code",            :limit => 40,                    :null => false
    t.string   "psp_reference",         :limit => 50,                    :null => false
    t.string   "original_reference"
    t.string   "merchant_reference",                                     :null => false
    t.string   "merchant_account_code",                                  :null => false
    t.datetime "event_date",                                             :null => false
    t.boolean  "success",                             :default => false, :null => false
    t.string   "payment_method"
    t.string   "operations"
    t.text     "reason"
    t.string   "currency",              :limit => 3
    t.integer  "value"
    t.boolean  "processed",                           :default => false, :null => false
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  add_index "adyen_notifications", ["psp_reference", "event_code", "success"], :name => "adyen_notification_uniqueness", :unique => true

  create_table "article_categories", :force => true do |t|
    t.string  "name",        :default => "", :null => false
    t.string  "description"
    t.string  "ancestry"
    t.integer "position"
    t.string  "scope"
  end

  add_index "article_categories", ["ancestry"], :name => "index_article_categories_on_ancestry"
  add_index "article_categories", ["name"], :name => "index_article_categories_on_name", :unique => true
  add_index "article_categories", ["position"], :name => "index_article_categories_on_position"
  add_index "article_categories", ["scope"], :name => "index_article_categories_on_scope"

  create_table "article_prices", :force => true do |t|
    t.integer  "article_id"
    t.decimal  "price",         :precision => 8, :scale => 2, :default => 0, :null => false
    t.decimal  "tax",           :precision => 8, :scale => 2, :default => 0, :null => false
    t.decimal  "deposit",       :precision => 8, :scale => 2, :default => 0, :null => false
    t.integer  "unit_quantity"
    t.datetime "created_at"
  end

  add_index "article_prices", ["article_id"], :name => "index_article_prices_on_article_id"

  create_table "articles", :force => true do |t|
    t.string   "name",                                              :default => "",   :null => false
    t.integer  "supplier_id",                                       :default => 0,    :null => false
    t.integer  "article_category_id",                               :default => 0,    :null => false
    t.string   "unit",                                              :default => "",   :null => false
    t.string   "note"
    t.boolean  "availability",                                      :default => true, :null => false
    t.string   "manufacturer"
    t.string   "origin"
    t.datetime "shared_updated_on"
    t.decimal  "price",               :precision => 8, :scale => 2
    t.float    "tax"
    t.decimal  "deposit",             :precision => 8, :scale => 2, :default => 0
    t.integer  "unit_quantity",                                     :default => 1,    :null => false
    t.string   "order_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "type"
    t.integer  "quantity"
    t.string   "info_url"
    t.string   "fc_note"
  end

  add_index "articles", ["article_category_id"], :name => "index_articles_on_article_category_id"
  add_index "articles", ["name", "supplier_id"], :name => "index_articles_on_name_and_supplier_id"
  add_index "articles", ["supplier_id"], :name => "index_articles_on_supplier_id"
  add_index "articles", ["type"], :name => "index_articles_on_type"

  create_table "assignments", :force => true do |t|
    t.integer "user_id",  :default => 0,     :null => false
    t.integer "task_id",  :default => 0,     :null => false
    t.boolean "accepted", :default => false
  end

  add_index "assignments", ["user_id", "task_id"], :name => "index_assignments_on_user_id_and_task_id", :unique => true

  create_table "deliveries", :force => true do |t|
    t.integer  "supplier_id"
    t.date     "delivered_on"
    t.datetime "created_at"
    t.text     "note"
  end

  add_index "deliveries", ["supplier_id"], :name => "index_deliveries_on_supplier_id"

  create_table "financial_transactions", :force => true do |t|
    t.integer  "ordergroup_id",                                     :default => 0, :null => false
    t.decimal  "amount",              :precision => 8, :scale => 2
    t.text     "note",                                                             :null => false
    t.integer  "user_id",                                           :default => 0, :null => false
    t.datetime "created_on",                                                       :null => false
    t.datetime "updated_on"
    t.string   "payment_method"
    t.string   "payment_plugin"
    t.string   "payment_id"
    t.decimal  "payment_amount",      :precision => 8, :scale => 3
    t.string   "payment_currency"
    t.string   "payment_state"
    t.decimal  "payment_fee",         :precision => 8, :scale => 3
    t.string   "payment_acct_number"
    t.string   "payment_acct_name"
    t.text     "payment_info"
  end

  add_index "financial_transactions", ["ordergroup_id"], :name => "index_financial_transactions_on_ordergroup_id"
  add_index "financial_transactions", ["payment_plugin", "payment_id"], :name => "index_financial_transactions_on_payment_plugin_and_payment_id"

  create_table "group_order_article_quantities", :force => true do |t|
    t.integer  "group_order_article_id",   :default => 0,     :null => false
    t.integer  "quantity",                 :default => 0
    t.integer  "tolerance",                :default => 0
    t.datetime "created_on",                                  :null => false
    t.integer  "financial_transaction_id"
    t.boolean  "confirmed",                :default => false, :null => false
  end

  add_index "group_order_article_quantities", ["group_order_article_id"], :name => "index_group_order_article_quantities_on_group_order_article_id"

  create_table "group_order_articles", :force => true do |t|
    t.integer  "group_order_id",                                 :default => 0, :null => false
    t.integer  "order_article_id",                               :default => 0, :null => false
    t.integer  "quantity",                                       :default => 0, :null => false
    t.integer  "tolerance",                                      :default => 0, :null => false
    t.datetime "updated_on",                                                    :null => false
    t.decimal  "result",           :precision => 8, :scale => 3
    t.decimal  "result_computed",  :precision => 8, :scale => 3
  end

  add_index "group_order_articles", ["group_order_id", "order_article_id"], :name => "goa_index", :unique => true
  add_index "group_order_articles", ["group_order_id"], :name => "index_group_order_articles_on_group_order_id"
  add_index "group_order_articles", ["order_article_id"], :name => "index_group_order_articles_on_order_article_id"

  create_table "group_orders", :force => true do |t|
    t.integer  "ordergroup_id",                                    :default => 0, :null => false
    t.integer  "order_id",                                         :default => 0, :null => false
    t.decimal  "price",              :precision => 8, :scale => 2, :default => 0, :null => false
    t.integer  "lock_version",                                     :default => 0, :null => false
    t.datetime "updated_on",                                                      :null => false
    t.integer  "updated_by_user_id"
    t.decimal  "net_price",          :precision => 8, :scale => 2, :default => 0
    t.decimal  "gross_price",        :precision => 8, :scale => 2, :default => 0
    t.decimal  "deposit",            :precision => 8, :scale => 2, :default => 0
  end

  add_index "group_orders", ["order_id"], :name => "index_group_orders_on_order_id"
  add_index "group_orders", ["ordergroup_id", "order_id"], :name => "index_group_orders_on_ordergroup_id_and_order_id", :unique => true
  add_index "group_orders", ["ordergroup_id"], :name => "index_group_orders_on_ordergroup_id"

  create_table "groups", :force => true do |t|
    t.string   "type",                                                   :default => "",    :null => false
    t.string   "name",                                                   :default => "",    :null => false
    t.string   "description"
    t.decimal  "account_balance",          :precision => 8, :scale => 2, :default => 0,     :null => false
    t.datetime "created_on",                                                                :null => false
    t.boolean  "role_admin",                                             :default => false, :null => false
    t.boolean  "role_suppliers",                                         :default => false, :null => false
    t.boolean  "role_article_meta",                                      :default => false, :null => false
    t.boolean  "role_finance",                                           :default => false, :null => false
    t.boolean  "role_orders",                                            :default => false, :null => false
    t.datetime "deleted_at"
    t.string   "contact_person"
    t.string   "contact_phone"
    t.string   "contact_address"
    t.text     "stats"
    t.integer  "next_weekly_tasks_number",                               :default => 8
    t.boolean  "ignore_apple_restriction",                               :default => false
    t.boolean  "approved",                                               :default => false
    t.string   "scope"
    t.string   "price_markup_key"
  end

  add_index "groups", ["name"], :name => "index_groups_on_name", :unique => true
  add_index "groups", ["scope"], :name => "index_groups_on_scope"

  create_table "invites", :force => true do |t|
    t.string   "token",      :default => "", :null => false
    t.datetime "expires_at",                 :null => false
    t.integer  "group_id"
    t.integer  "user_id",    :default => 0,  :null => false
    t.string   "email",      :default => "", :null => false
    t.string   "scope"
  end

  add_index "invites", ["scope"], :name => "index_invites_on_scope"
  add_index "invites", ["token"], :name => "index_invites_on_token"

  create_table "invoices", :force => true do |t|
    t.integer  "supplier_id"
    t.integer  "delivery_id"
    t.integer  "order_id"
    t.string   "number"
    t.date     "date"
    t.date     "paid_on"
    t.text     "note"
    t.decimal  "amount",         :precision => 8, :scale => 2, :default => 0, :null => false
    t.decimal  "deposit",        :precision => 8, :scale => 2, :default => 0, :null => false
    t.decimal  "deposit_credit", :precision => 8, :scale => 2, :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices", ["delivery_id"], :name => "index_invoices_on_delivery_id"
  add_index "invoices", ["supplier_id"], :name => "index_invoices_on_supplier_id"

  create_table "memberships", :force => true do |t|
    t.integer "group_id", :default => 0, :null => false
    t.integer "user_id",  :default => 0, :null => false
  end

  add_index "memberships", ["user_id", "group_id"], :name => "index_memberships_on_user_id_and_group_id", :unique => true

  create_table "messages", :force => true do |t|
    t.integer  "sender_id"
    t.text     "recipients_ids"
    t.string   "subject",                           :null => false
    t.text     "body"
    t.integer  "email_state",    :default => 0,     :null => false
    t.boolean  "private",        :default => false
    t.datetime "created_at"
    t.string   "scope"
  end

  add_index "messages", ["scope"], :name => "index_messages_on_scope"

  create_table "order_articles", :force => true do |t|
    t.integer "order_id",         :default => 0, :null => false
    t.integer "article_id",       :default => 0, :null => false
    t.integer "quantity",         :default => 0, :null => false
    t.integer "tolerance",        :default => 0, :null => false
    t.integer "units_to_order",   :default => 0, :null => false
    t.integer "lock_version",     :default => 0, :null => false
    t.integer "article_price_id"
    t.integer "units_billed"
    t.integer "units_received"
  end

  add_index "order_articles", ["order_id", "article_id"], :name => "index_order_articles_on_order_id_and_article_id", :unique => true
  add_index "order_articles", ["order_id"], :name => "index_order_articles_on_order_id"

  create_table "order_comments", :force => true do |t|
    t.integer  "order_id"
    t.integer  "user_id"
    t.text     "text"
    t.datetime "created_at"
  end

  add_index "order_comments", ["order_id"], :name => "index_order_comments_on_order_id"

  create_table "orders", :force => true do |t|
    t.integer  "supplier_id"
    t.text     "note"
    t.datetime "starts"
    t.datetime "ends"
    t.string   "state",                                            :default => "open"
    t.integer  "lock_version",                                     :default => 0,      :null => false
    t.integer  "updated_by_user_id"
    t.decimal  "foodcoop_result",    :precision => 8, :scale => 2
    t.integer  "created_by_user_id"
    t.datetime "pickup"
    t.string   "scope"
    t.datetime "boxfill"
  end

  add_index "orders", ["scope"], :name => "index_orders_on_scope"
  add_index "orders", ["state"], :name => "index_orders_on_state"

  create_table "page_versions", :force => true do |t|
    t.integer  "page_id"
    t.integer  "lock_version"
    t.text     "body"
    t.integer  "updated_by"
    t.integer  "redirect"
    t.integer  "parent_id"
    t.datetime "updated_at"
  end

  add_index "page_versions", ["page_id"], :name => "index_page_versions_on_page_id"

  create_table "pages", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.string   "permalink"
    t.integer  "lock_version", :default => 0
    t.integer  "updated_by"
    t.integer  "redirect"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pages", ["permalink"], :name => "index_pages_on_permalink"
  add_index "pages", ["title"], :name => "index_pages_on_title"

  create_table "periodic_task_groups", :force => true do |t|
    t.date     "next_task_date"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "settings", :force => true do |t|
    t.string   "var",                      :null => false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", :limit => 30
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "settings", ["thing_type", "thing_id", "var"], :name => "index_settings_on_thing_type_and_thing_id_and_var", :unique => true

  create_table "stock_changes", :force => true do |t|
    t.integer  "delivery_id"
    t.integer  "order_id"
    t.integer  "stock_article_id"
    t.integer  "quantity",         :default => 0
    t.datetime "created_at"
    t.integer  "stock_taking_id"
  end

  add_index "stock_changes", ["delivery_id"], :name => "index_stock_changes_on_delivery_id"
  add_index "stock_changes", ["stock_article_id"], :name => "index_stock_changes_on_stock_article_id"
  add_index "stock_changes", ["stock_taking_id"], :name => "index_stock_changes_on_stock_taking_id"

  create_table "stock_takings", :force => true do |t|
    t.date     "date"
    t.text     "note"
    t.datetime "created_at"
  end

  create_table "suppliers", :force => true do |t|
    t.string   "name",               :default => "",   :null => false
    t.string   "address",            :default => "",   :null => false
    t.string   "phone",              :default => "",   :null => false
    t.string   "phone2"
    t.string   "fax"
    t.string   "email"
    t.string   "url"
    t.string   "contact_person"
    t.string   "customer_number"
    t.string   "delivery_days"
    t.string   "order_howto"
    t.string   "note"
    t.integer  "shared_supplier_id"
    t.string   "min_order_quantity"
    t.datetime "deleted_at"
    t.string   "article_info_url"
    t.string   "scope"
    t.boolean  "use_tolerance",      :default => true
    t.string   "shared_sync_method"
  end

  add_index "suppliers", ["name"], :name => "index_suppliers_on_name", :unique => true
  add_index "suppliers", ["scope"], :name => "index_suppliers_on_scope"

  create_table "tasks", :force => true do |t|
    t.string   "name",                   :default => "",    :null => false
    t.string   "description"
    t.date     "due_date"
    t.boolean  "done",                   :default => false
    t.integer  "workgroup_id"
    t.datetime "created_on",                                :null => false
    t.datetime "updated_on",                                :null => false
    t.integer  "required_users",         :default => 1
    t.integer  "duration",               :default => 1
    t.integer  "periodic_task_group_id"
    t.string   "scope"
  end

  add_index "tasks", ["due_date"], :name => "index_tasks_on_due_date"
  add_index "tasks", ["name"], :name => "index_tasks_on_name"
  add_index "tasks", ["scope"], :name => "index_tasks_on_scope"
  add_index "tasks", ["workgroup_id"], :name => "index_tasks_on_workgroup_id"

  create_table "users", :force => true do |t|
    t.string   "nick"
    t.string   "password_hash",          :default => "", :null => false
    t.string   "password_salt",          :default => "", :null => false
    t.string   "first_name",             :default => "", :null => false
    t.string   "last_name",              :default => "", :null => false
    t.string   "email",                  :default => "", :null => false
    t.string   "phone"
    t.datetime "created_on",                             :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_expires"
    t.datetime "last_login"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["nick"], :name => "index_users_on_nick", :unique => true

end
