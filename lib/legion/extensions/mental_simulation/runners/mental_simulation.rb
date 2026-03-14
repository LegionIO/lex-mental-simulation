# frozen_string_literal: true

module Legion
  module Extensions
    module MentalSimulation
      module Runners
        module MentalSimulation
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_mental_simulation(label:, domain:, **)
            sim = engine.create_simulation(label: label, domain: domain)
            Legion::Logging.debug "[mental_simulation] created simulation id=#{sim.id[0..7]} label=#{label} domain=#{domain}"
            { simulation_id: sim.id, label: sim.label, domain: sim.domain, state: sim.state }
          end

          def add_simulation_step(simulation_id:, action:, predicted_outcome: :success,
                                  confidence: 0.5, risk: 0.1, preconditions: [], postconditions: [], **)
            result = engine.add_simulation_step(
              simulation_id:     simulation_id,
              action:            action,
              predicted_outcome: predicted_outcome,
              confidence:        confidence,
              risk:              risk,
              preconditions:     preconditions,
              postconditions:    postconditions
            )
            Legion::Logging.debug "[mental_simulation] add_step sim=#{simulation_id[0..7]} action=#{action} result=#{result[:added]}"
            result
          end

          def run_mental_simulation(simulation_id:, **)
            result = engine.run_simulation(simulation_id: simulation_id)
            if result[:error]
              Legion::Logging.warn "[mental_simulation] run failed: #{result[:error]}"
            else
              Legion::Logging.info "[mental_simulation] ran sim=#{simulation_id[0..7]} " \
                                   "state=#{result[:state]} favorable=#{result[:favorable]}"
            end
            result
          end

          def abort_mental_simulation(simulation_id:, **)
            result = engine.abort_simulation(simulation_id: simulation_id)
            Legion::Logging.info "[mental_simulation] aborted sim=#{simulation_id[0..7]}"
            result
          end

          def assess_mental_simulation(simulation_id:, **)
            result = engine.assess_simulation(simulation_id: simulation_id)
            Legion::Logging.debug "[mental_simulation] assessed sim=#{simulation_id[0..7]} steps=#{result[:step_count]}"
            result
          end

          def favorable_simulations_report(**)
            sims = engine.favorable_simulations
            Legion::Logging.debug "[mental_simulation] favorable count=#{sims.size}"
            { simulations: sims.map(&:to_h), count: sims.size }
          end

          def failed_simulations_report(**)
            sims = engine.failed_simulations
            Legion::Logging.debug "[mental_simulation] failed count=#{sims.size}"
            { simulations: sims.map(&:to_h), count: sims.size }
          end

          def riskiest_simulations_report(limit: 5, **)
            sims = engine.riskiest_simulations(limit: limit)
            Legion::Logging.debug "[mental_simulation] riskiest count=#{sims.size} limit=#{limit}"
            { simulations: sims.map(&:to_h), count: sims.size }
          end

          def mental_simulation_stats(**)
            stats = engine.to_h.except(:simulations)
            Legion::Logging.debug "[mental_simulation] stats total=#{stats[:total_simulations]}"
            stats
          end

          private

          def engine
            @engine ||= Helpers::SimulationEngine.new
          end
        end
      end
    end
  end
end
