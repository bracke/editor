package Editor.Ada_Declaration_Parser.Same_Line_Declarations is

   function Has_Same_Line_Subtype_Group
     (Raw_Line   : String;
      Decl_Lower : String) return Boolean;

   function Has_Same_Line_Type_Group
     (Raw_Line   : String;
      Decl_Lower : String) return Boolean;

end Editor.Ada_Declaration_Parser.Same_Line_Declarations;
