# frozen_string_literal: true

RSpec.describe Legion::Extensions::MentalSimulation::Helpers::Constants do
  describe 'SIMULATION_STATES' do
    it 'is frozen' do
      expect(described_class::SIMULATION_STATES).to be_frozen
    end

    it 'contains expected states' do
      expect(described_class::SIMULATION_STATES).to include(:pending, :running, :completed, :failed, :aborted)
    end
  end

  describe 'STEP_OUTCOMES' do
    it 'is frozen' do
      expect(described_class::STEP_OUTCOMES).to be_frozen
    end

    it 'contains expected outcomes' do
      expect(described_class::STEP_OUTCOMES).to include(:success, :partial_success, :failure, :unknown)
    end
  end

  describe 'CONFIDENCE_LABELS' do
    it 'labels 0.9 as very_confident' do
      match = described_class::CONFIDENCE_LABELS.find { |r, _| r.cover?(0.9) }&.last
      expect(match).to eq(:very_confident)
    end

    it 'labels 0.7 as confident' do
      match = described_class::CONFIDENCE_LABELS.find { |r, _| r.cover?(0.7) }&.last
      expect(match).to eq(:confident)
    end

    it 'labels 0.5 as uncertain' do
      match = described_class::CONFIDENCE_LABELS.find { |r, _| r.cover?(0.5) }&.last
      expect(match).to eq(:uncertain)
    end

    it 'labels 0.3 as doubtful' do
      match = described_class::CONFIDENCE_LABELS.find { |r, _| r.cover?(0.3) }&.last
      expect(match).to eq(:doubtful)
    end

    it 'labels 0.1 as very_doubtful' do
      match = described_class::CONFIDENCE_LABELS.find { |r, _| r.cover?(0.1) }&.last
      expect(match).to eq(:very_doubtful)
    end
  end

  describe 'RISK_LABELS' do
    it 'labels 0.9 as critical' do
      match = described_class::RISK_LABELS.find { |r, _| r.cover?(0.9) }&.last
      expect(match).to eq(:critical)
    end

    it 'labels 0.7 as high' do
      match = described_class::RISK_LABELS.find { |r, _| r.cover?(0.7) }&.last
      expect(match).to eq(:high)
    end

    it 'labels 0.5 as moderate' do
      match = described_class::RISK_LABELS.find { |r, _| r.cover?(0.5) }&.last
      expect(match).to eq(:moderate)
    end

    it 'labels 0.3 as low' do
      match = described_class::RISK_LABELS.find { |r, _| r.cover?(0.3) }&.last
      expect(match).to eq(:low)
    end

    it 'labels 0.1 as negligible' do
      match = described_class::RISK_LABELS.find { |r, _| r.cover?(0.1) }&.last
      expect(match).to eq(:negligible)
    end
  end

  describe 'numeric constants' do
    it 'MAX_SIMULATIONS is 100' do
      expect(described_class::MAX_SIMULATIONS).to eq(100)
    end

    it 'MAX_STEPS_PER_SIM is 50' do
      expect(described_class::MAX_STEPS_PER_SIM).to eq(50)
    end

    it 'MAX_HISTORY is 500' do
      expect(described_class::MAX_HISTORY).to eq(500)
    end

    it 'DEFAULT_CONFIDENCE is 0.5' do
      expect(described_class::DEFAULT_CONFIDENCE).to eq(0.5)
    end

    it 'CONFIDENCE_BOOST is 0.1' do
      expect(described_class::CONFIDENCE_BOOST).to eq(0.1)
    end

    it 'CONFIDENCE_PENALTY is 0.15' do
      expect(described_class::CONFIDENCE_PENALTY).to eq(0.15)
    end

    it 'RISK_ACCUMULATION_RATE is 0.1' do
      expect(described_class::RISK_ACCUMULATION_RATE).to eq(0.1)
    end
  end
end
