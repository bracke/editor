with Editor.State;

package Editor.Executor.File_Save_As_Commands is

   procedure Execute_Save_As
     (S    : in out Editor.State.State_Type;
      Path : String);

end Editor.Executor.File_Save_As_Commands;
