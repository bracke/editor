with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Project_Index;

package Editor.Ada_Body_Spec_Conformance is

   --  Snapshot-owned body/spec declaration conformance projection.
   --  This package consumes the project index and already-built cross-unit
   --  closure.  It does not perform file IO, parsing, rendering mutation, or
   --  workspace mutation.

   type Body_Spec_Conformance_Status is
     (Body_Spec_Conformance_Confirmed,
      Body_Spec_Conformance_Package_Confirmed,
      Body_Spec_Conformance_Subprogram_Profile_Confirmed,
      Body_Spec_Conformance_Missing_Counterpart,
      Body_Spec_Conformance_Ambiguous_Counterpart,
      Body_Spec_Conformance_Overflow,
      Body_Spec_Conformance_Role_Mismatch,
      Body_Spec_Conformance_Name_Mismatch,
      Body_Spec_Conformance_Profile_Mismatch,
      Body_Spec_Conformance_Profile_Unknown,
      Body_Spec_Conformance_Not_Applicable);

   type Body_Spec_Conformance_Info is record
      Status            : Body_Spec_Conformance_Status :=
        Body_Spec_Conformance_Not_Applicable;
      Spec_Unit_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Path         : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Role         : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Body_Unit_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Body_Path         : Ada.Strings.Unbounded.Unbounded_String;
      Body_Role         : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Spec_Profile      : Ada.Strings.Unbounded.Unbounded_String;
      Body_Profile      : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Count   : Natural := 0;
      Fingerprint       : Natural := 0;
   end record;

   package Body_Spec_Conformance_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Body_Spec_Conformance_Info);

   type Body_Spec_Conformance_Model is private;

   function Build
     (Index   : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model)
      return Body_Spec_Conformance_Model;

   function Conformance_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Conformance_At
     (Model : Body_Spec_Conformance_Model;
      Index : Positive) return Body_Spec_Conformance_Info;

   function Confirmed_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Package_Confirmed_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Subprogram_Profile_Confirmed_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Missing_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Ambiguous_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Overflow_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Role_Mismatch_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Name_Mismatch_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Profile_Mismatch_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Profile_Unknown_Count
     (Model : Body_Spec_Conformance_Model) return Natural;

   function Fingerprint
     (Model : Body_Spec_Conformance_Model) return Natural;

private
   type Body_Spec_Conformance_Model is record
      Items             : Body_Spec_Conformance_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Body_Spec_Conformance;
