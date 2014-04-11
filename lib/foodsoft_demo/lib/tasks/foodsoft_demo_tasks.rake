namespace :foodsoft do
  namespace :demo do
    desc 'Cleanup demo'
    task 'clean' => ['clean:users']

    desc 'Cleanup demo users'
    task 'clean:users' => :environment do
      if FoodsoftDemo.enabled? :autologin
        users = User.where('nick LIKE "demo%" AND email LIKE "demo%@foodcoop.test"').where('last_login < ?', 3.hours.ago)
        users.each do |user|
          if user.ordergroup
            user.ordergroup.group_orders.delete_all
            user.ordergroup.destroy
          end
          user.delete
        end
        rake_say "deleted #{users.count} demo users"
      else
        rake_say "autologin not enabled, skipping demo user clean"
      end
    end
  end
end
