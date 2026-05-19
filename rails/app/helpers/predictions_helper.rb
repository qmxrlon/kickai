module PredictionsHelper
  def probability_color(prob)
    case prob.to_f
    when 0.65..1.0  then "text-emerald-400"
    when 0.45..0.65 then "text-yellow-400"
    else                 "text-red-400"
    end
  end

  def confidence_bar_color(score)
    case score.to_f
    when 70..100 then "bg-emerald-500"
    when 50..70  then "bg-yellow-500"
    else              "bg-red-500"
    end
  end
end
