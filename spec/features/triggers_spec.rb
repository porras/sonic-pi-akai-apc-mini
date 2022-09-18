RSpec.describe 'triggers' do
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
