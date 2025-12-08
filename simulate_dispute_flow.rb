#!/usr/bin/env ruby

require File.expand_path('./config/environment', __dir__)

require 'httparty'
require 'json'
require 'colorize'
require 'multipart/post'
require 'open3'



BASE_URL = "http://localhost:3000"
ADMIN_CREDENTIALS = { email: "admin@example.com", password: "password" }
REVIEWER_CREDENTIALS = { email: "reviewer@example.com", password: "password" }

def log(step, message)
  puts "→ #{step.ljust(30)} #{message}"
end

def success(msg); log("SUCCESS", msg.green) end
def info(msg); log("INFO", msg.cyan) end
def error(msg); log("ERROR", msg.red) end
def wait(seconds = 1); sleep seconds end


def login_as(email, password)
  response = HTTParty.get("#{BASE_URL}/users/sign_in")
  cookie = response.headers['set-cookie']
  csrf = response.body[/<meta name="csrf-token" content="([^"]+)"/, 1]

  login_resp = HTTParty.post(
    "#{BASE_URL}/users/sign_in",
    body: {
      "user[email]" => email,
      "user[password]" => password,
      "authenticity_token" => csrf
    },
    headers: { "Cookie" => cookie }
  )

  raise "Login failed for #{email}" unless login_resp.code == 200
  { cookie: login_resp.headers['set-cookie'], csrf: csrf }
end

success "Starting full dispute lifecycle simulation"

charge_id = "ch_sim_#{Time.now.to_i}"
dispute_id = "dp_sim_#{Time.now.to_i}"
event_id_base = "evt_sim_#{Time.now.to_i}"

log "1. Send webhook", "charge.dispute.created"
payload = {
  id: "#{event_id_base}_1",
  type: "charge.dispute.created",
  data: {
    object: {
      id: dispute_id,
      charge: charge_id,
      amount: 9999,
      currency: "usd",
      status: "needs_response",
      created: Time.now.to_i
    }
  }
}.to_json

response = HTTParty.post(
  "#{BASE_URL}/webhooks/disputes",
  body: payload,
  headers: { "Content-Type" => "application/json" }
)

if response.code == 202
  success "Webhook queued (202)"
else
  error "Failed: #{response.body}"
  exit 1
end

wait 3

log "2. Send webhook", "charge.dispute.updated → under_review"
payload2 = {
  id: "#{event_id_base}_2",
  type: "charge.dispute.updated",
  data: {
    object: {
      id: dispute_id,
      charge: charge_id,
      amount: 9999,
      currency: "usd",
      status: "under_review",
      created: Time.now.to_i
    }
  }
}.to_json

HTTParty.post(
  "#{BASE_URL}/webhooks/disputes",
  body: payload2,
  headers: { "Content-Type" => "application/json" }
)

success "Dispute now under_review (via webhook)"
wait 2

info "3. Reviewer logs in and attaches evidence"
session = login_as(REVIEWER_CREDENTIALS[:email], REVIEWER_CREDENTIALS[:password])

resp = HTTParty.get("#{BASE_URL}/disputes", headers: { "Cookie" => session[:cookie] })
csrf = resp.body[/<meta name="csrf-token" content="([^"]+)"/, 1]

file_content = <<~TXT
  *** FAKE RECEIPT ***
  Merchant: Example Store
  Amount: $99.99
  Date: #{Time.now.strftime("%Y-%m-%d")}
  Customer confirmed delivery and satisfaction.
TXT

file = Tempfile.new(['receipt', '.txt'])
file.write(file_content)
file.rewind

upload = UploadIO.new(file, "text/plain", "receipt_2025.txt")

HTTParty.patch(
  "#{BASE_URL}/disputes/#{Dispute.last.id}/attach_evidence",
  body: {
    authenticity_token: csrf,
    kind: "receipt",
    note: "Customer emailed confirmation",
    file: upload
  },
  headers: { "Cookie" => session[:cookie] }
)

success "Evidence attached by reviewer"
wait 1

info "4. Admin logs in and decides WIN"
admin_session = login_as(ADMIN_CREDENTIALS[:email], ADMIN_CREDENTIALS[:password])

resp = HTTParty.get("#{BASE_URL}/disputes", headers: { "Cookie" => admin_session[:cookie] })
csrf = resp.body[/<meta name="csrf-token" content="([^"]+)"/, 1]

HTTParty.patch(
  "#{BASE_URL}/disputes/#{Dispute.last.id}/transition",
  body: {
    authenticity_token: csrf,
    action_type: "decide_win"
  },
  headers: { "Cookie" => admin_session[:cookie] }
)

success "Admin decided: WIN → Adjustment +9999 cents created"
wait 2

info "5. Simulate a LOST dispute"
lost_payload = {
  id: "#{event_id_base}_lost",
  type: "charge.dispute.closed",
  data: {
    object: {
      id: "dp_lost_001",
      charge: "ch_lost_001",
      amount: 5000,
      currency: "usd",
      status: "lost",
      created: Time.now.to_i
    }
  }
}.to_json

HTTParty.post(
  "#{BASE_URL}/webhooks/disputes",
  body: lost_payload,
  headers: { "Content-Type" => "application/json" }
)

success "Lost dispute processed → Adjustment -5000 cents"
wait 2

info "6. Reviewer re-opens the lost dispute"

resp = HTTParty.get("#{BASE_URL}/disputes", headers: { "Cookie" => session[:cookie] })
csrf = resp.body[/<meta name="csrf-token" content="([^"]+)"/, 1]

lost_dispute = Dispute.find_by(external_id: "dp_lost_001")
HTTParty.patch(
  "#{BASE_URL}/disputes/#{lost_dispute.id}/transition",
  body: {
    authenticity_token: csrf,
    action_type: "reopen",
    note: "New evidence from customer support"
  },
  headers: { "Cookie" => session[:cookie] }
)

success "Dispute re-opened → status back to needs_response"

puts "\n" + "="*60
puts "="*60
puts "Check your app at: http://localhost:3000"
puts "Login as: admin@example.com / password"
puts "="*60
