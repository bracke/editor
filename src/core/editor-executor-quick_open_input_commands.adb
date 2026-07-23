with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.File_Tree;
with Editor.Project;
with Editor.Overlay_Focus;
with Editor.Quick_Open;
use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
use type Editor.Quick_Open.Quick_Open_Priority_Mode;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Quick_Open_Input_Commands is

   function Quick_Open_File_Count
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if Editor.File_Tree.File_Node_Count (S.File_Tree) > 0 then
         return Editor.File_Tree.File_Node_Count (S.File_Tree);
      elsif Editor.Project.Has_Project (S.Project) then
         return Editor.Project.Known_File_Count (S.Project);
      else
         return 0;
      end if;
   end Quick_Open_File_Count;

   function Default_Quick_Open_Config
     return Editor.Quick_Open.Quick_Open_Config
   is
   begin
      return (others => <>);
   end Default_Quick_Open_Config;

   procedure Recompute_Quick_Open
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Quick_Open.Recompute_Results
        (S.Quick_Open, S.File_Tree, Default_Quick_Open_Config);
      Editor.Render_Cache.Invalidate_All;
   end Recompute_Quick_Open;

   procedure Execute_Quick_Open_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         Editor.Quick_Open.Set_Query_Text (S.Quick_Open, Text);
         Recompute_Quick_Open (S);
         if Editor.Quick_Open.Result_Count (S.Quick_Open) = 0 then
            if not Editor.Project.Has_Project (S.Project) then
               Report_Info (S, "No project open");
            elsif Quick_Open_File_Count (S) = 0 then
               Report_Info (S, "No project files");
            else
               Report_Info (S, "No Quick Open matches.");
            end if;
         else
            Report_Info (S, "Quick Open query set");
         end if;
      end if;
   end Execute_Quick_Open_Set_Query;

   procedure Execute_Quick_Open_Clear_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if Editor.Quick_Open.Query_Text (S.Quick_Open)'Length = 0 then
            Report_Info (S, "No Quick Open query to clear");
         else
            Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "");
            Recompute_Quick_Open (S);
            Report_Info (S, "Quick Open query cleared");
         end if;
      end if;
   end Execute_Quick_Open_Clear_Query;

   procedure Execute_Quick_Open_Kind_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;

         Editor.Quick_Open.Cycle_File_Kind_Next (S.Quick_Open);
         Recompute_Quick_Open (S);
         Report_Info (S, "Quick Open filter: " &
           Editor.Quick_Open.File_Kind_Filter_Name
             (Editor.Quick_Open.File_Kind_Filter (S.Quick_Open)));
      end if;
   end Execute_Quick_Open_Kind_Next;

   procedure Execute_Quick_Open_Kind_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         end if;

         Editor.Quick_Open.Cycle_File_Kind_Previous (S.Quick_Open);
         Recompute_Quick_Open (S);
         Report_Info (S, "Quick Open filter: " &
           Editor.Quick_Open.File_Kind_Filter_Name
             (Editor.Quick_Open.File_Kind_Filter (S.Quick_Open)));
      end if;
   end Execute_Quick_Open_Kind_Previous;

   procedure Execute_Quick_Open_Kind_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project) then
            Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif Editor.Quick_Open.File_Kind_Filter (S.Quick_Open) =
           Editor.Quick_Open.All_Files
         then
            Report_Info (S, "No Quick Open file-kind filter to clear");
         else
            Editor.Quick_Open.Clear_File_Kind_Filter (S.Quick_Open);
            Recompute_Quick_Open (S);
            Report_Info (S, "Quick Open filter: All");
         end if;
      end if;
   end Execute_Quick_Open_Kind_Clear;

   procedure Execute_Quick_Open_Priority_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Info (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Report_Info (S, "Quick Open is not visible");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Quick_Open.Toggle_Priority_Mode (S.Quick_Open);
      Recompute_Quick_Open (S);

      case Editor.Quick_Open.Priority_Mode (S.Quick_Open) is
         when Editor.Quick_Open.Open_Recent =>
            Report_Info (S, "Quick Open priority: Open/Recent");
         when Editor.Quick_Open.Path =>
            Report_Info (S, "Quick Open priority: Path");
      end case;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Priority_Toggle;

   procedure Execute_Quick_Open_Priority_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Info (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay)
        or else not Editor.Quick_Open.Is_Open (S.Quick_Open)
      then
         Report_Info (S, "Quick Open is not visible");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Quick_Open.Priority_Mode (S.Quick_Open) =
        Editor.Quick_Open.Path
      then
         Report_Info (S, "Quick Open priority already Path");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Quick_Open.Clear_Priority_Mode (S.Quick_Open);
      Recompute_Quick_Open (S);
      Report_Info (S, "Quick Open priority: Path");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Priority_Clear;

   procedure Execute_Quick_Open_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         Editor.Quick_Open.Insert_Text (S.Quick_Open, Text);
         Recompute_Quick_Open (S);
      end if;
   end Execute_Quick_Open_Insert_Text;

   procedure Execute_Quick_Open_Backspace
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         Editor.Quick_Open.Backspace (S.Quick_Open);
         Recompute_Quick_Open (S);
      end if;
   end Execute_Quick_Open_Backspace;

   procedure Execute_Quick_Open_Delete_Forward
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         Editor.Quick_Open.Delete_Forward (S.Quick_Open);
         Recompute_Quick_Open (S);
      end if;
   end Execute_Quick_Open_Delete_Forward;

   procedure Execute_Quick_Open_Move_Cursor_Left
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Quick_Open.Move_Cursor_Left (S.Quick_Open);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Move_Cursor_Left;

   procedure Execute_Quick_Open_Move_Cursor_Right
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Quick_Open.Move_Cursor_Right (S.Quick_Open);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Quick_Open_Move_Cursor_Right;

end Editor.Executor.Quick_Open_Input_Commands;
