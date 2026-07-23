with Editor.State;

package Editor.Executor.Quick_Open_Create_Commands is

   procedure Execute_Quick_Open_Create_From_Query
     (S : in out Editor.State.State_Type);

   procedure Execute_Quick_Open_Create_With_Parents_From_Query
     (S : in out Editor.State.State_Type);

end Editor.Executor.Quick_Open_Create_Commands;
