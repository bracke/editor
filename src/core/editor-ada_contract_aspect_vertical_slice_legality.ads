with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Contract_Aspect_Vertical_Slice_Legality is

   --  Pass1329 vertical-slice contract and aspect legality.
   --  This package models source-shaped Ada contract/aspect specifications:
   --  Pre/Post, type invariants, predicates, default/initial conditions,
   --  Global/Depends and refined variants, abstract/refined state,
   --  Preelaborable_Initialization, No_Return, Inline, and Convention.
   --  The checker is deterministic, bounded, and snapshot-owned.

   type Entity_Id is new Natural;
   No_Entity : constant Entity_Id := 0;

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Aspect_Id is new Natural;
   No_Aspect : constant Aspect_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Subject_Kind is
     (Subject_Subprogram,
      Subject_Function,
      Subject_Procedure,
      Subject_Type,
      Subject_Package,
      Subject_Generic_Unit,
      Subject_Abstract_State,
      Subject_Object,
      Subject_Unknown);

   type Type_Kind is
     (Type_Boolean,
      Type_Discrete,
      Type_Scalar,
      Type_Record,
      Type_Tagged,
      Type_Array,
      Type_Access,
      Type_Controlled,
      Type_Task,
      Type_Protected,
      Type_Private,
      Type_Limited,
      Type_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Aspect_Kind is
     (Aspect_Pre,
      Aspect_Post,
      Aspect_Type_Invariant,
      Aspect_Static_Predicate,
      Aspect_Dynamic_Predicate,
      Aspect_Default_Initial_Condition,
      Aspect_Initial_Condition,
      Aspect_Global,
      Aspect_Depends,
      Aspect_Refined_Global,
      Aspect_Refined_Depends,
      Aspect_Abstract_State,
      Aspect_Refined_State,
      Aspect_Preelaborable_Initialization,
      Aspect_No_Return,
      Aspect_Inline,
      Aspect_Convention,
      Aspect_Unknown);

   type Global_Mode is
     (Global_Unspecified,
      Global_Null,
      Global_In,
      Global_Out,
      Global_In_Out,
      Global_Proof_In);

   subtype Subject_Global_Mode is Global_Mode;

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Legal_With_Runtime_Check,
      Legality_Missing_Aspect,
      Legality_Missing_Target,
      Legality_Missing_Expression_Type,
      Legality_Missing_State,
      Legality_Missing_Constituent,
      Legality_Aspect_Target_Mismatch,
      Legality_Boolean_Expression_Required,
      Legality_Static_Expression_Required,
      Legality_Global_Mode_Mismatch,
      Legality_Depends_Target_Missing,
      Legality_Depends_Source_Missing,
      Legality_Depends_Cycle,
      Legality_Refinement_Without_Abstract_State,
      Legality_Refinement_Extra_Constituent,
      Legality_Refinement_Mode_Mismatch,
      Legality_Preelaborable_Initialization_Blocker,
      Legality_No_Return_Target_Invalid,
      Legality_No_Return_Fallthrough,
      Legality_Convention_Profile_Mismatch,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_Type_Fingerprint_Mismatch,
      Legality_Profile_Fingerprint_Mismatch,
      Legality_State_Fingerprint_Mismatch,
      Legality_Effect_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Subject_Info is record
      Id : Entity_Id := No_Entity;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Subject_Kind := Subject_Unknown;
      Typ : Type_Id := No_Type;
      View : View_Kind := View_Full;
      Is_Elaborated : Boolean := True;
      Is_Preelaborable : Boolean := True;
      Is_Imported : Boolean := False;
      Has_Body : Boolean := True;
      Has_Abstract_State : Boolean := False;
      Has_Refinement : Boolean := False;
      Callable_May_Return : Boolean := True;
      Profile_Convention_OK : Boolean := True;
      Global_Mode : Subject_Global_Mode := Global_Unspecified;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      State_Fingerprint : Natural := 0;
      Expected_State_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
   end record;

   type Type_Info is record
      Id : Type_Id := No_Type;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Type_Kind := Type_Unknown;
      View : View_Kind := View_Full;
      Base_Type : Type_Id := No_Type;
      Is_Boolean : Boolean := False;
      Has_Controlled_Component : Boolean := False;
      Has_Task_Component : Boolean := False;
      Has_Protected_Component : Boolean := False;
      Has_Access_Component : Boolean := False;
      Predicate_Runtime_Check : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
   end record;

   type Aspect_Info is record
      Id : Aspect_Id := No_Aspect;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Kind : Aspect_Kind := Aspect_Unknown;
      Target : Entity_Id := No_Entity;
      Expression_Type : Type_Id := No_Type;
      State_Target : Entity_Id := No_Entity;
      State_Source : Entity_Id := No_Entity;
      Constituent : Entity_Id := No_Entity;
      Required_Global_Mode : Subject_Global_Mode := Global_Unspecified;
      Actual_Global_Mode : Subject_Global_Mode := Global_Unspecified;
      Is_Static_Expression : Boolean := True;
      Boolean_Expression_OK : Boolean := True;
      Depends_Target_Present : Boolean := True;
      Depends_Source_Present : Boolean := True;
      Depends_Cycle : Boolean := False;
      Refinement_Has_Abstract_State : Boolean := True;
      Constituent_Present : Boolean := True;
      Extra_Constituent : Boolean := False;
      Constituent_Mode_OK : Boolean := True;
      Preelaborable_Init_OK : Boolean := True;
      No_Return_Target_OK : Boolean := True;
      No_Return_Fallthrough : Boolean := False;
      Convention_Profile_OK : Boolean := True;
      Runtime_Check_Required : Boolean := False;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      State_Fingerprint : Natural := 0;
      Expected_State_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Aspect : Aspect_Id := No_Aspect;
      Kind : Aspect_Kind := Aspect_Unknown;
      Status : Legality_Status := Legality_Not_Checked;
      Missing_Aspect_Blockers : Natural := 0;
      Missing_Target_Blockers : Natural := 0;
      Missing_Expression_Type_Blockers : Natural := 0;
      Missing_State_Blockers : Natural := 0;
      Missing_Constituent_Blockers : Natural := 0;
      Target_Mismatch_Blockers : Natural := 0;
      Boolean_Expression_Blockers : Natural := 0;
      Static_Expression_Blockers : Natural := 0;
      Global_Mode_Blockers : Natural := 0;
      Depends_Target_Blockers : Natural := 0;
      Depends_Source_Blockers : Natural := 0;
      Depends_Cycle_Blockers : Natural := 0;
      Refinement_Abstract_State_Blockers : Natural := 0;
      Refinement_Extra_Constituent_Blockers : Natural := 0;
      Refinement_Mode_Blockers : Natural := 0;
      Preelaborable_Init_Blockers : Natural := 0;
      No_Return_Target_Blockers : Natural := 0;
      No_Return_Fallthrough_Blockers : Natural := 0;
      Convention_Profile_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      Type_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      State_Fingerprint_Blockers : Natural := 0;
      Effect_Fingerprint_Blockers : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Message : Ada.Strings.Unbounded.Unbounded_String;
      Detail : Ada.Strings.Unbounded.Unbounded_String;
      Fingerprint : Natural := 0;
   end record;

   type Subject_Model is private;
   type Type_Model is private;
   type Aspect_Model is private;
   type Result_Model is private;

   procedure Clear (Model : in out Subject_Model);
   procedure Clear (Model : in out Type_Model);
   procedure Clear (Model : in out Aspect_Model);
   procedure Add_Subject (Model : in out Subject_Model; Info : Subject_Info);
   procedure Add_Type (Model : in out Type_Model; Info : Type_Info);
   procedure Add_Aspect (Model : in out Aspect_Model; Info : Aspect_Info);

   function Build
     (Subjects : Subject_Model;
      Types : Type_Model;
      Aspects : Aspect_Model) return Result_Model;

   function Subject_Count (Model : Subject_Model) return Natural;
   function Type_Count (Model : Type_Model) return Natural;
   function Aspect_Count (Model : Aspect_Model) return Natural;
   function Result_Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;
   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural;
   function Legal_Count (Model : Result_Model) return Natural;
   function Error_Count (Model : Result_Model) return Natural;
   function Fingerprint (Model : Result_Model) return Natural;
   function Has_Result (Info : Result_Info) return Boolean;

private
   package Subject_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Subject_Info);
   package Type_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Type_Info);
   package Aspect_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Aspect_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Result_Info);

   type Subject_Model is record
      Items : Subject_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Type_Model is record
      Items : Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Aspect_Model is record
      Items : Aspect_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Contract_Aspect_Vertical_Slice_Legality;
