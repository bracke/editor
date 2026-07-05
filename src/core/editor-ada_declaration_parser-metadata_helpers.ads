with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Metadata_Helpers is

   function Has_Access_Subprogram_Metadata (Line : String) return Boolean;

   function Has_Entry_Family_Metadata (Line : String) return Boolean;

   function Has_Class_Wide_Metadata (Line : String) return Boolean;

   function Generic_Formal_Type_Family_From_Line
     (Line : String) return Editor.Ada_Language_Model.Generic_Formal_Type_Family;

   function First_Non_Blank_Column (Line : String) return Positive;

end Editor.Ada_Declaration_Parser.Metadata_Helpers;
