with Editor.Buffer_Switcher;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Buffer_Switcher_Surface_Commands is

   function Buffer_Switcher_Surface_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Buffer_Switcher_Surface_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String);

   procedure Execute_Open_Buffer_Switcher
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Buffer_Switcher
     (S : in out Editor.State.State_Type);

   procedure Execute_Accept_Buffer_Switcher
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Next_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Previous_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Buffer_Switcher_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Move_Cursor_Left
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Move_Cursor_Right
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Filter_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Filter_Pinned
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Filter_Group
     (S    : in out Editor.State.State_Type;
      Name : String);

   procedure Execute_Buffer_Switcher_Filter_Label
     (S     : in out Editor.State.State_Type;
      Label : String);

   procedure Execute_Buffer_Switcher_Filter_Noted
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Sort
     (S    : in out Editor.State.State_Type;
      Mode : Editor.Buffer_Switcher.Switcher_Sort_Mode);

   procedure Execute_Buffer_Switcher_Sort_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Sort_Previous
     (S : in out Editor.State.State_Type);

end Editor.Executor.Buffer_Switcher_Surface_Commands;
