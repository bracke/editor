with Editor.Commands;
with Editor.Executor.Search_Commands;
with Editor.State;

package body Editor.Executor.Project_Search_Surface_Commands is

   procedure Execute_Open_Project_Search_Bar
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Open_Project_Search_Bar;

   procedure Execute_Toggle_Project_Search_Bar
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Toggle_Project_Search_Bar;

   procedure Execute_Close_Project_Search_Bar
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Close_Project_Search_Bar;

   procedure Execute_Run_Project_Search_From_Bar
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Run_Project_Search_From_Bar;

   procedure Execute_Project_Search_Bar_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Bar_Insert_Text;

   procedure Execute_Project_Search_Bar_Backspace
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Bar_Backspace;

   procedure Execute_Project_Search_Bar_Delete_Forward
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Bar_Delete_Forward;

   procedure Execute_Project_Search_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
      renames Editor.Executor.Search_Commands.Execute_Project_Search_Kind;

end Editor.Executor.Project_Search_Surface_Commands;
