with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Membership_Case_Choice_Vertical_Slice_Legality is

   --  Case 1315 vertical-slice membership/case-choice legality.  This
   --  package models concrete Ada membership tests, discrete choices,
   --  case coverage, choice overlap, and static choice validation needed by
   --  control-flow, subtype/range, predicate, aggregate, and overload
   --  consumers.  It is intentionally rule-oriented rather than another
   --  diagnostic/provenance/closure wrapper.

   type Check_Id is new Natural;
   No_Check : constant Check_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Choice_Kind is
     (Choice_Membership_Test,
      Choice_Not_In_Test,
      Choice_Case_Statement,
      Choice_Case_Expression,
      Choice_Variant_Choice,
      Choice_Aggregate_Choice,
      Choice_Array_Index_Choice,
      Choice_Record_Discriminant_Choice,
      Choice_Unknown);

   type Discrete_Class is
     (Discrete_Unknown,
      Discrete_Boolean,
      Discrete_Enumeration,
      Discrete_Integer,
      Discrete_Modular,
      Discrete_Character,
      Discrete_Wide_Character,
      Discrete_Not_Discrete);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal_Static,
      Legality_Legal_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Type_Evidence,
      Legality_Subject_Not_Discrete,
      Legality_Choice_Type_Mismatch,
      Legality_Choice_Not_Static,
      Legality_Range_Bounds_Reversed,
      Legality_Range_Out_Of_Base,
      Legality_Case_Missing_Choice,
      Legality_Case_Incomplete,
      Legality_Case_Choice_Overlap,
      Legality_Others_Not_Last,
      Legality_Duplicate_Others,
      Legality_Null_Range_Static,
      Legality_Variant_Governor_Mismatch,
      Legality_Aggregate_Choice_Mismatch,
      Legality_Runtime_Membership_Check,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Type_Fingerprint_Mismatch,
      Legality_Static_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Choice_Info is record
      Id       : Check_Id := No_Check;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Choice_Kind := Choice_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Type_Evidence : Boolean := True;
      Has_Static_Evidence : Boolean := True;

      Subject_Type : Discrete_Class := Discrete_Unknown;
      Choice_Type  : Discrete_Class := Discrete_Unknown;
      Expected_Type : Discrete_Class := Discrete_Unknown;

      Subject_Is_Discrete : Boolean := True;
      Choice_Type_Compatible : Boolean := True;
      Choice_Is_Static : Boolean := True;
      Bounds_Are_Static : Boolean := True;
      Bounds_In_Base : Boolean := True;
      Bounds_Reversed : Boolean := False;
      Null_Range_Allowed : Boolean := True;
      Runtime_Check_Allowed : Boolean := False;

      Has_At_Least_One_Choice : Boolean := True;
      Case_Coverage_Complete : Boolean := True;
      Choices_Overlap : Boolean := False;
      Others_Present : Boolean := False;
      Others_Is_Last : Boolean := True;
      Duplicate_Others : Boolean := False;

      Variant_Governor_Compatible : Boolean := True;
      Aggregate_Choice_Compatible : Boolean := True;

      Low_Value  : Long_Long_Integer := 0;
      High_Value : Long_Long_Integer := 0;
      Base_Low   : Long_Long_Integer := -9_223_372_036_854_775_000;
      Base_High  : Long_Long_Integer :=  9_223_372_036_854_775_000;
      Covered_Choice_Count : Natural := 0;
      Expected_Choice_Count : Natural := 0;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Expected_Static_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Static_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Check    : Check_Id := No_Check;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Choice_Kind := Choice_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Type_Blockers : Natural := 0;
      Static_Blockers : Natural := 0;
      Subject_Discrete_Blockers : Natural := 0;
      Choice_Type_Blockers : Natural := 0;
      Choice_Static_Blockers : Natural := 0;
      Reversed_Range_Blockers : Natural := 0;
      Out_Of_Base_Blockers : Natural := 0;
      Missing_Choice_Blockers : Natural := 0;
      Incomplete_Case_Blockers : Natural := 0;
      Choice_Overlap_Blockers : Natural := 0;
      Others_Order_Blockers : Natural := 0;
      Duplicate_Others_Blockers : Natural := 0;
      Null_Range_Blockers : Natural := 0;
      Variant_Governor_Blockers : Natural := 0;
      Aggregate_Choice_Blockers : Natural := 0;
      Runtime_Check_Required : Boolean := False;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Static_Fingerprint_Blockers : Natural := 0;
      Covered_Choice_Count : Natural := 0;
      Expected_Choice_Count : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Choice_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Choice_Model);
   procedure Add_Choice (Model : in out Choice_Model; Info : Choice_Info);

   function Build (Choices : Choice_Model) return Result_Model;

   function Choice_Count (Model : Choice_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Choice_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Choice_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Choice_Model is record
      Items : Choice_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Membership_Case_Choice_Vertical_Slice_Legality;
