class Users::BankAccountsController < ApplicationController
  after_filter  :verify_authorized, except: :index
  before_action :has_list_permission?, only: :index

  def index
    head :ok
  end

  def new
    @bank_account = BankAccount.new(user: current_user)
    authorize @bank_account

    @bank_account.authorization_documents.build

    @banks = Bank.order(:code).to_collection
  end

  def create
    @bank_account = BankAccount.new(user: current_user)

    authorize @bank_account

    @bank_account.attributes = bank_account_params

    if @bank_account.save
      flash[:notice] = t(:success, scope: 'user.bank_account.create')
    else
      flash[:alert] = @bank_account.errors.full_messages.to_sentence
    end

    head :ok
  end

  private

  def collection
    @collection ||= BankAccount.by_user(current_user) if current_user
  end

  def bank_account_params
    params.require(:bank_account).permit(
      policy(@bank_account).permitted_attributes
    )
  end

  def has_list_permission?
    redirect_to root_path unless policy(BankAccount).has_list_permission?(collection)
  end
end
