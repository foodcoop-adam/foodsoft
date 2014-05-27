# handles membership fee processing

module FoodsoftSignup

  module DebitMembership
    def self.included(base) # :nodoc:
      base.class_eval do

        # debit membership on ordergroup creation
        after_create :debit_membership!, :if => proc { FoodsoftSignup.enabled? :membership_fee }
        def debit_membership!
          Rails.logger.debug "Debit membership fee of #{FoodsoftConfig[:membership_fee].to_f} for ordergroup ##{id}"
          amount = (-FoodsoftConfig[:membership_fee].to_f).to_s
          amount.gsub!('\.', I18n.t('separator', :scope => 'number.format')) # workaround localize_input problem
          note = I18n.t('foodsoft_signup.membership_fee.transaction_note')
          FinancialTransaction.new(:ordergroup => self, :amount => amount, :note => note, :user_id => 0, :notify => false).save!
        end

      end
    end
  end

  module ApproveMembership
    def self.included(base) # :nodoc#
      base.class_eval do

        after_save :foodsoft_signup_approve

        private
        def foodsoft_signup_approve
          if FoodsoftSignup.enabled? :approval and FoodsoftSignup.enabled? :membership_fee
            if not ordergroup.approved? and (amount.to_f + payment_fee.to_f - FoodsoftConfig[:membership_fee].to_f) > -1e-4
              transaction do
                Rails.logger.debug "Approving ordergroup ##{ordergroup.id} after membership fee payment"
                ordergroup.update_attributes approved: true
                # @todo Implement additing payment fee to amount in payment plugin; until that's done, we
                #   compensate for that in the membership fee transaction afterwards.
                if payment_fee and (t = ordergroup.financial_transactions.first).amount == -FoodsoftConfig[:membership_fee].to_f
                  Rails.logger.debug "Compensating for payment fee #{payment_fee.to_f} in membership fee #{t.amount.to_f} -> #{(t.amount + payment_fee).to_f}"
                  t.update_attributes amount: (t.amount + payment_fee)
                  ordergroup.reload # for updated account_balance
                end
                # When this is the first transaction after the membership fee, and it's more than the
                # fee, we assume it's a donation - debit that.
                # @todo config option - perhaps some groups would like to have a prepaid credit right away
                if ordergroup.financial_transactions.hide_expired.count <= 2 and (diff = ordergroup.account_balance) > 0
                  Rails.logger.debug "Paid more than membership fee, assuming donation of #{diff.to_f}"
                  note = I18n.t('foodsoft_signup.membership_fee.transaction_note_donation')
                  FinancialTransaction.new(:ordergroup => ordergroup, :amount => -diff, :note => note, :user_id => 0).save!
                end
              end
            end
          end
        end

      end
    end
  end

end

ActiveSupport.on_load(:after_initialize) do
  Ordergroup.send :include, FoodsoftSignup::DebitMembership
  FinancialTransaction.send :include, FoodsoftSignup::ApproveMembership
end
