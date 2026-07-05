with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_Build_Terminal is

   function Make_Descriptor
     (Id          : Command_Id;
      Name        : String;
      Description : String;
      Category    : Command_Category;
      Visibility  : Command_Visibility) return Command_Descriptor
   is
      Effective_Description : constant String :=
        (if Id = No_Command then Description
         elsif Description'Length = 0 then "Execute " & Name & "."
         else Description);
   begin
      return Descriptor_Factory.Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Command_Name (Id),
         Label         => Name,
         Description   => Effective_Description,
         Category      => Category,
         Visible       => Visibility = Palette_Command,
         Bindable      => Id /= No_Command
           and then not Is_Public_Build_Command (Id),
         Destructive   => Is_Destructive_Command (Id),
         Lifecycle     => Is_Lifecycle_Command (Id),
         Configuration => Is_Configuration_Command (Id));
   end Make_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      case Id is
         when Command_Run_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project",
               Description => "Search known project files for the current query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Run_Project_Search_From_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Project Search Query",
               Description => "Set the Project Search query from the active input and run search.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Run_Project =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Project: Run",
                  Description => "Run the default project task through the structured project task runner.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Run_Tests =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Project: Run Tests",
                  Description => "Run the default project test task through the structured project task runner.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Terminal_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Toggle",
               Description => "Show or hide the integrated terminal and task panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Show",
               Description => "Show the integrated terminal and task panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Hide",
               Description => "Hide the integrated terminal and task panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Focus",
               Description => "Show and focus the integrated terminal and task panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Clear Tasks",
               Description => "Clear terminal task rows and output.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Clear_Output =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Clear Output",
               Description => "Clear bounded terminal output while preserving task rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Select_Next_Task =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Select Next Task",
               Description => "Move terminal task selection to the next row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Select_Previous_Task =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Select Previous Task",
               Description => "Move terminal task selection to the previous row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Run_Selected_Task =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Terminal: Run Selected Task",
                  Description => "Run the selected structured terminal task.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Terminal_Rerun_Last_Task =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Terminal: Rerun Last Task",
                  Description => "Run the most recently executed terminal task again.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Terminal_Cancel_Task =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Terminal: Cancel Task",
                  Description => "Request cancellation of the active terminal task when a backend is running it.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Build_UI_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Build Output",
               Description => "Show or hide the build output panel without refreshing candidates or running a build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Build Output",
               Description => "Show the current build output without starting a new build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Build Output",
               Description => "Hide the build output panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Build Output",
               Description => "Show and focus the build output panel without changing request, candidate, or confirmation state.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_Result_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Focus Latest Result",
               Description => "Focus the latest build result summary when a result is available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_Output_Details_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Focus Output Details",
               Description => "Focus the latest build stdout/stderr details when output details are available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_Output_Details_Select_Stdout =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Stdout Output",
               Description => "Show stdout as the selected latest build output stream.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Output_Details_Select_Stderr =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Stderr Output",
               Description => "Show stderr as the selected latest build output stream.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Output_Details_Select_Merged =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Merged Output",
               Description => "Show merged stdout/stderr as the selected latest build output stream.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Refresh_Candidates =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Refresh Candidates",
               Description => "Refresh build candidates for the current project without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Select_First_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select First Candidate",
               Description => "Select the first discovered build candidate without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Select_Next_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Next Candidate",
               Description => "Select the next discovered build candidate without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Select_Previous_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Previous Candidate",
               Description => "Select the previous discovered build candidate without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Clear_Selected_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Clear Selected Candidate",
               Description => "Clear the selected build candidate and require confirmation before the next run.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Default =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Default",
               Description => "Set the build mode to the default profile.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Debug =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Debug",
               Description => "Set the selected GPRbuild candidate to the debug profile (-g).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Release =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Release",
               Description => "Set the selected GPRbuild candidate to the release profile (-O2 -gnatp).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Validation =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Validation",
               Description => "Set the selected GPRbuild candidate to the validation profile (-gnata -gnatwa).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Diagnostics_Ingestion =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Diagnostics Ingestion",
               Description => "Toggle whether build results update Diagnostics after the next run.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Cycle_Output_Limit =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Cycle Output Capture Limit",
               Description => "Cycle the build output capture limit.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Option_Verbose =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Verbose Output",
               Description => "Toggle the fixed verbose-output request option where supported by the selected candidate.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Option_Keep_Going =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Keep Going",
               Description => "Toggle the fixed keep-going request option where supported by the selected candidate.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Acknowledge_Consent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Acknowledge Consent",
               Description => "Confirm the current build request before running it.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Clear_Consent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Clear Consent",
               Description => "Clear build confirmation without changing candidates or request options.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Cancel =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Cancel Build",
                  Description => "Request cancellation of the currently active build job.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Build_Run =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Run Build",
                  Description => "Run the currently selected build request after explicit confirmation.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Build_Run_User_Opt_In_Test_Seam =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Build: Run User Opt-In Test Command",
                  Description => "Internal test-only command for structured user opt-in build command validation.",
                  Category    => Internal_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when others =>
            raise Program_Error with "command is not owned by Descriptor_Build_Terminal";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_Build_Terminal;
