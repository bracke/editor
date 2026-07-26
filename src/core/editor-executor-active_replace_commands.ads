with Editor.State;

package Editor.Executor.Active_Replace_Commands is

   procedure Execute_Replace_Show
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Set_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Replace_Clear_Text
     (S : in out Editor.State.State_Type);

end Editor.Executor.Active_Replace_Commands;
