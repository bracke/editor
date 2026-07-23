with Editor.State;

package Editor.Executor.Quick_Open_Input_Commands is

   procedure Recompute_Quick_Open
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

end Editor.Executor.Quick_Open_Input_Commands;
