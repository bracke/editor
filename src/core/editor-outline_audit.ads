with Editor.State;

package Editor.Outline_Audit is

   type Outline_Contract_Review is record
      Active_Buffer_Only            : Boolean := False;
      Refresh_Command_Owned         : Boolean := False;
      Extraction_Deterministic      : Boolean := False;
      Projection_Side_Effect_Free   : Boolean := False;
      Selection_Stable              : Boolean := False;
      Current_Symbol_Derived        : Boolean := False;
      Targets_Validated             : Boolean := False;
      Filters_Projection_Only       : Boolean := False;
      Ada_Symbol_Navigation_Coherent : Boolean := False;
      Ada_Local_Structure_Coherent  : Boolean := False;
      Ada_Lexical_Safety_Coherent    : Boolean := False;
      Lifecycle_Reset_Stable        : Boolean := False;
      Persistence_Clean             : Boolean := False;
      Feature_Panel_Intact          : Boolean := False;
      Command_Surface_Intact        : Boolean := False;
      Public_Build_Guardrail_Intact : Boolean := False;
      Review_Passed                 : Boolean := False;
   end record;

   --  Compact review of the active-buffer Outline contract.
   --  The helper observes editor state and exercises only local copies for
   --  refresh/projection/selection/lifecycle checks. It does not refresh the
   --  live outline, parse buffers, move carets, alter selection, change the
   --  active Feature Panel feature, post messages, execute commands, inspect
   --  project files, call process runners, or persist audit results.
   function Review_Outline_Contract
     (State : Editor.State.State_Type) return Outline_Contract_Review;

   --  milestone helper for active-file Ada symbol navigation.
   --  The helper is observational: it uses existing Outline rows, command
   --  descriptors, and projection helpers only. It does not parse, refresh,
   --  navigate, mutate Feature Panel selection, inspect files, or persist state.
   function Assert_Ada_Symbol_Navigation_Coherent
     (State : Editor.State.State_Type) return Boolean;

   --  milestone helper for local Ada structure awareness. The helper
   --  is observational: it checks accepted Outline/range metadata through
   --  side-effect-free helpers and does not parse, refresh, compute render
   --  ranges, navigate, write files, or persist audit results.
   function Assert_Ada_Local_Structure_Awareness_Coherent
     (State : Editor.State.State_Type) return Boolean;

   --  milestone helper for Ada comment/string/character lexical
   --  safety. The helper uses side-effect-free scanner/extraction helpers on
   --  synthetic snapshots only; it does not inspect files, mutate editor state,
   --  render, navigate, or persist scanner state.
   function Assert_Ada_Lexical_Safety_Coherent
     (State : Editor.State.State_Type) return Boolean;

   --  Deterministic audit/test feedback. The returned text contains no argv,
   --  shell syntax, environment, PATH lookup detail, filesystem paths, run ids,
   --  projection generations, or serialized outline item dumps.
   function Build_Outline_Contract_Review_Feedback
     (Review : Outline_Contract_Review) return String;

end Editor.Outline_Audit;
