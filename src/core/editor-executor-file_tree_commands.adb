with Ada.Characters.Handling;
with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.IO_Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Build_Candidates;
with Editor.Build_UI;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Diagnostics;
with Editor.Executor;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Tree_Delete_Commands;
with Editor.Executor.File_Tree_Mutation_Commands;
with Editor.Executor.File_Tree_Navigation_Commands;
with Editor.Executor.Project_File_Index_Commands;
with Editor.Feature_Diagnostics;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.File_Tree.File_Tree_Node_Kind;
use type Editor.File_Tree.File_Tree_Scan_Status;
with Editor.File_Tree_View;
use type Editor.File_Tree_View.File_Tree_Action;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Layout;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Outline;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Project;
use type Editor.Project.Project_File_Refresh_Status;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Render_Cache;
with Editor.State;
with Editor.Syntax_Semantics;
with Editor.View;

package body Editor.Executor.File_Tree_Commands is

   use Editor.Commands;

   function File_Tree_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;

      function Has_Project return Boolean is
      begin
         return Editor.Project.Has_Project (S.Project);
      end Has_Project;

      function File_Tree_Has_Selected_Row return Boolean is
      begin
         return Editor.File_Tree.Visible_Row_Count (S.File_Tree) > 0
           and then Editor.File_Tree_View.Selected_Row_Index
             (S.File_Tree_View) /= 0;
      end File_Tree_Has_Selected_Row;

      function Selected_File_Tree_Node
        (Found : out Boolean) return Editor.File_Tree.File_Tree_Node_Summary
      is
         Node_Id : constant Editor.File_Tree.File_Tree_Node_Id :=
           Editor.File_Tree_View.Node_For_Row
             (S.File_Tree,
              Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View),
              Found);
      begin
         if not Found then
            return (others => <>);
         end if;
         return Editor.File_Tree.Node (S.File_Tree, Node_Id);
      end Selected_File_Tree_Node;
   begin
      case Id is
         when Command_Refresh_File_Tree
            | Command_Refresh_Project_Files
            | Command_Focus_File_Tree =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when Command_Project_Files_Summary =>
            return Editor.Commands.Available;

         when Command_Reveal_Active_File_In_Tree
            | Command_File_Tree_Expand_To_Active_File =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not S.File_Info.Has_Path or else Length (S.File_Info.Path) = 0 then
               return Editor.Commands.Unavailable ("Active buffer has no file path");
            elsif not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Editor.Project.Is_Under_Project
              (S.Project, To_String (S.File_Info.Path))
            then
               return Editor.Commands.Unavailable
                 ("Active file is outside the current project");
            elsif Editor.File_Tree.Is_Empty (S.File_Tree) then
               return Editor.Commands.Unavailable ("File Tree unavailable");
            end if;
            return Editor.Commands.Available;

         when Command_File_Tree_Move_Up
            | Command_File_Tree_Move_Down
            | Command_File_Tree_Page_Up
            | Command_File_Tree_Page_Down =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus) then
               return Editor.Commands.Unavailable ("Command not available here");
            end if;
            return Editor.Commands.Available;

         when Command_File_Tree_Open_Selected =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus) then
               return Editor.Commands.Unavailable ("Command not available here");
            elsif not File_Tree_Has_Selected_Row then
               return Editor.Commands.Unavailable ("No File Tree node selected");
            else
               declare
                  Found : Boolean := False;
                  Node  : constant Editor.File_Tree.File_Tree_Node_Summary :=
                    Selected_File_Tree_Node (Found);
               begin
                  if not Found then
                     return Editor.Commands.Unavailable ("No File Tree node selected");
                  elsif Node.Kind /= Editor.File_Tree.File_Node then
                     return Editor.Commands.Unavailable
                       ("Selected row is not a file");
                  elsif not Editor.Project.Is_Under_Project
                    (S.Project, To_String (Node.Absolute_Path))
                  then
                     return Editor.Commands.Unavailable
                       ("Target path is outside the project");
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_File_Tree_Create_File
            | Command_File_Tree_Create_Directory
            | Command_File_Tree_Rename_Selected
            | Command_File_Tree_Delete_Selected =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not File_Tree_Has_Selected_Row
              and then Id /= Command_File_Tree_Create_File
              and then Id /= Command_File_Tree_Create_Directory
            then
               return Editor.Commands.Unavailable ("No File Tree node selected");
            elsif Id = Command_File_Tree_Rename_Selected
              or else Id = Command_File_Tree_Delete_Selected
            then
               declare
                  Found : Boolean := False;
                  Node  : constant Editor.File_Tree.File_Tree_Node_Summary :=
                    Selected_File_Tree_Node (Found);
               begin
                  if not Found then
                     return Editor.Commands.Unavailable
                       ("No File Tree node selected");
                  elsif not Editor.Project.Is_Under_Project
                    (S.Project, To_String (Node.Absolute_Path))
                  then
                     return Editor.Commands.Unavailable
                       ("Target path is outside the project");
                  elsif Node.Parent = Editor.File_Tree.No_File_Tree_Node then
                     if Id = Command_File_Tree_Rename_Selected then
                        return Editor.Commands.Unavailable
                          ("Cannot rename project root");
                     else
                        return Editor.Commands.Unavailable
                          ("Cannot delete project root");
                     end if;
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_File_Tree_Expand_Selected
            | Command_File_Tree_Collapse_Selected
            | Command_File_Tree_Toggle_Selected =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif not Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus) then
               return Editor.Commands.Unavailable ("Command not available here");
            elsif not File_Tree_Has_Selected_Row then
               return Editor.Commands.Unavailable ("No File Tree node selected");
            else
               declare
                  Found : Boolean := False;
                  Node  : constant Editor.File_Tree.File_Tree_Node_Summary :=
                    Selected_File_Tree_Node (Found);
               begin
                  if not Found then
                     return Editor.Commands.Unavailable ("No File Tree node selected");
                  elsif not Editor.Project.Is_Under_Project
                    (S.Project, To_String (Node.Absolute_Path))
                  then
                     return Editor.Commands.Unavailable
                       ("Target path is outside the project");
                  elsif Node.Kind /= Editor.File_Tree.Directory_Node then
                     return Editor.Commands.Unavailable
                       ("Selected row is not a directory");
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_File_Tree_Collapse_All =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            elsif Editor.File_Tree.Is_Empty (S.File_Tree) then
               return Editor.Commands.Unavailable ("File Tree unavailable");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a file tree command");
      end case;
   end File_Tree_Command_Availability;

   function Result_After_Command
     (S               : Editor.State.State_Type;
      Command         : Editor.Commands.Command_Id;
      Before_Messages : Natural)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      if Editor.Messages.Count (S.Messages) > Before_Messages then
         Msg := Editor.Messages.Active_Message (S.Messages, Found);
         if Found then
            if Editor.Messages.Severity (Msg) =
              Editor.Messages.Error_Message
            then
               return Editor.Command_Execution.Failed (Command);
            elsif Editor.Messages.Severity (Msg) =
              Editor.Messages.Warning_Message
            then
               return Editor.Command_Execution.Unavailable (Command);
            end if;
         end if;
      end if;

      return Editor.Command_Execution.Executed (Command);
   end Result_After_Command;

   function Execute_File_Tree_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);
   begin
      case Id is
         when Command_Refresh_Project_Files =>
            Editor.Executor.Project_File_Index_Commands
              .Execute_Refresh_Project_Files (S);

         when Command_Project_Files_Summary =>
            Editor.Executor.Project_File_Index_Commands
              .Execute_Project_Files_Summary (S);

         when Command_Reveal_Active_File_In_Tree =>
            Editor.Executor.Project_File_Index_Commands
              .Execute_Reveal_Active_File_In_Tree (S);
            Editor.Render_Cache.Invalidate_All;

         when others =>
            raise Program_Error with "unsupported file-tree result command";
      end case;

      return Result_After_Command (S, Id, Before_Messages);
   end Execute_File_Tree_Result_Command;

   procedure Execute_File_Tree_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
   begin
      case Cmd.Kind is
         when Refresh_File_Tree =>
            Editor.Executor.Project_File_Index_Commands
              .Execute_Refresh_File_Tree (S);

         when Refresh_Project_Files =>
            Editor.Executor.Project_File_Index_Commands
              .Execute_Refresh_Project_Files (S);

         when Project_Files_Summary =>
            Editor.Executor.Project_File_Index_Commands
              .Execute_Project_Files_Summary (S);

         when Reveal_Active_File_In_Tree =>
            Editor.Executor.Project_File_Index_Commands
              .Execute_Reveal_Active_File_In_Tree (S);

         when Focus_File_Tree =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_Focus_File_Tree (S);

         when File_Tree_Move_Up =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Move_Up (S);

         when File_Tree_Move_Down =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Move_Down (S);

         when File_Tree_Page_Up =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Page_Up (S);

         when File_Tree_Page_Down =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Page_Down (S);

         when File_Tree_Open_Selected =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Open_Selected (S);

         when File_Tree_Create_File =>
            Editor.Executor.File_Tree_Mutation_Commands
              .Execute_File_Tree_Create_File (S, Cmd);

         when File_Tree_Create_Directory =>
            Editor.Executor.File_Tree_Mutation_Commands
              .Execute_File_Tree_Create_Directory (S, Cmd);

         when File_Tree_Rename_Selected =>
            Editor.Executor.File_Tree_Mutation_Commands
              .Execute_File_Tree_Rename_Selected (S, Cmd);

         when File_Tree_Delete_Selected =>
            Editor.Executor.File_Tree_Delete_Commands
              .Execute_File_Tree_Delete_Selected (S, Cmd);

         when File_Tree_Expand_Selected =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Expand_Selected (S);

         when File_Tree_Collapse_Selected =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Collapse_Selected (S);

         when File_Tree_Toggle_Selected =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Toggle_Selected (S);

         when File_Tree_Collapse_All =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Collapse_All (S);

         when File_Tree_Expand_To_Active_File =>
            Editor.Executor.File_Tree_Navigation_Commands
              .Execute_File_Tree_Expand_To_Active_File (S);

         when others =>
            raise Program_Error with "unsupported file tree command kind";
      end case;
   end Execute_File_Tree_Kind;

end Editor.Executor.File_Tree_Commands;
