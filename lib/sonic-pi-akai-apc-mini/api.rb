module SonicPiAkaiApcMini
  module API
    def switch?(line, col)
      n = (line * 8) + col
      !!get("switch_#{n}")
    end

    def fader(n, target = (0..1), _options = {})
      # TODO: Try to optimize speed, there is some latency because the
      # controller send a lot of events (too much granularity)
      value = get("fader_#{n}", 0)
      Helpers.normalize(value, target)
    end

    def attach_fader(n, node, property, target = (0..1))
      control node, property => fader(n, target)
      set "attached_fader_#{n}", node: node, property: property, target: target
    end

    def loop_rows(duration, rows)
      first_row = rows.keys.first
      8.times do |beat|
        prev = (beat - 1) % 8
        midi_note_on (first_row * 8) + prev, get("switch_#{(first_row * 8) + prev}") ? 1 : 0
        midi_note_on (first_row * 8) + beat, 5
        rows.each do |row, sound|
          sound.call if get("switch_#{(row * 8) + beat}")
        end
        sleep duration / 8.0
      end
    end

    def loop_rows_synth(duration, rows, notes, options = {})
      8.times do |beat|
        prev = (beat - 1) % 8
        midi_note_on (rows.first * 8) + prev, get("switch_#{(rows.first * 8) + prev}") ? 1 : 0
        midi_note_on (rows.first * 8) + beat, 5
        rows.each.with_index do |row, index|
          opts = options.respond_to?(:call) ? options.call : options
          play(notes[index], opts) if get("switch_#{(row * 8) + beat}")
        end
        sleep duration / 8.0
      end
    end

    def reset_free_play((row, col), size)
      size = size.size unless size.is_a?(Integer) # so we can pass the same ring
      Helpers.key_range([row, col], size).each do |key|
        midi_note_on key, 0
        set "free_play_#{key}", nil
      end
    end

    def free_play((row, col), notes, options = {})
      Helpers.key_range([row, col], notes.size).each.with_index do |key, i|
        midi_note_on key, 5
        set "free_play_#{key}", notes[i]
      end

      use_real_time

      message = sync(:free_play)
      note_control = play message[:note], { sustain: 9999 }.merge(options)
      set "free_play_playing_#{message[:key]}", note_control
    end

    def selector((row, col), values)
      # TODO: selector is quite messy. It can use a refactor and proper reset/cleanup (like free_play's).
      krange = Helpers.key_range([row, col], values.size)
      set "selector_values_#{krange}", values.ring
      set "selector_current_value_#{krange}", 0 if get("selector_current_value_#{krange}").nil?
      krange.each.with_index do |key, i|
        set "selector_keys_#{key}", krange.to_a
        midi_note_on key, i == get("selector_current_value_#{krange}") ? 1 : 3
      end
      values[get("selector_current_value_#{krange}")]
    end

    def initialize_akai
      # This loop manages faders. Whenever they change, the new value is stored via set,
      # and the corresponding light is turned on/off.
      live_loop :faders do
        use_real_time
        n, value = sync('/midi:apc_mini_apc_mini_midi_1_20_0:1/control_change')
        set "fader_#{n - 48}", value
        midi_note_on n - 48 + 64, value.zero? ? 0 : 1
        if attachment = get("attached_fader_#{n - 48}")
          normalized_value = Helpers.normalize(value, attachment[:target])
          control attachment[:node], attachment[:property] => normalized_value
        end
      end

      # Manages the buttons in the grid, both as switches and to "free play". Whenever one is,
      # pressed, we check if that row is being used to "free play". If it is, we play. If it's
      # not, we manage it as a switch.
      live_loop :switches_and_freeplay do
        use_real_time
        n, _vel = sync('/midi:apc_mini_apc_mini_midi_1_20_0:1/note_on')
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
        n, _vel = sync('/midi:apc_mini_apc_mini_midi_1_20_0:1/note_off')
        if note_control = get("free_play_playing_#{n}")
          release = note_control.args['release'] || note_control.info.arg_defaults[:release]
          control note_control, amp: 0, amp_slide: release
          at(release) { note_control.kill }
        end
      end
    end
  end
end

include SonicPiAkaiApcMini::API
