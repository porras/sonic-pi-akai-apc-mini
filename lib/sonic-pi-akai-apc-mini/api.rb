module SonicPiAkaiApcMini
  module API
    def switch?(row, col)
      !!get("switch_#{Helpers.key(row, col)}")
    end

    # default `target` is 0-0.999 instead of 0.1 because many parameters have
    # [0,1) as range and throw an error when passed 1 (e.g. tb303 synth's res).
    # It's not the most common usecase, but for the common use case it makes no
    # difference so I think it's a good default.
    DEFAULT_TARGET = (0..0.999).freeze

    def fader(n, target = DEFAULT_TARGET)
      # TODO: Try to optimize speed, there is some latency because the
      # controller send a lot of events (too much granularity). It is in theory
      # possible to save some of it by `get`ting the value directly instead of
      # waiting for all the events to be processed.
      value = get("fader_#{n}", 0)
      Helpers.normalize(value, target)
    end

    def attach_fader(n, node, property, target = DEFAULT_TARGET)
      set_fader(n, target) do |value|
        control node, property => value
      end
    end

    def set_fader(n, target = DEFAULT_TARGET, &block)
      # first we just call the block with the current value, or 0
      block.call(Helpers.normalize(get("fader_#{n}", 0), target))
      # and set a loop that will cal it again on every change
      live_loop "global_fader_#{n}" do
        use_real_time
        value = sync("fader_#{n}")
        block.call(Helpers.normalize(value, target))
      end
    end

    def set_trigger(row, col, release: nil, light: true, ignores: true, &block)
      note_number = Helpers.key(row, col)
      set "reserved_#{note_number}", true
      @panel.set note_number => Controller.model.light_yellow if light
      live_loop "global_trigger_#{note_number}" do
        use_real_time
        v, = sync("note_on_#{note_number}")
        # if the event is "fake" we set level to 0
        with_fx :level, amp: (v == :ignore ? 0 : 1) do |fx|
          node = block.call
          if release
            sync("note_off_#{note_number}")
            control fx, amp_slide: release, amp: 0
            at(release * 1.1) { node.kill }
          end
        end
      end
      return unless ignores

      # Trigger "fake" notes with :ignore value so that the loop that is waiting
      # for a note silently goes for a new iteration (with the new definition)
      cue "note_on_#{note_number}", :ignore
      cue "note_off_#{note_number}", :ignore
    end

    # Same signature as `set_trigger` for convenience
    def reset_trigger(row, col, *_)
      note_number = Helpers.key(row, col)
      set "reserved_#{note_number}", false
      @panel.set note_number => (switch?(row, col) ? Controller.model.light_green : Controller.model.light_off)
      live_loop("global_trigger_#{note_number}") { stop }
    end

    def free_play(row, first_col, synth_name, notes, options = {})
      return if notes.empty?

      # consider only as many notes as they fit before the end of the row
      last_col = [Controller.model.grid_columns - 1, first_col + notes.size - 1].min
      (first_col..last_col).each.with_index do |col, i|
        set_trigger(row, col, release: options[:release] || 1) do
          # options.except(:release) in Ruby <= 2.7:
          options_except_release = options.reject { |k, _v| k == :release }
          synth synth_name, { note: notes[i], sustain: 9999 }.merge(options_except_release)
        end
      end
    end

    # Same signature as `free_play` for convenience
    def reset_free_play(row, first_col, _, notes, *_)
      return if notes.empty?

      # consider only as many notes as they fit before the end of the row
      last_col = [Controller.model.grid_columns - 1, first_col + notes.size - 1].min
      (first_col..last_col).each do |col|
        reset_trigger(row, col)
      end
    end

    def loop_rows(duration, rows)
      first_row = rows.keys.max
      Controller.model.grid_columns.times do |beat|
        Controller.model.grid_columns.times do |i|
          @panel[Helpers.key(first_row, i)] = if i == beat
                                                Controller.model.light_yellow
                                              elsif switch?(first_row, i)
                                                Controller.model.light_green
                                              else
                                                Controller.model.light_off
                                              end
        end
        @panel.flush
        rows.each do |row, sound|
          in_thread(&sound) if switch?(row, beat)
        end
        sleep duration.to_f / Controller.model.grid_columns
      end
    end

    def loop_rows_synth(duration, rows, notes, options = {})
      rows = rows.map.with_index do |row, i|
        [row, lambda do
                opts = options.respond_to?(:call) ? options.call : options
                play(notes[i], opts)
              end]
      end.to_h
      loop_rows(duration, rows)
    end

    def selector(row, col, values)
      # Still a bit messy but at least robust and relatively performant
      # TODO: It could be made _more_ performant by implementing some kind of cache (no need to redefine the triggers if nothing changed)
      identifier = "selector_#{row}_#{col}_#{values.size}"
      select_option = lambda do |i|
        set identifier, i
        values.size.times do |j|
          @panel[Helpers.key(row, col + j)] = if i == j
                                                Controller.model.light_green
                                              else
                                                Controller.model.light_red
                                              end
        end
        @panel.flush
      end
      values.size.times do |i|
        set_trigger(row, col + i, light: false, ignores: false) do
          select_option.call(i)
        end
      end
      select_option.call(0) unless get(identifier)
      values[get(identifier)]
    end

    def reset_selector(row, col, values)
      values.size.times do |i|
        reset_trigger(row, col + i)
      end
    end

    def initialize_akai(model)
      @panel ||= LightsPanel.new(default: 0) { |note, value| midi_note_on note, value }
      Controller.model = model
      # This loop manages faders. Whenever they change, the new value is stored via set,
      # and the corresponding light is turned on/off.
      live_loop :faders do
        use_real_time
        note_number, value = sync(Controller.model.midi_event(:control_change))
        fader_number = note_number - Controller.model.fader_offset
        set "fader_#{fader_number}", value
        if Controller.model.fader_light_offset
          light_note_number = note_number + Controller.model.fader_light_offset
          @panel.set light_note_number => (value.zero? ? Controller.model.light_off : Controller.model.light_red)
        end
      end

      live_loop :_note_on do
        use_real_time
        note_number, value = sync(Controller.model.midi_event(:note_on))
        cue "note_on_#{note_number}", value
      end

      live_loop :_note_off do
        use_real_time
        note_number, value = sync(Controller.model.midi_event(:note_off))
        cue "note_off_#{note_number}", value
      end

      # Manages the buttons in the grid as switches. Whenever one is pressed, we
      # check if it is "reserved" (for triggers or free play). If it is, we
      # ignore it (it has its own loop handling it). If it's not, we manage it
      # as a switch.
      live_loop :_switches do
        use_real_time
        n, _vel = sync(Controller.model.midi_event(:note_on))
        next if get("reserved_#{n}")

        new_value = !get("switch_#{n}", false)
        set "switch_#{n}", new_value
        @panel.set n => (new_value ? Controller.model.light_green : Controller.model.light_off)
      end
    end
  end
end
