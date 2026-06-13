with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Type_Graph;
with Editor.Ada_Private_View_Visibility;

package Editor.Ada_Subtype_Compatibility is

   --  Compiler-grade type-checking foundation.  This package classifies the
   --  subtype-name compatibility cases and, when supplied, the declaration-
   --  derived type graph relationships available in the current snapshot.  It
   --  is deliberately conservative: unknown/private/cross-unit relationships
   --  remain indeterminate until later semantic passes provide those models.

   type Numeric_Family is
     (Numeric_Family_None,
      Numeric_Family_Discrete_Integer,
      Numeric_Family_Modular_Integer,
      Numeric_Family_Real_Floating,
      Numeric_Family_Real_Fixed,
      Numeric_Family_Universal_Integer,
      Numeric_Family_Universal_Real);

   type Compatibility_Status is
     (Subtype_Compatibility_Not_Checked,
      Subtype_Compatibility_Exact_Match,
      Subtype_Compatibility_Universal_Integer_To_Integer,
      Subtype_Compatibility_Universal_Real_To_Real,
      Subtype_Compatibility_Universal_Integer_To_Real,
      Subtype_Compatibility_Type_Graph_Exact,
      Subtype_Compatibility_Type_Graph_Subtype_Of,
      Subtype_Compatibility_Type_Graph_Derived_From,
      Subtype_Compatibility_Type_Graph_Class_Wide,
      Subtype_Compatibility_Private_View_Partial_View,
      Subtype_Compatibility_Private_View_Full_View,
      Subtype_Compatibility_Private_View_Hidden_Full_View,
      Subtype_Compatibility_Known_Incompatible,
      Subtype_Compatibility_Indeterminate);

   type Compatibility_Info is record
      Expected_Subtype    : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Expected : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Actual   : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Family     : Numeric_Family := Numeric_Family_None;
      Actual_Family       : Numeric_Family := Numeric_Family_None;
      Status              : Compatibility_Status := Subtype_Compatibility_Not_Checked;
      Fingerprint         : Natural := 0;
   end record;

   function Normalize_Subtype_Name (Text : String) return String;

   function Classify_Numeric_Family (Normalized_Name : String) return Numeric_Family;

   function Check
     (Expected_Subtype : String;
      Actual_Subtype   : String) return Compatibility_Info;

   function Check_With_Type_Graph
     (Types            : Editor.Ada_Type_Graph.Type_Model;
      Expected_Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region    : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtype : String;
      Actual_Subtype   : String) return Compatibility_Info;

   function Check_With_Private_View
     (Types            : Editor.Ada_Type_Graph.Type_Model;
      Private_Views    : Editor.Ada_Private_View_Visibility.Private_View_Model;
      Regions          : Editor.Ada_Declarative_Regions.Region_Model;
      Expected_Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region    : Editor.Ada_Declarative_Regions.Region_Id;
      Context_Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Source_Line      : Positive;
      Expected_Subtype : String;
      Actual_Subtype   : String) return Compatibility_Info;

   function Is_Compatible (Info : Compatibility_Info) return Boolean;

   function Is_Decided (Info : Compatibility_Info) return Boolean;

end Editor.Ada_Subtype_Compatibility;
