## regulapradas.nim -- Regula + Pradas bridge. Re-export module.

{.experimental: "strict_funcs".}

import regulapradas/[trigger, feedback, constraint_dsl, session]
export trigger, feedback, constraint_dsl, session
