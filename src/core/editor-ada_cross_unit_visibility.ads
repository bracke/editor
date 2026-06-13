with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Closure;
with Editor.Ada_Project_Index;

package Editor.Ada_Cross_Unit_Visibility is

   --  Project-wide visibility projection over cross-unit context closure.
   --  This model is intentionally snapshot-owned: it consumes the already-built
   --  project index and cross-unit closure, records only stable dependency
   --  metadata, and performs no file IO or parsing.

   type Cross_Unit_Visibility_Status is
     (Cross_Unit_Visibility_Not_Found,
      Cross_Unit_Visibility_Visible,
      Cross_Unit_Visibility_Limited_View,
      Cross_Unit_Visibility_Private_View,
      Cross_Unit_Visibility_Use_Package_Visible,
      Cross_Unit_Visibility_Missing,
      Cross_Unit_Visibility_Ambiguous,
      Cross_Unit_Visibility_Overflow);

   type Cross_Unit_Visibility_Info is record
      Status           : Cross_Unit_Visibility_Status :=
        Cross_Unit_Visibility_Not_Found;
      Source_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Target_Path      : Ada.Strings.Unbounded.Unbounded_String;
      Clause_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Is_With          : Boolean := False;
      Is_Use           : Boolean := False;
      Is_Limited       : Boolean := False;
      Is_Private       : Boolean := False;
      Candidate_Count  : Natural := 0;
      Fingerprint      : Natural := 0;
   end record;

   package Cross_Unit_Visibility_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_Visibility_Info);

   type Cross_Unit_Visibility_Model is private;

   function Build
     (Index   : Editor.Ada_Project_Index.Index_State;
      Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model)
      return Cross_Unit_Visibility_Model;

   function Visibility_Count (Model : Cross_Unit_Visibility_Model) return Natural;

   function Visibility_At
     (Model : Cross_Unit_Visibility_Model;
      Index : Positive) return Cross_Unit_Visibility_Info;

   function Lookup_Visible_Unit
     (Model            : Cross_Unit_Visibility_Model;
      Source_Unit_Name : String;
      Name             : String) return Cross_Unit_Visibility_Info;

   function With_Visible_Count (Model : Cross_Unit_Visibility_Model) return Natural;
   function Use_Visible_Count (Model : Cross_Unit_Visibility_Model) return Natural;
   function Limited_View_Count (Model : Cross_Unit_Visibility_Model) return Natural;
   function Private_View_Count (Model : Cross_Unit_Visibility_Model) return Natural;
   function Missing_Count (Model : Cross_Unit_Visibility_Model) return Natural;
   function Ambiguous_Count (Model : Cross_Unit_Visibility_Model) return Natural;
   function Overflow_Count (Model : Cross_Unit_Visibility_Model) return Natural;
   function Fingerprint (Model : Cross_Unit_Visibility_Model) return Natural;

private
   type Cross_Unit_Visibility_Model is record
      Items             : Cross_Unit_Visibility_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Cross_Unit_Visibility;
