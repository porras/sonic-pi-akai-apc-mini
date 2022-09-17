RSpec.describe SonicPiAkaiApcMini::LightsPanel do
  subject(:panel) { described_class.new(default: 0) { |k, v| operations << [k, v] } }

  let(:operations) { [] }

  it 'stores values' do
    panel.set(0 => 1, 1 => 2)

    expect(panel[0]).to eq 1
    expect(panel[1]).to eq 2
    expect(operations).to eq [[0, 1], [1, 2]]
  end

  it 'spares no-ops' do
    panel.set(1 => 2)
    panel.set(1 => 2)

    expect(operations).to eq [[1, 2]]
  end

  it 'groups operations' do
    panel[0] = 1
    panel[1] = 2

    expect(panel[0]).to eq 1
    expect(panel[1]).to eq 2
    expect(operations).to be_empty

    panel.flush

    expect(operations).to eq [[0, 1], [1, 2]]
  end

  it 'spares operations by grouping' do
    panel[0] = 1

    expect(panel[0]).to eq 1
    expect(operations).to be_empty

    panel[0] = 0 # undoing before flushing

    expect(panel[0]).to eq 0
    expect(operations).to be_empty

    panel.flush

    expect(operations).to be_empty
  end
end
