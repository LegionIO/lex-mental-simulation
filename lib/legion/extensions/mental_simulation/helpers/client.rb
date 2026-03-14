# frozen_string_literal: true

module Legion
  module Extensions
    module MentalSimulation
      class Client
        include Runners::MentalSimulation

        def initialize(**)
          @engine = Helpers::SimulationEngine.new
        end

        private

        attr_reader :engine
      end
    end
  end
end
