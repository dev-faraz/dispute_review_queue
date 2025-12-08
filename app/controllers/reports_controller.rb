class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_date_range

  def daily_volume
    authorize :report, :daily_volume?

    tz = current_user.time_zone
    from = @from.in_time_zone(tz).beginning_of_day
    to   = @to.in_time_zone(tz).end_of_day

    @daily_data = Dispute
      .where(opened_at: from..to)
      .group_by_day(:opened_at, time_zone: tz, format: "%Y-%m-%d")
      .count
      .transform_keys { |k| k.is_a?(String) ? k : k.strftime("%Y-%m-%d") }

    @daily_amounts = Dispute
      .where(opened_at: from..to)
      .group_by_day(:opened_at, time_zone: tz, format: "%Y-%m-%d")
      .sum(:amount_cents)

    @chart_data = @daily_data.map do |date, count|
      {
        date: date,
        count: count,
        amount: (@daily_amounts[date] || 0) / 100.0
      }
    end.sort_by { |h| h[:date] }
  end

  def time_to_decision
    authorize :report, :time_to_decision?

    tz = current_user.time_zone

    sql = <<-SQL.squish
      SELECT
        to_char(date_trunc('week', opened_at AT TIME ZONE '#{tz}'), 'YYYY "W"IW') AS week,
        percentile_cont(0.50) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (closed_at - opened_at))) AS p50_seconds,
        percentile_cont(0.90) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (closed_at - opened_at))) AS p90_seconds,
        COUNT(*) AS dispute_count
      FROM disputes
      WHERE closed_at IS NOT NULL AND opened_at IS NOT NULL
      GROUP BY date_trunc('week', opened_at AT TIME ZONE '#{tz}')
      ORDER BY week
    SQL

    results = ActiveRecord::Base.connection.execute(sql)

    @chart_data = results.map do |row|
      {
        week: row["week"],
        p50_hours: (row["p50_seconds"].to_f / 3600).round(1),
        p90_hours: (row["p90_seconds"].to_f / 3600).round(1),
        count: row["dispute_count"]
      }
    end
  end

  private

  def set_date_range
    @from = (params[:from].presence || 30.days.ago.to_date).to_date
    @to   = (params[:to].presence   || Date.current).to_date
  end
end