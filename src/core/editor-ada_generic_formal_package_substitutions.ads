with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Generic_Formal_Package_Nested_Conformance;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Formal_Package_Substitutions is

   --  Compiler-grade formal-package substitution foundation.  This package
   --  expands aggregate nested formal-package conformance records into
   --  per-nested-actual substitution metadata.  It is deterministic and
   --  projection-only: it performs no rewriting, no file IO, no compilation,
   --  and no editor state mutation.

   type Formal_Package_Substitution_Status is
     (Formal_Package_Substitution_Not_Checked,
      Formal_Package_Substitution_Substituted,
      Formal_Package_Substitution_Boxed,
      Formal_Package_Substitution_Mismatch,
      Formal_Package_Substitution_Missing,
      Formal_Package_Substitution_Wrong_Generic,
      Formal_Package_Substitution_Unresolved,
      Formal_Package_Substitution_Malformed,
      Formal_Package_Substitution_Unknown);

   type Formal_Package_Substitution_Id is new Natural;
   No_Formal_Package_Substitution : constant Formal_Package_Substitution_Id := 0;

   type Formal_Package_Substitution_Info is record
      Id              : Formal_Package_Substitution_Id := No_Formal_Package_Substitution;
      Check_Index     : Natural := 0;
      Instance        : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal          : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Actual_Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Instance_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Actual_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Generic : Ada.Strings.Unbounded.Unbounded_String;
      Nested_Position : Positive := 1;
      Formal_Actual_Text : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Actual_Text : Ada.Strings.Unbounded.Unbounded_String;
      Status          : Formal_Package_Substitution_Status :=
        Formal_Package_Substitution_Not_Checked;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Source_Fingerprint : Natural := 0;
      Fingerprint     : Natural := 0;
   end record;

   package Substitution_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Formal_Package_Substitution_Info);

   type Formal_Package_Substitution_Model is private;

   function Build
     (Nested : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model)
      return Formal_Package_Substitution_Model;

   function Substitution_Count (Model : Formal_Package_Substitution_Model) return Natural;

   function Substitution_At
     (Model : Formal_Package_Substitution_Model;
      Index : Natural) return Formal_Package_Substitution_Info;

   function First_For_Formal
     (Model    : Formal_Package_Substitution_Model;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id;
      Formal   : Editor.Ada_Generic_Contracts.Generic_Formal_Id)
      return Formal_Package_Substitution_Info;

   function Count_Status
     (Model  : Formal_Package_Substitution_Model;
      Status : Formal_Package_Substitution_Status) return Natural;

   function Substituted_Count (Model : Formal_Package_Substitution_Model) return Natural;
   function Boxed_Count (Model : Formal_Package_Substitution_Model) return Natural;
   function Mismatch_Count (Model : Formal_Package_Substitution_Model) return Natural;
   function Missing_Count (Model : Formal_Package_Substitution_Model) return Natural;
   function Wrong_Generic_Count (Model : Formal_Package_Substitution_Model) return Natural;
   function Unresolved_Count (Model : Formal_Package_Substitution_Model) return Natural;
   function Unknown_Count (Model : Formal_Package_Substitution_Model) return Natural;
   function Fingerprint (Model : Formal_Package_Substitution_Model) return Natural;

private
   type Formal_Package_Substitution_Model is record
      Entries             : Substitution_Vectors.Vector;
      Substituted_Total   : Natural := 0;
      Boxed_Total         : Natural := 0;
      Mismatch_Total      : Natural := 0;
      Missing_Total       : Natural := 0;
      Wrong_Generic_Total : Natural := 0;
      Unresolved_Total    : Natural := 0;
      Unknown_Total       : Natural := 0;
      Result_Fingerprint  : Natural := 0;
   end record;

end Editor.Ada_Generic_Formal_Package_Substitutions;
