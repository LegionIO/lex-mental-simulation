# frozen_string_literal: true

require 'legion/extensions/mental_simulation/helpers/client'

RSpec.describe Legion::Extensions::MentalSimulation::Runners::MentalSimulation do
  let(:client) { Legion::Extensions::MentalSimulation::Client.new }

  def create_and_populate_simulation(favorable: true)
    result = client.create_mental_simulation(label: 'test plan', domain: :infrastructure)
    sim_id = result[:simulation_id]
    if favorable
      client.add_simulation_step(simulation_id: sim_id, action: 'check health', confidence: 0.9, risk: 0.05)
      client.add_simulation_step(simulation_id: sim_id, action: 'deploy service', confidence: 0.85, risk: 0.05)
    else
      client.add_simulation_step(simulation_id: sim_id, action: 'low confidence step', confidence: 0.2, risk: 0.1)
    end
    sim_id
  end

  describe '#create_mental_simulation' do
    it 'returns a simulation_id' do
      result = client.create_mental_simulation(label: 'my plan', domain: :networking)
      expect(result[:simulation_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns the label' do
      result = client.create_mental_simulation(label: 'my plan', domain: :networking)
      expect(result[:label]).to eq('my plan')
    end

    it 'returns the domain' do
      result = client.create_mental_simulation(label: 'my plan', domain: :networking)
      expect(result[:domain]).to eq(:networking)
    end

    it 'starts in :pending state' do
      result = client.create_mental_simulation(label: 'my plan', domain: :app)
      expect(result[:state]).to eq(:pending)
    end
  end

  describe '#add_simulation_step' do
    it 'returns added: true' do
      sim_result = client.create_mental_simulation(label: 'plan', domain: :app)
      result = client.add_simulation_step(simulation_id: sim_result[:simulation_id], action: 'step 1')
      expect(result[:added]).to be true
    end

    it 'returns a step_id' do
      sim_result = client.create_mental_simulation(label: 'plan', domain: :app)
      result = client.add_simulation_step(simulation_id: sim_result[:simulation_id], action: 'step 1')
      expect(result[:step_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns error for unknown simulation' do
      result = client.add_simulation_step(simulation_id: 'bad-id', action: 'noop')
      expect(result[:error]).to eq(:simulation_not_found)
    end

    it 'increments step_count' do
      sim_result = client.create_mental_simulation(label: 'plan', domain: :app)
      client.add_simulation_step(simulation_id: sim_result[:simulation_id], action: 'step 1')
      result = client.add_simulation_step(simulation_id: sim_result[:simulation_id], action: 'step 2')
      expect(result[:step_count]).to eq(2)
    end
  end

  describe '#run_mental_simulation' do
    it 'transitions state from pending' do
      sim_id = create_and_populate_simulation
      result = client.run_mental_simulation(simulation_id: sim_id)
      expect(result[:state]).not_to eq(:pending)
    end

    it 'returns favorable: true for a well-configured plan' do
      sim_id = create_and_populate_simulation(favorable: true)
      result = client.run_mental_simulation(simulation_id: sim_id)
      expect(result[:favorable]).to be true
    end

    it 'returns favorable: false for a low-confidence plan' do
      sim_id = create_and_populate_simulation(favorable: false)
      result = client.run_mental_simulation(simulation_id: sim_id)
      expect(result[:favorable]).to be false
    end

    it 'returns error for unknown simulation' do
      result = client.run_mental_simulation(simulation_id: 'ghost')
      expect(result[:error]).to eq(:simulation_not_found)
    end

    it 'includes step_count in result' do
      sim_id = create_and_populate_simulation
      result = client.run_mental_simulation(simulation_id: sim_id)
      expect(result[:step_count]).to eq(2)
    end
  end

  describe '#abort_mental_simulation' do
    it 'aborts a simulation' do
      sim_result = client.create_mental_simulation(label: 'to abort', domain: :app)
      result = client.abort_mental_simulation(simulation_id: sim_result[:simulation_id])
      expect(result[:state]).to eq(:aborted)
      expect(result[:aborted]).to be true
    end

    it 'returns error for unknown simulation' do
      result = client.abort_mental_simulation(simulation_id: 'ghost')
      expect(result[:error]).to eq(:simulation_not_found)
    end
  end

  describe '#assess_mental_simulation' do
    it 'returns assessment without running' do
      sim_result = client.create_mental_simulation(label: 'assess me', domain: :security)
      client.add_simulation_step(simulation_id: sim_result[:simulation_id], action: 'read logs',
                                 confidence: 0.8, risk: 0.1)
      result = client.assess_mental_simulation(simulation_id: sim_result[:simulation_id])
      expect(result[:state]).to eq(:pending)
      expect(result[:steps].size).to eq(1)
    end

    it 'returns error for unknown simulation' do
      result = client.assess_mental_simulation(simulation_id: 'ghost')
      expect(result[:error]).to eq(:simulation_not_found)
    end
  end

  describe '#favorable_simulations_report' do
    it 'returns a report with count' do
      sim_id = create_and_populate_simulation(favorable: true)
      client.run_mental_simulation(simulation_id: sim_id)
      result = client.favorable_simulations_report
      expect(result).to include(:simulations, :count)
      expect(result[:count]).to be >= 1
    end

    it 'returns count: 0 when no favorable simulations exist' do
      result = client.favorable_simulations_report
      expect(result[:count]).to eq(0)
    end
  end

  describe '#failed_simulations_report' do
    it 'returns a report with count' do
      sim_id = create_and_populate_simulation(favorable: false)
      client.run_mental_simulation(simulation_id: sim_id)
      result = client.failed_simulations_report
      expect(result).to include(:simulations, :count)
      expect(result[:count]).to be >= 1
    end
  end

  describe '#riskiest_simulations_report' do
    it 'returns a report with simulations and count' do
      sim_id = create_and_populate_simulation
      client.add_simulation_step(simulation_id: sim_id, action: 'risky op', risk: 0.9)
      result = client.riskiest_simulations_report
      expect(result).to include(:simulations, :count)
    end

    it 'accepts a limit parameter' do
      3.times { client.create_mental_simulation(label: 'sim', domain: :app) }
      result = client.riskiest_simulations_report(limit: 2)
      expect(result[:count]).to be <= 2
    end
  end

  describe '#mental_simulation_stats' do
    it 'returns stats hash without simulations list' do
      client.create_mental_simulation(label: 'one', domain: :app)
      result = client.mental_simulation_stats
      expect(result).to include(:total_simulations, :history_size, :favorable_count, :failed_count)
      expect(result).not_to have_key(:simulations)
    end

    it 'reflects created simulations' do
      client.create_mental_simulation(label: 'a', domain: :app)
      client.create_mental_simulation(label: 'b', domain: :app)
      result = client.mental_simulation_stats
      expect(result[:total_simulations]).to eq(2)
    end
  end
end
