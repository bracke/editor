package Editor.Ada_Declaration_Parser.Target_Helpers is

   function Skip_Component_Qualifiers
     (Line  : String;
      Start : Natural) return Natural;

   function Array_Element_Target (Line : String) return String;

   function Access_Subprogram_Profile (Line : String) return String;

   function Access_Object_Target (Line : String) return String;

   function Object_Target_After_Colon (Line : String) return String;

   function Return_Target_From_Position
     (Line  : String;
      Start : Natural) return String;

   function Return_Target_From_Line_Start (Line : String) return String;

   function Function_Return_Target (Line : String) return String;

   function Interface_Parent_Target (Line : String) return String;

   function Interface_Target_From_Line_Start (Line : String) return String;

   function Subtype_Target_After_Is (Line : String) return String;

end Editor.Ada_Declaration_Parser.Target_Helpers;
