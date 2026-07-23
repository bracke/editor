with Editor.State;

package Editor.Executor.Find_Replace_Input_Commands is

   procedure Execute_Find_From_Selection
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_From_Active_Word
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Find_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Find_Clear_Query
     (S : in out Editor.State.State_Type);

   procedure Set_Active_Find_Query_And_Report
     (S    : in out Editor.State.State_Type;
      Text : String);

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
