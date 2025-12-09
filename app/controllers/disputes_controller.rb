class DisputesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_dispute, only: [:show, :attach_evidence, :transition]

  def index
    authorize Dispute
    @disputes = Dispute.includes(:charge).order(created_at: :desc)
  end

  def show
    authorize @dispute, :show?
    @case_actions = @dispute.case_actions.includes(:actor).order(created_at: :desc)
  end

  def attach_evidence
    authorize @dispute, :attach_evidence?

    evidence = @dispute.evidences.create!(
      kind: params[:kind].presence || "note",
      metadata: { note: params[:note] }.compact
    )
    note = params[:note]

    if params[:file].present?
      evidence.file.attach(params[:file])
      note = "#{params[:note]}: #{evidence.file.filename}"
    end

    @dispute.create_audit!("evidence_attached", note: note)
    redirect_to @dispute, notice: "Evidence attached successfully"
  end

  def transition
    authorize  @dispute, :transition?

    action = params[:action_type]
    note   = params[:note].presence

    case action
    when "submit_evidence"
      if @dispute.may_submit_evidence?
        @dispute.submit_evidence!
        @dispute.create_audit!("submit_evidence", note: note || "Evidence submitted")
      end

    when "decide_win"
      if @dispute.may_decide_win?
        @dispute.decide_win!
        @dispute.create_audit!("decide_win", note: note || "Merchant won dispute")
      end

    when "decide_lose"
      if @dispute.may_decide_lose?
        @dispute.decide_lose!
        @dispute.create_audit!("decide_lose", note: note || "Customer won dispute")
      end

    when "reopen"
      if note.blank?
        redirect_to @dispute, alert: "Justification note is required to reopen"
        return
      end
      if @dispute.may_reopen?
        @dispute.reopen!
        @dispute.create_audit!("reopen", note: note)
      end
    else
      redirect_to @dispute, alert: "Invalid action"
      return
    end

    redirect_to @dispute, notice: "Dispute updated successfully"
  end

  private

  def set_dispute
    @dispute = Dispute.find(params[:id] || params[:dispute_id])
  end
end