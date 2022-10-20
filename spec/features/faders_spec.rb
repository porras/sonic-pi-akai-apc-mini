RSpec.describe "faders" do
  example "direct use through #fader method" do
    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
      initialize_akai(:apc_mini)

      live_loop :drum do
        sample :bd_haus, amp: fader(0)
        sleep 1
      end
    end

    sp.run(2, events: [
      [0.5, "/midi:apc_mini*/control_change", [48, 64]],
      [1.5, "/midi:apc_mini*/control_change", [48, 128]]
    ])

    expect(sp).to have_output(:sample, :bd_haus, amp: 0).at(0)
    expect(sp).to have_output(:sample, :bd_haus, amp: be_within(0.05).of(0.5)).at(1)
    expect(sp).to have_output(:sample, :bd_haus, amp: be_within(0.05).of(1)).at(2)
  end

  example "moving faders turns lights on and off" do
    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
      initialize_akai(:apc_mini)
    end

    sp.run(2, events: [
      [0.5, "/midi:apc_mini*/control_change", [48, 64]],
      [1.5, "/midi:apc_mini*/control_change", [48, 0]]
    ])

    expect(sp).to have_output(:midi_note_on, 64, 3).at(0.5)
    expect(sp).to have_output(:midi_note_on, 64, 0).at(1.5)
  end

  example "using set_fader to control volume" do
    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
      initialize_akai(:apc_mini)
      set_fader(8, 0..2) { |v| set_volume! v }
    end

    sp.run(2, events: [
      [0.5, "/midi:apc_mini*/control_change", [56, 64]],
      [1.5, "/midi:apc_mini*/control_change", [56, 127]]
    ])

    expect(sp).to have_output(:set_volume!, be_within(0.05).of(0)).at(0)
    expect(sp).to have_output(:set_volume!, be_within(0.05).of(1)).at(0.5)
    expect(sp).to have_output(:set_volume!, be_within(0.05).of(2)).at(1.5)
  end

  example "using attach_fader to control a synth" do
    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
      initialize_akai(:apc_mini)

      live_loop :synth do
        node = play(:c4, cutoff: fader(0, 60..120))
        attach_fader 0, node, :cutoff, 60..120
        sleep 1
      end
    end

    sp.run(2, events: [
      [0.25, "/midi:apc_mini*/control_change", [48, 64]],
      [1.25, "/midi:apc_mini*/control_change", [48, 127]]
    ])

    expect(sp).to have_output(:play, :c4, cutoff: be_within(0.5).of(60)).at(0)
    expect(sp).to have_output(:control, a_node(:play, :c4), cutoff: be_within(0.5).of(60)).at(0)

    expect(sp).to have_output(:control, a_node(:play, :c4), cutoff: be_within(0.5).of(90)).at(0.25)

    expect(sp).to have_output(:play, :c4, cutoff: be_within(0.5).of(90)).at(1)
    expect(sp).to have_output(:control, a_node(:play, :c4), cutoff: be_within(0.5).of(90)).at(1)

    expect(sp).to have_output(:control, a_node(:play, :c4), cutoff: be_within(0.5).of(120)).at(1.25)
  end
end
