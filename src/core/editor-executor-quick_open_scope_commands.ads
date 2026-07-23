with Editor.State;

package Editor.Executor.Quick_Open_Scope_Commands is

   procedure Execute_Quick_Open_Scope_Set
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Quick_Open_Scope_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_From_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Scope_Parent
     (S : in out Editor.State.State_Type);

end Editor.Executor.Quick_Open_Scope_Commands;
