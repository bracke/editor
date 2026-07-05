with Ada.Containers.Vectors;
with Editor.Ada_Final_Semantic_Diagnostic_Provenance;
with Editor.Ada_Final_Semantic_Remediation_Gate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Final_Semantic_Remediation_Closure_Legality is

   --  Case 1201 final semantic remediation closure legality.
   --
   --  This package feeds Case 1200 remediation gates back into a deterministic
   --  closure model.  It is intentionally semantic rather than presentational:
   --  unresolved prerequisite gates become first-class closure blockers so a
   --  later consumer cannot accept a legal conclusion after a stale snapshot,
   --  AST/coverage gap, cross-unit dependency, view barrier, generic replay
   --  failure, overload/type blocker, representation/freezing blocker,
   --  flow/contract proof blocker, tasking/protected blocker, elaboration
   --  blocker, accessibility/lifetime blocker, or discriminant/variant blocker.
   --  Legal gates remain confident closure rows; preserved semantic errors stay
   --  hard closure blockers; indeterminate gates remain indeterminate closure.
   --  The model is bounded, snapshot-owned, and side-effect-free.

   package Gate renames Editor.Ada_Final_Semantic_Remediation_Gate_Legality;
   package Final_Prov renames Editor.Ada_Final_Semantic_Diagnostic_Provenance;

   subtype Final_Blocker_Family is Final_Prov.Final_Blocker_Family;
   subtype Final_Gate_Id is Gate.Final_Gate_Id;
   subtype Final_Gate_Status is Gate.Final_Gate_Status;
   subtype Final_Gate_Action is Gate.Final_Gate_Action;

   type Final_Remediation_Closure_Id is new Natural;
   No_Final_Remediation_Closure : constant Final_Remediation_Closure_Id := 0;

   type Final_Remediation_Closure_Status is
     (Final_Remediation_Closure_Not_Checked,
      Final_Remediation_Closure_Legal_Local,
      Final_Remediation_Closure_Legal_Derived,
      Final_Remediation_Closure_Stale_Blocker,
      Final_Remediation_Closure_AST_Coverage_Blocker,
      Final_Remediation_Closure_Cross_Unit_Blocker,
      Final_Remediation_Closure_View_Blocker,
      Final_Remediation_Closure_Generic_Replay_Blocker,
      Final_Remediation_Closure_Overload_Type_Blocker,
      Final_Remediation_Closure_Representation_Freezing_Blocker,
      Final_Remediation_Closure_Flow_Contract_Blocker,
      Final_Remediation_Closure_Tasking_Protected_Blocker,
      Final_Remediation_Closure_Elaboration_Blocker,
      Final_Remediation_Closure_Accessibility_Lifetime_Blocker,
      Final_Remediation_Closure_Discriminant_Variant_Blocker,
      Final_Remediation_Closure_Multiple_Blockers,
      Final_Remediation_Closure_Preserved_Semantic_Error,
      Final_Remediation_Closure_Indeterminate);

   type Final_Remediation_Closure_Row is record
      Id                    : Final_Remediation_Closure_Id := No_Final_Remediation_Closure;
      Gate_Id               : Final_Gate_Id := Gate.No_Final_Gate;
      Status                : Final_Remediation_Closure_Status := Final_Remediation_Closure_Not_Checked;
      Gate_Status           : Final_Gate_Status := Gate.Final_Gate_Not_Checked;
      Gate_Action           : Final_Gate_Action := Gate.Final_Gate_Action_None;
      Blocker_Family        : Final_Blocker_Family := Final_Prov.Final_Blocker_None;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Dependency_Order      : Natural := 0;
      Closure_Blocked       : Boolean := False;
      Derived_Legal_Withheld : Boolean := False;
      Downstream_Blocked    : Natural := 0;
      Source_Fingerprint    : Natural := 0;
      Gate_Fingerprint      : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Final_Remediation_Closure_Set is private;
   type Final_Remediation_Closure_Model is private;

   procedure Clear (Model : in out Final_Remediation_Closure_Model);

   function Build
     (Gate_Model : Gate.Final_Gated_Model)
      return Final_Remediation_Closure_Model;

   function Row_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Row_At
     (Model : Final_Remediation_Closure_Model;
      Index : Positive) return Final_Remediation_Closure_Row;

   function Set_Count (Set : Final_Remediation_Closure_Set) return Natural;
   function Set_At
     (Set   : Final_Remediation_Closure_Set;
      Index : Positive) return Final_Remediation_Closure_Row;

   function Query_Status
     (Model  : Final_Remediation_Closure_Model;
      Status : Final_Remediation_Closure_Status) return Final_Remediation_Closure_Set;
   function Query_Blocker
     (Model   : Final_Remediation_Closure_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Closure_Set;
   function Query_Node
     (Model : Final_Remediation_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Closure_Set;
   function Query_Position
     (Model  : Final_Remediation_Closure_Model;
      Line   : Positive;
      Column : Positive) return Final_Remediation_Closure_Set;

   function Count_Status
     (Model  : Final_Remediation_Closure_Model;
      Status : Final_Remediation_Closure_Status) return Natural;
   function Count_Blocker
     (Model   : Final_Remediation_Closure_Model;
      Blocker : Final_Blocker_Family) return Natural;

   function Legal_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Blocked_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Derived_Legal_Withheld_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Stale_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function AST_Coverage_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Cross_Unit_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function View_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Generic_Replay_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Overload_Type_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Representation_Freezing_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Flow_Contract_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Tasking_Protected_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Elaboration_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Accessibility_Lifetime_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Discriminant_Variant_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Multiple_Blocker_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Preserved_Error_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Indeterminate_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function Downstream_Blocked_Count (Model : Final_Remediation_Closure_Model) return Natural;
   function First_Blocker
     (Model : Final_Remediation_Closure_Model) return Final_Remediation_Closure_Row;
   function Fingerprint (Model : Final_Remediation_Closure_Model) return Natural;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Final_Remediation_Closure_Row);

   type Final_Remediation_Closure_Set is record
      Rows        : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Final_Remediation_Closure_Model is record
      Rows                             : Row_Vectors.Vector;
      Legal_Total                      : Natural := 0;
      Blocked_Total                    : Natural := 0;
      Derived_Legal_Withheld_Total     : Natural := 0;
      Stale_Blocker_Total              : Natural := 0;
      AST_Coverage_Blocker_Total       : Natural := 0;
      Cross_Unit_Blocker_Total         : Natural := 0;
      View_Blocker_Total               : Natural := 0;
      Generic_Replay_Blocker_Total     : Natural := 0;
      Overload_Type_Blocker_Total      : Natural := 0;
      Representation_Freezing_Blocker_Total : Natural := 0;
      Flow_Contract_Blocker_Total      : Natural := 0;
      Tasking_Protected_Blocker_Total  : Natural := 0;
      Elaboration_Blocker_Total        : Natural := 0;
      Accessibility_Lifetime_Blocker_Total : Natural := 0;
      Discriminant_Variant_Blocker_Total : Natural := 0;
      Multiple_Blocker_Total           : Natural := 0;
      Preserved_Error_Total            : Natural := 0;
      Indeterminate_Total              : Natural := 0;
      Downstream_Blocked_Total         : Natural := 0;
      Fingerprint                      : Natural := 0;
   end record;

end Editor.Ada_Final_Semantic_Remediation_Closure_Legality;
