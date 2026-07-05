with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Subtype_Range_Predicate_Vertical_Slice_Legality is

   --  Case 1306 vertical-slice subtype/range/predicate legality.  This
   --  package checks concrete scalar, modular, fixed/real, index, and
   --  predicate constraints that expression/type resolution consumers need;
   --  it is intentionally not a diagnostic/provenance/closure wrapper.

   type Subtype_Id is new Natural;
   No_Subtype : constant Subtype_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Constraint_Kind is
     (Constraint_Range,
      Constraint_Modular_Range,
      Constraint_Floating_Digits,
      Constraint_Fixed_Delta,
      Constraint_Index_Range,
      Constraint_Predicate,
      Constraint_Static_Predicate,
      Constraint_Dynamic_Predicate,
      Constraint_Unknown);

   type Type_Class is
     (Type_Unknown,
      Type_Boolean,
      Type_Enumeration,
      Type_Integer,
      Type_Modular,
      Type_Universal_Integer,
      Type_Real,
      Type_Universal_Real,
      Type_Fixed,
      Type_Array,
      Type_Record,
      Type_Access);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Base_Type,
      Legality_Missing_Static_Value,
      Legality_Range_Null,
      Legality_Range_Out_Of_Base,
      Legality_Modular_Range_Invalid,
      Legality_Digits_Invalid,
      Legality_Delta_Invalid,
      Legality_Index_Not_Discrete,
      Legality_Predicate_Not_Boolean,
      Legality_Static_Predicate_Not_Static,
      Legality_Static_Predicate_Out_Of_Range,
      Legality_Dynamic_Predicate_Requires_Check,
      Legality_Expected_Type_Mismatch,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Subtype_Info is record
      Id       : Subtype_Id := No_Subtype;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Constraint_Kind := Constraint_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Base_Type : Boolean := True;
      Has_Static_Lower : Boolean := True;
      Has_Static_Upper : Boolean := True;
      Has_Static_Value : Boolean := True;
      Has_Predicate_AST : Boolean := True;

      Base_Type : Type_Class := Type_Unknown;
      Expected_Type : Type_Class := Type_Unknown;
      Predicate_Type : Type_Class := Type_Boolean;

      Base_Low  : Long_Long_Integer := 0;
      Base_High : Long_Long_Integer := 0;
      Low       : Long_Long_Integer := 0;
      High      : Long_Long_Integer := 0;
      Static_Value : Long_Long_Integer := 0;
      Modulus   : Long_Long_Integer := 0;
      Digits_Value : Natural := 0;
      Delta_Numerator : Natural := 0;
      Delta_Denominator : Natural := 1;

      Predicate_Is_Boolean : Boolean := True;
      Predicate_Is_Static : Boolean := True;
      Predicate_Value_In_Range : Boolean := True;
      Predicate_Needs_Runtime_Check : Boolean := False;
      Index_Discrete : Boolean := True;
      Universal_Compatible : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Subtype_Ref : Subtype_Id := No_Subtype;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Constraint_Kind := Constraint_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Base_Type_Blockers : Natural := 0;
      Static_Value_Blockers : Natural := 0;
      Range_Null_Blockers : Natural := 0;
      Range_Base_Blockers : Natural := 0;
      Modular_Blockers : Natural := 0;
      Digits_Blockers : Natural := 0;
      Delta_Blockers : Natural := 0;
      Index_Blockers : Natural := 0;
      Predicate_Type_Blockers : Natural := 0;
      Static_Predicate_Blockers : Natural := 0;
      Static_Predicate_Range_Blockers : Natural := 0;
      Expected_Type_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Required : Boolean := False;
      Resolved_Type : Type_Class := Type_Unknown;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Subtype_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Subtype_Model);
   procedure Add_Subtype (Model : in out Subtype_Model; Info : Subtype_Info);

   function Build (Subtypes : Subtype_Model) return Result_Model;

   function Subtype_Count (Model : Subtype_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Subtype_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Subtype_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Subtype_Model is record
      Items : Subtype_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Subtype_Range_Predicate_Vertical_Slice_Legality;
