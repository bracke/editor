package Editor.Ada_Syntax_Tree.Line_Classifier is

   function Classify_Line (Line : String) return Node_Kind;
   function Opens_Scope (Kind : Node_Kind; Code : String) return Boolean;
   function Is_End_Node (Kind : Node_Kind) return Boolean;
   function Is_Alternative_Node (Kind : Node_Kind) return Boolean;
   function Expected_End_Label (Kind : Node_Kind) return String;

end Editor.Ada_Syntax_Tree.Line_Classifier;
