with Editor.Commands;
with Editor.Diagnostics;
with Editor.Executor;
with Editor.Executor.Diagnostics_Navigation_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Focus_Management;
with Editor.Panels;
with Editor.Problems;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Diagnostics_Problems_Commands is

   use type Editor.Diagnostics.Diagnostic_Index;

   procedure Execute_Problems_Move_Up
     (S : in out Editor.State.State_Type)
   is
      Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Filtered_Snapshot
          (Editor.Problems.Build_Snapshot (S.Diagnostics), S.Problems_View);
   begin
      if Editor.Problems.Row_Count (Snapshot) = 0 then
         Editor.Problems.Ensure_Valid_Selection (S.Problems_View, Snapshot);
         Editor.Executor.Shared_Services.Report_Info (S, "No problems");
      else
         Editor.Problems.Move_Selection
           (S.Problems_View, Snapshot, Editor.Problems.Previous_Row, True);
         Editor.Problems.Ensure_Selected_Row_Visible
           (S.Problems_View, Snapshot, Editor.Executor.Problems_Visible_Row_Count);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Diagnostics);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Problems_Move_Up;

   procedure Execute_Problems_Move_Down
     (S : in out Editor.State.State_Type)
   is
      Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Filtered_Snapshot
          (Editor.Problems.Build_Snapshot (S.Diagnostics), S.Problems_View);
   begin
      if Editor.Problems.Row_Count (Snapshot) = 0 then
         Editor.Problems.Ensure_Valid_Selection (S.Problems_View, Snapshot);
         Editor.Executor.Shared_Services.Report_Info (S, "No problems");
      else
         Editor.Problems.Move_Selection
           (S.Problems_View, Snapshot, Editor.Problems.Next_Row, True);
         Editor.Problems.Ensure_Selected_Row_Visible
           (S.Problems_View, Snapshot, Editor.Executor.Problems_Visible_Row_Count);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Diagnostics);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Problems_Move_Down;

   procedure Execute_Problems_Page_Up
     (S : in out Editor.State.State_Type)
   is
      Steps : constant Natural := Editor.Executor.Problems_Visible_Row_Count;
   begin
      for I in 1 .. Steps loop
         Execute_Problems_Move_Up (S);
      end loop;
   end Execute_Problems_Page_Up;

   procedure Execute_Problems_Page_Down
     (S : in out Editor.State.State_Type)
   is
      Steps : constant Natural := Editor.Executor.Problems_Visible_Row_Count;
   begin
      for I in 1 .. Steps loop
         Execute_Problems_Move_Down (S);
      end loop;
   end Execute_Problems_Page_Down;

   procedure Execute_Problems_Open_Selected
     (S : in out Editor.State.State_Type)
   is
      Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Filtered_Snapshot
          (Editor.Problems.Build_Snapshot (S.Diagnostics), S.Problems_View);
      Found : Boolean := False;
      Diagnostic_Index : constant Editor.Diagnostics.Diagnostic_Index :=
        Editor.Problems.Diagnostic_For_Row
          (Snapshot, Editor.Problems.Selected_Row_Index (S.Problems_View), Found);
      Problem_Row : Editor.Problems.Problem_Row;
   begin
      if not Found or else Diagnostic_Index = Editor.Diagnostics.No_Diagnostic then
         Editor.Executor.Shared_Services.Report_Info (S, "No diagnostic selected");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Problem_Row := Editor.Problems.Row
        (Snapshot, Positive (Editor.Problems.Selected_Row_Index (S.Problems_View)));
      if not Editor.Problems.Row_Has_Target (Problem_Row) then
         Editor.Executor.Shared_Services.Report_Info
           (S, Editor.Problems.Row_Target_Unavailable_Label (Problem_Row));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Jump_To_Diagnostic
        (S, Diagnostic_Index);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Problems_Open_Selected;

   procedure Execute_Problems_Filter
     (S      : in out Editor.State.State_Type;
      Filter : Editor.Problems.Problems_Severity_Filter)
   is
      Full_Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Build_Snapshot (S.Diagnostics);
      Visible : Editor.Problems.Problems_Snapshot;
   begin
      Editor.Problems.Set_Severity_Filter (S.Problems_View, Filter);
      Visible := Editor.Problems.Filtered_Snapshot
        (Full_Snapshot, S.Problems_View);
      Editor.Problems.Ensure_Valid_Selection (S.Problems_View, Visible);
      Editor.Problems.Ensure_Selected_Row_Visible
        (S.Problems_View, Visible, Editor.Executor.Problems_Visible_Row_Count);
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Problems_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Diagnostics);
      Editor.Executor.Shared_Services.Report_Info
        (S, "Problems filter: "
         & Editor.Problems.Severity_Filter_Label (Filter));
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Problems_Filter;

   procedure Execute_Problems_Sort
     (S    : in out Editor.State.State_Type;
      Sort : Editor.Problems.Problems_Sort_Mode)
   is
      Full_Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Build_Snapshot (S.Diagnostics);
      Visible : Editor.Problems.Problems_Snapshot;
   begin
      S.Problems_View.Sort_Mode := Sort;
      Visible := Editor.Problems.Review_Snapshot
        (Full_Snapshot, S.Problems_View);
      Editor.Problems.Ensure_Valid_Selection (S.Problems_View, Visible);
      Editor.Problems.Ensure_Selected_Row_Visible
        (S.Problems_View, Visible, Editor.Executor.Problems_Visible_Row_Count);
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Problems_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Diagnostics);
      case Sort is
         when Editor.Problems.Problems_Sort_By_Location =>
            Editor.Executor.Shared_Services.Report_Info (S, "Problems sort: location");
         when Editor.Problems.Problems_Sort_By_Severity =>
            Editor.Executor.Shared_Services.Report_Info (S, "Problems sort: severity");
         when Editor.Problems.Problems_Sort_By_Source =>
            Editor.Executor.Shared_Services.Report_Info (S, "Problems sort: source");
      end case;
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Problems_Sort;

   procedure Execute_Problems_Group
     (S     : in out Editor.State.State_Type;
      Group : Editor.Problems.Problems_Group_Mode)
   is
      Full_Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Build_Snapshot (S.Diagnostics);
      Visible : Editor.Problems.Problems_Snapshot;
   begin
      S.Problems_View.Group_Mode := Group;
      Visible := Editor.Problems.Review_Snapshot
        (Full_Snapshot, S.Problems_View);
      Editor.Problems.Ensure_Valid_Selection (S.Problems_View, Visible);
      Editor.Problems.Ensure_Selected_Row_Visible
        (S.Problems_View, Visible, Editor.Executor.Problems_Visible_Row_Count);
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Problems_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Diagnostics);
      case Group is
         when Editor.Problems.Problems_Group_By_Severity =>
            Editor.Executor.Shared_Services.Report_Info (S, "Problems group: severity");
         when Editor.Problems.Problems_Group_By_Source =>
            Editor.Executor.Shared_Services.Report_Info (S, "Problems group: source");
      end case;
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Problems_Group;

   procedure Execute_Problems_Focus_Editor
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Panel_Focus_Commands.Execute_Focus_Editor_Text (S);
   end Execute_Problems_Focus_Editor;

   procedure Execute_Problems_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
   begin
      case Kind is
         when Editor.Commands.Problems_Move_Up =>
            Execute_Problems_Move_Up (S);

         when Editor.Commands.Problems_Move_Down =>
            Execute_Problems_Move_Down (S);

         when Editor.Commands.Problems_Page_Up =>
            Execute_Problems_Page_Up (S);

         when Editor.Commands.Problems_Page_Down =>
            Execute_Problems_Page_Down (S);

         when Editor.Commands.Problems_Open_Selected =>
            Execute_Problems_Open_Selected (S);

         when Editor.Commands.Problems_Filter_All =>
            Execute_Problems_Filter (S, Editor.Problems.Problems_Show_All);

         when Editor.Commands.Problems_Filter_Errors =>
            Execute_Problems_Filter (S, Editor.Problems.Problems_Show_Errors);

         when Editor.Commands.Problems_Filter_Warnings =>
            Execute_Problems_Filter (S, Editor.Problems.Problems_Show_Warnings);

         when Editor.Commands.Problems_Filter_Info =>
            Execute_Problems_Filter (S, Editor.Problems.Problems_Show_Info);

         when Editor.Commands.Problems_Filter_Hints =>
            Execute_Problems_Filter (S, Editor.Problems.Problems_Show_Hints);

         when Editor.Commands.Problems_Sort_By_Location =>
            Execute_Problems_Sort
              (S, Editor.Problems.Problems_Sort_By_Location);

         when Editor.Commands.Problems_Sort_By_Severity =>
            Execute_Problems_Sort
              (S, Editor.Problems.Problems_Sort_By_Severity);

         when Editor.Commands.Problems_Sort_By_Source =>
            Execute_Problems_Sort
              (S, Editor.Problems.Problems_Sort_By_Source);

         when Editor.Commands.Problems_Group_By_Severity =>
            Execute_Problems_Group
              (S, Editor.Problems.Problems_Group_By_Severity);

         when Editor.Commands.Problems_Group_By_Source =>
            Execute_Problems_Group
              (S, Editor.Problems.Problems_Group_By_Source);

         when Editor.Commands.Problems_Focus_Editor =>
            Execute_Problems_Focus_Editor (S);

         when others =>
            raise Program_Error with "unsupported problems command kind";
      end case;
   end Execute_Problems_Kind;

end Editor.Executor.Diagnostics_Problems_Commands;
