with Editor.Ada_Syntax_Core;

package Editor.Ada_Declaration_Parser.Line_Metadata is

   function Has_Default_Expression_Metadata
     (Line : String) return Boolean;

   function Has_Entry_Family_Metadata
     (Line : String) return Boolean;

   function Has_Profile_Mode_Metadata
     (Line : String) return Boolean;

   function Has_Entry_Barrier_Metadata
     (Line : String) return Boolean;

   function Has_Class_Wide_Metadata
     (Line : String) return Boolean;

   function Has_Named_Number_Metadata
     (Line : String) return Boolean;

   function Has_Deferred_Constant_Metadata
     (Line : String) return Boolean;

   function Has_Null_Subprogram_Metadata
     (Line : String) return Boolean;

   function Has_Expression_Function_Metadata
     (Line : String) return Boolean;

   function Has_Null_Record_Metadata
     (Line : String) return Boolean;

   function Has_Discriminant_Part_Metadata
     (Line : String) return Boolean;

   function Has_Body_Stub_Metadata
     (Line : String) return Boolean;

   function Has_Constraint_Metadata
     (Line : String) return Boolean;

   function Has_Child_Unit_Metadata
     (Line : String) return Boolean;

   function Has_Generic_Actual_Part_Metadata
     (Line : String) return Boolean;

end Editor.Ada_Declaration_Parser.Line_Metadata;
