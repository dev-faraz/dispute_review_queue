class Webhooks::DisputesController < ApplicationController
  skip_before_action :verify_authenticity_token
  SCHEMA = JSON.parse(
      Rails.root.join("config/schemas/dispute_webhook_schema.json").read
    ).freeze

  def create
    payload = request.body.read
    parsed = JSON.parse(payload) rescue nil
    errors = JSON::Validator.validate(SCHEMA, parsed, strict: true)

    if errors
      Rails.logger.warn "Invalid webhook payload: #{errors.join(', ')}"
      render json: { error: "Invalid payload", details: errors }, status: :bad_request
      return
    end

    ProcessDisputeEventJob.perform_async(payload)
    render json: { status: "queued" }, status: :accepted
  end
end