with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Interfaces.C.Strings;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Editor.Buffers;
with Editor.C_API;
with Editor.Commands;
with Editor.Workspace_Persistence;
with Editor.Navigation_History;
with Editor.History;
with Editor.Clipboard;
with Editor.Cursors;
with Editor.Diagnostics;
with Editor.Executor;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Feature_Search_Results;
with Editor.Feature_Diagnostics;
with Editor.Outline;
with Editor.Input_Bridge;
with Editor.Guided_Prompts;
with Editor.Keybindings;
with Editor.Layout;
with Editor.Messages;
with Editor.Panels;
with Editor.Panel_Focus;
with Editor.Project;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Render_Model;
with Editor.State;
with Editor.View;

package body Editor.Input_Bridge.Tests is

   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Cursors.Cursor_Index;
   use type Editor.Diagnostics.Diagnostic_Index;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Input_Bridge.Text_Entry_Focus_Target;
   use type Editor.Input_Bridge.Text_Entry_Route_Result;
   use type Editor.Commands.Command_Id;
   use type Editor.Guided_Prompts.Prompt_Kind;
   use type Editor.Guided_Prompts.Prompt_Validation_State;
   use type Interfaces.C.Strings.chars_ptr;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", "phase57_input_" & Name);
   end Temp_Path;

   procedure Remove_File_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_File_If_Exists;

   procedure Remove_Dir_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Directory (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_Dir_If_Exists;



   function Text_Command (Text : String) return Editor.Commands.Command is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Text := To_Unbounded_String (Text);
      if Text'Length = 1 then
         Cmd.Ch := Text (Text'First);
      end if;
      return Cmd;
   end Text_Command;

   function Kind_Command
     (Kind : Editor.Commands.Command_Kind) return Editor.Commands.Command
   is
      Cmd : Editor.Commands.Command;
   begin
      Cmd.Kind := Kind;
      return Cmd;
   end Kind_Command;

   procedure Set_Primary_Caret
     (S      : in out Editor.State.State_Type;
      Pos    : Editor.Cursors.Cursor_Index;
      Anchor : Editor.Cursors.Cursor_Index)
   is
      C : Editor.Cursors.Caret_State;
   begin
      C.Pos := Pos;
      C.Anchor := Anchor;
      if S.Carets.Is_Empty then
         S.Carets.Append (C);
      else
         S.Carets.Replace_Element (S.Carets.First_Index, C);
      end if;
   end Set_Primary_Caret;

   procedure Write_Bytes (Path : String; Bytes : String) is
      F : Stream_IO.File_Type;
      Raw : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Bytes'Length));
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      for I in Bytes'Range loop
         Raw (Ada.Streams.Stream_Element_Offset (I - Bytes'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Bytes (I)));
      end loop;
      if Bytes'Length > 0 then
         Stream_IO.Write (F, Raw);
      end if;
      Stream_IO.Close (F);
   end Write_Bytes;

   procedure Build_Fixture (Root : String) is
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (A_Dir, "nested.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_Dir_If_Exists (A_Dir);
      Remove_Dir_If_Exists (Root);

      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (A_Dir);
      Write_Bytes (Ada.Directories.Compose (A_Dir, "nested.txt"), "nested");
      Write_Bytes (Ada.Directories.Compose (Root, "a.txt"), "a");
   end Build_Fixture;

   procedure Cleanup_Fixture (Root : String) is
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (A_Dir, "nested.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_Dir_If_Exists (A_Dir);
      Remove_Dir_If_Exists (Root);
   end Cleanup_Fixture;

   function Pointer_Click (X, Y : Natural) return Editor.Commands.Command is
   begin
      return
        (Kind    => Editor.Commands.Move_To_Point,
         Click_X => X,
         Click_Y => Y,
         others  => <>);
   end Pointer_Click;

   function Select_Word_Click (X, Y : Natural) return Editor.Commands.Command is
   begin
      return
        (Kind    => Editor.Commands.Select_Word_At_Point,
         Click_X => X,
         Click_Y => Y,
         others  => <>);
   end Select_Word_Click;

   function Pointer_Drag (X, Y : Natural) return Editor.Commands.Command is
   begin
      return
        (Kind    => Editor.Commands.Drag_To_Point,
         Click_X => X,
         Click_Y => Y,
         others  => <>);
   end Pointer_Drag;

   overriding function Name
     (T : Input_Bridge_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Input_Bridge");
   end Name;

   procedure Test_File_Tree_Directory_Click_Toggles_Expansion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("toggle_root");
      S    : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      A_Dir : Editor.File_Tree.File_Tree_Node_Id;
      Found : Boolean := False;
      Layout : Editor.Layout.Layout_Config;
      X : Natural;
      Y : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.State.Init (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "fixture project must open before file tree activation");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.View.Set_Viewport (Width => 800, Height => 480);
      A_Dir := Editor.File_Tree.Find_By_Path (S.File_Tree, "a_dir", Found);
      Assert (Found, "fixture must contain a_dir");
      Assert (not Editor.File_Tree.Node (S.File_Tree, A_Dir).Is_Expanded,
              "fixture directory must start collapsed");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Layout := Editor.Layout.Current;
      X := Natural (Editor.Layout.File_Tree_X (Layout))
        + 5 * Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.File_Tree_Y (Layout))
        + Editor.Layout.Cell_H + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.File_Tree.Node (After.File_Tree, A_Dir).Is_Expanded,
              "clicking a visible directory row must toggle expansion through Input_Bridge");
      Assert (Editor.File_Tree.Visible_Row_Count (After.File_Tree)
              > Editor.File_Tree.Visible_Row_Count (S.File_Tree),
              "directory click must rebuild visible rows after expansion");

      Cleanup_Fixture (Root);
   end Test_File_Tree_Directory_Click_Toggles_Expansion;

   procedure Test_File_Tree_File_Click_Opens_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("open_root");
      S    : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Found : Boolean := False;
      Layout : Editor.Layout.Layout_Config;
      X : Natural;
      Y : Natural;
      Count_After_First_Click : Natural;
      Active_After_First_Click : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.State.Init (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "fixture project must open before file tree activation");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.View.Set_Viewport (Width => 800, Height => 480);
      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Layout := Editor.Layout.Current;
      X := Natural (Editor.Layout.File_Tree_X (Layout))
        + 5 * Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.File_Tree_Y (Layout))
        + 2 * Editor.Layout.Cell_H + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Count_After_First_Click := Editor.Buffers.Global_Count;
      Active_After_First_Click := Editor.Buffers.Global_Active_Buffer;

      Assert (After.File_Info.Has_Path,
              "clicking a visible file row must open a file-backed active buffer");
      Assert (To_String (After.File_Info.Display_Name) = "a.txt",
              "file tree file click must make clicked file the active file");
      Assert (Count_After_First_Click >= 1,
              "file tree file click must leave a valid buffer registry");

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      Assert (Editor.Buffers.Global_Count = Count_After_First_Click,
              "clicking an already-open file tree row must switch, not duplicate buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = Active_After_First_Click,
              "clicking the already-active file tree row must keep that buffer active");

      Cleanup_Fixture (Root);
   end Test_File_Tree_File_Click_Opens_Buffer;

   procedure Test_File_Tree_Background_Click_Is_Handled_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("background_root");
      S    : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      X : Natural;
      Y : Natural;
      Caret_Before : Editor.Cursors.Caret_State;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.View.Set_Viewport (Width => 800, Height => 480);
      Caret_Before := S.Carets (S.Carets.First_Index);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Layout := Editor.Layout.Current;
      X := Natural (Editor.Layout.File_Tree_X (Layout)) + Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.File_Tree_Y (Layout))
        + 6 * Editor.Layout.Cell_H + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.State.Current_Text (After) = Editor.State.Current_Text (S),
              "file tree background click must not mutate document text");
      Assert (After.Carets (After.Carets.First_Index).Pos = Caret_Before.Pos,
              "file tree background click must not move caret");
      Assert (After.Carets (After.Carets.First_Index).Anchor = Caret_Before.Anchor,
              "file tree background click must not start text selection");
      Assert (Editor.File_Tree.Visible_Row_Count (After.File_Tree)
              = Editor.File_Tree.Visible_Row_Count (S.File_Tree),
              "file tree background click must not mutate expansion state");

      Cleanup_Fixture (Root);
   end Test_File_Tree_Background_Click_Is_Handled_No_Op;

   procedure Test_Disabled_File_Tree_Does_Not_Consume_Text_Click
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      After : Editor.State.State_Type;
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Layout : Editor.Layout.Layout_Config;
      X : Natural;
      Y : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Config.Enabled := False;

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.File_Tree_View.Set_Current_Config (Config);
      Layout := Editor.Layout.Current;
      X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S))
        + 2 * Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert (After.Carets (After.Carets.First_Index).Pos /=
              S.Carets (S.Carets.First_Index).Pos,
              "with file tree disabled and zero width, ordinary text clicks must route to text");
   end Test_Disabled_File_Tree_Does_Not_Consume_Text_Click;

   procedure Test_File_Tree_Splitter_Drag_Resizes_By_Columns
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Layout : Editor.Layout.Layout_Config;
      Start_X : Natural;
      Start_Y : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);

      Editor.File_Tree_View.Reset;
      Config := Editor.File_Tree_View.Current_Config;
      Editor.File_Tree_View.Set_Current_Config (Config);
      Editor.File_Tree_View.Set_Current_Width_In_Columns (28);
      Layout := Editor.Layout.Current;
      Start_X := Natural (Editor.Layout.File_Tree_Splitter_X (Layout));
      Start_Y := Natural (Editor.Layout.File_Tree_Splitter_Y (Layout)) + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (Start_X, Start_Y));
      Editor.Input_Bridge.Handle
        (Pointer_Drag (Start_X + Editor.Layout.Cell_W - 1, Start_Y));
      Assert (Editor.File_Tree_View.Current_Width_In_Columns = 28,
              "splitter drag under one cell must not resize the sidebar");

      Editor.Input_Bridge.Handle
        (Pointer_Drag (Start_X + Editor.Layout.Cell_W, Start_Y));
      Assert (Editor.File_Tree_View.Current_Width_In_Columns = 29,
              "splitter drag right by one cell must increase sidebar width by one column");

      Editor.Input_Bridge.Handle
        (Pointer_Drag (Start_X - Editor.Layout.Cell_W, Start_Y));
      Assert (Editor.File_Tree_View.Current_Width_In_Columns = 27,
              "splitter drag left from start by one cell must decrease sidebar width by one column");
   end Test_File_Tree_Splitter_Drag_Resizes_By_Columns;


   procedure Test_File_Tree_Splitter_Release_Restores_Text_Routing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      Start_X : Natural;
      Start_Y : Natural;
      Text_X  : Natural;
      Text_Y  : Natural;
      Release : Editor.Commands.Command :=
        (Kind => Editor.Commands.Break_Group, others => <>);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);
      Editor.File_Tree_View.Reset;
      Editor.File_Tree_View.Set_Current_Width_In_Columns (28);

      Layout := Editor.Layout.Current;
      Start_X := Natural (Editor.Layout.File_Tree_Splitter_X (Layout));
      Start_Y := Natural (Editor.Layout.File_Tree_Splitter_Y (Layout)) + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (Start_X, Start_Y));
      Editor.Input_Bridge.Handle
        (Pointer_Drag (Start_X + Editor.Layout.Cell_W, Start_Y));
      Editor.Input_Bridge.Handle (Release);

      Layout := Editor.Layout.Current;
      Text_X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S))
        + Editor.Layout.Cell_W;
      Text_Y := Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + Editor.Layout.Cell_H / 2;

      Editor.Input_Bridge.Handle (Pointer_Click (Text_X, Text_Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (After.Carets (After.Carets.First_Index).Pos /=
         S.Carets (S.Carets.First_Index).Pos,
         "splitter release must end resize capture so later text clicks route normally");
   end Test_File_Tree_Splitter_Release_Restores_Text_Routing;

   procedure Test_Disabled_File_Tree_Prevents_Splitter_Resize
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Layout : Editor.Layout.Layout_Config;
      X : Natural;
      Y : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);
      Editor.File_Tree_View.Reset;
      Config := Editor.File_Tree_View.Current_Config;
      Editor.File_Tree_View.Set_Current_Width_In_Columns (28);
      Config.Enabled := False;
      Editor.File_Tree_View.Set_Current_Config (Config);
      Layout := Editor.Layout.Current;
      X := Layout.Origin_X;
      Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      Editor.Input_Bridge.Handle (Pointer_Drag (X + 10 * Editor.Layout.Cell_W, Y));

      declare
         View_State : constant Editor.File_Tree_View.File_Tree_View_State :=
           Editor.File_Tree_View.Current_State;
      begin
         Assert (View_State.Width_In_Columns = 28,
                 "disabled file tree must preserve stored width and prevent splitter resize");
      end;
      Assert (Editor.File_Tree_View.Current_Width_In_Columns = 0,
              "disabled file tree must still expose zero effective width");
   end Test_Disabled_File_Tree_Prevents_Splitter_Resize;


   procedure Test_Problems_Panel_Click_Is_Handled_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      Panel  : Editor.Layout.Rect;
      X      : Natural;
      Y      : Natural;
      Before_Pos : Editor.Cursors.Cursor_Index;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panels.Set_Current (S.Panels);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);

      Layout := Editor.Layout.Current;
      Panel := Editor.Layout.Panel_Rect
        (Layout, Editor.Panels.Bottom_Panel,
         Editor.View.Viewport_Width, Editor.View.Viewport_Height);
      X := Natural (Panel.X) + Editor.Layout.Cell_W;
      Y := Natural (Panel.Y) + Editor.Layout.Cell_H;
      Before_Pos := S.Carets (S.Carets.First_Index).Pos;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (After.Carets (After.Carets.First_Index).Pos = Before_Pos,
         "clicking inside the Problems panel must be handled as a no-op and not move the caret");

      Editor.Panels.Initialize_Defaults (S.Panels);
      Editor.Panels.Set_Current (S.Panels);
   end Test_Problems_Panel_Click_Is_Handled_No_Op;



   procedure Test_Problems_Row_Click_Jumps_To_Diagnostic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      Panel  : Editor.Layout.Rect;
      X      : Natural;
      Y      : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 5, End_Index => 6,
         Severity => Editor.Diagnostics.Error,
         Message => "bad");
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panels.Set_Current (S.Panels);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);

      Layout := Editor.Layout.Current;
      Panel := Editor.Layout.Panel_Rect
        (Layout, Editor.Panels.Bottom_Panel,
         Editor.View.Viewport_Width, Editor.View.Viewport_Height);
      X := Natural (Panel.X) + Editor.Layout.Cell_W;
      Y := Natural (Panel.Y) + Editor.Layout.Cell_H + Editor.Layout.Cell_H / 2;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (After.Carets (After.Carets.First_Index).Pos = 5,
         "clicking a Problems row must jump through diagnostic navigation");
      Assert
        (After.Active_Diagnostic.Has_Active and then After.Active_Diagnostic.Index = 1,
         "Problems row click must set the active diagnostic");

      Editor.Panels.Initialize_Defaults (S.Panels);
      Editor.Panels.Set_Current (S.Panels);
   end Test_Problems_Row_Click_Jumps_To_Diagnostic;


   procedure Test_Phase66_Text_Double_Click_Selects_Word
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      X      : Natural;
      Y      : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Layout := Editor.Layout.Current;
      X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S))
        + 2 * Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + 1;

      Editor.Input_Bridge.Handle (Select_Word_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (After.Carets (After.Carets.First_Index).Anchor = 0
         and then After.Carets (After.Carets.First_Index).Pos = 5,
         "double-click routed to text must select the clicked word");
      Assert
        (Editor.State.Current_Text (After) = Editor.State.Current_Text (S),
         "double-click word selection must not mutate text");
   end Test_Phase66_Text_Double_Click_Selects_Word;

   procedure Test_Phase66_File_Tree_Double_Click_Does_Not_Select_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase66_tree_double_click_root");
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      X      : Natural;
      Y      : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha beta");
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.View.Set_Viewport (Width => 800, Height => 480);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Layout := Editor.Layout.Current;
      X := Natural (Editor.Layout.File_Tree_X (Layout)) + Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.File_Tree_Y (Layout)) + 6 * Editor.Layout.Cell_H + 1;

      Editor.Input_Bridge.Handle (Select_Word_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (After.Carets (After.Carets.First_Index).Anchor =
         S.Carets (S.Carets.First_Index).Anchor
         and then After.Carets (After.Carets.First_Index).Pos =
         S.Carets (S.Carets.First_Index).Pos,
         "file tree double-click must not select an editor word");

      Cleanup_Fixture (Root);
   end Test_Phase66_File_Tree_Double_Click_Does_Not_Select_Text;

   procedure Test_Phase76_Search_Results_Focus_Captures_Down_Key
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase76_input_focus_root");
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Before_Pos : Editor.Cursors.Cursor_Index;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Before_Pos := S.Carets (S.Carets.First_Index).Pos;

      Editor.Executor.Execute_Open_Project (S, Root);
      Editor.Executor.Execute_Run_Project_Search (S, "a");
      Editor.Executor.Execute_Focus_Search_Results (S);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle_Key_Chord
        ((Key       => Editor.Keybindings.Key_Down,
          Modifiers => (others => False)));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (After.Carets (After.Carets.First_Index).Pos = Before_Pos,
         "Phase 76 focused Search Results Down key must not move the editor caret");
      Assert
        (Editor.Panel_Focus.Bottom_Content (After.Panel_Focus) =
           Editor.Panel_Focus.Search_Results_Focus,
         "Phase 76 focused Search Results Down key should keep Search Results focus");
      Assert
        (Editor.Project_Search.Selected_Result_Index (After.Project_Search) = 1,
         "Phase 76 one-result Down key should leave the Search Results selection stable");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase76_Search_Results_Focus_Captures_Down_Key;


   procedure Test_Phase221_Search_Query_Input_Consumes_Text_Before_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Snap   : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Editor.Feature_Search_Results.Activate_Search_Query_Input
        (S.Feature_Search_Results);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String (String'(1 => 'x'));
      Editor.Input_Bridge.Handle (Cmd);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Length = 3,
         "Phase 221 active Search query input must prevent accidental buffer edits");
      Assert
        (Editor.Feature_Search_Results.Search_Input_Text
           (After.Feature_Search_Results) = "x",
         "Phase 221 typed text must be routed to the active Search query input");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase221_Search_Query_Input_Consumes_Text_Before_Buffer;

   procedure Test_Phase221_Outline_Filter_Input_Consumes_Text_Before_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Snap   : Editor.Render_Model.Render_Snapshot;
      Items  : constant Editor.Outline.Outline_Item_Array :=
        (1 =>
           (Kind        => Editor.Outline.Outline_Procedure,
            Label       => To_Unbounded_String ("Yield_Model"),
            Detail      => To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Editor.Outline.Buffer_Position_Target,
            Buffer_Token => 1,
            Line         => 1,
            Column       => 1));
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Editor.Outline.Replace_Items (S.Outline, Items);
      Editor.Outline.Activate_Filter_Input (S.Outline);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'y';
      Cmd.Text := To_Unbounded_String (String'(1 => 'y'));
      Editor.Input_Bridge.Handle (Cmd);
      After := Editor.Input_Bridge.Get_State_For_Test;
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);

      Assert
        (Snap.Length = 3,
         "Phase 221 active Outline filter must prevent accidental buffer edits");
      Assert
        (Editor.Outline.Filter_Text (After.Outline) = "y",
         "Phase 221 typed text must be routed to the active Outline filter");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase221_Outline_Filter_Input_Consumes_Text_Before_Buffer;

   procedure Test_Phase230_Feature_Panel_Search_Click_Selects_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      Width  : Natural;
      X      : Natural;
      Y      : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "alpha", "buffer", True, S.Active_Buffer_Token, 1, 1);
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "beta", "buffer", True, S.Active_Buffer_Token, 2, 1);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 0);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);

      Layout := Editor.Layout.Current;
      Width := Natural'Min (280, Editor.View.Viewport_Width);
      X := Editor.View.Viewport_Width - Width + Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + 2 * Editor.Layout.Cell_H + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (Editor.Feature_Panel.Active_Feature (After.Feature_Panel) =
         Editor.Feature_Panel.Search_Results_Feature,
         "Phase 230 search-result mouse click must keep Search Results as the active feature");
      Assert
        (Editor.Feature_Panel.Selected_Row (After.Feature_Panel) = 2,
         "Phase 230 search-result mouse click must select the clicked feature row");
      Assert
        (After.Carets (After.Carets.First_Index).Pos =
         S.Carets (S.Carets.First_Index).Pos,
         "Phase 230 single-clicking a Search Results row must not activate the target");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase230_Feature_Panel_Search_Click_Selects_Row;

   procedure Test_Phase230_Feature_Panel_Search_Double_Click_Activates_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      Width  : Natural;
      X      : Natural;
      Y      : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      Editor.Feature_Search_Results.Add_Search_Result
        (S.Feature_Search_Results, "beta", "buffer", True, S.Active_Buffer_Token, 2, 2);
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);

      Layout := Editor.Layout.Current;
      Width := Natural'Min (280, Editor.View.Viewport_Width);
      X := Editor.View.Viewport_Width - Width + Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + Editor.Layout.Cell_H + 1;

      Editor.Input_Bridge.Handle (Select_Word_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (After.Carets (After.Carets.First_Index).Pos = 7,
         "Phase 230 double-clicking a Search Results feature row must activate through the search-result target path");
      Assert
        (Editor.Feature_Panel.Selected_Row (After.Feature_Panel) = 1,
         "Phase 230 Search Results activation must select the activated feature row");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase230_Feature_Panel_Search_Double_Click_Activates_Row;

   procedure Test_Phase230_Feature_Panel_Diagnostics_Click_Selects_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Layout : Editor.Layout.Layout_Config;
      Width  : Natural;
      X      : Natural;
      Y      : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Warning,
         "first", "buffer", Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         True, S.Registry_Token, 1, 1);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error,
         "second", "buffer", Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         True, S.Registry_Token, 2, 1);
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);

      Layout := Editor.Layout.Current;
      Width := Natural'Min (280, Editor.View.Viewport_Width);
      X := Editor.View.Viewport_Width - Width + Editor.Layout.Cell_W;
      Y := Natural (Editor.Layout.Text_Viewport_Y (Layout))
        + 2 * Editor.Layout.Cell_H + 1;

      Editor.Input_Bridge.Handle (Pointer_Click (X, Y));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (Editor.Feature_Panel.Active_Feature (After.Feature_Panel) =
         Editor.Feature_Panel.Diagnostics_Feature,
         "Phase 230 diagnostics mouse click must keep Diagnostics as the active feature");
      Assert
        (Editor.Feature_Panel.Selected_Row (After.Feature_Panel) = 2,
         "Phase 230 diagnostics mouse click must select the clicked feature row");
      Assert
        (After.Carets (After.Carets.First_Index).Pos =
         S.Carets (S.Carets.First_Index).Pos,
         "Phase 230 single-clicking a Diagnostics row must not activate the target");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase230_Feature_Panel_Diagnostics_Click_Selects_Row;


   procedure Test_Phase231_Wheel_Over_Editor_Scrolls_Viewport_Not_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      X      : Natural;
      Y      : Natural;
      Before : Editor.Cursors.Cursor_Index;
      After  : Editor.State.State_Type;
   begin
      Editor.Input_Bridge.Reset;
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S,
         "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF &
         "3" & ASCII.LF & "4" & ASCII.LF & "5" & ASCII.LF &
         "6" & ASCII.LF & "7" & ASCII.LF & "8" & ASCII.LF & "9");
      Editor.View.Reset_Scroll;
      Editor.View.Set_Viewport (Width => 800, Height => Editor.Layout.Cell_H * 4);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Before := S.Carets (S.Carets.First_Index).Pos;

      X := Editor.Layout.Text_Origin_X (Layout, Editor.State.Line_Count (S)) + 1;
      Y := Natural (Editor.Layout.Text_Viewport_Y (Layout)) + Editor.Layout.Cell_H + 1;
      Editor.Input_Bridge.Handle_Wheel (X, Y, 0, -1);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.View.Scroll_Y = 3,
              "wheel down over editor advances the editor viewport deterministically");
      Assert (After.Carets (After.Carets.First_Index).Pos = Before,
              "wheel scrolling editor text does not move the caret");
   end Test_Phase231_Wheel_Over_Editor_Scrolls_Viewport_Not_Caret;


   procedure Test_Phase239_Reload_Command_Id_Uses_Canonical_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path  : constant String := Temp_Path ("phase239_reload_keybinding.txt");
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File_If_Exists (Path);
      Write_Bytes (Path, "old");

      Editor.State.Init (S);
      Editor.Executor.Execute_Open_File (S, Path);
      Write_Bytes (Path, "new");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Reload_Active_Buffer);
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.State.Current_Text (After) = "new",
              "Phase 239: keybinding/command-id reload must use the same reload path as the Executor");
      Assert (not After.File_Info.Dirty,
              "Phase 239: successful command-id reload keeps the clean reload policy");

      Remove_File_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase239_Reload_Command_Id_Uses_Canonical_Path;



   procedure Test_Phase417_Text_Entry_Route_Preview_Is_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Text : Unbounded_String;
      Before_Caret : Editor.Cursors.Caret_State;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Set_Primary_Caret (S, 1, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Caret := S.Carets (S.Carets.First_Index);

      Assert
        (Editor.Input_Bridge.Resolve_Text_Entry_Focus_Target =
         Editor.Input_Bridge.Text_Entry_Editor_Buffer,
         "Phase 417 editor focus must classify as the editor text-entry owner");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command ("x")) =
         Editor.Input_Bridge.Routed_To_Text_Insert,
         "Phase 417 ordinary text must route to canonical Text Insert");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Selection_Range)) =
         Editor.Input_Bridge.Routed_To_Selection_Delete,
         "Phase 417 explicit selection delete must route to Selection Delete");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Char)) =
         Editor.Input_Bridge.Routed_To_Delete_Previous_Character,
         "Phase 417 previous Backspace input kind must canonicalize to previous-character delete");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Forward_Delete_Char)) =
         Editor.Input_Bridge.Routed_To_Delete_Next_Character,
         "Phase 417 previous Delete input kind must canonicalize to next-character delete");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Previous_Word)) =
         Editor.Input_Bridge.Routed_To_Delete_Previous_Word,
         "Phase 417 previous-word delete must route to canonical Word Delete previous");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Next_Word)) =
         Editor.Input_Bridge.Routed_To_Delete_Next_Word,
         "Phase 417 next-word delete must route to canonical Word Delete next");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command (String'(1 => ASCII.LF))) =
         Editor.Input_Bridge.Routed_To_Text_Insert,
         "Phase 417 retained line-break policy routes newline payloads to Text Insert, not Line Split");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Split_Current_Line_At_Caret)) =
         Editor.Input_Bridge.Routed_To_Line_Split,
         "Phase 417 explicit Line Split remains a separate canonical route");

      declare
         After : constant Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
      begin
         Assert
           (Editor.State.Current_Text (After) = To_String (Before_Text),
            "Phase 417 route preview must not mutate active-buffer text");
         Assert
           (After.Carets (After.Carets.First_Index).Pos = Before_Caret.Pos
            and then After.Carets (After.Carets.First_Index).Anchor = Before_Caret.Anchor,
            "Phase 417 route preview must not normalize or move caret/selection");
      end;
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase417_Text_Entry_Route_Preview_Is_Canonical;

   procedure Test_Phase417_Overlay_Input_Remains_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command ("z")) =
         Editor.Input_Bridge.Routed_To_Overlay_Input,
         "Phase 417 overlay focus must be resolved before editor text mutation routing");

      Editor.Input_Bridge.Handle (Text_Command ("z"));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert
        (Editor.State.Current_Text (After) = "abc",
         "Phase 417 overlay text input must not leak into active-buffer Text Insert");
      Assert
        (Editor.Quick_Open.Query_Text (After.Quick_Open) = "z",
         "Phase 417 Quick Open input must remain local under overlay focus");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase417_Overlay_Input_Remains_Local;

   procedure Test_Phase417_Editor_Text_Workflow_Mutates_Through_Canonical_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Set_Primary_Caret (S, 1, 2);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle (Text_Command ("X"));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.State.Current_Text (After) = "aXc",
         "Phase 417 ordinary text with active selection must reach canonical Text Insert replacement");

      Set_Primary_Caret (After, 2, 2);
      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Delete_Char));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.State.Current_Text (After) = "ac",
         "Phase 417 previous-character workflow event must route through canonical Character Delete previous");

      Set_Primary_Caret (After, 1, 1);
      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle (Text_Command (String'(1 => ASCII.LF)));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.State.Current_Text (After) = "a" & ASCII.LF & "c",
         "Phase 417 newline text-entry follows retained Text Insert line-boundary policy exactly once");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase417_Editor_Text_Workflow_Mutates_Through_Canonical_Routes;


   procedure Test_Phase418_Route_Preview_Is_Reliable_And_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      After         : Editor.State.State_Type;
      Before_Text   : Unbounded_String;
      Before_Caret  : Editor.Cursors.Caret_State;
      Before_Back   : Natural := 0;
      Before_Fwd    : Natural := 0;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Alpha Beta");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("Beta");
      S.Active_Replace_Text := To_Unbounded_String ("Gamma");
      S.Active_Find_Stale := False;
      Set_Primary_Caret (S, 5, 5);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Caret := S.Carets (S.Carets.First_Index);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);

      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command ("x")) =
         Editor.Input_Bridge.Routed_To_Text_Insert,
         "Phase 418 preview classifies ordinary payload without executing it");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Previous_Character)) =
         Editor.Input_Bridge.Routed_To_Delete_Previous_Character,
         "Phase 418 preview classifies named previous-character delete canonically");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Next_Character)) =
         Editor.Input_Bridge.Routed_To_Delete_Next_Character,
         "Phase 418 preview classifies named next-character delete canonically");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Previous_Word)) =
         Editor.Input_Bridge.Routed_To_Delete_Previous_Word,
         "Phase 418 preview classifies previous-word delete canonically");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Next_Word)) =
         Editor.Input_Bridge.Routed_To_Delete_Next_Word,
         "Phase 418 preview classifies next-word delete canonically");

      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (After) = To_String (Before_Text),
              "Phase 418 route preview must not mutate active-buffer text");
      Assert
        (After.Carets (After.Carets.First_Index).Pos = Before_Caret.Pos
         and then After.Carets (After.Carets.First_Index).Anchor = Before_Caret.Anchor,
         "Phase 418 route preview must not mutate caret or selection");
      Assert (not Editor.State.Is_Dirty (After),
              "Phase 418 route preview must not dirty active buffers");
      Assert (After.Active_Find_Query = To_Unbounded_String ("Beta")
              and then After.Active_Replace_Text = To_Unbounded_String ("Gamma")
              and then not After.Active_Find_Stale,
              "Phase 418 route preview must not mutate Find/Replace state");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 418 route preview must not mutate Clipboard text");
      Assert (Editor.Navigation_History.Back_Count (After.Navigation_History) = Before_Back
              and then Editor.Navigation_History.Forward_Count (After.Navigation_History) = Before_Fwd,
              "Phase 418 route preview must not record Navigation History");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 418 route preview must not mutate Undo/Redo stacks");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase418_Route_Preview_Is_Reliable_And_Read_Only;

   procedure Test_Phase418_Overlay_Named_Delete_Remains_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      After       : Editor.State.State_Type;
      Undo_Before : Natural := 0;
      Redo_Before : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "Buffer");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Caret (S, 3, 3);
      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command ("a"));
      Editor.Input_Bridge.Handle (Text_Command ("b"));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);

      Assert
        (Editor.Input_Bridge.Resolve_Text_Entry_Focus_Target =
         Editor.Input_Bridge.Text_Entry_Overlay_Input,
         "Phase 418 Quick Open owns text-entry focus before named delete routing");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Previous_Character)) =
         Editor.Input_Bridge.Routed_To_Overlay_Input,
         "Phase 418 named previous-character delete must be classified as overlay-local when overlay owns focus");

      Editor.Input_Bridge.Handle
        (Kind_Command (Editor.Commands.Delete_Previous_Character));
      After := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.State.Current_Text (After) = "Buffer",
              "Phase 418 overlay named delete must not mutate active-buffer text");
      Assert (Editor.Quick_Open.Query_Text (After.Quick_Open) = "a",
              "Phase 418 overlay named delete must use the local input-field delete policy");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before
              and then Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 418 overlay named delete must not mutate active-buffer history");
      Assert (not Editor.State.Is_Dirty (After),
              "Phase 418 overlay named delete must not dirty the active buffer");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase418_Overlay_Named_Delete_Remains_Local;

   procedure Test_Phase418_Redo_Boundaries_Are_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AB");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Caret (S, 1, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle (Text_Command ("X"));
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Undo));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 418 undo after routed Text Insert must make redo available through canonical history");

      S.Carets.Clear;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command ("Y")) =
         Editor.Input_Bridge.No_Caret_Location,
         "Phase 418 no-caret text-entry route must fail before mutation");
      Editor.Input_Bridge.Handle (Text_Command ("Y"));
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 418 no-op/failure workflow route must preserve redo stack");

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command ("q"));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = "q",
              "Phase 418 overlay text input remains local after undo");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 418 overlay local input after undo must preserve active-buffer redo stack");
      Assert (Editor.State.Current_Text (S) = "AB",
              "Phase 418 overlay local input after undo must not change active-buffer text");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase418_Redo_Boundaries_Are_Canonical;

   procedure Test_Phase418_Persistence_Excludes_Workflow_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S         : Editor.State.State_Type;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary   : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Set_Primary_Caret (S, 1, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command ("x"));
      S := Editor.Input_Bridge.Get_State_For_Test;

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "text entry workflow") = 0
         and then Index (Summary, "last input route") = 0
         and then Index (Summary, "last input event") = 0
         and then Index (Summary, "last text-entry payload") = 0
         and then Index (Summary, "routed command") = 0
         and then Index (Summary, "input focus routing history") = 0
         and then Index (Summary, "route audit cache") = 0
         and then Index (Summary, "selection-consuming Backspace") = 0
         and then Index (Summary, "line-break routing policy") = 0,
         "Phase 418 workspace persistence must exclude text-entry workflow transients and policy overrides");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase418_Persistence_Excludes_Workflow_State;

   procedure Test_Phase417_Non_Editor_Focus_Blocks_Text_Entry_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      After : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc");
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command ("q")) =
         Editor.Input_Bridge.No_Editor_Text_Focus,
         "Phase 417 text-entry workflow must require editor text focus");
      Editor.Input_Bridge.Handle (Text_Command ("q"));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.State.Current_Text (After) = "abc",
         "Phase 417 non-editor focus must not mutate the active buffer through text entry");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase417_Non_Editor_Focus_Blocks_Text_Entry_Workflow;



   procedure Assert_Text_Entry_Workflow_Coherent
     (Cmd              : Editor.Commands.Command;
      Expected_Route   : Editor.Input_Bridge.Text_Entry_Route_Result;
      Expected_Command : Editor.Commands.Command_Id;
      Message          : String)
   is
   begin
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Cmd) = Expected_Route,
         Message & ": route result must match retained text-entry workflow policy");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Command_Id (Cmd) = Expected_Command,
         Message & ": canonical command-id preview must match the chosen route");
   end Assert_Text_Entry_Workflow_Coherent;

   procedure Test_Phase419_Focus_Resolution_And_Route_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Text    : Unbounded_String;
      Before_Undo    : Natural := 0;
      Before_Redo    : Natural := 0;
      Before_Back    : Natural := 0;
      Before_Forward : Natural := 0;
      Before_Caret   : Editor.Cursors.Caret_State;
      After          : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc def");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("def");
      S.Active_Replace_Text := To_Unbounded_String ("ghi");
      Set_Primary_Caret (S, 3, 3);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Caret := S.Carets (S.Carets.First_Index);
      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Assert
        (Editor.Input_Bridge.Resolve_Text_Entry_Focus_Target =
         Editor.Input_Bridge.Text_Entry_Editor_Buffer,
         "Phase 419 editor buffer is the focus owner when no overlay/input field is active");
      Assert_Text_Entry_Workflow_Coherent
        (Text_Command ("x"),
         Editor.Input_Bridge.Routed_To_Text_Insert,
         Editor.Commands.No_Command,
         "Phase 419 ordinary editor payload");
      Assert_Text_Entry_Workflow_Coherent
        (Kind_Command (Editor.Commands.Delete_Selection_Range),
         Editor.Input_Bridge.Routed_To_Selection_Delete,
         Editor.Commands.Command_Selection_Delete,
         "Phase 419 explicit selection delete");
      Assert_Text_Entry_Workflow_Coherent
        (Kind_Command (Editor.Commands.Delete_Previous_Character),
         Editor.Input_Bridge.Routed_To_Delete_Previous_Character,
         Editor.Commands.Command_Char_Delete_Previous,
         "Phase 419 previous-character delete");
      Assert_Text_Entry_Workflow_Coherent
        (Kind_Command (Editor.Commands.Delete_Next_Character),
         Editor.Input_Bridge.Routed_To_Delete_Next_Character,
         Editor.Commands.Command_Char_Delete_Next,
         "Phase 419 next-character delete");
      Assert_Text_Entry_Workflow_Coherent
        (Kind_Command (Editor.Commands.Delete_Previous_Word),
         Editor.Input_Bridge.Routed_To_Delete_Previous_Word,
         Editor.Commands.Command_Word_Delete_Previous,
         "Phase 419 previous-word delete");
      Assert_Text_Entry_Workflow_Coherent
        (Kind_Command (Editor.Commands.Delete_Next_Word),
         Editor.Input_Bridge.Routed_To_Delete_Next_Word,
         Editor.Commands.Command_Word_Delete_Next,
         "Phase 419 next-word delete");
      Assert_Text_Entry_Workflow_Coherent
        (Kind_Command (Editor.Commands.Split_Current_Line_At_Caret),
         Editor.Input_Bridge.Routed_To_Line_Split,
         Editor.Commands.Command_Line_Split_At_Caret,
         "Phase 419 explicit line split");
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Move_Left)) =
         Editor.Input_Bridge.Unsupported_Text_Entry_Event,
         "Phase 419 unsupported text-entry event must fail deterministically");

      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (After) = To_String (Before_Text),
              "Phase 419 route previews must not mutate active-buffer text");
      Assert
        (After.Carets (After.Carets.First_Index).Pos = Before_Caret.Pos
         and then After.Carets (After.Carets.First_Index).Anchor = Before_Caret.Anchor,
         "Phase 419 route previews must not repair or normalize focus/caret/selection");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 419 route previews must not mutate Undo/Redo stacks");
      Assert (not Editor.State.Is_Dirty (After),
              "Phase 419 route previews must not dirty active buffers");
      Assert (After.Active_Find_Query = To_Unbounded_String ("def")
              and then After.Active_Replace_Text = To_Unbounded_String ("ghi"),
              "Phase 419 route previews must not mutate Find/Replace state");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 419 route previews must not mutate Clipboard state");
      Assert (Editor.Navigation_History.Back_Count (After.Navigation_History) = Before_Back
              and then Editor.Navigation_History.Forward_Count (After.Navigation_History) = Before_Forward,
              "Phase 419 route previews must not record Navigation History");

      Editor.Executor.Execute_Open_Quick_Open (After);
      Editor.Input_Bridge.Set_State_For_Test (After);
      Assert
        (Editor.Input_Bridge.Resolve_Text_Entry_Focus_Target =
         Editor.Input_Bridge.Text_Entry_Overlay_Input,
         "Phase 419 Quick Open overlay outranks editor text focus");
      Assert_Text_Entry_Workflow_Coherent
        (Text_Command ("q"),
         Editor.Input_Bridge.Routed_To_Overlay_Input,
         Editor.Commands.No_Command,
         "Phase 419 overlay ordinary payload");
      Assert_Text_Entry_Workflow_Coherent
        (Kind_Command (Editor.Commands.Delete_Previous_Character),
         Editor.Input_Bridge.Routed_To_Overlay_Input,
         Editor.Commands.No_Command,
         "Phase 419 overlay previous-character delete");

      Editor.Executor.Execute_Close_Quick_Open (After);
      Editor.Panel_Focus.Focus_File_Tree (After.Panel_Focus);
      Editor.Input_Bridge.Set_State_For_Test (After);
      Assert
        (Editor.Input_Bridge.Resolve_Text_Entry_Focus_Target =
         Editor.Input_Bridge.Text_Entry_No_Target,
         "Phase 419 non-editor focus leaves no text-entry owner");
      Assert_Text_Entry_Workflow_Coherent
        (Text_Command ("q"),
         Editor.Input_Bridge.No_Editor_Text_Focus,
         Editor.Commands.No_Command,
         "Phase 419 no focused text owner");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase419_Focus_Resolution_And_Route_Matrix;

   procedure Test_Phase419_Editor_Routes_Use_Canonical_Owners
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Nav_Back : Natural := 0;
      Before_Nav_Fwd  : Natural := 0;
      Undo_Before     : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc def");
      Editor.State.Set_Dirty (S, False);
      S.Active_Find_Query := To_Unbounded_String ("def");
      S.Active_Replace_Text := To_Unbounded_String ("ghi");
      Set_Primary_Caret (S, 4, 7);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Before_Nav_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Nav_Fwd := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command ("X")) =
         Editor.Input_Bridge.Routed_To_Text_Insert,
         "Phase 419 selected ordinary payload must route to Text Insert replacement");
      Editor.Input_Bridge.Handle (Text_Command ("X"));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (S) = "abc X",
              "Phase 419 Text Insert replacement must be one canonical replacement edit");
      Assert (S.Carets (S.Carets.First_Index).Pos = 5
              and then S.Carets (S.Carets.First_Index).Anchor = 5,
              "Phase 419 Text Insert owns caret/selection collapse after replacement");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "Phase 419 Text Insert replacement creates exactly one canonical undo entry");
      Assert (Editor.State.Is_Dirty (S),
              "Phase 419 dirty state is updated by the canonical Text Insert owner");
      Assert (S.Active_Find_Stale,
              "Phase 419 Find/Replace invalidation is driven by the canonical Text Insert owner");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 419 Text Insert replacement must not mutate Clipboard");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Nav_Back
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Nav_Fwd,
              "Phase 419 Text Insert replacement must not record Navigation History");

      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Undo));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (S) = "abc def",
              "Phase 419 undo restores exact pre-route text without re-running workflow routing");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 1,
              "Phase 419 undo creates redo through canonical history");

      Set_Primary_Caret (S, 4, 7);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Delete_Selection_Range));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (S) = "abc ",
              "Phase 419 explicit selection-delete workflow event reaches canonical Selection Delete");
      Assert (Natural (Editor.History.Redo_Stack.Length) = 0,
              "Phase 419 successful routed Selection Delete clears redo through canonical owner");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 419 Selection Delete must not behave like Cut");

      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Set_Primary_Caret (S, 4, 4);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Delete_Previous_Character));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (S) = "abc",
              "Phase 419 previous-character workflow event reaches canonical Character Delete");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before + 1,
              "Phase 419 Character Delete owns the undo entry");

      Set_Primary_Caret (S, 3, 3);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command (" def"));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Set_Primary_Caret (S, 7, 7);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Delete_Previous_Word)) =
         Editor.Input_Bridge.Routed_To_Delete_Previous_Word,
         "Phase 419 previous-word event routes to Word Delete without workflow range computation");
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Delete_Previous_Word));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (S) = "abc ",
              "Phase 419 previous-word workflow event reaches canonical Word Delete");

      Set_Primary_Caret (S, 4, 4);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command (String'(1 => ASCII.LF))) =
         Editor.Input_Bridge.Routed_To_Text_Insert,
         "Phase 419 retained line-break policy chooses Text Insert newline payload");
      Editor.Input_Bridge.Handle (Text_Command (String'(1 => ASCII.LF)));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (S) = "abc " & ASCII.LF,
              "Phase 419 line-break payload mutates exactly once through Text Insert");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("CLIP"),
              "Phase 419 delete and line-break routes do not mutate Clipboard");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase419_Editor_Routes_Use_Canonical_Owners;

   procedure Test_Phase419_Overlay_Invalid_And_Redo_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Redo_Before : Natural := 0;
      Undo_Before : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "AB");
      Editor.State.Set_Dirty (S, False);
      Set_Primary_Caret (S, 1, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle (Text_Command ("X"));
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Undo));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Redo_Before := Natural (Editor.History.Redo_Stack.Length);
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Assert (Redo_Before = 1,
              "Phase 419 setup must have redo available after undo");

      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route
           (Kind_Command (Editor.Commands.Move_Left)) =
         Editor.Input_Bridge.Unsupported_Text_Entry_Event,
         "Phase 419 unsupported event is classified before mutation");
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Move_Left));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 419 unsupported workflow event preserves Redo_Stack");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "Phase 419 unsupported workflow event creates no undo entry");
      Assert (Editor.State.Current_Text (S) = "AB",
              "Phase 419 unsupported workflow event does not mutate active-buffer text");

      S.Carets.Clear;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Assert
        (Editor.Input_Bridge.Preview_Text_Entry_Route (Text_Command ("Y")) =
         Editor.Input_Bridge.No_Caret_Location,
         "Phase 419 no-caret editor route fails before mutation");
      Editor.Input_Bridge.Handle (Text_Command ("Y"));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 419 no-caret failure preserves Redo_Stack");
      Assert (Editor.State.Current_Text (S) = "AB",
              "Phase 419 no-caret failure does not mutate active-buffer text");

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command ("local"));
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Delete_Previous_Character));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = "loca",
              "Phase 419 overlay payload and local deletion remain owned by Quick Open");
      Assert (Editor.State.Current_Text (S) = "AB",
              "Phase 419 overlay local input must not leak into active-buffer insertion/deletion");
      Assert (Natural (Editor.History.Redo_Stack.Length) = Redo_Before,
              "Phase 419 overlay local input preserves active-buffer Redo_Stack");
      Assert (not Editor.State.Is_Dirty (S),
              "Phase 419 overlay local input never dirties the active buffer");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase419_Overlay_Invalid_And_Redo_Boundaries;

   procedure Test_Phase419_Active_Buffer_Isolation_And_Render_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      A_Id          : Editor.Buffers.Buffer_Id;
      B_Id          : Editor.Buffers.Buffer_Id;
      Before_B_Text : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Before_Undo   : Natural := 0;
      Before_Redo   : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A");
      Set_Primary_Caret (S, 1, 1);
      Editor.Buffers.Ensure_Global_Registry (S);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "B");
      Set_Primary_Caret (S, 1, 1);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_B_Text := To_Unbounded_String (Editor.State.Current_Text (S));

      Editor.Executor.Execute_Switch_Buffer (S, A_Id);
      Set_Primary_Caret (S, 1, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command ("1"));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
              "Phase 419 routed editor input must not switch active buffers");
      Assert (Editor.State.Current_Text (S) = "A1",
              "Phase 419 routed editor input mutates only the active buffer");
      Assert (Editor.State.Current_Text (Editor.Buffers.Buffer (Editor.Buffers.Global_Registry_For_UI, B_Id)) = To_String (Before_B_Text),
              "Phase 419 inactive buffer text remains isolated from routed workflow input");

      Editor.Executor.Execute_Switch_Buffer (S, B_Id);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command ("2"));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "Phase 419 switch to Buffer B remains explicit lifecycle/state behavior");
      Assert (Editor.State.Current_Text (S) = "B2",
              "Phase 419 Buffer B changes only when it is active and editor focus is active");
      Assert (Editor.State.Current_Text (Editor.Buffers.Buffer (Editor.Buffers.Global_Registry_For_UI, A_Id)) = "A1",
              "Phase 419 Buffer A remains unchanged after Buffer B routed input");

      Before_Undo := Natural (Editor.History.Undo_Stack.Length);
      Before_Redo := Natural (Editor.History.Redo_Stack.Length);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.State.Current_Text (S) = "B2",
              "Phase 419 render snapshot must not mutate active-buffer text");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Before_Undo
              and then Natural (Editor.History.Redo_Stack.Length) = Before_Redo,
              "Phase 419 render snapshot must not mutate Undo/Redo stacks");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase419_Active_Buffer_Isolation_And_Render_Read_Only;

   procedure Test_Phase419_Persistence_Exclusion_Is_Complete
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S         : Editor.State.State_Type;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary   : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "persist");
      Set_Primary_Caret (S, 7, 7);
      S.Active_Find_Query := To_Unbounded_String ("persist");
      S.Active_Replace_Text := To_Unbounded_String ("state");
      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command ("overlay"));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Editor.Executor.Execute_Close_Quick_Open (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Text_Command ("X"));
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Delete_Previous_Character));
      Editor.Input_Bridge.Handle (Kind_Command (Editor.Commands.Delete_Previous_Word));
      Editor.Input_Bridge.Handle (Text_Command (String'(1 => ASCII.LF)));
      S := Editor.Input_Bridge.Get_State_For_Test;

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert
        (Index (Summary, "text entry workflow") = 0
         and then Index (Summary, "last input route") = 0
         and then Index (Summary, "last input event") = 0
         and then Index (Summary, "last text-entry payload") = 0
         and then Index (Summary, "last routed command") = 0
         and then Index (Summary, "input focus routing history") = 0
         and then Index (Summary, "editor typing history") = 0
         and then Index (Summary, "overlay-routed payload") = 0
         and then Index (Summary, "text-entry availability") = 0
         and then Index (Summary, "workflow policy override") = 0
         and then Index (Summary, "selection-consuming Backspace") = 0
         and then Index (Summary, "line-break routing policy") = 0
         and then Index (Summary, "route audit cache") = 0
         and then Index (Summary, "route audit result history") = 0,
         "Phase 419 workspace persistence excludes workflow state, payload history, route history, policy overrides, and audit caches");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase419_Persistence_Exclusion_Is_Complete;


   procedure Test_Phase420_Command_Id_Text_Entry_Uses_Canonical_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ab");
      Set_Primary_Caret (S, 1, 1);
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Insert_Newline);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.State.Current_Text (S) = "a" & ASCII.LF & "b",
         "Phase 420 Command_Insert_Newline must use the canonical Text Insert line-break route");
      Assert
        (Natural (Editor.History.Undo_Stack.Length) = 1,
         "Phase 420 command-id text entry creates undo only through the canonical mutation owner");

      Editor.Executor.Execute_Open_Quick_Open (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Assert
        (Editor.Input_Bridge.Resolve_Text_Entry_Focus_Target =
         Editor.Input_Bridge.Text_Entry_Overlay_Input,
         "Phase 420 setup must make overlay/input focus outrank editor focus");

      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Char_Delete_Previous);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert
        (Editor.State.Current_Text (S) = "a" & ASCII.LF & "b",
         "Phase 420 command-id character delete must not bypass overlay/input focus priority");
      Assert
        (Natural (Editor.History.Undo_Stack.Length) = 1,
         "Phase 420 overlay-routed command-id text entry must not create active-buffer undo entries");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase420_Command_Id_Text_Entry_Uses_Canonical_Workflow;

   procedure Test_Phase572_File_Tree_Create_Prompts_Allow_Project_Relative_Paths
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Prompt : Editor.Guided_Prompts.Prompt_State;
   begin
      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
         Editor.Commands.Command_File_Tree_Create_File,
         "Create File",
         "Enter a file name or project-relative path inside the active project.",
         "File Tree",
         Confirm_Label => "Create");
      Editor.Guided_Prompts.Update_Input (Prompt, "src/new_unit.adb");
      Assert (Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 create-file prompt must allow explicit project-relative paths");

      Editor.Guided_Prompts.Update_Input (Prompt, "src/../escape.adb");
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 create-file prompt must reject parent traversal segments");

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt,
         Editor.Commands.Command_File_Tree_Create_Directory,
         "Create Directory",
         "Enter a directory name or project-relative path inside the active project.",
         "File Tree",
         Confirm_Label => "Create");
      Editor.Guided_Prompts.Update_Input (Prompt, "src/generated");
      Assert (Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 create-directory prompt must allow explicit project-relative paths");

      Editor.Guided_Prompts.Update_Input (Prompt, "src//generated");
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 create-directory prompt must reject empty path segments");

      Editor.Guided_Prompts.Update_Input (Prompt, "src/generated/");
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 create-directory prompt must reject trailing separators");
   end Test_Phase572_File_Tree_Create_Prompts_Allow_Project_Relative_Paths;




   procedure Test_Phase572_File_Tree_Empty_Prompt_Uses_Name_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Prompt   : Editor.Guided_Prompts.Prompt_State;
      Snapshot : Editor.Guided_Prompts.Prompt_Snapshot;
   begin
      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
         Editor.Commands.Command_File_Tree_Create_File,
         "Create File",
         "Enter a file name or project-relative path inside the active project.",
         "File Tree",
         Confirm_Label => "Create");
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 empty create-file prompt must block confirmation");
      Assert (To_String (Snapshot.Validation_Label) = "Enter a name.",
              "Phase 572 empty create-file prompt must use File Tree name guidance");

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt,
         Editor.Commands.Command_File_Tree_Create_Directory,
         "Create Directory",
         "Enter a directory name or project-relative path inside the active project.",
         "File Tree",
         Confirm_Label => "Create");
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);
      Assert (To_String (Snapshot.Validation_Label) = "Enter a name.",
              "Phase 572 empty create-directory prompt must use File Tree name guidance");

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Rename_Prompt,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         "Rename File or Directory",
         "Enter a new name for the selected file or directory.",
         "File Tree",
         Confirm_Label => "Rename");
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);
      Assert (To_String (Snapshot.Validation_Label) = "Enter a name.",
              "Phase 572 empty rename prompt must use File Tree name guidance");
   end Test_Phase572_File_Tree_Empty_Prompt_Uses_Name_Message;


   procedure Test_Phase572_File_Tree_Rename_Prompt_Remains_Leaf_Name_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Prompt : Editor.Guided_Prompts.Prompt_State;
   begin
      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Rename_Prompt,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         "Rename File or Directory",
         "Enter a new name for the selected file or directory.",
         "File Tree",
         Confirm_Label => "Rename");
      Editor.Guided_Prompts.Update_Input (Prompt, "renamed.adb");
      Assert (Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 rename prompt must accept a leaf name");

      Editor.Guided_Prompts.Update_Input (Prompt, "src/renamed.adb");
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 rename prompt must reject path fragments");
      Assert (Editor.Guided_Prompts.Snapshot (Prompt).Validation =
                Editor.Guided_Prompts.Validation_Invalid_Syntax,
              "Phase 572 rename path rejection should be syntax validation");
      Assert (To_String (Editor.Guided_Prompts.Snapshot (Prompt).Validation_Label) =
                "Rename expects a single new name",
              "Phase 572 rename path rejection should explain the leaf-name policy");
   end Test_Phase572_File_Tree_Rename_Prompt_Remains_Leaf_Name_Only;




   procedure Test_Phase572_File_Tree_Prompt_Invalid_Syntax_Uses_Operation_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Prompt   : Editor.Guided_Prompts.Prompt_State;
      Snapshot : Editor.Guided_Prompts.Prompt_Snapshot;
   begin
      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
         Editor.Commands.Command_File_Tree_Create_File,
         "Create File",
         "Enter a file name or project-relative path inside the active project.",
         "File Tree",
         Confirm_Label => "Create");
      Editor.Guided_Prompts.Update_Input (Prompt, "src/../bad.adb");
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 create-file invalid prompt input must block confirmation");
      Assert (To_String (Snapshot.Validation_Label) = "Invalid file name",
              "Phase 572 create-file prompt syntax must match execution wording");

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt,
         Editor.Commands.Command_File_Tree_Create_Directory,
         "Create Directory",
         "Enter a directory name or project-relative path inside the active project.",
         "File Tree",
         Confirm_Label => "Create");
      Editor.Guided_Prompts.Update_Input (Prompt, "generated/");
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 create-directory invalid prompt input must block confirmation");
      Assert (To_String (Snapshot.Validation_Label) = "Invalid directory name",
              "Phase 572 create-directory prompt syntax must match execution wording");

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Rename_Prompt,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         "Rename File or Directory",
         "Enter a new name for the selected file or directory.",
         "File Tree",
         Confirm_Label => "Rename");
      Editor.Guided_Prompts.Update_Input (Prompt, "C:tmp");
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 rename invalid prompt input must block confirmation");
      Assert (To_String (Snapshot.Validation_Label) = "Invalid rename target",
              "Phase 572 rename prompt syntax must match execution wording");
   end Test_Phase572_File_Tree_Prompt_Invalid_Syntax_Uses_Operation_Message;


   procedure Test_Phase572_File_Tree_Absolute_Prompt_Uses_Project_Relative_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Prompt   : Editor.Guided_Prompts.Prompt_State;
      Snapshot : Editor.Guided_Prompts.Prompt_Snapshot;
   begin
      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
         Editor.Commands.Command_File_Tree_Create_File,
         "Create File",
         "Enter a file name or project-relative path inside the active project.",
         "File Tree",
         Confirm_Label => "Create");
      Editor.Guided_Prompts.Update_Input (Prompt, "/tmp/outside.adb");
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 absolute create-file prompt input must block confirmation");
      Assert (Snapshot.Validation = Editor.Guided_Prompts.Validation_Outside_Project,
              "Phase 572 absolute create-file prompt should be an outside/project-relative validation");
      Assert (To_String (Snapshot.Validation_Label) =
                "Target path must be project-relative",
              "Phase 572 absolute create-file prompt must use Executor-aligned project-relative wording");

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt,
         Editor.Commands.Command_File_Tree_Create_Directory,
         "Create Directory",
         "Enter a directory name or project-relative path inside the active project.",
         "File Tree",
         Confirm_Label => "Create");
      Editor.Guided_Prompts.Update_Input (Prompt, "C:/outside");
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);
      Assert (not Editor.Guided_Prompts.Ready (Prompt),
              "Phase 572 absolute create-directory prompt input must block confirmation");
      Assert (To_String (Snapshot.Validation_Label) =
                "Target path must be project-relative",
              "Phase 572 drive-rooted create-directory prompt must use project-relative wording");
   end Test_Phase572_File_Tree_Absolute_Prompt_Uses_Project_Relative_Message;


   procedure Test_Phase572_File_Tree_Mutation_Prompts_Check_Availability_Before_Start
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Editor.State.Init (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_File_Tree_Create_File);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Assert (not Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
              "Phase 572 create-file must not open a prompt with no project");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) = "No project open.",
              "Phase 572 unavailable create-file must report no project before prompt start");
   end Test_Phase572_File_Tree_Mutation_Prompts_Check_Availability_Before_Start;


   procedure Test_Open_Project_Command_Starts_Path_Prompt
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
      Snapshot     : Editor.Guided_Prompts.Prompt_Snapshot;
   begin
      Editor.State.Init (S);
      Availability :=
        Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Open_Project);

      Assert (Editor.Commands.Is_Available (Availability),
              "Open Project must be selectable from the command palette");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Open_Project);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Guided_Prompts.Snapshot (S.Guided_Prompt);

      Assert (Snapshot.Active,
              "Open Project command must start a path prompt");
      Assert (Snapshot.Kind = Editor.Guided_Prompts.Project_Open_Prompt,
              "Open Project prompt uses the project-open prompt kind");
      Assert (To_String (Snapshot.Confirm_Label) = "Open",
              "Open Project prompt exposes the Open confirmation action");
   end Test_Open_Project_Command_Starts_Path_Prompt;


   procedure Test_Runtime_C_API_Open_Project_Path_Opens_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("runtime_c_api_open_project");
      Path : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.New_String (Root);
      S    : Editor.State.State_Type;
   begin
      Build_Fixture (Root);

      Editor.C_API.Editor_Init;
      Editor.C_API.Editor_Open_Project_Path (Path);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.Project.Has_Project (S.Project),
              "runtime C API project path must open a project");
      Assert (Editor.Project.Root_Path (S.Project) = Root,
              "runtime C API project path must become the active project root");

      Interfaces.C.Strings.Free (Path);
      Cleanup_Fixture (Root);
   exception
      when others =>
         if Path /= Interfaces.C.Strings.Null_Ptr then
            Interfaces.C.Strings.Free (Path);
         end if;
         Cleanup_Fixture (Root);
         raise;
   end Test_Runtime_C_API_Open_Project_Path_Opens_Project;


   procedure Test_Open_Project_Prompt_Shows_Directory_Picker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("open_project_picker");
      A_Dir    : constant String := Ada.Directories.Compose (Root, "a_dir");
      Prompt   : Editor.Guided_Prompts.Prompt_State;
      Snapshot : Editor.Guided_Prompts.Prompt_Snapshot;
      Found    : Boolean := False;
      Selected : Unbounded_String := Null_Unbounded_String;
   begin
      Build_Fixture (Root);

      Editor.Guided_Prompts.Start
        (Prompt,
         Editor.Guided_Prompts.Project_Open_Prompt,
         Editor.Commands.Command_Open_Project,
         "Open Project",
         "Enter project path.",
         "Project",
         Confirm_Label => "Open");
      Editor.Guided_Prompts.Update_Input (Prompt, Root);
      Snapshot := Editor.Guided_Prompts.Snapshot (Prompt);

      Assert (Snapshot.File_Picker_Active,
              "Open Project prompt must expose a directory picker");
      Assert (Natural (Snapshot.File_Picker_Rows.Length) >= 3,
              "directory picker includes current, parent, and child directories");
      Assert (To_String (Snapshot.File_Picker_Current_Directory) =
                Ada.Directories.Full_Name (Root),
              "directory picker tracks the typed directory");

      for Row of Snapshot.File_Picker_Rows loop
         if To_String (Row.Label) = "a_dir/" then
            Found := True;
            Selected := Row.Path;
            exit;
         end if;
      end loop;

      Assert (Found, "directory picker lists child project directories");
      Assert (To_String (Selected) = Ada.Directories.Full_Name (A_Dir),
              "directory picker row carries the child directory path");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Open_Project_Prompt_Shows_Directory_Picker;


   procedure Test_Open_Project_Picker_Selection_Can_Browse_And_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root  : constant String := Temp_Path ("open_project_picker_accept");
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Path  : Unbounded_String := Null_Unbounded_String;
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Open_Project);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Editor.Guided_Prompts.Update_Input (S.Guided_Prompt, Root);
      for I in 1 .. Natural (S.Guided_Prompt.File_Picker_Rows.Length) loop
         if To_String (S.Guided_Prompt.File_Picker_Rows.Element (Positive (I)).Label) =
           "a_dir/"
         then
            S.Guided_Prompt.File_Picker_Selected_Index := Positive (I);
            Found := True;
            Path := S.Guided_Prompt.File_Picker_Rows.Element (Positive (I)).Path;
            exit;
         end if;
      end loop;

      Assert (Found, "picker selection test must find child directory row");
      Assert (To_String (Path) = Ada.Directories.Full_Name (A_Dir),
              "picker selection carries expected child path");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        ((Key       => Editor.Keybindings.Key_Right,
          Modifiers => (others => False)));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Guided_Prompts.Input_Text (S.Guided_Prompt) =
                Ada.Directories.Full_Name (A_Dir),
              "Right applies the selected directory to the path field");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        ((Key       => Editor.Keybindings.Key_Enter,
          Modifiers => (others => False)));
      S := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.Project.Has_Project (S.Project),
              "Enter opens the picker-selected project directory");
      Assert (Editor.Project.Root_Path (S.Project) =
                Ada.Directories.Full_Name (A_Dir),
              "picker-selected directory becomes the active project root");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Open_Project_Picker_Selection_Can_Browse_And_Open;


   procedure Test_Open_Project_Picker_Runtime_Enter_Browses_Selected_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root  : constant String := Temp_Path ("open_project_picker_runtime_enter");
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Enter : Editor.Commands.Command;
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Open_Project);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Editor.Guided_Prompts.Update_Input (S.Guided_Prompt, Root);
      for I in 1 .. Natural (S.Guided_Prompt.File_Picker_Rows.Length) loop
         if To_String (S.Guided_Prompt.File_Picker_Rows.Element (Positive (I)).Label) =
           "a_dir/"
         then
            S.Guided_Prompt.File_Picker_Selected_Index := Positive (I);
            Found := True;
            exit;
         end if;
      end loop;
      Assert (Found, "runtime Enter picker setup must find child directory row");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Enter.Kind := Editor.Commands.Insert_Text_Input;
      Enter.Ch := ASCII.LF;
      Enter.Text := To_Unbounded_String (String'(1 => ASCII.LF));
      Editor.Input_Bridge.Handle (Enter);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
              "runtime Enter on child directory browses instead of closing prompt");
      Assert (Editor.Guided_Prompts.Input_Text (S.Guided_Prompt) =
                Ada.Directories.Full_Name (A_Dir),
              "runtime Enter applies selected directory to the path field");

      Enter := (others => <>);
      Enter.Kind := Editor.Commands.Insert_Text_Input;
      Enter.Ch := ASCII.LF;
      Enter.Text := To_Unbounded_String (String'(1 => ASCII.LF));
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle (Enter);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.Project.Has_Project (S.Project),
              "second runtime Enter opens the current selected directory");
      Assert (Editor.Project.Root_Path (S.Project) =
                Ada.Directories.Full_Name (A_Dir),
              "runtime Enter opens the browsed directory as project root");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Open_Project_Picker_Runtime_Enter_Browses_Selected_Directory;


   procedure Test_Phase572_File_Tree_Rename_Prompt_Prefills_Selected_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase572_rename_prefill");
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Found     : Boolean := False;
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Row_Found : Boolean := False;
      Row       : Natural := 0;
      Snapshot  : Editor.Guided_Prompts.Prompt_Snapshot;
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 572 rename prefill setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, File_Path, Found);
      Assert (Found, "Phase 572 rename prefill setup must find file node");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 rename prefill setup must find visible row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_File_Tree_Rename_Selected);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Guided_Prompts.Snapshot (S.Guided_Prompt);

      Assert (Snapshot.Active,
              "Phase 572 rename starts an editable prompt for a selected target");
      Assert (Editor.Guided_Prompts.Input_Text (S.Guided_Prompt) = "a.txt",
              "Phase 572 rename prompt must prefill the selected leaf name");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase572_File_Tree_Rename_Prompt_Prefills_Selected_Name;


   procedure Test_Phase572_File_Tree_Delete_Prompt_Shows_Target_And_Buffer_Impact
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase572_delete_prompt");
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Found     : Boolean := False;
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Row_Found : Boolean := False;
      Row       : Natural := 0;
      Snapshot  : Editor.Guided_Prompts.Prompt_Snapshot;
   begin
      Build_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 572 delete prompt setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Executor.Execute_Open_File (S, File_Path);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 delete prompt setup must find file node");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 delete prompt setup must find visible row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_File_Tree_Delete_Selected);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Guided_Prompts.Snapshot (S.Guided_Prompt);

      Assert (Snapshot.Active,
              "Phase 572 delete starts a confirmation prompt");
      Assert (Snapshot.Requires_Confirmation and then Snapshot.Destructive,
              "Phase 572 delete prompt is explicitly destructive confirmation");
      Assert (To_String (Snapshot.Title) = "Delete File or Directory",
              "Phase 579 delete prompt uses product-facing title");
      Assert (Index (To_String (Snapshot.Description), File_Path) > 0,
              "Phase 572 delete prompt shows the affected path");
      Assert (Index (To_String (Snapshot.Description), "Clean open buffers") > 0,
              "Phase 572 delete prompt describes clean open-buffer impact");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase572_File_Tree_Delete_Prompt_Shows_Target_And_Buffer_Impact;

   procedure Test_Phase572_File_Tree_Prompt_Cancel_Uses_Operation_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase572_cancel_messages");
      S         : Editor.State.State_Type;
      Open_Res  : Editor.Project.Project_Open_Result;
      Found     : Boolean := False;
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Row_Found : Boolean := False;
      Row       : Natural := 0;
      Msg       : Editor.Messages.Editor_Message;

      procedure Assert_Cancel_Message
        (Id       : Editor.Commands.Command_Id;
         Expected : String)
      is
      begin
         Editor.Input_Bridge.Set_State_For_Test (S);
         Editor.Input_Bridge.Execute_Command_Id (Id);
         S := Editor.Input_Bridge.Get_State_For_Test;
         Assert (Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
                 "Phase 572 cancel-message setup must start the prompt");

         Editor.Input_Bridge.Set_State_For_Test (S);
         Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Cancel);
         S := Editor.Input_Bridge.Get_State_For_Test;

         Assert (not Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
                 "Phase 572 cancel must clear the transient prompt");
         Msg := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then Editor.Messages.Text (Msg) = Expected,
                 "Phase 572 File Tree cancel should report " & Expected);
      end Assert_Cancel_Message;
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "Phase 572 cancel-message setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Assert_Cancel_Message
        (Editor.Commands.Command_File_Tree_Create_File,
         "Create file cancelled.");
      Assert_Cancel_Message
        (Editor.Commands.Command_File_Tree_Create_Directory,
         "Create directory cancelled.");

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 cancel-message setup must find file node");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 cancel-message setup must map file row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Assert_Cancel_Message
        (Editor.Commands.Command_File_Tree_Rename_Selected,
         "Rename cancelled.");
      Assert_Cancel_Message
        (Editor.Commands.Command_File_Tree_Delete_Selected,
         "Delete cancelled.");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase572_File_Tree_Prompt_Cancel_Uses_Operation_Message;

   procedure Test_Async_Build_Idle_Tick_Hook_Is_Callable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Tick_Async_Build_Jobs;
      Assert (True, "idle async build tick hook is callable without a queued job");
   end Test_Async_Build_Idle_Tick_Hook_Is_Callable;


   overriding procedure Register_Tests
     (T : in out Input_Bridge_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Async_Build_Idle_Tick_Hook_Is_Callable'Access,
         "idle async build tick polls queued jobs before render");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Create_Prompts_Allow_Project_Relative_Paths'Access,
         "Phase 572 file tree create prompts allow project-relative paths");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Rename_Prompt_Remains_Leaf_Name_Only'Access,
         "Phase 572 file tree rename prompt remains leaf-name only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Empty_Prompt_Uses_Name_Message'Access,
         "Phase 572 file tree empty prompts use name guidance");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Mutation_Prompts_Check_Availability_Before_Start'Access,
         "Phase 572 file tree mutation prompts check availability before start");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Project_Command_Starts_Path_Prompt'Access,
         "Open Project command starts a path prompt");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Runtime_C_API_Open_Project_Path_Opens_Project'Access,
         "runtime C API opens project path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Project_Prompt_Shows_Directory_Picker'Access,
         "Open Project prompt shows a directory picker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Project_Picker_Selection_Can_Browse_And_Open'Access,
         "Open Project picker selection can browse and open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Project_Picker_Runtime_Enter_Browses_Selected_Directory'Access,
         "Open Project picker runtime Enter browses selected directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Rename_Prompt_Prefills_Selected_Name'Access,
         "Phase 572 file tree rename prompt pre-fills selected name");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Delete_Prompt_Shows_Target_And_Buffer_Impact'Access,
         "Phase 572 file tree delete prompt shows target and buffer impact");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Prompt_Cancel_Uses_Operation_Message'Access,
         "Phase 572 file tree prompt cancellation uses operation messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Prompt_Invalid_Syntax_Uses_Operation_Message'Access,
         "Phase 572 file tree prompt invalid syntax uses operation messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_File_Tree_Absolute_Prompt_Uses_Project_Relative_Message'Access,
         "Phase 572 file tree absolute prompt uses project-relative message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase420_Command_Id_Text_Entry_Uses_Canonical_Workflow'Access,
         "Phase 420 command-id text entry uses canonical workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase419_Focus_Resolution_And_Route_Matrix'Access,
         "Phase 419 focus resolution and route matrix are coherent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase419_Editor_Routes_Use_Canonical_Owners'Access,
         "Phase 419 editor routes use canonical mutation owners");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase419_Overlay_Invalid_And_Redo_Boundaries'Access,
         "Phase 419 overlay invalid and redo boundaries are coherent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase419_Active_Buffer_Isolation_And_Render_Read_Only'Access,
         "Phase 419 active-buffer isolation and render are read-only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase419_Persistence_Exclusion_Is_Complete'Access,
         "Phase 419 persistence exclusion is complete");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase418_Route_Preview_Is_Reliable_And_Read_Only'Access,
         "Phase 418 text-entry route preview is reliable and read-only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase418_Overlay_Named_Delete_Remains_Local'Access,
         "Phase 418 overlay named delete remains local");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase418_Redo_Boundaries_Are_Canonical'Access,
         "Phase 418 redo boundaries are canonical");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase418_Persistence_Excludes_Workflow_State'Access,
         "Phase 418 persistence excludes text-entry workflow state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase417_Text_Entry_Route_Preview_Is_Canonical'Access,
         "Phase 417 text-entry route preview is canonical and side-effect-free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase417_Overlay_Input_Remains_Local'Access,
         "Phase 417 overlay input remains local before editor routing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase417_Editor_Text_Workflow_Mutates_Through_Canonical_Routes'Access,
         "Phase 417 editor text workflow reaches canonical routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase417_Non_Editor_Focus_Blocks_Text_Entry_Workflow'Access,
         "Phase 417 non-editor focus blocks text-entry workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase239_Reload_Command_Id_Uses_Canonical_Path'Access,
         "Phase 239 reload command id uses canonical path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase231_Wheel_Over_Editor_Scrolls_Viewport_Not_Caret'Access,
         "Phase 231 wheel over editor scrolls viewport without moving caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Directory_Click_Toggles_Expansion'Access,
         "Phase 57 File Tree Directory Click Toggles Expansion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_File_Click_Opens_Buffer'Access,
         "Phase 57 File Tree File Click Opens Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Background_Click_Is_Handled_No_Op'Access,
         "Phase 57 File Tree Background Click Is No-Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabled_File_Tree_Does_Not_Consume_Text_Click'Access,
         "Phase 57 Disabled File Tree Does Not Consume Text Click");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Splitter_Drag_Resizes_By_Columns'Access,
         "Phase 58 File Tree Splitter Drag Resizes By Columns");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Splitter_Release_Restores_Text_Routing'Access,
         "Phase 58 File Tree Splitter Release Restores Text Routing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabled_File_Tree_Prevents_Splitter_Resize'Access,
         "Phase 58 Disabled File Tree Prevents Splitter Resize");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Problems_Panel_Click_Is_Handled_No_Op'Access,
         "Phase 60 Problems Panel Click Is Handled No-Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Problems_Row_Click_Jumps_To_Diagnostic'Access,
         "Phase 61 Problems Row Click Jumps To Diagnostic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase76_Search_Results_Focus_Captures_Down_Key'Access,
         "Phase 76 Search Results focus captures Down key before editor navigation");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase221_Search_Query_Input_Consumes_Text_Before_Buffer'Access,
         "Phase 221 Search query input consumes text before buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase221_Outline_Filter_Input_Consumes_Text_Before_Buffer'Access,
         "Phase 221 Outline filter input consumes text before buffer");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase230_Feature_Panel_Search_Click_Selects_Row'Access,
         "Phase 230 Feature Panel Search click selects row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase230_Feature_Panel_Search_Double_Click_Activates_Row'Access,
         "Phase 230 Feature Panel Search double-click activates row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase230_Feature_Panel_Diagnostics_Click_Selects_Row'Access,
         "Phase 230 Feature Panel Diagnostics click selects row");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase66_Text_Double_Click_Selects_Word'Access,
         "Phase 66 Text Double Click Selects Word");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase66_File_Tree_Double_Click_Does_Not_Select_Text'Access,
         "Phase 66 File Tree Double Click Does Not Select Text");
   end Register_Tests;

end Editor.Input_Bridge.Tests;
