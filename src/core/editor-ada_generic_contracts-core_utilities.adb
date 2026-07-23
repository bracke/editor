with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;
with Editor.Text_Helpers;

package body Editor.Ada_Generic_Contracts.Core_Utilities is

   use type Editor.Ada_Syntax_Tree.Node_Kind;

   function Trim (Text : String) return String
     renames Editor.Text_Helpers.Trim;

   function Normalize (Text : String) return String
     renames Editor.Text_Helpers.Normalize;

   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Pattern'Length = 0
        or else Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer;
      Modulus    : Long_Long_Integer := Long_Long_Integer (Natural'Last))
      return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Modulus);
   end Hash_Mix;

   function Hash_Text (Text : String) return Natural is
      H : Natural := 2166136261 mod Natural'Last;
   begin
      for C of Text loop
         H := Hash_Mix
           (H, Long_Long_Integer (Character'Pos (C)) + 1, 16_777_619);
      end loop;
      return H;
   end Hash_Text;

   procedure Mix
     (Model : in out Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Value : Natural)
   is
   begin
      Model.Result_Fingerprint :=
        Hash_Mix (Model.Result_Fingerprint, Long_Long_Integer (Value) + 197, 65_599);
   end Mix;

   function Empty_Formal
     return Editor.Ada_Generic_Contracts.Generic_Formal_Info
   is
   begin
      return (Id => Editor.Ada_Generic_Contracts.No_Generic_Formal,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Kind => Editor.Ada_Generic_Contracts.Generic_Formal_Unknown,
              Has_Default => False,
              Default_Text => Null_Unbounded_String,
              Formal_Parameter_Count => 0,
              Formal_Parameter_Subtypes => Null_Unbounded_String,
              Formal_Parameter_Modes => Null_Unbounded_String,
              Formal_Parameter_Names => Null_Unbounded_String,
              Formal_Parameter_Defaults => Null_Unbounded_String,
              Formal_Subprogram_Convention => Null_Unbounded_String,
              Formal_Has_Result => False,
              Formal_Result_Subtype => Null_Unbounded_String,
              Formal_Package_Generic_Name => Null_Unbounded_String,
              Formal_Package_Normalized_Generic => Null_Unbounded_String,
              Formal_Package_Has_Box => False,
              Status => Editor.Ada_Generic_Contracts.Generic_Formal_Unsupported,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Formal;

   function Empty_Instance
     return Editor.Ada_Generic_Contracts.Generic_Instance_Info
   is
   begin
      return (Id => Editor.Ada_Generic_Contracts.No_Generic_Instance,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Generic_Name => Null_Unbounded_String,
              Normalized_Generic => Null_Unbounded_String,
              Positional_Actuals => 0,
              Named_Actuals => 0,
              Total_Actuals => 0,
              Named_Actual_Names => Null_Unbounded_String,
              Positional_Actual_Kinds => Null_Unbounded_String,
              Named_Actual_Kinds => Null_Unbounded_String,
              Positional_Actual_Texts => Null_Unbounded_String,
              Named_Actual_Texts => Null_Unbounded_String,
              Status => Editor.Ada_Generic_Contracts.Generic_Instance_Unsupported,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Instance;

   function Empty_Actual_Match
     return Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info
   is
   begin
      return (Id => Editor.Ada_Generic_Contracts.No_Generic_Actual_Match,
              Instance => Editor.Ada_Generic_Contracts.No_Generic_Instance,
              Instance_Node => Editor.Ada_Syntax_Tree.No_Node,
              Instance_Region => Editor.Ada_Declarative_Regions.No_Region,
              Generic_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Generic_Formal_Region => Editor.Ada_Declarative_Regions.No_Region,
              Formal_Count => 0,
              Required_Formals => 0,
              Positional_Actuals => 0,
              Named_Actuals => 0,
              Matched_Formals => 0,
              Defaulted_Formals => 0,
              Unknown_Named_Actuals => 0,
              Duplicate_Named_Actuals => 0,
              Missing_Required_Formals => 0,
              Kind_Compatible_Formals => 0,
              Kind_Mismatched_Formals => 0,
              Kind_Unknown_Formals => 0,
              Subprogram_Profile_Compatible_Formals => 0,
              Subprogram_Profile_Mismatched_Formals => 0,
              Subprogram_Profile_Unknown_Formals => 0,
              Subprogram_Profile_Mode_Mismatched_Formals => 0,
              Subprogram_Profile_Null_Exclusion_Mismatched_Formals => 0,
              Subprogram_Profile_Access_Profile_Mismatched_Formals => 0,
              Subprogram_Profile_Convention_Mismatched_Formals => 0,
              Subprogram_Profile_Default_Mismatched_Formals => 0,
              Subprogram_Profile_Class_Wide_Mismatched_Formals => 0,
              Subprogram_Profile_Name_Mismatched_Formals => 0,
              Subprogram_Profile_Result_Compatible_Formals => 0,
              Subprogram_Profile_Result_Mismatched_Formals => 0,
              Subprogram_Profile_Result_Unknown_Formals => 0,
              Subprogram_Profile_Type_Compatible_Formals => 0,
              Subprogram_Profile_Type_Mismatched_Formals => 0,
              Subprogram_Profile_Type_Unknown_Formals => 0,
              Subprogram_Profile_Overload_Candidates => 0,
              Subprogram_Profile_Overload_Selected_Formals => 0,
              Subprogram_Profile_Overload_Ambiguous_Formals => 0,
              Subprogram_Profile_Overload_Unresolved_Formals => 0,
              Formal_Package_Compatible_Formals => 0,
              Formal_Package_Mismatched_Formals => 0,
              Formal_Package_Unknown_Formals => 0,
              Formal_Package_Unresolved_Formals => 0,
              Formal_Package_Ambiguous_Formals => 0,
              Formal_Package_Not_Instance_Formals => 0,
              Formal_Package_Wrong_Generic_Formals => 0,
              Formal_Package_Contract_Unknown_Formals => 0,
              Formal_Package_Malformed_Formals => 0,
              Default_Expression_Checked_Formals => 0,
              Default_Expression_Static_Formals => 0,
              Default_Expression_Illegal_Formals => 0,
              Default_Expression_Unknown_Formals => 0,
              Default_Expression_Unresolved_Formals => 0,
              Default_Expression_Nonstatic_Formals => 0,
              Default_Expression_Malformed_Formals => 0,
              Default_Expression_Division_By_Zero_Formals => 0,
              Status => Editor.Ada_Generic_Contracts.Generic_Actual_Match_Generic_Not_Found,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Actual_Match;

   function Empty_Body_Contract_Visibility
     return Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Info
   is
   begin
      return (Id => Editor.Ada_Generic_Contracts.No_Generic_Body_Contract_Visibility,
              Generic_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Generic_Node => Editor.Ada_Syntax_Tree.No_Node,
              Generic_Formal_Region => Editor.Ada_Declarative_Regions.No_Region,
              Body_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Body_Node => Editor.Ada_Syntax_Tree.No_Node,
              Body_Region => Editor.Ada_Declarative_Regions.No_Region,
              Name => Null_Unbounded_String,
              Normalized_Name => Null_Unbounded_String,
              Formal_Count => 0,
              Visible_Formals => 0,
              Shadowed_Formals => 0,
              Shadowed_Formal_Names => Null_Unbounded_String,
              Status => Editor.Ada_Generic_Contracts.Generic_Body_Contract_Unsupported,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Body_Contract_Visibility;

   function To_Formal_Kind
     (Kind : Editor.Ada_Direct_Visibility.Declaration_Kind)
      return Editor.Ada_Generic_Contracts.Generic_Formal_Kind
   is
   begin
      case Kind is
         when Editor.Ada_Direct_Visibility.Declaration_Formal_Type =>
            return Editor.Ada_Generic_Contracts.Generic_Formal_Type;
         when Editor.Ada_Direct_Visibility.Declaration_Formal_Object =>
            return Editor.Ada_Generic_Contracts.Generic_Formal_Object;
         when Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram =>
            return Editor.Ada_Generic_Contracts.Generic_Formal_Subprogram;
         when Editor.Ada_Direct_Visibility.Declaration_Formal_Package =>
            return Editor.Ada_Generic_Contracts.Generic_Formal_Package;
         when others =>
            return Editor.Ada_Generic_Contracts.Generic_Formal_Unknown;
      end case;
   end To_Formal_Kind;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
   is
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Parent, Index));
         begin
            if Child.Kind = Kind then
               return To_String (Child.Label);
            end if;
         end;
      end loop;
      return "";
   end Child_Label;

end Editor.Ada_Generic_Contracts.Core_Utilities;
