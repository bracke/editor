with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Generic_Contracts.Core_Utilities;

package body Editor.Ada_Generic_Contracts.Type_Conformance is

   use Editor.Ada_Generic_Contracts.Type_Conformance;
   use type Editor.Ada_Type_Graph.Type_Id;

   function Trim (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Generic_Contracts.Core_Utilities.Normalize;

   function Type_Id_For_Profile_Subtype
     (Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Editor.Ada_Type_Graph.Type_Id
   is
      Wanted : constant String := Normalize (Name);
      Found  : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
   begin
      if Wanted = "" then
         return Editor.Ada_Type_Graph.No_Type;
      end if;

      Found := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Wanted);
      if Found /= Editor.Ada_Type_Graph.No_Type then
         return Found;
      end if;

      for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
         declare
            Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_At (Types, Index);
         begin
            if To_String (Info.Normalized_Name) = Wanted then
               if Found /= Editor.Ada_Type_Graph.No_Type then
                  return Editor.Ada_Type_Graph.No_Type;
               end if;
               Found := Info.Id;
            end if;
         end;
      end loop;

      return Found;
   end Type_Id_For_Profile_Subtype;

   function Type_Graph_Profile_Subtypes_Conform
     (Types             : Editor.Ada_Type_Graph.Type_Model;
      Formal_Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtypes : String;
      Actual_Subtypes   : String)
      return Editor.Ada_Generic_Contracts.Type_Conformance.Profile_Type_Conformance_Status
   is
      Expected_First : Natural := Expected_Subtypes'First;
      Actual_First   : Natural := Actual_Subtypes'First;
      Saw_Type_Graph_Relation : Boolean := False;

      function Next_Field
        (Text  : String;
         First : in out Natural;
         Field : out Unbounded_String) return Boolean
      is
         Sep  : Natural;
         Last : Natural;
      begin
         Field := Null_Unbounded_String;
         if Text = "" or else First > Text'Last then
            return False;
         end if;
         Sep := Ada.Strings.Fixed.Index (Text (First .. Text'Last), "|");
         Last := Text'Last;
         if Sep /= 0 then
            Last := Sep - 1;
         end if;
         Field := To_Unbounded_String (Normalize (Text (First .. Last)));
         if Sep = 0 then
            First := Text'Last + 1;
         else
            First := Sep + 1;
         end if;
         return True;
      end Next_Field;
   begin
      if Expected_Subtypes = Actual_Subtypes then
         return Profile_Type_Conformance_Compatible;
      end if;

      loop
         declare
            Expected_Field : Unbounded_String;
            Actual_Field   : Unbounded_String;
            Has_Expected   : constant Boolean :=
              Next_Field (Expected_Subtypes, Expected_First, Expected_Field);
            Has_Actual     : constant Boolean :=
              Next_Field (Actual_Subtypes, Actual_First, Actual_Field);
         begin
            if Has_Expected /= Has_Actual then
               return Profile_Type_Conformance_Mismatch;
            elsif not Has_Expected then
               exit;
            elsif To_String (Expected_Field) = To_String (Actual_Field) then
               null;
            else
               declare
                  Expected_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                    Type_Id_For_Profile_Subtype
                      (Types, Formal_Region, To_String (Expected_Field));
                  Actual_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                    Type_Id_For_Profile_Subtype
                      (Types, Actual_Region, To_String (Actual_Field));
               begin
                  if Expected_Type = Editor.Ada_Type_Graph.No_Type
                    or else Actual_Type = Editor.Ada_Type_Graph.No_Type
                  then
                     return Profile_Type_Conformance_Unknown;
                  end if;

                  case Editor.Ada_Type_Graph.Compatibility
                    (Types, Expected_Type, Actual_Type)
                  is
                     when Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type
                        | Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of =>
                        Saw_Type_Graph_Relation := True;
                     when Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root =>
                        return Profile_Type_Conformance_Mismatch;
                     when others =>
                        return Profile_Type_Conformance_Unknown;
                  end case;
               end;
            end if;
         end;
      end loop;

      if Saw_Type_Graph_Relation then
         return Profile_Type_Conformance_Compatible;
      else
         return Profile_Type_Conformance_Unknown;
      end if;
   end Type_Graph_Profile_Subtypes_Conform;

   function Type_Graph_Result_Subtype_Conforms
     (Types             : Editor.Ada_Type_Graph.Type_Model;
      Formal_Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtype : String;
      Actual_Subtype   : String)
      return Editor.Ada_Generic_Contracts.Type_Conformance.Profile_Type_Conformance_Status
   is
      Expected : constant String := Normalize (Expected_Subtype);
      Actual   : constant String := Normalize (Actual_Subtype);
      Expected_Type : Editor.Ada_Type_Graph.Type_Id;
      Actual_Type : Editor.Ada_Type_Graph.Type_Id;

      function Builtin_Root (Name : String) return String is
         N : constant String := Normalize (Name);
      begin
         if N = "integer" or else N = "natural" or else N = "positive" then
            return "integer";
         elsif N = "float" or else N = "long_float" or else N = "short_float" then
            return "float";
         elsif N = "string" then
            return "string";
         else
            return "";
         end if;
      end Builtin_Root;

      function Type_Info_For_Id
        (Id : Editor.Ada_Type_Graph.Type_Id) return Editor.Ada_Type_Graph.Type_Info
      is
      begin
         for Index in 1 .. Editor.Ada_Type_Graph.Type_Count (Types) loop
            declare
               Info : constant Editor.Ada_Type_Graph.Type_Info :=
                 Editor.Ada_Type_Graph.Type_At (Types, Index);
            begin
               if Info.Id = Id then
                  return Info;
               end if;
            end;
         end loop;
         return Editor.Ada_Type_Graph.Type_At (Types, 1);
      end Type_Info_For_Id;

      function Has_Class (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
      begin
         return Ada.Strings.Fixed.Index (Lower, "'class") /= 0;
      end Has_Class;

      function Strip_Class (Text : String) return String is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Normalize (Text));
         Pos   : constant Natural := Ada.Strings.Fixed.Index (Lower, "'class");
      begin
         if Pos = 0 then
            return Lower;
         else
            return Trim (Lower (Lower'First .. Pos - 1));
         end if;
      end Strip_Class;
   begin
      if Expected = Actual then
         return Profile_Type_Conformance_Compatible;
      elsif Expected = "" or else Actual = "" then
         return Profile_Type_Conformance_Unknown;
      end if;

      if Has_Class (Actual) and then not Has_Class (Expected) then
         return Profile_Type_Conformance_Mismatch;
      end if;

      Expected_Type := Type_Id_For_Profile_Subtype (Types, Formal_Region, Strip_Class (Expected));
      Actual_Type := Type_Id_For_Profile_Subtype (Types, Actual_Region, Strip_Class (Actual));
      if Expected_Type = Editor.Ada_Type_Graph.No_Type
        and then Actual_Type /= Editor.Ada_Type_Graph.No_Type
      then
         declare
            Actual_Info : constant Editor.Ada_Type_Graph.Type_Info :=
              Type_Info_For_Id (Actual_Type);
         begin
            if To_String (Actual_Info.Normalized_Base) = Strip_Class (Expected) then
               return Profile_Type_Conformance_Compatible;
            end if;
         end;
      elsif Expected_Type = Editor.Ada_Type_Graph.No_Type
        and then Actual_Type = Editor.Ada_Type_Graph.No_Type
        and then Builtin_Root (Expected) /= ""
        and then Builtin_Root (Actual) /= ""
        and then Builtin_Root (Expected) /= Builtin_Root (Actual)
      then
         return Profile_Type_Conformance_Mismatch;
      end if;
      if Expected_Type = Editor.Ada_Type_Graph.No_Type
        or else Actual_Type = Editor.Ada_Type_Graph.No_Type
      then
         return Profile_Type_Conformance_Unknown;
      end if;

      if Has_Class (Expected) then
         case Editor.Ada_Type_Graph.Class_Wide_Compatibility
           (Types, Expected_Type, Actual_Type)
         is
            when Editor.Ada_Type_Graph.Type_Compatibility_Class_Wide
               | Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type
               | Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of =>
               return Profile_Type_Conformance_Compatible;
            when Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root =>
               return Profile_Type_Conformance_Mismatch;
            when others =>
               return Profile_Type_Conformance_Unknown;
         end case;
      end if;

      case Editor.Ada_Type_Graph.Compatibility (Types, Expected_Type, Actual_Type) is
         when Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type
            | Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of =>
            return Profile_Type_Conformance_Compatible;
         when Editor.Ada_Type_Graph.Type_Compatibility_Known_Different_Root =>
            return Profile_Type_Conformance_Mismatch;
         when others =>
            return Profile_Type_Conformance_Unknown;
      end case;
   end Type_Graph_Result_Subtype_Conforms;

end Editor.Ada_Generic_Contracts.Type_Conformance;
