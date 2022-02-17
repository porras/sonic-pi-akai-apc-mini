RSpec::Matchers.define :have_output do |command, *args|
  match do |sp|
    expect(@beats).to all(satisfy do |beat|
                            beat_commands = sp.output.events.select { |b, *_| b == beat }.map(&:last)
                            expect(beat_commands).to include(have_attributes(name: command, value: args))
                          end)
  end

  chain :at do |*beats|
    @beats = beats.map(&:to_f)
  end
end

# TODO: The matching is very simplistic, ok for now but might need some refining
# to be able to pass other matchers.
RSpec::Matchers.define :a_node do |command, arg|
  match do |actual|
    expect(actual).to be_a(FakeSonicPi::Node)
    expect(actual.command).to eq command
    expect(actual.args.first).to eq(arg)
  end
end
