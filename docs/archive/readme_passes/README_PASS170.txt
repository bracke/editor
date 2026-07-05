Editor IDE-grade Outline/Semantic Colouring - pass 170

Completeness pass after canonical language command registration.

Implemented:
- Project close/clear/switch now clears the transient Ada language index in Reset_Project_Scoped_State.
- File lifecycle invalidation now invalidates Ada project-index entries for the current source path and active buffer token.
- This connects the pass169 command/index state to existing lifecycle invalidation paths instead of leaving stale indexed rows until an explicit clear command.
- Updated Outline and semantic-colouring documentation.
- Extended release_check guards for the lifecycle invalidation wiring.

Not run here:
- GNAT/gprbuild/AUnit, because the environment does not provide GNAT/gprbuild.
