with Editor.Commands.Availability_Metadata;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with Editor.Ada_Diagnostic_Action_Execution;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Clipboard;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Commands.Workflow_Messages;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Diagnostics_Navigation_Commands;
with Editor.Executor.Diagnostics_Problems_Commands;
with Editor.Executor.Diagnostics_Action_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Diagnostics;
use type Editor.Diagnostics.Diagnostic_Index;
with Editor.Executor.History;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Focus_Management;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Problems;
with Editor.Render_Cache;
with Editor.State;
with Editor.Executor.Diagnostics_Suppressed_Commands;

package body Editor.Executor.Diagnostics_Feature_Commands is

   use Ada.Strings.Unbounded;
   use Editor.Commands;
   use Editor.Cursors;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Execution_Effect;
   use type Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Execution_Status;
   use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Feature_Diagnostics.Diagnostic_Id;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Panel_Focus.Bottom_Focus_Content;

   function Problems_Has_Focus
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
        Editor.Panel_Focus.Problems_Focus;
   end Problems_Has_Focus;

   function Diagnostics_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability
   is
   begin
      case Id is
         when Command_Next_Diagnostic
            | Command_Previous_Diagnostic =>
            if Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Problems_Move_Up
            | Command_Problems_Move_Down
            | Command_Problems_Page_Up
            | Command_Problems_Page_Down =>
            if Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Problems_Has_Focus (S) then
               return Editor.Commands.Availability_Metadata.Unavailable ("Command not available here");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Problems_Open_Selected =>
            if Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No problems");
            elsif not Problems_Has_Focus (S) then
               return Editor.Commands.Availability_Metadata.Unavailable ("Command not available here");
            elsif Editor.Problems.Selected_Row_Index (S.Problems_View) = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostic selected");
            end if;
            declare
               Snapshot : constant Editor.Problems.Problems_Snapshot :=
                 Editor.Problems.Filtered_Snapshot
                   (Editor.Problems.Build_Snapshot (S.Diagnostics),
                    S.Problems_View);
               Selected : constant Natural :=
                 Editor.Problems.Selected_Row_Index (S.Problems_View);
               Row : Editor.Problems.Problem_Row;
            begin
               if Selected = 0
                 or else Selected > Editor.Problems.Row_Count (Snapshot)
               then
                  return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostic selected");
               end if;

               Row := Editor.Problems.Row (Snapshot, Positive (Selected));
               if not Editor.Problems.Row_Has_Target (Row) then
                  return Editor.Commands.Availability_Metadata.Unavailable
                    (Editor.Problems.Row_Target_Unavailable_Label (Row));
               end if;
            end;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Problems_Filter_All
            | Command_Problems_Filter_Errors
            | Command_Problems_Filter_Warnings
            | Command_Problems_Filter_Info
            | Command_Problems_Filter_Hints
            | Command_Problems_Sort_By_Location
            | Command_Problems_Sort_By_Severity
            | Command_Problems_Sort_By_Source
            | Command_Problems_Group_By_Severity
            | Command_Problems_Group_By_Source
            | Command_Diagnostics_Show
            | Command_Diagnostics_Toggle_Info
            | Command_Diagnostics_Toggle_Warnings
            | Command_Diagnostics_Toggle_Errors
            | Command_Diagnostics_Show_All
            | Command_Diagnostics_Toggle_Editor_Source
            | Command_Diagnostics_Toggle_File_Source
            | Command_Diagnostics_Toggle_Project_Source
            | Command_Diagnostics_Toggle_External_Source
            | Command_Diagnostics_Toggle_Unknown_Source
            | Command_Diagnostics_Clear =>
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Open_Selected
            | Command_Diagnostic_Open_Source
            | Command_Diagnostics_Execute_Selected_Action
            | Command_Diagnostic_Apply_Quick_Fix =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif Id = Command_Diagnostic_Apply_Quick_Fix
              and then Editor.State.Has_Pending_Quick_Fix_Workflow (S)
            then
               declare
                  Mapped : constant Natural :=
                    Editor.State.Pending_Quick_Fix_Diagnostic_Index (S);
                  Action_Index : constant Natural :=
                    (if Editor.State.Pending_Quick_Fix_Action_Index (S) > 0
                     then Editor.State.Pending_Quick_Fix_Action_Index (S)
                     else 1);
               begin
                  return Editor.Executor.Diagnostic_Quick_Fix_Action_Availability
                    (S, Mapped, Action_Index);
               end;
            elsif not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostic selected");
            elsif not Editor.Feature_Diagnostics.Selected_Diagnostic_Has_Target
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Availability_Metadata.Unavailable
                 (Editor.Feature_Diagnostics.Selected_Diagnostic_Open_Unavailable_Reason
                    (S.Feature_Diagnostics, S.Feature_Panel));
            else
               declare
                  Diagnostic_Id : constant Editor.Feature_Diagnostics.Diagnostic_Id :=
                    Editor.Feature_Diagnostics.Selected_Diagnostic_Id
                      (S.Feature_Diagnostics, S.Feature_Panel);
                  Mapped : constant Natural :=
                    Editor.Feature_Diagnostics.Map_Diagnostic_Id_To_Item
                      (S.Feature_Diagnostics, Diagnostic_Id);
                  Target_Buffer : constant Natural :=
                    (if Mapped = 0 then 0 else
                       Editor.Feature_Diagnostics.Item_Target_Buffer
                         (S.Feature_Diagnostics, Positive (Mapped)));
                  Target_Line : constant Natural :=
                    (if Mapped = 0 then 0 else
                       Editor.Feature_Diagnostics.Item_Target_Line
                         (S.Feature_Diagnostics, Positive (Mapped)));
                  Target_Column : constant Natural :=
                    (if Mapped = 0 then 0 else
                       Natural'Max
                         (1, Editor.Feature_Diagnostics.Item_Target_Column
                               (S.Feature_Diagnostics, Positive (Mapped))));
               begin
                  if Mapped = 0 then
                     return Editor.Commands.Availability_Metadata.Unavailable
                       (Editor.Executor.Diagnostic_Availability_Reason
                          (S, Mapped, Target_Buffer, Target_Line, Target_Column));
                  elsif Editor.Feature_Diagnostics.Item_Is_Stale
                    (S.Feature_Diagnostics, Positive (Mapped))
                  then
                     return Editor.Commands.Availability_Metadata.Unavailable
                       (Editor.Commands.Workflow_Messages.Reason_Target_Stale);
                  elsif not Editor.Feature_Diagnostics.Validate_Diagnostic_Target
                      (S.Feature_Diagnostics, Positive (Mapped), Target_Buffer)
                    or else not Editor.Executor.Feature_Target_Position_Is_Valid
                      (S, Target_Buffer, Target_Line, Target_Column)
                  then
                     return Editor.Commands.Availability_Metadata.Unavailable
                       (Editor.Executor.Diagnostic_Availability_Reason
                          (S, Mapped, Target_Buffer, Target_Line, Target_Column));
                  elsif (Id = Command_Diagnostics_Execute_Selected_Action
                         or else Id = Command_Diagnostic_Apply_Quick_Fix)
                    and then Editor.Feature_Diagnostics.Item_Primary_Action_Kind
                      (S.Feature_Diagnostics, Positive (Mapped)) =
                        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None
                  then
                     return Editor.Commands.Availability_Metadata.Unavailable
                       ("Diagnostic action unavailable");
                  elsif (Id = Command_Diagnostics_Execute_Selected_Action
                         or else Id = Command_Diagnostic_Apply_Quick_Fix)
                    and then Editor.Feature_Diagnostics.Item_Has_Edit
                      (S.Feature_Diagnostics, Positive (Mapped))
                    and then
                      (not Editor.Executor.Feature_Target_Position_Is_Valid
                         (S, Target_Buffer,
                          Editor.Feature_Diagnostics.Item_Edit_Start_Line
                            (S.Feature_Diagnostics, Positive (Mapped)),
                          Editor.Feature_Diagnostics.Item_Edit_Start_Column
                            (S.Feature_Diagnostics, Positive (Mapped)))
                       or else not Editor.Executor.Feature_Target_Position_Is_Valid
                         (S, Target_Buffer,
                          Editor.Feature_Diagnostics.Item_Edit_End_Line
                            (S.Feature_Diagnostics, Positive (Mapped)),
                          Editor.Feature_Diagnostics.Item_Edit_End_Column
                            (S.Feature_Diagnostics, Positive (Mapped))))
                  then
                     return Editor.Commands.Availability_Metadata.Unavailable
                       (Editor.Commands.Workflow_Messages.Reason_Diagnostic_Edit_Stale_Target);
                  end if;
               end;
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostic_Suppress_Selected
            | Command_Diagnostic_Show_Suppressed
            | Command_Diagnostic_Restore_Last_Suppressed
            | Command_Diagnostic_Restore_Selected_Suppressed
            | Command_Diagnostic_Clear_Suppressed =>
            return Editor.Executor.Diagnostics_Suppressed_Commands
              .Diagnostics_Suppressed_Command_Availability (S, Id);

         when Command_Diagnostics_Clear_Selected
            | Command_Diagnostics_Copy_Selected_Text =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostic selected");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Select_Next
            | Command_Diagnostics_Select_Previous =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Visible_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No visible diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Clear_Info =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Info_Or_Note_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Availability_Metadata.Unavailable
                 ("No info or note diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Clear_Warnings =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Diagnostic_With_Severity
              (S.Feature_Diagnostics,
               Editor.Feature_Diagnostics.Diagnostic_Warning)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No warning diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Clear_Errors =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Diagnostic_With_Severity
              (S.Feature_Diagnostics,
               Editor.Feature_Diagnostics.Diagnostic_Error)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No error diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Clear_Filter =>
            if not Editor.Feature_Diagnostics.Filter_Active
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No filter is active");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Filter_Errors
            | Command_Diagnostics_Filter_Warnings
            | Command_Diagnostics_Filter_Info_Notes =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Filter_Build =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Build_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No build diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Filter_Source =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Visible_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No visible diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostic selected");
            elsif Editor.Feature_Diagnostics.Selected_Diagnostic_Source_Filter_Label
              (S.Feature_Diagnostics, S.Feature_Panel)'Length = 0
            then
               return Editor.Commands.Availability_Metadata.Unavailable
                 ("Selected diagnostic has no source label");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostics_Clear_Build =>
            if not Editor.Feature_Diagnostics.Has_Build_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No build diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when others =>
            return Editor.Commands.Availability_Metadata.Unavailable
              ("Command is not a diagnostics command");
      end case;
   end Diagnostics_Command_Availability;

   procedure Report_Target_Unavailable
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Info (S, "Navigation target unavailable.");
   end Report_Target_Unavailable;

   procedure Report_No_Selection
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Info (S, "No selection");
   end Report_No_Selection;

   function Feature_Target_Buffer_Is_Current
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean
   is
   begin
      return Target_Buffer /= 0
        and then Target_Buffer = Editor.Executor.Active_Feature_Buffer_Token (S);
   end Feature_Target_Buffer_Is_Current;

   function Feature_Target_Buffer_Exists
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural) return Boolean
   is
   begin
      if Feature_Target_Buffer_Is_Current (S, Target_Buffer) then
         return True;
      elsif Target_Buffer = 0 then
         return False;
      else
         return Editor.Buffers.Global_Contains
           (Editor.Buffers.Buffer_Id (Target_Buffer));
      end if;
   end Feature_Target_Buffer_Exists;

   function Feature_Target_Line_Count
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural) return Natural
   is
      Target_State : Editor.State.State_Type;
   begin
      if Target_Buffer = 0 then
         return 0;
      elsif Feature_Target_Buffer_Is_Current (S, Target_Buffer) then
         Target_State := S;
      elsif Editor.Buffers.Global_Contains
        (Editor.Buffers.Buffer_Id (Target_Buffer))
      then
         Target_State := Editor.Buffers.Buffer
           (Editor.Buffers.Global_Registry_For_UI,
            Editor.Buffers.Buffer_Id (Target_Buffer));
      else
         return 0;
      end if;

      return Editor.State.Line_Count (Target_State);
   end Feature_Target_Line_Count;

   function Feature_Target_Line_Length
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural) return Natural
   is
      Target_State : Editor.State.State_Type;
   begin
      if Target_Buffer = 0 or else Line = 0 then
         return 0;
      elsif Feature_Target_Buffer_Is_Current (S, Target_Buffer) then
         Target_State := S;
      elsif Editor.Buffers.Global_Contains
        (Editor.Buffers.Buffer_Id (Target_Buffer))
      then
         Target_State := Editor.Buffers.Buffer
           (Editor.Buffers.Global_Registry_For_UI,
            Editor.Buffers.Buffer_Id (Target_Buffer));
      else
         return 0;
      end if;

      if Line > Editor.State.Line_Count (Target_State) then
         return 0;
      end if;

      return Editor.Navigation.Line_Length (Target_State, Line - 1);
   end Feature_Target_Line_Length;

   function Diagnostic_Target_Failure_Label
     (S             : Editor.State.State_Type;
      Mapped        : Natural;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return String
   is
      Line_Count : constant Natural :=
        Feature_Target_Line_Count (S, Target_Buffer);
   begin
      if Mapped = 0 then
         return "Selected diagnostic is no longer available.";
      elsif not Editor.Feature_Diagnostics.Item_Has_Target
        (S.Feature_Diagnostics, Positive (Mapped))
      then
         return "Selected diagnostic has no source target.";
      elsif Target_Buffer = 0
        or else not Feature_Target_Buffer_Exists (S, Target_Buffer)
      then
         return Editor.Commands.Workflow_Messages.Reason_Target_Missing;
      elsif Line = 0 then
         return Editor.Commands.Workflow_Messages.Reason_Diagnostic_Target_Line_Unavailable;
      elsif Line_Count = 0 or else Line > Line_Count then
         if Editor.Feature_Diagnostics.Item_Is_Stale
           (S.Feature_Diagnostics, Positive (Mapped))
         then
            return Editor.Commands.Workflow_Messages.Reason_Target_Stale;
         else
            return Editor.Commands.Workflow_Messages.Reason_Diagnostic_Target_Line_Outside_Buffer
              & ".";
         end if;
      elsif Column = 0 then
         return Editor.Commands.Workflow_Messages.Reason_Diagnostic_Target_Column_Unavailable;
      elsif Column - 1 > Feature_Target_Line_Length (S, Target_Buffer, Line) then
         if Editor.Feature_Diagnostics.Item_Is_Stale
           (S.Feature_Diagnostics, Positive (Mapped))
         then
            return Editor.Commands.Workflow_Messages.Reason_Target_Stale;
         else
            return Editor.Commands.Workflow_Messages.Reason_Diagnostic_Target_Column_Outside_Line
              & ".";
         end if;
      else
         return "Navigation target unavailable.";
      end if;
   end Diagnostic_Target_Failure_Label;

   function Feature_Target_Position_Is_Valid
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return Boolean
   is
      Target_State : Editor.State.State_Type;
   begin
      if Target_Buffer = 0 or else Line = 0 or else Column = 0 then
         return False;
      elsif Feature_Target_Buffer_Is_Current (S, Target_Buffer) then
         Target_State := S;
      elsif Editor.Buffers.Global_Contains
        (Editor.Buffers.Buffer_Id (Target_Buffer))
      then
         Target_State := Editor.Buffers.Buffer
           (Editor.Buffers.Global_Registry_For_UI,
            Editor.Buffers.Buffer_Id (Target_Buffer));
      else
         return False;
      end if;

      return Line <= Editor.State.Line_Count (Target_State)
        and then Column - 1 <= Editor.Navigation.Line_Length
          (Target_State, Line - 1);
   end Feature_Target_Position_Is_Valid;

   function Diagnostic_Availability_Reason
     (S             : Editor.State.State_Type;
      Mapped        : Natural;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return String
   is
      Label : constant String := Diagnostic_Target_Failure_Label
        (S, Mapped, Target_Buffer, Line, Column);
   begin
      if Label = "Target no longer exists." then
         return Label;
      elsif Label'Length > 0 and then Label (Label'Last) = '.' then
         return Label (Label'First .. Label'Last - 1);
      else
         return Label;
      end if;
   end Diagnostic_Availability_Reason;

   function Diagnostic_Quick_Fix_Action_Availability
     (S                : Editor.State.State_Type;
      Diagnostic_Index : Natural;
      Action_Index     : Natural)
      return Editor.Commands.Availability_Metadata.Command_Availability
   is
      Target_Buffer : constant Natural :=
        (if Diagnostic_Index = 0
           or else Diagnostic_Index >
             Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics)
         then 0
         else Editor.Feature_Diagnostics.Item_Target_Buffer
           (S.Feature_Diagnostics, Positive (Diagnostic_Index)));
      Target_Line : constant Natural :=
        (if Diagnostic_Index = 0
           or else Diagnostic_Index >
             Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics)
         then 0
         else Editor.Feature_Diagnostics.Item_Target_Line
           (S.Feature_Diagnostics, Positive (Diagnostic_Index)));
      Target_Column : constant Natural :=
        (if Diagnostic_Index = 0
           or else Diagnostic_Index >
             Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics)
         then 0
         else Natural'Max
           (1, Editor.Feature_Diagnostics.Item_Target_Column
                 (S.Feature_Diagnostics, Positive (Diagnostic_Index))));
   begin
      if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
         return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
      elsif Diagnostic_Index = 0
        or else Diagnostic_Index >
          Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics)
      then
         return Editor.Commands.Availability_Metadata.Unavailable
           ("Diagnostic quick fix is no longer available");
      elsif Action_Index = 0
        or else Action_Index >
          Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
            (S.Feature_Diagnostics, Positive (Diagnostic_Index))
      then
         return Editor.Commands.Availability_Metadata.Unavailable
           (Editor.Feature_Diagnostics
              .Quick_Fix_Action_Intrinsic_Unavailable_Reason
                (S.Feature_Diagnostics,
                 Positive (Diagnostic_Index),
                 Action_Index));
      elsif Editor.Feature_Diagnostics.Item_Is_Stale
        (S.Feature_Diagnostics, Positive (Diagnostic_Index))
      then
         return Editor.Commands.Availability_Metadata.Unavailable
           (Editor.Commands.Workflow_Messages.Reason_Target_Stale);
      elsif not Editor.Feature_Diagnostics.Validate_Diagnostic_Target
          (S.Feature_Diagnostics, Positive (Diagnostic_Index), Target_Buffer)
        or else not Feature_Target_Position_Is_Valid
          (S, Target_Buffer, Target_Line, Target_Column)
      then
         return Editor.Commands.Availability_Metadata.Unavailable
           (Diagnostic_Availability_Reason
              (S, Diagnostic_Index, Target_Buffer, Target_Line, Target_Column));
      elsif not Editor.Feature_Diagnostics
        .Quick_Fix_Action_Is_Intrinsically_Available
          (S.Feature_Diagnostics, Positive (Diagnostic_Index), Action_Index)
      then
         return Editor.Commands.Availability_Metadata.Unavailable
           (Editor.Feature_Diagnostics
              .Quick_Fix_Action_Intrinsic_Unavailable_Reason
                (S.Feature_Diagnostics,
                 Positive (Diagnostic_Index),
                 Action_Index));
      else
         return Editor.Commands.Availability_Metadata.Available;
      end if;
   end Diagnostic_Quick_Fix_Action_Availability;

   function Execute_Diagnostics_Feature_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
         return Editor.Command_Execution.Command_Execution_Result is
      begin
         return Editor.Command_Execution.Executed (Command);
      end Result_After_Command;
   begin
      case Id is
         when Editor.Commands.Command_Diagnostics_Show =>
            if not Editor.Feature_Panel_Controller.Show_Feature
              (S, Editor.Feature_Panel.Diagnostics_Feature)
            then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Diagnostics);
               return Editor.Command_Execution.No_Op (Id);
            end if;
            if Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0 then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Diagnostics);
            else
               Report_Info (S, Editor.Feature_Diagnostics.Message_Diagnostics_Shown);
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Clear =>
            if Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0 then
               Editor.Feature_Diagnostics.Show_All (S.Feature_Diagnostics);
               Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
                 (S.Feature_Diagnostics, S.Feature_Panel);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Show_All (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Diagnostics.Message_Diagnostics_Cleared);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Toggle_Info =>
            Editor.Feature_Diagnostics.Toggle_Info_Visible (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            if Editor.Feature_Diagnostics.Severity_Is_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Info)
            then
               Report_Info (S, Editor.Feature_Diagnostics.Message_Info_Shown);
            else
               Report_Info (S, Editor.Feature_Diagnostics.Message_Info_Hidden);
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Toggle_Warnings =>
            Editor.Feature_Diagnostics.Toggle_Warnings_Visible (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            if Editor.Feature_Diagnostics.Severity_Is_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Warning)
            then
               Report_Info (S, Editor.Feature_Diagnostics.Message_Warnings_Shown);
            else
               Report_Info (S, Editor.Feature_Diagnostics.Message_Warnings_Hidden);
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Toggle_Errors =>
            Editor.Feature_Diagnostics.Toggle_Errors_Visible (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            if Editor.Feature_Diagnostics.Severity_Is_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error)
            then
               Report_Info (S, Editor.Feature_Diagnostics.Message_Errors_Shown);
            else
               Report_Info (S, Editor.Feature_Diagnostics.Message_Errors_Hidden);
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Show_All =>
            Editor.Feature_Diagnostics.Show_All (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Diagnostics.Message_All_Diagnostics_Shown);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Clear_Filter =>
            if not Editor.Feature_Diagnostics.Filter_Active (S.Feature_Diagnostics) then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Filter_Active);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Diagnostics.Clear_Filter (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Diagnostics.Message_Filter_Cleared);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Filter_Errors =>
            Editor.Feature_Diagnostics.Filter_Errors_Only (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Diagnostics.Message_Filter_Errors);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Filter_Warnings =>
            Editor.Feature_Diagnostics.Filter_Warnings_Only (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Diagnostics.Message_Filter_Warnings);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Filter_Info_Notes =>
            Editor.Feature_Diagnostics.Filter_Info_And_Notes_Only (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Diagnostics.Message_Filter_Info_Notes);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Filter_Source =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Diagnostics);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            elsif not Editor.Feature_Diagnostics.Has_Visible_Diagnostic
              (S.Feature_Diagnostics)
            then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Visible_Diagnostic);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            end if;
            declare
               Source_Label : constant String :=
                 Editor.Feature_Diagnostics.Selected_Diagnostic_Source_Filter_Label
                   (S.Feature_Diagnostics, S.Feature_Panel);
            begin
               if Source_Label'Length = 0 then
                  Report_Info
                    (S, Editor.Feature_Diagnostics.Message_Filter_Selected_Source_Unavailable);
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.No_Op (Id);
               end if;
               Editor.Feature_Diagnostics.Filter_Source_Label
                 (S.Feature_Diagnostics, Source_Label);
               Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
                 (S.Feature_Diagnostics, S.Feature_Panel);
               Report_Info (S, Editor.Feature_Diagnostics.Message_Filter_Selected_Source);
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;

         when Editor.Commands.Command_Diagnostics_Filter_Build =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Diagnostics);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            elsif not Editor.Feature_Diagnostics.Has_Build_Diagnostic
              (S.Feature_Diagnostics)
            then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Build_Diagnostics);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Diagnostics.Filter_Build_Produced (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            Report_Info (S, Editor.Feature_Diagnostics.Message_Filter_Build);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Clear_Build =>
            declare
               Previous_Id : constant Editor.Feature_Diagnostics.Diagnostic_Id :=
                 Editor.Feature_Diagnostics.Selected_Diagnostic_Id
                   (S.Feature_Diagnostics, S.Feature_Panel);
               Previous_Source : constant Natural :=
                 (if Previous_Id = Editor.Feature_Diagnostics.No_Diagnostic then 0
                  else Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
                    (S.Feature_Diagnostics, S.Feature_Panel,
                     Editor.Feature_Panel.Selected_Row (S.Feature_Panel),
                     Editor.Feature_Panel.Projection_Generation (S.Feature_Panel)));
               Removed : Natural := 0;
            begin
               Removed := Editor.Feature_Diagnostics.Clear_Build_Diagnostics
                 (S.Feature_Diagnostics);
               Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
                 (S.Feature_Diagnostics, S.Feature_Panel, Previous_Id, Previous_Source);
               Editor.Render_Cache.Invalidate_All;
               if Removed > 0 then
                  Report_Info (S, Editor.Feature_Diagnostics.Message_Build_Diagnostics_Cleared);
                  return Result_After_Command (Id);
               else
                  Report_Info (S, Editor.Feature_Diagnostics.Message_No_Build_Diagnostics);
                  return Editor.Command_Execution.No_Op (Id);
               end if;
            end;

         when Editor.Commands.Command_Diagnostics_Open_Selected
            | Editor.Commands.Command_Diagnostic_Open_Source =>
            declare
               Row : constant Natural := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
               Result : Editor.Command_Execution.Command_Execution_Result :=
                 Editor.Executor.Diagnostics_Navigation_Commands.Execute_Diagnostic_Row_Activation
                   (S, Row, Editor.Feature_Panel.Projection_Generation (S.Feature_Panel));
            begin
               if Result.Status = Editor.Command_Execution.Command_Executed then
                  return Result_After_Command (Id);
               end if;

               --  Execute_Diagnostic_Row_Activation owns the failure message.
               --  Do not append a second generic outcome here;                --  requires one primary command outcome, and target failures
               --  should keep the precise row/target reason reported by the
               --  activation path.
               return Editor.Command_Execution.No_Op (Id);
            end;

         when Editor.Commands.Command_Diagnostic_Suppress_Selected
            | Editor.Commands.Command_Diagnostic_Show_Suppressed
            | Editor.Commands.Command_Diagnostic_Restore_Last_Suppressed
            | Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed
            | Editor.Commands.Command_Diagnostic_Clear_Suppressed =>
            return Editor.Executor.Diagnostics_Suppressed_Commands
              .Execute_Diagnostics_Suppressed_Command (S, Id);

         when Editor.Commands.Command_Diagnostics_Execute_Selected_Action
            | Editor.Commands.Command_Diagnostic_Apply_Quick_Fix =>
            return Editor.Executor.Diagnostics_Action_Commands
              .Execute_Diagnostics_Action_Command (S, Id);

         when Editor.Commands.Command_Diagnostics_Select_Next =>
            if Editor.Feature_Panel.Active_Feature (S.Feature_Panel) /=
              Editor.Feature_Panel.Diagnostics_Feature
            then
               if not Editor.Feature_Panel_Controller.Show_Feature
                 (S, Editor.Feature_Panel.Diagnostics_Feature)
               then
                  null;
               end if;
            end if;
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Diagnostics);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            elsif not Editor.Feature_Diagnostics.Has_Visible_Diagnostic
              (S.Feature_Diagnostics)
            then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Visible_Diagnostic);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Diagnostics.Select_Next_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Select_Previous =>
            if Editor.Feature_Panel.Active_Feature (S.Feature_Panel) /=
              Editor.Feature_Panel.Diagnostics_Feature
            then
               if not Editor.Feature_Panel_Controller.Show_Feature
                 (S, Editor.Feature_Panel.Diagnostics_Feature)
               then
                  null;
               end if;
            end if;
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Diagnostics);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            elsif not Editor.Feature_Diagnostics.Has_Visible_Diagnostic
              (S.Feature_Diagnostics)
            then
               Report_Info (S, Editor.Feature_Diagnostics.Message_No_Visible_Diagnostic);
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.No_Op (Id);
            end if;
            Editor.Feature_Diagnostics.Select_Previous_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Clear_Selected =>
            if Editor.Feature_Diagnostics.Clear_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Selected_Diagnostic_Cleared);
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end if;
            Report_Info
              (S, Editor.Feature_Diagnostics.Message_No_Selected_Diagnostic);
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.No_Op (Id);

         when Editor.Commands.Command_Diagnostics_Copy_Selected_Text =>
            declare
               Text : constant String := Editor.Feature_Diagnostics.Selected_Diagnostic_Text
                 (S.Feature_Diagnostics, S.Feature_Panel);
            begin
               if Text'Length = 0 then
                  Report_Info
                    (S, Editor.Feature_Diagnostics.Message_No_Selected_Diagnostic);
                  return Editor.Command_Execution.No_Op (Id);
               end if;
               Editor.Clipboard.Set_Text (To_Unbounded_String (Text));
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Selected_Diagnostic_Copied);
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;

         when Editor.Commands.Command_Diagnostics_Clear_Info =>
            declare
               Previous_Id : constant Editor.Feature_Diagnostics.Diagnostic_Id :=
                 Editor.Feature_Diagnostics.Selected_Diagnostic_Id
                   (S.Feature_Diagnostics, S.Feature_Panel);
               Previous_Source : constant Natural :=
                 (if Previous_Id = Editor.Feature_Diagnostics.No_Diagnostic then 0
                  else Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
                    (S.Feature_Diagnostics, S.Feature_Panel,
                     Editor.Feature_Panel.Selected_Row (S.Feature_Panel),
                     Editor.Feature_Panel.Projection_Generation (S.Feature_Panel)));
               Removed : Natural := 0;
            begin
               Removed := Editor.Feature_Diagnostics.Clear_Info_And_Note_Diagnostics
                 (S.Feature_Diagnostics);
               Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
                 (S.Feature_Diagnostics, S.Feature_Panel, Previous_Id, Previous_Source);
               Editor.Render_Cache.Invalidate_All;
               if Removed > 0 then
                  Report_Info (S, Editor.Feature_Diagnostics.Message_Info_Cleared);
                  return Result_After_Command (Id);
               else
                  Report_Info (S, Editor.Feature_Diagnostics.Message_No_Info_Diagnostics);
                  return Editor.Command_Execution.No_Op (Id);
               end if;
            end;

         when Editor.Commands.Command_Diagnostics_Clear_Warnings =>
            declare
               Previous_Id : constant Editor.Feature_Diagnostics.Diagnostic_Id :=
                 Editor.Feature_Diagnostics.Selected_Diagnostic_Id
                   (S.Feature_Diagnostics, S.Feature_Panel);
               Previous_Source : constant Natural :=
                 (if Previous_Id = Editor.Feature_Diagnostics.No_Diagnostic then 0
                  else Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
                    (S.Feature_Diagnostics, S.Feature_Panel,
                     Editor.Feature_Panel.Selected_Row (S.Feature_Panel),
                     Editor.Feature_Panel.Projection_Generation (S.Feature_Panel)));
               Removed : Natural := 0;
            begin
               Removed := Editor.Feature_Diagnostics.Clear_Diagnostics_By_Severity
                 (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Warning);
               Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
                 (S.Feature_Diagnostics, S.Feature_Panel, Previous_Id, Previous_Source);
               Editor.Render_Cache.Invalidate_All;
               if Removed > 0 then
                  Report_Info (S, Editor.Feature_Diagnostics.Message_Warnings_Cleared);
                  return Result_After_Command (Id);
               else
                  Report_Info (S, Editor.Feature_Diagnostics.Message_No_Warning_Diagnostics);
                  return Editor.Command_Execution.No_Op (Id);
               end if;
            end;

         when Editor.Commands.Command_Diagnostics_Clear_Errors =>
            declare
               Previous_Id : constant Editor.Feature_Diagnostics.Diagnostic_Id :=
                 Editor.Feature_Diagnostics.Selected_Diagnostic_Id
                   (S.Feature_Diagnostics, S.Feature_Panel);
               Previous_Source : constant Natural :=
                 (if Previous_Id = Editor.Feature_Diagnostics.No_Diagnostic then 0
                  else Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
                    (S.Feature_Diagnostics, S.Feature_Panel,
                     Editor.Feature_Panel.Selected_Row (S.Feature_Panel),
                     Editor.Feature_Panel.Projection_Generation (S.Feature_Panel)));
               Removed : Natural := 0;
            begin
               Removed := Editor.Feature_Diagnostics.Clear_Diagnostics_By_Severity
                 (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Diagnostic_Error);
               Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
                 (S.Feature_Diagnostics, S.Feature_Panel, Previous_Id, Previous_Source);
               Editor.Render_Cache.Invalidate_All;
               if Removed > 0 then
                  Report_Info (S, Editor.Feature_Diagnostics.Message_Errors_Cleared);
                  return Result_After_Command (Id);
               else
                  Report_Info (S, Editor.Feature_Diagnostics.Message_No_Error_Diagnostics);
                  return Editor.Command_Execution.No_Op (Id);
               end if;
            end;

         when Editor.Commands.Command_Diagnostics_Toggle_Editor_Source =>
            Editor.Feature_Diagnostics.Toggle_Source_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Editor_Diagnostic_Source);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            if Editor.Feature_Diagnostics.Source_Is_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Editor_Diagnostic_Source)
            then
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Shown
                   (Editor.Feature_Diagnostics.Editor_Diagnostic_Source));
            else
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Hidden
                   (Editor.Feature_Diagnostics.Editor_Diagnostic_Source));
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Toggle_File_Source =>
            Editor.Feature_Diagnostics.Toggle_Source_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.File_Diagnostic_Source);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            if Editor.Feature_Diagnostics.Source_Is_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.File_Diagnostic_Source)
            then
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Shown
                   (Editor.Feature_Diagnostics.File_Diagnostic_Source));
            else
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Hidden
                   (Editor.Feature_Diagnostics.File_Diagnostic_Source));
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Toggle_Project_Source =>
            Editor.Feature_Diagnostics.Toggle_Source_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Project_Diagnostic_Source);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            if Editor.Feature_Diagnostics.Source_Is_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Project_Diagnostic_Source)
            then
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Shown
                   (Editor.Feature_Diagnostics.Project_Diagnostic_Source));
            else
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Hidden
                   (Editor.Feature_Diagnostics.Project_Diagnostic_Source));
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Toggle_External_Source =>
            Editor.Feature_Diagnostics.Toggle_Source_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.External_Diagnostic_Source);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            if Editor.Feature_Diagnostics.Source_Is_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.External_Diagnostic_Source)
            then
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Shown
                   (Editor.Feature_Diagnostics.External_Diagnostic_Source));
            else
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Hidden
                   (Editor.Feature_Diagnostics.External_Diagnostic_Source));
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Diagnostics_Toggle_Unknown_Source =>
            Editor.Feature_Diagnostics.Toggle_Source_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Unknown_Diagnostic_Source);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Filter_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            if Editor.Feature_Diagnostics.Source_Is_Visible
              (S.Feature_Diagnostics, Editor.Feature_Diagnostics.Unknown_Diagnostic_Source)
            then
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Shown
                   (Editor.Feature_Diagnostics.Unknown_Diagnostic_Source));
            else
               Report_Info
                 (S, Editor.Feature_Diagnostics.Message_Source_Hidden
                   (Editor.Feature_Diagnostics.Unknown_Diagnostic_Source));
            end if;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Diagnostics_Feature_Command;

end Editor.Executor.Diagnostics_Feature_Commands;
