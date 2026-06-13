with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Visibility;
with Editor.Ada_Limited_View_Rules;
with Editor.Ada_Private_With_Rules;
with Editor.Ada_Body_Spec_Conformance;
with Editor.Ada_Child_Unit_Visibility;
with Editor.Ada_Separate_Body_Stub_Rules;
with Editor.Ada_Nested_Body_Spec_Conformance;

package Editor.Ada_Cross_Unit_Diagnostics is

   --  Projection-only diagnostics for cross-unit semantic closure and
   --  visibility rules.  This package consumes already-built snapshot-owned
   --  cross-unit metadata and emits deterministic diagnostics.  It performs
   --  no parsing, file IO, editor mutation, command registration, or rendering
   --  work.

   type Cross_Unit_Diagnostic_Id is new Natural;
   No_Cross_Unit_Diagnostic : constant Cross_Unit_Diagnostic_Id := 0;

   type Cross_Unit_Diagnostic_Severity is
     (Cross_Unit_Diagnostic_Severity_Info,
      Cross_Unit_Diagnostic_Warning,
      Cross_Unit_Diagnostic_Error);

   type Cross_Unit_Diagnostic_Kind is
     (Cross_Unit_Diagnostic_Missing_Dependency,
      Cross_Unit_Diagnostic_Ambiguous_Dependency,
      Cross_Unit_Diagnostic_Limited_View_Full_View_Hidden,
      Cross_Unit_Diagnostic_Private_With_Hidden,
      Cross_Unit_Diagnostic_Body_Spec_Missing,
      Cross_Unit_Diagnostic_Body_Spec_Ambiguous,
      Cross_Unit_Diagnostic_Body_Spec_Mismatch,
      Cross_Unit_Diagnostic_Private_Child_Hidden,
      Cross_Unit_Diagnostic_Child_Parent_Error,
      Cross_Unit_Diagnostic_Separate_Stub_Missing,
      Cross_Unit_Diagnostic_Separate_Parent_Error,
      Cross_Unit_Diagnostic_Nested_Body_Spec_Missing,
      Cross_Unit_Diagnostic_Nested_Body_Spec_Extra,
      Cross_Unit_Diagnostic_Nested_Body_Spec_Ambiguous,
      Cross_Unit_Diagnostic_Nested_Body_Spec_Mismatch,
      Cross_Unit_Diagnostic_Nested_Body_Spec_Unknown,
      Cross_Unit_Diagnostic_Cross_Unit_Unknown);

   type Cross_Unit_Diagnostic_Info is record
      Id       : Cross_Unit_Diagnostic_Id := No_Cross_Unit_Diagnostic;
      Kind     : Cross_Unit_Diagnostic_Kind := Cross_Unit_Diagnostic_Cross_Unit_Unknown;
      Severity : Cross_Unit_Diagnostic_Severity := Cross_Unit_Diagnostic_Warning;
      Source_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Nested_Conformance : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Conformance_Id :=
        Editor.Ada_Nested_Body_Spec_Conformance.No_Nested_Conformance;
      Nested_Status : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Status :=
        Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Not_Applicable;
      Declaration_Name : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint  : Natural := 0;
   end record;

   type Cross_Unit_Diagnostic_Model is private;

   procedure Clear (Model : in out Cross_Unit_Diagnostic_Model);

   function Build
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Limited_View    : Editor.Ada_Limited_View_Rules.Limited_View_Model;
      Private_W  : Editor.Ada_Private_With_Rules.Private_With_Model;
      Body_Spec  : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
      Children   : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Separates  : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model)
      return Cross_Unit_Diagnostic_Model;

   function Build_With_Nested
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Limited_View    : Editor.Ada_Limited_View_Rules.Limited_View_Model;
      Private_W  : Editor.Ada_Private_With_Rules.Private_With_Model;
      Body_Spec  : Editor.Ada_Body_Spec_Conformance.Body_Spec_Conformance_Model;
      Children   : Editor.Ada_Child_Unit_Visibility.Child_Visibility_Model;
      Separates  : Editor.Ada_Separate_Body_Stub_Rules.Separate_Body_Stub_Model;
      Nested     : Editor.Ada_Nested_Body_Spec_Conformance.Nested_Body_Spec_Conformance_Model)
      return Cross_Unit_Diagnostic_Model;

   function Has_Diagnostics (Model : Cross_Unit_Diagnostic_Model) return Boolean;
   function Diagnostic_Count (Model : Cross_Unit_Diagnostic_Model) return Natural;
   function Diagnostic_At
     (Model : Cross_Unit_Diagnostic_Model;
      Index : Positive) return Cross_Unit_Diagnostic_Info;

   function Error_Count (Model : Cross_Unit_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Cross_Unit_Diagnostic_Model) return Natural;
   function Info_Count (Model : Cross_Unit_Diagnostic_Model) return Natural;
   function Count_Kind
     (Model : Cross_Unit_Diagnostic_Model;
      Kind  : Cross_Unit_Diagnostic_Kind) return Natural;

   function Nested_Body_Spec_Diagnostic_Count
     (Model : Cross_Unit_Diagnostic_Model) return Natural;

   function Nested_Missing_Declaration_Count
     (Model : Cross_Unit_Diagnostic_Model) return Natural;

   function Nested_Extra_Declaration_Count
     (Model : Cross_Unit_Diagnostic_Model) return Natural;

   function Nested_Mismatch_Count
     (Model : Cross_Unit_Diagnostic_Model) return Natural;

   function Fingerprint (Model : Cross_Unit_Diagnostic_Model) return Natural;

private
   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_Diagnostic_Info);

   type Cross_Unit_Diagnostic_Model is record
      Diagnostics        : Diagnostic_Vectors.Vector;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Cross_Unit_Diagnostics;
