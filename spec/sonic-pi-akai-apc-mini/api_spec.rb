# Some kind of integration test. Not really, because it uses a fake SonicPi
# implementation, but it does a basic sanity check of the API and all its
# components.
RSpec.describe SonicPiAkaiApcMini::API do
  example 'basic test of the FakeSonicPi class :)' do
    sp = FakeSonicPi.new do
      live_loop :drums do
        sample :bd_haus
        sleep 0.5
      end

      live_loop :bass do
        play :c2
        sleep 1
      end
    end

    sp.run(2)

    expect(sp).to have_output(:sample, :bd_haus).at(0, 0.5, 1, 1.5)
    expect(sp).to have_output(:play, :c2).at(0, 1)
  end

  describe 'faders' do
    example 'direct use through #fader method' do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        live_loop :drum do
          sample :bd_haus, amp: fader(0)
          sleep 1
        end
      end

      sp.run(2, events: [
               [0.5, '/midi:apc_mini*/control_change', [48, 64]],
               [1.5, '/midi:apc_mini*/control_change', [48, 128]]
             ])

      expect(sp).to have_output(:sample, :bd_haus, amp: 0).at(0)
      expect(sp).to have_output(:sample, :bd_haus, amp: be_within(0.05).of(0.5)).at(1)
      expect(sp).to have_output(:sample, :bd_haus, amp: be_within(0.05).of(1)).at(2)
    end

    example 'moving faders turns lights on and off' do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)
      end

      sp.run(2, events: [
               [0.5, '/midi:apc_mini*/control_change', [48, 64]],
               [1.5, '/midi:apc_mini*/control_change', [48, 0]]
             ])

      expect(sp).to have_output(:midi_note_on, 64, 3).at(0.5)
      expect(sp).to have_output(:midi_note_on, 64, 0).at(1.5)
    end

    example 'using set_fader to control volume' do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)
        set_fader(8, 0..2) { |v| set_volume! v }
      end

      sp.run(2, events: [
               [0.5, '/midi:apc_mini*/control_change', [56, 64]],
               [1.5, '/midi:apc_mini*/control_change', [56, 127]]
             ])

      expect(sp).to have_output(:set_volume!, be_within(0.05).of(0)).at(0)
      expect(sp).to have_output(:set_volume!, be_within(0.05).of(1)).at(0.5)
      expect(sp).to have_output(:set_volume!, be_within(0.05).of(2)).at(1.5)
    end

    example 'using attach_fader to control a synth' do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        live_loop :synth do
          node = play(:c4, cutoff: fader(0, 60..120))
          attach_fader 0, node, :cutoff, 60..120
          sleep 1
        end
      end

      sp.run(2, events: [
               [0.25, '/midi:apc_mini*/control_change', [48, 64]],
               [1.25, '/midi:apc_mini*/control_change', [48, 127]]
             ])

      expect(sp).to have_output(:play, :c4, cutoff: be_within(0.5).of(60)).at(0)
      expect(sp).to have_output(:control, a_node(:play, :c4), cutoff: be_within(0.5).of(60)).at(0)

      expect(sp).to have_output(:control, a_node(:play, :c4), cutoff: be_within(0.5).of(90)).at(0.25)

      expect(sp).to have_output(:play, :c4, cutoff: be_within(0.5).of(90)).at(1)
      expect(sp).to have_output(:control, a_node(:play, :c4), cutoff: be_within(0.5).of(90)).at(1)

      expect(sp).to have_output(:control, a_node(:play, :c4), cutoff: be_within(0.5).of(120)).at(1.25)
    end
  end

  describe 'triggers' do
    example 'simple trigger' do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        set_trigger(0, 0) { sample :bd_haus }
        set_trigger(0, 1) { sample :bd_ada }
      end

      sp.run(2, events: [
               [0.30, '/midi:apc_mini*/note_on', [0, 127]],
               [0.35, '/midi:apc_mini*/note_off', [0, 127]],
               [1.30, '/midi:apc_mini*/note_on', [0, 127]],
               [1.35, '/midi:apc_mini*/note_off', [0, 127]],
               [1.40, '/midi:apc_mini*/note_on', [1, 127]],
               [1.45, '/midi:apc_mini*/note_off', [1, 127]]
             ])

      expect(sp).to have_output(:midi_note_on, 0, 5).at(0)
      expect(sp).to have_output(:midi_note_on, 1, 5).at(0)
      expect(sp).to have_output(:sample, :bd_haus).at(0.3, 1.3)
      expect(sp).to have_output(:sample, :bd_ada).at(1.4)
    end

    example 'with release' do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        set_trigger(0, 0, release: 0.3) { sample :bass_trance_c }
      end

      sp.run(2, events: [
               [0.30, '/midi:apc_mini*/note_on', [0, 127]],
               [0.35, '/midi:apc_mini*/note_off', [0, 127]],
               [1.30, '/midi:apc_mini*/note_on', [0, 127]],
               [1.45, '/midi:apc_mini*/note_off', [0, 127]]
             ])

      expect(sp).to have_output(:sample, :bass_trance_c).at(0.3, 1.3)
      expect(sp).to have_output(:control, a_node(:fx, :level, amp: 1), amp: 0, amp_slide: 0.3).at(0.35, 1.45)
    end
  end

  describe 'switches' do
    example do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        live_loop :noise do
          sample :vynil_hiss if switch?(0, 0)
          sleep 1
        end
      end

      sp.run(4, events: [
               [0.5, '/midi:apc_mini*/note_on', [0, 127]],
               [0.55, '/midi:apc_mini*/note_off', [0, 127]],
               [3.5, '/midi:apc_mini*/note_on', [0, 127]],
               [3.55, '/midi:apc_mini*/note_off', [0, 127]]
             ])

      # light goes green when key pressed and off when pressed again
      expect(sp).to have_output(:midi_note_on, 0, 1).at(0.5)
      expect(sp).to have_output(:midi_note_on, 0, 0).at(3.5)

      # noise at the exact beats where the switch was on
      expect(sp).not_to have_output(:sample, :vynil_hiss).at(0, 4)
      expect(sp).to have_output(:sample, :vynil_hiss).at(1, 2, 3)
    end
  end

  describe 'free_play' do
    example do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        free_play(0, 0, :piano, %i[c3 d3 e3], amp: 2, release: 0.5)
      end

      sp.run(3, events: [
               [0.30, '/midi:apc_mini*/note_on', [0, 127]],
               [0.35, '/midi:apc_mini*/note_off', [0, 127]],
               [1.30, '/midi:apc_mini*/note_on', [1, 127]],
               [1.45, '/midi:apc_mini*/note_off', [1, 127]],
               [2.30, '/midi:apc_mini*/note_on', [2, 127]],
               [2.45, '/midi:apc_mini*/note_off', [2, 127]]
             ])

      # yellow lights
      expect(sp).to have_output(:midi_note_on, 0, 5).at(0)
      expect(sp).to have_output(:midi_note_on, 1, 5).at(0)
      expect(sp).to have_output(:midi_note_on, 2, 5).at(0)

      # three notes
      expect(sp).to have_output(:synth, :piano, note: :c3, amp: 2, sustain: 9999).at(0.3)
      expect(sp).to have_output(:synth, :piano, note: :d3, amp: 2, sustain: 9999).at(1.3)
      expect(sp).to have_output(:synth, :piano, note: :e3, amp: 2, sustain: 9999).at(2.3)

      # their releases
      expect(sp).to have_output(:control, a_node(:fx, :level, amp: 1), amp: 0, amp_slide: 0.5).at(0.35, 1.45, 2.45)
    end
  end

  describe 'loop_rows' do
    example do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        live_loop :drums do
          loop_rows(8,
                    1 => -> { sample :bd_haus },
                    0 => -> { sample :sn_generic })
        end
      end

      # unrealistic but easy to test: we punch the whole pattern just before the
      # second repetition will start:
      sp.run(16, events: [
               # kick on 1/4 and 3/4
               [7.99, '/midi:apc_mini*/note_on', [8, 127]],
               [7.99, '/midi:apc_mini*/note_on', [12, 127]],
               # snare on 2/4 and 4/4
               [7.99, '/midi:apc_mini*/note_on', [2, 127]],
               [7.99, '/midi:apc_mini*/note_on', [6, 127]]
             ])

      # in the first 8 beats, just the yellow light in the first row...
      expect(sp).to have_output(:midi_note_on, 8, 5).at(0)
      expect(sp).to have_output(:midi_note_on, 9, 5).at(1)
      expect(sp).to have_output(:midi_note_on, 10, 5).at(2)
      expect(sp).to have_output(:midi_note_on, 11, 5).at(3)
      expect(sp).to have_output(:midi_note_on, 12, 5).at(4)
      expect(sp).to have_output(:midi_note_on, 13, 5).at(5)
      expect(sp).to have_output(:midi_note_on, 14, 5).at(6)
      expect(sp).to have_output(:midi_note_on, 15, 5).at(7)
      # ...getting turned off 1 beat later
      expect(sp).to have_output(:midi_note_on,  8, 0).at(1)
      expect(sp).to have_output(:midi_note_on,  9, 0).at(2)
      expect(sp).to have_output(:midi_note_on, 10, 0).at(3)
      expect(sp).to have_output(:midi_note_on, 11, 0).at(4)
      expect(sp).to have_output(:midi_note_on, 12, 0).at(5)
      expect(sp).to have_output(:midi_note_on, 13, 0).at(6)
      expect(sp).to have_output(:midi_note_on, 14, 0).at(7)
      expect(sp).to have_output(:midi_note_on, 15, 0).at(8)

      # when the buttons are pressed, their lights should turn green
      expect(sp).to have_output(:midi_note_on, 8, 1).at(7.99)
      expect(sp).to have_output(:midi_note_on, 12, 1).at(7.99)
      expect(sp).to have_output(:midi_note_on, 2, 1).at(7.99)
      expect(sp).to have_output(:midi_note_on, 6, 1).at(7.99)

      # in the second 8 beats, we should play!
      expect(sp).to have_output(:sample, :bd_haus).at(8, 12)
      expect(sp).to have_output(:sample, :sn_generic).at(10, 14)

      # the yellow light should keep on...
      expect(sp).to have_output(:midi_note_on, 8, 5).at(8)
      expect(sp).to have_output(:midi_note_on, 9, 5).at(9)
      expect(sp).to have_output(:midi_note_on, 10, 5).at(10)
      expect(sp).to have_output(:midi_note_on, 11, 5).at(11)
      expect(sp).to have_output(:midi_note_on, 12, 5).at(12)
      expect(sp).to have_output(:midi_note_on, 13, 5).at(13)
      expect(sp).to have_output(:midi_note_on, 14, 5).at(14)
      expect(sp).to have_output(:midi_note_on, 15, 5).at(15)
      # ...but this time 1st and 5th should turn green, not off!
      expect(sp).to have_output(:midi_note_on,  8, 1).at(9)
      expect(sp).to have_output(:midi_note_on,  9, 0).at(10)
      expect(sp).to have_output(:midi_note_on, 10, 0).at(11)
      expect(sp).to have_output(:midi_note_on, 11, 0).at(12)
      expect(sp).to have_output(:midi_note_on, 12, 1).at(13)
      expect(sp).to have_output(:midi_note_on, 13, 0).at(14)
      expect(sp).to have_output(:midi_note_on, 14, 0).at(15)
      expect(sp).to have_output(:midi_note_on, 15, 0).at(16)
    end
  end

  describe 'loop_rows_synth' do
    example do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        live_loop :bass do
          loop_rows_synth(8, 0..1, %i[c2 d2])
        end
      end

      # unrealistic but easy to test: we punch the whole pattern just before the
      # second repetition will start:
      sp.run(16, events: [
               # d2 on 1/4 and 3/4
               [7.99, '/midi:apc_mini*/note_on', [8, 127]],
               [7.99, '/midi:apc_mini*/note_on', [12, 127]],
               # c2 on 2/4 and 4/4
               [7.99, '/midi:apc_mini*/note_on', [2, 127]],
               [7.99, '/midi:apc_mini*/note_on', [6, 127]]
             ])

      # no need to test the lights again, loop_rows tests them

      # in the second 8 beats, we should play!
      expect(sp).to have_output(:play, :d2, {}).at(8, 12)
      expect(sp).to have_output(:play, :c2, {}).at(10, 14)
    end

    example 'with options' do
      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        live_loop :bass do
          loop_rows_synth(8, 0..0, [:c2], amp: 2)
        end
      end

      sp.run(16, events: [
               [7.99, '/midi:apc_mini*/note_on', [0, 127]]
             ])

      expect(sp).to have_output(:play, :c2, amp: 2).at(8)
    end

    example 'with dynamic options' do
      dummy = double(:whatever)
      allow(dummy).to receive(:something).and_return(2, 3, 4) # fake a ring or whatever

      sp = FakeSonicPi.new do
        initialize_akai(:apc_mini)

        live_loop :bass do
          loop_rows_synth(8, 0..0, [:c2], -> { { amp: dummy.something } })
        end
      end

      sp.run(8, events: [
               [0, '/midi:apc_mini*/note_on', [1, 127]],
               [0, '/midi:apc_mini*/note_on', [2, 127]],
               [0, '/midi:apc_mini*/note_on', [3, 127]]
             ])

      expect(sp).to have_output(:play, :c2, amp: 2).at(1)
      expect(sp).to have_output(:play, :c2, amp: 3).at(2)
      expect(sp).to have_output(:play, :c2, amp: 4).at(3)
    end
  end
end
