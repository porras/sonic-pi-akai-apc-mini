require 'sonic-pi-akai-apc-mini/controller'

RSpec.describe SonicPiAkaiApcMini::Controller do
  it 'can be set but not changed' do
    expect { described_class.model }.to raise_error(described_class::Error)

    described_class.model = :apc_mini

    expect(described_class.model).to have_attributes(name: :apc_mini)

    expect { described_class.model = :apc_mini }.not_to raise_error

    expect { described_class.model = :apc_key_25 }.to raise_error(described_class::Error)
  end

  it 'raises an error with unsupported models' do
    expect { described_class.model = :does_not_exist }.to raise_error(described_class::Error)
  end
end
