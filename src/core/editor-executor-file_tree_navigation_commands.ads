with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.State;

package Editor.Executor.File_Tree_Navigation_Commands is

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

end Editor.Executor.File_Tree_Navigation_Commands;
