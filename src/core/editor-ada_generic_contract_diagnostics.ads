with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Formal_Type_Conformance;
with Editor.Ada_Generic_Formal_Package_Nested_Conformance;
with Editor.Ada_Generic_Renaming_Visibility;
with Editor.Ada_Generic_Object_Default_Type_Conformance;
with Editor.Ada_Generic_View_Compatibility;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Generic_Formal_Package_Substitutions;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Contract_Diagnostics is

   --  Projection-only diagnostics for the generic-contract semantic layers.
   --  This model consumes already-built generic contract/conformance metadata
   --  and emits deterministic diagnostics with stable node spans and severity.
   --  It performs no parsing, file IO, editor mutation, command registration,
   --  or rendering work.

   type Generic_Contract_Diagnostic_Id is new Natural;
   No_Generic_Contract_Diagnostic : constant Generic_Contract_Diagnostic_Id := 0;

   type Generic_Contract_Diagnostic_Severity is
     (Generic_Contract_Diagnostic_Severity_Info,
      Generic_Contract_Diagnostic_Warning,
      Generic_Contract_Diagnostic_Error);

   type Generic_Contract_Diagnostic_Kind is
     (Generic_Diagnostic_Formal_Type_Mismatch,
      Generic_Diagnostic_Formal_Type_Unresolved,
      Generic_Diagnostic_Formal_Package_Nested_Mismatch,
      Generic_Diagnostic_Formal_Package_Nested_Unresolved,
      Generic_Diagnostic_Generic_Renaming_Error,
      Generic_Diagnostic_Nested_Instantiation_Error,
      Generic_Diagnostic_Object_Default_Type_Mismatch,
      Generic_Diagnostic_Object_Default_Range_Error,
      Generic_Diagnostic_Object_Default_Unknown,
      Generic_Diagnostic_Generic_View_Private_Barrier,
      Generic_Diagnostic_Generic_View_Limited_Barrier,
      Generic_Diagnostic_Generic_View_Cross_Unit_Unresolved,
      Generic_Diagnostic_Generic_View_Object_Mismatch,
      Generic_Diagnostic_Generic_View_Unknown,
      Generic_Diagnostic_Instantiated_Body_Private_Barrier,
      Generic_Diagnostic_Instantiated_Body_Limited_Barrier,
      Generic_Diagnostic_Instantiated_Body_Cross_Unit_Unresolved,
      Generic_Diagnostic_Instantiated_Body_Object_Mismatch,
      Generic_Diagnostic_Instantiated_Body_Object_Unknown,
      Generic_Diagnostic_Instantiated_Body_Missing_Body_Contract,
      Generic_Diagnostic_Instantiated_Body_Contract_Mismatch,
      Generic_Diagnostic_Formal_Package_Substitution_Mismatch,
      Generic_Diagnostic_Formal_Package_Substitution_Missing,
      Generic_Diagnostic_Formal_Package_Substitution_Wrong_Generic,
      Generic_Diagnostic_Formal_Package_Substitution_Unresolved,
      Generic_Diagnostic_Formal_Package_Substitution_Unknown,
      Generic_Diagnostic_Contract_Unknown);

   type Generic_Contract_Diagnostic_Info is record
      Id       : Generic_Contract_Diagnostic_Id := No_Generic_Contract_Diagnostic;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal   : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Kind     : Generic_Contract_Diagnostic_Kind := Generic_Diagnostic_Contract_Unknown;
      Severity : Generic_Contract_Diagnostic_Severity :=
        Generic_Contract_Diagnostic_Warning;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      From_Generic_View : Boolean := False;
      Generic_View      : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Id :=
        Editor.Ada_Generic_View_Compatibility.No_Generic_View_Compatibility;
      Generic_View_Status : Editor.Ada_Generic_View_Compatibility.Generic_View_Status :=
        Editor.Ada_Generic_View_Compatibility.Generic_View_Not_Checked;
      Generic_View_Fingerprint : Natural := 0;
      From_Instantiated_Body : Boolean := False;
      Instantiated_Body : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Id :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.No_Instantiated_Body_Substitution;
      Instantiated_Body_Status : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Status :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Not_Checked;
      Instantiated_Body_Fingerprint : Natural := 0;
      Body_Contract : Editor.Ada_Generic_Contracts.Generic_Body_Contract_Visibility_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Body_Contract_Visibility;
      From_Formal_Package_Substitution : Boolean := False;
      Formal_Package_Substitution : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Id :=
        Editor.Ada_Generic_Formal_Package_Substitutions.No_Formal_Package_Substitution;
      Formal_Package_Substitution_Status : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Status :=
        Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Not_Checked;
      Formal_Package_Substitution_Fingerprint : Natural := 0;
      Nested_Position : Positive := 1;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint  : Natural := 0;
   end record;

   type Generic_Contract_Diagnostic_Model is private;

   procedure Clear (Model : in out Generic_Contract_Diagnostic_Model);

   function Build
     (Formal_Types : Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
      Nested_Packages : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
      Renamings : Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
      Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model)
      return Generic_Contract_Diagnostic_Model;

   function Build_With_View_Compatibility
     (Formal_Types : Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
      Nested_Packages : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
      Renamings : Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
      Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model)
      return Generic_Contract_Diagnostic_Model;

   function Build_With_View_Compatibility_And_Body_Analysis
     (Formal_Types : Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
      Nested_Packages : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
      Renamings : Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
      Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model;
      Bodies : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model)
      return Generic_Contract_Diagnostic_Model;

   function Build_With_Formal_Package_Substitutions
     (Formal_Types : Editor.Ada_Generic_Formal_Type_Conformance.Formal_Type_Conformance_Model;
      Nested_Packages : Editor.Ada_Generic_Formal_Package_Nested_Conformance.Formal_Package_Nested_Model;
      Renamings : Editor.Ada_Generic_Renaming_Visibility.Generic_Renaming_Visibility_Model;
      Object_Defaults : Editor.Ada_Generic_Object_Default_Type_Conformance.Object_Default_Type_Model;
      Generic_Views : Editor.Ada_Generic_View_Compatibility.Generic_View_Compatibility_Model;
      Bodies : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model;
      Substitutions : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model)
      return Generic_Contract_Diagnostic_Model;

   function Has_Diagnostics (Model : Generic_Contract_Diagnostic_Model) return Boolean;
   function Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Diagnostic_At
     (Model : Generic_Contract_Diagnostic_Model;
      Index : Natural) return Generic_Contract_Diagnostic_Info;
   function Diagnostic_For_Node
     (Model : Generic_Contract_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Contract_Diagnostic_Info;

   function Error_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Info_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Count_Kind
     (Model : Generic_Contract_Diagnostic_Model;
      Kind  : Generic_Contract_Diagnostic_Kind) return Natural;
   function Generic_View_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Private_View_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Limited_View_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function View_Unresolved_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Instantiated_Body_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Body_Private_Barrier_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Body_Limited_Barrier_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Body_Unresolved_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Body_Missing_Contract_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Body_Contract_Mismatch_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Formal_Package_Substitution_Diagnostic_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Formal_Package_Substitution_Mismatch_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Formal_Package_Substitution_Missing_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Formal_Package_Substitution_Unresolved_Count (Model : Generic_Contract_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Generic_Contract_Diagnostic_Model) return Natural;

private
   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Contract_Diagnostic_Info);

   type Generic_Contract_Diagnostic_Model is record
      Diagnostics        : Diagnostic_Vectors.Vector;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Generic_View_Total : Natural := 0;
      Private_View_Total : Natural := 0;
      Limited_View_Total : Natural := 0;
      View_Unresolved_Total : Natural := 0;
      Instantiated_Body_Total : Natural := 0;
      Body_Private_Barrier_Total : Natural := 0;
      Body_Limited_Barrier_Total : Natural := 0;
      Body_Unresolved_Total : Natural := 0;
      Body_Missing_Contract_Total : Natural := 0;
      Body_Contract_Mismatch_Total : Natural := 0;
      Formal_Package_Substitution_Total : Natural := 0;
      Formal_Package_Substitution_Mismatch_Total : Natural := 0;
      Formal_Package_Substitution_Missing_Total : Natural := 0;
      Formal_Package_Substitution_Unresolved_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Contract_Diagnostics;
