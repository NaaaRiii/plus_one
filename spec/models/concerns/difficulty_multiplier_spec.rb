require 'rails_helper'

RSpec.describe DifficultyMultiplier do
  let(:dummy_class) { Class.new { include DifficultyMultiplier } }
  let(:instance) { dummy_class.new }

  describe '#get_multiplier' do
    it 'returns correct multiplier for each difficulty level' do
      expect(instance.get_multiplier('ものすごく簡単')).to eq 0.5
      expect(instance.get_multiplier('簡単')).to eq 0.7
      expect(instance.get_multiplier('普通')).to eq 1.0
      expect(instance.get_multiplier('難しい')).to eq 1.2
      expect(instance.get_multiplier('とても難しい')).to eq 1.5
    end

    it 'returns nil for unknown difficulty' do
      expect(instance.get_multiplier('存在しない難易度')).to be_nil
    end
  end
end