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
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Diagnostics_Navigation_Commands;
with Editor.Executor.Diagnostics_Problems_Commands;
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
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Command_Next_Diagnostic
            | Command_Previous_Diagnostic =>
            if Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0 then
               return Editor.Commands.Unavailable ("No diagnostics");
            end if;
            return Editor.Commands.Available;

         when Command_Problems_Move_Up
            | Command_Problems_Move_Down
            | Command_Problems_Page_Up
            | Command_Problems_Page_Down =>
            if Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0 then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Problems_Has_Focus (S) then
               return Editor.Commands.Unavailable ("Command not available here");
            end if;
            return Editor.Commands.Available;

         when Command_Problems_Open_Selected =>
            if Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0 then
               return Editor.Commands.Unavailable ("No problems");
            elsif not Problems_Has_Focus (S) then
               return Editor.Commands.Unavailable ("Command not available here");
            elsif Editor.Problems.Selected_Row_Index (S.Problems_View) = 0 then
               return Editor.Commands.Unavailable ("No diagnostic selected");
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
                  return Editor.Commands.Unavailable ("No diagnostic selected");
               end if;

               Row := Editor.Problems.Row (Snapshot, Positive (Selected));
               if not Editor.Problems.Row_Has_Target (Row) then
                  return Editor.Commands.Unavailable
                    (Editor.Problems.Row_Target_Unavailable_Label (Row));
               end if;
            end;
            return Editor.Commands.Available;

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
            return Editor.Commands.Available;

         when Command_Diagnostics_Open_Selected
            | Command_Diagnostic_Open_Source
            | Command_Diagnostics_Execute_Selected_Action
            | Command_Diagnostic_Apply_Quick_Fix =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
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
               return Editor.Commands.Unavailable ("No diagnostic selected");
            elsif not Editor.Feature_Diagnostics.Selected_Diagnostic_Has_Target
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Unavailable
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
                     return Editor.Commands.Unavailable
                       (Editor.Executor.Diagnostic_Availability_Reason
                          (S, Mapped, Target_Buffer, Target_Line, Target_Column));
                  elsif Editor.Feature_Diagnostics.Item_Is_Stale
                    (S.Feature_Diagnostics, Positive (Mapped))
                  then
                     return Editor.Commands.Unavailable
                       (Editor.Commands.Reason_Target_Stale);
                  elsif not Editor.Feature_Diagnostics.Validate_Diagnostic_Target
                      (S.Feature_Diagnostics, Positive (Mapped), Target_Buffer)
                    or else not Editor.Executor.Feature_Target_Position_Is_Valid
                      (S, Target_Buffer, Target_Line, Target_Column)
                  then
                     return Editor.Commands.Unavailable
                       (Editor.Executor.Diagnostic_Availability_Reason
                          (S, Mapped, Target_Buffer, Target_Line, Target_Column));
                  elsif (Id = Command_Diagnostics_Execute_Selected_Action
                         or else Id = Command_Diagnostic_Apply_Quick_Fix)
                    and then Editor.Feature_Diagnostics.Item_Primary_Action_Kind
                      (S.Feature_Diagnostics, Positive (Mapped)) =
                        Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None
                  then
                     return Editor.Commands.Unavailable
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
                     return Editor.Commands.Unavailable
                       (Editor.Commands.Reason_Diagnostic_Edit_Stale_Target);
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostic_Suppress_Selected =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Unavailable ("No diagnostic selected");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostic_Show_Suppressed
            | Command_Diagnostic_Restore_Last_Suppressed
            | Command_Diagnostic_Restore_Selected_Suppressed
            | Command_Diagnostic_Clear_Suppressed =>
            if Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
              (S.Feature_Diagnostics) = 0
            then
               return Editor.Commands.Unavailable ("No suppressed diagnostics");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Clear_Selected
            | Command_Diagnostics_Copy_Selected_Text =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Unavailable ("No diagnostic selected");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Select_Next
            | Command_Diagnostics_Select_Previous =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Visible_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Unavailable ("No visible diagnostics");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Clear_Info =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Info_Or_Note_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Unavailable
                 ("No info or note diagnostics");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Clear_Warnings =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Diagnostic_With_Severity
              (S.Feature_Diagnostics,
               Editor.Feature_Diagnostics.Diagnostic_Warning)
            then
               return Editor.Commands.Unavailable ("No warning diagnostics");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Clear_Errors =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Diagnostic_With_Severity
              (S.Feature_Diagnostics,
               Editor.Feature_Diagnostics.Diagnostic_Error)
            then
               return Editor.Commands.Unavailable ("No error diagnostics");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Clear_Filter =>
            if not Editor.Feature_Diagnostics.Filter_Active
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Unavailable ("No filter is active");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Filter_Errors
            | Command_Diagnostics_Filter_Warnings
            | Command_Diagnostics_Filter_Info_Notes =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Filter_Build =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Build_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Unavailable ("No build diagnostics");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Filter_Source =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Visible_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Unavailable ("No visible diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Unavailable ("No diagnostic selected");
            elsif Editor.Feature_Diagnostics.Selected_Diagnostic_Source_Filter_Label
              (S.Feature_Diagnostics, S.Feature_Panel)'Length = 0
            then
               return Editor.Commands.Unavailable
                 ("Selected diagnostic has no source label");
            end if;
            return Editor.Commands.Available;

         when Command_Diagnostics_Clear_Build =>
            if not Editor.Feature_Diagnostics.Has_Build_Diagnostic
              (S.Feature_Diagnostics)
            then
               return Editor.Commands.Unavailable ("No build diagnostics");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
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
         return Editor.Commands.Reason_Target_Missing;
      elsif Line = 0 then
         return Editor.Commands.Reason_Diagnostic_Target_Line_Unavailable;
      elsif Line_Count = 0 or else Line > Line_Count then
         if Editor.Feature_Diagnostics.Item_Is_Stale
           (S.Feature_Diagnostics, Positive (Mapped))
         then
            return Editor.Commands.Reason_Target_Stale;
         else
            return Editor.Commands.Reason_Diagnostic_Target_Line_Outside_Buffer
              & ".";
         end if;
      elsif Column = 0 then
         return Editor.Commands.Reason_Diagnostic_Target_Column_Unavailable;
      elsif Column - 1 > Feature_Target_Line_Length (S, Target_Buffer, Line) then
         if Editor.Feature_Diagnostics.Item_Is_Stale
           (S.Feature_Diagnostics, Positive (Mapped))
         then
            return Editor.Commands.Reason_Target_Stale;
         else
            return Editor.Commands.Reason_Diagnostic_Target_Column_Outside_Line
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
      return Editor.Commands.Command_Availability
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
         return Editor.Commands.Unavailable ("No diagnostics");
      elsif Diagnostic_Index = 0
        or else Diagnostic_Index >
          Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics)
      then
         return Editor.Commands.Unavailable
           ("Diagnostic quick fix is no longer available");
      elsif Action_Index = 0
        or else Action_Index >
          Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
            (S.Feature_Diagnostics, Positive (Diagnostic_Index))
      then
         return Editor.Commands.Unavailable
           (Editor.Feature_Diagnostics
              .Quick_Fix_Action_Intrinsic_Unavailable_Reason
                (S.Feature_Diagnostics,
                 Positive (Diagnostic_Index),
                 Action_Index));
      elsif Editor.Feature_Diagnostics.Item_Is_Stale
        (S.Feature_Diagnostics, Positive (Diagnostic_Index))
      then
         return Editor.Commands.Unavailable
           (Editor.Commands.Reason_Target_Stale);
      elsif not Editor.Feature_Diagnostics.Validate_Diagnostic_Target
          (S.Feature_Diagnostics, Positive (Diagnostic_Index), Target_Buffer)
        or else not Feature_Target_Position_Is_Valid
          (S, Target_Buffer, Target_Line, Target_Column)
      then
         return Editor.Commands.Unavailable
           (Diagnostic_Availability_Reason
              (S, Diagnostic_Index, Target_Buffer, Target_Line, Target_Column));
      elsif not Editor.Feature_Diagnostics
        .Quick_Fix_Action_Is_Intrinsically_Available
          (S.Feature_Diagnostics, Positive (Diagnostic_Index), Action_Index)
      then
         return Editor.Commands.Unavailable
           (Editor.Feature_Diagnostics
              .Quick_Fix_Action_Intrinsic_Unavailable_Reason
                (S.Feature_Diagnostics,
                 Positive (Diagnostic_Index),
                 Action_Index));
      else
         return Editor.Commands.Available;
      end if;
   end Diagnostic_Quick_Fix_Action_Availability;

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

         when Editor.Commands.Command_Diagnostic_Suppress_Selected =>
            if Editor.Feature_Diagnostics.Suppress_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               Report_Info
                 (S,
                  "Diagnostic suppressed. "
                  & Ada.Strings.Fixed.Trim
                      (Natural'Image
                         (Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
                            (S.Feature_Diagnostics)),
                       Ada.Strings.Both)
                  & " suppressed this session.");
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end if;

            Report_Info (S, Editor.Feature_Diagnostics.Message_No_Selected_Diagnostic);
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.No_Op (Id);

         when Editor.Commands.Command_Diagnostic_Show_Suppressed =>
            declare
               Count : constant Natural :=
                 Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
                   (S.Feature_Diagnostics);
               Last : constant String :=
                 Editor.Feature_Diagnostics.Last_Suppressed_Diagnostic_Text
                   (S.Feature_Diagnostics);
               Selected : constant Natural :=
                 Editor.Feature_Diagnostics.Selected_Suppressed_Diagnostic
                   (S.Feature_Diagnostics);
               Selected_Text : constant String :=
                 (if Selected = 0 then ""
                  else Editor.Feature_Diagnostics.Suppressed_Diagnostic_Text
                    (S.Feature_Diagnostics, Positive (Selected)));
            begin
               if Count = 0 then
                  Report_Info (S, "No suppressed diagnostics.");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.No_Op (Id);
               end if;

               Report_Info
                 (S,
                  "Suppressed diagnostics: "
                  & Ada.Strings.Fixed.Trim
                      (Natural'Image (Count), Ada.Strings.Both)
                  & (if Last'Length > 0 then "; latest: " & Last else "")
                  & (if Selected_Text'Length > 0 then
                       "; selected: " & Selected_Text
                     else ""));
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;

         when Editor.Commands.Command_Diagnostic_Restore_Last_Suppressed =>
            if Editor.Feature_Diagnostics.Restore_Last_Suppressed_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               Report_Info (S, "Suppressed diagnostic restored.");
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end if;

            Report_Info (S, "No suppressed diagnostics.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.No_Op (Id);

         when Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed =>
            if Editor.Feature_Diagnostics.Restore_Selected_Suppressed_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               Report_Info (S, "Selected suppressed diagnostic restored.");
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end if;

            Report_Info (S, "No suppressed diagnostic selected.");
            Editor.Render_Cache.Invalidate_All;
            return Editor.Command_Execution.No_Op (Id);

         when Editor.Commands.Command_Diagnostic_Clear_Suppressed =>
            declare
               Cleared : constant Natural :=
                 Editor.Feature_Diagnostics.Clear_Suppressed_Diagnostics
                   (S.Feature_Diagnostics);
            begin
               if Cleared = 0 then
                  Report_Info (S, "No suppressed diagnostics.");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.No_Op (Id);
               end if;

               Report_Info
                 (S,
                  "Cleared "
                  & Ada.Strings.Fixed.Trim
                      (Natural'Image (Cleared), Ada.Strings.Both)
                  & " suppressed diagnostics.");
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;

         when Editor.Commands.Command_Diagnostics_Execute_Selected_Action
            | Editor.Commands.Command_Diagnostic_Apply_Quick_Fix =>
            declare
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
                  Report_Info (S, Editor.Feature_Diagnostics.Message_No_Selected_Diagnostic);
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
                        Report_Info
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
                     Report_Info
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
                        Report_Info
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
                     Report_Info (S, To_String (Action_Result.Message));
                     Editor.Render_Cache.Invalidate_All;
                     return Editor.Command_Execution.Unavailable (Id);
                  elsif not Action_Execution.Is_Success (Action_Result) then
                     Report_Info (S, To_String (Action_Result.Message));
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
                        Cmd : Editor.Commands.Command;
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
                           Report_Info
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
                           Report_Info
                             (S, Editor.Commands.Reason_Diagnostic_Edit_Stale_Target);
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
                           Report_Info
                             (S, Editor.Commands.Reason_Diagnostic_Edit_Stale_Target);
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
                           Report_Info (S, To_String (Action_Result.Message));
                        else
                           Report_Info
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
                        Report_Info (S, To_String (Action_Result.Message));
                        Editor.Render_Cache.Invalidate_All;
                        return Result_After_Command (Id);
                     end;
                  end if;
               end;
            end;

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

  procedure Execute_Diagnostics_Kind
    (S    : in out Editor.State.State_Type;
     Kind : Editor.Commands.Command_Kind)
  is
      procedure Dispatch_Feature_Command
        (Id : Editor.Commands.Command_Id)
      is
         Result : Editor.Command_Execution.Command_Execution_Result;
         pragma Unreferenced (Result);
      begin
         Result :=
           Editor.Executor.Diagnostics_Commands.Execute_Diagnostics_Feature_Command
             (S, Id);
      end Dispatch_Feature_Command;
  begin
      case Kind is
         when Diagnostics_Show =>
            Dispatch_Feature_Command (Command_Diagnostics_Show);

         when Diagnostics_Clear =>
            Dispatch_Feature_Command (Command_Diagnostics_Clear);

         when Diagnostics_Toggle_Info =>
            Dispatch_Feature_Command (Command_Diagnostics_Toggle_Info);

         when Diagnostics_Toggle_Warnings =>
            Dispatch_Feature_Command (Command_Diagnostics_Toggle_Warnings);

         when Diagnostics_Toggle_Errors =>
            Dispatch_Feature_Command (Command_Diagnostics_Toggle_Errors);

         when Diagnostics_Show_All =>
            Dispatch_Feature_Command (Command_Diagnostics_Show_All);

         when Diagnostics_Clear_Filter =>
            Dispatch_Feature_Command (Command_Diagnostics_Clear_Filter);

         when Diagnostics_Filter_Errors =>
            Dispatch_Feature_Command (Command_Diagnostics_Filter_Errors);

         when Diagnostics_Filter_Warnings =>
            Dispatch_Feature_Command (Command_Diagnostics_Filter_Warnings);

         when Diagnostics_Filter_Info_Notes =>
            Dispatch_Feature_Command (Command_Diagnostics_Filter_Info_Notes);

         when Diagnostics_Filter_Source =>
            Dispatch_Feature_Command (Command_Diagnostics_Filter_Source);

         when Diagnostics_Filter_Build =>
            Dispatch_Feature_Command (Command_Diagnostics_Filter_Build);

         when Diagnostics_Clear_Build =>
            Dispatch_Feature_Command (Command_Diagnostics_Clear_Build);

         when Diagnostics_Open_Selected =>
            Dispatch_Feature_Command (Command_Diagnostics_Open_Selected);

         when Next_Diagnostic =>
            Editor.Executor.Diagnostics_Navigation_Commands.Execute_Next_Diagnostic
              (S);

         when Previous_Diagnostic =>
            Editor.Executor.Diagnostics_Navigation_Commands.Execute_Previous_Diagnostic
              (S);

         when Diagnostic_Open_Source =>
            Dispatch_Feature_Command (Command_Diagnostic_Open_Source);

         when Diagnostic_Suppress_Selected =>
            Dispatch_Feature_Command (Command_Diagnostic_Suppress_Selected);

         when Diagnostic_Show_Suppressed =>
            Dispatch_Feature_Command (Command_Diagnostic_Show_Suppressed);

         when Diagnostic_Restore_Last_Suppressed =>
            Dispatch_Feature_Command (Command_Diagnostic_Restore_Last_Suppressed);

         when Diagnostic_Restore_Selected_Suppressed =>
            Dispatch_Feature_Command (Command_Diagnostic_Restore_Selected_Suppressed);

         when Diagnostic_Clear_Suppressed =>
            Dispatch_Feature_Command (Command_Diagnostic_Clear_Suppressed);

         when Diagnostic_Apply_Quick_Fix =>
            Dispatch_Feature_Command (Command_Diagnostic_Apply_Quick_Fix);

         when Diagnostics_Execute_Selected_Action =>
            Dispatch_Feature_Command (Command_Diagnostics_Execute_Selected_Action);

         when Diagnostics_Select_Next =>
            Dispatch_Feature_Command (Command_Diagnostics_Select_Next);

         when Diagnostics_Select_Previous =>
            Dispatch_Feature_Command (Command_Diagnostics_Select_Previous);

         when Diagnostics_Clear_Selected =>
            Dispatch_Feature_Command (Command_Diagnostics_Clear_Selected);

         when Diagnostics_Copy_Selected_Text =>
            Dispatch_Feature_Command (Command_Diagnostics_Copy_Selected_Text);

         when Diagnostics_Clear_Info =>
            Dispatch_Feature_Command (Command_Diagnostics_Clear_Info);

         when Diagnostics_Clear_Warnings =>
            Dispatch_Feature_Command (Command_Diagnostics_Clear_Warnings);

         when Diagnostics_Clear_Errors =>
            Dispatch_Feature_Command (Command_Diagnostics_Clear_Errors);

         when Diagnostics_Toggle_Editor_Source =>
            Dispatch_Feature_Command (Command_Diagnostics_Toggle_Editor_Source);

         when Diagnostics_Toggle_File_Source =>
            Dispatch_Feature_Command (Command_Diagnostics_Toggle_File_Source);

         when Diagnostics_Toggle_Project_Source =>
            Dispatch_Feature_Command (Command_Diagnostics_Toggle_Project_Source);

         when Diagnostics_Toggle_External_Source =>
            Dispatch_Feature_Command (Command_Diagnostics_Toggle_External_Source);

         when Diagnostics_Toggle_Unknown_Source =>
            Dispatch_Feature_Command (Command_Diagnostics_Toggle_Unknown_Source);

         when Problems_Move_Up =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Move_Up
              (S);

         when Problems_Move_Down =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Move_Down
              (S);

         when Problems_Page_Up =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Page_Up
              (S);

         when Problems_Page_Down =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Page_Down
              (S);

         when Problems_Open_Selected =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Open_Selected
              (S);

         when Problems_Filter_All =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Filter
              (S, Editor.Problems.Problems_Show_All);

         when Problems_Filter_Errors =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Filter
              (S, Editor.Problems.Problems_Show_Errors);

         when Problems_Filter_Warnings =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Filter
              (S, Editor.Problems.Problems_Show_Warnings);

         when Problems_Filter_Info =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Filter
              (S, Editor.Problems.Problems_Show_Info);

         when Problems_Filter_Hints =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Filter
              (S, Editor.Problems.Problems_Show_Hints);

         when Problems_Sort_By_Location =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Sort
              (S, Editor.Problems.Problems_Sort_By_Location);

         when Problems_Sort_By_Severity =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Sort
              (S, Editor.Problems.Problems_Sort_By_Severity);

         when Problems_Sort_By_Source =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Sort
              (S, Editor.Problems.Problems_Sort_By_Source);

         when Problems_Group_By_Severity =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Group
              (S, Editor.Problems.Problems_Group_By_Severity);

         when Problems_Group_By_Source =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Group
              (S, Editor.Problems.Problems_Group_By_Source);

         when Problems_Focus_Editor =>
            Editor.Executor.Diagnostics_Problems_Commands.Execute_Problems_Focus_Editor
              (S);

         when others =>
            raise Program_Error with "unsupported diagnostics command kind";
      end case;
   end Execute_Diagnostics_Kind;

end Editor.Executor.Diagnostics_Feature_Commands;
