with Editor.Commands;
with Editor.State;

package Editor.Core_Editing_Workflow is

   type Core_Editing_Workflow_Result is record
      Active_Buffer_State_Coherent : Boolean := False;
      File_State_Coherent          : Boolean := False;
      Dirty_State_Coherent         : Boolean := False;
      Caret_State_Coherent         : Boolean := False;
      Selection_State_Coherent     : Boolean := False;
      Persistence_Boundary_Coherent : Boolean := False;
      Transient_Boundary_Coherent  : Boolean := False;
      Command_Availability_Coherent : Boolean := False;
      Prompt_Boundary_Coherent     : Boolean := False;
      Dirty_Close_Guard_Coherent   : Boolean := False;
      Caret_Command_Coverage_Coherent : Boolean := False;
      Selection_Command_Coverage_Coherent : Boolean := False;
      Text_Mutation_Command_Coverage_Coherent : Boolean := False;
      Input_Bridge_Boundary_Coherent : Boolean := False;
      Coherent                     : Boolean := False;
   end record;

   --  Return the concise dirty-state label used by editing/file lifecycle UI
   --  projections.  This is a pure projection over State and never changes the
   --  buffer, dirty flag, saved baseline, or registry state.
   function Buffer_Dirty_Label
     (S : Editor.State.State_Type) return String;

   --  Return a concise file-backing label for the active buffer.  The helper
   --  does not probe the filesystem; it describes only the retained buffer
   --  association state.
   function Buffer_File_State_Label
     (S : Editor.State.State_Type) return String;

   --  Return whether the command belongs to the Phase 532 core editing/file
   --  workflow surface.  This is descriptor classification only and never
   --  executes a command.
   function Is_Core_Editing_Command
     (Id : Editor.Commands.Command_Id) return Boolean;

   --  Return whether the command is a buffer lifecycle/navigation command in
   --  the Phase 532 editing loop: open/new/close/reopen/switch.  This helper
   --  deliberately excludes project lifecycle, build, diagnostics, search,
   --  and panel-local commands.
   function Is_Buffer_Lifecycle_Command
     (Id : Editor.Commands.Command_Id) return Boolean;

   --  Return whether the command is a caret/navigation operation in the
   --  editing loop.  Overlay/query setup commands for goto-line are included
   --  because they parameterize a bounded caret move but do not mutate text.
   function Is_Caret_Navigation_Command
     (Id : Editor.Commands.Command_Id) return Boolean;

   --  Return whether the command creates, extends, clears, or consumes an
   --  active-buffer selection.  Copy/cut/delete are included because their
   --  availability depends on a normalized selection range.
   function Is_Selection_Command
     (Id : Editor.Commands.Command_Id) return Boolean;

   --  Return whether the command mutates active-buffer text without being a
   --  file lifecycle save/reload/rename/copy/move command.
   function Is_Text_Editing_Command
     (Id : Editor.Commands.Command_Id) return Boolean;

   --  Return whether the command writes or discards active-buffer text.  This
   --  helper is used by route/audit tests to distinguish caret-only commands
   --  from commands that must dirty, save, reload, or explicitly discard text.
   function Mutates_Or_Replaces_Buffer_Text
     (Id : Editor.Commands.Command_Id) return Boolean;

   --  Return whether the command requires an active file-backed buffer path.
   function Requires_File_Backed_Buffer
     (Id : Editor.Commands.Command_Id) return Boolean;

   --  Return the stable, user-readable reason that a core editing/file command
   --  would be unavailable from the supplied state.  Empty means available.
   --  This is intentionally side-effect-free and does not consult or mutate
   --  render, palette, persistence, project, diagnostics, outline, or build
   --  state.
   function Editing_Availability_Reason
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return String;

   --  Inspect the active editing state for Phase 532 invariants: file-backed
   --  identity, dirty baseline, caret/selection bounds, persistence exclusions,
   --  and command availability reason coherence.
   function Audit_Core_Editing_Workflow
     (S : Editor.State.State_Type) return Core_Editing_Workflow_Result;

   function Assert_Core_Editing_Workflow_Coherent
     (S : Editor.State.State_Type) return Boolean;

   --  Phase 540 milestone helper: verify that everyday text-editing
   --  primitives are coherently represented in the static command surface.
   --  This is descriptor/classification/command-name coverage only; it never mutates
   --  buffer text, caret/selection state, undo/redo history, render state, or
   --  persistence domains.
   function Assert_Text_Editing_Primitives_Coherent return Boolean;

end Editor.Core_Editing_Workflow;
