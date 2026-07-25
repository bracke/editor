with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Representation_Legality.Enumeration_Checks is

   function Is_Enumeration_Type_Node
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return Boolean;
   function Enumeration_Definition_Text
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return String;
   function Enumeration_Definition_Count (Definition : String) return Natural;
   function Enumeration_Definition_Name_At
     (Definition : String;
      Position   : Positive) return String;
   function Enumeration_Literal_Count
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural;
   function Enumeration_Literal_Name_At
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Position  : Positive) return String;
   function Enumeration_Literal_Exists
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Name      : String) return Boolean;
   function Enumeration_Literal_Position
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Name      : String) return Natural;
   function Enumeration_Literal_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Normalized_Name : String) return Boolean;
   function Enumeration_Value_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Static_Value  : Long_Long_Integer) return Boolean;
   procedure Count_Enumeration_Result
     (Model : in out Representation_Legality_Model;
      Info  : Enumeration_Representation_Legality_Info);
   procedure Add_Enumeration_Check
     (Model           : in out Representation_Legality_Model;
      Tree            : Editor.Ada_Syntax_Tree.Tree_Type;
      Static          : Editor.Ada_Static_Expressions.Static_Model;
      Parent_Info     : Representation_Legality_Info;
      Association     : Editor.Ada_Syntax_Tree.Node_Info;
      Literal_Name    : String;
      Value_Text      : String;
      Expected_Pos    : Natural;
      Target_Type_Node : Editor.Ada_Syntax_Tree.Node_Id);
   procedure Add_Enumeration_Incomplete_Check
     (Model           : in out Representation_Legality_Model;
      Parent_Info     : Representation_Legality_Info;
      Missing_Literal  : String;
      Source_Line      : Positive);
   procedure Add_Enumeration_Representation_Checks
     (Model    : in out Representation_Legality_Model;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Clause   : Editor.Ada_Syntax_Tree.Node_Info;
      Parent_Info : Representation_Legality_Info);

end Editor.Ada_Representation_Legality.Enumeration_Checks;
