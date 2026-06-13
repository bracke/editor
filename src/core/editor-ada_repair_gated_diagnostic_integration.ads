with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Coverage_Repair_Gate_Application;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Repair_Gated_Diagnostic_Integration is

   --  Pass1150 diagnostic integration for repaired coverage gates.
   --
   --  Pass1149 feeds repair-applied coverage-gate results back into integrated
   --  semantic closure.  This package carries that restored or still-blocking
   --  closure state into a deterministic diagnostic-integration model so
   --  repaired constructs regain confident non-diagnostic semantic closure,
   --  while unrepaired gaps, original semantic errors, dependency failures, and
   --  indeterminate repairs remain visible to the unified diagnostic path.
   --
   --  The model is snapshot-owned and bounded.  It performs no parsing, no file
   --  IO, no save/reload, no dirty-state mutation, no render-side parsing, no
   --  command/keybinding/workspace/render mutation, no compiler invocation, and
   --  no external parser generation.

   package App renames Editor.Ada_AST_Coverage_Repair_Gate_Application;
   package Closure renames Editor.Ada_Integrated_Semantic_Closure;
   package Feed renames Editor.Ada_Semantic_Diagnostic_Feed;

   type Repair_Gated_Diagnostic_Id is new Natural;
   No_Repair_Gated_Diagnostic : constant Repair_Gated_Diagnostic_Id := 0;

   type Repair_Gated_Diagnostic_Status is
     (Repair_Gated_Diagnostic_Not_Checked,
      Repair_Gated_Diagnostic_Restored_Confident,
      Repair_Gated_Diagnostic_Already_Confident,
      Repair_Gated_Diagnostic_Blocker,
      Repair_Gated_Diagnostic_Dependency_Failure,
      Repair_Gated_Diagnostic_Indeterminate,
      Repair_Gated_Diagnostic_Original_Error,
      Repair_Gated_Diagnostic_Stale_Rejected);

   type Repair_Gated_Diagnostic_Action is
     (Repair_Gated_Action_None,
      Repair_Gated_Action_Withhold_Diagnostic,
      Repair_Gated_Action_Emit_Error,
      Repair_Gated_Action_Emit_Warning,
      Repair_Gated_Action_Require_Cross_Unit_Closure,
      Repair_Gated_Action_Preserve_Original_Error,
      Repair_Gated_Action_Reject_Stale_Input);

   type Repair_Gated_Diagnostic_Info is record
      Id                 : Repair_Gated_Diagnostic_Id := No_Repair_Gated_Diagnostic;
      Application_Id     : App.Application_Row_Id := App.No_Application_Row;
      Closure_Id         : Closure.Integrated_Closure_Id := Closure.No_Integrated_Closure;
      Application_Status : App.Application_Status := App.Application_Not_Checked;
      Closure_Status     : Closure.Integrated_Closure_Status := Closure.Integrated_Closure_Not_Checked;
      Blocker            : Closure.Closure_Blocker_Family := Closure.Closure_Blocker_None;
      Dependency         : Closure.Closure_Dependency_State := Closure.Dependency_Unknown;
      Status             : Repair_Gated_Diagnostic_Status := Repair_Gated_Diagnostic_Not_Checked;
      Action             : Repair_Gated_Diagnostic_Action := Repair_Gated_Action_None;
      Severity           : Feed.Semantic_Diagnostic_Feed_Severity := Feed.Semantic_Diagnostic_Feed_Info;
      Node               : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Message            : Ada.Strings.Unbounded.Unbounded_String;
      Detail             : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint : Natural := 0;
      Start_Line         : Positive := 1;
      Start_Column       : Positive := 1;
      End_Line           : Positive := 1;
      End_Column         : Positive := 1;
      Fingerprint        : Natural := 0;
   end record;

   type Repair_Gated_Diagnostic_Model is private;
   type Repair_Gated_Diagnostic_Set is private;

   procedure Clear (Model : in out Repair_Gated_Diagnostic_Model);

   function Build
     (Applications : App.Application_Model;
      Closure_Model : Closure.Integrated_Closure_Model;
      Closure_Input_Current : Boolean := True;
      Closure_Rejected_Count : Natural := 0)
      return Repair_Gated_Diagnostic_Model;

   function Row_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Row_At
     (Model : Repair_Gated_Diagnostic_Model;
      Index : Positive) return Repair_Gated_Diagnostic_Info;

   function Rows_For_Status
     (Model  : Repair_Gated_Diagnostic_Model;
      Status : Repair_Gated_Diagnostic_Status) return Repair_Gated_Diagnostic_Set;
   function Rows_For_Action
     (Model  : Repair_Gated_Diagnostic_Model;
      Action : Repair_Gated_Diagnostic_Action) return Repair_Gated_Diagnostic_Set;
   function First_For_Node
     (Model : Repair_Gated_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Repair_Gated_Diagnostic_Info;

   function Set_Count (Set : Repair_Gated_Diagnostic_Set) return Natural;
   function Set_At
     (Set   : Repair_Gated_Diagnostic_Set;
      Index : Positive) return Repair_Gated_Diagnostic_Info;

   function Count_Status
     (Model  : Repair_Gated_Diagnostic_Model;
      Status : Repair_Gated_Diagnostic_Status) return Natural;
   function Count_Action
     (Model  : Repair_Gated_Diagnostic_Model;
      Action : Repair_Gated_Diagnostic_Action) return Natural;

   function Restored_Confident_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Emitted_Diagnostic_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Error_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Withheld_Diagnostic_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Dependency_Failure_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Original_Error_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Rejected_Stale_Count (Model : Repair_Gated_Diagnostic_Model) return Natural;
   function Fingerprint (Model : Repair_Gated_Diagnostic_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Repair_Gated_Diagnostic_Info);

   type Repair_Gated_Diagnostic_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Repair_Gated_Diagnostic_Model is record
      Rows                 : Row_Vectors.Vector;
      Restored_Total       : Natural := 0;
      Emitted_Total        : Natural := 0;
      Error_Total          : Natural := 0;
      Warning_Total        : Natural := 0;
      Withheld_Total       : Natural := 0;
      Dependency_Total     : Natural := 0;
      Original_Error_Total : Natural := 0;
      Rejected_Total       : Natural := 0;
      Fingerprint          : Natural := 0;
   end record;

end Editor.Ada_Repair_Gated_Diagnostic_Integration;
