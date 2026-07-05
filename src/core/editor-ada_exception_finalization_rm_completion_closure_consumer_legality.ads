with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Elaboration_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Dataflow_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
with Editor.Ada_Overload_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Representation_RM_Completion_Closure_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_RM_Completion_Closure_Consumer_Legality;

package Editor.Ada_Exception_Finalization_RM_Completion_Closure_Consumer_Legality is

   --  Case 1271 exception/finalization RM-completion closure consumer legality.
   --
   --  This package makes exception/finalization legality consume the Case 1263 stabilized
   --  RM-completion closure and the direct RM-completion closure consumers
   --  introduced for overload/type, representation/freezing, tasking/protected,
   --  dataflow, and cross-unit closure.  It prevents exception/finalization conclusions for
   --  raise statements, raise expressions, handlers, exception propagation,
   --  controlled initialization/adjust/finalize, master finalization, cleanup
   --  actions, abort-deferred finalization, task termination, no-return paths,
   --  generic replay finalization, dispatching exception effects, renamed
   --  handler sources, dataflow cleanup edges, and accessibility-master
   --  finalization
   --  from bypassing stabilized RM-completion evidence.

   package Prior renames Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
   package Cross_Unit renames Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality;
   package Elaboration renames Editor.Ada_Elaboration_RM_Completion_Closure_Consumer_Legality;
   package Accessibility renames Editor.Ada_Accessibility_RM_Completion_Closure_Consumer_Legality;
   package Overload renames Editor.Ada_Overload_RM_Completion_Closure_Consumer_Legality;
   package Representation renames Editor.Ada_Representation_RM_Completion_Closure_Consumer_Legality;
   package Tasking renames Editor.Ada_Tasking_RM_Completion_Closure_Consumer_Legality;
   package Dataflow renames Editor.Ada_Dataflow_RM_Completion_Closure_Consumer_Legality;

   type Exception_Finalization_RM_Closure_Consumer_Id is new Natural;
   No_Exception_Finalization_RM_Closure_Consumer : constant Exception_Finalization_RM_Closure_Consumer_Id := 0;

   subtype Exception_Finalization_RM_Kind is Prior.Exception_RM_Completion_Kind;

   type Exception_Finalization_RM_Closure_Consumer_Status is
     (Exception_Finalization_RM_Closure_Consumer_Not_Checked,
      Exception_Finalization_RM_Closure_Consumer_Accepted,
      Exception_Finalization_RM_Closure_Consumer_Missing_Exception_Finalization_RM_Row,
      Exception_Finalization_RM_Closure_Consumer_Exception_Finalization_RM_Blocker,
      Exception_Finalization_RM_Closure_Consumer_Missing_Stabilized_Closure,
      Exception_Finalization_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint,
      Exception_Finalization_RM_Closure_Consumer_Closure_AST_Or_Coverage,
      Exception_Finalization_RM_Closure_Consumer_Closure_Cross_Unit,
      Exception_Finalization_RM_Closure_Consumer_Closure_Generic_Substitution,
      Exception_Finalization_RM_Closure_Consumer_Closure_Prior_Dataflow,
      Exception_Finalization_RM_Closure_Consumer_Closure_Volatile_Atomic,
      Exception_Finalization_RM_Closure_Consumer_Closure_Overload_Type,
      Exception_Finalization_RM_Closure_Consumer_Closure_Representation,
      Exception_Finalization_RM_Closure_Consumer_Closure_Tasking_Protected,
      Exception_Finalization_RM_Closure_Consumer_Closure_Elaboration,
      Exception_Finalization_RM_Closure_Consumer_Closure_Accessibility,
      Exception_Finalization_RM_Closure_Consumer_Closure_Discriminant_Variant,
      Exception_Finalization_RM_Closure_Consumer_Closure_Exception_Finalization,
      Exception_Finalization_RM_Closure_Consumer_Closure_Renaming_Alias,
      Exception_Finalization_RM_Closure_Consumer_Closure_Predicate_Invariant,
      Exception_Finalization_RM_Closure_Consumer_Closure_Dataflow,
      Exception_Finalization_RM_Closure_Consumer_Closure_Multiple_Prerequisites,
      Exception_Finalization_RM_Closure_Consumer_Closure_Recheck_Required,
      Exception_Finalization_RM_Closure_Consumer_Closure_Indeterminate,
      Exception_Finalization_RM_Closure_Consumer_Missing_Cross_Unit_Consumer,
      Exception_Finalization_RM_Closure_Consumer_Cross_Unit_Consumer_Blocker,
      Exception_Finalization_RM_Closure_Consumer_Missing_Elaboration_Consumer,
      Exception_Finalization_RM_Closure_Consumer_Elaboration_Consumer_Blocker,
      Exception_Finalization_RM_Closure_Consumer_Missing_Accessibility_Consumer,
      Exception_Finalization_RM_Closure_Consumer_Accessibility_Consumer_Blocker,
      Exception_Finalization_RM_Closure_Consumer_Missing_Overload_Consumer,
      Exception_Finalization_RM_Closure_Consumer_Overload_Consumer_Blocker,
      Exception_Finalization_RM_Closure_Consumer_Missing_Representation_Consumer,
      Exception_Finalization_RM_Closure_Consumer_Representation_Consumer_Blocker,
      Exception_Finalization_RM_Closure_Consumer_Missing_Tasking_Consumer,
      Exception_Finalization_RM_Closure_Consumer_Tasking_Consumer_Blocker,
      Exception_Finalization_RM_Closure_Consumer_Missing_Dataflow_Consumer,
      Exception_Finalization_RM_Closure_Consumer_Dataflow_Consumer_Blocker,
      Exception_Finalization_RM_Closure_Consumer_Source_Fingerprint_Mismatch,
      Exception_Finalization_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch,
      Exception_Finalization_RM_Closure_Consumer_Multiple_Blockers,
      Exception_Finalization_RM_Closure_Consumer_Indeterminate);

   type Exception_Finalization_RM_Closure_Consumer_Family is
     (Exception_Finalization_RM_Closure_Consumer_Family_None,
      Exception_Finalization_RM_Closure_Consumer_Family_Exception_Finalization_RM,
      Exception_Finalization_RM_Closure_Consumer_Family_Stabilized_Closure,
      Exception_Finalization_RM_Closure_Consumer_Family_Stale_Or_Fingerprint,
      Exception_Finalization_RM_Closure_Consumer_Family_AST_Or_Coverage,
      Exception_Finalization_RM_Closure_Consumer_Family_Cross_Unit,
      Exception_Finalization_RM_Closure_Consumer_Family_Generic_Substitution,
      Exception_Finalization_RM_Closure_Consumer_Family_Dataflow,
      Exception_Finalization_RM_Closure_Consumer_Family_Volatile_Atomic,
      Exception_Finalization_RM_Closure_Consumer_Family_Overload_Type,
      Exception_Finalization_RM_Closure_Consumer_Family_Representation,
      Exception_Finalization_RM_Closure_Consumer_Family_Tasking_Protected,
      Exception_Finalization_RM_Closure_Consumer_Family_Elaboration,
      Exception_Finalization_RM_Closure_Consumer_Family_Accessibility,
      Exception_Finalization_RM_Closure_Consumer_Family_Discriminant_Variant,
      Exception_Finalization_RM_Closure_Consumer_Family_Exception_Finalization,
      Exception_Finalization_RM_Closure_Consumer_Family_Renaming_Alias,
      Exception_Finalization_RM_Closure_Consumer_Family_Predicate_Invariant,
      Exception_Finalization_RM_Closure_Consumer_Family_Source_Fingerprint,
      Exception_Finalization_RM_Closure_Consumer_Family_Substitution_Fingerprint,
      Exception_Finalization_RM_Closure_Consumer_Family_Multiple,
      Exception_Finalization_RM_Closure_Consumer_Family_Indeterminate);

   type Exception_Finalization_RM_Closure_Consumer_Context is record
      Id                              : Exception_Finalization_RM_Closure_Consumer_Id := No_Exception_Finalization_RM_Closure_Consumer;
      Kind                            : Exception_Finalization_RM_Kind := Prior.Exception_RM_Completion_Unknown;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                       : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name                     : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                      : Ada.Strings.Unbounded.Unbounded_String;
      Exception_Finalization_RM_Row              : Prior.Exception_RM_Completion_Row_Id := Prior.No_Exception_RM_Completion_Row;
      Exception_Finalization_RM_Status           : Prior.Exception_RM_Completion_Status := Prior.Exception_RM_Completion_Not_Checked;
      Stabilized_Closure_Row          : Closure.RM_Completion_Stabilized_Closure_Id := Closure.No_RM_Completion_Stabilized_Closure;
      Stabilized_Closure_Status       : Closure.RM_Completion_Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Not_Checked;
      Cross_Unit_Consumer_Row         : Cross_Unit.Cross_Unit_RM_Closure_Consumer_Id := Cross_Unit.No_Cross_Unit_RM_Closure_Consumer;
      Cross_Unit_Consumer_Status      : Cross_Unit.Cross_Unit_RM_Closure_Consumer_Status := Cross_Unit.Cross_Unit_RM_Closure_Consumer_Not_Checked;
      Elaboration_Consumer_Row        : Elaboration.Elaboration_RM_Closure_Consumer_Id := Elaboration.No_Elaboration_RM_Closure_Consumer;
      Elaboration_Consumer_Status     : Elaboration.Elaboration_RM_Closure_Consumer_Status := Elaboration.Elaboration_RM_Closure_Consumer_Not_Checked;
      Accessibility_Consumer_Row       : Accessibility.Accessibility_RM_Closure_Consumer_Id := Accessibility.No_Accessibility_RM_Closure_Consumer;
      Accessibility_Consumer_Status    : Accessibility.Accessibility_RM_Closure_Consumer_Status := Accessibility.Accessibility_RM_Closure_Consumer_Not_Checked;
      Overload_Consumer_Row           : Overload.Overload_RM_Closure_Consumer_Id := Overload.No_Overload_RM_Closure_Consumer;
      Overload_Consumer_Status        : Overload.Overload_RM_Closure_Consumer_Status := Overload.Overload_RM_Closure_Consumer_Not_Checked;
      Representation_Consumer_Row     : Representation.Representation_RM_Closure_Consumer_Id := Representation.No_Representation_RM_Closure_Consumer;
      Representation_Consumer_Status  : Representation.Representation_RM_Closure_Consumer_Status := Representation.Representation_RM_Closure_Consumer_Not_Checked;
      Tasking_Consumer_Row            : Tasking.Tasking_RM_Closure_Consumer_Id := Tasking.No_Tasking_RM_Closure_Consumer;
      Tasking_Consumer_Status         : Tasking.Tasking_RM_Closure_Consumer_Status := Tasking.Tasking_RM_Closure_Consumer_Not_Checked;
      Dataflow_Consumer_Row           : Dataflow.Dataflow_RM_Closure_Consumer_Id := Dataflow.No_Dataflow_RM_Closure_Consumer;
      Dataflow_Consumer_Status        : Dataflow.Dataflow_RM_Closure_Consumer_Status := Dataflow.Dataflow_RM_Closure_Consumer_Not_Checked;
      Requires_Exception_Finalization_RM         : Boolean := True;
      Requires_Stabilized_Closure     : Boolean := True;
      Requires_Cross_Unit_Consumer    : Boolean := True;
      Requires_Elaboration_Consumer   : Boolean := True;
      Requires_Accessibility_Consumer  : Boolean := True;
      Requires_Overload_Consumer      : Boolean := True;
      Requires_Representation_Consumer : Boolean := True;
      Requires_Tasking_Consumer       : Boolean := True;
      Requires_Dataflow_Consumer      : Boolean := True;
      Source_Fingerprint              : Natural := 0;
      Expected_Source_Fingerprint     : Natural := 0;
      Substitution_Fingerprint        : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                      : Positive := 1;
      Start_Column                    : Positive := 1;
      End_Line                        : Positive := 1;
      End_Column                      : Positive := 1;
   end record;

   type Exception_Finalization_RM_Closure_Consumer_Row is record
      Id                       : Exception_Finalization_RM_Closure_Consumer_Id := No_Exception_Finalization_RM_Closure_Consumer;
      Context                  : Exception_Finalization_RM_Closure_Consumer_Id := No_Exception_Finalization_RM_Closure_Consumer;
      Kind                     : Exception_Finalization_RM_Kind := Prior.Exception_RM_Completion_Unknown;
      Status                   : Exception_Finalization_RM_Closure_Consumer_Status := Exception_Finalization_RM_Closure_Consumer_Not_Checked;
      Family                   : Exception_Finalization_RM_Closure_Consumer_Family := Exception_Finalization_RM_Closure_Consumer_Family_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name              : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                 : Boolean := False;
      Blocked                  : Boolean := False;
      Blocks_Downstream        : Boolean := False;
      Source_Fingerprint       : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Row_Fingerprint          : Natural := 0;
      Start_Line               : Positive := 1;
      Start_Column             : Positive := 1;
      End_Line                 : Positive := 1;
      End_Column               : Positive := 1;
      Message                  : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Exception_Finalization_RM_Closure_Consumer_Context_Model is private;
   type Exception_Finalization_RM_Closure_Consumer_Model is private;
   type Exception_Finalization_RM_Closure_Consumer_Set is private;

   procedure Clear (Model : in out Exception_Finalization_RM_Closure_Consumer_Context_Model);
   procedure Add_Context
     (Model   : in out Exception_Finalization_RM_Closure_Consumer_Context_Model;
      Context : Exception_Finalization_RM_Closure_Consumer_Context);

   function Build (Contexts : Exception_Finalization_RM_Closure_Consumer_Context_Model) return Exception_Finalization_RM_Closure_Consumer_Model;
   function Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural;
   function Row_Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural renames Count;
   function Row_At
     (Model : Exception_Finalization_RM_Closure_Consumer_Model;
      Index : Positive) return Exception_Finalization_RM_Closure_Consumer_Row;

   function Query_Count (Set : Exception_Finalization_RM_Closure_Consumer_Set) return Natural;
   function Query_At
     (Set   : Exception_Finalization_RM_Closure_Consumer_Set;
      Index : Positive) return Exception_Finalization_RM_Closure_Consumer_Row;

   function Count_By_Status
     (Model  : Exception_Finalization_RM_Closure_Consumer_Model;
      Status : Exception_Finalization_RM_Closure_Consumer_Status) return Natural;
   function Count_By_Family
     (Model  : Exception_Finalization_RM_Closure_Consumer_Model;
      Family : Exception_Finalization_RM_Closure_Consumer_Family) return Natural;
   function Accepted_Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural;
   function Blocked_Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural;
   function Find_By_Node
     (Model : Exception_Finalization_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Exception_Finalization_RM_Closure_Consumer_Set;
   function Find_By_Source_Fingerprint
     (Model       : Exception_Finalization_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Exception_Finalization_RM_Closure_Consumer_Set;
   function Stable_Fingerprint (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Exception_Finalization_RM_Closure_Consumer_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Exception_Finalization_RM_Closure_Consumer_Row);

   type Exception_Finalization_RM_Closure_Consumer_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Exception_Finalization_RM_Closure_Consumer_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Exception_Finalization_RM_Closure_Consumer_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Exception_Finalization_RM_Completion_Closure_Consumer_Legality;
