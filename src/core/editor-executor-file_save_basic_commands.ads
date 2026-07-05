with Editor.State;

package Editor.Executor.File_Save_Basic_Commands is

   procedure Execute_Save
     (S : in out Editor.State.State_Type);

   procedure Execute_Reload_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Revert_Active_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_Save_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Save_As
     (S    : in out Editor.State.State_Type;
      Path : String);

end Editor.Executor.File_Save_Basic_Commands;
