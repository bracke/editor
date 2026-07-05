with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
with Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
with Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
with Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Shared_State_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;

package Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality is

   --  Case 1235 exception/finalization generic shared-state final legality.
   --
   --  This package connects Ada exception propagation and controlled-object
   --  finalization evidence with the generic/shared-state final semantic chain.
   --  Conclusions for raise/reraise paths, handlers, exception propagation,
   --  controlled initialization/adjust/finalize primitives, master cleanup,
   --  abort/deferred finalization, task termination, no-return paths, generic
   --  replay, cross-unit closure, discriminants/variants, accessibility, and
   --  representation-sensitive shared-state effects are accepted only when the
   --  prerequisite semantic evidence agrees.  Missing or blocked prerequisites
   --  remain first-class blocker families; this layer performs no parsing,
   --  file IO, command routing, rendering, or workspace mutation.

   package Exception_Final renames Editor.Ada_Exception_Finalization_Legality;
   package Cross_Generic renames Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
   package Elab_Generic renames Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
   package Generic_Replay renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   package Overload_Generic renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   package Rep_Generic renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   package Tasking_Generic renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
   package Access_Generic renames Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
   package Disc_Generic renames Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
   package Closure renames Editor.Ada_Shared_State_Stabilized_Closure_Legality;

   type Exception_Generic_Final_Row_Id is new Natural;
   No_Exception_Generic_Final_Row : constant Exception_Generic_Final_Row_Id := 0;

   type Exception_Generic_Final_Kind is
     (Exception_Generic_Final_Raise_Statement,
      Exception_Generic_Final_Raise_Expression,
      Exception_Generic_Final_Reraise,
      Exception_Generic_Final_Handler,
      Exception_Generic_Final_Exception_Propagation,
      Exception_Generic_Final_Controlled_Initialize,
      Exception_Generic_Final_Controlled_Adjust,
      Exception_Generic_Final_Controlled_Finalize,
      Exception_Generic_Final_Master_Finalization,
      Exception_Generic_Final_Cleanup_Action,
      Exception_Generic_Final_Abort_Deferred_Finalization,
      Exception_Generic_Final_Task_Termination,
      Exception_Generic_Final_No_Return,
      Exception_Generic_Final_Generic_Replay,
      Exception_Generic_Final_Cross_Unit_Finalization,
      Exception_Generic_Final_Unknown);

   type Exception_Generic_Final_Blocker_Family is
     (Exception_Generic_Final_Blocker_None,
      Exception_Generic_Final_Blocker_Exception_Finalization,
      Exception_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State,
      Exception_Generic_Final_Blocker_Elaboration_Generic_Shared_State,
      Exception_Generic_Final_Blocker_Generic_Abstract_Replay,
      Exception_Generic_Final_Blocker_Overload_Generic_Shared_State,
      Exception_Generic_Final_Blocker_Representation_Generic_Shared_State,
      Exception_Generic_Final_Blocker_Tasking_Generic_Shared_State,
      Exception_Generic_Final_Blocker_Accessibility_Generic_Shared_State,
      Exception_Generic_Final_Blocker_Discriminant_Generic_Shared_State,
      Exception_Generic_Final_Blocker_Stabilized_Shared_State_Closure,
      Exception_Generic_Final_Blocker_Exception_Propagation,
      Exception_Generic_Final_Blocker_Handler_Coverage,
      Exception_Generic_Final_Blocker_Finalization_Primitive,
      Exception_Generic_Final_Blocker_Finalization_Order,
      Exception_Generic_Final_Blocker_Abort_Finalization,
      Exception_Generic_Final_Blocker_Task_Termination,
      Exception_Generic_Final_Blocker_No_Return,
      Exception_Generic_Final_Blocker_Accessibility_Master,
      Exception_Generic_Final_Blocker_Discriminant_Finalization,
      Exception_Generic_Final_Blocker_Representation_Finalization,
      Exception_Generic_Final_Blocker_Source_Fingerprint,
      Exception_Generic_Final_Blocker_Substitution_Fingerprint,
      Exception_Generic_Final_Blocker_Multiple,
      Exception_Generic_Final_Blocker_Indeterminate);

   type Exception_Generic_Final_Status is
     (Exception_Generic_Final_Not_Checked,
      Exception_Generic_Final_Legal_Raise_Statement_Accepted,
      Exception_Generic_Final_Legal_Raise_Expression_Accepted,
      Exception_Generic_Final_Legal_Reraise_Accepted,
      Exception_Generic_Final_Legal_Handler_Accepted,
      Exception_Generic_Final_Legal_Exception_Propagation_Accepted,
      Exception_Generic_Final_Legal_Controlled_Initialize_Accepted,
      Exception_Generic_Final_Legal_Controlled_Adjust_Accepted,
      Exception_Generic_Final_Legal_Controlled_Finalize_Accepted,
      Exception_Generic_Final_Legal_Master_Finalization_Accepted,
      Exception_Generic_Final_Legal_Cleanup_Action_Accepted,
      Exception_Generic_Final_Legal_Abort_Deferred_Finalization_Accepted,
      Exception_Generic_Final_Legal_Task_Termination_Accepted,
      Exception_Generic_Final_Legal_No_Return_Accepted,
      Exception_Generic_Final_Legal_Generic_Replay_Accepted,
      Exception_Generic_Final_Legal_Cross_Unit_Finalization_Accepted,
      Exception_Generic_Final_Missing_Exception_Finalization_Row,
      Exception_Generic_Final_Exception_Finalization_Blocker,
      Exception_Generic_Final_Missing_Cross_Unit_Generic_Row,
      Exception_Generic_Final_Cross_Unit_Generic_Blocker,
      Exception_Generic_Final_Missing_Elaboration_Generic_Row,
      Exception_Generic_Final_Elaboration_Generic_Blocker,
      Exception_Generic_Final_Missing_Generic_Replay_Row,
      Exception_Generic_Final_Generic_Replay_Blocker,
      Exception_Generic_Final_Missing_Overload_Generic_Row,
      Exception_Generic_Final_Overload_Generic_Blocker,
      Exception_Generic_Final_Missing_Representation_Generic_Row,
      Exception_Generic_Final_Representation_Generic_Blocker,
      Exception_Generic_Final_Missing_Tasking_Generic_Row,
      Exception_Generic_Final_Tasking_Generic_Blocker,
      Exception_Generic_Final_Missing_Accessibility_Generic_Row,
      Exception_Generic_Final_Accessibility_Generic_Blocker,
      Exception_Generic_Final_Missing_Discriminant_Generic_Row,
      Exception_Generic_Final_Discriminant_Generic_Blocker,
      Exception_Generic_Final_Missing_Stabilized_Closure_Row,
      Exception_Generic_Final_Stabilized_Closure_Blocker,
      Exception_Generic_Final_Exception_Propagation_Blocker,
      Exception_Generic_Final_Handler_Coverage_Blocker,
      Exception_Generic_Final_Finalization_Primitive_Blocker,
      Exception_Generic_Final_Finalization_Order_Blocker,
      Exception_Generic_Final_Abort_Finalization_Blocker,
      Exception_Generic_Final_Task_Termination_Blocker,
      Exception_Generic_Final_No_Return_Blocker,
      Exception_Generic_Final_Accessibility_Master_Blocker,
      Exception_Generic_Final_Discriminant_Finalization_Blocker,
      Exception_Generic_Final_Representation_Finalization_Blocker,
      Exception_Generic_Final_Source_Fingerprint_Mismatch,
      Exception_Generic_Final_Substitution_Fingerprint_Mismatch,
      Exception_Generic_Final_Multiple_Blockers,
      Exception_Generic_Final_Indeterminate);

   type Exception_Generic_Final_Context is record
      Id                         : Exception_Generic_Final_Row_Id := No_Exception_Generic_Final_Row;
      Kind                       : Exception_Generic_Final_Kind := Exception_Generic_Final_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Exception_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Exception_Final_Row        : Exception_Final.Exception_Legality_Id := Exception_Final.No_Exception_Legality;
      Exception_Final_Status     : Exception_Final.Exception_Legality_Status := Exception_Final.Exception_Legality_Not_Checked;
      Cross_Generic_Row          : Cross_Generic.Cross_Unit_Generic_Final_Row_Id := Cross_Generic.No_Cross_Unit_Generic_Final_Row;
      Cross_Generic_Status       : Cross_Generic.Cross_Unit_Generic_Final_Status := Cross_Generic.Cross_Unit_Generic_Final_Not_Checked;
      Elaboration_Generic_Row    : Elab_Generic.Elaboration_Generic_Final_Row_Id := Elab_Generic.No_Elaboration_Generic_Final_Row;
      Elaboration_Generic_Status : Elab_Generic.Elaboration_Generic_Final_Status := Elab_Generic.Elaboration_Generic_Final_Not_Checked;
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
      Stabilized_Closure_Row     : Closure.Shared_State_Stabilized_Closure_Id := Closure.No_Shared_State_Stabilized_Closure;
      Stabilized_Closure_Status  : Closure.Shared_State_Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Not_Checked;
      Requires_Elaboration_Generic : Boolean := False;
      Requires_Generic_Replay    : Boolean := False;
      Requires_Overload_Generic  : Boolean := False;
      Requires_Representation_Generic : Boolean := False;
      Requires_Tasking_Generic   : Boolean := False;
      Requires_Accessibility_Generic : Boolean := False;
      Requires_Discriminant_Generic : Boolean := False;
      Requires_Stabilized_Closure : Boolean := True;
      Exception_Propagation_Blocker : Boolean := False;
      Handler_Coverage_Blocker  : Boolean := False;
      Finalization_Primitive_Blocker : Boolean := False;
      Finalization_Order_Blocker : Boolean := False;
      Abort_Finalization_Blocker : Boolean := False;
      Task_Termination_Blocker  : Boolean := False;
      No_Return_Blocker         : Boolean := False;
      Accessibility_Master_Blocker : Boolean := False;
      Discriminant_Finalization_Blocker : Boolean := False;
      Representation_Finalization_Blocker : Boolean := False;
      Source_Fingerprint        : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint  : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                : Positive := 1;
      Start_Column              : Positive := 1;
      End_Line                  : Positive := 1;
      End_Column                : Positive := 1;
   end record;

   type Exception_Generic_Final_Row is record
      Id                         : Exception_Generic_Final_Row_Id := No_Exception_Generic_Final_Row;
      Context                    : Exception_Generic_Final_Row_Id := No_Exception_Generic_Final_Row;
      Kind                       : Exception_Generic_Final_Kind := Exception_Generic_Final_Unknown;
      Status                     : Exception_Generic_Final_Status := Exception_Generic_Final_Not_Checked;
      Blocker_Family             : Exception_Generic_Final_Blocker_Family := Exception_Generic_Final_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Exception_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                  : Ada.Strings.Unbounded.Unbounded_String;
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

   type Exception_Generic_Final_Context_Model is private;
   type Exception_Generic_Final_Model is private;
   type Exception_Generic_Final_Set is private;

   procedure Clear (Model : in out Exception_Generic_Final_Context_Model);
   procedure Add_Context (Model : in out Exception_Generic_Final_Context_Model; Info : Exception_Generic_Final_Context);
   function Context_Count (Model : Exception_Generic_Final_Context_Model) return Natural;

   function Build (Contexts : Exception_Generic_Final_Context_Model) return Exception_Generic_Final_Model;
   function Count (Model : Exception_Generic_Final_Model) return Natural;
   function Row_At (Model : Exception_Generic_Final_Model; Index : Positive) return Exception_Generic_Final_Row;
   function Accepted_Count (Model : Exception_Generic_Final_Model) return Natural;
   function Blocked_Count (Model : Exception_Generic_Final_Model) return Natural;
   function Indeterminate_Count (Model : Exception_Generic_Final_Model) return Natural;
   function Count_By_Status (Model : Exception_Generic_Final_Model; Status : Exception_Generic_Final_Status) return Natural;
   function Count_By_Blocker_Family (Model : Exception_Generic_Final_Model; Family : Exception_Generic_Final_Blocker_Family) return Natural;
   function Find_By_Node (Model : Exception_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Exception_Generic_Final_Set;
   function Find_By_Source_Fingerprint (Model : Exception_Generic_Final_Model; Fingerprint : Natural) return Exception_Generic_Final_Set;
   function Query_Blocker_Family (Model : Exception_Generic_Final_Model; Family : Exception_Generic_Final_Blocker_Family) return Exception_Generic_Final_Set;
   function Query_Count (Set : Exception_Generic_Final_Set) return Natural;
   function Query_Row_At (Set : Exception_Generic_Final_Set; Index : Positive) return Exception_Generic_Final_Row;
   function Stable_Fingerprint (Model : Exception_Generic_Final_Model) return Natural;

   function Is_Accepted (Status : Exception_Generic_Final_Status) return Boolean;
   function Is_Blocked (Status : Exception_Generic_Final_Status) return Boolean;
   function Blocks_Downstream (Status : Exception_Generic_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Exception_Generic_Final_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Exception_Generic_Final_Row);

   type Exception_Generic_Final_Context_Model is record
      Items : Context_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Exception_Generic_Final_Model is record
      Rows : Row_Vectors.Vector;
      Stable_Fingerprint : Natural := 0;
   end record;

   type Exception_Generic_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
