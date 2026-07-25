with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Representation_Legality.Core_Utilities;
with Editor.Ada_Representation_Legality.Clause_Classification;
with Editor.Ada_Representation_Legality.Target_Compatibility;
with Editor.Ada_Representation_Legality.Static_Value_Checks;

package body Editor.Ada_Representation_Legality.Static_Value_Checks is

   pragma Suppress (Overflow_Check);

   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Kind;
   use type Editor.Ada_Freezing_Points.Representation_Freezing_Status;
   use type Editor.Ada_Freezing_Points.Freezing_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Language_Model.Representation_Clause_Kind;
   use type Editor.Ada_Language_Model.Representation_Source_Form;

   function Mix (A, B : Natural) return Natural
     renames Editor.Ada_Representation_Legality.Core_Utilities.Mix;

   function Trimmed (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Trimmed;

   function Lower (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Lower;

   function Normalized (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Normalized;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Child_Label;

   function Declaration_Name
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Declaration_Name;

   function Name_List_Contains (List_Text, Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Core_Utilities.Name_List_Contains;

   function Has_Record_Component
     (Tree           : Editor.Ada_Syntax_Tree.Tree_Type;
      Record_Type    : Editor.Ada_Syntax_Tree.Node_Id;
      Component_Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Core_Utilities.Has_Record_Component;

   function Strip_Leading_At (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Strip_Leading_At;

   function Range_First (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Range_First;

   function Range_Last (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Range_Last;

   function Check_For_Clause
     (Model  : Representation_Legality_Model;
      Clause : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Legality_Info
     renames Editor.Ada_Representation_Legality.Check_For_Clause;

   function Interfacing_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Interfacing_Clause;

   function Stream_Attribute_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Stream_Attribute_Clause;

   function Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Operational_Clause;

   function Boolean_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Boolean_Operational_Clause;

   function Order_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Order_Operational_Clause;


   function Is_Known_Convention (Name : String) return Boolean is
      N : constant String := Lower (Name);
   begin
      return N = "ada" or else N = "intrinsic" or else N = "c"
        or else N = "c_pass_by_copy" or else N = "cobol"
        or else N = "fortran" or else N = "assembler"
        or else N = "stdcall" or else N = "win32" or else N = "cpp";
   end Is_Known_Convention;

   function Is_Identifier_Text (Text : String) return Boolean is
      T : constant String := Trimmed (Text);
   begin
      if T = "" then
         return False;
      end if;
      if not (T (T'First) in 'A' .. 'Z' or else T (T'First) in 'a' .. 'z') then
         return False;
      end if;
      for I in T'First + 1 .. T'Last loop
         if not (T (I) in 'A' .. 'Z' or else T (I) in 'a' .. 'z'
                 or else T (I) in '0' .. '9' or else T (I) = '_') then
            return False;
         end if;
      end loop;
      return True;
   end Is_Identifier_Text;

   function Is_Static_String_Text (Text : String) return Boolean is
      T : constant String := Trimmed (Text);
   begin
      return T'Length >= 2 and then T (T'First) = '"' and then T (T'Last) = '"';
   end Is_Static_String_Text;

   function Is_Static_Boolean_True (Text : String) return Boolean is
      T : constant String := Lower (Text);
   begin
      return T = "true" or else T = "standard.true";
   end Is_Static_Boolean_True;

   function Is_Static_Boolean_False (Text : String) return Boolean is
      T : constant String := Lower (Text);
   begin
      return T = "false" or else T = "standard.false";
   end Is_Static_Boolean_False;

   function Is_High_Order_First (Text : String) return Boolean is
      T : constant String := Lower (Text);
   begin
      return T = "high_order_first" or else T = "system.high_order_first";
   end Is_High_Order_First;

   function Is_Low_Order_First (Text : String) return Boolean is
      T : constant String := Lower (Text);
   begin
      return T = "low_order_first" or else T = "system.low_order_first";
   end Is_Low_Order_First;

   function Operational_Value_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Operational_Value_Status is
      T : constant String := Trimmed (Text);
   begin
      if not Operational_Clause (Kind) then
         return Operational_Value_Not_Operational_Clause;
      elsif T = "" then
         return Operational_Value_Malformed;
      elsif Boolean_Operational_Clause (Kind) then
         if Is_Static_Boolean_True (T) then
            return Operational_Value_Static_Boolean_True;
         elsif Is_Static_Boolean_False (T) then
            return Operational_Value_Static_Boolean_False;
         else
            return Operational_Value_Malformed;
         end if;
      elsif Order_Operational_Clause (Kind) then
         if Is_High_Order_First (T) then
            return Operational_Value_Order_High_Order_First;
         elsif Is_Low_Order_First (T) then
            return Operational_Value_Order_Low_Order_First;
         else
            return Operational_Value_Malformed;
         end if;
      else
         return Operational_Value_Not_Operational_Clause;
      end if;
   end Operational_Value_Status_For;

   function Interfacing_Value_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Interfacing_Value_Status is
      T : constant String := Trimmed (Text);
   begin
      if not Interfacing_Clause (Kind) then
         return Interfacing_Value_Not_Interfacing_Clause;
      elsif T = "" then
         return Interfacing_Value_Malformed;
      end if;

      case Kind is
         when Editor.Ada_Language_Model.Representation_Convention_Clause =>
            if not Is_Identifier_Text (T) then
               return Interfacing_Value_Malformed;
            elsif Is_Known_Convention (T) then
               return Interfacing_Value_Convention_Identifier;
            else
               return Interfacing_Value_Convention_Unknown_Identifier;
            end if;
         when Editor.Ada_Language_Model.Representation_Import_Clause |
              Editor.Ada_Language_Model.Representation_Export_Clause =>
            if Is_Static_Boolean_True (T) then
               return Interfacing_Value_Static_Boolean_True;
            elsif Is_Static_Boolean_False (T) then
               return Interfacing_Value_Static_Boolean_False;
            else
               return Interfacing_Value_Malformed;
            end if;
         when Editor.Ada_Language_Model.Representation_External_Name_Clause |
              Editor.Ada_Language_Model.Representation_Link_Name_Clause =>
            if Is_Static_String_Text (T) then
               return Interfacing_Value_Static_String;
            else
               return Interfacing_Value_Malformed;
            end if;
         when others =>
            return Interfacing_Value_Not_Interfacing_Clause;
      end case;
   end Interfacing_Value_Status_For;

   function Starts_With_Digit_Or_Sign (Text : String) return Boolean is
      T : constant String := Trimmed (Text);
   begin
      if T = "" then
         return False;
      end if;

      return T (T'First) in '0' .. '9'
        or else T (T'First) = '+'
        or else T (T'First) = '-';
   end Starts_With_Digit_Or_Sign;

   function Stream_Subprogram_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Stream_Subprogram_Status is
      T : constant String := Trimmed (Text);
      L : constant String := Lower (T);
   begin
      if not Stream_Attribute_Clause (Kind) then
         return Stream_Subprogram_Not_Stream_Clause;
      elsif T = "" then
         return Stream_Subprogram_Malformed;
      elsif Is_Static_String_Text (T) or else Starts_With_Digit_Or_Sign (T)
        or else L = "null" or else L = "true" or else L = "false"
      then
         return Stream_Subprogram_Malformed;
      elsif Ada.Strings.Fixed.Index (L, "(") /= 0
        or else Ada.Strings.Fixed.Index (L, ";") /= 0
      then
         return Stream_Subprogram_Malformed;
      elsif Is_Identifier_Text (T)
        or else Ada.Strings.Fixed.Index (T, ".") /= 0
      then
         --  The parser-level model can prove that the representation item is
         --  a callable designator.  Full profile matching is layered through
         --  subsequent call/profile metadata and is therefore preserved as
         --  unknown rather than silently accepted as profile-conformant.
         return Stream_Subprogram_Profile_Unknown;
      else
         return Stream_Subprogram_Unknown;
      end if;
   end Stream_Subprogram_Status_For;

   function Address_Value_Status_For (Text : String) return Address_Value_Status is
      T : constant String := Trimmed (Strip_Leading_At (Text));
      L : constant String := Lower (T);
   begin
      if T = "" then
         return Address_Value_Malformed;
      elsif L = "null" then
         return Address_Value_Null_Literal;
      elsif Ada.Strings.Fixed.Index (L, "'address") /= 0
        or else Ada.Strings.Fixed.Index (L, "to_address") /= 0
      then
         return Address_Value_Static_Address;
      elsif Starts_With_Digit_Or_Sign (T) then
         return Address_Value_Raw_Literal;
      else
         return Address_Value_Non_Static_Name;
      end if;
   end Address_Value_Status_For;

   function Value_Status_For
     (Value : Editor.Ada_Static_Expressions.Static_Value_Info) return Representation_Value_Status is
   begin
      case Value.Status is
         when Editor.Ada_Static_Expressions.Static_Value_Integer |
              Editor.Ada_Static_Expressions.Static_Value_Static_Attribute |
              Editor.Ada_Static_Expressions.Static_Value_Modular_Integer =>
            return Representation_Value_Static_Integer;
         when Editor.Ada_Static_Expressions.Static_Value_Real |
              Editor.Ada_Static_Expressions.Static_Value_Fixed_Point =>
            return Representation_Value_Static_Real;
         when Editor.Ada_Static_Expressions.Static_Value_Division_By_Zero =>
            return Representation_Value_Division_By_Zero;
         when Editor.Ada_Static_Expressions.Static_Value_Malformed =>
            return Representation_Value_Malformed;
         when Editor.Ada_Static_Expressions.Static_Value_Unresolved_Name =>
            return Representation_Value_Unresolved;
         when Editor.Ada_Static_Expressions.Static_Value_Unsupported_Attribute =>
            return Representation_Value_Unsupported;
         when others =>
            return Representation_Value_Non_Static;
      end case;
   end Value_Status_For;

end Editor.Ada_Representation_Legality.Static_Value_Checks;
