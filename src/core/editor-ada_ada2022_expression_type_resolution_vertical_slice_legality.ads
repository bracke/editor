with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality is

   --  Pass1305 vertical-slice expression/type resolution legality for Ada
   --  2022 constructs that gained parser/AST coverage in Pass1304.  This
   --  package checks concrete expression typing prerequisites instead of
   --  adding another diagnostic, provenance, or closure wrapper.

   type Expression_Id is new Natural;
   No_Expression : constant Expression_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Expression_Kind is
     (Expression_Quantified,
      Expression_Reduction,
      Expression_Delta_Aggregate,
      Expression_Container_Aggregate,
      Expression_Declare,
      Expression_Target_Name_Update,
      Expression_Generalized_Indexing,
      Expression_Parallel_Loop,
      Expression_Unknown);

   type Type_Class is
     (Type_Unknown,
      Type_Boolean,
      Type_Integer,
      Type_Real,
      Type_Universal_Integer,
      Type_Universal_Real,
      Type_Array,
      Type_Record,
      Type_Tagged,
      Type_Access,
      Type_Container,
      Type_Iterator,
      Type_Void);

   type Resolution_Status is
     (Resolution_Not_Checked,
      Resolution_Legal,
      Resolution_Legal_With_Runtime_Check,
      Resolution_Missing_AST_Coverage,
      Resolution_Missing_Expected_Type,
      Resolution_Missing_Operand_Type,
      Resolution_Predicate_Not_Boolean,
      Resolution_Reduction_Profile_Mismatch,
      Resolution_Reduction_Seed_Mismatch,
      Resolution_Delta_Base_Not_Composite,
      Resolution_Delta_Component_Mismatch,
      Resolution_Container_Element_Mismatch,
      Resolution_Declare_Result_Mismatch,
      Resolution_Target_Name_Outside_Update,
      Resolution_Generalized_Indexing_Mismatch,
      Resolution_Parallel_Loop_Shared_State_Blocker,
      Resolution_Expected_Type_Mismatch,
      Resolution_Source_Fingerprint_Mismatch,
      Resolution_AST_Fingerprint_Mismatch,
      Resolution_Multiple_Blockers,
      Resolution_Indeterminate);

   type Expression_Info is record
      Id       : Expression_Id := No_Expression;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Expression_Kind := Expression_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Expected_Type : Boolean := True;
      Has_Primary_Operand_Type : Boolean := True;
      Has_Secondary_Operand_Type : Boolean := True;
      Has_Result_Type : Boolean := True;

      Expected_Type : Type_Class := Type_Unknown;
      Primary_Type  : Type_Class := Type_Unknown;
      Secondary_Type : Type_Class := Type_Unknown;
      Result_Type   : Type_Class := Type_Unknown;
      Element_Type  : Type_Class := Type_Unknown;
      Accumulator_Type : Type_Class := Type_Unknown;

      Predicate_Result_Is_Boolean : Boolean := True;
      Reducer_Profile_Compatible : Boolean := True;
      Reduction_Seed_Compatible : Boolean := True;
      Delta_Component_Exists : Boolean := True;
      Delta_Component_Compatible : Boolean := True;
      Container_Element_Compatible : Boolean := True;
      Declare_Declarations_Elaborable : Boolean := True;
      Target_Name_In_Update_Context : Boolean := True;
      Generalized_Indexing_Profile_Compatible : Boolean := True;
      Parallel_Shared_State_Safe : Boolean := True;
      Needs_Runtime_Accessibility_Check : Boolean := False;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Expression : Expression_Id := No_Expression;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Expression_Kind := Expression_Unknown;
      Status   : Resolution_Status := Resolution_Not_Checked;
      AST_Blockers : Natural := 0;
      Expected_Type_Blockers : Natural := 0;
      Operand_Type_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Reduction_Profile_Blockers : Natural := 0;
      Reduction_Seed_Blockers : Natural := 0;
      Delta_Base_Blockers : Natural := 0;
      Delta_Component_Blockers : Natural := 0;
      Container_Element_Blockers : Natural := 0;
      Declare_Result_Blockers : Natural := 0;
      Target_Name_Blockers : Natural := 0;
      Indexing_Blockers : Natural := 0;
      Parallel_State_Blockers : Natural := 0;
      Expected_Result_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Resolved_Type : Type_Class := Type_Unknown;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
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
   function Count_Status (Model : Result_Model; Status : Resolution_Status) return Natural;
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

end Editor.Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality;
