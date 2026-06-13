with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
with Editor.Ada_RM_Gap_Burn_Down_Pass1366;

package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1428 is

   --  Pass1428 freezes the finite remaining-gap inventory selected after
   --  pass1418.  It is deliberately not a broad new audit layer: it records
   --  the nine closed concrete edges, rejects reopened or newly-coined
   --  remaining edges, and checks package/test/README/Core_Suite evidence plus
   --  stable inventory fingerprints.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
   package Inventory renames Editor.Ada_RM_Gap_Burn_Down_Pass1366;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;
   subtype Release_Readiness is Inventory.Release_Readiness;

   type Remediated_Gap_Family is
     (Remaining_Protected_Action_Reentrancy_Edge,
     Remaining_Volatile_Atomic_Representation_Clause_Edge,
     Remaining_Controlled_Finalized_Discriminant_Component_Edge,
     Remaining_Generic_Formal_Subprogram_Call_Edge,
     Remaining_Access_Subprogram_Effect_Profile_Edge,
     Remaining_Universal_Numeric_Stateful_Expected_Context_Edge,
     Remaining_Renamed_Primitive_Visibility_Edge,
     Remaining_Inherited_Private_Extension_Primitive_Hiding_Edge,
     Remaining_Dispatching_Abstract_State_Effect_Edge,
     Remaining_Inventory_Closed,
     Remaining_Gap_Unknown);

   type Closure_Status is
     (Status_Not_Checked,
      Status_Inventory_Closed,
      Status_Edge_Closed,
      Status_Edge_Reopened,
      Status_Missing_Implementation_Package,
      Status_Missing_AUnit_Test,
      Status_Missing_Readme,
      Status_Missing_Core_Suite_Registration,
      Status_New_Edge_After_Freeze,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Inventory_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Indeterminate);

   type Closure_Row is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Pass_Number : Natural := 0;
      Family : RM_Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Owner : Implementing_Slice := Matrix.Slice_Diagnostics_Consumer;
      Expected : Precision_Classification := Precision.Class_Legal;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Source_File : Ada.Strings.Unbounded.Unbounded_String;
      Concrete_Subrule : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Test_Package : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Readme : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;

      Edge_Closed : Boolean := True;
      Implementation_Package_Present : Boolean := True;
      AUnit_Test_Present : Boolean := True;
      Readme_Present : Boolean := True;
      Core_Suite_Registration_Present : Boolean := True;
      No_New_Edge_After_Freeze : Boolean := True;
      Source_Shaped_Evidence : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Consumer_Result_Agrees : Boolean := True;
      Inventory_Fingerprint : Natural := 0;
      Expected_Inventory_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Closure_Row);

   type Closure_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Closure_Entry is record
      Id : Natural := 0;
      Gap : Remediated_Gap_Family := Remaining_Gap_Unknown;
      Status : Closure_Status := Status_Not_Checked;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Closure_Entry);

   type Closure_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Closed_Count : Natural := 0;
      Reopened_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Closure_Input; Row : Closure_Row);
   function Build (Input : Closure_Input) return Closure_Model;
   function Result_For (Model : Closure_Model; Id : Natural) return Closure_Entry;
   function Expected_For_Status (Status : Closure_Status) return Precision_Classification;
   function Final_Closure_Achieved (Model : Closure_Model) return Boolean;

end Editor.Ada_RM_Remaining_Gap_Remediation_Pass1428;
