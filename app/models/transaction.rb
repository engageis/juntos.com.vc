class Transaction < ActiveRecord::Base
  extend Enumerize

  validates_presence_of :transaction_code, :status, :amount,
                        :payment_method, :subscription_id

  belongs_to :subscription
  has_one    :project, through: :subscription

  enumerize :status, in: {
                           processing:      0,
                           authorized:      1,
                           paid:            2,
                           refunded:        3,
                           waiting_payment: 4,
                           pending_payment: 5,
                           refused:         6
                         }

   enumerize :payment_method, in: { credit_card: 0, bank_billet: 1 }

end
