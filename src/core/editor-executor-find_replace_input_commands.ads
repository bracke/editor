with Editor.State;

package Editor.Executor.Find_Replace_Input_Commands is

   procedure Execute_Active_Find_Input_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Active_Find_Input_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Move_Cursor_Left
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Move_Cursor_Right
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Move_Cursor_Start
     (S : in out Editor.State.State_Type);

   procedure Execute_Active_Find_Input_Move_Cursor_End
     (S : in out Editor.State.State_Type);

end Editor.Executor.Find_Replace_Input_Commands;
