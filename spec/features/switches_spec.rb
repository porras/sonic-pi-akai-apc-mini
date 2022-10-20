RSpec.describe "switches" do
  example "using a switch to conditionally play a sample" do
    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
      initialize_akai(:apc_mini)

      live_loop :noise do
        sample :vynil_hiss if switch?(0, 0)
        sleep 1
      end
    end

    sp.run(4, events: [
      [0.5, "/midi:apc_mini*/note_on", [0, 127]],
      [0.55, "/midi:apc_mini*/note_off", [0, 127]],
      [3.5, "/midi:apc_mini*/note_on", [0, 127]],
      [3.55, "/midi:apc_mini*/note_off", [0, 127]]
    ])

    # light goes green when key pressed and off when pressed again
    expect(sp).to have_output(:midi_note_on, 0, 1).at(0.5)
    expect(sp).to have_output(:midi_note_on, 0, 0).at(3.5)

    # noise at the exact beats where the switch was on
    expect(sp).not_to have_output(:sample, :vynil_hiss).at(0, 4)
    expect(sp).to have_output(:sample, :vynil_hiss).at(1, 2, 3)
  end
end
