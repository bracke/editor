with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Generic_View_Compatibility;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Instantiated_Body_Analysis is

   --  Compiler-grade instantiated-body analysis foundation.  This package
   --  projects generic formal/actual contract metadata into generic body
   --  contexts, preserving substitution identity and view-aware compatibility
   --  barriers without expanding, rewriting, saving, reloading, compiling, or
   --  mutating buffers.  Later passes can consume this metadata for deeper
   --  instantiated body legality and expression analysis.

   type Instantiated_Body_Status is
     (Instantiated_Body_Not_Checked,
      Instantiated_Body_Substituted,
      Instantiated_Body_Default_Substituted,
      Instantiated_Body_Private_View_Barrier,
      Instantiated_Body_Limited_View_Barrier,
      Instantiated_Body_Cross_Unit_Unresolved,
      Instantiated_Body_Object_Mismatch,
      Instantiated_Body_Object_Unknown,
      Instantiated_Body_No_Body_Contract,
      Instantiated_Body_Contract_Mismatch,
      Instantiated_Body_Unknown);

   type Instantiated_Body_Substitution_Id is new Natural;
   No_Instantiated_Body_Substitution : constant Instantiated_Body_Substitution_Id := 0;

   type Instantiated_Body_Substitution_Info is record
      Id              : Instantiated_Body_Substitution_Id := No_Instantiated_Body_Substitution;
      Instance        : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal          : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Body_Contract   : Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Body_Contract_Visibility;
      Instance_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Region     : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Formal_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Is_Default      : Boolean := False;
      Actual_Match_Status : Editor.Ada_Generic_Contracts.Generic_Actual_Match_Status :=
        Editor.Ada_Generic_Contracts.Generic_Actual_Match_Generic_Not_Found;
      Generic_View    : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Id :=
        Editor.Ada_Generic_View_Compatibility.No_Generic_View_Compatibility;
      Generic_View_Status : Editor.Ada_Generic_View_Compatibility.Generic_View_Status :=
        Editor.Ada_Generic_View_Compatibility.Generic_View_Not_Checked;
      Cross_Unit_Target   : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Selector : Ada.Strings.Unbounded.Unbounded_String;
      Status          : Instantiated_Body_Status := Instantiated_Body_Not_Checked;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   package Instantiated_Body_Substitution_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Instantiated_Body_Substitution_Info);

   type Instantiated_Body_Model is private;

   function Build
     (Contracts     : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model)
      return Instantiated_Body_Model;

   function Substitution_Count (Model : Instantiated_Body_Model) return Natural;

   function Substitution_At
     (Model : Instantiated_Body_Model;
      Index : Positive) return Instantiated_Body_Substitution_Info;

   function First_For_Formal
     (Model    : Instantiated_Body_Model;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Formal   : Editor.Ada_Generic_Contracts.Generic_Formal_Id)
      return Instantiated_Body_Substitution_Info;

   function Count_Status
     (Model  : Instantiated_Body_Model;
      Status : Instantiated_Body_Status) return Natural;

   function Substituted_Count (Model : Instantiated_Body_Model) return Natural;
   function Default_Substituted_Count (Model : Instantiated_Body_Model) return Natural;
   function Private_Barrier_Count (Model : Instantiated_Body_Model) return Natural;
   function Limited_Barrier_Count (Model : Instantiated_Body_Model) return Natural;
   function Unresolved_Count (Model : Instantiated_Body_Model) return Natural;
   function Object_Mismatch_Count (Model : Instantiated_Body_Model) return Natural;
   function Unknown_Count (Model : Instantiated_Body_Model) return Natural;
   function Missing_Body_Count (Model : Instantiated_Body_Model) return Natural;
   function Contract_Mismatch_Count (Model : Instantiated_Body_Model) return Natural;
   function Fingerprint (Model : Instantiated_Body_Model) return Natural;

private
   type Instantiated_Body_Model is record
      Entries                   : Instantiated_Body_Substitution_Vectors.Vector;
      Substituted_Total         : Natural := 0;
      Default_Substituted_Total : Natural := 0;
      Private_Barrier_Total     : Natural := 0;
      Limited_Barrier_Total     : Natural := 0;
      Unresolved_Total          : Natural := 0;
      Object_Mismatch_Total     : Natural := 0;
      Unknown_Total             : Natural := 0;
      Missing_Body_Total        : Natural := 0;
      Contract_Mismatch_Total   : Natural := 0;
      Model_Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Generic_Instantiated_Body_Analysis;
