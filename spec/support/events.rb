class Events
  Event = Struct.new(:name, :value, :processed) do
    def initialize(name, value)
      super(name, value, false)
    end
  end

  def initialize(events)
    @events = []
    events.each do |beat, name, value|
      add(beat, name, value)
    end
  end

  def most_recent(beat, name)
    @events.select { |b, e| b <= beat && e.name == name }.max_by(&:first)&.last
  end

  def next_beat(beat)
    @events.map(&:first).sort.select { |b| b > beat }.first
  end

  def find(beat, name)
    @events.find { |b, e| b == beat && e.name == name && !e.processed }&.last
  end

  def add(beat, name, value)
    @events << [beat, Event.new(name, value)]
  end

  def ==(other)
    hash == other.hash
  end

  def hash
    @events.hash
  end
end
