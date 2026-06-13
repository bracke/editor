Editor Phase 579 pass779: parallel loop grammar depth

Implemented bounded Ada 2022 parallel loop statement metadata in the token cursor.

Changes:
- Added `parallel` to the token cursor keyword table.
- Added `Production_Parallel_Loop_Statement`.
- Added `Production_Parallel_Loop_Keyword`.
- Added `Production_Parallel_Loop_Chunk_Specification`.
- Added `Production_Parallel_Loop_Chunk_Expression`.
- Added `Production_Parallel_Loop_Iteration_Scheme`.
- Added `Production_Parallel_Loop_Recovery_Boundary`.
- Parallel loop parsing now preserves nested ordinary loop metadata by delegating the post-`parallel` `for`, iterator, `while`, or bare `loop` scheme to the existing bounded loop parser.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Parallel_Loop_Depth_Pass779`.
- Updated validation/release guards and parser coverage docs.

This improves structural grammar coverage for Ada parallel loop statements. It is not compiler-grade parallel execution legality checking, chunk-specification staticness checking, iterator legality checking, data-race analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
