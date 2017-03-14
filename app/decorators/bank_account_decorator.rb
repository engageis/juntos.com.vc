class BankAccountDecorator < Draper::Decorator
  delegate_all

  def bank_name
    source.bank.name
  end

  def bank_code
    source.bank.code
  end

  def agency
    return agency_with_digit if source.agency_digit

    source.agency
  end

  def account
    "#{source.account}-#{source.account_digit}"
  end

  private

  def agency_with_digit
    "#{source.agency}-#{source.agency_digit}"
  end
end
