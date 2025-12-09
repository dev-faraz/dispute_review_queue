#!/usr/bin/env ruby
require File.expand_path('./config/environment', __dir__)

require 'httparty'
require 'json'
require 'optparse'

BASE_URL = "http://localhost:3000"
WEBHOOK_URL = "#{BASE_URL}/webhooks/disputes"

options = {
  charge_id: "ch_#{Time.now.to_i}",
  dispute_id: "dp_#{Time.now.to_i}",
  amount: 9999,
  currency: "usd"
}

OptionParser.new do |opts|
  opts.banner = "Usage: send_dispute_webhook.rb [options]"

  opts.on("--type TYPE", ["charge.dispute.created", "charge.dispute.updated", "charge.dispute.closed"]) do |v|
    options[:type] = v
  end

  opts.on("--charge ID", "Charge external ID") { |v| options[:charge_id] = v }
  opts.on("--dispute ID", "Dispute external ID") { |v| options[:dispute_id] = v }
  opts.on("--amount CENTS", Integer, "Amount in cents") { |v| options[:amount] = v }
  opts.on("--status STATUS", "For updated/closed: needs_response, under_review, won, lost") { |v| options[:status] = v }

  opts.on("-h", "--help", "Show help") do
    puts opts
    puts "\nExamples:"
    puts "  # Create dispute"
    puts "  ./send_dispute_webhook.rb --type charge.dispute.created --charge ch_123 --dispute dp_456"
    puts ""
    puts "  # Update to under_review"
    puts "  ./send_dispute_webhook.rb --type charge.dispute.updated --dispute dp_456 --status under_review"
    puts ""
    puts "  # Close as lost"
    puts "  ./send_dispute_webhook.rb --type charge.dispute.closed --dispute dp_456 --status lost"
    exit
  end
end.parse!

unless options[:type]
  puts "Error: --type is required!"
  puts "Use -h for help"
  exit 1
end

event_id = "evt_#{Time.now.to_i}_#{rand(1000)}"
timestamp = Time.now.to_i + 200

payload = {
  id: event_id,
  type: options[:type],
  created: timestamp,
  data: {
    object: {
      id: options[:dispute_id],
      charge: options[:charge_id],
      amount: options[:amount],
      currency: options[:currency],
      created: timestamp
    }
  }
}

if %w[charge.dispute.updated charge.dispute.closed].include?(options[:type])
  status = options[:status] || "under_review"
  payload[:data][:object][:status] = status
else
  payload[:data][:object][:status] = "needs_response"
end

puts "Sending #{options[:type]} → #{options[:dispute_id]}"
puts "→ POST #{WEBHOOK_URL}"
puts "Payload: #{JSON.pretty_generate(payload)}"
puts

response = HTTParty.post(
  WEBHOOK_URL,
  body: payload.to_json,
  headers: { "Content-Type" => "application/json" }
)

if response.code == 202
  puts "SUCCESS: Webhook queued (202)"
else
  puts "FAILED: #{response.code}"
  puts response.body
end

puts "\nRun again with different --type to continue the lifecycle!"