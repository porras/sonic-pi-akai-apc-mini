require 'fiber' # for Ruby < 3.0

class FakeSonicPi
  class SleepForever < StandardError; end
  class NoSleep < StandardError; end

  include SonicPiAkaiApcMini::API

  attr_reader :output

  def initialize(&definition)
    @definition = definition
    @output = {}
  end

  # MAGIC :D I mean Fibers ;)
  def run(beats, events: {})
    @events = events
    instance_eval(&@definition)
    fibers = live_loops.to_h do |name, block|
      f = Fiber.new do
        Thread.current[:beat] = 0.0
        until Thread.current[:beat] > beats
          before = Thread.current[:beat]
          instance_eval(&block)
          raise NoSleep, "live_loop #{name} didn't sleep" if Thread.current[:beat] == before
        end
      rescue SleepForever
        # nothing, let the fiber die
      end
      [f, 0.0]
    end
    loop do
      next_fiber, _b = fibers.select { |f, _b| f.alive? }.min_by { |_f, beat| beat }
      break unless next_fiber

      fibers[next_fiber] = next_fiber.resume
    end
    output
  end

  def live_loop(name, &block)
    live_loops[name] = block
  end

  def live_loops
    @_live_loops ||= {}
  end

  # sleep the fast way ;)
  def sleep(n)
    Fiber.yield Thread.current[:beat] += n
  end

  def sync(event_name)
    # find closest future event (if any)
    beat, event = @events.select do |beat, event|
                    beat > Thread.current[:beat] && event[:name] == event_name
                  end.min_by { |beat, _e| beat }
    if beat
      # "sleep" until then
      Fiber.yield Thread.current[:beat] = beat
      # return it when we're back
      event[:value]
    else
      raise SleepForever
    end
  end

  def get(name, default = nil)
    # find most recent past event (if any)
    _b, event = @events.select do |beat, event|
                  beat <= Thread.current[:beat] && event[:name] == name
                end.max_by { |beat, _e| beat }
    (event && event[:value]) || default
  end

  def set(name, value)
    # TODO: this should be an array (multiple events in same beat)
    @events[Thread.current[:beat]] = { name: name, value: value }
  end

  # commands we store as output
  %i[play sample midi_note_on].each do |cmd|
    define_method(cmd) do |*args|
      @output[Thread.current[:beat]] ||= []
      @output[Thread.current[:beat]] << [cmd, *args]
    end
  end

  # no-ops (sonic pi commands whose effect is not relevant here, but need to be
  # implemented so that the test doesn't fail)
  [:use_real_time].each do |cmd|
    define_method(cmd) { |*_args| }
  end
end
