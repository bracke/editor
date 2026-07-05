with Editor.Diagnostics;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Feature_Diagnostics;
with Editor.Problems;
with Editor.State;

package Editor.Executor.Diagnostics_Commands is

   function Diagnostics_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Diagnostics_Feature_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Diagnostics_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

   function Execute_Diagnostic_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result;

   function Execute_Diagnostic_Id_Activation
     (S  : in out Editor.State.State_Type;
      Id : Editor.Feature_Diagnostics.Diagnostic_Id)
      return Editor.Command_Execution.Command_Execution_Result;

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

   procedure Execute_Problems_Move_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Move_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Page_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Page_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Problems_Filter
     (S      : in out Editor.State.State_Type;
      Filter : Editor.Problems.Problems_Severity_Filter);

   procedure Execute_Problems_Sort
     (S    : in out Editor.State.State_Type;
      Sort : Editor.Problems.Problems_Sort_Mode);

   procedure Execute_Problems_Group
     (S     : in out Editor.State.State_Type;
      Group : Editor.Problems.Problems_Group_Mode);

   procedure Execute_Problems_Focus_Editor
     (S : in out Editor.State.State_Type);

end Editor.Executor.Diagnostics_Commands;
