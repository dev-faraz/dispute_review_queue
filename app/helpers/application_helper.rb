module ApplicationHelper
  def user_time(time)
    return "Never" unless time
    time.in_time_zone(current_user.time_zone).strftime("%b %d, %Y at %I:%M %p %Z")
  end

  def user_date(time)
    return "—" unless time
    time.in_time_zone(current_user.time_zone).strftime("%b %d, %Y")
  end
end