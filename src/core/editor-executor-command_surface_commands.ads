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

   procedure Execute_Goto_Line_Move_Cursor_Left
     (S : in out Editor.State.State_Type);

   procedure Execute_Goto_Line_Move_Cursor_Right
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Accept_Quick_Open
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Next_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Previous_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Quick_Open_Clear_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Kind_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Kind_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Kind_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_Set
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Quick_Open_Scope_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_From_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_Parent
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Reveal_Active
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_Active_Directory
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Create_From_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Create_With_Parents_From_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Priority_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Priority_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Quick_Open_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Move_Cursor_Left
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Move_Cursor_Right
     (S : in out Editor.State.State_Type);

end Editor.Executor.Command_Surface_Commands;
