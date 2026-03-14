# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module MentalSimulation
      module Helpers
        class SimulationStep
          attr_reader :id, :action, :predicted_outcome, :confidence, :risk,
                      :preconditions, :postconditions, :created_at

          def initialize(action:, predicted_outcome: :success, confidence: 0.5, risk: 0.1,
                         preconditions: [], postconditions: [])
            @id               = SecureRandom.uuid
            @action           = action
            @predicted_outcome = predicted_outcome
            @confidence       = confidence.clamp(0.0, 1.0)
            @risk             = risk.clamp(0.0, 1.0)
            @preconditions    = Array(preconditions)
            @postconditions   = Array(postconditions)
            @created_at       = Time.now.utc
          end

          def favorable?
            %i[success partial_success].include?(@predicted_outcome) && @confidence >= 0.5
          end

          def risky?
            @risk >= 0.6
          end

          def to_h
            {
              id:                @id,
              action:            @action,
              predicted_outcome: @predicted_outcome,
              confidence:        @confidence,
              risk:              @risk,
              preconditions:     @preconditions,
              postconditions:    @postconditions,
              created_at:        @created_at
            }
          end
        end
      end
    end
  end
end
