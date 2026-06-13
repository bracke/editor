with Ada.Containers.Vectors;
with Editor.Ada_Final_Semantic_Blocker_Remediation_Order;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Remediation_Gate_Legality is

   --  Pass1200 final semantic remediation gate legality.
   --
   --  This package consumes Pass1199 final semantic blocker remediation order
   --  and turns it into a deterministic semantic gate model.  The gate model is
   --  deliberately not a projection layer: it decides whether downstream
   --  semantic conclusions may remain confident, must be withheld until a
   --  prerequisite semantic blocker is repaired, must preserve an already-known
   --  semantic error, or must degrade to indeterminate.  It preserves blocker
   --  family, remediation priority, source node/span/fingerprints, dependency
   --  order, and downstream unlock pressure so stale evidence, AST/coverage
   --  repair, cross-unit closure, view barriers, generic replay/backmapping,
   --  overload/type evidence, representation/freezing, flow/contract proof,
   --  tasking/protected effects, elaboration, accessibility/lifetime, and
   --  discriminant/variant evidence cannot be bypassed by later consumers.
   --  The model is deterministic, bounded, snapshot-owned, and performs no
   --  parsing, file IO, save/reload, dirty-state mutation, command/keybinding,
   --  workspace/render mutation, LSP use, compiler invocation, or external
   --  parser generation.

   package Remediation renames Editor.Ada_Final_Semantic_Blocker_Remediation_Order;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Remediation_Id is Remediation.Final_Remediation_Id;
   subtype Final_Remediation_Status is Remediation.Final_Remediation_Status;
   subtype Final_Remediation_Priority is Remediation.Final_Remediation_Priority;

   type Final_Gate_Id is new Natural;
   No_Final_Gate : constant Final_Gate_Id := 0;

   type Final_Gate_Status is
     (Final_Gate_Not_Checked,
      Final_Gate_Confident_Legal,
      Final_Gate_Withheld_Stale_Input,
      Final_Gate_Withheld_AST_Coverage,
      Final_Gate_Withheld_Cross_Unit_Dependency,
      Final_Gate_Withheld_View_Barrier,
      Final_Gate_Withheld_Generic_Replay,
      Final_Gate_Withheld_Overload_Type,
      Final_Gate_Withheld_Representation_Freezing,
      Final_Gate_Withheld_Flow_Contract,
      Final_Gate_Withheld_Tasking_Protected,
      Final_Gate_Withheld_Elaboration,
      Final_Gate_Withheld_Accessibility_Lifetime,
      Final_Gate_Withheld_Discriminant_Variant,
      Final_Gate_Withheld_Multiple_Blockers,
      Final_Gate_Preserve_Semantic_Error,
      Final_Gate_Indeterminate);

   type Final_Gate_Action is
     (Final_Gate_Action_None,
      Final_Gate_Action_Allow_Confident_Result,
      Final_Gate_Action_Require_Prerequisite_Remediation,
      Final_Gate_Action_Suppress_Downstream_Legal_Result,
      Final_Gate_Action_Preserve_Original_Error,
      Final_Gate_Action_Degrade_To_Indeterminate);

   type Final_Gated_Result is record
      Id                    : Final_Gate_Id := No_Final_Gate;
      Remediation_Id        : Final_Remediation_Id := Remediation.No_Final_Remediation;
      Status                : Final_Gate_Status := Final_Gate_Not_Checked;
      Action                : Final_Gate_Action := Final_Gate_Action_None;
      Remediation_Status    : Final_Remediation_Status := Remediation.Final_Remediation_Not_Checked;
      Priority              : Final_Remediation_Priority := Remediation.Final_Remediation_Priority_None;
      Blocker_Family        : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Dependency_Order      : Natural := 0;
      Prerequisite_Blocking : Boolean := False;
      Legal_Result_Withheld : Boolean := False;
      Downstream_Blocked    : Natural := 0;
      Source_Fingerprint    : Natural := 0;
      Remediation_Fingerprint : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Final_Gated_Result_Set is private;
   type Final_Gated_Model is private;

   procedure Clear (Model : in out Final_Gated_Model);

   function Build
     (Remediation_Model : Remediation.Final_Remediation_Model)
      return Final_Gated_Model;

   function Row_Count (Model : Final_Gated_Model) return Natural;
   function Row_At
     (Model : Final_Gated_Model;
      Index : Positive) return Final_Gated_Result;

   function Set_Count (Set : Final_Gated_Result_Set) return Natural;
   function Set_At
     (Set   : Final_Gated_Result_Set;
      Index : Positive) return Final_Gated_Result;

   function Query_Status
     (Model  : Final_Gated_Model;
      Status : Final_Gate_Status) return Final_Gated_Result_Set;
   function Query_Action
     (Model  : Final_Gated_Model;
      Action : Final_Gate_Action) return Final_Gated_Result_Set;
   function Query_Blocker
     (Model   : Final_Gated_Model;
      Blocker : Final_Blocker_Family) return Final_Gated_Result_Set;
   function Query_Node
     (Model : Final_Gated_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Gated_Result_Set;
   function Query_Position
     (Model  : Final_Gated_Model;
      Line   : Positive;
      Column : Positive) return Final_Gated_Result_Set;

   function Count_Status
     (Model  : Final_Gated_Model;
      Status : Final_Gate_Status) return Natural;
   function Count_Action
     (Model  : Final_Gated_Model;
      Action : Final_Gate_Action) return Natural;
   function Count_Blocker
     (Model   : Final_Gated_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Confident_Legal_Count (Model : Final_Gated_Model) return Natural;
   function Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Stale_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function AST_Coverage_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Dependency_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function View_Barrier_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Generic_Replay_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Core_Type_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Representation_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Object_State_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Consumer_Chain_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Multiple_Blocker_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Gated_Model) return Natural;
   function Indeterminate_Count (Model : Final_Gated_Model) return Natural;
   function Prerequisite_Blocking_Count (Model : Final_Gated_Model) return Natural;
   function Legal_Result_Withheld_Count (Model : Final_Gated_Model) return Natural;
   function Downstream_Blocked_Count (Model : Final_Gated_Model) return Natural;
   function First_Prerequisite_Blocker
     (Model : Final_Gated_Model) return Final_Gated_Result;
   function Fingerprint (Model : Final_Gated_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Gated_Result);

   type Final_Gated_Result_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Gated_Model is record
      Rows                       : Row_Vectors.Vector;
      Confident_Legal_Total      : Natural := 0;
      Withheld_Total             : Natural := 0;
      Stale_Withheld_Total       : Natural := 0;
      AST_Coverage_Withheld_Total : Natural := 0;
      Dependency_Withheld_Total  : Natural := 0;
      View_Barrier_Withheld_Total : Natural := 0;
      Generic_Replay_Withheld_Total : Natural := 0;
      Core_Type_Withheld_Total   : Natural := 0;
      Representation_Withheld_Total : Natural := 0;
      Object_State_Withheld_Total : Natural := 0;
      Consumer_Chain_Withheld_Total : Natural := 0;
      Multiple_Blocker_Withheld_Total : Natural := 0;
      Preserved_Error_Total      : Natural := 0;
      Indeterminate_Total        : Natural := 0;
      Prerequisite_Blocking_Total : Natural := 0;
      Legal_Result_Withheld_Total : Natural := 0;
      Downstream_Blocked_Total   : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Remediation_Gate_Legality;
