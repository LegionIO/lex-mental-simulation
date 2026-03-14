# lex-mental-simulation

Step-by-step mental simulation for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-mental-simulation` lets an agent mentally walk through a sequence of steps before acting. Simulations are created with a name and context, steps are added with outcome labels (favorable/neutral/unfavorable/uncertain), and when run, each step adjusts the simulation's confidence and risk score. Completed simulations can be assessed, ranked by confidence or risk, and used to guide action selection.

Key capabilities:

- **Step-by-step execution**: up to 50 steps per simulation
- **Confidence dynamics**: favorable steps +0.1, unfavorable steps -0.15
- **Risk accumulation**: unfavorable steps +0.1 to risk score
- **Assessment**: confidence label, risk label, and proceed/caution/abort recommendation
- **Ranked retrieval**: most favorable or riskiest completed simulations

## Installation

Add to your Gemfile:

```ruby
gem 'lex-mental-simulation'
```

Or install directly:

```
gem install lex-mental-simulation
```

## Usage

```ruby
require 'legion/extensions/mental_simulation'

client = Legion::Extensions::MentalSimulation::Client.new

# Create a simulation
sim = client.create_mental_simulation(name: 'Deploy to production', context: { environment: :prod })
sim_id = sim[:simulation][:id]

# Add steps
client.add_simulation_step(simulation_id: sim_id, description: 'Run test suite', outcome: :favorable, probability: 0.95)
client.add_simulation_step(simulation_id: sim_id, description: 'Deploy to staging', outcome: :favorable, probability: 0.9)
client.add_simulation_step(simulation_id: sim_id, description: 'Production deploy', outcome: :uncertain, probability: 0.8)
client.add_simulation_step(simulation_id: sim_id, description: 'Monitor error rate', outcome: :neutral, probability: 1.0)

# Run it
client.run_mental_simulation(simulation_id: sim_id)

# Assess
result = client.assess_mental_simulation(simulation_id: sim_id)
# => { confidence: 0.7, confidence_label: :high, risk: 0.0, risk_label: :minimal,
#      recommendation: :proceed }

# Find best and riskiest simulations
client.favorable_simulations_report(limit: 3)
client.riskiest_simulations_report(limit: 3)

# Stats
client.mental_simulation_stats
```

## Runner Methods

| Method | Description |
|---|---|
| `create_mental_simulation` | Create a new simulation |
| `add_simulation_step` | Add a step with an outcome label |
| `run_mental_simulation` | Execute the simulation through all steps |
| `abort_mental_simulation` | Abort a simulation |
| `assess_mental_simulation` | Full assessment: confidence, risk, recommendation |
| `favorable_simulations_report` | Top N most confident completed simulations |
| `failed_simulations_report` | Most recently failed or aborted simulations |
| `riskiest_simulations_report` | Top N highest-risk completed simulations |
| `mental_simulation_stats` | Total count, by state, avg confidence, avg risk |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
