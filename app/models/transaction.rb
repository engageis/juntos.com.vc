class Transaction < ActiveRecord::Base
  validates_presence_of :transaction_code, :status, :amount,
                        :payment_method, :subscription_id

  belongs_to :subscription
  has_one    :project, through: :subscription

  enum status: [ :pending_payment, :processing, :authorized, :paid, :refunded, :waiting_payment, :refused ]

  enum payment_method: [ :credit_card, :bank_billet ]

end
