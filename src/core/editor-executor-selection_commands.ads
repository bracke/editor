with Editor.Command_Execution;
with Editor.Commands;
with Editor.Navigation;
with Editor.Selection;
with Editor.State;

package Editor.Executor.Selection_Commands is

   function Selection_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Select_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Line_At
     (S   : in out Editor.State.State_Type;
      Row : Natural);

   procedure Execute_Extend_Selection_By_Line
     (S         : in out Editor.State.State_Type;
      Direction : Editor.Navigation.Navigation_Direction);

   procedure Execute_Extend_Selection_To_Line
     (S   : in out Editor.State.State_Type;
      Row : Natural);

   procedure Execute_Select_Word
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_All_Selection_Command
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Selection_Command
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Current_Word_Command
     (S : in out Editor.State.State_Type);

   function Execute_Selection_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Select_Word_At
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Column : Natural);

   procedure Execute_Extend_Selection_By_Word
     (S         : in out Editor.State.State_Type;
      Direction : Editor.Navigation.Navigation_Direction);

   procedure Execute_Start_Rectangular_Selection
     (S : in out Editor.State.State_Type);

   procedure Execute_Set_Rectangular_Selection
     (S      : in out Editor.State.State_Type;
      Anchor : Editor.Selection.Text_Position;
      Cursor : Editor.Selection.Text_Position);

   procedure Execute_Clear_Rectangular_Selection
     (S : in out Editor.State.State_Type);

   procedure Execute_Select_Rectangle_To
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Column : Natural);

end Editor.Executor.Selection_Commands;
