with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Semantic_Integration_Audit_Pass1335 is

   --  Pass1335 starts the post vertical-slice integration/audit phase.
   --  It does not introduce diagnostics, rendering, command, palette, or
   --  workspace plumbing.  It models the cross-slice evidence that must be
   --  present before the compiler-grade Ada semantic model can be treated as
   --  composition-ready: common source/AST/type/profile/substitution/effect
   --  fingerprints, canonical entity/type/view/overload/freezing/generic/
   --  cross-unit evidence roles, real semantic consumers, and whole-source
   --  scenario coverage across the vertical legality engines.

   type Slice_Family is
     (Slice_Aggregate,
      Slice_Assignment_Conversion,
      Slice_Iterator_Loop_Parallel,
      Slice_Contract_Aspect,
      Slice_Context_Clause_With_Use,
      Slice_Library_Unit_Subunit,
      Slice_Interface_Synchronized,
      Slice_Interfacing_Import_Export,
      Slice_Flow_Refinement,
      Slice_Callable_Profile,
      Slice_Unknown);

   type Scenario_Kind is
     (Scenario_Generic_Private_Aggregate_Assignment,
      Scenario_Separate_Body_Context_Elaboration,
      Scenario_Interface_Dispatching_Flow,
      Scenario_Import_Export_Profile_Representation,
      Scenario_Iterator_Parallel_Contract_Flow,
      Scenario_Unknown);

   type Audit_Status is
     (Audit_Not_Checked,
      Audit_Ready,
      Audit_Missing_Slice,
      Audit_Missing_Source_Evidence,
      Audit_Missing_AST_Evidence,
      Audit_Missing_Type_Evidence,
      Audit_Missing_Profile_Evidence,
      Audit_Missing_View_Evidence,
      Audit_Missing_Overload_Evidence,
      Audit_Missing_Freezing_Evidence,
      Audit_Missing_Generic_Substitution_Evidence,
      Audit_Missing_Cross_Unit_Evidence,
      Audit_Missing_Flow_Effect_Evidence,
      Audit_Missing_Representation_Evidence,
      Audit_Missing_Runtime_Check_Evidence,
      Audit_Unconsumed_Semantic_Result,
      Audit_Source_Fingerprint_Mismatch,
      Audit_AST_Fingerprint_Mismatch,
      Audit_Type_Fingerprint_Mismatch,
      Audit_Profile_Fingerprint_Mismatch,
      Audit_Substitution_Fingerprint_Mismatch,
      Audit_Effect_Fingerprint_Mismatch,
      Audit_Slice_Model_Disagreement,
      Audit_Scenario_Not_Source_Shaped,
      Audit_Multiple_Blockers,
      Audit_Indeterminate);

   type Slice_Info is record
      Family : Slice_Family := Slice_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Present : Boolean := False;
      Source_Shaped : Boolean := False;
      Has_Source_Evidence : Boolean := False;
      Has_AST_Evidence : Boolean := False;
      Has_Type_Evidence : Boolean := False;
      Has_Profile_Evidence : Boolean := False;
      Has_View_Evidence : Boolean := False;
      Has_Overload_Evidence : Boolean := False;
      Has_Freezing_Evidence : Boolean := False;
      Has_Generic_Substitution_Evidence : Boolean := False;
      Has_Cross_Unit_Evidence : Boolean := False;
      Has_Flow_Effect_Evidence : Boolean := False;
      Has_Representation_Evidence : Boolean := False;
      Has_Runtime_Check_Evidence : Boolean := False;
      Consumed_By_Semantic_Path : Boolean := False;
      Agrees_With_Canonical_Model : Boolean := True;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
   end record;

   package Slice_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Slice_Info);

   type Slice_Model is record
      Items : Slice_Vectors.Vector;
   end record;

   type Scenario_Check is record
      Id : Natural := 0;
      Kind : Scenario_Kind := Scenario_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped : Boolean := True;
      Requires_Aggregate : Boolean := False;
      Requires_Assignment_Conversion : Boolean := False;
      Requires_Iterator_Loop_Parallel : Boolean := False;
      Requires_Contract_Aspect : Boolean := False;
      Requires_Context_Clause_With_Use : Boolean := False;
      Requires_Library_Unit_Subunit : Boolean := False;
      Requires_Interface_Synchronized : Boolean := False;
      Requires_Interfacing_Import_Export : Boolean := False;
      Requires_Flow_Refinement : Boolean := False;
      Requires_Callable_Profile : Boolean := False;
      Requires_Source_Evidence : Boolean := True;
      Requires_AST_Evidence : Boolean := True;
      Requires_Type_Evidence : Boolean := True;
      Requires_Profile_Evidence : Boolean := False;
      Requires_View_Evidence : Boolean := False;
      Requires_Overload_Evidence : Boolean := False;
      Requires_Freezing_Evidence : Boolean := False;
      Requires_Generic_Substitution_Evidence : Boolean := False;
      Requires_Cross_Unit_Evidence : Boolean := False;
      Requires_Flow_Effect_Evidence : Boolean := False;
      Requires_Representation_Evidence : Boolean := False;
      Requires_Runtime_Check_Evidence : Boolean := False;
      Requires_Consumer : Boolean := True;
      Requires_Canonical_Agreement : Boolean := True;
   end record;

   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Scenario_Check);

   type Check_Model is record
      Items : Check_Vectors.Vector;
   end record;

   type Audit_Result is record
      Id : Natural := 0;
      Kind : Scenario_Kind := Scenario_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Status : Audit_Status := Audit_Not_Checked;
      Blocking_Slice : Slice_Family := Slice_Unknown;
      Blocker_Count : Natural := 0;
      Evidence_Fingerprint : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Audit_Result);

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Ready_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   procedure Add_Slice (Model : in out Slice_Model; Slice : Slice_Info);
   procedure Add_Check (Model : in out Check_Model; Check : Scenario_Check);

   function Build (Slices : Slice_Model; Checks : Check_Model) return Result_Model;
   function Count (Results : Result_Model) return Natural;
   function Result_At (Results : Result_Model; Index : Positive) return Audit_Result;
   function Integration_Ready (Results : Result_Model) return Boolean;

end Editor.Ada_Semantic_Integration_Audit_Pass1335;
