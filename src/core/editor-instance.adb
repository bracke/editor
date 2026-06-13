with Editor.Executor;
with Editor.State;
with Textrender; use Textrender;
with Editor.Font_Config;
with Editor.Fonts.Init;
with Editor.History;
with Editor.Buffers;
with Ada.Text_IO;

package body Editor.Instance is

   Font_Initialized : Boolean := False;

   ------------------------------------------------------------------------
   procedure Init (E : in out Editor_Instance) is
   begin
      Editor.Fonts.Init.Initialize;
      E.Log.Clear;
      E.Position := 0;
      Editor.State.Init (E.State);
      Editor.Buffers.Ensure_Global_Registry (E.State);
   end Init;


   ------------------------------------------------------------------------
   procedure Load_Text
     (E    : in out Editor_Instance;
      Text : String) is
   begin
      Editor.State.Load_Text (E.State, Text);
      E.Log.Clear;
      E.Position := 0;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Buffers.Ensure_Global_Registry (E.State);
      Editor.Buffers.Sync_Global_Active_From_State (E.State);
   end Load_Text;

   ------------------------------------------------------------------------
   procedure Execute
     (E   : in out Editor_Instance;
      Cmd : Editor.Commands.Command) is
   begin
      E.Log.Append (Cmd);
      E.Position := Natural (E.Log.Length);

      Editor.Executor.Execute_No_Log (E.State, Cmd);
   end Execute;

   ------------------------------------------------------------------------
   procedure Undo (E : in out Editor_Instance) is
   begin
      --  Phase 372: the instance helper must not restore text
      --  through a private path.  Route through the canonical command id so
      --  availability, stack ownership, dirty tracking, Find/Replace
      --  invalidation, and message policy remain Executor-owned.
      Editor.Executor.Execute_Command (E.State, Editor.Commands.Command_Undo);
   end Undo;

   ------------------------------------------------------------------------
   procedure Redo (E : in out Editor_Instance) is
   begin
      --  Phase 372: keep redo on the same canonical route as keybindings and
      --  the command palette; do not pop/push history stacks locally.
      Editor.Executor.Execute_Command (E.State, Editor.Commands.Command_Redo);
   end Redo;

end Editor.Instance;