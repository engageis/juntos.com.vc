class RecurringContribution::Subscriptions::Processor
  attr_reader :subscription

  def initialize(subscription, credit_card_hash)
    @subscription     = subscription
    @credit_card_hash = credit_card_hash
  end

  def self.process(subscription:, credit_card_hash: {}, with_save: true)
    new(subscription, credit_card_hash).process(with_save)
  end

  def process(with_save)
    register_errors(subscription.errors) do
      assign_attributes(with_save,
        status: :waiting_for_charging_day,
        credit_card_key: (new_credit_card_id if paid_with_credit_card?)
      )
    end

    subscription
  end

  private
  attr_reader :credit_card_hash

  def new_credit_card_id
    response = Pagarme::API.create_credit_card(credit_card_hash)
    response.id
  rescue Pagarme::API::InvalidAttributeError
    register_error(:credit_card_key, :credit_card_invalid)
  end

  def paid_with_credit_card?
    subscription.payment_method == 'credit_card'
  end

  def assign_attributes(with_save, attributes)
    subscription.assign_attributes(attributes)

    subscription.save if with_save && !has_errors?
  end

  def has_errors?
    @errors.any?
  end

  def register_error(key, error_type)
    @errors.push([key, error_type])
  end

  def register_errors(errors)
    @errors = []
    result = yield
    @errors.each { |(key, error_type)| errors.add(key, error_type) }
    result
  end
end
