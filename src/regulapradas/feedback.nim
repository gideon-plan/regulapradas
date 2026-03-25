## feedback.nim -- Pradas solution results asserted as regula facts.
##
## Takes solver output (variable assignments) and converts them to
## fact insertions for the regula session.

{.experimental: "strict_funcs".}

import std/tables
import basis/code/choice

# =====================================================================================================================
# Types
# =====================================================================================================================

type
  FactAssertion* = object
    ## A fact to be inserted into the regula session.
    fact_type*: string
    field_names*: seq[string]
    field_values*: seq[string]

  AssertFn* = proc(assertion: FactAssertion): Choice[bool] {.raises: [].}
    ## Function that inserts a fact into the regula session.

# =====================================================================================================================
# Feedback
# =====================================================================================================================

proc solution_to_facts*(solution: Table[string, string],
                        fact_type: string): seq[FactAssertion] =
  ## Convert a solver solution (variable -> value map) into fact assertions.
  ## Each variable assignment becomes a fact with fields "variable" and "value".
  for variable, value in solution:
    result.add(FactAssertion(
      fact_type: fact_type,
      field_names: @["variable", "value"],
      field_values: @[variable, value]))

proc assert_solution*(solution: Table[string, string], fact_type: string,
                      assert_fn: AssertFn): Choice[int] =
  ## Assert all facts from a solver solution. Returns count of facts asserted.
  let facts = solution_to_facts(solution, fact_type)
  var count = 0
  for f in facts:
    let r = assert_fn(f)
    if r.is_bad:
      return bad[int](r.err)
    inc count
  good(count)
