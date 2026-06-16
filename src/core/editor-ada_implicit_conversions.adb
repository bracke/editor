with Editor.Ada_Subtype_Compatibility;

package body Editor.Ada_Implicit_Conversions is

   pragma Suppress (Overflow_Check);

   function Classify
     (Compatibility : Editor.Ada_Subtype_Compatibility.Compatibility_Info)
      return Implicit_Conversion_Info
   is
      use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
      Info : Implicit_Conversion_Info;
   begin
      Info.Compatibility := Compatibility.Status;

      case Compatibility.Status is
         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Exact_Match
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Exact
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Subtype_Of =>
            Info.Status := Implicit_Conversion_Same_Type;

         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Integer_To_Integer
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Real_To_Real
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Universal_Integer_To_Real =>
            Info.Status := Implicit_Conversion_Universal_Numeric;

         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Class_Wide =>
            Info.Status := Implicit_Conversion_Class_Wide;

         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Full_View =>
            Info.Status := Implicit_Conversion_Same_Type;

         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Partial_View
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Private_View_Hidden_Full_View =>
            Info.Status := Implicit_Conversion_Indeterminate;

         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Derived_From =>
            Info.Status := Implicit_Conversion_No_Derived_Type_Conversion;

         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Known_Incompatible =>
            Info.Status := Implicit_Conversion_No_Known_Different_Root;

         when Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Not_Checked
            | Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Indeterminate =>
            Info.Status := Implicit_Conversion_Indeterminate;
      end case;

      Info.Fingerprint :=
        (Editor.Ada_Subtype_Compatibility.Compatibility_Status'Pos (Info.Compatibility) * 1000003
         + Implicit_Conversion_Status'Pos (Info.Status) * 1009
         + Compatibility.Fingerprint * 17) mod Natural'Last;
      return Info;
   end Classify;

   function Is_Implicitly_Allowed
     (Info : Implicit_Conversion_Info) return Boolean is
   begin
      return Info.Status = Implicit_Conversion_Same_Type
        or else Info.Status = Implicit_Conversion_Universal_Numeric
        or else Info.Status = Implicit_Conversion_Class_Wide;
   end Is_Implicitly_Allowed;

   function Is_Decided
     (Info : Implicit_Conversion_Info) return Boolean is
   begin
      return Info.Status /= Implicit_Conversion_Not_Checked
        and then Info.Status /= Implicit_Conversion_Indeterminate;
   end Is_Decided;

end Editor.Ada_Implicit_Conversions;
