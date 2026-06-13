with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Object_Initialization_Default_Vertical_Slice_Legality is

   --  Pass1307 vertical-slice object initialization/default-expression
   --  legality.  This package checks concrete default initialization,
   --  aggregate initialization, deferred constants, controlled/finalized
   --  initialization, and definite-assignment prerequisites.  It is not a
   --  diagnostic/provenance/closure wrapper.

   type Object_Id is new Natural;
   No_Object : constant Object_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Initialization_Kind is
     (Initialization_Object_Declaration,
      Initialization_Default_Expression,
      Initialization_Deferred_Constant,
      Initialization_Aggregate,
      Initialization_Array_Aggregate,
      Initialization_Record_Aggregate,
      Initialization_Controlled_Object,
      Initialization_Access_Object,
      Initialization_Out_Parameter,
      Initialization_Unknown);

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
      Type_Access,
      Type_Limited,
      Type_Controlled,
      Type_Private);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_AST_Coverage,
      Legality_Missing_Object_Type,
      Legality_Missing_Initializer,
      Legality_Type_Mismatch,
      Legality_Subtype_Range_Blocked,
      Legality_Predicate_Blocked,
      Legality_Default_Expression_Blocked,
      Legality_Deferred_Constant_Missing_Completion,
      Legality_Deferred_Constant_Type_Mismatch,
      Legality_Aggregate_Component_Missing,
      Legality_Aggregate_Component_Duplicate,
      Legality_Aggregate_Component_Type_Mismatch,
      Legality_Limited_Default_Required,
      Legality_Controlled_Finalization_Blocked,
      Legality_Accessibility_Blocked,
      Legality_Definite_Assignment_Blocked,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Object_Info is record
      Id       : Object_Id := No_Object;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Initialization_Kind := Initialization_Unknown;
      Source_Name : Ada.Strings.Unbounded.Unbounded_String;

      Has_AST_Coverage : Boolean := True;
      Has_Object_Type : Boolean := True;
      Requires_Initializer : Boolean := False;
      Has_Initializer : Boolean := True;
      Has_Default_Expression : Boolean := True;
      Default_Expression_Legal : Boolean := True;

      Object_Type : Type_Class := Type_Unknown;
      Initializer_Type : Type_Class := Type_Unknown;
      Expected_Type : Type_Class := Type_Unknown;
      Universal_Compatible : Boolean := True;

      Subtype_Range_Legal : Boolean := True;
      Predicate_Legal : Boolean := True;
      Runtime_Predicate_Check_Required : Boolean := False;

      Is_Deferred_Constant : Boolean := False;
      Has_Deferred_Completion : Boolean := True;
      Deferred_Completion_Type_Matches : Boolean := True;

      Aggregate_Complete : Boolean := True;
      Aggregate_Has_Duplicate_Component : Boolean := False;
      Aggregate_Component_Types_Match : Boolean := True;

      Is_Limited_Type : Boolean := False;
      Limited_Default_Available : Boolean := True;
      Controlled_Finalization_Legal : Boolean := True;
      Accessibility_Legal : Boolean := True;
      Definite_Assignment_Legal : Boolean := True;

      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id       : Result_Id := No_Result;
      Object   : Object_Id := No_Object;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind     : Initialization_Kind := Initialization_Unknown;
      Status   : Legality_Status := Legality_Not_Checked;
      AST_Blockers : Natural := 0;
      Object_Type_Blockers : Natural := 0;
      Initializer_Blockers : Natural := 0;
      Type_Blockers : Natural := 0;
      Subtype_Blockers : Natural := 0;
      Predicate_Blockers : Natural := 0;
      Default_Blockers : Natural := 0;
      Deferred_Completion_Blockers : Natural := 0;
      Deferred_Type_Blockers : Natural := 0;
      Aggregate_Missing_Blockers : Natural := 0;
      Aggregate_Duplicate_Blockers : Natural := 0;
      Aggregate_Type_Blockers : Natural := 0;
      Limited_Default_Blockers : Natural := 0;
      Controlled_Blockers : Natural := 0;
      Accessibility_Blockers : Natural := 0;
      Assignment_Blockers : Natural := 0;
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

   type Initialization_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Initialization_Model);
   procedure Add_Object (Model : in out Initialization_Model; Info : Object_Info);

   function Build (Objects : Initialization_Model) return Result_Model;

   function Object_Count (Model : Initialization_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Object_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Object_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Initialization_Model is record
      Items : Object_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Object_Initialization_Default_Vertical_Slice_Legality;
