RSpec.describe 'selector' do
  example 'using a selector to play one note from a chord' do
    sp = FakeSonicPi.new do
      initialize_akai(:apc_mini)

      live_loop :bass do
        play selector(0, 0, %i[c2 d2 e2])
        sleep 1
      end
    end

    sp.run(4, events: [
             [1.5, '/midi:apc_mini*/note_on', [1, 127]],
             [2.5, '/midi:apc_mini*/note_on', [2, 127]],
             [3.5, '/midi:apc_mini*/note_on', [0, 127]]
           ])

    # first light goes green at the beginning, the other two red
    expect(sp).to have_output(:midi_note_on, 0, 1).at(0)
    expect(sp).to have_output(:midi_note_on, 1, 3).at(0)
    expect(sp).to have_output(:midi_note_on, 2, 3).at(0)

    # when pressing the second, it goes green, the first one red
    expect(sp).to have_output(:midi_note_on, 0, 3).at(1.5)
    expect(sp).to have_output(:midi_note_on, 1, 1).at(1.5)

    # same business when pressing the third
    expect(sp).to have_output(:midi_note_on, 1, 3).at(2.5)
    expect(sp).to have_output(:midi_note_on, 2, 1).at(2.5)

    # and the first one again
    expect(sp).to have_output(:midi_note_on, 2, 3).at(3.5)
    expect(sp).to have_output(:midi_note_on, 0, 1).at(3.5)

    # bass played the right notes
    expect(sp).to have_output(:play, :c2).at(0, 1, 4)
    expect(sp).to have_output(:play, :d2).at(2)
    expect(sp).to have_output(:play, :e2).at(3)
  end
end
