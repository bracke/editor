package body Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality is

   pragma Suppress (Overflow_Check);
   use type Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 65_537 + Right * 257 + 12_751) mod 1_000_000_007;
   end Mix;

   function Status_For
     (Item : Worklist.RM_Closure_Consumer_Worklist_Item)
      return RM_Closure_Consumer_Recheck_Status is
   begin
      if Worklist.Is_Current_Evidence (Item) then
         return RM_Closure_Consumer_Recheck_Not_Required_Current;
      end if;

      case Item.Action is
         when Worklist.RM_Closure_Consumer_Worklist_No_Action =>
            return RM_Closure_Consumer_Recheck_Not_Checked;
         when Worklist.RM_Closure_Consumer_Worklist_Keep_Current_Evidence =>
            return RM_Closure_Consumer_Recheck_Not_Required_Current;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Predicate_RM |
              Worklist.RM_Closure_Consumer_Worklist_Resolve_Stabilized_Closure =>
            return RM_Closure_Consumer_Recheck_Eligible_Now;
         when Worklist.RM_Closure_Consumer_Worklist_Recheck_Stale_Or_Fingerprint =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Stale_Or_Fingerprint;
         when Worklist.RM_Closure_Consumer_Worklist_Repair_AST_Coverage =>
            return RM_Closure_Consumer_Recheck_Blocked_By_AST_Or_Coverage;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Cross_Unit =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Cross_Unit;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Generic_Substitution =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Generic_Substitution;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Dataflow =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Dataflow;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Volatile_Atomic =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Volatile_Atomic;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Overload_Type =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Overload_Type;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Representation =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Representation;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Tasking_Protected =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Tasking_Protected;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Elaboration =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Elaboration;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Accessibility =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Accessibility;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Discriminant_Variant =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Discriminant_Variant;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Exception_Finalization =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Exception_Finalization;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Renaming_Alias =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Renaming_Alias;
         when Worklist.RM_Closure_Consumer_Worklist_Resolve_Predicate_Invariant =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Predicate_Invariant;
         when Worklist.RM_Closure_Consumer_Worklist_Recheck_Source_Fingerprint =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Source_Fingerprint;
         when Worklist.RM_Closure_Consumer_Worklist_Recheck_Substitution_Fingerprint =>
            return RM_Closure_Consumer_Recheck_Blocked_By_Substitution_Fingerprint;
         when Worklist.RM_Closure_Consumer_Worklist_Split_Multiple_Blockers =>
            return RM_Closure_Consumer_Recheck_Multiple_Prerequisites;
         when Worklist.RM_Closure_Consumer_Worklist_Recheck_Indeterminate =>
            return RM_Closure_Consumer_Recheck_Indeterminate;
      end case;
   end Status_For;

   function Action_For
     (Status : RM_Closure_Consumer_Recheck_Status)
      return RM_Closure_Consumer_Recheck_Action is
   begin
      case Status is
         when RM_Closure_Consumer_Recheck_Not_Checked =>
            return RM_Closure_Consumer_Recheck_Action_None;
         when RM_Closure_Consumer_Recheck_Not_Required_Current =>
            return RM_Closure_Consumer_Recheck_Action_Keep_Current;
         when RM_Closure_Consumer_Recheck_Eligible_Now =>
            return RM_Closure_Consumer_Recheck_Action_Run_Now;
         when RM_Closure_Consumer_Recheck_Blocked_By_Stale_Or_Fingerprint =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Fingerprint;
         when RM_Closure_Consumer_Recheck_Blocked_By_AST_Or_Coverage =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_AST_Repair;
         when RM_Closure_Consumer_Recheck_Blocked_By_Cross_Unit =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Cross_Unit;
         when RM_Closure_Consumer_Recheck_Blocked_By_Generic_Substitution =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Generic_Substitution;
         when RM_Closure_Consumer_Recheck_Blocked_By_Dataflow =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Dataflow;
         when RM_Closure_Consumer_Recheck_Blocked_By_Volatile_Atomic =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Volatile_Atomic;
         when RM_Closure_Consumer_Recheck_Blocked_By_Overload_Type =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Overload_Type;
         when RM_Closure_Consumer_Recheck_Blocked_By_Representation =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Representation;
         when RM_Closure_Consumer_Recheck_Blocked_By_Tasking_Protected =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Tasking_Protected;
         when RM_Closure_Consumer_Recheck_Blocked_By_Elaboration =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Elaboration;
         when RM_Closure_Consumer_Recheck_Blocked_By_Accessibility =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Accessibility;
         when RM_Closure_Consumer_Recheck_Blocked_By_Discriminant_Variant =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Discriminants;
         when RM_Closure_Consumer_Recheck_Blocked_By_Exception_Finalization =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Exception_Finalization;
         when RM_Closure_Consumer_Recheck_Blocked_By_Renaming_Alias =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Renaming;
         when RM_Closure_Consumer_Recheck_Blocked_By_Predicate_Invariant =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Predicate;
         when RM_Closure_Consumer_Recheck_Blocked_By_Source_Fingerprint =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Source_Fingerprint;
         when RM_Closure_Consumer_Recheck_Blocked_By_Substitution_Fingerprint =>
            return RM_Closure_Consumer_Recheck_Action_Wait_For_Substitution_Fingerprint;
         when RM_Closure_Consumer_Recheck_Multiple_Prerequisites =>
            return RM_Closure_Consumer_Recheck_Action_Split_Prerequisites;
         when RM_Closure_Consumer_Recheck_Indeterminate =>
            return RM_Closure_Consumer_Recheck_Action_Degrade;
      end case;
   end Action_For;

   function Rank_For
     (Priority : RM_Closure_Consumer_Recheck_Work_Priority) return Natural is
   begin
      case Priority is
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Current_Evidence => return 0;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Stale_Or_Fingerprint => return 10;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_AST_Or_Coverage => return 20;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Cross_Unit => return 30;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Generic_Substitution => return 40;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Dataflow => return 50;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Volatile_Atomic => return 60;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Overload_Type => return 70;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Representation => return 80;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Tasking_Protected => return 90;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Elaboration => return 100;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Accessibility => return 110;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Exception_Finalization => return 120;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Predicate_Invariant => return 130;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Discriminant_Variant => return 140;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Renaming_Alias => return 150;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Multiple => return 170;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_Indeterminate => return 180;
         when Worklist.RM_Closure_Consumer_Worklist_Priority_None => return 999;
      end case;
   end Rank_For;

   function Is_Blocked (Status : RM_Closure_Consumer_Recheck_Status) return Boolean is
   begin
      return Status not in RM_Closure_Consumer_Recheck_Not_Checked |
                           RM_Closure_Consumer_Recheck_Not_Required_Current |
                           RM_Closure_Consumer_Recheck_Eligible_Now;
   end Is_Blocked;

   function Fingerprint_For
     (Item   : Worklist.RM_Closure_Consumer_Worklist_Item;
      Status : RM_Closure_Consumer_Recheck_Status;
      Action : RM_Closure_Consumer_Recheck_Action) return Natural is
      F : Natural := 12_750;
   begin
      F := Mix (F, Natural (Item.Id));
      F := Mix (F, Natural (Item.Diagnostic_Row));
      F := Mix (F, Worklist.RM_Closure_Consumer_Worklist_Action'Pos (Item.Action));
      F := Mix (F, Worklist.RM_Closure_Consumer_Worklist_Priority'Pos (Item.Priority));
      F := Mix (F, RM_Closure_Consumer_Recheck_Status'Pos (Status));
      F := Mix (F, RM_Closure_Consumer_Recheck_Action'Pos (Action));
      F := Mix (F, Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Pos (Item.Family));
      F := Mix (F, Natural (Item.Node));
      F := Mix (F, Item.Source_Fingerprint);
      F := Mix (F, Item.Substitution_Fingerprint);
      F := Mix (F, Item.Semantic_Fingerprint);
      F := Mix (F, Item.Diagnostic_Fingerprint);
      F := Mix (F, Item.Worklist_Fingerprint);
      return F;
   end Fingerprint_For;

   procedure Increment_Counters
     (Model : in out RM_Closure_Consumer_Recheck_Model;
      Row   : RM_Closure_Consumer_Recheck_Row) is
   begin
      if Row.Current_Evidence then
         Model.Current_Evidence_Total := Model.Current_Evidence_Total + 1;
      end if;
      if Row.Status = RM_Closure_Consumer_Recheck_Eligible_Now then
         Model.Eligible_Total := Model.Eligible_Total + 1;
      end if;
      if Is_Blocked (Row.Status) then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;

      case Row.Status is
         when RM_Closure_Consumer_Recheck_Blocked_By_Stale_Or_Fingerprint |
              RM_Closure_Consumer_Recheck_Blocked_By_Source_Fingerprint |
              RM_Closure_Consumer_Recheck_Blocked_By_Substitution_Fingerprint =>
            Model.Fingerprint_Blocked_Total := Model.Fingerprint_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_AST_Or_Coverage =>
            Model.AST_Coverage_Blocked_Total := Model.AST_Coverage_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Cross_Unit =>
            Model.Cross_Unit_Blocked_Total := Model.Cross_Unit_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Generic_Substitution =>
            Model.Generic_Substitution_Total := Model.Generic_Substitution_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Dataflow =>
            Model.Dataflow_Blocked_Total := Model.Dataflow_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Volatile_Atomic =>
            Model.Volatile_Atomic_Blocked_Total := Model.Volatile_Atomic_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Overload_Type =>
            Model.Overload_Blocked_Total := Model.Overload_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Representation =>
            Model.Representation_Blocked_Total := Model.Representation_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Tasking_Protected =>
            Model.Tasking_Blocked_Total := Model.Tasking_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Elaboration =>
            Model.Elaboration_Blocked_Total := Model.Elaboration_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Accessibility =>
            Model.Accessibility_Blocked_Total := Model.Accessibility_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Discriminant_Variant =>
            Model.Discriminant_Blocked_Total := Model.Discriminant_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Exception_Finalization =>
            Model.Exception_Blocked_Total := Model.Exception_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Renaming_Alias =>
            Model.Renaming_Blocked_Total := Model.Renaming_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Blocked_By_Predicate_Invariant =>
            Model.Predicate_Blocked_Total := Model.Predicate_Blocked_Total + 1;
         when RM_Closure_Consumer_Recheck_Multiple_Prerequisites =>
            Model.Multiple_Total := Model.Multiple_Total + 1;
         when RM_Closure_Consumer_Recheck_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others =>
            null;
      end case;
   end Increment_Counters;

   procedure Append_Row
     (Model : in out RM_Closure_Consumer_Recheck_Model;
      Item  : Worklist.RM_Closure_Consumer_Worklist_Item) is
      Status : constant RM_Closure_Consumer_Recheck_Status := Status_For (Item);
      Action : constant RM_Closure_Consumer_Recheck_Action := Action_For (Status);
      Row    : RM_Closure_Consumer_Recheck_Row;
   begin
      Row.Id := RM_Closure_Consumer_Recheck_Id (Natural (Model.Rows.Length) + 1);
      Row.Worklist_Item := Item.Id;
      Row.Diagnostic_Row := Item.Diagnostic_Row;
      Row.Work_Action := Item.Action;
      Row.Work_Priority := Item.Priority;
      Row.Status := Status;
      Row.Action := Action;
      Row.Family := Item.Family;
      Row.Node := Item.Node;
      Row.Current_Evidence := Item.Current_Evidence;
      Row.Ready_For_Recheck := Item.Ready_For_Recheck;
      Row.Blocks_Downstream := Is_Blocked (Status) or else Item.Blocks_Downstream;
      Row.Priority_Rank := Rank_For (Item.Priority);
      Row.Source_Fingerprint := Item.Source_Fingerprint;
      Row.Substitution_Fingerprint := Item.Substitution_Fingerprint;
      Row.Semantic_Fingerprint := Item.Semantic_Fingerprint;
      Row.Diagnostic_Fingerprint := Item.Diagnostic_Fingerprint;
      Row.Worklist_Fingerprint := Item.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Fingerprint_For (Item, Status, Action);
      Row.Start_Line := Item.Start_Line;
      Row.Start_Column := Item.Start_Column;
      Row.End_Line := Item.End_Line;
      Row.End_Column := Item.End_Column;

      Increment_Counters (Model, Row);
      Model.Stable_Fingerprint_Value := Mix (Model.Stable_Fingerprint_Value, Row.Eligibility_Fingerprint);
      Model.Rows.Append (Row);
   end Append_Row;

   procedure Clear (Model : in out RM_Closure_Consumer_Recheck_Model) is
   begin
      Model.Rows.Clear;
      Model.Current_Evidence_Total := 0;
      Model.Eligible_Total := 0;
      Model.Blocked_Total := 0;
      Model.Fingerprint_Blocked_Total := 0;
      Model.AST_Coverage_Blocked_Total := 0;
      Model.Cross_Unit_Blocked_Total := 0;
      Model.Generic_Substitution_Total := 0;
      Model.Dataflow_Blocked_Total := 0;
      Model.Volatile_Atomic_Blocked_Total := 0;
      Model.Overload_Blocked_Total := 0;
      Model.Representation_Blocked_Total := 0;
      Model.Tasking_Blocked_Total := 0;
      Model.Elaboration_Blocked_Total := 0;
      Model.Accessibility_Blocked_Total := 0;
      Model.Discriminant_Blocked_Total := 0;
      Model.Exception_Blocked_Total := 0;
      Model.Renaming_Blocked_Total := 0;
      Model.Predicate_Blocked_Total := 0;
      Model.Multiple_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Stable_Fingerprint_Value := 0;
   end Clear;

   function Build
     (Work : Worklist.RM_Closure_Consumer_Worklist_Model)
      return RM_Closure_Consumer_Recheck_Model is
      Model : RM_Closure_Consumer_Recheck_Model;
   begin
      for Index in 1 .. Worklist.Count (Work) loop
         Append_Row (Model, Worklist.Row_At (Work, Index));
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : RM_Closure_Consumer_Recheck_Model;
      Index : Positive) return RM_Closure_Consumer_Recheck_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Closure_Consumer_Recheck_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Closure_Consumer_Recheck_Set;
      Index : Positive) return RM_Closure_Consumer_Recheck_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Status : RM_Closure_Consumer_Recheck_Status)
      return RM_Closure_Consumer_Recheck_Set is
      Set : RM_Closure_Consumer_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Action : RM_Closure_Consumer_Recheck_Action)
      return RM_Closure_Consumer_Recheck_Set is
      Set : RM_Closure_Consumer_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Family : RM_Closure_Consumer_Recheck_Family)
      return RM_Closure_Consumer_Recheck_Set is
      Set : RM_Closure_Consumer_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Node
     (Model : RM_Closure_Consumer_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Recheck_Set is
      Set : RM_Closure_Consumer_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Recheck_Model;
      Fingerprint : Natural)
      return RM_Closure_Consumer_Recheck_Set is
      Set : RM_Closure_Consumer_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Status
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Status : RM_Closure_Consumer_Recheck_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Action : RM_Closure_Consumer_Recheck_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : RM_Closure_Consumer_Recheck_Model;
      Family : RM_Closure_Consumer_Recheck_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Current_Evidence_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Current_Evidence_Total;
   end Current_Evidence_Count;

   function Eligible_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Eligible_Total;
   end Eligible_Count;

   function Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Fingerprint_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Fingerprint_Blocked_Total;
   end Fingerprint_Blocked_Count;

   function AST_Coverage_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.AST_Coverage_Blocked_Total;
   end AST_Coverage_Blocked_Count;

   function Cross_Unit_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Cross_Unit_Blocked_Total;
   end Cross_Unit_Blocked_Count;

   function Generic_Substitution_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Generic_Substitution_Total;
   end Generic_Substitution_Blocked_Count;

   function Dataflow_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Dataflow_Blocked_Total;
   end Dataflow_Blocked_Count;

   function Volatile_Atomic_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Volatile_Atomic_Blocked_Total;
   end Volatile_Atomic_Blocked_Count;

   function Overload_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Overload_Blocked_Total;
   end Overload_Blocked_Count;

   function Representation_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Representation_Blocked_Total;
   end Representation_Blocked_Count;

   function Tasking_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Tasking_Blocked_Total;
   end Tasking_Blocked_Count;

   function Elaboration_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Elaboration_Blocked_Total;
   end Elaboration_Blocked_Count;

   function Accessibility_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Accessibility_Blocked_Total;
   end Accessibility_Blocked_Count;

   function Discriminant_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Discriminant_Blocked_Total;
   end Discriminant_Blocked_Count;

   function Exception_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Exception_Blocked_Total;
   end Exception_Blocked_Count;

   function Renaming_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Renaming_Blocked_Total;
   end Renaming_Blocked_Count;

   function Predicate_Blocked_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Predicate_Blocked_Total;
   end Predicate_Blocked_Count;

   function Multiple_Prerequisite_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Multiple_Total;
   end Multiple_Prerequisite_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : RM_Closure_Consumer_Recheck_Model) return Natural is
   begin
      return Model.Stable_Fingerprint_Value;
   end Stable_Fingerprint;

   function Is_Current (Row : RM_Closure_Consumer_Recheck_Row) return Boolean is
   begin
      return Row.Status = RM_Closure_Consumer_Recheck_Not_Required_Current;
   end Is_Current;

   function Is_Eligible (Row : RM_Closure_Consumer_Recheck_Row) return Boolean is
   begin
      return Row.Status = RM_Closure_Consumer_Recheck_Eligible_Now;
   end Is_Eligible;

end Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality;
