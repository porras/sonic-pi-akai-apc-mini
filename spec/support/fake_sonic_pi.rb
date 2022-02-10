require 'fiber' # for Ruby < 3.0
require 'support/events'

class FakeSonicPi
  class NoSleep < StandardError; end

  include SonicPiAkaiApcMini::API

  attr_reader :output

  def initialize(&definition)
    @definition = definition
    @output = Events.new
    @events = Events.new
    @beat = 0.0
    @fibers = {}
  end

  # MAGIC :D I mean Fibers ;)
  def run(beats, events: [])
    @events.add_batch(events)
    instance_eval(&@definition)
    loop do
      waiting_fibers, scheduled_fibers = @fibers.partition { |_f, b| b.nil? }
      scheduled_fibers.reject! { |_f, b| b > beats }

      # give all waiting fibers a chance
      events_before = @events.dup
      waiting_fibers.each do |f, _b|
        @fibers[f] = f.resume
      end
      # if any of them added an event, do it again
      next if events_before != @events

      # find next scheduled fiber (and for when is it scheduled?)
      next_fiber, next_beat = scheduled_fibers.min_by { |_f, beat| beat }

      # is there any event to happen before next_beat? if so, process that before
      next_beat_with_event = @events.next_beat(@beat)
      if next_beat_with_event && (next_beat.nil? || next_beat_with_event < next_beat)
        @beat = next_beat_with_event
        next
        # otherwise proceed with the next scheduled fiber
      elsif next_fiber
        @beat = next_beat
        @fibers[next_fiber] = next_fiber.resume
        # and if there is none, then we're done \o/
      else
        break
      end
    end
  end

  def live_loop(name, &block)
    f = Fiber.new do
      loop do
        Thread.current[:slept] = false
        instance_eval(&block)
        raise NoSleep, "live_loop #{name} didn't sleep" unless Thread.current[:slept]
      end
    end
    @fibers[f] = @beat
  end

  # sleep the fast way ;)
  def sleep(n)
    Thread.current[:slept] = true
    Fiber.yield @beat + n
  end

  def sync(event_name)
    loop do
      Thread.current[:slept] = true
      # find event in current beat and return its value, otherwise let the other
      # fibers progress, then try again
      if event = @events.find(@beat, event_name)
        event.processed = true
        return event.value
      else
        Fiber.yield nil
      end
    end
  end

  def get(name, default = nil)
    if event = @events.most_recent(@beat, name)
      event.value
    else
      default
    end
  end

  def set(name, value)
    @events.add(@beat, name, value)
  end

  alias_method :cue, :set

  # commands we store as output, returning a (fake) node
  %i[play sample control midi_note_on set_volume!].each do |command|
    define_method(command) do |*args|
      @output.add @beat, command, args
      Node.new(command, args)
    end
  end

  Node = Struct.new(:command, :args)

  # no-ops (sonic pi commands whose effect is not relevant here, but need to be
  # implemented so that the test doesn't fail)
  [:use_real_time].each do |cmd|
    define_method(cmd) { |*_args| }
  end
end
