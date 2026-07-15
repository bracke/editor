with Editor.Test_Temp;
with Ada.Characters.Handling;
with Editor.Test_Helper;
with Editor.Pending_Transitions;
with Editor.Buffers;
with Ada.Text_IO;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Outline.Fixtures; use Editor.Outline.Fixtures;
with Editor.Ada_Syntax_Core;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Feature_Panel;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Keybinding_Config;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Outline_Extractor;
with Editor.Outline_Audit;
with Editor.Panel_Focus;
with Editor.State;
with Editor.Render_Model;
with Editor.Workspace_Persistence;

package body Editor.Outline.Navigation_Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.Outline.Outline_Target_Kind;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Outline.Outline_Refresh_Failure_Kind;
   use type Editor.Cursors.Cursor_Index;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Outline.Outline_Freshness;
   use type Editor.Outline_Extractor.Extraction_Status;
   use type Editor.Outline_Extractor.Extraction_Failure_Kind;
   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;
   use type Editor.Feature_Panel.Feature_Panel_Fingerprint;

   function Active_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (Msg);
      end if;
      return "";
   end Active_Message_Text;

   function Name (T : Navigation_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Outline.Navigation.Tests");
   end Name;

   procedure Populate_Synthetic_Outline
     (O : in out Outline_State)
   is
      Result : constant Outline_Refresh_Result := Editor.Outline.Fixtures.Populate_Synthetic_Outline (O);
   begin
      pragma Assert (Result.Status = Outline_Refresh_Ok,
                     "synthetic outline fixture refresh succeeds");
   end Populate_Synthetic_Outline;

   function First_Label_Index
     (O     : Outline_State;
      Label : String) return Natural
   is
   begin
      for I in 1 .. Item_Count (O) loop
         if Item_Label (O, I) = Label then
            return I;
         end if;
      end loop;

      return 0;
   end First_Label_Index;

   function Has_Label
     (O     : Outline_State;
      Label : String) return Boolean
   is
   begin
      return First_Label_Index (O, Label) /= 0;
   end Has_Label;

   procedure Assert_Has_Label
     (O       : Outline_State;
      Label   : String;
      Message : String)
   is
   begin
      Assert (Has_Label (O, Label), Message);
   end Assert_Has_Label;

   function Temp_Path (Name : String) return String is
   begin
      return Editor.Test_Temp.Base & "/editor_outline_" & Name;
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_If_Exists;

   procedure Write_Text
     (Path : String;
      Text : String)
   is
      package Stream_IO renames Ada.Streams.Stream_IO;
      File  : Stream_IO.File_Type;
      Bytes : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
   begin
      for I in Text'Range loop
         Bytes (Ada.Streams.Stream_Element_Offset (I - Text'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Text (I)));
      end loop;

      Stream_IO.Create (File, Stream_IO.Out_File, Path);
      if Text'Length > 0 then
         Stream_IO.Write (File, Bytes);
      end if;
      Stream_IO.Close (File);
   exception
      when others =>
         if Stream_IO.Is_Open (File) then
            Stream_IO.Close (File);
         end if;
         raise;
   end Write_Text;


   function Contains_Lexical_State_Term (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
   begin
      return Ada.Strings.Fixed.Index (Lower, "scanner") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "sanitized") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "token mask") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "lexical state") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "comment map") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "string map") /= 0;
   end Contains_Lexical_State_Term;

   procedure Test_Open_Selected_Navigates_To_Buffer_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "intro" & ASCII.LF & "@outline procedure Demo" & ASCII.LF &
            "procedure Demo is begin null; end Demo;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "refresh setup executes");
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "open selected outline item navigates to its buffer target");
      Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
      Assert (Row = 1 and then Col = 0,
              "open selected moves the primary caret to the captured line/column");
      Assert (Editor.State.Current_Text (S) =
                "intro" & ASCII.LF & "@outline procedure Demo" & ASCII.LF &
                "procedure Demo is begin null; end Demo;",
              "open selected outline does not alter buffer text");
   end Test_Open_Selected_Navigates_To_Buffer_Target;

   procedure Test_Open_Selected_Requires_Live_Outline_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Editor.Outline.Clear (S.Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale feature-panel selection cannot open without outline item");
      Assert (Active_Message_Text (S) = Editor.Outline.Reason_No_Outline_Item_Selected,
              "stale selection emits unavailable selected-item reason");
   end Test_Open_Selected_Requires_Live_Outline_Row;

   procedure Test_Refresh_Replaces_And_Clears_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Outline_First : Natural := 0;
      Panel_First   : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Result        : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "first buffer text must not affect outline");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "refresh executes with active buffer");
      Outline_First := Fingerprint (S.Outline);
      Panel_First := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);

      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "display-only empty outline row is not selectable before replacement refresh");
      Editor.State.Load_Text (S, "different active text still must not affect outline");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "replacement refresh executes");
      Assert (Fingerprint (S.Outline) = Outline_First,
              "refresh twice produces identical outline fingerprint");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel).Row_Labels_Hash =
                Panel_First.Row_Labels_Hash,
              "refresh twice produces identical feature-panel row label fingerprint");
      Assert (Editor.Feature_Panel.Fingerprint (S.Feature_Panel).Row_Details_Hash =
                Panel_First.Row_Details_Hash,
              "refresh twice produces identical feature-panel row detail fingerprint");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "refresh clears feature-panel selection");
      Assert (Editor.Feature_Panel.Is_Visible (S.Feature_Panel),
              "refresh shows the feature panel");
      Assert (not Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "refresh does not focus the feature panel");
   end Test_Refresh_Replaces_And_Clears_Selection;

   procedure Test_Selection_Mapping_Rejects_Stale_Generic_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline procedure Reset_Test" & ASCII.LF & "x");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Editor.Feature_Panel.Fixtures.Set_Placeholder_Rows (S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_First (S.Feature_Panel);

      Assert (not Editor.Outline.Feature_Row_Maps_To_Item
                (S.Outline, S.Feature_Panel,
                 Editor.Feature_Panel.Selected_Row (S.Feature_Panel)),
              "generic feature-panel rows are not current outline projections");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "open selected outline rejects stale or non-outline selected rows");
      Assert (Active_Message_Text (S) = Editor.Outline.Reason_No_Outline_Item_Selected,
              "stale or non-outline row reports selected-item unavailable reason");
   end Test_Selection_Mapping_Rejects_Stale_Generic_Row;

   procedure Test_Refresh_Does_Not_Preserve_Selection_Across_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot_1 : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Snapshot_2 : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot_1 := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 201,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot_1));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot_1), O);
      Select_Item (O, 2);

      Snapshot_2 := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 202,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot_2));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot_2), O);

      Assert (Selected_Index (O) = 0,
              "does not preserve outline selection across buffer tokens");
   end Test_Refresh_Does_Not_Preserve_Selection_Across_Buffers;

   procedure Test_Select_Current_Symbol_Chooses_Preceding_Item
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Result   : Editor.Outline_Extractor.Extraction_Result;
      Index    : Natural;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "" & ASCII.LF &
         "   procedure Second;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 300,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Result := Editor.Outline_Extractor.Extract (Snapshot);
      Editor.Outline_Extractor.Apply_To_Outline (Result, O);

      Index := Find_Nearest_Item_For_Position (O, 300, 3, 1);
      Assert (Index /= 0, "nearest-symbol lookup finds a preceding row");
      Assert (Item_Label (O, Index) = "procedure First",
              "nearest-symbol lookup chooses greatest line at or before cursor");
   end Test_Select_Current_Symbol_Chooses_Preceding_Item;

   procedure Test_Select_Next_Previous_Skip_Non_Selectable_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("@outline section Navigation" & ASCII.LF &
         "@outline procedure First" & ASCII.LF &
         "@outline section More" & ASCII.LF &
         "@outline procedure Second",
         Active_Buffer_Token  => 400,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Select_Next_Selectable (O),
              "select-next finds first selectable row");
      Assert (Selected_Index (O) = 2,
              "select-next skips non-selectable section row");
      Assert (Select_Next_Selectable (O),
              "select-next finds following selectable row");
      Assert (Selected_Index (O) = 4,
              "select-next skips intermediate non-selectable section row");
      Assert (Select_Previous_Selectable (O),
              "select-previous finds previous selectable row");
      Assert (Selected_Index (O) = 2,
              "select-previous skips non-selectable rows");
   end Test_Select_Next_Previous_Skip_Non_Selectable_Rows;

   procedure Test_Current_Symbol_Updates_On_Cursor_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "   procedure Second;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 501,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Update_Current_Symbol_For_Cursor (O, 501, 3, 1);
      Assert (Has_Current_Symbol (O),
              "cursor update records a current outline symbol");
      Assert (Current_Symbol_Label (O) = "procedure Second",
              "current symbol uses the nearest preceding extracted row");
      Assert (Current_Symbol_Line (O) = 3,
              "current symbol records the target source line");
   end Test_Current_Symbol_Updates_On_Cursor_Line;

   procedure Test_Current_Symbol_Clears_Before_First_Item
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("" & ASCII.LF &
         "package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 502,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Update_Current_Symbol_For_Cursor (O, 502, 1, 1);
      Assert (not Has_Current_Symbol (O),
              "cursor before first symbol clears current-symbol state");
      Assert (Current_Symbol_Index (O) = 0,
              "cleared current symbol exposes zero index");
   end Test_Current_Symbol_Clears_Before_First_Item;

   procedure Test_Current_Symbol_Does_Not_Change_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "   procedure Second;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 503,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Select_Item (O, 2);

      Update_Current_Symbol_For_Cursor (O, 503, 3, 1);
      Assert (Selected_Index (O) = 2,
              "cursor current-symbol update does not move outline selection");
      Assert (Current_Symbol_Index (O) = 3,
              "current-symbol index remains independent from selection");
   end Test_Current_Symbol_Does_Not_Change_Selection;

   procedure Test_Current_Symbol_Clears_For_Unsupported_And_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF & "   procedure Run;" & ASCII.LF & "end Demo;",
         Active_Buffer_Token  => 504,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Update_Current_Symbol_For_Cursor (O, 504, 2, 1);
      Assert (Has_Current_Symbol (O), "fixture has current symbol");

      Mark_Unsupported (O);
      Assert (not Has_Current_Symbol (O),
              "unsupported outline state clears current symbol");
      Assert (Outline_Header_Text (O) = "Outline: unavailable",
              "unsupported outline state has compact header text");

      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Update_Current_Symbol_For_Cursor (O, 504, 2, 1);
      Mark_Extraction_Failed (O);
      Assert (not Has_Current_Symbol (O),
              "extraction failure clears current symbol");
      Assert (Outline_Header_Text (O) = "Outline: refresh failed",
              "extraction failure has compact header text");
   end Test_Current_Symbol_Clears_For_Unsupported_And_Failure;

   procedure Test_Header_And_Row_Projection_Mark_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Render : Editor.Feature_Panel.Feature_Panel_Render_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure First;" & ASCII.LF &
         "   procedure Second;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 505,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Update_Current_Symbol_For_Cursor (O, 505, 3, 1);
      Select_Item (O, 2);

      Set_Rows_From_Outline (O, P);
      Assert (Outline_Header_Text (O) = "Outline: procedure Second",
              "header prefers the current symbol label");
      Assert (Editor.Feature_Panel.Header_Text (P) = "Outline: procedure Second",
              "projection exposes compact outline header text");
      Assert (not Editor.Feature_Panel.Row_Is_Current_Symbol (P, 2),
              "selected-only outline row is not marked current");
      Assert (Editor.Feature_Panel.Row_Is_Current_Symbol (P, 3),
              "projection marks the current-symbol row");
      Assert (Editor.Feature_Panel.Selected_Row (P) = 2,
              "projection keeps selected row independent from current symbol");

      Render := Editor.Feature_Panel.Build_Render_Snapshot (P);
      Assert (Editor.Feature_Panel.Snapshot_Row_Selected (Render, 2),
              "selected row remains primary in render snapshot");
      Assert (Editor.Feature_Panel.Snapshot_Row_Is_Current_Symbol (Render, 3),
              "render snapshot carries current-symbol marker");

      Select_Item (O, 3);
      Set_Rows_From_Outline (O, P);
      Assert (Editor.Feature_Panel.Selected_Row (P) = 3,
              "selected current-symbol row keeps selected state primary");
      Assert (Editor.Feature_Panel.Row_Is_Current_Symbol (P, 3),
              "selected current-symbol row keeps passive marker metadata");
   end Test_Header_And_Row_Projection_Mark_Current_Symbol;

   procedure Test_Clear_Removes_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF & "   procedure Run;" & ASCII.LF & "end Demo;",
         Active_Buffer_Token  => 506,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);
      Update_Current_Symbol_For_Cursor (O, 506, 2, 1);
      Clear (O);

      Assert (not Has_Current_Symbol (O),
              "clear removes current-symbol state");
      Assert (Outline_Header_Text (O) = "Outline: not refreshed",
              "clear reports no-symbol header state");
   end Test_Clear_Removes_Current_Symbol;

   procedure Test_Stale_Result_Preserves_Accepted_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Accepted_Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Accepted_Result   : Editor.Outline_Extractor.Extraction_Result;
      Pending_Snapshot  : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Accepted_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 507,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Accepted_Snapshot));
      Accepted_Result := Editor.Outline_Extractor.Extract (Accepted_Snapshot);
      Editor.Outline_Extractor.Apply_To_Outline (Accepted_Result, O);
      Update_Current_Symbol_For_Cursor (O, 507, 2, 1);

      Pending_Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Newer is" & ASCII.LF,
         Active_Buffer_Token  => 507,
         Buffer_Revision      => 2,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Pending_Snapshot));

      Editor.Outline_Extractor.Apply_To_Outline (Accepted_Result, O);
      Assert (Source_Class (O) = Extracted_Outline,
              "stale result preserves accepted outline classification when rows exist");
      Assert (Last_Extraction_Source_Class (O) = Stale_Extracted_Outline,
              "stale result is still recorded in diagnostics");
      Assert (Current_Symbol_Label (O) = "procedure Run",
              "stale result does not clear accepted current-symbol label");
      Assert (Current_Symbol_Index (O) = 2,
              "stale result does not replace current-symbol index from rejected rows");
   end Test_Stale_Result_Preserves_Accepted_Current_Symbol;

   procedure Test_Cursor_Move_Command_Updates_Current_Symbol_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body line" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "cursor movement fixture refreshes outline");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "first cursor move executes");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "second cursor move executes");

      Assert (Current_Symbol_Label (S.Outline) = "procedure Later",
              "cursor movement updates passive current-symbol state");
      Assert (Editor.Feature_Panel.Header_Text (S.Feature_Panel) =
                "Outline: procedure Later",
              "cursor movement refreshes compact outline header projection");
      Assert (Editor.Feature_Panel.Row_Is_Current_Symbol (S.Feature_Panel, 2),
              "cursor movement marks the current-symbol row projection");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "cursor movement does not steal outline selection");
   end Test_Cursor_Move_Command_Updates_Current_Symbol_Projection;

   procedure Test_Reveal_Current_Symbol_Requests_Reveal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body line" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "reveal fixture refreshes extracted outline");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Current_Symbol_Index (S.Outline) = 2,
              "fixture tracks second outline row as current symbol");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "reveal current symbol command executes");
      Assert (Editor.Feature_Panel.Is_Visible (S.Feature_Panel),
              "reveal current symbol shows the outline panel");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) = 2,
              "reveal current symbol requests reveal of the current-symbol row");
      Assert (Selected_Index (S.Outline) = 2,
              "reveal current symbol selects the matching outline row");
      Assert (Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
              and then Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "reveal current symbol mirrors feature-panel selection");
   end Test_Reveal_Current_Symbol_Requests_Reveal;

   procedure Test_Reveal_Current_Symbol_Noops_When_No_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "intro" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "no-current fixture refreshes extracted outline");
      Assert (not Has_Current_Symbol (S.Outline),
              "cursor before first symbol has no current symbol");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "reveal current symbol is unavailable without a current symbol");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) = 0,
              "no-current reveal leaves no reveal request");
      Assert (Active_Message_Text (S) = Editor.Outline.Message_Outline_No_Current_Symbol,
              "no-current reveal emits deterministic feedback");
   end Test_Reveal_Current_Symbol_Noops_When_No_Current_Symbol;

   procedure Test_Select_Current_Symbol_Changes_Selection_And_Reveals
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body line" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "select current symbol executes");
      Assert (Selected_Index (S.Outline) = 2,
              "select current symbol intentionally changes outline selection");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "select current symbol mirrors feature-panel selection");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) = 2,
              "select current symbol also requests reveal of selected row");
   end Test_Select_Current_Symbol_Changes_Selection_And_Reveals;

   procedure Test_Open_Selected_Does_Not_Use_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body line" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body line");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Current_Symbol_Index (S.Outline) = 2,
              "fixture current symbol is row two before open-selected");

      Select_Item (S.Outline, 1);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "open selected executes against selected row");
      Editor.State.Row_Col_For_Index (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 0,
              "open-selected navigates to selected row, not current symbol");
   end Test_Open_Selected_Does_Not_Use_Current_Symbol;

   procedure Test_Outline_Open_Selected_Returns_Focus_To_Editor_On_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "focus-return fixture refreshes outline");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "fixture focuses feature panel");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "open-selected succeeds for a live selected outline target");
      Assert (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
              "successful outline open-selected should return focus to editor text");
      Assert (not Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "successful outline open-selected should clear feature-panel focus");
   end Test_Outline_Open_Selected_Returns_Focus_To_Editor_On_Success;

   procedure Test_Outline_Open_Selected_Does_Not_Return_Focus_On_No_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 0);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "open-selected without a selected target should be unavailable");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "failed open-selected should not steal feature-panel focus");
   end Test_Outline_Open_Selected_Does_Not_Return_Focus_On_No_Target;

   procedure Test_Outline_Open_Selected_Does_Not_Use_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Current_Symbol_Index (S.Outline) = 2,
              "fixture has current symbol on row two");
      Select_Item (S.Outline, 1);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "open-selected should navigate the selected row");
      Editor.State.Row_Col_For_Index (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 0 and then Col = 0,
              "open-selected must not navigate to passive current-symbol row");
   end Test_Outline_Open_Selected_Does_Not_Use_Current_Symbol;

   procedure Test_Outline_Select_Current_Symbol_Preserves_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "select-current-symbol executes");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "select-current-symbol should preserve feature-panel focus");
   end Test_Outline_Select_Current_Symbol_Preserves_Focus;

   procedure Test_Outline_Reveal_Current_Symbol_Does_Not_Move_Editor_Cursor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "reveal-current-symbol executes");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "reveal-current-symbol must not move the editor cursor");
   end Test_Outline_Reveal_Current_Symbol_Does_Not_Move_Editor_Cursor;

   procedure Test_Outline_Select_Next_Requests_Reveal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "select-next reveal fixture executes");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) =
                Editor.Outline.Selected_Index (S.Outline),
              "select-next should request reveal for the new selected row");
   end Test_Outline_Select_Next_Requests_Reveal;

   procedure Test_Outline_Select_Previous_Requests_Reveal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Select_Item (S.Outline, 2);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Select_Previous_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "select-previous reveal fixture executes");
      Assert (Editor.Feature_Panel.Requested_Reveal_Row (S.Feature_Panel) =
                Editor.Outline.Selected_Index (S.Outline),
              "select-previous should request reveal for the new selected row");
   end Test_Outline_Select_Previous_Requests_Reveal;

   procedure Test_Outline_Mouse_Click_Selects_Row_Without_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result := Editor.Executor.Outline_Commands.Execute_Outline_Row_Click (S, 2);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "mouse click should select a live outline row");
      Assert (Editor.Outline.Selected_Index (S.Outline) = 2,
              "mouse click updates outline selection");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 2,
              "mouse click mirrors feature-panel selection");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "mouse click must not navigate the editor cursor");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "mouse click preserves feature-panel focus");
   end Test_Outline_Mouse_Click_Selects_Row_Without_Navigation;

   procedure Test_Outline_Mouse_Double_Click_Opens_Selected_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);

      Result :=
        Editor.Executor.Outline_Commands.Execute_Outline_Row_Activation (S, 2);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "mouse activation should dispatch through open-selected");
      Assert (Editor.Outline.Selected_Index (S.Outline) = 2,
              "mouse activation selects the activated row first");
      Editor.State.Row_Col_For_Index (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 2,
              "mouse activation navigates to the selected row target");
      Assert (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
              "successful mouse activation returns focus to editor text");
      Assert (not Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "successful mouse activation clears feature-panel focus");
   end Test_Outline_Mouse_Double_Click_Opens_Selected_Row;

   procedure Test_Outline_Mouse_Click_Diagnostic_Row_Does_Not_Navigate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Populate_Synthetic_Outline (S.Outline);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Result :=
        Editor.Executor.Outline_Commands.Execute_Outline_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "placeholder/diagnostic row activation should be rejected");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "rejected diagnostic activation must not move the cursor");
      Assert (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
              "rejected diagnostic activation must not return focus to editor text");
   end Test_Outline_Mouse_Click_Diagnostic_Row_Does_Not_Navigate;

   procedure Test_Outline_Mouse_Click_Rejects_Stale_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Gen    : Natural := 0;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "@outline package Demo" & ASCII.LF & "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Focus_Outline);
      Gen := Editor.Feature_Panel.Projection_Generation (S.Feature_Panel);
      Before := S.Carets (S.Carets.First_Index).Pos;
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Clear_Outline);

      Result :=
        Editor.Executor.Outline_Commands.Execute_Outline_Row_Click (S, 1, Gen);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "stale mouse projection should be rejected");
      Assert (not Editor.Feature_Panel.Has_Selection (S.Feature_Panel),
              "stale mouse projection must not recreate selection");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "stale mouse projection must not navigate");
   end Test_Outline_Mouse_Click_Rejects_Stale_Projection;

   procedure Test_Outline_Mouse_Selection_Does_Not_Change_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Current_Before : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline package Demo" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Later" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Current_Before := Editor.Outline.Current_Symbol_Index (S.Outline);
      Assert (Current_Before = 2,
              "fixture has passive current symbol on second row");

      Result := Editor.Executor.Outline_Commands.Execute_Outline_Row_Click (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "mouse selection should execute for row one");
      Assert (Editor.Outline.Selected_Index (S.Outline) = 1,
              "mouse selection changes selection intentionally");
      Assert (Editor.Outline.Current_Symbol_Index (S.Outline) = Current_Before,
              "mouse selection must not overwrite current-symbol state");
   end Test_Outline_Mouse_Selection_Does_Not_Change_Current_Symbol;

   procedure Test_Mouse_And_Reveal_Reject_Old_Panel_Generation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Old_Gen : Natural;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 1),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 1));
   begin
      Replace_Items (O, Items);
      Set_Rows_From_Outline (O, P);
      Old_Gen := Editor.Feature_Panel.Projection_Generation (P);
      Apply_Filter (O, "clear");
      Set_Rows_From_Outline (O, P);

      Assert (Map_Panel_Row_To_Outline_Row (O, P, 1, Old_Gen) = 0,
              "stale mouse mapping generation is rejected");
      Assert (not Validate_Outline_Row_For_Selection (O, P, 1, Old_Gen),
              "stale selection generation is rejected");
      Assert (not Validate_Outline_Row_For_Activation (O, P, 1, 7, Old_Gen),
              "stale reveal/activation generation is rejected");
      Assert (Validate_Outline_Row_For_Activation
                (O, P, 1, 7, Editor.Feature_Panel.Projection_Generation (P)),
              "current projection generation remains activatable");
   end Test_Mouse_And_Reveal_Reject_Old_Panel_Generation;

   procedure Test_Declaration_Navigation_Availability_Rejects_Stale_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Open_Availability : Editor.Commands.Command_Availability;
      Declaration_Availability : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "procedure Demo is" & ASCII.LF &
            "begin" & ASCII.LF &
            "null;" & ASCII.LF &
            "end Demo;");
      Replace_Items
        (S.Outline,
         (1 =>
            (Kind        => Outline_Procedure,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Demo"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 99"),
             Depth       => 0,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 99,
             Column       => 1)));
      Select_Item (S.Outline, 1);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Open_Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Declaration_Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Declaration);

      Assert (not Editor.Commands.Is_Available (Open_Availability),
              "open-selected availability rejects out-of-range outline target");
      Assert (not Editor.Commands.Is_Available (Declaration_Availability),
              "goto-declaration availability rejects out-of-range outline target");
   end Test_Declaration_Navigation_Availability_Rejects_Stale_Target;

   procedure Test_Next_Previous_Symbol_Use_Source_Order_And_Wrap
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Next     : Natural;
      Previous : Natural;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Alpha;" & ASCII.LF &
         "   procedure Beta;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 550,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Next := Find_Next_Symbol_For_Position (O, 550, 1, 1, True);
      Assert (Next /= 0, "next symbol finds a navigable row");
      Assert (Item_Label (O, Next) = "procedure Alpha",
              "next symbol chooses the first symbol after the caret");

      Next := Find_Next_Symbol_For_Position (O, 550, 3, 4, True);
      Assert (Next /= 0 and then Item_Label (O, Next) = "package Demo",
              "next symbol wraps to the first active-buffer symbol");

      Previous := Find_Previous_Symbol_For_Position (O, 550, 3, 4, True);
      Assert (Previous /= 0 and then Item_Label (O, Previous) = "procedure Alpha",
              "previous symbol chooses the closest preceding symbol");

      Previous := Find_Previous_Symbol_For_Position (O, 550, 1, 1, True);
      Assert (Previous /= 0 and then Item_Label (O, Previous) = "procedure Beta",
              "previous symbol wraps to the last active-buffer symbol");
   end Test_Next_Previous_Symbol_Use_Source_Order_And_Wrap;

   procedure Test_Symbol_Navigation_Rejects_Other_Buffer_And_Stale_Outline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 551,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Find_Next_Symbol_For_Position (O, 552, 1, 1, True) = 0,
              "next symbol rejects a different active buffer token");
      Assert (Find_Previous_Symbol_For_Position (O, 552, 1, 1, True) = 0,
              "previous symbol rejects a different active buffer token");

      Mark_Stale_Result (O);
      Clear (O);
      Mark_Stale_Result (O);
      Assert (Find_Next_Symbol_For_Position (O, 551, 1, 1, True) = 0,
              "next symbol rejects stale/non-extracted outline state");
   end Test_Symbol_Navigation_Rejects_Other_Buffer_And_Stale_Outline;

   procedure Test_Symbol_Navigation_Rejects_Retained_Stale_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 553,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Source_Class (O) = Extracted_Outline,
              "retained stale-row fixture starts from accepted extracted rows");
      Mark_Stale_Result (O);
      Assert (Source_Class (O) = Extracted_Outline,
              "stale diagnostic may retain accepted rows for display");
      Assert (Last_Extraction_Source_Class (O) = Stale_Extracted_Outline,
              "stale diagnostic is still visible to navigation guards");
      Assert (Find_Next_Symbol_For_Position (O, 553, 1, 1, True) = 0,
              "next symbol rejects retained stale rows");
      Assert (Find_Previous_Symbol_For_Position (O, 553, 3, 1, True) = 0,
              "previous symbol rejects retained stale rows");
      Assert (Find_Current_Symbol_For_Cursor (O, 553, 2, 4) = 0,
              "current symbol rejects retained stale rows");
   end Test_Symbol_Navigation_Rejects_Retained_Stale_Rows;

   procedure Test_Symbol_Navigation_Rejects_Mixed_Buffer_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O     : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("package Demo"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 1"),
            Depth       => 0,
            Target_Kind => Buffer_Position_Target,
            Buffer_Token => 5501,
            Line        => 1,
            Column      => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("procedure Other"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 3"),
            Depth       => 1,
            Target_Kind => Buffer_Position_Target,
            Buffer_Token => 5502,
            Line        => 3,
            Column      => 4));
   begin
      Replace_Items (O, Items);

      Assert (Source_Class (O) = Extracted_Outline,
              "mixed-buffer fixture starts as extracted rows");
      Assert (not Outline_Buffer_Identity_Matches (O, 5501),
              "buffer identity rejects mixed active-buffer rows");
      Assert (not Has_Navigable_Symbol_For_Buffer (O, 5501),
              "navigable helper rejects mixed-buffer outline rows");
      Assert (Find_Next_Symbol_For_Position (O, 5501, 1, 1, True) = 0,
              "next symbol refuses partial navigation into mixed-buffer rows");
      Assert (Find_Previous_Symbol_For_Position (O, 5501, 4, 1, True) = 0,
              "previous symbol refuses partial navigation into mixed-buffer rows");
      Assert (Find_Current_Symbol_For_Cursor (O, 5501, 2, 1) = 0,
              "current symbol refuses partial derivation from mixed-buffer rows");
   end Test_Symbol_Navigation_Rejects_Mixed_Buffer_Rows;

   procedure Test_Status_Counts_Only_Navigable_Symbol_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O     : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Section,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Navigation"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("section"),
            Depth       => 0,
            Target_Kind  => No_Target,
            Buffer_Token => 0,
            Line         => 0,
            Column       => 0),
         2 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("package Demo"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 1"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 5503,
            Line         => 1,
            Column       => 1),
         3 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("procedure Run"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 2"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 5503,
            Line         => 2,
            Column       => 4));
   begin
      Replace_Items (O, Items);

      Assert (Navigable_Symbol_Count (O) = 2,
              "status counts real navigable symbols, not group/status rows");
      Assert (Filtered_Navigable_Symbol_Count (O) = 2,
              "unfiltered visible symbol count excludes display rows");
      Assert (Outline_Header_Text (O) = "Outline: 2 symbols",
              "outline header counts navigable symbols only");

      Apply_Filter (O, "run");
      Assert (Filtered_Navigable_Symbol_Count (O) = 1,
              "filtered status count reports only matching symbols");
      Assert (Filtered_Row_Count (O) = 1,
              "fixture filter also leaves one visible projection row");
      Assert (Outline_Header_Text (O) = "Outline: filter ""run"" -- 1 of 2 symbols",
              "filtered header counts navigable symbols only");

      Mark_Stale_Result (O);
      Assert (Outline_Header_Text (O) = "Outline: stale",
              "retained stale rows override current/filter header text");
      Assert (Navigable_Symbol_Count (O) = 0,
              "status symbol count rejects retained stale rows");
      Assert (Filtered_Navigable_Symbol_Count (O) = 0,
              "filtered status count rejects retained stale rows");
   end Test_Status_Counts_Only_Navigable_Symbol_Rows;

   procedure Test_Reveal_Helper_Rejects_Retained_Stale_Current_Symbol
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Panel    : Editor.Feature_Panel.Feature_Panel_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 554,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Update_Current_Symbol_For_Cursor (O, 554, 2, 4);
      Set_Rows_From_Outline (O, Panel);
      Assert (Can_Reveal_Current_Symbol (O, Panel, 554),
              "reveal helper accepts a live current symbol row");

      Mark_Stale_Result (O);
      Assert (not Can_Reveal_Current_Symbol (O, Panel, 554),
              "reveal helper rejects retained stale current-symbol rows");
   end Test_Reveal_Helper_Rejects_Retained_Stale_Current_Symbol;

   procedure Test_Ada_Symbol_Navigation_Audit_Is_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_FP      : Natural;
      Before_Select  : Natural;
      Before_Current : Natural;
      Before_Filter  : Ada.Strings.Unbounded.Unbounded_String;
      Review         : Editor.Outline_Audit.Outline_Contract_Review;
   begin
      Editor.State.Init (S);
      Replace_Items
        (S.Outline,
         (1 =>
            (Kind        => Outline_Package,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Demo"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 1"),
             Depth       => 0,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 1,
             Column       => 1),
          2 =>
            (Kind        => Outline_Procedure,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 2"),
             Depth       => 1,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 2,
             Column       => 4),
          3 =>
            (Kind        => Outline_Function,
             Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Compute"),
             Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("line 3"),
             Depth       => 1,
             Target_Kind  => Buffer_Position_Target,
             Buffer_Token => S.Registry_Token,
             Line         => 3,
             Column       => 4)));
      Apply_Filter (S.Outline, "run");
      Update_Current_Symbol_For_Cursor (S.Outline, S.Registry_Token, 2, 4);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);

      Before_FP := Fingerprint (S.Outline);
      Before_Select := Selected_Index (S.Outline);
      Before_Current := Current_Symbol_Index (S.Outline);
      Before_Filter := Ada.Strings.Unbounded.To_Unbounded_String (Filter_Text (S.Outline));

      Assert (Editor.Outline_Audit.Assert_Ada_Symbol_Navigation_Coherent (S),
              "milestone helper accepts coherent symbol navigation state");
      Review := Editor.Outline_Audit.Review_Outline_Contract (S);
      Assert (Review.Ada_Symbol_Navigation_Coherent,
              "contract review includes symbol navigation coherence");
      Assert (Editor.Outline_Audit.Assert_Ada_Lexical_Safety_Coherent (S),
              "milestone helper accepts coherent lexical safety state");
      Assert (Review.Ada_Lexical_Safety_Coherent,
              "contract review includes lexical safety coherence");
      Assert (Fingerprint (S.Outline) = Before_FP,
              "symbol navigation audit does not mutate outline content");
      Assert (Selected_Index (S.Outline) = Before_Select,
              "symbol navigation audit does not change selection");
      Assert (Current_Symbol_Index (S.Outline) = Before_Current,
              "symbol navigation audit does not change current symbol");
      Assert (Filter_Text (S.Outline) = Ada.Strings.Unbounded.To_String (Before_Filter),
              "symbol navigation audit does not change filter text");
   end Test_Ada_Symbol_Navigation_Audit_Is_Coherent;

   procedure Test_Ada_Current_Symbol_And_Reveal_Skip_Fakes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "-- procedure Fake_Comment;" & ASCII.LF &
            "package Real is" & ASCII.LF &
            "   S : constant String := ""procedure Fake_String is"";" & ASCII.LF &
            "   procedure Run; -- procedure Fake_Inline;" & ASCII.LF &
            "end Real;");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "current-symbol fixture refreshes through executor");
      Assert (Item_Count (S.Outline) = 3,
              "current-symbol fixture has real package, object, and procedure rows");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Down);
      Assert (Current_Symbol_Label (S.Outline) = "procedure Run",
              "current symbol ignores fake comment and string declarations");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "reveal current executes after lexical-safe refresh");
      Assert (Selected_Index (S.Outline) = 3,
              "reveal current selects only the real procedure row");
      Assert (Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
              and then Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 3,
              "reveal current mirrors the real row into feature-panel selection");
   end Test_Ada_Current_Symbol_And_Reveal_Skip_Fakes;

   procedure Test_Outline_Freshness_Is_Queryable_After_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 579,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));

      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Source_Buffer_Token (O) = 579,
              "accepted outline records source buffer token");
      Assert (Source_Buffer_Revision (O) = 1,
              "accepted outline records source buffer revision");
      Assert (Is_Current_For_Buffer (O, 579, 1),
              "accepted outline is current for matching buffer identity");

      Mark_For_Buffer_Change (O);

      Assert (Item_Count (O) > 0,
              "edit freshness marking preserves rows for display");
      Assert (not Is_Current_For_Buffer (O, 579, 1),
              "stale outline is not current even for old revision");
      Assert (Is_Stale_For_Buffer (O, 579, 2),
              "stale outline is queryable against the edited revision");
      Assert (Last_Extraction_Source_Class (O) = Stale_Extracted_Outline,
              "edit freshness marking records stale outline status");
   end Test_Outline_Freshness_Is_Queryable_After_Edit;

   procedure Test_Outline_Freshness_Classifies_Current_Stale_And_Wrong_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 901,
         Buffer_Revision      => 7,
         Lifecycle_Generation => 3,
         Request_Token        => Next_Request_Token (O));

      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Freshness_For_Active_Buffer (O, 901, 7) = Outline_Current,
              "matching active buffer and revision is current");
      Assert (Freshness_For_Active_Buffer (O, 901, 8) = Outline_Stale,
              "same active buffer with newer revision is stale");
      Assert (Freshness_For_Active_Buffer (O, 902, 7) = Outline_Unavailable,
              "different active buffer is not falsely current");

      Mark_For_Buffer_Change (O);
      Assert (Freshness_For_Active_Buffer (O, 901, 8) = Outline_Stale,
              "edited source remains stale until refresh");

      Reset_Outline_For_Buffer_Close (O, 901);
      Assert (Freshness_For_Active_Buffer (O, 901, 8) = Outline_Unavailable,
              "closed source buffer makes outline unavailable");
   end Test_Outline_Freshness_Classifies_Current_Stale_And_Wrong_Buffer;

   procedure Test_Outline_Reload_And_Revert_Clear_Freshness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("reload_revert.adb");
      Disk_Text : constant String :=
        "package Demo is" & ASCII.LF &
        "   procedure Run;" & ASCII.LF &
        "end Demo;";
      Disk_Replacement : constant String :=
        "package Demo is" & ASCII.LF &
        "   procedure Run;" & ASCII.LF &
        "   procedure Stop;" & ASCII.LF &
        "end Demo;";
   begin
      Remove_If_Exists (Path);
      Write_Text (Path, Disk_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) > 0,
              "reload setup refreshes a real Ada outline");
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Current,
        "reload setup outline is current before file replacement");

      Write_Text (Path, Disk_Replacement);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.State.Current_Text (S) = Disk_Replacement,
              "reload replaces text from disk");
      Assert (Item_Count (S.Outline) = 0,
              "reload clears previously accepted outline rows");
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Unavailable,
        "reload makes outline unavailable until explicit refresh");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Current,
        "outline can be refreshed current again after reload");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, ' '));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Current,
        "dirty-buffer outline can be current before revert");

      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "revert creates an explicit destructive confirmation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);
      Assert (Editor.State.Current_Text (S) = Disk_Replacement,
              "revert restores disk text after confirmation");
      Assert (Item_Count (S.Outline) = 0,
              "revert clears previously accepted outline rows");
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Unavailable,
        "revert makes outline unavailable until explicit refresh");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Outline_Reload_And_Revert_Clear_Freshness;

   procedure Test_Close_Buffer_Blocks_Selected_Row_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Demo is" & ASCII.LF &
            "   procedure Run;" & ASCII.LF &
            "end Demo;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Item_Count (S.Outline) > 0,
              "close-buffer setup has outline rows");
      Editor.Feature_Panel.Select_First (S.Feature_Panel);
      Before := S.Carets (S.Carets.First_Index).Pos;

      Reset_Outline_For_Buffer_Close (S.Outline, S.Active_Buffer_Token);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Result.Status = Editor.Executor.Command_Unavailable
                or else Result.Status = Editor.Executor.Command_No_Op,
              "closed-buffer outline navigation is blocked");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before,
              "closed-buffer outline navigation does not move caret");
      Assert (Freshness_For_Active_Buffer
        (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)) =
          Outline_Unavailable,
        "closed-buffer outline is unavailable");
   end Test_Close_Buffer_Blocks_Selected_Row_Navigation;

   procedure Test_Next_Previous_Boundaries_Can_Report_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Alpha;" & ASCII.LF &
         "   procedure Beta;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 57918,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Find_Next_Symbol_For_Position (O, 57918, 4, 1, Wrap => False) = 0,
              "next symbol can report unavailable after the last row");
      Assert (Find_Previous_Symbol_For_Position (O, 57918, 1, 1, Wrap => False) = 0,
              "previous symbol can report unavailable before the first row");
      Assert (Find_Next_Symbol_For_Position (O, 57918, 4, 1, Wrap => True) /= 0,
              "next symbol still supports explicit wrap semantics");
      Assert (Find_Previous_Symbol_For_Position (O, 57918, 1, 1, Wrap => True) /= 0,
              "previous symbol still supports explicit wrap semantics");
   end Test_Next_Previous_Boundaries_Can_Report_Unavailable;

   overriding procedure Register_Tests (T : in out Navigation_Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Open_Selected_Navigates_To_Buffer_Target'Access,
                        "open selected outline item navigates to buffer target");
      Register_Routine (T, Test_Open_Selected_Requires_Live_Outline_Row'Access,
                        "open selected outline requires a live outline row");
      Register_Routine (T, Test_Refresh_Replaces_And_Clears_Selection'Access,
                        "refresh replaces placeholders and clears selection");
      Register_Routine (T, Test_Selection_Mapping_Rejects_Stale_Generic_Row'Access,
                        "selection mapping rejects stale generic rows");
      Register_Routine (T, Test_Refresh_Does_Not_Preserve_Selection_Across_Buffers'Access,
                        "refresh does not preserve selection across buffers");
      Register_Routine (T, Test_Select_Current_Symbol_Chooses_Preceding_Item'Access,
                        "current-symbol lookup chooses preceding item");
      Register_Routine (T, Test_Select_Next_Previous_Skip_Non_Selectable_Rows'Access,
                        "previous/next selection skips non-selectable rows");
      Register_Routine (T, Test_Current_Symbol_Updates_On_Cursor_Line'Access,
                        "current symbol updates on cursor line");
      Register_Routine (T, Test_Current_Symbol_Clears_Before_First_Item'Access,
                        "current symbol clears before first item");
      Register_Routine (T, Test_Current_Symbol_Does_Not_Change_Selection'Access,
                        "current symbol does not change selection");
      Register_Routine (T, Test_Current_Symbol_Clears_For_Unsupported_And_Failure'Access,
                        "unsupported and failure clear current symbol");
      Register_Routine (T, Test_Header_And_Row_Projection_Mark_Current_Symbol'Access,
                        "header and projection mark current symbol");
      Register_Routine (T, Test_Clear_Removes_Current_Symbol'Access,
                        "clear removes current symbol");
      Register_Routine
        (T, Test_Stale_Result_Preserves_Accepted_Current_Symbol'Access,
         "stale result preserves accepted current symbol");
      Register_Routine
        (T, Test_Cursor_Move_Command_Updates_Current_Symbol_Projection'Access,
         "cursor move command updates current symbol projection");
      Register_Routine
        (T, Test_Reveal_Current_Symbol_Requests_Reveal'Access,
         "reveal current symbol requests reveal");
      Register_Routine
        (T, Test_Reveal_Current_Symbol_Noops_When_No_Current_Symbol'Access,
         "reveal current symbol noops without current symbol");
      Register_Routine
        (T, Test_Select_Current_Symbol_Changes_Selection_And_Reveals'Access,
         "select current symbol changes selection and reveals");
      Register_Routine
        (T, Test_Open_Selected_Does_Not_Use_Current_Symbol'Access,
         "open selected does not use current symbol");
      Register_Routine
        (T, Test_Outline_Open_Selected_Returns_Focus_To_Editor_On_Success'Access,
         "open selected returns focus to editor on success");
      Register_Routine
        (T, Test_Outline_Open_Selected_Does_Not_Return_Focus_On_No_Target'Access,
         "open selected does not return focus on no target");
      Register_Routine
        (T, Test_Outline_Open_Selected_Does_Not_Use_Current_Symbol'Access,
         "open selected does not use current symbol");
      Register_Routine
        (T, Test_Outline_Select_Current_Symbol_Preserves_Focus'Access,
         "select current symbol preserves focus");
      Register_Routine
        (T, Test_Outline_Reveal_Current_Symbol_Does_Not_Move_Editor_Cursor'Access,
         "reveal current symbol does not move editor cursor");
      Register_Routine
        (T, Test_Outline_Select_Next_Requests_Reveal'Access,
         "select next requests reveal");
      Register_Routine
        (T, Test_Outline_Select_Previous_Requests_Reveal'Access,
         "select previous requests reveal");
      Register_Routine
        (T, Test_Outline_Mouse_Click_Selects_Row_Without_Navigation'Access,
         "mouse click selects row without navigation");
      Register_Routine
        (T, Test_Outline_Mouse_Double_Click_Opens_Selected_Row'Access,
         "mouse activation opens selected row");
      Register_Routine
        (T, Test_Outline_Mouse_Click_Diagnostic_Row_Does_Not_Navigate'Access,
         "mouse diagnostic row does not navigate");
      Register_Routine
        (T, Test_Outline_Mouse_Click_Rejects_Stale_Projection'Access,
         "mouse stale projection is rejected");
      Register_Routine
        (T, Test_Outline_Mouse_Selection_Does_Not_Change_Current_Symbol'Access,
         "mouse selection does not change current symbol");
      Register_Routine
        (T, Test_Mouse_And_Reveal_Reject_Old_Panel_Generation'Access,
         "mouse and reveal reject old projection generation");
      Register_Routine
        (T, Test_Declaration_Navigation_Availability_Rejects_Stale_Target'Access,
         "declaration navigation availability rejects stale targets");
      Register_Routine
        (T, Test_Next_Previous_Symbol_Use_Source_Order_And_Wrap'Access,
         "next/previous symbol use source order and wrap");
      Register_Routine
        (T, Test_Symbol_Navigation_Rejects_Other_Buffer_And_Stale_Outline'Access,
         "symbol navigation rejects other-buffer and stale outline state");
      Register_Routine
        (T, Test_Symbol_Navigation_Rejects_Retained_Stale_Rows'Access,
         "symbol navigation rejects retained stale rows");
      Register_Routine
        (T, Test_Symbol_Navigation_Rejects_Mixed_Buffer_Rows'Access,
         "symbol navigation rejects mixed-buffer rows");
      Register_Routine
        (T, Test_Status_Counts_Only_Navigable_Symbol_Rows'Access,
         "status counts only navigable symbol rows");
      Register_Routine
        (T, Test_Reveal_Helper_Rejects_Retained_Stale_Current_Symbol'Access,
         "reveal helper rejects retained stale current symbol rows");
      Register_Routine
        (T, Test_Ada_Symbol_Navigation_Audit_Is_Coherent'Access,
         "Ada symbol navigation audit is coherent");
      Register_Routine
        (T, Test_Ada_Current_Symbol_And_Reveal_Skip_Fakes'Access,
         "Ada current symbol and reveal skip fakes");
      Register_Routine
        (T, Test_Outline_Freshness_Is_Queryable_After_Edit'Access,
         "outline freshness is queryable after edit");
      Register_Routine
        (T, Test_Outline_Freshness_Classifies_Current_Stale_And_Wrong_Buffer'Access,
         "outline freshness classifies current stale and wrong buffer");
      Register_Routine
        (T, Test_Outline_Reload_And_Revert_Clear_Freshness'Access,
         "outline reload and revert clear freshness");
      Register_Routine
        (T, Test_Close_Buffer_Blocks_Selected_Row_Navigation'Access,
         "close buffer blocks selected outline navigation");
      Register_Routine
        (T, Test_Next_Previous_Boundaries_Can_Report_Unavailable'Access,
         "next previous boundaries can report unavailable");
   end Register_Tests;

end Editor.Outline.Navigation_Tests;
