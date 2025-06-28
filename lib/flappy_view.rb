require "live"

class FlappyView < Live::View
  def render(builder)
    builder.inline_tag(:div, class: "flappy") do
      builder.text("Flappy View")
    end
  end
end
