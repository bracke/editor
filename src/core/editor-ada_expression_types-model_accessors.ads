with Editor.Ada_Syntax_Tree;

package Editor.Ada_Expression_Types.Model_Accessors is

   function Has_Expression_Types (Model : Expression_Type_Model) return Boolean;
   function Expression_Type_Count (Model : Expression_Type_Model) return Natural;

   function Expression_Type_At
     (Model : Expression_Type_Model;
      Index : Positive) return Expression_Type_Info;

   function Expression_Type
     (Model : Expression_Type_Model;
      Id    : Expression_Type_Id) return Expression_Type_Info;

   function Expression_Type_For_Node
     (Model : Expression_Type_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expression_Type_Info;

   function Count_Status
     (Model  : Expression_Type_Model;
      Status : Expression_Type_Status) return Natural;

end Editor.Ada_Expression_Types.Model_Accessors;
