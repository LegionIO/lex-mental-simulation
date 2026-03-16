# frozen_string_literal: true

require_relative 'lib/legion/extensions/mental_simulation/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-mental-simulation'
  spec.version       = Legion::Extensions::MentalSimulation::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Mental Simulation'
  spec.description   = 'Forward mental simulation of action sequences — imagine a plan, predict step outcomes, evaluate before executing'
  spec.homepage      = 'https://github.com/LegionIO/lex-mental-simulation'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-mental-simulation'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-mental-simulation'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-mental-simulation'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-mental-simulation/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-mental-simulation.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
