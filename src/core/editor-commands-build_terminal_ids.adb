with Editor.Command_Kinds;
package body Editor.Commands.Build_Terminal_Ids is

   function Is_Public_Build_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id in Command_Build_Run
        | Command_Build_Cancel
        | Command_Build_Result_Focus
        | Command_Build_Output_Details_Focus
        | Command_Build_Output_Details_Select_Stdout
        | Command_Build_Output_Details_Select_Stderr
        | Command_Build_Output_Details_Select_Merged
        | Command_Build_Refresh_Candidates
        | Command_Build_Select_First_Candidate
        | Command_Build_Select_Next_Candidate
        | Command_Build_Select_Previous_Candidate
        | Command_Build_Clear_Selected_Candidate
        | Command_Build_Set_Mode_Default
        | Command_Build_Set_Mode_Debug
        | Command_Build_Set_Mode_Release
        | Command_Build_Set_Mode_Validation
        | Command_Build_Toggle_Diagnostics_Ingestion
        | Command_Build_Cycle_Output_Limit
        | Command_Build_Toggle_Option_Verbose
        | Command_Build_Toggle_Option_Keep_Going
        | Command_Build_Acknowledge_Consent
        | Command_Build_Clear_Consent;
   end Is_Public_Build_Command;

   function Is_Internal_Build_Test_Seam_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Build_Run_User_Opt_In_Test_Seam;
   end Is_Internal_Build_Test_Seam_Command;

   function Is_Build_Or_Terminal_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Run_Project
            | Command_Run_Tests
            | Command_Terminal_Toggle
            | Command_Terminal_Show
            | Command_Terminal_Hide
            | Command_Terminal_Focus
            | Command_Terminal_Clear
            | Command_Terminal_Clear_Output
            | Command_Terminal_Select_Next_Task
            | Command_Terminal_Select_Previous_Task
            | Command_Terminal_Run_Selected_Task
            | Command_Terminal_Rerun_Last_Task
            | Command_Terminal_Cancel_Task
            | Command_Build_UI_Toggle
            | Command_Build_UI_Show
            | Command_Build_UI_Hide
            | Command_Build_UI_Focus
            | Command_Build_Result_Focus
            | Command_Build_Output_Details_Focus
            | Command_Build_Output_Details_Select_Stdout
            | Command_Build_Output_Details_Select_Stderr
            | Command_Build_Output_Details_Select_Merged
            | Command_Build_Refresh_Candidates
            | Command_Build_Select_First_Candidate
            | Command_Build_Select_Next_Candidate
            | Command_Build_Select_Previous_Candidate
            | Command_Build_Clear_Selected_Candidate
            | Command_Build_Set_Mode_Default
            | Command_Build_Set_Mode_Debug
            | Command_Build_Set_Mode_Release
            | Command_Build_Set_Mode_Validation
            | Command_Build_Toggle_Diagnostics_Ingestion
            | Command_Build_Cycle_Output_Limit
            | Command_Build_Toggle_Option_Verbose
            | Command_Build_Toggle_Option_Keep_Going
            | Command_Build_Acknowledge_Consent
            | Command_Build_Clear_Consent
            | Command_Build_Run
            | Command_Build_Cancel
            | Command_Build_Run_User_Opt_In_Test_Seam =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Build_Or_Terminal_Command;

end Editor.Commands.Build_Terminal_Ids;
