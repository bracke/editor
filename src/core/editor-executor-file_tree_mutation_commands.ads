with Editor.Commands.Payloads;
with Ada.Strings.Unbounded;
with Editor.File_Tree;
with Editor.State;

package Editor.Executor.File_Tree_Mutation_Commands is
   function File_Tree_Input_Text
     (Cmd : Editor.Commands.Payloads.Command) return String;

   function Contains_Control_File_Tree_Input_Character
     (Value : String) return Boolean;

   function Contains_Parent_Traversal
     (Value : String) return Boolean;

   function Contains_Current_Directory_Segment
     (Value : String) return Boolean;

   function Has_Trailing_Path_Separator
     (Value : String) return Boolean;

   function Contains_Empty_Relative_Path_Segment
     (Value : String) return Boolean;

   function Is_Windows_Drive_Qualified_File_Tree_Input
     (Value : String) return Boolean;

   function Is_Windows_Drive_Absolute_File_Tree_Input
     (Value : String) return Boolean;

   function File_Tree_Input_Is_Absolute
     (Input : String) return Boolean;

   function Absolute_File_Tree_Input_Message
     (S     : Editor.State.State_Type;
      Input : String) return String;

   function File_Tree_Input_Has_Explicit_Directory
     (Input : String) return Boolean;

   function Selected_File_Tree_Base_Directory
     (S           : Editor.State.State_Type;
      Found       : out Boolean) return String;

   function Project_Bounded_File_Tree_Target
     (S      : Editor.State.State_Type;
      Input  : String;
      Base   : String;
      Target : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;

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

   function File_Tree_Parent_Directory_Available
     (S    : Editor.State.State_Type;
      Target : String) return Boolean;

   procedure Update_Active_Buffer_After_File_Tree_Rename
     (S        : in out Editor.State.State_Type;
      Old_Path : String;
      New_Path : String);

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
