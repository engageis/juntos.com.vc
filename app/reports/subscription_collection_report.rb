require 'csv'

class SubscriptionCollectionReport
  def initialize(subscriptions, project_id)
    @subscriptions = subscriptions
    @filename = Rails.root.join("#{report_path}/apoiadores_#{project_id}.csv")
  end

  def export!
    file = File.open(@filename, 'w+') { |f| f.write(generate); f }
    File::realpath(file)
  end

  private

  attr_reader :subscriptions

  REPORT_SCOPE = 'subscription_report_to_project_owner'
  HEADERS = [
    I18n.t('subscription.charges', scope: REPORT_SCOPE),
    I18n.t('subscription.confirmed_at', scope: REPORT_SCOPE),
    I18n.t('subscription.payment_method', scope: REPORT_SCOPE),
    I18n.t('reward.description', scope: REPORT_SCOPE),
    I18n.t('user.name', scope: REPORT_SCOPE),
    I18n.t('user.email', scope: REPORT_SCOPE),
    I18n.t('user.phone_number', scope: REPORT_SCOPE),
    I18n.t('user.cpf', scope: REPORT_SCOPE),
    I18n.t('user.address_street', scope: REPORT_SCOPE),
    I18n.t('user.address_number', scope: REPORT_SCOPE),
    I18n.t('user.address_complement', scope: REPORT_SCOPE),
    I18n.t('user.address_neighbourhood', scope: REPORT_SCOPE),
    I18n.t('user.address_city', scope: REPORT_SCOPE),
    I18n.t('user.address_state', scope: REPORT_SCOPE),
    I18n.t('user.address_zip_code', scope: REPORT_SCOPE),
    I18n.t('plan.formatted_amount', scope: REPORT_SCOPE),
  ]

  def generate
    CSV.generate(options) do |csv|
      report_content.each { |element| csv << element }
    end
  end

  def report_content
    subscriptions.map do |subscription|
      [
        subscription.charges,
        confirmed_at(subscription),
        subscription.payment_method,
        reward_description,
        subscription.user_name,
        subscription.user_email,
        subscription.user_phone_number,
        subscription.user_cpf,
        subscription.user_address_street,
        subscription.user_address_number,
        subscription.user_address_complement,
        subscription.user_address_neighbourhood,
        subscription.user_address_city,
        subscription.user_address_state,
        subscription.user_address_zip_code,
        subscription.plan_formatted_amount
      ]
    end
  end

  def confirmed_at(subscription)
    return "" if subscription.confirmed_at.nil?

    subscription.confirmed_at.strftime('%d/%m/%Y')
  end

  def reward_description
    ""
  end

  def report_path
    report_dir_name = File.dirname('tmp/reports')
    Dir.mkdir(report_dir_name) unless File.exists?(report_dir_name)
    report_dir_name
  end

  def options
    {write_headers: true, headers: HEADERS, col_sep: ';', quote_char: '"', force_quotes: true}
  end
end
