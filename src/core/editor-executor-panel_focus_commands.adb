with Editor.Build_UI_Actions;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Search_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Focus_Management;
with Editor.Layout;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Problems;
with Editor.Render_Cache;
with Editor.State;
with Editor.View;

package body Editor.Executor.Panel_Focus_Commands is

   function Panel_Focus_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;
   begin
      case Id is
         when Editor.Commands.Command_Toggle_Problems_Panel
            | Editor.Commands.Command_Focus_Editor_Text
            | Editor.Commands.Command_Problems_Focus_Editor
            | Editor.Commands.Command_Toggle_Bottom_Panel_Focus =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Focus_Search_Results =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Editor.Commands.Command_Focus_Problems =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a panel/focus command");
      end case;
   end Panel_Focus_Command_Availability;

   procedure Clear_Restore_Feedback_Current
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Clear_Restore_Feedback_Current;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Execute_Toggle_Problems_Panel
     (S : in out Editor.State.State_Type)
   is
      Visible : constant Boolean :=
        Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel);
   begin
      Editor.Panels.Set_Bottom_Content (S.Panels, Editor.Panels.Problems_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, not Visible);
      if Visible then
         Editor.Focus_Management.Restore_Focus_To_Editor (S);
      elsif Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Diagnostics);
      end if;
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Toggle_Problems_Panel;

   procedure Execute_Focus_Editor_Text
     (S : in out Editor.State.State_Type)
   is
   begin
      --  Direct editor focus must clear every transient owner.
      Clear_Restore_Feedback_Current (S);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Focus_Editor_Text;

   procedure Execute_Focus_Search_Results
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Search_Results_Commands.Execute_Focus_Search_Results (S);
   end Execute_Focus_Search_Results;

   function Problems_Visible_Row_Count return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Rows : Natural := 1;
   begin
      if Editor.Layout.Cell_H = 0 then
         return 1;
      end if;

      Rows := Natural'Max (1, Panel.Height / Editor.Layout.Cell_H);
      --  The Problems header is fixed; the view window counts diagnostic rows.
      if Rows > 1 then
         return Rows - 1;
      else
         return 1;
      end if;
   end Problems_Visible_Row_Count;

   procedure Execute_Focus_Problems
     (S : in out Editor.State.State_Type)
   is
      Full_Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Build_Snapshot (S.Diagnostics);
      Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Filtered_Snapshot (Full_Snapshot, S.Problems_View);
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Diagnostics);

      Editor.Problems.Ensure_Selected_Row_Visible
        (S.Problems_View, Snapshot, Problems_Visible_Row_Count);
      if Editor.Problems.Row_Count (Full_Snapshot) = 0 then
         Report_Info (S, "No problems");
      end if;

      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Focus_Problems;

   procedure Execute_Toggle_Bottom_Panel_Focus
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
         Execute_Focus_Editor_Text (S);
      elsif Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel) then
         case Editor.Panels.Active_Bottom_Content (S.Panels) is
            when Editor.Panels.Search_Results_Content =>
               Editor.Focus_Management.Set_Focus_Owner
                 (S, Editor.Focus_Management.Focus_Project_Search_Results);
            when Editor.Panels.Problems_Content =>
               Editor.Focus_Management.Set_Focus_Owner
                 (S, Editor.Focus_Management.Focus_Diagnostics);
         end case;
         Editor.Render_Cache.Invalidate_All;
      else
         Execute_Focus_Editor_Text (S);
      end if;
   end Execute_Toggle_Bottom_Panel_Focus;

   procedure Execute_Toggle_Build_Output
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI_Actions.Toggle_Build_UI (S);
      Report_Info (S, "Build Output toggled.");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Toggle_Build_Output;

   procedure Execute_Show_Build_Output
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI_Actions.Show_Build_UI (S);
      Report_Info (S, "Build Output shown.");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Show_Build_Output;

   procedure Execute_Hide_Build_Output
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI_Actions.Hide_Build_UI (S);
      Report_Info (S, "Build Output hidden.");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Hide_Build_Output;

   procedure Execute_Focus_Build_Output
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI_Actions.Focus_Build_UI (S);
      Report_Info (S, "Build Output focused.");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Focus_Build_Output;

   procedure Execute_Focus_Build_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_Result_Summary);
      Report_Info (S, "Build result focused.");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Focus_Build_Result;

   procedure Execute_Focus_Build_Output_Details
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_Output_Details);
      Report_Info (S, "Build output details focused.");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Focus_Build_Output_Details;

   function Execute_Panel_Focus_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Editor.Commands.Command_Build_UI_Toggle =>
            Execute_Toggle_Build_Output (S);
         when Editor.Commands.Command_Build_UI_Show =>
            Execute_Show_Build_Output (S);
         when Editor.Commands.Command_Build_UI_Hide =>
            Execute_Hide_Build_Output (S);
         when Editor.Commands.Command_Build_UI_Focus =>
            Execute_Focus_Build_Output (S);
         when Editor.Commands.Command_Build_Result_Focus =>
            Execute_Focus_Build_Result (S);
         when Editor.Commands.Command_Build_Output_Details_Focus =>
            Execute_Focus_Build_Output_Details (S);
         when others =>
            null;
      end case;

      return Editor.Command_Execution.Executed (Id);
   end Execute_Panel_Focus_Command;

end Editor.Executor.Panel_Focus_Commands;
