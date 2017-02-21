class BankAccountDecorator < Draper::Decorator
  delegate_all

  def bank_name
    source.bank.name
  end

  def bank_code
    source.bank.code
  end
end
