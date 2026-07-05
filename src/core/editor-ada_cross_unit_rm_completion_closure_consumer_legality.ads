with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality is

   --  Case 1268 cross-unit RM-completion closure consumer legality.
   --
   --  This package makes cross-unit semantic closure consume the Case 1263
   --  generic/shared-state RM-completion stabilized closure directly, instead
   --  of accepting older intermediate cross-unit rows as sufficient evidence.
   --  It preserves dependency, view-barrier, child/private-child, separate-body,
   --  generic body/backmapping, state-visibility, source fingerprint,
   --  substitution fingerprint, RM-completion closure, stabilized closure,
   --  multiple-blocker, and indeterminate families as first-class downstream
   --  blockers across specs, bodies, with/use dependencies, child units, private
   --  children, separate bodies, generic bodies, and generic instances.

   package Prior renames Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality;
   package Closure renames Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;

   type Cross_Unit_RM_Closure_Consumer_Id is new Natural;
   No_Cross_Unit_RM_Closure_Consumer : constant Cross_Unit_RM_Closure_Consumer_Id := 0;

   subtype Cross_Unit_RM_Kind is Prior.Cross_Unit_RM_Completion_Kind;
   subtype Cross_Unit_RM_Dependency_State is Prior.Cross_Unit_RM_Dependency_State;

   type Cross_Unit_RM_Closure_Consumer_Status is
     (Cross_Unit_RM_Closure_Consumer_Not_Checked,
      Cross_Unit_RM_Closure_Consumer_Accepted,
      Cross_Unit_RM_Closure_Consumer_Missing_Cross_Unit_RM_Row,
      Cross_Unit_RM_Closure_Consumer_Cross_Unit_RM_Blocker,
      Cross_Unit_RM_Closure_Consumer_Missing_Stabilized_Closure,
      Cross_Unit_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint,
      Cross_Unit_RM_Closure_Consumer_Closure_AST_Or_Coverage,
      Cross_Unit_RM_Closure_Consumer_Closure_Cross_Unit,
      Cross_Unit_RM_Closure_Consumer_Closure_Generic_Substitution,
      Cross_Unit_RM_Closure_Consumer_Closure_Prior_Dataflow,
      Cross_Unit_RM_Closure_Consumer_Closure_Volatile_Atomic,
      Cross_Unit_RM_Closure_Consumer_Closure_Overload_Type,
      Cross_Unit_RM_Closure_Consumer_Closure_Representation,
      Cross_Unit_RM_Closure_Consumer_Closure_Tasking_Protected,
      Cross_Unit_RM_Closure_Consumer_Closure_Elaboration,
      Cross_Unit_RM_Closure_Consumer_Closure_Accessibility,
      Cross_Unit_RM_Closure_Consumer_Closure_Discriminant_Variant,
      Cross_Unit_RM_Closure_Consumer_Closure_Exception_Finalization,
      Cross_Unit_RM_Closure_Consumer_Closure_Renaming_Alias,
      Cross_Unit_RM_Closure_Consumer_Closure_Predicate_Invariant,
      Cross_Unit_RM_Closure_Consumer_Closure_Dataflow,
      Cross_Unit_RM_Closure_Consumer_Closure_Multiple_Prerequisites,
      Cross_Unit_RM_Closure_Consumer_Closure_Recheck_Required,
      Cross_Unit_RM_Closure_Consumer_Closure_Indeterminate,
      Cross_Unit_RM_Closure_Consumer_Missing_Dependency,
      Cross_Unit_RM_Closure_Consumer_Ambiguous_Dependency,
      Cross_Unit_RM_Closure_Consumer_Dependency_Overflow,
      Cross_Unit_RM_Closure_Consumer_Stale_Dependency,
      Cross_Unit_RM_Closure_Consumer_Limited_View_Barrier,
      Cross_Unit_RM_Closure_Consumer_Private_View_Barrier,
      Cross_Unit_RM_Closure_Consumer_Private_Child_Visibility_Blocker,
      Cross_Unit_RM_Closure_Consumer_Separate_Body_Blocker,
      Cross_Unit_RM_Closure_Consumer_Generic_Body_Unavailable,
      Cross_Unit_RM_Closure_Consumer_Generic_Backmapping_Blocker,
      Cross_Unit_RM_Closure_Consumer_State_Visibility_Blocker,
      Cross_Unit_RM_Closure_Consumer_Source_Fingerprint_Mismatch,
      Cross_Unit_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch,
      Cross_Unit_RM_Closure_Consumer_Multiple_Blockers,
      Cross_Unit_RM_Closure_Consumer_Indeterminate);

   type Cross_Unit_RM_Closure_Consumer_Family is
     (Cross_Unit_RM_Closure_Consumer_Family_None,
      Cross_Unit_RM_Closure_Consumer_Family_Cross_Unit_RM,
      Cross_Unit_RM_Closure_Consumer_Family_Stabilized_Closure,
      Cross_Unit_RM_Closure_Consumer_Family_Stale_Or_Fingerprint,
      Cross_Unit_RM_Closure_Consumer_Family_AST_Or_Coverage,
      Cross_Unit_RM_Closure_Consumer_Family_Cross_Unit,
      Cross_Unit_RM_Closure_Consumer_Family_Generic_Substitution,
      Cross_Unit_RM_Closure_Consumer_Family_Dataflow,
      Cross_Unit_RM_Closure_Consumer_Family_Volatile_Atomic,
      Cross_Unit_RM_Closure_Consumer_Family_Overload_Type,
      Cross_Unit_RM_Closure_Consumer_Family_Representation,
      Cross_Unit_RM_Closure_Consumer_Family_Tasking_Protected,
      Cross_Unit_RM_Closure_Consumer_Family_Elaboration,
      Cross_Unit_RM_Closure_Consumer_Family_Accessibility,
      Cross_Unit_RM_Closure_Consumer_Family_Discriminant_Variant,
      Cross_Unit_RM_Closure_Consumer_Family_Exception_Finalization,
      Cross_Unit_RM_Closure_Consumer_Family_Renaming_Alias,
      Cross_Unit_RM_Closure_Consumer_Family_Predicate_Invariant,
      Cross_Unit_RM_Closure_Consumer_Family_Dependency,
      Cross_Unit_RM_Closure_Consumer_Family_View_Barrier,
      Cross_Unit_RM_Closure_Consumer_Family_Private_Child,
      Cross_Unit_RM_Closure_Consumer_Family_Separate_Body,
      Cross_Unit_RM_Closure_Consumer_Family_Generic_Body,
      Cross_Unit_RM_Closure_Consumer_Family_Generic_Backmapping,
      Cross_Unit_RM_Closure_Consumer_Family_State_Visibility,
      Cross_Unit_RM_Closure_Consumer_Family_Source_Fingerprint,
      Cross_Unit_RM_Closure_Consumer_Family_Substitution_Fingerprint,
      Cross_Unit_RM_Closure_Consumer_Family_Multiple,
      Cross_Unit_RM_Closure_Consumer_Family_Indeterminate);

   type Cross_Unit_RM_Closure_Consumer_Context is record
      Id                              : Cross_Unit_RM_Closure_Consumer_Id := No_Cross_Unit_RM_Closure_Consumer;
      Kind                            : Cross_Unit_RM_Kind := Prior.Cross_Unit_RM_Completion_Unknown;
      Dependency                      : Cross_Unit_RM_Dependency_State := Prior.RM_Dependency_Unknown;
      Node                            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency_Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                       : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name                   : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                      : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_RM_Row               : Prior.Cross_Unit_RM_Completion_Closure_Id := Prior.No_Cross_Unit_RM_Completion_Closure;
      Cross_Unit_RM_Status            : Prior.Cross_Unit_RM_Completion_Status := Prior.Cross_Unit_RM_Completion_Not_Checked;
      Stabilized_Closure_Row          : Closure.RM_Completion_Stabilized_Closure_Id := Closure.No_RM_Completion_Stabilized_Closure;
      Stabilized_Closure_Status       : Closure.RM_Completion_Stabilized_Closure_Status := Closure.RM_Completion_Stabilized_Closure_Not_Checked;
      Requires_Cross_Unit_RM          : Boolean := True;
      Requires_Stabilized_Closure     : Boolean := True;
      Limited_View_Barrier            : Boolean := False;
      Private_View_Barrier            : Boolean := False;
      Private_Child_Visibility_Blocker : Boolean := False;
      Separate_Body_Blocker           : Boolean := False;
      Generic_Body_Unavailable        : Boolean := False;
      Generic_Backmapping_Blocker     : Boolean := False;
      State_Visibility_Blocker        : Boolean := False;
      Source_Fingerprint              : Natural := 0;
      Expected_Source_Fingerprint     : Natural := 0;
      Substitution_Fingerprint        : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                      : Positive := 1;
      Start_Column                    : Positive := 1;
      End_Line                        : Positive := 1;
      End_Column                      : Positive := 1;
   end record;

   type Cross_Unit_RM_Closure_Consumer_Row is record
      Id                       : Cross_Unit_RM_Closure_Consumer_Id := No_Cross_Unit_RM_Closure_Consumer;
      Context                  : Cross_Unit_RM_Closure_Consumer_Id := No_Cross_Unit_RM_Closure_Consumer;
      Kind                     : Cross_Unit_RM_Kind := Prior.Cross_Unit_RM_Completion_Unknown;
      Dependency               : Cross_Unit_RM_Dependency_State := Prior.RM_Dependency_Unknown;
      Status                   : Cross_Unit_RM_Closure_Consumer_Status := Cross_Unit_RM_Closure_Consumer_Not_Checked;
      Family                   : Cross_Unit_RM_Closure_Consumer_Family := Cross_Unit_RM_Closure_Consumer_Family_None;
      Node                     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name            : Ada.Strings.Unbounded.Unbounded_String;
      State_Name               : Ada.Strings.Unbounded.Unbounded_String;
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

   type Cross_Unit_RM_Closure_Consumer_Context_Model is private;
   type Cross_Unit_RM_Closure_Consumer_Model is private;
   type Cross_Unit_RM_Closure_Consumer_Set is private;

   procedure Clear (Model : in out Cross_Unit_RM_Closure_Consumer_Context_Model);
   procedure Add_Context
     (Model   : in out Cross_Unit_RM_Closure_Consumer_Context_Model;
      Context : Cross_Unit_RM_Closure_Consumer_Context);

   function Build (Contexts : Cross_Unit_RM_Closure_Consumer_Context_Model) return Cross_Unit_RM_Closure_Consumer_Model;
   function Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural;
   function Row_Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural renames Count;
   function Row_At
     (Model : Cross_Unit_RM_Closure_Consumer_Model;
      Index : Positive) return Cross_Unit_RM_Closure_Consumer_Row;

   function Query_Count (Set : Cross_Unit_RM_Closure_Consumer_Set) return Natural;
   function Query_At
     (Set   : Cross_Unit_RM_Closure_Consumer_Set;
      Index : Positive) return Cross_Unit_RM_Closure_Consumer_Row;

   function Count_By_Status
     (Model  : Cross_Unit_RM_Closure_Consumer_Model;
      Status : Cross_Unit_RM_Closure_Consumer_Status) return Natural;
   function Count_By_Family
     (Model  : Cross_Unit_RM_Closure_Consumer_Model;
      Family : Cross_Unit_RM_Closure_Consumer_Family) return Natural;
   function Accepted_Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural;
   function Blocked_Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural;
   function Indeterminate_Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural;
   function Find_By_Node
     (Model : Cross_Unit_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_RM_Closure_Consumer_Set;
   function Find_By_Unit
     (Model : Cross_Unit_RM_Closure_Consumer_Model;
      Unit  : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_RM_Closure_Consumer_Set;
   function Find_By_Source_Fingerprint
     (Model       : Cross_Unit_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Cross_Unit_RM_Closure_Consumer_Set;
   function Stable_Fingerprint (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_RM_Closure_Consumer_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_RM_Closure_Consumer_Row);

   type Cross_Unit_RM_Closure_Consumer_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Cross_Unit_RM_Closure_Consumer_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Cross_Unit_RM_Closure_Consumer_Set is record
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality;
