with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
with Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality;
with Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_RM_Integrated_Semantic_Closure_Legality is

   --  Case 1296 final RM-integrated semantic closure legality.
   --
   --  This package creates the first unified trusted closure boundary after the
   --  RM-completion, direct-consumer, remaining-RM-edge, and coverage-proven AST
   --  repair chains have each been stabilized.  A row is accepted only when all
   --  required stabilized evidence is present, current or not-required, and has
   --  matching source/substitution fingerprints.  Otherwise the original
   --  prerequisite blocker family is preserved so later diagnostic, remediation,
   --  and recheck passes cannot flatten or bypass the real semantic cause.

   package Final_Base renames Editor.Ada_Final_Semantic_Stabilized_Closure_Legality;
   package RM_Completion renames Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality;
   package Consumers renames Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
   package Remaining_Edge renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality;
   package AST_Repair renames Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality;

   subtype Final_Base_Row is Final_Base.Final_Stabilized_Closure_Row;
   subtype RM_Completion_Row is RM_Completion.RM_Completion_Stabilized_Closure_Row;
   subtype Direct_Consumer_Row is Consumers.RM_Closure_Consumer_Stabilized_Closure_Row;
   subtype Remaining_Edge_Row is Remaining_Edge.Remaining_RM_Edge_Stabilized_Closure_Row;
   subtype AST_Repair_Row is AST_Repair.Remaining_RM_Edge_AST_Repair_Row;

   type Final_RM_Integrated_Closure_Id is new Natural;
   No_Final_RM_Integrated_Closure : constant Final_RM_Integrated_Closure_Id := 0;

   type Final_RM_Integrated_Blocker_Family is
     (Final_RM_Integrated_Blocker_None,
      Final_RM_Integrated_Blocker_Missing_Final_Stabilized_Closure,
      Final_RM_Integrated_Blocker_Final_Stabilized_Closure,
      Final_RM_Integrated_Blocker_Missing_RM_Completion_Closure,
      Final_RM_Integrated_Blocker_RM_Completion_Closure,
      Final_RM_Integrated_Blocker_Missing_Direct_Consumer_Closure,
      Final_RM_Integrated_Blocker_Direct_Consumer_Closure,
      Final_RM_Integrated_Blocker_Missing_Remaining_Edge_Closure,
      Final_RM_Integrated_Blocker_Remaining_Edge_Closure,
      Final_RM_Integrated_Blocker_Missing_AST_Repair,
      Final_RM_Integrated_Blocker_AST_Repair,
      Final_RM_Integrated_Blocker_Abstract_Refined_State,
      Final_RM_Integrated_Blocker_Volatile_Atomic_Shared_State,
      Final_RM_Integrated_Blocker_Cross_Unit,
      Final_RM_Integrated_Blocker_Generic_Shared_State,
      Final_RM_Integrated_Blocker_Overload_Type,
      Final_RM_Integrated_Blocker_Representation_Freezing,
      Final_RM_Integrated_Blocker_Tasking_Protected,
      Final_RM_Integrated_Blocker_Elaboration,
      Final_RM_Integrated_Blocker_Accessibility,
      Final_RM_Integrated_Blocker_Exception_Finalization,
      Final_RM_Integrated_Blocker_Predicate_Invariant,
      Final_RM_Integrated_Blocker_Dataflow,
      Final_RM_Integrated_Blocker_Source_Fingerprint,
      Final_RM_Integrated_Blocker_Substitution_Fingerprint,
      Final_RM_Integrated_Blocker_Multiple_Prerequisites,
      Final_RM_Integrated_Blocker_Indeterminate,
      Final_RM_Integrated_Blocker_Recheck_Required);

   type Final_RM_Integrated_Closure_Status is
     (Final_RM_Integrated_Closure_Not_Checked,
      Final_RM_Integrated_Closure_Accepted_Current,
      Final_RM_Integrated_Closure_Accepted_Not_Required,
      Final_RM_Integrated_Closure_Blocker_Final_Stabilized_Closure,
      Final_RM_Integrated_Closure_Blocker_RM_Completion_Closure,
      Final_RM_Integrated_Closure_Blocker_Direct_Consumer_Closure,
      Final_RM_Integrated_Closure_Blocker_Remaining_Edge_Closure,
      Final_RM_Integrated_Closure_Blocker_AST_Repair,
      Final_RM_Integrated_Closure_Blocker_Abstract_Refined_State,
      Final_RM_Integrated_Closure_Blocker_Volatile_Atomic_Shared_State,
      Final_RM_Integrated_Closure_Blocker_Cross_Unit,
      Final_RM_Integrated_Closure_Blocker_Generic_Shared_State,
      Final_RM_Integrated_Closure_Blocker_Overload_Type,
      Final_RM_Integrated_Closure_Blocker_Representation_Freezing,
      Final_RM_Integrated_Closure_Blocker_Tasking_Protected,
      Final_RM_Integrated_Closure_Blocker_Elaboration,
      Final_RM_Integrated_Closure_Blocker_Accessibility,
      Final_RM_Integrated_Closure_Blocker_Exception_Finalization,
      Final_RM_Integrated_Closure_Blocker_Predicate_Invariant,
      Final_RM_Integrated_Closure_Blocker_Dataflow,
      Final_RM_Integrated_Closure_Blocker_Source_Fingerprint,
      Final_RM_Integrated_Closure_Blocker_Substitution_Fingerprint,
      Final_RM_Integrated_Closure_Blocker_Multiple_Prerequisites,
      Final_RM_Integrated_Closure_Indeterminate,
      Final_RM_Integrated_Closure_Recheck_Required);

   type Final_RM_Integrated_Closure_Action is
     (Final_RM_Integrated_Closure_Action_None,
      Final_RM_Integrated_Closure_Action_Accept_Current,
      Final_RM_Integrated_Closure_Action_Accept_Not_Required,
      Final_RM_Integrated_Closure_Action_Block_Final_Base,
      Final_RM_Integrated_Closure_Action_Block_RM_Completion,
      Final_RM_Integrated_Closure_Action_Block_Direct_Consumer,
      Final_RM_Integrated_Closure_Action_Block_Remaining_Edge,
      Final_RM_Integrated_Closure_Action_Block_AST_Repair,
      Final_RM_Integrated_Closure_Action_Block_State,
      Final_RM_Integrated_Closure_Action_Block_Effects,
      Final_RM_Integrated_Closure_Action_Block_Cross_Unit,
      Final_RM_Integrated_Closure_Action_Block_Generic,
      Final_RM_Integrated_Closure_Action_Block_Overload,
      Final_RM_Integrated_Closure_Action_Block_Representation,
      Final_RM_Integrated_Closure_Action_Block_Tasking,
      Final_RM_Integrated_Closure_Action_Block_Elaboration,
      Final_RM_Integrated_Closure_Action_Block_Accessibility,
      Final_RM_Integrated_Closure_Action_Block_Exception,
      Final_RM_Integrated_Closure_Action_Block_Predicate,
      Final_RM_Integrated_Closure_Action_Block_Dataflow,
      Final_RM_Integrated_Closure_Action_Block_Source_Fingerprint,
      Final_RM_Integrated_Closure_Action_Block_Substitution_Fingerprint,
      Final_RM_Integrated_Closure_Action_Split_Prerequisites,
      Final_RM_Integrated_Closure_Action_Degrade,
      Final_RM_Integrated_Closure_Action_Recheck);

   type Final_RM_Integrated_Closure_Context is record
      Id                         : Final_RM_Integrated_Closure_Id := No_Final_RM_Integrated_Closure;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Has_Final_Stabilized_Closure : Boolean := False;
      Final_Stabilized_Closure   : Final_Base_Row;
      Has_RM_Completion_Closure  : Boolean := False;
      RM_Completion_Closure      : RM_Completion_Row;
      Has_Direct_Consumer_Closure : Boolean := False;
      Direct_Consumer_Closure    : Direct_Consumer_Row;
      Has_Remaining_Edge_Closure : Boolean := False;
      Remaining_Edge_Closure     : Remaining_Edge_Row;
      Requires_AST_Repair_Evidence : Boolean := False;
      Has_AST_Repair_Evidence    : Boolean := False;
      AST_Repair_Evidence        : AST_Repair_Row;
      Has_Abstract_Refined_State_Evidence : Boolean := True;
      Abstract_Refined_State_Accepted     : Boolean := True;
      Has_Volatile_Atomic_Shared_State_Evidence : Boolean := True;
      Volatile_Atomic_Shared_State_Accepted     : Boolean := True;
      Has_Cross_Unit_Evidence    : Boolean := True;
      Cross_Unit_Accepted        : Boolean := True;
      Has_Generic_Shared_State_Evidence : Boolean := True;
      Generic_Shared_State_Accepted     : Boolean := True;
      Has_Overload_Type_Evidence : Boolean := True;
      Overload_Type_Accepted     : Boolean := True;
      Has_Representation_Evidence : Boolean := True;
      Representation_Accepted    : Boolean := True;
      Has_Tasking_Evidence       : Boolean := True;
      Tasking_Accepted           : Boolean := True;
      Has_Elaboration_Evidence   : Boolean := True;
      Elaboration_Accepted       : Boolean := True;
      Has_Accessibility_Evidence : Boolean := True;
      Accessibility_Accepted     : Boolean := True;
      Has_Exception_Finalization_Evidence : Boolean := True;
      Exception_Finalization_Accepted     : Boolean := True;
      Has_Predicate_Evidence     : Boolean := True;
      Predicate_Accepted         : Boolean := True;
      Has_Dataflow_Evidence      : Boolean := True;
      Dataflow_Accepted          : Boolean := True;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Final_RM_Integrated_Closure_Row is record
      Id                         : Final_RM_Integrated_Closure_Id := No_Final_RM_Integrated_Closure;
      Context                    : Final_RM_Integrated_Closure_Id := No_Final_RM_Integrated_Closure;
      Status                     : Final_RM_Integrated_Closure_Status := Final_RM_Integrated_Closure_Not_Checked;
      Action                     : Final_RM_Integrated_Closure_Action := Final_RM_Integrated_Closure_Action_None;
      Blocker_Family             : Final_RM_Integrated_Blocker_Family := Final_RM_Integrated_Blocker_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Construct_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Accepted                   : Boolean := False;
      Current                    : Boolean := False;
      Blocked                    : Boolean := False;
      Recheck_Required           : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Has_Final_Stabilized_Closure : Boolean := False;
      Has_RM_Completion_Closure  : Boolean := False;
      Has_Direct_Consumer_Closure : Boolean := False;
      Has_Remaining_Edge_Closure : Boolean := False;
      Has_AST_Repair_Evidence    : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Final_Closure_Fingerprint  : Natural := 0;
      RM_Completion_Fingerprint  : Natural := 0;
      Direct_Consumer_Fingerprint : Natural := 0;
      Remaining_Edge_Fingerprint : Natural := 0;
      AST_Repair_Fingerprint     : Natural := 0;
      Integrated_Fingerprint     : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Final_RM_Integrated_Closure_Context_Model is private;
   type Final_RM_Integrated_Closure_Model is private;
   type Final_RM_Integrated_Closure_Set is private;

   procedure Clear (Model : in out Final_RM_Integrated_Closure_Context_Model);
   procedure Add_Context
     (Model   : in out Final_RM_Integrated_Closure_Context_Model;
      Context : Final_RM_Integrated_Closure_Context);

   function Context_Count (Model : Final_RM_Integrated_Closure_Context_Model) return Natural;
   function Context_At
     (Model : Final_RM_Integrated_Closure_Context_Model;
      Index : Positive) return Final_RM_Integrated_Closure_Context;

   function Build
     (Contexts : Final_RM_Integrated_Closure_Context_Model)
      return Final_RM_Integrated_Closure_Model;

   function Count (Model : Final_RM_Integrated_Closure_Model) return Natural;
   function Row_Count (Model : Final_RM_Integrated_Closure_Model) return Natural renames Count;
   function Row_At
     (Model : Final_RM_Integrated_Closure_Model;
      Index : Positive) return Final_RM_Integrated_Closure_Row;

   function Query_Count (Set : Final_RM_Integrated_Closure_Set) return Natural;
   function Query_At
     (Set   : Final_RM_Integrated_Closure_Set;
      Index : Positive) return Final_RM_Integrated_Closure_Row;

   function Query_Status
     (Model  : Final_RM_Integrated_Closure_Model;
      Status : Final_RM_Integrated_Closure_Status) return Final_RM_Integrated_Closure_Set;
   function Query_Blocker_Family
     (Model  : Final_RM_Integrated_Closure_Model;
      Family : Final_RM_Integrated_Blocker_Family) return Final_RM_Integrated_Closure_Set;
   function Query_Node
     (Model : Final_RM_Integrated_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_RM_Integrated_Closure_Set;

   function Count_By_Status
     (Model  : Final_RM_Integrated_Closure_Model;
      Status : Final_RM_Integrated_Closure_Status) return Natural;
   function Count_By_Blocker_Family
     (Model  : Final_RM_Integrated_Closure_Model;
      Family : Final_RM_Integrated_Blocker_Family) return Natural;

   function Accepted_Count (Model : Final_RM_Integrated_Closure_Model) return Natural;
   function Blocked_Count (Model : Final_RM_Integrated_Closure_Model) return Natural;
   function Recheck_Required_Count (Model : Final_RM_Integrated_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Final_RM_Integrated_Closure_Model) return Natural;
   function Stable_Fingerprint (Model : Final_RM_Integrated_Closure_Model) return Natural;

   function Is_Accepted (Status : Final_RM_Integrated_Closure_Status) return Boolean;
   function Is_Blocked (Status : Final_RM_Integrated_Closure_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_RM_Integrated_Closure_Context);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_RM_Integrated_Closure_Row);

   type Final_RM_Integrated_Closure_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_RM_Integrated_Closure_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Blocked_Total       : Natural := 0;
      Recheck_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Final_RM_Integrated_Closure_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Final_RM_Integrated_Semantic_Closure_Legality;
