with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Metadata_Helpers is

   function Has_Access_Subprogram_Metadata (Line : String) return Boolean;

   function Has_Access_Protected_Metadata (Line : String) return Boolean;

   function Has_Aliased_Metadata (Line : String) return Boolean;

   function Has_Incomplete_Type_Metadata (Line : String) return Boolean;

   function Has_Entry_Family_Metadata (Line : String) return Boolean;

   function Has_Class_Wide_Metadata (Line : String) return Boolean;

   function Has_Aspect_Specification (Line : String) return Boolean;

   function Representation_Clause_Target (Line : String) return String;

   function Clean_Metadata_Name (Name : String) return String;

   procedure Mark_Declaration_Form_Metadata
     (Flags : in out Editor.Ada_Language_Model.Declaration_Flags;
      Line  : String);

   procedure Mark_Type_Qualifier_Metadata
     (Flags : in out Editor.Ada_Language_Model.Declaration_Flags;
      Line  : String);

   procedure Mark_Pragma_Target
     (Analysis      : in out Editor.Ada_Language_Model.Analysis_Result;
      Line          : String;
      Current_Scope : Editor.Ada_Language_Model.Symbol_Id := Editor.Ada_Language_Model.No_Symbol);

   function Generic_Formal_Type_Family_From_Line
     (Line : String) return Editor.Ada_Language_Model.Generic_Formal_Type_Family;

   function Is_Scope_End (Lower_Line : String) return Boolean;

   function First_Non_Blank_Column (Line : String) return Positive;

end Editor.Ada_Declaration_Parser.Metadata_Helpers;
