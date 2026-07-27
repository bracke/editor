with Editor.Commands.Payloads;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Commands.Workflow_Messages;
with Editor.Executor.File_Tree_Mutation_Commands;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Shared_Services;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.File_Tree.File_Tree_Node_Kind;
with Editor.Focus_Management;
with Editor.Project;
with Editor.State;

package body Editor.Executor.File_Tree_Rename_Commands is

   procedure Execute_File_Tree_Rename_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command)
   is
      Found   : Boolean := False;
      Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
        Editor.Executor.File_Tree_Mutation_Commands
          .Selected_File_Tree_Node_Summary (S, Found);
      Input   : constant String :=
        Editor.Executor.File_Tree_Mutation_Commands.File_Tree_Input_Text (Cmd);
      Target  : Unbounded_String := Null_Unbounded_String;
      Parent_Path : Unbounded_String := Null_Unbounded_String;
      Active_Buffer_Was_Renamed : Boolean := False;
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Shared_Services.Report_Warning
           (S, "No File Tree node selected");
         return;
      elsif not Editor.Project.Is_Under_Project
        (S.Project_Runtime.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Target path is outside the project");
         return;
      elsif Summary.Parent = Editor.File_Tree.No_File_Tree_Node then
         Editor.Executor.Shared_Services.Report_Warning
           (S, "Cannot rename project root");
         return;
      elsif Input'Length = 0 then
         Editor.Executor.Shared_Services.Report_Error (S, "Enter a name.");
         return;
      elsif Ada.Strings.Fixed.Index (Input, "/") /= 0
        or else Ada.Strings.Fixed.Index (Input, "\") /= 0
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Rename expects a single new name");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Contains_Control_File_Tree_Input_Character (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Contains_Parent_Traversal (Input)
        or else Editor.Executor.File_Tree_Mutation_Commands
          .Contains_Current_Directory_Segment (Input)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Invalid rename target");
         return;
      elsif not Ada.Directories.Exists (To_String (Summary.Absolute_Path)) then
         Editor.Executor.Shared_Services.Report_Warning
           (S, "Target no longer exists.");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Source_Project_Bounded (S, Summary)
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Target path is outside the project");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Source_Matches_Filesystem (Summary)
      then
         Editor.Executor.Shared_Services.Report_Warning
           (S, Editor.Commands.Workflow_Messages.Reason_File_Tree_Item_Stale);
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Open_Buffer_Blocks_File_Tree_Mutation
          (S, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Info
           (S, "Dirty buffer preserved.");
         return;
      end if;

      Parent_Path := Editor.File_Tree.Node (S.Surface.File_Tree, Summary.Parent).Absolute_Path;
      Target := To_Unbounded_String
        (Ada.Directories.Compose (To_String (Parent_Path), Input));
      Active_Buffer_Was_Renamed :=
        S.Buffer_Lifecycle.File_Info.Has_Path
        and then Editor.Executor.File_Tree_Mutation_Commands
          .Same_Or_Descendant_File_Tree_Path
            (To_String (S.Buffer_Lifecycle.File_Info.Path), To_String (Summary.Absolute_Path));

      if not Editor.Project.Is_Under_Project (S.Project_Runtime.Project, To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Target path is outside the project");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Same_Or_Descendant_File_Tree_Path
          (To_String (Summary.Absolute_Path), To_String (Target))
        and then Editor.Executor.File_Tree_Mutation_Commands
          .Same_Or_Descendant_File_Tree_Path
            (To_String (Target), To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Warning
           (S, "Rename target is unchanged");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Parent_Directory_Available (S, To_String (Target))
      then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Parent directory unavailable");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error
           (S, "Open buffer already represents target path");
         return;
      end if;

      begin
         Ada.Directories.Rename
           (Old_Name => To_String (Summary.Absolute_Path),
            New_Name => To_String (Target));

         declare
            Rebased_Count : Natural := 0;
         begin
            Editor.Buffers.Global_Rebase_Clean_File_Paths
              (Old_Root      => To_String (Summary.Absolute_Path),
               New_Root      => To_String (Target),
               Rebased_Count => Rebased_Count);
            if Rebased_Count > 0 then
               Editor.Executor.Semantic_Index_Commands
                 .Load_Global_Active_Preserving_Language_Index (S);
               if Active_Buffer_Was_Renamed then
                  Editor.Focus_Management.Restore_Focus_To_Editor (S);
               end if;
            else
               Editor.Executor.File_Tree_Mutation_Commands
                 .Update_Active_Buffer_After_File_Tree_Rename
                   (S, To_String (Summary.Absolute_Path), To_String (Target));
            end if;
         end;

         Editor.Executor.File_Tree_Mutation_Commands
           .Invalidate_Project_State_After_File_Tree_Mutation
             (S, To_String (Summary.Absolute_Path), To_String (Target));

         if Editor.Executor.File_Tree_Mutation_Commands
           .Refresh_File_Tree_Model_After_Operation (S)
         then
            Editor.Executor.File_Tree_Mutation_Commands.Select_File_Tree_Path
              (S, To_String (Target));
            Editor.Executor.Shared_Services.Report_Success
              (S,
               Editor.Executor.File_Tree_Mutation_Commands
                 .File_Tree_Outcome_Kind_Label (Summary.Kind) & " renamed.");
         else
            Editor.Executor.Shared_Services.Report_Warning
              (S,
               Editor.Executor.File_Tree_Mutation_Commands
                 .File_Tree_Outcome_Kind_Label (Summary.Kind)
               & " renamed; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Editor.Executor.Shared_Services.Report_Error
              (S, "Invalid rename target");
         when Ada.Directories.Use_Error =>
            Editor.Executor.Shared_Services.Report_Error
              (S, "Permission denied");
         when others =>
            Editor.Executor.Shared_Services.Report_Error
              (S, "Could not rename File Tree item");
      end;
   end Execute_File_Tree_Rename_Selected;

end Editor.Executor.File_Tree_Rename_Commands;
