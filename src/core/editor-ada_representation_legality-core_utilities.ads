with Editor.Ada_Syntax_Tree;
with Editor.Ada_Language_Model;

package Editor.Ada_Representation_Legality.Core_Utilities is

   function Mix (A, B : Natural) return Natural;

   function Trimmed (Text : String) return String;

   function Lower (Text : String) return String;

   function Normalized (Text : String) return String;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String;

   function Attribute_Name (Target_Text : String) return String;

   function Strip_Leading_At (Text : String) return String;

   function Range_First (Text : String) return String;

   function Range_Last (Text : String) return String;

   function Ancestor_Representation_Clause
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return Editor.Ada_Syntax_Tree.Node_Id;

   function Declaration_Name
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String;

   function Name_List_Contains (List_Text, Name : String) return Boolean;

   function Has_Record_Component
     (Tree           : Editor.Ada_Syntax_Tree.Tree_Type;
      Record_Type    : Editor.Ada_Syntax_Tree.Node_Id;
      Component_Name : String) return Boolean;

   function Clause_Kind
     (Target_Text : String;
      Item_Text   : String;
      Full_Text   : String) return Editor.Ada_Language_Model.Representation_Clause_Kind;

end Editor.Ada_Representation_Legality.Core_Utilities;
