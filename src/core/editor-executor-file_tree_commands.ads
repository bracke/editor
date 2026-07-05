with Editor.Commands;
with Editor.Command_Execution;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.State;

package Editor.Executor.File_Tree_Commands is

   function File_Tree_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Refresh_File_Tree
     (S : in out Editor.State.State_Type);

   procedure Execute_Refresh_Project_Files
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Files_Summary
     (S : in out Editor.State.State_Type);

   procedure Execute_Reveal_Active_File_In_Tree
     (S : in out Editor.State.State_Type);

   function Execute_File_Tree_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_Focus_File_Tree
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Move_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Move_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Page_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Page_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Node_Action
     (S      : in out Editor.State.State_Type;
      Node   : Editor.File_Tree.File_Tree_Node_Id;
      Action : Editor.File_Tree_View.File_Tree_Action);

   procedure Execute_File_Tree_Action
     (S   : in out Editor.State.State_Type;
      Hit : Editor.File_Tree_View.File_Tree_Hit_Result);

   procedure Execute_File_Tree_Create_File
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   procedure Execute_File_Tree_Create_Directory
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   procedure Execute_File_Tree_Rename_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   procedure Execute_File_Tree_Delete_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   procedure Execute_File_Tree_Expand_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Collapse_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Toggle_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Collapse_All
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Expand_To_Active_File
     (S : in out Editor.State.State_Type);

   procedure Execute_File_Tree_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.File_Tree_Commands;
