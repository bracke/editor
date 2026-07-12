with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Bookmark_Commands;
with Editor.Executor.Buffer_Navigation_Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Quick_Open_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.File_Tree_Navigation_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Find_Replace_Input_Commands;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Executor.Search_Commands;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Folding;
with Editor.Go_To_Line;
with Editor.Gutter_Markers;
with Editor.Input_Field;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Project;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Recent_Buffers;
with Editor.State;
with Editor.Test_Helper;
with Editor.View;

package body Editor.Executor.Navigation_Tests is

   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
   use type Editor.Quick_Open.Quick_Open_Priority_Mode;

   procedure Test_Buffer_Switcher_Accept_Switches_And_Pushes_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("switcher_accept");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "switcher open command must open switcher state");
      Assert (Editor.Overlay_Focus.Is_Active
                (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay),
              "switcher open command must own overlay focus");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Insert_Text (S, "beta");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "switcher filter should narrow to matching open buffer only");
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Accept_Buffer_Switcher (S);

      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "accepting selected switcher row switches active buffer");
      Assert (not Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "successful accept closes switcher");
      Assert (Buffer_Text (S) = "beta body",
              "accepted switch must load selected buffer contents");
      Assert (not S.File_Info.Dirty,
              "switcher activation must not dirty target buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "successful switcher activation pushes navigation history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Buffer_Switcher_Accept_Switches_And_Pushes_History;

   procedure Test_File_Tree_Node_Action_Pushes_Navigation_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("tree_history");
      S           : Editor.State.State_Type;
      Found       : Boolean := False;
      First_File  : Editor.File_Tree.File_Tree_Node_Id;
      Second_File : Editor.File_Tree.File_Tree_Node_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      First_File := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");
      Second_File := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "a_dir/nested.txt", Found);
      Assert (Found, "fixture must contain nested file");

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, First_File, Editor.File_Tree_View.Open_File_Action);
      Assert (To_String (S.File_Info.Display_Name) = "a.txt",
              "first tree activation must make a.txt active");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "first file activation from empty startup has no prior editor location");

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, Second_File, Editor.File_Tree_View.Open_File_Action);
      Assert (To_String (S.File_Info.Display_Name) = "nested.txt",
              "second tree activation must switch active buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "File Tree activation is not a navigation-history recording point");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (Latest_Message_Text (S) = "No previous navigation location.",
              "navigation.back after File Tree-only movement must report empty history");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Tree_Node_Action_Pushes_Navigation_History;

   procedure Test_Recent_Previous_And_Next_Switch_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (B_Id /= A_Id,
              "setup must create a second active buffer");

      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Executor.Buffer_Navigation_Commands.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "previous recent buffer must return to the last active buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "previous recent buffer must record navigation history");

      Editor.Executor.Buffer_Navigation_Commands.Execute_Next_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "next recent buffer must return through the traversal sequence");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 2,
              "next recent buffer must record navigation history");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Recent_Previous_And_Next_Switch_Buffers;

   procedure Test_Recent_Traversal_Wraps_Three_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Buffer_Navigation_Commands.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "previous recent should first select B from C/B/A order");
      Editor.Executor.Buffer_Navigation_Commands.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "previous recent should continue to A");
      Editor.Executor.Buffer_Navigation_Commands.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = C_Id,
              "previous recent should wrap to C");
      Editor.Executor.Buffer_Navigation_Commands.Execute_Next_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "next recent should reverse the traversal");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Recent_Traversal_Wraps_Three_Buffers;

   procedure Test_Recent_Close_Removes_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (A_Id));

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (B_Id)),
              "new active buffer must enter recent order");

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, B_Id);
      Assert (not Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (B_Id)),
              "closing a buffer must remove it from recent order");
      Editor.Executor.Buffer_Navigation_Commands.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "recent navigation after close must not target the closed buffer");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Recent_Close_Removes_Target;

   procedure Test_New_Explicit_Navigation_After_Back_Clears_Forward
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State  : Editor.Navigation_History.Navigation_History_State;
      Target : Editor.Navigation_History.Navigation_Location;
      Found  : Boolean;
   begin
      Editor.Navigation_History.Record_Explicit_Navigation
        (State, (Buffer_Id => 1, Line => 1, Column => 0, others => <>));
      Found := Editor.Navigation_History.Pop_Back (State, Target);
      Assert (Found, "setup must pop a previous location");
      Editor.Navigation_History.Record_Forward_Navigation
        (State, (Buffer_Id => 1, Line => 3, Column => 0, others => <>));
      Assert (Editor.Navigation_History.Forward_Count (State) = 1,
              "setup must create a forward entry after back");

      Editor.Navigation_History.Record_Explicit_Navigation
        (State, (Buffer_Id => 1, Line => 2, Column => 0, others => <>));
      Assert (Editor.Navigation_History.Forward_Count (State) = 0,
              "new explicit navigation after back must clear forward history");
   end Test_New_Explicit_Navigation_After_Back_Clears_Forward;

   procedure Test_New_Buffer_Seeds_Initial_Recent_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Assert (B_Id /= A_Id,
              "setup must create a distinct second buffer");
      Assert (Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (A_Id)),
              "creating a second buffer must seed the prior active buffer in MRU order");
      Assert (Editor.Recent_Buffers.Contains (S.Recent_Buffers, Natural (B_Id)),
              "creating a second buffer must record the new active buffer in MRU order");

      Editor.Executor.Buffer_Navigation_Commands.Execute_Previous_Recent_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "previous recent must work immediately after ordinary new-buffer creation");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_New_Buffer_Seeds_Initial_Recent_Order;

   procedure Test_Recent_Feedback_Is_Primary_Command_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Buffers.Ensure_Global_Registry (S);

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Buffer_Navigation_Commands.Execute_Previous_Recent_Buffer (S);

      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (Msg.Text) = "Buffer: previous",
              "recent previous must expose compact recent-buffer feedback, not generic switch feedback");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Buffer_Navigation_Commands.Execute_Next_Recent_Buffer (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (Msg.Text) = "Buffer: next",
              "recent next must expose compact recent-buffer feedback, not generic switch feedback");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Recent_Feedback_Is_Primary_Command_Message;

   procedure Test_Buffer_Switcher_Failed_Accept_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("switcher_failed_accept");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Insert_Text (S, "not-open");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0,
              "test setup should create no-match switcher state");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Accept_Buffer_Switcher (S);

      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "failed accept must preserve active buffer");
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "failed accept keeps switcher open for filter repair");
      Assert (Buffer_Text (S) = "alpha body",
              "failed accept must preserve buffer contents");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "failed switcher activation must not push navigation history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Buffer_Switcher_Failed_Accept_Preserves_State;

   overriding function Name
     (T : Navigation_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Navigation_Tests");
   end Name;

   procedure Test_Navigation_Boundaries_Are_No_Ops
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Before_Dirty : Boolean;
   begin
      Init_Executor_Test_State (S);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_New_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "new buffer setup succeeds");
      Before_Dirty := S.File_Info.Dirty;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Move_Left);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "moving left at the start of the buffer is a no-op");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "boundary navigation must not dirty the buffer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Previous_Buffer);
      Assert (Result.Status = Editor.Executor.Command_No_Op,
              "previous buffer with only one buffer is a no-op");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "buffer navigation no-op must not dirty the buffer");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Navigation_Boundaries_Are_No_Ops;

   procedure Test_Goto_Line_Jumps_And_Returns_To_Editor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Executor.Navigation_Commands.Execute_Open_Goto_Line (S);
      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "Go To Line input opens");
      Assert
        (Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay),
         "Go To Line owns overlay focus while open");

      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "3");
      Editor.Executor.Navigation_Commands.Execute_Accept_Goto_Line (S);

      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 2 and then Col = 0,
              "valid one-based line target moves caret to column 1");
      Assert (not Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "successful Go To Line closes the input");
      Assert (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
              "successful Go To Line returns to normal editor focus");
      Assert (not S.File_Info.Dirty,
              "Go To Line does not dirty the buffer");
      Assert (Latest_Message_Text (S) = "Went to line 3",
              "successful Go To Line feedback is deterministic");
   end Test_Goto_Line_Jumps_And_Returns_To_Editor;


   procedure Test_Goto_Line_Failure_Preserves_Cursor_Viewport
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Before_Caret  : Editor.Cursors.Cursor_Index;
      Before_Anchor : Editor.Cursors.Cursor_Index;
      Before_Scroll : Natural;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 4,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.View.Set_Scroll (0, 7);

      Before_Caret := S.Carets (S.Carets.First_Index).Pos;
      Before_Anchor := S.Carets (S.Carets.First_Index).Anchor;
      Before_Scroll := Editor.View.Scroll_Y;

      Editor.Executor.Navigation_Commands.Execute_Open_Goto_Line (S);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "99");
      Editor.Executor.Navigation_Commands.Execute_Accept_Goto_Line (S);

      Assert (Editor.Go_To_Line.Is_Open (S.Go_To_Line),
              "failed Go To Line keeps input open for correction");
      Assert (S.Carets (S.Carets.First_Index).Pos = Before_Caret,
              "failed Go To Line preserves cursor");
      Assert (S.Carets (S.Carets.First_Index).Anchor = Before_Anchor,
              "failed Go To Line preserves selection anchor");
      Assert (Editor.View.Scroll_Y = Before_Scroll,
              "failed Go To Line preserves viewport");
      Assert (Latest_Message_Text (S) = "Line 99 is outside the active buffer",
              "out-of-range feedback is deterministic");
      Assert (not S.File_Info.Dirty,
              "failed Go To Line does not dirty the buffer");
   end Test_Goto_Line_Failure_Preserves_Cursor_Viewport;


   procedure Test_Goto_Line_Does_Not_Mutate_Find_Or_Feature_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Feature_Rows : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "alpha");
      S.Active_Find_Prompt := True;
      Editor.Input_Field.Set_Text (S.Active_Find_Input, "alpha");
      Editor.Feature_Panel.Clear (S.Feature_Panel);
      Before_Feature_Rows := Editor.Feature_Panel.Row_Count (S.Feature_Panel);

      Editor.Executor.Navigation_Commands.Execute_Open_Goto_Line (S);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "2");
      Editor.Executor.Navigation_Commands.Execute_Accept_Goto_Line (S);

      Assert (Editor.Input_Field.Text (S.Active_Find_Input) = "alpha",
              "Go To Line preserves find query");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = Before_Feature_Rows,
              "Go To Line does not create Feature Panel rows");
   end Test_Goto_Line_Does_Not_Mutate_Find_Or_Feature_Rows;


   procedure Test_Goto_Line_Back_Forward_Routes_Through_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Row : Natural := 0;
      Col : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two" & ASCII.LF & "three");

      Editor.Executor.Navigation_Commands.Execute_Open_Goto_Line (S);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "3");
      Editor.Executor.Navigation_Commands.Execute_Accept_Goto_Line (S);

      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Go To Line must record explicit navigation history");
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 2 and then Col = 0,
              "Go To Line must still move the caret without creating history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Assert (Row = 0 and then Col = 0,
              "navigation.back must restore the pre-go-to-line caret location");
   end Test_Goto_Line_Back_Forward_Routes_Through_Executor;


   procedure Test_Find_Navigation_Pushes_History_And_Back_Preserves_Query
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Cmd.Kind := Editor.Commands.Active_Find_Next;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "find-next must record explicit navigation history");
      Assert (Editor.Input_Field.Text (S.Active_Find_Input) = "alpha",
              "find-next must not mutate the find query");
      Assert (Editor.Feature_Search_Results.Is_Empty (S.Feature_Search_Results),
              "find-next must not create Feature Panel Search Results");
   end Test_Find_Navigation_Pushes_History_And_Back_Preserves_Query;


   procedure Test_Typing_And_Save_Do_Not_Push_Navigation_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "abc");

      Cmd := Editor.Test_Helper.Insert (0, 'X');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "ordinary typing must not push navigation history");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "save must not push navigation history");
   end Test_Typing_And_Save_Do_Not_Push_Navigation_History;


   procedure Test_Navigation_History_Clear_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one" & ASCII.LF & "two");
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History, (Buffer_Id => 1, Line => 1, Column => 0, others => <>));
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "setup must create a back entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_History_Clear);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "clear must empty the back stack");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "clear must empty the forward stack");
      Assert (Latest_Message_Text (S) = "Navigation history cleared",
              "clear feedback must be deterministic");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_History_Clear);
      Assert (Latest_Message_Text (S) = "No navigation history.",
              "empty clear feedback must be deterministic");
   end Test_Navigation_History_Clear_Command;


   procedure Test_Navigation_History_Clear_Descriptor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Navigation_History_Clear);
   begin
      Assert (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Navigation_History_Clear) = "navigation.history.clear",
              "clear command must have a stable persisted name");
      Assert (D.Bindable,
              "clear command must be bindable");
      Assert (D.Visibility = Editor.Commands.Palette_Command,
              "clear command must be visible in the Command Palette");
      Assert (D.Category = Editor.Commands.Navigation_Category,
              "clear command must be categorized as Navigation");
      Assert (not D.Destructive,
              "clear command must not be classified destructive");
   end Test_Navigation_History_Clear_Descriptor;


   procedure Test_Failed_Back_Invalid_Open_Target_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("invalid_back_atomic");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Navigation_History.Clear (S.Navigation_History);

      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id     => Natural (B_Id),
          Has_File_Path => True,
          File_Path     => To_Unbounded_String (B_Path),
          Display_Path  => To_Unbounded_String ("beta.adb"),
          Line          => 99,
          Column        => 0,
          Viewport_Row  => 0,
          Reason        => Editor.Navigation_History.Navigation_Reason_Unknown));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);

      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "failed back to invalid open target must keep current buffer active");
      Assert (Buffer_Text (S) = "alpha body",
              "failed back to invalid open target must not load target text");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "failed back to invalid open target must restore back stack");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "failed back to invalid open target must not create forward entry");
      Assert (Latest_Message_Text (S) = "Could not navigate to beta.adb:99: invalid location",
              "failed back to invalid open target must report deterministic invalid-location feedback");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Failed_Back_Invalid_Open_Target_Is_Atomic;



   procedure Test_Back_To_Unopened_Stale_Line_Is_Partial_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("back_partial_line");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S      : Editor.State.State_Type;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha body");
      Write_Text_File (B_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id     => 0,
          Has_File_Path => True,
          File_Path     => To_Unbounded_String (B_Path),
          Display_Path  => To_Unbounded_String ("beta.adb"),
          Line          => 99,
          Column        => 0,
          Viewport_Row  => 0,
          Reason        => Editor.Navigation_History.Navigation_Reason_Unknown));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "partial stale-line back must keep successfully opened target active");
      Assert (Buffer_Text (S) = "beta body",
              "partial stale-line back must load the opened target text");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "partial stale-line back must consume the back entry");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "partial stale-line back must record current location for forward navigation");
      Assert (Latest_Message_Text (S) =
                "Navigated back to beta.adb:99; could not move to line 99",
              "partial stale-line back must report one deterministic partial-success message");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Back_To_Unopened_Stale_Line_Is_Partial_Success;











   procedure Test_Reveal_Active_Selects_Known_Project_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("reveal_root");
      Src       : constant String := Ada.Directories.Compose (Root, "src");
      Exec_Path : constant String := Ada.Directories.Compose (Src, "executor.adb");
      Ads_Path  : constant String := Ada.Directories.Compose (Src, "executor.ads");
      Doc_Path  : constant String := Ada.Directories.Compose (Root, "README.md");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Snap      : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Text_File (Exec_Path, "body");
      Write_Text_File (Ads_Path, "spec");
      Write_Text_File (Doc_Path, "doc");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String (""),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "README.md", Doc_Path);
      Editor.Project.Add_Known_File (S.Project, "src/executor.adb", Exec_Path);
      Editor.Project.Add_Known_File (S.Project, "src/executor.ads", Ads_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Exec_Path);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "README");
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Kind_Next (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Set (S, "docs");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Reveal_Active (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);

      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open),
              "reveal-active must show Quick Open");
      Assert (To_String (Snap.Query) = "executor.adb",
              "reveal-active must install a filename query so no-query prompt does not hide the active file");
      Assert (Snap.File_Kind_Filter = Editor.Quick_Open.All_Files,
              "reveal-active must reset kind filter to All");
      Assert (To_String (Snap.Path_Scope) = "",
              "reveal-active must clear path scope");
      Assert (To_String (Snap.Selected_Path) = "src/executor.adb",
              "reveal-active must select the active project file by relative path");
      Assert (Snap.Visible_Count = 1 and then Snap.Known_Count = 3,
              "reveal-active count feedback must reflect the filename query and known project files");
      Assert (Latest_Message_Text (S) =
                "Quick Open selected active file: src/executor.adb",
              "reveal-active must report selection without claiming open/activation");

      Remove_Tree_If_Exists (Root);
   end Test_Reveal_Active_Selects_Known_Project_File;

   procedure Test_Scope_Active_Directory_Selects_Active_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("scope_root");
      Src       : constant String := Ada.Directories.Compose (Root, "src");
      Other_Dir : constant String := Ada.Directories.Compose (Root, "tests");
      Exec_Path : constant String := Ada.Directories.Compose (Src, "executor.adb");
      Ads_Path  : constant String := Ada.Directories.Compose (Src, "executor.ads");
      Test_Path : constant String := Ada.Directories.Compose (Other_Dir, "test_executor.adb");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Snap      : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Other_Dir);
      Write_Text_File (Exec_Path, "body");
      Write_Text_File (Ads_Path, "spec");
      Write_Text_File (Test_Path, "test");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String (""),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "src/executor.adb", Exec_Path);
      Editor.Project.Add_Known_File (S.Project, "src/executor.ads", Ads_Path);
      Editor.Project.Add_Known_File (S.Project, "tests/test_executor.adb", Test_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Exec_Path);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Active_Directory (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);

      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open),
              "scope-active-directory must show Quick Open");
      Assert (To_String (Snap.Query) = "executor.adb",
              "scope-active-directory must install a filename query so no-query prompt does not hide the active file");
      Assert (Snap.File_Kind_Filter = Editor.Quick_Open.All_Files,
              "scope-active-directory must reset kind filter to All");
      Assert (To_String (Snap.Path_Scope) = "src/",
              "scope-active-directory must scope to the active file directory");
      Assert (To_String (Snap.Selected_Path) = "src/executor.adb",
              "scope-active-directory must select the active file");
      Assert (Snap.Visible_Count = 1 and then Snap.Known_Count = 3,
              "scope-active-directory count feedback must reflect scoped filename results");
      Assert (Latest_Message_Text (S) = "Quick Open scope: src/",
              "scope-active-directory must use existing scope message wording");

      Remove_Tree_If_Exists (Root);
   end Test_Scope_Active_Directory_Selects_Active_File;

   procedure Test_Active_Buffer_Not_Known_Does_Not_Show_Quick_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("not_known_root");
      Known     : constant String := Ada.Directories.Compose (Root, "known.adb");
      Unknown   : constant String := Ada.Directories.Compose (Root, "unknown.adb");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (Known, "known");
      Write_Text_File (Unknown, "unknown");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String (""),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "known.adb", Known);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Unknown);

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Reveal_Active (S);

      Assert (not Editor.Quick_Open.Is_Open (S.Quick_Open),
              "reveal-active must not open Quick Open when active file is not known");
      Assert (Latest_Message_Text (S) = "Active buffer is not a known project file",
              "unknown active file must have deterministic feedback");

      Remove_Tree_If_Exists (Root);
   end Test_Active_Buffer_Not_Known_Does_Not_Show_Quick_Open;


   procedure Test_Active_Reveal_And_Scope_Preserve_Priority
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("active_priority_root");
      Src       : constant String := Ada.Directories.Compose (Root, "src");
      Docs      : constant String := Ada.Directories.Compose (Root, "docs");
      Exec_Path : constant String := Ada.Directories.Compose (Src, "executor.adb");
      Ads_Path  : constant String := Ada.Directories.Compose (Src, "executor.ads");
      Doc_Path  : constant String := Ada.Directories.Compose (Docs, "guide.md");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Snap      : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Docs);
      Write_Text_File (Exec_Path, "body");
      Write_Text_File (Ads_Path, "spec");
      Write_Text_File (Doc_Path, "doc");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String (""),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "src/executor.adb", Exec_Path);
      Editor.Project.Add_Known_File (S.Project, "src/executor.ads", Ads_Path);
      Editor.Project.Add_Known_File (S.Project, "docs/guide.md", Doc_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Exec_Path);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "guide");
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Kind_Next (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Set (S, "docs/");
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Priority_Toggle (S);

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Reveal_Active (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (Snap.Priority_Mode = Editor.Quick_Open.Open_Recent,
              "reveal-active must preserve Open/Recent priority mode");
      Assert (To_String (Snap.Query) = "executor.adb"
              and then Snap.File_Kind_Filter = Editor.Quick_Open.All_Files
              and then To_String (Snap.Path_Scope) = "",
              "reveal-active must normalize kind/scope and install the active filename query");
      Assert (To_String (Snap.Selected_Path) = "src/executor.adb",
              "reveal-active must select the active file despite previous filters");
      Assert (Latest_Message_Text (S) =
                "Quick Open selected active file: src/executor.adb",
              "reveal-active must keep one selection message");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "guide");
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Kind_Next (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Set (S, "docs/");
      Assert (Editor.Quick_Open.Priority_Mode (S.Quick_Open) = Editor.Quick_Open.Open_Recent,
              "test setup must keep Open/Recent priority before scope-active-directory");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Scope_Active_Directory (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (Snap.Priority_Mode = Editor.Quick_Open.Open_Recent,
              "scope-active-directory must preserve Open/Recent priority mode");
      Assert (To_String (Snap.Query) = "executor.adb"
              and then Snap.File_Kind_Filter = Editor.Quick_Open.All_Files
              and then To_String (Snap.Path_Scope) = "src/",
              "scope-active-directory must reset kind/scope and install the active filename query");
      Assert (To_String (Snap.Selected_Path) = "src/executor.adb"
              and then Snap.Visible_Count = 1 and then Snap.Known_Count = 3,
              "scope-active-directory must select active file and keep scoped filename counts coherent");
      Assert (Latest_Message_Text (S) = "Quick Open scope: src/",
              "scope-active-directory must keep one scope message");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Active_Reveal_And_Scope_Preserve_Priority;

   procedure Test_Stale_Quick_Open_Open_Failure_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("stale_open_root");
      Src        : constant String := Ada.Directories.Compose (Root, "src");
      Stale_Path : constant String := Ada.Directories.Compose (Src, "stale.adb");
      Other_Path : constant String := Ada.Directories.Compose (Src, "other.adb");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
      Refresh    : Editor.Project.Project_File_Refresh_Result;
      Snap       : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Text_File (Stale_Path, "stale");
      Write_Text_File (Other_Path, "other");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "stale-open test project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Refresh_Known_Files (S.Project, Refresh);
      Assert (Refresh.Status = Editor.Project.Project_File_Refresh_Ok,
              "stale-open setup refresh must succeed");

      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "stale");
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (To_String (Snap.Selected_Path) = "src/stale.adb",
              "stale-open setup must select stale candidate");

      Ada.Directories.Delete_File (Stale_Path);
      Editor.Executor.Quick_Open_Commands.Execute_Accept_Quick_Open (S);
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);

      Assert (Latest_Message_Text (S) =
                "Could not open src/stale.adb: file not found",
              "stale open failure must report one deterministic failure message");
      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open),
              "stale open failure must keep Quick Open visible");
      Assert (To_String (Snap.Query) = "stale"
              and then To_String (Snap.Selected_Path) = "src/stale.adb",
              "stale open failure must preserve query and selected known candidate");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/stale.adb"),
              "stale open failure must not mutate known files before refresh");
      Assert (not Editor.State.Has_Active_Buffer (S),
              "stale open failure must not invent an active buffer");

      Editor.Project.Refresh_Known_Files (S.Project, Refresh);
      Assert (Refresh.Status = Editor.Project.Project_File_Refresh_Ok
              and then Refresh.Removed_Count = 1,
              "later refresh must remove the stale known path");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.Project, (others => <>));
      Snap := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/stale.adb")
              and then Snap.Visible_Count = 0
              and then To_String (Snap.Selected_Path) = "",
              "refresh after stale failure must clear stale candidate selection");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Stale_Quick_Open_Open_Failure_Preserves_State;

   procedure Test_Quick_Open_Accept_Records_Previous_Location
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("quick_open_record_root");
      A_Path    : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path    : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Quick Open record setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "alpha.adb", A_Path);
      Editor.Project.Add_Known_File (S.Project, "beta.adb", B_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "beta");
      Editor.Executor.Quick_Open_Commands.Execute_Accept_Quick_Open (S);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "Quick Open accept must open selected target");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "Quick Open accept must record previous editor location on success");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "successful new Quick Open navigation must leave no forward history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Quick_Open_Accept_Records_Previous_Location;

   procedure Test_Quick_Open_Stale_Failure_Does_Not_Record
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("quick_open_stale_root");
      Current    : constant String := Ada.Directories.Compose (Root, "current.adb");
      Stale_Path : constant String := Ada.Directories.Compose (Root, "stale.adb");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (Current, "current");
      Write_Text_File (Stale_Path, "stale");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Quick Open stale setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "current.adb", Current);
      Editor.Project.Add_Known_File (S.Project, "stale.adb", Stale_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Current);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "stale");
      Ada.Directories.Delete_File (Stale_Path);
      Editor.Executor.Quick_Open_Commands.Execute_Accept_Quick_Open (S);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Current,
              "stale Quick Open failure must keep active editor location");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "stale Quick Open failure must not record previous location");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "stale Quick Open failure must not mutate forward history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Quick_Open_Stale_Failure_Does_Not_Record;


   procedure Test_Quick_Open_Captures_Execution_Time_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("quick_open_capture");
      A_Path   : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path   : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, Numbered_Lines (50));
      Write_Text_File (B_Path, Numbered_Lines (10));

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Quick Open capture setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "alpha.adb", A_Path);
      Editor.Project.Add_Known_File (S.Project, "beta.adb", B_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Move_Caret_To_Line (S, 20);

      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "beta");
      Editor.Executor.Quick_Open_Commands.Execute_Accept_Quick_Open (S);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "Quick Open accept must open the selected target");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1
              and then Back_Top_Path (S) = A_Path
              and then Back_Top_Line (S) = 20,
              "Quick Open must record the execution-time caret line, not the stale open line");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = A_Path
              and then Active_Caret_Line (S) = 20,
              "navigation.back must return to the captured Quick Open source line");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "back must create a coherent forward entry");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "navigation.forward must restore the Quick Open destination");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "forward must leave one useful previous-location entry");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Quick_Open_Captures_Execution_Time_Caret;


   procedure Test_Project_Search_Same_File_Line_Roundtrip
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("project_search_same_file");
      Path     : constant String := Ada.Directories.Compose (Root, "executor.adb");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (Path, Numbered_Lines (130, 120));

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Project Search setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "executor.adb", Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Move_Caret_To_Line (S, 20);

      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "same-file Project Search setup must produce one result");
      Editor.Executor.Project_Search_Result_Commands.Execute_Open_Selected_Project_Search_Result (S);

      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path,
              "Project Search open-selected must stay in the same file");
      Assert (Active_Caret_Line (S) = 120,
              "Project Search open-selected must move to the result line");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1
              and then Back_Top_Line (S) = 20,
              "same-file search navigation must record the prior line as useful history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path
              and then Active_Caret_Line (S) = 20,
              "back must return to the same-file source line");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path
              and then Active_Caret_Line (S) = 120,
              "forward must return to the same-file search result line");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Search_Same_File_Line_Roundtrip;


   procedure Test_Back_Forward_Capture_Moved_Current_Anchors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("refined_anchors");
      A_Path : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      S      : Editor.State.State_Type;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, Numbered_Lines (40));
      Write_Text_File (B_Path, Numbered_Lines (40));
      Write_Text_File (C_Path, Numbered_Lines (40));

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      Move_Caret_To_Line (S, 30);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (A_Path), Display_Path => To_Unbounded_String ("alpha.adb"),
          Line => 10, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (B_Path), Display_Path => To_Unbounded_String ("beta.adb"),
          Line => 20, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path
              and then Active_Caret_Line (S) = 20
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1,
              "setup back must move C:30 to B:20 and save C for forward");

      Move_Caret_To_Line (S, 25);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = C_Path
              and then Active_Caret_Line (S) = 30
              and then Back_Top_Line (S) = 25,
              "forward must capture the moved B:25 anchor at execution time");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path
              and then Active_Caret_Line (S) = 25,
              "next back must return to moved B:25 rather than stale B:20");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Back_Forward_Capture_Moved_Current_Anchors;


   procedure Test_Forward_Stack_Clears_Only_On_Successful_New_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("forward_clear");
      A_Path     : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path     : constant String := Ada.Directories.Compose (Root, "beta.adb");
      C_Path     : constant String := Ada.Directories.Compose (Root, "gamma.adb");
      D_Path     : constant String := Ada.Directories.Compose (Root, "delta.adb");
      Stale_Path : constant String := Ada.Directories.Compose (Root, "stale.adb");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha");
      Write_Text_File (B_Path, "beta");
      Write_Text_File (C_Path, "gamma");
      Write_Text_File (D_Path, "delta");
      Write_Text_File (Stale_Path, "stale");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "forward-clear setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "alpha.adb", A_Path);
      Editor.Project.Add_Known_File (S.Project, "beta.adb", B_Path);
      Editor.Project.Add_Known_File (S.Project, "gamma.adb", C_Path);
      Editor.Project.Add_Known_File (S.Project, "delta.adb", D_Path);
      Editor.Project.Add_Known_File (S.Project, "stale.adb", Stale_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (A_Path), Display_Path => To_Unbounded_String ("alpha.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (C_Path), Display_Path => To_Unbounded_String ("gamma.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));

      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "delta");
      Editor.Executor.Quick_Open_Commands.Execute_Accept_Quick_Open (S);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = D_Path,
              "successful new navigation must open D");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "successful new non-history navigation must clear forward history");
      Assert (Back_Top_Path (S) = B_Path,
              "successful new navigation must record current B before D");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (A_Path), Display_Path => To_Unbounded_String ("alpha.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (C_Path), Display_Path => To_Unbounded_String ("gamma.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Ada.Directories.Delete_File (Stale_Path);

      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "stale");
      Editor.Executor.Quick_Open_Commands.Execute_Accept_Quick_Open (S);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
              "stale Quick Open failure must preserve active B");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 1
              and then Forward_Top_Line (S) = 1,
              "failed new navigation must not push current or clear forward history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = C_Path,
              "preserved forward history must still navigate to C after failed new navigation");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Forward_Stack_Clears_Only_On_Successful_New_Navigation;


   procedure Test_Non_Recording_Selection_Commands_Preserve_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("non_recording");
      A_Path   : constant String := Ada.Directories.Compose (Root, "alpha.adb");
      B_Path   : constant String := Ada.Directories.Compose (Root, "beta.adb");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      Back_Before    : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha needle" & ASCII.LF & "again needle");
      Write_Text_File (B_Path, "beta");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "non-recording setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      Editor.Project.Add_Known_File (S.Project, "alpha.adb", A_Path);
      Editor.Project.Add_Known_File (S.Project, "beta.adb", B_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (A_Path), Display_Path => To_Unbounded_String ("alpha.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Editor.Navigation_History.Record_Forward_Navigation
        (S.Navigation_History,
         (Buffer_Id => 0, Has_File_Path => True,
          File_Path => To_Unbounded_String (B_Path), Display_Path => To_Unbounded_String ("beta.adb"),
          Line => 1, Column => 0, Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Unknown));
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "alpha");
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Next_Result (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Previous_Result (S);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Editor.Executor.Project_Search_Result_Commands.Execute_Next_Project_Search_Result (S);
      Editor.Executor.Project_Search_Result_Commands.Execute_Previous_Project_Search_Result (S);
      Editor.Executor.Project_Search_Result_Commands.Execute_Reveal_Active_Project_Search_Result (S);
      Editor.Executor.Bookmark_Commands.Execute_Bookmark_Toggle_Surface (S);
      Editor.Executor.Bookmark_Commands.Execute_Bookmark_Reveal_Current (S);

      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "selection/read-only feature commands must not capture, clear, or normalize navigation history");

      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Set_Query (S, "alpha");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "reopening/querying Quick Open before clear must still not mutate history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_History_Clear);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "history.clear must mutate only navigation history stacks");
      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open)
              and then Editor.Project_Search.Result_Count (S.Project_Search) = 2,
              "history.clear must preserve populated Quick Open and Project Search state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Non_Recording_Selection_Commands_Preserve_History;


   procedure Test_Toggle_Bookmark_At_Caret_And_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Before_Text  : Unbounded_String;
      Before_Dirty : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Dirty := S.File_Info.Dirty;

      Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark (S);
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
        "toggle bookmark should add a bookmark on the primary caret row");
      Assert (To_String (Before_Text) = Editor.State.Current_Text (S),
              "toggle bookmark must not mutate buffer text");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "toggle bookmark must not change dirty state");

      Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark_At_Row (S, 0);
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
        "toggle bookmark at row should affect the requested row");

      Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark (S);
      Assert (not Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
        "toggle bookmark should remove an existing bookmark on the caret row");
   end Test_Toggle_Bookmark_At_Caret_And_Row;

   procedure Test_Next_Previous_Bookmark_Navigation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S, "aaa" & ASCII.LF & "bbb" & ASCII.LF & "ccc" & ASCII.LF & "ddd");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 0, Anchor => 2, Virtual_Column => 3, Anchor_Virtual_Column => 3));
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Executor.Bookmark_Commands.Execute_Next_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 2),
              "next bookmark should jump to the next bookmarked row at column zero");
      Assert (S.Carets.Length = 1,
              "bookmark navigation should clear secondary carets");
      Assert (S.Carets (S.Carets.First_Index).Anchor = S.Carets (S.Carets.First_Index).Pos,
              "bookmark navigation should collapse selection");

      Editor.Executor.Bookmark_Commands.Execute_Next_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 0),
              "next bookmark should wrap to the first bookmark");

      Editor.Executor.Bookmark_Commands.Execute_Previous_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 2),
              "previous bookmark should wrap to the last bookmark");
   end Test_Next_Previous_Bookmark_Navigation;

   procedure Test_Bookmark_Navigation_Empty_Preserves_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => 4, Anchor => 4, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before := Editor.Executor.Safe_Caret (S);

      Editor.Executor.Bookmark_Commands.Execute_Next_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Before,
              "next bookmark with no bookmarks must preserve the caret");
      Editor.Executor.Bookmark_Commands.Execute_Previous_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Before,
              "previous bookmark with no bookmarks must preserve the caret");
   end Test_Bookmark_Navigation_Empty_Preserves_Caret;

   procedure Test_Bookmark_Navigation_Across_Open_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      First_Id : Editor.Buffers.Buffer_Id;
      Other_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "a0" & ASCII.LF & "a1");
      Editor.Buffers.Ensure_Global_Registry (S);
      First_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (Other_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "b0" & ASCII.LF & "b1" & ASCII.LF & "b2");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (First_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos => Editor.State.Line_Start (S, 1),
          Anchor => Editor.State.Line_Start (S, 1),
          Virtual_Column => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Bookmark_Commands.Execute_Next_Bookmark (S);
      Assert (Editor.Buffers.Global_Active_Buffer = Other_Id,
              "next bookmark should move to the next open buffer in row order");
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 2),
              "next bookmark should land on the bookmarked row in the target buffer");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "successful bookmark navigation should push the previous location");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
      Assert (Editor.Buffers.Global_Active_Buffer = First_Id,
              "navigation back after bookmark jump should return to prior buffer");
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 1),
              "navigation back after bookmark jump should return to prior row");
   end Test_Bookmark_Navigation_Across_Open_Buffers;

   procedure Test_Clear_All_Bookmarks_Across_Open_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      First_Id : Editor.Buffers.Buffer_Id;
      Other_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "a0" & ASCII.LF & "a1");
      Editor.Buffers.Ensure_Global_Registry (S);
      First_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Add_Untitled_Buffer (Other_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.State.Load_Text (S, "b0" & ASCII.LF & "b1");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Bookmark_Commands.Execute_Clear_All_Bookmarks (S);
      Assert (Editor.Buffers.Global_Bookmark_Count = 0,
              "clear all bookmarks should remove bookmarks from every open buffer");

      Editor.Buffers.Global_Set_Active_Buffer (First_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers),
              "clear all bookmarks should update the first buffer marker projection");

      Editor.Buffers.Global_Set_Active_Buffer (Other_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers),
              "clear all bookmarks should update the second buffer marker projection");
   end Test_Clear_All_Bookmarks_Across_Open_Buffers;


   procedure Test_Clear_Bookmarks_Active_Buffer_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Other_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "active");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Dirty_Line_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Diagnostic_Error_Marker);

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Add_Untitled_Buffer (Other_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Dirty_Line_Marker);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Diagnostic_Error_Marker);

      Editor.Executor.Bookmark_Commands.Execute_Clear_Bookmarks (S);
      Assert (not Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
        "clear bookmarks should remove active-buffer bookmarks");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Dirty_Line_Marker),
        "clear bookmarks should preserve active-buffer dirty-line markers");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Diagnostic_Error_Marker),
        "clear bookmarks should preserve active-buffer diagnostic markers");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (Editor.Buffers.Buffer_Id (1));
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
        "clear bookmarks must not affect inactive buffer bookmarks");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Dirty_Line_Marker),
        "clear bookmarks must preserve dirty-line markers");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Diagnostic_Error_Marker),
        "clear bookmarks must preserve diagnostic markers");
   end Test_Clear_Bookmarks_Active_Buffer_Only;

   procedure Test_Bookmark_Commands_Report_No_Bookmarks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");

      Editor.Executor.Bookmark_Commands.Execute_Next_Bookmark (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark: no bookmarks",
         "next bookmark with no bookmarks should report bookmark feedback");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Bookmark_Commands.Execute_Clear_Bookmarks (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "No bookmarks to clear",
         "clear bookmarks with no bookmarks should report deterministic feedback");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Bookmark_Commands.Execute_Clear_All_Bookmarks (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "No bookmarks to clear",
         "clear all bookmarks with no bookmarks should report deterministic feedback");
   end Test_Bookmark_Commands_Report_No_Bookmarks;

   procedure Test_Bookmark_Jump_Expands_Hidden_Fold
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S, "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF & "3");
      Editor.Folding.Add_Fold (S.Folding, 1, 3);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 2, Editor.Gutter_Markers.Bookmark_Marker);

      Editor.Executor.Bookmark_Commands.Execute_Next_Bookmark (S);

      Assert (not Editor.Folding.Is_Fold_Collapsed (S.Folding, 1),
              "bookmark jump should expand the fold hiding its target row");
      Assert (Editor.Executor.Safe_Caret (S) = Editor.State.Line_Start (S, 2),
              "bookmark jump inside a folded range should land on target row");
   end Test_Bookmark_Jump_Expands_Hidden_Fold;



   procedure Test_Bookmark_Toggle_Feedback_And_Stable_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Toggle_Bookmark) = "bookmarks.toggle",
         "toggle bookmark should expose the stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Next_Bookmark) = "bookmarks.next",
         "next bookmark should expose the stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Previous_Bookmark) = "bookmarks.previous",
         "previous bookmark should expose the stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Clear_Bookmarks) = "bookmarks.clear-buffer",
         "clear buffer bookmarks should expose the stable command name");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Clear_All_Bookmarks) = "bookmarks.clear-all",
         "clear all bookmarks should expose the stable command name");

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark added",
         "toggle bookmark should report deterministic add feedback");

      Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark (S);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark removed",
         "toggle bookmark should report deterministic remove feedback");
   end Test_Bookmark_Toggle_Feedback_And_Stable_Names;

   procedure Test_Bookmark_Navigation_Prunes_Stale_Bookmarks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "one" & ASCII.LF & "two");
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 20, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Bookmark_Commands.Execute_Next_Bookmark (S);
      Assert
        (not Editor.Gutter_Markers.Has_Bookmarks (S.Gutter_Markers),
         "bookmark navigation should prune out-of-range active-buffer bookmarks");
      Assert
        (Editor.Buffers.Global_Bookmark_Count = 0,
         "bookmark navigation should prune out-of-range registry bookmarks");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark: no bookmarks",
         "stale-only bookmark navigation should report no bookmarks after pruning");
   end Test_Bookmark_Navigation_Prunes_Stale_Bookmarks;


   procedure Test_Bookmark_Commands_On_Empty_Buffer_Are_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Found  : Boolean := False;
      Msg    : Editor.Messages.Editor_Message;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Before := Editor.Executor.Safe_Caret (S);

      Editor.Executor.Bookmark_Commands.Execute_Next_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Before,
              "next bookmark on an empty buffer must preserve the caret");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark: no bookmarks",
         "next bookmark on an empty buffer should report no bookmarks");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Bookmark_Commands.Execute_Previous_Bookmark (S);
      Assert (Editor.Executor.Safe_Caret (S) = Before,
              "previous bookmark on an empty buffer must preserve the caret");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert
        (Found and then To_String (Msg.Text) = "Bookmark: no bookmarks",
         "previous bookmark on an empty buffer should report no bookmarks");
   end Test_Bookmark_Commands_On_Empty_Buffer_Are_Safe;

   procedure Test_Bookmark_Toggle_And_Clear_Do_Not_Push_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");

      Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "toggle bookmark must not push navigation history");

      Editor.Executor.Bookmark_Commands.Execute_Clear_Bookmarks (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "clear buffer bookmarks must not push navigation history");

      Editor.Executor.Bookmark_Commands.Execute_Toggle_Bookmark (S);
      Editor.Executor.Bookmark_Commands.Execute_Clear_All_Bookmarks (S);
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "clear all bookmarks must not push navigation history");
   end Test_Bookmark_Toggle_And_Clear_Do_Not_Push_History;


   overriding procedure Register_Tests (T : in out Navigation_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Navigation_Boundaries_Are_No_Ops'Access,
         "navigation boundaries are no-ops");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Goto_Line_Jumps_And_Returns_To_Editor'Access,
         "Go To Line jumps and returns to editor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Goto_Line_Failure_Preserves_Cursor_Viewport'Access,
         "failed Go To Line preserves cursor and viewport");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Goto_Line_Does_Not_Mutate_Find_Or_Feature_Rows'Access,
         "Go To Line preserves find and Feature Panel separation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Goto_Line_Back_Forward_Routes_Through_Executor'Access,
         "Go To Line navigation history back forward");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Find_Navigation_Pushes_History_And_Back_Preserves_Query'Access,
         "find navigation history preserves query");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Typing_And_Save_Do_Not_Push_Navigation_History'Access,
         "typing and save do not push navigation history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Navigation_History_Clear_Command'Access,
         "navigation history clear command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Navigation_History_Clear_Descriptor'Access,
         "navigation history clear descriptor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Back_Invalid_Open_Target_Is_Atomic'Access,
         "failed back invalid open target is atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Back_To_Unopened_Stale_Line_Is_Partial_Success'Access,
         "back to unopened stale line is partial success");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reveal_Active_Selects_Known_Project_File'Access,
         "reveal active selects known project file");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Scope_Active_Directory_Selects_Active_File'Access,
         "scope active directory selects active file");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Buffer_Not_Known_Does_Not_Show_Quick_Open'Access,
         "active buffer not known does not show quick open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Reveal_And_Scope_Preserve_Priority'Access,
         "active reveal and scope preserve priority");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Stale_Quick_Open_Open_Failure_Preserves_State'Access,
         "stale quick open failure preserves state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Quick_Open_Accept_Records_Previous_Location'Access,
         "quick open accept records previous location");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Quick_Open_Stale_Failure_Does_Not_Record'Access,
         "quick open stale failure does not record");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Quick_Open_Captures_Execution_Time_Caret'Access,
         "quick open captures execution-time caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Search_Same_File_Line_Roundtrip'Access,
         "project search same-file line roundtrip");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Back_Forward_Capture_Moved_Current_Anchors'Access,
         "back forward capture moved current anchors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Forward_Stack_Clears_Only_On_Successful_New_Navigation'Access,
         "forward stack clears only on successful new navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Non_Recording_Selection_Commands_Preserve_History'Access,
         "non-recording selection commands preserve history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Toggle_Bookmark_At_Caret_And_Row'Access,
         "toggle bookmark at caret and row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Next_Previous_Bookmark_Navigation'Access,
         "next and previous bookmark navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Navigation_Empty_Preserves_Caret'Access,
         "bookmark empty navigation preserves caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Navigation_Across_Open_Buffers'Access,
         "bookmark navigation crosses open buffers and records history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_All_Bookmarks_Across_Open_Buffers'Access,
         "clear all bookmarks removes every open-buffer bookmark");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Bookmarks_Active_Buffer_Only'Access,
         "clear bookmarks active buffer only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Commands_Report_No_Bookmarks'Access,
         "bookmark commands report no bookmarks");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Jump_Expands_Hidden_Fold'Access,
         "bookmark jump expands hidden fold");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Toggle_Feedback_And_Stable_Names'Access,
         "bookmark stable names and feedback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Navigation_Prunes_Stale_Bookmarks'Access,
         "bookmark navigation prunes stale bookmarks");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Commands_On_Empty_Buffer_Are_Safe'Access,
         "bookmark commands handle empty buffers safely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Bookmark_Toggle_And_Clear_Do_Not_Push_History'Access,
         "bookmark toggle and clear do not push history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Buffer_Switcher_Accept_Switches_And_Pushes_History'Access,
         "buffer switcher accept switches and records history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Node_Action_Pushes_Navigation_History'Access,
         "File Tree row activation does not push navigation history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Recent_Previous_And_Next_Switch_Buffers'Access,
         "recent previous and next switch buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Recent_Traversal_Wraps_Three_Buffers'Access,
         "recent traversal wraps three buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Recent_Close_Removes_Target'Access,
         "recent close removes target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_New_Explicit_Navigation_After_Back_Clears_Forward'Access,
         "explicit navigation after back clears forward");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Buffer_Switcher_Failed_Accept_Preserves_State'Access,
         "buffer switcher failed accept preserves state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_New_Buffer_Seeds_Initial_Recent_Order'Access,
         "new buffer seeds initial recent order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Recent_Feedback_Is_Primary_Command_Message'Access,
         "recent feedback is primary command message");
   end Register_Tests;

end Editor.Executor.Navigation_Tests;
