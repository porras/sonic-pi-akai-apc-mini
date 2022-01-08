use_midi_defaults port: "apc_mini_apc_mini_midi_1_20_0"

define :initialize_akai do
  # This loop manages faders. Whenever they change, the new value is stored via set,
  # and the corresponding light is turned on/off.
  live_loop :faders do
    use_real_time
    n, value = sync("/midi:apc_mini_apc_mini_midi_1_20_0:1/control_change")
    set "fader_#{n}", value
    midi_note_on n + 16, value.zero? ? 0 : 1
    if attachment = get("attached_fader_#{n}")
      target = deserialize_target(attachment[:target])
      normalized_value = normalize(value, target)
      control attachment[:node], attachment[:property] => normalized_value
    end
  end
  
  # Manages the buttons in the grid, both as switches and to "free play". Whenever one is,
  # pressed, we check if that row is being used to "free play". If it is, we play. If it's
  # not, we manage it as a switch.
  live_loop :switches_and_freeplay do
    use_real_time
    n, _vel = sync("/midi:apc_mini_apc_mini_midi_1_20_0:1/note_on")
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
    n, _vel = sync("/midi:apc_mini_apc_mini_midi_1_20_0:1/note_off")
    if note_control = get("free_play_playing_#{n}")
      release = note_control.args["release"] || note_control.info.arg_defaults[:release]
      control note_control, amp: 0, amp_slide: release
      at(release) { note_control.kill }
    end
  end
  
  define :switch? do |line, col|
    n = line * 8 + col
    !!get("switch_#{n}")
  end
  
  define :fader do |n, target = (0..1), options = {}|
    # TODO: Optimize speed, there is some latency
    value = get("fader_#{n + 47}", 0)
    normalize(value, target)
  end
  
  define :normalize do |value, target|
    value /= 127.0
    target = (-1..1) if target == :pan
    case target
    when Range
      target.begin + value * (target.end - target.begin)
    when Array, SonicPi::Core::RingVector
      index = ((target.size - 1) * value).round
      target[index]
    end
  end
  
  define :loop_rows do |duration, rows|
    first_row = rows.keys.first
    8.times do |beat|
      prev = (beat - 1) % 8
      midi_note_on first_row * 8 + prev, get("switch_#{first_row * 8 + prev}") ? 1 : 0
      midi_note_on first_row * 8 + beat, 5
      rows.each do |row, sound|
        sound.call if get("switch_#{row * 8 + beat}")
      end
      sleep duration / 8.0
    end
  end
  
  define :loop_rows_synth do |duration, rows, notes, options = {}|
    8.times do |beat|
      prev = (beat - 1) % 8
      midi_note_on rows.first * 8 + prev, get("switch_#{rows.first * 8 + prev}") ? 1 : 0
      midi_note_on rows.first * 8 + beat, 5
      rows.each.with_index do |row, index|
        opts = options.respond_to?(:call) ? options.call : options
        play(notes[index], opts) if get("switch_#{row * 8 + beat}")
      end
      sleep duration / 8.0
    end
  end
  
  define :attach_fader do |n, node, property, target = (0..1)|
    control node, property => fader(n, target)
    set "attached_fader_#{n + 47}", node: node, property: property, target: serialize_target(target)
  end
  
  define :serialize_target do |target|
    case target
    when Range
      [:range, [target.first, target.last]]
    else
      [:as_is, target]
    end
  end
  
  define :deserialize_target do |serialized|
    case serialized
    in [:range, [a, b]]
      (a..b)
    in [:as_is, value]
      value
    end
  end
  
  define :reset_free_play do |(row, col), size|
    size = size.size unless size.is_a?(Integer) # so we can pass the same ring
    key_range([row, col], size).each do |key|
      midi_note_on key, 0
      set "free_play_#{key}", nil
    end
  end
  
  define :key_range do |(row, col), max_size|
    first = row * 8 + col
    last = [row * 8 + 7, first + max_size - 1].min
    (first..last)
  end
  
  define :free_play do |(row, col), notes, options = {}|
    key_range([row, col], notes.size).each.with_index do |key, i|
      midi_note_on key, 5
      set "free_play_#{key}", notes[i]
    end
    
    use_real_time
    
    message = sync(:free_play)
    note_control = play message[:note], {sustain: 9999}.merge(options)
    set "free_play_playing_#{message[:key]}", note_control
  end
  
  define :selector do |(row, col), values|
    # TODO: selector is quite messy. It can use a refactor and proper reset/cleanup (like free_play's).
    krange = key_range([row, col], values.size)
    set "selector_values_#{krange.to_s}", values.ring
    set "selector_current_value_#{krange.to_s}", 0 if get("selector_current_value_#{krange.to_s}").nil?
    krange.each.with_index do |key, i|
      set "selector_keys_#{key}", krange.to_a
      midi_note_on key, i == get("selector_current_value_#{krange.to_s}") ? 1 : 3
    end
    values[get("selector_current_value_#{krange.to_s}")]
  end
end
