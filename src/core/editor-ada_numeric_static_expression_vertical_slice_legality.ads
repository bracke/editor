with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Numeric_Static_Expression_Vertical_Slice_Legality is

   --  Case 1314 vertical-slice numeric/static-expression legality.  This
   --  package models concrete Ada staticness and universal numeric checks
   --  needed by overload, subtype/range, representation, and aggregate
   --  consumers; it is not a diagnostic/provenance/closure wrapper.

   type Expression_Id is new Natural;
   No_Expression : constant Expression_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Expression_Kind is
     (Expr_Named_Number,
      Expr_Static_Constant,
      Expr_Integer_Literal,
      Expr_Real_Literal,
      Expr_Unary_Operator,
      Expr_Binary_Operator,
      Expr_Qualified_Expression,
      Expr_Static_Attribute,
      Expr_Range_Bound,
      Expr_Modular_Expression,
      Expr_Fixed_Point_Expression,
      Expr_Unknown);

   type Numeric_Class is
     (Numeric_Unknown,
      Numeric_Boolean,
      Numeric_Integer,
      Numeric_Modular,
      Numeric_Universal_Integer,
      Numeric_Real,
      Numeric_Universal_Real,
      Numeric_Fixed,
      Numeric_Duration,
      Numeric_Not_Numeric);

   type Operator_Kind is
     (Operator_None,
      Operator_Add,
      Operator_Subtract,
      Operator_Multiply,
      Operator_Divide,
      Operator_Mod,
      Operator_Rem,
      Operator_Exponent,
      Operator_Abs,
      Operator_Unary_Minus,
      Operator_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal_Static,
      Legality_Legal_Nonstatic_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Type_Evidence,
      Legality_Not_Static,
      Legality_Named_Number_Not_Static,
      Legality_Static_Constant_Not_Static,
      Legality_Operand_Not_Static,
      Legality_Operator_Not_Static,
      Legality_Universal_Numeric_Ambiguous,
      Legality_Universal_Numeric_Not_Resolved,
      Legality_Expected_Type_Mismatch,
      Legality_Range_Out_Of_Base,
      Legality_Modular_Out_Of_Modulus,
      Legality_Divide_By_Zero_Static,
      Legality_Exponent_Not_Natural,
      Legality_Fixed_Delta_Mismatch,
      Legality_Attribute_Not_Static,
      Legality_Qualification_Mismatch,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Type_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Expression_Info is record
      Id       : Expression_Id := No_Expression;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Expression_Kind := Expr_Unknown;
      Operator : Operator_Kind := Operator_None;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Type_Evidence : Boolean := True;
      Expression_Is_Static : Boolean := True;
      Requires_Static_Context : Boolean := True;
      Named_Number_Is_Static : Boolean := True;
      Static_Constant_Is_Static : Boolean := True;
      Left_Operand_Static : Boolean := True;
      Right_Operand_Static : Boolean := True;
      Operator_Static_Allowed : Boolean := True;
      Attribute_Static : Boolean := True;
      Qualified_Type_Compatible : Boolean := True;

      Actual_Type : Numeric_Class := Numeric_Unknown;
      Expected_Type : Numeric_Class := Numeric_Unknown;
      Left_Type : Numeric_Class := Numeric_Unknown;
      Right_Type : Numeric_Class := Numeric_Unknown;
      Resolved_Type : Numeric_Class := Numeric_Unknown;

      Universal_Ambiguous : Boolean := False;
      Universal_Resolved : Boolean := True;
      Runtime_Check_Required : Boolean := False;
      Range_Check_Required : Boolean := False;
      Range_In_Base : Boolean := True;
      Modular_In_Modulus : Boolean := True;
      Divisor_Is_Zero : Boolean := False;
      Exponent_Is_Natural : Boolean := True;
      Fixed_Delta_Compatible : Boolean := True;

      Static_Integer_Value : Long_Long_Integer := 0;
      Base_Low  : Long_Long_Integer := -9_223_372_036_854_775_000;
      Base_High : Long_Long_Integer :=  9_223_372_036_854_775_000;
      Modulus   : Long_Long_Integer := 0;
      Delta_Numerator : Natural := 0;
      Delta_Denominator : Natural := 1;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Expression : Expression_Id := No_Expression;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Expression_Kind := Expr_Unknown;
      Operator : Operator_Kind := Operator_None;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Type_Blockers : Natural := 0;
      Static_Blockers : Natural := 0;
      Named_Number_Blockers : Natural := 0;
      Constant_Blockers : Natural := 0;
      Operand_Static_Blockers : Natural := 0;
      Operator_Static_Blockers : Natural := 0;
      Universal_Ambiguity_Blockers : Natural := 0;
      Universal_Resolution_Blockers : Natural := 0;
      Expected_Type_Blockers : Natural := 0;
      Range_Blockers : Natural := 0;
      Modular_Blockers : Natural := 0;
      Divide_By_Zero_Blockers : Natural := 0;
      Exponent_Blockers : Natural := 0;
      Fixed_Delta_Blockers : Natural := 0;
      Attribute_Blockers : Natural := 0;
      Qualification_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Required : Boolean := False;
      Resolved_Type : Numeric_Class := Numeric_Unknown;
      Static_Integer_Value : Long_Long_Integer := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Expression_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Expression_Model);
   procedure Add_Expression (Model : in out Expression_Model; Info : Expression_Info);

   function Build (Expressions : Expression_Model) return Result_Model;

   function Expression_Count (Model : Expression_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Expression_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Expression_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Expression_Model is record
      Items : Expression_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Numeric_Static_Expression_Vertical_Slice_Legality;
