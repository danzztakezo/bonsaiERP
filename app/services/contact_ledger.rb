# encoding: utf-8
# Creates the in and out for a contact,creating a account to pay in case
# it's an in and account to receive in case is an out
class ContactLedger

  attr_reader :account_ledger, :errors

  def initialize(attributes)
    @errors = ActiveModel::Errors.new(self)

    @account_ledger = AccountLedger.new(attributes) do |al|
      al.amount = al.amount.to_f.abs
      al.exchange_rate = 1
    end
  rescue Exception => e
    errors[:base] << 'There are missing attributes'
  end

  def create_in(concil = true)
    account_ledger.operation    = 'contin'
    account_ledger.conciliation = concil

    ActiveRecord::Base.transaction do
      set_or_create_account_to

      account_ledger.save!
    end
  rescue Exception => e
    false
  end

  def create_out(concil = true)
    account_ledger.operation    = 'contout'
    account_ledger.conciliation = concil
    account_ledger.amount       = -account_ledger.amount

    ActiveRecord::Base.transaction do
      set_or_create_account_to

      account_ledger.save!
    end
  rescue Exception => e
    false
  end

  def persisted
    false
  end

private
  def set_or_create_account_to
    unless to = account_ledger.contact.account_cur(currency).present?
      to = contact.set_account_currency(currency)

      to.save!
    end

    account_ledger.to_id = to.id
  end

  def currency
    @currency ||= account.currency
  end

  def contact
    account_ledger.contact
  end

  def account
    @account ||= account_ledger.account
  end
end