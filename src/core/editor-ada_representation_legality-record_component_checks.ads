with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Representation_Legality.Record_Component_Checks is

   function Component_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Normalized_Name : String) return Boolean;
   procedure Count_Component_Result
     (Model : in out Representation_Legality_Model;
      Info  : Record_Component_Legality_Info);
   procedure Add_Record_Component_Check
     (Model  : in out Representation_Legality_Model;
      Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Types  : Editor.Ada_Type_Graph.Type_Model;
      Static : Editor.Ada_Static_Expressions.Static_Model;
      Node   : Editor.Ada_Syntax_Tree.Node_Info);

end Editor.Ada_Representation_Legality.Record_Component_Checks;
