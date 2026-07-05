with Editor.Commands;
with Editor.State;

package Editor.Executor.Project_Search_Surface_Commands is

   procedure Execute_Open_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Run_Project_Search_From_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Bar_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Project_Search_Bar_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Bar_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Project_Search_Surface_Commands;
