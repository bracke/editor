with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality is

   --  Case 1260 RM-completed generic/shared-state recheck application legality.
   --
   --  This package consumes Case 1259 RM-completed generic/shared-state recheck
   --  eligibility rows and applies them back into the RM-completed generic/shared-state
   --  final diagnostic and closure boundary.  A RM-completed generic/shared-state
   --  conclusion is current only when its prerequisite recheck chain is
   --  eligible now, source and substitution fingerprints still match, and
   --  generic substitution, prior dataflow, volatile/atomic,
   --  overload/type, representation/freezing, tasking/protected,
   --  elaboration, accessibility, discriminants/variants,
   --  exception/finalization, renaming/aliasing, predicate/invariant, and
   --  dataflow evidence can be trusted together.  Blocker-family identity is
   --  preserved for later convergence and stabilization passes.

   package Recheck renames Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;

   subtype RM_Completion_Application_Family is
     Recheck.RM_Completion_Recheck_Family;
   subtype RM_Completion_Eligibility_Status is
     Recheck.RM_Completion_Recheck_Status;
   subtype RM_Completion_Eligibility_Action is
     Recheck.RM_Completion_Recheck_Action;

   type RM_Completion_Application_Id is new Natural;
   No_RM_Completion_Application : constant RM_Completion_Application_Id := 0;

   type RM_Completion_Application_Status is
     (RM_Completion_Application_Not_Checked,
      RM_Completion_Application_Current_Accepted,
      RM_Completion_Application_Current_Non_Diagnostic_Evidence,
      RM_Completion_Application_Not_Required,
      RM_Completion_Application_Withheld_Stale_Or_Fingerprint,
      RM_Completion_Application_Withheld_AST_Or_Coverage,
      RM_Completion_Application_Withheld_Cross_Unit,
      RM_Completion_Application_Withheld_Generic_Substitution,
      RM_Completion_Application_Withheld_Prior_Dataflow,
      RM_Completion_Application_Withheld_Volatile_Atomic,
      RM_Completion_Application_Withheld_Overload_Type,
      RM_Completion_Application_Withheld_Representation,
      RM_Completion_Application_Withheld_Tasking_Protected,
      RM_Completion_Application_Withheld_Elaboration,
      RM_Completion_Application_Withheld_Accessibility,
      RM_Completion_Application_Withheld_Discriminant_Variant,
      RM_Completion_Application_Withheld_Exception_Finalization,
      RM_Completion_Application_Withheld_Renaming_Alias,
      RM_Completion_Application_Withheld_Predicate_Invariant,
      RM_Completion_Application_Withheld_Dataflow,
      RM_Completion_Application_Withheld_Multiple_Prerequisites,
      RM_Completion_Application_Indeterminate);

   type RM_Completion_Application_Action is
     (RM_Completion_Application_Action_None,
      RM_Completion_Application_Action_Expose_Current,
      RM_Completion_Application_Action_Keep_Non_Diagnostic_Evidence,
      RM_Completion_Application_Action_Skip_Not_Required,
      RM_Completion_Application_Action_Withhold_For_Fingerprint,
      RM_Completion_Application_Action_Withhold_For_AST_Repair,
      RM_Completion_Application_Action_Withhold_For_Cross_Unit,
      RM_Completion_Application_Action_Withhold_For_Generic_Substitution,
      RM_Completion_Application_Action_Withhold_For_Prior_Dataflow,
      RM_Completion_Application_Action_Withhold_For_Volatile_Atomic,
      RM_Completion_Application_Action_Withhold_For_Overload_Type,
      RM_Completion_Application_Action_Withhold_For_Representation,
      RM_Completion_Application_Action_Withhold_For_Tasking_Protected,
      RM_Completion_Application_Action_Withhold_For_Elaboration,
      RM_Completion_Application_Action_Withhold_For_Accessibility,
      RM_Completion_Application_Action_Withhold_For_Discriminants,
      RM_Completion_Application_Action_Withhold_For_Exception_Finalization,
      RM_Completion_Application_Action_Withhold_For_Renaming,
      RM_Completion_Application_Action_Withhold_For_Predicate,
      RM_Completion_Application_Action_Withhold_For_Dataflow,
      RM_Completion_Application_Action_Split_Prerequisites,
      RM_Completion_Application_Action_Degrade);

   type RM_Completion_Application_Row is record
      Id                         : RM_Completion_Application_Id := No_RM_Completion_Application;
      Eligibility_Id             : Recheck.RM_Completion_Recheck_Id := Recheck.No_RM_Completion_Recheck;
      Worklist_Item              : Recheck.Worklist.RM_Completion_Worklist_Id := Recheck.Worklist.No_RM_Completion_Worklist_Item;
      Diagnostic_Row             : Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Id := Recheck.Worklist.Diagnostics.No_RM_Completion_Diagnostic;
      Eligibility_Status         : RM_Completion_Eligibility_Status := Recheck.RM_Completion_Recheck_Not_Checked;
      Eligibility_Action         : RM_Completion_Eligibility_Action := Recheck.RM_Completion_Recheck_Action_None;
      Status                     : RM_Completion_Application_Status := RM_Completion_Application_Not_Checked;
      Action                     : RM_Completion_Application_Action := RM_Completion_Application_Action_None;
      Family                     : RM_Completion_Application_Family := Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Operation_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Unit_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Instance_Name              : Ada.Strings.Unbounded.Unbounded_String;
      State_Name                 : Ada.Strings.Unbounded.Unbounded_String;
      Current                    : Boolean := False;
      Accepted                   : Boolean := False;
      Withheld                   : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type RM_Completion_Application_Model is private;
   type RM_Completion_Application_Set is private;

   procedure Clear (Model : in out RM_Completion_Application_Model);

   function Build
     (Eligibility : Recheck.RM_Completion_Recheck_Model)
      return RM_Completion_Application_Model;

   function Count (Model : RM_Completion_Application_Model) return Natural;
   function Row_Count (Model : RM_Completion_Application_Model) return Natural renames Count;
   function Row_At
     (Model : RM_Completion_Application_Model;
      Index : Positive) return RM_Completion_Application_Row;

   function Query_Count (Set : RM_Completion_Application_Set) return Natural;
   function Query_At
     (Set   : RM_Completion_Application_Set;
      Index : Positive) return RM_Completion_Application_Row;

   function Query_Status
     (Model  : RM_Completion_Application_Model;
      Status : RM_Completion_Application_Status)
      return RM_Completion_Application_Set;
   function Query_Action
     (Model  : RM_Completion_Application_Model;
      Action : RM_Completion_Application_Action)
      return RM_Completion_Application_Set;
   function Query_Family
     (Model  : RM_Completion_Application_Model;
      Family : RM_Completion_Application_Family)
      return RM_Completion_Application_Set;
   function Find_By_Node
     (Model : RM_Completion_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Completion_Application_Set;
   function Find_By_Source_Fingerprint
     (Model       : RM_Completion_Application_Model;
      Fingerprint : Natural)
      return RM_Completion_Application_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : RM_Completion_Application_Model;
      Fingerprint : Natural)
      return RM_Completion_Application_Set;

   function Count_By_Status
     (Model  : RM_Completion_Application_Model;
      Status : RM_Completion_Application_Status) return Natural;
   function Count_By_Family
     (Model  : RM_Completion_Application_Model;
      Family : RM_Completion_Application_Family) return Natural;

   function Accepted_Count (Model : RM_Completion_Application_Model) return Natural;
   function Withheld_Count (Model : RM_Completion_Application_Model) return Natural;
   function Current_Count (Model : RM_Completion_Application_Model) return Natural;
   function Indeterminate_Count (Model : RM_Completion_Application_Model) return Natural;
   function Stable_Fingerprint (Model : RM_Completion_Application_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => RM_Completion_Application_Row);

   type RM_Completion_Application_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type RM_Completion_Application_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Withheld_Total      : Natural := 0;
      Current_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality;
