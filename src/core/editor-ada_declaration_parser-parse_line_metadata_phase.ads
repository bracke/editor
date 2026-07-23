with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase is

   procedure Mark_Declaration_Form_Metadata
     (Flags : in out Editor.Ada_Language_Model.Declaration_Flags;
      Line  : String);

   procedure Mark_Type_Qualifier_Metadata
     (Flags : in out Editor.Ada_Language_Model.Declaration_Flags;
      Line  : String);

   function Generic_Formal_Object_Flags
     (Line : String) return Editor.Ada_Language_Model.Declaration_Flags;

end Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase;
