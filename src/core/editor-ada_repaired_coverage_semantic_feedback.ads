with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Coverage_Repair_Gate_Application;
with Editor.Ada_AST_Coverage_Repair_Legality;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Repair_Gated_Diagnostic_Integration;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package Editor.Ada_Repaired_Coverage_Semantic_Feedback is

   --  Pass1152 repaired coverage semantic feedback.
   --
   --  This package feeds repaired parser/AST/metadata/consumer coverage back
   --  into semantic consumers.  It consumes repair-gate application rows and
   --  repair-gated diagnostic integration rows, then produces explicit feedback
   --  rows telling widened legality engines whether a repaired Ada construct is
   --  structurally complete enough to be treated as a confident semantic input.
   --
   --  This is not a projection/status wrapper.  The resulting model exposes a
   --  direct Is_Eligible_For_Engine query used by assignment, return,
   --  conversion, overload, generic, flow, tasking, elaboration, and
   --  representation legality consumers before accepting conclusions that were
   --  previously suppressed by coverage gates.
   --
   --  The model is deterministic, bounded, and snapshot-owned.  It performs no
   --  parsing, no file IO, no save/reload, no dirty-state mutation, no render-
   --  side parsing, no command/keybinding/workspace/render mutation, no
   --  compiler invocation, and no external parser generation.

   package App renames Editor.Ada_AST_Coverage_Repair_Gate_Application;
   package Repair renames Editor.Ada_AST_Coverage_Repair_Legality;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;
   package Diag renames Editor.Ada_Repair_Gated_Diagnostic_Integration;
   package Gates renames Editor.Ada_Semantic_Coverage_Gates;
   package Enforce renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   type Feedback_Row_Id is new Natural;
   No_Feedback_Row : constant Feedback_Row_Id := 0;

   type Feedback_Status is
     (Feedback_Not_Checked,
      Feedback_Construct_Structurally_Restored,
      Feedback_Metadata_Restored,
      Feedback_Consumer_Restored,
      Feedback_Cross_Unit_Metadata_Restored,
      Feedback_Already_Confident,
      Feedback_Eligible_For_Legality,
      Feedback_Cross_Unit_Still_Required,
      Feedback_Original_Semantic_Error_Preserved,
      Feedback_Partial_Repair_Blocker,
      Feedback_Missing_Repair_Blocker,
      Feedback_Repair_Mismatch_Blocker,
      Feedback_Indeterminate,
      Feedback_Stale_Rejected);

   type Feedback_Info is record
      Id                   : Feedback_Row_Id := No_Feedback_Row;
      Application_Id       : App.Application_Row_Id := App.No_Application_Row;
      Diagnostic_Id        : Diag.Repair_Gated_Diagnostic_Id := Diag.No_Repair_Gated_Diagnostic;
      Application_Status   : App.Application_Status := App.Application_Not_Checked;
      Diagnostic_Status    : Diag.Repair_Gated_Diagnostic_Status := Diag.Repair_Gated_Diagnostic_Not_Checked;
      Diagnostic_Action    : Diag.Repair_Gated_Diagnostic_Action := Diag.Repair_Gated_Action_None;
      Feedback             : Feedback_Status := Feedback_Not_Checked;
      Engine               : Enforce.Widened_Legality_Engine := Enforce.Engine_Unknown;
      Conclusion           : Gates.Semantic_Conclusion_Kind := Gates.Conclusion_Unknown;
      Construct            : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer             : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Repair_Kind          : Repair.Repair_Kind := Repair.Repair_Unknown;
      Repair_Status        : Repair.Repair_Status := Repair.Repair_Not_Checked;
      Node                 : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Semantic_Row_Id      : Natural := 0;
      Construct_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Message              : Ada.Strings.Unbounded.Unbounded_String;
      Detail               : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint   : Natural := 0;
      Start_Line           : Positive := 1;
      Start_Column         : Positive := 1;
      End_Line             : Positive := 1;
      End_Column           : Positive := 1;
      Fingerprint          : Natural := 0;
   end record;

   type Feedback_Model is private;
   type Feedback_Set is private;

   function Classify
     (Application_Status : App.Application_Status;
      Diagnostic_Status  : Diag.Repair_Gated_Diagnostic_Status;
      Diagnostic_Action  : Diag.Repair_Gated_Diagnostic_Action;
      Repair_Kind        : Repair.Repair_Kind)
      return Feedback_Status;

   function Build
     (Applications : App.Application_Model;
      Diagnostics  : Diag.Repair_Gated_Diagnostic_Model)
      return Feedback_Model;

   function Row_Count (Model : Feedback_Model) return Natural;
   function Row_At
     (Model : Feedback_Model;
      Index : Positive) return Feedback_Info;

   function First_For_Node
     (Model : Feedback_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Feedback_Info;
   function Rows_For_Status
     (Model  : Feedback_Model;
      Status : Feedback_Status) return Feedback_Set;
   function Rows_For_Engine
     (Model  : Feedback_Model;
      Engine : Enforce.Widened_Legality_Engine) return Feedback_Set;
   function Rows_For_Construct
     (Model     : Feedback_Model;
      Construct : Audit.Ada_Construct_Kind) return Feedback_Set;

   function Set_Count (Set : Feedback_Set) return Natural;
   function Set_At
     (Set   : Feedback_Set;
      Index : Positive) return Feedback_Info;

   function Count_Status
     (Model  : Feedback_Model;
      Status : Feedback_Status) return Natural;
   function Count_Engine
     (Model  : Feedback_Model;
      Engine : Enforce.Widened_Legality_Engine) return Natural;
   function Count_Construct
     (Model     : Feedback_Model;
      Construct : Audit.Ada_Construct_Kind) return Natural;

   function Restored_Count (Model : Feedback_Model) return Natural;
   function Eligible_Count (Model : Feedback_Model) return Natural;
   function Blocker_Count (Model : Feedback_Model) return Natural;
   function Cross_Unit_Required_Count (Model : Feedback_Model) return Natural;
   function Original_Error_Count (Model : Feedback_Model) return Natural;
   function Stale_Rejected_Count (Model : Feedback_Model) return Natural;
   function Indeterminate_Count (Model : Feedback_Model) return Natural;
   function Fingerprint (Model : Feedback_Model) return Natural;

   function Is_Restored (Status : Feedback_Status) return Boolean;
   function Is_Eligible (Info : Feedback_Info) return Boolean;
   function Has_Blocker (Info : Feedback_Info) return Boolean;

   function Is_Eligible_For_Engine
     (Model  : Feedback_Model;
      Node   : Editor.Ada_Syntax_Tree.Node_Id;
      Engine : Enforce.Widened_Legality_Engine) return Boolean;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Feedback_Info);

   type Feedback_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Feedback_Model is record
      Rows              : Row_Vectors.Vector;
      Restored_Total    : Natural := 0;
      Eligible_Total    : Natural := 0;
      Blocker_Total     : Natural := 0;
      Cross_Unit_Total  : Natural := 0;
      Original_Total    : Natural := 0;
      Stale_Total       : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Fingerprint       : Natural := 0;
   end record;

end Editor.Ada_Repaired_Coverage_Semantic_Feedback;
