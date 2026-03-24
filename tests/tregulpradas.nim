## tregulapradas.nim -- Tests for regulapradas bridge.

{.experimental: "strict_funcs".}

import std/[unittest, tables]
import regulapradas

# =====================================================================================================================
# Trigger tests
# =====================================================================================================================

suite "trigger":
  test "create trigger request":
    var bindings: Table[string, string]
    bindings["x"] = "10"
    let params = @[ConstraintParam(name: "slot", values: @["a", "b", "c"])]
    let req = create_trigger("assign_rule", bindings, params)
    check req.rule_name == "assign_rule"
    check req.bindings["x"] == "10"
    check req.constraints.len == 1
    check req.constraints[0].name == "slot"

  test "execute trigger with mock solver":
    var bindings: Table[string, string]
    bindings["x"] = "5"
    let req = create_trigger("test_rule", bindings, @[])
    let mock_solver: SolverFn = proc(r: TriggerRequest): Result[Table[string, string], BridgeError] {.raises: [].} =
      var solution: Table[string, string]
      solution["slot"] = "a"
      Result[Table[string, string], BridgeError].good(solution)
    let result = execute_trigger(req, mock_solver)
    check result.is_good
    check result.val["slot"] == "a"

# =====================================================================================================================
# Feedback tests
# =====================================================================================================================

suite "feedback":
  test "solution to facts":
    var solution: Table[string, string]
    solution["x"] = "1"
    solution["y"] = "2"
    let facts = solution_to_facts(solution, "solver_result")
    check facts.len == 2
    for f in facts:
      check f.fact_type == "solver_result"
      check f.field_names == @["variable", "value"]

  test "assert solution with mock":
    var solution: Table[string, string]
    solution["x"] = "1"
    var asserted: seq[FactAssertion]
    let mock_assert: AssertFn = proc(a: FactAssertion): Result[void, BridgeError] {.raises: [].} =
      asserted.add(a)
      Result[void, BridgeError](ok: true)
    let result = assert_solution(solution, "result", mock_assert)
    check result.is_good
    check result.val == 1
    check asserted.len == 1

# =====================================================================================================================
# Constraint DSL tests
# =====================================================================================================================

suite "constraint_dsl":
  test "minimize constraint":
    let ic = minimize("Shift", "slot", @["morning", "afternoon", "night"])
    check ic.kind == ckMinimize
    check ic.entity_type == "Shift"
    check ic.domain.len == 3

  test "with hard constraint":
    let ic = minimize("Shift", "slot", @["a", "b"]).with_hard("no_overlap")
    check ic.hard_constraints.len == 1
    check ic.hard_constraints[0] == "no_overlap"

  test "to trigger request":
    var bindings: Table[string, string]
    bindings["employee"] = "alice"
    let ic = satisfy("Shift", "slot", @["a", "b"])
    let req = ic.to_trigger_request("assign_shift", bindings)
    check req.rule_name == "assign_shift"
    check req.constraints.len == 1

# =====================================================================================================================
# Session tests
# =====================================================================================================================

suite "session":
  test "dispatch loop":
    let mock_solver: SolverFn = proc(r: TriggerRequest): Result[Table[string, string], BridgeError] {.raises: [].} =
      var solution: Table[string, string]
      solution["slot"] = "morning"
      Result[Table[string, string], BridgeError].good(solution)
    var asserted_facts: seq[FactAssertion]
    let mock_assert: AssertFn = proc(a: FactAssertion): Result[void, BridgeError] {.raises: [].} =
      asserted_facts.add(a)
      Result[void, BridgeError](ok: true)
    var session = new_bridge_session(mock_solver, mock_assert)
    var bindings: Table[string, string]
    bindings["emp"] = "alice"
    let req = create_trigger("shift_rule", bindings, @[])
    let result = session.dispatch(req)
    check result.is_good
    check result.val == 1
    let (triggers, facts) = session.stats()
    check triggers == 1
    check facts == 1
    check asserted_facts.len == 1
