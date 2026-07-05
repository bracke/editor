with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

package Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality is

   --  Case 1254 predicate/invariant legality over the completed
   --  generic/shared-state RM chain.
   --
   --  This package consumes the prior predicate/invariant generic/shared-state
   --  final evidence together with completed cross-unit RM closure,
   --  elaboration, accessibility/lifetime, exception/finalization,
   --  dataflow, overload/type, representation/freezing, tasking/protected,
   --  and coverage-proven AST repair evidence.  Predicate and invariant
   --  conclusions become accepted only when completed RM evidence agrees and
   --  source/substitution fingerprints still match.

   package Prior_Predicate renames Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
   package Cross_RM renames Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
   package Elaboration_RM renames Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
   package Accessibility_RM renames Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
   package Exception_RM renames Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
   package Dataflow_Final renames Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
   package Overload_RM renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Representation_RM renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Tasking_RM renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package AST_Repair renames Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;

   type Predicate_RM_Completion_Row_Id is new Natural;
   No_Predicate_RM_Completion_Row : constant Predicate_RM_Completion_Row_Id := 0;

   type Predicate_RM_Completion_Kind is
     (Predicate_RM_Completion_Assignment,
      Predicate_RM_Completion_Object_Initialization,
      Predicate_RM_Completion_Return,
      Predicate_RM_Completion_Conversion,
      Predicate_RM_Completion_Aggregate,
      Predicate_RM_Completion_Call_Actual,
      Predicate_RM_Completion_Call_Result,
      Predicate_RM_Completion_Generic_Actual,
      Predicate_RM_Completion_Derived_Type,
      Predicate_RM_Completion_Private_View,
      Predicate_RM_Completion_Dispatching_Call,
      Predicate_RM_Completion_Renamed_Object,
      Predicate_RM_Completion_Controlled_Finalization,
      Predicate_RM_Completion_Discriminant_Dependent_Object,
      Predicate_RM_Completion_Cross_Unit_State,
      Predicate_RM_Completion_Variant_Component,
      Predicate_RM_Completion_Access_Escape,
      Predicate_RM_Completion_Volatile_Atomic_State,
      Predicate_RM_Completion_Unknown);

   type Predicate_RM_Completion_Blocker_Family is
     (Predicate_RM_Completion_Blocker_None,
      Predicate_RM_Completion_Blocker_Prior_Predicate,
      Predicate_RM_Completion_Blocker_Cross_Unit_RM_Completion,
      Predicate_RM_Completion_Blocker_Elaboration_RM_Completion,
      Predicate_RM_Completion_Blocker_Accessibility_RM_Completion,
      Predicate_RM_Completion_Blocker_Exception_Finalization_RM_Completion,
      Predicate_RM_Completion_Blocker_Dataflow_Final,
      Predicate_RM_Completion_Blocker_Overload_RM_Completion,
      Predicate_RM_Completion_Blocker_Representation_RM_Completion,
      Predicate_RM_Completion_Blocker_Tasking_RM_Completion,
      Predicate_RM_Completion_Blocker_AST_Repair,
      Predicate_RM_Completion_Blocker_Static_Predicate,
      Predicate_RM_Completion_Blocker_Dynamic_Predicate_Check,
      Predicate_RM_Completion_Blocker_Invariant,
      Predicate_RM_Completion_Blocker_Private_View,
      Predicate_RM_Completion_Blocker_Derived_Invariant,
      Predicate_RM_Completion_Blocker_Generic_Substitution,
      Predicate_RM_Completion_Blocker_Discriminant_Predicate,
      Predicate_RM_Completion_Blocker_Controlled_Finalization,
      Predicate_RM_Completion_Blocker_Renamed_Predicate_Source,
      Predicate_RM_Completion_Blocker_Dispatching_Effect,
      Predicate_RM_Completion_Blocker_Variant_Component,
      Predicate_RM_Completion_Blocker_Access_Escape,
      Predicate_RM_Completion_Blocker_Volatile_Atomic_Effect,
      Predicate_RM_Completion_Blocker_View_Barrier,
      Predicate_RM_Completion_Blocker_Source_Fingerprint,
      Predicate_RM_Completion_Blocker_Substitution_Fingerprint,
      Predicate_RM_Completion_Blocker_Multiple,
      Predicate_RM_Completion_Blocker_Indeterminate);

   type Predicate_RM_Completion_Status is
     (Predicate_RM_Completion_Not_Checked,
      Predicate_RM_Completion_Legal_Assignment_Accepted,
      Predicate_RM_Completion_Legal_Object_Initialization_Accepted,
      Predicate_RM_Completion_Legal_Return_Accepted,
      Predicate_RM_Completion_Legal_Conversion_Accepted,
      Predicate_RM_Completion_Legal_Aggregate_Accepted,
      Predicate_RM_Completion_Legal_Call_Actual_Accepted,
      Predicate_RM_Completion_Legal_Call_Result_Accepted,
      Predicate_RM_Completion_Legal_Generic_Actual_Accepted,
      Predicate_RM_Completion_Legal_Derived_Type_Accepted,
      Predicate_RM_Completion_Legal_Private_View_Accepted,
      Predicate_RM_Completion_Legal_Dispatching_Call_Accepted,
      Predicate_RM_Completion_Legal_Renamed_Object_Accepted,
      Predicate_RM_Completion_Legal_Controlled_Finalization_Accepted,
      Predicate_RM_Completion_Legal_Discriminant_Dependent_Object_Accepted,
      Predicate_RM_Completion_Legal_Cross_Unit_State_Accepted,
      Predicate_RM_Completion_Legal_Variant_Component_Accepted,
      Predicate_RM_Completion_Legal_Access_Escape_Accepted,
      Predicate_RM_Completion_Legal_Volatile_Atomic_State_Accepted,
      Predicate_RM_Completion_Missing_Prior_Predicate_Row,
      Predicate_RM_Completion_Prior_Predicate_Blocker,
      Predicate_RM_Completion_Missing_Cross_Unit_RM_Row,
      Predicate_RM_Completion_Cross_Unit_RM_Blocker,
      Predicate_RM_Completion_Missing_Elaboration_RM_Row,
      Predicate_RM_Completion_Elaboration_RM_Blocker,
      Predicate_RM_Completion_Missing_Accessibility_RM_Row,
      Predicate_RM_Completion_Accessibility_RM_Blocker,
      Predicate_RM_Completion_Missing_Exception_RM_Row,
      Predicate_RM_Completion_Exception_RM_Blocker,
      Predicate_RM_Completion_Missing_Dataflow_Row,
      Predicate_RM_Completion_Dataflow_Blocker,
      Predicate_RM_Completion_Missing_Overload_RM_Row,
      Predicate_RM_Completion_Overload_RM_Blocker,
      Predicate_RM_Completion_Missing_Representation_RM_Row,
      Predicate_RM_Completion_Representation_RM_Blocker,
      Predicate_RM_Completion_Missing_Tasking_RM_Row,
      Predicate_RM_Completion_Tasking_RM_Blocker,
      Predicate_RM_Completion_Missing_AST_Repair_Row,
      Predicate_RM_Completion_AST_Repair_Blocker,
      Predicate_RM_Completion_Static_Predicate_Blocker,
      Predicate_RM_Completion_Dynamic_Predicate_Check_Blocker,
      Predicate_RM_Completion_Invariant_Blocker,
      Predicate_RM_Completion_Private_View_Blocker,
      Predicate_RM_Completion_Derived_Invariant_Blocker,
      Predicate_RM_Completion_Generic_Substitution_Blocker,
      Predicate_RM_Completion_Discriminant_Predicate_Blocker,
      Predicate_RM_Completion_Controlled_Finalization_Blocker,
      Predicate_RM_Completion_Renamed_Predicate_Source_Blocker,
      Predicate_RM_Completion_Dispatching_Effect_Blocker,
      Predicate_RM_Completion_Variant_Component_Blocker,
      Predicate_RM_Completion_Access_Escape_Blocker,
      Predicate_RM_Completion_Volatile_Atomic_Effect_Blocker,
      Predicate_RM_Completion_View_Barrier,
      Predicate_RM_Completion_Source_Fingerprint_Mismatch,
      Predicate_RM_Completion_Substitution_Fingerprint_Mismatch,
      Predicate_RM_Completion_Multiple_Blockers,
      Predicate_RM_Completion_Indeterminate);

   type Predicate_RM_Completion_Context is record
      Id                         : Predicate_RM_Completion_Row_Id := No_Predicate_RM_Completion_Row;
      Kind                       : Predicate_RM_Completion_Kind := Predicate_RM_Completion_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Prior_Predicate_Row        : Prior_Predicate.Predicate_Generic_Final_Row_Id := Prior_Predicate.No_Predicate_Generic_Final_Row;
      Prior_Predicate_Status     : Prior_Predicate.Predicate_Generic_Final_Status := Prior_Predicate.Predicate_Generic_Final_Not_Checked;
      Cross_RM_Row               : Cross_RM.Cross_Unit_RM_Completion_Closure_Id := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Cross_RM_Status            : Cross_RM.Cross_Unit_RM_Completion_Status := Cross_RM.Cross_Unit_RM_Completion_Not_Checked;
      Elaboration_RM_Row         : Elaboration_RM.Elaboration_RM_Completion_Row_Id := Elaboration_RM.No_Elaboration_RM_Completion_Row;
      Elaboration_RM_Status      : Elaboration_RM.Elaboration_RM_Completion_Status := Elaboration_RM.Elaboration_RM_Completion_Not_Checked;
      Accessibility_RM_Row       : Accessibility_RM.Accessibility_RM_Completion_Row_Id := Accessibility_RM.No_Accessibility_RM_Completion_Row;
      Accessibility_RM_Status    : Accessibility_RM.Accessibility_RM_Completion_Status := Accessibility_RM.Accessibility_RM_Completion_Not_Checked;
      Exception_RM_Row           : Exception_RM.Exception_RM_Completion_Row_Id := Exception_RM.No_Exception_RM_Completion_Row;
      Exception_RM_Status        : Exception_RM.Exception_RM_Completion_Status := Exception_RM.Exception_RM_Completion_Not_Checked;
      Dataflow_Row               : Dataflow_Final.Dataflow_Generic_Final_Row_Id := Dataflow_Final.No_Dataflow_Generic_Final_Row;
      Dataflow_Status            : Dataflow_Final.Dataflow_Generic_Final_Status := Dataflow_Final.Dataflow_Generic_Final_Not_Checked;
      Overload_RM_Row            : Overload_RM.Overload_Generic_RM_Edge_Completion_Id := Overload_RM.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Status         : Overload_RM.Overload_Generic_RM_Edge_Status := Overload_RM.Overload_Generic_RM_Edge_Not_Checked;
      Representation_RM_Row      : Representation_RM.Representation_Generic_RM_Hard_Case_Id := Representation_RM.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Status   : Representation_RM.Representation_Generic_RM_Hard_Case_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Not_Checked;
      Tasking_RM_Row             : Tasking_RM.Tasking_Generic_RM_Hard_Case_Id := Tasking_RM.No_Tasking_Generic_RM_Hard_Case;
      Tasking_RM_Status          : Tasking_RM.Tasking_Generic_RM_Hard_Case_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Not_Checked;
      AST_Repair_Row             : AST_Repair.Coverage_Proven_AST_Repair_Id := AST_Repair.No_Coverage_Proven_AST_Repair;
      AST_Repair_Status          : AST_Repair.Coverage_Proven_AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Not_Checked;
      Requires_Prior_Predicate   : Boolean := True;
      Requires_Cross_RM          : Boolean := True;
      Requires_Elaboration_RM    : Boolean := False;
      Requires_Accessibility_RM  : Boolean := False;
      Requires_Exception_RM      : Boolean := False;
      Requires_Dataflow          : Boolean := False;
      Requires_Overload_RM       : Boolean := False;
      Requires_Representation_RM : Boolean := False;
      Requires_Tasking_RM        : Boolean := False;
      Requires_AST_Repair        : Boolean := False;
      Static_Predicate_Error     : Boolean := False;
      Dynamic_Predicate_Check_Error : Boolean := False;
      Invariant_Error            : Boolean := False;
      Private_View_Error         : Boolean := False;
      Derived_Invariant_Error    : Boolean := False;
      Generic_Substitution_Error : Boolean := False;
      Discriminant_Predicate_Error : Boolean := False;
      Controlled_Finalization_Error : Boolean := False;
      Renamed_Predicate_Source_Error : Boolean := False;
      Dispatching_Effect_Error   : Boolean := False;
      Variant_Component_Error    : Boolean := False;
      Access_Escape_Error        : Boolean := False;
      Volatile_Atomic_Effect_Error : Boolean := False;
      View_Barrier               : Boolean := False;
      Explicit_Multiple_Blockers : Boolean := False;
      Explicit_Indeterminate     : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Predicate_RM_Completion_Row is record
      Id                         : Predicate_RM_Completion_Row_Id := No_Predicate_RM_Completion_Row;
      Kind                       : Predicate_RM_Completion_Kind := Predicate_RM_Completion_Unknown;
      Status                     : Predicate_RM_Completion_Status := Predicate_RM_Completion_Not_Checked;
      Blocker_Family             : Predicate_RM_Completion_Blocker_Family := Predicate_RM_Completion_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Fingerprint         : Natural := 0;
      Stable_Fingerprint         : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Predicate_RM_Completion_Context_Model is private;
   type Predicate_RM_Completion_Model is private;
   type Predicate_RM_Completion_Set is private;

   procedure Clear (Model : in out Predicate_RM_Completion_Context_Model);
   procedure Add_Context (Model : in out Predicate_RM_Completion_Context_Model; Info : Predicate_RM_Completion_Context);
   function Context_Count (Model : Predicate_RM_Completion_Context_Model) return Natural;
   function Context_At (Model : Predicate_RM_Completion_Context_Model; Index : Positive) return Predicate_RM_Completion_Context;
   function Context_Fingerprint (Model : Predicate_RM_Completion_Context_Model) return Natural;

   function Build (Contexts : Predicate_RM_Completion_Context_Model) return Predicate_RM_Completion_Model;
   function Count (Model : Predicate_RM_Completion_Model) return Natural;
   function Row_Count (Model : Predicate_RM_Completion_Model) return Natural renames Count;
   function Row_At (Model : Predicate_RM_Completion_Model; Index : Positive) return Predicate_RM_Completion_Row;
   function Query_Count (Set : Predicate_RM_Completion_Set) return Natural;
   function Query_At (Set : Predicate_RM_Completion_Set; Index : Positive) return Predicate_RM_Completion_Row;
   function Query_Status (Model : Predicate_RM_Completion_Model; Status : Predicate_RM_Completion_Status) return Predicate_RM_Completion_Set;
   function Query_Blocker_Family (Model : Predicate_RM_Completion_Model; Family : Predicate_RM_Completion_Blocker_Family) return Predicate_RM_Completion_Set;
   function Find_By_Node (Model : Predicate_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Predicate_RM_Completion_Set;
   function Find_By_Source_Fingerprint (Model : Predicate_RM_Completion_Model; Source_Fingerprint : Natural) return Predicate_RM_Completion_Set;
   function Count_By_Status (Model : Predicate_RM_Completion_Model; Status : Predicate_RM_Completion_Status) return Natural;
   function Count_By_Blocker_Family (Model : Predicate_RM_Completion_Model; Family : Predicate_RM_Completion_Blocker_Family) return Natural;
   function Accepted_Count (Model : Predicate_RM_Completion_Model) return Natural;
   function Blocked_Count (Model : Predicate_RM_Completion_Model) return Natural;
   function Indeterminate_Count (Model : Predicate_RM_Completion_Model) return Natural;
   function Stable_Fingerprint (Model : Predicate_RM_Completion_Model) return Natural;

   function Is_Accepted (Status : Predicate_RM_Completion_Status) return Boolean;
   function Is_Blocked (Status : Predicate_RM_Completion_Status) return Boolean;
   function Is_Indeterminate (Status : Predicate_RM_Completion_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Predicate_RM_Completion_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Predicate_RM_Completion_Row);

   type Predicate_RM_Completion_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Predicate_RM_Completion_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Predicate_RM_Completion_Set is record
      Rows : Row_Vectors.Vector;
   end record;
end Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality;
