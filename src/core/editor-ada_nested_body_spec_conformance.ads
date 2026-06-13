with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Body_Spec_Conformance;
with Editor.Ada_Language_Model;
with Editor.Ada_Project_Index;

package Editor.Ada_Nested_Body_Spec_Conformance is

   --  Snapshot-owned nested declaration conformance projection for matching
   --  body/spec pairs.  This package consumes only project-index and
   --  body/spec conformance metadata; it performs no file IO, parsing,
   --  rendering work, or editor-state mutation.

   type Nested_Conformance_Id is new Natural;
   No_Nested_Conformance : constant Nested_Conformance_Id := 0;

   type Nested_Body_Spec_Conformance_Status is
     (Nested_Body_Spec_Confirmed,
      Nested_Body_Spec_Profile_Confirmed,
      Nested_Body_Spec_Package_Confirmed,
      Nested_Body_Spec_Missing_Body_Declaration,
      Nested_Body_Spec_Extra_Body_Declaration,
      Nested_Body_Spec_Ambiguous_Body_Declaration,
      Nested_Body_Spec_Kind_Mismatch,
      Nested_Body_Spec_Profile_Mismatch,
      Nested_Body_Spec_Profile_Unknown,
      Nested_Body_Spec_Nonconforming_Unit_Pair,
      Nested_Body_Spec_Not_Applicable);

   type Nested_Body_Spec_Conformance_Info is record
      Id                 : Nested_Conformance_Id := No_Nested_Conformance;
      Status             : Nested_Body_Spec_Conformance_Status :=
        Nested_Body_Spec_Not_Applicable;
      Unit_Conformance   : Natural := 0;
      Spec_Unit_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Body_Unit_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Path          : Ada.Strings.Unbounded.Unbounded_String;
      Body_Path          : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Symbol        : Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Language_Model.No_Symbol;
      Body_Symbol        : Editor.Ada_Language_Model.Symbol_Id :=
        Editor.Ada_Language_Model.No_Symbol;
      Declaration_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Kind          : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
      Body_Kind          : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
      Spec_Profile       : Ada.Strings.Unbounded.Unbounded_String;
      Body_Profile       : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Range         : Editor.Ada_Language_Model.Source_Range;
      Body_Range         : Editor.Ada_Language_Model.Source_Range;
      Candidate_Count    : Natural := 0;
      Fingerprint        : Natural := 0;
   end record;

   package Nested_Conformance_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Nested_Body_Spec_Conformance_Info);

   type Nested_Body_Spec_Conformance_Model is private;

   function Build
     (Index       : Editor.Ada_Project_Index.Index_State;
      Conformance : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model)
      return Nested_Body_Spec_Conformance_Model;

   function Conformance_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Conformance_At
     (Model : Nested_Body_Spec_Conformance_Model;
      Index : Positive) return Nested_Body_Spec_Conformance_Info;

   function First_For_Name
     (Model : Nested_Body_Spec_Conformance_Model;
      Name  : String) return Nested_Body_Spec_Conformance_Info;

   function Count_Status
     (Model  : Nested_Body_Spec_Conformance_Model;
      Status : Nested_Body_Spec_Conformance_Status) return Natural;

   function Confirmed_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Missing_Body_Declaration_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Extra_Body_Declaration_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Ambiguous_Body_Declaration_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Kind_Mismatch_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Profile_Mismatch_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Profile_Unknown_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Nonconforming_Unit_Pair_Count
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

   function Fingerprint
     (Model : Nested_Body_Spec_Conformance_Model) return Natural;

private
   type Nested_Body_Spec_Conformance_Model is record
      Items             : Nested_Conformance_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Nested_Body_Spec_Conformance;
