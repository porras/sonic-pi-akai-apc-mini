require 'sonic-pi-akai-apc-mini/helpers'

RSpec.describe SonicPiAkaiApcMini::Helpers do
  describe '#normalize' do
    it 'supports ranges' do
      expect(described_class.normalize(0, (0..100))).to eq 0
      expect(described_class.normalize(64, (0..100))).to be_within(1).of(50)
      expect(described_class.normalize(127, (0..100))).to eq 100
    end

    it 'supports arrays' do
      expect(described_class.normalize(0, [:a, :b, :c])).to eq :a
      expect(described_class.normalize(64, [:a, :b, :c])).to eq :b
      expect(described_class.normalize(127, [:a, :b, :c])).to eq :c
    end

    it 'supports special value :pan' do
      expect(described_class.normalize(0, :pan)).to eq -1
      expect(described_class.normalize(64, :pan)).to be_within(0.1).of(0)
      expect(described_class.normalize(127, :pan)).to eq 1
    end
  end
end
