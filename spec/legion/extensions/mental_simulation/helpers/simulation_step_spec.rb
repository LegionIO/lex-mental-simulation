# frozen_string_literal: true

RSpec.describe Legion::Extensions::MentalSimulation::Helpers::SimulationStep do
  subject(:step) { described_class.new(action: 'deploy service') }

  describe '#initialize' do
    it 'generates a UUID id' do
      expect(step.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores the action' do
      expect(step.action).to eq('deploy service')
    end

    it 'defaults predicted_outcome to :success' do
      expect(step.predicted_outcome).to eq(:success)
    end

    it 'defaults confidence to 0.5' do
      expect(step.confidence).to eq(0.5)
    end

    it 'defaults risk to 0.1' do
      expect(step.risk).to eq(0.1)
    end

    it 'defaults preconditions to empty array' do
      expect(step.preconditions).to eq([])
    end

    it 'defaults postconditions to empty array' do
      expect(step.postconditions).to eq([])
    end

    it 'records created_at' do
      expect(step.created_at).to be_a(Time)
    end

    it 'clamps confidence above 1.0 to 1.0' do
      s = described_class.new(action: 'test', confidence: 1.5)
      expect(s.confidence).to eq(1.0)
    end

    it 'clamps confidence below 0.0 to 0.0' do
      s = described_class.new(action: 'test', confidence: -0.5)
      expect(s.confidence).to eq(0.0)
    end

    it 'clamps risk above 1.0 to 1.0' do
      s = described_class.new(action: 'test', risk: 2.0)
      expect(s.risk).to eq(1.0)
    end
  end

  describe '#favorable?' do
    it 'returns true for success with sufficient confidence' do
      s = described_class.new(action: 'go', predicted_outcome: :success, confidence: 0.8)
      expect(s.favorable?).to be true
    end

    it 'returns true for partial_success with sufficient confidence' do
      s = described_class.new(action: 'go', predicted_outcome: :partial_success, confidence: 0.6)
      expect(s.favorable?).to be true
    end

    it 'returns false for success with low confidence' do
      s = described_class.new(action: 'go', predicted_outcome: :success, confidence: 0.4)
      expect(s.favorable?).to be false
    end

    it 'returns false for failure regardless of confidence' do
      s = described_class.new(action: 'go', predicted_outcome: :failure, confidence: 0.9)
      expect(s.favorable?).to be false
    end

    it 'returns false for unknown outcome' do
      s = described_class.new(action: 'go', predicted_outcome: :unknown, confidence: 0.9)
      expect(s.favorable?).to be false
    end
  end

  describe '#risky?' do
    it 'returns true when risk >= 0.6' do
      s = described_class.new(action: 'go', risk: 0.7)
      expect(s.risky?).to be true
    end

    it 'returns false when risk < 0.6' do
      s = described_class.new(action: 'go', risk: 0.4)
      expect(s.risky?).to be false
    end

    it 'returns true at exactly 0.6' do
      s = described_class.new(action: 'go', risk: 0.6)
      expect(s.risky?).to be true
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = step.to_h
      expect(h).to include(:id, :action, :predicted_outcome, :confidence, :risk,
                           :preconditions, :postconditions, :created_at)
    end

    it 'includes stored preconditions' do
      s = described_class.new(action: 'go', preconditions: ['service_up'])
      expect(s.to_h[:preconditions]).to eq(['service_up'])
    end
  end
end
