with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Project_Index;

package Editor.Ada_Separate_Body_Stub_Rules is

   --  Semantic projection for Ada separate-body/subunit placement rules.
   --  The model consumes parser-owned project-index and cross-unit closure
   --  metadata only; it performs no parsing, no file IO, and no editor-state
   --  mutation.  It verifies that a resolved separate body is backed by a
   --  matching body stub in the resolved parent body unit.

   type Separate_Body_Stub_Status is
     (Separate_Body_Stub_Not_Found,
      Separate_Body_Stub_Matched,
      Separate_Body_Stub_Missing,
      Separate_Body_Stub_Ambiguous,
      Separate_Body_Stub_Kind_Mismatch,
      Separate_Body_Stub_Profile_Mismatch,
      Separate_Body_Stub_Profile_Unknown,
      Separate_Body_Stub_Missing_Parent,
      Separate_Body_Stub_Ambiguous_Parent,
      Separate_Body_Stub_Overflow,
      Separate_Body_Stub_Parent_Role_Mismatch,
      Separate_Body_Stub_Target_Name_Missing);

   type Separate_Body_Stub_Info is record
      Status             : Separate_Body_Stub_Status := Separate_Body_Stub_Not_Found;
      Separate_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Separate_Path      : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Unit_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Path        : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Name_Text   : Ada.Strings.Unbounded.Unbounded_String;
      Stub_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Stub_Path          : Ada.Strings.Unbounded.Unbounded_String;
      Stub_Count         : Natural := 0;
      Candidate_Count    : Natural := 0;
      Fingerprint        : Natural := 0;
   end record;

   package Separate_Body_Stub_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Separate_Body_Stub_Info);

   type Separate_Body_Stub_Model is private;

   function Build
     (Index   : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model)
      return Separate_Body_Stub_Model;

   function Stub_Check_Count (Model : Separate_Body_Stub_Model) return Natural;

   function Stub_Check_At
     (Model : Separate_Body_Stub_Model;
      Index : Positive) return Separate_Body_Stub_Info;

   function Lookup_Separate
     (Model              : Separate_Body_Stub_Model;
      Separate_Unit_Name : String) return Separate_Body_Stub_Info;

   function Matched_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Missing_Stub_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Ambiguous_Stub_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Kind_Mismatch_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Profile_Mismatch_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Profile_Unknown_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Parent_Error_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Missing_Parent_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Ambiguous_Parent_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Overflow_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Target_Name_Missing_Count (Model : Separate_Body_Stub_Model) return Natural;
   function Fingerprint (Model : Separate_Body_Stub_Model) return Natural;

private
   type Separate_Body_Stub_Model is record
      Items             : Separate_Body_Stub_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Separate_Body_Stub_Rules;
