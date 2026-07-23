with Ada.Strings.Fixed;

with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Line_Metadata;
with Editor.Ada_Declaration_Parser.Metadata_Helpers;
with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase is

   use Editor.Ada_Language_Model;
   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Text_Helpers;

   procedure Mark_Declaration_Form_Metadata
     (Flags : in out Declaration_Flags;
      Line  : String)
   is
      Code : constant String := Normalized_Line (Line);
   begin
      Flags.Has_Access_Metadata := Has_Token (Code, "access");
      Flags.Has_Access_All_Metadata := Has_Token_Pair (Code, "access", "all");
      Flags.Has_Access_Constant_Metadata :=
        Has_Token_Pair (Code, "access", "constant");
      Flags.Has_Class_Wide_Metadata :=
        Metadata_Helpers.Has_Class_Wide_Metadata (Code);
      Flags.Has_Access_Subprogram_Metadata :=
        Has_Token (Code, "access")
        and then Metadata_Helpers.Has_Access_Subprogram_Metadata (Code);
      Flags.Has_Access_Protected_Metadata :=
        Metadata_Helpers.Has_Access_Protected_Metadata (Code);
      Flags.Has_Array_Metadata := Has_Token (Code, "array");
      Flags.Has_Range_Metadata := Has_Token (Code, "range");
      Flags.Has_Modular_Metadata := Has_Token (Code, "mod");
      Flags.Has_Digits_Metadata := Has_Token (Code, "digits");
      Flags.Has_Delta_Metadata := Has_Token (Code, "delta");
      Flags.Has_Variant_Record_Metadata :=
        Has_Token (Code, "record") and then Has_Token (Code, "case");
      Flags.Has_Default_Expression_Metadata :=
        Line_Metadata.Has_Default_Expression_Metadata (Code);
      Flags.Has_Entry_Family_Metadata :=
        Metadata_Helpers.Has_Entry_Family_Metadata (Code);
      Flags.Has_Profile_Mode_Metadata :=
        Line_Metadata.Has_Profile_Mode_Metadata (Code);
      Flags.Has_Entry_Barrier_Metadata :=
        Line_Metadata.Has_Entry_Barrier_Metadata (Code);
      Flags.Has_Box_Metadata := Ada.Strings.Fixed.Index (Code, "<>") /= 0;
      Flags.Has_Named_Number_Metadata :=
        Line_Metadata.Has_Named_Number_Metadata (Code);
      Flags.Has_Null_Subprogram_Metadata :=
        Line_Metadata.Has_Null_Subprogram_Metadata (Code);
      Flags.Has_Expression_Function_Metadata :=
        Line_Metadata.Has_Expression_Function_Metadata (Code);
      Flags.Has_Null_Record_Metadata :=
        Line_Metadata.Has_Null_Record_Metadata (Code);
      Flags.Has_Discriminant_Part_Metadata :=
        Line_Metadata.Has_Discriminant_Part_Metadata (Code);
      Flags.Has_Body_Stub_Metadata :=
        Line_Metadata.Has_Body_Stub_Metadata (Code);
      Flags.Has_Constraint_Metadata :=
        Line_Metadata.Has_Constraint_Metadata (Code);
      Flags.Has_Child_Unit_Metadata :=
        Line_Metadata.Has_Child_Unit_Metadata (Code);
      Flags.Has_Task_Type_Metadata := Has_Token_Pair (Code, "task", "type");
      Flags.Has_Protected_Type_Metadata :=
        Has_Token_Pair (Code, "protected", "type");
   end Mark_Declaration_Form_Metadata;

   procedure Mark_Type_Qualifier_Metadata
     (Flags : in out Declaration_Flags;
      Line  : String)
   is
      Code : constant String := Normalized_Line (Line);
   begin
      Flags.Has_Limited_Metadata := Has_Token (Code, "limited");
      Flags.Has_Tagged_Metadata := Has_Token (Code, "tagged");
      Flags.Has_Interface_Metadata := Has_Token (Code, "interface");
      Flags.Has_Synchronized_Metadata := Has_Token (Code, "synchronized");
      Flags.Has_Task_Interface_Metadata :=
        Has_Token_Pair (Code, "task", "interface");
      Flags.Has_Protected_Interface_Metadata :=
        Has_Token_Pair (Code, "protected", "interface");
      Flags.Has_Task_Type_Metadata := Has_Token_Pair (Code, "task", "type");
      Flags.Has_Protected_Type_Metadata :=
        Has_Token_Pair (Code, "protected", "type");
      Flags.Has_Incomplete_Type_Metadata :=
        Metadata_Helpers.Has_Incomplete_Type_Metadata (Line);
      Flags.Has_Private_Extension_Metadata :=
        Has_Token_Pair (Code, "with", "private");
   end Mark_Type_Qualifier_Metadata;

   function Generic_Formal_Object_Flags
     (Line : String) return Declaration_Flags
   is
      Code : constant String := Normalized_Line (Line);
   begin
      return
        (Is_Generic => True,
         Has_Null_Exclusion => Has_Null_Exclusion (Line),
         Has_Aliased_Metadata => Metadata_Helpers.Has_Aliased_Metadata (Line),
         Has_Limited_Metadata => Has_Token (Code, "limited"),
         Has_Tagged_Metadata => Has_Token (Code, "tagged"),
         Has_Interface_Metadata => Has_Token (Code, "interface"),
         Has_Synchronized_Metadata => Has_Token (Code, "synchronized"),
         Has_Task_Interface_Metadata =>
           Has_Token_Pair (Code, "task", "interface"),
         Has_Protected_Interface_Metadata =>
           Has_Token_Pair (Code, "protected", "interface"),
         Has_Access_Metadata => Has_Token (Code, "access"),
         Has_Access_All_Metadata => Has_Token_Pair (Code, "access", "all"),
         Has_Access_Constant_Metadata =>
           Has_Token_Pair (Code, "access", "constant"),
         Has_Class_Wide_Metadata =>
           Metadata_Helpers.Has_Class_Wide_Metadata (Line),
         Has_Access_Subprogram_Metadata =>
           Has_Token (Code, "access")
           and then Metadata_Helpers.Has_Access_Subprogram_Metadata (Line),
         Has_Access_Protected_Metadata =>
           Metadata_Helpers.Has_Access_Protected_Metadata (Line),
         Has_Array_Metadata => Has_Token (Code, "array"),
         Has_Private_Extension_Metadata =>
           Has_Token_Pair (Code, "with", "private"),
         Has_Range_Metadata => Has_Token (Code, "range"),
         Has_Modular_Metadata => Has_Token (Code, "mod"),
         Has_Digits_Metadata => Has_Token (Code, "digits"),
         Has_Delta_Metadata => Has_Token (Code, "delta"),
         Has_Variant_Record_Metadata =>
           Has_Token (Code, "record") and then Has_Token (Code, "case"),
         Has_Default_Expression_Metadata =>
           Line_Metadata.Has_Default_Expression_Metadata (Line),
         Has_Constraint_Metadata =>
           Line_Metadata.Has_Constraint_Metadata (Line),
         Has_Box_Metadata => Ada.Strings.Fixed.Index (Code, "<>") /= 0,
         others => False);
   end Generic_Formal_Object_Flags;

end Editor.Ada_Declaration_Parser.Parse_Line_Metadata_Phase;
