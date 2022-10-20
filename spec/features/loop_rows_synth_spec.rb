RSpec.describe "loop_rows_synth" do
  example "a pattern of two bass notes" do
    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
      initialize_akai(:apc_mini)

      live_loop :bass do
        loop_rows_synth(8, 0..1, %i[c2 d2])
      end
    end

    # unrealistic but easy to test: we punch the whole pattern just before the
    # second repetition will start:
    sp.run(16, events: [
      # d2 on 1/4 and 3/4
      [7.99, "/midi:apc_mini*/note_on", [8, 127]],
      [7.99, "/midi:apc_mini*/note_on", [12, 127]],
      # c2 on 2/4 and 4/4
      [7.99, "/midi:apc_mini*/note_on", [2, 127]],
      [7.99, "/midi:apc_mini*/note_on", [6, 127]]
    ])

    # no need to test the lights again, loop_rows tests them

    # in the second 8 beats, we should play!
    expect(sp).to have_output(:play, :d2, {}).at(8, 12)
    expect(sp).to have_output(:play, :c2, {}).at(10, 14)
  end

  example "with options" do
    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
      initialize_akai(:apc_mini)

      live_loop :bass do
        loop_rows_synth(8, 0..0, [:c2], amp: 2)
      end
    end

    sp.run(16, events: [
      [7.99, "/midi:apc_mini*/note_on", [0, 127]]
    ])

    expect(sp).to have_output(:play, :c2, amp: 2).at(8)
  end

  example "with dynamic options" do
    dummy = double(:whatever)
    allow(dummy).to receive(:something).and_return(2, 3, 4) # fake a ring or whatever

    sp = FakeSonicPi.new do
      include SonicPiAkaiApcMini::API
      initialize_akai(:apc_mini)

      live_loop :bass do
        loop_rows_synth(8, 0..0, [:c2], -> { {amp: dummy.something} })
      end
    end

    sp.run(8, events: [
      [0, "/midi:apc_mini*/note_on", [1, 127]],
      [0, "/midi:apc_mini*/note_on", [2, 127]],
      [0, "/midi:apc_mini*/note_on", [3, 127]]
    ])

    expect(sp).to have_output(:play, :c2, amp: 2).at(1)
    expect(sp).to have_output(:play, :c2, amp: 3).at(2)
    expect(sp).to have_output(:play, :c2, amp: 4).at(3)
  end
end
