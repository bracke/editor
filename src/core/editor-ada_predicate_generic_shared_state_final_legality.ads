with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
with Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
with Editor.Ada_Dispatching_Global_Refinement_Legality;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Predicate_Invariant_Propagation_Legality;
with Editor.Ada_Predicate_Invariant_Use_Site_Legality;
with Editor.Ada_Renaming_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

package Editor.Ada_Predicate_Generic_Shared_State_Final_Legality is

   --  Case 1237 predicate/invariant generic shared-state final legality.
   --
   --  This package connects subtype predicates and type invariants with the
   --  generic/shared-state final semantic chain.  Predicate and invariant
   --  conclusions for assignments, returns, conversions, aggregates, call
   --  actuals/results, generic actuals, derived/private views, dispatching
   --  calls, renamed objects/primitives, controlled finalization paths, and
   --  discriminant-dependent objects are accepted only when use-site,
   --  propagation, generic replay, shared-state, representation, tasking,
   --  accessibility, dispatching, exception/finalization, renaming, and
   --  cross-unit evidence agree.  Missing or blocked prerequisites remain
   --  first-class blocker families.

   package PIU renames Editor.Ada_Predicate_Invariant_Use_Site_Legality;
   package PIP renames Editor.Ada_Predicate_Invariant_Propagation_Legality;
   package Cross_Generic renames Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Overload_Generic renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Tasking_Generic renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
   package Access_Generic renames Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
   package Disc_Generic renames Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
   package Exception_Generic renames Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
   package Renaming_Generic renames Editor.Ada_Renaming_Generic_Shared_State_Final_Legality;
   package Dispatching_Global renames Editor.Ada_Dispatching_Global_Refinement_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Predicate_Generic_Final_Row_Id is new Natural;
   No_Predicate_Generic_Final_Row : constant Predicate_Generic_Final_Row_Id := 0;

   type Predicate_Generic_Final_Kind is
     (Predicate_Generic_Final_Assignment,
      Predicate_Generic_Final_Object_Initialization,
      Predicate_Generic_Final_Return,
      Predicate_Generic_Final_Conversion,
      Predicate_Generic_Final_Aggregate,
      Predicate_Generic_Final_Call_Actual,
      Predicate_Generic_Final_Call_Result,
      Predicate_Generic_Final_Generic_Actual,
      Predicate_Generic_Final_Derived_Type,
      Predicate_Generic_Final_Private_View,
      Predicate_Generic_Final_Dispatching_Call,
      Predicate_Generic_Final_Renamed_Object,
      Predicate_Generic_Final_Controlled_Finalization,
      Predicate_Generic_Final_Discriminant_Dependent_Object,
      Predicate_Generic_Final_Cross_Unit_State,
      Predicate_Generic_Final_Unknown);

   type Predicate_Generic_Final_Blocker_Family is
     (Predicate_Generic_Final_Blocker_None,
      Predicate_Generic_Final_Blocker_Predicate_Use_Site,
      Predicate_Generic_Final_Blocker_Predicate_Propagation,
      Predicate_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State,
      Predicate_Generic_Final_Blocker_Generic_Abstract_Replay,
      Predicate_Generic_Final_Blocker_Overload_Generic_Shared_State,
      Predicate_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Predicate_Generic_Final_Blocker_Tasking_Generic_Shared_State,
      Predicate_Generic_Final_Blocker_Accessibility_Generic_Shared_State,
      Predicate_Generic_Final_Blocker_Discriminant_Generic_Shared_State,
      Predicate_Generic_Final_Blocker_Exception_Finalization_Generic_Shared_State,
      Predicate_Generic_Final_Blocker_Renaming_Generic_Shared_State,
      Predicate_Generic_Final_Blocker_Dispatching_Global_Refinement,
      Predicate_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Predicate_Generic_Final_Blocker_Static_Predicate,
      Predicate_Generic_Final_Blocker_Dynamic_Predicate_Check,
      Predicate_Generic_Final_Blocker_Invariant,
      Predicate_Generic_Final_Blocker_Private_View,
      Predicate_Generic_Final_Blocker_Derived_Invariant,
      Predicate_Generic_Final_Blocker_Generic_Substitution,
      Predicate_Generic_Final_Blocker_Discriminant_Predicate,
      Predicate_Generic_Final_Blocker_Controlled_Finalization,
      Predicate_Generic_Final_Blocker_Renamed_Predicate_Source,
      Predicate_Generic_Final_Blocker_Dispatching_Effect,
      Predicate_Generic_Final_Blocker_Source_Fingerprint,
      Predicate_Generic_Final_Blocker_Substitution_Fingerprint,
      Predicate_Generic_Final_Blocker_Multiple,
      Predicate_Generic_Final_Blocker_Indeterminate);

   type Predicate_Generic_Final_Status is
     (Predicate_Generic_Final_Not_Checked,
      Predicate_Generic_Final_Legal_Assignment_Accepted,
      Predicate_Generic_Final_Legal_Object_Initialization_Accepted,
      Predicate_Generic_Final_Legal_Return_Accepted,
      Predicate_Generic_Final_Legal_Conversion_Accepted,
      Predicate_Generic_Final_Legal_Aggregate_Accepted,
      Predicate_Generic_Final_Legal_Call_Actual_Accepted,
      Predicate_Generic_Final_Legal_Call_Result_Accepted,
      Predicate_Generic_Final_Legal_Generic_Actual_Accepted,
      Predicate_Generic_Final_Legal_Derived_Type_Accepted,
      Predicate_Generic_Final_Legal_Private_View_Accepted,
      Predicate_Generic_Final_Legal_Dispatching_Call_Accepted,
      Predicate_Generic_Final_Legal_Renamed_Object_Accepted,
      Predicate_Generic_Final_Legal_Controlled_Finalization_Accepted,
      Predicate_Generic_Final_Legal_Discriminant_Dependent_Object_Accepted,
      Predicate_Generic_Final_Legal_Cross_Unit_State_Accepted,
      Predicate_Generic_Final_Missing_Predicate_Use_Row,
      Predicate_Generic_Final_Predicate_Use_Blocker,
      Predicate_Generic_Final_Missing_Predicate_Propagation_Row,
      Predicate_Generic_Final_Predicate_Propagation_Blocker,
      Predicate_Generic_Final_Missing_Cross_Unit_Generic_Row,
      Predicate_Generic_Final_Cross_Unit_Generic_Blocker,
      Predicate_Generic_Final_Missing_Generic_Replay_Row,
      Predicate_Generic_Final_Generic_Replay_Blocker,
      Predicate_Generic_Final_Missing_Overload_Generic_Row,
      Predicate_Generic_Final_Overload_Generic_Blocker,
      Predicate_Generic_Final_Missing_Representation_Generic_Row,
      Predicate_Generic_Final_Representation_Generic_Blocker,
      Predicate_Generic_Final_Missing_Tasking_Generic_Row,
      Predicate_Generic_Final_Tasking_Generic_Blocker,
      Predicate_Generic_Final_Missing_Accessibility_Generic_Row,
      Predicate_Generic_Final_Accessibility_Generic_Blocker,
      Predicate_Generic_Final_Missing_Discriminant_Generic_Row,
      Predicate_Generic_Final_Discriminant_Generic_Blocker,
      Predicate_Generic_Final_Missing_Exception_Generic_Row,
      Predicate_Generic_Final_Exception_Generic_Blocker,
      Predicate_Generic_Final_Missing_Renaming_Generic_Row,
      Predicate_Generic_Final_Renaming_Generic_Blocker,
      Predicate_Generic_Final_Missing_Dispatching_Global_Row,
      Predicate_Generic_Final_Dispatching_Global_Blocker,
      Predicate_Generic_Final_Missing_Stabilized_Closure_Row,
      Predicate_Generic_Final_Stabilized_Closure_Blocker,
      Predicate_Generic_Final_Static_Predicate_Blocker,
      Predicate_Generic_Final_Dynamic_Predicate_Check_Blocker,
      Predicate_Generic_Final_Invariant_Blocker,
      Predicate_Generic_Final_Private_View_Blocker,
      Predicate_Generic_Final_Derived_Invariant_Blocker,
      Predicate_Generic_Final_Generic_Substitution_Blocker,
      Predicate_Generic_Final_Discriminant_Predicate_Blocker,
      Predicate_Generic_Final_Controlled_Finalization_Blocker,
      Predicate_Generic_Final_Renamed_Predicate_Source_Blocker,
      Predicate_Generic_Final_Dispatching_Effect_Blocker,
      Predicate_Generic_Final_Source_Fingerprint_Mismatch,
      Predicate_Generic_Final_Substitution_Fingerprint_Mismatch,
      Predicate_Generic_Final_Multiple_Blockers,
      Predicate_Generic_Final_Indeterminate);

   type Predicate_Generic_Final_Context is record
      Id                         : Predicate_Generic_Final_Row_Id := No_Predicate_Generic_Final_Row;
      Kind                       : Predicate_Generic_Final_Kind := Predicate_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Predicate_Use_Row          : PIU.Predicate_Use_Legality_Id := PIU.No_Predicate_Use_Legality;
      Predicate_Use_Status       : PIU.Predicate_Use_Legality_Status := PIU.Predicate_Use_Legality_Not_Checked;
      Propagation_Row            : PIP.Propagation_Row_Id := PIP.No_Propagation_Row;
      Propagation_Status         : PIP.Propagation_Status := PIP.Propagation_Not_Checked;
      Cross_Generic_Row          : Cross_Generic.Cross_Unit_Generic_Final_Row_Id := Cross_Generic.No_Cross_Unit_Generic_Final_Row;
      Cross_Generic_Status       : Cross_Generic.Cross_Unit_Generic_Final_Status := Cross_Generic.Cross_Unit_Generic_Final_Not_Checked;
      Generic_Replay_Row         : Generic_Replay.Generic_Abstract_Replay_Row_Id := Generic_Replay.No_Generic_Abstract_Replay_Row;
      Generic_Replay_Status      : Generic_Replay.Generic_Abstract_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Not_Checked;
      Overload_Generic_Row       : Overload_Generic.Overload_Generic_Final_Row_Id := Overload_Generic.No_Overload_Generic_Final_Row;
      Overload_Generic_Status    : Overload_Generic.Overload_Generic_Final_Status := Overload_Generic.Overload_Generic_Final_Not_Checked;
      Representation_Generic_Row : Rep_Generic.Representation_Generic_Final_Row_Id := Rep_Generic.No_Representation_Generic_Final_Row;
      Representation_Generic_Status : Rep_Generic.Representation_Generic_Final_Status := Rep_Generic.Representation_Generic_Final_Not_Checked;
      Tasking_Generic_Row        : Tasking_Generic.Tasking_Generic_Final_Row_Id := Tasking_Generic.No_Tasking_Generic_Final_Row;
      Tasking_Generic_Status     : Tasking_Generic.Tasking_Generic_Final_Status := Tasking_Generic.Tasking_Generic_Final_Not_Checked;
      Accessibility_Generic_Row  : Access_Generic.Accessibility_Generic_Final_Row_Id := Access_Generic.No_Accessibility_Generic_Final_Row;
      Accessibility_Generic_Status : Access_Generic.Accessibility_Generic_Final_Status := Access_Generic.Accessibility_Generic_Final_Not_Checked;
      Discriminant_Generic_Row   : Disc_Generic.Discriminant_Generic_Final_Row_Id := Disc_Generic.No_Discriminant_Generic_Final_Row;
      Discriminant_Generic_Status : Disc_Generic.Discriminant_Generic_Final_Status := Disc_Generic.Discriminant_Generic_Final_Not_Checked;
      Exception_Generic_Row      : Exception_Generic.Exception_Generic_Final_Row_Id := Exception_Generic.No_Exception_Generic_Final_Row;
      Exception_Generic_Status   : Exception_Generic.Exception_Generic_Final_Status := Exception_Generic.Exception_Generic_Final_Not_Checked;
      Renaming_Generic_Row       : Renaming_Generic.Renaming_Generic_Final_Row_Id := Renaming_Generic.No_Renaming_Generic_Final_Row;
      Renaming_Generic_Status    : Renaming_Generic.Renaming_Generic_Final_Status := Renaming_Generic.Renaming_Generic_Final_Not_Checked;
      Dispatching_Global_Row     : Dispatching_Global.Dispatching_Global_Row_Id := Dispatching_Global.No_Dispatching_Global_Row;
      Dispatching_Global_Status  : Dispatching_Global.Dispatching_Global_Status := Dispatching_Global.Dispatching_Global_Not_Checked;
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Propagation       : Boolean := True;
      Requires_Cross_Generic     : Boolean := True;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Overload_Generic  : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Tasking_Generic   : Boolean := False;
      Requires_Accessibility_Generic : Boolean := False;
      Requires_Discriminant_Generic : Boolean := False;
      Requires_Exception_Generic : Boolean := False;
      Requires_Renaming_Generic  : Boolean := False;
      Requires_Dispatching_Global : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Static_Predicate_Blocker   : Boolean := False;
      Dynamic_Predicate_Check_Blocker : Boolean := False;
      Invariant_Blocker          : Boolean := False;
      Private_View_Blocker       : Boolean := False;
      Derived_Invariant_Blocker  : Boolean := False;
      Generic_Substitution_Blocker : Boolean := False;
      Discriminant_Predicate_Blocker : Boolean := False;
      Controlled_Finalization_Blocker : Boolean := False;
      Renamed_Predicate_Source_Blocker : Boolean := False;
      Dispatching_Effect_Blocker : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Predicate_Generic_Final_Row is record
      Id                         : Predicate_Generic_Final_Row_Id := No_Predicate_Generic_Final_Row;
      Context                    : Predicate_Generic_Final_Row_Id := No_Predicate_Generic_Final_Row;
      Kind                       : Predicate_Generic_Final_Kind := Predicate_Generic_Final_Unknown;
      Status                     : Predicate_Generic_Final_Status := Predicate_Generic_Final_Not_Checked;
      Blocker_Family             : Predicate_Generic_Final_Blocker_Family := Predicate_Generic_Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Fingerprint                : Natural := 0;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Predicate_Generic_Final_Context_Model is private;
   type Predicate_Generic_Final_Model is private;
   type Predicate_Generic_Final_Set is private;

   procedure Clear (Model : in out Predicate_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Predicate_Generic_Final_Context_Model; Info : Predicate_Generic_Final_Context);
   function Context_Count (Model : Predicate_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Predicate_Generic_Final_Context_Model) return Predicate_Generic_Final_Model;
   function Count (Model : Predicate_Generic_Final_Model) return Natural;
   function Row_At (Model : Predicate_Generic_Final_Model; Index : Positive) return Predicate_Generic_Final_Row;
   function Accepted_Count (Model : Predicate_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Predicate_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Predicate_Generic_Final_Model) return Natural;
   function Count_By_Status (Model : Predicate_Generic_Final_Model; Status : Predicate_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Predicate_Generic_Final_Model; Family : Predicate_Generic_Final_Blocker_Family) return Natural;
   function Find_By_Node (Model : Predicate_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Predicate_Generic_Final_Set;
   function Find_By_Source_Fingerprint (Model : Predicate_Generic_Final_Model; Fingerprint : Natural) return Predicate_Generic_Final_Set;
   function Query_Blocker_Family (Model : Predicate_Generic_Final_Model; Family : Predicate_Generic_Final_Blocker_Family) return Predicate_Generic_Final_Set;
   function Query_Count (Set : Predicate_Generic_Final_Set) return Natural;
   function Query_Row_At (Set : Predicate_Generic_Final_Set; Index : Positive) return Predicate_Generic_Final_Row;
   function Stable_Fingerprint (Model : Predicate_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Predicate_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Predicate_Generic_Final_Status) return Boolean;
   function Blocks_Downstream (Status : Predicate_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Predicate_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Predicate_Generic_Final_Row);

   type Predicate_Generic_Final_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Predicate_Generic_Final_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Predicate_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
