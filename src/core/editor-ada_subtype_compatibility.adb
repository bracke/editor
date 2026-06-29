with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Type_Graph;
with Editor.Ada_Private_View_Visibility;

package body Editor.Ada_Subtype_Compatibility is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Type_Graph.Type_View_Status;

   function To_Unbounded_String (Value : String)
      return Ada.Strings.Unbounded.Unbounded_String
      renames Ada.Strings.Unbounded.To_Unbounded_String;

   function Hash_Text (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         Result := Natural
           ((Long_Long_Integer (Result) * 131
             + Long_Long_Integer
               (Character'Pos (Ada.Characters.Handling.To_Lower (C))) + 1)
            mod Long_Long_Integer (Natural'Last));
      end loop;
      return Result;
   end Hash_Text;

   function Normalize_Subtype_Name (Text : String) return String is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
      Lowered : constant String := Ada.Characters.Handling.To_Lower (Trimmed);
      Result  : String (Lowered'Range) := Lowered;
   begin
      --  Collapse the most common subtype-mark spelling noise used by parser
      --  recovery and profile extraction.  This is intentionally not a full
      --  name resolver; selected names and renamings are handled by later
      --  semantic layers before this helper is asked for compatibility.
      for I in Result'Range loop
         if Result (I) = ASCII.HT or else Result (I) = ASCII.CR or else Result (I) = ASCII.LF then
            Result (I) := ' ';
         end if;
      end loop;
      return Ada.Strings.Fixed.Trim (Result, Ada.Strings.Both);
   end Normalize_Subtype_Name;

   function Classify_Numeric_Family (Normalized_Name : String) return Numeric_Family is
      Name : constant String := Normalize_Subtype_Name (Normalized_Name);
   begin
      if Name = "universal_integer" or else Name = "root_integer" then
         return Numeric_Family_Universal_Integer;
      elsif Name = "universal_real" or else Name = "root_real" then
         return Numeric_Family_Universal_Real;
      elsif Name = "integer" or else Name = "natural" or else Name = "positive"
        or else Name = "short_integer" or else Name = "long_integer"
        or else Name = "long_long_integer"
      then
         return Numeric_Family_Discrete_Integer;
      elsif Name = "mod" or else Name = "modular_integer" then
         return Numeric_Family_Modular_Integer;
      elsif Name = "float" or else Name = "long_float" or else Name = "long_long_float"
        or else Name = "short_float"
      then
         return Numeric_Family_Real_Floating;
      elsif Name = "duration" then
         return Numeric_Family_Real_Fixed;
      elsif Name = "boolean" then
         return Numeric_Family_Boolean;
      else
         return Numeric_Family_None;
      end if;
   end Classify_Numeric_Family;

   function Check
     (Expected_Subtype : String;
      Actual_Subtype   : String) return Compatibility_Info
   is
      Expected : constant String := Normalize_Subtype_Name (Expected_Subtype);
      Actual   : constant String := Normalize_Subtype_Name (Actual_Subtype);
      Info     : Compatibility_Info;
   begin
      Info.Expected_Subtype := To_Unbounded_String (Expected_Subtype);
      Info.Actual_Subtype := To_Unbounded_String (Actual_Subtype);
      Info.Normalized_Expected := To_Unbounded_String (Expected);
      Info.Normalized_Actual := To_Unbounded_String (Actual);
      Info.Expected_Family := Classify_Numeric_Family (Expected);
      Info.Actual_Family := Classify_Numeric_Family (Actual);

      if Expected = "" or else Actual = "" then
         Info.Status := Subtype_Compatibility_Indeterminate;
      elsif Expected = Actual then
         Info.Status := Subtype_Compatibility_Exact_Match;
      elsif Info.Actual_Family = Numeric_Family_Universal_Integer
        and then (Info.Expected_Family = Numeric_Family_Discrete_Integer
                  or else Info.Expected_Family = Numeric_Family_Modular_Integer)
      then
         Info.Status := Subtype_Compatibility_Universal_Integer_To_Integer;
      elsif Info.Actual_Family = Numeric_Family_Universal_Real
        and then (Info.Expected_Family = Numeric_Family_Real_Floating
                  or else Info.Expected_Family = Numeric_Family_Real_Fixed)
      then
         Info.Status := Subtype_Compatibility_Universal_Real_To_Real;
      elsif Info.Actual_Family = Numeric_Family_Universal_Integer
        and then (Info.Expected_Family = Numeric_Family_Real_Floating
                  or else Info.Expected_Family = Numeric_Family_Real_Fixed)
      then
         Info.Status := Subtype_Compatibility_Universal_Integer_To_Real;
      elsif Info.Expected_Family /= Numeric_Family_None
        and then Info.Actual_Family /= Numeric_Family_None
      then
         Info.Status := Subtype_Compatibility_Known_Incompatible;
      else
         Info.Status := Subtype_Compatibility_Indeterminate;
      end if;

      Info.Fingerprint :=
        Natural
          ((Long_Long_Integer (Compatibility_Status'Pos (Info.Status)) * 1_000_003
            + Long_Long_Integer (Numeric_Family'Pos (Info.Expected_Family)) * 10_007
            + Long_Long_Integer (Numeric_Family'Pos (Info.Actual_Family)) * 1_009
            + Long_Long_Integer (Hash_Text (Expected)) * 131
            + Long_Long_Integer (Hash_Text (Actual)))
           mod Long_Long_Integer (Natural'Last));
      return Info;
   end Check;



   function Ends_With (Text : String; Suffix : String) return Boolean is
      T : constant String := Normalize_Subtype_Name (Text);
      S : constant String := Normalize_Subtype_Name (Suffix);
   begin
      return T'Length >= S'Length
        and then T (T'Last - S'Length + 1 .. T'Last) = S;
   end Ends_With;

   function Class_Wide_Root_Name (Text : String) return String is
      T : constant String := Normalize_Subtype_Name (Text);
   begin
      if Ends_With (T, "'class") then
         if T'Length <= 6 then
            return "";
         end if;
         return T (T'First .. T'Last - 6);
      else
         return T;
      end if;
   end Class_Wide_Root_Name;

   procedure Apply_Graph_Status
     (Info         : in out Compatibility_Info;
      Graph_Status : Editor.Ada_Type_Graph.Compatibility_Status) is
   begin
      case Graph_Status is
         when Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type =>
            Info.Status := Subtype_Compatibility_Type_Graph_Exact;
         when Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of =>
            Info.Status := Subtype_Compatibility_Type_Graph_Subtype_Of;
         when Editor.Ada_Type_Graph.Type_Compatibility_Derived_From =>
            Info.Status := Subtype_Compatibility_Type_Graph_Derived_From;
         when Editor.Ada_Type_Graph.Type_Compatibility_Class_Wide =>
            Info.Status := Subtype_Compatibility_Type_Graph_Class_Wide;
         when Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root =>
            Info.Status := Subtype_Compatibility_Known_Incompatible;
         when others =>
            null;
      end case;
   end Apply_Graph_Status;

   function Resolve_Type
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Subtype_Name : String) return Editor.Ada_Type_Graph.Type_Id is
   begin
      if Ends_With (Subtype_Name, "'class") then
         return Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Class_Wide_Root_Name (Subtype_Name));
      else
         return Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Subtype_Name);
      end if;
   end Resolve_Type;

   function Check_With_Type_Graph
     (Types            : Editor.Ada_Type_Graph.Type_Model;
      Expected_Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region    : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtype : String;
      Actual_Subtype   : String) return Compatibility_Info
   is
      Info : Compatibility_Info := Check (Expected_Subtype, Actual_Subtype);
      Expected_Type : constant Editor.Ada_Type_Graph.Type_Id :=
        Resolve_Type (Types, Expected_Region, Expected_Subtype);
      Actual_Type : constant Editor.Ada_Type_Graph.Type_Id :=
        Resolve_Type (Types, Actual_Region, Actual_Subtype);
      Graph_Status : Editor.Ada_Type_Graph.Compatibility_Status;
   begin
      if Is_Decided (Info) then
         return Info;
      elsif Expected_Type = Editor.Ada_Type_Graph.No_Type
        or else Actual_Type = Editor.Ada_Type_Graph.No_Type
      then
         return Info;
      end if;

      if Ends_With (Expected_Subtype, "'class") then
         Graph_Status := Editor.Ada_Type_Graph.Class_Wide_Compatibility
           (Types, Expected_Type, Actual_Type);
      else
         Graph_Status := Editor.Ada_Type_Graph.Compatibility
           (Types, Expected_Type, Actual_Type);
      end if;
      case Graph_Status is
         when Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type =>
            Info.Status := Subtype_Compatibility_Type_Graph_Exact;
         when Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of =>
            Info.Status := Subtype_Compatibility_Type_Graph_Subtype_Of;
         when Editor.Ada_Type_Graph.Type_Compatibility_Derived_From =>
            Info.Status := Subtype_Compatibility_Type_Graph_Derived_From;
         when Editor.Ada_Type_Graph.Type_Compatibility_Class_Wide =>
            Info.Status := Subtype_Compatibility_Type_Graph_Class_Wide;
         when Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root =>
            Info.Status := Subtype_Compatibility_Known_Incompatible;
         when others =>
            null;
      end case;

      Info.Fingerprint :=
        (Info.Fingerprint * 65599
         + Natural (Expected_Type) * 101
         + Natural (Actual_Type) * 53
         + Editor.Ada_Type_Graph.Compatibility_Status'Pos (Graph_Status) * 17)
        mod Natural'Last;
      return Info;
   end Check_With_Type_Graph;


   function Check_With_Private_View
     (Types            : Editor.Ada_Type_Graph.Type_Model;
      Private_Views    : Editor.Ada_Private_View_Visibility.Private_View_Model;
      Regions          : Editor.Ada_Declarative_Regions.Region_Model;
      Expected_Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region    : Editor.Ada_Declarative_Regions.Region_Id;
      Context_Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Source_Line      : Positive;
      Expected_Subtype : String;
      Actual_Subtype   : String) return Compatibility_Info
   is
      use type Editor.Ada_Type_Graph.Type_Id;
      Info : Compatibility_Info := Check (Expected_Subtype, Actual_Subtype);
      Expected_Type : constant Editor.Ada_Type_Graph.Type_Id :=
        Resolve_Type (Types, Expected_Region, Expected_Subtype);
      Actual_Type : constant Editor.Ada_Type_Graph.Type_Id :=
        Resolve_Type (Types, Actual_Region, Actual_Subtype);
      Effective_Expected : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Private_View_Visibility.Effective_Type_At_Line
          (Private_Views, Regions, Expected_Type, Context_Region, Source_Line);
      Effective_Actual : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Private_View_Visibility.Effective_Type_At_Line
          (Private_Views, Regions, Actual_Type, Context_Region, Source_Line);
      Graph_Status : Editor.Ada_Type_Graph.Compatibility_Status;
   begin
      if Expected_Type = Editor.Ada_Type_Graph.No_Type
        or else Actual_Type = Editor.Ada_Type_Graph.No_Type
      then
         return Info;
      end if;

      if Effective_Expected /= Editor.Ada_Type_Graph.No_Type
        and then Effective_Expected = Effective_Actual
        and then
          (Editor.Ada_Type_Graph.Type_Node (Types, Effective_Expected).View_Status =
             Editor.Ada_Type_Graph.Type_View_Private_Full
           or else Editor.Ada_Type_Graph.Type_Node (Types, Effective_Expected).View_Status =
             Editor.Ada_Type_Graph.Type_View_Private_Partial)
      then
         declare
            View : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_Node (Types, Effective_Expected);
         begin
            if View.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Full then
               Info.Status := Subtype_Compatibility_Private_View_Full_View;
            else
               Info.Status := Subtype_Compatibility_Private_View_Partial_View;
            end if;
         end;
      elsif Effective_Expected /= Expected_Type or else Effective_Actual /= Actual_Type then
         if Effective_Expected = Editor.Ada_Type_Graph.No_Type
           or else Effective_Actual = Editor.Ada_Type_Graph.No_Type
         then
            Info.Status := Subtype_Compatibility_Private_View_Hidden_Full_View;
         elsif Effective_Expected = Effective_Actual then
            declare
               View : constant Editor.Ada_Type_Graph.Type_Info :=
                 Editor.Ada_Type_Graph.Type_Node (Types, Effective_Expected);
            begin
               if View.View_Status = Editor.Ada_Type_Graph.Type_View_Private_Full then
                  Info.Status := Subtype_Compatibility_Private_View_Full_View;
               else
                  Info.Status := Subtype_Compatibility_Private_View_Partial_View;
               end if;
            end;
         elsif Ends_With (Expected_Subtype, "'class") then
            Graph_Status := Editor.Ada_Type_Graph.Class_Wide_Compatibility
              (Types, Effective_Expected, Effective_Actual);
            Apply_Graph_Status (Info, Graph_Status);
         else
            Graph_Status := Editor.Ada_Type_Graph.Compatibility
              (Types, Effective_Expected, Effective_Actual);
            Apply_Graph_Status (Info, Graph_Status);
         end if;
      elsif not Is_Decided (Info) then
         if Ends_With (Expected_Subtype, "'class") then
            Graph_Status := Editor.Ada_Type_Graph.Class_Wide_Compatibility
              (Types, Effective_Expected, Effective_Actual);
         else
            Graph_Status := Editor.Ada_Type_Graph.Compatibility
              (Types, Effective_Expected, Effective_Actual);
         end if;
         Apply_Graph_Status (Info, Graph_Status);
      end if;

      Info.Fingerprint :=
        (Info.Fingerprint * 65599
         + Natural (Expected_Type) * 197
         + Natural (Actual_Type) * 193
         + Natural (Effective_Expected) * 191
         + Natural (Effective_Actual) * 181
         + Natural (Context_Region) * 173
         + Source_Line * 167) mod Natural'Last;
      return Info;
   end Check_With_Private_View;

   function Is_Compatible (Info : Compatibility_Info) return Boolean is
   begin
      return Info.Status = Subtype_Compatibility_Exact_Match
        or else Info.Status = Subtype_Compatibility_Universal_Integer_To_Integer
        or else Info.Status = Subtype_Compatibility_Universal_Real_To_Real
        or else Info.Status = Subtype_Compatibility_Universal_Integer_To_Real
        or else Info.Status = Subtype_Compatibility_Type_Graph_Exact
        or else Info.Status = Subtype_Compatibility_Type_Graph_Subtype_Of
        or else Info.Status = Subtype_Compatibility_Type_Graph_Derived_From
        or else Info.Status = Subtype_Compatibility_Type_Graph_Class_Wide
        or else Info.Status = Subtype_Compatibility_Private_View_Partial_View
        or else Info.Status = Subtype_Compatibility_Private_View_Full_View;
   end Is_Compatible;

   function Is_Decided (Info : Compatibility_Info) return Boolean is
   begin
      return Info.Status /= Subtype_Compatibility_Not_Checked
        and then Info.Status /= Subtype_Compatibility_Indeterminate;
   end Is_Decided;

end Editor.Ada_Subtype_Compatibility;
