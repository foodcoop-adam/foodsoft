# encoding: utf-8
module FoodsoftVokomokum

  def self.userid_for_ordergroup(ordergroup)
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
      return user.id
    end
  end

end
