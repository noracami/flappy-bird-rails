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
      rotation = (@velocity / 20.0).clamp(-40.0, 40.0)
      rotate = "rotate(#{rotation}deg)"
      builder.inline_tag(:div, class: "bird", style: "left: #{@x}px; bottom: #{@y}px; width: #{@width}px; height: #{@height}px; transform: #{rotate};")
    end
  end

  class Pipe < BoundingBox
    def initialize(x, y, offset = 100, random: 0, width: 44, height: 700)
      @x = x
      @y = y
      @offset = offset

      @width = width
      @height = height

      @random = random
    end

    def right
      @x + @width
    end

    def top
      @y + @offset
    end

    def bottom
      (@y - @offset) - @height
    end

    def scaled_random
      @random.rand(-0.8..0.8) * 0.5
    end

    # Reset the pipe to the right side of the screen.
    def reset!
      @x = WIDTH + (@random.rand * 10)
      @y = HEIGHT / 2 + (HEIGHT / 2 * scaled_random)
    end

    # Move the pipe to the left by a fixed amount.
    def step(dt)
      @x -= 100 * dt

      # Reset the pipe if it goes off the left side of the screen.
      if self.right < 0
        reset!
      end
    end

    def upper_bounding_box
      BoundingBox.new(@x, self.bottom, @width, @height)
    end

    def lower_bounding_box
      BoundingBox.new(@x, self.top, @width, @height)
    end

    # Whether a given bounding box intersects with the pipe segments.
    def intersects?(other)
      upper_bounding_box.intersects?(other) ||
      lower_bounding_box.intersects?(other)
    end

    # Render the pipe segments.
    def render(builder)
      size = "width: #{@width}px; height: #{@height}px;"

      builder.inline_tag(:div, class: "pipe",
        style: "left: #{@x}px; bottom: #{self.bottom}px; #{size}"
      )

      builder.inline_tag(:div, class: "pipe",
        style: "left: #{@x}px; bottom: #{self.top}px; #{size}"
      )
    end
  end

  def initialize(...)
    super(...)
    @game = nil
    @bird = nil
    @pipes = nil

    @random = nil
  end

  # Reset the game state.
  def reset!
    @random ||= Random.new

    @bird = Bird.new
    @pipes = [
      Pipe.new(WIDTH * 1/2, HEIGHT / 2, random: @random),
      Pipe.new(WIDTH * 2/2, HEIGHT / 2, random: @random)
    ]
    @game ||= self.run!
  end

  # Update the game state by one time step.
  def step(dt)
    @bird.step(dt)

    @pipes.each do |pipe|
      pipe.step(dt)

      if pipe.intersects?(@bird)
        return reset!
      end
    end

    if @bird.top < 0
      reset!
    end
  end

  # Run the game loop, updating the game state every `dt` seconds.
  def run!(dt = 1.0 / 60.0)
    Async do
      while true
        self.step(dt)
        self.update!
        sleep(dt)
      end
    end
  end

  # Bind the view to the page, when the client connects.
  def bind(page)
    super
    self.reset!
  end

  # Close the game loop when the client disconnects.
  def close
    if @game
      @game.stop
      @game = nil
    end

    super
  end

  # Handle events from the client.
  def handle(event)
    case event[:type]
    when "keypress", "touchstart"
      detail = event[:detail]
      if detail[:key] == " " || detail[:touch]
        @bird&.flap
      end
    end
  end

  # Forward keypress events from the client to the server.
  def forward_keypress
    "live.forwardEvent(#{JSON.dump(@id)}, event, {key: event.key, touch: (event.type === 'touchstart')});"
  end

  # Render the view.
  def render(builder)
    builder.tag(:div, class: "flappy", tabIndex: 0, onKeyPress: forward_keypress, onTouchStart: forward_keypress) do
      @bird&.render(builder)
      @pipes&.each do |pipe|
        pipe.render(builder)
      end
    end
  end
end
