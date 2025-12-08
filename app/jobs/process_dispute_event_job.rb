class ProcessDisputeEventJob
  include Sidekiq::Job

  SCHEMA = JSON.parse(
    Rails.root.join("config/schemas/dispute_webhook_schema.json").read
  ).freeze


  def perform(raw_payload)
    payload = JSON.parse(raw_payload)
    errors = JSON::Validator.validate(SCHEMA, payload, strict: true)
    if errors
      Rails.logger.error "Invalid webhook payload: #{errors}"
      return
    end

    external_dispute_id = payload["data"]["object"]["id"]
    charge_ext_id = payload["data"]["object"]["charge"]

    charge = Charge.find_or_create_by!(external_id: charge_ext_id) do |c|
      c.amount_cents = payload["data"]["object"]["amount"]
      c.currency = payload["data"]["object"]["currency"]
      c.created_at = Time.current
    end

    dispute = Dispute.find_or_initialize_by(external_id: external_dispute_id)
    dispute.charge = charge
    dispute.save

    dispute.process_event!(payload)
  end
end