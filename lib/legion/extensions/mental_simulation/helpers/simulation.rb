# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module MentalSimulation
      module Helpers
        class Simulation
          include Constants

          attr_reader :id, :label, :domain, :steps, :state, :created_at, :completed_at

          def initialize(label:, domain:)
            @id           = SecureRandom.uuid
            @label        = label
            @domain       = domain.to_sym
            @steps        = []
            @state        = :pending
            @created_at   = Time.now.utc
            @completed_at = nil
          end

          def add_step(action:, predicted_outcome: :success, confidence: 0.5, risk: 0.1,
                       preconditions: [], postconditions: [])
            step = SimulationStep.new(
              action:            action,
              predicted_outcome: predicted_outcome,
              confidence:        confidence,
              risk:              risk,
              preconditions:     preconditions,
              postconditions:    postconditions
            )
            @steps << step
            step
          end

          def run!
            @state = :running
            accumulated_risk = 0.0

            @steps.each do |step|
              accumulated_risk += step.risk * RISK_ACCUMULATION_RATE

              next unless step.predicted_outcome == :failure && step.confidence > 0.7

              @state = :aborted
              return self
            end

            final_state = overall_confidence >= 0.5 && cumulative_risk < 0.6 ? :completed : :failed
            @state        = final_state
            @completed_at = Time.now.utc
            self
          end

          def abort!
            @state        = :aborted
            @completed_at = Time.now.utc
            self
          end

          def overall_confidence
            return 0.0 if @steps.empty?

            @steps.reduce(1.0) { |prod, step| prod * step.confidence }
          end

          def cumulative_risk
            return 0.0 if @steps.empty?

            1.0 - @steps.reduce(1.0) { |prod, step| prod * (1.0 - step.risk) }
          end

          def favorable?
            @state == :completed && overall_confidence >= 0.5 && cumulative_risk < 0.6
          end

          def confidence_label
            CONFIDENCE_LABELS.find { |range, _| range.cover?(overall_confidence) }&.last || :very_doubtful
          end

          def risk_label
            RISK_LABELS.find { |range, _| range.cover?(cumulative_risk) }&.last || :negligible
          end

          def step_count
            @steps.size
          end

          def to_h
            {
              id:                 @id,
              label:              @label,
              domain:             @domain,
              state:              @state,
              step_count:         step_count,
              overall_confidence: overall_confidence,
              cumulative_risk:    cumulative_risk,
              confidence_label:   confidence_label,
              risk_label:         risk_label,
              favorable:          favorable?,
              steps:              @steps.map(&:to_h),
              created_at:         @created_at,
              completed_at:       @completed_at
            }
          end
        end
      end
    end
  end
end
