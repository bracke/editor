with Editor.Ada_Subtype_Compatibility;

package Editor.Ada_Implicit_Conversions is

   --  Compiler-grade type-checking staging layer.  This package classifies
   --  whether a subtype compatibility result is usable by Ada's implicit
   --  conversion rules in an expected-type context.  It intentionally keeps
   --  derived-type ancestry distinct from subtype compatibility because Ada
   --  requires an explicit conversion between distinct specific types.

   type Implicit_Conversion_Status is
     (Implicit_Conversion_Not_Checked,
      Implicit_Conversion_Same_Type,
      Implicit_Conversion_Universal_Numeric,
      Implicit_Conversion_Class_Wide,
      Implicit_Conversion_No_Derived_Type_Conversion,
      Implicit_Conversion_No_Known_Different_Root,
      Implicit_Conversion_Indeterminate);

   type Implicit_Conversion_Info is record
      Compatibility : Editor.Ada_Subtype_Compatibility.Compatibility_Status :=
        Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Not_Checked;
      Status        : Implicit_Conversion_Status :=
        Implicit_Conversion_Not_Checked;
      Fingerprint   : Natural := 0;
   end record;

   function Classify
     (Compatibility : Editor.Ada_Subtype_Compatibility.Compatibility_Info)
      return Implicit_Conversion_Info;

   function Is_Implicitly_Allowed
     (Info : Implicit_Conversion_Info) return Boolean;

   function Is_Decided
     (Info : Implicit_Conversion_Info) return Boolean;

end Editor.Ada_Implicit_Conversions;
