with Editor.Executor.File_Save_Commands;
with Editor.State;

package body Editor.Executor.File_Operation_Commands is

   procedure Execute_Rename_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String)
      renames Editor.Executor.File_Save_Commands.Execute_Rename_Buffer_File;

   procedure Execute_Delete_Buffer_File
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.File_Save_Commands.Execute_Delete_Buffer_File;

   procedure Execute_Copy_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String)
      renames Editor.Executor.File_Save_Commands.Execute_Copy_Buffer_File;

   procedure Execute_Move_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String)
      renames Editor.Executor.File_Save_Commands.Execute_Move_Buffer_File;

end Editor.Executor.File_Operation_Commands;
