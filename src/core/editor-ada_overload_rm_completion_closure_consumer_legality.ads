with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
with Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Overload_RM_Completion_Closure_Consumer_Legality is

   --  Case 1264 overload RM-completion closure consumer legality.
   --
   --  This package consumes the Case 1263 generic/shared-state RM-completion
   --  stabilized closure as first-class semantic evidence for overload/type
   --  RM edge consumers.  It prevents overload conclusions from bypassing
   --  stabilized closure blockers for stale/fingerprint evidence, AST/coverage
   --  repair, cross-unit closure, generic substitution, dataflow, volatile or
   --  atomic shared state, representation/freezing, tasking/protected effects,
   --  elaboration, accessibility, discriminants/variants, exception/finalization,
   --  renaming/aliasing, predicates/invariants, multiple prerequisites, and
   --  indeterminate closure state.

   package Prior renames Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;

   type Overload_RM_Closure_Consumer_Id is new Natural;
   No_Overload_RM_Closure_Consumer : constant Overload_RM_Closure_Consumer_Id := 0;

   subtype Overload_RM_Kind is Prior.Overload_Generic_RM_Edge_Kind;

   type Overload_RM_Closure_Consumer_Status is
     (Overload_RM_Closure_Consumer_Not_Checked,
      Overload_RM_Closure_Consumer_Accepted,
      Overload_RM_Closure_Consumer_Missing_Overload_RM_Row,
      Overload_RM_Closure_Consumer_Overload_RM_Blocker,
      Overload_RM_Closure_Consumer_Missing_Stabilized_Closure,
      Overload_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint,
      Overload_RM_Closure_Consumer_Closure_AST_Or_Coverage,
      Overload_RM_Closure_Consumer_Closure_Cross_Unit,
      Overload_RM_Closure_Consumer_Closure_Generic_Substitution,
      Overload_RM_Closure_Consumer_Closure_Prior_Dataflow,
      Overload_RM_Closure_Consumer_Closure_Volatile_Atomic,
      Overload_RM_Closure_Consumer_Closure_Overload_Type,
      Overload_RM_Closure_Consumer_Closure_Representation,
      Overload_RM_Closure_Consumer_Closure_Tasking_Protected,
      Overload_RM_Closure_Consumer_Closure_Elaboration,
      Overload_RM_Closure_Consumer_Closure_Accessibility,
      Overload_RM_Closure_Consumer_Closure_Discriminant_Variant,
      Overload_RM_Closure_Consumer_Closure_Exception_Finalization,
      Overload_RM_Closure_Consumer_Closure_Renaming_Alias,
      Overload_RM_Closure_Consumer_Closure_Predicate_Invariant,
      Overload_RM_Closure_Consumer_Closure_Dataflow,
      Overload_RM_Closure_Consumer_Closure_Multiple_Prerequisites,
      Overload_RM_Closure_Consumer_Closure_Recheck_Required,
      Overload_RM_Closure_Consumer_Closure_Indeterminate,
      Overload_RM_Closure_Consumer_Source_Fingerprint_Mismatch,
      Overload_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch,
      Overload_RM_Closure_Consumer_Multiple_Blockers,
      Overload_RM_Closure_Consumer_Indeterminate);

   type Overload_RM_Closure_Consumer_Family is
     (Overload_RM_Closure_Consumer_Family_None,
      Overload_RM_Closure_Consumer_Family_Overload_RM,
      Overload_RM_Closure_Consumer_Family_Stabilized_Closure,
      Overload_RM_Closure_Consumer_Family_Stale_Or_Fingerprint,
      Overload_RM_Closure_Consumer_Family_AST_Or_Coverage,
      Overload_RM_Closure_Consumer_Family_Cross_Unit,
      Overload_RM_Closure_Consumer_Family_Generic_Substitution,
      Overload_RM_Closure_Consumer_Family_Dataflow,
      Overload_RM_Closure_Consumer_Family_Volatile_Atomic,
      Overload_RM_Closure_Consumer_Family_Representation,
      Overload_RM_Closure_Consumer_Family_Tasking_Protected,
      Overload_RM_Closure_Consumer_Family_Elaboration,
      Overload_RM_Closure_Consumer_Family_Accessibility,
      Overload_RM_Closure_Consumer_Family_Discriminant_Variant,
      Overload_RM_Closure_Consumer_Family_Exception_Finalization,
      Overload_RM_Closure_Consumer_Family_Renaming_Alias,
      Overload_RM_Closure_Consumer_Family_Predicate_Invariant,
      Overload_RM_Closure_Consumer_Family_Source_Fingerprint,
      Overload_RM_Closure_Consumer_Family_Substitution_Fingerprint,
      Overload_RM_Closure_Consumer_Family_Multiple,
      Overload_RM_Closure_Consumer_Family_Indeterminate);

   type Overload_RM_Closure_Consumer_Context is record
      Id                              : Overload_RM_Closure_Consumer_Id := No_Overload_RM_Closure_Consumer;
      Kind                            : Overload_RM_Kind := Prior.Overload_Generic_RM_Edge_Unknown;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                       : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                      : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Overload_RM_Row                 : Prior.Overload_Generic_RM_Edge_Completion_Id := Prior.No_Overload_Generic_RM_Edge_Completion;
      Overload_RM_Status              : Prior.Overload_Generic_RM_Edge_Status := Prior.Overload_Generic_RM_Edge_Not_Checked;
      Stabilized_Closure_Row          : Closure.RM_Completion_Stabilized_Closure_Id := Closure.No_RM_Completion_Stabilized_Closure;
      Stabilized_Closure_Status       : Closure.RM_Completion_Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Not_Checked;
      Requires_Overload_RM            : Boolean := True;
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

   type Overload_RM_Closure_Consumer_Row is record
      Id                       : Overload_RM_Closure_Consumer_Id := No_Overload_RM_Closure_Consumer;
      Context                  : Overload_RM_Closure_Consumer_Id := No_Overload_RM_Closure_Consumer;
      Kind                     : Overload_RM_Kind := Prior.Overload_Generic_RM_Edge_Unknown;
      Status                   : Overload_RM_Closure_Consumer_Status := Overload_RM_Closure_Consumer_Not_Checked;
      Family                   : Overload_RM_Closure_Consumer_Family := Overload_RM_Closure_Consumer_Family_None;
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

   type Overload_RM_Closure_Consumer_Context_Model is private;
   type Overload_RM_Closure_Consumer_Model is private;
   type Overload_RM_Closure_Consumer_Set is private;

   procedure Clear (Model : in out Overload_RM_Closure_Consumer_Context_Model);
   procedure Add_Context
     (Model   : in out Overload_RM_Closure_Consumer_Context_Model;
      Context : Overload_RM_Closure_Consumer_Context);

   function Build (Contexts : Overload_RM_Closure_Consumer_Context_Model) return Overload_RM_Closure_Consumer_Model;
   function Count (Model : Overload_RM_Closure_Consumer_Model) return Natural;
   function Row_Count (Model : Overload_RM_Closure_Consumer_Model) return Natural renames Count;
   function Row_At
     (Model : Overload_RM_Closure_Consumer_Model;
      Index : Positive) return Overload_RM_Closure_Consumer_Row;

   function Query_Count (Set : Overload_RM_Closure_Consumer_Set) return Natural;
   function Query_At
     (Set   : Overload_RM_Closure_Consumer_Set;
      Index : Positive) return Overload_RM_Closure_Consumer_Row;

   function Count_By_Status
     (Model  : Overload_RM_Closure_Consumer_Model;
      Status : Overload_RM_Closure_Consumer_Status) return Natural;
   function Count_By_Family
     (Model  : Overload_RM_Closure_Consumer_Model;
      Family : Overload_RM_Closure_Consumer_Family) return Natural;
   function Accepted_Count (Model : Overload_RM_Closure_Consumer_Model) return Natural;
   function Blocked_Count (Model : Overload_RM_Closure_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Overload_RM_Closure_Consumer_Model) return Natural;
   function Find_By_Node
     (Model : Overload_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_RM_Closure_Consumer_Set;
   function Find_By_Source_Fingerprint
     (Model       : Overload_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Overload_RM_Closure_Consumer_Set;
   function Stable_Fingerprint (Model : Overload_RM_Closure_Consumer_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_RM_Closure_Consumer_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Overload_RM_Closure_Consumer_Row);

   type Overload_RM_Closure_Consumer_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Overload_RM_Closure_Consumer_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Overload_RM_Closure_Consumer_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Overload_RM_Completion_Closure_Consumer_Legality;
