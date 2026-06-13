package body Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 12_774) mod 2_147_483_647;
   end Mix;

   function Is_Current_Evidence (Item : RM_Closure_Consumer_Worklist_Item) return Boolean is
   begin
      return Item.Current_Evidence;
   end Is_Current_Evidence;

   function Is_Ready_For_Recheck (Item : RM_Closure_Consumer_Worklist_Item) return Boolean is
   begin
      return Item.Ready_For_Recheck;
   end Is_Ready_For_Recheck;

   function Blocks_Downstream (Item : RM_Closure_Consumer_Worklist_Item) return Boolean is
   begin
      return Item.Blocks_Downstream;
   end Blocks_Downstream;

   function Action_For
     (Row : Diagnostics.RM_Closure_Consumer_Diagnostic_Row)
      return RM_Closure_Consumer_Worklist_Action is
   begin
      case Row.Status is
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Withheld_Accepted_Current =>
            return RM_Closure_Consumer_Worklist_Keep_Current_Evidence;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Predicate_RM_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Predicate_RM;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Stabilized_Closure_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Stabilized_Closure;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Stale_Or_Fingerprint_Blocker =>
            return RM_Closure_Consumer_Worklist_Recheck_Stale_Or_Fingerprint;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_AST_Or_Coverage_Blocker =>
            return RM_Closure_Consumer_Worklist_Repair_AST_Coverage;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Cross_Unit_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Cross_Unit;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Generic_Substitution_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Generic_Substitution;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Dataflow_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Dataflow;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Volatile_Atomic_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Volatile_Atomic;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Overload_Type_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Overload_Type;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Representation_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Representation;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Tasking_Protected_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Tasking_Protected;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Elaboration_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Elaboration;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Accessibility_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Accessibility;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Discriminant_Variant_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Discriminant_Variant;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Exception_Finalization_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Exception_Finalization;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Renaming_Alias_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Renaming_Alias;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Predicate_Invariant_Blocker =>
            return RM_Closure_Consumer_Worklist_Resolve_Predicate_Invariant;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Source_Fingerprint_Mismatch =>
            return RM_Closure_Consumer_Worklist_Recheck_Source_Fingerprint;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Substitution_Fingerprint_Mismatch =>
            return RM_Closure_Consumer_Worklist_Recheck_Substitution_Fingerprint;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Multiple_Blockers =>
            return RM_Closure_Consumer_Worklist_Split_Multiple_Blockers;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Indeterminate =>
            return RM_Closure_Consumer_Worklist_Recheck_Indeterminate;
         when Diagnostics.RM_Closure_Consumer_Diagnostic_Not_Checked =>
            return RM_Closure_Consumer_Worklist_No_Action;
      end case;
   end Action_For;

   function Priority_For
     (Action : RM_Closure_Consumer_Worklist_Action)
      return RM_Closure_Consumer_Worklist_Priority is
   begin
      case Action is
         when RM_Closure_Consumer_Worklist_Keep_Current_Evidence =>
            return RM_Closure_Consumer_Worklist_Priority_Current_Evidence;
         when RM_Closure_Consumer_Worklist_Recheck_Stale_Or_Fingerprint |
              RM_Closure_Consumer_Worklist_Recheck_Source_Fingerprint |
              RM_Closure_Consumer_Worklist_Recheck_Substitution_Fingerprint =>
            return RM_Closure_Consumer_Worklist_Priority_Stale_Or_Fingerprint;
         when RM_Closure_Consumer_Worklist_Repair_AST_Coverage =>
            return RM_Closure_Consumer_Worklist_Priority_AST_Or_Coverage;
         when RM_Closure_Consumer_Worklist_Resolve_Cross_Unit =>
            return RM_Closure_Consumer_Worklist_Priority_Cross_Unit;
         when RM_Closure_Consumer_Worklist_Resolve_Generic_Substitution =>
            return RM_Closure_Consumer_Worklist_Priority_Generic_Substitution;
         when RM_Closure_Consumer_Worklist_Resolve_Dataflow =>
            return RM_Closure_Consumer_Worklist_Priority_Dataflow;
         when RM_Closure_Consumer_Worklist_Resolve_Volatile_Atomic =>
            return RM_Closure_Consumer_Worklist_Priority_Volatile_Atomic;
         when RM_Closure_Consumer_Worklist_Resolve_Overload_Type =>
            return RM_Closure_Consumer_Worklist_Priority_Overload_Type;
         when RM_Closure_Consumer_Worklist_Resolve_Representation =>
            return RM_Closure_Consumer_Worklist_Priority_Representation;
         when RM_Closure_Consumer_Worklist_Resolve_Tasking_Protected =>
            return RM_Closure_Consumer_Worklist_Priority_Tasking_Protected;
         when RM_Closure_Consumer_Worklist_Resolve_Elaboration =>
            return RM_Closure_Consumer_Worklist_Priority_Elaboration;
         when RM_Closure_Consumer_Worklist_Resolve_Accessibility =>
            return RM_Closure_Consumer_Worklist_Priority_Accessibility;
         when RM_Closure_Consumer_Worklist_Resolve_Exception_Finalization =>
            return RM_Closure_Consumer_Worklist_Priority_Exception_Finalization;
         when RM_Closure_Consumer_Worklist_Resolve_Predicate_RM |
              RM_Closure_Consumer_Worklist_Resolve_Predicate_Invariant |
              RM_Closure_Consumer_Worklist_Resolve_Stabilized_Closure =>
            return RM_Closure_Consumer_Worklist_Priority_Predicate_Invariant;
         when RM_Closure_Consumer_Worklist_Resolve_Discriminant_Variant =>
            return RM_Closure_Consumer_Worklist_Priority_Discriminant_Variant;
         when RM_Closure_Consumer_Worklist_Resolve_Renaming_Alias =>
            return RM_Closure_Consumer_Worklist_Priority_Renaming_Alias;
         when RM_Closure_Consumer_Worklist_Split_Multiple_Blockers =>
            return RM_Closure_Consumer_Worklist_Priority_Multiple;
         when RM_Closure_Consumer_Worklist_Recheck_Indeterminate =>
            return RM_Closure_Consumer_Worklist_Priority_Indeterminate;
         when RM_Closure_Consumer_Worklist_No_Action =>
            return RM_Closure_Consumer_Worklist_Priority_None;
      end case;
   end Priority_For;

   function Fingerprint_For
     (Row      : Diagnostics.RM_Closure_Consumer_Diagnostic_Row;
      Action   : RM_Closure_Consumer_Worklist_Action;
      Priority : RM_Closure_Consumer_Worklist_Priority) return Natural is
      F : Natural := 12_740;
   begin
      F := Mix (F, Natural (Row.Id));
      F := Mix (F, Natural (Row.Predicate_Row));
      F := Mix (F, Diagnostics.RM_Closure_Consumer_Diagnostic_Status'Pos (Row.Status));
      F := Mix (F, Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Pos (Row.Family));
      F := Mix (F, RM_Closure_Consumer_Worklist_Action'Pos (Action));
      F := Mix (F, RM_Closure_Consumer_Worklist_Priority'Pos (Priority));
      F := Mix (F, Natural (Row.Node));
      F := Mix (F, Row.Source_Fingerprint);
      F := Mix (F, Row.Substitution_Fingerprint);
      F := Mix (F, Row.Semantic_Fingerprint);
      F := Mix (F, Row.Diagnostic_Fingerprint);
      return F;
   end Fingerprint_For;

   procedure Append_Item
     (Model : in out RM_Closure_Consumer_Worklist_Model;
      Row   : Diagnostics.RM_Closure_Consumer_Diagnostic_Row) is
      Action   : constant RM_Closure_Consumer_Worklist_Action := Action_For (Row);
      Priority : constant RM_Closure_Consumer_Worklist_Priority := Priority_For (Action);
      Item     : RM_Closure_Consumer_Worklist_Item;
   begin
      Item.Id := RM_Closure_Consumer_Worklist_Id (Natural (Model.Rows.Length) + 1);
      Item.Diagnostic_Row := Row.Id;
      Item.Diagnostic_Status := Row.Status;
      Item.Family := Row.Family;
      Item.Action := Action;
      Item.Priority := Priority;
      Item.Node := Row.Node;
      Item.Current_Evidence := Diagnostics.Is_Withheld_Current (Row.Status);
      Item.Ready_For_Recheck := Action not in RM_Closure_Consumer_Worklist_No_Action |
                                           RM_Closure_Consumer_Worklist_Keep_Current_Evidence;
      Item.Blocks_Downstream := Item.Ready_For_Recheck or else Row.Blocks_Downstream or else Row.Emitted;
      Item.Source_Fingerprint := Row.Source_Fingerprint;
      Item.Substitution_Fingerprint := Row.Substitution_Fingerprint;
      Item.Semantic_Fingerprint := Row.Semantic_Fingerprint;
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
      if Action in RM_Closure_Consumer_Worklist_Recheck_Stale_Or_Fingerprint |
                   RM_Closure_Consumer_Worklist_Recheck_Source_Fingerprint |
                   RM_Closure_Consumer_Worklist_Recheck_Substitution_Fingerprint then
         Model.Fingerprint_Mismatch_Total := Model.Fingerprint_Mismatch_Total + 1;
      end if;
      if Action = RM_Closure_Consumer_Worklist_Recheck_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;

      Model.Stable_Fingerprint_Value := Mix (Model.Stable_Fingerprint_Value, Item.Worklist_Fingerprint);
      Model.Rows.Append (Item);
   end Append_Item;

   procedure Clear (Model : in out RM_Closure_Consumer_Worklist_Model) is
   begin
      Model.Rows.Clear;
      Model.Current_Evidence_Total := 0;
      Model.Ready_For_Recheck_Total := 0;
      Model.Blocked_Downstream_Total := 0;
      Model.Fingerprint_Mismatch_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Stable_Fingerprint_Value := 0;
   end Clear;

   function Build
     (Diagnostics_Model : Diagnostics.RM_Closure_Consumer_Diagnostic_Model)
      return RM_Closure_Consumer_Worklist_Model is
      Model : RM_Closure_Consumer_Worklist_Model;
   begin
      for Index in 1 .. Diagnostics.Row_Count (Diagnostics_Model) loop
         Append_Item (Model, Diagnostics.Row_At (Diagnostics_Model, Index));
      end loop;
      return Model;
   end Build;

   function Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : RM_Closure_Consumer_Worklist_Model;
      Index : Positive) return RM_Closure_Consumer_Worklist_Item is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Closure_Consumer_Worklist_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Closure_Consumer_Worklist_Set;
      Index : Positive) return RM_Closure_Consumer_Worklist_Item is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Action
     (Model  : RM_Closure_Consumer_Worklist_Model;
      Action : RM_Closure_Consumer_Worklist_Action) return RM_Closure_Consumer_Worklist_Set is
      Set : RM_Closure_Consumer_Worklist_Set;
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
     (Model  : RM_Closure_Consumer_Worklist_Model;
      Family : RM_Closure_Consumer_Worklist_Family) return RM_Closure_Consumer_Worklist_Set is
      Set : RM_Closure_Consumer_Worklist_Set;
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
     (Model    : RM_Closure_Consumer_Worklist_Model;
      Priority : RM_Closure_Consumer_Worklist_Priority) return RM_Closure_Consumer_Worklist_Set is
      Set : RM_Closure_Consumer_Worklist_Set;
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
     (Model : RM_Closure_Consumer_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Closure_Consumer_Worklist_Set is
      Set : RM_Closure_Consumer_Worklist_Set;
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
     (Model       : RM_Closure_Consumer_Worklist_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Worklist_Set is
      Set : RM_Closure_Consumer_Worklist_Set;
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
     (Model  : RM_Closure_Consumer_Worklist_Model;
      Action : RM_Closure_Consumer_Worklist_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : RM_Closure_Consumer_Worklist_Model;
      Family : RM_Closure_Consumer_Worklist_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Count_Priority
     (Model    : RM_Closure_Consumer_Worklist_Model;
      Priority : RM_Closure_Consumer_Worklist_Priority) return Natural is
   begin
      return Query_Count (Query_Priority (Model, Priority));
   end Count_Priority;

   function Current_Evidence_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural is
   begin
      return Model.Current_Evidence_Total;
   end Current_Evidence_Count;

   function Ready_For_Recheck_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural is
   begin
      return Model.Ready_For_Recheck_Total;
   end Ready_For_Recheck_Count;

   function Blocked_Downstream_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural is
   begin
      return Model.Blocked_Downstream_Total;
   end Blocked_Downstream_Count;

   function Fingerprint_Mismatch_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural is
   begin
      return Model.Fingerprint_Mismatch_Total;
   end Fingerprint_Mismatch_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Worklist_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : RM_Closure_Consumer_Worklist_Model) return Natural is
   begin
      return Model.Stable_Fingerprint_Value;
   end Stable_Fingerprint;

end Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality;
