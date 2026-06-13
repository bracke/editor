with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality is

   --  Pass1288 recheck application for remaining Ada RM edge consumers.
   --
   --  This package consumes Pass1287 bounded remaining-edge recheck
   --  eligibility rows and applies them back into the remaining RM edge
   --  diagnostic/closure boundary.  Remaining-edge conclusions are current
   --  only when the prerequisite recheck chain is eligible now or when the row
   --  is already accepted non-diagnostic semantic evidence.  Rows blocked by
   --  remaining-edge evidence, stabilized closure evidence, source or
   --  substitution fingerprints, multiple prerequisites, explicit recheck
   --  gates, or indeterminate state stay withheld with their original blocker
   --  family preserved.

   package Recheck renames Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality;
   package Diagnostics renames Recheck.Diagnostics;
   package Edge renames Recheck.Edge;

   subtype Remaining_RM_Edge_Application_Diagnostic_Status is Recheck.Remaining_RM_Edge_Recheck_Diagnostic_Status;
   subtype Remaining_RM_Edge_Application_Diagnostic_Family is Recheck.Remaining_RM_Edge_Recheck_Diagnostic_Family;
   subtype Remaining_RM_Edge_Application_Eligibility_Status is Recheck.Remaining_RM_Edge_Recheck_Status;
   subtype Remaining_RM_Edge_Application_Eligibility_Action is Recheck.Remaining_RM_Edge_Recheck_Action;
   subtype Remaining_RM_Edge_Kind is Recheck.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Recheck.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Application_Id is new Natural;
   No_Remaining_RM_Edge_Application : constant Remaining_RM_Edge_Application_Id := 0;

   type Remaining_RM_Edge_Application_Status is
     (Remaining_RM_Edge_Application_Not_Checked,
      Remaining_RM_Edge_Application_Current_Accepted,
      Remaining_RM_Edge_Application_Current_Non_Diagnostic_Evidence,
      Remaining_RM_Edge_Application_Not_Required,
      Remaining_RM_Edge_Application_Withheld_Remaining_Edge,
      Remaining_RM_Edge_Application_Withheld_Stabilized_Closure,
      Remaining_RM_Edge_Application_Withheld_Source_Fingerprint,
      Remaining_RM_Edge_Application_Withheld_Substitution_Fingerprint,
      Remaining_RM_Edge_Application_Withheld_Multiple_Prerequisites,
      Remaining_RM_Edge_Application_Withheld_Recheck_Required,
      Remaining_RM_Edge_Application_Indeterminate);

   type Remaining_RM_Edge_Application_Action is
     (Remaining_RM_Edge_Application_Action_None,
      Remaining_RM_Edge_Application_Action_Expose_Current,
      Remaining_RM_Edge_Application_Action_Keep_Non_Diagnostic_Evidence,
      Remaining_RM_Edge_Application_Action_Skip_Not_Required,
      Remaining_RM_Edge_Application_Action_Withhold_For_Remaining_Edge,
      Remaining_RM_Edge_Application_Action_Withhold_For_Stabilized_Closure,
      Remaining_RM_Edge_Application_Action_Withhold_For_Source_Fingerprint,
      Remaining_RM_Edge_Application_Action_Withhold_For_Substitution_Fingerprint,
      Remaining_RM_Edge_Application_Action_Split_Prerequisites,
      Remaining_RM_Edge_Application_Action_Wait_For_Recheck_Gate,
      Remaining_RM_Edge_Application_Action_Degrade);

   type Remaining_RM_Edge_Application_Row is record
      Id                         : Remaining_RM_Edge_Application_Id := No_Remaining_RM_Edge_Application;
      Eligibility_Id             : Recheck.Remaining_RM_Edge_Recheck_Id := Recheck.No_Remaining_RM_Edge_Recheck;
      Worklist_Item              : Recheck.Worklist.Remaining_RM_Edge_Worklist_Id := Recheck.Worklist.No_Remaining_RM_Edge_Worklist_Item;
      Diagnostic_Row             : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id := Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Diagnostic_Status          : Remaining_RM_Edge_Application_Diagnostic_Status := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Not_Checked;
      Diagnostic_Family          : Remaining_RM_Edge_Application_Diagnostic_Family := Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Remaining_Edge_Kind        : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker     : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
      Eligibility_Status         : Remaining_RM_Edge_Application_Eligibility_Status := Recheck.Remaining_RM_Edge_Recheck_Not_Checked;
      Eligibility_Action         : Remaining_RM_Edge_Application_Eligibility_Action := Recheck.Remaining_RM_Edge_Recheck_Action_None;
      Status                     : Remaining_RM_Edge_Application_Status := Remaining_RM_Edge_Application_Not_Checked;
      Action                     : Remaining_RM_Edge_Application_Action := Remaining_RM_Edge_Application_Action_None;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Current                    : Boolean := False;
      Accepted                   : Boolean := False;
      Withheld                   : Boolean := False;
      Blocks_Downstream          : Boolean := False;
      Priority_Rank              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Substitution_Fingerprint   : Natural := 0;
      Edge_Fingerprint           : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Diagnostic_Fingerprint     : Natural := 0;
      Worklist_Fingerprint       : Natural := 0;
      Eligibility_Fingerprint    : Natural := 0;
      Application_Fingerprint    : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Remaining_RM_Edge_Application_Model is private;
   type Remaining_RM_Edge_Application_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Application_Model);

   function Build
     (Eligibility : Recheck.Remaining_RM_Edge_Recheck_Model)
      return Remaining_RM_Edge_Application_Model;

   function Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Row_Count (Model : Remaining_RM_Edge_Application_Model) return Natural renames Count;
   function Row_At
     (Model : Remaining_RM_Edge_Application_Model;
      Index : Positive) return Remaining_RM_Edge_Application_Row;

   function Query_Count (Set : Remaining_RM_Edge_Application_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Application_Set;
      Index : Positive) return Remaining_RM_Edge_Application_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Application_Model;
      Status : Remaining_RM_Edge_Application_Status) return Remaining_RM_Edge_Application_Set;
   function Query_Action
     (Model  : Remaining_RM_Edge_Application_Model;
      Action : Remaining_RM_Edge_Application_Action) return Remaining_RM_Edge_Application_Set;
   function Query_Family
     (Model  : Remaining_RM_Edge_Application_Model;
      Family : Remaining_RM_Edge_Application_Diagnostic_Family) return Remaining_RM_Edge_Application_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Application_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Application_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Application_Set;
   function Query_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Application_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Application_Set;

   function Count_Status
     (Model  : Remaining_RM_Edge_Application_Model;
      Status : Remaining_RM_Edge_Application_Status) return Natural;
   function Count_Action
     (Model  : Remaining_RM_Edge_Application_Model;
      Action : Remaining_RM_Edge_Application_Action) return Natural;
   function Count_Family
     (Model  : Remaining_RM_Edge_Application_Model;
      Family : Remaining_RM_Edge_Application_Diagnostic_Family) return Natural;

   function Accepted_Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Withheld_Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Current_Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Remaining_Edge_Withheld_Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Stabilized_Closure_Withheld_Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Fingerprint_Withheld_Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Recheck_Required_Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Application_Model) return Natural;
   function Stable_Fingerprint (Model : Remaining_RM_Edge_Application_Model) return Natural;

   function Is_Current (Row : Remaining_RM_Edge_Application_Row) return Boolean;
   function Is_Accepted (Row : Remaining_RM_Edge_Application_Row) return Boolean;
   function Is_Withheld (Row : Remaining_RM_Edge_Application_Row) return Boolean;
   function Blocks_Downstream (Row : Remaining_RM_Edge_Application_Row) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Application_Row);

   type Remaining_RM_Edge_Application_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Application_Model is record
      Rows                         : Row_Vectors.Vector;
      Accepted_Total               : Natural := 0;
      Withheld_Total               : Natural := 0;
      Current_Total                : Natural := 0;
      Remaining_Edge_Withheld_Total : Natural := 0;
      Closure_Withheld_Total       : Natural := 0;
      Fingerprint_Withheld_Total   : Natural := 0;
      Recheck_Required_Total       : Natural := 0;
      Indeterminate_Total          : Natural := 0;
      Stable_Fingerprint_Value     : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality;
