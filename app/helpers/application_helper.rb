module ApplicationHelper
  def time_duration_in_words(duration_in_seconds)
    return "0 minutes" if duration_in_seconds < 60

    hours = (duration_in_seconds / 3600).to_i
    minutes = ((duration_in_seconds % 3600) / 60).to_i

    if hours > 0
      "#{hours} #{'hour'.pluralize(hours)} #{minutes} #{'minute'.pluralize(minutes)}"
    else
      "#{minutes} #{'minute'.pluralize(minutes)}"
    end
  end
end
