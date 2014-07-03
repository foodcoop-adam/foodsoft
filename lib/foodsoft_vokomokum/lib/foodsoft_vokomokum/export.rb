# encoding: utf-8
module FoodsoftVokomokum

  # create text blob for uploading ordergroup totals to vokomokum system
  def self.export_amounts(amounts)
    lines = []
    amounts.map do |ordergroup, amount|
      user = user_for_ordergroup ordergroup
      if user.nil?
        if 0 != amount
          lines << "# Ordergroup ##{ordergroup} has no users, cannot book amount: #{amount}"
        end
      elsif user.id < 20000  # only upload amounts for vokomokum users
        lines << "#{user.id}\t#{user.display}\t€ #{'%.02f'%amount}\tAfgewogen"
      end
    end
    lines.join("\r\n")
  end

  def self.user_for_ordergroup(ordergroup)
    unless ordergroup.kind_of?(Ordergroup)
      begin
        ordergroup = Ordergroup.undeleted.find(ordergroup)
      rescue ActiveRecord::RecordNotFound
        return nil
      end
    end
    if ordergroup.users.count == 0
      Rails.logger.warn "Ordergroup ##{ordergroup.id} has no users, fix this! (skipping because amount is zero)"
      return nil
    else
      user = ordergroup.users.first
      if ordergroup.users.count > 1
        Rails.logger.warn "Ordergroup ##{ordergroup.id} has multiple users, selecting ##{user.id}."
      end
      return user
    end
  end

end
