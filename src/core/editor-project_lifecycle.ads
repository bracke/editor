with Ada.Strings.Unbounded;

package Editor.Project_Lifecycle is

   type Project_Lifecycle_Transition is
     (No_Project_Lifecycle_Transition,
      Open_Project_Lifecycle_Transition,
      Open_Recent_Project_Lifecycle_Transition,
      Switch_Project_Lifecycle_Transition,
      Reset_Project_Lifecycle_Transition,
      Close_Project_Lifecycle_Transition,
      Clear_Project_Context_Lifecycle_Transition,
      Restore_Workspace_Lifecycle_Transition);

   type Project_Buffer_Close_Policy is
     (Retain_All_Buffers,
      Close_Project_File_Buffers,
      Close_All_Clean_Project_Buffers);

   --  Return True for transitions that install or switch to a project root.
   --  This helper is side-effect-free and is intended for lifecycle audits.
   --  @param Transition lifecycle transition to classify
   --  @return True when Transition opens a project root
   function Is_Project_Opening_Transition
     (Transition : Project_Lifecycle_Transition) return Boolean;

   --  Return True for transitions that remove or clear the active project root.
   --  This helper is side-effect-free and is intended for lifecycle audits.
   --  @param Transition lifecycle transition to classify
   --  @return True when Transition closes or clears project context
   function Is_Project_Closing_Transition
     (Transition : Project_Lifecycle_Transition) return Boolean;

   --  Return True when Transition can discard, hide, replace, or reload user
   --  editing context and therefore must pass through Dirty_Guards before
   --  mutating state.
   --  @param Transition lifecycle transition to classify
   --  @return True when dirty-buffer protection is required
   function Requires_Dirty_Guard
     (Transition : Project_Lifecycle_Transition) return Boolean;

   --  Return True when Transition resets state derived from the active project.
   --  This does not imply that global editor state, recent projects, workspace
   --  session files, or buffer contents are reset.
   --  @param Transition lifecycle transition to classify
   --  @return True when project-scoped UI/cache state is reset
   function Resets_Project_Scoped_State
     (Transition : Project_Lifecycle_Transition) return Boolean;

   type Project_Lifecycle_Result is record
      Project_Changed          : Boolean := False;
      Project_Closed           : Boolean := False;
      Buffers_Closed           : Natural := 0;
      Dirty_Buffers_Blocked    : Natural := 0;
      Project_State_Reset      : Boolean := False;
      Recent_Project_Promoted  : Boolean := False;
      Workspace_State_Restored : Boolean := False;
   end record;

   function Summary_Text
     (Result : Project_Lifecycle_Result) return String;

end Editor.Project_Lifecycle;
