with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Visibility;
with Editor.Ada_Direct_Visibility;

package Editor.Ada_Cross_Unit_Lookup_Integration is

   --  Deterministic lookup-facing integration of cross-unit visibility.
   --  This package bridges context-clause visibility metadata into the same
   --  kind of name-lookup decision records used by direct/use lookup consumers.
   --  It performs no parsing, file IO, buffer mutation, command registration,
   --  workspace mutation, or rendering-side work.

   type Cross_Unit_Lookup_Status is
     (Cross_Unit_Lookup_Not_Found,
      Cross_Unit_Lookup_Local_Found,
      Cross_Unit_Lookup_Local_Ambiguous,
      Cross_Unit_Lookup_With_Visible,
      Cross_Unit_Lookup_Use_Visible,
      Cross_Unit_Lookup_Limited_Incomplete_View,
      Cross_Unit_Lookup_Private_View,
      Cross_Unit_Lookup_Missing,
      Cross_Unit_Lookup_Ambiguous,
      Cross_Unit_Lookup_Overflow);

   type Cross_Unit_Lookup_Id is new Natural;
   No_Cross_Unit_Lookup : constant Cross_Unit_Lookup_Id := 0;

   type Cross_Unit_Lookup_Entry is record
      Id               : Cross_Unit_Lookup_Id := No_Cross_Unit_Lookup;
      Status           : Cross_Unit_Lookup_Status := Cross_Unit_Lookup_Not_Found;
      Source_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Lookup_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Target_Path      : Ada.Strings.Unbounded.Unbounded_String;
      Is_With          : Boolean := False;
      Is_Use           : Boolean := False;
      Is_Limited       : Boolean := False;
      Is_Private       : Boolean := False;
      Candidate_Count  : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Fingerprint      : Natural := 0;
   end record;

   package Cross_Unit_Lookup_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_Lookup_Entry);

   type Cross_Unit_Lookup_Model is private;

   procedure Clear (Model : in out Cross_Unit_Lookup_Model);

   function Build
     (Visibility       : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model;
      Source_Unit_Name : String) return Cross_Unit_Lookup_Model;

   function Lookup_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Lookup_At
     (Model : Cross_Unit_Lookup_Model;
      Index : Positive) return Cross_Unit_Lookup_Entry;

   function Lookup_Name
     (Model : Cross_Unit_Lookup_Model;
      Name  : String) return Cross_Unit_Lookup_Entry;

   function Resolve_With_Local
     (Model : Cross_Unit_Lookup_Model;
      Local : Editor.Ada_Direct_Visibility.Lookup_Result;
      Name  : String) return Cross_Unit_Lookup_Entry;

   function Visible_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function With_Visible_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Use_Visible_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Limited_View_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Private_View_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Missing_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Ambiguous_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Overflow_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Local_Precedence_Count (Model : Cross_Unit_Lookup_Model) return Natural;
   function Fingerprint (Model : Cross_Unit_Lookup_Model) return Natural;

private
   type Cross_Unit_Lookup_Model is record
      Source_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Entries                : Cross_Unit_Lookup_Vectors.Vector;
      Visible_Total          : Natural := 0;
      With_Total             : Natural := 0;
      Use_Total              : Natural := 0;
      Limited_Total          : Natural := 0;
      Private_Total          : Natural := 0;
      Missing_Total          : Natural := 0;
      Ambiguous_Total        : Natural := 0;
      Overflow_Total         : Natural := 0;
      Local_Precedence_Total : Natural := 0;
      Result_Fingerprint     : Natural := 0;
   end record;

end Editor.Ada_Cross_Unit_Lookup_Integration;
