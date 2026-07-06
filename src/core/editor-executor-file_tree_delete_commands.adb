with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.File_Tree_Mutation_Commands;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.File_Tree.File_Tree_Node_Kind;
with Editor.Focus_Management;
with Editor.Project;
with Editor.State;

package body Editor.Executor.File_Tree_Delete_Commands is

   procedure Execute_File_Tree_Delete_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Found   : Boolean := False;
      Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
        Editor.Executor.File_Tree_Mutation_Commands
          .Selected_File_Tree_Node_Summary (S, Found);
      Confirm : constant String :=
        Editor.Executor.File_Tree_Mutation_Commands.File_Tree_Input_Text (Cmd);
      Parent_After_Delete : Unbounded_String := Null_Unbounded_String;
      Active_Buffer_Was_Deleted : Boolean := False;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Shared_Services.Report_Warning (S, "No File Tree node selected");
         return;
      elsif Summary.Parent = Editor.File_Tree.No_File_Tree_Node then
         Editor.Executor.Shared_Services.Report_Warning (S, "Cannot delete project root");
         return;
      elsif not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif not Ada.Directories.Exists (To_String (Summary.Absolute_Path)) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Target no longer exists.");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Source_Project_Bounded (S, Summary)
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .File_Tree_Source_Matches_Filesystem (Summary)
      then
         Editor.Executor.Shared_Services.Report_Warning
           (S, Editor.Commands.Reason_File_Tree_Item_Stale);
         return;
      elsif not Editor.Executor.File_Tree_Mutation_Commands
        .Delete_Confirmation_Accepted (Summary.Kind, Confirm)
      then
         --  Delete remains confirmation-first at the filesystem mutation
         --  boundary; unconfirmed routes must not reveal impact-specific
         --  outcomes or mutate state.
         Editor.Executor.Shared_Services.Report_Info (S, "Delete cancelled.");
         return;
      elsif Editor.Executor.File_Tree_Mutation_Commands
        .Open_Buffer_Blocks_File_Tree_Mutation
          (S, To_String (Summary.Absolute_Path), For_Delete => True)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty buffer preserved.");
         return;
      elsif Summary.Kind = Editor.File_Tree.Directory_Node
        and then not Editor.Executor.File_Tree_Mutation_Commands
          .Directory_Is_Empty (To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Directory is not empty");
         return;
      end if;

      if Summary.Parent /= Editor.File_Tree.No_File_Tree_Node then
         Parent_After_Delete :=
           Editor.File_Tree.Node (S.File_Tree, Summary.Parent).Absolute_Path;
      end if;

      Active_Buffer_Was_Deleted :=
        S.File_Info.Has_Path
        and then Editor.Executor.File_Tree_Mutation_Commands
          .Same_Or_Descendant_File_Tree_Path
            (To_String (S.File_Info.Path),
             To_String (Summary.Absolute_Path));

      begin
         if Summary.Kind = Editor.File_Tree.File_Node then
            Ada.Directories.Delete_File (To_String (Summary.Absolute_Path));
         else
            Ada.Directories.Delete_Directory (To_String (Summary.Absolute_Path));
         end if;

         Editor.Executor.File_Tree_Mutation_Commands
           .Invalidate_Project_State_After_File_Tree_Mutation
             (S, To_String (Summary.Absolute_Path));

         declare
            Closed_Count : Natural := 0;
         begin
            Editor.Buffers.Global_Close_Clean_File_Paths_Under
              (Path         => To_String (Summary.Absolute_Path),
               Closed_Count => Closed_Count);
            if Closed_Count > 0 then
               if Editor.Buffers.Global_Active_Buffer =
                 Editor.Buffers.No_Buffer
               then
                  S.Active_Buffer_Token := 0;
                  Editor.State.Load_Text (S, "");
                  Editor.Focus_Management.Set_Focus_Owner
                    (S, Editor.Focus_Management.Focus_File_Tree);
               else
                  Editor.Executor.Semantic_Index_Commands.Load_Global_Active_Preserving_Language_Index
                    (S);
                  if Active_Buffer_Was_Deleted then
                     Editor.Focus_Management.Restore_Focus_To_Editor (S);
                  end if;
               end if;
            end if;
         end;

         if Editor.Executor.File_Tree_Mutation_Commands
           .Refresh_File_Tree_Model_After_Operation (S)
         then
            if Length (Parent_After_Delete) > 0
              and then Ada.Directories.Exists (To_String (Parent_After_Delete))
            then
               Editor.Executor.File_Tree_Mutation_Commands.Select_File_Tree_Path
                 (S, To_String (Parent_After_Delete));
            end if;
            Editor.Executor.Shared_Services.Report_Success
              (S, Editor.Executor.File_Tree_Mutation_Commands
                    .File_Tree_Outcome_Kind_Label (Summary.Kind)
                  & " deleted.");
         else
            Editor.Executor.Shared_Services.Report_Warning
              (S, Editor.Executor.File_Tree_Mutation_Commands
                    .File_Tree_Outcome_Kind_Label (Summary.Kind)
                  & " deleted; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Target no longer exists.");
         when Ada.Directories.Use_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Permission denied");
         when others =>
            Editor.Executor.Shared_Services.Report_Error (S, "Could not delete File Tree item");
      end;
   end Execute_File_Tree_Delete_Selected;

end Editor.Executor.File_Tree_Delete_Commands;
