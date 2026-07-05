with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Control_Flow_Statement_Vertical_Slice_Legality is

   --  Case 1308 vertical-slice statement/expression control-flow legality.
   --  This package checks concrete return, raise, exit, goto, if/case,
   --  loop, and no-return control-flow rules against source-shaped semantic
   --  rows.  It is intentionally not a diagnostic/provenance/closure wrapper.

   type Flow_Id is new Natural;
   No_Flow : constant Flow_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Control_Construct_Kind is
     (Construct_Return_Statement,
      Construct_Extended_Return,
      Construct_Return_Expression,
      Construct_Raise_Statement,
      Construct_Raise_Expression,
      Construct_Exit_Statement,
      Construct_Goto_Statement,
      Construct_If_Statement,
      Construct_If_Expression,
      Construct_Case_Statement,
      Construct_Case_Expression,
      Construct_Loop_Statement,
      Construct_Block_Statement,
      Construct_No_Return_Call,
      Construct_Unknown);

   type Type_Class is
     (Type_Unknown,
      Type_Void,
      Type_Boolean,
      Type_Enumeration,
      Type_Integer,
      Type_Modular,
      Type_Universal_Integer,
      Type_Real,
      Type_Universal_Real,
      Type_Access,
      Type_Record,
      Type_Array,
      Type_Class_Wide,
      Type_Private,
      Type_Limited);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Context,
      Legality_Return_Missing_Expression,
      Legality_Return_Unexpected_Expression,
      Legality_Return_Type_Mismatch,
      Legality_Return_Accessibility_Blocked,
      Legality_Return_Definite_Assignment_Blocked,
      Legality_Raise_Missing_Exception,
      Legality_Raise_Exception_Not_Visible,
      Legality_Exit_Target_Missing,
      Legality_Exit_Target_Not_Loop,
      Legality_Goto_Target_Missing,
      Legality_Goto_Enters_Deeper_Scope,
      Legality_Goto_Enters_Protected_Action,
      Legality_Condition_Not_Boolean,
      Legality_Case_Expression_Type_Mismatch,
      Legality_Case_Alternatives_Incomplete,
      Legality_Case_Alternatives_Overlap,
      Legality_Loop_Exit_Path_Missing,
      Legality_No_Return_Falls_Through,
      Legality_Unreachable_Statement,
      Legality_Predicate_Blocked,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Flow_Info is record
      Id       : Flow_Id := No_Flow;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Control_Construct_Kind := Construct_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Context : Boolean := True;

      In_Function : Boolean := False;
      In_Procedure : Boolean := False;
      Expected_Result_Type : Type_Class := Type_Unknown;
      Actual_Result_Type : Type_Class := Type_Unknown;
      Has_Return_Expression : Boolean := False;
      Return_Expression_Required : Boolean := False;
      Return_Accessibility_Legal : Boolean := True;
      Return_Definite_Assignment_Legal : Boolean := True;

      Has_Exception_Entity : Boolean := True;
      Exception_Visible : Boolean := True;

      Has_Exit_Target : Boolean := True;
      Exit_Target_Is_Loop : Boolean := True;
      Loop_Has_Exit_Path : Boolean := True;

      Has_Goto_Target : Boolean := True;
      Goto_Enters_Deeper_Scope : Boolean := False;
      Goto_Enters_Protected_Action : Boolean := False;

      Condition_Type : Type_Class := Type_Boolean;
      Case_Expression_Type : Type_Class := Type_Unknown;
      Case_Alternative_Type : Type_Class := Type_Unknown;
      Case_Alternatives_Complete : Boolean := True;
      Case_Alternatives_Overlap : Boolean := False;

      No_Return_Expected : Boolean := False;
      May_Fall_Through : Boolean := False;
      Statement_Reachable : Boolean := True;

      Predicate_Legal : Boolean := True;
      Runtime_Check_Required : Boolean := False;
      Universal_Compatible : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Flow     : Flow_Id := No_Flow;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Control_Construct_Kind := Construct_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Context_Blockers : Natural := 0;
      Return_Missing_Blockers : Natural := 0;
      Return_Unexpected_Blockers : Natural := 0;
      Return_Type_Blockers : Natural := 0;
      Return_Accessibility_Blockers : Natural := 0;
      Return_Assignment_Blockers : Natural := 0;
      Raise_Missing_Blockers : Natural := 0;
      Raise_Visibility_Blockers : Natural := 0;
      Exit_Target_Blockers : Natural := 0;
      Exit_Target_Kind_Blockers : Natural := 0;
      Goto_Target_Blockers : Natural := 0;
      Goto_Scope_Blockers : Natural := 0;
      Goto_Protected_Blockers : Natural := 0;
      Condition_Blockers : Natural := 0;
      Case_Type_Blockers : Natural := 0;
      Case_Incomplete_Blockers : Natural := 0;
      Case_Overlap_Blockers : Natural := 0;
      Loop_Exit_Blockers : Natural := 0;
      No_Return_Blockers : Natural := 0;
      Unreachable_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Required : Boolean := False;
      Resolved_Result_Type : Type_Class := Type_Unknown;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail  : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Flow_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Flow_Model);
   procedure Add_Flow (Model : in out Flow_Model; Info : Flow_Info);

   function Build (Flows : Flow_Model) return Result_Model;

   function Flow_Count (Model : Flow_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Flow_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Flow_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Flow_Model is record
      Items : Flow_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Control_Flow_Statement_Vertical_Slice_Legality;
