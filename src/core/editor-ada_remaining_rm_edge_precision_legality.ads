with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Precision_Legality is

   --  Case 1277 remaining Ada RM edge precision legality.
   --
   --  This package consumes the Case 1276 applied direct RM-completion
   --  closure-consumer boundary and models the remaining hard Ada RM edge
   --  cases that still require direct legality evidence before downstream
   --  semantic consumers may treat them as accepted: dispatching calls with
   --  abstract-state effects, renamed primitives, inherited/private-extension
   --  primitive hiding, access-to-subprogram effect profiles, generic formal
   --  subprogram calls, universal numeric ambiguity under stateful expected
   --  contexts, volatile/atomic representation clauses, protected action
   --  reentrancy, entry-family queues, requeue/select paths,
   --  abort/deferred-finalization, and controlled/finalized
   --  discriminant-dependent components.

   package Application renames Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Application_Legality;

   type Remaining_RM_Edge_Precision_Id is new Natural;
   No_Remaining_RM_Edge_Precision : constant Remaining_RM_Edge_Precision_Id := 0;

   type Remaining_RM_Edge_Kind is
     (Remaining_RM_Edge_Dispatching_Abstract_State_Effect,
      Remaining_RM_Edge_Renamed_Primitive,
      Remaining_RM_Edge_Inherited_Private_Extension_Primitive_Hiding,
      Remaining_RM_Edge_Access_Subprogram_Effect_Profile,
      Remaining_RM_Edge_Generic_Formal_Subprogram_Call,
      Remaining_RM_Edge_Universal_Numeric_Stateful_Expected_Context,
      Remaining_RM_Edge_Volatile_Atomic_Representation_Clause,
      Remaining_RM_Edge_Protected_Action_Reentrancy,
      Remaining_RM_Edge_Entry_Family_Queue,
      Remaining_RM_Edge_Requeue_Select_Path,
      Remaining_RM_Edge_Abort_Deferred_Finalization,
      Remaining_RM_Edge_Controlled_Finalized_Discriminant_Component,
      Remaining_RM_Edge_Unknown);

   type Remaining_RM_Edge_Blocker_Family is
     (Remaining_RM_Edge_Blocker_None,
      Remaining_RM_Edge_Blocker_RM_Completion_Consumer_Application,
      Remaining_RM_Edge_Blocker_Dispatching_Abstract_State,
      Remaining_RM_Edge_Blocker_Renamed_Primitive,
      Remaining_RM_Edge_Blocker_Inherited_Primitive_Hiding,
      Remaining_RM_Edge_Blocker_Access_Profile,
      Remaining_RM_Edge_Blocker_Generic_Formal_Subprogram,
      Remaining_RM_Edge_Blocker_Universal_Numeric_State,
      Remaining_RM_Edge_Blocker_Volatile_Atomic_Representation,
      Remaining_RM_Edge_Blocker_Protected_Reentrancy,
      Remaining_RM_Edge_Blocker_Entry_Family_Queue,
      Remaining_RM_Edge_Blocker_Requeue_Select,
      Remaining_RM_Edge_Blocker_Abort_Finalization,
      Remaining_RM_Edge_Blocker_Controlled_Discriminant,
      Remaining_RM_Edge_Blocker_Source_Fingerprint,
      Remaining_RM_Edge_Blocker_Substitution_Fingerprint,
      Remaining_RM_Edge_Blocker_Multiple,
      Remaining_RM_Edge_Blocker_Indeterminate);

   type Remaining_RM_Edge_Status is
     (Remaining_RM_Edge_Not_Checked,
      Remaining_RM_Edge_Legal_Dispatching_Abstract_State_Effect,
      Remaining_RM_Edge_Legal_Renamed_Primitive,
      Remaining_RM_Edge_Legal_Inherited_Private_Extension_Primitive_Hiding,
      Remaining_RM_Edge_Legal_Access_Subprogram_Effect_Profile,
      Remaining_RM_Edge_Legal_Generic_Formal_Subprogram_Call,
      Remaining_RM_Edge_Legal_Universal_Numeric_Stateful_Expected_Context,
      Remaining_RM_Edge_Legal_Volatile_Atomic_Representation_Clause,
      Remaining_RM_Edge_Legal_Protected_Action_Reentrancy,
      Remaining_RM_Edge_Legal_Entry_Family_Queue,
      Remaining_RM_Edge_Legal_Requeue_Select_Path,
      Remaining_RM_Edge_Legal_Abort_Deferred_Finalization,
      Remaining_RM_Edge_Legal_Controlled_Finalized_Discriminant_Component,
      Remaining_RM_Edge_Missing_Application_Row,
      Remaining_RM_Edge_Application_Blocker,
      Remaining_RM_Edge_Dispatching_Abstract_State_Mismatch,
      Remaining_RM_Edge_Renamed_Primitive_Visibility_Mismatch,
      Remaining_RM_Edge_Inherited_Primitive_Hiding_Mismatch,
      Remaining_RM_Edge_Access_Profile_Effect_Mismatch,
      Remaining_RM_Edge_Generic_Formal_Subprogram_Mismatch,
      Remaining_RM_Edge_Universal_Numeric_State_Ambiguous,
      Remaining_RM_Edge_Volatile_Atomic_Representation_Mismatch,
      Remaining_RM_Edge_Protected_Reentrancy_Mismatch,
      Remaining_RM_Edge_Entry_Family_Queue_Mismatch,
      Remaining_RM_Edge_Requeue_Select_Mismatch,
      Remaining_RM_Edge_Abort_Finalization_Mismatch,
      Remaining_RM_Edge_Controlled_Discriminant_Mismatch,
      Remaining_RM_Edge_Source_Fingerprint_Mismatch,
      Remaining_RM_Edge_Substitution_Fingerprint_Mismatch,
      Remaining_RM_Edge_Multiple_Blockers,
      Remaining_RM_Edge_Indeterminate);

   type Remaining_RM_Edge_Context is record
      Id                                      : Remaining_RM_Edge_Precision_Id := No_Remaining_RM_Edge_Precision;
      Kind                                    : Remaining_RM_Edge_Kind := Remaining_RM_Edge_Unknown;
      Node                                    : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                               : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name                          : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                               : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                              : Ada.Strings.Unbounded.Unbounded_String;
      Application_Row                         : Application.RM_Closure_Consumer_Application_Id := Application.No_RM_Closure_Consumer_Application;
      Application_Status                      : Application.RM_Closure_Consumer_Application_Status := Application.RM_Closure_Consumer_Application_Not_Checked;
      Requires_Application                    : Boolean := True;
      Dispatching_Abstract_State_Mismatch     : Boolean := False;
      Renamed_Primitive_Visibility_Mismatch   : Boolean := False;
      Inherited_Primitive_Hiding_Mismatch     : Boolean := False;
      Access_Profile_Effect_Mismatch          : Boolean := False;
      Generic_Formal_Subprogram_Mismatch      : Boolean := False;
      Universal_Numeric_State_Ambiguous        : Boolean := False;
      Volatile_Atomic_Representation_Mismatch : Boolean := False;
      Protected_Reentrancy_Mismatch           : Boolean := False;
      Entry_Family_Queue_Mismatch             : Boolean := False;
      Requeue_Select_Mismatch                 : Boolean := False;
      Abort_Finalization_Mismatch             : Boolean := False;
      Controlled_Discriminant_Mismatch        : Boolean := False;
      Source_Fingerprint                      : Natural := 0;
      Expected_Source_Fingerprint             : Natural := 0;
      Substitution_Fingerprint                : Natural := 0;
      Expected_Substitution_Fingerprint       : Natural := 0;
      Start_Line                              : Positive := 1;
      Start_Column                            : Positive := 1;
      End_Line                                : Positive := 1;
      End_Column                              : Positive := 1;
   end record;

   type Remaining_RM_Edge_Row is record
      Id                       : Remaining_RM_Edge_Precision_Id := No_Remaining_RM_Edge_Precision;
      Context                  : Remaining_RM_Edge_Precision_Id := No_Remaining_RM_Edge_Precision;
      Kind                     : Remaining_RM_Edge_Kind := Remaining_RM_Edge_Unknown;
      Status                   : Remaining_RM_Edge_Status := Remaining_RM_Edge_Not_Checked;
      Blocker_Family           : Remaining_RM_Edge_Blocker_Family := Remaining_RM_Edge_Blocker_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                : Ada.Strings.Unbounded.Unbounded_String;
      State_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Application_Row          : Application.RM_Closure_Consumer_Application_Id := Application.No_RM_Closure_Consumer_Application;
      Application_Status       : Application.RM_Closure_Consumer_Application_Status := Application.RM_Closure_Consumer_Application_Not_Checked;
      Accepted                 : Boolean := False;
      Blocked                  : Boolean := False;
      Blocks_Downstream        : Boolean := False;
      Blocker_Count            : Natural := 0;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Row_Fingerprint          : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Remaining_RM_Edge_Context_Model is private;
   type Remaining_RM_Edge_Model is private;
   type Remaining_RM_Edge_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Context_Model);
   procedure Add_Context
     (Model   : in out Remaining_RM_Edge_Context_Model;
      Context : Remaining_RM_Edge_Context);

   function Build (Contexts : Remaining_RM_Edge_Context_Model) return Remaining_RM_Edge_Model;
   function Count (Model : Remaining_RM_Edge_Model) return Natural;
   function Row_Count (Model : Remaining_RM_Edge_Model) return Natural renames Count;
   function Row_At
     (Model : Remaining_RM_Edge_Model;
      Index : Positive) return Remaining_RM_Edge_Row;

   function Query_Count (Set : Remaining_RM_Edge_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Set;
      Index : Positive) return Remaining_RM_Edge_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Model;
      Status : Remaining_RM_Edge_Status) return Remaining_RM_Edge_Set;
   function Query_Blocker_Family
     (Model  : Remaining_RM_Edge_Model;
      Family : Remaining_RM_Edge_Blocker_Family) return Remaining_RM_Edge_Set;
   function Find_By_Node
     (Model : Remaining_RM_Edge_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Set;
   function Find_By_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Set;

   function Count_By_Status
     (Model  : Remaining_RM_Edge_Model;
      Status : Remaining_RM_Edge_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Remaining_RM_Edge_Model;
      Family : Remaining_RM_Edge_Blocker_Family) return Natural;
   function Accepted_Count (Model : Remaining_RM_Edge_Model) return Natural;
   function Blocked_Count (Model : Remaining_RM_Edge_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Row);

   type Remaining_RM_Edge_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Remaining_RM_Edge_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Remaining_RM_Edge_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Remaining_RM_Edge_Precision_Legality;
