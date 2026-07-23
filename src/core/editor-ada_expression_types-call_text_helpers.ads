with Editor.Ada_Call_Resolution;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Expression_Types.Call_Text_Helpers is

   function Formal_List_Text (Label : String) return String;
   function Count_Names_In_Formal (Names : String) return Natural;
   function Name_At_In_Formal (Names : String; Index : Positive) return String;
   function Clean_Formal_Subtype (Text : String) return String;
   function Formal_Subtype_By_Position
     (Callable_Label : String; Position : Positive) return String;
   function Formal_Subtype_By_Name (Callable_Label : String; Name : String) return String;
   function Named_Actual_Formal_Name (Text : String) return String;
   function Actual_Expression_Text (Text : String) return String;
   function Extract_Designator_Before_Call (Text : String) return String;
   function Extract_First_Actual_Text (Text : String) return String;
   function Infer_Text_Subtype
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String;
   function Actual_Position_In_Call
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Call : Editor.Ada_Syntax_Tree.Node_Id;
      Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural;
   function Callable_Result_Subtype (Callable_Label : String) return String;
   function Is_Class_Wide_Subtype (Text : String) return Boolean;
   function Looks_Primitive_Call_Designator (Text : String) return Boolean;

end Editor.Ada_Expression_Types.Call_Text_Helpers;
