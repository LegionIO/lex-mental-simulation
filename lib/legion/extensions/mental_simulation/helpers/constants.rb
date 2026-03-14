# frozen_string_literal: true

module Legion
  module Extensions
    module MentalSimulation
      module Helpers
        module Constants
          SIMULATION_STATES = %i[pending running completed failed aborted].freeze
          STEP_OUTCOMES     = %i[success partial_success failure unknown].freeze

          CONFIDENCE_LABELS = {
            (0.8..)     => :very_confident,
            (0.6...0.8) => :confident,
            (0.4...0.6) => :uncertain,
            (0.2...0.4) => :doubtful,
            (..0.2)     => :very_doubtful
          }.freeze

          RISK_LABELS = {
            (0.8..)     => :critical,
            (0.6...0.8) => :high,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :low,
            (..0.2)     => :negligible
          }.freeze

          MAX_SIMULATIONS    = 100
          MAX_STEPS_PER_SIM  = 50
          MAX_HISTORY        = 500

          DEFAULT_CONFIDENCE       = 0.5
          CONFIDENCE_BOOST         = 0.1
          CONFIDENCE_PENALTY       = 0.15
          RISK_ACCUMULATION_RATE   = 0.1
        end
      end
    end
  end
end
