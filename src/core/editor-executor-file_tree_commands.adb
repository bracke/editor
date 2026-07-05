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

   function Natural_Image_Trimmed (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Natural_Image_Trimmed;

   function File_Count_Text (Count : Natural) return String is
   begin
      if Count = 1 then
         return "1 file";
      else
         return Natural_Image_Trimmed (Count) & " files";
      end if;
   end File_Count_Text;

   function Format_Project_File_Refresh_Message
     (Result : Editor.Project.Project_File_Refresh_Result) return String
   is
      Text : Unbounded_String := To_Unbounded_String
        ("Project files refreshed: " & File_Count_Text (Result.Total_Count));
   begin
      if Result.Added_Count > 0 then
         Append (Text, "; added " & Natural_Image_Trimmed (Result.Added_Count));
      end if;
      if Result.Removed_Count > 0 then
         Append (Text, "; removed " & Natural_Image_Trimmed (Result.Removed_Count));
      end if;
      if Result.Ignored_Path_Count > 0 then
         Append
           (Text,
            "; excluded " & Natural_Image_Trimmed (Result.Ignored_Path_Count)
            & (if Result.Ignored_Path_Count = 1 then " ignored path" else " ignored paths"));
      end if;
      if Result.Invalid_Ignore_Pattern_Count > 0 then
         Append
           (Text,
            "; ignored " & Natural_Image_Trimmed (Result.Invalid_Ignore_Pattern_Count)
            & (if Result.Invalid_Ignore_Pattern_Count = 1 then " invalid pattern" else " invalid patterns"));
      end if;
      if Result.Skipped_Directory_Count > 0 then
         Append
           (Text,
            "; skipped " & Natural_Image_Trimmed (Result.Skipped_Directory_Count)
            & (if Result.Skipped_Directory_Count = 1 then " directory" else " directories"));
      end if;
      return To_String (Text);
   end Format_Project_File_Refresh_Message;

   function Format_Project_File_Summary_Message
     (S : Editor.State.State_Type) return String
   is
      Count : constant Natural := Editor.Project.Known_File_Count (S.Project);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         return "No project open";
      elsif Count = 0 then
         return "No project open.";
      elsif Editor.Project.Has_Last_Refresh_Summary (S.Project) then
         declare
            Summary : constant Editor.Project.Project_File_Refresh_Result :=
              Editor.Project.Last_Refresh_Summary (S.Project);
            Text : Unbounded_String := To_Unbounded_String
              ("Project files: " & Natural_Image_Trimmed (Count) & " known files");
         begin
            if Summary.Added_Count > 0 or else Summary.Removed_Count > 0 then
               Append (Text, "; last refresh");
               if Summary.Added_Count > 0 then
                  Append (Text, " added " & Natural_Image_Trimmed (Summary.Added_Count));
               end if;
               if Summary.Removed_Count > 0 then
                  if Summary.Added_Count > 0 then
                     Append (Text, ",");
                  end if;
                  Append (Text, " removed " & Natural_Image_Trimmed (Summary.Removed_Count));
               end if;
            end if;
            if Summary.Ignored_Path_Count > 0 then
               Append
                 (Text,
                  (if Summary.Added_Count > 0 or else Summary.Removed_Count > 0 then ";" else "; last refresh")
                  & " excluded " & Natural_Image_Trimmed (Summary.Ignored_Path_Count)
                  & (if Summary.Ignored_Path_Count = 1 then " ignored path" else " ignored paths"));
            end if;
            if Summary.Invalid_Ignore_Pattern_Count > 0 then
               Append
                 (Text,
                  "; last refresh ignored "
                  & Natural_Image_Trimmed (Summary.Invalid_Ignore_Pattern_Count)
                  & (if Summary.Invalid_Ignore_Pattern_Count = 1 then " invalid pattern" else " invalid patterns"));
            end if;
            return To_String (Text);
         end;
      else
         return "Project files: " & Natural_Image_Trimmed (Count) & " known files";
      end if;
   end Format_Project_File_Summary_Message;

   function File_Tree_Refresh_Failure_Message
     (Result : Editor.File_Tree.File_Tree_Scan_Result) return String
   is
   begin
      case Result.Status is
         when Editor.File_Tree.File_Tree_Scan_Ok =>
            return "ok";
         when Editor.File_Tree.File_Tree_No_Project =>
            return "No project open";
         when Editor.File_Tree.File_Tree_Invalid_Root
            | Editor.File_Tree.File_Tree_Root_Not_Found
            | Editor.File_Tree.File_Tree_Root_Not_Directory =>
            return "Project root unavailable";
         when Editor.File_Tree.File_Tree_Permission_Denied =>
            return "Permission denied";
         when Editor.File_Tree.File_Tree_Read_Error =>
            return "File Tree unavailable";
      end case;
   end File_Tree_Refresh_Failure_Message;

   procedure Execute_Refresh_Project_Files
     (S : in out Editor.State.State_Type)
   is
      Result : Editor.Project.Project_File_Refresh_Result;
   begin
      Editor.Project.Refresh_Known_Files (S.Project, Result);
      if Result.Status = Editor.Project.Project_File_Refresh_Ok then
         Editor.Executor.Rebuild_Language_Index_After_File_Lifecycle (S);
         if Editor.Quick_Open.Is_Open (S.Quick_Open) then
            Editor.Executor.Recompute_Quick_Open (S);
         end if;
         Editor.Project_Search.Clear_Results_Preserve_Query (S.Project_Search);
         Editor.Executor.Report_Success
           (S, Format_Project_File_Refresh_Message (Result));
      else
         Editor.Executor.Report_Error
           (S, "Could not refresh project files: "
            & (if Length (Result.Failure_Reason) > 0
               then To_String (Result.Failure_Reason)
               else "filesystem error"));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Refresh_Project_Files;

   procedure Execute_Project_Files_Summary
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Report_Info (S, Format_Project_File_Summary_Message (S));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Files_Summary;

   procedure Execute_Reveal_Active_File_In_Tree
     (S : in out Editor.State.State_Type)
   is
      Path       : Unbounded_String := Null_Unbounded_String;
      Found      : Boolean := False;
      Node       : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Parent     : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Row_Found  : Boolean := False;
      Row        : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      if S.Active_Buffer_Token = Natural (Editor.Buffers.Global_Active_Buffer) then
         Editor.Buffers.Sync_Global_Active_From_State (S);
      elsif Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer then
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;

      if Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer then
         Editor.Executor.Report_Info (S, "No active buffer.");
         return;
      elsif not S.File_Info.Has_Path or else Length (S.File_Info.Path) = 0 then
         Editor.Executor.Report_Info (S, "Active buffer has no file path");
         return;
      elsif not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      end if;

      Path := S.File_Info.Path;
      if not Ada.Directories.Exists (To_String (Path)) then
         Editor.Executor.Report_Warning (S, "Active file no longer exists");
         return;
      elsif not Editor.Project.Is_Under_Project (S.Project, To_String (Path)) then
         Editor.Executor.Report_Info (S, "Active file is outside the current project");
         return;
      elsif Editor.File_Tree.Is_Empty (S.File_Tree) then
         Editor.Executor.Report_Info (S, "File Tree unavailable");
         return;
      end if;

      declare
         Relative_Path : constant String :=
           Editor.Project.Relative_Path (S.Project, To_String (Path));
      begin
         Node := Editor.File_Tree.Find_By_Path (S.File_Tree, Relative_Path, Found);
      end;
      if not Found or else Node = Editor.File_Tree.No_File_Tree_Node then
         Editor.Executor.Report_Info (S, "File Tree refresh required");
         return;
      end if;

      Parent := Editor.File_Tree.Node (S.File_Tree, Node).Parent;
      while Parent /= Editor.File_Tree.No_File_Tree_Node loop
         Editor.File_Tree.Set_Expanded (S.File_Tree, Parent, True);
         Parent := Editor.File_Tree.Node (S.File_Tree, Parent).Parent;
      end loop;
      Editor.File_Tree.Rebuild_Visible_Rows (S.File_Tree);

      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      if Row_Found then
         Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
         Editor.File_Tree_View.Ensure_Selected_Row_Visible
           (S.File_Tree_View, S.File_Tree, Editor.File_Tree.Visible_Row_Count (S.File_Tree));
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_File_Tree);
         Editor.Executor.Report_Success (S, "Active file revealed in File Tree");
      else
         Editor.Executor.Report_Info (S, "File Tree row unavailable");
      end if;
   end Execute_Reveal_Active_File_In_Tree;

   procedure Execute_Refresh_File_Tree
     (S : in out Editor.State.State_Type)
   is
      Tree   : Editor.File_Tree.File_Tree_State;
      Result : Editor.File_Tree.File_Tree_Scan_Result;
      Selected_Found : Boolean := False;
      Selected_Node  : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Selected_Path  : Unbounded_String := Null_Unbounded_String;
      Restored_Row   : Natural := 0;
      Selection_Disappeared : Boolean := False;
      Default_Collapsed_Load : constant Boolean :=
        Editor.File_Tree.Is_Empty (S.File_Tree)
        or else Editor.File_Tree.Expanded_Node_Count (S.File_Tree) <= 1;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.File_Tree.Clear (S.File_Tree);
         Editor.File_Tree_View.Clear_View (S.File_Tree_View);
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      end if;

      Selected_Node := Editor.File_Tree_View.Node_For_Row
        (S.File_Tree,
         Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View),
         Selected_Found);
      if Selected_Found then
         Selected_Path := Editor.File_Tree.Node
           (S.File_Tree, Selected_Node).Relative_Path;
      end if;

      Tree := Editor.File_Tree.Scan_Project
        (Editor.Project.Root_Path (S.Project));
      Result := Editor.File_Tree.Scan_Status (Tree);

      if Result.Status = Editor.File_Tree.File_Tree_Scan_Ok then
         Editor.File_Tree.Preserve_Expanded_Paths_From
           (Tree   => Tree,
            Source => S.File_Tree);
         if Default_Collapsed_Load
           and then (Length (Selected_Path) = 0
                     or else To_String (Selected_Path) = ".")
         then
            Editor.File_Tree.Expand_File_Ancestors (Tree);
         end if;

         S.File_Tree := Tree;
         Editor.Executor.Populate_Project_Known_Files_From_File_Tree (S);

         if Length (Selected_Path) > 0 then
            declare
               New_Found : Boolean := False;
               New_Node  : constant Editor.File_Tree.File_Tree_Node_Id :=
                 Editor.File_Tree.Find_By_Path
                   (S.File_Tree, To_String (Selected_Path), New_Found);
               Row_Found : Boolean := False;
            begin
               if New_Found then
                  Restored_Row := Editor.File_Tree_View.Row_For_Node
                    (S.File_Tree, New_Node, Row_Found);
                  if Row_Found then
                     Editor.File_Tree_View.Set_Selected_Row_Index
                       (S.File_Tree_View, Restored_Row);
                  else
                     Editor.File_Tree_View.Clear_View (S.File_Tree_View);
                     Selection_Disappeared := True;
                  end if;
               else
                  Editor.File_Tree_View.Clear_View (S.File_Tree_View);
                  Selection_Disappeared := True;
               end if;
            end;
         end if;

         Editor.Executor.Validate_File_Tree_View (S);
         if Selection_Disappeared then
            Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 0);
            Editor.File_Tree_View.Set_Top_Row (S.File_Tree_View, 1);
         end if;
         Editor.Project_Search.Mark_Stale (S.Project_Search);
         if Editor.Quick_Open.Is_Open (S.Quick_Open) then
            Editor.Executor.Recompute_Quick_Open (S);
         end if;

         if Ada.Strings.Fixed.Index
           (To_String (Result.Error_Text), "limit reached") /= 0
         then
            Editor.Executor.Report_Warning (S, "File Tree refresh limit reached");
         elsif Selection_Disappeared then
            Editor.Executor.Report_Warning
              (S, "File tree refreshed; selected path no longer exists");
         elsif Length (Result.Error_Text) > 0 then
            Editor.Executor.Report_Warning
              (S, "File tree refreshed with warnings: " &
                    To_String (Result.Error_Text));
         else
            Editor.Executor.Report_Success (S, "File tree refreshed");
         end if;
      else
         Editor.File_Tree.Clear (S.File_Tree);
         Editor.File_Tree_View.Clear_View (S.File_Tree_View);
         Editor.Project.Clear_Known_Files (S.Project);
         Editor.Project_Search.Mark_Stale (S.Project_Search);
         if Editor.Quick_Open.Is_Open (S.Quick_Open) then
            Editor.Executor.Recompute_Quick_Open (S);
         end if;
         Editor.Executor.Report_Error
           (S, "File tree refresh failed: " & File_Tree_Refresh_Failure_Message (Result));
      end if;
   end Execute_Refresh_File_Tree;

   procedure Execute_Focus_File_Tree
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         Editor.Focus_Management.Restore_Focus_To_Editor (S);
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.File_Tree_Panel, True);
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Focus_File_Tree;

   procedure Execute_File_Tree_Move_Up
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.File_Tree_View.Move_Selection
        (S.File_Tree_View, S.File_Tree, Editor.File_Tree_View.Previous_Row);
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Move_Up;

   procedure Execute_File_Tree_Move_Down
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.File_Tree_View.Move_Selection
        (S.File_Tree_View, S.File_Tree, Editor.File_Tree_View.Next_Row);
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Move_Down;

   procedure Execute_File_Tree_Page_Up
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.File_Tree_View.Move_Selection_By
        (S.File_Tree_View, S.File_Tree, -Integer (Editor.Executor.File_Tree_Visible_Row_Count_For_View));
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Page_Up;

   procedure Execute_File_Tree_Page_Down
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.File_Tree_View.Move_Selection_By
        (S.File_Tree_View, S.File_Tree, Integer (Editor.Executor.File_Tree_Visible_Row_Count_For_View));
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Page_Down;

   procedure Execute_File_Tree_Open_Selected
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Node  : constant Editor.File_Tree.File_Tree_Node_Id := Editor.Executor.Selected_File_Tree_Node (S, Found);
      Summary : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Report_Warning (S, "No File Tree node selected");
         return;
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);
      if Summary.Kind /= Editor.File_Tree.File_Node then
         --  /545: the open-selected command opens real file nodes
         --  only.  Directory activation remains explicit through
         --  expand/collapse/toggle commands, so status/directory rows cannot
         --  masquerade as file opens.
         Editor.Executor.Report_Warning (S, "Selected row is not a file");
      elsif not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         --  completeness: File Tree nodes normally originate from
         --  the bounded project scan, but command execution must still defend
         --  the project boundary if stale/corrupt transient tree state reaches
         --  the Executor.  Opening a selected File Tree row must not become an
         --  escape hatch to a recent-project or absolute path outside the
         --  active project root.
         Editor.Executor.Report_Error (S, "Target path is outside the project");
      else
         --  Use the canonical explicit open/focus route rather than a
         --  File-Tree-specific filesystem preflight.  Existing buffers,
         --  including dirty ones whose backing file disappeared, are focused
         --  without disk I/O; missing or unreadable unopened paths fail through
         --  Editor.Executor.File_Open_Commands.Execute_Open_File's normal message path.
         Editor.Executor.File_Open_Commands.Execute_Open_File (S, To_String (Summary.Absolute_Path));
         Editor.Focus_Management.Restore_Focus_To_Editor (S);
      end if;
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Open_Selected;

   procedure Execute_File_Tree_Node_Action
     (S      : in out Editor.State.State_Type;
      Node   : Editor.File_Tree.File_Tree_Node_Id;
      Action : Editor.File_Tree_View.File_Tree_Action)
   is
      Summary : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if Action = Editor.File_Tree_View.No_File_Tree_Action
        or else Node = Editor.File_Tree.No_File_Tree_Node
        or else not Editor.File_Tree.Contains (S.File_Tree, Node)
      then
         return;
      end if;

      --  Mouse/row File Tree activation is a normal post-cleanup action even
      --  when it bypasses Execute_Command_With_Result. It should not leave
      --  restore feedback as the current Status Bar command result.
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);

      case Action is
         when Editor.File_Tree_View.No_File_Tree_Action =>
            null;

         when Editor.File_Tree_View.Toggle_Directory_Action =>
            if Summary.Kind = Editor.File_Tree.Directory_Node then
               --  Completeness: mouse/row activation is local UI input, but
               --  it still mutates File Tree view state. Recheck the active
               --  project boundary before toggling so stale transient rows
               --  cannot expand/collapse an outside-root node.
               if Editor.Project.Has_Project (S.Project)
                 and then not Editor.Project.Is_Under_Project
                   (S.Project, To_String (Summary.Absolute_Path))
               then
                  Editor.Executor.Report_Error
                    (S, "Target path is outside the project");
               else
                  Editor.File_Tree.Toggle_Expanded (S.File_Tree, Node);
               end if;
            end if;

         when Editor.File_Tree_View.Open_File_Action =>
            if Summary.Kind = Editor.File_Tree.File_Node then
               --  Route through the same explicit open/focus path used by
               --  Command_Open_File. That path first focuses an already-open
               --  buffer without rereading disk, and otherwise owns missing,
               --  unreadable, and successful-open feedback.
               if Editor.Project.Has_Project (S.Project)
                 and then not Editor.Project.Is_Under_Project
                   (S.Project, To_String (Summary.Absolute_Path))
               then
                  Editor.Executor.Report_Error
                    (S, "Target path is outside the project");
               else
                  Editor.Executor.File_Open_Commands.Execute_Open_File
                    (S, To_String (Summary.Absolute_Path));
               end if;
            end if;
      end case;
   end Execute_File_Tree_Node_Action;

   procedure Execute_File_Tree_Action
     (S   : in out Editor.State.State_Type;
      Hit : Editor.File_Tree_View.File_Tree_Hit_Result)
   is
      Action : constant Editor.File_Tree_View.File_Tree_Action :=
        Editor.File_Tree_View.Action_For_Hit (S.File_Tree, Hit);
   begin
      if Hit.Node_Id /= Editor.File_Tree.No_File_Tree_Node then
         --  Row activation must not mutate transient File Tree selection
         --  before the same project-context and boundary checks used by the
         --  actual row action.
         if not Editor.Project.Has_Project (S.Project) then
            Editor.Executor.Report_Warning (S, "No project open");
            return;
         elsif not Editor.File_Tree.Contains (S.File_Tree, Hit.Node_Id) then
            return;
         else
            declare
               Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
                 Editor.File_Tree.Node (S.File_Tree, Hit.Node_Id);
            begin
               if not Editor.Project.Is_Under_Project
                 (S.Project, To_String (Summary.Absolute_Path))
               then
                  Editor.Executor.Report_Error
                    (S, "Target path is outside the project");
                  return;
               end if;
            end;
         end if;

         Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Hit.Row);
         Editor.Executor.Validate_File_Tree_View (S);
      end if;
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Execute_File_Tree_Node_Action (S, Hit.Node_Id, Action);
      Editor.Executor.Validate_File_Tree_View (S);
   end Execute_File_Tree_Action;



   function File_Tree_Input_Text
     (Cmd : Editor.Commands.Command) return String
   is
   begin
      --  File Tree project-explorer commands consume only explicit prompt text.
      --  Path payloads are deliberately ignored so Command Palette entries and
      --  keybindings cannot smuggle filesystem targets into create/rename/delete.
      --  The explicit text is normalized at the command boundary so whitespace-
      --  only prompts are rejected as empty names and confirmations tolerate
      --  ordinary prompt padding without changing the accepted tokens.
      return Ada.Strings.Fixed.Trim (To_String (Cmd.Text), Ada.Strings.Both);
   end File_Tree_Input_Text;

   function Contains_Parent_Traversal (Value : String) return Boolean is
      Segment : Unbounded_String := Null_Unbounded_String;

      procedure Check_Segment (Found : in out Boolean) is
      begin
         if To_String (Segment) = ".." then
            Found := True;
         end if;
         Segment := Null_Unbounded_String;
      end Check_Segment;

      Found : Boolean := False;
   begin
      for Ch of Value loop
         if Ch = '/' or else Ch = Character'Val (16#5C#) then
            Check_Segment (Found);
            exit when Found;
         else
            Append (Segment, Ch);
         end if;
      end loop;
      if not Found then
         Check_Segment (Found);
      end if;
      return Found;
   end Contains_Parent_Traversal;

   function Contains_Current_Directory_Segment (Value : String) return Boolean is
      Segment : Unbounded_String := Null_Unbounded_String;

      procedure Check_Segment (Found : in out Boolean) is
      begin
         if To_String (Segment) = "." then
            Found := True;
         end if;
         Segment := Null_Unbounded_String;
      end Check_Segment;

      Found : Boolean := False;
   begin
      --  completeness: File Tree create/rename targets are explicit
      --  user-facing names, not shell paths.  Reject no-op current-directory
      --  segments so prompts such as ".", "./file", or "src/./file" do
      --  not reach filesystem mutation or produce misleading already-exists
      --  messages.  Parent traversal remains rejected separately.
      for Ch of Value loop
         if Ch = '/' or else Ch = Character'Val (16#5C#) then
            Check_Segment (Found);
            exit when Found;
         else
            Append (Segment, Ch);
         end if;
      end loop;
      if not Found then
         Check_Segment (Found);
      end if;
      return Found;
   end Contains_Current_Directory_Segment;



   function Contains_Control_File_Tree_Input_Character
     (Value : String) return Boolean
   is
   begin
      --  completeness: project-explorer names are prompt text, not
      --  raw byte payloads.  Reject ASCII control characters before filesystem
      --  mutation so embedded newlines, tabs, or NUL-like characters cannot
      --  become host filenames or confusing command messages.
      for Ch of Value loop
         if Character'Pos (Ch) < 32 or else Character'Pos (Ch) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Control_File_Tree_Input_Character;



   function Strip_Trailing_File_Tree_Path_Separators
     (Value : String) return String;

   function Is_Absolute_Path (Path : String) return Boolean;

   function Contains_Empty_Relative_Path_Segment (Value : String) return Boolean is
      Effective : constant String :=
        Strip_Trailing_File_Tree_Path_Separators (Value);
      Previous_Was_Separator : Boolean := False;
      Saw_Separator          : Boolean := False;
   begin
      --  completeness: project-explorer prompts are explicit names
      --  or simple project-relative paths, not shell-normalized path strings.
      --  Reject empty relative path components such as "src//file" or
      --  "src\\\\file" before filesystem mutation so they cannot be silently
      --  normalized by the host runtime or produce misleading target paths.
      --  Absolute paths are left to the canonical project-boundary check so
      --  outside-root absolutes still report the boundary failure.
      if Effective'Length = 0
        or else Is_Absolute_Path (Effective)
      then
         return False;
      end if;

      for Ch of Effective loop
         if Ch = '/' or else Ch = Character'Val (16#5C#) then
            if not Saw_Separator then
               Saw_Separator := True;
            end if;
            if Previous_Was_Separator then
               return True;
            end if;
            Previous_Was_Separator := True;
         else
            Previous_Was_Separator := False;
         end if;
      end loop;

      return False;
   end Contains_Empty_Relative_Path_Segment;

   function Has_Trailing_Path_Separator (Value : String) return Boolean is
   begin
      return Value'Length > 0
        and then (Value (Value'Last) = '/'
                  or else Value (Value'Last) = Character'Val (16#5C#));
   end Has_Trailing_Path_Separator;

   function Strip_Trailing_File_Tree_Path_Separators
     (Value : String) return String
   is
      Last : Integer := Value'Last;
   begin
      if Value'Length = 0 then
         return Value;
      end if;

      while Last > Value'First
        and then (Value (Last) = '/'
                  or else Value (Last) = Character'Val (16#5C#))
      loop
         Last := Last - 1;
      end loop;

      return Value (Value'First .. Last);
   end Strip_Trailing_File_Tree_Path_Separators;

   function Is_Absolute_Path (Path : String) return Boolean is
   begin
      return Path'Length > 0
        and then (Path (Path'First) = '/'
                  or else (Path'Length >= 3
                           and then Path (Path'First + 1) = ':'
                           and then (Path (Path'First + 2) = '/'
                                     or else Path (Path'First + 2) = Character'Val (16#5C#))));
   end Is_Absolute_Path;

   function Normalize_File_Tree_Input_Separators
     (Value : String) return String
   is
      Result : String (Value'Range);
   begin
      --  completeness: prompt paths are project-relative editor
      --  paths, not host-shell payloads.  Treat both supported prompt
      --  separators consistently before composing with the project root or a
      --  selected directory so an input such as "src\helper.adb" cannot be
      --  interpreted as a single root-level filename on hosts where backslash
      --  is not a directory separator.
      for I in Value'Range loop
         if Value (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         else
            Result (I) := Value (I);
         end if;
      end loop;
      return Result;
   end Normalize_File_Tree_Input_Separators;

   function Selected_File_Tree_Base_Directory
     (S     : Editor.State.State_Type;
      Found : out Boolean) return String
   is
      Node_Id : constant Editor.File_Tree.File_Tree_Node_Id :=
        Editor.Executor.Selected_File_Tree_Node (S, Found);
      Summary : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if not Found then
         --  No selected File Tree row is not the same as selecting the project
         --  root.  Callers may still use the root as the composition base for
         --  an explicit project-relative target such as "src/new.adb", but a
         --  bare name must report "No target directory selected" instead of
         --  silently creating at the root.
         if Editor.Project.Has_Project (S.Project) then
            return Editor.Project.Root_Path (S.Project);
         end if;
         return "";
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node_Id);
      if Summary.Kind = Editor.File_Tree.Directory_Node then
         return To_String (Summary.Absolute_Path);
      else
         --  completeness: a selected file is not a selected target
         --  directory.  Bare create input must therefore fail with
         --  "No target directory selected" rather than silently creating a
         --  sibling next to the selected file.  Explicit project-relative
         --  input remains valid because Build_File_Tree_Target_Path composes
         --  such paths from the project root and ignores this base value.
         Found := False;
         if Editor.Project.Has_Project (S.Project) then
            return Editor.Project.Root_Path (S.Project);
         else
            return "";
         end if;
      end if;
   end Selected_File_Tree_Base_Directory;

   function Build_File_Tree_Target_Path
     (S     : Editor.State.State_Type;
      Input : String;
      Base  : String) return String
   is
      Effective : constant String :=
        Normalize_File_Tree_Input_Separators
          (Strip_Trailing_File_Tree_Path_Separators (Input));
   begin
      if Effective'Length = 0 then
         return "";
      elsif Is_Absolute_Path (Effective) then
         return Effective;
      elsif Ada.Strings.Fixed.Index (Effective, "/") /= 0
        or else Ada.Strings.Fixed.Index (Effective, "\") /= 0
      then
         return Editor.Project.Absolute_Project_File_Path (S.Project, Effective);
      else
         return Ada.Directories.Compose (Base, Effective);
      end if;
   end Build_File_Tree_Target_Path;



   function Is_Windows_Drive_Qualified_File_Tree_Input
     (Value : String) return Boolean
   is
      First : constant Integer := Value'First;

      function Is_Ascii_Letter (Ch : Character) return Boolean is
      begin
         return (Ch >= 'A' and then Ch <= 'Z')
           or else (Ch >= 'a' and then Ch <= 'z');
      end Is_Ascii_Letter;
   begin
      --  completeness: prompt text is project-relative editor
      --  input, not host-shell path text.  Reject Windows drive-qualified
      --  strings before target composition on every host.  Drive-rooted
      --  forms such as "C:/tmp/file" are absolute.  Drive-relative forms
      --  such as "C:tmp/file" are not portable project-relative paths and
      --  must not become filenames containing a colon under the project root.
      return Value'Length >= 2
        and then Is_Ascii_Letter (Value (First))
        and then Value (First + 1) = ':';
   end Is_Windows_Drive_Qualified_File_Tree_Input;

   function Is_Windows_Drive_Absolute_File_Tree_Input
     (Value : String) return Boolean
   is
      First : constant Integer := Value'First;
   begin
      return Is_Windows_Drive_Qualified_File_Tree_Input (Value)
        and then Value'Length >= 3
        and then (Value (First + 2) = '/'
                  or else Value (First + 2) = Character'Val (16#5C#));
   end Is_Windows_Drive_Absolute_File_Tree_Input;

   function File_Tree_Input_Is_Absolute
     (Input : String) return Boolean
   is
      Raw       : constant String :=
        Strip_Trailing_File_Tree_Path_Separators (Input);
      Effective : constant String :=
        Normalize_File_Tree_Input_Separators (Raw);
   begin
      return Effective'Length > 0
        and then (Is_Absolute_Path (Effective)
                  or else Is_Windows_Drive_Qualified_File_Tree_Input (Raw)
                  or else Is_Windows_Drive_Absolute_File_Tree_Input (Input));
   end File_Tree_Input_Is_Absolute;

   function Absolute_File_Tree_Input_Message
     (S     : Editor.State.State_Type;
      Input : String) return String
   is
      pragma Unreferenced (S, Input);
   begin
      --  completeness: create-file/create-directory input is an
      --  editor project-relative path, not a raw filesystem payload.  Guided
      --  prompt validation is intentionally side-effect-free and cannot safely
      --  probe whether an absolute host path happens to sit inside the active
      --  project.  Keep direct Executor revalidation aligned with that input
      --  model: any absolute or drive-qualified create target is rejected as
      --  non project-relative before path composition or mutation.
      return "Target path must be project-relative";
   end Absolute_File_Tree_Input_Message;

   function File_Tree_Input_Has_Explicit_Directory
     (Input : String) return Boolean
   is
      Effective : constant String :=
        Normalize_File_Tree_Input_Separators
          (Strip_Trailing_File_Tree_Path_Separators (Input));
   begin
      --  A trailing separator by itself does not make a bare name an explicit
      --  project-relative path.  With no selected directory, "newdir/" must
      --  not silently target the project root; "src/newdir/" remains an
      --  explicit project-relative path.
      return Effective'Length > 0
        and then (Is_Absolute_Path (Effective)
                  or else Ada.Strings.Fixed.Index (Effective, "/") /= 0
                  or else Ada.Strings.Fixed.Index (Effective, "\") /= 0);
   end File_Tree_Input_Has_Explicit_Directory;

   function Project_Bounded_File_Tree_Target
     (S      : Editor.State.State_Type;
      Input  : String;
      Base   : String;
      Target : out Unbounded_String) return Boolean
   is
      Candidate : constant String := Build_File_Tree_Target_Path (S, Input, Base);
   begin
      Target := Null_Unbounded_String;
      if Input'Length = 0 or else Candidate'Length = 0 then
         return False;
      elsif Contains_Parent_Traversal (Input) then
         return False;
      elsif not Editor.Project.Is_Under_Project (S.Project, Candidate) then
         return False;
      else
         Target := To_Unbounded_String (Candidate);
         return True;
      end if;
   end Project_Bounded_File_Tree_Target;


   function File_Tree_Parent_Directory_Available
     (S      : Editor.State.State_Type;
      Target : String) return Boolean
   is
      Parent : constant String := Ada.Directories.Containing_Directory (Target);
      Canonical_Parent : Unbounded_String := Null_Unbounded_String;
   begin
      if Parent'Length = 0
        or else not Ada.Directories.Exists (Parent)
        or else Ada.Directories.Kind (Parent) /= Ada.Directories.Directory
      then
         return False;
      end if;

      --  completeness: target validation must be project-root
      --  bounded at the filesystem operation boundary, not only by the raw
      --  composed prompt string.  Re-check the existing parent directory
      --  through the filesystem's canonical name so create/rename cannot use
      --  an in-project path component that resolves to a directory outside
      --  the active project root.
      Canonical_Parent := To_Unbounded_String (Ada.Directories.Full_Name (Parent));
      return Editor.Project.Is_Under_Project
        (S.Project, To_String (Canonical_Parent));
   exception
      when others =>
         return False;
   end File_Tree_Parent_Directory_Available;

   function Delete_Confirmation_Accepted
     (Kind    : Editor.File_Tree.File_Tree_Node_Kind;
      Confirm : String) return Boolean
   is
      pragma Unreferenced (Kind);
      Token : constant String := Ada.Characters.Handling.To_Lower (Confirm);
   begin
      --  baseline policy deletes files and empty directories only.
      --  Recursive directory deletion is deliberately not exposed here, so the
      --  same explicit confirmation token is sufficient for both safe delete
      --  targets.  Directory emptiness is revalidated immediately before the
      --  filesystem mutation.
      return Token = "confirm";
   end Delete_Confirmation_Accepted;

   function File_Tree_Outcome_Kind_Label
     (Kind : Editor.File_Tree.File_Tree_Node_Kind) return String
   is
   begin
      case Kind is
         when Editor.File_Tree.Directory_Node =>
            return "Directory";
         when Editor.File_Tree.File_Node =>
            return "File";
      end case;
   end File_Tree_Outcome_Kind_Label;

   function Directory_Is_Empty (Path : String) return Boolean
   is
      function Pattern_Has_Entry (Pattern : String) return Boolean
      is
         Search         : Ada.Directories.Search_Type;
         Search_Started : Boolean := False;
      begin
         Ada.Directories.Start_Search
           (Search    => Search,
            Directory => Path,
            Pattern   => Pattern);
         Search_Started := True;

         while Ada.Directories.More_Entries (Search) loop
            declare
               Dir_Entry : Ada.Directories.Directory_Entry_Type;
            begin
               Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
               declare
                  Entry_Name : constant String :=
                    Ada.Directories.Simple_Name (Dir_Entry);
               begin
                  if Entry_Name /= "." and then Entry_Name /= ".." then
                     Ada.Directories.End_Search (Search);
                     return True;
                  end if;
               end;
            end;
         end loop;

         Ada.Directories.End_Search (Search);
         return False;
      exception
         when others =>
            if Search_Started then
               begin
                  Ada.Directories.End_Search (Search);
               exception
                  when others =>
                     null;
               end;
            end if;
            --  Treat unreadable or otherwise unscannable directories as not
            --  empty so the delete workflow remains fail-before-mutation.
            return True;
      end Pattern_Has_Entry;
   begin
      --  completeness: the empty-directory-only delete policy must
      --  not depend on host glob behaviour for dotfiles.  Some directory
      --  searches with "*" can omit hidden entries, so also scan ".*" and
      --  ignore only the synthetic current/parent entries.  A directory that
      --  contains only ".keep" or another hidden file is still non-empty and
      --  must be rejected before Delete_Directory is attempted.
      return not Pattern_Has_Entry ("*")
        and then not Pattern_Has_Entry (".*");
   end Directory_Is_Empty;

   function File_Tree_Source_Matches_Filesystem
     (Summary : Editor.File_Tree.File_Tree_Node_Summary) return Boolean
   is
      Path : constant String := To_String (Summary.Absolute_Path);
   begin
      if Path'Length = 0 or else not Ada.Directories.Exists (Path) then
         return False;
      end if;

      case Summary.Kind is
         when Editor.File_Tree.File_Node =>
            return Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File;
         when Editor.File_Tree.Directory_Node =>
            return Ada.Directories.Kind (Path) = Ada.Directories.Directory;
      end case;
   exception
      when others =>
         return False;
   end File_Tree_Source_Matches_Filesystem;

   function File_Tree_Source_Project_Bounded
     (S       : Editor.State.State_Type;
      Summary : Editor.File_Tree.File_Tree_Node_Summary) return Boolean
   is
      Path           : constant String := To_String (Summary.Absolute_Path);
      Canonical_Path : Unbounded_String := Null_Unbounded_String;
   begin
      if Path'Length = 0
        or else not Ada.Directories.Exists (Path)
        or else not Editor.Project.Is_Under_Project (S.Project, Path)
      then
         return False;
      end if;

      --  completeness: selected File Tree rows are transient
      --  snapshots and must be revalidated at the filesystem operation
      --  boundary.  Checking only the stored path string is insufficient when
      --  stale/corrupt tree state or resolved filesystem alternate paths point outside
      --  the active project.  Rename/delete therefore require the existing
      --  source object's canonical filesystem name to remain project-bounded
      --  before any mutation is attempted.
      Canonical_Path := To_Unbounded_String (Ada.Directories.Full_Name (Path));
      return Editor.Project.Is_Under_Project
        (S.Project, To_String (Canonical_Path));
   exception
      when others =>
         return False;
   end File_Tree_Source_Project_Bounded;

   procedure Select_File_Tree_Path
     (S    : in out Editor.State.State_Type;
      Path : String)
   is
      Found     : Boolean := False;
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Row_Found : Boolean := False;
      Row       : Natural := 0;
   begin
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, Path, Found);
      if Found and then Node /= Editor.File_Tree.No_File_Tree_Node then
         Editor.File_Tree.Expand_Ancestors (S.File_Tree, Node);
         Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
         if Row_Found then
            Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
            Editor.File_Tree_View.Ensure_Selected_Row_Visible
              (S.File_Tree_View,
               S.File_Tree,
               Editor.File_Tree.Visible_Row_Count (S.File_Tree));
         end if;
      end if;
   end Select_File_Tree_Path;

   function Selected_File_Tree_Node_Summary
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.File_Tree.File_Tree_Node_Summary
   is
      Node : constant Editor.File_Tree.File_Tree_Node_Id :=
        Editor.Executor.Selected_File_Tree_Node (S, Found);
   begin
      if not Found then
         return (others => <>);
      end if;
      return Editor.File_Tree.Node (S.File_Tree, Node);
   end Selected_File_Tree_Node_Summary;

   function Normalize_File_Tree_Path_For_Compare
     (Path : String) return String
   is
      Result : String (Path'Range);
      Last   : Integer := Path'Last;
   begin
      for I in Path'Range loop
         if Path (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         else
            Result (I) := Path (I);
         end if;
      end loop;

      while Last >= Result'First and then Result (Last) = '/' loop
         Last := Last - 1;
      end loop;

      if Last < Result'First then
         return "";
      else
         return Result (Result'First .. Last);
      end if;
   end Normalize_File_Tree_Path_For_Compare;

   function Same_Or_Descendant_File_Tree_Path
     (Path : String;
      Root : String) return Boolean
   is
      P : constant String := Normalize_File_Tree_Path_For_Compare (Path);
      R : constant String := Normalize_File_Tree_Path_For_Compare (Root);
   begin
      if P = R then
         return True;
      elsif R'Length = 0 or else P'Length <= R'Length then
         return False;
      else
         return P (P'First .. P'First + R'Length - 1) = R
           and then P (P'First + R'Length) = '/';
      end if;
   end Same_Or_Descendant_File_Tree_Path;

   function Open_Buffer_Blocks_File_Tree_Mutation
     (S          : Editor.State.State_Type;
      Source     : String;
      For_Delete : Boolean := False) return Boolean
   is
      pragma Unreferenced (S);
      pragma Unreferenced (For_Delete);
   begin
      --  Project-explorer rename/delete only block on dirty file-backed buffers.
      --  Clean open buffers are handled explicitly by the operation path: rename
      --  rebases their file paths, while delete closes them before removing the
      --  filesystem object.
      return Editor.Buffers.Global_Has_Dirty_File_Under_Path (Source);
   end Open_Buffer_Blocks_File_Tree_Mutation;

   function Rebased_File_Tree_Path
     (Path       : String;
      Old_Root   : String;
      New_Root   : String) return String
   is
      P : constant String := Normalize_File_Tree_Path_For_Compare (Path);
      R : constant String := Normalize_File_Tree_Path_For_Compare (Old_Root);
      Suffix_Start : Integer := P'First + R'Length;
   begin
      if P = R then
         return New_Root;
      elsif R'Length = 0 or else P'Length <= R'Length then
         return Path;
      elsif P (P'First .. P'First + R'Length - 1) /= R then
         return Path;
      elsif P (P'First + R'Length) /= '/' then
         return Path;
      else
         Suffix_Start := P'First + R'Length + 1;
         return Ada.Directories.Compose
           (New_Root, P (Suffix_Start .. P'Last));
      end if;
   end Rebased_File_Tree_Path;

   procedure Update_Active_Buffer_After_File_Tree_Rename
     (S        : in out Editor.State.State_Type;
      Old_Path : String;
      New_Path : String)
   is
      Updated : constant String :=
        Rebased_File_Tree_Path
          (To_String (S.File_Info.Path), Old_Path, New_Path);
   begin
      if S.File_Info.Has_Path
        and then Same_Or_Descendant_File_Tree_Path
          (To_String (S.File_Info.Path), Old_Path)
      then
         S.File_Info.Path := To_Unbounded_String (Updated);
         S.File_Info.Display_Name :=
           To_Unbounded_String
             (Editor.Files.Display_Name_For_Path (Updated));
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;
   end Update_Active_Buffer_After_File_Tree_Rename;

   function Refresh_File_Tree_Model_After_Operation
     (S : in out Editor.State.State_Type) return Boolean
   is
      Tree   : Editor.File_Tree.File_Tree_State;
      Result : Editor.File_Tree.File_Tree_Scan_Result;
      Selected_Found : Boolean := False;
      Selected_Node  : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Selected_Path  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.File_Tree.Clear (S.File_Tree);
         Editor.File_Tree_View.Clear_View (S.File_Tree_View);
         return False;
      end if;

      Selected_Node := Editor.File_Tree_View.Node_For_Row
        (S.File_Tree,
         Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View),
         Selected_Found);
      if Selected_Found then
         Selected_Path := Editor.File_Tree.Node
           (S.File_Tree, Selected_Node).Relative_Path;
      end if;

      Tree := Editor.File_Tree.Scan_Project (Editor.Project.Root_Path (S.Project));
      Result := Editor.File_Tree.Scan_Status (Tree);
      if Result.Status = Editor.File_Tree.File_Tree_Scan_Ok then
         Editor.File_Tree.Preserve_Expanded_Paths_From
           (Tree   => Tree,
            Source => S.File_Tree);
         S.File_Tree := Tree;
         Editor.Executor.Populate_Project_Known_Files_From_File_Tree (S);

         if Length (Selected_Path) > 0 then
            declare
               New_Found : Boolean := False;
               New_Node  : constant Editor.File_Tree.File_Tree_Node_Id :=
                 Editor.File_Tree.Find_By_Path
                   (S.File_Tree, To_String (Selected_Path), New_Found);
               Row_Found : Boolean := False;
               Row       : Natural := 0;
            begin
               if New_Found then
                  Row := Editor.File_Tree_View.Row_For_Node
                    (S.File_Tree, New_Node, Row_Found);
                  if Row_Found then
                     Editor.File_Tree_View.Set_Selected_Row_Index
                       (S.File_Tree_View, Row);
                  else
                     Editor.File_Tree_View.Set_Selected_Row_Index
                       (S.File_Tree_View, 0);
                  end if;
               else
                  Editor.File_Tree_View.Set_Selected_Row_Index
                    (S.File_Tree_View, 0);
               end if;
            end;
         end if;

         Editor.Executor.Validate_File_Tree_View (S);
         Editor.Project_Search.Mark_Stale (S.Project_Search);
         --  completeness: File Tree mutations invalidate Quick Open
         --  candidates even while the Quick Open overlay is visible.  Do not
         --  silently recompute here: the mutation path owns filesystem
         --  consistency, while Quick Open owns explicit candidate discovery.
         --  Keeping the open/query/filter UI state but clearing stale rows
         --  prevents accepting a pre-mutation candidate after create/rename/delete.
         Editor.Quick_Open.Mark_Stale (S.Quick_Open);
      else
         --  completeness: after a filesystem mutation, a failed
         --  refresh must not leave pre-mutation File Tree rows or known-file
         --  indexes behind.  Clear transient explorer state while preserving
         --  the active project itself; the command outcome still reports the
         --  mutation plus refresh failure to the user.
         Editor.File_Tree.Clear (S.File_Tree);
         Editor.File_Tree_View.Clear_View (S.File_Tree_View);
         Editor.Project.Clear_Known_Files (S.Project);
         Editor.Project_Search.Mark_Stale (S.Project_Search);
         Editor.Quick_Open.Mark_Stale (S.Quick_Open);
      end if;

      return Result.Status = Editor.File_Tree.File_Tree_Scan_Ok;
   end Refresh_File_Tree_Model_After_Operation;

   function File_Tree_Build_Config_Path (Path : String) return Boolean
   is
      Name  : constant String :=
        Ada.Characters.Handling.To_Lower (Ada.Directories.Simple_Name (Path));
      Last4 : constant Natural := 4;
   begin
      if Name = "alire.toml" then
         return True;
      elsif Name'Length < Last4 then
         return False;
      else
         return Name (Name'Last - 3 .. Name'Last) = ".gpr";
      end if;
   exception
      when others =>
         return False;
   end File_Tree_Build_Config_Path;

   function File_Tree_Mutation_Affects_Path
     (Old_Path : String;
      New_Path : String;
      Path     : String) return Boolean
   is
   begin
      if Path'Length = 0 then
         return False;
      elsif Old_Path'Length > 0
        and then Same_Or_Descendant_File_Tree_Path (Path, Old_Path)
      then
         return True;
      elsif New_Path'Length > 0
        and then Same_Or_Descendant_File_Tree_Path (Path, New_Path)
      then
         return True;
      else
         return False;
      end if;
   end File_Tree_Mutation_Affects_Path;

   function File_Tree_Mutation_Affects_Known_Build_Config
     (S        : Editor.State.State_Type;
      Old_Path : String;
      New_Path : String) return Boolean
   is
      Count : constant Natural := Editor.File_Tree.File_Node_Count (S.File_Tree);
   begin
      --  completeness: build candidate staleness is not limited to
      --  mutations whose direct target is named alire.toml or *.gpr.  A
      --  directory rename/delete can move or remove build configuration files
      --  below the selected directory.  Use the pre-refresh File Tree snapshot
      --  as a side-effect-free ownership boundary to detect affected known
      --  build config files before the mutation refresh replaces the tree.
      for Index in 1 .. Count loop
         declare
            Node : constant Editor.File_Tree.File_Tree_Node_Summary :=
              Editor.File_Tree.File_Node_At (S.File_Tree, Index);
            Path : constant String := To_String (Node.Absolute_Path);
         begin
            if File_Tree_Build_Config_Path (Path)
              and then File_Tree_Mutation_Affects_Path (Old_Path, New_Path, Path)
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end File_Tree_Mutation_Affects_Known_Build_Config;

   function File_Tree_Mutation_Affects_Selected_Build_Candidate
     (S        : Editor.State.State_Type;
      Old_Path : String;
      New_Path : String) return Boolean
   is
      Selected_Id : constant String :=
        To_String (S.Build_UI.Selected_Build_Candidate_Id);
   begin
      if Selected_Id'Length = 0 then
         return False;
      end if;

      for Candidate of S.Build_UI.Build_Candidates loop
         if To_String (Candidate.Candidate_Id) = Selected_Id then
            declare
               Source : constant String :=
                 To_String (Candidate.Source_Path_If_Represented);
               Old_Relative : constant String :=
                 (if Old_Path'Length > 0
                    and then Editor.Project.Has_Project (S.Project)
                    and then Editor.Project.Is_Under_Project (S.Project, Old_Path)
                  then Editor.Project.Relative_Path (S.Project, Old_Path)
                  else "");
               New_Relative : constant String :=
                 (if New_Path'Length > 0
                    and then Editor.Project.Has_Project (S.Project)
                    and then Editor.Project.Is_Under_Project (S.Project, New_Path)
                  then Editor.Project.Relative_Path (S.Project, New_Path)
                  else "");
            begin
               --  completeness: selected build-candidate staleness
               --  must follow the candidate's represented source whether that
               --  source is stored as an absolute filesystem path or as a
               --  project-relative label.  File Tree mutation execution works
               --  with absolute paths, but Build UI candidate records may be
               --  projected through relative source labels; either spelling
               --  must invalidate consent and pending request state.
               return File_Tree_Mutation_Affects_Path
                   (Old_Path, New_Path, Source)
                 or else File_Tree_Mutation_Affects_Path
                   (Old_Relative, New_Relative, Source);
            end;
         end if;
      end loop;

      return False;
   end File_Tree_Mutation_Affects_Selected_Build_Candidate;

   procedure Invalidate_Project_State_After_File_Tree_Mutation
     (S        : in out Editor.State.State_Type;
      Old_Path : String;
      New_Path : String := "")
   is
      Affects_Active_File : constant Boolean :=
        S.File_Info.Has_Path
        and then File_Tree_Mutation_Affects_Path
          (Old_Path, New_Path, To_String (S.File_Info.Path));
      Affects_Build_Config : constant Boolean :=
        (Old_Path'Length > 0 and then File_Tree_Build_Config_Path (Old_Path))
        or else (New_Path'Length > 0 and then File_Tree_Build_Config_Path (New_Path))
        or else File_Tree_Mutation_Affects_Known_Build_Config
          (S, Old_Path, New_Path);
      Has_Selected_Build_Candidate : constant Boolean :=
        To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length > 0;
      Affects_Selected_Build_Candidate : constant Boolean :=
        File_Tree_Mutation_Affects_Selected_Build_Candidate
          (S, Old_Path, New_Path);
   begin
      --  filesystem mutations make project-derived surfaces stale
      --  through the owning runtime state, never through render, availability,
      --  Command Palette rows, keybinding payloads, or persisted operation data.
      Editor.Project_Search.Mark_Stale_Unconditionally (S.Project_Search);
      Editor.Project_Search.Mark_Replace_Preview_Stale (S.Project_Search);
      Editor.Quick_Open.Mark_Stale (S.Quick_Open);

      --  pass 182: File Tree create/rename/delete changes the set
      --  of project source paths independently of active-buffer commands.
      --  Invalidate exact and subtree paths so indexed cross-file Outline and
      --  semantic navigation never points at removed, moved, or rebased Ada
      --  source files.  New paths are also dropped because clean open buffers
      --  may have been rebased to that target and must be re-indexed with the
      --  new lifecycle stamps before navigation can use them.
      if Old_Path'Length > 0 then
         Editor.Ada_Project_Index.Invalidate_Path_Subtree
           (S.Language_Index, Old_Path);
         Editor.Ada_Language_Service.Invalidate_Path_Subtree
           (S.Language_Service, Old_Path);
      end if;
      if New_Path'Length > 0 then
         Editor.Ada_Project_Index.Invalidate_Path_Subtree
           (S.Language_Index, New_Path);
         Editor.Ada_Language_Service.Invalidate_Path_Subtree
           (S.Language_Service, New_Path);
      end if;
      if Affects_Active_File and then S.Active_Buffer_Token /= 0 then
         Editor.Ada_Project_Index.Invalidate_Buffer
           (S.Language_Index, S.Active_Buffer_Token);
         Editor.Ada_Language_Service.Invalidate_Buffer
           (S.Language_Service, S.Active_Buffer_Token);
         Editor.Syntax_Semantics.Clear (S.Syntax_Symbols);
         Editor.Ada_Language_Model.Clear (S.Syntax_Analysis);
         S.Syntax_Symbols_Revision := Natural'Last;
         S.Syntax_Symbols_Buffer_Token := 0;
      end if;

      if Affects_Active_File then
         Editor.Outline.Clear (S.Outline);
         S.Outline_Cursor_Key_Valid := False;
         Editor.Diagnostics.Clear (S.Diagnostics);
         Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      end if;

      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
        (S.Feature_Diagnostics, Old_Path, New_Path);

      if Editor.Project.Has_Project (S.Project) then
         declare
            Old_Relative : constant String :=
              (if Old_Path'Length > 0
                 and then Editor.Project.Is_Under_Project (S.Project, Old_Path)
               then Editor.Project.Relative_Path (S.Project, Old_Path)
               else "");
            New_Relative : constant String :=
              (if New_Path'Length > 0
                 and then Editor.Project.Is_Under_Project (S.Project, New_Path)
               then Editor.Project.Relative_Path (S.Project, New_Path)
               else "");
         begin
            --  completeness: diagnostics rows often store
            --  project-relative source labels (for example "src/main.adb")
            --  while File Tree execution validates and mutates absolute
            --  filesystem paths.  Mark both absolute and project-relative
            --  spellings stale so directory/file rename/delete cannot leave
            --  stale diagnostics live merely because the source label used
            --  the UI-relative form.
            Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
              (S.Feature_Diagnostics, Old_Relative, New_Relative);
         end;
      end if;

      if Affects_Build_Config then
         --  completeness: .gpr/alire.toml creation, rename, or
         --  deletion invalidates the discovered build-candidate list itself,
         --  not only the currently selected candidate.  Do not refresh from
         --  this mutation path and do not preserve a runnable request; leave
         --  candidate discovery for the owning Build UI command.
         S.Build_UI.Build_Candidates :=
           Editor.Build_Candidates.Build_Candidate_Vectors.Empty_Vector;
         S.Build_UI.Candidate_Refresh_Status :=
           Editor.Build_UI.Build_Candidate_Refresh_Not_Requested;
         S.Build_UI.Candidate_Refresh_Message := To_Unbounded_String
           ("Build candidates are stale after File Tree mutation");
         S.Build_UI.Candidate_Discovery_Message := To_Unbounded_String
           ("Build candidates are stale after File Tree mutation");
         S.Build_UI.Last_Refresh_Candidate_Count := 0;
         S.Build_UI.Selected_Candidate_Preserved_On_Refresh := False;
         S.Build_UI.Selected_Candidate_Cleared_On_Refresh := False;
      end if;

      if (Affects_Build_Config and then Has_Selected_Build_Candidate)
        or else Affects_Selected_Build_Candidate
      then
         S.Build_UI.Selected_Candidate_Stale := True;
         S.Build_UI.Consent_Acknowledged := False;
         S.Build_UI.Pending_Public_Build_Request := False;
         S.Build_UI.Candidate_Selection_Message := To_Unbounded_String
           ("Selected build candidate is stale after File Tree mutation");
         S.Build_UI.Validation_Status :=
           Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale;
         S.Build_UI.Validation_Message := To_Unbounded_String
           (Editor.Build_UI.Validation_Message
              (Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale));
      end if;
   end Invalidate_Project_State_After_File_Tree_Mutation;

   procedure Execute_File_Tree_Create_File
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Base_Found : Boolean := False;
      Base       : constant String := Selected_File_Tree_Base_Directory (S, Base_Found);
      Input      : constant String := File_Tree_Input_Text (Cmd);
      Target     : Unbounded_String := Null_Unbounded_String;
      File       : Ada.Text_IO.File_Type;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif Input'Length = 0 then
         --  completeness: execution-time validation must mirror the
         --  guided prompt validation for empty File Tree mutation names.
         --  Even if a command reaches the Executor without prompt-local text,
         --  the operation should report the operation-model name guidance
         --  rather than a generic malformed-name diagnostic.
         Editor.Executor.Report_Error (S, "Enter a name.");
         return;
      elsif Contains_Control_File_Tree_Input_Character (Input) then
         --  completeness pass 33: reject raw control characters
         --  before host-path classification.  A prompt such as "/tmp/\n"
         --  is malformed editor input, not merely an outside-project path,
         --  and must receive the canonical invalid file-name diagnostic.
         Editor.Executor.Report_Error (S, "Invalid file name");
         return;
      elsif Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        and then not Is_Windows_Drive_Absolute_File_Tree_Input (Input)
      then
         --  completeness: prompt validation rejects drive-relative
         --  text such as "C:tmp" as malformed File Tree input.  Execution-time
         --  validation must produce the same class of failure instead of
         --  treating it as a reusable host-path payload or a boundary-only
         --  error.  Drive-rooted forms continue through the absolute-path
         --  branch and report the project-boundary violation.
         Editor.Executor.Report_Error (S, "Invalid file name");
         return;
      elsif File_Tree_Input_Is_Absolute (Input) then
         Editor.Executor.Report_Error (S, Absolute_File_Tree_Input_Message (S, Input));
         return;
      elsif Contains_Parent_Traversal (Input)
        or else Has_Trailing_Path_Separator (Input)
        or else Contains_Current_Directory_Segment (Input)
        or else Contains_Empty_Relative_Path_Segment (Input)
      then
         --  completeness: prompt validation reports traversal,
         --  current-directory segments, empty segments, and trailing
         --  separators as malformed File Tree input.  Execution-time
         --  validation must reject the same syntax class before the generic
         --  project-boundary fallback so confirm-time diagnostics remain
         --  aligned with the guided prompt.
         Editor.Executor.Report_Error (S, "Invalid file name");
         return;
      end if;

      declare
         Selected_Found   : Boolean := False;
         Selected_Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
           Selected_File_Tree_Node_Summary (S, Selected_Found);
      begin
         if Base_Found
           and then Selected_Found
           and then Selected_Summary.Kind = Editor.File_Tree.Directory_Node
           and then not File_Tree_Input_Has_Explicit_Directory (Input)
         then
            --  completeness: create operations using the selected
            --  directory as their base must revalidate that selected snapshot
            --  before target composition reaches the filesystem.  A stale
            --  directory row must not degrade into a generic missing-parent
            --  diagnostic or create relative to a replacement object.
            if not Ada.Directories.Exists
              (To_String (Selected_Summary.Absolute_Path))
              or else not File_Tree_Source_Matches_Filesystem
                (Selected_Summary)
            then
               Editor.Executor.Report_Warning (S, Editor.Commands.Reason_File_Tree_Item_Stale);
               return;
            elsif not File_Tree_Source_Project_Bounded (S, Selected_Summary) then
               Editor.Executor.Report_Error (S, "Target path is outside the project");
               return;
            end if;
         end if;
      end;

      if not Base_Found
        and then not File_Tree_Input_Has_Explicit_Directory (Input)
      then
         Editor.Executor.Report_Warning (S, "No target directory selected");
         return;
      elsif not Project_Bounded_File_Tree_Target (S, Input, Base, Target) then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Report_Error (S, "Open buffer already represents target path");
         return;
      elsif not File_Tree_Parent_Directory_Available (S, To_String (Target)) then
         Editor.Executor.Report_Error (S, "Parent directory unavailable");
         return;
      end if;

      begin
         Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, To_String (Target));
         Ada.Text_IO.Close (File);
         Invalidate_Project_State_After_File_Tree_Mutation
           (S, To_String (Target));
         if Refresh_File_Tree_Model_After_Operation (S) then
            Select_File_Tree_Path (S, To_String (Target));
            Editor.Executor.Report_Success (S, "File created.");
         else
            Editor.Executor.Report_Warning (S, "File created; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error | Ada.IO_Exceptions.Name_Error =>
            Editor.Executor.Report_Error (S, "Invalid file name");
         when Ada.IO_Exceptions.Use_Error =>
            Editor.Executor.Report_Error (S, "Permission denied");
         when others =>
            begin
               if Ada.Text_IO.Is_Open (File) then
                  Ada.Text_IO.Close (File);
               end if;
            exception
               when others => null;
            end;
            Editor.Executor.Report_Error (S, "Could not create file");
      end;
   end Execute_File_Tree_Create_File;

   procedure Execute_File_Tree_Create_Directory
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Base_Found : Boolean := False;
      Base       : constant String := Selected_File_Tree_Base_Directory (S, Base_Found);
      Input      : constant String := File_Tree_Input_Text (Cmd);
      Target     : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif Input'Length = 0 then
         --  completeness: keep empty create-directory execution
         --  aligned with the prompt-owned validation surface.
         Editor.Executor.Report_Error (S, "Enter a name.");
         return;
      elsif Contains_Control_File_Tree_Input_Character (Input) then
         --  completeness pass 33: reject raw control characters
         --  before host-path classification.  Malformed prompt text should
         --  not be reported as an absolute/outside-project target.
         Editor.Executor.Report_Error (S, "Invalid directory name");
         return;
      elsif Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        and then not Is_Windows_Drive_Absolute_File_Tree_Input (Input)
      then
         --  completeness: keep guided prompt validation and
         --  execution-time validation aligned for drive-relative text.  It is
         --  malformed File Tree input, not a project-relative directory target
         --  and not a persisted filesystem payload.
         Editor.Executor.Report_Error (S, "Invalid directory name");
         return;
      elsif File_Tree_Input_Is_Absolute (Input) then
         Editor.Executor.Report_Error (S, Absolute_File_Tree_Input_Message (S, Input));
         return;
      elsif Contains_Parent_Traversal (Input)
        or else Has_Trailing_Path_Separator (Input)
        or else Contains_Current_Directory_Segment (Input)
        or else Contains_Empty_Relative_Path_Segment (Input)
      then
         --  completeness: prompt validation and execution-time
         --  validation must agree.  Directory creation accepts explicit
         --  project-relative paths such as "src/generated", but traversal,
         --  current-directory segments, empty segments, and trailing
         --  separators are malformed input rather than shell-normalized
         --  directory paths.
         Editor.Executor.Report_Error (S, "Invalid directory name");
         return;
      end if;

      declare
         Selected_Found   : Boolean := False;
         Selected_Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
           Selected_File_Tree_Node_Summary (S, Selected_Found);
      begin
         if Base_Found
           and then Selected_Found
           and then Selected_Summary.Kind = Editor.File_Tree.Directory_Node
           and then not File_Tree_Input_Has_Explicit_Directory (Input)
         then
            --  completeness: create operations using the selected
            --  directory as their base must revalidate that selected snapshot
            --  before target composition reaches the filesystem.  A stale
            --  directory row must not degrade into a generic missing-parent
            --  diagnostic or create relative to a replacement object.
            if not Ada.Directories.Exists
              (To_String (Selected_Summary.Absolute_Path))
              or else not File_Tree_Source_Matches_Filesystem
                (Selected_Summary)
            then
               Editor.Executor.Report_Warning (S, Editor.Commands.Reason_File_Tree_Item_Stale);
               return;
            elsif not File_Tree_Source_Project_Bounded (S, Selected_Summary) then
               Editor.Executor.Report_Error (S, "Target path is outside the project");
               return;
            end if;
         end if;
      end;

      if not Base_Found
        and then not File_Tree_Input_Has_Explicit_Directory (Input)
      then
         Editor.Executor.Report_Warning (S, "No target directory selected");
         return;
      elsif not Project_Bounded_File_Tree_Target (S, Input, Base, Target) then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Report_Error (S, "Open buffer already represents target path");
         return;
      elsif not File_Tree_Parent_Directory_Available (S, To_String (Target)) then
         Editor.Executor.Report_Error (S, "Parent directory unavailable");
         return;
      end if;

      begin
         Ada.Directories.Create_Directory (To_String (Target));
         Invalidate_Project_State_After_File_Tree_Mutation
           (S, To_String (Target));
         if Refresh_File_Tree_Model_After_Operation (S) then
            Select_File_Tree_Path (S, To_String (Target));
            Editor.Executor.Report_Success (S, "Directory created.");
         else
            Editor.Executor.Report_Warning (S, "Directory created; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Editor.Executor.Report_Error (S, "Invalid directory name");
         when Ada.Directories.Use_Error =>
            Editor.Executor.Report_Error (S, "Permission denied");
         when others =>
            Editor.Executor.Report_Error (S, "Could not create directory");
      end;
   end Execute_File_Tree_Create_Directory;

   procedure Execute_File_Tree_Rename_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Found   : Boolean := False;
      Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
        Selected_File_Tree_Node_Summary (S, Found);
      Input   : constant String := File_Tree_Input_Text (Cmd);
      Target  : Unbounded_String := Null_Unbounded_String;
      Parent_Path : Unbounded_String := Null_Unbounded_String;
      Active_Buffer_Was_Renamed : Boolean := False;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Report_Warning (S, "No File Tree node selected");
         return;
      elsif not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif Summary.Parent = Editor.File_Tree.No_File_Tree_Node then
         --  The project-root row is a real directory node, but it is not a
         --  valid rename source.  Report the project-root constraint before
         --  validating prompt text so root rename attempts cannot be confused
         --  with malformed user input.
         Editor.Executor.Report_Warning (S, "Cannot rename project root");
         return;
      elsif Input'Length = 0 then
         --  completeness: rename uses the same empty-name
         --  validation language as the guided prompt.
         Editor.Executor.Report_Error (S, "Enter a name.");
         return;
      elsif Ada.Strings.Fixed.Index (Input, "/") /= 0
        or else Ada.Strings.Fixed.Index (Input, "\") /= 0
      then
         --  completeness: rename is a leaf-name workflow even at
         --  direct Executor revalidation time.  Guided prompt validation
         --  already explains path fragments with the leaf-name-only policy;
         --  keep execution aligned so Command Palette/keybinding routes that
         --  reach the Executor without prompt-local blocking do not degrade to
         --  a generic invalid-target message.
         Editor.Executor.Report_Error (S, "Rename expects a single new name");
         return;
      elsif Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        or else Contains_Control_File_Tree_Input_Character (Input)
        or else Contains_Parent_Traversal (Input)
        or else Contains_Current_Directory_Segment (Input)
      then
         --  completeness: rename-selected accepts a new leaf name,
         --  not a host-path fragment.  Reject Windows drive-qualified text on
         --  every host so prompts such as "C:tmp" or "C:/tmp" cannot be
         --  interpreted as a colon-containing filename or as an accidental
         --  absolute path variant.
         Editor.Executor.Report_Error (S, "Invalid rename target");
         return;
      elsif not Ada.Directories.Exists (To_String (Summary.Absolute_Path)) then
         Editor.Executor.Report_Warning (S, "Target no longer exists.");
         return;
      elsif not File_Tree_Source_Project_Bounded (S, Summary) then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif not File_Tree_Source_Matches_Filesystem (Summary) then
         Editor.Executor.Report_Warning (S, Editor.Commands.Reason_File_Tree_Item_Stale);
         return;
      elsif Open_Buffer_Blocks_File_Tree_Mutation
        (S, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Report_Info (S, "Dirty buffer preserved.");
         return;
      end if;

      Parent_Path := Editor.File_Tree.Node (S.File_Tree, Summary.Parent).Absolute_Path;
      Target := To_Unbounded_String
        (Ada.Directories.Compose (To_String (Parent_Path), Input));
      Active_Buffer_Was_Renamed :=
        S.File_Info.Has_Path
        and then Same_Or_Descendant_File_Tree_Path
          (To_String (S.File_Info.Path), To_String (Summary.Absolute_Path));

      if not Editor.Project.Is_Under_Project (S.Project, To_String (Target)) then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif Same_Or_Descendant_File_Tree_Path
        (To_String (Summary.Absolute_Path), To_String (Target))
        and then Same_Or_Descendant_File_Tree_Path
          (To_String (Target), To_String (Summary.Absolute_Path))
      then
         --  completeness: a rename to the same filesystem path is
         --  neither a conflict nor a successful mutation.  Reject it
         --  explicitly before the generic target-exists check so the workflow
         --  does not report a misleading collision for an unchanged name.
         Editor.Executor.Report_Warning (S, "Rename target is unchanged");
         return;
      elsif not File_Tree_Parent_Directory_Available (S, To_String (Target)) then
         Editor.Executor.Report_Error (S, "Parent directory unavailable");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Report_Error (S, "Open buffer already represents target path");
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
               Editor.Executor.Load_Global_Active_Preserving_Language_Index (S);
               if Active_Buffer_Was_Renamed then
                  --  pass 35: renaming an already-open clean file
                  --  is a navigation workflow as well as a File Tree mutation.
                  --  Once the buffer backing path has been rebased, return
                  --  focus to the renamed buffer so the daily loop continues
                  --  at the document the user was working in.  Pure File Tree
                  --  renames with no affected active buffer keep File Tree
                  --  focus below.
                  Editor.Focus_Management.Restore_Focus_To_Editor (S);
               end if;
            else
               Update_Active_Buffer_After_File_Tree_Rename
                 (S, To_String (Summary.Absolute_Path), To_String (Target));
            end if;
         end;

         Invalidate_Project_State_After_File_Tree_Mutation
           (S, To_String (Summary.Absolute_Path), To_String (Target));

         if Refresh_File_Tree_Model_After_Operation (S) then
            Select_File_Tree_Path (S, To_String (Target));
            Editor.Executor.Report_Success
              (S, File_Tree_Outcome_Kind_Label (Summary.Kind) & " renamed.");
         else
            Editor.Executor.Report_Warning
              (S, File_Tree_Outcome_Kind_Label (Summary.Kind)
                    & " renamed; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Editor.Executor.Report_Error (S, "Invalid rename target");
         when Ada.Directories.Use_Error =>
            Editor.Executor.Report_Error (S, "Permission denied");
         when others =>
            Editor.Executor.Report_Error (S, "Could not rename File Tree item");
      end;
   end Execute_File_Tree_Rename_Selected;

   procedure Execute_File_Tree_Delete_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Found   : Boolean := False;
      Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
        Selected_File_Tree_Node_Summary (S, Found);
      Confirm : constant String := File_Tree_Input_Text (Cmd);
      Parent_After_Delete : Unbounded_String := Null_Unbounded_String;
      Active_Buffer_Was_Deleted : Boolean := False;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Report_Warning (S, "No File Tree node selected");
         return;
      elsif Summary.Parent = Editor.File_Tree.No_File_Tree_Node then
         Editor.Executor.Report_Warning (S, "Cannot delete project root");
         return;
      elsif not Editor.Project.Is_Under_Project (S.Project, To_String (Summary.Absolute_Path)) then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif not Ada.Directories.Exists (To_String (Summary.Absolute_Path)) then
         Editor.Executor.Report_Warning (S, "Target no longer exists.");
         return;
      elsif not File_Tree_Source_Project_Bounded (S, Summary) then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif not File_Tree_Source_Matches_Filesystem (Summary) then
         Editor.Executor.Report_Warning (S, Editor.Commands.Reason_File_Tree_Item_Stale);
         return;
      elsif not Delete_Confirmation_Accepted (Summary.Kind, Confirm) then
         --  completeness: delete remains confirmation-first at the
         --  filesystem mutation boundary.  Dirty/open-buffer impact is shown
         --  by the prompt before confirmation, but an unconfirmed Executor
         --  route must not proceed into impact-specific validation or expose a
         --  delete-blocked outcome as if confirmation had already happened.
         Editor.Executor.Report_Info (S, "Delete cancelled.");
         return;
      elsif Open_Buffer_Blocks_File_Tree_Mutation
        (S, To_String (Summary.Absolute_Path), For_Delete => True)
      then
         Editor.Executor.Report_Info (S, "Dirty buffer preserved.");
         return;
      elsif Summary.Kind = Editor.File_Tree.Directory_Node
        and then not Directory_Is_Empty (To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Report_Warning (S, "Directory is not empty");
         return;
      end if;

      if Summary.Parent /= Editor.File_Tree.No_File_Tree_Node then
         Parent_After_Delete :=
           Editor.File_Tree.Node (S.File_Tree, Summary.Parent).Absolute_Path;
      end if;

      Active_Buffer_Was_Deleted :=
        S.File_Info.Has_Path
        and then Same_Or_Descendant_File_Tree_Path
          (To_String (S.File_Info.Path), To_String (Summary.Absolute_Path));

      begin
         --  Mutate the filesystem before closing clean open buffers.  If the
         --  host delete fails because of permissions, races, or read-only
         --  state, the editor must not have already dropped buffer registry
         --  entries.  Dirty buffers are still blocked by the preflight guard
         --  above; clean buffers are closed only after successful removal.
         if Summary.Kind = Editor.File_Tree.File_Node then
            Ada.Directories.Delete_File (To_String (Summary.Absolute_Path));
         else
            Ada.Directories.Delete_Directory (To_String (Summary.Absolute_Path));
         end if;

         Invalidate_Project_State_After_File_Tree_Mutation
           (S, To_String (Summary.Absolute_Path));

         declare
            Closed_Count : Natural := 0;
         begin
            Editor.Buffers.Global_Close_Clean_File_Paths_Under
              (Path         => To_String (Summary.Absolute_Path),
               Closed_Count => Closed_Count);
            if Closed_Count > 0 then
               if Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer then
                  --  pass 34: deleting the only clean open buffer
                  --  through the File Tree must not leave the editor state
                  --  pointing at the removed backing path.  Move the editor to
                  --  the same empty-buffer state users see after closing the
                  --  final clean buffer, while keeping the File Tree workflow
                  --  focused for the next selection.
                  S.Active_Buffer_Token := 0;
                  Editor.State.Load_Text (S, "");
                  Editor.Focus_Management.Set_Focus_Owner
                    (S, Editor.Focus_Management.Focus_File_Tree);
               else
                  Editor.Executor.Load_Global_Active_Preserving_Language_Index (S);
                  if Active_Buffer_Was_Deleted then
                     --  pass 36: deleting the active clean buffer
                     --  from the File Tree is also a buffer-switch workflow
                     --  when another buffer remains.  Continue the daily loop
                     --  in the replacement editor buffer instead of leaving
                     --  focus on a File Tree row for a file that no longer
                     --  backs the active editor state.  Deleting a different
                     --  open clean buffer still keeps File Tree focus.
                     Editor.Focus_Management.Restore_Focus_To_Editor (S);
                  end if;
               end if;
            end if;
         end;

         if Refresh_File_Tree_Model_After_Operation (S) then
            if Length (Parent_After_Delete) > 0
              and then Ada.Directories.Exists (To_String (Parent_After_Delete))
            then
               Select_File_Tree_Path (S, To_String (Parent_After_Delete));
            end if;
            Editor.Executor.Report_Success
              (S, File_Tree_Outcome_Kind_Label (Summary.Kind) & " deleted.");
         else
            Editor.Executor.Report_Warning
              (S, File_Tree_Outcome_Kind_Label (Summary.Kind)
                    & " deleted; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Editor.Executor.Report_Error (S, "Target no longer exists.");
         when Ada.Directories.Use_Error =>
            Editor.Executor.Report_Error (S, "Permission denied");
         when others =>
            Editor.Executor.Report_Error (S, "Could not delete File Tree item");
      end;
   end Execute_File_Tree_Delete_Selected;

   procedure Execute_File_Tree_Expand_Selected
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Node  : constant Editor.File_Tree.File_Tree_Node_Id := Editor.Executor.Selected_File_Tree_Node (S, Found);
      Summary : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Report_Warning (S, "No File Tree node selected");
         return;
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);
      if not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif Summary.Kind /= Editor.File_Tree.Directory_Node then
         Editor.Executor.Report_Warning (S, "Selected row is not a directory");
         return;
      end if;

      if Summary.Is_Expanded then
         Editor.Executor.Report_Info (S, "File Tree directory already expanded");
      else
         Editor.File_Tree.Set_Expanded (S.File_Tree, Node, True);
         Editor.Executor.Select_File_Tree_Node (S, Node);
         Editor.Executor.Report_Success (S, "File Tree directory expanded");
      end if;

      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Expand_Selected;

   procedure Execute_File_Tree_Collapse_Selected
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Node  : constant Editor.File_Tree.File_Tree_Node_Id := Editor.Executor.Selected_File_Tree_Node (S, Found);
      Summary : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Report_Warning (S, "No File Tree node selected");
         return;
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);
      if not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif Summary.Kind /= Editor.File_Tree.Directory_Node then
         Editor.Executor.Report_Warning (S, "Selected row is not a directory");
         return;
      elsif not Summary.Is_Expanded then
         Editor.Executor.Report_Info (S, "File Tree directory already collapsed");
         return;
      end if;

      Editor.File_Tree.Set_Expanded (S.File_Tree, Node, False);
      Editor.Executor.Select_File_Tree_Node (S, Node);
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Executor.Report_Success (S, "File Tree directory collapsed");
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Collapse_Selected;

   procedure Execute_File_Tree_Toggle_Selected
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Node  : constant Editor.File_Tree.File_Tree_Node_Id := Editor.Executor.Selected_File_Tree_Node (S, Found);
      Summary : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Report_Warning (S, "No File Tree node selected");
         return;
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);
      if not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Report_Error (S, "Target path is outside the project");
         return;
      elsif Summary.Kind /= Editor.File_Tree.Directory_Node then
         Editor.Executor.Report_Warning (S, "Selected row is not a directory");
         return;
      end if;

      Editor.File_Tree.Toggle_Expanded (S.File_Tree, Node);
      Editor.Executor.Select_File_Tree_Node (S, Node);
      Editor.Executor.Validate_File_Tree_View (S);
      if Summary.Is_Expanded then
         Editor.Executor.Report_Success (S, "File Tree directory collapsed");
      else
         Editor.Executor.Report_Success (S, "File Tree directory expanded");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Toggle_Selected;



   procedure Execute_File_Tree_Collapse_All
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Report_Warning (S, "No project open");
         return;
      elsif Editor.File_Tree.Is_Empty (S.File_Tree) then
         Editor.Executor.Report_Warning (S, "File Tree unavailable");
         return;
      end if;

      Editor.File_Tree.Collapse_All (S.File_Tree);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Executor.Report_Success (S, "File Tree collapsed");
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Collapse_All;

   procedure Execute_File_Tree_Expand_To_Active_File
     (S : in out Editor.State.State_Type)
   is
   begin
      Execute_Reveal_Active_File_In_Tree (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Expand_To_Active_File;

   function Execute_File_Tree_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);
   begin
      case Id is
         when Command_Refresh_Project_Files =>
            Execute_Refresh_Project_Files (S);

         when Command_Project_Files_Summary =>
            Execute_Project_Files_Summary (S);

         when Command_Reveal_Active_File_In_Tree =>
            Execute_Reveal_Active_File_In_Tree (S);
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
            Execute_Refresh_File_Tree (S);

         when Refresh_Project_Files =>
            Execute_Refresh_Project_Files (S);

         when Project_Files_Summary =>
            Execute_Project_Files_Summary (S);

         when Reveal_Active_File_In_Tree =>
            Execute_Reveal_Active_File_In_Tree (S);

         when Focus_File_Tree =>
            Execute_Focus_File_Tree (S);

         when File_Tree_Move_Up =>
            Execute_File_Tree_Move_Up (S);

         when File_Tree_Move_Down =>
            Execute_File_Tree_Move_Down (S);

         when File_Tree_Page_Up =>
            Execute_File_Tree_Page_Up (S);

         when File_Tree_Page_Down =>
            Execute_File_Tree_Page_Down (S);

         when File_Tree_Open_Selected =>
            Execute_File_Tree_Open_Selected (S);

         when File_Tree_Create_File =>
            Execute_File_Tree_Create_File (S, Cmd);

         when File_Tree_Create_Directory =>
            Execute_File_Tree_Create_Directory (S, Cmd);

         when File_Tree_Rename_Selected =>
            Execute_File_Tree_Rename_Selected (S, Cmd);

         when File_Tree_Delete_Selected =>
            Execute_File_Tree_Delete_Selected (S, Cmd);

         when File_Tree_Expand_Selected =>
            Execute_File_Tree_Expand_Selected (S);

         when File_Tree_Collapse_Selected =>
            Execute_File_Tree_Collapse_Selected (S);

         when File_Tree_Toggle_Selected =>
            Execute_File_Tree_Toggle_Selected (S);

         when File_Tree_Collapse_All =>
            Execute_File_Tree_Collapse_All (S);

         when File_Tree_Expand_To_Active_File =>
            Execute_File_Tree_Expand_To_Active_File (S);

         when others =>
            raise Program_Error with "unsupported file tree command kind";
      end case;
   end Execute_File_Tree_Kind;

end Editor.Executor.File_Tree_Commands;
