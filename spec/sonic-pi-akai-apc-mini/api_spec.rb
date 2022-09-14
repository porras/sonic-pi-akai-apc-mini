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
end
