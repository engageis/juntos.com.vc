class RecurringContribution::Subscriptions::Processor
  attr_reader :subscription, :with_save

  def initialize(subscription, credit_card_hash, with_save:)
    @subscription     = subscription
    @credit_card_hash = credit_card_hash
    @with_save        = with_save
  end

  def self.process(subscription:, credit_card_hash: {}, with_save: true)
    new(subscription, credit_card_hash, with_save: with_save).process
  end

  def process
    register_errors(subscription.errors) do
      assign_attributes(with_save,
        status: subscription_status,
        credit_card_key: (new_credit_card_id if paid_with_credit_card?)
      )
    end

    charge(subscription) if charge_scheduled_for_today?

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

  def charge(subscription)
    RecurringContribution::Subscriptions::Create.process(subscription)
  end

  def charge_scheduled_for_today?
    (subscription.charging_day == DateTime.current.day) && with_save
  end

  def subscription_status
    return :pending_payment if charge_scheduled_for_today?

    :waiting_for_charging_day
  end

  def paid_with_credit_card?
    subscription.payment_method == 'credit_card'
  end

  def assign_attributes(with_save, attributes)
    subscription.assign_attributes(attributes)
    subscription.user.cpf = subscription.donator_cpf

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
