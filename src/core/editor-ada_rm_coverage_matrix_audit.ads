with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_RM_Coverage_Matrix_Audit is

   --  RM coverage matrix audit is part of the post vertical-slice integration
   --  audit campaign.
   --  It makes the Ada RM semantic coverage matrix explicit and machine
   --  checkable.  A rule family is not treated as covered unless it is tied
   --  to a present implementing semantic slice, has source-shaped tests,
   --  has a consumed semantic result, carries concrete rule-family evidence,
   --  and has fresh source/AST/type/profile/substitution/effect fingerprints.

   type RM_Family is
     (Family_Declarations_Completions,
      Family_Names_Visibility_Selected_Attributes,
      Family_Types_Subtypes_Constraints_Predicates,
      Family_Expressions_Expected_Type_Resolution,
      Family_Aggregates,
      Family_Assignments_Conversions,
      Family_Calls_Overload_Callable_Profiles,
      Family_Generics_Contracts_Substitution_Replay,
      Family_Tagged_Interfaces_Dispatching,
      Family_Arrays_Records_Discriminants_Variants,
      Family_Access_Types_Accessibility,
      Family_Tasking_Protected_Synchronized,
      Family_Exceptions_Finalization,
      Family_Representation_Aspects_Freezing,
      Family_Library_Context_Subunits_Elaboration,
      Family_Contracts_Global_Depends_Flow,
      Family_Interfacing_Import_Export,
      Family_Iterators_Parallel_Reductions,
      Family_Static_Expressions_Choices,
      Family_Diagnostics_Consumer_Readiness,
      Family_Unknown);

   type Implementing_Slice is
     (Slice_Body_Spec_Conformance,
      Slice_Visibility_Name_Resolution,
      Slice_Selected_Name_Attribute,
      Slice_Subtype_Range_Predicate,
      Slice_Ada2022_Expression_Type_Resolution,
      Slice_Numeric_Static_Expression,
      Slice_Membership_Case_Choice,
      Slice_Aggregate,
      Slice_Assignment_Conversion,
      Slice_Overload_Resolution,
      Slice_Callable_Profile,
      Slice_Generic_Contract_Body,
      Slice_Generic_Formal_Type_Family,
      Slice_Generic_Body_Replay,
      Slice_Tagged_Dispatching,
      Slice_Interface_Synchronized,
      Slice_Array_Container_Indexing,
      Slice_Discriminant_Variant_Record,
      Slice_Access_Type_Access_Subprogram,
      Slice_Accessibility_Lifetime,
      Slice_Tasking_Protected,
      Slice_Exception_Finalization,
      Slice_Freezing_Representation,
      Slice_Representation_Aspect_Operational,
      Slice_Record_Layout_Representation,
      Slice_Enumeration_Representation,
      Slice_Context_Clause_With_Use,
      Slice_Library_Unit_Subunit,
      Slice_Elaboration,
      Slice_Contract_Aspect,
      Slice_Abstract_State_Global_Depends,
      Slice_Flow_Refinement,
      Slice_Interfacing_Import_Export,
      Slice_Iterator_Loop_Parallel,
      Slice_Parser_AST_Coverage,
      Slice_Semantic_Integration_Audit,
      Slice_Canonical_Model_Agreement_Audit,
      Slice_End_To_End_Scenario_Audit,
      Slice_Diagnostics_Consumer,
      Slice_Unknown);

   type Coverage_Level is
     (Coverage_None,
      Coverage_Partial,
      Coverage_Covered,
      Coverage_Blocked,
      Coverage_Unknown);

   type Audit_Status is
     (Status_Not_Checked,
      Status_Covered,
      Status_Partial,
      Status_Not_Covered,
      Status_Missing_Implementing_Slice,
      Status_Slice_Unclaimed,
      Status_Duplicate_Coverage_Claim,
      Status_Conflicting_Coverage_Claim,
      Status_Missing_Source_Shaped_Test,
      Status_Unconsumed_Semantic_Result,
      Status_Generic_Compiler_Grade_Claim,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Coverage_Claim is record
      Id : Natural := 0;
      Family : RM_Family := Family_Unknown;
      Slice : Implementing_Slice := Slice_Unknown;
      Level : Coverage_Level := Coverage_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped_Test_Present : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Concrete_Rule_Family_Evidence : Boolean := True;
      Claims_Generic_Compiler_Grade : Boolean := False;
      Conflicts_With_Existing_Claim : Boolean := False;
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

   package Claim_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Coverage_Claim);

   type Slice_Result is record
      Slice : Implementing_Slice := Slice_Unknown;
      Present : Boolean := True;
      Result_Fingerprint : Natural := 0;
      Expected_Result_Fingerprint : Natural := 0;
   end record;

   package Slice_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Slice_Result);

   type Coverage_Matrix is record
      Claims : Claim_Vectors.Vector;
      Slices : Slice_Vectors.Vector;
   end record;

   type Audit_Entry is record
      Family : RM_Family := Family_Unknown;
      Slice : Implementing_Slice := Slice_Unknown;
      Status : Audit_Status := Status_Not_Checked;
      Level : Coverage_Level := Coverage_Unknown;
      Claim_Count : Natural := 0;
      Blocker_Count : Natural := 0;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Audit_Entry);

   type Audit_Model is record
      Items : Entry_Vectors.Vector;
      Total_Families : Natural := 0;
      Covered_Count : Natural := 0;
      Partial_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Unclaimed_Slice_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Coverage_Claim (Matrix : in out Coverage_Matrix; Claim : Coverage_Claim);
   procedure Add_Slice_Result (Matrix : in out Coverage_Matrix; Result : Slice_Result);

   function Build (Matrix : Coverage_Matrix) return Audit_Model;
   function Count (Results : Audit_Model) return Natural;
   function Result_At (Results : Audit_Model; Index : Positive) return Audit_Entry;
   function Result_For (Results : Audit_Model; Family : RM_Family) return Audit_Entry;
   function RM_Coverage_Audit_Ready (Results : Audit_Model) return Boolean;

end Editor.Ada_RM_Coverage_Matrix_Audit;
