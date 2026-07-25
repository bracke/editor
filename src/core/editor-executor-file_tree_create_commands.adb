with Editor.Commands.Payloads;
with Ada.Directories;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Commands;
with Editor.Executor.File_Tree_Mutation_Commands;
with Editor.Executor.Shared_Services;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Kind;
with Editor.Project;
with Editor.State;

package body Editor.Executor.File_Tree_Create_Commands is

   procedure Execute_File_Tree_Create_File
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command)
   is
      Base_Found : Boolean := False;
      Base       : constant String :=
        Editor.Executor.File_Tree_Mutation_Commands
          .Selected_File_Tree_Base_Directory (S, Base_Found);
      Input      : constant String :=
        Editor.Executor.File_Tree_Mutation_Commands.File_Tree_Input_Text (Cmd);
      Target     : Unbounded_String := Null_Unbounded_String;
      File       : Ada.Text_IO.File_Type;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif Input'Length = 0 then
         Editor.Executor.Shared_Services.Report_Error (S, "Enter a name.");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Contains_Control_File_Tree_Input_Character (Input)
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid file name");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        and then not Editor.Executor.File_Tree_Mutation_Commands
          .Is_Windows_Drive_Absolute_File_Tree_Input (Input)
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid file name");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Input_Is_Absolute (Input)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S,
            Editor.Executor.File_Tree_Mutation_Commands
              .Absolute_File_Tree_Input_Message (S, Input));
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Contains_Parent_Traversal (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Has_Trailing_Path_Separator (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Contains_Current_Directory_Segment (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Contains_Empty_Relative_Path_Segment (Input)
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid file name");
         return;
      end if;

      declare
         Selected_Found   : Boolean := False;
         Selected_Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
           Editor.Executor.File_Tree_Mutation_Commands
             .Selected_File_Tree_Node_Summary (S, Selected_Found);
      begin
         if Base_Found
           and then Selected_Found
           and then Selected_Summary.Kind = Editor.File_Tree.Directory_Node
           and then not Editor.Executor.File_Tree_Mutation_Commands
             .File_Tree_Input_Has_Explicit_Directory (Input)
         then
            if not Ada.Directories.Exists
              (To_String (Selected_Summary.Absolute_Path))
              or else not Editor.Executor.File_Tree_Mutation_Commands
                .File_Tree_Source_Matches_Filesystem (Selected_Summary)
            then
               Editor.Executor.Shared_Services.Report_Warning
                 (S, Editor.Commands.Reason_File_Tree_Item_Stale);
               return;
            elsif not Editor.Executor.File_Tree_Mutation_Commands
              .File_Tree_Source_Project_Bounded (S, Selected_Summary)
            then
               Editor.Executor.Shared_Services.Report_Error
                 (S, "Target path is outside the project");
               return;
            end if;
         end if;
      end;

      if not Base_Found
        and then not Editor.Executor.File_Tree_Mutation_Commands
          .File_Tree_Input_Has_Explicit_Directory (Input)
      then
         Editor.Executor.Shared_Services.Report_Warning
           (S, "No target directory selected");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .Project_Bounded_File_Tree_Target (S, Input, Base, Target)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Target path is outside the project");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Open buffer already represents target path");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Parent_Directory_Available (S, To_String (Target))
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Parent directory unavailable");
         return;
      end if;

      begin
         Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, To_String (Target));
         Ada.Text_IO.Close (File);
         Editor.Executor.File_Tree_Mutation_Commands
           .Invalidate_Project_State_After_File_Tree_Mutation
             (S, To_String (Target));
         if Editor.Executor.File_Tree_Mutation_Commands
           .Refresh_File_Tree_Model_After_Operation (S)
         then
            Editor.Executor.File_Tree_Mutation_Commands.Select_File_Tree_Path
              (S, To_String (Target));
            Editor.Executor.Shared_Services.Report_Success (S, "File created.");
         else
            Editor.Executor.Shared_Services.Report_Warning
              (S, "File created; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error | Ada.IO_Exceptions.Name_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid file name");
         when Ada.IO_Exceptions.Use_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Permission denied");
         when others =>
            begin
               if Ada.Text_IO.Is_Open (File) then
                  Ada.Text_IO.Close (File);
               end if;
            exception
               when others => null;
            end;
            Editor.Executor.Shared_Services.Report_Error
              (S, "Could not create file");
      end;
   end Execute_File_Tree_Create_File;

   procedure Execute_File_Tree_Create_Directory
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command)
   is
      Base_Found : Boolean := False;
      Base       : constant String :=
        Editor.Executor.File_Tree_Mutation_Commands
          .Selected_File_Tree_Base_Directory (S, Base_Found);
      Input      : constant String :=
        Editor.Executor.File_Tree_Mutation_Commands.File_Tree_Input_Text (Cmd);
      Target     : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif Input'Length = 0 then
         Editor.Executor.Shared_Services.Report_Error (S, "Enter a name.");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Contains_Control_File_Tree_Input_Character (Input)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Invalid directory name");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        and then not Editor.Executor.File_Tree_Mutation_Commands
          .Is_Windows_Drive_Absolute_File_Tree_Input (Input)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Invalid directory name");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Input_Is_Absolute (Input)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S,
            Editor.Executor.File_Tree_Mutation_Commands
              .Absolute_File_Tree_Input_Message (S, Input));
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Contains_Parent_Traversal (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Has_Trailing_Path_Separator (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Contains_Current_Directory_Segment (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Contains_Empty_Relative_Path_Segment (Input)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Invalid directory name");
         return;
      end if;

      declare
         Selected_Found   : Boolean := False;
         Selected_Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
           Editor.Executor.File_Tree_Mutation_Commands
             .Selected_File_Tree_Node_Summary (S, Selected_Found);
      begin
         if Base_Found
           and then Selected_Found
           and then Selected_Summary.Kind = Editor.File_Tree.Directory_Node
           and then not Editor.Executor.File_Tree_Mutation_Commands
             .File_Tree_Input_Has_Explicit_Directory (Input)
         then
            if not Ada.Directories.Exists
              (To_String (Selected_Summary.Absolute_Path))
              or else not Editor.Executor.File_Tree_Mutation_Commands
                .File_Tree_Source_Matches_Filesystem (Selected_Summary)
            then
               Editor.Executor.Shared_Services.Report_Warning
                 (S, Editor.Commands.Reason_File_Tree_Item_Stale);
               return;
            elsif not Editor.Executor.File_Tree_Mutation_Commands
              .File_Tree_Source_Project_Bounded (S, Selected_Summary)
            then
               Editor.Executor.Shared_Services.Report_Error
                 (S, "Target path is outside the project");
               return;
            end if;
         end if;
      end;

      if not Base_Found
        and then not Editor.Executor.File_Tree_Mutation_Commands
          .File_Tree_Input_Has_Explicit_Directory (Input)
      then
         Editor.Executor.Shared_Services.Report_Warning
           (S, "No target directory selected");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .Project_Bounded_File_Tree_Target (S, Input, Base, Target)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Target path is outside the project");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Open buffer already represents target path");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Parent_Directory_Available (S, To_String (Target))
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Parent directory unavailable");
         return;
      end if;

      begin
         Ada.Directories.Create_Directory (To_String (Target));
         Editor.Executor.File_Tree_Mutation_Commands
           .Invalidate_Project_State_After_File_Tree_Mutation
             (S, To_String (Target));
         if Editor.Executor.File_Tree_Mutation_Commands
           .Refresh_File_Tree_Model_After_Operation (S)
         then
            Editor.Executor.File_Tree_Mutation_Commands.Select_File_Tree_Path
              (S, To_String (Target));
            Editor.Executor.Shared_Services.Report_Success
              (S, "Directory created.");
         else
            Editor.Executor.Shared_Services.Report_Warning
              (S, "Directory created; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Editor.Executor.Shared_Services.Report_Error
              (S, "Invalid directory name");
         when Ada.Directories.Use_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Permission denied");
         when others =>
            Editor.Executor.Shared_Services.Report_Error
              (S, "Could not create directory");
      end;
   end Execute_File_Tree_Create_Directory;

end Editor.Executor.File_Tree_Create_Commands;
