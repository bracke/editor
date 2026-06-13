with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality is

   --  Pass1242 generic/shared-state final recheck application legality.
   --
   --  This package consumes Pass1241 generic/shared-state final recheck
   --  eligibility rows and applies them back into the generic/shared-state
   --  final diagnostic and closure boundary.  A generic/shared-state
   --  conclusion is current only when its prerequisite recheck chain is
   --  eligible now, source and substitution fingerprints still match, and
   --  generic replay, stabilized shared-state closure, volatile/atomic,
   --  overload/type, representation/freezing, tasking/protected,
   --  elaboration, accessibility, discriminants/variants,
   --  exception/finalization, renaming/aliasing, predicate/invariant, and
   --  dataflow evidence can be trusted together.  Blocker-family identity is
   --  preserved for later convergence and stabilization passes.

   package Recheck renames Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality;

   subtype Generic_Shared_State_Final_Application_Family is
     Recheck.Generic_Shared_State_Final_Recheck_Family;
   subtype Generic_Shared_State_Final_Eligibility_Status is
     Recheck.Generic_Shared_State_Final_Recheck_Status;
   subtype Generic_Shared_State_Final_Eligibility_Action is
     Recheck.Generic_Shared_State_Final_Recheck_Action;

   type Generic_Shared_State_Final_Application_Id is new Natural;
   No_Generic_Shared_State_Final_Application : constant Generic_Shared_State_Final_Application_Id := 0;

   type Generic_Shared_State_Final_Application_Status is
     (Generic_Shared_State_Final_Application_Not_Checked,
      Generic_Shared_State_Final_Application_Current_Accepted,
      Generic_Shared_State_Final_Application_Current_Non_Diagnostic_Evidence,
      Generic_Shared_State_Final_Application_Not_Required,
      Generic_Shared_State_Final_Application_Withheld_Stale_Or_Fingerprint,
      Generic_Shared_State_Final_Application_Withheld_AST_Or_Coverage,
      Generic_Shared_State_Final_Application_Withheld_Cross_Unit,
      Generic_Shared_State_Final_Application_Withheld_Generic_Replay,
      Generic_Shared_State_Final_Application_Withheld_Abstract_Or_Shared_State,
      Generic_Shared_State_Final_Application_Withheld_Volatile_Atomic,
      Generic_Shared_State_Final_Application_Withheld_Overload_Type,
      Generic_Shared_State_Final_Application_Withheld_Representation,
      Generic_Shared_State_Final_Application_Withheld_Tasking_Protected,
      Generic_Shared_State_Final_Application_Withheld_Elaboration,
      Generic_Shared_State_Final_Application_Withheld_Accessibility,
      Generic_Shared_State_Final_Application_Withheld_Discriminant_Variant,
      Generic_Shared_State_Final_Application_Withheld_Exception_Finalization,
      Generic_Shared_State_Final_Application_Withheld_Renaming_Alias,
      Generic_Shared_State_Final_Application_Withheld_Predicate_Invariant,
      Generic_Shared_State_Final_Application_Withheld_Dataflow,
      Generic_Shared_State_Final_Application_Withheld_Multiple_Prerequisites,
      Generic_Shared_State_Final_Application_Indeterminate);

   type Generic_Shared_State_Final_Application_Action is
     (Generic_Shared_State_Final_Application_Action_None,
      Generic_Shared_State_Final_Application_Action_Expose_Current,
      Generic_Shared_State_Final_Application_Action_Keep_Non_Diagnostic_Evidence,
      Generic_Shared_State_Final_Application_Action_Skip_Not_Required,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Fingerprint,
      Generic_Shared_State_Final_Application_Action_Withhold_For_AST_Repair,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Cross_Unit,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Generic_Replay,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Shared_State,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Volatile_Atomic,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Overload_Type,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Representation,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Tasking_Protected,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Elaboration,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Accessibility,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Discriminants,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Exception_Finalization,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Renaming,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Predicate,
      Generic_Shared_State_Final_Application_Action_Withhold_For_Dataflow,
      Generic_Shared_State_Final_Application_Action_Split_Prerequisites,
      Generic_Shared_State_Final_Application_Action_Degrade);

   type Generic_Shared_State_Final_Application_Row is record
      Id                         : Generic_Shared_State_Final_Application_Id := No_Generic_Shared_State_Final_Application;
      Eligibility_Id             : Recheck.Generic_Shared_State_Final_Recheck_Id := Recheck.No_Generic_Shared_State_Final_Recheck;
      Worklist_Item              : Recheck.Worklist.Generic_Shared_State_Final_Worklist_Id := Recheck.Worklist.No_Generic_Shared_State_Final_Worklist_Item;
      Diagnostic_Row             : Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Id := Recheck.Worklist.Diagnostics.No_Generic_Shared_State_Final_Diagnostic;
      Eligibility_Status         : Generic_Shared_State_Final_Eligibility_Status := Recheck.Generic_Shared_State_Final_Recheck_Not_Checked;
      Eligibility_Action         : Generic_Shared_State_Final_Eligibility_Action := Recheck.Generic_Shared_State_Final_Recheck_Action_None;
      Status                     : Generic_Shared_State_Final_Application_Status := Generic_Shared_State_Final_Application_Not_Checked;
      Action                     : Generic_Shared_State_Final_Application_Action := Generic_Shared_State_Final_Application_Action_None;
      Family                     : Generic_Shared_State_Final_Application_Family := Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Unknown;
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

   type Generic_Shared_State_Final_Application_Model is private;
   type Generic_Shared_State_Final_Application_Set is private;

   procedure Clear (Model : in out Generic_Shared_State_Final_Application_Model);

   function Build
     (Eligibility : Recheck.Generic_Shared_State_Final_Recheck_Model)
      return Generic_Shared_State_Final_Application_Model;

   function Count (Model : Generic_Shared_State_Final_Application_Model) return Natural;
   function Row_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural renames Count;
   function Row_At
     (Model : Generic_Shared_State_Final_Application_Model;
      Index : Positive) return Generic_Shared_State_Final_Application_Row;

   function Query_Count (Set : Generic_Shared_State_Final_Application_Set) return Natural;
   function Query_At
     (Set   : Generic_Shared_State_Final_Application_Set;
      Index : Positive) return Generic_Shared_State_Final_Application_Row;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Application_Model;
      Status : Generic_Shared_State_Final_Application_Status)
      return Generic_Shared_State_Final_Application_Set;
   function Query_Action
     (Model  : Generic_Shared_State_Final_Application_Model;
      Action : Generic_Shared_State_Final_Application_Action)
      return Generic_Shared_State_Final_Application_Set;
   function Query_Family
     (Model  : Generic_Shared_State_Final_Application_Model;
      Family : Generic_Shared_State_Final_Application_Family)
      return Generic_Shared_State_Final_Application_Set;
   function Find_By_Node
     (Model : Generic_Shared_State_Final_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Generic_Shared_State_Final_Application_Set;
   function Find_By_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Application_Model;
      Fingerprint : Natural)
      return Generic_Shared_State_Final_Application_Set;
   function Find_By_Substitution_Fingerprint
     (Model       : Generic_Shared_State_Final_Application_Model;
      Fingerprint : Natural)
      return Generic_Shared_State_Final_Application_Set;

   function Count_By_Status
     (Model  : Generic_Shared_State_Final_Application_Model;
      Status : Generic_Shared_State_Final_Application_Status) return Natural;
   function Count_By_Family
     (Model  : Generic_Shared_State_Final_Application_Model;
      Family : Generic_Shared_State_Final_Application_Family) return Natural;

   function Accepted_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural;
   function Withheld_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural;
   function Current_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural;
   function Indeterminate_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural;
   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Application_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Shared_State_Final_Application_Row);

   type Generic_Shared_State_Final_Application_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Generic_Shared_State_Final_Application_Model is record
      Rows                : Row_Vectors.Vector;
      Accepted_Total      : Natural := 0;
      Withheld_Total      : Natural := 0;
      Current_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

end Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality;
