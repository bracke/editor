with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_End_To_End_Semantic_Scenario_Audit_Pass1337 is

   --  Pass1337 is the third post vertical-slice integration/audit pass.
   --  It audits complete Ada source-shaped semantic stories instead of
   --  isolated legality-slice rows.  Each scenario must carry evidence from
   --  the canonical semantic model through the real vertical-slice consumers
   --  that would participate in a realistic Ada program: units, views,
   --  generics, aggregates, assignment/conversion, dispatching, contracts,
   --  representation/freezing, flow/effects, and runtime checks.

   type Scenario_Kind is
     (Scenario_Private_Type_Full_View,
      Scenario_Generic_Instantiation,
      Scenario_Tagged_Interface_Dispatch,
      Scenario_Library_Separate_Body,
      Scenario_Task_Protected_Parallel,
      Scenario_Representation_Interfacing,
      Scenario_Unknown);

   type Slice_Result is
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
      Slice_Generic_Contract_Body,
      Slice_Generic_Body_Replay,
      Slice_Representation_Freezing,
      Slice_Visibility_Name_Resolution,
      Slice_Tagged_Dispatching,
      Slice_Accessibility_Lifetime,
      Slice_Elaboration,
      Slice_Overload_Resolution,
      Slice_Record_Layout,
      Slice_Enumeration_Representation,
      Slice_Unknown);

   type Audit_Status is
     (Status_Not_Checked,
      Status_Ready,
      Status_Not_Source_Shaped,
      Status_Missing_Source_Evidence,
      Status_Missing_AST_Evidence,
      Status_Missing_Required_Slice_Result,
      Status_Unconsumed_Semantic_Result,
      Status_Canonical_Model_Disagreement,
      Status_Cross_Unit_Evidence_Stale,
      Status_Generic_Substitution_Not_Propagated,
      Status_View_Model_Disagreement,
      Status_Overload_Profile_Disagreement,
      Status_Flow_Effect_Not_Consumed,
      Status_Representation_Freezing_Inconsistent,
      Status_Runtime_Check_Not_Preserved,
      Status_Blocker_Family_Unstable,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Canonical_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type End_To_End_Scenario is record
      Id : Natural := 0;
      Kind : Scenario_Kind := Scenario_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped : Boolean := True;
      Has_Source_Evidence : Boolean := True;
      Has_AST_Evidence : Boolean := True;
      Canonical_Model_Agrees : Boolean := True;
      Cross_Unit_Evidence_Fresh : Boolean := True;
      Generic_Substitution_Propagated : Boolean := True;
      View_Model_Agrees : Boolean := True;
      Overload_Profile_Agrees : Boolean := True;
      Flow_Effect_Consumed : Boolean := True;
      Representation_Freezing_Consistent : Boolean := True;
      Runtime_Check_Preserved : Boolean := True;
      Blocker_Family_Stable : Boolean := True;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Canonical_Fingerprint : Natural := 0;
      Expected_Canonical_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Scenario_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => End_To_End_Scenario);

   type Scenario_Model is record
      Items : Scenario_Vectors.Vector;
   end record;

   type Slice_Evidence is record
      Scenario_Id : Natural := 0;
      Slice : Slice_Result := Slice_Unknown;
      Present : Boolean := True;
      Consumed : Boolean := True;
      Source_Shaped : Boolean := True;
      Has_Source_Evidence : Boolean := True;
      Has_AST_Evidence : Boolean := True;
      Result_Fingerprint : Natural := 0;
      Expected_Result_Fingerprint : Natural := 0;
   end record;

   package Evidence_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Slice_Evidence);

   type Evidence_Model is record
      Items : Evidence_Vectors.Vector;
   end record;

   type Audit_Result is record
      Id : Natural := 0;
      Kind : Scenario_Kind := Scenario_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Status : Audit_Status := Status_Not_Checked;
      Blocking_Slice : Slice_Result := Slice_Unknown;
      Blocker_Count : Natural := 0;
      Scenario_Fingerprint : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Audit_Result);

   type Audit_Model is record
      Items : Result_Vectors.Vector;
      Ready_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Scenario (Model : in out Scenario_Model; Scenario : End_To_End_Scenario);
   procedure Add_Evidence (Model : in out Evidence_Model; Evidence : Slice_Evidence);

   function Build (Scenarios : Scenario_Model; Evidence : Evidence_Model) return Audit_Model;
   function Count (Results : Audit_Model) return Natural;
   function Result_At (Results : Audit_Model; Index : Positive) return Audit_Result;
   function End_To_End_Audit_Ready (Results : Audit_Model) return Boolean;

end Editor.Ada_End_To_End_Semantic_Scenario_Audit_Pass1337;
