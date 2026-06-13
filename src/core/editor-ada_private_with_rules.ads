with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Visibility;

package Editor.Ada_Private_With_Rules is

   --  Semantic projection for Ada private-with visibility constraints.
   --  The model consumes cross-unit visibility metadata only.  It performs no
   --  parsing, no file IO, and no workspace mutation.  It lets later semantic
   --  lookup consumers distinguish ordinary visible-part lookup from private
   --  part and body lookup when a dependency came from a private with clause.

   type Private_With_Context is
     (Private_With_Context_Visible_Part,
      Private_With_Context_Private_Part,
      Private_With_Context_Body);

   type Private_With_Status is
     (Private_With_Not_Found,
      Private_With_Not_Private,
      Private_With_Hidden_From_Visible_Part,
      Private_With_Visible_In_Private_Context,
      Private_With_Visible_In_Body_Context,
      Private_With_Missing_Dependency,
      Private_With_Ambiguous_Dependency,
      Private_With_Overflow_Dependency);

   type Private_With_Info is record
      Status                   : Private_With_Status := Private_With_Not_Found;
      Source_Unit_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Target_Path              : Ada.Strings.Unbounded.Unbounded_String;
      Clause_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Is_Private_Dependency    : Boolean := False;
      Visible_Part_Visible     : Boolean := False;
      Private_Part_Visible     : Boolean := False;
      Body_Visible             : Boolean := False;
      Hidden_From_Visible_Part : Boolean := False;
      Use_Clause_Allowed       : Boolean := False;
      Candidate_Count          : Natural := 0;
      Fingerprint              : Natural := 0;
   end record;

   package Private_With_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Private_With_Info);

   type Private_With_Model is private;

   function Build
     (Visibility : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model)
      return Private_With_Model;

   function Rule_Count (Model : Private_With_Model) return Natural;

   function Rule_At
     (Model : Private_With_Model;
      Index : Positive) return Private_With_Info;

   function Lookup_Private_With
     (Model            : Private_With_Model;
      Source_Unit_Name : String;
      Name             : String;
      Context          : Private_With_Context) return Private_With_Info;

   function Visible_In_Context
     (Model            : Private_With_Model;
      Source_Unit_Name : String;
      Name             : String;
      Context          : Private_With_Context) return Boolean;

   function Private_Dependency_Count (Model : Private_With_Model) return Natural;
   function Hidden_From_Visible_Part_Count (Model : Private_With_Model) return Natural;
   function Private_Context_Visible_Count (Model : Private_With_Model) return Natural;
   function Body_Context_Visible_Count (Model : Private_With_Model) return Natural;
   function Nonprivate_Dependency_Count (Model : Private_With_Model) return Natural;
   function Missing_Count (Model : Private_With_Model) return Natural;
   function Ambiguous_Count (Model : Private_With_Model) return Natural;
   function Overflow_Count (Model : Private_With_Model) return Natural;
   function Fingerprint (Model : Private_With_Model) return Natural;

private
   type Private_With_Model is record
      Items             : Private_With_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Private_With_Rules;
