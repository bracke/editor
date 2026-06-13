with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
with Editor.Ada_Renaming_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;

package Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality is

   --  Pass1251 elaboration legality over the completed generic/shared-state
   --  RM chain.
   --
   --  This package consumes the completed cross-unit RM closure together with
   --  prior elaboration/generic evidence, completed overload/type,
   --  representation/freezing, tasking/protected, coverage-proven AST repair,
   --  exception/finalization, renaming/alias, predicate/invariant, and dataflow
   --  evidence.  Elaboration conclusions for dispatching calls, default and
   --  aspect expressions, representation items, task activation/termination,
   --  generic instances, generic body replay, preelaboration, Pure,
   --  Remote_Types, Shared_Passive, exception paths, renamed sources,
   --  predicate checks, and dataflow edges are accepted only when all required
   --  completed RM evidence agrees and fingerprints still match.

   package Cross_RM renames Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
   package Prior_Elab renames Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
   package Overload_RM renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Representation_RM renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Tasking_RM renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package AST_Repair renames Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality;
   package Exception_Generic renames Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
   package Renaming_Generic renames Editor.Ada_Renaming_Generic_Shared_State_Final_Legality;
   package Predicate_Generic renames Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
   package Dataflow_Generic renames Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;

   type Elaboration_RM_Completion_Row_Id is new Natural;
   No_Elaboration_RM_Completion_Row : constant Elaboration_RM_Completion_Row_Id := 0;

   type Elaboration_RM_Completion_Kind is
     (Elaboration_RM_Completion_Dispatching_Call,
      Elaboration_RM_Completion_Default_Expression,
      Elaboration_RM_Completion_Aspect_Expression,
      Elaboration_RM_Completion_Representation_Item,
      Elaboration_RM_Completion_Task_Activation,
      Elaboration_RM_Completion_Task_Termination,
      Elaboration_RM_Completion_Generic_Instance,
      Elaboration_RM_Completion_Generic_Body_Replay,
      Elaboration_RM_Completion_Preelaboration_Policy,
      Elaboration_RM_Completion_Pure_Policy,
      Elaboration_RM_Completion_Remote_Types_Policy,
      Elaboration_RM_Completion_Shared_Passive_Policy,
      Elaboration_RM_Completion_Cross_Unit_Body,
      Elaboration_RM_Completion_Exception_Finalization,
      Elaboration_RM_Completion_Renamed_Elaboration_Source,
      Elaboration_RM_Completion_Predicate_Check,
      Elaboration_RM_Completion_Dataflow_Edge,
      Elaboration_RM_Completion_Unknown);

   type Elaboration_RM_Completion_Blocker_Family is
     (Elaboration_RM_Completion_Blocker_None,
      Elaboration_RM_Completion_Blocker_Cross_Unit_RM_Completion,
      Elaboration_RM_Completion_Blocker_Prior_Elaboration,
      Elaboration_RM_Completion_Blocker_Overload_RM_Completion,
      Elaboration_RM_Completion_Blocker_Representation_RM_Completion,
      Elaboration_RM_Completion_Blocker_Tasking_RM_Completion,
      Elaboration_RM_Completion_Blocker_AST_Repair,
      Elaboration_RM_Completion_Blocker_Exception_Finalization,
      Elaboration_RM_Completion_Blocker_Renaming_Alias,
      Elaboration_RM_Completion_Blocker_Predicate_Invariant,
      Elaboration_RM_Completion_Blocker_Dataflow_Initialization,
      Elaboration_RM_Completion_Blocker_Elaboration_Order,
      Elaboration_RM_Completion_Blocker_Preelaboration_Policy,
      Elaboration_RM_Completion_Blocker_Pure_Policy,
      Elaboration_RM_Completion_Blocker_Remote_Types_Policy,
      Elaboration_RM_Completion_Blocker_Shared_Passive_Policy,
      Elaboration_RM_Completion_Blocker_Generic_Body,
      Elaboration_RM_Completion_Blocker_View_Barrier,
      Elaboration_RM_Completion_Blocker_Source_Fingerprint,
      Elaboration_RM_Completion_Blocker_Substitution_Fingerprint,
      Elaboration_RM_Completion_Blocker_Multiple,
      Elaboration_RM_Completion_Blocker_Indeterminate);

   type Elaboration_RM_Completion_Status is
     (Elaboration_RM_Completion_Not_Checked,
      Elaboration_RM_Completion_Legal_Dispatching_Call_Accepted,
      Elaboration_RM_Completion_Legal_Default_Expression_Accepted,
      Elaboration_RM_Completion_Legal_Aspect_Expression_Accepted,
      Elaboration_RM_Completion_Legal_Representation_Item_Accepted,
      Elaboration_RM_Completion_Legal_Task_Activation_Accepted,
      Elaboration_RM_Completion_Legal_Task_Termination_Accepted,
      Elaboration_RM_Completion_Legal_Generic_Instance_Accepted,
      Elaboration_RM_Completion_Legal_Generic_Body_Replay_Accepted,
      Elaboration_RM_Completion_Legal_Preelaboration_Policy_Accepted,
      Elaboration_RM_Completion_Legal_Pure_Policy_Accepted,
      Elaboration_RM_Completion_Legal_Remote_Types_Policy_Accepted,
      Elaboration_RM_Completion_Legal_Shared_Passive_Policy_Accepted,
      Elaboration_RM_Completion_Legal_Cross_Unit_Body_Accepted,
      Elaboration_RM_Completion_Legal_Exception_Finalization_Accepted,
      Elaboration_RM_Completion_Legal_Renamed_Source_Accepted,
      Elaboration_RM_Completion_Legal_Predicate_Check_Accepted,
      Elaboration_RM_Completion_Legal_Dataflow_Edge_Accepted,
      Elaboration_RM_Completion_Missing_Cross_Unit_RM_Row,
      Elaboration_RM_Completion_Cross_Unit_RM_Blocker,
      Elaboration_RM_Completion_Missing_Prior_Elaboration_Row,
      Elaboration_RM_Completion_Prior_Elaboration_Blocker,
      Elaboration_RM_Completion_Missing_Overload_RM_Row,
      Elaboration_RM_Completion_Overload_RM_Blocker,
      Elaboration_RM_Completion_Missing_Representation_RM_Row,
      Elaboration_RM_Completion_Representation_RM_Blocker,
      Elaboration_RM_Completion_Missing_Tasking_RM_Row,
      Elaboration_RM_Completion_Tasking_RM_Blocker,
      Elaboration_RM_Completion_Missing_AST_Repair_Row,
      Elaboration_RM_Completion_AST_Repair_Blocker,
      Elaboration_RM_Completion_Missing_Exception_Generic_Row,
      Elaboration_RM_Completion_Exception_Generic_Blocker,
      Elaboration_RM_Completion_Missing_Renaming_Generic_Row,
      Elaboration_RM_Completion_Renaming_Generic_Blocker,
      Elaboration_RM_Completion_Missing_Predicate_Generic_Row,
      Elaboration_RM_Completion_Predicate_Generic_Blocker,
      Elaboration_RM_Completion_Missing_Dataflow_Generic_Row,
      Elaboration_RM_Completion_Dataflow_Generic_Blocker,
      Elaboration_RM_Completion_Elaboration_Order_Blocker,
      Elaboration_RM_Completion_Preelaboration_Policy_Blocker,
      Elaboration_RM_Completion_Pure_Policy_Blocker,
      Elaboration_RM_Completion_Remote_Types_Policy_Blocker,
      Elaboration_RM_Completion_Shared_Passive_Policy_Blocker,
      Elaboration_RM_Completion_Generic_Body_Unavailable,
      Elaboration_RM_Completion_View_Barrier,
      Elaboration_RM_Completion_Source_Fingerprint_Mismatch,
      Elaboration_RM_Completion_Substitution_Fingerprint_Mismatch,
      Elaboration_RM_Completion_Multiple_Blockers,
      Elaboration_RM_Completion_Indeterminate);

   type Elaboration_RM_Completion_Context is record
      Id                         : Elaboration_RM_Completion_Row_Id := No_Elaboration_RM_Completion_Row;
      Kind                       : Elaboration_RM_Completion_Kind := Elaboration_RM_Completion_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Cross_RM_Row               : Cross_RM.Cross_Unit_RM_Completion_Closure_Id := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Cross_RM_Status            : Cross_RM.Cross_Unit_RM_Completion_Status := Cross_RM.Cross_Unit_RM_Completion_Not_Checked;
      Prior_Elaboration_Row      : Prior_Elab.Elaboration_Generic_Final_Row_Id := Prior_Elab.No_Elaboration_Generic_Final_Row;
      Prior_Elaboration_Status   : Prior_Elab.Elaboration_Generic_Final_Status := Prior_Elab.Elaboration_Generic_Final_Not_Checked;
      Overload_RM_Row            : Overload_RM.Overload_Generic_RM_Edge_Completion_Id := Overload_RM.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Status         : Overload_RM.Overload_Generic_RM_Edge_Status := Overload_RM.Overload_Generic_RM_Edge_Not_Checked;
      Representation_RM_Row      : Representation_RM.Representation_Generic_RM_Hard_Case_Id := Representation_RM.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Status   : Representation_RM.Representation_Generic_RM_Hard_Case_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Not_Checked;
      Tasking_RM_Row             : Tasking_RM.Tasking_Generic_RM_Hard_Case_Id := Tasking_RM.No_Tasking_Generic_RM_Hard_Case;
      Tasking_RM_Status          : Tasking_RM.Tasking_Generic_RM_Hard_Case_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Not_Checked;
      AST_Repair_Row             : AST_Repair.Coverage_Proven_AST_Repair_Id := AST_Repair.No_Coverage_Proven_AST_Repair;
      AST_Repair_Status          : AST_Repair.Coverage_Proven_AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Not_Checked;
      Exception_Generic_Row      : Exception_Generic.Exception_Generic_Final_Row_Id := Exception_Generic.No_Exception_Generic_Final_Row;
      Exception_Generic_Status   : Exception_Generic.Exception_Generic_Final_Status := Exception_Generic.Exception_Generic_Final_Not_Checked;
      Renaming_Generic_Row       : Renaming_Generic.Renaming_Generic_Final_Row_Id := Renaming_Generic.No_Renaming_Generic_Final_Row;
      Renaming_Generic_Status    : Renaming_Generic.Renaming_Generic_Final_Status := Renaming_Generic.Renaming_Generic_Final_Not_Checked;
      Predicate_Generic_Row      : Predicate_Generic.Predicate_Generic_Final_Row_Id := Predicate_Generic.No_Predicate_Generic_Final_Row;
      Predicate_Generic_Status   : Predicate_Generic.Predicate_Generic_Final_Status := Predicate_Generic.Predicate_Generic_Final_Not_Checked;
      Dataflow_Generic_Row       : Dataflow_Generic.Dataflow_Generic_Final_Row_Id := Dataflow_Generic.No_Dataflow_Generic_Final_Row;
      Dataflow_Generic_Status    : Dataflow_Generic.Dataflow_Generic_Final_Status := Dataflow_Generic.Dataflow_Generic_Final_Not_Checked;
      Requires_Cross_RM          : Boolean := True;
      Requires_Prior_Elaboration : Boolean := True;
      Requires_Overload_RM       : Boolean := True;
      Requires_Representation_RM : Boolean := True;
      Requires_Tasking_RM        : Boolean := True;
      Requires_AST_Repair        : Boolean := False;
      Requires_Exception_Generic : Boolean := True;
      Requires_Renaming_Generic  : Boolean := True;
      Requires_Predicate_Generic : Boolean := True;
      Requires_Dataflow_Generic  : Boolean := True;
      Elaboration_Order_Error    : Boolean := False;
      Preelaboration_Policy_Error : Boolean := False;
      Pure_Policy_Error          : Boolean := False;
      Remote_Types_Policy_Error  : Boolean := False;
      Shared_Passive_Policy_Error : Boolean := False;
      Generic_Body_Unavailable   : Boolean := False;
      View_Barrier               : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Elaboration_RM_Completion_Row is record
      Id                         : Elaboration_RM_Completion_Row_Id := No_Elaboration_RM_Completion_Row;
      Context                    : Elaboration_RM_Completion_Row_Id := No_Elaboration_RM_Completion_Row;
      Kind                       : Elaboration_RM_Completion_Kind := Elaboration_RM_Completion_Unknown;
      Status                     : Elaboration_RM_Completion_Status := Elaboration_RM_Completion_Not_Checked;
      Blocker_Family             : Elaboration_RM_Completion_Blocker_Family := Elaboration_RM_Completion_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Blocked                    : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Elaboration_RM_Completion_Context_Model is private;
   type Elaboration_RM_Completion_Model is private;
   type Elaboration_RM_Completion_Set is private;

   procedure Clear (Model : in out Elaboration_RM_Completion_Context_Model);
   procedure Add_Context (Model : in out Elaboration_RM_Completion_Context_Model; Info : Elaboration_RM_Completion_Context);
   function Context_Count (Model : Elaboration_RM_Completion_Context_Model) return Natural;
   function Context_At (Model : Elaboration_RM_Completion_Context_Model; Index : Positive) return Elaboration_RM_Completion_Context;
   function Context_Fingerprint (Model : Elaboration_RM_Completion_Context_Model) return Natural;

   function Build (Contexts : Elaboration_RM_Completion_Context_Model) return Elaboration_RM_Completion_Model;
   function Count (Model : Elaboration_RM_Completion_Model) return Natural;
   function Row_Count (Model : Elaboration_RM_Completion_Model) return Natural renames Count;
   function Row_At (Model : Elaboration_RM_Completion_Model; Index : Positive) return Elaboration_RM_Completion_Row;
   function Query_Count (Set : Elaboration_RM_Completion_Set) return Natural;
   function Query_At (Set : Elaboration_RM_Completion_Set; Index : Positive) return Elaboration_RM_Completion_Row;
   function Query_Status (Model : Elaboration_RM_Completion_Model; Status : Elaboration_RM_Completion_Status) return Elaboration_RM_Completion_Set;
   function Query_Blocker_Family (Model : Elaboration_RM_Completion_Model; Family : Elaboration_RM_Completion_Blocker_Family) return Elaboration_RM_Completion_Set;
   function Find_By_Node (Model : Elaboration_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_RM_Completion_Set;
   function Find_By_Source_Fingerprint (Model : Elaboration_RM_Completion_Model; Source_Fingerprint : Natural) return Elaboration_RM_Completion_Set;
   function Count_By_Status (Model : Elaboration_RM_Completion_Model; Status : Elaboration_RM_Completion_Status) return Natural;
   function Count_By_Blocker_Family (Model : Elaboration_RM_Completion_Model; Family : Elaboration_RM_Completion_Blocker_Family) return Natural;
   function Accepted_Count (Model : Elaboration_RM_Completion_Model) return Natural;
   function Blocked_Count (Model : Elaboration_RM_Completion_Model) return Natural;
   function Indeterminate_Count (Model : Elaboration_RM_Completion_Model) return Natural;
   function Stable_Fingerprint (Model : Elaboration_RM_Completion_Model) return Natural;

   function Is_Accepted (Status : Elaboration_RM_Completion_Status) return Boolean;
   function Is_Blocked (Status : Elaboration_RM_Completion_Status) return Boolean;
   function Is_Indeterminate (Status : Elaboration_RM_Completion_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_RM_Completion_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Elaboration_RM_Completion_Row);

   type Elaboration_RM_Completion_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Elaboration_RM_Completion_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Elaboration_RM_Completion_Set is record
      Rows : Row_Vectors.Vector;
   end record;
end Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
