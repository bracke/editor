with Editor.Ada_Declarative_Regions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Expression_Types.Operator_Helpers is

   function Operator_Symbol_From_Text (Text : String) return String;
   function Is_Relational_Operator (Symbol : String) return Boolean;
   function Is_Boolean_Operator (Symbol : String) return Boolean;
   function Is_Numeric_Operator (Symbol : String) return Boolean;
   function Is_Integer_Family (Subtype_Name : String) return Boolean;
   function Is_Real_Family (Subtype_Name : String) return Boolean;
   function Is_Numeric_Family (Subtype_Name : String) return Boolean;
   function Is_String_Family (Subtype_Name : String) return Boolean;
   function Is_Character_Family (Subtype_Name : String) return Boolean;
   function Is_Array_Family
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Subtype_Name : String) return Boolean;
   function Simple_Subtype_Compatible (Left : String; Right : String) return Boolean;
   function Looks_Range_Choice (Text : String) return Boolean;
   procedure Set_Boolean_Result (Info : in out Expression_Type_Info);

end Editor.Ada_Expression_Types.Operator_Helpers;
