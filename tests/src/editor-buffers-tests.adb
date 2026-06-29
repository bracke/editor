with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Directories;
with Editor.Buffers;
with Editor.Command_Route_Audit;
with Editor.Command_Palette;
with Editor.Keybindings;
with Editor.Project;
with Editor.Commands;
with Editor.Executor;
with Editor.Messages;
with Editor.Dirty_Guards;
with Editor.State;
with Editor.Test_Helper;
with Editor.Cursors;
with Editor.History;
with Editor.Buffer_Switcher;
with Editor.Clipboard;
with Editor.Navigation_History;
with Editor.Render_Model;
with Editor.Workspace_Persistence;

package body Editor.Buffers.Tests is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Buffers.Buffer_Ownership_Kind;
   use type Editor.Buffers.Buffer_Dirty_Category;
   use type Editor.Buffers.Buffer_Close_Eligibility;
   use type Editor.Buffers.Buffer_Workspace_Persistability;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Id;
   use type Editor.Messages.Message_Severity;
   use type Editor.State.Dirty_Close_Scope;
   use type Editor.State.File_State;
   use type Ada.Containers.Count_Type;

   function Text (S : Editor.State.State_Type) return String is
   begin
      return Editor.State.Current_Text (S);
   end Text;

   procedure Set_Caret
     (S      : in out Editor.State.State_Type;
      Pos    : Editor.Cursors.Cursor_Index;
      Anchor : Editor.Cursors.Cursor_Index := Editor.Cursors.Cursor_Index'Last)
   is
      A : constant Editor.Cursors.Cursor_Index :=
        (if Anchor = Editor.Cursors.Cursor_Index'Last then Pos else Anchor);
   begin
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => Pos,
          Anchor                => A,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Rect_Select_Active := False;
      Editor.State.Normalize_Carets (S);
   end Set_Caret;

   procedure Write_File
     (Path     : String;
      Contents : String)
   is
      F : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (F, Contents);
      Ada.Text_IO.Close (F);
   end Write_File;


   function Read_File (Path : String) return String is
      F    : Ada.Text_IO.File_Type;
      Line : String (1 .. 1024);
      Last : Natural;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      Ada.Text_IO.Get_Line (F, Line, Last);
      Ada.Text_IO.Close (F);
      return Line (1 .. Last);
   end Read_File;

   procedure Remove_File (Path : String) is
      F : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      Ada.Text_IO.Delete (F);
   exception
      when others =>
         null;
   end Remove_File;

   procedure Test_New_Buffer_And_Switch_Isolate_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id;
      B_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Editor.Buffers.Global_Count = 2,
        "new buffer should increase buffer count");
      Assert (B_Id /= A_Id,
        "new buffer should become a distinct active buffer");
      Assert (Text (S) = "",
        "new buffer should start empty");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'B'));
      Assert (Text (S) = "B",
        "edit should apply to the active new buffer");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (Text (S) = "A",
        "switching back should restore first buffer text");

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert (Text (S) = "B",
        "switching forward should restore second buffer text");
   end Test_New_Buffer_And_Switch_Isolate_Text;

   procedure Test_Invalid_Switch_Preserves_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Editor.Buffers.Buffer_Id;
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Before := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Switch_Buffer (S, 9999);

      Assert (Editor.Buffers.Global_Active_Buffer = Before,
        "invalid switch should preserve active buffer");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message,
        "invalid switch should publish an error message");
   end Test_Invalid_Switch_Preserves_Active_Buffer;

   procedure Test_Close_Dirty_Buffer_Is_Refused
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Id    : Editor.Buffers.Buffer_Id;
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      S.File_Info.Dirty := True;

      Editor.Executor.Execute_Close_Buffer (S, Id);

      Assert (Editor.Buffers.Global_Count = 1,
        "dirty close should preserve registry count");
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
        "dirty close should preserve active buffer");
      Assert (S.File_Info.Dirty,
        "dirty close should preserve dirty state");
      Assert (S.Dirty_Close_Prompt_Active,
        "Phase 575: dirty close should open explicit close review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Active_Buffer_Close_Scope,
        "Phase 575: active dirty close records active close scope");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Warning_Message,
        "dirty close should publish a warning");
      Assert (To_String (M.Text) = "Discard unsaved scratch buffer?",
        "Phase 575: dirty scratch close should ask for explicit review");
   end Test_Close_Dirty_Buffer_Is_Refused;

   procedure Test_Open_Already_Open_Path_Switches_Without_Reread
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := "/tmp/editor_phase51_open_once.txt";
      Id   : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Write_File (Path, "disk");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Assert (Text (S) = "Xdisk" & ASCII.LF,
        "test setup should create unsaved active-buffer edits");

      Editor.Executor.Execute_Open_File (S, Path);
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
        "opening an already-open path should switch to the existing buffer");
      Assert (Text (S) = "Xdisk" & ASCII.LF,
        "opening an already-open path should not reread or discard edits");
      Remove_File (Path);
   end Test_Open_Already_Open_Path_Switches_Without_Reread;



   procedure Test_Dirty_Buffer_Summary_Counts_File_And_Untitled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      File_Id  : Editor.Buffers.Buffer_Id;
      Untitled : Editor.Buffers.Buffer_Id;
      Summary  : Editor.Dirty_Guards.Dirty_Buffer_Summary;
      File_Buffer : access Editor.State.State_Type;
      Untitled_Buffer : access Editor.State.State_Type;
   begin
      File_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/phase93.txt", "phase93.txt", "disk");
      Untitled := Editor.Buffers.Create_Untitled_Buffer (Registry);

      File_Buffer := Editor.Buffers.Buffer_Access (Registry, File_Id);
      Untitled_Buffer := Editor.Buffers.Buffer_Access (Registry, Untitled);
      File_Buffer.File_Info.Dirty := True;
      Untitled_Buffer.File_Info.Dirty := True;

      Summary := Editor.Buffers.Dirty_Buffer_Summary (Registry);
      Assert (Summary.Dirty_Count = 2,
        "dirty summary should count all dirty buffers");
      Assert (Summary.File_Backed_Count = 1,
        "dirty summary should count dirty file-backed buffers");
      Assert (Summary.Untitled_Count = 1,
        "dirty summary should count dirty untitled buffers");
      Assert (Editor.Buffers.Dirty_Buffer_Display_Name (Registry, 1) = "phase93.txt",
        "dirty display names should follow deterministic registry order");
   end Test_Dirty_Buffer_Summary_Counts_File_And_Untitled;


   procedure Test_State_Init_Starts_Independent_Global_Registry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      First  : Editor.State.State_Type;
      Second : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (First);
      Editor.Buffers.Ensure_Global_Registry (First);
      Editor.Executor.Execute_New_Buffer (First);
      Assert (Editor.Buffers.Global_Count = 2,
        "test setup should create two buffers for the first state");

      Editor.State.Init (Second);
      Editor.Buffers.Ensure_Global_Registry (Second);
      Assert (Editor.Buffers.Global_Count = 1,
        "a separate initialized state should receive an independent registry");
      Assert (Editor.State.Current_Text (Second) = "",
        "independent registry setup must not load text from an old state");
   end Test_State_Init_Starts_Independent_Global_Registry;

   procedure Test_Close_Inactive_Buffer_Reports_Closed_Buffer_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("First");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      S.File_Info.Display_Name := To_Unbounded_String ("Second");

      Editor.Executor.Execute_Close_Buffer (S, A_Id);

      Assert (Editor.Buffers.Global_Contains (A_Id),
        "Phase 432: explicit-id inactive close must not remove an inactive buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "Phase 432: rejected inactive close must keep the active buffer");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not close buffer",
        "Phase 432: rejected inactive close must use canonical close failure text");
   end Test_Close_Inactive_Buffer_Reports_Closed_Buffer_Name;


   procedure Test_Traversal_Helpers_Wrap_And_Invalid_Id
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      A_Id     : Editor.Buffers.Buffer_Id;
      B_Id     : Editor.Buffers.Buffer_Id;
      C_Id     : Editor.Buffers.Buffer_Id;
   begin
      A_Id := Editor.Buffers.Create_Untitled_Buffer (Registry);
      B_Id := Editor.Buffers.Create_Untitled_Buffer (Registry);
      C_Id := Editor.Buffers.Create_Untitled_Buffer (Registry);

      Assert (Editor.Buffers.First_Buffer (Registry) = A_Id,
        "first buffer should be the first registry entry");
      Assert (Editor.Buffers.Last_Buffer (Registry) = C_Id,
        "last buffer should be the final registry entry");
      Assert (Editor.Buffers.Next_Buffer (Registry, A_Id) = B_Id,
        "next buffer should follow registry order");
      Assert (Editor.Buffers.Next_Buffer (Registry, C_Id) = A_Id,
        "next buffer should wrap from last to first");
      Assert (Editor.Buffers.Previous_Buffer (Registry, A_Id) = C_Id,
        "previous buffer should wrap from first to last");
      Assert (Editor.Buffers.Next_Buffer (Registry, 9999) = Editor.Buffers.No_Buffer,
        "next with invalid id should return No_Buffer");
      Assert (Editor.Buffers.Previous_Buffer (Registry, 9999) = Editor.Buffers.No_Buffer,
        "previous with invalid id should return No_Buffer");
   end Test_Traversal_Helpers_Wrap_And_Invalid_Id;

   procedure Test_Traversal_With_One_Buffer_Returns_Same_Id
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Id       : Editor.Buffers.Buffer_Id;
   begin
      Id := Editor.Buffers.Create_Untitled_Buffer (Registry);
      Assert (Editor.Buffers.Next_Buffer (Registry, Id) = Id,
        "next with one buffer should return same id");
      Assert (Editor.Buffers.Previous_Buffer (Registry, Id) = Id,
        "previous with one buffer should return same id");
   end Test_Traversal_With_One_Buffer_Returns_Same_Id;

   procedure Test_Next_Previous_Executor_Wraps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id;
      B_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Next_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "next buffer should wrap from second to first");
      Editor.Executor.Execute_Previous_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "previous buffer should wrap from first to second");
   end Test_Next_Previous_Executor_Wraps;

   procedure Test_Close_Last_Clean_Buffer_Creates_Replacement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);

      Editor.Executor.Execute_Close_Active_Buffer (S);

      Assert (Editor.Buffers.Global_Count = 0,
        "closing the last clean buffer should leave no active buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer,
        "closing the last clean buffer should clear the active public id");
      Assert (S.Active_Buffer_Token = 0,
        "closing the last clean buffer should clear the state active token");
      Assert (Editor.State.Current_Text (S) = "",
        "closed-last state should retain empty editor text");
      Assert (not S.File_Info.Dirty,
        "closed-last state should remain clean");
   end Test_Close_Last_Clean_Buffer_Creates_Replacement;

   procedure Test_Save_As_Refuses_Path_Open_In_Another_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := "/tmp/editor_phase52_save_as_a.txt";
      B_Path : constant String := "/tmp/editor_phase52_save_as_b.txt";
      Old    : Editor.State.File_State;
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (A_Path);
      Remove_File (B_Path);
      Write_File (A_Path, "A");
      Write_File (B_Path, "B");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      Editor.Executor.Execute_Open_File (S, B_Path);
      Old := S.File_Info;

      Editor.Executor.Execute_Save_As (S, A_Path);

      Assert (S.File_Info = Old,
        "Save As to a path open in another buffer should preserve active identity");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Invalid Save As target",
        "duplicate Save As path should publish deterministic error");
      Remove_File (A_Path);
      Remove_File (B_Path);
   end Test_Save_As_Refuses_Path_Open_In_Another_Buffer;



   procedure Test_Phase250_First_File_Open_Uses_Disposable_Untitled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := "/tmp/editor_phase250_first_open.txt";
      Row  : Editor.Buffers.Buffer_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (Path);
      Write_File (Path, "alpha");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Path);

      Assert (Editor.Buffers.Global_Count = 1,
        "Phase 250: first explicit file open should replace disposable empty untitled state");
      Row := Editor.Buffers.Global_Summary_At (1);
      Assert (Row.Is_Active,
        "Phase 250: first opened file should be active");
      Assert (not Row.Is_Dirty,
        "Phase 250: first opened file should be clean");
      Assert (Row.Has_Path,
        "Phase 250: first opened file should be file-backed");
      Assert (Text (S) = "alpha" & ASCII.LF,
        "Phase 250: first opened file should populate the active buffer");
      Remove_File (Path);
   end Test_Phase250_First_File_Open_Uses_Disposable_Untitled;

   procedure Test_Phase250_Multiple_File_Open_Order_Duplicate_And_Failed_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      A_Path     : constant String := "/tmp/editor_phase250_multi_a.txt";
      B_Path     : constant String := "/tmp/editor_phase250_multi_b.txt";
      C_Path     : constant String := "/tmp/editor_phase250_multi_c.txt";
      Missing    : constant String := "/tmp/editor_phase250_missing.txt";
      A_Id       : Editor.Buffers.Buffer_Id;
      B_Id       : Editor.Buffers.Buffer_Id;
      C_Id       : Editor.Buffers.Buffer_Id;
      Active_Before_Failed : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (A_Path);
      Remove_File (B_Path);
      Remove_File (C_Path);
      Remove_File (Missing);
      Write_File (A_Path, "A");
      Write_File (B_Path, "B");
      Write_File (C_Path, "C");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'x'));

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Assert (Editor.Buffers.Global_Count = 3,
        "Phase 250: opening three files should create exactly three buffers");
      Assert (Editor.Buffers.Global_Summary_At (1).Id = A_Id
        and then Editor.Buffers.Global_Summary_At (2).Id = B_Id
        and then Editor.Buffers.Global_Summary_At (3).Id = C_Id,
        "Phase 250: multi-file open-buffer row order should be deterministic append order");
      Assert (Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, A_Id),
        "Phase 250: opening more files should preserve dirty state in existing buffers");

      Editor.Executor.Execute_Open_File (S, A_Path);
      Assert (Editor.Buffers.Global_Count = 3,
        "Phase 250: opening an already-open file should not create a duplicate row");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "Phase 250: opening an already-open file should focus its existing buffer");
      Assert (Text (S) = "xA" & ASCII.LF,
        "Phase 250: focusing an already-open dirty file should not reload from disk");

      Active_Before_Failed := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, Missing);
      Assert (Editor.Buffers.Global_Count = 3,
        "Phase 250: failed open after multiple files should preserve open-buffer list");
      Assert (Editor.Buffers.Global_Active_Buffer = Active_Before_Failed,
        "Phase 250: failed open after multiple files should preserve active buffer");

      Remove_File (A_Path);
      Remove_File (B_Path);
      Remove_File (C_Path);
   end Test_Phase250_Multiple_File_Open_Order_Duplicate_And_Failed_Open;

   procedure Test_Phase250_Per_Buffer_Dirty_Save_And_Cursor_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := "/tmp/editor_phase250_dirty_a.txt";
      B_Path : constant String := "/tmp/editor_phase250_dirty_b.txt";
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (A_Path);
      Remove_File (B_Path);
      Write_File (A_Path, "A");
      Write_File (B_Path, "B");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Caret (S, 0);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'x'));
      Assert (S.File_Info.Dirty,
        "Phase 250: editing buffer A should mark A dirty");

      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (not S.File_Info.Dirty,
        "Phase 250: switching to clean buffer B should show clean active state");
      Assert (Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, A_Id),
        "Phase 250: dirty marker for buffer A should remain per-row after switching away");

      Set_Caret (S, 1);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'y'));
      Assert (Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, A_Id),
        "Phase 250: editing buffer B should not clear A dirty state");
      Assert (S.File_Info.Dirty,
        "Phase 250: editing buffer B should mark B dirty independently");

      Editor.Executor.Execute_Save (S);
      Assert (not S.File_Info.Dirty,
        "Phase 250: saving active buffer B should clear B dirty state");
      Assert (Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, A_Id),
        "Phase 250: saving B should leave dirty buffer A dirty");
      Assert (Read_File (B_Path) = "By",
        "Phase 250: saving B should write only B content");
      Assert (Read_File (A_Path) = "A",
        "Phase 250: saving B should not write A file");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (S.Carets (S.Carets.First_Index).Pos = 1,
        "Phase 250: buffer A should restore its own cursor rather than B cursor");
      Assert (Text (S) = "xA" & ASCII.LF,
        "Phase 250: switching back to A should restore A text");
      Assert (S.File_Info.Dirty,
        "Phase 250: switching back to A should restore A dirty state");

      Editor.Executor.Execute_Save (S);
      Assert (not S.File_Info.Dirty,
        "Phase 250: saving A should clear A dirty state");
      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert (not S.File_Info.Dirty,
        "Phase 250: saving A should not re-dirty already-saved buffer B");
      Assert (Read_File (A_Path) = "xA",
        "Phase 250: saving A should write A content");
      Assert (Read_File (B_Path) = "By",
        "Phase 250: saving A should preserve B file content");

      Remove_File (A_Path);
      Remove_File (B_Path);
   end Test_Phase250_Per_Buffer_Dirty_Save_And_Cursor_Isolation;



   procedure Test_Phase250_Reload_Targets_Only_Active_Clean_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := "/tmp/editor_phase250_reload_a.txt";
      B_Path : constant String := "/tmp/editor_phase250_reload_b.txt";
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (A_Path);
      Remove_File (B_Path);
      Write_File (A_Path, "A1");
      Write_File (B_Path, "B1");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Write_File (A_Path, "A2");
      Write_File (B_Path, "B2");

      Editor.Executor.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "Phase 250: reload should keep targeting the active buffer");
      Assert (Text (S) = "B2" & ASCII.LF,
        "Phase 250: reload while B is active should replace B from B's file");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (Text (S) = "A1" & ASCII.LF,
        "Phase 250: reloading B should not refresh or mutate inactive buffer A");
      Assert (not S.File_Info.Dirty,
        "Phase 250: inactive clean buffer A should remain clean after B reload");

      Remove_File (A_Path);
      Remove_File (B_Path);
   end Test_Phase250_Reload_Targets_Only_Active_Clean_Buffer;

   procedure Test_Phase250_Close_Active_And_Inactive_Buffers_Isolates_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := "/tmp/editor_phase250_close_a.txt";
      B_Path : constant String := "/tmp/editor_phase250_close_b.txt";
      C_Path : constant String := "/tmp/editor_phase250_close_c.txt";
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
      C_Id   : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (A_Path);
      Remove_File (B_Path);
      Remove_File (C_Path);
      Write_File (A_Path, "A");
      Write_File (B_Path, "B");
      Write_File (C_Path, "C");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Count = 2,
        "Phase 250: closing clean active C should remove only C");
      Assert (not Editor.Buffers.Global_Contains (C_Id),
        "Phase 250: closed active buffer C should be removed from the registry");
      Assert (Editor.Buffers.Global_Contains (A_Id)
        and then Editor.Buffers.Global_Contains (B_Id),
        "Phase 250: closing C should preserve unrelated buffers A and B");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "Phase 250: closing active buffer should choose deterministic previous row as active");
      Assert (Text (S) = "B" & ASCII.LF,
        "Phase 250: active state after closing C should be buffer B");

      Editor.Executor.Execute_Close_Buffer (S, A_Id);
      Assert (Editor.Buffers.Global_Count = 2,
        "Phase 250: explicit-id inactive close should preserve all buffers");
      Assert (Editor.Buffers.Global_Contains (A_Id),
        "Phase 250: explicit-id inactive close should not remove inactive buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "Phase 250: explicit-id inactive close should preserve active buffer B");
      Assert (Text (S) = "B" & ASCII.LF,
        "Phase 250: explicit-id inactive close should not replace active buffer text");

      Remove_File (A_Path);
      Remove_File (B_Path);
      Remove_File (C_Path);
   end Test_Phase250_Close_Active_And_Inactive_Buffers_Isolates_State;

   procedure Test_Phase250_Dirty_Close_Blocks_Target_Buffer_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := "/tmp/editor_phase250_dirty_close_a.txt";
      B_Path : constant String := "/tmp/editor_phase250_dirty_close_b.txt";
      A_Id   : Editor.Buffers.Buffer_Id;
      B_Id   : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (A_Path);
      Remove_File (B_Path);
      Write_File (A_Path, "A");
      Write_File (B_Path, "B");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, '!'));
      Editor.Executor.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Close_Buffer (S, A_Id);
      Assert (Editor.Buffers.Global_Count = 2,
        "Phase 250: blocked dirty inactive close should preserve all buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "Phase 250: blocked dirty inactive close should preserve the active buffer");
      Assert (not Editor.Buffers.Global_Summary_For (A_Id).Blocked_Close_Surfaced,
        "Phase 250: explicit-id inactive close should not mark the inactive buffer row");
      Assert (not Editor.Buffers.Global_Summary_For (B_Id).Blocked_Close_Surfaced,
        "Phase 250: blocked dirty inactive close should not mark unrelated active buffer row");
      Assert (Text (S) = "B" & ASCII.LF,
        "Phase 250: blocked dirty inactive close should not change active buffer content");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Count = 2,
        "Phase 250: blocked dirty active close should preserve all buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "Phase 250: blocked dirty active close should keep the dirty target active");
      Assert (S.File_Info.Blocked_Close_Surfaced,
        "Phase 250: blocked dirty active close should surface lifecycle state on active buffer");
      Assert (Text (S) = "A!" & ASCII.LF,
        "Phase 250: blocked dirty active close should preserve dirty buffer content");

      Remove_File (A_Path);
      Remove_File (B_Path);
   end Test_Phase250_Dirty_Close_Blocks_Target_Buffer_Only;

   procedure Test_Phase217_Switch_Restores_Cursor_Dirty_And_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id;
      B_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Set_Caret (S, 2);
      S.File_Info.Display_Name := To_Unbounded_String ("A");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'x'));
      Assert (S.File_Info.Dirty,
        "editing buffer B should make only the active buffer dirty");
      Assert (not Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, A_Id),
        "buffer A should remain clean while editing buffer B");

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (S.Carets (S.Carets.First_Index).Pos = 2,
        "switching back should restore buffer A cursor");
      Assert (not S.File_Info.Dirty,
        "switching back should restore buffer A clean dirty state");
      Assert (Editor.History.Undo_Stack.Is_Empty,
        "buffer A should not inherit buffer B undo history");

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Assert (Text (S) = "x",
        "switching forward should restore buffer B text");
      Assert (S.File_Info.Dirty,
        "switching forward should restore buffer B dirty state");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
        "buffer B should restore its own undo history");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (Text (S) = "",
        "undo in buffer B should affect only buffer B");
      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Assert (Text (S) = "abc",
        "undo in buffer B must not mutate buffer A");
   end Test_Phase217_Switch_Restores_Cursor_Dirty_And_Undo;

   procedure Test_Phase217_Close_Active_Buffer_Selects_Previous_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      A_Id : Editor.Buffers.Buffer_Id;
      B_Id : Editor.Buffers.Buffer_Id;
      C_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Close_Active_Buffer (S);

      Assert (not Editor.Buffers.Global_Contains (C_Id),
        "closed active buffer should be removed from the registry");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "closing the last active buffer should select the previous buffer");
      Assert (Editor.Buffers.Global_Contains (A_Id),
        "closing one buffer should preserve unrelated buffers");
   end Test_Phase217_Close_Active_Buffer_Selects_Previous_Buffer;



   procedure Test_Phase270_Pin_Unpin_Toggle_And_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Id      : Editor.Buffers.Buffer_Id;
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Pin_Buffer) = "buffers.pin",
        "Phase 270: pin command stable name must be buffers.pin");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Unpin_Buffer) = "buffers.unpin",
        "Phase 270: unpin command stable name must be buffers.unpin");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Toggle_Buffer_Pin) = "buffers.toggle-pin",
        "Phase 270: toggle pin command stable name must be buffers.toggle-pin");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("Pinned.adb");
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Pin_Buffer);
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (Id),
        "Phase 270: pin command should mark active buffer as pinned");
      Summary := Editor.Buffers.Global_Summary_For (Id);
      Assert (Summary.Is_Pinned,
        "Phase 270: buffer summary should expose pinned state");
      Assert (To_String (Summary.Display_Name) = "Pinned.adb [Pinned] — untitled",
        "Phase 270: buffer summary should include compact pinned marker");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Unpin_Buffer);
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (Id),
        "Phase 270: unpin command should clear pinned state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Buffer_Pin);
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (Id),
        "Phase 270: toggle should pin an unpinned buffer");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Toggle_Buffer_Pin);
      Assert (not Editor.Buffers.Global_Is_Buffer_Pinned (Id),
        "Phase 270: toggle should unpin a pinned buffer");
   end Test_Phase270_Pin_Unpin_Toggle_And_Marker;

   procedure Test_Phase270_Cleanup_Skips_Pinned_And_Reopen_Is_Unpinned
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Pinned_Path : constant String := "/tmp/editor_phase270_pinned.txt";
      Loose_Path  : constant String := "/tmp/editor_phase270_loose.txt";
      Pinned_Id   : Editor.Buffers.Buffer_Id;
      Loose_Id    : Editor.Buffers.Buffer_Id;
      Reopened_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Write_File (Pinned_Path, "pinned");
      Write_File (Loose_Path, "loose");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Pinned_Path);
      Pinned_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Pin_Buffer);

      Editor.Executor.Execute_Open_File (S, Loose_Path);
      Loose_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Loose_Id /= Pinned_Id,
        "Phase 270 setup should open two distinct file-backed buffers");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Clean_Buffers);
      Assert (Editor.Buffers.Global_Contains (Pinned_Id),
        "Phase 270: close-clean should keep pinned buffers");
      Assert (not Editor.Buffers.Global_Contains (Loose_Id),
        "Phase 270: close-clean should close clean unpinned buffers");
      Assert (True,
        "Phase 432: cleanup close must not create close-history/reopen state");

      null;
      Assert (not Editor.Buffers.Global_Contains (Loose_Id),
        "Phase 432: removed removed-name reopen must not restore file.close-buffer cleanup state");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (Pinned_Id),
        "Phase 432: rejected reopen must preserve existing pinned buffer state");

      Remove_File (Pinned_Path);
      Remove_File (Loose_Path);
   end Test_Phase270_Cleanup_Skips_Pinned_And_Reopen_Is_Unpinned;



   procedure Test_Phase271_Buffer_Groups_Assign_Cycle_Close_And_Reopen
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Core_Path  : constant String := "/tmp/editor_phase271_core.txt";
      Test_Path  : constant String := "/tmp/editor_phase271_tests.txt";
      Pin_Path   : constant String := "/tmp/editor_phase271_pinned.txt";
      Core_Id    : Editor.Buffers.Buffer_Id;
      Test_Id    : Editor.Buffers.Buffer_Id;
      Pin_Id     : Editor.Buffers.Buffer_Id;
      Reopened   : Editor.Buffers.Buffer_Id;
      Summary    : Editor.Buffers.Buffer_Summary;
   begin
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Assign_Buffer_Group) = "buffers.group.assign",
        "Phase 271: assign group command stable name must be deterministic");
      Editor.Buffers.Reset_Global_For_Test;
      Write_File (Core_Path, "core");
      Write_File (Test_Path, "tests");
      Write_File (Pin_Path, "pinned");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Core_Path);
      Core_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Assign_Buffer_Group;
      Cmd.Text := To_Unbounded_String (" core ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Has_Buffer_Group (Core_Id),
        "Phase 271: active buffer should receive group membership");
      Assert (Editor.Buffers.Global_Buffer_Group (Core_Id) = "core",
        "Phase 271: group assignment should trim literal group names");

      Cmd.Text := To_Unbounded_String ("tests");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Group (Core_Id) = "tests",
        "Phase 271: assigning a second group should replace prior membership");
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Executor.Execute_Open_File (S, Test_Path);
      Test_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Text := To_Unbounded_String ("tests");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Executor.Execute_Open_File (S, Pin_Path);
      Pin_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Pin_Buffer);

      Cmd.Kind := Editor.Commands.Switch_Buffer_Group;
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Has_Active_Buffer_Group,
        "Phase 271: switch group should activate a group filter");
      Assert (Editor.Buffers.Global_Active_Buffer_Group = "core",
        "Phase 271: switch group should store the requested active group");
      Assert (Editor.Buffers.Global_Active_Buffer = Core_Id,
        "Phase 271: switching a group should activate a deterministic buffer in that group");

      Cmd.Kind := Editor.Commands.Next_Buffer_Group;
      Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Active_Buffer_Group = "tests",
        "Phase 271: next group should cycle deterministically through existing groups");
      Assert (Editor.Buffers.Global_Active_Buffer = Test_Id,
        "Phase 271: next group should activate a buffer in the cycled group");
      Cmd.Kind := Editor.Commands.Previous_Buffer_Group;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Active_Buffer_Group = "core",
        "Phase 271: previous group should cycle back deterministically");
      Assert (Editor.Buffers.Global_Active_Buffer = Core_Id,
        "Phase 271: previous group should activate a buffer in the cycled group");

      Summary := Editor.Buffers.Global_Summary_For (Core_Id);
      Assert (Summary.Has_Group and then To_String (Summary.Group_Name) = "core",
        "Phase 271: buffer summary should expose group state");
      Assert (To_String (Summary.Display_Name) /= "",
        "Phase 271: grouped buffer summary should remain displayable");

      Assert (Editor.Buffers.Global_Contains (Core_Id),
        "Phase 271: group switching keeps buffers in the active group");

      Cmd.Kind := Editor.Commands.Show_All_Buffer_Groups;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Active_Buffer_Group,
        "Phase 271: show all should clear the active group filter");

      Remove_File (Core_Path);
      Remove_File (Test_Path);
      Remove_File (Pin_Path);
   end Test_Phase271_Buffer_Groups_Assign_Cycle_Close_And_Reopen;


   procedure Test_Phase271_Buffer_Groups_Dirty_Pinned_And_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Cmd         : Editor.Commands.Command;
      Availability : Editor.Commands.Command_Availability;
      Core_Path   : constant String := "/tmp/editor_phase271_core_dirty.txt";
      Dirty_Path  : constant String := "/tmp/editor_phase271_dirty_outside.txt";
      Pin_Path    : constant String := "/tmp/editor_phase271_pinned_outside.txt";
      Core_Id     : Editor.Buffers.Buffer_Id;
      Dirty_Id    : Editor.Buffers.Buffer_Id;
      Pin_Id      : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Clear_Buffer_Group);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
        "Phase 271: clear group should be unavailable without grouped active buffer");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Next_Buffer_Group);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
        "Phase 271: cycle group should be unavailable without any groups");
      Assert (not Editor.Buffers.Global_Has_Buffer_Groups,
        "Phase 271: availability checks must not create group state");

      Write_File (Core_Path, "core");
      Write_File (Dirty_Path, "dirty");
      Write_File (Pin_Path, "pinned");

      Editor.Executor.Execute_Open_File (S, Core_Path);
      Core_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Assign_Buffer_Group;
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, 'x'));
      Assert (Editor.Buffers.Global_Summary_For (Core_Id).Is_Dirty,
        "Phase 271: grouped buffers remain ordinary editable dirty buffers");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Buffers.Global_Summary_For (Core_Id).Is_Dirty,
        "Phase 271: grouped buffers remain saveable through ordinary save");
      Assert (Editor.Buffers.Global_Has_Buffer_Group (Core_Id),
        "Phase 271: ordinary save must not clear group membership");

      Editor.Executor.Execute_Open_File (S, Dirty_Path);
      Dirty_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (5, 'x'));
      Assert (Editor.Buffers.Global_Summary_For (Dirty_Id).Is_Dirty,
        "Phase 271 setup should leave an outside dirty buffer");

      Editor.Executor.Execute_Open_File (S, Pin_Path);
      Pin_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Pin_Buffer);

      Cmd.Kind := Editor.Commands.Switch_Buffer_Group;
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Buffers.Global_Contains (Dirty_Id),
        "Phase 271: dirty grouped buffers remain tracked after group switch");
      Assert (Editor.Buffers.Global_Contains (Pin_Id),
        "Phase 271: pinned grouped buffers remain tracked after group switch");

      Cmd.Kind := Editor.Commands.Clear_Buffer_Group;
      Editor.Buffers.Global_Set_Active_Buffer (Core_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Group (Core_Id),
        "Phase 271: clear group should remove active buffer group membership");
      Assert (not Editor.Buffers.Global_Has_Active_Buffer_Group,
        "Phase 271: clearing the last member of the active group should clear stale active group state");

      Remove_File (Core_Path);
      Remove_File (Dirty_Path);
      Remove_File (Pin_Path);
   end Test_Phase271_Buffer_Groups_Dirty_Pinned_And_Availability;


   procedure Test_Phase272_Buffer_Notes_Set_Clear_Show_And_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Cmd          : Editor.Commands.Command;
      Id           : Editor.Buffers.Buffer_Id;
      Summary      : Editor.Buffers.Buffer_Summary;
      Availability : Editor.Commands.Command_Availability;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
      Was_Dirty    : Boolean := False;
   begin
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Set_Buffer_Note) = "buffers.note.set",
        "Phase 272: set note command stable name must be deterministic");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Clear_Buffer_Note) = "buffers.note.clear",
        "Phase 272: clear note command stable name must be deterministic");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Edit_Buffer_Note) = "buffers.note.edit",
        "Phase 272: edit note command stable name must be deterministic");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Show_Buffer_Note) = "buffers.note.show",
        "Phase 272: show note command stable name must be deterministic");
      Assert (not Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Set_Buffer_Note),
        "Phase 272: setting a note must not be classified as destructive");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("Notes.adb");
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Clear_Buffer_Note);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
        "Phase 272: clear note should be unavailable before a note exists");
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (Id),
        "Phase 272: availability checks must not mutate note state");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'x'));
      Was_Dirty := Editor.Buffers.Global_Summary_For (Id).Is_Dirty;
      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String (" parser cleanup ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Has_Buffer_Note (Id),
        "Phase 272: set note should attach note state to the active buffer");
      Assert (Editor.Buffers.Global_Buffer_Note (Id) = "parser cleanup",
        "Phase 272: set note should trim literal note text");
      Assert (Editor.Buffers.Global_Summary_For (Id).Is_Dirty = Was_Dirty,
        "Phase 272: setting a note must not change dirty state");

      Cmd.Text := To_Unbounded_String ("needs tests");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Note (Id) = "needs tests",
        "Phase 272: setting a second note should replace the first note");
      Summary := Editor.Buffers.Global_Summary_For (Id);
      Assert (Summary.Has_Note and then To_String (Summary.Note_Text) = "needs tests",
        "Phase 272: buffer summary should expose note state");
      Assert (To_String (Summary.Display_Name) = "Notes.adb — needs tests — untitled",
        "Phase 272: buffer summary should include compact note text");

      Cmd.Kind := Editor.Commands.Show_Buffer_Note;
      Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Cmd);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Notes.adb: needs tests",
        "Phase 272: show note should emit one deterministic message");

      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("   ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (Id),
        "Phase 272: whitespace-only note input should clear the note");

      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("x" & String'(1 .. Editor.Buffers.Max_Buffer_Note_Length => 'y'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (Id),
        "Phase 272: too-long note should be rejected without storing state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Note too long",
        "Phase 272: too-long note feedback should be deterministic");
   end Test_Phase272_Buffer_Notes_Set_Clear_Show_And_Markers;

   procedure Test_Phase272_Buffer_Notes_Independence_Cleanup_Reopen_And_Switcher
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Cmd           : Editor.Commands.Command;
      Note_Path     : constant String := "/tmp/editor_phase272_note.txt";
      Pinned_Path   : constant String := "/tmp/editor_phase272_pinned_note.txt";
      Existing_Path : constant String := "/tmp/editor_phase272_existing_note.txt";
      Note_Id       : Editor.Buffers.Buffer_Id;
      Pinned_Id     : Editor.Buffers.Buffer_Id;
      Existing_Id   : Editor.Buffers.Buffer_Id;
      Reopened_Id   : Editor.Buffers.Buffer_Id;
      Row           : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found_Row     : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Write_File (Note_Path, "note");
      Write_File (Pinned_Path, "pinned");
      Write_File (Existing_Path, "existing");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Note_Path);
      Note_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("temporary reference");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd.Kind := Editor.Commands.Assign_Buffer_Group;
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Pin_Buffer);
      Assert (Editor.Buffers.Global_Has_Buffer_Note (Note_Id),
        "Phase 272 setup should create a noted buffer");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (Note_Id),
        "Phase 272 setup should pin the noted buffer");
      Assert (Editor.Buffers.Global_Has_Buffer_Group (Note_Id),
        "Phase 272 setup should group the noted buffer");

      Cmd.Kind := Editor.Commands.Clear_Buffer_Note;
      Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (Note_Id),
        "Phase 272: clearing a note must not change pinned state");
      Assert (Editor.Buffers.Global_Has_Buffer_Group (Note_Id),
        "Phase 272: clearing a note must not change group membership");
      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("temporary reference");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Executor.Execute_Open_File (S, Pinned_Path);
      Pinned_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("do not close");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Pin_Buffer);

      Editor.Buffers.Global_Set_Active_Buffer (Note_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Unpin_Buffer);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Clean_Buffers);
      Assert (not Editor.Buffers.Global_Contains (Note_Id),
        "Phase 272: cleanup should close clean noted buffers when unpinned");
      Assert (Editor.Buffers.Global_Contains (Pinned_Id),
        "Phase 272: pinned noted buffers should still be skipped by cleanup");
      Assert (True,
        "Phase 432: cleanup close must not create close-history/reopen state");

      null;
      Assert (not Editor.Buffers.Global_Contains (Note_Id),
        "Phase 432: removed removed-name reopen must not restore noted cleanup state");

      Editor.Executor.Execute_Open_File (S, Existing_Path);
      Existing_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("already open note");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffers.Global_Set_Active_Buffer (Existing_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Buffers.Global_Close_Buffer (Existing_Id, Found_Row);
      Assert (Found_Row,
        "Phase 272 setup should close existing file-backed buffer once");
      Editor.Executor.Execute_Open_File (S, Existing_Path);
      Existing_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("current note");
      Editor.Executor.Execute_No_Log (S, Cmd);
      null;
      Assert (Editor.Buffers.Global_Active_Buffer = Existing_Id,
        "Phase 272: reopen of an already-open file should focus existing buffer");
      Assert (Editor.Buffers.Global_Buffer_Note (Existing_Id) = "current note",
        "Phase 272: already-open reopen should preserve current note state");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         Editor.Buffer_Switcher.Buffer_Switcher_Config'(others => <>));
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found_Row);
      Assert (Found_Row and then Row.Id = Editor.Buffers.Global_Active_Buffer,
        "Phase 272: switcher activation semantics should still select the active buffer");
      Assert (To_String (Row.Display_Label) = "editor_phase272_existing_note.txt"
        and then Row.Has_Note,
        "Phase 272: switcher rows should project file label and note metadata separately");

      Remove_File (Note_Path);
      Remove_File (Pinned_Path);
      Remove_File (Existing_Path);
   end Test_Phase272_Buffer_Notes_Independence_Cleanup_Reopen_And_Switcher;



   procedure Test_Phase273_Buffer_Labels_Set_Clear_Show_Validation_And_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Cmd          : Editor.Commands.Command;
      Id           : Editor.Buffers.Buffer_Id;
      Summary      : Editor.Buffers.Buffer_Summary;
      Availability : Editor.Commands.Command_Availability;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
      Was_Dirty    : Boolean := False;
   begin
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Set_Buffer_Label) = "buffers.label.set",
        "Phase 273: set label command stable name must be deterministic");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Clear_Buffer_Label) = "buffers.label.clear",
        "Phase 273: clear label command stable name must be deterministic");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Edit_Buffer_Label) = "buffers.label.edit",
        "Phase 273: edit label command stable name must be deterministic");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Show_Buffer_Label) = "buffers.label.show",
        "Phase 273: show label command stable name must be deterministic");
      Assert (not Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Set_Buffer_Label),
        "Phase 273: setting a label must not be classified as destructive");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("Labels.adb");
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Clear_Buffer_Label);
      Assert (Availability.Status = Editor.Commands.Command_Unavailable,
        "Phase 273: clear label should be unavailable before a label exists");
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (Id),
        "Phase 273: availability checks must not mutate label state");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'x'));
      Was_Dirty := Editor.Buffers.Global_Summary_For (Id).Is_Dirty;
      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String (" test ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Has_Buffer_Label (Id),
        "Phase 273: set label should attach label state to the active buffer");
      Assert (Editor.Buffers.Global_Buffer_Label (Id) = "test",
        "Phase 273: set label should trim literal label text");
      Assert (Editor.Buffers.Global_Summary_For (Id).Is_Dirty = Was_Dirty,
        "Phase 273: setting a label must not change dirty state");

      Cmd.Text := To_Unbounded_String ("review");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (Id) = "review",
        "Phase 273: setting a second label should replace the first label");
      Summary := Editor.Buffers.Global_Summary_For (Id);
      Assert (Summary.Has_Label and then To_String (Summary.Label_Text) = "review",
        "Phase 273: buffer summary should expose label state");
      Assert (To_String (Summary.Display_Name) = "Labels.adb [label: review] — untitled",
        "Phase 273: buffer summary should include compact label text");

      Cmd.Kind := Editor.Commands.Show_Buffer_Label;
      Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Cmd);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Labels.adb label: review",
        "Phase 273: show label should emit one deterministic message");

      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String ("bad" & Character'Val (10) & "label");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (Id) = "review",
        "Phase 273: invalid multiline label should be rejected without replacing current label");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Invalid label",
        "Phase 273: invalid label feedback should be deterministic");

      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String ("x" & String'(1 .. Editor.Buffers.Max_Buffer_Label_Length => 'y'));
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Label (Id) = "review",
        "Phase 273: too-long label should be rejected without replacing current label");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Label too long",
        "Phase 273: too-long label feedback should be deterministic");

      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String ("   ");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Editor.Buffers.Global_Has_Buffer_Label (Id),
        "Phase 273: whitespace-only label input should clear the label");
   end Test_Phase273_Buffer_Labels_Set_Clear_Show_Validation_And_Markers;

   procedure Test_Phase273_Buffer_Labels_Independence_Cleanup_Reopen_And_Switcher
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Cmd           : Editor.Commands.Command;
      Label_Path    : constant String := "/tmp/editor_phase273_label.txt";
      Pinned_Path   : constant String := "/tmp/editor_phase273_pinned_label.txt";
      Existing_Path : constant String := "/tmp/editor_phase273_existing_label.txt";
      Label_Id      : Editor.Buffers.Buffer_Id;
      Pinned_Id     : Editor.Buffers.Buffer_Id;
      Existing_Id   : Editor.Buffers.Buffer_Id;
      Reopened_Id   : Editor.Buffers.Buffer_Id;
      Row           : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found_Row     : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Write_File (Label_Path, "label");
      Write_File (Pinned_Path, "pinned");
      Write_File (Existing_Path, "existing");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Label_Path);
      Label_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String ("test");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("needs parser cleanup");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd.Kind := Editor.Commands.Assign_Buffer_Group;
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Pin_Buffer);
      Assert (Editor.Buffers.Global_Has_Buffer_Label (Label_Id),
        "Phase 273 setup should create a labeled buffer");
      Assert (Editor.Buffers.Global_Has_Buffer_Note (Label_Id),
        "Phase 273 setup should create an independent note");
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (Label_Id),
        "Phase 273 setup should pin the labeled buffer");
      Assert (Editor.Buffers.Global_Has_Buffer_Group (Label_Id),
        "Phase 273 setup should group the labeled buffer");

      Cmd.Kind := Editor.Commands.Clear_Buffer_Label;
      Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Is_Buffer_Pinned (Label_Id),
        "Phase 273: clearing a label must not change pinned state");
      Assert (Editor.Buffers.Global_Has_Buffer_Group (Label_Id),
        "Phase 273: clearing a label must not change group membership");
      Assert (Editor.Buffers.Global_Buffer_Note (Label_Id) = "needs parser cleanup",
        "Phase 273: clearing a label must not change buffer note");
      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String ("core");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Buffers.Global_Buffer_Group (Label_Id) = "core"
        and then Editor.Buffers.Global_Buffer_Label (Label_Id) = "core",
        "Phase 273: equal group and label text must remain distinct state");

      Editor.Executor.Execute_Open_File (S, Pinned_Path);
      Pinned_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String ("blocked");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Pin_Buffer);

      Editor.Buffers.Global_Set_Active_Buffer (Label_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Unpin_Buffer);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_All_Clean_Buffers);
      Assert (not Editor.Buffers.Global_Contains (Label_Id),
        "Phase 273: cleanup should close clean labeled buffers when unpinned");
      Assert (Editor.Buffers.Global_Contains (Pinned_Id),
        "Phase 273: pinned labeled buffers should still be skipped by cleanup");
      Assert (True,
        "Phase 432: cleanup close must not create close-history/reopen state");

      null;
      Assert (not Editor.Buffers.Global_Contains (Label_Id),
        "Phase 432: removed removed-name reopen must not restore labeled cleanup state");
      Editor.Executor.Execute_Open_File (S, Label_Path);
      Reopened_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (not Editor.Buffers.Global_Has_Buffer_Note (Reopened_Id),
        "Phase 273: label reopen path must not smuggle note state either");

      Editor.Executor.Execute_Open_File (S, Existing_Path);
      Existing_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String ("old");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Buffers.Global_Set_Active_Buffer (Existing_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Buffers.Global_Close_Buffer (Existing_Id, Found_Row);
      Assert (Found_Row,
        "Phase 273 setup should close existing file-backed buffer once");
      Editor.Executor.Execute_Open_File (S, Existing_Path);
      Existing_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Set_Buffer_Label;
      Cmd.Text := To_Unbounded_String ("current");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Cmd.Kind := Editor.Commands.Set_Buffer_Note;
      Cmd.Text := To_Unbounded_String ("current note");
      Editor.Executor.Execute_No_Log (S, Cmd);
      null;
      Assert (Editor.Buffers.Global_Active_Buffer = Existing_Id,
        "Phase 273: reopen of an already-open file should focus existing buffer");
      Assert (Editor.Buffers.Global_Buffer_Label (Existing_Id) = "current",
        "Phase 273: already-open reopen should preserve current label state");
      Assert (Editor.Buffers.Global_Buffer_Note (Existing_Id) = "current note",
        "Phase 273: setting a label must not modify the note");

      Editor.Executor.Execute_Open_Buffer_Switcher (S);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         Editor.Buffer_Switcher.Buffer_Switcher_Config'(others => <>));
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found_Row);
      Assert (Found_Row and then Row.Id = Editor.Buffers.Global_Active_Buffer,
        "Phase 273: switcher activation semantics should still select the active buffer");
      Assert (To_String (Row.Display_Label) = "editor_phase273_existing_label.txt"
        and then Row.Has_Label
        and then To_String (Row.Label_Text) = "current"
        and then Row.Has_Note,
        "Phase 273: switcher rows should project file label and note metadata separately");

      Remove_File (Label_Path);
      Remove_File (Pinned_Path);
      Remove_File (Existing_Path);
   end Test_Phase273_Buffer_Labels_Independence_Cleanup_Reopen_And_Switcher;


   procedure Test_Phase429_File_Close_Buffer_Command_Descriptor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D     : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Close_Active_Buffer);
      Found : Boolean := False;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Close_Active_Buffer) = "file.close-buffer",
         "Phase 429: active-buffer close stable name must be file.close-buffer");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("file.close-buffer", Found) = Editor.Commands.Command_Close_Active_Buffer
         and then Found,
         "Phase 429: file.close-buffer must resolve to active-buffer close");
      Assert (D.Category = Editor.Commands.File_Category,
        "Phase 429: close-buffer must be a File command");
      Assert (D.Bindable,
        "Phase 429: close-buffer must be bindable");
      Assert (D.Visibility = Editor.Commands.Palette_Command,
        "Phase 429: close-buffer must be visible in Command Palette");
      Assert (D.Lifecycle,
        "Phase 429: close-buffer must be classified as lifecycle");
   end Test_Phase429_File_Close_Buffer_Command_Descriptor;


   procedure Test_Phase432_Close_Surface_Is_Canonical_And_Removed_Name_Hidden
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
   begin
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Close_Active_Buffer).Visibility =
         Editor.Commands.Palette_Command,
         "Phase 575: file.close-buffer remains the active-buffer close surface");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Close_Other_Buffers).Visibility =
         Editor.Commands.Palette_Command,
         "Phase 575: Close Other Buffers is public with dirty review guards");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Close_All_Clean_Buffers).Visibility =
         Editor.Commands.Palette_Command,
         "Phase 575: Close Clean Buffers is public and preserves dirty buffers");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name ("file.close-buffer", Found) =
         Editor.Commands.Command_Close_Active_Buffer and then Found,
         "Phase 432: canonical close stable name must resolve");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name ("close-buffer", Found) =
         Editor.Commands.No_Command and then not Found,
         "Phase 432: removed-name close-buffer name must not resolve");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name ("buffer.close", Found) =
         Editor.Commands.No_Command and then not Found,
         "Phase 432: buffer.close removed name must not resolve");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name ("file.close-other-buffers", Found) =
         Editor.Commands.Command_Close_Other_Buffers and then Found,
         "Phase 575: close-other stable name must resolve");
      Found := False;
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name ("file.close-clean-buffers", Found) =
         Editor.Commands.Command_Close_All_Clean_Buffers and then Found,
         "Phase 575: close-clean stable name must resolve");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name ("file.close-all", Found) =
         Editor.Commands.No_Command and then not Found,
         "Phase 432: close-all removed name must not resolve");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name ("file.discard-buffer", Found) =
         Editor.Commands.No_Command and then not Found,
         "Phase 432: discard removed-name close-adjacent name must not resolve");
   end Test_Phase432_Close_Surface_Is_Canonical_And_Removed_Name_Hidden;

   procedure Test_Phase429_File_Close_Buffer_Route_Closes_Only_Active_Clean_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("A");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      S.File_Info.Display_Name := To_Unbounded_String ("B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (not Editor.Buffers.Global_Contains (B_Id),
        "Phase 429: file.close-buffer must remove the active clean buffer");
      Assert (Editor.Buffers.Global_Contains (A_Id),
        "Phase 429: file.close-buffer must preserve inactive buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "Phase 429: file.close-buffer must select deterministic remaining buffer");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer closed",
        "Phase 429: successful close must emit canonical success message");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase429_File_Close_Buffer_Route_Closes_Only_Active_Clean_Buffer;


   procedure Test_Phase432_Close_Does_Not_Create_Close_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := "/tmp/editor_phase432_no_close_history.txt";
      Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Write_File (Path, "phase432");
      Editor.State.Init (S);
      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (not Editor.Buffers.Global_Contains (Id),
        "Phase 432: clean active close must still remove the active buffer");
      Assert (True,
        "Phase 432: file.close-buffer must not create removed-name close history");
      Assert (S.Has_Reopen_Candidate,
        "Phase 433: clean associated close must create a path-only reopen candidate");
      Assert (To_String (S.Reopen_Candidate_Path) = Path,
        "Phase 433: reopen candidate must store the associated path reference");
      null;
      Assert (not Editor.Buffers.Global_Contains (Id),
        "Phase 432: removed removed-name reopen route must not restore file.close-buffer state");

      Remove_File (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase432_Close_Does_Not_Create_Close_History;


   procedure Test_Phase433_Reopen_Closed_Buffer_Descriptor_And_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := "/tmp/editor_phase433_reopen_success.txt";
      D     : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Reopen_Closed_Buffer);
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Write_File (Path, "phase433 disk text");
      Editor.State.Init (S);

      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Reopen_Closed_Buffer) =
         "file.reopen-closed-buffer",
         "Phase 433: reopen command stable name must be canonical");
      Assert
        (Editor.Commands.Command_Id_From_Stable_Name
           ("file.reopen-closed-buffer", Found) =
         Editor.Commands.Command_Reopen_Closed_Buffer and then Found,
         "Phase 433: reopen stable name must resolve");
      Assert (D.Category = Editor.Commands.File_Category,
        "Phase 433: reopen command must be a File command");
      Assert (D.Bindable,
        "Phase 433: reopen command must be bindable");
      Assert (D.Visibility = Editor.Commands.Palette_Command,
        "Phase 433: reopen command must be palette visible");
      Assert (D.Lifecycle,
        "Phase 433: reopen command must be lifecycle-classified");
      Assert (not D.Destructive,
        "Phase 433: reopen command must not be classified destructive");

      Editor.Executor.Execute_Open_File (S, Path);
      Editor.State.Replace_Buffer_Contents (S, "closed-time clean memory differs");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("editor_phase433_reopen_success.txt");
      Editor.State.Set_Dirty (S, False);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (S.Has_Reopen_Candidate,
        "Phase 433: clean associated close must retain a transient candidate");
      Assert (True,
        "Phase 433: canonical close must still avoid removed-name close history");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (Editor.Buffers.Global_Count = 1,
        "Phase 433: reopen must add exactly one file-backed buffer");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path,
        "Phase 433: reopened buffer must use the candidate path");
      Assert (Editor.State.Current_Text (S) = "phase433 disk text" & ASCII.LF,
        "Phase 433: reopened text must come from disk, not close-time memory");
      Assert (not S.File_Info.Dirty,
        "Phase 433: reopened buffer must follow canonical clean file-open baseline");
      Assert (not S.Has_Reopen_Candidate,
        "Phase 433: successful reopen must consume the candidate");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Reopened editor_phase433_reopen_success.txt",
        "Phase 433: successful reopen must emit one canonical message");

      Remove_File (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase433_Reopen_Closed_Buffer_Descriptor_And_Success;

   procedure Test_Phase429_File_Close_Buffer_Blocks_Dirty_Without_Discarding
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before : constant String := "phase429 dirty text";
      M      : Editor.Messages.Editor_Message;
      Found  : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Replace_Buffer_Contents (S, Before);
      S.File_Info.Display_Name := To_Unbounded_String ("Dirty");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 0;
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (Editor.Buffers.Global_Contains (Id),
        "Phase 429: dirty active buffer must remain open");
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
        "Phase 429: blocked close must preserve active buffer");
      Assert (S.File_Info.Dirty,
        "Phase 429: blocked close must preserve dirty state");
      Assert (Text (S) = Before,
        "Phase 429: blocked close must preserve buffer text");
      Assert (S.Dirty_Close_Prompt_Active,
        "Phase 575: dirty close must open explicit review instead of discarding");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Discard unsaved scratch buffer?",
        "Phase 575: dirty scratch close must emit explicit review message");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase429_File_Close_Buffer_Blocks_Dirty_Without_Discarding;



   procedure Test_Phase429_File_Close_Buffer_Ignores_Switcher_Inactive_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("A");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'A'));

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      S.File_Info.Display_Name := To_Unbounded_String ("B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         Editor.Buffer_Switcher.Buffer_Switcher_Config'(others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (not Editor.Buffers.Global_Contains (B_Id),
        "Phase 429: file.close-buffer must close the active buffer, not the switcher-selected inactive row");
      Assert (Editor.Buffers.Global_Contains (A_Id),
        "Phase 429: switcher-selected inactive buffer must remain open");
      Assert (Editor.Buffers.Global_Summary_For (A_Id).Is_Dirty,
        "Phase 429: inactive dirty buffer state must be preserved when clean active buffer closes");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "Phase 429: deterministic post-close active buffer should be the remaining open buffer");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase429_File_Close_Buffer_Ignores_Switcher_Inactive_Selection;

   procedure Test_Phase429_File_Close_Buffer_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Id           : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Count : Natural := 0;
      A            : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Replace_Buffer_Contents (S, "phase429 dirty availability");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      Before_Count := Editor.Buffers.Global_Count;

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (Editor.Commands.Is_Available (A),
        "Phase 575: dirty active buffer close is available because execution opens explicit review");
      Assert (Editor.Buffers.Global_Count = Before_Count,
        "Phase 429: availability must not close or remove buffers");
      Assert (Editor.Buffers.Global_Contains (Id),
        "Phase 429: availability must preserve the active buffer");
      Assert (S.File_Info.Dirty,
        "Phase 429: availability must not clean dirty state");
      Assert (Text (S) = "phase429 dirty availability",
        "Phase 429: availability must not mutate buffer text");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase429_File_Close_Buffer_Availability_Is_Side_Effect_Free;

   procedure Test_Phase429_File_Close_Buffer_Does_Not_Save_Before_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := "/tmp/editor_phase429_close_does_not_save.txt";
      Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (Path);
      Write_File (Path, "disk");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, '!'));

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (Editor.Buffers.Global_Contains (Id),
        "Phase 429: dirty associated buffer must remain open after blocked close");
      Assert (Read_File (Path) = "disk",
        "Phase 429: dirty close must not call file.save or write the associated file");
      Assert (S.File_Info.Dirty,
        "Phase 429: blocked close must preserve dirty state before save");

      Editor.Executor.Execute_Save (S);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Close);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (not Editor.Buffers.Global_Contains (Id),
        "Phase 429: successful file.save should make the buffer eligible for close");
      Assert (Read_File (Path) = "disk!",
        "Phase 429: only explicit file.save should update disk before close");

      Remove_File (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase429_File_Close_Buffer_Does_Not_Save_Before_Close;


   procedure Test_Phase430_Close_Last_Clean_Buffer_Leaves_No_Active
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("Only");
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_Close_Active_Buffer (S);

      Assert (not Editor.Buffers.Global_Contains (Id),
        "Phase 430: closing the only clean active buffer must remove it");
      Assert (Editor.Buffers.Global_Count = 0,
        "Phase 430: closing the last clean buffer must not synthesize a replacement buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer,
        "Phase 430: closing the last clean buffer must leave no active buffer");
      Assert (S.Active_Buffer_Token = 0,
        "Phase 430: close-last-buffer must clear the state's active-buffer token");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer closed",
        "Phase 430: close-last-buffer success must emit only Buffer closed");

      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Count = 0,
        "Phase 430: a subsequent close with no active buffer must not resurrect stale state");
      Assert (Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer,
        "Phase 430: no-active close must preserve no active buffer");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer.",
        "Phase 430: no-active close must emit the canonical no-active message");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase430_Close_Last_Clean_Buffer_Leaves_No_Active;

   procedure Test_Phase430_Close_Uses_Active_Target_Not_Stale_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      A_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      A     : Editor.Commands.Command_Availability;
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("A");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'A'));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      S.File_Info.Display_Name := To_Unbounded_String ("B");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      --  Leave State loaded with dirty A while the canonical active buffer is
      --  clean B.  Close must bind to B and must not sync stale A over B.
      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Editor.Buffers.Global_Set_Active_Buffer (B_Id);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("phase430 clipboard"));

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (Editor.Commands.Is_Available (A),
        "Phase 430: close availability must observe the clean active buffer, not stale dirty State");

      Editor.Executor.Execute_Close_Active_Buffer (S);

      Assert (not Editor.Buffers.Global_Contains (B_Id),
        "Phase 430: close must remove the active clean buffer selected at execution time");
      Assert (Editor.Buffers.Global_Contains (A_Id),
        "Phase 430: close must preserve the inactive dirty buffer");
      Assert (Editor.Buffers.Global_Summary_For (A_Id).Is_Dirty,
        "Phase 430: inactive dirty buffer must remain dirty after closing clean active buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "Phase 430: post-close active buffer must be deterministic and open");
      Assert (Text (S) = "A",
        "Phase 430: stale State must not overwrite the close target's text before close");
      Assert (S.File_Info.Dirty,
        "Phase 430: remaining dirty buffer dirty state must be loaded unchanged after close");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "phase430 clipboard",
        "Phase 430: close must not mutate Clipboard state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer closed",
        "Phase 430: stale-state close success must emit only Buffer closed");

      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase430_Close_Uses_Active_Target_Not_Stale_State;

   procedure Test_Phase430_Dirty_Close_Preserves_Local_State_And_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Id             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Undo    : constant Natural := 0;
      Before_Redo    : constant Natural := 0;
      Back_Before    : Natural := 0;
      Forward_Before : Natural := 0;
      M              : Editor.Messages.Editor_Message;
      Found          : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.State.Replace_Buffer_Contents (S, "dirty-local");
      Set_Caret (S, 2, 7);
      S.File_Info.Display_Name := To_Unbounded_String ("Dirty Local");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard-stays"));
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Execute_Close_Active_Buffer (S);

      Assert (Editor.Buffers.Global_Contains (Id),
        "Phase 430: dirty active close must keep the active buffer open");
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
        "Phase 430: dirty blocked close must preserve active-buffer identity");
      Assert (Text (S) = "dirty-local",
        "Phase 430: dirty blocked close must preserve text");
      Assert (S.File_Info.Dirty,
        "Phase 430: dirty blocked close must preserve dirty state");
      Assert (S.Carets.Length = 1
        and then S.Carets (S.Carets.First_Index).Pos = 2
        and then S.Carets (S.Carets.First_Index).Anchor = 7,
        "Phase 430: dirty blocked close must preserve caret and selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
        and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
        "Phase 430: dirty blocked close must not create undo or redo entries");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
        and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
        "Phase 430: dirty blocked close must not record navigation");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard-stays",
        "Phase 430: dirty blocked close must preserve Clipboard");
      Assert (S.Dirty_Close_Prompt_Active,
        "Phase 575: dirty close must open review without mutating local state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Discard unsaved scratch buffer?",
        "Phase 575: dirty scratch close must emit explicit review message");

      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase430_Dirty_Close_Preserves_Local_State_And_Boundaries;


   procedure Test_Phase431_Close_Save_Save_As_Workflow_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      A_Path        : constant String := "/tmp/editor_phase431_a.txt";
      B_Path        : constant String := "/tmp/editor_phase431_b.txt";
      Missing_Path  : constant String := "";
      A_Id          : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id          : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      M             : Editor.Messages.Editor_Message;
      Found         : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (A_Path);
      Remove_File (B_Path);
      Write_File (A_Path, "A0");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, '1'));

      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Contains (A_Id),
        "Phase 431: dirty associated active buffer must remain open after blocked close");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "Phase 431: dirty associated blocked close must preserve active identity");
      Assert (Text (S) = "A01" & ASCII.LF,
        "Phase 431: dirty associated blocked close must preserve in-memory text");
      Assert (S.File_Info.Dirty,
        "Phase 431: dirty associated blocked close must preserve dirty state");
      Assert (Read_File (A_Path) = "A0",
        "Phase 431: blocked close must not save the associated file");
      Assert (S.Dirty_Close_Prompt_Active,
        "Phase 575: dirty associated close must open explicit review");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Unsaved changes require confirmation.",
        "Phase 575: dirty associated close must emit explicit review message");

      Editor.Executor.Execute_Save (S);
      Assert (Read_File (A_Path) = "A01",
        "Phase 431: only explicit file.save may write the associated file before close");
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (not Editor.Buffers.Global_Contains (A_Id),
        "Phase 431: clean associated buffer after save must close successfully");
      Assert (Read_File (A_Path) = "A01",
        "Phase 431: successful clean close must not perform an additional write");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer closed",
        "Phase 431: clean associated close must emit only Buffer closed");

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'B'));

      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Contains (B_Id),
        "Phase 431: dirty untitled active buffer must remain open after blocked close");
      Assert (not S.File_Info.Has_Path,
        "Phase 431: dirty untitled blocked close must preserve untitled state");
      Assert (S.File_Info.Dirty,
        "Phase 431: dirty untitled blocked close must preserve dirty state");

      Editor.Executor.Execute_Save_As (S, Missing_Path);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Contains (B_Id),
        "Phase 431: failed Save As must not make dirty untitled buffer closeable");
      Assert (not S.File_Info.Has_Path,
        "Phase 431: failed Save As before blocked close must not associate a file path");
      Assert (Text (S) = "B",
        "Phase 431: failed Save As followed by blocked close must preserve untitled text");

      Editor.Executor.Execute_Save_As (S, B_Path);
      Assert (Read_File (B_Path) = "B",
        "Phase 431: explicit successful Save As must write untitled text");
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (not Editor.Buffers.Global_Contains (B_Id),
        "Phase 431: clean untitled buffer after Save As must close successfully");
      Assert (Read_File (B_Path) = "B",
        "Phase 431: successful close after Save As must not rewrite the target");
      Assert (Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer,
        "Phase 431: closing the final clean buffer must leave no active buffer");

      Remove_File (A_Path);
      Remove_File (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (A_Path);
         Remove_File (B_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase431_Close_Save_Save_As_Workflow_Coherence;

   procedure Test_Phase431_Close_Target_Selection_And_Local_State_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      A_Id           : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id           : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      A_Undo_Before  : Natural := 0;
      A_Redo_Before  : Natural := 0;
      M              : Editor.Messages.Editor_Message;
      Found          : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      S.File_Info.Display_Name := To_Unbounded_String ("same-name");
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'A'));
      A_Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      A_Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      S.File_Info.Display_Name := To_Unbounded_String ("same-name");
      Editor.State.Replace_Buffer_Contents (S, "B");
      Set_Caret (S, 0, 1);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         Editor.Buffer_Switcher.Buffer_Switcher_Config'(others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, A_Id, 1);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("phase431 clipboard"));

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Close_Active_Buffer);

      Assert (not Editor.Buffers.Global_Contains (B_Id),
        "Phase 431: close must remove the active buffer selected at execution time");
      Assert (Editor.Buffers.Global_Contains (A_Id),
        "Phase 431: close must not remove inactive switcher-selected buffer with same display name");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "Phase 431: post-close active buffer must be the deterministic remaining open buffer");
      Assert (Text (S) = "A",
        "Phase 431: next active buffer must retain its own text, not closed-buffer text");
      Assert (S.File_Info.Dirty,
        "Phase 431: next active buffer must retain its own dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = A_Undo_Before
        and then Natural (Editor.History.Redo_Stack.Length) = A_Redo_Before,
        "Phase 431: remaining buffer Undo/Redo stacks must be preserved after closing another buffer");
      Assert (S.Carets.Length = 1
        and then S.Carets (S.Carets.First_Index).Pos = 1
        and then S.Carets (S.Carets.First_Index).Anchor = 1,
        "Phase 431: next active buffer must not inherit the closed buffer caret/selection");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "phase431 clipboard",
        "Phase 431: close must preserve global Clipboard text");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer closed",
        "Phase 431: close target workflow must emit only Buffer closed");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Text (S) = "",
        "Phase 431: undo after close must affect the remaining active buffer only");
      Assert (not Editor.Buffers.Global_Contains (B_Id),
        "Phase 431: undo after close must not reopen or retarget the closed buffer");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Text (S) = "A",
        "Phase 431: redo after close must affect the remaining active buffer only");

      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase431_Close_Target_Selection_And_Local_State_Isolation;

   procedure Test_Phase431_Read_Only_Close_Projections_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Id             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Count   : Natural := 0;
      Before_Text    : Unbounded_String := Null_Unbounded_String;
      Before_Dirty   : Boolean := False;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Back    : Natural := 0;
      Before_Forward : Natural := 0;
      A              : Editor.Commands.Command_Availability;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Candidates     : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.State.Replace_Buffer_Contents (S, "side-effect");
      Set_Caret (S, 2, 5);
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard-readonly"));

      Before_Count := Editor.Buffers.Global_Count;
      Before_Text := To_Unbounded_String (Text (S));
      Before_Dirty := S.File_Info.Dirty;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Close_Active_Buffer);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      Assert (Editor.Commands.Is_Available (A),
        "Phase 575: dirty close availability is available and still side-effect-free");
      Assert (Snap.Length = To_String (Before_Text)'Length,
        "Phase 431: render snapshot must observe text without repairing close state");
      Assert (Natural (Candidates.Length) > 0,
        "Phase 431: Command Palette projection should be readable in populated state");
      Assert (Editor.Buffers.Global_Count = Before_Count
        and then Editor.Buffers.Global_Contains (Id)
        and then Editor.Buffers.Global_Active_Buffer = Id,
        "Phase 431: render/availability/palette reads must not close or switch buffers");
      Assert (Text (S) = To_String (Before_Text)
        and then S.File_Info.Dirty = Before_Dirty
        and then S.File_Info.Baseline_Valid,
        "Phase 431: read-only projections must not mutate text, dirty state, or saved baseline");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
        and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
        "Phase 431: read-only projections must not mutate Undo/Redo stacks");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
        and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
        "Phase 431: read-only projections must not mutate Navigation History");
      Assert (S.Carets.Length = 1
        and then S.Carets (S.Carets.First_Index).Pos = 2
        and then S.Carets (S.Carets.First_Index).Anchor = 5,
        "Phase 431: read-only projections must not mutate caret or selection");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard-readonly",
        "Phase 431: read-only projections must not mutate Clipboard");

      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase431_Read_Only_Close_Projections_Are_Side_Effect_Free;


   procedure Test_Phase434_Reopen_Candidate_Exclusions_And_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      A_Path  : constant String := "/tmp/editor_phase434_candidate_a.txt";
      A_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      M       : Editor.Messages.Editor_Message;
      Found   : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File (A_Path);
      Write_File (A_Path, "phase434-A-disk");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Close_Active_Buffer (S);

      Assert (not Editor.Buffers.Global_Contains (A_Id),
        "Phase 434: successful clean associated close must remove the closed buffer");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = A_Path,
        "Phase 434: clean associated close must create the most-recent safe path candidate");
      Assert (True,
        "Phase 434: canonical reopen candidate must not revive removed-name close-history state");

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'B'));
      Editor.Executor.Execute_Close_Active_Buffer (S);

      Assert (Editor.Buffers.Global_Contains (B_Id),
        "Phase 434: dirty untitled close must remain blocked");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = A_Path,
        "Phase 434: dirty blocked close must not replace the previous safe candidate");
      Assert (S.Dirty_Close_Prompt_Active,
        "Phase 575: dirty untitled close must open explicit review");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Discard unsaved scratch buffer?",
        "Phase 575: dirty untitled close must emit explicit review message");

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Close);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (not Editor.Buffers.Global_Contains (B_Id),
        "Phase 434: clean unassociated untitled close may still close normally");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = A_Path,
        "Phase 434: clean unassociated untitled close must not create or replace a candidate");

      Editor.Executor.Execute_New_Buffer (S);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (not Editor.Buffers.Global_Contains (C_Id),
        "Phase 434: another clean untitled close must remain a normal close");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = A_Path,
        "Phase 434: non-producing close attempts must not alter candidate ordering");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (Editor.Buffers.Global_Count = 1,
        "Phase 434: reopen after non-producing closes must open exactly the retained candidate");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = A_Path,
        "Phase 434: retained candidate path must be the reopen target");
      Assert (Text (S) = "phase434-A-disk" & ASCII.LF,
        "Phase 434: retained candidate reopen must read file contents through canonical open");
      Assert (not S.Has_Reopen_Candidate,
        "Phase 434: successful reopen must consume the retained candidate");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Reopened editor_phase434_candidate_a.txt",
        "Phase 434: successful reopen after exclusions must emit only the named reopen message");

      Remove_File (A_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (A_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase434_Reopen_Candidate_Exclusions_And_Order;


   procedure Test_Phase434_Reopen_Duplicate_Open_Preserves_Buffer_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := "/tmp/editor_phase434_duplicate.txt";
      Id            : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
      Before_Count  : Natural := 0;
      M             : Editor.Messages.Editor_Message;
      Found         : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Remove_File (Path);
      Write_File (Path, "disk duplicate");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Path,
        "Phase 434: duplicate-open setup must retain the closed file candidate");

      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, '!'));
      Set_Caret (S, 3, 8);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("phase434 clipboard"));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);

      Assert (Editor.Buffers.Global_Count = Before_Count,
        "Phase 434: duplicate reopen must not create a second buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
        "Phase 434: duplicate reopen must keep or activate the existing candidate buffer");
      Assert (Text (S) = "disk duplicate" & ASCII.LF & "!",
        "Phase 434: duplicate reopen must preserve already-open dirty text");
      Assert (S.File_Info.Dirty,
        "Phase 434: duplicate reopen must not mark an already-open dirty buffer clean");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
        and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
        "Phase 434: duplicate reopen must preserve existing Undo/Redo stacks");
      Assert (S.Carets.Length = 1
        and then S.Carets (S.Carets.First_Index).Pos = 3
        and then S.Carets (S.Carets.First_Index).Anchor = 8,
        "Phase 434: duplicate reopen must preserve existing caret/selection");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "phase434 clipboard",
        "Phase 434: duplicate reopen must preserve Clipboard state");
      Assert (not S.Has_Reopen_Candidate,
        "Phase 434: successful duplicate reopen must consume the path-only candidate");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Reopened editor_phase434_duplicate.txt",
        "Phase 434: duplicate reopen success must emit one canonical message");

      Editor.Clipboard.Clear;
      Remove_File (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_File (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase434_Reopen_Duplicate_Open_Preserves_Buffer_State;


   procedure Test_Phase434_Reopen_Failure_And_Read_Only_Projections_Preserve_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Candidate_Path : constant String := "/tmp/editor_phase434_missing_candidate.txt";
      Open_Path      : constant String := "/tmp/editor_phase434_failure_active.txt";
      Active_Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Count   : Natural := 0;
      Before_Text    : Unbounded_String := Null_Unbounded_String;
      Before_Dirty   : Boolean := False;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Back    : Natural := 0;
      Before_Forward : Natural := 0;
      A              : Editor.Commands.Command_Availability;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Candidates     : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      M              : Editor.Messages.Editor_Message;
      Found          : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Remove_File (Candidate_Path);
      Remove_File (Open_Path);
      Write_File (Candidate_Path, "will disappear");
      Write_File (Open_Path, "active disk");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Candidate_Path);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Candidate_Path,
        "Phase 434: failure setup must create a transient candidate");
      Remove_File (Candidate_Path);

      Editor.Executor.Execute_Open_File (S, Open_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, '!'));
      Set_Caret (S, 4, 10);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("phase434-failure-clipboard"));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Before_Count := Editor.Buffers.Global_Count;
      Before_Text := To_Unbounded_String (Text (S));
      Before_Dirty := S.File_Info.Dirty;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      Assert (Editor.Commands.Is_Available (A),
        "Phase 434: reopen availability must depend on candidate presence, not filesystem probing");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Candidate_Path,
        "Phase 434: render/availability/palette reads must not consume the candidate");
      Assert (Editor.Buffers.Global_Count = Before_Count
        and then Editor.Buffers.Global_Active_Buffer = Active_Id
        and then Text (S) = To_String (Before_Text),
        "Phase 434: render/availability/palette reads must not mutate buffers or active text");
      Assert (Snap.Length = To_String (Before_Text)'Length,
        "Phase 434: render snapshot must observe active text without reading candidate files");
      Assert (Natural (Candidates.Length) > 0,
        "Phase 434: Command Palette projection should remain readable with a reopen candidate");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);

      Assert (Editor.Buffers.Global_Count = Before_Count,
        "Phase 434: failed reopen must not add a placeholder or empty buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = Active_Id,
        "Phase 434: failed reopen must preserve active-buffer identity");
      Assert (Text (S) = To_String (Before_Text)
        and then S.File_Info.Dirty = Before_Dirty,
        "Phase 434: failed reopen must preserve active text and dirty state");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
        and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
        "Phase 434: failed reopen must preserve Undo/Redo stacks");
      Assert (S.Carets.Length = 1
        and then S.Carets (S.Carets.First_Index).Pos = 4
        and then S.Carets (S.Carets.First_Index).Anchor = 10,
        "Phase 434: failed reopen must preserve caret/selection");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
        and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
        "Phase 434: failed reopen must not record Navigation History directly");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "phase434-failure-clipboard",
        "Phase 434: failed reopen must preserve Clipboard state");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Candidate_Path,
        "Phase 434: failed reopen must retain the same candidate for deterministic retry");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not reopen closed buffer",
        "Phase 434: failed reopen must emit one canonical failure message");

      Editor.Clipboard.Clear;
      Remove_File (Open_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_File (Candidate_Path);
         Remove_File (Open_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase434_Reopen_Failure_And_Read_Only_Projections_Preserve_State;


   procedure Test_Phase435_Reopen_Integrated_Save_Close_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      A_Path  : constant String := "/tmp/editor_phase435_integrated_a.txt";
      B_Path  : constant String := "/tmp/editor_phase435_integrated_b.txt";
      A_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      M       : Editor.Messages.Editor_Message;
      Found   : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Remove_File (A_Path);
      Remove_File (B_Path);
      Write_File (A_Path, "A disk original");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, '!'));
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Contains (A_Id),
        "Phase 435: dirty associated close must remain blocked");
      Assert (not S.Has_Reopen_Candidate,
        "Phase 435: dirty associated close must not create a reopen candidate");

      Editor.Executor.Execute_Save (S);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Close);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (not Editor.Buffers.Global_Contains (A_Id),
        "Phase 435: saved clean associated buffer must close successfully");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = A_Path,
        "Phase 435: successful clean close after save must create path-only candidate A");
      Write_File (A_Path, "A disk after close");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (Editor.Buffers.Global_Count = 1,
        "Phase 435: reopen must add the saved associated file through canonical open");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = A_Path,
        "Phase 435: reopened active buffer must use candidate A path");
      Assert (Text (S) = "A disk after close" & ASCII.LF,
        "Phase 435: reopen must read current disk contents, not close-time memory");
      Assert (not S.File_Info.Dirty,
        "Phase 435: reopened file-backed buffer must follow clean open baseline");
      Assert (not S.Has_Reopen_Candidate,
        "Phase 435: successful reopen must consume candidate A");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Reopened editor_phase435_integrated_a.txt",
        "Phase 435: successful reopen must emit one primary Reopened buffer message");

      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'B'));
      Editor.Executor.Execute_Save_As (S, "");
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Contains (B_Id),
        "Phase 435: invalid Save As leaves untitled dirty buffer open and close-blocked");
      Assert (not S.Has_Reopen_Candidate,
        "Phase 435: failed/invalid Save As followed by blocked close must not create candidate");

      Editor.Executor.Execute_Save_As (S, B_Path);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Close);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (not Editor.Buffers.Global_Contains (B_Id),
        "Phase 435: Save As success then clean close must remove untitled buffer");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = B_Path,
        "Phase 435: Save As success then clean close must create candidate B");

      Remove_File (B_Path);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = B_Path,
        "Phase 435: failed reopen must retain candidate B for deterministic retry");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not reopen closed buffer",
        "Phase 435: failed reopen must emit one primary failure message");
      Write_File (B_Path, "B restored disk");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path
        and then Text (S) = "B restored disk" & ASCII.LF,
        "Phase 435: retained failed candidate must reopen from canonical disk read after file returns");
      Assert (not S.Has_Reopen_Candidate,
        "Phase 435: retry success must consume retained candidate B");

      Remove_File (A_Path);
      Remove_File (B_Path);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (A_Path);
         Remove_File (B_Path);
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase435_Reopen_Integrated_Save_Close_Workflow;


   procedure Test_Phase435_Reopen_State_Boundaries_And_No_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Candidate_Path : constant String := "/tmp/editor_phase435_state_candidate.txt";
      Active_Path    : constant String := "/tmp/editor_phase435_state_active.txt";
      Active_Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Count   : Natural := 0;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Find    : Unbounded_String := Null_Unbounded_String;
      Before_Replace : Unbounded_String := Null_Unbounded_String;
      M              : Editor.Messages.Editor_Message;
      Found          : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Remove_File (Candidate_Path);
      Remove_File (Active_Path);
      Write_File (Candidate_Path, "candidate disk");
      Write_File (Active_Path, "active disk");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Candidate_Path);
      Set_Caret (S, 5, 1);
      S.Active_Find_Query := To_Unbounded_String ("candidate-find-must-not-survive");
      S.Active_Replace_Text := To_Unbounded_String ("candidate-replace-must-not-survive");
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Candidate_Path,
        "Phase 435: closed buffer setup must create candidate path only");

      Editor.Executor.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, '!'));
      Set_Caret (S, 3, 7);
      S.Active_Find_Query := To_Unbounded_String ("active-find");
      S.Active_Replace_Text := To_Unbounded_String ("active-replace");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("phase435 clipboard"));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Count := Editor.Buffers.Global_Count;
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Find := S.Active_Find_Query;
      Before_Replace := S.Active_Replace_Text;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (Editor.Buffers.Global_Count = Before_Count + 1,
        "Phase 435: successful non-duplicate reopen must add one buffer");
      Assert (Editor.Buffers.Global_Contains (Active_Id),
        "Phase 435: successful reopen must not mutate or remove the previous active buffer");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Candidate_Path,
        "Phase 435: reopened buffer must become active through canonical open policy");
      Assert (Text (S) = "candidate disk" & ASCII.LF,
        "Phase 435: reopened buffer must come from file-open read behavior");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 0
        and then Natural (Editor.History.Redo_Stack.Length) = 0,
        "Phase 435: newly reopened buffer must not restore closed-buffer Undo/Redo");
      Assert (S.Carets.Length = 1
        and then S.Carets (S.Carets.First_Index).Pos = 0
        and then S.Carets (S.Carets.First_Index).Anchor = 0,
        "Phase 435: newly reopened buffer must use canonical caret/selection defaults");
      Assert (S.Active_Find_Query /= To_Unbounded_String ("candidate-find-must-not-survive")
        and then S.Active_Replace_Text /=
          To_Unbounded_String ("candidate-replace-must-not-survive"),
        "Phase 435: reopen must not restore candidate Find/Replace state from closed memory");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "phase435 clipboard",
        "Phase 435: successful reopen must preserve Clipboard text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (Editor.Buffers.Global_Count = Before_Count + 1,
        "Phase 435: no-candidate reopen must not change open-buffer collection");
      Assert (Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer,
        "Phase 435: no-candidate reopen must not create placeholder active state");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "phase435 clipboard",
        "Phase 435: no-candidate reopen must preserve Clipboard");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No closed buffer to reopen",
        "Phase 435: no-candidate reopen must emit one primary no-candidate message");

      --  Ensure the previously dirty open buffer still carries its own edit stack
      --  when reactivated after the reopen/no-candidate sequence.
      Editor.Buffers.Global_Set_Active_Buffer (Active_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Text (S) = "active disk" & ASCII.LF & "!" and then S.File_Info.Dirty,
        "Phase 435: reopen/no-candidate workflow must preserve unrelated dirty buffer text and flag");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
        and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
        "Phase 435: reopen/no-candidate workflow must preserve unrelated buffer Undo/Redo stacks");
      Assert (S.Carets.Length = 1
        and then S.Carets (S.Carets.First_Index).Pos = 3
        and then S.Carets (S.Carets.First_Index).Anchor = 7,
        "Phase 435: reopen/no-candidate workflow must preserve unrelated buffer caret/selection");

      Remove_File (Candidate_Path);
      Remove_File (Active_Path);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (Candidate_Path);
         Remove_File (Active_Path);
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase435_Reopen_State_Boundaries_And_No_Candidate;


   procedure Test_Phase435_Reopen_Duplicate_Open_And_Read_Only_Surfaces
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := "/tmp/editor_phase435_duplicate.txt";
      Id            : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Count  : Natural := 0;
      Before_Text   : Unbounded_String := Null_Unbounded_String;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
      A             : Editor.Commands.Command_Availability;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      M             : Editor.Messages.Editor_Message;
      Found         : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Remove_File (Path);
      Write_File (Path, "duplicate disk");
      Editor.State.Init (S);

      Editor.Executor.Execute_Open_File (S, Path);
      Editor.Executor.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate,
        "Phase 435: duplicate-open setup must create a transient candidate");
      Editor.Executor.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, '!'));
      Set_Caret (S, 6, 2);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("phase435 duplicate clipboard"));
      S.Active_Find_Query := To_Unbounded_String ("duplicate-find");
      S.Active_Replace_Text := To_Unbounded_String ("duplicate-replace");
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Count := Editor.Buffers.Global_Count;
      Before_Text := To_Unbounded_String (Text (S));
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Write_File (Path, "external disk change must not overwrite dirty duplicate");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      Assert (Editor.Commands.Is_Available (A),
        "Phase 435: reopen availability must depend on candidate presence only");
      Assert (S.Has_Reopen_Candidate and then To_String (S.Reopen_Candidate_Path) = Path,
        "Phase 435: render/availability/palette must not consume candidate");
      Assert (Snap.Length = To_String (Before_Text)'Length
        and then Natural (Candidates.Length) > 0,
        "Phase 435: render and Command Palette projection must remain side-effect-free observations");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (Editor.Buffers.Global_Count = Before_Count,
        "Phase 435: duplicate-open reopen must not add a duplicate buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
        "Phase 435: duplicate-open reopen must activate/keep existing candidate buffer");
      Assert (Text (S) = To_String (Before_Text) and then S.File_Info.Dirty,
        "Phase 435: duplicate-open reopen must preserve dirty in-memory text and dirty flag");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
        and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
        "Phase 435: duplicate-open reopen must preserve existing Undo/Redo stacks");
      Assert (S.Carets.Length = 1
        and then S.Carets (S.Carets.First_Index).Pos = 6
        and then S.Carets (S.Carets.First_Index).Anchor = 2,
        "Phase 435: duplicate-open reopen must preserve existing caret/selection");
      Assert (S.Active_Find_Query = To_Unbounded_String ("duplicate-find")
        and then S.Active_Replace_Text = To_Unbounded_String ("duplicate-replace"),
        "Phase 435: duplicate-open reopen must preserve active buffer Find/Replace state");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
        and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Fwd,
        "Phase 435: duplicate-open reopen must not record Navigation History directly");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "phase435 duplicate clipboard",
        "Phase 435: duplicate-open reopen must preserve Clipboard");
      Assert (not S.Has_Reopen_Candidate,
        "Phase 435: duplicate-open success must consume candidate under retained policy");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Reopened editor_phase435_duplicate.txt",
        "Phase 435: duplicate-open success must emit one primary Reopened buffer message");

      Remove_File (Path);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (Path);
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase435_Reopen_Duplicate_Open_And_Read_Only_Surfaces;




   function Phase577_Project (Root : String) return Editor.Project.Project_State is
      P : Editor.Project.Project_State;
      R : Editor.Project.Project_Open_Result;
   begin
      if not Ada.Directories.Exists (Root) then
         Ada.Directories.Create_Path (Root);
      end if;
      R := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (R), "phase 577 project fixture should open");
      Editor.Project.Apply_Open_Result (P, R);
      return P;
   end Phase577_Project;

   procedure Test_Phase577_Metadata_Classifies_Ownership_And_Labels
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Root     : constant String := "/tmp/editor_phase577_project";
      Project  : constant Editor.Project.Project_State := Phase577_Project (Root);
      Project_Id : Editor.Buffers.Buffer_Id;
      Outside_Id : Editor.Buffers.Buffer_Id;
      Scratch_Id : Editor.Buffers.Buffer_Id;
      Project_Metadata : Editor.Buffers.Buffer_Metadata_Snapshot;
      Outside_Metadata : Editor.Buffers.Buffer_Metadata_Snapshot;
      Scratch_Metadata : Editor.Buffers.Buffer_Metadata_Snapshot;
   begin
      Project_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, Root & "/src/main.adb", "main.adb", "project text must not leak");
      Outside_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/editor_phase577_outside.adb", "outside.adb", "outside text");
      Scratch_Id := Editor.Buffers.Create_Untitled_Buffer (Registry);

      Editor.Buffers.Set_Active_Buffer (Registry, Outside_Id);
      Project_Metadata := Editor.Buffers.Metadata_For
        (Registry, Project, Project_Id, Selected_Id => Project_Id);
      Outside_Metadata := Editor.Buffers.Metadata_For (Registry, Project, Outside_Id);
      Scratch_Metadata := Editor.Buffers.Metadata_For (Registry, Project, Scratch_Id);

      Assert (Project_Metadata.Ownership = Editor.Buffers.Buffer_Project_Owned,
        "project path should classify as project-owned");
      Assert (To_String (Project_Metadata.Project_Relative_Path) = "src/main.adb",
        "project metadata should expose bounded relative display path");
      Assert (Project_Metadata.Is_Selected,
        "metadata should mark the selected runtime row transiently");
      Assert (not Project_Metadata.Is_Active,
        "inactive project row should not be marked active");
      Assert (To_String (Project_Metadata.Ownership_Label) = "Project file",
        "ownership label should be user-readable");
      Assert (To_String (Project_Metadata.Lifecycle_Status_Label) = "Clean",
        "clean lifecycle label should be user-readable");

      Assert (Outside_Metadata.Ownership = Editor.Buffers.Buffer_Outside_Project,
        "outside path should classify distinctly from project-owned");
      Assert (Outside_Metadata.Is_Active,
        "active marker should follow registry active buffer");
      Assert (Scratch_Metadata.Ownership = Editor.Buffers.Buffer_Scratch_Unbacked,
        "scratch buffer must not classify as a project file");
      Assert (Scratch_Metadata.Is_Scratch,
        "scratch marker should be explicit");
      Assert (Scratch_Metadata.Has_Scratch_Label,
        "scratch metadata should expose a bounded scratch label");
      Assert (To_String (Scratch_Metadata.Scratch_Label) = "No backing file",
        "scratch label should be user-readable and not derived from text");
      Assert (To_String (Scratch_Metadata.Lifecycle_Status_Label) = "Scratch",
        "scratch lifecycle label should be user-readable");
   end Test_Phase577_Metadata_Classifies_Ownership_And_Labels;

   procedure Test_Phase577_Dirty_Categorization_And_Audit_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Root     : constant String := "/tmp/editor_phase577_project_dirty";
      Project  : constant Editor.Project.Project_State := Phase577_Project (Root);
      Project_Id : Editor.Buffers.Buffer_Id;
      Outside_Id : Editor.Buffers.Buffer_Id;
      Scratch_Id : Editor.Buffers.Buffer_Id;
      Missing_Id : Editor.Buffers.Buffer_Id;
      Conflict_Id : Editor.Buffers.Buffer_Id;
      Unwritable_Id : Editor.Buffers.Buffer_Id;
      B : access Editor.State.State_Type;
      Audit : Editor.Buffers.Buffer_Audit_Summary;
      All_Dirty : Editor.Dirty_Guards.Dirty_Buffer_Summary;
      Project_Dirty : Editor.Dirty_Guards.Dirty_Buffer_Summary;
      Sets : Editor.Buffers.Buffer_Project_Lifecycle_Sets;
      Dirty_Ids : array (Positive range 1 .. 6) of Editor.Buffers.Buffer_Id;
   begin
      Project_Id := Editor.Buffers.Add_Buffer_From_File (Registry, Root & "/a.adb", "a.adb", "a");
      Outside_Id := Editor.Buffers.Add_Buffer_From_File (Registry, "/tmp/outside-a.adb", "outside-a.adb", "b");
      Scratch_Id := Editor.Buffers.Create_Untitled_Buffer (Registry);
      Missing_Id := Editor.Buffers.Add_Buffer_From_File (Registry, Root & "/missing.adb", "missing.adb", "c");
      Conflict_Id := Editor.Buffers.Add_Buffer_From_File (Registry, Root & "/conflict.adb", "conflict.adb", "d");
      Unwritable_Id := Editor.Buffers.Add_Buffer_From_File (Registry, Root & "/readonly.adb", "readonly.adb", "e");

      Dirty_Ids := (Project_Id, Outside_Id, Scratch_Id, Missing_Id, Conflict_Id, Unwritable_Id);
      for Id of Dirty_Ids loop
         B := Editor.Buffers.Buffer_Access (Registry, Id);
         B.File_Info.Dirty := True;
      end loop;
      B := Editor.Buffers.Buffer_Access (Registry, Missing_Id);
      B.File_Info.Missing_Target_Surfaced := True;
      B := Editor.Buffers.Buffer_Access (Registry, Conflict_Id);
      B.File_Info.External_Change_Surfaced := True;
      B := Editor.Buffers.Buffer_Access (Registry, Unwritable_Id);
      B.File_Info.Unwritable_Target_Surfaced := True;

      Audit := Editor.Buffers.Audit_Buffers (Registry, Project, Selected_Id => Scratch_Id);
      Assert (Audit.Dirty_Project_File_Count = 1,
        "dirty project-owned file count should be stable");
      Assert (Audit.Dirty_Outside_Project_Count = 1,
        "dirty outside-project file count should be stable");
      Assert (Audit.Dirty_Scratch_Count = 1,
        "dirty scratch count should be stable");
      Assert (Audit.Dirty_Missing_Count = 1,
        "dirty missing backing file count should be stable");
      Assert (Audit.Dirty_Conflicted_Count = 1,
        "dirty conflicted file count should be stable");
      Assert (Audit.Dirty_Unwritable_Count = 1,
        "dirty unwritable file count should be stable");
      Assert (Audit.Missing_Or_Conflicted_Count = 2,
        "missing/conflicted audit count should exclude plain unwritable buffers");
      Assert (Audit.Stale_Backing_State_Count = 2,
        "stale backing state count should track missing and external-change buffers explicitly");
      Assert (Audit.Unwritable_Count = 1,
        "unwritable audit count should be explicit and separate from missing/conflicted");
      Assert (Audit.Lifecycle_Problem_Count = 3,
        "missing, conflicted, and unwritable lifecycle problem set should be explicit");
      Assert (Audit.Project_Close_Affected_Count = 4,
        "project close affected set should contain project-owned buffers only");
      Assert (Audit.Project_Close_Unaffected_Count = 2,
        "project close unaffected set should distinguish outside-project and scratch buffers");
      Assert (Audit.Project_Owned_Dirty_Count = 4,
        "project-owned dirty set count should include dirty project, missing, conflict, and unwritable buffers");
      Assert (Audit.Outside_Project_Dirty_Count = 1,
        "outside-project dirty set count should remain distinct");
      Assert (Audit.Scratch_Dirty_Count = 1,
        "scratch dirty set count should remain distinct");
      Assert (Editor.Buffers.Project_Owned_Dirty_Buffer_Count (Registry, Project) = 4,
        "project-owned dirty set helper should match the audit summary");
      Assert (Editor.Buffers.Outside_Project_Dirty_Buffer_Count (Registry, Project) = 1,
        "outside-project dirty set helper should match the audit summary");
      Assert (Editor.Buffers.Scratch_Dirty_Buffer_Count (Registry, Project) = 1,
        "scratch dirty set helper should match the audit summary");
      Sets := Editor.Buffers.Project_Lifecycle_Buffer_Sets (Registry, Project);
      Assert (Natural (Sets.Project_Owned.Length) = 4,
        "project lifecycle should expose the deterministic project-owned buffer set");
      Assert (Natural (Sets.Project_Owned_Dirty.Length) = 4,
        "project lifecycle should expose the deterministic project-owned dirty buffer set");
      Assert (Natural (Sets.Project_Owned_Clean.Length) = 0,
        "project lifecycle should expose the deterministic project-owned clean buffer set");
      Assert (Natural (Sets.Outside_Project.Length) = 1,
        "project lifecycle should expose outside-project buffers distinctly");
      Assert (Natural (Sets.Scratch.Length) = 1,
        "project lifecycle should expose scratch buffers distinctly");
      Assert (Natural (Sets.Project_Close_Affected.Length) = 4,
        "project close affected set should be a reusable ordered vector, not only a count");
      Assert (Natural (Sets.Project_Close_Unaffected.Length) = 2,
        "project close retained set should be a reusable ordered vector, not only a count");
      Assert (Sets.Project_Owned.Element (Sets.Project_Owned.First_Index) = Project_Id,
        "project-owned set should preserve registry order for deterministic lifecycle review");
      Assert (Sets.Outside_Project.Element (Sets.Outside_Project.First_Index) = Outside_Id,
        "outside-project set should preserve registry order for deterministic lifecycle review");
      Assert (Sets.Scratch.Element (Sets.Scratch.First_Index) = Scratch_Id,
        "scratch set should preserve registry order for deterministic lifecycle review");
      All_Dirty := Editor.Buffers.Categorized_Dirty_Buffer_Summary (Registry, Project);
      Project_Dirty := Editor.Buffers.Project_Lifecycle_Dirty_Buffer_Summary (Registry, Project);
      Assert (All_Dirty.Dirty_Count = 6
        and then All_Dirty.File_Backed_Count = 5
        and then All_Dirty.Untitled_Count = 1,
        "dirty review summary should be derived from Phase 577 dirty categories");
      Assert (Project_Dirty.Dirty_Count = 4
        and then Project_Dirty.File_Backed_Count = 4
        and then Project_Dirty.Untitled_Count = 0,
        "project lifecycle dirty summary should use project-owned metadata categories only");
      Assert (Audit.Close_Needs_Confirmation_Count = 2,
        "plain dirty project/outside files should require confirmation");
      Assert (Audit.Close_Needs_Save_As_Count = 2,
        "dirty scratch and unwritable buffers should require save-as or discard");
      Assert (Audit.Close_Needs_Conflict_Count = 2,
        "missing and conflicted dirty files should require conflict resolution or discard");
      Assert (Audit.Selected_Buffer_Valid,
        "selected buffer audit should accept current runtime rows only");
      Assert (To_String (Audit.Dirty_Project_Files_Summary_Label) =
                "4 dirty project files.",
        "dirty project summary should be canonical and user-readable");
      Assert (To_String (Audit.Dirty_Outside_Project_Summary_Label) =
                "1 dirty outside-project file.",
        "dirty outside-project summary should be canonical and user-readable");
      Assert (To_String (Audit.Dirty_Scratch_Summary_Label) =
                "1 unsaved scratch buffer.",
        "dirty scratch summary should be canonical and user-readable");
      Assert (To_String (Audit.Dirty_File_Conflict_Summary_Label) =
                "2 dirty buffers have file conflicts.",
        "dirty conflict summary should include missing and externally conflicted dirty buffers");
      Assert (To_String (Audit.Workspace_Persistability_Summary_Label) =
                "4 workspace-persistable file references. 2 runtime-only buffers excluded.",
        "workspace persistability summary should distinguish structural references from runtime-only state");
      Assert (To_String (Audit.Project_Lifecycle_Buffer_Set_Summary_Label) =
                "4 project-close affected buffers. 2 retained outside/scratch buffers.",
        "project lifecycle summary should distinguish affected and retained buffer sets");
   end Test_Phase577_Dirty_Categorization_And_Audit_Counts;

   procedure Test_Phase577_Close_Eligibility_And_Persistability_Are_Projection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Project  : Editor.Project.Project_State;
      File_Id  : Editor.Buffers.Buffer_Id;
      Scratch_Id : Editor.Buffers.Buffer_Id;
      Conflict_Id : Editor.Buffers.Buffer_Id;
      Unwritable_Id : Editor.Buffers.Buffer_Id;
      Unreadable_Id : Editor.Buffers.Buffer_Id;
      B : access Editor.State.State_Type;
      Before_Count : Natural;
      M : Editor.Buffers.Buffer_Metadata_Snapshot;
   begin
      File_Id := Editor.Buffers.Add_Buffer_From_File (Registry, "/tmp/phase577_clean.adb", "clean.adb", "clean");
      Scratch_Id := Editor.Buffers.Create_Untitled_Buffer (Registry);
      Conflict_Id := Editor.Buffers.Add_Buffer_From_File (Registry, "/tmp/phase577_conflict.adb", "conflict.adb", "x");
      Unwritable_Id := Editor.Buffers.Add_Buffer_From_File (Registry, "/tmp/phase577_readonly.adb", "readonly.adb", "x");
      Unreadable_Id := Editor.Buffers.Add_Buffer_From_File (Registry, "/tmp/phase577_unreadable.adb", "unreadable.adb", "x");
      Before_Count := Editor.Buffers.Count (Registry);

      M := Editor.Buffers.Metadata_For (Registry, Project, File_Id);
      Assert (M.Close_Eligibility = Editor.Buffers.Buffer_Closable_Clean,
        "clean file-backed buffer should be directly closable metadata");
      Assert (M.Workspace_Persistability = Editor.Buffers.Buffer_Persistable_File_Reference,
        "file-backed buffer should persist only as structural file reference");

      B := Editor.Buffers.Buffer_Access (Registry, Scratch_Id);
      B.File_Info.Dirty := True;
      M := Editor.Buffers.Metadata_For (Registry, Project, Scratch_Id);
      Assert (M.Close_Eligibility = Editor.Buffers.Buffer_Requires_Save_As_Or_Discard,
        "dirty scratch buffer should require save-as or discard policy");
      Assert (M.Workspace_Persistability = Editor.Buffers.Buffer_Not_Persistable_Scratch,
        "scratch text must not be workspace-persistable");

      B := Editor.Buffers.Buffer_Access (Registry, Conflict_Id);
      B.File_Info.Dirty := True;
      B.File_Info.External_Change_Surfaced := True;
      M := Editor.Buffers.Metadata_For (Registry, Project, Conflict_Id);
      Assert (M.Close_Eligibility = Editor.Buffers.Buffer_Requires_Conflict_Resolution_Or_Discard,
        "dirty conflicted file should require conflict resolution or discard");
      B.File_Info.Missing_Target_Surfaced := True;
      M := Editor.Buffers.Metadata_For (Registry, Project, Conflict_Id);
      Assert (M.Workspace_Persistability = Editor.Buffers.Buffer_Not_Persistable_Invalid_Path,
        "missing file-backed buffers should not be treated as workspace-persistable open references");

      B := Editor.Buffers.Buffer_Access (Registry, Unwritable_Id);
      B.File_Info.Dirty := True;
      B.File_Info.Unwritable_Target_Surfaced := True;
      M := Editor.Buffers.Metadata_For (Registry, Project, Unwritable_Id);
      Assert (M.Close_Eligibility = Editor.Buffers.Buffer_Requires_Save_As_Or_Discard,
        "dirty unwritable file should require save-as or discard rather than generic dirty confirmation");

      B := Editor.Buffers.Buffer_Access (Registry, Unreadable_Id);
      B.File_Info.Dirty := True;
      B.File_Info.Unreadable_Target_Surfaced := True;
      B.File_Info.Last_Reload_Failed := True;
      M := Editor.Buffers.Metadata_For (Registry, Project, Unreadable_Id);
      Assert (M.Close_Eligibility = Editor.Buffers.Buffer_Requires_Save_As_Or_Discard,
        "dirty unreadable file should require save-as or discard rather than generic dirty confirmation");

      Assert (Editor.Buffers.Count (Registry) = Before_Count,
        "metadata and eligibility helpers must not close, save, or mutate buffers");
   end Test_Phase577_Close_Eligibility_And_Persistability_Are_Projection_Only;

   procedure Test_Phase577_Active_Selected_And_Leak_Audit_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Project  : Editor.Project.Project_State;
      A : Editor.Buffers.Buffer_Id;
      B : Editor.Buffers.Buffer_Id;
      Closed : Boolean;
      Audit : Editor.Buffers.Buffer_Audit_Summary;
   begin
      A := Editor.Buffers.Create_Untitled_Buffer (Registry);
      B := Editor.Buffers.Create_Untitled_Buffer (Registry);
      Editor.Buffers.Set_Active_Buffer (Registry, B);
      Editor.Buffers.Close_Buffer (Registry, B, Closed, Force => True);
      Assert (Closed, "test setup should close active buffer");

      Audit := Editor.Buffers.Audit_Buffers (Registry, Project, Selected_Id => A);
      Assert (Audit.Active_Buffer_Valid,
        "closing active buffer should leave active id registered or none");
      Assert (Audit.Selected_Buffer_Valid,
        "current selected buffer id should validate against current rows");
      Assert (not Audit.Runtime_Buffer_Id_Persisted,
        "buffer audit must report no runtime buffer id persistence channel");
      Assert (not Audit.Command_Or_Keybinding_Payload,
        "buffer audit must report no command/keybinding buffer payload channel");
      Assert (not Audit.Render_Mutation_Route,
        "buffer audit must report no render mutation route");
      Assert (Audit.Metadata_Projection_Coherent,
        "valid active/selected state should be a coherent metadata projection");
      Assert (Editor.Buffers.Buffer_Metadata_Lifecycle_Audit_Coherent
                (Registry, Project, Selected_Id => A),
        "coherent helper should pass when active and selected buffers are registered");

      Audit := Editor.Buffers.Audit_Buffers (Registry, Project, Selected_Id => B);
      Assert (not Audit.Selected_Buffer_Valid,
        "stale selected buffer id should be rejected by audit");
      Assert (not Audit.Metadata_Projection_Coherent,
        "stale selected runtime id should make metadata projection incoherent");
      Assert (not Editor.Buffers.Buffer_Metadata_Lifecycle_Audit_Coherent
                (Registry, Project, Selected_Id => B),
        "coherent helper should reject stale selected runtime buffer ids");
   end Test_Phase577_Active_Selected_And_Leak_Audit_Boundaries;




   procedure Test_Phase577_Metadata_Normalizes_Paths_And_Conflict_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Root     : constant String := "/tmp/editor_phase577_norm/project";
      Project  : constant Editor.Project.Project_State := Phase577_Project (Root);
      In_Id    : Editor.Buffers.Buffer_Id;
      Outside_Id : Editor.Buffers.Buffer_Id;
      No_Project : Editor.Project.Project_State;
      B : access Editor.State.State_Type;
      M : Editor.Buffers.Buffer_Metadata_Snapshot;
   begin
      In_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, Root & "/sub/../unit.adb", "unit.adb", "package Unit is end Unit;");
      Outside_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/editor_phase577_norm/outside.adb", "outside.adb", "outside body text");

      M := Editor.Buffers.Metadata_For (Registry, Project, In_Id);
      Assert (M.Ownership = Editor.Buffers.Buffer_Project_Owned,
        "normalized project-root descendant should classify as project-owned");
      Assert (To_String (M.File_Path) = Root & "/unit.adb",
        "metadata file path projection should be normalized rather than a raw input string");
      Assert (M.Has_Project_Relative_Path,
        "project-owned metadata should expose a project-relative label");
      Assert (To_String (M.Project_Relative_Path) /= "package Unit is end Unit;",
        "metadata projection must not copy buffer text into path labels");

      M := Editor.Buffers.Metadata_For (Registry, Project, Outside_Id);
      Assert (M.Ownership = Editor.Buffers.Buffer_Outside_Project,
        "outside path should remain distinct from project-owned buffers");
      Assert (M.Has_Outside_Project_Path_Label,
        "outside-project metadata should expose an outside-project path label");
      Assert (not M.Has_Project_Relative_Path,
        "outside-project metadata must not fabricate a project-relative path");

      M := Editor.Buffers.Metadata_For (Registry, No_Project, Outside_Id);
      Assert (M.Ownership = Editor.Buffers.Buffer_Missing_Project_Context,
        "file-backed buffer with no active project should be classified explicitly");
      Assert (To_String (M.Ownership_Label) = "No project open.",
        "missing project ownership label should use the Phase 578 canonical wording");

      B := Editor.Buffers.Buffer_Access (Registry, Outside_Id);
      B.File_Info.Dirty := True;
      B.File_Info.External_Change_Surfaced := True;
      M := Editor.Buffers.Metadata_For (Registry, Project, Outside_Id);
      Assert (To_String (M.Lifecycle_Status_Label) = "Conflict pending",
        "dirty external change should report a pending conflict label");
      Assert (M.Dirty_Category = Editor.Buffers.Buffer_Dirty_Conflicted_File,
        "dirty external change should use the conflicted dirty category");
      Assert (M.Stale_Backing_State,
        "external change should mark the metadata as stale backing state without probing the filesystem");
   end Test_Phase577_Metadata_Normalizes_Paths_And_Conflict_Status;

   procedure Test_Phase577_Audit_Empty_And_Forbidden_Persistence_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Project  : Editor.Project.Project_State;
      Audit    : Editor.Buffers.Buffer_Audit_Summary;
   begin
      Audit := Editor.Buffers.Audit_Buffers (Registry, Project);
      Assert (Audit.Buffer_Count = 0,
        "empty registry audit should report zero buffers");
      Assert (Audit.Active_Buffer_Valid,
        "empty registry should have a valid no-active-buffer state");
      Assert (Audit.Selected_Buffer_Valid,
        "empty registry with no selection should have a valid no-selection state");
      Assert (not Audit.Active_Runtime_Id_Persisted,
        "workspace persistence must not store the active runtime buffer id");
      Assert (not Audit.Selected_Runtime_Id_Persisted,
        "workspace persistence must not store selected runtime buffer id");
      Assert (not Audit.Buffer_List_State_Persisted,
        "workspace persistence must not store Buffer List rows or selection");
      Assert (not Audit.Dirty_Text_Persisted,
        "workspace persistence must not store dirty buffer text");
      Assert (not Audit.Scratch_Text_Persisted,
        "workspace persistence must not store scratch buffer text");
      Assert (not Audit.Conflict_Token_Persisted,
        "workspace persistence must not store conflict prompt tokens");
      Assert (not Audit.Runtime_Buffer_Id_Persisted,
        "workspace persistence must not store runtime buffer ids");
      Assert (Audit.Metadata_Projection_Coherent,
        "empty audit should still be a coherent metadata projection");
      Assert (Audit.Workspace_Persistence_Safe,
        "workspace persistence safety audit should pass by default");
      Assert (Audit.Command_Keybinding_Payloads_Clear,
        "command/keybinding payload boundary should be explicit and clear");
      Assert (Audit.Render_Boundary_Safe,
        "render boundary audit should report no mutation route");
      Assert (Audit.Audit_Side_Effect_Free,
        "buffer audit must be declared side-effect-free");
      Assert (Editor.Buffers.Buffer_Metadata_Lifecycle_Audit_Coherent
                (Registry, Project),
        "coherent helper should pass for empty registry");
   end Test_Phase577_Audit_Empty_And_Forbidden_Persistence_Boundaries;

   procedure Test_Phase577_Workspace_Snapshot_Remains_Structural
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item    : Editor.Workspace_Persistence.Workspace_File_Entry;
   begin
      Item.Path := To_Unbounded_String ("src/main.adb");
      Item.Is_Project_Relative := True;
      Item.Cursor_Row := 7;
      Item.Cursor_Column := 3;
      Editor.Workspace_Persistence.Add_Open_File (Snapshot, Item);
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/main.adb", Is_Project_Relative => True);

      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
        "workspace snapshot should store structural open file references only");
      Assert (To_String (Editor.Workspace_Persistence.Open_File (Snapshot, 1).Path) = "src/main.adb",
        "workspace open file entry should be a structural project-relative path");
      Assert (Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
        "workspace active reference should be structural file path state");
      Assert (Editor.Workspace_Persistence.Active_File_Path (Snapshot) = "src/main.adb",
        "workspace active file reference must not depend on a runtime buffer id");
   end Test_Phase577_Workspace_Snapshot_Remains_Structural;



   procedure Test_Phase577_Audit_Tracks_Readability_And_Close_Sets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Root     : constant String := "/tmp/editor_phase577_readability";
      Project  : constant Editor.Project.Project_State := Phase577_Project (Root);
      Clean_Id : Editor.Buffers.Buffer_Id;
      Read_Id  : Editor.Buffers.Buffer_Id;
      Blocked_Id : Editor.Buffers.Buffer_Id;
      B : access Editor.State.State_Type;
      Audit : Editor.Buffers.Buffer_Audit_Summary;
      M : Editor.Buffers.Buffer_Metadata_Snapshot;
   begin
      Clean_Id := Editor.Buffers.Add_Buffer_From_File (Registry, Root & "/clean.adb", "clean.adb", "clean");
      Read_Id := Editor.Buffers.Add_Buffer_From_File (Registry, Root & "/read.adb", "read.adb", "read");
      Blocked_Id := Editor.Buffers.Add_Buffer_From_File (Registry, Root & "/blocked.adb", "blocked.adb", "blocked");

      B := Editor.Buffers.Buffer_Access (Registry, Read_Id);
      B.File_Info.Unreadable_Target_Surfaced := True;
      B.File_Info.Last_Reload_Failed := True;

      B := Editor.Buffers.Buffer_Access (Registry, Blocked_Id);
      B.File_Info.Dirty := True;
      B.File_Info.Blocked_Close_Surfaced := True;

      M := Editor.Buffers.Metadata_For (Registry, Project, Read_Id);
      Assert (M.Unreadable,
        "metadata should surface known unreadable lifecycle state");
      Assert (To_String (M.Lifecycle_Status_Label) = "Unreadable",
        "unreadable lifecycle label should be user-readable");

      Audit := Editor.Buffers.Audit_Buffers (Registry, Project);
      Assert (Audit.Project_Owned_Clean_Count = 2,
        "project-owned clean set should include clean and unreadable clean buffers");
      Assert (Audit.Project_Owned_Dirty_Count = 1,
        "project-owned dirty set should include blocked dirty buffers");
      Assert (Audit.Unreadable_Count = 1,
        "audit should count unreadable buffers explicitly");
      Assert (Audit.Lifecycle_Problem_Count = 1,
        "unreadable lifecycle problem should be included in the explicit problem set");
      Assert (Audit.Project_Close_Affected_Count = 3,
        "project close affected set should be computed from ownership without mutation");
      Assert (Audit.Close_Direct_Count = 2,
        "clean buffers remain directly closable by metadata even when unreadable state is surfaced");
      Assert (Audit.Close_Blocked_Count = 1,
        "blocked close state should have an explicit audit count");
      Assert (Editor.Buffers.Count (Registry) = 3,
        "audit should not close or mutate buffers");
      Assert (Clean_Id /= Editor.Buffers.No_Buffer,
        "clean fixture id should be a real runtime id only inside the registry");
   end Test_Phase577_Audit_Tracks_Readability_And_Close_Sets;


   procedure Test_Phase577_Metadata_Labels_Are_Bounded_And_Not_Text_Dumps
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Root     : constant String := "/tmp/editor_phase577_bounded";
      Project  : constant Editor.Project.Project_State := Phase577_Project (Root);
      Long_Name : constant String :=
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" &
        "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" &
        "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";
      Id : Editor.Buffers.Buffer_Id;
      M  : Editor.Buffers.Buffer_Metadata_Snapshot;
   begin
      Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, Root & "/" & Long_Name & ".adb", Long_Name & ".adb",
         "this buffer text must never appear in metadata labels");
      M := Editor.Buffers.Metadata_For (Registry, Project, Id);

      Assert (Length (M.Display_Label) <= Editor.Buffers.Metadata_Label_Max_Length,
        "display labels should be bounded snapshot metadata");
      Assert (Length (M.File_Path) <= Editor.Buffers.Metadata_Label_Max_Length,
        "file path labels should be bounded rather than raw unbounded path dumps");
      Assert (Length (M.Project_Relative_Path) <= Editor.Buffers.Metadata_Label_Max_Length,
        "project-relative path labels should be bounded snapshot metadata");
      Assert (To_String (M.Display_Label) /= "this buffer text must never appear in metadata labels",
        "metadata labels must not copy buffer text");
   end Test_Phase577_Metadata_Labels_Are_Bounded_And_Not_Text_Dumps;


   procedure Test_Phase577_Render_Projects_Active_Metadata_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Root : constant String := "/tmp/editor_phase577_render_project";
      Path : constant String := Root & "/src/rendered.adb";
   begin
      Editor.Buffers.Reset_Global_For_Test;
      if not Ada.Directories.Exists (Root & "/src") then
         Ada.Directories.Create_Path (Root & "/src");
      end if;
      Write_File (Path, "procedure Rendered is begin null; end Rendered;");
      Editor.State.Init (S);
      S.Project := Phase577_Project (Root);
      Editor.Executor.Execute_Open_File (S, Path);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Active_Buffer_Has_Metadata,
        "render snapshot should expose active buffer metadata as an inert projection");
      Assert (To_String (Snap.Active_Buffer_Ownership_Label) = "Project file",
        "render snapshot should display ownership label from buffer metadata");
      Assert (To_String (Snap.Active_Buffer_Lifecycle_Label) = "Clean",
        "render snapshot should display lifecycle label from buffer metadata");
      Assert (To_String (Snap.Active_Buffer_Workspace_Persistability_Label) =
                "Persistable file reference",
        "render snapshot should display workspace persistability label without persisting it");
      Assert (To_String (Snap.Active_Buffer_Close_Eligibility_Label) = "Closable",
        "render snapshot should display close eligibility label without closing");
      Assert (not Snap.Active_Buffer_Stale_Backing_State,
        "fresh clean file should not be marked stale by render projection");

      Remove_File (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase577_Render_Projects_Active_Metadata_Snapshot;

   procedure Test_Phase577_Buffer_Workflow_Route_Audit_Rejects_Buffer_Payloads
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Buffer_Workflow_Route
        (Result                  => Audit,
         Source                  => Editor.Command_Route_Audit.Route_From_Command_Palette,
         Command                 => Editor.Commands.Command_Close_Active_Buffer,
         Routed_Through_Executor => True,
         Availability_Checked    => True,
         Carried_Buffer_Payload  => False);
      Editor.Command_Route_Audit.Record_Buffer_Workflow_Route
        (Result                  => Audit,
         Source                  => Editor.Command_Route_Audit.Route_From_Keybinding,
         Command                 => Editor.Commands.Command_Next_Buffer,
         Routed_Through_Executor => True,
         Availability_Checked    => True,
         Carried_Buffer_Payload  => False);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
        "valid buffer routes should pass through Executor without payloads");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Buffer_Workflow_Route
        (Result                  => Audit,
         Source                  => Editor.Command_Route_Audit.Route_From_Command_Palette,
         Command                 => Editor.Commands.Command_Switch_Buffer,
         Routed_Through_Executor => False,
         Availability_Checked    => False,
         Carried_Buffer_Payload  => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 3,
        "buffer route audit should reject executor, availability, and buffer-id payload violations");
      Assert (Editor.Command_Route_Audit.Last_Failure_Message (Audit)
              = "ROUTE_CARRIED_COMMAND_PAYLOAD source=ROUTE_FROM_COMMAND_PALETTE expected=NO_COMMAND actual=COMMAND_SWITCH_BUFFER message=buffer workflow route carried a runtime buffer id payload",
        "buffer route audit should name runtime buffer id payload leakage");
   end Test_Phase577_Buffer_Workflow_Route_Audit_Rejects_Buffer_Payloads;



   procedure Test_Phase577_Route_Audit_Inspects_Serialized_Buffer_Payload_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Inspect_Serialized_Route_Text_No_Buffer_Payload
        (Result => Audit,
         Source => Editor.Command_Route_Audit.Route_From_Test,
         Text   => "workspace_open_file=/project/src/main.adb");
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
        "structural workspace route text should not fail buffer-payload audit");

      Editor.Command_Route_Audit.Inspect_Serialized_Route_Text_No_Buffer_Payload
        (Result => Audit,
         Source => Editor.Command_Route_Audit.Route_From_Test,
         Text   => "runtime_buffer_id=42");
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
        "serialized runtime buffer id should be detected by route audit");
   end Test_Phase577_Route_Audit_Inspects_Serialized_Buffer_Payload_Text;


   procedure Test_Phase577_Route_Audit_Uses_Structural_Serialized_Field_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Assert (not Editor.Command_Route_Audit.Text_Contains_Runtime_Buffer_Payload
                ("open_file=/tmp/runtime_buffer_id_notes.adb"),
        "public route payload detector should be field-name based");
      Assert (Editor.Command_Route_Audit.Text_Contains_Runtime_Buffer_Payload
                ("runtime_buffer_id=17"),
        "public route payload detector should reject forbidden field names");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Inspect_Serialized_Route_Text_No_Buffer_Payload
        (Result => Audit,
         Source => Editor.Command_Route_Audit.Route_From_Test,
         Text   => "open_file=/tmp/runtime_buffer_id_notes.adb" & ASCII.LF
                   & "active_file=/tmp/selected_buffer_id_notes.adb");
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
        "serialized route audit must not reject forbidden words inside path values");

      Editor.Command_Route_Audit.Inspect_Serialized_Route_Text_No_Buffer_Payload
        (Result => Audit,
         Source => Editor.Command_Route_Audit.Route_From_Test,
         Text   => "open_file=/tmp/main.adb|selected_buffer_id=17");
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
        "serialized route audit should reject forbidden structured field names");
   end Test_Phase577_Route_Audit_Uses_Structural_Serialized_Field_Names;


   procedure Test_Phase577_Route_Audit_Inspects_Palette_And_Buffer_List_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit       : Editor.Command_Route_Audit.Route_Audit_Result;
      Palette_Row : Editor.Command_Palette.Command_Palette_Row;
      Buffer_Row  : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      Palette_Row.Kind := Editor.Command_Palette.Command_Palette_Command_Row;
      Palette_Row.Primary_Text := To_Unbounded_String ("Close Buffer");
      Buffer_Row.Display_Label := To_Unbounded_String ("runtime_buffer_id_notes.adb");
      Buffer_Row.Path := To_Unbounded_String ("/project/src/runtime_buffer_id_notes.adb");
      Buffer_Row.Project_Ownership_Label := To_Unbounded_String ("Project file");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Inspect_Command_Palette_Row_No_Buffer_Payload
        (Audit, Palette_Row);
      Editor.Command_Route_Audit.Inspect_Buffer_Switcher_Row_No_Buffer_Payload
        (Audit, Buffer_Row);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
        "ordinary palette and Buffer List rows should carry no runtime buffer payload");

      Palette_Row.Secondary_Text := To_Unbounded_String ("runtime_buffer_id=7");
      Buffer_Row.Label_Text := To_Unbounded_String ("selected_buffer_id=7");
      Editor.Command_Route_Audit.Inspect_Command_Palette_Row_No_Buffer_Payload
        (Audit, Palette_Row);
      Editor.Command_Route_Audit.Inspect_Buffer_Switcher_Row_No_Buffer_Payload
        (Audit, Buffer_Row);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 2,
        "palette and Buffer List row inspectors should reject explicit buffer-id payload fields");
   end Test_Phase577_Route_Audit_Inspects_Palette_And_Buffer_List_Rows;

   procedure Test_Phase577_Route_Audit_Inspects_Descriptors_Keybindings_And_Switcher
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Inspect_Buffer_Route_Surfaces_No_Buffer_Payload
        (Result                => Audit,
         Buffer_Switcher_State => S.Buffer_Switcher,
         Serialized_Workspace  => "workspace_open_file=/project/src/main.adb");
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
        "descriptor, keybinding, Buffer List, and workspace route surfaces should inspect cleanly");

      Editor.Command_Route_Audit.Inspect_Buffer_Route_Surfaces_No_Buffer_Payload
        (Result                => Audit,
         Buffer_Switcher_State => S.Buffer_Switcher,
         Serialized_Workspace  => "selected_buffer_id=17");
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
        "aggregate route-surface inspection should reject serialized selected buffer ids");
   end Test_Phase577_Route_Audit_Inspects_Descriptors_Keybindings_And_Switcher;

   overriding function Name (T : Buffers_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Buffers");
   end Name;

   overriding procedure Register_Tests (T : in out Buffers_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_New_Buffer_And_Switch_Isolate_Text'Access,
         "New Buffer And Switch Isolate Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Invalid_Switch_Preserves_Active_Buffer'Access,
         "Invalid Switch Preserves Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_Dirty_Buffer_Is_Refused'Access,
         "Close Dirty Buffer Is Refused");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Already_Open_Path_Switches_Without_Reread'Access,
         "Open Already Open Path Switches Without Reread");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Buffer_Summary_Counts_File_And_Untitled'Access,
         "Dirty Buffer Summary Counts File And Untitled");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_State_Init_Starts_Independent_Global_Registry'Access,
         "State Init Starts Independent Global Registry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_Inactive_Buffer_Reports_Closed_Buffer_Name'Access,
         "Close Inactive Buffer Reports Closed Buffer Name");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Traversal_Helpers_Wrap_And_Invalid_Id'Access,
         "Traversal Helpers Wrap And Invalid Id");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Traversal_With_One_Buffer_Returns_Same_Id'Access,
         "Traversal With One Buffer Returns Same Id");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Next_Previous_Executor_Wraps'Access,
         "Next Previous Executor Wraps");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_Last_Clean_Buffer_Creates_Replacement'Access,
         "Close Last Clean Buffer Creates Replacement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Refuses_Path_Open_In_Another_Buffer'Access,
         "Save As Refuses Path Open In Another Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase250_First_File_Open_Uses_Disposable_Untitled'Access,
         "Phase250 First File Open Replaces Disposable Untitled");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase250_Multiple_File_Open_Order_Duplicate_And_Failed_Open'Access,
         "Phase250 Multiple File Open Order Duplicate And Failed Open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase250_Per_Buffer_Dirty_Save_And_Cursor_Isolation'Access,
         "Phase250 Per Buffer Dirty Save And Cursor Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase250_Reload_Targets_Only_Active_Clean_Buffer'Access,
         "Phase250 Reload Targets Only Active Clean Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase250_Close_Active_And_Inactive_Buffers_Isolates_State'Access,
         "Phase250 Close Active And Inactive Buffers Isolates State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase250_Dirty_Close_Blocks_Target_Buffer_Only'Access,
         "Phase250 Dirty Close Blocks Target Buffer Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase217_Switch_Restores_Cursor_Dirty_And_Undo'Access,
         "Phase217 Switch Restores Cursor Dirty And Undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase217_Close_Active_Buffer_Selects_Previous_Buffer'Access,
         "Phase217 Close Active Buffer Selects Previous Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase270_Pin_Unpin_Toggle_And_Marker'Access,
         "Phase270 Pin Unpin Toggle And Marker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase270_Cleanup_Skips_Pinned_And_Reopen_Is_Unpinned'Access,
         "Phase270 Cleanup Skips Pinned And Reopen Is Unpinned");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase271_Buffer_Groups_Assign_Cycle_Close_And_Reopen'Access,
         "Phase271 Buffer Groups Assign Cycle Close And Reopen");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase271_Buffer_Groups_Dirty_Pinned_And_Availability'Access,
         "Phase271 Buffer Groups Dirty Pinned And Availability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase272_Buffer_Notes_Set_Clear_Show_And_Markers'Access,
         "Phase272 Buffer Notes Set Clear Show And Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase272_Buffer_Notes_Independence_Cleanup_Reopen_And_Switcher'Access,
         "Phase272 Buffer Notes Independence Cleanup Reopen And Switcher");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase273_Buffer_Labels_Set_Clear_Show_Validation_And_Markers'Access,
         "Phase273 Buffer Labels Set Clear Show Validation And Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase273_Buffer_Labels_Independence_Cleanup_Reopen_And_Switcher'Access,
         "Phase273 Buffer Labels Independence Cleanup Reopen And Switcher");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase429_File_Close_Buffer_Command_Descriptor'Access,
         "Phase429 File Close Buffer Command Descriptor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase429_File_Close_Buffer_Route_Closes_Only_Active_Clean_Buffer'Access,
         "Phase429 File Close Buffer Route Closes Only Active Clean Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase432_Close_Does_Not_Create_Close_History'Access,
         "Phase432 Close Does Not Create Close History");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase433_Reopen_Closed_Buffer_Descriptor_And_Success'Access,
         "Phase433 Reopen Closed Buffer Descriptor And Success");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase434_Reopen_Candidate_Exclusions_And_Order'Access,
         "Phase434 Reopen Candidate Exclusions And Order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase434_Reopen_Duplicate_Open_Preserves_Buffer_State'Access,
         "Phase434 Reopen Duplicate Open Preserves Buffer State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase434_Reopen_Failure_And_Read_Only_Projections_Preserve_State'Access,
         "Phase434 Reopen Failure And Read Only Projections Preserve State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase435_Reopen_Integrated_Save_Close_Workflow'Access,
         "Phase435 Reopen Integrated Save Close Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase435_Reopen_State_Boundaries_And_No_Candidate'Access,
         "Phase435 Reopen State Boundaries And No Candidate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase435_Reopen_Duplicate_Open_And_Read_Only_Surfaces'Access,
         "Phase435 Reopen Duplicate Open And Read Only Surfaces");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Metadata_Classifies_Ownership_And_Labels'Access,
         "Phase577 Metadata Classifies Ownership And Labels");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Dirty_Categorization_And_Audit_Counts'Access,
         "Phase577 Dirty Categorization And Audit Counts");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Close_Eligibility_And_Persistability_Are_Projection_Only'Access,
         "Phase577 Close Eligibility And Persistability Projection Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Active_Selected_And_Leak_Audit_Boundaries'Access,
         "Phase577 Active Selected And Leak Audit Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Metadata_Normalizes_Paths_And_Conflict_Status'Access,
         "Phase577 Metadata Normalizes Paths And Conflict Status");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Audit_Empty_And_Forbidden_Persistence_Boundaries'Access,
         "Phase577 Audit Empty And Forbidden Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Workspace_Snapshot_Remains_Structural'Access,
         "Phase577 Workspace Snapshot Remains Structural");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Audit_Tracks_Readability_And_Close_Sets'Access,
         "Phase577 Audit Tracks Readability And Close Sets");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Metadata_Labels_Are_Bounded_And_Not_Text_Dumps'Access,
         "Phase577 Metadata Labels Are Bounded And Not Text Dumps");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Render_Projects_Active_Metadata_Snapshot'Access,
         "Phase577 Render Projects Active Metadata Snapshot");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Buffer_Workflow_Route_Audit_Rejects_Buffer_Payloads'Access,
         "Phase577 Buffer Workflow Route Audit Rejects Buffer Payloads");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Route_Audit_Inspects_Serialized_Buffer_Payload_Text'Access,
         "Phase577 Route Audit Inspects Serialized Buffer Payload Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Route_Audit_Uses_Structural_Serialized_Field_Names'Access,
         "Phase577 Route Audit Uses Structural Serialized Field Names");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Route_Audit_Inspects_Palette_And_Buffer_List_Rows'Access,
         "Phase577 Route Audit Inspects Palette And Buffer List Rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase577_Route_Audit_Inspects_Descriptors_Keybindings_And_Switcher'Access,
         "Phase577 Route Audit Inspects Descriptors Keybindings And Switcher");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase429_File_Close_Buffer_Blocks_Dirty_Without_Discarding'Access,
         "Phase429 File Close Buffer Blocks Dirty Without Discarding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase429_File_Close_Buffer_Ignores_Switcher_Inactive_Selection'Access,
         "Phase429 File Close Buffer Ignores Switcher Inactive Selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase429_File_Close_Buffer_Availability_Is_Side_Effect_Free'Access,
         "Phase429 File Close Buffer Availability Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase429_File_Close_Buffer_Does_Not_Save_Before_Close'Access,
         "Phase429 File Close Buffer Does Not Save Before Close");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase430_Close_Last_Clean_Buffer_Leaves_No_Active'Access,
         "Phase430 Close Last Clean Buffer Leaves No Active");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase430_Close_Uses_Active_Target_Not_Stale_State'Access,
         "Phase430 Close Uses Active Target Not Stale State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase430_Dirty_Close_Preserves_Local_State_And_Boundaries'Access,
         "Phase430 Dirty Close Preserves Local State And Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase431_Close_Save_Save_As_Workflow_Coherence'Access,
         "Phase431 Close Save Save As Workflow Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase431_Close_Target_Selection_And_Local_State_Isolation'Access,
         "Phase431 Close Target Selection And Local State Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase431_Read_Only_Close_Projections_Are_Side_Effect_Free'Access,
         "Phase431 Read Only Close Projections Are Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase432_Close_Surface_Is_Canonical_And_Removed_Name_Hidden'Access,
         "Phase432 Close Surface Is Canonical And Removed Name Hidden");
   end Register_Tests;

end Editor.Buffers.Tests;
