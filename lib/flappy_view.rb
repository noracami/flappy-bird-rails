require "live"

class FlappyView < Live::View
  WIDTH = 420
  HEIGHT = 640
  GRAVITY = -9.8 * 50.0
  FLAPPING = 6.0 * 50.0

  class BoundingBox
    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
    end

    attr_accessor :x, :y, :width, :height

    def right
      @x + @width
    end

    def top
      @y + @height
    end

    # Intersection computed by separating planes:
    def intersects?(other)
      !(
        self.right < other.x ||
        self.x > other.right ||
        self.top < other.y ||
        self.y > other.top
      )
    end
  end

  class Bird < BoundingBox
    def initialize(x = 30, y = HEIGHT / 2, width: 34, height: 24)
      super(x, y, width, height)
      @velocity = 0.0
    end

    def step(dt)
      @velocity += GRAVITY * dt
      @y += @velocity * dt

      if @y > HEIGHT
        @y = HEIGHT
        @velocity = 0.0
      end
    end

    def flap
      @velocity = FLAPPING
    end

    def render(builder)
      builder.inline_tag(:div, class: "bird", style: "left: #{@x}px; bottom: #{@y}px; width: #{@width}px; height: #{@height}px;")
    end
  end


  def render(builder)
    builder.inline_tag(:div, class: "flappy") do
      builder.text("Flappy View")
    end
  end
end
