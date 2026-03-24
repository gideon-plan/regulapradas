## constraint_dsl.nim -- Inline constraint declarations for regula rules.
##
## Provides a simple DSL for declaring pradas constraints inline in rule actions.

{.experimental: "strict_funcs".}

import std/tables
import trigger

# =====================================================================================================================
# Types
# =====================================================================================================================

type
  ConstraintKind* = enum
    ckMinimize    ## Minimize a score
    ckMaximize    ## Maximize a score
    ckSatisfy     ## Find any feasible solution

  InlineConstraint* = object
    kind*: ConstraintKind
    entity_type*: string
    variable_name*: string
    domain*: seq[string]
    hard_constraints*: seq[string]  ## String expressions for hard constraints

# =====================================================================================================================
# DSL
# =====================================================================================================================

proc minimize*(entity_type, variable_name: string, domain: seq[string]): InlineConstraint =
  InlineConstraint(kind: ckMinimize, entity_type: entity_type,
                   variable_name: variable_name, domain: domain)

proc maximize*(entity_type, variable_name: string, domain: seq[string]): InlineConstraint =
  InlineConstraint(kind: ckMaximize, entity_type: entity_type,
                   variable_name: variable_name, domain: domain)

proc satisfy*(entity_type, variable_name: string, domain: seq[string]): InlineConstraint =
  InlineConstraint(kind: ckSatisfy, entity_type: entity_type,
                   variable_name: variable_name, domain: domain)

proc with_hard*(ic: InlineConstraint, constraint: string): InlineConstraint =
  var copy = ic
  copy.hard_constraints.add(constraint)
  copy

proc to_trigger_request*(ic: InlineConstraint, rule_name: string,
                         bindings: Table[string, string]): TriggerRequest =
  ## Convert an inline constraint to a trigger request for the solver.
  let param = ConstraintParam(name: ic.variable_name, values: ic.domain)
  create_trigger(rule_name, bindings, @[param])
