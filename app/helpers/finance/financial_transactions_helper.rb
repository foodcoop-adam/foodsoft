module Finance::FinancialTransactionsHelper
  # Returns css class for payment (color depending on state).
  def payment_state_class(transaction)
    case transaction.payment_state
    when 'created', 'open'
      return 'text-warning'
    when 'paid'
      return nil
    when 'refunded'
      return 'text-error'
    when 'cancelled', 'expired'
      return 'muted'
    end
  end


  # Return amount of transaction (in html), or short text if not fully paid.
  def transaction_amount_text(t)
    info = case t.payment_state
           when 'created', 'open'
             I18n.t('helpers.finance.financial_transactions.state.pending')
           when 'refunded'
             I18n.t('helpers.finance.financial_transactions.state.refunded')
           when 'cancelled', 'expired'
             I18n.t('helpers.finance.financial_transactions.state.cancelled')
           end
    if info and (t.amount.nil? or t.amount == 0)
      content_tag :i, info, title: number_to_currency(t.payment_amount)
    elsif info
      content_tag :abbr, number_to_currency(t.amount), title: info
    end
  end
end
