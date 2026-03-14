# frozen_string_literal: true

RSpec.describe Legion::Extensions::MentalSimulation::Helpers::SimulationEngine do
  subject(:engine) { described_class.new }

  let(:label)  { 'deploy pipeline' }
  let(:domain) { :infrastructure }

  def build_favorable_simulation
    sim = engine.create_simulation(label: label, domain: domain)
    engine.add_simulation_step(simulation_id: sim.id, action: 'check', confidence: 0.9, risk: 0.05)
    engine.add_simulation_step(simulation_id: sim.id, action: 'deploy', confidence: 0.85, risk: 0.05)
    sim
  end

  def build_risky_simulation
    sim = engine.create_simulation(label: 'risky plan', domain: :security)
    engine.add_simulation_step(simulation_id: sim.id, action: 'dangerous op', confidence: 0.9, risk: 0.8)
    sim
  end

  describe '#create_simulation' do
    it 'creates a simulation and returns it' do
      sim = engine.create_simulation(label: label, domain: domain)
      expect(sim).to be_a(Legion::Extensions::MentalSimulation::Helpers::Simulation)
    end

    it 'stores the simulation internally' do
      sim = engine.create_simulation(label: label, domain: domain)
      expect(engine.assess_simulation(simulation_id: sim.id)[:label]).to eq(label)
    end
  end

  describe '#add_simulation_step' do
    it 'returns added: true on success' do
      sim = engine.create_simulation(label: label, domain: domain)
      result = engine.add_simulation_step(simulation_id: sim.id, action: 'check prereqs')
      expect(result[:added]).to be true
    end

    it 'returns step_id' do
      sim = engine.create_simulation(label: label, domain: domain)
      result = engine.add_simulation_step(simulation_id: sim.id, action: 'check')
      expect(result[:step_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns error for unknown simulation_id' do
      result = engine.add_simulation_step(simulation_id: 'no-such-id', action: 'go')
      expect(result[:error]).to eq(:simulation_not_found)
    end

    it 'returns error when max steps reached' do
      sim = engine.create_simulation(label: label, domain: domain)
      Legion::Extensions::MentalSimulation::Helpers::Constants::MAX_STEPS_PER_SIM.times do |i|
        engine.add_simulation_step(simulation_id: sim.id, action: "step #{i}")
      end
      result = engine.add_simulation_step(simulation_id: sim.id, action: 'one too many')
      expect(result[:error]).to eq(:max_steps_reached)
    end
  end

  describe '#run_simulation' do
    it 'returns state after running' do
      sim = build_favorable_simulation
      result = engine.run_simulation(simulation_id: sim.id)
      expect(result[:state]).to be_a(Symbol)
    end

    it 'returns favorable: true for a good plan' do
      sim = build_favorable_simulation
      result = engine.run_simulation(simulation_id: sim.id)
      expect(result[:favorable]).to be true
    end

    it 'returns error for unknown simulation' do
      result = engine.run_simulation(simulation_id: 'ghost')
      expect(result[:error]).to eq(:simulation_not_found)
    end

    it 'returns overall_confidence in result' do
      sim = build_favorable_simulation
      result = engine.run_simulation(simulation_id: sim.id)
      expect(result[:overall_confidence]).to be > 0
    end

    it 'returns cumulative_risk in result' do
      sim = build_favorable_simulation
      result = engine.run_simulation(simulation_id: sim.id)
      expect(result[:cumulative_risk]).to be >= 0
    end
  end

  describe '#abort_simulation' do
    it 'aborts a simulation and returns aborted: true' do
      sim = engine.create_simulation(label: label, domain: domain)
      result = engine.abort_simulation(simulation_id: sim.id)
      expect(result[:aborted]).to be true
      expect(result[:state]).to eq(:aborted)
    end

    it 'returns error for unknown simulation' do
      result = engine.abort_simulation(simulation_id: 'ghost')
      expect(result[:error]).to eq(:simulation_not_found)
    end
  end

  describe '#assess_simulation' do
    it 'returns full assessment without running' do
      sim = engine.create_simulation(label: label, domain: domain)
      engine.add_simulation_step(simulation_id: sim.id, action: 'assess me')
      result = engine.assess_simulation(simulation_id: sim.id)
      expect(result[:state]).to eq(:pending)
      expect(result[:steps].size).to eq(1)
    end

    it 'returns error for unknown simulation' do
      result = engine.assess_simulation(simulation_id: 'ghost')
      expect(result[:error]).to eq(:simulation_not_found)
    end

    it 'includes confidence and risk in assessment' do
      sim = engine.create_simulation(label: label, domain: domain)
      engine.add_simulation_step(simulation_id: sim.id, action: 'step', confidence: 0.7, risk: 0.2)
      result = engine.assess_simulation(simulation_id: sim.id)
      expect(result[:overall_confidence]).to eq(0.7)
      expect(result[:cumulative_risk]).to be_within(0.001).of(0.2)
    end
  end

  describe '#favorable_simulations' do
    it 'returns only favorable simulations' do
      sim = build_favorable_simulation
      engine.run_simulation(simulation_id: sim.id)
      favs = engine.favorable_simulations
      expect(favs).not_to be_empty
      expect(favs.all?(&:favorable?)).to be true
    end

    it 'excludes non-favorable simulations' do
      sim = engine.create_simulation(label: label, domain: domain)
      engine.add_simulation_step(simulation_id: sim.id, action: 'low conf', confidence: 0.2, risk: 0.1)
      engine.run_simulation(simulation_id: sim.id)
      favs = engine.favorable_simulations
      expect(favs.map(&:id)).not_to include(sim.id)
    end
  end

  describe '#failed_simulations' do
    it 'returns simulations in :failed state' do
      sim = engine.create_simulation(label: label, domain: domain)
      engine.add_simulation_step(simulation_id: sim.id, action: 'low conf', confidence: 0.2, risk: 0.1)
      engine.run_simulation(simulation_id: sim.id)
      failed = engine.failed_simulations
      expect(failed.map(&:id)).to include(sim.id)
    end
  end

  describe '#simulations_by_domain' do
    it 'returns simulations for the specified domain' do
      sim_a = engine.create_simulation(label: 'a', domain: :networking)
      sim_b = engine.create_simulation(label: 'b', domain: :security)
      result = engine.simulations_by_domain(domain: :networking)
      expect(result.map(&:id)).to include(sim_a.id)
      expect(result.map(&:id)).not_to include(sim_b.id)
    end

    it 'handles domain as string by converting to symbol' do
      sim = engine.create_simulation(label: 'str domain', domain: :cloud)
      result = engine.simulations_by_domain(domain: 'cloud')
      expect(result.map(&:id)).to include(sim.id)
    end
  end

  describe '#riskiest_simulations' do
    it 'returns simulations sorted by descending cumulative_risk' do
      low_risk_sim = engine.create_simulation(label: 'safe', domain: :app)
      engine.add_simulation_step(simulation_id: low_risk_sim.id, action: 'safe', risk: 0.1)

      high_risk_sim = build_risky_simulation

      result = engine.riskiest_simulations(limit: 2)
      expect(result.first.id).to eq(high_risk_sim.id)
    end

    it 'respects the limit parameter' do
      3.times { |i| engine.create_simulation(label: "sim #{i}", domain: :test) }
      expect(engine.riskiest_simulations(limit: 2).size).to be <= 2
    end
  end

  describe '#most_confident' do
    it 'returns simulations sorted by descending overall_confidence' do
      low_conf_sim = engine.create_simulation(label: 'uncertain', domain: :app)
      engine.add_simulation_step(simulation_id: low_conf_sim.id, action: 'maybe', confidence: 0.2)

      high_conf_sim = engine.create_simulation(label: 'sure', domain: :app)
      engine.add_simulation_step(simulation_id: high_conf_sim.id, action: 'definitely', confidence: 0.95)

      result = engine.most_confident(limit: 2)
      expect(result.first.id).to eq(high_conf_sim.id)
    end

    it 'respects the limit parameter' do
      4.times { |i| engine.create_simulation(label: "sim #{i}", domain: :test) }
      expect(engine.most_confident(limit: 2).size).to be <= 2
    end
  end

  describe '#to_h' do
    it 'returns engine summary hash' do
      engine.create_simulation(label: label, domain: domain)
      h = engine.to_h
      expect(h).to include(:total_simulations, :history_size, :favorable_count, :failed_count, :simulations)
      expect(h[:total_simulations]).to eq(1)
    end
  end
end
