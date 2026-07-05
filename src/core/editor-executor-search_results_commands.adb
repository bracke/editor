with Ada.Strings.Unbounded;

with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Focus_Management;
with Editor.Layout;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Project_Search;
with Editor.Render_Cache;
with Editor.Search_Results;
with Editor.State;
with Editor.View;

package body Editor.Executor.Search_Results_Commands is

   use Ada.Strings.Unbounded;
   use Editor.Commands;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Feature_Search_Results.External_Result_Set_Kind;
   use type Editor.Panels.Bottom_Panel_Content;

   function Search_Results_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Command_Search_Results_Focus_Query
            | Command_Search_Results_Query_History_Previous
            | Command_Search_Results_Query_History_Next
            | Command_Search_Results_Toggle_Case_Sensitive
            | Command_Show_Search_Results_Feature =>
            return Editor.Commands.Available;

         when Command_Search_Results_Search_Active_Buffer =>
            if not Editor.State.Has_Active_Buffer (S)
              or else S.Registry_Token = 0
            then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Search_Results
                    .Message_Search_Active_Buffer_No_Active_Buffer);
            elsif Editor.Feature_Search_Results.Search_Input_Text
              (S.Feature_Search_Results)'Length = 0
              and then Length (S.Active_Find_Query) = 0
            then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Search_Results
                    .Message_Search_Active_Buffer_Empty_Query);
            end if;
            return Editor.Commands.Available;

         when Command_Search_Results_Repeat_Active_Buffer =>
            if not Editor.Feature_Search_Results.Has_Query
              (S.Feature_Search_Results)
            then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Search_Results.Message_Search_Repeat_No_Query);
            elsif not Editor.State.Has_Active_Buffer (S)
              or else S.Registry_Token = 0
            then
               return Editor.Commands.Unavailable
                 (Editor.Feature_Search_Results
                    .Message_Search_Active_Buffer_No_Active_Buffer);
            end if;
            return Editor.Commands.Available;

         when Command_Clear_Search_Results_Feature =>
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a search-results command");
      end case;
   end Search_Results_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Active_Feature_Buffer_Token
     (S : Editor.State.State_Type) return Natural
      renames Editor.Executor.Active_Feature_Buffer_Token;

   function Feature_Target_Position_Is_Valid
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return Boolean
      renames Editor.Executor.Feature_Target_Position_Is_Valid;

   function Focus_Feature_Target_Buffer
     (S             : in out Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean
      renames Editor.Executor.Focus_Feature_Target_Buffer;

   procedure Apply_Feature_Target_Handoff
     (S             : in out Editor.State.State_Type;
      Target_Row    : Natural;
      Target_Column : Natural)
      renames Editor.Executor.Apply_Feature_Target_Handoff;

   function Executed
     (Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
      renames Editor.Command_Execution.Executed;

   function No_Op
     (Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
      renames Editor.Command_Execution.No_Op;

   procedure Report_Target_Unavailable
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Info (S, "Navigation target unavailable.");
   end Report_Target_Unavailable;

   function Search_Results_Visible_Row_Count return Natural
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Panel  : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
   begin
      if Editor.Layout.Cell_H = 0 then
         return 1;
      else
         return Natural'Max (1, Panel.Height / Editor.Layout.Cell_H);
      end if;
   end Search_Results_Visible_Row_Count;

   procedure Ensure_Search_Result_Visible
     (S : in out Editor.State.State_Type)
   is
      Snapshot : constant Editor.Search_Results.Search_Results_Snapshot :=
        Editor.Search_Results.Build_Snapshot (S.Project_Search, (others => <>));
   begin
      Editor.Search_Results.Ensure_Selected_Row_Visible
        (S.Search_Results_View,
         Snapshot,
         Editor.Project_Search.Selected_Result_Index (S.Project_Search),
         Search_Results_Visible_Row_Count);
   end Ensure_Search_Result_Visible;

   procedure Execute_Focus_Search_Results
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
        and then Editor.Panels.Active_Bottom_Content (S.Panels) =
          Editor.Panels.Search_Results_Content
      then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      elsif Editor.Project_Search.Result_Count (S.Project_Search) > 0 then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      else
         Report_Info (S, "No project search results");
      end if;
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Focus_Search_Results;

   procedure Execute_Search_Results_Move_Up
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
      else
         Editor.Project_Search.Move_Selected_Result
           (S.Project_Search, Editor.Project_Search.Previous_Result, False);
         Ensure_Search_Result_Visible (S);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Move_Up;

   procedure Execute_Search_Results_Move_Down
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
      else
         Editor.Project_Search.Move_Selected_Result
           (S.Project_Search, Editor.Project_Search.Next_Result, False);
         Ensure_Search_Result_Visible (S);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Move_Down;

   procedure Execute_Search_Results_Page_Up
     (S : in out Editor.State.State_Type)
   is
      Steps : constant Natural := Search_Results_Visible_Row_Count;
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
      else
         for I in 1 .. Steps loop
            Editor.Project_Search.Move_Selected_Result
              (S.Project_Search, Editor.Project_Search.Previous_Result, False);
         end loop;
         Ensure_Search_Result_Visible (S);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Page_Up;

   procedure Execute_Search_Results_Page_Down
     (S : in out Editor.State.State_Type)
   is
      Steps : constant Natural := Search_Results_Visible_Row_Count;
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
      else
         for I in 1 .. Steps loop
            Editor.Project_Search.Move_Selected_Result
              (S.Project_Search, Editor.Project_Search.Next_Result, False);
         end loop;
         Ensure_Search_Result_Visible (S);
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Page_Down;

   procedure Execute_Search_Results_Open_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
        Editor.Feature_Panel.Search_Results_Feature
        and then Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
      then
         declare
            Result : constant Editor.Executor.Command_Execution_Result :=
              Execute_Search_Result_Row_Activation
                (S, Editor.Feature_Panel.Selected_Row (S.Feature_Panel));
         begin
            if Result.Status = Editor.Executor.Command_Executed then
               Editor.Focus_Management.Restore_Focus_To_Editor (S);
               Editor.Render_Cache.Invalidate_All;
               return;
            end if;
         end;
      end if;

      Editor.Executor.Project_Search_Result_Commands
        .Execute_Open_Selected_Project_Search_Result (S);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Open_Selected;

   procedure Execute_Search_Results_Close_Or_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Search_Results_Close_Or_Hide;

   function Execute_Search_Results_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Editor.Commands.Command_Search_Results_Search_Active_Buffer =>
            declare
               Input_Query     : constant String :=
                 Editor.Feature_Search_Results.Search_Input_Text
                   (S.Feature_Search_Results);
               Effective_Query : constant String :=
                 (if Input_Query'Length > 0
                  then Input_Query
                  else To_String (S.Active_Find_Query));
               Previous_Index  : Natural := 0;
               Previous_Buffer : Natural := Editor.Feature_Search_Results.No_Buffer;
               Previous_Line   : Natural := 0;
               Previous_Column : Natural := 0;
               Previous_Length : Natural := 0;
               Previous_Text   : Unbounded_String := Null_Unbounded_String;
               Preserve        : Boolean := False;
               New_Index       : Natural := 0;
            begin
               if not Editor.State.Has_Active_Buffer (S)
                 or else S.Registry_Token = 0
               then
                  Report_Info
                    (S,
                     Editor.Feature_Search_Results
                       .Message_Search_Active_Buffer_No_Active_Buffer);
                  return No_Op (Id);
               elsif Effective_Query'Length = 0 then
                  Report_Info
                    (S,
                     Editor.Feature_Search_Results
                       .Message_Search_Active_Buffer_Empty_Query);
                  return No_Op (Id);
               end if;

               Preserve :=
                 Editor.Feature_Search_Results.Has_Query
                   (S.Feature_Search_Results)
                 and then Editor.Feature_Search_Results.Query_Text
                   (S.Feature_Search_Results) = Effective_Query
                 and then Editor.Feature_Search_Results.Searched_Buffer
                   (S.Feature_Search_Results) = Active_Feature_Buffer_Token (S);

               if Preserve then
                  Previous_Index :=
                    Editor.Feature_Search_Results.Map_Search_Result_Row_To_Item
                      (S.Feature_Search_Results, S.Feature_Panel,
                       Editor.Feature_Panel.Selected_Row (S.Feature_Panel));
                  if Previous_Index > 0 then
                     Previous_Buffer :=
                       Editor.Feature_Search_Results.Item_Target_Buffer
                         (S.Feature_Search_Results, Positive (Previous_Index));
                     Previous_Line :=
                       Editor.Feature_Search_Results.Item_Match_Line
                         (S.Feature_Search_Results, Positive (Previous_Index));
                     Previous_Column :=
                       Editor.Feature_Search_Results.Item_Match_Column
                         (S.Feature_Search_Results, Positive (Previous_Index));
                     Previous_Length :=
                       Editor.Feature_Search_Results.Item_Match_Length
                         (S.Feature_Search_Results, Positive (Previous_Index));
                     Previous_Text := To_Unbounded_String
                       (Editor.Feature_Search_Results.Item_Line_Text
                          (S.Feature_Search_Results,
                           Positive (Previous_Index)));
                  end if;
               end if;

               Editor.Feature_Search_Results.Run_Active_Buffer_Search
                 (Results          => S.Feature_Search_Results,
                  Query            => Effective_Query,
                  Snapshot_Text    => Editor.State.Current_Text (S),
                  Source_Label     => To_String (S.File_Info.Display_Name),
                  Target_Buffer    => Active_Feature_Buffer_Token (S),
                  Snapshot_Version => Editor.State.Current_Buffer_Revision (S));
               Editor.Feature_Search_Results.Commit_Search_Query_To_History
                 (S.Feature_Search_Results, Effective_Query);
               Editor.Feature_Search_Results.Deactivate_Search_Query_Input
                 (S.Feature_Search_Results);

               if Preserve then
                  New_Index := Editor.Feature_Search_Results.Best_Rerun_Selection
                    (S.Feature_Search_Results, Previous_Buffer, Previous_Line,
                     Previous_Column, Previous_Length, To_String (Previous_Text));
               elsif Editor.Feature_Search_Results.Row_Count
                 (S.Feature_Search_Results) > 0
               then
                  New_Index := 1;
               end if;

               Editor.Feature_Panel.Forget_Feature_View_State
                 (S.Feature_Panel, Editor.Feature_Panel.Search_Results_Feature);
               Editor.Feature_Search_Results.Project_Rows
                 (S.Feature_Search_Results, S.Feature_Panel);
               Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
               Editor.Feature_Panel.Select_Row (S.Feature_Panel, New_Index);
               Report_Info
                 (S,
                  Editor.Feature_Search_Results
                    .Message_Search_Active_Buffer_Completed
                      (S.Feature_Search_Results));
               Editor.Render_Cache.Invalidate_All;
               return Executed (Id);
            end;

         when Editor.Commands.Command_Search_Results_Focus_Query =>
            Editor.Focus_Management.Clear_Transient_Focus_Owners (S);
            Editor.Feature_Search_Results.Activate_Search_Query_Input
              (S.Feature_Search_Results);
            Editor.Feature_Search_Results.Project_Rows
              (S.Feature_Search_Results, S.Feature_Panel);
            Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
            Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
            Report_Info
              (S, Editor.Feature_Search_Results
                    .Message_Search_Query_Input_Focused);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Search_Results_Repeat_Active_Buffer =>
            declare
               Previous_Index  : Natural := 0;
               Previous_Buffer : Natural := Editor.Feature_Search_Results.No_Buffer;
               Previous_Line   : Natural := 0;
               Previous_Column : Natural := 0;
               Previous_Length : Natural := 0;
               Previous_Text   : Unbounded_String := Null_Unbounded_String;
               New_Index       : Natural := 0;
            begin
               if not Editor.Feature_Search_Results.Has_Query
                 (S.Feature_Search_Results)
               then
                  Report_Info
                    (S, Editor.Feature_Search_Results
                          .Message_Search_Repeat_No_Query);
                  return No_Op (Id);
               elsif not Editor.State.Has_Active_Buffer (S)
                 or else S.Registry_Token = 0
               then
                  Report_Info
                    (S,
                     Editor.Feature_Search_Results
                       .Message_Search_Active_Buffer_No_Active_Buffer);
                  return No_Op (Id);
               end if;

               Previous_Index :=
                 Editor.Feature_Search_Results.Map_Search_Result_Row_To_Item
                   (S.Feature_Search_Results, S.Feature_Panel,
                    Editor.Feature_Panel.Selected_Row (S.Feature_Panel));
               if Previous_Index > 0 then
                  Previous_Buffer :=
                    Editor.Feature_Search_Results.Item_Target_Buffer
                      (S.Feature_Search_Results, Positive (Previous_Index));
                  Previous_Line :=
                    Editor.Feature_Search_Results.Item_Match_Line
                      (S.Feature_Search_Results, Positive (Previous_Index));
                  Previous_Column :=
                    Editor.Feature_Search_Results.Item_Match_Column
                      (S.Feature_Search_Results, Positive (Previous_Index));
                  Previous_Length :=
                    Editor.Feature_Search_Results.Item_Match_Length
                      (S.Feature_Search_Results, Positive (Previous_Index));
                  Previous_Text := To_Unbounded_String
                    (Editor.Feature_Search_Results.Item_Line_Text
                       (S.Feature_Search_Results, Positive (Previous_Index)));
               end if;

               Editor.Feature_Search_Results.Run_Active_Buffer_Search
                 (Results          => S.Feature_Search_Results,
                  Query            => Editor.Feature_Search_Results.Query_Text
                    (S.Feature_Search_Results),
                  Snapshot_Text    => Editor.State.Current_Text (S),
                  Source_Label     => To_String (S.File_Info.Display_Name),
                  Target_Buffer    => Active_Feature_Buffer_Token (S),
                  Snapshot_Version => Editor.State.Current_Buffer_Revision (S));
               Editor.Feature_Search_Results.Commit_Search_Query_To_History
                 (S.Feature_Search_Results,
                  Editor.Feature_Search_Results.Query_Text
                    (S.Feature_Search_Results));
               New_Index := Editor.Feature_Search_Results.Best_Rerun_Selection
                 (S.Feature_Search_Results, Previous_Buffer, Previous_Line,
                  Previous_Column, Previous_Length, To_String (Previous_Text));
               Editor.Feature_Panel.Forget_Feature_View_State
                 (S.Feature_Panel, Editor.Feature_Panel.Search_Results_Feature);
               Editor.Feature_Search_Results.Project_Rows
                 (S.Feature_Search_Results, S.Feature_Panel);
               Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
               Editor.Feature_Panel.Select_Row (S.Feature_Panel, New_Index);
               Report_Info
                 (S, Editor.Feature_Search_Results.Message_Search_Repeated);
               Editor.Render_Cache.Invalidate_All;
               return Executed (Id);
            end;

         when Editor.Commands.Command_Search_Results_Query_History_Previous =>
            Editor.Feature_Search_Results.Select_Previous_Search_Query
              (S.Feature_Search_Results);
            Editor.Feature_Search_Results.Project_Rows
              (S.Feature_Search_Results, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Search_Results_Query_History_Next =>
            Editor.Feature_Search_Results.Select_Next_Search_Query
              (S.Feature_Search_Results);
            Editor.Feature_Search_Results.Project_Rows
              (S.Feature_Search_Results, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Search_Results_Toggle_Case_Sensitive =>
            Editor.Feature_Search_Results.Toggle_Case_Sensitive
              (S.Feature_Search_Results);
            Editor.Feature_Search_Results.Project_Rows
              (S.Feature_Search_Results, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Show_Search_Results_Feature =>
            if not Editor.Feature_Panel_Controller.Show_Feature
              (S, Editor.Feature_Panel.Search_Results_Feature)
            then
               Report_Info
                 (S, Editor.Feature_Search_Results.Message_No_Search_Results);
               return No_Op (Id);
            end if;
            Report_Info
              (S, Editor.Feature_Search_Results.Message_Search_Results_Shown);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when Editor.Commands.Command_Clear_Search_Results_Feature =>
            if Editor.Feature_Search_Results.Row_Count
                 (S.Feature_Search_Results) = 0
              and then not Editor.Feature_Search_Results.Has_Query
                (S.Feature_Search_Results)
            then
               return No_Op (Id);
            end if;
            Editor.Feature_Search_Results.Clear (S.Feature_Search_Results);
            Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
              (S.Feature_Search_Results, S.Feature_Panel);
            Report_Info
              (S, Editor.Feature_Search_Results
                    .Message_Search_Results_Cleared);
            Editor.Render_Cache.Invalidate_All;
            return Executed (Id);

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Search_Results_Command;

   procedure Execute_Search_Results_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
      procedure Run (Id : Editor.Commands.Command_Id);

      procedure Run (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Execute_Search_Results_Command (S, Id);
         pragma Unreferenced (Result);
      begin
         null;
      end Run;
   begin
      case Kind is
         when Search_Results_Move_Up =>
            Execute_Search_Results_Move_Up (S);

         when Search_Results_Move_Down =>
            Execute_Search_Results_Move_Down (S);

         when Search_Results_Page_Up =>
            Execute_Search_Results_Page_Up (S);

         when Search_Results_Page_Down =>
            Execute_Search_Results_Page_Down (S);

         when Search_Results_Open_Selected =>
            Execute_Search_Results_Open_Selected (S);

         when Search_Results_Close_Or_Hide =>
            Execute_Search_Results_Close_Or_Hide (S);

         when Search_Results_Search_Active_Buffer =>
            Run (Command_Search_Results_Search_Active_Buffer);

         when Search_Results_Focus_Query =>
            Run (Command_Search_Results_Focus_Query);

         when Search_Results_Repeat_Active_Buffer =>
            Run (Command_Search_Results_Repeat_Active_Buffer);

         when Search_Results_Query_History_Previous =>
            Run (Command_Search_Results_Query_History_Previous);

         when Search_Results_Query_History_Next =>
            Run (Command_Search_Results_Query_History_Next);

         when Search_Results_Toggle_Case_Sensitive =>
            Run (Command_Search_Results_Toggle_Case_Sensitive);

         when Show_Search_Results_Feature =>
            Run (Command_Show_Search_Results_Feature);

         when Clear_Search_Results_Feature =>
            Run (Command_Clear_Search_Results_Feature);

         when others =>
            raise Program_Error with
              "unsupported search-results command kind";
      end case;
   end Execute_Search_Results_Kind;

   function Execute_Search_Result_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Mapped : constant Natural :=
        Editor.Feature_Search_Results.Map_Search_Result_Row_To_Item
          (S.Feature_Search_Results, S.Feature_Panel, Row,
           Expected_Panel_Generation);
      Target_Buffer : Natural := 0;
      Target_Line   : Natural := 0;
      Target_Column_One_Based : Natural := 0;
      Target_Row    : Natural;
      Target_Column : Natural;
   begin
      if Editor.State.Has_Pending_Quick_Fix_Workflow (S)
        and then Editor.Feature_Search_Results.External_Kind
          (S.Feature_Search_Results) =
            Editor.Feature_Search_Results.Diagnostic_Quick_Fix_Action_List
      then
         declare
            Payload : constant Editor.Feature_Search_Results
              .External_Result_Payload :=
                (if Mapped > 0
                 then Editor.Feature_Search_Results.Item_External_Payload
                   (S.Feature_Search_Results, Positive (Mapped))
                 else Editor.Feature_Search_Results.No_External_Payload);
            Payload_Action_Index : constant Natural :=
              (case Payload.Kind is
                 when Editor.Feature_Search_Results.Quick_Fix_Action_Payload =>
                   Payload.Action_Index,
                 when Editor.Feature_Search_Results.No_External_Result_Payload =>
                   0);
            Action_Index : constant Natural :=
              (if Mapped > 0
               then (if Payload_Action_Index > 0
                     then Payload_Action_Index
                     else Mapped)
               elsif Row >= 1
                 and then Row <= Editor.Feature_Search_Results.Row_Count
                   (S.Feature_Search_Results)
               then Row
               else 0);
         begin
            if Action_Index > 0 then
               Editor.Feature_Panel.Select_Row (S.Feature_Panel, Row);
               Editor.State.Start_Quick_Fix_Workflow
                 (S,
                  Editor.State.Pending_Quick_Fix_Diagnostic_Index (S),
                  Action_Index);
               return Editor.Executor.Execute_Command_With_Result
                 (S, Editor.Commands.Command_Diagnostic_Apply_Quick_Fix);
            end if;
         end;
      end if;

      if Row = 0
        or else Mapped = 0
        or else not Editor.Feature_Panel.Row_Is_Activatable
          (S.Feature_Panel, Positive (Row))
      then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      if Editor.Feature_Search_Results.Results_Stale (S.Feature_Search_Results)
      then
         Report_Info (S, Editor.Feature_Search_Results.Message_Stale_Result);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      Target_Buffer := Editor.Feature_Search_Results.Item_Target_Buffer
        (S.Feature_Search_Results, Positive (Mapped));
      Target_Line := Editor.Feature_Search_Results.Item_Target_Line
        (S.Feature_Search_Results, Positive (Mapped));
      Target_Column_One_Based :=
        Editor.Feature_Search_Results.Item_Target_Column
          (S.Feature_Search_Results, Positive (Mapped));

      if not Editor.Feature_Search_Results.Validate_Search_Result_Target
          (S.Feature_Search_Results, Positive (Mapped), Target_Buffer)
        or else not Feature_Target_Position_Is_Valid
          (S, Target_Buffer, Target_Line, Target_Column_One_Based)
      then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      if not Focus_Feature_Target_Buffer (S, Target_Buffer) then
         Report_Target_Unavailable (S);
         Editor.Render_Cache.Invalidate_All;
         return No_Op (Editor.Commands.Command_Feature_Panel_Open_Selected);
      end if;

      Target_Row := Natural'Min
        (Target_Line - 1, Natural'Max (Editor.State.Line_Count (S), 1) - 1);
      Target_Column := Target_Column_One_Based - 1;
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Row);
      Apply_Feature_Target_Handoff (S, Target_Row, Target_Column);
      Editor.Render_Cache.Invalidate_All;
      return Executed (Editor.Commands.Command_Feature_Panel_Open_Selected);
   end Execute_Search_Result_Row_Activation;

end Editor.Executor.Search_Results_Commands;
