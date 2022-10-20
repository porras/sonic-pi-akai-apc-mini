RSpec.describe 'free_play' do
  example 'playing three notes on a piano' do
    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
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
