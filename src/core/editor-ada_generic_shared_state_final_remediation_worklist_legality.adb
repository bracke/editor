with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality is

   pragma Suppress (Overflow_Check);
   use type Generic_Shared_State_Final_Worklist_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 12_407) mod 2_147_483_647;
   end Mix;

   function Is_Current_Evidence (Item : Generic_Shared_State_Final_Worklist_Item) return Boolean is
   begin
      return Item.Current_Evidence;
   end Is_Current_Evidence;

   function Is_Ready_For_Recheck (Item : Generic_Shared_State_Final_Worklist_Item) return Boolean is
   begin
      return Item.Ready_For_Recheck;
   end Is_Ready_For_Recheck;

   function Blocks_Downstream (Item : Generic_Shared_State_Final_Worklist_Item) return Boolean is
   begin
      return Item.Blocks_Downstream;
   end Blocks_Downstream;

   procedure Clear (Model : in out Generic_Shared_State_Final_Worklist_Model) is
   begin
      Model.Rows.Clear;
      Model.Current_Evidence_Total := 0;
      Model.Ready_For_Recheck_Total := 0;
      Model.Blocked_Downstream_Total := 0;
      Model.Fingerprint_Mismatch_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Stable_Fingerprint_Value := 0;
   end Clear;

   function Action_For
     (Row : Diagnostics.Generic_Shared_State_Final_Diagnostic_Row)
      return Generic_Shared_State_Final_Worklist_Action is
   begin
      case Row.Status is
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Withheld_Accepted_Current =>
            return Generic_Shared_State_Final_Worklist_Keep_Current_Evidence;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Definite_Initialization_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Definite_Initialization;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Dataflow_Initialization_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Dataflow_Initialization;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Predicate_Dataflow_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Predicate_Dataflow;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Predicate_Generic_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Predicate_Generic_Shared_State;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay_Blocker =>
            return Generic_Shared_State_Final_Worklist_Replay_Generic_Abstract_State;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Stabilized_Closure_Blocker =>
            return Generic_Shared_State_Final_Worklist_Stabilize_Shared_State_Closure;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Representation_Generic_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Representation_Generic_Shared_State;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Tasking_Generic_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Tasking_Generic_Shared_State;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Accessibility_Generic_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Accessibility_Generic_Shared_State;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Discriminant_Generic_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Discriminant_Generic_Shared_State;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Exception_Finalization_Generic_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Exception_Finalization_Generic_Shared_State;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Renaming_Generic_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Renaming_Generic_Shared_State;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Volatile_Atomic_Representation_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Volatile_Atomic_Representation;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Local_Dataflow_RM_Blocker =>
            return Generic_Shared_State_Final_Worklist_Resolve_Local_Dataflow_RM;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Source_Fingerprint_Mismatch |
              Diagnostics.Generic_Shared_State_Final_Diagnostic_Substitution_Fingerprint_Mismatch =>
            return Generic_Shared_State_Final_Worklist_Recheck_Fingerprint;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Multiple_Blockers =>
            return Generic_Shared_State_Final_Worklist_Split_Multiple_Blockers;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Indeterminate =>
            return Generic_Shared_State_Final_Worklist_Recheck_Indeterminate;
         when Diagnostics.Generic_Shared_State_Final_Diagnostic_Not_Checked =>
            return Generic_Shared_State_Final_Worklist_No_Action;
      end case;
   end Action_For;

   function Priority_For
     (Action : Generic_Shared_State_Final_Worklist_Action)
      return Generic_Shared_State_Final_Worklist_Priority is
   begin
      case Action is
         when Generic_Shared_State_Final_Worklist_Keep_Current_Evidence =>
            return Generic_Shared_State_Final_Worklist_Priority_Current_Evidence;
         when Generic_Shared_State_Final_Worklist_Recheck_Fingerprint =>
            return Generic_Shared_State_Final_Worklist_Priority_Stale_Or_Fingerprint;
         when Generic_Shared_State_Final_Worklist_Replay_Generic_Abstract_State =>
            return Generic_Shared_State_Final_Worklist_Priority_Generic_Replay;
         when Generic_Shared_State_Final_Worklist_Stabilize_Shared_State_Closure =>
            return Generic_Shared_State_Final_Worklist_Priority_Abstract_Or_Shared_State;
         when Generic_Shared_State_Final_Worklist_Resolve_Volatile_Atomic_Representation =>
            return Generic_Shared_State_Final_Worklist_Priority_Volatile_Atomic;
         when Generic_Shared_State_Final_Worklist_Resolve_Representation_Generic_Shared_State =>
            return Generic_Shared_State_Final_Worklist_Priority_Representation;
         when Generic_Shared_State_Final_Worklist_Resolve_Tasking_Generic_Shared_State =>
            return Generic_Shared_State_Final_Worklist_Priority_Tasking_Protected;
         when Generic_Shared_State_Final_Worklist_Resolve_Accessibility_Generic_Shared_State =>
            return Generic_Shared_State_Final_Worklist_Priority_Accessibility;
         when Generic_Shared_State_Final_Worklist_Resolve_Discriminant_Generic_Shared_State =>
            return Generic_Shared_State_Final_Worklist_Priority_Discriminant_Variant;
         when Generic_Shared_State_Final_Worklist_Resolve_Exception_Finalization_Generic_Shared_State =>
            return Generic_Shared_State_Final_Worklist_Priority_Exception_Finalization;
         when Generic_Shared_State_Final_Worklist_Resolve_Renaming_Generic_Shared_State =>
            return Generic_Shared_State_Final_Worklist_Priority_Renaming_Alias;
         when Generic_Shared_State_Final_Worklist_Resolve_Predicate_Dataflow |
              Generic_Shared_State_Final_Worklist_Resolve_Predicate_Generic_Shared_State =>
            return Generic_Shared_State_Final_Worklist_Priority_Predicate_Invariant;
         when Generic_Shared_State_Final_Worklist_Resolve_Definite_Initialization |
              Generic_Shared_State_Final_Worklist_Resolve_Dataflow_Initialization |
              Generic_Shared_State_Final_Worklist_Resolve_Local_Dataflow_RM =>
            return Generic_Shared_State_Final_Worklist_Priority_Dataflow;
         when Generic_Shared_State_Final_Worklist_Split_Multiple_Blockers =>
            return Generic_Shared_State_Final_Worklist_Priority_Multiple;
         when Generic_Shared_State_Final_Worklist_Recheck_Indeterminate =>
            return Generic_Shared_State_Final_Worklist_Priority_Indeterminate;
         when Generic_Shared_State_Final_Worklist_No_Action =>
            return Generic_Shared_State_Final_Worklist_Priority_None;
      end case;
   end Priority_For;

   function Message_For
     (Action : Generic_Shared_State_Final_Worklist_Action)
      return Unbounded_String is
   begin
      case Action is
         when Generic_Shared_State_Final_Worklist_Keep_Current_Evidence =>
            return To_Unbounded_String ("generic/shared-state final semantic evidence is current");
         when Generic_Shared_State_Final_Worklist_Resolve_Definite_Initialization =>
            return To_Unbounded_String ("resolve definite-initialization evidence before generic/shared-state recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Dataflow_Initialization =>
            return To_Unbounded_String ("resolve dataflow initialization evidence before generic/shared-state recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Predicate_Dataflow =>
            return To_Unbounded_String ("resolve predicate/dataflow evidence before generic/shared-state recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Predicate_Generic_Shared_State =>
            return To_Unbounded_String ("resolve predicate generic/shared-state evidence before recheck");
         when Generic_Shared_State_Final_Worklist_Replay_Generic_Abstract_State =>
            return To_Unbounded_String ("replay generic abstract/refined-state evidence before recheck");
         when Generic_Shared_State_Final_Worklist_Stabilize_Shared_State_Closure =>
            return To_Unbounded_String ("stabilize shared-state closure evidence before generic/shared-state recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Representation_Generic_Shared_State =>
            return To_Unbounded_String ("resolve representation/freezing generic shared-state evidence before recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Tasking_Generic_Shared_State =>
            return To_Unbounded_String ("resolve tasking/protected generic shared-state evidence before recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Accessibility_Generic_Shared_State =>
            return To_Unbounded_String ("resolve accessibility/lifetime generic shared-state evidence before recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Discriminant_Generic_Shared_State =>
            return To_Unbounded_String ("resolve discriminant/variant generic shared-state evidence before recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Exception_Finalization_Generic_Shared_State =>
            return To_Unbounded_String ("resolve exception/finalization generic shared-state evidence before recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Renaming_Generic_Shared_State =>
            return To_Unbounded_String ("resolve renaming/alias generic shared-state evidence before recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Volatile_Atomic_Representation =>
            return To_Unbounded_String ("resolve volatile/atomic representation evidence before generic/shared-state recheck");
         when Generic_Shared_State_Final_Worklist_Resolve_Local_Dataflow_RM =>
            return To_Unbounded_String ("resolve local Ada dataflow legality before generic/shared-state recheck");
         when Generic_Shared_State_Final_Worklist_Recheck_Fingerprint =>
            return To_Unbounded_String ("refresh source or substitution fingerprint before generic/shared-state recheck");
         when Generic_Shared_State_Final_Worklist_Split_Multiple_Blockers =>
            return To_Unbounded_String ("split multiple generic/shared-state blockers into prerequisite work items");
         when Generic_Shared_State_Final_Worklist_Recheck_Indeterminate =>
            return To_Unbounded_String ("recheck indeterminate generic/shared-state evidence after prerequisites");
         when Generic_Shared_State_Final_Worklist_No_Action =>
            return To_Unbounded_String ("no generic/shared-state remediation action");
      end case;
   end Message_For;

   function Fingerprint_For
     (Row      : Diagnostics.Generic_Shared_State_Final_Diagnostic_Row;
      Action   : Generic_Shared_State_Final_Worklist_Action;
      Priority : Generic_Shared_State_Final_Worklist_Priority) return Natural is
      F : Natural := 12_400;
   begin
      F := Mix (F, Natural (Row.Id));
      F := Mix (F, Natural (Row.Dataflow_Row));
      F := Mix (F, Diagnostics.Generic_Shared_State_Final_Diagnostic_Status'Pos (Row.Status));
      F := Mix (F, Diagnostics.Generic_Shared_State_Final_Diagnostic_Family'Pos (Row.Family));
      F := Mix (F, Generic_Shared_State_Final_Worklist_Action'Pos (Action));
      F := Mix (F, Generic_Shared_State_Final_Worklist_Priority'Pos (Priority));
      F := Mix (F, Natural (Row.Node));
      F := Mix (F, Row.Source_Fingerprint);
      F := Mix (F, Row.Substitution_Fingerprint);
      F := Mix (F, Row.Diagnostic_Fingerprint);
      return F;
   end Fingerprint_For;

   procedure Append_Item
     (Model : in out Generic_Shared_State_Final_Worklist_Model;
      Row   : Diagnostics.Generic_Shared_State_Final_Diagnostic_Row) is
      Action   : constant Generic_Shared_State_Final_Worklist_Action := Action_For (Row);
      Priority : constant Generic_Shared_State_Final_Worklist_Priority := Priority_For (Action);
      Item     : Generic_Shared_State_Final_Worklist_Item;
   begin
      Item.Id := Generic_Shared_State_Final_Worklist_Id (Natural (Model.Rows.Length) + 1);
      Item.Diagnostic_Row := Row.Id;
      Item.Diagnostic_Status := Row.Status;
      Item.Family := Row.Family;
      Item.Action := Action;
      Item.Priority := Priority;
      Item.Node := Row.Node;
      Item.Object_Name := Row.Object_Name;
      Item.Component_Name := Row.Component_Name;
      Item.Operation_Name := Row.Operation_Name;
      Item.Generic_Unit_Name := Row.Generic_Unit_Name;
      Item.Instance_Name := Row.Instance_Name;
      Item.State_Name := Row.State_Name;
      Item.Current_Evidence := Diagnostics.Is_Withheld_Current (Row.Status);
      Item.Ready_For_Recheck := Action not in Generic_Shared_State_Final_Worklist_No_Action |
                                           Generic_Shared_State_Final_Worklist_Keep_Current_Evidence;
      Item.Blocks_Downstream := Item.Ready_For_Recheck or else Row.Blocks_Downstream or else Row.Emitted;
      Item.Message := Message_For (Action);
      Item.Detail := Row.Detail;
      Item.Source_Fingerprint := Row.Source_Fingerprint;
      Item.Substitution_Fingerprint := Row.Substitution_Fingerprint;
      Item.Diagnostic_Fingerprint := Row.Diagnostic_Fingerprint;
      Item.Worklist_Fingerprint := Fingerprint_For (Row, Action, Priority);
      Item.Start_Line := Row.Start_Line;
      Item.Start_Column := Row.Start_Column;
      Item.End_Line := Row.End_Line;
      Item.End_Column := Row.End_Column;

      if Item.Current_Evidence then
         Model.Current_Evidence_Total := Model.Current_Evidence_Total + 1;
      end if;
      if Item.Ready_For_Recheck then
         Model.Ready_For_Recheck_Total := Model.Ready_For_Recheck_Total + 1;
      end if;
      if Item.Blocks_Downstream then
         Model.Blocked_Downstream_Total := Model.Blocked_Downstream_Total + 1;
      end if;
      if Action = Generic_Shared_State_Final_Worklist_Recheck_Fingerprint then
         Model.Fingerprint_Mismatch_Total := Model.Fingerprint_Mismatch_Total + 1;
      end if;
      if Action = Generic_Shared_State_Final_Worklist_Recheck_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;

      Model.Stable_Fingerprint_Value := Mix (Model.Stable_Fingerprint_Value, Item.Worklist_Fingerprint);
      Model.Rows.Append (Item);
   end Append_Item;

   function Build
     (Diagnostics_Model : Diagnostics.Generic_Shared_State_Final_Diagnostic_Model)
      return Generic_Shared_State_Final_Worklist_Model is
      Model : Generic_Shared_State_Final_Worklist_Model;
   begin
      for Index in 1 .. Diagnostics.Row_Count (Diagnostics_Model) loop
         Append_Item (Model, Diagnostics.Row_At (Diagnostics_Model, Index));
      end loop;
      return Model;
   end Build;

   function Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Generic_Shared_State_Final_Worklist_Model;
      Index : Positive) return Generic_Shared_State_Final_Worklist_Item is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Generic_Shared_State_Final_Worklist_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Generic_Shared_State_Final_Worklist_Set;
      Index : Positive) return Generic_Shared_State_Final_Worklist_Item is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Action
     (Model  : Generic_Shared_State_Final_Worklist_Model;
      Action : Generic_Shared_State_Final_Worklist_Action)
      return Generic_Shared_State_Final_Worklist_Set is
      Set : Generic_Shared_State_Final_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Worklist_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Generic_Shared_State_Final_Worklist_Model;
      Family : Generic_Shared_State_Final_Worklist_Family)
      return Generic_Shared_State_Final_Worklist_Set is
      Set : Generic_Shared_State_Final_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Worklist_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Priority
     (Model    : Generic_Shared_State_Final_Worklist_Model;
      Priority : Generic_Shared_State_Final_Worklist_Priority)
      return Generic_Shared_State_Final_Worklist_Set is
      Set : Generic_Shared_State_Final_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Priority = Priority then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Worklist_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Priority;

   function Query_Node
     (Model : Generic_Shared_State_Final_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Generic_Shared_State_Final_Worklist_Set is
      Set : Generic_Shared_State_Final_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Worklist_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Worklist_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Worklist_Set is
      Set : Generic_Shared_State_Final_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Worklist_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Action
     (Model  : Generic_Shared_State_Final_Worklist_Model;
      Action : Generic_Shared_State_Final_Worklist_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : Generic_Shared_State_Final_Worklist_Model;
      Family : Generic_Shared_State_Final_Worklist_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Count_Priority
     (Model    : Generic_Shared_State_Final_Worklist_Model;
      Priority : Generic_Shared_State_Final_Worklist_Priority) return Natural is
   begin
      return Query_Count (Query_Priority (Model, Priority));
   end Count_Priority;

   function Current_Evidence_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural is
   begin
      return Model.Current_Evidence_Total;
   end Current_Evidence_Count;

   function Ready_For_Recheck_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural is
   begin
      return Model.Ready_For_Recheck_Total;
   end Ready_For_Recheck_Count;

   function Blocked_Downstream_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural is
   begin
      return Model.Blocked_Downstream_Total;
   end Blocked_Downstream_Count;

   function Fingerprint_Mismatch_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural is
   begin
      return Model.Fingerprint_Mismatch_Total;
   end Fingerprint_Mismatch_Count;

   function Indeterminate_Count (Model : Generic_Shared_State_Final_Worklist_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Worklist_Model) return Natural is
   begin
      return Model.Stable_Fingerprint_Value;
   end Stable_Fingerprint;

end Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;
