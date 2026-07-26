with Editor.Commands.Payloads;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Diagnostic_Action_Execution;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Clipboard;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Commands.Workflow_Messages;
with Editor.Executor.Diagnostics_Navigation_Commands;
with Editor.Executor.History;
with Editor.Executor.Shared_Services;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Folding;
with Editor.Focus_Management;
with Editor.Layout;
with Editor.Navigation;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Problems;
with Editor.Render_Cache;
with Editor.State;
with Editor.View;

package body Editor.Executor.Diagnostics_Action_Commands is

   use Editor.Commands;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Execution_Effect;
   use type Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Execution_Status;
   use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Feature_Diagnostics.Diagnostic_Id;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Panel_Focus.Bottom_Focus_Content;

   function Result_After_Command
     (Command : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result is
   begin
      return Editor.Command_Execution.Executed (Command);
   end Result_After_Command;

   function Diagnostic_Action_Effect_Label
     (Effect : Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Execution_Effect)
      return String
   is
   begin
      case Effect is
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_Navigate =>
            return "navigate";
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_Explain =>
            return "explain";
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_Edit =>
            return "edit";
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_Review_Expression =>
            return "review expression";
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_Review_Overload_Ranking =>
            return "review overload ranking";
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_Review_Generic =>
            return "review generic";
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_Review_Cross_Unit =>
            return "review cross-unit";
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_Review_Representation =>
            return "review representation";
         when Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Effect_None =>
            return "none";
      end case;
   end Diagnostic_Action_Effect_Label;

   function Execute_Diagnostics_Action_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      package Action_Execution renames Editor.Ada_Diagnostic_Action_Execution;
      package Action_Commands renames Editor.Ada_Diagnostic_Command_Projection;

      Row : constant Natural := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
      Selected_Item_Index : constant Natural :=
        Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
          (S.Feature_Diagnostics, S.Feature_Panel, Row,
           Editor.Feature_Panel.Projection_Generation (S.Feature_Panel));
      Item_Index : constant Natural :=
        (if Id = Command_Diagnostic_Apply_Quick_Fix
           and then Editor.State.Has_Pending_Quick_Fix_Workflow (S)
         then Editor.State.Pending_Quick_Fix_Diagnostic_Index (S)
         else Selected_Item_Index);
      Action_Index : constant Natural :=
        (if Id = Command_Diagnostic_Apply_Quick_Fix
           and then Editor.State.Pending_Quick_Fix_Action_Index (S) > 0
         then Editor.State.Pending_Quick_Fix_Action_Index (S)
         else 1);
   begin
      if Item_Index = 0 then
         Shared_Services.Report_Info (S, Editor.Feature_Diagnostics.Message_No_Selected_Diagnostic);
         Editor.State.Clear_Quick_Fix_Workflow (S);
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.No_Op (Id);
      end if;

      if Id = Command_Diagnostic_Apply_Quick_Fix
        and then
          Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
            (S.Feature_Diagnostics, Positive (Item_Index)) > 1
        and then Editor.State.Pending_Quick_Fix_Action_Index (S) = 0
      then
         declare
            Added_Actions : Natural := 0;
            First_Unavailable_Reason : Unbounded_String :=
              Null_Unbounded_String;
         begin
            Editor.State.Start_Quick_Fix_Workflow (S, Item_Index);
            Editor.Feature_Search_Results.Begin_External_Result_Set
              (S.Feature_Search_Results,
               Query        =>
                 Editor.Feature_Diagnostics.Diagnostic_Quick_Fix_Picker_Query_Text,
               Source_Label => "Diagnostics",
               Kind         =>
                 Editor.Feature_Search_Results.Diagnostic_Quick_Fix_Action_List);
            for Action_Index in 1 ..
              Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
                (S.Feature_Diagnostics, Positive (Item_Index))
            loop
               declare
                  Availability : constant Editor.Commands.Command_Availability :=
                    Editor.Executor.Diagnostic_Quick_Fix_Action_Availability
                      (S, Item_Index, Action_Index);
               begin
                  if Editor.Commands.Is_Available (Availability) then
                     Added_Actions := Added_Actions + 1;
                     Editor.Feature_Search_Results.Add_Search_Result
                       (S.Feature_Search_Results,
                        Label         =>
                          Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Label_For_Display
                            (S.Feature_Diagnostics, Positive (Item_Index), Action_Index),
                        Source_Label  =>
                          Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Detail_For_Display
                            (S.Feature_Diagnostics, Positive (Item_Index), Action_Index),
                        Has_Target    => False,
                        Target_Buffer => 0,
                        Target_Line   => 0,
                        Target_Column => 0,
                        Query         => "diagnostic quick fix",
                        Match_Line    => 0,
                        Match_Column  => 0,
                        Match_Length  => 0,
                        External_Payload =>
                          Editor.Feature_Search_Results
                            .Quick_Fix_Action_Result_Payload
                              (Action_Index));
                  elsif Length (First_Unavailable_Reason) = 0 then
                     First_Unavailable_Reason :=
                       To_Unbounded_String
                         (Editor.Commands.Unavailable_Reason (Availability));
                  end if;
               end;
            end loop;
            if Added_Actions = 0 then
               Editor.State.Clear_Quick_Fix_Workflow (S);
               Shared_Services.Report_Info
                 (S,
                  (if Length (First_Unavailable_Reason) > 0
                   then To_String (First_Unavailable_Reason)
                   else "No available diagnostic quick fixes"));
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end if;
            Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
              (S.Feature_Search_Results, S.Feature_Panel,
               Select_First_When_Available => True);
            Editor.Panels.Set_Bottom_Content
              (S.Panels, Editor.Panels.Search_Results_Content);
            Editor.Panels.Set_Visible
              (S.Panels, Editor.Panels.Bottom_Panel, True);
            Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
            Shared_Services.Report_Info
              (S, "Choose a diagnostic quick fix");
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);
         end;
      end if;

      if Id = Command_Diagnostic_Apply_Quick_Fix then
         declare
            Availability : constant Editor.Commands.Command_Availability :=
              Editor.Executor.Diagnostic_Quick_Fix_Action_Availability
                (S, Item_Index, Action_Index);
         begin
            if not Editor.Commands.Is_Available (Availability) then
               Shared_Services.Report_Info
                 (S, Editor.Commands.Unavailable_Reason (Availability));
               Editor.State.Clear_Quick_Fix_Workflow (S);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end if;
         end;
      end if;

      declare
         Descriptor : Action_Commands.Diagnostic_Command_Descriptor;
         Action_Result : Action_Execution.Diagnostic_Action_Execution_Result;
      begin
         Descriptor.Id :=
           Action_Commands.Diagnostic_Command_Descriptor_Id
             (Natural
                (Editor.Feature_Diagnostics.Item_Id
                   (S.Feature_Diagnostics, Positive (Item_Index))));
         Descriptor.Command_Kind :=
           (if Id = Command_Diagnostic_Apply_Quick_Fix
            then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Kind
              (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index))
            else Editor.Feature_Diagnostics.Item_Primary_Action_Kind
              (S.Feature_Diagnostics, Positive (Item_Index)));
         Descriptor.Availability :=
           (if Editor.Feature_Diagnostics.Item_Is_Stale
                 (S.Feature_Diagnostics, Positive (Item_Index))
            then Action_Commands.Diagnostic_Command_Rejected_Stale
            elsif Editor.Feature_Diagnostics.Item_Has_Target
                 (S.Feature_Diagnostics, Positive (Item_Index))
              and then Descriptor.Command_Kind /=
                Action_Commands.Diagnostic_Command_None
            then Action_Commands.Diagnostic_Command_Available
            else Action_Commands.Diagnostic_Command_Missing_Target);
         declare
            Quick_Fix_Label : constant String :=
              Editor.Feature_Diagnostics.Item_Quick_Fix_Label_For_Display
                (S.Feature_Diagnostics, Positive (Item_Index));
            Quick_Fix_Detail : constant String :=
              (if Action_Index = 1
               then Editor.Feature_Diagnostics.Item_Quick_Fix_Detail_For_Display
                 (S.Feature_Diagnostics, Positive (Item_Index))
               else Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Detail_For_Display
                 (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index)));
            Effective_Quick_Fix_Label : constant String :=
              (if Action_Index = 1
               then Quick_Fix_Label
               else Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Label_For_Display
                 (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index)));
         begin
            Descriptor.Display_Label :=
              To_Unbounded_String
                (if Id = Command_Diagnostic_Apply_Quick_Fix
                 then Effective_Quick_Fix_Label
                 else "Diagnostic action: " &
                   Editor.Feature_Diagnostics.Item_Display_Label
                     (S.Feature_Diagnostics, Positive (Item_Index)));
            Descriptor.Detail :=
              To_Unbounded_String
                (if Id = Command_Diagnostic_Apply_Quick_Fix
                 then Quick_Fix_Detail
                 else Editor.Feature_Diagnostics.Item_Source_Display_Label
                   (S.Feature_Diagnostics, Positive (Item_Index)));
         end;
         Descriptor.Has_Edit :=
           (if Id = Command_Diagnostic_Apply_Quick_Fix
            then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Has_Edit
              (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index))
            else Editor.Feature_Diagnostics.Item_Has_Edit
              (S.Feature_Diagnostics, Positive (Item_Index)));
         if Descriptor.Has_Edit then
            Descriptor.Edit_Start_Line :=
              Positive'Max
                (1, Positive
                  ((if Id = Command_Diagnostic_Apply_Quick_Fix
                    then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Edit_Start_Line
                      (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index))
                    else Editor.Feature_Diagnostics.Item_Edit_Start_Line
                      (S.Feature_Diagnostics, Positive (Item_Index)))));
            Descriptor.Edit_Start_Column :=
              Positive'Max
                (1, Positive
                  ((if Id = Command_Diagnostic_Apply_Quick_Fix
                    then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Edit_Start_Column
                      (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index))
                    else Editor.Feature_Diagnostics.Item_Edit_Start_Column
                      (S.Feature_Diagnostics, Positive (Item_Index)))));
            Descriptor.Edit_End_Line :=
              Positive'Max
                (1, Positive
                  ((if Id = Command_Diagnostic_Apply_Quick_Fix
                    then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Edit_End_Line
                      (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index))
                    else Editor.Feature_Diagnostics.Item_Edit_End_Line
                      (S.Feature_Diagnostics, Positive (Item_Index)))));
            Descriptor.Edit_End_Column :=
              Positive'Max
                (1, Positive
                  ((if Id = Command_Diagnostic_Apply_Quick_Fix
                    then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Edit_End_Column
                      (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index))
                    else Editor.Feature_Diagnostics.Item_Edit_End_Column
                      (S.Feature_Diagnostics, Positive (Item_Index)))));
            Descriptor.Replacement_Text :=
              To_Unbounded_String
                ((if Id = Command_Diagnostic_Apply_Quick_Fix
                  then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Replacement_Text
                    (S.Feature_Diagnostics, Positive (Item_Index), Positive (Action_Index))
                  else Editor.Feature_Diagnostics.Item_Replacement_Text
                    (S.Feature_Diagnostics, Positive (Item_Index))));
         end if;
         Descriptor.Start_Line :=
           Positive'Max
             (1, Positive
               (Natural'Max
                  (1, Editor.Feature_Diagnostics.Item_Target_Line
                    (S.Feature_Diagnostics, Positive (Item_Index)))));
         Descriptor.Start_Column :=
           Positive'Max
             (1, Positive
               (Natural'Max
                  (1, Editor.Feature_Diagnostics.Item_Target_Column
                    (S.Feature_Diagnostics, Positive (Item_Index)))));
         Descriptor.End_Line := Descriptor.Start_Line;
         Descriptor.End_Column := Descriptor.Start_Column;

         if Id = Command_Diagnostic_Apply_Quick_Fix then
            Editor.State.Clear_Quick_Fix_Workflow (S);
         end if;

         Action_Result := Action_Execution.Execute (Descriptor);
         if Action_Result.Status =
           Action_Execution.Diagnostic_Action_Execution_Rejected_Stale
         then
            Shared_Services.Report_Info (S, To_String (Action_Result.Message));
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Unavailable (Id);
         elsif not Action_Execution.Is_Success (Action_Result) then
            Shared_Services.Report_Info (S, To_String (Action_Result.Message));
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.Unavailable (Id);
         elsif Action_Result.Effect =
           Action_Execution.Diagnostic_Action_Effect_Navigate
         then
            declare
               Activation : Editor.Command_Execution.Command_Execution_Result :=
                 Editor.Executor.Diagnostics_Navigation_Commands.Execute_Diagnostic_Row_Activation
                   (S, Row,
                    Editor.Feature_Panel.Projection_Generation (S.Feature_Panel));
            begin
               if Activation.Status = Editor.Command_Execution.Command_Executed then
                  return Result_After_Command (Id);
               end if;
               return Editor.Command_Execution.No_Op (Id);
            end;
         elsif Action_Result.Effect =
           Action_Execution.Diagnostic_Action_Effect_Edit
         then
            declare
               Target_Buffer : constant Natural :=
                 Editor.Feature_Diagnostics.Item_Target_Buffer
                   (S.Feature_Diagnostics, Positive (Item_Index));
               Active_Buffer : constant Natural :=
                 Editor.Executor.Active_Feature_Buffer_Token (S);
               Replacement : constant Unbounded_String :=
                 Action_Result.Replacement_Text;
               Delete_Count : Natural := 0;
               Pos : Natural := 0;
               End_Pos : Natural := 0;
               Cmd : Editor.Commands.Payloads.Command;
               Before : Editor.State.State_Type;
               Before_Text : Unbounded_String;
               Target_State : Editor.State.State_Type;
               Target_Id : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Buffer_Id (Target_Buffer);
               Replaced : Boolean := False;
            begin
               Editor.Buffers.Ensure_Global_Registry (S);

               if Target_Buffer = Active_Buffer then
                  Target_State := S;
               elsif Target_Buffer /= 0
                 and then Editor.Buffers.Global_Contains (Target_Id)
               then
                  Target_State := Editor.Buffers.Global_Buffer
                    (Target_Id);
               else
                  Shared_Services.Report_Info
                    (S, "Diagnostic edit unavailable: target buffer is not open");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Unavailable (Id);
               end if;

               if Action_Result.Edit_Start_Line = 0
                 or else Action_Result.Edit_Start_Column = 0
                 or else Action_Result.Edit_End_Line = 0
                 or else Action_Result.Edit_End_Column = 0
                 or else Natural (Action_Result.Edit_Start_Line) >
                   Editor.State.Line_Count (Target_State)
                 or else Natural (Action_Result.Edit_End_Line) >
                   Editor.State.Line_Count (Target_State)
                 or else
                   Natural (Action_Result.Edit_Start_Column) - 1 >
                     Editor.Navigation.Line_Length
                       (Target_State,
                        Natural (Action_Result.Edit_Start_Line) - 1)
                 or else
                   Natural (Action_Result.Edit_End_Column) - 1 >
                     Editor.Navigation.Line_Length
                       (Target_State,
                        Natural (Action_Result.Edit_End_Line) - 1)
               then
                  Shared_Services.Report_Info
                    (S, Editor.Commands.Workflow_Messages.Reason_Diagnostic_Edit_Stale_Target);
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Unavailable (Id);
               end if;

               Pos :=
                 Editor.Navigation.Index_For_Line_Column
                   (Target_State,
                    Natural (Action_Result.Edit_Start_Line) - 1,
                    Natural (Action_Result.Edit_Start_Column) - 1);
               End_Pos :=
                 Editor.Navigation.Index_For_Line_Column
                   (Target_State,
                    Natural (Action_Result.Edit_End_Line) - 1,
                    Natural (Action_Result.Edit_End_Column) - 1);
               if End_Pos < Pos then
                  Shared_Services.Report_Info
                    (S, Editor.Commands.Workflow_Messages.Reason_Diagnostic_Edit_Stale_Target);
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Unavailable (Id);
               end if;
               Delete_Count := End_Pos - Pos;
               Cmd.Kind := Editor.Commands.Apply_Replace_Batch;
               Editor.Executor.Append_Replace_Op
                 (Cmd, Cursor_Index (Pos), Delete_Count, Replacement);

               if Target_Buffer = Active_Buffer then
                  Before := S;
                  Before_Text :=
                    To_Unbounded_String
                      (Editor.State.Current_Text (S));
                  Editor.Executor.History.Apply_Replace_Batch_Command
                    (S, Cmd);
                  if Editor.State.Current_Text (S) /=
                    To_String (Before_Text)
                  then
                     Editor.State.Load_Text
                       (Before, To_String (Before_Text));
                     Editor.Executor.History.Log_Edit
                       (Before, S, Cmd);
                     Editor.Buffers.Sync_Global_Active_From_State (S);
                     Editor.Ada_Project_Index.Invalidate_Buffer
                       (S.Language_Index, Target_Buffer);
                     Editor.Ada_Language_Service.Invalidate_Buffer
                       (S.Language_Service, Target_Buffer);
                  end if;
               else
                  Before_Text :=
                    To_Unbounded_String
                      (Editor.State.Current_Text (Target_State));
                  Editor.Executor.History.Apply_Replace_Batch_Command
                    (Target_State, Cmd);
                  if Editor.State.Current_Text (Target_State) /=
                    To_String (Before_Text)
                  then
                     Editor.Buffers.Global_Replace_Buffer_Contents
                       (Target_Id,
                        Editor.State.Current_Text (Target_State),
                        Replaced);
                     if Replaced then
                        Editor.Ada_Project_Index.Invalidate_Buffer
                          (S.Language_Index, Target_Buffer);
                        Editor.Ada_Language_Service.Invalidate_Buffer
                          (S.Language_Service, Target_Buffer);
                     end if;
                  end if;
               end if;

               if Target_Buffer = Active_Buffer then
                  Shared_Services.Report_Info (S, To_String (Action_Result.Message));
               else
                  Shared_Services.Report_Info
                    (S, To_String (Action_Result.Message) & " in " &
                     Editor.Feature_Diagnostics.Item_Source_Display_Label
                       (S.Feature_Diagnostics, Positive (Item_Index)) &
                     "; use Open Buffer Switcher to open the changed buffer");
               end if;
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;
         else
            declare
               Match_Length : constant Natural :=
                 (if Action_Result.End_Line = Action_Result.Start_Line
                    and then Action_Result.End_Column >=
                      Action_Result.Start_Column
                  then Natural (Action_Result.End_Column) -
                    Natural (Action_Result.Start_Column) + 1
                  else 1);
            begin
               Editor.Feature_Search_Results.Begin_External_Result_Set
                 (S.Feature_Search_Results,
                  Query        => "diagnostic action: " &
                    Diagnostic_Action_Effect_Label (Action_Result.Effect),
                  Source_Label => "Ada diagnostic action");
               Editor.Feature_Search_Results.Add_Search_Result
                 (S.Feature_Search_Results,
                  Label         => To_String (Action_Result.Message),
                  Source_Label  => To_String (Descriptor.Detail),
                  Has_Target    => Editor.Feature_Diagnostics.Item_Has_Target
                    (S.Feature_Diagnostics, Positive (Item_Index)),
                  Target_Buffer => Editor.Feature_Diagnostics.Item_Target_Buffer
                    (S.Feature_Diagnostics, Positive (Item_Index)),
                  Target_Line   => Action_Result.Start_Line,
                  Target_Column => Action_Result.Start_Column,
                  Query         => Diagnostic_Action_Effect_Label
                    (Action_Result.Effect),
                  Match_Line    => Action_Result.Start_Line,
                  Match_Column  => Action_Result.Start_Column,
                  Match_Length  => Match_Length);
               Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
                 (S.Feature_Search_Results, S.Feature_Panel,
                  Select_First_When_Available => True);
               Editor.Panels.Set_Bottom_Content
                 (S.Panels, Editor.Panels.Search_Results_Content);
               Editor.Panels.Set_Visible
                 (S.Panels, Editor.Panels.Bottom_Panel, True);
               if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
                  Editor.Focus_Management.Set_Focus_Owner
                    (S, Editor.Focus_Management.Focus_Project_Search_Results);
               end if;
               Editor.Panels.Set_Current (S.Panels);
               Shared_Services.Report_Info (S, To_String (Action_Result.Message));
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;
         end if;
      end;
   end Execute_Diagnostics_Action_Command;

end Editor.Executor.Diagnostics_Action_Commands;
