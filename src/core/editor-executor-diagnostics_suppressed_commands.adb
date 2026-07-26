with Editor.Commands.Availability_Metadata;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Diagnostics_Suppressed_Commands is

   use Editor.Commands;
   use type Editor.Command_Execution.Command_Execution_Status;

   function Diagnostics_Suppressed_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability
   is
   begin
      case Id is
         when Command_Diagnostic_Suppress_Selected =>
            if Editor.Feature_Diagnostics.Is_Empty (S.Feature_Diagnostics) then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostics");
            elsif not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
              (S.Feature_Diagnostics, S.Feature_Panel)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No diagnostic selected");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Diagnostic_Show_Suppressed
            | Command_Diagnostic_Restore_Last_Suppressed
            | Command_Diagnostic_Restore_Selected_Suppressed
            | Command_Diagnostic_Clear_Suppressed =>
            if Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
              (S.Feature_Diagnostics) = 0
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No suppressed diagnostics");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when others =>
            return Editor.Commands.Availability_Metadata.Unavailable
              ("Command is not a suppressed-diagnostics command");
      end case;
   end Diagnostics_Suppressed_Command_Availability;

   function Execute_Diagnostics_Suppressed_Command
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
         when Command_Diagnostic_Suppress_Selected =>
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

         when Command_Diagnostic_Show_Suppressed =>
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

         when Command_Diagnostic_Restore_Last_Suppressed =>
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

         when Command_Diagnostic_Restore_Selected_Suppressed =>
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

         when Command_Diagnostic_Clear_Suppressed =>
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

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Diagnostics_Suppressed_Command;

end Editor.Executor.Diagnostics_Suppressed_Commands;
