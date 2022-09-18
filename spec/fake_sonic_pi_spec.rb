RSpec.describe FakeSonicPi do
  # Used to test drive the first implementation, it doesn't cover it all but
  # it's useful enough to keep around, for refactorings.
  example 'basic test' do
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
end
