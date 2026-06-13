with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;

package Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341 is

   --  Pass1341 is the seventh post vertical-slice integration/audit pass.
   --  It hardens the compiler-grade Ada semantic model against false
   --  positives and false negatives when source-shaped evidence is partial.
   --  The audit keeps hard legality diagnostics out of incomplete or stale
   --  contexts, preserves legal-with-runtime-check cases, and forces
   --  consumers to surface indeterminate, blocked, partial, and missing
   --  checker states without inventing semantic facts.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;

   type Precision_Area is
     (Area_Source_AST_Evidence,
      Area_Type_Profile_Evidence,
      Area_View_Cross_Unit_Evidence,
      Area_Flow_Effect_Evidence,
      Area_Representation_Freezing_Evidence,
      Area_Consumer_Precision,
      Area_Aggregate_Assignment_Predicate,
      Area_Generic_Overload_Profile,
      Area_Tasking_Parallel_Shared_State,
      Area_Unknown);

   type Precision_Classification is
     (Class_Legal,
      Class_Illegal,
      Class_Legal_With_Runtime_Check,
      Class_Indeterminate,
      Class_Partial_Coverage,
      Class_Missing_Checker,
      Class_Unknown);

   type Precision_Status is
     (Status_Not_Checked,
      Status_Ready,
      Status_Missing_Source_Shaped_Evidence,
      Status_Hard_Diagnostic_From_Incomplete_Evidence,
      Status_Runtime_Check_Marked_Illegal,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Treated_As_Legal,
      Status_Indeterminate_Treated_As_Illegal,
      Status_Stale_Evidence_Treated_As_Authoritative,
      Status_Partial_Coverage_Treated_As_Complete,
      Status_Missing_Checker_Treated_As_Complete,
      Status_Consumer_Hides_Blocker_State,
      Status_Complete_Evidence_Violation_Not_Diagnosed,
      Status_Legal_Case_Diagnosed,
      Status_Diagnostic_Missing_Blocker_Family,
      Status_Source_AST_Evidence_Incomplete,
      Status_Type_Profile_Evidence_Incomplete,
      Status_View_Cross_Unit_Evidence_Incomplete,
      Status_Flow_Effect_Evidence_Incomplete,
      Status_Representation_Freezing_Evidence_Incomplete,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Precision_Row is record
      Id : Natural := 0;
      Area : Precision_Area := Area_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Slice : Implementing_Slice := Matrix.Slice_Unknown;
      State : Remediation_State := Remediation.State_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Expected : Precision_Classification := Class_Unknown;
      Actual : Precision_Classification := Class_Unknown;
      Source_Shaped_Evidence : Boolean := True;
      Required_Source_AST_Evidence_Complete : Boolean := True;
      Required_Type_Profile_Evidence_Complete : Boolean := True;
      Required_View_Cross_Unit_Evidence_Complete : Boolean := True;
      Required_Flow_Effect_Evidence_Complete : Boolean := True;
      Required_Representation_Freezing_Evidence_Complete : Boolean := True;
      Hard_Diagnostic_Emitted : Boolean := False;
      Semantic_Blocker_Family_Present : Boolean := True;
      Consumer_Represents_Blocker_State : Boolean := True;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Partial_Coverage_Represented : Boolean := True;
      Missing_Checker_Represented : Boolean := True;
      Evidence_Stale : Boolean := False;
      Authoritative_Result_Used : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Precision_Row);

   type Precision_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Precision_Entry is record
      Area : Precision_Area := Area_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Slice : Implementing_Slice := Matrix.Slice_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Expected : Precision_Classification := Class_Unknown;
      Actual : Precision_Classification := Class_Unknown;
      Status : Precision_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Precision_Entry);

   type Precision_Model is record
      Items : Entry_Vectors.Vector;
      Ready_Count : Natural := 0;
      Legal_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Partial_Coverage_Count : Natural := 0;
      Missing_Checker_Count : Natural := 0;
      Hard_Diagnostic_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Precision_Row
     (Input : in out Precision_Input;
      Row : Precision_Row);

   function Build (Input : Precision_Input) return Precision_Model;
   function Count (Results : Precision_Model) return Natural;
   function Result_At (Results : Precision_Model; Index : Positive) return Precision_Entry;
   function Result_For (Results : Precision_Model; Area : Precision_Area) return Precision_Entry;
   function Partial_Evidence_Precision_Ready (Results : Precision_Model) return Boolean;
   function False_Positive_False_Negative_Hardened (Results : Precision_Model) return Boolean;

end Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;
