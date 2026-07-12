with Editor.State;

package Editor.Executor.File_Conflict_Commands is

   procedure Execute_File_Conflict_Cancel
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Keep_Buffer
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Reload_From_Disk
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Conflict_Overwrite_Disk
     (S : in out Editor.State.State_Type);

end Editor.Executor.File_Conflict_Commands;
