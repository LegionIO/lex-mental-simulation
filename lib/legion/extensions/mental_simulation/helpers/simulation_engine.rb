# frozen_string_literal: true

module Legion
  module Extensions
    module MentalSimulation
      module Helpers
        class SimulationEngine
          include Constants

          def initialize
            @simulations = {}
            @history     = []
          end

          def create_simulation(label:, domain:)
            prune_simulations if @simulations.size >= MAX_SIMULATIONS
            sim = Simulation.new(label: label, domain: domain)
            @simulations[sim.id] = sim
            sim
          end

          def add_simulation_step(simulation_id:, action:, predicted_outcome: :success,
                                  confidence: 0.5, risk: 0.1, preconditions: [], postconditions: [])
            sim = @simulations[simulation_id]
            return { error: :simulation_not_found } unless sim

            return { error: :max_steps_reached, max: MAX_STEPS_PER_SIM } if sim.step_count >= MAX_STEPS_PER_SIM

            step = sim.add_step(
              action:            action,
              predicted_outcome: predicted_outcome,
              confidence:        confidence,
              risk:              risk,
              preconditions:     preconditions,
              postconditions:    postconditions
            )
            { added: true, step_id: step.id, step_count: sim.step_count }
          end

          def run_simulation(simulation_id:)
            sim = @simulations[simulation_id]
            return { error: :simulation_not_found } unless sim

            sim.run!
            archive_simulation(sim)

            {
              simulation_id:      sim.id,
              state:              sim.state,
              overall_confidence: sim.overall_confidence,
              cumulative_risk:    sim.cumulative_risk,
              confidence_label:   sim.confidence_label,
              risk_label:         sim.risk_label,
              favorable:          sim.favorable?,
              step_count:         sim.step_count
            }
          end

          def abort_simulation(simulation_id:)
            sim = @simulations[simulation_id]
            return { error: :simulation_not_found } unless sim

            sim.abort!
            { simulation_id: sim.id, state: sim.state, aborted: true }
          end

          def assess_simulation(simulation_id:)
            sim = @simulations[simulation_id]
            return { error: :simulation_not_found } unless sim

            {
              simulation_id:      sim.id,
              label:              sim.label,
              domain:             sim.domain,
              state:              sim.state,
              step_count:         sim.step_count,
              overall_confidence: sim.overall_confidence,
              cumulative_risk:    sim.cumulative_risk,
              confidence_label:   sim.confidence_label,
              risk_label:         sim.risk_label,
              favorable:          sim.favorable?,
              steps:              sim.steps.map(&:to_h)
            }
          end

          def favorable_simulations
            @simulations.values.select(&:favorable?)
          end

          def failed_simulations
            @simulations.values.select { |s| s.state == :failed }
          end

          def simulations_by_domain(domain:)
            sym = domain.to_sym
            @simulations.values.select { |s| s.domain == sym }
          end

          def riskiest_simulations(limit: 5)
            @simulations.values
                        .sort_by { |s| -s.cumulative_risk }
                        .first(limit)
          end

          def most_confident(limit: 5)
            @simulations.values
                        .sort_by { |s| -s.overall_confidence }
                        .first(limit)
          end

          def to_h
            {
              total_simulations: @simulations.size,
              history_size:      @history.size,
              favorable_count:   favorable_simulations.size,
              failed_count:      failed_simulations.size,
              simulations:       @simulations.values.map(&:to_h)
            }
          end

          private

          def archive_simulation(sim)
            @history << { simulation_id: sim.id, state: sim.state, archived_at: Time.now.utc }
            @history.shift while @history.size > MAX_HISTORY
          end

          def prune_simulations
            completed = @simulations.select { |_, s| %i[completed failed aborted].include?(s.state) }
            oldest = completed.values.min_by(&:created_at)
            @simulations.delete(oldest.id) if oldest
          end
        end
      end
    end
  end
end
