with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Search_Results_Commands is

   function Search_Results_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Search_Results_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   function Search_Results_Visible_Row_Count return Natural;

   procedure Ensure_Search_Result_Visible
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Search_Results
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Move_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Move_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Page_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Page_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Close_Or_Hide
     (S : in out Editor.State.State_Type);

   function Execute_Search_Result_Row_Activation
     (S                         : in out Editor.State.State_Type;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Search_Results_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

end Editor.Executor.Search_Results_Commands;
