with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Command_Surface_Commands is

   function Command_Surface_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Recompute_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Command_Surface_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String := "");

   function Execute_Command_Surface_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Open_Command_Palette
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Command_Palette
     (S : in out Editor.State.State_Type);

   procedure Execute_Palette_Show_Command_Help
     (S : in out Editor.State.State_Type);

end Editor.Executor.Command_Surface_Commands;
