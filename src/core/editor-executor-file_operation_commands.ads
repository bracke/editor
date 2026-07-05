with Editor.State;

package Editor.Executor.File_Operation_Commands is

   procedure Execute_Rename_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_Delete_Buffer_File
     (S : in out Editor.State.State_Type);

   procedure Execute_Copy_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

   procedure Execute_Move_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String);

end Editor.Executor.File_Operation_Commands;
