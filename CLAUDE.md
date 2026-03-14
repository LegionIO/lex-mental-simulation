# lex-mental-simulation

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-mental-simulation`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::MentalSimulation`

## Purpose

Step-by-step mental simulation runner for LegionIO agents. Allows the agent to create named simulations, add sequential steps with outcome probabilities, run the simulation to completion (applying confidence boosts on favorable steps and penalties on unfavorable ones), assess the result, and retrieve favorable or risky simulations for decision support.

## Gem Info

- **Require path**: `legion/extensions/mental_simulation`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/mental_simulation/
  version.rb
  helpers/
    constants.rb          # States, outcomes, labels, limits, confidence params
    simulation_engine.rb  # SimulationEngine with simulation lifecycle + assessment
  runners/
    mental_simulation.rb  # Runner module

spec/
  legion/extensions/mental_simulation/
    helpers/
      constants_spec.rb
      simulation_engine_spec.rb
    runners/mental_simulation_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
SIMULATION_STATES = %i[pending running completed aborted failed]
STEP_OUTCOMES     = %i[favorable neutral unfavorable uncertain]

CONFIDENCE_LABELS = {
  (0.8..)     => :very_high,
  (0.6...0.8) => :high,
  (0.4...0.6) => :moderate,
  (0.2...0.4) => :low,
  (..0.2)     => :very_low
}

RISK_LABELS = {
  (0.7..)     => :very_high,
  (0.5...0.7) => :high,
  (0.3...0.5) => :moderate,
  (0.1...0.3) => :low,
  (..0.1)     => :minimal
}

MAX_SIMULATIONS       = 100
MAX_STEPS_PER_SIM     = 50
DEFAULT_CONFIDENCE    = 0.5
CONFIDENCE_BOOST      = 0.1   # per favorable step
CONFIDENCE_PENALTY    = 0.15  # per unfavorable step
RISK_ACCUMULATION_RATE = 0.1  # risk increment per unfavorable step
```

## Helpers

### `Helpers::SimulationEngine` (class)

In-memory store for all simulations and their step-by-step execution.

Simulation data structure:
```ruby
{
  id:          String (UUID),
  name:        String,
  context:     Hash,
  state:       Symbol,       # from SIMULATION_STATES
  steps:       Array<Hash>,  # { description:, outcome:, probability:, notes: }
  confidence:  Float,        # evolves as steps are added and run
  risk_score:  Float,        # accumulates from unfavorable steps
  created_at:  Time,
  completed_at: Time
}
```

| Method | Description |
|---|---|
| `create_simulation(name:, context:)` | creates new simulation in :pending state; enforces MAX_SIMULATIONS |
| `add_simulation_step(id:, description:, outcome:, probability:, notes:)` | appends step; enforces MAX_STEPS_PER_SIM |
| `run_simulation(id:)` | transitions to :running then :completed; applies confidence boosts/penalties per step outcome |
| `abort_simulation(id:)` | transitions to :aborted |
| `assess_simulation(id:)` | returns summary with confidence label, risk label, recommendation |
| `favorable_simulations(limit:)` | completed simulations with highest confidence |
| `riskiest_simulations(limit:)` | completed simulations with highest risk_score |

`run_simulation` step processing:
- `:favorable` step: confidence += CONFIDENCE_BOOST
- `:unfavorable` step: confidence -= CONFIDENCE_PENALTY; risk_score += RISK_ACCUMULATION_RATE
- `:neutral` / `:uncertain` step: no change
- Final confidence clamped to 0.0..1.0

## Runners

Module: `Legion::Extensions::MentalSimulation::Runners::MentalSimulation`

Private state: `@engine` (memoized `SimulationEngine` instance).

| Runner Method | Parameters | Description |
|---|---|---|
| `create_mental_simulation` | `name:, context: {}` | Create a new simulation |
| `add_simulation_step` | `simulation_id:, description:, outcome:, probability: 0.5, notes: nil` | Add a step |
| `run_mental_simulation` | `simulation_id:` | Execute the simulation |
| `abort_mental_simulation` | `simulation_id:` | Abort a simulation |
| `assess_mental_simulation` | `simulation_id:` | Full assessment with labels and recommendation |
| `favorable_simulations_report` | `limit: 5` | Top N most confident completed simulations |
| `failed_simulations_report` | `limit: 5` | Most recently failed/aborted simulations |
| `riskiest_simulations_report` | `limit: 5` | Top N highest-risk completed simulations |
| `mental_simulation_stats` | (none) | Total, by state, avg confidence, avg risk |

## Integration Points

- **lex-imagination**: imagination builds multi-scenario counterfactual comparisons; mental simulation runs step-by-step sequential processes. Both contribute to action_selection but at different granularity levels.
- **lex-planning**: planning constructs action sequences; mental simulation validates them by running through each step before committing.
- **lex-tick**: simulation assessment feeds into `action_selection` phase — simulations with high risk_score can trigger caution mode.
- **lex-metacognition**: `MentalSimulation` is listed under `:cognition` capability category.

## Development Notes

- Simulation state transitions are linear: pending -> running -> completed (or aborted/failed). There is no branching — all steps run sequentially in insertion order.
- Step `outcome` is set by the caller at step creation time, not dynamically determined during `run_simulation`. The "simulation" is therefore a replay of a pre-specified outcome sequence, not a stochastic simulation.
- `probability` field on steps is stored but not used in the current run_simulation logic. It is available for future weighted confidence calculations.
- MAX_SIMULATIONS eviction removes oldest completed/aborted simulations (by created_at) when the limit is reached.
- `assess_simulation` recommendation is: :proceed if confidence > 0.6 and risk < 0.5; :caution if confidence between 0.4..0.6 or risk 0.3..0.5; :abort otherwise.
- No actor defined; simulations are created and run on-demand.
