with Editor.Commands;
with Editor.File_Tree;
with Editor.State;

package Editor.Executor.File_Tree_Mutation_Commands is

   procedure Execute_File_Tree_Create_File
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);
   procedure Execute_File_Tree_Create_Directory
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);
   procedure Execute_File_Tree_Rename_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   function File_Tree_Input_Text
     (Cmd : Editor.Commands.Command) return String;

   function Delete_Confirmation_Accepted
     (Kind    : Editor.File_Tree.File_Tree_Node_Kind;
      Confirm : String) return Boolean;

   function Directory_Is_Empty
     (Path : String) return Boolean;

   function File_Tree_Source_Matches_Filesystem
     (Summary : Editor.File_Tree.File_Tree_Node_Summary) return Boolean;

   function File_Tree_Source_Project_Bounded
     (S       : Editor.State.State_Type;
      Summary : Editor.File_Tree.File_Tree_Node_Summary) return Boolean;

   procedure Select_File_Tree_Path
     (S    : in out Editor.State.State_Type;
      Path : String);

   function Selected_File_Tree_Node_Summary
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.File_Tree.File_Tree_Node_Summary;

   function Same_Or_Descendant_File_Tree_Path
     (Path : String;
      Root : String) return Boolean;

   function Open_Buffer_Blocks_File_Tree_Mutation
     (S          : Editor.State.State_Type;
      Source     : String;
      For_Delete : Boolean := False) return Boolean;

   function Refresh_File_Tree_Model_After_Operation
     (S : in out Editor.State.State_Type) return Boolean;

   function File_Tree_Outcome_Kind_Label
     (Kind : Editor.File_Tree.File_Tree_Node_Kind) return String;

   procedure Invalidate_Project_State_After_File_Tree_Mutation
     (S        : in out Editor.State.State_Type;
      Old_Path : String;
      New_Path : String := "");

end Editor.Executor.File_Tree_Mutation_Commands;
