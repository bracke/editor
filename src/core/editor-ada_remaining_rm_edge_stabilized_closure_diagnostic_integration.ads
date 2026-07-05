with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration is

   --  Case 1292 diagnostic integration for stabilized remaining RM edge closure.
   --
   --  This package consumes Case 1291 remaining RM edge stabilized closure rows.
   --  Accepted closure evidence is withheld as current non-diagnostic semantic
   --  evidence.  Stable closure blockers are emitted with their original
   --  blocker family preserved.  Recheck-required rows remain outside trusted
   --  closure and are reported as recheck blockers rather than confident Ada
   --  legality diagnostics.  The model is deterministic, bounded,
   --  snapshot-owned, and side-effect-free.

   package Closure renames Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality;
   package Edge renames Closure.Edge;

   subtype Remaining_RM_Edge_Stabilized_Closure_Id is Closure.Remaining_RM_Edge_Stabilized_Closure_Id;
   subtype Remaining_RM_Edge_Stabilized_Closure_Status is Closure.Remaining_RM_Edge_Stabilized_Closure_Status;
   subtype Remaining_RM_Edge_Stabilized_Closure_Action is Closure.Remaining_RM_Edge_Stabilized_Closure_Action;
   subtype Remaining_RM_Edge_Stabilized_Closure_Family is Closure.Remaining_RM_Edge_Stabilized_Closure_Family;
   subtype Remaining_RM_Edge_Kind is Closure.Remaining_RM_Edge_Kind;
   subtype Remaining_RM_Edge_Blocker_Family is Closure.Remaining_RM_Edge_Blocker_Family;

   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Id is new Natural;
   No_Remaining_RM_Edge_Stabilized_Closure_Diagnostic : constant Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Id := 0;

   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family is
     (Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Accepted,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Remaining_Edge,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Stabilized_Closure,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Source_Fingerprint,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Substitution_Fingerprint,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Multiple,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Unknown);

   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity is
     (Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Info,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Warning,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Error);

   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status is
     (Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Current,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Withheld_Accepted_Not_Required,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Remaining_Edge_Blocker,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Stabilized_Closure_Blocker,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Source_Fingerprint_Mismatch,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Substitution_Fingerprint_Mismatch,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Multiple_Prerequisites,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required,
      Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate);

   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row is record
      Id                        : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Id := No_Remaining_RM_Edge_Stabilized_Closure_Diagnostic;
      Closure_Row               : Remaining_RM_Edge_Stabilized_Closure_Id := Closure.No_Remaining_RM_Edge_Stabilized_Closure;
      Stabilization_Id          : Closure.Gate.Remaining_RM_Edge_Stabilization_Gate_Id := Closure.Gate.No_Remaining_RM_Edge_Stabilization_Gate;
      Convergence_Id            : Closure.Gate.Conv.Remaining_RM_Edge_Convergence_Id := Closure.Gate.Conv.No_Remaining_RM_Edge_Convergence;
      Application_Id            : Closure.Gate.Conv.Apply.Remaining_RM_Edge_Application_Id := Closure.Gate.Conv.Apply.No_Remaining_RM_Edge_Application;
      Eligibility_Id            : Closure.Gate.Conv.Apply.Recheck.Remaining_RM_Edge_Recheck_Id := Closure.Gate.Conv.Apply.Recheck.No_Remaining_RM_Edge_Recheck;
      Worklist_Item             : Closure.Gate.Conv.Apply.Recheck.Worklist.Remaining_RM_Edge_Worklist_Id := Closure.Gate.Conv.Apply.Recheck.Worklist.No_Remaining_RM_Edge_Worklist_Item;
      Prior_Diagnostic_Row      : Closure.Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id := Closure.Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
      Closure_Status            : Remaining_RM_Edge_Stabilized_Closure_Status := Closure.Remaining_RM_Edge_Stabilized_Closure_Not_Checked;
      Closure_Action            : Remaining_RM_Edge_Stabilized_Closure_Action := Closure.Remaining_RM_Edge_Stabilized_Closure_Action_None;
      Closure_Family            : Remaining_RM_Edge_Stabilized_Closure_Family := Closure.Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Unknown;
      Status                    : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status := Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked;
      Family                    : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family := Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Unknown;
      Severity                  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity := Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Warning;
      Remaining_Edge_Kind       : Remaining_RM_Edge_Kind := Edge.Remaining_RM_Edge_Unknown;
      Remaining_Edge_Blocker    : Remaining_RM_Edge_Blocker_Family := Edge.Remaining_RM_Edge_Blocker_None;
      Node                      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message                   : Ada.Strings.Unbounded.Unbounded_String;
      Detail                    : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint        : Natural := 0;
      Substitution_Fingerprint  : Natural := 0;
      Edge_Fingerprint          : Natural := 0;
      Consumer_Closure_Fingerprint : Natural := 0;
      Prior_Diagnostic_Fingerprint : Natural := 0;
      Worklist_Fingerprint      : Natural := 0;
      Eligibility_Fingerprint   : Natural := 0;
      Application_Fingerprint   : Natural := 0;
      Convergence_Fingerprint   : Natural := 0;
      Stabilization_Fingerprint : Natural := 0;
      Closure_Fingerprint       : Natural := 0;
      Diagnostic_Fingerprint    : Natural := 0;
      Emitted                   : Boolean := False;
      Withheld_Current          : Boolean := False;
      Requires_Recheck          : Boolean := False;
      Blocks_Downstream         : Boolean := False;
      Start_Line                : Positive := 1;
      Start_Column              : Positive := 1;
      End_Line                  : Positive := 1;
      End_Column                : Positive := 1;
   end record;

   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model is private;
   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set is private;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model);

   function Build
     (Closures : Closure.Remaining_RM_Edge_Stabilized_Closure_Model)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;

   function Row_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;
   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set) return Natural;
   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   function Query_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   function Query_Closure_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   function Query_Node
     (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;
   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set;

   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status) return Natural;
   function Count_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family) return Natural;
   function Count_Closure_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family) return Natural;
   function Error_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;
   function Info_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;
   function Emitted_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;
   function Withheld_Current_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;
   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;
   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model) return Natural;

   function Is_Emitted (Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status) return Boolean;
   function Is_Withheld_Current (Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row);

   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model is record
      Rows                   : Row_Vectors.Vector;
      Error_Total            : Natural := 0;
      Warning_Total          : Natural := 0;
      Info_Total             : Natural := 0;
      Emitted_Total          : Natural := 0;
      Withheld_Current_Total : Natural := 0;
      Recheck_Total          : Natural := 0;
      Indeterminate_Total    : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Integration;
