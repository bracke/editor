with Editor.Ada_Language_Model;
with Editor.Syntax;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Language_Model.Syntax_Attachment is

   procedure Set_Syntax_Tree
     (Analysis : in out Analysis_Result;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type);

   function Has_Syntax_Tree (Analysis : Analysis_Result) return Boolean;
   function Syntax_Tree_Node_Count (Analysis : Analysis_Result) return Natural;
   function Syntax_Tree_Root_Kind
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Node_Kind;
   function Syntax_Tree_Fingerprint (Analysis : Analysis_Result) return Natural;
   function Syntax_Tree
     (Analysis : Analysis_Result) return Editor.Ada_Syntax_Tree.Tree_Type;

   function Fingerprint (Analysis : Analysis_Result) return Natural;


end Editor.Ada_Language_Model.Syntax_Attachment;
