with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Closure;

package Editor.Ada_Child_Unit_Visibility is

   --  Semantic projection for child-unit visibility from parent and
   --  private-child contexts.  The model consumes cross-unit closure metadata
   --  only; it performs no parsing, no file IO, and no editor-state mutation.
   --  It is intended as a lookup-facing bridge for later cross-unit semantic
   --  name resolution.

   type Child_Visibility_Context is
     (Child_Visibility_Context_External_Client,
      Child_Visibility_Context_Parent_Visible_Part,
      Child_Visibility_Context_Parent_Private_Part,
      Child_Visibility_Context_Parent_Body);

   type Child_Visibility_Status is
     (Child_Visibility_Not_Found,
      Child_Visibility_Public_Child_Visible,
      Child_Visibility_Private_Child_Hidden,
      Child_Visibility_Private_Child_Visible_In_Private_Context,
      Child_Visibility_Private_Child_Visible_In_Body_Context,
      Child_Visibility_Missing_Parent,
      Child_Visibility_Ambiguous_Parent,
      Child_Visibility_Overflow,
      Child_Visibility_Parent_Role_Mismatch);

   type Child_Visibility_Info is record
      Status                      : Child_Visibility_Status :=
        Child_Visibility_Not_Found;
      Parent_Unit_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Path                 : Ada.Strings.Unbounded.Unbounded_String;
      Child_Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Child_Path                  : Ada.Strings.Unbounded.Unbounded_String;
      Is_Private_Child            : Boolean := False;
      External_Client_Visible     : Boolean := False;
      Parent_Visible_Part_Visible : Boolean := False;
      Parent_Private_Part_Visible : Boolean := False;
      Parent_Body_Visible         : Boolean := False;
      Candidate_Count             : Natural := 0;
      Fingerprint                 : Natural := 0;
   end record;

   package Child_Visibility_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Child_Visibility_Info);

   type Child_Visibility_Model is private;

   function Build
     (Closure : Editor.Ada_Cross_Unit_Closure.Cross_Unit_Closure_Model)
      return Child_Visibility_Model;

   function Visibility_Count (Model : Child_Visibility_Model) return Natural;

   function Visibility_At
     (Model : Child_Visibility_Model;
      Index : Positive) return Child_Visibility_Info;

   function Lookup_Child
     (Model            : Child_Visibility_Model;
      Parent_Unit_Name : String;
      Child_Name       : String;
      Context          : Child_Visibility_Context) return Child_Visibility_Info;

   function Visible_In_Context
     (Model            : Child_Visibility_Model;
      Parent_Unit_Name : String;
      Child_Name       : String;
      Context          : Child_Visibility_Context) return Boolean;

   function Public_Child_Visible_Count (Model : Child_Visibility_Model) return Natural;
   function Private_Child_Hidden_Count (Model : Child_Visibility_Model) return Natural;
   function Private_Child_Private_Context_Visible_Count
     (Model : Child_Visibility_Model) return Natural;
   function Private_Child_Body_Context_Visible_Count
     (Model : Child_Visibility_Model) return Natural;
   function Parent_Error_Count (Model : Child_Visibility_Model) return Natural;
   function Missing_Parent_Count (Model : Child_Visibility_Model) return Natural;
   function Ambiguous_Parent_Count (Model : Child_Visibility_Model) return Natural;
   function Overflow_Count (Model : Child_Visibility_Model) return Natural;
   function Fingerprint (Model : Child_Visibility_Model) return Natural;

private
   type Child_Visibility_Model is record
      Items             : Child_Visibility_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Child_Unit_Visibility;
