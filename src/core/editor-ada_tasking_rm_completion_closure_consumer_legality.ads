with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
with Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Tasking_RM_Completion_Closure_Consumer_Legality is

   --  Case 1266 tasking/protected RM-completion closure consumer legality.
   --
   --  This package consumes the Case 1263 generic/shared-state RM-completion
   --  stabilized closure as first-class semantic evidence for tasking/protected
   --  RM hard-case consumers.  It prevents tasking/protected conclusions from bypassing
   --  stabilized closure blockers for stale/fingerprint evidence, AST/coverage
   --  repair, cross-unit closure, generic substitution, dataflow, volatile or
   --  atomic shared state, tasking/protected, tasking/protected effects,
   --  elaboration, accessibility, discriminants/variants, exception/finalization,
   --  renaming/aliasing, predicates/invariants, multiple prerequisites, and
   --  indeterminate closure state.

   package Prior renames Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;

   type Tasking_RM_Closure_Consumer_Id is new Natural;
   No_Tasking_RM_Closure_Consumer : constant Tasking_RM_Closure_Consumer_Id := 0;

   subtype Tasking_RM_Kind is Prior.Tasking_Generic_RM_Hard_Case_Kind;

   type Tasking_RM_Closure_Consumer_Status is
     (Tasking_RM_Closure_Consumer_Not_Checked,
      Tasking_RM_Closure_Consumer_Accepted,
      Tasking_RM_Closure_Consumer_Missing_Tasking_RM_Row,
      Tasking_RM_Closure_Consumer_Tasking_RM_Blocker,
      Tasking_RM_Closure_Consumer_Missing_Stabilized_Closure,
      Tasking_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint,
      Tasking_RM_Closure_Consumer_Closure_AST_Or_Coverage,
      Tasking_RM_Closure_Consumer_Closure_Cross_Unit,
      Tasking_RM_Closure_Consumer_Closure_Generic_Substitution,
      Tasking_RM_Closure_Consumer_Closure_Prior_Dataflow,
      Tasking_RM_Closure_Consumer_Closure_Volatile_Atomic,
      Tasking_RM_Closure_Consumer_Closure_Overload_Type,
      Tasking_RM_Closure_Consumer_Closure_Representation,
      Tasking_RM_Closure_Consumer_Closure_Tasking_Protected,
      Tasking_RM_Closure_Consumer_Closure_Elaboration,
      Tasking_RM_Closure_Consumer_Closure_Accessibility,
      Tasking_RM_Closure_Consumer_Closure_Discriminant_Variant,
      Tasking_RM_Closure_Consumer_Closure_Exception_Finalization,
      Tasking_RM_Closure_Consumer_Closure_Renaming_Alias,
      Tasking_RM_Closure_Consumer_Closure_Predicate_Invariant,
      Tasking_RM_Closure_Consumer_Closure_Dataflow,
      Tasking_RM_Closure_Consumer_Closure_Multiple_Prerequisites,
      Tasking_RM_Closure_Consumer_Closure_Recheck_Required,
      Tasking_RM_Closure_Consumer_Closure_Indeterminate,
      Tasking_RM_Closure_Consumer_Source_Fingerprint_Mismatch,
      Tasking_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch,
      Tasking_RM_Closure_Consumer_Multiple_Blockers,
      Tasking_RM_Closure_Consumer_Indeterminate);

   type Tasking_RM_Closure_Consumer_Family is
     (Tasking_RM_Closure_Consumer_Family_None,
      Tasking_RM_Closure_Consumer_Family_Tasking_RM,
      Tasking_RM_Closure_Consumer_Family_Stabilized_Closure,
      Tasking_RM_Closure_Consumer_Family_Stale_Or_Fingerprint,
      Tasking_RM_Closure_Consumer_Family_AST_Or_Coverage,
      Tasking_RM_Closure_Consumer_Family_Cross_Unit,
      Tasking_RM_Closure_Consumer_Family_Generic_Substitution,
      Tasking_RM_Closure_Consumer_Family_Dataflow,
      Tasking_RM_Closure_Consumer_Family_Volatile_Atomic,
      Tasking_RM_Closure_Consumer_Family_Representation,
      Tasking_RM_Closure_Consumer_Family_Tasking_Protected,
      Tasking_RM_Closure_Consumer_Family_Elaboration,
      Tasking_RM_Closure_Consumer_Family_Accessibility,
      Tasking_RM_Closure_Consumer_Family_Discriminant_Variant,
      Tasking_RM_Closure_Consumer_Family_Exception_Finalization,
      Tasking_RM_Closure_Consumer_Family_Renaming_Alias,
      Tasking_RM_Closure_Consumer_Family_Predicate_Invariant,
      Tasking_RM_Closure_Consumer_Family_Source_Fingerprint,
      Tasking_RM_Closure_Consumer_Family_Substitution_Fingerprint,
      Tasking_RM_Closure_Consumer_Family_Multiple,
      Tasking_RM_Closure_Consumer_Family_Indeterminate);

   type Tasking_RM_Closure_Consumer_Context is record
      Id                              : Tasking_RM_Closure_Consumer_Id := No_Tasking_RM_Closure_Consumer;
      Kind                            : Tasking_RM_Kind := Prior.Tasking_Generic_RM_Hard_Case_Unknown;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                       : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                      : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Tasking_RM_Row                 : Prior.Tasking_Generic_RM_Hard_Case_Id := Prior.No_Tasking_Generic_RM_Hard_Case;
      Tasking_RM_Status              : Prior.Tasking_Generic_RM_Hard_Case_Status := Prior.Tasking_Generic_RM_Hard_Case_Not_Checked;
      Stabilized_Closure_Row          : Closure.RM_Completion_Stabilized_Closure_Id := Closure.No_RM_Completion_Stabilized_Closure;
      Stabilized_Closure_Status       : Closure.RM_Completion_Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Not_Checked;
      Requires_Tasking_RM            : Boolean := True;
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

   type Tasking_RM_Closure_Consumer_Row is record
      Id                       : Tasking_RM_Closure_Consumer_Id := No_Tasking_RM_Closure_Consumer;
      Context                  : Tasking_RM_Closure_Consumer_Id := No_Tasking_RM_Closure_Consumer;
      Kind                     : Tasking_RM_Kind := Prior.Tasking_Generic_RM_Hard_Case_Unknown;
      Status                   : Tasking_RM_Closure_Consumer_Status := Tasking_RM_Closure_Consumer_Not_Checked;
      Family                   : Tasking_RM_Closure_Consumer_Family := Tasking_RM_Closure_Consumer_Family_None;
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

   type Tasking_RM_Closure_Consumer_Context_Model is private;
   type Tasking_RM_Closure_Consumer_Model is private;
   type Tasking_RM_Closure_Consumer_Set is private;

   procedure Clear (Model : in out Tasking_RM_Closure_Consumer_Context_Model);
   procedure Add_Context
     (Model   : in out Tasking_RM_Closure_Consumer_Context_Model;
      Context : Tasking_RM_Closure_Consumer_Context);

   function Build (Contexts : Tasking_RM_Closure_Consumer_Context_Model) return Tasking_RM_Closure_Consumer_Model;
   function Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural;
   function Row_Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural renames Count;
   function Row_At
     (Model : Tasking_RM_Closure_Consumer_Model;
      Index : Positive) return Tasking_RM_Closure_Consumer_Row;

   function Query_Count (Set : Tasking_RM_Closure_Consumer_Set) return Natural;
   function Query_At
     (Set   : Tasking_RM_Closure_Consumer_Set;
      Index : Positive) return Tasking_RM_Closure_Consumer_Row;

   function Count_By_Status
     (Model  : Tasking_RM_Closure_Consumer_Model;
      Status : Tasking_RM_Closure_Consumer_Status) return Natural;
   function Count_By_Family
     (Model  : Tasking_RM_Closure_Consumer_Model;
      Family : Tasking_RM_Closure_Consumer_Family) return Natural;
   function Accepted_Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural;
   function Blocked_Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural;
   function Find_By_Node
     (Model : Tasking_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_RM_Closure_Consumer_Set;
   function Find_By_Source_Fingerprint
     (Model       : Tasking_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Tasking_RM_Closure_Consumer_Set;
   function Stable_Fingerprint (Model : Tasking_RM_Closure_Consumer_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_RM_Closure_Consumer_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Tasking_RM_Closure_Consumer_Row);

   type Tasking_RM_Closure_Consumer_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Tasking_RM_Closure_Consumer_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Tasking_RM_Closure_Consumer_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Tasking_RM_Completion_Closure_Consumer_Legality;
