RSpec::Matchers.define :have_output do |*command|
  match do |sp|
    beat_outputs = sp.output.values_at(*@beats)
    expect(beat_outputs).to all(include(match(command)))
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
