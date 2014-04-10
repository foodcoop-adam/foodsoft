# encoding: utf-8
module FoodsoftVokomokum

  # create text blob for uploading ordergroup totals to vokomokum system
  def self.export_amounts(amounts)
    lines = []
    amounts.map do |ordergroup, amount|
      user = user_for_ordergroup ordergroup
      lines << "#{user.id}\t#{user.display}\t€ #{'%.02f'%amount}\tAfgewogen"
      # TODO rescue each inner loop?
    end
    lines.join("\r\n")
  end

  def self.user_for_ordergroup(ordergroup)
    ordergroup = Ordergroup.find(ordergroup) unless ordergroup.kind_of?(Ordergroup)
    if ordergroup.users.count == 0
      if amount == 0
        Rails.logger.warn "Ordergroup ##{ordergroup.id} has no users, fix this! (skipping because amount is zero)"
      else
        raise Exception.new("Ordergroup ##{ordergroup.id} has no users, cannot book amount.")
      end
    else
      user = ordergroup.users.first
      if ordergroup.users.count > 1
        Rails.logger.warn "Ordergroup ##{ordergroup.id} has multiple users, selecting ##{user.id}."
      end
      return user
    end
  end

end
