with Editor.Diagnostics;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Feature_Diagnostics;
with Editor.Problems;
with Editor.State;

package Editor.Executor.Diagnostics_Commands is


   function Feature_Target_Position_Is_Valid
     (S             : Editor.State.State_Type;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return Boolean;

   function Diagnostic_Availability_Reason
     (S             : Editor.State.State_Type;
      Mapped        : Natural;
      Target_Buffer : Natural;
      Line          : Natural;
      Column        : Natural) return String;

   function Diagnostic_Quick_Fix_Action_Availability
     (S                : Editor.State.State_Type;
      Diagnostic_Index : Natural;
      Action_Index     : Natural)
      return Editor.Commands.Command_Availability;

   function Diagnostics_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Diagnostics_Feature_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   function Execute_Diagnostic_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result;

   function Execute_Diagnostic_Id_Activation
     (S  : in out Editor.State.State_Type;
      Id : Editor.Feature_Diagnostics.Diagnostic_Id)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Diagnostics_Commands;
