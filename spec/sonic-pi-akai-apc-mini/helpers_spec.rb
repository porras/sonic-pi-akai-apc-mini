require 'sonic-pi-akai-apc-mini/helpers'
require 'sonic-pi-akai-apc-mini/controller'

RSpec.describe SonicPiAkaiApcMini::Helpers do
  describe '#normalize' do
    it 'supports ranges' do
      expect(described_class.normalize(0, (0..100))).to eq 0
      expect(described_class.normalize(64, (0..100))).to be_within(1).of(50)
      expect(described_class.normalize(127, (0..100))).to eq 100
    end

    it 'supports arrays' do
      expect(described_class.normalize(0, %i[a b c])).to eq :a
      expect(described_class.normalize(64, %i[a b c])).to eq :b
      expect(described_class.normalize(127, %i[a b c])).to eq :c
    end

    it 'supports special value :pan' do
      expect(described_class.normalize(0, :pan)).to eq(-1)
      expect(described_class.normalize(64, :pan)).to be_within(0.1).of(0)
      expect(described_class.normalize(127, :pan)).to eq 1
    end
  end

  describe '#key_range' do
    before do
      SonicPiAkaiApcMini::Controller.model = model_name
    end

    context 'on the APC mini' do
      let(:model_name) { :apc_mini }

      it 'returns the MIDI note for a button' do
        expect(described_class.key_range(0, 0, 1)).to eq(0..0)
      end

      it 'returns the MIDI notes for three buttons' do
        expect(described_class.key_range(0, 0, 3)).to eq(0..2)
      end

      it 'calculates the right MIDI notes away from the origin' do
        expect(described_class.key_range(2, 2, 3)).to eq(18..20)
      end

      it 'does not exceed the end of the row' do
        expect(described_class.key_range(0, 6, 6)).to eq(6..7)
      end

      it 'errors out when trying to use a row higher than 7' do
        expect(described_class.key_range(7, 0, 1)).to eq(56..56)
        expect { described_class.key_range(8, 0, 1) }.to raise_error(described_class::RangeError)
      end

      it 'errors out when trying to use a column higher than 7' do
        expect(described_class.key_range(0, 7, 1)).to eq(7..7)
        expect { described_class.key_range(0, 8, 1) }.to raise_error(described_class::RangeError)
      end
    end

    context 'on the APC Key 25' do
      let(:model_name) { :apc_key_25 }

      it 'returns the MIDI note for a button' do
        expect(described_class.key_range(0, 0, 1)).to eq(0..0)
      end

      it 'errors out when trying to use a row higher than 4' do
        expect(described_class.key_range(4, 0, 1)).to eq(32..32)
        expect { described_class.key_range(5, 0, 1) }.to raise_error(described_class::RangeError)
      end

      it 'errors out when trying to use a column higher than 7' do
        expect(described_class.key_range(0, 7, 1)).to eq(7..7)
        expect { described_class.key_range(0, 8, 1) }.to raise_error(described_class::RangeError)
      end
    end
  end
end
