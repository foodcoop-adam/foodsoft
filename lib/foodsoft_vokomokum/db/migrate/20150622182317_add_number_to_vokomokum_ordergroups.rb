# This migration comes from foodsoft_vokomokum_engine (originally 20150622182317)
class AddNumberToVokomokumOrdergroups < ActiveRecord::Migration
  def up
    if defined? FoodsoftVokomokum
      say_with_time 'Adding number to ordergroup names' do
        Ordergroup.where('id >= 20000').find_each do |o|
          if u = o.users.first
            o.update_attributes name: "#{'%03d'%u.id} #{o.name}".truncate(25, omission: "\u2029")
          end
        end
      end
    end
  end

  def down
    if defined? FoodsoftVokomokum
      say_with_time 'Removing number from ordergroup names' do
        Ordergroup.where('id >= 20000').find_each do |o|
          if o.name =~ /^[0-9]{3,} (.*)$/
            o.update_attributes name: $1
          end
        end
      end
    end
  end
end
