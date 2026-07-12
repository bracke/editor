with Editor.Diagnostics;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Feature_Diagnostics;
with Editor.State;

package Editor.Executor.Diagnostics_Navigation_Commands is

   procedure Execute_Jump_To_Diagnostic
     (S     : in out Editor.State.State_Type;
      Index : Editor.Diagnostics.Diagnostic_Index);

   procedure Execute_Next_Diagnostic
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Diagnostic
     (S : in out Editor.State.State_Type);

   procedure Execute_Jump_To_Diagnostic_On_Row
     (S   : in out Editor.State.State_Type;
      Row : Natural);

   function Execute_Diagnostic_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result;

   function Execute_Diagnostic_Id_Activation
     (S  : in out Editor.State.State_Type;
      Id : Natural)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Diagnostics_Navigation_Commands;
