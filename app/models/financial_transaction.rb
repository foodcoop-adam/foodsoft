# Financial transactions are the foodcoop's internal financial transactions.
# +Ordergroup+s have an account balance, which is the sum of all their financial transactions.
class FinancialTransaction < ActiveRecord::Base

  # @!attribute amount
  #   @return [Number] Amount credited (negative means debit). May be +nil+ when +payment_amount+ is set.
  # @!attribute note
  #   @return [String] Description of the transaction.

  # @!attribute payment_method
  #   @return [String] Identifier of the payment method (e.g. +manual+, +transfer+, +ideal+, +creditcard+, +paypal+).
  # @!attribute payment_plugin
  #   @return [String] Identifier of the Foodsoft payment plugin (e.g. +mollie+).
  # @!attribute payment_id
  #   @return [String] Identifier at payment provider; when specified, is unique together with +payment_plugin+.
  # @!attribute payment_amount
  #   @return [Number] Amount submitted/paid at payment provider; can be different from +amount+ (e.g. by +payment_fee+).
  # @!attribute payment_currency
  #   @return [String] {https://en.wikipedia.org/wiki/ISO_4217 ISO-4217} currency of +payment_amount+.
  # @!attribute payment_state
  #   Payment status. One of: +created+, +open+, +cancelled+, +paid+, +refunded+, +expired+.
  #   @return [String] Last known status of payment.
  #   @todo Document payment states, and what happens to this object.
  #   @todo Use a state machine here?
  # @!attribute payment_fee
  #   @return [Number] Fee paid to provider for this transaction.
  # @!attribute payment_acct_number
  #   Account number where payment comes from.
  #   This is dependent on +payment_method+, but there can be overlap between
  #   different methods (e.g. for bank transfer and ideal this is preferably an
  #   IBAN number, but Paypal may have a different identifier).
  #   This, together with +payment_acct_name+, might be used to match payments for
  #   which the ordergroup is not yet known (e.g. bank transfers without a reference number).
  #   @return [String] Account number where payment comes from
  # @!attribute payment_acct_name
  #   @return [String] Account name corresponding to +payment_acct_number+.
  # @!attribute payment_info
  #   @return [String] +payment_plugin+-specific information, stored in YAML.

  # @!attribute ordergroup
  #   @return [Ordergroup] Ordergroup account credited/debited.
  belongs_to :ordergroup
  # @!attribute user
  #   @return [User] User who entered the transaction.
  belongs_to :user
  
  validates_presence_of :note, :user_id, :ordergroup_id
  validates_numericality_of :amount, allow_nil: -> { payment_amount.present? }
  validates_numericality_of :payment_amount, :payment_fee, allow_nil: true

  localize_input_of :amount

  after_save :update_ordergroup_balance

  private
  def update_ordergroup_balance
    # @todo Make sure this transaction and the ordergroup update is in one database transaction.
    #   It may be possible to use an around filter if needed.
    ordergroup.update_balance!
  end
end

