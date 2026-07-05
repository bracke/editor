package Editor.Ada_Declaration_Parser.Target_Helpers is

   function Skip_Component_Qualifiers
     (Line  : String;
      Start : Natural) return Natural;

   function Array_Element_Target (Line : String) return String;

   function Access_Object_Target (Line : String) return String;

   function Object_Target_After_Colon (Line : String) return String;

end Editor.Ada_Declaration_Parser.Target_Helpers;
