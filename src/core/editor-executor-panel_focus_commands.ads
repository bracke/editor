with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Panel_Focus_Commands is

   function Panel_Focus_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Panel_Focus_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Toggle_Problems_Panel
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Editor_Text
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Search_Results
     (S : in out Editor.State.State_Type);

   function Problems_Visible_Row_Count return Natural;

   procedure Execute_Focus_Problems
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Bottom_Panel_Focus
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Build_Output
     (S : in out Editor.State.State_Type);

   procedure Execute_Show_Build_Output
     (S : in out Editor.State.State_Type);

   procedure Execute_Hide_Build_Output
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Build_Output
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Build_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Build_Output_Details
     (S : in out Editor.State.State_Type);

end Editor.Executor.Panel_Focus_Commands;
