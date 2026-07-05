with Editor.Executor.File_Save_Commands;
with Editor.State;

package body Editor.Executor.File_Save_Basic_Commands is

   procedure Execute_Save
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Execute_Save;

   procedure Execute_Reload_Active_Buffer
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Execute_Reload_Active_Buffer;

   procedure Execute_Revert_Active_Buffer
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Execute_Revert_Active_Buffer;

   procedure Execute_Save_All
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Execute_Save_All;

   procedure Execute_Save_As
     (S    : in out Editor.State.State_Type;
      Path : String)
      renames Editor.Executor.File_Save_Commands.Execute_Save_As;

end Editor.Executor.File_Save_Basic_Commands;
