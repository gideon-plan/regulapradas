## trigger.nim -- Regula rule actions that invoke pradas solver.
##
## When a rule fires, its action can trigger a constraint optimization problem.
## The trigger extracts constraint parameters from the rule's bound variables.

{.experimental: "strict_funcs".}

import std/tables
import lattice

# =====================================================================================================================
# Types
# =====================================================================================================================

type
  ConstraintParam* = object
    ## Parameters extracted from a rule activation for the solver.
    name*: string
    values*: seq[string]  ## Domain values for this parameter

  TriggerRequest* = object
    ## A request from regula to pradas.
    rule_name*: string
    bindings*: Table[string, string]  ## Variable bindings from rule match
    constraints*: seq[ConstraintParam]

  SolverFn* = proc(request: TriggerRequest): Result[Table[string, string], BridgeError] {.raises: [].}
    ## Function that invokes pradas solver and returns assignment.

# =====================================================================================================================
# Trigger
# =====================================================================================================================

proc create_trigger*(rule_name: string, bindings: Table[string, string],
                     constraints: seq[ConstraintParam]): TriggerRequest =
  TriggerRequest(rule_name: rule_name, bindings: bindings, constraints: constraints)

proc execute_trigger*(request: TriggerRequest, solver_fn: SolverFn
                     ): Result[Table[string, string], BridgeError] =
  ## Execute the solver for a trigger request.
  solver_fn(request)
