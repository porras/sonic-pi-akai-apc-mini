RSpec::Matchers.define :have_output do |*command|
  match do |sp|
    beat_outputs = sp.output.values_at(*@beats)
    expect(beat_outputs).to all(include(match(command)))
  end

  chain :at do |*beats|
    @beats = beats.map(&:to_f)
  end
end
