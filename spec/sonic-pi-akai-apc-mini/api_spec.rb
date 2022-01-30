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

  example 'direct use of fader' do
    sp = FakeSonicPi.new do
      initialize_akai(:apc_mini)

      live_loop :drum do
        sample :bd_haus, amp: fader(0)
        sleep 1
      end
    end

    sp.run(2, events: {
             0.5 => { name: '/midi:apc_mini*/control_change', value: [48, 64] },
             1.5 => { name: '/midi:apc_mini*/control_change', value: [48, 127] }
           })

    expect(sp).to have_output(:sample, :bd_haus, amp: 0).at(0)
    expect(sp).to have_output(:sample, :bd_haus, amp: be_within(0.05).of(0.5)).at(1)
    expect(sp).to have_output(:sample, :bd_haus, amp: be_within(0.05).of(1)).at(2)
  end
end
