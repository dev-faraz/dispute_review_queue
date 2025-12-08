require 'faker'

[Rake::Task["db:reset"]].each(&:reenable) if Rails.env.development?


system_user = User.find_or_create_by!(email: "system@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.role = "admin"
  u.time_zone = "America/New_York"
end

admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.role = "admin"
  u.time_zone = "America/New_York"
end

reviewer = User.find_or_create_by!(email: "reviewer@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.role = "reviewer"
  u.time_zone = "America/Los_Angeles"
end

readonly = User.find_or_create_by!(email: "readonly@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.role = "read_only"
  u.time_zone = "Europe/London"
end

puts "Created users:"
puts "  Admin     → admin@example.com     / password"
puts "  Reviewer  → reviewer@example.com  / password"
puts "  Read-only → readonly@example.com   / password"

charges = 5.times.map do |i|
  Charge.create!(
    external_id: "ch_#{Faker::Alphanumeric.alphanumeric(number: 16).upcase}",
    amount_cents: [1999, 4599, 8900, 12500, 3499].sample,
    currency: "USD",
    created_at: Faker::Time.between(from: 45.days.ago, to: 1.day.ago)
  )
end

puts "Created #{charges.size} Charges"

def audit(dispute, user, action, note: nil, details: {})
  dispute.case_actions.create!(
    actor: user,
    action: action,
    note: note,
    details: details
  )
end

dispute1 = Dispute.create!(
  charge: charges[0],
  external_id: "dp_needs_response_001",
  status: "needs_response",
  opened_at: 5.days.ago,
  amount_cents: charges[0].amount_cents,
  currency: "USD",
  external_payload: {},
  last_event_id: "evt_fake_001"
)
audit(dispute1, system_user, "webhook_processed", details: { event_type: "charge.dispute.created" })

dispute2 = Dispute.create!(
  charge: charges[1],
  external_id: "dp_under_review_001",
  status: "under_review",
  opened_at: 12.days.ago,
  amount_cents: charges[1].amount_cents,
  external_payload: {}
)
dispute2.submit_evidence!
audit(dispute2, reviewer, "submit_evidence", note: "Customer emailed receipt")
evidence = dispute2.evidences.create!(kind: "receipt", metadata: { description: "Customer confirmation email" })
evidence.file.attach(
  io: StringIO.new("Fake receipt PDF content"),
  filename: "receipt_2025.pdf",
  content_type: "application/pdf"
)

dispute3 = Dispute.create!(
  charge: charges[2],
  external_id: "dp_won_001",
  status: "won",
  opened_at: 20.days.ago,
  closed_at: 3.days.ago,
  amount_cents: charges[2].amount_cents,
  external_payload: {}
)
dispute3.decide_win!
audit(dispute3, admin, "decide_win", note: "Bank ruled in our favor – strong evidence")

dispute4 = Dispute.create!(
  charge: charges[3],
  external_id: "dp_lost_001",
  status: "lost",
  opened_at: 8.days.ago,
  closed_at: 1.day.ago,
  amount_cents: charges[3].amount_cents,
  external_payload: {}
)
dispute4.decide_lose!
audit(dispute4, admin, "decide_lose", note: "Insufficient proof – refunded")

dispute5 = Dispute.create!(
  charge: charges[4],
  external_id: "dp_reopened_001",
  status: "needs_response",
  opened_at: 25.days.ago,
  closed_at: 10.days.ago,
  amount_cents: charges[4].amount_cents,
  external_payload: {}
)
dispute5.decide_lose!
audit(dispute5, admin, "decide_lose", note: "First decision – lost")
dispute5.reopen!
dispute5.closed_at = nil
dispute5.save!
audit(dispute5, reviewer, "reopen", note: "New compelling evidence from customer support")

Dispute.create!(
  charge: charges.sample,
  external_id: "dp_recent_001",
  status: "needs_response",
  opened_at: 1.day.ago,
  amount_cents: 8900,
  external_payload: {},
  last_event_id: "evt_recent_123"
)

puts "Created 6 Disputes in various states (needs_response, under_review, won, lost, reopened)"

puts "\nSeeding complete!"
puts "Total Charges:     #{Charge.count}"
puts "Total Disputes:    #{Dispute.count}"
puts "Total CaseActions: #{CaseAction.count}"
puts "Total Evidence:    #{Evidence.count}"
puts "Total Adjustments: #{Adjustment.count}"

puts "\nYou can now:"
puts "  rails server"
puts "  bundle exec sidekiq"
puts "  Login as admin@example.com / password"