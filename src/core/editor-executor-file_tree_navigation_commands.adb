with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Project_File_Index_Commands;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.File_Tree.File_Tree_Node_Kind;
with Editor.File_Tree_View;
use type Editor.File_Tree_View.File_Tree_Action;
with Editor.Focus_Management;
with Editor.Project;
with Editor.Render_Cache;
with Editor.State;
with Editor.Panels;

package body Editor.Executor.File_Tree_Navigation_Commands is

   procedure Execute_Focus_File_Tree
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Clear_Restore_Feedback_Current (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
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
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Shared_Services.Report_Warning (S, "No File Tree node selected");
         return;
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);
      if Summary.Kind /= Editor.File_Tree.File_Node then
         --  /545: the open-selected command opens real file nodes
         --  only.  Directory activation remains explicit through
         --  expand/collapse/toggle commands, so status/directory rows cannot
         --  masquerade as file opens.
         Editor.Executor.Shared_Services.Report_Warning (S, "Selected row is not a file");
      elsif not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         --  completeness: File Tree nodes normally originate from
         --  the bounded project scan, but command execution must still defend
         --  the project boundary if stale/corrupt transient tree state reaches
         --  the Executor.  Opening a selected File Tree row must not become an
         --  escape hatch to a recent-project or absolute path outside the
         --  active project root.
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
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
                  Editor.Executor.Shared_Services.Report_Error
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
                  Editor.Executor.Shared_Services.Report_Error
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
            Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
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
                  Editor.Executor.Shared_Services.Report_Error
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

   procedure Execute_File_Tree_Expand_Selected
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Node  : constant Editor.File_Tree.File_Tree_Node_Id := Editor.Executor.Selected_File_Tree_Node (S, Found);
      Summary : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Shared_Services.Report_Warning (S, "No File Tree node selected");
         return;
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);
      if not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif Summary.Kind /= Editor.File_Tree.Directory_Node then
         Editor.Executor.Shared_Services.Report_Warning (S, "Selected row is not a directory");
         return;
      end if;

      if Summary.Is_Expanded then
         Editor.Executor.Shared_Services.Report_Info (S, "File Tree directory already expanded");
      else
         Editor.File_Tree.Set_Expanded (S.File_Tree, Node, True);
         Editor.Executor.Select_File_Tree_Node (S, Node);
         Editor.Executor.Shared_Services.Report_Success (S, "File Tree directory expanded");
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
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Shared_Services.Report_Warning (S, "No File Tree node selected");
         return;
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);
      if not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif Summary.Kind /= Editor.File_Tree.Directory_Node then
         Editor.Executor.Shared_Services.Report_Warning (S, "Selected row is not a directory");
         return;
      elsif not Summary.Is_Expanded then
         Editor.Executor.Shared_Services.Report_Info (S, "File Tree directory already collapsed");
         return;
      end if;

      Editor.File_Tree.Set_Expanded (S.File_Tree, Node, False);
      Editor.Executor.Select_File_Tree_Node (S, Node);
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Executor.Shared_Services.Report_Success (S, "File Tree directory collapsed");
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
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Shared_Services.Report_Warning (S, "No File Tree node selected");
         return;
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node);
      if not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif Summary.Kind /= Editor.File_Tree.Directory_Node then
         Editor.Executor.Shared_Services.Report_Warning (S, "Selected row is not a directory");
         return;
      end if;

      Editor.File_Tree.Toggle_Expanded (S.File_Tree, Node);
      Editor.Executor.Select_File_Tree_Node (S, Node);
      Editor.Executor.Validate_File_Tree_View (S);
      if Summary.Is_Expanded then
         Editor.Executor.Shared_Services.Report_Success (S, "File Tree directory collapsed");
      else
         Editor.Executor.Shared_Services.Report_Success (S, "File Tree directory expanded");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Toggle_Selected;



   procedure Execute_File_Tree_Collapse_All
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif Editor.File_Tree.Is_Empty (S.File_Tree) then
         Editor.Executor.Shared_Services.Report_Warning (S, "File Tree unavailable");
         return;
      end if;

      Editor.File_Tree.Collapse_All (S.File_Tree);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);
      Editor.Executor.Validate_File_Tree_View (S);
      Editor.Executor.Shared_Services.Report_Success (S, "File Tree collapsed");
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Collapse_All;

   procedure Execute_File_Tree_Expand_To_Active_File
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Project_File_Index_Commands
        .Execute_Reveal_Active_File_In_Tree (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_File_Tree_Expand_To_Active_File;

end Editor.Executor.File_Tree_Navigation_Commands;
