class ReportPolicy < ApplicationPolicy
  attr_reader :user

  def initialize(user, record)
    @user = user
  end

  def read?
    true
  end

  def export?
    user.admin?
  end

  def daily_volume?
    read?
  end

  def time_to_decision?
    read?
  end
end