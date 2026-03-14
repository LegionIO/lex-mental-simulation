# frozen_string_literal: true

require 'legion/extensions/mental_simulation/version'
require 'legion/extensions/mental_simulation/helpers/constants'
require 'legion/extensions/mental_simulation/helpers/simulation_step'
require 'legion/extensions/mental_simulation/helpers/simulation'
require 'legion/extensions/mental_simulation/helpers/simulation_engine'
require 'legion/extensions/mental_simulation/runners/mental_simulation'
require 'legion/extensions/mental_simulation/helpers/client'

module Legion
  module Extensions
    module MentalSimulation
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
