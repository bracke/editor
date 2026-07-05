with Editor.Commands;
with Editor.State;

package Editor.Executor.Navigation_Commands is

   function Navigation_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Navigation_History_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind);

   procedure Execute_Navigation_Back
     (S : in out Editor.State.State_Type);

   procedure Execute_Navigation_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Navigation_History_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Prefill_Goto_Line_Current
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Accept_Goto_Line
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Goto_Line_Clear_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Goto_Line_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Delete_Forward
     (S : in out Editor.State.State_Type);

end Editor.Executor.Navigation_Commands;
