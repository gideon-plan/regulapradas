## session.nim -- Combined session managing regula + pradas lifecycle.
##
## Orchestrates the trigger-solve-feedback loop.

{.experimental: "strict_funcs".}

import lattice, trigger, feedback

# =====================================================================================================================
# Types
# =====================================================================================================================

type
  BridgeSession* = object
    solver_fn*: SolverFn
    assert_fn*: AssertFn
    solution_fact_type*: string
    trigger_count*: int
    feedback_count*: int

# =====================================================================================================================
# Session management
# =====================================================================================================================

proc new_bridge_session*(solver_fn: SolverFn, assert_fn: AssertFn,
                         solution_fact_type: string = "solver_result"): BridgeSession =
  BridgeSession(solver_fn: solver_fn, assert_fn: assert_fn,
                solution_fact_type: solution_fact_type)

proc dispatch*(session: var BridgeSession, request: TriggerRequest
              ): Result[int, BridgeError] =
  ## Execute a trigger request: invoke solver, assert results as facts.
  ## Returns number of facts asserted.
  let solution = execute_trigger(request, session.solver_fn)
  if solution.is_bad:
    return Result[int, BridgeError].bad(solution.err)
  inc session.trigger_count
  let count = assert_solution(solution.val, session.solution_fact_type, session.assert_fn)
  if count.is_bad:
    return Result[int, BridgeError].bad(count.err)
  session.feedback_count += count.val
  Result[int, BridgeError].good(count.val)

proc stats*(session: BridgeSession): tuple[triggers: int, facts: int] =
  (triggers: session.trigger_count, facts: session.feedback_count)
