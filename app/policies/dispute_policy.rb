class DisputePolicy < ApplicationPolicy
  attr_reader :user, :dispute

  def initialize(user, dispute)
    @user = user
    @dispute = dispute
  end

  def index?
    true
  end

  def show?
    true
  end

  def update?
    user.admin? || user.reviewer?
  end

  def attach_evidence?
    user.admin? || user.reviewer?
  end

  def transition?
    user.admin? || user.reviewer?
  end

  def destroy_evidence?
    user.admin?
  end

  def manage_users?
    user.admin?
  end
end