with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Flow_Refinement_Vertical_Slice_Legality is

   --  Pass1334 vertical-slice legality for Ada flow refinement.  This
   --  package models source-shaped Refined_Global, Refined_Depends,
   --  abstract-state constituent flow, initialization flow, data dependency,
   --  dispatching effect joins, generic substitutions, and volatile/atomic
   --  ordering evidence.  It returns deterministic blocker families and does
   --  not add projection, diagnostic, rendering, or workspace plumbing.

   type Entity_Id is new Natural;
   No_Entity : constant Entity_Id := 0;

   type State_Id is new Natural;
   No_State : constant State_Id := 0;

   type Flow_Id is new Natural;
   No_Flow : constant Flow_Id := 0;

   type Check_Id is new Natural;
   No_Check : constant Check_Id := 0;

   type Result_Id is new Natural;
   No_Result : constant Result_Id := 0;

   type Entity_Kind is
     (Entity_Subprogram,
      Entity_Dispatching_Operation,
      Entity_Generic_Instance,
      Entity_Abstract_State,
      Entity_State_Constituent,
      Entity_Object,
      Entity_Type,
      Entity_Unknown);

   type Flow_Mode is
     (Mode_Null,
      Mode_In,
      Mode_Out,
      Mode_In_Out,
      Mode_Proof_In,
      Mode_Unknown);

   type Check_Kind is
     (Check_Refined_Global,
      Check_Refined_Depends,
      Check_Abstract_State_Constituent_Flow,
      Check_Initialization_Flow,
      Check_Data_Dependency,
      Check_Dispatching_Effect_Join,
      Check_Generic_Substitution_Flow,
      Check_Volatile_Atomic_Ordering,
      Check_Unknown);

   type View_Kind is
     (View_Full,
      View_Private,
      View_Limited,
      View_Incomplete,
      View_Generic_Formal,
      View_Unknown);

   type Legality_Status is
     (Legality_Not_Checked,
      Legality_Legal,
      Legality_Missing_Check,
      Legality_Missing_Entity,
      Legality_Missing_State,
      Legality_Missing_Flow,
      Legality_Entity_Kind_Mismatch,
      Legality_Refined_Global_Missing,
      Legality_Global_Mode_Mismatch,
      Legality_Refined_Depends_Missing,
      Legality_Depends_Source_Missing,
      Legality_Depends_Target_Missing,
      Legality_Depends_Cycle,
      Legality_Constituent_Missing,
      Legality_Constituent_Extra,
      Legality_Constituent_Mode_Mismatch,
      Legality_Initialization_Missing,
      Legality_Initialization_Order_Mismatch,
      Legality_Data_Dependency_Mismatch,
      Legality_Dispatching_Effect_Join_Mismatch,
      Legality_Generic_Substitution_Mismatch,
      Legality_Volatile_Ordering_Mismatch,
      Legality_Atomic_Ordering_Mismatch,
      Legality_Private_View_Barrier,
      Legality_Limited_View_Barrier,
      Legality_Incomplete_View_Barrier,
      Legality_Generic_Formal_View_Barrier,
      Legality_Source_Fingerprint_Mismatch,
      Legality_AST_Fingerprint_Mismatch,
      Legality_State_Fingerprint_Mismatch,
      Legality_Flow_Fingerprint_Mismatch,
      Legality_Profile_Fingerprint_Mismatch,
      Legality_Substitution_Fingerprint_Mismatch,
      Legality_Effect_Fingerprint_Mismatch,
      Legality_Multiple_Blockers,
      Legality_Indeterminate);

   type Entity_Info is record
      Id : Entity_Id := No_Entity;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Entity_Kind := Entity_Unknown;
      View : View_Kind := View_Full;
      Has_Refined_Global : Boolean := False;
      Has_Refined_Depends : Boolean := False;
      Refined_Global_Mode_OK : Boolean := True;
      Refined_Depends_OK : Boolean := True;
      Dispatching_Effect_Join_OK : Boolean := True;
      Generic_Substitution_OK : Boolean := True;
      Volatile_Ordering_OK : Boolean := True;
      Atomic_Ordering_OK : Boolean := True;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      State_Fingerprint : Natural := 0;
      Flow_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_State_Fingerprint : Natural := 0;
      Expected_Flow_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
   end record;

   package Entity_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Entity_Info);

   type Entity_Model is record
      Items : Entity_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type State_Info is record
      Id : State_Id := No_State;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Owner : Entity_Id := No_Entity;
      View : View_Kind := View_Full;
      Mode : Flow_Mode := Mode_Unknown;
      Has_Abstract_State : Boolean := False;
      Has_Constituent : Boolean := False;
      Constituent_Extra : Boolean := False;
      Constituent_Mode_OK : Boolean := True;
      Initialized : Boolean := True;
      Initialization_Order_OK : Boolean := True;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      State_Fingerprint : Natural := 0;
      Flow_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_State_Fingerprint : Natural := 0;
      Expected_Flow_Fingerprint : Natural := 0;
   end record;

   package State_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => State_Info);

   type State_Model is record
      Items : State_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Flow_Info is record
      Id : Flow_Id := No_Flow;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source : State_Id := No_State;
      Target : State_Id := No_State;
      Mode : Flow_Mode := Mode_Unknown;
      Source_Present : Boolean := True;
      Target_Present : Boolean := True;
      Has_Cycle : Boolean := False;
      Data_Dependency_OK : Boolean := True;
      Initialization_OK : Boolean := True;
      Volatile_Ordering_OK : Boolean := True;
      Atomic_Ordering_OK : Boolean := True;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Flow_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_Flow_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
   end record;

   package Flow_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Flow_Info);

   type Flow_Model is record
      Items : Flow_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Check_Info is record
      Id : Check_Id := No_Check;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Kind : Check_Kind := Check_Unknown;
      Operation : Entity_Id := No_Entity;
      State : State_Id := No_State;
      Flow : Flow_Id := No_Flow;
      Expected_Entity_Kind : Entity_Kind := Entity_Unknown;
      Expected_Mode : Flow_Mode := Mode_Unknown;
      Requires_Refined_Global : Boolean := False;
      Requires_Refined_Depends : Boolean := False;
      Requires_Depends_Source : Boolean := False;
      Requires_Depends_Target : Boolean := False;
      Reject_Depends_Cycle : Boolean := True;
      Requires_Abstract_State : Boolean := False;
      Requires_Constituent : Boolean := False;
      Reject_Extra_Constituent : Boolean := True;
      Requires_Initialization : Boolean := False;
      Requires_Dispatching_Join : Boolean := False;
      Requires_Generic_Substitution : Boolean := False;
      Requires_Volatile_Ordering : Boolean := False;
      Requires_Atomic_Ordering : Boolean := False;
      Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      State_Fingerprint : Natural := 0;
      Flow_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Expected_State_Fingerprint : Natural := 0;
      Expected_Flow_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
   end record;

   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Check_Info);

   type Check_Model is record
      Items : Check_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Result_Info is record
      Id : Result_Id := No_Result;
      Check : Check_Id := No_Check;
      Status : Legality_Status := Legality_Not_Checked;
      Source_Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Fingerprint : Natural := 0;
      Missing_Check_Blockers : Natural := 0;
      Missing_Entity_Blockers : Natural := 0;
      Missing_State_Blockers : Natural := 0;
      Missing_Flow_Blockers : Natural := 0;
      Entity_Kind_Blockers : Natural := 0;
      Refined_Global_Missing_Blockers : Natural := 0;
      Global_Mode_Blockers : Natural := 0;
      Refined_Depends_Missing_Blockers : Natural := 0;
      Depends_Source_Blockers : Natural := 0;
      Depends_Target_Blockers : Natural := 0;
      Depends_Cycle_Blockers : Natural := 0;
      Constituent_Missing_Blockers : Natural := 0;
      Constituent_Extra_Blockers : Natural := 0;
      Constituent_Mode_Blockers : Natural := 0;
      Initialization_Missing_Blockers : Natural := 0;
      Initialization_Order_Blockers : Natural := 0;
      Data_Dependency_Blockers : Natural := 0;
      Dispatching_Effect_Join_Blockers : Natural := 0;
      Generic_Substitution_Blockers : Natural := 0;
      Volatile_Ordering_Blockers : Natural := 0;
      Atomic_Ordering_Blockers : Natural := 0;
      Private_View_Blockers : Natural := 0;
      Limited_View_Blockers : Natural := 0;
      Incomplete_View_Blockers : Natural := 0;
      Generic_Formal_View_Blockers : Natural := 0;
      Source_Fingerprint_Blockers : Natural := 0;
      AST_Fingerprint_Blockers : Natural := 0;
      State_Fingerprint_Blockers : Natural := 0;
      Flow_Fingerprint_Blockers : Natural := 0;
      Profile_Fingerprint_Blockers : Natural := 0;
      Substitution_Fingerprint_Blockers : Natural := 0;
      Effect_Fingerprint_Blockers : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Result_Info);

   type Result_Model is record
      Items : Result_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   procedure Clear (Model : in out Entity_Model);
   procedure Clear (Model : in out State_Model);
   procedure Clear (Model : in out Flow_Model);
   procedure Clear (Model : in out Check_Model);
   procedure Clear (Model : in out Result_Model);

   procedure Add_Entity (Model : in out Entity_Model; Item : Entity_Info);
   procedure Add_State (Model : in out State_Model; Item : State_Info);
   procedure Add_Flow (Model : in out Flow_Model; Item : Flow_Info);
   procedure Add_Check (Model : in out Check_Model; Item : Check_Info);

   function Build
     (Entities : Entity_Model;
      States : State_Model;
      Flows : Flow_Model;
      Checks : Check_Model) return Result_Model;

   function Count (Model : Result_Model) return Natural;
   function Result_At (Model : Result_Model; Index : Positive) return Result_Info;

end Editor.Ada_Flow_Refinement_Vertical_Slice_Legality;
