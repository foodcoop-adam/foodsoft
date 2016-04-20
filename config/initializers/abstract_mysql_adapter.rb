# Workaround for Rails 3 with MySQL 5.7+
# https://github.com/rails/rails/pull/13247#issuecomment-32425844
ActiveSupport.on_load(:active_record) do
  class ActiveRecord::ConnectionAdapters::Mysql2Adapter
    NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
  end
end
