with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases.Registration;
with Editor.Buffers;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor;
with Editor.Input_Field;
with Editor.Go_To_Line;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Render_Model;
with Editor.Search;
with Editor.State;
with Editor.Workspace_Persistence;
with Text_Buffer;

use type Editor.Commands.Command_Category;
use type Editor.Commands.Command_Id;
use type Editor.Commands.Command_Visibility;
use type Editor.Commands.Command_Availability_Status;
use type Editor.Keybindings.Binding_Result;

package body Editor.Active_Find.Tests is

   overriding function Name
     (T : Active_Find_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Active_Find");
   end Name;

   function Active_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      M := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (M);
      else
         return "";
      end if;
   end Active_Message_Text;

   function Chord
     (Key   : Editor.Keybindings.Key_Code;
      Ctrl  : Boolean := False;
      Shift : Boolean := False;
      Alt   : Boolean := False) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Key,
         Modifiers => (Ctrl => Ctrl, Shift => Shift, Alt => Alt, Meta => False));
   end Chord;

   procedure Test_Command_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      D     : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Find_Show);
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_Show) = "edit.find.show",
         "find show must have a stable edit.find.show name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Active_Find_Next) = "edit.find.next",
         "find next must have a stable edit.find.next name");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.find.previous", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Active_Find_Previous,
         "stable edit.find.previous name must resolve to the active find command");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_First) = "edit.find.first"
         and then Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_Last) = "edit.find.last"
         and then Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_Reveal_Current) = "edit.find.reveal-current",
         "Phase 361 find first/last/reveal-current commands must have stable persisted names");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.find.first", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_First,
         "stable edit.find.first name must resolve");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.find.last", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_Last,
         "stable edit.find.last name must resolve");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.find.reveal-current", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_Reveal_Current,
         "stable edit.find.reveal-current name must resolve");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Find_First).Bindable
         and then Editor.Commands.Descriptor (Editor.Commands.Command_Find_Last).Bindable
         and then Editor.Commands.Descriptor (Editor.Commands.Command_Find_Reveal_Current).Bindable
         and then Editor.Commands.Is_Search_Command (Editor.Commands.Command_Find_Reveal_Current)
         and then Editor.Commands.Is_Navigation_Command (Editor.Commands.Command_Find_First)
         and then Editor.Commands.Is_Navigation_Command (Editor.Commands.Command_Find_Last)
         and then not Editor.Commands.Is_Navigation_Command
           (Editor.Commands.Command_Find_Reveal_Current),
         "Phase 361 command descriptors must classify first/last as navigation search commands and reveal-current as non-navigation search state");
      Assert
        (D.Category = Editor.Commands.Search_Category
         and then D.Visibility = Editor.Commands.Palette_Command
         and then D.Bindable,
         "find show must be a bindable visible Search command");
      Assert
        (not Editor.Commands.Descriptor
           (Editor.Commands.Command_Find_Query_Set).Bindable,
         "payload-style find query setter must not be bindable");
      Assert
        (To_String (D.Name) = "Find",
         "visible palette Find must now be the Phase 354 active-buffer Find command");
   end Test_Command_Metadata;

   procedure Test_Query_Set_And_Snapshot_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha alpha" & ASCII.LF & "ALPHA");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Assert
        (S.Active_Find_Prompt,
         "find show must make the prompt visible");
      Assert
        (Natural (S.Active_Find_Matches.Length) = 3,
         "case-insensitive active-buffer find must count all literal occurrences");
      Assert
        (Editor.Project_Search.Query (S.Project_Search) = "",
         "active-buffer find must not mutate the project search query field");
      Assert
        (Active_Message_Text (S) = "Find query set: 3 matches",
         "direct query set must report match count");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Find_Visible, "snapshot must expose visible find prompt state");
      Assert
        (To_String (Snap.Find_Query) = "alpha"
         and then Snap.Find_Match_Count = 3
         and then Snap.Active_Find_Match_Count = 3,
         "snapshot must expose query and structured find match ranges");
      Assert
        (Snap.Active_Find_Matches (1).Start_Row = 0
         and then Snap.Active_Find_Matches (2).Start_Row = 0
         and then Snap.Active_Find_Matches (3).Start_Row = 1,
         "multiple matches on one line and later-line matches must be exposed individually");
      Assert
        (Snap.Total_Find_Match_Count = 3,
         "active Find snapshot total count must use canonical active Find matches");
   end Test_Query_Set_And_Snapshot_Ranges;

   procedure Test_Active_Find_Next_Previous_Navigation_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "start" & ASCII.LF & "needle" & ASCII.LF & "needle");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "needle");
      Editor.Executor.Execute_Find_Next (S);

      Assert
        (S.Active_Find_Match.Start_Row = 2
         and then S.Active_Find_Match.Start_Column = 0,
         "find next must advance from the query-selected nearest match to the next match");
      Assert
        (Natural (S.Carets (S.Carets.First_Index).Pos) = Natural (S.Active_Find_Match.Start_Index),
         "find navigation must collapse the caret at the selected match start");
      Assert
        (Editor.Navigation_History.Has_Back (S.Navigation_History),
         "successful find navigation must record the pre-find location");

      Editor.Executor.Execute_Find_Previous (S);
      Assert
        (S.Active_Find_Match.Start_Row = 1,
         "find previous must move back to the prior match");
   end Test_Active_Find_Next_Previous_Navigation_History;

   procedure Test_Hide_Clears_Transient_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc abc");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "abc");
      Editor.Executor.Execute_Find_Hide (S);
      Assert
        ((not S.Active_Find_Prompt)
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match),
         "find hide must clear prompt query, matches, and selected match");
   end Test_Hide_Clears_Transient_State;


   procedure Test_Prompt_Text_Stays_Out_Of_Project_Search
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Assert
        (To_String (S.Active_Find_Query) = "alpha"
         and then Natural (S.Active_Find_Matches.Length) = 2,
         "active Find prompt typing must update active-buffer Find state");
      Assert
        (Editor.Project_Search.Query (S.Project_Search) = "",
         "active Find prompt typing must not mutate the project search query field");
      Assert
        (not S.File_Info.Dirty,
         "typing in active Find prompt must not dirty the active buffer");
   end Test_Prompt_Text_Stays_Out_Of_Project_Search;




   procedure Test_Active_Find_Prompt_Input_Uses_Canonical_Find
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := ASCII.CR;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.CR));
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Cmd);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (After.Active_Find_Prompt
         and then To_String (After.Active_Find_Query) = "alpha"
         and then Natural (After.Active_Find_Matches.Length) = 2
         and then Editor.Search.Has_Match (After.Active_Find_Match),
         "Enter in the active Find prompt must route through canonical active-buffer Find navigation");
   end Test_Active_Find_Prompt_Input_Uses_Canonical_Find;











   procedure Test_Buffer_Change_Marks_Active_Find_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Editor.State.Rebuild_After_Buffer_Change (S);

      Assert
        (S.Active_Find_Stale
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match),
         "buffer text changes must invalidate active Find matches without clearing the query");
      Assert
        (To_String (S.Active_Find_Query) = "alpha",
         "buffer text changes must preserve the active Find query for recomputation");
   end Test_Buffer_Change_Marks_Active_Find_Stale;


   procedure Test_Buffer_Switch_Preserves_Active_Find_Query
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Original : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Buffers.Ensure_Global_Registry (S);
      Original := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_New_Buffer (S);

      Assert
        (S.Active_Find_Prompt
         and then To_String (S.Active_Find_Query) = "alpha"
         and then Editor.Input_Field.Text (S.Active_Find_Input) = "alpha"
         and then S.Active_Find_Stale
         and then Editor.Project_Search.Query (S.Project_Search) = "",
         "active-buffer Find query must remain visible and stale after switching to a new buffer");

      Editor.Executor.Execute_Switch_Buffer (S, Original);

      Assert
        (S.Active_Find_Prompt
         and then To_String (S.Active_Find_Query) = "alpha"
         and then Editor.Input_Field.Text (S.Active_Find_Input) = "alpha"
         and then S.Active_Find_Stale
         and then S.Active_Find_Matches.Is_Empty,
         "buffer switches must preserve active Find prompt text without recomputing ranges");
   end Test_Buffer_Switch_Preserves_Active_Find_Query;




   procedure Test_Stale_Find_Does_Not_Render_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Editor.State.Rebuild_After_Buffer_Change (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (S.Active_Find_Stale
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0
         and then Snap.Find_Selected_Match_Index = 0,
         "stale active Find matches must not be projected as render ranges or selected ranges");
   end Test_Stale_Find_Does_Not_Render_Ranges;



   procedure Test_Next_Recomputes_Stale_Find_After_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'a';
      Cmd.Text := To_Unbounded_String (String'(1 => 'a'));
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert
        (S.Active_Find_Stale
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match),
         "ordinary buffer edits must clear selected active Find match and mark matches stale");

      Editor.Executor.Execute_Find_Next (S);
      Assert
        ((not S.Active_Find_Stale)
         and then Natural (S.Active_Find_Matches.Length) = 2
         and then Natural (S.Carets (S.Carets.First_Index).Pos) =
                  Natural (S.Active_Find_Match.Start_Index),
         "find next must recompute stale matches against unsaved active-buffer text before moving");
   end Test_Next_Recomputes_Stale_Find_After_Edit;

   procedure Test_No_Active_Buffer_Message_Precedes_Query_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_Find_Next (S);
      Assert
        (Active_Message_Text (S) = "No active buffer.",
         "find next without an active buffer must report No active buffer, not stale query state");
   end Test_No_Active_Buffer_Message_Precedes_Query_State;


   procedure Test_Source_Buffer_Mismatch_Does_Not_Render_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      S.Active_Find_Source_Buffer_Token := S.Active_Buffer_Token + 1;
      S.Active_Find_Stale := False;
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0
         and then Snap.Find_Selected_Match_Index = 0,
         "active Find ranges from a different source buffer must not render");
   end Test_Source_Buffer_Mismatch_Does_Not_Render_Ranges;


   procedure Test_Query_Set_Without_Active_Target_Preserves_Stale_Query
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Assert
        (To_String (S.Active_Find_Query) = "alpha"
         and then S.Active_Find_Stale
         and then S.Active_Find_Source_Buffer_Token = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match),
         "query.set without an active searchable buffer must preserve query as stale, not compute no-match ranges");
      Assert
        (Active_Message_Text (S) = "No active buffer.",
         "query.set without an active searchable buffer must report No active buffer");
   end Test_Query_Set_Without_Active_Target_Preserves_Stale_Query;



   procedure Test_Query_Set_Preserves_Literal_Spaces
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha alpha" & ASCII.LF & " alpha ");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, " alpha ");

      Assert
        (To_String (S.Active_Find_Query) = " alpha "
         and then Natural (S.Active_Find_Matches.Length) = 1,
         "active Find query.set must treat leading and trailing spaces as literal query text");
      Assert
        (S.Active_Find_Match.Start_Row = 1
         and then S.Active_Find_Match.Start_Column = 0,
         "literal-space query must select the exact spaced occurrence, not trimmed alpha matches");
   end Test_Query_Set_Preserves_Literal_Spaces;


   procedure Test_Previous_Ignores_Out_Of_Range_Selected_Ordinal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      S.Active_Find_Match :=
        (Index        => Editor.Search.Search_Match_Index (99),
         Start_Index  => 0,
         End_Index    => 0,
         Start_Row    => 0,
         Start_Column => 0,
         End_Row      => 0,
         End_Column   => 0);

      Editor.Executor.Execute_Find_Previous (S);

      Assert
        (Editor.Search.Has_Match (S.Active_Find_Match)
         and then Natural (S.Active_Find_Match.Index) <= Natural (S.Active_Find_Matches.Length)
         and then Active_Message_Text (S) = "Found previous match 2 of 2",
         "find previous must normalize stale/out-of-range selected ordinals before moving");
   end Test_Previous_Ignores_Out_Of_Range_Selected_Ordinal;

   procedure Test_Render_Uses_Effective_Find_Source_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      --  Single-buffer editor states may use the state's registry token as
      --  the effective active Find source identity.  Snapshot/render code
      --  must compare against the same effective identity used when Find
      --  recomputes matches, not only the raw Active_Buffer_Token field.
      S.Active_Buffer_Token := 0;
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (Snap.Find_Match_Count = 2
         and then Snap.Active_Find_Match_Count = 2
         and then Snap.Find_Selected_Match_Index /= 0,
         "active Find snapshot must use the effective source-buffer token used by recomputation");
   end Test_Render_Uses_Effective_Find_Source_Token;




   procedure Set_Primary_Caret
     (S      : in out Editor.State.State_Type;
      Pos    : Natural;
      Anchor : Natural)
   is
   begin
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => Editor.Cursors.Cursor_Index (Pos),
            Anchor                => Editor.Cursors.Cursor_Index (Anchor),
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
   end Set_Primary_Caret;

   procedure Test_Context_Command_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      D1    : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Find_From_Selection);
      D2    : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Find_From_Active_Word);
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_From_Selection) = "edit.find.from-selection",
         "find from selection must have a stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_From_Active_Word) = "edit.find.from-active-word",
         "find from active word must have a stable command name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.from-selection", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_From_Selection,
         "stable find-from-selection name must resolve");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.from-active-word", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_From_Active_Word,
         "stable find-from-active-word name must resolve");
      Assert
        (D1.Category = Editor.Commands.Search_Category
         and then D1.Visibility = Editor.Commands.Palette_Command
         and then D1.Bindable,
         "find-from-selection must be bindable visible Search command");
      Assert
        (D2.Category = Editor.Commands.Search_Category
         and then D2.Visibility = Editor.Commands.Palette_Command
         and then D2.Bindable,
         "find-from-active-word must be bindable visible Search command");
   end Test_Context_Command_Metadata;

   procedure Test_Find_From_Selection_Sets_Query_Without_Moving
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Set_Primary_Caret (S, Pos => 10, Anchor => 6);

      Editor.Executor.Execute_Find_From_Selection (S);

      Assert
        (S.Active_Find_Prompt
         and then S.Active_Find_Prompt
         and then To_String (S.Active_Find_Query) = "beta"
         and then Natural (S.Active_Find_Matches.Length) = 1,
         "find from selection must show Find, set literal selected query, and recompute matches");
      Assert
        (Natural (S.Carets (S.Carets.First_Index).Pos) = 10,
         "find from selection must not move the caret");
      Assert
        (not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "find from selection must not record navigation history");
      Assert
        (Active_Message_Text (S) = "Find query set: 1 matches",
         "find from selection must emit the query/match result as the primary message");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Find_Visible
         and then To_String (Snap.Find_Query) = "beta"
         and then Snap.Find_Match_Count = 1
         and then Snap.Find_Selected_Match_Index = 1,
         "snapshot must expose context-derived Find query, count, ranges, and selected match");
   end Test_Find_From_Selection_Sets_Query_Without_Moving;

   procedure Test_Find_From_Selection_Trims_Outer_Line_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & Character'Val (10) & "beta");
      Set_Primary_Caret (S, Pos => 6, Anchor => 0);

      Editor.Executor.Execute_Find_From_Selection (S);

      Assert
        (To_String (S.Active_Find_Query) = "alpha"
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then Active_Message_Text (S) = "Find query set: 1 matches",
         "find from selection must trim only outer line terminators before using the literal query");
   end Test_Find_From_Selection_Trims_Outer_Line_Terminator;

   procedure Test_Find_From_Selection_Rejects_Internal_Multiline_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & Character'Val (10) & "beta");
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Set_Primary_Caret (S, Pos => 10, Anchor => 0);

      Editor.Executor.Execute_Find_From_Selection (S);

      Assert
        (To_String (S.Active_Find_Query) = "alpha"
         and then Active_Message_Text (S) = "Selected text is not a single-line find query",
         "find from selection must reject internal multiline selections and preserve prior Find state");
   end Test_Find_From_Selection_Rejects_Internal_Multiline_Text;

   procedure Test_Find_From_Selection_Rejects_Too_Long_Query
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Long : String (1 .. 257) := (others => 'a');
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Long & " tail");
      Editor.Executor.Execute_Find_Set_Query (S, "tail");
      Set_Primary_Caret (S, Pos => 257, Anchor => 0);

      Editor.Executor.Execute_Find_From_Selection (S);

      Assert
        (To_String (S.Active_Find_Query) = "tail"
         and then Active_Message_Text (S) = "Selected text is too long",
         "find from selection must reject queries beyond the bounded context Find length and preserve state");
   end Test_Find_From_Selection_Rejects_Too_Long_Query;

   procedure Test_Find_From_Active_Word_Token_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Foo.Bar A_B2 Foo");
      Set_Primary_Caret (S, Pos => 5, Anchor => 5);

      Editor.Executor.Execute_Find_From_Active_Word (S);

      Assert
        (To_String (S.Active_Find_Query) = "Bar"
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = 5,
         "active-word Find must extract only [A-Za-z0-9_]+ token at the caret and not move");
      Assert
        (not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "active-word Find must not record navigation history");

      Set_Primary_Caret (S, Pos => 8, Anchor => 8);
      Editor.Executor.Execute_Find_From_Active_Word (S);
      Assert
        (To_String (S.Active_Find_Query) = "A_B2",
         "underscore and digits must remain part of the active-word token");
   end Test_Find_From_Active_Word_Token_Policy;

   procedure Test_Find_From_Active_Word_Punctuation_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Foo.Bar");
      Editor.Executor.Execute_Find_Set_Query (S, "Foo");
      Set_Primary_Caret (S, Pos => 3, Anchor => 3);

      Editor.Executor.Execute_Find_From_Active_Word (S);

      Assert
        (To_String (S.Active_Find_Query) = "Foo"
         and then Active_Message_Text (S) = "No searchable text at cursor",
         "active-word Find must not extract punctuation or dotted names as a single token");
   end Test_Find_From_Active_Word_Punctuation_Preserves_State;

   procedure Test_Find_Context_Failures_Preserve_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Set_Primary_Caret (S, Pos => 5, Anchor => 5);
      Editor.Executor.Execute_Find_From_Selection (S);
      Assert
        (To_String (S.Active_Find_Query) = "alpha"
         and then Active_Message_Text (S) = "No selected text",
         "failed find-from-selection must preserve existing Find state");

      Set_Primary_Caret (S, Pos => 5, Anchor => 5);
      Editor.Executor.Execute_Find_From_Active_Word (S);
      Assert
        (To_String (S.Active_Find_Query) = "alpha"
         and then Active_Message_Text (S) = "No searchable text at cursor",
         "failed active-word extraction must preserve existing Find state");
   end Test_Find_Context_Failures_Preserve_State;



   procedure Test_Find_Context_Input_Bridge_Dispatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Set_Primary_Caret (S, Pos => 10, Anchor => 6);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_From_Selection);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (To_String (After.Active_Find_Query) = "beta"
         and then Natural (After.Active_Find_Matches.Length) = 1
         and then Natural (After.Carets (After.Carets.First_Index).Pos) = 10,
         "Input_Bridge command-id dispatch must route find-from-selection through Executor without local mutation");

      Set_Primary_Caret (After, Pos => 0, Anchor => 0);
      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_From_Active_Word);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (To_String (After.Active_Find_Query) = "alpha"
         and then Natural (After.Active_Find_Matches.Length) = 2
         and then Natural (After.Carets (After.Carets.First_Index).Pos) = 0,
         "Input_Bridge command-id dispatch must route find-from-active-word through Executor without moving the caret");
   end Test_Find_Context_Input_Bridge_Dispatch;

   procedure Test_Find_Context_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      A        : Editor.Commands.Command_Availability;
      Message  : Unbounded_String;
      Query    : Unbounded_String;
      Count    : Natural := 0;
      Caret    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Set_Primary_Caret (S, Pos => 5, Anchor => 5);
      Message := To_Unbounded_String (Active_Message_Text (S));
      Query := S.Active_Find_Query;
      Count := Natural (S.Active_Find_Matches.Length);
      Caret := Natural (S.Carets (S.Carets.First_Index).Pos);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_From_Selection);

      Assert
        ((not Editor.Commands.Is_Available (A))
         and then Editor.Commands.Unavailable_Reason (A) = "No selected text"
         and then S.Active_Find_Query = Query
         and then Natural (S.Active_Find_Matches.Length) = Count
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret
         and then Active_Message_Text (S) = To_String (Message),
         "find-from-selection availability must be a side-effect-free no-selection check");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_From_Active_Word);

      Assert
        (Editor.Commands.Is_Available (A)
         and then S.Active_Find_Query = Query
         and then Natural (S.Active_Find_Matches.Length) = Count
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret
         and then Active_Message_Text (S) = To_String (Message),
         "find-from-active-word availability must not extract words, recompute matches, move caret, or emit messages");
   end Test_Find_Context_Availability_Is_Side_Effect_Free;

   procedure Test_Optional_Find_Selection_Next_Not_Exposed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := True;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.find-selection-next", Found);

      Assert
        ((not Found) and then Id = Editor.Commands.No_Command,
         "omitted optional find-selection-next must not expose a descriptor, stable name, binding, palette, or Executor route");
   end Test_Optional_Find_Selection_Next_Not_Exposed;




   procedure Assert_Find_Coherent
     (S       : in out Editor.State.State_Type;
      Context : String)
   is
      Snap       : Editor.Render_Model.Render_Snapshot;
      Renderable : constant Boolean :=
        S.Active_Find_Prompt
        and then Length (S.Active_Find_Query) > 0
        and then not S.Active_Find_Stale
        and then S.Active_Find_Source_Buffer_Token /= 0
        and then S.Active_Find_Source_Buffer_Token =
          (if S.Active_Buffer_Token /= 0 then S.Active_Buffer_Token else S.Registry_Token);
   begin
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Find_Case_Sensitive = S.Active_Find_Case_Sensitive
         and then Snap.Find_Whole_Word = S.Active_Find_Whole_Word,
         Context & ": snapshot Find options must match transient state");

      if Renderable then
         Assert
           (Snap.Find_Match_Count = Natural (S.Active_Find_Matches.Length),
            Context & ": rendered Find count must equal stored active Find matches");
         Assert
           (Snap.Active_Find_Match_Count = Natural (S.Active_Find_Matches.Length),
            Context & ": editor match ranges must project active Find matches");
         if Editor.Search.Has_Match (S.Active_Find_Match) then
            Assert
              (Snap.Find_Selected_Match_Index = Natural (S.Active_Find_Match.Index),
               Context & ": selected render index must match selected Find ordinal");
            Assert
              (Snap.Find_Selected_Match_Index >= 1
               and then Snap.Find_Selected_Match_Index <= Snap.Find_Match_Count,
               Context & ": selected render index must be in range");
         else
            Assert
              (Snap.Find_Selected_Match_Index = 0,
               Context & ": no selected Find match must render no selected index");
         end if;
      else
         Assert
           (Snap.Find_Match_Count = 0
            and then Snap.Active_Find_Match_Count = 0
            and then Snap.Find_Selected_Match_Index = 0,
            Context & ": stale, empty, or foreign active Find state must render no current ranges");
      end if;
   end Assert_Find_Coherent;

   procedure Test_Query_Change_Cleanup_And_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "Execute_Command Input_Bridge Execute_Command" & ASCII.LF &
         "Input_Bridge");
      Editor.Executor.Execute_Find_Show (S);

      Editor.Executor.Execute_Find_Set_Query (S, "Execute_Command");
      Assert
        (Natural (S.Active_Find_Matches.Length) = 2
         and then Editor.Search.Has_Match (S.Active_Find_Match),
         "initial Find query must compute Execute_Command matches and selected match");
      Assert_Find_Coherent (S, "initial query");

      Editor.Executor.Execute_Find_Set_Query (S, "Input_Bridge");
      Assert
        (Natural (S.Active_Find_Matches.Length) = 2
         and then S.Active_Find_Match.Start_Row in 0 .. 1
         and then Active_Message_Text (S) = "Find query set: 2 matches",
         "query change must replace old matches and selected ordinal with new query matches");
      Assert_Find_Coherent (S, "changed query");

      Editor.Executor.Execute_Find_Set_Query (S, "NoSuchToken");
      Assert
        (S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match)
         and then Active_Message_Text (S) = "Find query set: no matches",
         "no-match query must clear the selected match and old ranges");
      Assert_Find_Coherent (S, "no-match query");

      Editor.Executor.Execute_Find_Clear_Query (S);
      Assert
        (Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not S.Active_Find_Stale
         and then not S.Active_Find_Case_Sensitive
         and then not S.Active_Find_Whole_Word
         and then S.Active_Find_Source_Buffer_Token = 0
         and then not Editor.Search.Has_Match (S.Active_Find_Match),
         "query.clear must clear query, matches, selected match, stale flag, and source-buffer identity");
      Assert_Find_Coherent (S, "cleared query");
   end Test_Query_Change_Cleanup_And_Coherence;

   procedure Test_Context_Active_Find_Next_Back_Forward_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "needle" & ASCII.LF &
         "plain" & ASCII.LF &
         "needle" & ASCII.LF &
         "needle");
      Set_Primary_Caret (S, Pos => 0, Anchor => 0);

      Editor.Executor.Execute_Find_From_Active_Word (S);
      Assert
        (To_String (S.Active_Find_Query) = "needle"
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = 0
         and then not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "context-derived Find query must not move the caret or record history");

      Editor.Executor.Execute_Find_Next (S);
      Assert
        (S.Active_Find_Match.Start_Row = 2
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
         "find.next after context query must move to the next match and record one previous location");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert
        (Natural (S.Carets (S.Carets.First_Index).Pos) = 0
         and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
         "navigation.back must return to the pre-find caret location and populate the forward stack");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert
        (S.Active_Find_Match.Start_Row = 2
         and then Natural (S.Carets (S.Carets.First_Index).Pos) =
           Natural (S.Active_Find_Match.Start_Index),
         "navigation.forward must return to the successful find target");
   end Test_Context_Active_Find_Next_Back_Forward_Workflow;

   procedure Test_No_Match_Find_Does_Not_Clear_Forward_Stack
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "alpha" & ASCII.LF &
         "beta" & ASCII.LF &
         "alpha");

      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Case_Clear (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Clear (S);
      Editor.Executor.Execute_Find_Next (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert
        (Editor.Navigation_History.Has_Forward (S.Navigation_History),
         "setup must leave a forward navigation target after back");

      Editor.Executor.Execute_Find_Set_Query (S, "NoSuchToken");
      Editor.Executor.Execute_Find_Next (S);
      Assert
        (Active_Message_Text (S) = "No matches"
         and then Editor.Navigation_History.Has_Forward (S.Navigation_History),
         "failed no-match find.next must not clear the existing forward stack");
   end Test_No_Match_Find_Does_Not_Clear_Forward_Stack;

   procedure Test_Active_Buffer_Change_Recomputes_Only_Current_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Original : Editor.Buffers.Buffer_Id;
      Snap     : Editor.Render_Model.Render_Snapshot;
      Cmd      : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha alpha");
      Editor.Buffers.Ensure_Global_Registry (S);
      Original := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Assert_Find_Coherent (S, "buffer A before switch");

      S.File_Info.Dirty := False;
      Editor.Executor.Execute_New_Buffer (S);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'b';
      Cmd.Text := To_Unbounded_String (String'(1 => 'b'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Stale
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0,
         "switching buffers must not render matches from the previous active buffer");

      Editor.Executor.Execute_Find_Next (S);
      Assert
        (Active_Message_Text (S) = "No matches"
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "find.next in the new buffer must recompute against that buffer only and avoid history on no matches");

      Editor.Executor.Execute_Switch_Buffer (S, Original);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Stale
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0,
         "returning to the original buffer must not resurrect old ranges until recomputed");
   end Test_Active_Buffer_Change_Recomputes_Only_Current_Buffer;

   procedure Test_Find_Prompt_Input_Routing_And_Feature_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc abc");
      Editor.Project_Search.Set_Query (S.Project_Search, "project-query");
      S.Active_Find_Query := To_Unbounded_String ("project-query");
      Editor.Executor.Execute_Find_Show (S);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'a';
      Cmd.Text := To_Unbounded_String (String'(1 => 'a'));
      Editor.Input_Bridge.Handle (Cmd);
      Cmd.Ch := 'b';
      Cmd.Text := To_Unbounded_String (String'(1 => 'b'));
      Editor.Input_Bridge.Handle (Cmd);
      Cmd.Ch := 'c';
      Cmd.Text := To_Unbounded_String (String'(1 => 'c'));
      Editor.Input_Bridge.Handle (Cmd);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (To_String (After.Active_Find_Query) = "abc"
         and then Natural (After.Active_Find_Matches.Length) = 2
         and then Editor.Project_Search.Query (After.Project_Search) = "project-query"
         and then not After.File_Info.Dirty,
         "Find prompt text input must update active Find only and leave Project Search, separate search, and dirty state unchanged");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := ASCII.CR;
      Cmd.Text := To_Unbounded_String (String'(1 => ASCII.CR));
      Editor.Input_Bridge.Handle (Cmd);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.Search.Has_Match (After.Active_Find_Match)
         and then Editor.Navigation_History.Has_Back (After.Navigation_History)
         and then Active_Message_Text (After) = "Found match 2 of 2",
         "Enter in active Find prompt must route find.next through Executor and record history only on movement");
   end Test_Find_Prompt_Input_Routing_And_Feature_Isolation;

   procedure Test_Find_Project_Lifecycle_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Editor.State.Rebuild_After_Buffer_Change (S);

      Editor.State.Reset_Project_Scoped_State (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        ((not S.Active_Find_Prompt)
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match)
         and then not S.Active_Find_Stale
         and then not S.Active_Find_Case_Sensitive
         and then not S.Active_Find_Whole_Word
         and then S.Active_Find_Source_Buffer_Token = 0
         and then (not Snap.Find_Visible)
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0,
         "project lifecycle reset must clear all transient active Find prompt, query, match, options, stale, source, and render state");
   end Test_Find_Project_Lifecycle_Cleanup;

   procedure Test_Find_Command_Surface_Rejects_Non_Goals
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := True;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;

      procedure Check_Absent (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert
           ((not Found) and then Id = Editor.Commands.No_Command,
            Name & " must not be exposed by active-buffer Find consolidation");
      end Check_Absent;
   begin
      Check_Absent ("edit.find.regex");
      Check_Absent ("edit.find.case.smart");
      Check_Absent ("edit.find.regex.toggle");
      Check_Absent ("edit.find.fuzzy.toggle");
      Check_Absent ("edit.find.history");
      Check_Absent ("edit.find.in-project");
   end Test_Find_Command_Surface_Rejects_Non_Goals;


   procedure Test_Dirty_Buffer_Find_Uses_Unsaved_Text_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Original_Text : constant String :=
        "UnsavedToken" & ASCII.LF & "clean" & ASCII.LF & "UnsavedToken";
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Original_Text);
      S.File_Info.Dirty := True;
      Set_Primary_Caret (S, Pos => 2, Anchor => 2);

      Editor.Executor.Execute_Find_From_Active_Word (S);
      Assert
        (To_String (S.Active_Find_Query) = "UnsavedToken"
         and then Natural (S.Active_Find_Matches.Length) = 2
         and then S.File_Info.Dirty
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = 2,
         "find-from-active-word must search dirty in-memory text, preserve dirty state, and not move");

      Editor.Executor.Execute_Find_Next (S);
      Assert
        (S.File_Info.Dirty
         and then S.Active_Find_Match.Start_Row = 2
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
         "find.next in a dirty buffer must only move the caret and record successful navigation");

      Editor.Executor.Execute_Find_Previous (S);
      Assert
        (S.File_Info.Dirty
         and then S.Active_Find_Match.Start_Row = 0,
         "find.previous in a dirty buffer must not save, reload, discard, or clean the buffer");
   end Test_Dirty_Buffer_Find_Uses_Unsaved_Text_Only;

   procedure Test_Render_Snapshot_Is_Find_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Query_Before   : Unbounded_String;
      Message_Before : Unbounded_String;
      Count_Before   : Natural;
      Caret_Before   : Natural;
      Stale_Before   : Boolean;
      Source_Before  : Natural;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Query_Before := S.Active_Find_Query;
      Message_Before := To_Unbounded_String (Active_Message_Text (S));
      Count_Before := Natural (S.Active_Find_Matches.Length);
      Caret_Before := Natural (S.Carets (S.Carets.First_Index).Pos);
      Stale_Before := S.Active_Find_Stale;
      Source_Before := S.Active_Find_Source_Buffer_Token;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (S.Active_Find_Query = Query_Before
         and then Natural (S.Active_Find_Matches.Length) = Count_Before
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then S.Active_Find_Stale = Stale_Before
         and then S.Active_Find_Source_Buffer_Token = Source_Before
         and then Active_Message_Text (S) = To_String (Message_Before),
         "render snapshots must project Find state without recomputing, repairing, moving, or messaging");
      Assert_Find_Coherent (S, "read-only render snapshot");
   end Test_Render_Snapshot_Is_Find_Read_Only;

   procedure Test_Find_Prompt_Key_Routing_Backspace_Shift_Enter_Escape
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc abc abc");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "abc");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord (Chord (Editor.Keybindings.Key_Backspace));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Length (After.Active_Find_Query) = 2
         and then To_String (After.Active_Find_Query) = "ab"
         and then not After.File_Info.Dirty,
         "Backspace owned by active Find must edit the Find query, not the buffer");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord
        (Chord (Editor.Keybindings.Key_Enter, Shift => True));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.Search.Has_Match (After.Active_Find_Match)
         and then Editor.Navigation_History.Has_Back (After.Navigation_History)
         and then Active_Message_Text (After) = "Found previous match 3 of 3",
         "Shift+Enter owned by active Find must route edit.find.previous through Executor");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord (Chord (Editor.Keybindings.Key_Escape));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        ((not After.Active_Find_Prompt)
         and then Length (After.Active_Find_Query) = 0
         and then After.Active_Find_Matches.Is_Empty
         and then Active_Message_Text (After) = "Find hidden",
         "Escape owned by active Find must route edit.find.hide through Executor and clear prompt state");
   end Test_Find_Prompt_Key_Routing_Backspace_Shift_Enter_Escape;

   procedure Test_Find_Toggle_Lifecycle_Clears_And_Reopens_Empty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc abc");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "abc");

      Editor.Executor.Execute_Find_Toggle (S);
      Assert
        ((not S.Active_Find_Prompt)
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not S.Active_Find_Stale
         and then not S.Active_Find_Case_Sensitive
         and then not S.Active_Find_Whole_Word
         and then S.Active_Find_Source_Buffer_Token = 0
         and then Active_Message_Text (S) = "Find hidden",
         "toggle from visible Find must apply the hide cleanup policy");

      Editor.Executor.Execute_Find_Toggle (S);
      Assert
        (S.Active_Find_Prompt
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then Active_Message_Text (S) = "Find shown",
         "toggle from hidden Find must reopen an empty prompt without resurrecting old query state");
   end Test_Find_Toggle_Lifecycle_Clears_And_Reopens_Empty;

   procedure Test_Find_State_Excluded_From_Workspace_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Next (S);
      Editor.State.Rebuild_After_Buffer_Change (S);

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snapshot));

      Assert
        (Ada.Strings.Fixed.Index (To_String (Summary), "alpha") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "find") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "Find") = 0
         and then Editor.Navigation_History.Has_Back (S.Navigation_History),
         "workspace snapshots must exclude transient Find query/matches/case/whole-word/source/stale/error and non-persistent navigation history");
   end Test_Find_State_Excluded_From_Workspace_Snapshot;

   procedure Test_Find_Leaves_Other_Overlay_Queries_Unchanged
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Go_To_Before   : Unbounded_String;
      Quick_Before   : Unbounded_String;
      Project_Before : Unbounded_String;
      Project_Case_Before : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "12:4");
      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "bad line");
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "quick-query");
      Editor.Project_Search.Set_Query (S.Project_Search, "project-query");
      Editor.Project_Search.Set_Case_Sensitive (S.Project_Search, True);
      Project_Case_Before := Editor.Project_Search.Case_Sensitive (S.Project_Search);
      Go_To_Before := To_Unbounded_String (Editor.Go_To_Line.Text (S.Go_To_Line));
      Quick_Before := To_Unbounded_String (Editor.Quick_Open.Query_Text (S.Quick_Open));
      Project_Before := To_Unbounded_String (Editor.Project_Search.Query (S.Project_Search));

      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Case_Clear (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Clear (S);
      Editor.Executor.Execute_Find_Next (S);
      Editor.Executor.Execute_Find_Previous (S);
      Editor.Executor.Execute_Find_Hide (S);

      Assert
        (To_Unbounded_String (Editor.Go_To_Line.Text (S.Go_To_Line)) = Go_To_Before
         and then Editor.Go_To_Line.Has_Error (S.Go_To_Line)
         and then To_Unbounded_String (Editor.Quick_Open.Query_Text (S.Quick_Open)) = Quick_Before
         and then To_Unbounded_String (Editor.Project_Search.Query (S.Project_Search)) = Project_Before
         and then Editor.Project_Search.Case_Sensitive (S.Project_Search) = Project_Case_Before,
         "active Find commands, including transient Find options, must not mutate Go To Line, Quick Open, or Project Search query state outside overlay ownership policy");
   end Test_Find_Leaves_Other_Overlay_Queries_Unchanged;


   procedure Test_Find_Case_Command_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      D1    : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Find_Case_Toggle);
      D2    : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Find_Case_Clear);
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_Case_Toggle) = "edit.find.case.toggle",
         "find case toggle must have a stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_Case_Clear) = "edit.find.case.clear",
         "find case clear must have a stable command name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.case.toggle", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_Case_Toggle,
         "stable find-case-toggle name must resolve");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.case.clear", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_Case_Clear,
         "stable find-case-clear name must resolve");
      Assert
        (D1.Category = Editor.Commands.Search_Category
         and then D1.Visibility = Editor.Commands.Palette_Command
         and then D1.Bindable,
         "find-case-toggle must be a bindable visible Search command");
      Assert
        (D2.Category = Editor.Commands.Search_Category
         and then D2.Visibility = Editor.Commands.Palette_Command
         and then D2.Bindable,
         "find-case-clear must be a bindable visible Search command");
   end Test_Find_Case_Command_Metadata;


   procedure Test_Find_Case_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      A       : Editor.Commands.Command_Availability;
      Query   : Unbounded_String;
      Count   : Natural := 0;
      Message : Unbounded_String;
      Case_Mode : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha alpha ALPHA");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Query := S.Active_Find_Query;
      Count := Natural (S.Active_Find_Matches.Length);
      Message := To_Unbounded_String (Active_Message_Text (S));
      Case_Mode := S.Active_Find_Case_Sensitive;

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_Case_Toggle);
      Assert
        (Editor.Commands.Is_Available (A)
         and then S.Active_Find_Query = Query
         and then Natural (S.Active_Find_Matches.Length) = Count
         and then S.Active_Find_Case_Sensitive = Case_Mode
         and then Active_Message_Text (S) = To_String (Message),
         "find-case-toggle availability must not mutate case, query, matches, or messages");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_Case_Clear);
      Assert
        (Editor.Commands.Is_Available (A)
         and then S.Active_Find_Query = Query
         and then Natural (S.Active_Find_Matches.Length) = Count
         and then S.Active_Find_Case_Sensitive = Case_Mode
         and then Active_Message_Text (S) = To_String (Message),
         "find-case-clear availability must not recompute or reset transient Find state");
   end Test_Find_Case_Availability_Is_Side_Effect_Free;

   procedure Test_Find_Case_Toggle_Recomputes_And_Renders
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Back_Before    : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "Execute_Command execute_command EXECUTE_COMMAND execute_command");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "execute_command");

      Assert
        ((not S.Active_Find_Case_Sensitive)
         and then Natural (S.Active_Find_Matches.Length) = 4,
         "default active-buffer Find must be case-insensitive");

      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1,
          Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1,
          Column => 0,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Forward));
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then Natural (S.Active_Find_Matches.Length) = 2
         and then Editor.Search.Has_Match (S.Active_Find_Match)
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
         and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before
         and then Active_Message_Text (S) = "Find case: sensitive; 2 matches",
         "case toggle must switch to sensitive matching and recompute current matches");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Find_Case_Sensitive
         and then Snap.Find_Match_Count = 2
         and then Snap.Active_Find_Match_Count = 2
         and then not Snap.Find_Matches_Stale
         and then Snap.Find_Matches_For_Active_Buffer
         and then (Snap.Find_Selected_Match_Index in 1 .. 2),
         "snapshot and rendered ranges must reflect sensitive Find mode");

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Assert
        ((not S.Active_Find_Case_Sensitive)
         and then Natural (S.Active_Find_Matches.Length) = 4
         and then Active_Message_Text (S) = "Find case: insensitive; 4 matches",
         "second case toggle must return to insensitive matching and recompute ranges");
   end Test_Find_Case_Toggle_Recomputes_And_Renders;

   procedure Test_Find_Case_Clear_No_Op_And_Reset
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha alpha ALPHA");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Editor.Executor.Execute_Find_Case_Clear (S);
      Assert
        ((not S.Active_Find_Case_Sensitive)
         and then Active_Message_Text (S) = "Find case already insensitive",
         "case.clear when already insensitive must emit deterministic no-op");

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then Natural (S.Active_Find_Matches.Length) = 1,
         "case toggle setup must leave exact-case-only matches");

      Editor.Executor.Execute_Find_Case_Clear (S);
      Assert
        ((not S.Active_Find_Case_Sensitive)
         and then Natural (S.Active_Find_Matches.Length) = 3
         and then Active_Message_Text (S) = "Find case: insensitive; 3 matches",
         "case.clear must reset to insensitive and recompute current query");
   end Test_Find_Case_Clear_No_Op_And_Reset;

   procedure Test_Find_Case_Preserved_By_Query_Context_And_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Execute_Command execute_command Execute_Command");
      Set_Primary_Caret (S, Pos => 0, Anchor => 0);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);

      Editor.Executor.Execute_Find_From_Active_Word (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then To_String (S.Active_Find_Query) = "Execute_Command"
         and then Natural (S.Active_Find_Matches.Length) = 2,
         "context-derived active-word Find must preserve current case mode");

      Editor.Executor.Execute_Find_Set_Query (S, "execute_command");
      Assert
        (S.Active_Find_Case_Sensitive
         and then Natural (S.Active_Find_Matches.Length) = 1,
         "query.set must use and preserve current case mode");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Stale,
         "buffer edit must mark matches stale without resetting case mode");
      Editor.Executor.Execute_Find_Next (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then Natural (S.Active_Find_Matches.Length) = 1,
         "find.next after edit must recompute stale matches using current case mode");
   end Test_Find_Case_Preserved_By_Query_Context_And_Edit;

   procedure Test_Find_Case_Input_Bridge_And_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_Case_Toggle);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (After.Active_Find_Case_Sensitive
         and then Natural (After.Active_Find_Matches.Length) = 1,
         "Input_Bridge command-id dispatch must route find-case-toggle through Executor");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_Case_Clear);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        ((not After.Active_Find_Case_Sensitive)
         and then Natural (After.Active_Find_Matches.Length) = 2,
         "Input_Bridge command-id dispatch must route find-case-clear through Executor");

      Editor.Executor.Execute_Find_Case_Toggle (After);
      Editor.Executor.Execute_Find_Hide (After);
      Assert
        ((not After.Active_Find_Case_Sensitive)
         and then Length (After.Active_Find_Query) = 0
         and then After.Active_Find_Matches.Is_Empty,
         "find hide lifecycle must reset transient case mode to insensitive");
   end Test_Find_Case_Input_Bridge_And_Lifecycle;


   procedure Test_Find_Whole_Word_Command_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      D1    : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Find_Whole_Word_Toggle);
      D2    : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Find_Whole_Word_Clear);
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_Whole_Word_Toggle) =
             "edit.find.whole-word.toggle",
         "find whole-word toggle must have a stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Find_Whole_Word_Clear) =
             "edit.find.whole-word.clear",
         "find whole-word clear must have a stable command name");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.whole-word.toggle", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_Whole_Word_Toggle,
         "stable find whole-word toggle name must resolve");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.whole-word.clear", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Find_Whole_Word_Clear,
         "stable find whole-word clear name must resolve");
      Assert
        (D1.Category = Editor.Commands.Search_Category
         and then D1.Visibility = Editor.Commands.Palette_Command
         and then D1.Bindable,
         "find whole-word toggle must be a bindable visible Search command");
      Assert
        (D2.Category = Editor.Commands.Search_Category
         and then D2.Visibility = Editor.Commands.Palette_Command
         and then D2.Bindable,
         "find whole-word clear must be a bindable visible Search command");
   end Test_Find_Whole_Word_Command_Metadata;


   procedure Test_Find_Whole_Word_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      A       : Editor.Commands.Command_Availability;
      Query   : Unbounded_String;
      Count   : Natural := 0;
      Message : Unbounded_String;
      Whole   : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run Runner PreRun Run_One Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Query := S.Active_Find_Query;
      Count := Natural (S.Active_Find_Matches.Length);
      Message := To_Unbounded_String (Active_Message_Text (S));
      Whole := S.Active_Find_Whole_Word;

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_Whole_Word_Toggle);
      Assert
        (Editor.Commands.Is_Available (A)
         and then S.Active_Find_Query = Query
         and then Natural (S.Active_Find_Matches.Length) = Count
         and then S.Active_Find_Whole_Word = Whole
         and then Active_Message_Text (S) = To_String (Message),
         "find whole-word toggle availability must not mutate Find state");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_Whole_Word_Clear);
      Assert
        (Editor.Commands.Is_Available (A)
         and then S.Active_Find_Query = Query
         and then Natural (S.Active_Find_Matches.Length) = Count
         and then S.Active_Find_Whole_Word = Whole
         and then Active_Message_Text (S) = To_String (Message),
         "find whole-word clear availability must not recompute or reset state");
   end Test_Find_Whole_Word_Availability_Is_Side_Effect_Free;


   procedure Test_Find_Whole_Word_Boundaries_Recompute_And_Render
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Back_Before    : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "Run Runner PreRun Run_One Run (Run); Foo.Bar run runner");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Assert
        ((not S.Active_Find_Whole_Word)
         and then Natural (S.Active_Find_Matches.Length) = 8,
         "default active-buffer Find must remain substring matching");

      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 1,
          Has_File_Path => False,
          File_Path => Null_Unbounded_String,
          Display_Path => Null_Unbounded_String,
          Line => 1,
          Column => 0,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Forward));
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Assert
        (S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 4
         and then Editor.Search.Has_Match (S.Active_Find_Match)
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
         and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before
         and then Active_Message_Text (S) = "Find whole word: on; 4 matches",
         "whole-word toggle must recompute bounded matches without navigation side effects");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Find_Whole_Word
         and then Snap.Find_Match_Count = 4
         and then Snap.Active_Find_Match_Count = 4
         and then not Snap.Find_Matches_Stale
         and then Snap.Find_Matches_For_Active_Buffer
         and then (Snap.Find_Selected_Match_Index in 1 .. 4),
         "snapshot and rendered ranges must reflect whole-word mode");

      Editor.State.Load_Text (S, "Execute_Command Execute Execute.Command");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Execute");
      Assert
        (S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 2,
         "underscore must be a word character while punctuation remains a boundary");

      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Assert
        ((not S.Active_Find_Whole_Word)
         and then Natural (S.Active_Find_Matches.Length) = 3
         and then Active_Message_Text (S) = "Find whole word: off; 3 matches",
         "second whole-word toggle must restore substring matching");
   end Test_Find_Whole_Word_Boundaries_Recompute_And_Render;


   procedure Test_Find_Whole_Word_Case_Composition_And_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "run Run runner Run_One PreRun run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "run");
      Assert
        (Natural (S.Active_Find_Matches.Length) = 6,
         "case-insensitive substring mode must match embedded different-case occurrences");

      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Assert
        (S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 3,
         "case-insensitive whole-word mode must filter embedded occurrences");

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 2
         and then Active_Message_Text (S) = "Find case: sensitive; 2 matches",
         "case-sensitive whole-word mode must compose with exact-case comparison");

      Editor.Executor.Execute_Find_Whole_Word_Clear (S);
      Assert
        ((not S.Active_Find_Whole_Word)
         and then S.Active_Find_Case_Sensitive
         and then Natural (S.Active_Find_Matches.Length) = 3
         and then Active_Message_Text (S) = "Find whole word: off; 3 matches",
         "whole-word clear must preserve case mode and recompute substring matches");

      Editor.Executor.Execute_Find_Whole_Word_Clear (S);
      Assert
        ((not S.Active_Find_Whole_Word)
         and then Active_Message_Text (S) = "Find whole word already off",
         "whole-word clear when already off must emit deterministic no-op");
   end Test_Find_Whole_Word_Case_Composition_And_Clear;


   procedure Test_Find_Whole_Word_Preserved_By_Query_Context_Edit_And_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command;
      After : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Execute_Command Execute Execute.Command");
      Set_Primary_Caret (S, Pos => 0, Anchor => 0);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);

      Editor.Executor.Execute_Find_From_Active_Word (S);
      Assert
        (S.Active_Find_Whole_Word
         and then To_String (S.Active_Find_Query) = "Execute_Command"
         and then Natural (S.Active_Find_Matches.Length) = 1,
         "context-derived active word Find must preserve current whole-word option");

      Editor.Executor.Execute_Find_Set_Query (S, "Execute");
      Assert
        (S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 2,
         "query.set must use and preserve current whole-word option");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Active_Find_Whole_Word
         and then S.Active_Find_Stale,
         "buffer edit must mark matches stale without resetting whole-word mode");
      Editor.Executor.Execute_Find_Next (S);
      Assert
        (S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 2,
         "find.next after edit must recompute using current whole-word mode");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_Whole_Word_Clear);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        ((not After.Active_Find_Whole_Word)
         and then Natural (After.Active_Find_Matches.Length) >= 1,
         "Input_Bridge command-id dispatch must route whole-word clear through Executor");

      Editor.Executor.Execute_Find_Whole_Word_Toggle (After);
      Editor.Executor.Execute_Find_Hide (After);
      Assert
        ((not After.Active_Find_Whole_Word)
         and then Length (After.Active_Find_Query) = 0
         and then After.Active_Find_Matches.Is_Empty,
         "find hide lifecycle must reset transient whole-word mode to substring matching");
   end Test_Find_Whole_Word_Preserved_By_Query_Context_Edit_And_Lifecycle;




   procedure Test_Phase360_Default_Options_And_Exact_Composition_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "Run" & ASCII.LF &
         "run" & ASCII.LF &
         "Runner" & ASCII.LF &
         "runner" & ASCII.LF &
         "PreRun" & ASCII.LF &
         "preRun" & ASCII.LF &
         "Run_One" & ASCII.LF &
         "run_one" & ASCII.LF &
         "Run.Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");

      Assert
        ((not S.Active_Find_Case_Sensitive)
         and then (not S.Active_Find_Whole_Word)
         and then Natural (S.Active_Find_Matches.Length) = 10
         and then Active_Message_Text (S) = "Find query set: 10 matches",
         "default Find options must be case-insensitive substring matching");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        ((not Snap.Find_Case_Sensitive)
         and then (not Snap.Find_Whole_Word)
         and then Snap.Find_Match_Count = 10
         and then Snap.Active_Find_Match_Count = 10,
         "snapshot ranges must reflect default option state");

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Case_Sensitive
         and then (not S.Active_Find_Whole_Word)
         and then Natural (S.Active_Find_Matches.Length) = 7
         and then Snap.Find_Case_Sensitive
         and then (not Snap.Find_Whole_Word)
         and then Snap.Find_Match_Count = 7,
         "case-sensitive substring mode must filter only by text comparison");

      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 3
         and then Snap.Find_Case_Sensitive
         and then Snap.Find_Whole_Word
         and then Snap.Find_Match_Count = 3
         and then Snap.Active_Find_Matches (1).Start_Row = 0
         and then Snap.Active_Find_Matches (1).Start_Column = 0
         and then Snap.Active_Find_Matches (2).Start_Row = 8
         and then Snap.Active_Find_Matches (2).Start_Column = 0
         and then Snap.Active_Find_Matches (3).Start_Row = 8
         and then Snap.Active_Find_Matches (3).Start_Column = 4,
         "case-sensitive whole-word mode must keep only bounded exact-case Run ranges");

      Editor.Executor.Execute_Find_Case_Clear (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        ((not S.Active_Find_Case_Sensitive)
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 4
         and then (not Snap.Find_Case_Sensitive)
         and then Snap.Find_Whole_Word
         and then Snap.Find_Match_Count = 4,
         "case-insensitive whole-word mode must add bounded lower-case ranges without changing boundary policy");

      Editor.Executor.Execute_Find_Whole_Word_Clear (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        ((not S.Active_Find_Case_Sensitive)
         and then (not S.Active_Find_Whole_Word)
         and then Natural (S.Active_Find_Matches.Length) = 10
         and then Snap.Find_Match_Count = 10,
         "clearing whole-word after composition must restore substring ranges under current case mode");
      Assert_Find_Coherent (S, "phase 360 composed options");
   end Test_Phase360_Default_Options_And_Exact_Composition_Ranges;

   procedure Test_Phase360_Query_Clear_Preserves_Current_Option_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run run Runner Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 2,
         "setup must leave case-sensitive whole-word Find options active");

      Editor.Executor.Execute_Find_Set_Query (S, "run");
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then Active_Message_Text (S) = "Find query set: 1 matches",
         "query.set must use and preserve the current option combination");

      Editor.Executor.Execute_Find_Clear_Query (S);
      Assert
        (Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match)
         and then not S.Active_Find_Stale
         and then S.Active_Find_Source_Buffer_Token = 0
         and then S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then Active_Message_Text (S) = "Find query cleared",
         "query.clear must clear query-derived state while preserving the explicit transient option policy");
   end Test_Phase360_Query_Clear_Preserves_Current_Option_Policy;

   procedure Test_Phase360_Context_Find_Preserves_Options_And_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Back_Before   : Natural := 0;
      Caret_Before  : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "Execute execute Execute_Command" & ASCII.LF &
         "plain");
      Set_Primary_Caret (S, Pos => 0, Anchor => 0);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Caret_Before := Natural (S.Carets (S.Carets.First_Index).Pos);

      Editor.Executor.Execute_Find_From_Active_Word (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then To_String (S.Active_Find_Query) = "Execute"
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before,
         "find-from-active-word must preserve options, avoid Execute_Command under whole-word, and not navigate");

      Set_Primary_Caret (S, Pos => 15, Anchor => 8);
      Editor.Executor.Execute_Find_From_Selection (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then To_String (S.Active_Find_Query) = "execute"
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before,
         "find-from-selection must preserve active case and whole-word options");

      Set_Primary_Caret (S, Pos => 15, Anchor => 15);
      Editor.Executor.Execute_Find_From_Selection (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then To_String (S.Active_Find_Query) = "execute"
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then Active_Message_Text (S) = "No selected text"
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before,
         "failed context Find must preserve query, options, matches, caret, and navigation history");
   end Test_Phase360_Context_Find_Preserves_Options_And_Failures;

   procedure Test_Phase360_Option_Change_After_Context_Query_Then_Navigate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Back_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "Run run Runner" & ASCII.LF &
         "Run.Run" & ASCII.LF &
         "run");
      Set_Primary_Caret (S, Pos => 0, Anchor => 0);
      Editor.Executor.Execute_Find_From_Active_Word (S);
      Assert
        (To_String (S.Active_Find_Query) = "Run"
         and then Natural (S.Active_Find_Matches.Length) = 6,
         "context-derived query setup must use default substring options");

      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Assert
        (To_String (S.Active_Find_Query) = "Run"
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 5,
         "whole-word toggle after context query must recompute the same query");

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Assert
        (To_String (S.Active_Find_Query) = "Run"
         and then S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 3,
         "case toggle after context query must compose with whole-word for the same query");

      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Editor.Executor.Execute_Find_Next (S);
      Assert
        (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before + 1
         and then S.Active_Find_Match.Start_Row = 1
         and then Active_Message_Text (S) = "Found match 2 of 3",
         "only successful next after option changes must record navigation history");
   end Test_Phase360_Option_Change_After_Context_Query_Then_Navigate;

   procedure Test_Phase360_Buffer_Edit_And_Buffer_Switch_Use_Current_Options
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Original : Editor.Buffers.Buffer_Id;
      Snap     : Editor.Render_Model.Render_Snapshot;
      Cmd      : Editor.Commands.Command;

      procedure Set_Buffer_B_Text
        (B : in out Text_Buffer.Buffer_Type)
      is
      begin
         Text_Buffer.Set_Text (B, "run Run_One Run");
      end Set_Buffer_B_Text;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run run Runner" & ASCII.LF & "Run");
      Editor.Buffers.Ensure_Global_Registry (S);
      Original := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 2,
         "setup must compute exact whole-word Run matches in buffer A");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert
        (S.Active_Find_Stale
         and then S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then S.Active_Find_Matches.Is_Empty,
         "active buffer edits must stale matches without resetting Find options");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0
         and then Snap.Find_Case_Sensitive
         and then Snap.Find_Whole_Word,
         "stale edited matches must not render, but option feedback remains current");

      Editor.Executor.Execute_New_Buffer (S);
      Editor.State.Mutate_Buffer (S, Set_Buffer_B_Text'Access);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0
         and then S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word,
         "switching buffers must not render buffer-A option-derived ranges");

      Editor.Executor.Execute_Find_Next (S);
      Assert
        ((not S.Active_Find_Stale)
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then S.Active_Find_Match.Start_Row = 0
         and then S.Active_Find_Match.Start_Column = 12,
         "find.next in buffer B must recompute using current case-sensitive whole-word options");

      Editor.Executor.Execute_Switch_Buffer (S, Original);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Stale
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0,
         "returning to buffer A must not resurrect old rendered ranges without recomputation");
   end Test_Phase360_Buffer_Edit_And_Buffer_Switch_Use_Current_Options;

   procedure Test_Phase360_Input_Routes_Option_Commands_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      After         : Editor.State.State_Type;
      Caret_Before  : Natural := 0;
      Back_Before   : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha alpha Run Runner Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Caret_Before := Natural (S.Carets (S.Carets.First_Index).Pos);
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_Case_Toggle);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (After.Active_Find_Case_Sensitive
         and then Natural (After.Carets (After.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (After.Navigation_History) = Back_Before,
         "Input_Bridge must route case toggle through Executor without local caret/history mutation");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_Whole_Word_Toggle);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (After.Active_Find_Whole_Word
         and then Natural (After.Active_Find_Matches.Length) = 2
         and then Natural (After.Carets (After.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (After.Navigation_History) = Back_Before,
         "Input_Bridge must route whole-word toggle through Executor and recompute with current query");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_Case_Clear);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_Whole_Word_Clear);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        ((not After.Active_Find_Case_Sensitive)
         and then (not After.Active_Find_Whole_Word)
         and then Natural (After.Active_Find_Matches.Length) = 3
         and then Editor.Navigation_History.Back_Count (After.Navigation_History) = Back_Before,
         "Input_Bridge clear commands must also route through Executor and avoid navigation side effects");
   end Test_Phase360_Input_Routes_Option_Commands_Through_Executor;

   procedure Test_Phase360_Option_Commands_Preserve_Stale_Query_Without_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Assert
        (S.Active_Find_Stale
         and then S.Active_Find_Source_Buffer_Token = 0
         and then S.Active_Find_Matches.Is_Empty
         and then Active_Message_Text (S) = "No active buffer.",
         "setup must preserve a stale non-empty Find query when no active buffer is searchable");

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then S.Active_Find_Stale
         and then S.Active_Find_Source_Buffer_Token = 0
         and then S.Active_Find_Matches.Is_Empty
         and then Active_Message_Text (S) = "Find case: sensitive",
         "case toggle without a searchable buffer must preserve stale query state without fabricating no-match ranges");

      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Assert
        (S.Active_Find_Whole_Word
         and then S.Active_Find_Stale
         and then S.Active_Find_Source_Buffer_Token = 0
         and then S.Active_Find_Matches.Is_Empty
         and then Active_Message_Text (S) = "Find whole word: on",
         "whole-word toggle without a searchable buffer must preserve stale query state under current options");
   end Test_Phase360_Option_Commands_Preserve_Stale_Query_Without_Buffer;

   procedure Test_Phase360_Option_Commands_Do_Not_Record_History_Or_Move_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Caret_Before : Natural := 0;
      Back_Before  : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run Run");
      Set_Primary_Caret (S, Pos => 0, Anchor => 0);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Caret_Before := Natural (S.Carets (S.Carets.First_Index).Pos);
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Assert
        (S.Active_Find_Case_Sensitive
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
         and then Active_Message_Text (S) = "Find case: sensitive; 2 matches",
         "case toggle must recompute and message once without caret movement or navigation history");

      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Assert
        (S.Active_Find_Whole_Word
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
         and then Active_Message_Text (S) = "Find whole word: on; 2 matches",
         "whole-word toggle must recompute and message once without caret movement or navigation history");

      Editor.Executor.Execute_Find_Case_Clear (S);
      Assert
        ((not S.Active_Find_Case_Sensitive)
         and then S.Active_Find_Whole_Word
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
         and then Active_Message_Text (S) = "Find case: insensitive; 2 matches",
         "case.clear must reset only case mode and preserve whole-word without history");

      Editor.Executor.Execute_Find_Whole_Word_Clear (S);
      Assert
        ((not S.Active_Find_Whole_Word)
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
         and then Active_Message_Text (S) = "Find whole word: off; 2 matches",
         "whole-word.clear must reset only whole-word mode without history");
   end Test_Phase360_Option_Commands_Do_Not_Record_History_Or_Move_Caret;

   procedure Test_Phase360_Dirty_Buffer_Options_Use_Unsaved_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Caret_Before : Natural := 0;
      Back_Before  : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run run Runner");
      S.File_Info.Dirty := True;
      Set_Primary_Caret (S, Pos => 0, Anchor => 0);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Caret_Before := Natural (S.Carets (S.Carets.First_Index).Pos);
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);

      Assert
        (S.File_Info.Dirty
         and then S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then Active_Message_Text (S) = "Find query set: 1 matches",
         "case-sensitive whole-word Find must search the dirty in-memory buffer only");

      Editor.Executor.Execute_Find_Case_Clear (S);
      Assert
        (S.File_Info.Dirty
         and then (not S.Active_Find_Case_Sensitive)
         and then S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 2
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before,
         "case clear in dirty buffer must recompute against unsaved text without saving or navigating");

      Editor.Executor.Execute_Find_Whole_Word_Clear (S);
      Assert
        (S.File_Info.Dirty
         and then (not S.Active_Find_Whole_Word)
         and then Natural (S.Active_Find_Matches.Length) = 3
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before,
         "whole-word clear in dirty buffer must include embedded unsaved occurrences without dirty-state changes");
   end Test_Phase360_Dirty_Buffer_Options_Use_Unsaved_Text;

   procedure Test_Phase360_Hide_Show_Resets_All_Find_Option_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run run Runner Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");

      Editor.Executor.Execute_Find_Hide (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        ((not S.Active_Find_Prompt)
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match)
         and then not S.Active_Find_Stale
         and then not S.Active_Find_Case_Sensitive
         and then not S.Active_Find_Whole_Word
         and then S.Active_Find_Source_Buffer_Token = 0
         and then (not Snap.Find_Visible)
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0
         and then Active_Message_Text (S) = "Find hidden",
         "find.hide must reset query, matches, source, stale flag, selected match, and both Find options");

      Editor.Executor.Execute_Find_Show (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Prompt
         and then Length (S.Active_Find_Query) = 0
         and then not S.Active_Find_Case_Sensitive
         and then not S.Active_Find_Whole_Word
         and then Snap.Find_Visible
         and then (not Snap.Find_Case_Sensitive)
         and then (not Snap.Find_Whole_Word)
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0
         and then Active_Message_Text (S) = "Find shown",
         "find.show after hide must start with empty query and default transient option state");
   end Test_Phase360_Hide_Show_Resets_All_Find_Option_State;

   procedure Test_Phase360_Stale_Snapshot_Preserves_Option_Feedback_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Cmd            : Editor.Commands.Command;
      Query_Before   : Unbounded_String;
      Message_Before : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Query_Before := S.Active_Find_Query;
      Message_Before := To_Unbounded_String (Active_Message_Text (S));

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Query = Query_Before
         and then S.Active_Find_Case_Sensitive
         and then S.Active_Find_Whole_Word
         and then S.Active_Find_Stale
         and then Snap.Find_Case_Sensitive
         and then Snap.Find_Whole_Word
         and then Snap.Find_Match_Count = 0
         and then Snap.Find_Selected_Match_Index = 0
         and then Snap.Find_Selected_Match_Ordinal = 0
         and then To_String (Snap.Find_Status_Text) = "Stale"
         and then Snap.Active_Find_Match_Count = 0
         and then Active_Message_Text (S) = To_String (Message_Before),
         "stale Find snapshots must hide stale ranges/ordinals, expose current options, and avoid recompute/mutation/messages");
   end Test_Phase360_Stale_Snapshot_Preserves_Option_Feedback_Read_Only;

   procedure Test_Phase360_Workspace_Snapshot_Excludes_Option_Tokens
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run run Runner Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Next (S);
      Editor.State.Rebuild_After_Buffer_Change (S);

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snapshot));

      Assert
        (Ada.Strings.Fixed.Index (To_String (Summary), "Run") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "find") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "Find") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "case") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "whole") = 0
         and then Editor.Navigation_History.Has_Back (S.Navigation_History),
         "workspace persistence summary must exclude Find query, option names, matches, stale/source state, and navigation history payloads");
   end Test_Phase360_Workspace_Snapshot_Excludes_Option_Tokens;


   procedure Test_Phase361_First_Last_And_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "alpha" & ASCII.LF &
         "plain" & ASCII.LF &
         "alpha" & ASCII.LF &
         "tail alpha");
      Set_Primary_Caret (S, Pos => 8, Anchor => 8);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");

      Editor.Executor.Execute_Find_Last (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Match.Start_Row = 3
         and then Natural (S.Active_Find_Match.Index) = 3
         and then Natural (S.Carets (S.Carets.First_Index).Pos) =
           Natural (S.Active_Find_Match.Start_Index)
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 1
         and then Snap.Find_Match_Count = 3
         and then Snap.Find_Selected_Match_Index = 3
         and then Snap.Find_Selected_Match_Ordinal = 3
         and then To_String (Snap.Find_Status_Text) = "3/3"
         and then Active_Message_Text (S) = "Found last match 3 of 3",
         "find.last must select/move to the final current match, expose 3/3 status, and record one history entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert
        (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
         "navigation.back after find.last must populate forward history");

      Editor.Executor.Execute_Find_First (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Match.Start_Row = 0
         and then Natural (S.Active_Find_Match.Index) = 1
         and then Snap.Find_Selected_Match_Ordinal = 1
         and then To_String (Snap.Find_Status_Text) = "1/3"
         and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0
         and then Active_Message_Text (S) = "Found first match 1 of 3",
         "find.first after back must select first match, expose 1/3 status, and clear forward stack only through successful navigation");
   end Test_Phase361_First_Last_And_Status;

   procedure Test_Phase361_Reveal_Current_Selects_Without_Moving_Or_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Caret_Before  : Natural := 0;
      Back_Before   : Natural := 0;
      Forward_Before : Natural := 0;
      Snap          : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "alpha" & ASCII.LF &
         "plain" & ASCII.LF &
         "alpha" & ASCII.LF &
         "omega");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "alpha");
      Set_Primary_Caret (S, Pos => 8, Anchor => 8);
      Editor.Executor.Execute_Find_Last (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Set_Primary_Caret (S, Pos => 8, Anchor => 8);
      Caret_Before := Natural (S.Carets (S.Carets.First_Index).Pos);
      Editor.Executor.Execute_Find_Reveal_Current (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Match.Start_Row = 2
         and then Natural (S.Active_Find_Match.Index) = 2
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
         and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before
         and then Snap.Find_Selected_Match_Ordinal = 2
         and then To_String (Snap.Find_Status_Text) = "2/2"
         and then Active_Message_Text (S) = "Selected find match 2 of 2",
         "reveal-current must select first match at/after caret, not move caret, and preserve both history stacks");

      Set_Primary_Caret (S, Pos => 18, Anchor => 18);
      Editor.Executor.Execute_Find_Reveal_Current (S);
      Assert
        (Natural (S.Active_Find_Match.Index) = 1
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = 18,
         "reveal-current must wrap to first match when no later match exists and still not move caret");
   end Test_Phase361_Reveal_Current_Selects_Without_Moving_Or_History;

   procedure Test_Phase361_Reveal_Current_Containing_And_Stale_Recompute
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;

      procedure Replace_With_Three_Abc
        (B : in out Text_Buffer.Buffer_Type)
      is
      begin
         Text_Buffer.Set_Text
           (B, "abc" & ASCII.LF & "abc" & ASCII.LF & "abc");
      end Replace_With_Three_Abc;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc abc" & ASCII.LF & "abc");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "abc");
      Set_Primary_Caret (S, Pos => 1, Anchor => 1);
      Editor.Executor.Execute_Find_Reveal_Current (S);
      Assert
        (Natural (S.Active_Find_Match.Index) = 1
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = 1,
         "reveal-current must prefer the match containing the caret");

      Editor.State.Mutate_Buffer (S, Replace_With_Three_Abc'Access);
      Assert (S.Active_Find_Stale, "buffer edit must make active find stale before Phase 361 action");
      Set_Primary_Caret (S, Pos => 5, Anchor => 5);
      Editor.Executor.Execute_Find_Reveal_Current (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        ((not S.Active_Find_Stale)
         and then Natural (S.Active_Find_Matches.Length) = 3
         and then Natural (S.Active_Find_Match.Index) = 2
         and then Snap.Find_Match_Count = 3
         and then Snap.Find_Selected_Match_Ordinal = 2
         and then To_String (Snap.Find_Status_Text) = "2/3",
         "reveal-current must recompute stale matches under the current query/options before selecting current caret match");
   end Test_Phase361_Reveal_Current_Containing_And_Stale_Recompute;

   procedure Test_Phase361_No_Query_No_Matches_And_Availability_Are_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      A       : Editor.Commands.Command_Availability;
      Caret   : Natural := 0;
      Query   : Unbounded_String;
      Count   : Natural := 0;
      Message : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta");
      Editor.Executor.Execute_Find_Show (S);
      Caret := Natural (S.Carets (S.Carets.First_Index).Pos);
      Editor.Executor.Execute_Find_First (S);
      Assert
        (Natural (S.Carets (S.Carets.First_Index).Pos) = Caret
         and then Active_Message_Text (S) = "No find query"
         and then not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "find.first with no query must not move or record history");

      Editor.Executor.Execute_Find_Set_Query (S, "missing");
      Query := S.Active_Find_Query;
      Count := Natural (S.Active_Find_Matches.Length);
      Message := To_Unbounded_String (Active_Message_Text (S));
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Find_Last);
      Assert
        (Editor.Commands.Is_Available (A)
         and then S.Active_Find_Query = Query
         and then Natural (S.Active_Find_Matches.Length) = Count
         and then Active_Message_Text (S) = To_String (Message),
         "find.last availability must not recompute matches or mutate messages");

      Editor.Executor.Execute_Find_Last (S);
      Assert
        (Natural (S.Carets (S.Carets.First_Index).Pos) = Caret
         and then Active_Message_Text (S) = "No matches"
         and then not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "find.last with no matches must not move or record history");
   end Test_Phase361_No_Query_No_Matches_And_Availability_Are_Read_Only;


   procedure Test_Phase361_Options_Input_Routes_And_Lifecycle_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      After    : Editor.State.State_Type;
      Snap     : Editor.Render_Model.Render_Snapshot;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Unbounded_String;
      Reveal_Message : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run run Runner Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Find_Last);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Editor.Render_Model.Build_Render_Snapshot (After, Snap);
      Assert
        (Natural (After.Active_Find_Matches.Length) = 2
         and then Natural (After.Active_Find_Match.Index) = 2
         and then Snap.Find_Case_Sensitive
         and then Snap.Find_Whole_Word
         and then Snap.Find_Selected_Match_Ordinal = 2
         and then To_String (Snap.Find_Status_Text) = "2/2"
         and then Active_Message_Text (After) = "Found last match 2 of 2",
         "Input_Bridge find.last must route through Executor and use current case plus whole-word options");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Find_First);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Natural (After.Active_Find_Match.Index) = 1
         and then Active_Message_Text (After) = "Found first match 1 of 2",
         "Input_Bridge find.first must route through Executor and select the first option-derived match");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Find_Reveal_Current);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Reveal_Message := To_Unbounded_String (Active_Message_Text (After));
      Assert
        (Natural (After.Active_Find_Matches.Length) = 2
         and then Length (Reveal_Message) > 0,
         "Input_Bridge reveal-current must route through Executor without local direct match mutation");

      Snapshot := Editor.State.Build_Workspace_Snapshot (After);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snapshot));
      Assert
        (Ada.Strings.Fixed.Index (To_String (Summary), "Run") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "find") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "Find") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "2/2") = 0,
         "workspace snapshot must not persist Phase 361 current-match query/status feedback");

      Editor.State.Reset_Project_Scoped_State (After);
      Editor.Render_Model.Build_Render_Snapshot (After, Snap);
      Assert
        ((not Snap.Find_Visible)
         and then Snap.Find_Selected_Match_Index = 0
         and then Snap.Find_Selected_Match_Ordinal = 0
         and then Length (Snap.Find_Status_Text) = 0
         and then Length (Snap.Find_Error_Message) = 0
         and then (not After.Active_Find_Case_Sensitive)
         and then (not After.Active_Find_Whole_Word),
         "project lifecycle reset must clear Phase 361 current-match ordinal/status feedback and transient options");
   end Test_Phase361_Options_Input_Routes_And_Lifecycle_Status;



   procedure Test_Phase362_No_Duplicate_Prefill_Aliases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := True;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.prefill-selection", Found);
      Assert
        ((not Found) and then Id = Editor.Commands.No_Command,
         "Phase 362 must not expose duplicate selection-prefill aliases when find-from-selection is canonical");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("edit.find.prefill-active-word", Found);
      Assert
        ((not Found) and then Id = Editor.Commands.No_Command,
         "Phase 362 must not expose duplicate active-word-prefill aliases when find-from-active-word is canonical");
   end Test_Phase362_No_Duplicate_Prefill_Aliases;

   procedure Test_Phase362_Show_Prefills_Selection_Without_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Snap        : Editor.Render_Model.Render_Snapshot;
      Caret_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta beta");
      Set_Primary_Caret (S, Pos => 10, Anchor => 6);
      Caret_Before := Natural (S.Carets (S.Carets.First_Index).Pos);

      Editor.Executor.Execute_Find_Show (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (S.Active_Find_Prompt
         and then S.Active_Find_Prompt
         and then To_String (S.Active_Find_Query) = "beta"
         and then Natural (S.Active_Find_Matches.Length) = 2
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret_Before
         and then not Editor.Navigation_History.Has_Back (S.Navigation_History)
         and then Active_Message_Text (S) = "Find query set: 2 matches",
         "find.show from hidden must prefill a valid single-line selection, recompute, emit one useful message, and not navigate");
      Assert
        (Snap.Find_Visible
         and then To_String (Snap.Find_Query) = "beta"
         and then Snap.Find_Match_Count = 2
         and then Snap.Find_Selected_Match_Ordinal > 0,
         "find.show selection prefill must expose structured prompt query/count/current ordinal");
   end Test_Phase362_Show_Prefills_Selection_Without_Navigation;

   procedure Test_Phase362_Show_Ignores_Invalid_Selection_Quietly
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      Set_Primary_Caret (S, Pos => 10, Anchor => 0);

      Editor.Executor.Execute_Find_Show (S);

      Assert
        (S.Active_Find_Prompt
         and then S.Active_Find_Prompt
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then Active_Message_Text (S) = "Find shown",
         "find.show must ignore invalid or multiline selections without noisy explicit-prefill failure state");
   end Test_Phase362_Show_Ignores_Invalid_Selection_Quietly;

   procedure Test_Phase362_Prompt_Edits_Clear_Stale_Failure_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta alpha");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "missing");
      Editor.Executor.Execute_Find_Next (S);
      Assert (Active_Message_Text (S) = "No matches", "test setup must create stale prompt failure feedback");

      Editor.Input_Field.Select_All (S.Active_Find_Input);
      Editor.Executor.Execute_Active_Find_Input_Insert_Text (S, "alpha");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        (To_String (S.Active_Find_Query) = "alpha"
         and then Natural (S.Active_Find_Matches.Length) = 2
         and then Active_Message_Text (S) = "Find query set: 2 matches"
         and then To_String (Snap.Find_Status_Text) = "1/2"
         and then Length (Snap.Find_Error_Message) = 0,
         "prompt typing must recompute immediately and replace stale failure feedback with current structured status");
   end Test_Phase362_Prompt_Edits_Clear_Stale_Failure_Message;

   procedure Test_Phase362_Hide_Resets_Query_Options_And_Ranges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run run Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");

      Editor.Executor.Execute_Find_Hide (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert
        ((not S.Active_Find_Prompt)
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match)
         and then not S.Active_Find_Stale
         and then S.Active_Find_Source_Buffer_Token = 0
         and then not S.Active_Find_Case_Sensitive
         and then not S.Active_Find_Whole_Word
         and then not Snap.Find_Visible
         and then Snap.Active_Find_Match_Count = 0
         and then Active_Message_Text (S) = "Find hidden",
         "find.hide must clear all transient prompt/query/range/status state and reset transient Find options");
   end Test_Phase362_Hide_Resets_Query_Options_And_Ranges;



   procedure Test_Phase363_End_To_End_Prompt_Option_Render_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "Execute_Command" & ASCII.LF &
         "Execute_Command_Extended" & ASCII.LF &
         "execute_command" & ASCII.LF &
         "Execute_Command");
      Set_Primary_Caret (S, Pos => 15, Anchor => 0);

      Editor.Executor.Execute_Find_Show (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Prompt
         and then To_String (S.Active_Find_Query) = "Execute_Command"
         and then Natural (S.Active_Find_Matches.Length) = 4
         and then Snap.Find_Match_Count = 4
         and then Snap.Find_Selected_Match_Ordinal in 1 .. 4
         and then not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "phase 363 show must prefill selection, recompute current ranges, select a valid ordinal, and avoid history");
      Assert_Find_Coherent (S, "phase 363 show prefill");

      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Case_Sensitive
         and then Natural (S.Active_Find_Matches.Length) = 3
         and then Snap.Find_Match_Count = 3
         and then Snap.Find_Case_Sensitive
         and then not Snap.Find_Whole_Word,
         "case toggle must replace prefill-derived ranges with current case-sensitive ranges");
      Assert_Find_Coherent (S, "phase 363 case-sensitive prefill query");

      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Whole_Word
         and then Natural (S.Active_Find_Matches.Length) = 2
         and then Snap.Find_Match_Count = 2
         and then Snap.Find_Selected_Match_Ordinal in 1 .. 2,
         "whole-word toggle must remove embedded ranges and keep the selected ordinal valid");
      Assert_Find_Coherent (S, "phase 363 whole-word composition");

      Editor.Executor.Execute_Find_Set_Query (S, "missing");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match)
         and then Snap.Find_Match_Count = 0
         and then Snap.Find_Selected_Match_Ordinal = 0
         and then To_String (Snap.Find_Status_Text) = "No matches",
         "query edit to no-match must clear old option-derived ranges and stale selected status");
      Assert_Find_Coherent (S, "phase 363 no-match query edit");

      Editor.Executor.Execute_Find_Hide (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        ((not S.Active_Find_Prompt)
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match)
         and then not S.Active_Find_Case_Sensitive
         and then not S.Active_Find_Whole_Word
         and then not S.Active_Find_Stale
         and then S.Active_Find_Source_Buffer_Token = 0
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0
         and then Snap.Find_Selected_Match_Ordinal = 0,
         "hide must fully clear prompt, query, options, ranges, selected ordinal, stale, and source state");
   end Test_Phase363_End_To_End_Prompt_Option_Render_Coherence;

   procedure Test_Phase363_Navigation_History_Only_For_Movement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "start" & ASCII.LF &
         "Run" & ASCII.LF &
         "middle" & ASCII.LF &
         "Run" & ASCII.LF &
         "end Run");
      Set_Primary_Caret (S, Pos => 0, Anchor => 0);
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Assert
        (not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "show/query/options must not record navigation history");

      Editor.Executor.Execute_Find_Next (S);
      Assert
        (S.Active_Find_Match.Start_Row = 3
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
         "successful find.next movement must record exactly one previous location");
      Editor.Executor.Execute_Find_Last (S);
      Assert
        (S.Active_Find_Match.Start_Row = 4
         and then Editor.Navigation_History.Back_Count (S.Navigation_History) = 2,
         "successful find.last movement must record history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert
        (Editor.Navigation_History.Has_Forward (S.Navigation_History),
         "navigation.back after Find movement must populate forward stack");
      Editor.Executor.Execute_Find_Reveal_Current (S);
      Assert
        (Editor.Navigation_History.Has_Forward (S.Navigation_History)
         and then Active_Message_Text (S) /= "",
         "reveal-current must select coherently without clearing forward history");

      Editor.Executor.Execute_Find_Set_Query (S, "Missing");
      Editor.Executor.Execute_Find_First (S);
      Assert
        (Active_Message_Text (S) = "No matches"
         and then Editor.Navigation_History.Has_Forward (S.Navigation_History),
         "failed find.first must neither record movement nor clear an existing forward stack");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert
        (not Editor.Navigation_History.Has_Forward (S.Navigation_History),
         "preserved forward target must remain usable after a failed Find movement command");
   end Test_Phase363_Navigation_History_Only_For_Movement;

   procedure Test_Phase363_Buffer_Edit_Switch_And_Reveal_Use_Current_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Original : Editor.Buffers.Buffer_Id;
      Snap     : Editor.Render_Model.Render_Snapshot;
      Cmd      : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run" & ASCII.LF & "Runner" & ASCII.LF & "Run");
      Editor.Buffers.Ensure_Global_Registry (S);
      Original := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Assert
        (Natural (S.Active_Find_Matches.Length) = 2,
         "setup must have only whole-word Run matches in buffer A");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'R';
      Cmd.Text := To_Unbounded_String (String'(1 => 'R'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Stale
         and then S.Active_Find_Matches.Is_Empty
         and then not Editor.Search.Has_Match (S.Active_Find_Match)
         and then Snap.Find_Match_Count = 0
         and then Snap.Find_Selected_Match_Ordinal = 0,
         "buffer edits must stale Find, suppress old ranges, and clear selected ordinal before recompute");

      Editor.Executor.Execute_Find_Reveal_Current (S);
      Assert
        ((not S.Active_Find_Stale)
         and then Natural (S.Active_Find_Matches.Length) = 1
         and then Editor.Search.Has_Match (S.Active_Find_Match)
         and then S.File_Info.Dirty,
         "reveal-current must recompute against the current dirty in-memory text without saving or discarding edits");

      S.File_Info.Dirty := False;
      Editor.Executor.Execute_New_Buffer (S);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Stale
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0,
         "active-buffer switch must suppress ranges from the old buffer");
      Editor.Executor.Execute_Find_Next (S);
      Assert
        (Active_Message_Text (S) = "No matches"
         and then not Editor.Navigation_History.Has_Back (S.Navigation_History),
         "Find movement in a different active buffer must recompute there and avoid history on no-match failure");

      Editor.Executor.Execute_Switch_Buffer (S, Original);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Stale
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0,
         "returning to the original buffer must not resurrect stale old-buffer ranges until recomputed");
   end Test_Phase363_Buffer_Edit_Switch_And_Reveal_Use_Current_Text;

   procedure Test_Phase363_Overlay_Input_And_Feature_Independence_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      After   : Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Go_Text : Unbounded_String;
      Quick_Text : Unbounded_String;
      Project_Text : Unbounded_String;
      Project_Case : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc abc");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "7:2");
      Editor.Go_To_Line.Set_Error (S.Go_To_Line, "bad target");
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "quick-query");
      Editor.Project_Search.Set_Query (S.Project_Search, "project-query");
      Editor.Project_Search.Set_Case_Sensitive (S.Project_Search, True);
      Go_Text := To_Unbounded_String (Editor.Go_To_Line.Text (S.Go_To_Line));
      Quick_Text := To_Unbounded_String (Editor.Quick_Open.Query_Text (S.Quick_Open));
      Project_Text := To_Unbounded_String (Editor.Project_Search.Query (S.Project_Search));
      Project_Case := Editor.Project_Search.Case_Sensitive (S.Project_Search);

      Editor.Executor.Execute_Find_Show (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'a';
      Cmd.Text := To_Unbounded_String (String'(1 => 'a'));
      Editor.Input_Bridge.Handle (Cmd);
      Cmd.Ch := 'b';
      Cmd.Text := To_Unbounded_String (String'(1 => 'b'));
      Editor.Input_Bridge.Handle (Cmd);
      Cmd.Ch := 'c';
      Cmd.Text := To_Unbounded_String (String'(1 => 'c'));
      Editor.Input_Bridge.Handle (Cmd);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (To_String (After.Active_Find_Query) = "abc"
         and then Natural (After.Active_Find_Matches.Length) = 2
         and then To_Unbounded_String (Editor.Go_To_Line.Text (After.Go_To_Line)) = Go_Text
         and then Editor.Go_To_Line.Has_Error (After.Go_To_Line)
         and then To_Unbounded_String (Editor.Quick_Open.Query_Text (After.Quick_Open)) = Quick_Text
         and then To_Unbounded_String (Editor.Project_Search.Query (After.Project_Search)) = Project_Text
         and then Editor.Project_Search.Case_Sensitive (After.Project_Search) = Project_Case
         and then not After.File_Info.Dirty,
         "Find-owned printable input must edit only the active Find query and leave other feature state intact");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord (Chord (Editor.Keybindings.Key_Enter));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.Search.Has_Match (After.Active_Find_Match)
         and then Editor.Navigation_History.Has_Back (After.Navigation_History)
         and then To_Unbounded_String (Editor.Project_Search.Query (After.Project_Search)) = Project_Text,
         "Find Enter must route movement through Executor without mutating Project Search state");

      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord (Chord (Editor.Keybindings.Key_Escape));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        ((not After.Active_Find_Prompt)
         and then Length (After.Active_Find_Query) = 0
         and then After.Active_Find_Matches.Is_Empty
         and then To_Unbounded_String (Editor.Quick_Open.Query_Text (After.Quick_Open)) = Quick_Text
         and then Active_Message_Text (After) = "Find hidden",
         "Find Escape must route hide through Executor and leave unrelated overlay query state untouched");
   end Test_Phase363_Overlay_Input_And_Feature_Independence_Matrix;

   procedure Test_Phase363_Availability_Snapshot_And_Lifecycle_Are_Read_Only_Or_Clean
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Snap    : Editor.Render_Model.Render_Snapshot;
      A       : Editor.Commands.Command_Availability;
      Query   : Unbounded_String;
      Count   : Natural := 0;
      Caret   : Natural := 0;
      Message : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Run" & ASCII.LF & "Runner" & ASCII.LF & "Run");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Query := S.Active_Find_Query;
      Count := Natural (S.Active_Find_Matches.Length);
      Caret := Natural (S.Carets (S.Carets.First_Index).Pos);
      Message := To_Unbounded_String (Active_Message_Text (S));

      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Find_Reveal_Current);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (Editor.Commands.Is_Available (A)
         and then S.Active_Find_Query = Query
         and then Natural (S.Active_Find_Matches.Length) = Count
         and then Natural (S.Carets (S.Carets.First_Index).Pos) = Caret
         and then Active_Message_Text (S) = To_String (Message)
         and then Snap.Find_Match_Count = Count,
         "availability and snapshot construction must expose Find state without recompute, movement, messages, or mutation");

      Editor.State.Rebuild_After_Buffer_Change (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        (S.Active_Find_Stale
         and then Snap.Find_Match_Count = 0
         and then Snap.Find_Selected_Match_Ordinal = 0
         and then To_String (Snap.Find_Status_Text) = "Stale",
         "stale snapshots must expose stale status without rendering current ranges or selected ordinals");

      Editor.State.Reset_Project_Scoped_State (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert
        ((not S.Active_Find_Prompt)
         and then Length (S.Active_Find_Query) = 0
         and then S.Active_Find_Matches.Is_Empty
         and then not S.Active_Find_Stale
         and then not S.Active_Find_Case_Sensitive
         and then not S.Active_Find_Whole_Word
         and then S.Active_Find_Source_Buffer_Token = 0
         and then Snap.Find_Match_Count = 0
         and then Snap.Active_Find_Match_Count = 0,
         "project lifecycle cleanup must restore the Find transient defaults and leave no render ranges");
   end Test_Phase363_Availability_Snapshot_And_Lifecycle_Are_Read_Only_Or_Clean;

   procedure Test_Phase363_Persistence_And_Absent_Command_Final_Coverage
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Unbounded_String;
      Found    : Boolean := True;
      Id       : Editor.Commands.Command_Id := Editor.Commands.No_Command;

      procedure Check_Absent (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert
           ((not Found) and then Id = Editor.Commands.No_Command,
            Name & " must remain absent from descriptors, palette, bindings, input routes, and Executor dispatch");
      end Check_Absent;
   begin
      Check_Absent ("edit.find.regex");
      Check_Absent ("edit.find.fuzzy");
      Check_Absent ("edit.find.smart-case.toggle");
      Check_Absent ("edit.find.history");
      Check_Absent ("edit.find.in-project");
      Check_Absent ("edit.find.results.toggle");
      Check_Absent ("edit.find.symbol.toggle");
      Check_Absent ("edit.find.accept");
      Check_Absent ("edit.find.find-selection-next");

      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "PersistToken" & ASCII.LF &
         "PersistToken" & ASCII.LF &
         "PersistToken_Extended");
      Editor.Executor.Execute_Find_Show (S);
      Editor.Executor.Execute_Find_Set_Query (S, "PersistToken");
      Editor.Executor.Execute_Find_Case_Toggle (S);
      Editor.Executor.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Execute_Find_Next (S);
      Editor.State.Rebuild_After_Buffer_Change (S);

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Snapshot));
      Assert
        (Ada.Strings.Fixed.Index (To_String (Summary), "PersistToken") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "find") = 0
         and then Ada.Strings.Fixed.Index (To_String (Summary), "Find") = 0
         and then Editor.Navigation_History.Has_Back (S.Navigation_History),
         "workspace persistence must exclude Find prompt/query/options/matches/selection/source/stale/error and navigation history");
   end Test_Phase363_Persistence_And_Absent_Command_Final_Coverage;



   overriding procedure Register_Tests
     (T : in out Active_Find_Test_Case)
   is
   begin
      Register_Routine (T, Test_Phase363_End_To_End_Prompt_Option_Render_Coherence'Access, "phase 363 end-to-end prompt option render coherence");
      Register_Routine (T, Test_Phase363_Navigation_History_Only_For_Movement'Access, "phase 363 navigation history only for movement");
      Register_Routine (T, Test_Phase363_Buffer_Edit_Switch_And_Reveal_Use_Current_Text'Access, "phase 363 buffer edit switch reveal current text");
      Register_Routine (T, Test_Phase363_Overlay_Input_And_Feature_Independence_Matrix'Access, "phase 363 overlay input and feature independence matrix");
      Register_Routine (T, Test_Phase363_Availability_Snapshot_And_Lifecycle_Are_Read_Only_Or_Clean'Access, "phase 363 availability snapshot lifecycle read-only clean");
      Register_Routine (T, Test_Phase363_Persistence_And_Absent_Command_Final_Coverage'Access, "phase 363 persistence and absent command final coverage");
      Register_Routine (T, Test_Phase362_No_Duplicate_Prefill_Aliases'Access, "phase 362 no duplicate prefill aliases");
      Register_Routine (T, Test_Phase362_Show_Prefills_Selection_Without_Navigation'Access, "phase 362 show prefill selection no navigation");
      Register_Routine (T, Test_Phase362_Show_Ignores_Invalid_Selection_Quietly'Access, "phase 362 show ignores invalid selection quietly");
      Register_Routine (T, Test_Phase362_Prompt_Edits_Clear_Stale_Failure_Message'Access, "phase 362 prompt edits clear stale failure message");
      Register_Routine (T, Test_Phase362_Hide_Resets_Query_Options_And_Ranges'Access, "phase 362 hide resets query options ranges");
      Register_Routine (T, Test_Command_Metadata'Access, "command metadata");
      Register_Routine (T, Test_Find_Case_Command_Metadata'Access, "find case command metadata");
      Register_Routine (T, Test_Find_Case_Availability_Is_Side_Effect_Free'Access, "find case availability side-effect freedom");
      Register_Routine (T, Test_Find_Case_Toggle_Recomputes_And_Renders'Access, "find case toggle recomputes and renders");
      Register_Routine (T, Test_Find_Case_Clear_No_Op_And_Reset'Access, "find case clear no-op and reset");
      Register_Routine (T, Test_Find_Case_Preserved_By_Query_Context_And_Edit'Access, "find case preserved by query context and edit");
      Register_Routine (T, Test_Find_Case_Input_Bridge_And_Lifecycle'Access, "find case input bridge and lifecycle");
      Register_Routine (T, Test_Find_Whole_Word_Command_Metadata'Access, "find whole-word command metadata");
      Register_Routine (T, Test_Find_Whole_Word_Availability_Is_Side_Effect_Free'Access, "find whole-word availability side-effect freedom");
      Register_Routine (T, Test_Find_Whole_Word_Boundaries_Recompute_And_Render'Access, "find whole-word boundaries recompute and render");
      Register_Routine (T, Test_Find_Whole_Word_Case_Composition_And_Clear'Access, "find whole-word case composition and clear");
      Register_Routine (T, Test_Find_Whole_Word_Preserved_By_Query_Context_Edit_And_Lifecycle'Access, "find whole-word preserved by query context edit and lifecycle");
      Register_Routine (T, Test_Phase361_First_Last_And_Status'Access, "phase 361 first last and status feedback");
      Register_Routine (T, Test_Phase361_Reveal_Current_Selects_Without_Moving_Or_History'Access, "phase 361 reveal-current selection without movement or history");
      Register_Routine (T, Test_Phase361_Reveal_Current_Containing_And_Stale_Recompute'Access, "phase 361 reveal-current containing and stale recompute");
      Register_Routine (T, Test_Phase361_No_Query_No_Matches_And_Availability_Are_Read_Only'Access, "phase 361 failures and availability read-only");
      Register_Routine (T, Test_Phase361_Options_Input_Routes_And_Lifecycle_Status'Access, "phase 361 options input routes lifecycle and persistence status");
      Register_Routine (T, Test_Phase360_Default_Options_And_Exact_Composition_Ranges'Access, "phase 360 default options and exact composition ranges");
      Register_Routine (T, Test_Phase360_Query_Clear_Preserves_Current_Option_Policy'Access, "phase 360 query clear preserves option policy");
      Register_Routine (T, Test_Phase360_Context_Find_Preserves_Options_And_Failures'Access, "phase 360 context find preserves options and failures");
      Register_Routine (T, Test_Phase360_Option_Change_After_Context_Query_Then_Navigate'Access, "phase 360 option change after context query then navigate");
      Register_Routine (T, Test_Phase360_Buffer_Edit_And_Buffer_Switch_Use_Current_Options'Access, "phase 360 buffer edit and switch use current options");
      Register_Routine (T, Test_Phase360_Input_Routes_Option_Commands_Through_Executor'Access, "phase 360 input routes option commands through Executor");
      Register_Routine (T, Test_Phase360_Option_Commands_Preserve_Stale_Query_Without_Buffer'Access, "phase 360 option commands preserve stale query without buffer");
      Register_Routine (T, Test_Phase360_Option_Commands_Do_Not_Record_History_Or_Move_Caret'Access, "phase 360 option commands no history or caret movement");
      Register_Routine (T, Test_Phase360_Dirty_Buffer_Options_Use_Unsaved_Text'Access, "phase 360 dirty buffer options use unsaved text");
      Register_Routine (T, Test_Phase360_Hide_Show_Resets_All_Find_Option_State'Access, "phase 360 hide/show resets option state");
      Register_Routine (T, Test_Phase360_Stale_Snapshot_Preserves_Option_Feedback_Read_Only'Access, "phase 360 stale snapshot option feedback read-only");
      Register_Routine (T, Test_Phase360_Workspace_Snapshot_Excludes_Option_Tokens'Access, "phase 360 workspace snapshot excludes option tokens");
      Register_Routine (T, Test_Context_Command_Metadata'Access, "context command metadata");
      Register_Routine (T, Test_Find_Context_Input_Bridge_Dispatch'Access, "find context Input_Bridge dispatch");
      Register_Routine (T, Test_Find_Context_Availability_Is_Side_Effect_Free'Access, "find context availability side-effect freedom");
      Register_Routine (T, Test_Optional_Find_Selection_Next_Not_Exposed'Access, "optional find-selection-next omitted");
      Register_Routine (T, Test_Find_From_Selection_Sets_Query_Without_Moving'Access, "find from selection sets query without moving");
      Register_Routine (T, Test_Find_From_Selection_Trims_Outer_Line_Terminator'Access, "find from selection trims outer line terminator");
      Register_Routine (T, Test_Find_From_Selection_Rejects_Internal_Multiline_Text'Access, "find from selection rejects internal multiline text");
      Register_Routine (T, Test_Find_From_Selection_Rejects_Too_Long_Query'Access, "find from selection rejects too-long query");
      Register_Routine (T, Test_Find_From_Active_Word_Token_Policy'Access, "find from active word token policy");
      Register_Routine (T, Test_Find_From_Active_Word_Punctuation_Preserves_State'Access, "find from active word punctuation preserves state");
      Register_Routine (T, Test_Find_Context_Failures_Preserve_State'Access, "find context failures preserve state");
      Register_Routine (T, Test_Query_Change_Cleanup_And_Coherence'Access, "query change cleanup and coherence");
      Register_Routine (T, Test_Context_Active_Find_Next_Back_Forward_Workflow'Access, "context find next/back/forward workflow");
      Register_Routine (T, Test_No_Match_Find_Does_Not_Clear_Forward_Stack'Access, "no-match find preserves forward stack");
      Register_Routine (T, Test_Active_Buffer_Change_Recomputes_Only_Current_Buffer'Access, "active buffer change recomputes current buffer only");
      Register_Routine (T, Test_Find_Prompt_Input_Routing_And_Feature_Isolation'Access, "find prompt input routing and feature isolation");
      Register_Routine (T, Test_Find_Project_Lifecycle_Cleanup'Access, "find project lifecycle cleanup");
      Register_Routine (T, Test_Find_Command_Surface_Rejects_Non_Goals'Access, "find command surface rejects non-goals");
      Register_Routine (T, Test_Dirty_Buffer_Find_Uses_Unsaved_Text_Only'Access, "dirty buffer find uses unsaved text only");
      Register_Routine (T, Test_Render_Snapshot_Is_Find_Read_Only'Access, "render snapshot is Find read-only");
      Register_Routine (T, Test_Find_Prompt_Key_Routing_Backspace_Shift_Enter_Escape'Access, "find prompt key routing backspace shift-enter escape");
      Register_Routine (T, Test_Find_Toggle_Lifecycle_Clears_And_Reopens_Empty'Access, "find toggle lifecycle clears and reopens empty");
      Register_Routine (T, Test_Find_State_Excluded_From_Workspace_Snapshot'Access, "find state excluded from workspace snapshot");
      Register_Routine (T, Test_Find_Leaves_Other_Overlay_Queries_Unchanged'Access, "find leaves other overlay queries unchanged");
      Register_Routine (T, Test_Query_Set_And_Snapshot_Ranges'Access, "query set and snapshot ranges");
      Register_Routine (T, Test_Active_Find_Next_Previous_Navigation_History'Access, "find navigation history");
      Register_Routine (T, Test_Hide_Clears_Transient_State'Access, "hide clears transient state");
      Register_Routine (T, Test_Prompt_Text_Stays_Out_Of_Project_Search'Access, "prompt text stays out of project search");
      Register_Routine (T, Test_Active_Find_Prompt_Input_Uses_Canonical_Find'Access, "active Find input uses canonical Find");
      Register_Routine (T, Test_Buffer_Change_Marks_Active_Find_Stale'Access, "buffer edit invalidates active Find");
      Register_Routine (T, Test_Buffer_Switch_Preserves_Active_Find_Query'Access, "buffer switch preserves active Find query");
      Register_Routine (T, Test_Stale_Find_Does_Not_Render_Ranges'Access, "stale active Find does not render ranges");
      Register_Routine (T, Test_Next_Recomputes_Stale_Find_After_Edit'Access, "find next recomputes stale matches after edit");
      Register_Routine (T, Test_No_Active_Buffer_Message_Precedes_Query_State'Access, "no active buffer message priority");
      Register_Routine (T, Test_Source_Buffer_Mismatch_Does_Not_Render_Ranges'Access, "source-buffer mismatch suppresses active Find ranges");
      Register_Routine (T, Test_Render_Uses_Effective_Find_Source_Token'Access, "effective source-buffer token keeps active Find renderable");
      Register_Routine (T, Test_Query_Set_Without_Active_Target_Preserves_Stale_Query'Access, "query set without active target preserves stale query");
      Register_Routine (T, Test_Query_Set_Preserves_Literal_Spaces'Access, "query set preserves literal spaces");
      Register_Routine (T, Test_Previous_Ignores_Out_Of_Range_Selected_Ordinal'Access, "previous normalizes stale selected ordinal");
   end Register_Tests;

end Editor.Active_Find.Tests;
