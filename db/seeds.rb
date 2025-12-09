require 'faker'

def create_dispute_if_missing(attrs, &block)
  return if Dispute.exists?(external_id: attrs[:external_id])

  dispute = Dispute.create!(attrs)
  yield dispute if block_given?
  dispute
end

def create_charge_if_missing(attrs)
  Charge.find_or_create_by!(external_id: attrs[:external_id]) do |c|
    c.amount_cents = attrs[:amount_cents]
    c.currency = attrs[:currency]
    c.created_at = attrs[:created_at] || Time.current
  end
end

system_user = User.find_or_create_by!(email: "system@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.role = "admin"
  u.time_zone = "America/New_York"
end

admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = u.password_confirmation = "password"
  u.role = "admin"
  u.time_zone = "America/New_York"
end

reviewer = User.find_or_create_by!(email: "reviewer@example.com") do |u|
  u.password = u.password_confirmation = "password"
  u.role = "reviewer"
  u.time_zone = "America/Los_Angeles"
end

readonly = User.find_or_create_by!(email: "readonly@example.com") do |u|
  u.password = u.password_confirmation = "password"
  u.role = "read_only"
  u.time_zone = "Europe/London"
end

puts "Created users:"
puts "  Admin     → admin@example.com     / password"
puts "  Reviewer  → reviewer@example.com  / password"
puts "  Read-only → readonly@example.com   / password"

charges = [
  { external_id: "ch_demo_001", amount_cents: 12500, created_at: 10.days.ago },
  { external_id: "ch_demo_002", amount_cents: 1999,  created_at: 15.days.ago },
  { external_id: "ch_demo_003", amount_cents: 8900,  created_at: 20.days.ago },
  { external_id: "ch_demo_004", amount_cents: 3499,  created_at: 8.days.ago },
  { external_id: "ch_demo_005", amount_cents: 4599,  created_at: 25.days.ago }
].map { |c| create_charge_if_missing(c) }

puts "Created #{charges.size} demo Charges"

def audit(dispute, actor, action, note: nil, details: {})
  dispute.case_actions.find_or_create_by!(
    actor: actor,
    action: action
  ) do |ca|
    ca.note = note
    ca.details = details
  end
end

create_dispute_if_missing(
  charge: charges[0],
  external_id: "dp_needs_response_001",
  status: "needs_response",
  opened_at: 5.days.ago,
  amount_cents: charges[0].amount_cents,
  currency: "USD",
  external_payload: {},
  last_event_id: "evt_fake_001"
) do |d|
  audit(d, admin, "webhook_processed", details: { event_type: "charge.dispute.created" })
end

create_dispute_if_missing(
  charge: charges[1],
  external_id: "dp_under_review_001",
  status: "under_review",
  opened_at: 12.days.ago,
  amount_cents: charges[1].amount_cents,
  external_payload: {}
) do |d|
  d.submit_evidence!
  audit(d, reviewer, "submit_evidence", note: "Customer emailed receipt")
  evidence = d.evidences.find_or_create_by!(kind: "receipt") do |e|
    e.metadata = { description: "Customer confirmation email" }
  end
  unless evidence.file.attached?
    evidence.file.attach(
      io: StringIO.new("Fake receipt PDF content"),
      filename: "receipt_2025.pdf",
      content_type: "application/pdf"
    )
  end
end

create_dispute_if_missing(
  charge: charges[2],
  external_id: "dp_won_001",
  status: "won",
  opened_at: 20.days.ago,
  closed_at: 3.days.ago,
  amount_cents: charges[2].amount_cents,
  external_payload: {}
) do |d|
  d.decide_win!
  audit(d, admin, "decide_win", note: "Bank ruled in our favor – strong evidence")
end

create_dispute_if_missing(
  charge: charges[3],
  external_id: "dp_lost_001",
  status: "lost",
  opened_at: 8.days.ago,
  closed_at: 1.day.ago,
  amount_cents: charges[3].amount_cents,
  external_payload: {}
) do |d|
  d.decide_lose!
  audit(d, admin, "decide_lose", note: "Insufficient proof – refunded")
end

create_dispute_if_missing(
  charge: charges[4],
  external_id: "dp_reopened_001",
  status: "needs_response",
  opened_at: 25.days.ago,
  amount_cents: charges[4].amount_cents,
  external_payload: {}
) do |d|
  d.decide_lose!
  audit(d, admin, "decide_lose", note: "First decision – lost")
  d.reopen!
  d.closed_at = nil
  d.save!
  audit(d, reviewer, "reopen", note: "New compelling evidence from customer support")
end

create_dispute_if_missing(
  charge: charges.sample,
  external_id: "dp_recent_001",
  status: "needs_response",
  opened_at: 1.day.ago,
  amount_cents: 8900,
  external_payload: {},
  last_event_id: "evt_recent_123"
)

puts "Created 6 Disputes in various states (safe to re-run!)"

puts "\nSeeding complete!"
puts "Total Charges:     #{Charge.count}"
puts "Total Disputes:    #{Dispute.count}"
puts "Total CaseActions: #{CaseAction.count}"
puts "Total Evidence:    #{Evidence.count}"
puts "Total Adjustments: #{Adjustment.count}"

puts "\nYou can now:"
puts "  Login as admin@example.com / password"
puts "  Run: docker-compose exec web bin/simulate_dispute_flow.rb"