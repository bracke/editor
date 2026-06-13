with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
with Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Dataflow_RM_Completion_Closure_Consumer_Legality is

   --  Pass1267 dataflow/initialization RM-completion closure consumer legality.
   --
   --  This package consumes the Pass1263 generic/shared-state RM-completion
   --  stabilized closure as first-class semantic evidence for dataflow/initialization
   --  RM-completion dataflow consumers.  It prevents dataflow/initialization conclusions from bypassing
   --  stabilized closure blockers for stale/fingerprint evidence, AST/coverage
   --  repair, cross-unit closure, generic substitution, dataflow, volatile or
   --  atomic shared state, dataflow/initialization, tasking/protected effects,
   --  elaboration, accessibility, discriminants/variants, exception/finalization,
   --  renaming/aliasing, predicates/invariants, multiple prerequisites, and
   --  indeterminate closure state.

   package Prior renames Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;

   type Dataflow_RM_Closure_Consumer_Id is new Natural;
   No_Dataflow_RM_Closure_Consumer : constant Dataflow_RM_Closure_Consumer_Id := 0;

   subtype Dataflow_RM_Kind is Prior.Dataflow_RM_Completion_Kind;

   type Dataflow_RM_Closure_Consumer_Status is
     (Dataflow_RM_Closure_Consumer_Not_Checked,
      Dataflow_RM_Closure_Consumer_Accepted,
      Dataflow_RM_Closure_Consumer_Missing_Dataflow_RM_Row,
      Dataflow_RM_Closure_Consumer_Dataflow_RM_Blocker,
      Dataflow_RM_Closure_Consumer_Missing_Stabilized_Closure,
      Dataflow_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint,
      Dataflow_RM_Closure_Consumer_Closure_AST_Or_Coverage,
      Dataflow_RM_Closure_Consumer_Closure_Cross_Unit,
      Dataflow_RM_Closure_Consumer_Closure_Generic_Substitution,
      Dataflow_RM_Closure_Consumer_Closure_Prior_Dataflow,
      Dataflow_RM_Closure_Consumer_Closure_Volatile_Atomic,
      Dataflow_RM_Closure_Consumer_Closure_Overload_Type,
      Dataflow_RM_Closure_Consumer_Closure_Representation,
      Dataflow_RM_Closure_Consumer_Closure_Tasking_Protected,
      Dataflow_RM_Closure_Consumer_Closure_Elaboration,
      Dataflow_RM_Closure_Consumer_Closure_Accessibility,
      Dataflow_RM_Closure_Consumer_Closure_Discriminant_Variant,
      Dataflow_RM_Closure_Consumer_Closure_Exception_Finalization,
      Dataflow_RM_Closure_Consumer_Closure_Renaming_Alias,
      Dataflow_RM_Closure_Consumer_Closure_Predicate_Invariant,
      Dataflow_RM_Closure_Consumer_Closure_Dataflow,
      Dataflow_RM_Closure_Consumer_Closure_Multiple_Prerequisites,
      Dataflow_RM_Closure_Consumer_Closure_Recheck_Required,
      Dataflow_RM_Closure_Consumer_Closure_Indeterminate,
      Dataflow_RM_Closure_Consumer_Source_Fingerprint_Mismatch,
      Dataflow_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch,
      Dataflow_RM_Closure_Consumer_Multiple_Blockers,
      Dataflow_RM_Closure_Consumer_Indeterminate);

   type Dataflow_RM_Closure_Consumer_Family is
     (Dataflow_RM_Closure_Consumer_Family_None,
      Dataflow_RM_Closure_Consumer_Family_Dataflow_RM,
      Dataflow_RM_Closure_Consumer_Family_Stabilized_Closure,
      Dataflow_RM_Closure_Consumer_Family_Stale_Or_Fingerprint,
      Dataflow_RM_Closure_Consumer_Family_AST_Or_Coverage,
      Dataflow_RM_Closure_Consumer_Family_Cross_Unit,
      Dataflow_RM_Closure_Consumer_Family_Generic_Substitution,
      Dataflow_RM_Closure_Consumer_Family_Dataflow,
      Dataflow_RM_Closure_Consumer_Family_Volatile_Atomic,
      Dataflow_RM_Closure_Consumer_Family_Representation,
      Dataflow_RM_Closure_Consumer_Family_Tasking_Protected,
      Dataflow_RM_Closure_Consumer_Family_Elaboration,
      Dataflow_RM_Closure_Consumer_Family_Accessibility,
      Dataflow_RM_Closure_Consumer_Family_Discriminant_Variant,
      Dataflow_RM_Closure_Consumer_Family_Exception_Finalization,
      Dataflow_RM_Closure_Consumer_Family_Renaming_Alias,
      Dataflow_RM_Closure_Consumer_Family_Predicate_Invariant,
      Dataflow_RM_Closure_Consumer_Family_Source_Fingerprint,
      Dataflow_RM_Closure_Consumer_Family_Substitution_Fingerprint,
      Dataflow_RM_Closure_Consumer_Family_Multiple,
      Dataflow_RM_Closure_Consumer_Family_Indeterminate);

   type Dataflow_RM_Closure_Consumer_Context is record
      Id                              : Dataflow_RM_Closure_Consumer_Id := No_Dataflow_RM_Closure_Consumer;
      Kind                            : Dataflow_RM_Kind := Prior.Dataflow_RM_Completion_Unknown;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                       : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                      : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Dataflow_RM_Row                 : Prior.Dataflow_RM_Completion_Row_Id := Prior.No_Dataflow_RM_Completion_Row;
      Dataflow_RM_Status              : Prior.Dataflow_RM_Completion_Status := Prior.Dataflow_RM_Completion_Not_Checked;
      Stabilized_Closure_Row          : Closure.RM_Completion_Stabilized_Closure_Id := Closure.No_RM_Completion_Stabilized_Closure;
      Stabilized_Closure_Status       : Closure.RM_Completion_Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Not_Checked;
      Requires_Dataflow_RM            : Boolean := True;
      Requires_Stabilized_Closure     : Boolean := True;
      Source_Fingerprint              : Natural := 0;
      Expected_Source_Fingerprint     : Natural := 0;
      Substitution_Fingerprint        : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                      : Positive := 1;
      Start_Column                    : Positive := 1;
      End_Line                        : Positive := 1;
      End_Column                      : Positive := 1;
   end record;

   type Dataflow_RM_Closure_Consumer_Row is record
      Id                       : Dataflow_RM_Closure_Consumer_Id := No_Dataflow_RM_Closure_Consumer;
      Context                  : Dataflow_RM_Closure_Consumer_Id := No_Dataflow_RM_Closure_Consumer;
      Kind                     : Dataflow_RM_Kind := Prior.Dataflow_RM_Completion_Unknown;
      Status                   : Dataflow_RM_Closure_Consumer_Status := Dataflow_RM_Closure_Consumer_Not_Checked;
      Family                   : Dataflow_RM_Closure_Consumer_Family := Dataflow_RM_Closure_Consumer_Family_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                : Ada.Strings.Unbounded.Unbounded_String;
      State_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name            : Ada.Strings.Unbounded.Unbounded_String;
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

   type Dataflow_RM_Closure_Consumer_Context_Model is private;
   type Dataflow_RM_Closure_Consumer_Model is private;
   type Dataflow_RM_Closure_Consumer_Set is private;

   procedure Clear (Model : in out Dataflow_RM_Closure_Consumer_Context_Model);
   procedure Add_Context
     (Model   : in out Dataflow_RM_Closure_Consumer_Context_Model;
      Context : Dataflow_RM_Closure_Consumer_Context);

   function Build (Contexts : Dataflow_RM_Closure_Consumer_Context_Model) return Dataflow_RM_Closure_Consumer_Model;
   function Count (Model : Dataflow_RM_Closure_Consumer_Model) return Natural;
   function Row_Count (Model : Dataflow_RM_Closure_Consumer_Model) return Natural renames Count;
   function Row_At
     (Model : Dataflow_RM_Closure_Consumer_Model;
      Index : Positive) return Dataflow_RM_Closure_Consumer_Row;

   function Query_Count (Set : Dataflow_RM_Closure_Consumer_Set) return Natural;
   function Query_At
     (Set   : Dataflow_RM_Closure_Consumer_Set;
      Index : Positive) return Dataflow_RM_Closure_Consumer_Row;

   function Count_By_Status
     (Model  : Dataflow_RM_Closure_Consumer_Model;
      Status : Dataflow_RM_Closure_Consumer_Status) return Natural;
   function Count_By_Family
     (Model  : Dataflow_RM_Closure_Consumer_Model;
      Family : Dataflow_RM_Closure_Consumer_Family) return Natural;
   function Accepted_Count (Model : Dataflow_RM_Closure_Consumer_Model) return Natural;
   function Blocked_Count (Model : Dataflow_RM_Closure_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Dataflow_RM_Closure_Consumer_Model) return Natural;
   function Find_By_Node
     (Model : Dataflow_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Dataflow_RM_Closure_Consumer_Set;
   function Find_By_Source_Fingerprint
     (Model       : Dataflow_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Dataflow_RM_Closure_Consumer_Set;
   function Stable_Fingerprint (Model : Dataflow_RM_Closure_Consumer_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dataflow_RM_Closure_Consumer_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Dataflow_RM_Closure_Consumer_Row);

   type Dataflow_RM_Closure_Consumer_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Dataflow_RM_Closure_Consumer_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Dataflow_RM_Closure_Consumer_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Dataflow_RM_Completion_Closure_Consumer_Legality;
