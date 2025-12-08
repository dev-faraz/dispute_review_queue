class Dispute < ApplicationRecord
  include AASM

  belongs_to :charge
  has_many :case_actions, dependent: :destroy
  has_many :evidences, dependent: :destroy
  has_many :adjustments, dependent: :destroy
  has_many_attached :evidence_files

  aasm column: :status, whiny_transitions: false do
    state :needs_response, initial: true
    state :under_review
    state :won
    state :lost

    event :submit_evidence do
      transitions from: :needs_response, to: :under_review
    end

    event :decide_win do
      transitions from: [:needs_response, :under_review], to: :won
      after do
        self.closed_at = Time.current
        adjustments.create!(
          amount_cents: amount_cents,
          reason: "dispute_won"
        )
        save!
      end
    end

    event :decide_lose do
      transitions from: [:needs_response, :under_review], to: :lost
      after do
        self.closed_at = Time.current
        adjustments.create!(
          amount_cents: -amount_cents,
          reason: "dispute_lost"
        )
        save!
      end
    end

    event :reopen do
      transitions from: [:won, :lost], to: :needs_response
      after do
        self.closed_at = nil
        adjustments.destroy_all
      end
    end
  end

  def process_event!(payload)
    event_id = payload["id"]
    charge_obj = payload["data"]["object"]

    if last_event_id == event_id
      return false
    end

    occurred_at = Time.at(payload["data"]["object"]["created"].to_i)
    return false if last_event_id && occurred_at < self.updated_at

    transaction do
      lock!

      case payload["type"]
      when "charge.dispute.created"
        update!(
          opened_at: Time.at(charge_obj["created"]),
          amount_cents: charge_obj["amount"],
          currency: charge_obj["currency"],
          external_payload: payload
        )

      when "charge.dispute.updated"
        if charge_obj["status"] == "under_review" && may_submit_evidence?
          submit_evidence!
        end
        update!(external_payload: payload)

      when "charge.dispute.closed"
        if charge_obj["status"] == "won" && may_decide_win?
          decide_win!
        elsif charge_obj["status"] == "lost" && may_decide_lose?
          decide_lose!
        end
        update!(closed_at: Time.at(charge_obj["created"]), external_payload: payload)
      end

      update!(last_event_id: event_id)
      create_audit!("webhook_processed", details: { event_type: payload["type"], event_id: })
      true
    end
  end

  def create_audit!(action, note: nil, details: {})
    case_actions.create!(
      actor: actor,
      action: action,
      note: note,
      details: details
    )
  end

  def actor
    Current.user || User.find_by(email: 'system@example.com')
  end
end