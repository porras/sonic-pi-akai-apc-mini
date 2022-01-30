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

    def loop_rows(duration, rows)
      first_row = rows.keys.max
      Controller.model.grid_columns.times do |beat|
        prev = (beat - 1) % 8
        prev_key = Helpers.key(first_row, prev)
        beat_key = Helpers.key(first_row, beat)
        midi_note_on prev_key, get("switch_#{prev_key}") ? Controller.model.light_green : Controller.model.light_off
        midi_note_on beat_key, Controller.model.light_yellow
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

    def reset_free_play(row, col, size)
      size = size.size unless size.is_a?(Integer) # so we can pass the same ring
      Helpers.key_range(row, col, size).each do |key|
        midi_note_on key, Controller.model.light_off
        set "free_play_#{key}", nil
      end
    end

    def free_play(row, col, notes, options = {})
      Helpers.key_range(row, col, notes.size).each.with_index do |key, i|
        midi_note_on key, Controller.model.light_yellow
        set "free_play_#{key}", notes[i]
      end

      use_real_time

      message = sync(:free_play)
      note_control = play message[:note], { sustain: 9999 }.merge(options)
      set "free_play_playing_#{message[:key]}", note_control
    end

    def selector(row, col, values)
      # TODO: selector is quite messy. It can use a refactor and proper reset/cleanup (like free_play's).
      krange = Helpers.key_range(row, col, values.size)
      set "selector_values_#{krange}", values.ring
      set "selector_current_value_#{krange}", 0 if get("selector_current_value_#{krange}").nil?
      krange.each.with_index do |key, i|
        set "selector_keys_#{key}", krange.to_a
        midi_note_on key, i == get("selector_current_value_#{krange}") ? 1 : 3
      end
      values[get("selector_current_value_#{krange}")]
    end

    def initialize_akai(model)
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
          midi_note_on light_note_number,
                       value.zero? ? Controller.model.light_off : Controller.model.light_red
        end
      end

      # Manages the buttons in the grid, both as switches, selectors, and to
      # "free play". Whenever one is pressed, we check if that row is being used
      # to "free play". If it is, we play. If it's not, we check if its used as
      # a selector and manage it. Otherwise, we manage it as a switch.
      live_loop :switches_and_freeplay do
        use_real_time
        n, _vel = sync(Controller.model.midi_event(:note_on))
        if note = get("free_play_#{n}")
          cue :free_play, note: note, key: n
        elsif keys = get("selector_keys_#{n}")
          keys.each do |k|
            midi_note_on k, 3
          end
          midi_note_on n, 1
          set "selector_current_value_#{keys.first}..#{keys.last}", n - keys.first
        else
          new_value = !get("switch_#{n}", false)
          set "switch_#{n}", new_value
          midi_note_on n, (new_value ? 1 : 0)
        end
      end

      live_loop :free_play_note_offs do
        use_real_time
        n, _vel = sync(Controller.model.midi_event(:note_off))
        if note_control = get("free_play_playing_#{n}")
          release = note_control.args['release'] || note_control.info.arg_defaults[:release]
          control note_control, amp: 0, amp_slide: release
          at(release) { note_control.kill }
        end
      end
    end
  end
end
