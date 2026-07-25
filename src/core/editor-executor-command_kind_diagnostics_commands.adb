with Editor.Commands.Payloads;
with Editor.Command_Execution;
with Editor.Commands; use Editor.Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Diagnostics_Navigation_Commands;
with Editor.Executor.Diagnostics_Problems_Commands;
with Editor.Invariants;
with Editor.Problems;
with Editor.Render_Cache;

package body Editor.Executor.Command_Kind_Diagnostics_Commands is

   procedure Run_Diagnostics_Feature_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
   is
      Result : constant Editor.Command_Execution.Command_Execution_Result :=
        Editor.Executor.Diagnostics_Commands.Execute_Diagnostics_Feature_Command
          (S, Id);
      pragma Unreferenced (Result);
   begin
      null;
   end Run_Diagnostics_Feature_Command;

   function Try_Execute_Diagnostics_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command) return Boolean
   is
      use type Editor.Commands.Command_Kind;
   begin
      case Cmd.Kind is
         when Next_Diagnostic
            | Previous_Diagnostic
            | Problems_Move_Up
            | Problems_Move_Down
            | Problems_Page_Up
            | Problems_Page_Down
            | Problems_Open_Selected
            | Problems_Filter_All
            | Problems_Filter_Errors
            | Problems_Filter_Warnings
            | Problems_Filter_Info
            | Problems_Filter_Hints
            | Problems_Sort_By_Location
            | Problems_Sort_By_Severity
            | Problems_Sort_By_Source
            | Problems_Group_By_Severity
            | Problems_Group_By_Source
            | Problems_Focus_Editor
            | Diagnostics_Show
            | Diagnostics_Clear
            | Diagnostics_Toggle_Info
            | Diagnostics_Toggle_Warnings
            | Diagnostics_Toggle_Errors
            | Diagnostics_Show_All
            | Diagnostics_Clear_Filter
            | Diagnostics_Filter_Errors
            | Diagnostics_Filter_Warnings
            | Diagnostics_Filter_Info_Notes
            | Diagnostics_Filter_Source
            | Diagnostics_Filter_Build
            | Diagnostics_Clear_Build
            | Diagnostics_Open_Selected
            | Diagnostic_Open_Source
            | Diagnostic_Suppress_Selected
            | Diagnostic_Show_Suppressed
            | Diagnostic_Restore_Last_Suppressed
            | Diagnostic_Restore_Selected_Suppressed
            | Diagnostic_Clear_Suppressed
            | Diagnostic_Apply_Quick_Fix
            | Diagnostics_Execute_Selected_Action
            | Diagnostics_Select_Next
            | Diagnostics_Select_Previous
            | Diagnostics_Clear_Selected
            | Diagnostics_Copy_Selected_Text
            | Diagnostics_Clear_Info
            | Diagnostics_Clear_Warnings
            | Diagnostics_Clear_Errors
            | Diagnostics_Toggle_Editor_Source
            | Diagnostics_Toggle_File_Source
            | Diagnostics_Toggle_Project_Source
            | Diagnostics_Toggle_External_Source
            | Diagnostics_Toggle_Unknown_Source =>
            case Cmd.Kind is
               when Next_Diagnostic =>
                  Editor.Executor.Diagnostics_Navigation_Commands
                    .Execute_Next_Diagnostic (S);

               when Previous_Diagnostic =>
                  Editor.Executor.Diagnostics_Navigation_Commands
                    .Execute_Previous_Diagnostic (S);

               when Diagnostics_Show =>
                  Run_Diagnostics_Feature_Command (S, Command_Diagnostics_Show);

               when Diagnostics_Clear =>
                  Run_Diagnostics_Feature_Command (S, Command_Diagnostics_Clear);

               when Diagnostics_Toggle_Info =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Toggle_Info);

               when Diagnostics_Toggle_Warnings =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Toggle_Warnings);

               when Diagnostics_Toggle_Errors =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Toggle_Errors);

               when Diagnostics_Show_All =>
                  Run_Diagnostics_Feature_Command (S, Command_Diagnostics_Show_All);

               when Diagnostics_Clear_Filter =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Clear_Filter);

               when Diagnostics_Filter_Errors =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Filter_Errors);

               when Diagnostics_Filter_Warnings =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Filter_Warnings);

               when Diagnostics_Filter_Info_Notes =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Filter_Info_Notes);

               when Diagnostics_Filter_Source =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Filter_Source);

               when Diagnostics_Filter_Build =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Filter_Build);

               when Diagnostics_Clear_Build =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Clear_Build);

               when Diagnostics_Open_Selected =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Open_Selected);

               when Diagnostic_Open_Source =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostic_Open_Source);

               when Diagnostic_Suppress_Selected =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostic_Suppress_Selected);

               when Diagnostic_Show_Suppressed =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostic_Show_Suppressed);

               when Diagnostic_Restore_Last_Suppressed =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostic_Restore_Last_Suppressed);

               when Diagnostic_Restore_Selected_Suppressed =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostic_Restore_Selected_Suppressed);

               when Diagnostic_Clear_Suppressed =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostic_Clear_Suppressed);

               when Diagnostic_Apply_Quick_Fix =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostic_Apply_Quick_Fix);

               when Diagnostics_Execute_Selected_Action =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Execute_Selected_Action);

               when Diagnostics_Select_Next =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Select_Next);

               when Diagnostics_Select_Previous =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Select_Previous);

               when Diagnostics_Clear_Selected =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Clear_Selected);

               when Diagnostics_Copy_Selected_Text =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Copy_Selected_Text);

               when Diagnostics_Clear_Info =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Clear_Info);

               when Diagnostics_Clear_Warnings =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Clear_Warnings);

               when Diagnostics_Clear_Errors =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Clear_Errors);

               when Diagnostics_Toggle_Editor_Source =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Toggle_Editor_Source);

               when Diagnostics_Toggle_File_Source =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Toggle_File_Source);

               when Diagnostics_Toggle_Project_Source =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Toggle_Project_Source);

               when Diagnostics_Toggle_External_Source =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Toggle_External_Source);

               when Diagnostics_Toggle_Unknown_Source =>
                  Run_Diagnostics_Feature_Command
                    (S, Command_Diagnostics_Toggle_Unknown_Source);

               when Problems_Move_Up =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Move_Up (S);

               when Problems_Move_Down =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Move_Down (S);

               when Problems_Page_Up =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Page_Up (S);

               when Problems_Page_Down =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Page_Down (S);

               when Problems_Open_Selected =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Open_Selected (S);

               when Problems_Filter_All =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_All);

               when Problems_Filter_Errors =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_Errors);

               when Problems_Filter_Warnings =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_Warnings);

               when Problems_Filter_Info =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_Info);

               when Problems_Filter_Hints =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_Hints);

               when Problems_Sort_By_Location =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Sort
                      (S, Editor.Problems.Problems_Sort_By_Location);

               when Problems_Sort_By_Severity =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Sort
                      (S, Editor.Problems.Problems_Sort_By_Severity);

               when Problems_Sort_By_Source =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Sort
                      (S, Editor.Problems.Problems_Sort_By_Source);

               when Problems_Group_By_Severity =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Group
                      (S, Editor.Problems.Problems_Group_By_Severity);

               when Problems_Group_By_Source =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Group
                      (S, Editor.Problems.Problems_Group_By_Source);

               when Problems_Focus_Editor =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Focus_Editor (S);

               when others =>
                  null;
            end case;

            Editor.Invariants.Check (S);
            return True;

         when others =>
            return False;
      end case;
   end Try_Execute_Diagnostics_Kind;

end Editor.Executor.Command_Kind_Diagnostics_Commands;
