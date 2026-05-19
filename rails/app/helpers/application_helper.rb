module ApplicationHelper
  include Pagy::Frontend

  def status_badge(status)
    classes = case status.to_s
              when "scheduled"    then "bg-blue-900/40 text-blue-400"
              when "in_progress"  then "bg-yellow-900/40 text-yellow-400 animate-pulse"
              when "finished"     then "bg-gray-800 text-gray-400"
              when "postponed"    then "bg-orange-900/40 text-orange-400"
              when "cancelled"    then "bg-red-900/40 text-red-400"
              else                     "bg-gray-800 text-gray-400"
              end
    content_tag(:span, status.to_s.humanize, class: "px-2 py-0.5 rounded-full text-xs font-medium #{classes}")
  end

  def flag_for_country(country)
    flags = {
      "Deutschland" => "🇩🇪", "England" => "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Spanien" => "🇪🇸",
      "Italien"     => "🇮🇹", "Frankreich" => "🇫🇷", "Portugal" => "🇵🇹",
      "Niederlande" => "🇳🇱", "Europa" => "🇪🇺"
    }
    flags.fetch(country, "🏳")
  end
end
