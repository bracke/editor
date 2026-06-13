with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Canonical_Semantic_Model_Agreement_Audit_Pass1336 is

   --  Pass1336 is the second post vertical-slice integration/audit pass.
   --  It audits whether independently implemented Ada semantic legality
   --  slices agree on one canonical model for entity, type, view, callable
   --  profile, generic substitution, library unit, representation/freezing,
   --  and flow/effect identity.  The package deliberately remains a semantic
   --  audit layer only: it introduces no rendering, command, palette,
   --  workspace, diagnostic projection, LSP, or compiler-invocation path.

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
      Slice_Generic_Contract_Body,
      Slice_Generic_Body_Replay,
      Slice_Representation_Freezing,
      Slice_Visibility_Name_Resolution,
      Slice_Tagged_Dispatching,
      Slice_Unknown);

   type Agreement_Dimension is
     (Dimension_Entity,
      Dimension_Type,
      Dimension_View,
      Dimension_Profile,
      Dimension_Generic_Substitution,
      Dimension_Unit,
      Dimension_Representation_Freezing,
      Dimension_Flow_Effect,
      Dimension_Overload_Set,
      Dimension_Runtime_Check,
      Dimension_Unknown);

   type View_Class is
     (View_None,
      View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Class_Wide);

   type Scenario_Kind is
     (Scenario_Private_Type_Rep_Aggregate_Assignment,
      Scenario_Generic_Formal_Body_Replay_Flow,
      Scenario_Tagged_Interface_Dispatching_Contract,
      Scenario_Private_Child_Separate_Imported_Callable,
      Scenario_Protected_Parallel_Volatile_Effects,
      Scenario_Unknown);

   type Agreement_Status is
     (Agreement_Not_Checked,
      Agreement_Ready,
      Agreement_Missing_Source_Evidence,
      Agreement_Missing_AST_Evidence,
      Agreement_Missing_Binding,
      Agreement_Missing_Canonical_Identity,
      Agreement_Slice_Local_Identity_Mismatch,
      Agreement_View_Class_Mismatch,
      Agreement_Profile_Model_Mismatch,
      Agreement_Generic_Substitution_Mismatch,
      Agreement_Unit_Completion_Mismatch,
      Agreement_Representation_Freezing_Mismatch,
      Agreement_Flow_Effect_Mismatch,
      Agreement_Overload_Set_Mismatch,
      Agreement_Runtime_Check_Mismatch,
      Agreement_Unconsumed_By_Semantic_Path,
      Agreement_Source_Fingerprint_Mismatch,
      Agreement_AST_Fingerprint_Mismatch,
      Agreement_Model_Fingerprint_Mismatch,
      Agreement_Scenario_Not_Source_Shaped,
      Agreement_Multiple_Blockers,
      Agreement_Indeterminate);

   type Canonical_Binding is record
      Scenario_Id : Natural := 0;
      Dimension : Agreement_Dimension := Dimension_Unknown;
      Slice : Slice_Family := Slice_Unknown;
      Source_Shaped : Boolean := True;
      Has_Source_Evidence : Boolean := True;
      Has_AST_Evidence : Boolean := True;
      Consumed_By_Semantic_Path : Boolean := True;
      Canonical_Id : Natural := 0;
      Slice_Local_Id : Natural := 0;
      Canonical_View : View_Class := View_None;
      Slice_View : View_Class := View_None;
      Canonical_Profile_Id : Natural := 0;
      Slice_Profile_Id : Natural := 0;
      Canonical_Substitution_Id : Natural := 0;
      Slice_Substitution_Id : Natural := 0;
      Canonical_Unit_Id : Natural := 0;
      Slice_Unit_Id : Natural := 0;
      Canonical_Representation_Id : Natural := 0;
      Slice_Representation_Id : Natural := 0;
      Canonical_Flow_Effect_Id : Natural := 0;
      Slice_Flow_Effect_Id : Natural := 0;
      Canonical_Overload_Set_Id : Natural := 0;
      Slice_Overload_Set_Id : Natural := 0;
      Canonical_Runtime_Check_Id : Natural := 0;
      Slice_Runtime_Check_Id : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Model_Fingerprint : Natural := 0;
      Expected_Model_Fingerprint : Natural := 0;
   end record;

   package Binding_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Canonical_Binding);

   type Canonical_Model is record
      Bindings : Binding_Vectors.Vector;
   end record;

   type Scenario_Check is record
      Id : Natural := 0;
      Kind : Scenario_Kind := Scenario_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped : Boolean := True;
      Requires_Entity : Boolean := False;
      Requires_Type : Boolean := False;
      Requires_View : Boolean := False;
      Requires_Profile : Boolean := False;
      Requires_Generic_Substitution : Boolean := False;
      Requires_Unit : Boolean := False;
      Requires_Representation_Freezing : Boolean := False;
      Requires_Flow_Effect : Boolean := False;
      Requires_Overload_Set : Boolean := False;
      Requires_Runtime_Check : Boolean := False;
   end record;

   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Scenario_Check);

   type Check_Model is record
      Items : Check_Vectors.Vector;
   end record;

   type Agreement_Result is record
      Id : Natural := 0;
      Kind : Scenario_Kind := Scenario_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Dimension : Agreement_Dimension := Dimension_Unknown;
      Blocking_Slice : Slice_Family := Slice_Unknown;
      Status : Agreement_Status := Agreement_Not_Checked;
      Blocker_Count : Natural := 0;
      Agreement_Fingerprint : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Agreement_Result);

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Ready_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   procedure Add_Binding (Model : in out Canonical_Model; Binding : Canonical_Binding);
   procedure Add_Check (Model : in out Check_Model; Check : Scenario_Check);

   function Build (Model : Canonical_Model; Checks : Check_Model) return Result_Model;
   function Count (Results : Result_Model) return Natural;
   function Result_At (Results : Result_Model; Index : Positive) return Agreement_Result;
   function Canonical_Model_Agrees (Results : Result_Model) return Boolean;

end Editor.Ada_Canonical_Semantic_Model_Agreement_Audit_Pass1336;
