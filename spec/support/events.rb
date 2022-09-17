class Events
  attr_reader :events

  Event = Struct.new(:name, :value, :processed_by) do
    def initialize(name, value)
      super(name, value, Set.new)
    end
  end

  def initialize
    @events = []
  end

  def most_recent(beat, name)
    @events.select { |b, e| b <= beat && e.name == name }.max_by(&:first)&.last
  end

  def next_beat(beat)
    @events.map(&:first).sort.select { |b| b > beat }.first
  end

  def find(beat, name)
    @events.find { |b, e| b == beat && e.name == name && !e.processed_by.include?(Fiber.current) }&.last
  end

  def add_batch(events)
    events.each { |b, n, v| add b, n, v }
  end

  def add(beat, name, value)
    @events << [beat, Event.new(name, value)]
  end

  def ==(other)
    other.is_a?(self.class) && @events == other.events
  end
end
