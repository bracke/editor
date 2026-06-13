with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;

package Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339 is

   --  Pass1339 is the fifth post vertical-slice integration/audit pass.
   --  It turns the Pass1338 RM coverage matrix into an actionable gap
   --  remediation gate.  Every Ada rule family must have exactly one
   --  source-shaped remediation state: covered, partial, blocked, or
   --  missing.  Partial, blocked, and missing states must name concrete
   --  missing subrules or evidence blockers; covered states must be backed
   --  by consumed semantic results and end-to-end scenario evidence.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Matrix_Coverage_Level is Matrix.Coverage_Level;

   type Remediation_State is
     (State_Covered,
      State_Partial,
      State_Blocked,
      State_Missing,
      State_Unknown);

   type Required_Evidence is
     (Evidence_None,
      Evidence_Source,
      Evidence_AST,
      Evidence_Type,
      Evidence_Profile,
      Evidence_Unit,
      Evidence_Substitution,
      Evidence_Effect,
      Evidence_Representation,
      Evidence_Runtime_Check,
      Evidence_Consumer);

   type Remediation_Status is
     (Status_Not_Checked,
      Status_Covered,
      Status_Partial_Actionable,
      Status_Blocked_Actionable,
      Status_Missing_Actionable,
      Status_Missing_Remediation_Entry,
      Status_Missing_Matrix_Coverage,
      Status_State_Matrix_Mismatch,
      Status_Vague_Partial,
      Status_Missing_Subrule_Evidence,
      Status_Missing_Implementing_Package,
      Status_Duplicate_Remediation_Owner,
      Status_Missing_Source_Shaped_Evidence,
      Status_Unconsumed_Semantic_Result,
      Status_Unconsumed_End_To_End_Result,
      Status_Untraceable_Blocker,
      Status_Stale_Remediation_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Remediation_Item is record
      Id : Natural := 0;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      State : Remediation_State := State_Unknown;
      Matrix_Level : Matrix_Coverage_Level := Matrix.Coverage_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Matrix_Entry_Present : Boolean := True;
      Source_Shaped_Evidence : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      End_To_End_Consumed : Boolean := True;
      Missing_Subrules_Named : Boolean := True;
      Missing_Subrule_Count : Natural := 0;
      Required_Evidence_Absent : Required_Evidence := Evidence_None;
      Concrete_Blocker_Family : Boolean := True;
      Blocker_Source_Traceable : Boolean := True;
      Duplicate_Ownership : Boolean := False;
      Remediation_Fingerprint : Natural := 0;
      Expected_Remediation_Fingerprint : Natural := 0;
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
   end record;

   package Item_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Remediation_Item);

   type Remediation_Input is record
      Items : Item_Vectors.Vector;
   end record;

   type Remediation_Entry is record
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      State : Remediation_State := State_Unknown;
      Status : Remediation_Status := Status_Not_Checked;
      Matrix_Level : Matrix_Coverage_Level := Matrix.Coverage_Unknown;
      Missing_Subrule_Count : Natural := 0;
      Blocker_Count : Natural := 0;
      Actionable_Gap : Boolean := False;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Remediation_Entry);

   type Remediation_Model is record
      Items : Entry_Vectors.Vector;
      Total_Families : Natural := 0;
      Covered_Count : Natural := 0;
      Partial_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Missing_Count : Natural := 0;
      Actionable_Gap_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Remediation_Item
     (Input : in out Remediation_Input;
      Item : Remediation_Item);

   function Build (Input : Remediation_Input) return Remediation_Model;
   function Count (Results : Remediation_Model) return Natural;
   function Result_At (Results : Remediation_Model; Index : Positive) return Remediation_Entry;
   function Result_For (Results : Remediation_Model; Family : RM_Family) return Remediation_Entry;
   function Coverage_Gap_Remediation_Audit_Valid (Results : Remediation_Model) return Boolean;
   function RM_Gaps_Remediated (Results : Remediation_Model) return Boolean;
   function Actionable_Gaps_Present (Results : Remediation_Model) return Boolean;

end Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
