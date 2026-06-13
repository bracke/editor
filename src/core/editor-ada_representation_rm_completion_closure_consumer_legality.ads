with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
with Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Representation_RM_Completion_Closure_Consumer_Legality is

   --  Pass1265 representation RM-completion closure consumer legality.
   --
   --  This package consumes the Pass1263 generic/shared-state RM-completion
   --  stabilized closure as first-class semantic evidence for representation/freezing
   --  RM hard-case consumers.  It prevents representation conclusions from bypassing
   --  stabilized closure blockers for stale/fingerprint evidence, AST/coverage
   --  repair, cross-unit closure, generic substitution, dataflow, volatile or
   --  atomic shared state, representation/freezing, tasking/protected effects,
   --  elaboration, accessibility, discriminants/variants, exception/finalization,
   --  renaming/aliasing, predicates/invariants, multiple prerequisites, and
   --  indeterminate closure state.

   package Prior renames Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;

   type Representation_RM_Closure_Consumer_Id is new Natural;
   No_Representation_RM_Closure_Consumer : constant Representation_RM_Closure_Consumer_Id := 0;

   subtype Representation_RM_Kind is Prior.Representation_Generic_RM_Hard_Case_Kind;

   type Representation_RM_Closure_Consumer_Status is
     (Representation_RM_Closure_Consumer_Not_Checked,
      Representation_RM_Closure_Consumer_Accepted,
      Representation_RM_Closure_Consumer_Missing_Representation_RM_Row,
      Representation_RM_Closure_Consumer_Representation_RM_Blocker,
      Representation_RM_Closure_Consumer_Missing_Stabilized_Closure,
      Representation_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint,
      Representation_RM_Closure_Consumer_Closure_AST_Or_Coverage,
      Representation_RM_Closure_Consumer_Closure_Cross_Unit,
      Representation_RM_Closure_Consumer_Closure_Generic_Substitution,
      Representation_RM_Closure_Consumer_Closure_Prior_Dataflow,
      Representation_RM_Closure_Consumer_Closure_Volatile_Atomic,
      Representation_RM_Closure_Consumer_Closure_Overload_Type,
      Representation_RM_Closure_Consumer_Closure_Representation,
      Representation_RM_Closure_Consumer_Closure_Tasking_Protected,
      Representation_RM_Closure_Consumer_Closure_Elaboration,
      Representation_RM_Closure_Consumer_Closure_Accessibility,
      Representation_RM_Closure_Consumer_Closure_Discriminant_Variant,
      Representation_RM_Closure_Consumer_Closure_Exception_Finalization,
      Representation_RM_Closure_Consumer_Closure_Renaming_Alias,
      Representation_RM_Closure_Consumer_Closure_Predicate_Invariant,
      Representation_RM_Closure_Consumer_Closure_Dataflow,
      Representation_RM_Closure_Consumer_Closure_Multiple_Prerequisites,
      Representation_RM_Closure_Consumer_Closure_Recheck_Required,
      Representation_RM_Closure_Consumer_Closure_Indeterminate,
      Representation_RM_Closure_Consumer_Source_Fingerprint_Mismatch,
      Representation_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch,
      Representation_RM_Closure_Consumer_Multiple_Blockers,
      Representation_RM_Closure_Consumer_Indeterminate);

   type Representation_RM_Closure_Consumer_Family is
     (Representation_RM_Closure_Consumer_Family_None,
      Representation_RM_Closure_Consumer_Family_Representation_RM,
      Representation_RM_Closure_Consumer_Family_Stabilized_Closure,
      Representation_RM_Closure_Consumer_Family_Stale_Or_Fingerprint,
      Representation_RM_Closure_Consumer_Family_AST_Or_Coverage,
      Representation_RM_Closure_Consumer_Family_Cross_Unit,
      Representation_RM_Closure_Consumer_Family_Generic_Substitution,
      Representation_RM_Closure_Consumer_Family_Dataflow,
      Representation_RM_Closure_Consumer_Family_Volatile_Atomic,
      Representation_RM_Closure_Consumer_Family_Representation,
      Representation_RM_Closure_Consumer_Family_Tasking_Protected,
      Representation_RM_Closure_Consumer_Family_Elaboration,
      Representation_RM_Closure_Consumer_Family_Accessibility,
      Representation_RM_Closure_Consumer_Family_Discriminant_Variant,
      Representation_RM_Closure_Consumer_Family_Exception_Finalization,
      Representation_RM_Closure_Consumer_Family_Renaming_Alias,
      Representation_RM_Closure_Consumer_Family_Predicate_Invariant,
      Representation_RM_Closure_Consumer_Family_Source_Fingerprint,
      Representation_RM_Closure_Consumer_Family_Substitution_Fingerprint,
      Representation_RM_Closure_Consumer_Family_Multiple,
      Representation_RM_Closure_Consumer_Family_Indeterminate);

   type Representation_RM_Closure_Consumer_Context is record
      Id                              : Representation_RM_Closure_Consumer_Id := No_Representation_RM_Closure_Consumer;
      Kind                            : Representation_RM_Kind := Prior.Representation_Generic_RM_Hard_Case_Unknown;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operation_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Type_Name                       : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                      : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      Representation_RM_Row                 : Prior.Representation_Generic_RM_Hard_Case_Id := Prior.No_Representation_Generic_RM_Hard_Case;
      Representation_RM_Status              : Prior.Representation_Generic_RM_Hard_Case_Status := Prior.Representation_Generic_RM_Hard_Case_Not_Checked;
      Stabilized_Closure_Row          : Closure.RM_Completion_Stabilized_Closure_Id := Closure.No_RM_Completion_Stabilized_Closure;
      Stabilized_Closure_Status       : Closure.RM_Completion_Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Not_Checked;
      Requires_Representation_RM            : Boolean := True;
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

   type Representation_RM_Closure_Consumer_Row is record
      Id                       : Representation_RM_Closure_Consumer_Id := No_Representation_RM_Closure_Consumer;
      Context                  : Representation_RM_Closure_Consumer_Id := No_Representation_RM_Closure_Consumer;
      Kind                     : Representation_RM_Kind := Prior.Representation_Generic_RM_Hard_Case_Unknown;
      Status                   : Representation_RM_Closure_Consumer_Status := Representation_RM_Closure_Consumer_Not_Checked;
      Family                   : Representation_RM_Closure_Consumer_Family := Representation_RM_Closure_Consumer_Family_None;
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

   type Representation_RM_Closure_Consumer_Context_Model is private;
   type Representation_RM_Closure_Consumer_Model is private;
   type Representation_RM_Closure_Consumer_Set is private;

   procedure Clear (Model : in out Representation_RM_Closure_Consumer_Context_Model);
   procedure Add_Context
     (Model   : in out Representation_RM_Closure_Consumer_Context_Model;
      Context : Representation_RM_Closure_Consumer_Context);

   function Build (Contexts : Representation_RM_Closure_Consumer_Context_Model) return Representation_RM_Closure_Consumer_Model;
   function Count (Model : Representation_RM_Closure_Consumer_Model) return Natural;
   function Row_Count (Model : Representation_RM_Closure_Consumer_Model) return Natural renames Count;
   function Row_At
     (Model : Representation_RM_Closure_Consumer_Model;
      Index : Positive) return Representation_RM_Closure_Consumer_Row;

   function Query_Count (Set : Representation_RM_Closure_Consumer_Set) return Natural;
   function Query_At
     (Set   : Representation_RM_Closure_Consumer_Set;
      Index : Positive) return Representation_RM_Closure_Consumer_Row;

   function Count_By_Status
     (Model  : Representation_RM_Closure_Consumer_Model;
      Status : Representation_RM_Closure_Consumer_Status) return Natural;
   function Count_By_Family
     (Model  : Representation_RM_Closure_Consumer_Model;
      Family : Representation_RM_Closure_Consumer_Family) return Natural;
   function Accepted_Count (Model : Representation_RM_Closure_Consumer_Model) return Natural;
   function Blocked_Count (Model : Representation_RM_Closure_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Representation_RM_Closure_Consumer_Model) return Natural;
   function Find_By_Node
     (Model : Representation_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_RM_Closure_Consumer_Set;
   function Find_By_Source_Fingerprint
     (Model       : Representation_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Representation_RM_Closure_Consumer_Set;
   function Stable_Fingerprint (Model : Representation_RM_Closure_Consumer_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_RM_Closure_Consumer_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_RM_Closure_Consumer_Row);

   type Representation_RM_Closure_Consumer_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Representation_RM_Closure_Consumer_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Representation_RM_Closure_Consumer_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Representation_RM_Completion_Closure_Consumer_Legality;
