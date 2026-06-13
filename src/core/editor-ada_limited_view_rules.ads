with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Visibility;

package Editor.Ada_Limited_View_Rules is

   --  Semantic projection for Ada limited-with incomplete-view rules.
   --  The model consumes cross-unit visibility metadata only; it performs no
   --  parsing, no file IO, and no workspace mutation.  It is intended as the
   --  lookup-facing bridge that lets later semantic consumers reject full-view
   --  assumptions when a unit is visible only through a limited with clause.

   type Limited_View_Status is
     (Limited_View_Not_Found,
      Limited_View_Not_Limited,
      Limited_View_Incomplete_View_Visible,
      Limited_View_Full_View_Hidden,
      Limited_View_Missing_Dependency,
      Limited_View_Ambiguous_Dependency,
      Limited_View_Overflow_Dependency);

   type Limited_View_Info is record
      Status                   : Limited_View_Status := Limited_View_Not_Found;
      Source_Unit_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Target_Path              : Ada.Strings.Unbounded.Unbounded_String;
      Clause_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Incomplete_View_Visible  : Boolean := False;
      Full_View_Visible        : Boolean := False;
      Full_View_Hidden         : Boolean := False;
      Use_Clause_Allowed       : Boolean := False;
      Candidate_Count          : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

   package Limited_View_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Limited_View_Info);

   type Limited_View_Model is private;

   function Build
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model)
      return Limited_View_Model;

   function Rule_Count (Model : Limited_View_Model) return Natural;

   function Rule_At
     (Model : Limited_View_Model;
      Index : Positive) return Limited_View_Info;

   function Lookup_Limited_View
     (Model            : Limited_View_Model;
      Source_Unit_Name : String;
      Name             : String) return Limited_View_Info;

   function Full_View_Visible
     (Model            : Limited_View_Model;
      Source_Unit_Name : String;
      Name             : String) return Boolean;

   function Incomplete_View_Count (Model : Limited_View_Model) return Natural;
   function Full_View_Hidden_Count (Model : Limited_View_Model) return Natural;
   function Nonlimited_View_Count (Model : Limited_View_Model) return Natural;
   function Missing_Count (Model : Limited_View_Model) return Natural;
   function Ambiguous_Count (Model : Limited_View_Model) return Natural;
   function Overflow_Count (Model : Limited_View_Model) return Natural;
   function Fingerprint (Model : Limited_View_Model) return Natural;

private
   type Limited_View_Model is record
      Items             : Limited_View_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Limited_View_Rules;
