with Editor.Command_Kinds;
with Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Command_Surface_Commands is

   function Command_Surface_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   procedure Recompute_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Command_Surface_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Command_Kinds.Command_Kind;
      Text : String := "");

   function Execute_Command_Surface_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Open_Command_Palette
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Command_Palette
     (S : in out Editor.State.State_Type);

   procedure Execute_Palette_Show_Command_Help
     (S : in out Editor.State.State_Type);

end Editor.Executor.Command_Surface_Commands;
