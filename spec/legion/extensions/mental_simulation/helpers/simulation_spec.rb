# frozen_string_literal: true

RSpec.describe Legion::Extensions::MentalSimulation::Helpers::Simulation do
  subject(:sim) { described_class.new(label: 'test plan', domain: :infrastructure) }

  describe '#initialize' do
    it 'generates a UUID id' do
      expect(sim.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores the label' do
      expect(sim.label).to eq('test plan')
    end

    it 'stores the domain as a symbol' do
      expect(sim.domain).to eq(:infrastructure)
    end

    it 'starts with no steps' do
      expect(sim.steps).to be_empty
    end

    it 'starts in :pending state' do
      expect(sim.state).to eq(:pending)
    end

    it 'records created_at' do
      expect(sim.created_at).to be_a(Time)
    end

    it 'has nil completed_at initially' do
      expect(sim.completed_at).to be_nil
    end
  end

  describe '#add_step' do
    it 'adds a SimulationStep and returns it' do
      step = sim.add_step(action: 'check health')
      expect(step).to be_a(Legion::Extensions::MentalSimulation::Helpers::SimulationStep)
    end

    it 'increments step_count' do
      sim.add_step(action: 'step one')
      sim.add_step(action: 'step two')
      expect(sim.step_count).to eq(2)
    end

    it 'passes parameters through to the step' do
      step = sim.add_step(action: 'deploy', predicted_outcome: :failure, confidence: 0.3, risk: 0.8)
      expect(step.predicted_outcome).to eq(:failure)
      expect(step.confidence).to eq(0.3)
      expect(step.risk).to eq(0.8)
    end
  end

  describe '#overall_confidence' do
    it 'returns 0.0 when no steps' do
      expect(sim.overall_confidence).to eq(0.0)
    end

    it 'returns product of step confidences' do
      sim.add_step(action: 'a', confidence: 0.8)
      sim.add_step(action: 'b', confidence: 0.5)
      expect(sim.overall_confidence).to be_within(0.001).of(0.4)
    end

    it 'returns single step confidence when only one step' do
      sim.add_step(action: 'a', confidence: 0.75)
      expect(sim.overall_confidence).to eq(0.75)
    end
  end

  describe '#cumulative_risk' do
    it 'returns 0.0 when no steps' do
      expect(sim.cumulative_risk).to eq(0.0)
    end

    it 'computes combined risk correctly' do
      sim.add_step(action: 'a', risk: 0.2)
      sim.add_step(action: 'b', risk: 0.3)
      # 1 - (0.8 * 0.7) = 1 - 0.56 = 0.44
      expect(sim.cumulative_risk).to be_within(0.001).of(0.44)
    end

    it 'returns high risk when steps have high individual risk' do
      sim.add_step(action: 'a', risk: 0.9)
      sim.add_step(action: 'b', risk: 0.9)
      expect(sim.cumulative_risk).to be > 0.9
    end
  end

  describe '#run!' do
    context 'with favorable steps' do
      before do
        sim.add_step(action: 'check prereqs', confidence: 0.9, risk: 0.1)
        sim.add_step(action: 'deploy', confidence: 0.8, risk: 0.1)
      end

      it 'sets state to :completed' do
        sim.run!
        expect(sim.state).to eq(:completed)
      end

      it 'sets completed_at' do
        sim.run!
        expect(sim.completed_at).to be_a(Time)
      end
    end

    context 'when a step predicts failure with high confidence' do
      before do
        sim.add_step(action: 'safe step', confidence: 0.9, risk: 0.1)
        sim.add_step(action: 'dangerous step', predicted_outcome: :failure, confidence: 0.8, risk: 0.5)
      end

      it 'aborts the simulation' do
        sim.run!
        expect(sim.state).to eq(:aborted)
      end
    end

    context 'with low overall confidence' do
      before do
        sim.add_step(action: 'a', confidence: 0.3, risk: 0.1)
        sim.add_step(action: 'b', confidence: 0.3, risk: 0.1)
      end

      it 'sets state to :failed' do
        sim.run!
        expect(sim.state).to eq(:failed)
      end
    end

    context 'with high cumulative risk' do
      before do
        sim.add_step(action: 'a', confidence: 0.9, risk: 0.7)
        sim.add_step(action: 'b', confidence: 0.9, risk: 0.7)
      end

      it 'sets state to :failed when cumulative risk >= 0.6' do
        sim.run!
        expect(sim.state).to eq(:failed)
      end
    end

    it 'sets state to :running briefly and transitions' do
      sim.add_step(action: 'a', confidence: 0.9, risk: 0.1)
      sim.run!
      expect(%i[completed failed aborted]).to include(sim.state)
    end
  end

  describe '#abort!' do
    it 'sets state to :aborted' do
      sim.abort!
      expect(sim.state).to eq(:aborted)
    end

    it 'sets completed_at' do
      sim.abort!
      expect(sim.completed_at).to be_a(Time)
    end
  end

  describe '#favorable?' do
    it 'returns false for pending simulation' do
      sim.add_step(action: 'a', confidence: 0.9, risk: 0.1)
      expect(sim.favorable?).to be false
    end

    it 'returns true for completed simulation with good confidence and low risk' do
      sim.add_step(action: 'a', confidence: 0.9, risk: 0.1)
      sim.add_step(action: 'b', confidence: 0.9, risk: 0.1)
      sim.run!
      expect(sim.favorable?).to be true
    end

    it 'returns false for aborted simulation' do
      sim.add_step(action: 'a', predicted_outcome: :failure, confidence: 0.9, risk: 0.5)
      sim.run!
      expect(sim.favorable?).to be false
    end
  end

  describe '#confidence_label' do
    it 'returns :very_confident for high overall confidence' do
      sim.add_step(action: 'a', confidence: 0.95)
      expect(sim.confidence_label).to eq(:very_confident)
    end

    it 'returns :very_doubtful when no steps' do
      expect(sim.confidence_label).to eq(:very_doubtful)
    end
  end

  describe '#risk_label' do
    it 'returns :negligible for low risk' do
      sim.add_step(action: 'a', risk: 0.1)
      expect(sim.risk_label).to eq(:negligible)
    end

    it 'returns :critical for very high risk' do
      sim.add_step(action: 'a', risk: 0.95)
      sim.add_step(action: 'b', risk: 0.95)
      expect(sim.risk_label).to eq(:critical)
    end
  end

  describe '#to_h' do
    it 'returns a complete hash' do
      sim.add_step(action: 'test step')
      h = sim.to_h
      expect(h).to include(:id, :label, :domain, :state, :step_count, :overall_confidence,
                           :cumulative_risk, :confidence_label, :risk_label, :favorable, :steps)
    end

    it 'includes step hashes' do
      sim.add_step(action: 'step one')
      h = sim.to_h
      expect(h[:steps].first[:action]).to eq('step one')
    end
  end
end
