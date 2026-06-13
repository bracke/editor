with Editor.State;

package Editor.Command_Surface is

   type Command_Surface_Review is record
      Descriptor_Count             : Natural := 0;
      Stable_Ids_Unique             : Boolean := False;
      Display_Names_Present         : Boolean := False;
      Categories_Valid              : Boolean := False;
      Visibility_Consistent         : Boolean := False;
      Bindability_Consistent        : Boolean := False;
      Executor_Coverage_Complete    : Boolean := False;
      Availability_Reasons_Stable   : Boolean := False;
      Palette_Projection_Consistent : Boolean := False;
      Discoverability_Metadata_Coherent : Boolean := False;
      Keybinding_Targets_Valid      : Boolean := False;
      Persistence_Clean             : Boolean := False;
      Public_Build_Guardrail_Intact : Boolean := False;
      Review_Passed                 : Boolean := False;
   end record;

   --  Build a compact, side-effect-free review of the registered command
   --  surface.  This observes descriptors, stable ids, keybinding targets,
   --  palette projection rules, Executor availability coverage, and the
   --  public-build regression manifest; it does not register, repair, route,
   --  execute, or persist commands.
   function Review_Command_Surface
     (State : Editor.State.State_Type) return Command_Surface_Review;

   --  Return deterministic audit/test feedback for a command-surface review.
   --  The text intentionally contains no argv, shell syntax, environment,
   --  filesystem, PATH, run-id, generation, or project path details.
   function Build_Command_Surface_Review_Feedback
     (Review : Command_Surface_Review) return String;

   --  Phase 534 milestone helper. Returns True only when the configuration
   --  and command-discovery surface is coherent: descriptors are stable,
   --  palette projection hides internal/demo commands, active keybindings
   --  target bindable canonical commands only, availability can be queried
   --  repeatedly without changing the answer, and public-build persistence
   --  guardrails remain clean. This function is side-effect-free.
   function Assert_Configuration_Command_Surface_Coherent
     (State : Editor.State.State_Type) return Boolean;

end Editor.Command_Surface;
