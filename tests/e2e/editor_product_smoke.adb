with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Buffers;
with Editor.Commands;
with Editor.Executor;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Input_Bridge;
with Editor.Outline;
with Editor.Project;
with Editor.Project_Search;
with Editor.Render_Packet;
with Editor.State;
with Editor.Test_Helper;
with Editor.Workspace_Persistence;

procedure Editor_Product_Smoke is

   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.Focus_Management.Focus_Owner;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Outline.Outline_Freshness;

   package Stream_IO renames Ada.Streams.Stream_IO;

   Root : constant String := Ada.Directories.Current_Directory
     & "/phase579_e2e_product_smoke_project";
   Src  : constant String := Root & "/src";
   Main_Path : constant String := Src & "/main.adb";
   Unit_Path : constant String := Src & "/smoke_unit.adb";
   Demo_Path : constant String := Src & "/smoke_demo.ads";
   Workspace_Path : constant String := Root & "/phase579_e2e.workspace";

   procedure Fail (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,
                            "editor_product_smoke: " & Message);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      raise Program_Error with Message;
   end Fail;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Fail (Message);
      end if;
   end Check;

   procedure Remove_Tree_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_Tree_If_Exists;

   procedure Write_File (Path : String; Text : String) is
      F   : Stream_IO.File_Type;
      Raw : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      for I in Text'Range loop
         Raw (Ada.Streams.Stream_Element_Offset (I - Text'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Text (I)));
      end loop;
      if Text'Length > 0 then
         Stream_IO.Write (F, Raw);
      end if;
      Stream_IO.Close (F);
   end Write_File;

   function Read_File (Path : String) return String is
      Result : constant Editor.Files.File_Open_Result :=
        Editor.Files.Open_File (Path);
   begin
      if Editor.Files.Is_Success (Result) then
         return To_String (Result.Contents);
      end if;
      return "";
   end Read_File;

   procedure Build_Fixture is
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
      Write_File
        (Root & "/smoke_project.gpr",
         "project Smoke_Project is" & ASCII.LF &
         "   for Source_Dirs use (""src"");" & ASCII.LF &
         "   for Main use (""main.adb"");" & ASCII.LF &
         "end Smoke_Project;" & ASCII.LF);
      Write_File
        (Src & "/smoke_unit.ads",
         "package Smoke_Unit is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   function Token return String;" & ASCII.LF &
         "end Smoke_Unit;" & ASCII.LF);
      Write_File
        (Demo_Path,
         "package Smoke_Demo is" & ASCII.LF &
         "   type Counter is range 0 .. 100;" & ASCII.LF &
         ASCII.LF &
         "   procedure Increment (Value : in out Counter);" & ASCII.LF &
         "end Smoke_Demo;" & ASCII.LF);
      Write_File
        (Unit_Path,
         "package body Smoke_Unit is" & ASCII.LF &
         "   procedure Run is" & ASCII.LF &
         "   begin" & ASCII.LF &
         "      null;" & ASCII.LF &
         "   end Run;" & ASCII.LF & ASCII.LF &
         "   function Token return String is" & ASCII.LF &
         "   begin" & ASCII.LF &
         "      return ""Phase579_E2E_Token"";" & ASCII.LF &
         "   end Token;" & ASCII.LF &
         "end Smoke_Unit;" & ASCII.LF);
      Write_File
        (Main_Path,
         "with Smoke_Unit;" & ASCII.LF & ASCII.LF &
         "procedure Main is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   Smoke_Unit.Run;" & ASCII.LF &
         "end Main;" & ASCII.LF);
   end Build_Fixture;

   function Smoke_Request return Editor.External_Producers.Build_Run_Request is
      Args : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
   begin
      Editor.External_Producers.Append_Process_Argument (Args, "-P");
      Editor.External_Producers.Append_Process_Argument
        (Args, Root & "/smoke_project.gpr");
      return
        (Tool => Editor.External_Producers.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild -P smoke_project.gpr"),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Args);
   end Smoke_Request;

   S : Editor.State.State_Type;
   Refresh : Editor.Project.Project_File_Refresh_Result;
   Found : Boolean := False;
   Node : Editor.File_Tree.File_Tree_Node_Id;
   Row : Natural := 0;
   Search_Result : Editor.Project_Search.Project_Search_Result;
   Build_Context : Editor.External_Producers.User_Opt_In_Build_Command_Context;
   Supplied_Process : Editor.External_Producers.Process_Run_Result;
   Build_Result : Editor.External_Producers.Build_Command_Result;
   Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
   Loaded : Editor.Workspace_Persistence.Workspace_Snapshot;
   Persist_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   Packet : Editor.Render_Packet.Render_Packet;

begin
   Build_Fixture;
   Editor.Buffers.Reset_Global_For_Test;
   Editor.State.Init (S);

   Editor.Executor.Execute_Open_Project (S, Root);
   Check (Editor.Project.Has_Project (S.Project),
          "project open did not retain a project root");

   Editor.Project.Refresh_Known_Files (S.Project, Refresh);
   Check (Refresh.Status = Editor.Project.Project_File_Refresh_Ok,
          "project file refresh failed");
   Check (Editor.Project.Has_Known_File (S.Project, "src/smoke_unit.adb"),
          "project file index does not include smoke_unit.adb");

   Editor.Executor.Execute_Refresh_File_Tree (S);
   Node := Editor.File_Tree.Find_By_Path
     (S.File_Tree, "src/smoke_unit.adb", Found);
   Check (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
          "file tree did not discover smoke_unit.adb");
   Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
   Check (Found and then Row > 0,
          "file tree node did not map to a selectable row");
   Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
   Editor.Focus_Management.Set_Focus_Owner
     (S, Editor.Focus_Management.Focus_File_Tree);
   Editor.Executor.Execute_Command
     (S, Editor.Commands.Command_File_Tree_Open_Selected);
   Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Unit_Path,
          "file tree activation did not open the expected buffer");
   Check (Editor.Focus_Management.Effective_Focus_Owner (S) =
            Editor.Focus_Management.Focus_Editor,
          "file tree activation did not return focus to editor");

   Editor.Executor.Execute_No_Log
     (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, ' '));
   Check (S.File_Info.Dirty, "editing did not mark the file dirty");
   Editor.Executor.Execute_Save (S);
   Check (not S.File_Info.Dirty, "save did not clear dirty state");
   Check (Ada.Strings.Fixed.Index (Read_File (Unit_Path), "Phase579_E2E_Token") > 0,
          "saved file no longer contains the expected token");

   Editor.Executor.Execute_Open_File (S, Demo_Path);
   Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Demo_Path,
          "direct open did not activate the outline smoke fixture");
   Check (not S.File_Info.Dirty,
          "opening outline smoke fixture should start clean");
   declare
      Text_Before_Outline : constant String := Editor.State.Current_Text (S);
      Token_A             : constant Natural := S.Active_Buffer_Token;
      Revision_A          : constant Natural := Editor.State.Current_Buffer_Revision (S);
      Row                 : Natural := 0;
      Col                 : Natural := 0;
   begin
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Check (Editor.Outline.Item_Count (S.Outline) >= 3,
             "outline.refresh returned no real Ada declaration rows");
      Check (Editor.Outline.Is_Current_For_Buffer (S.Outline, Token_A, Revision_A),
             "outline is not current for the refreshed source buffer");
      Check (Editor.State.Current_Text (S) = Text_Before_Outline,
             "outline.refresh mutated buffer text");
      Check (not S.File_Info.Dirty,
             "outline.refresh changed clean dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Check (Row = 0 and then Col = 0,
             "opening package outline row did not move caret to package declaration");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Check (Row = 1,
             "opening type outline row did not move caret to type declaration");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Check (Row = 3,
             "opening procedure outline row did not move caret to procedure declaration");
      Check (Editor.State.Current_Text (S) = Text_Before_Outline,
             "outline navigation mutated buffer text");
      Check (not S.File_Info.Dirty,
             "outline navigation changed clean dirty state");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, ' '));
      Check (S.File_Info.Dirty,
             "outline smoke edit did not mark demo buffer dirty");
      Check (not Editor.Outline.Is_Current_For_Buffer
               (S.Outline, Token_A, Editor.State.Current_Buffer_Revision (S)),
             "edited buffer still reports outline current");
      Check (Editor.Outline.Freshness_For_Active_Buffer
               (S.Outline, Token_A, Editor.State.Current_Buffer_Revision (S)) =
             Editor.Outline.Outline_Stale,
             "edited buffer did not mark outline stale");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Check (Editor.Outline.Is_Current_For_Buffer
               (S.Outline, Token_A, Editor.State.Current_Buffer_Revision (S)),
             "outline.refresh did not make edited buffer current again");
      Editor.Executor.Execute_Save (S);
      Check (not S.File_Info.Dirty,
             "saving outline smoke fixture did not clear dirty state");

      Editor.Executor.Execute_Open_File (S, Unit_Path);
      Check (not Editor.Outline.Is_Current_For_Buffer
               (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)),
             "outline falsely reports current after switching buffers");
   end;

   Editor.Project_Search.Set_Query (S.Project_Search, "Phase579_E2E_Token");
   Editor.Project_Search.Search_Known_Project_Files
     (S.Project_Search, S.Project, (others => <>));
   Check (Editor.Project_Search.Status (S.Project_Search) =
            Editor.Project_Search.Project_Search_Ok
          and then Editor.Project_Search.Result_Count (S.Project_Search) >= 1,
          "project search did not find the fixture token");
   Search_Result := Editor.Project_Search.Selected_Result
     (S.Project_Search, Found);
   Check (Found, "project search did not select the first fixture result");

   Build_Context.Has_Request := True;
   Build_Context.Request := Smoke_Request;
   Build_Context.Gate := Editor.External_Producers.Build_Real_Execution_Gate
     (Allow_Diagnostics_Ingestion => True,
      Show_Diagnostics            => True,
      Consent                     => Editor.External_Producers.Build_Consent_User_Confirmed);
   Supplied_Process := Editor.External_Producers.Build_Process_Run_Result
     (Status        => Editor.External_Producers.Process_Run_Failed,
      Exit_Code     => 1,
      Has_Exit_Code => True,
      Stdout_Text   => "smoke build stdout",
      Stderr_Text   => Unit_Path & ":4:7: error: smoke diagnostic" & ASCII.LF);
   Build_Result := Editor.Executor.Execute_User_Opt_In_Build_Command
     (S, Build_Context, Supplied_Process);
   Check (Build_Result.Build_Result.Status =
            Editor.External_Producers.Build_Run_Failed,
          "build command did not publish the supplied failure result");
   Check (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) >= 1,
          "build diagnostic output was not ingested into Diagnostics");

   Editor.Workspace_Persistence.Clear (Workspace);
   Editor.Workspace_Persistence.Set_Project_Root (Workspace, Root);
   Editor.Workspace_Persistence.Add_Open_File
     (Workspace,
      (Path => To_Unbounded_String ("src/smoke_unit.adb"),
       Is_Project_Relative => True,
       Cursor_Row => Search_Result.Row,
       Cursor_Column => Search_Result.Match_Column,
       View_First_Row => 1));
   Editor.Workspace_Persistence.Set_Active_File_Path
     (Workspace, "src/smoke_unit.adb", True);
   Editor.Workspace_Persistence.Save_To_File
     (Workspace, Workspace_Path, Persist_Status);
   Check (Persist_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
          "workspace save failed");
   Editor.Workspace_Persistence.Load_From_File
     (Workspace_Path, Loaded, Persist_Status);
   Check (Persist_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
          "workspace reload failed");
   Check (Editor.Workspace_Persistence.Has_Project_Root (Loaded)
          and then Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1
          and then Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
          "workspace reload did not restore project/open/active file state");
   Check (Ada.Strings.Fixed.Index (Read_File (Workspace_Path), "Phase579_E2E_Token") = 0,
          "workspace persistence leaked source text");

   Editor.Input_Bridge.Set_State_For_Test (S);
   Editor.Input_Bridge.Build_Render_Packet (Packet);
   Check (Natural (Packet.Rect_Count) <= Editor.Render_Packet.Max_Rectangles,
          "render packet rectangle count exceeded the ABI maximum");
   Check (Natural (Packet.Glyph_Count) <= Editor.Render_Packet.Max_Glyphs,
          "render packet glyph count exceeded the ABI maximum");
   Check (Natural (Packet.Rect_Count) + Natural (Packet.Glyph_Count) > 0,
          "render packet was empty after product workflow");

   Remove_Tree_If_Exists (Root);
   Ada.Text_IO.Put_Line ("editor_product_smoke: PASS");
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when E : others =>
      Remove_Tree_If_Exists (Root);
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "editor_product_smoke: FAIL: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Editor_Product_Smoke;
