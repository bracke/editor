with Editor.Command_Kinds;
with Editor.Command_Ids;
with Editor.State;

package Editor.Executor.Buffer_Switcher_Mark_Metadata_Commands is

   procedure Execute_Buffer_Switcher_Mark_Pinned
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Group
     (S    : in out Editor.State.State_Type;
      Name : String);

   procedure Execute_Buffer_Switcher_Mark_Label
     (S     : in out Editor.State.State_Type;
      Label : String);

   procedure Execute_Buffer_Switcher_Mark_Noted
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Pin_Marked
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Unpin_Marked
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Clear_Metadata
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Group_Assign
     (S    : in out Editor.State.State_Type;
      Name : String);

   procedure Execute_Buffer_Switcher_Mark_Group_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Label_Set
     (S     : in out Editor.State.State_Type;
      Label : String);

   procedure Execute_Buffer_Switcher_Mark_Label_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Note_Set
     (S    : in out Editor.State.State_Type;
      Note : String);

   procedure Execute_Buffer_Switcher_Mark_Note_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Buffer_Switcher_Mark_Metadata_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Command_Kinds.Command_Kind;
      Text : String);

end Editor.Executor.Buffer_Switcher_Mark_Metadata_Commands;
