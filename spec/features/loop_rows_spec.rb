RSpec.describe 'loop_rows' do
  example 'a drum pattern' do
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
