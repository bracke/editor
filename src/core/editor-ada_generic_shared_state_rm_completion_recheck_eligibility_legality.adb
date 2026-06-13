with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality is
   use type RM_Completion_Recheck_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 12_411) mod 2_147_483_647;
   end Mix;

   function Status_For
     (Item : Worklist.RM_Completion_Worklist_Item)
      return RM_Completion_Recheck_Status is
   begin
      case Item.Action is
         when Worklist.RM_Completion_Worklist_Keep_Current_Evidence =>
            return RM_Completion_Recheck_Not_Required_Current;
         when Worklist.RM_Completion_Worklist_Recheck_Fingerprint =>
            return RM_Completion_Recheck_Blocked_By_Stale_Or_Fingerprint;
         when Worklist.RM_Completion_Worklist_Repair_AST_Coverage =>
            return RM_Completion_Recheck_Blocked_By_AST_Or_Coverage;
         when Worklist.RM_Completion_Worklist_Resolve_Cross_Unit_RM_Completion =>
            return RM_Completion_Recheck_Blocked_By_Cross_Unit;
         when Worklist.RM_Completion_Worklist_Resolve_Generic_Substitution =>
            return RM_Completion_Recheck_Blocked_By_Generic_Substitution;
         when Worklist.RM_Completion_Worklist_Resolve_Prior_Dataflow =>
            return RM_Completion_Recheck_Blocked_By_Prior_Dataflow;
         when Worklist.RM_Completion_Worklist_Resolve_Volatile_Atomic_Effect =>
            return RM_Completion_Recheck_Blocked_By_Volatile_Atomic;
         when Worklist.RM_Completion_Worklist_Resolve_Overload_RM_Completion |
              Worklist.RM_Completion_Worklist_Resolve_Dispatching_Effect =>
            return RM_Completion_Recheck_Blocked_By_Overload_Type;
         when Worklist.RM_Completion_Worklist_Resolve_Representation_RM_Completion =>
            return RM_Completion_Recheck_Blocked_By_Representation;
         when Worklist.RM_Completion_Worklist_Resolve_Tasking_RM_Completion =>
            return RM_Completion_Recheck_Blocked_By_Tasking_Protected;
         when Worklist.RM_Completion_Worklist_Resolve_Elaboration_RM_Completion =>
            return RM_Completion_Recheck_Blocked_By_Elaboration;
         when Worklist.RM_Completion_Worklist_Resolve_Accessibility_RM_Completion |
              Worklist.RM_Completion_Worklist_Resolve_Access_Escape =>
            return RM_Completion_Recheck_Blocked_By_Accessibility;
         when Worklist.RM_Completion_Worklist_Resolve_Variant_Component =>
            return RM_Completion_Recheck_Blocked_By_Discriminant_Variant;
         when Worklist.RM_Completion_Worklist_Resolve_Exception_Finalization_RM_Completion |
              Worklist.RM_Completion_Worklist_Resolve_Exception_Path |
              Worklist.RM_Completion_Worklist_Resolve_Finalization_Path =>
            return RM_Completion_Recheck_Blocked_By_Exception_Finalization;
         when Worklist.RM_Completion_Worklist_Resolve_Predicate_RM_Completion =>
            return RM_Completion_Recheck_Blocked_By_Predicate_Invariant;
         when Worklist.RM_Completion_Worklist_Resolve_Read_Before_Write |
              Worklist.RM_Completion_Worklist_Resolve_Component_Initialization |
              Worklist.RM_Completion_Worklist_Resolve_Out_Parameter_Flow |
              Worklist.RM_Completion_Worklist_Resolve_Return_Object_Flow |
              Worklist.RM_Completion_Worklist_Resolve_Branch_Loop_Merge =>
            return RM_Completion_Recheck_Blocked_By_Dataflow;
         when Worklist.RM_Completion_Worklist_Resolve_View_Barrier =>
            return RM_Completion_Recheck_Blocked_By_Cross_Unit;
         when Worklist.RM_Completion_Worklist_Split_Multiple_Blockers =>
            return RM_Completion_Recheck_Multiple_Prerequisites;
         when Worklist.RM_Completion_Worklist_Recheck_Indeterminate =>
            return RM_Completion_Recheck_Indeterminate;
         when Worklist.RM_Completion_Worklist_No_Action =>
            if Worklist.Is_Ready_For_Recheck (Item) then
               return RM_Completion_Recheck_Eligible_Now;
            else
               case Item.Priority is
                  when Worklist.RM_Completion_Worklist_Priority_AST_Or_Coverage =>
                     return RM_Completion_Recheck_Blocked_By_AST_Or_Coverage;
                  when Worklist.RM_Completion_Worklist_Priority_Cross_Unit_Closure |
                       Worklist.RM_Completion_Worklist_Priority_View_Barrier =>
                     return RM_Completion_Recheck_Blocked_By_Cross_Unit;
                  when Worklist.RM_Completion_Worklist_Priority_Generic_Replay =>
                     return RM_Completion_Recheck_Blocked_By_Generic_Substitution;
                  when Worklist.RM_Completion_Worklist_Priority_Volatile_Atomic =>
                     return RM_Completion_Recheck_Blocked_By_Volatile_Atomic;
                  when Worklist.RM_Completion_Worklist_Priority_Overload_Or_Type |
                       Worklist.RM_Completion_Worklist_Priority_Dispatching =>
                     return RM_Completion_Recheck_Blocked_By_Overload_Type;
                  when Worklist.RM_Completion_Worklist_Priority_Representation =>
                     return RM_Completion_Recheck_Blocked_By_Representation;
                  when Worklist.RM_Completion_Worklist_Priority_Tasking_Protected =>
                     return RM_Completion_Recheck_Blocked_By_Tasking_Protected;
                  when Worklist.RM_Completion_Worklist_Priority_Elaboration =>
                     return RM_Completion_Recheck_Blocked_By_Elaboration;
                  when Worklist.RM_Completion_Worklist_Priority_Accessibility |
                       Worklist.RM_Completion_Worklist_Priority_Access_Escape =>
                     return RM_Completion_Recheck_Blocked_By_Accessibility;
                  when Worklist.RM_Completion_Worklist_Priority_Discriminant_Variant =>
                     return RM_Completion_Recheck_Blocked_By_Discriminant_Variant;
                  when Worklist.RM_Completion_Worklist_Priority_Exception_Finalization =>
                     return RM_Completion_Recheck_Blocked_By_Exception_Finalization;
                  when Worklist.RM_Completion_Worklist_Priority_Predicate_Invariant =>
                     return RM_Completion_Recheck_Blocked_By_Predicate_Invariant;
                  when Worklist.RM_Completion_Worklist_Priority_Dataflow =>
                     return RM_Completion_Recheck_Blocked_By_Dataflow;
                  when Worklist.RM_Completion_Worklist_Priority_Stale_Or_Fingerprint =>
                     return RM_Completion_Recheck_Blocked_By_Stale_Or_Fingerprint;
                  when Worklist.RM_Completion_Worklist_Priority_Multiple =>
                     return RM_Completion_Recheck_Multiple_Prerequisites;
                  when Worklist.RM_Completion_Worklist_Priority_Indeterminate =>
                     return RM_Completion_Recheck_Indeterminate;
                  when others =>
                     return RM_Completion_Recheck_Not_Checked;
               end case;
            end if;
      end case;
   end Status_For;

   function Action_For
     (Status : RM_Completion_Recheck_Status)
      return RM_Completion_Recheck_Action is
   begin
      case Status is
         when RM_Completion_Recheck_Not_Required_Current =>
            return RM_Completion_Recheck_Action_Keep_Current;
         when RM_Completion_Recheck_Eligible_Now =>
            return RM_Completion_Recheck_Action_Run_Now;
         when RM_Completion_Recheck_Blocked_By_Stale_Or_Fingerprint =>
            return RM_Completion_Recheck_Action_Wait_For_Fingerprint;
         when RM_Completion_Recheck_Blocked_By_AST_Or_Coverage =>
            return RM_Completion_Recheck_Action_Wait_For_AST_Repair;
         when RM_Completion_Recheck_Blocked_By_Cross_Unit =>
            return RM_Completion_Recheck_Action_Wait_For_Cross_Unit;
         when RM_Completion_Recheck_Blocked_By_Generic_Substitution =>
            return RM_Completion_Recheck_Action_Wait_For_Generic_Substitution;
         when RM_Completion_Recheck_Blocked_By_Prior_Dataflow =>
            return RM_Completion_Recheck_Action_Wait_For_Prior_Dataflow;
         when RM_Completion_Recheck_Blocked_By_Volatile_Atomic =>
            return RM_Completion_Recheck_Action_Wait_For_Volatile_Atomic;
         when RM_Completion_Recheck_Blocked_By_Overload_Type =>
            return RM_Completion_Recheck_Action_Wait_For_Overload_Type;
         when RM_Completion_Recheck_Blocked_By_Representation =>
            return RM_Completion_Recheck_Action_Wait_For_Representation;
         when RM_Completion_Recheck_Blocked_By_Tasking_Protected =>
            return RM_Completion_Recheck_Action_Wait_For_Tasking_Protected;
         when RM_Completion_Recheck_Blocked_By_Elaboration =>
            return RM_Completion_Recheck_Action_Wait_For_Elaboration;
         when RM_Completion_Recheck_Blocked_By_Accessibility =>
            return RM_Completion_Recheck_Action_Wait_For_Accessibility;
         when RM_Completion_Recheck_Blocked_By_Discriminant_Variant =>
            return RM_Completion_Recheck_Action_Wait_For_Discriminants;
         when RM_Completion_Recheck_Blocked_By_Exception_Finalization =>
            return RM_Completion_Recheck_Action_Wait_For_Exception_Finalization;
         when RM_Completion_Recheck_Blocked_By_Renaming_Alias =>
            return RM_Completion_Recheck_Action_Wait_For_Renaming;
         when RM_Completion_Recheck_Blocked_By_Predicate_Invariant =>
            return RM_Completion_Recheck_Action_Wait_For_Predicate;
         when RM_Completion_Recheck_Blocked_By_Dataflow =>
            return RM_Completion_Recheck_Action_Wait_For_Dataflow;
         when RM_Completion_Recheck_Multiple_Prerequisites =>
            return RM_Completion_Recheck_Action_Split_Prerequisites;
         when RM_Completion_Recheck_Indeterminate =>
            return RM_Completion_Recheck_Action_Degrade;
         when RM_Completion_Recheck_Not_Checked =>
            return RM_Completion_Recheck_Action_None;
      end case;
   end Action_For;

   function Rank_For
     (Priority : RM_Completion_Recheck_Work_Priority) return Natural is
   begin
      case Priority is
         when Worklist.RM_Completion_Worklist_Priority_Current_Evidence => return 0;
         when Worklist.RM_Completion_Worklist_Priority_Stale_Or_Fingerprint => return 10;
         when Worklist.RM_Completion_Worklist_Priority_AST_Or_Coverage => return 20;
         when Worklist.RM_Completion_Worklist_Priority_Cross_Unit_Closure => return 30;
         when Worklist.RM_Completion_Worklist_Priority_View_Barrier => return 35;
         when Worklist.RM_Completion_Worklist_Priority_Generic_Replay => return 40;
         when Worklist.RM_Completion_Worklist_Priority_Volatile_Atomic => return 60;
         when Worklist.RM_Completion_Worklist_Priority_Overload_Or_Type => return 70;
         when Worklist.RM_Completion_Worklist_Priority_Dispatching => return 75;
         when Worklist.RM_Completion_Worklist_Priority_Representation => return 80;
         when Worklist.RM_Completion_Worklist_Priority_Tasking_Protected => return 90;
         when Worklist.RM_Completion_Worklist_Priority_Elaboration => return 100;
         when Worklist.RM_Completion_Worklist_Priority_Accessibility => return 110;
         when Worklist.RM_Completion_Worklist_Priority_Access_Escape => return 115;
         when Worklist.RM_Completion_Worklist_Priority_Discriminant_Variant => return 120;
         when Worklist.RM_Completion_Worklist_Priority_Exception_Finalization => return 130;
         when Worklist.RM_Completion_Worklist_Priority_Predicate_Invariant => return 150;
         when Worklist.RM_Completion_Worklist_Priority_Dataflow => return 160;
         when Worklist.RM_Completion_Worklist_Priority_Multiple => return 170;
         when Worklist.RM_Completion_Worklist_Priority_Indeterminate => return 180;
         when Worklist.RM_Completion_Worklist_Priority_None => return 999;
      end case;
   end Rank_For;

   function Message_For
     (Status : RM_Completion_Recheck_Status) return Unbounded_String is
   begin
      case Status is
         when RM_Completion_Recheck_Not_Required_Current =>
            return To_Unbounded_String ("RM-completed generic/shared-state evidence is current and does not require recheck");
         when RM_Completion_Recheck_Eligible_Now =>
            return To_Unbounded_String ("RM-completed generic/shared-state row is eligible for bounded recheck now");
         when RM_Completion_Recheck_Blocked_By_Stale_Or_Fingerprint =>
            return To_Unbounded_String ("source or substitution fingerprint must be refreshed before RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_AST_Or_Coverage =>
            return To_Unbounded_String ("AST or coverage repair evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Cross_Unit =>
            return To_Unbounded_String ("cross-unit closure must complete before RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Generic_Substitution =>
            return To_Unbounded_String ("generic substitution evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Prior_Dataflow =>
            return To_Unbounded_String ("prior dataflow evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Volatile_Atomic =>
            return To_Unbounded_String ("volatile/atomic representation evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Overload_Type =>
            return To_Unbounded_String ("overload/type evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Representation =>
            return To_Unbounded_String ("representation/freezing evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Tasking_Protected =>
            return To_Unbounded_String ("tasking/protected evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Elaboration =>
            return To_Unbounded_String ("elaboration evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Accessibility =>
            return To_Unbounded_String ("accessibility/lifetime evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Discriminant_Variant =>
            return To_Unbounded_String ("discriminant/variant evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Exception_Finalization =>
            return To_Unbounded_String ("exception/finalization evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Renaming_Alias =>
            return To_Unbounded_String ("renaming/alias evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Predicate_Invariant =>
            return To_Unbounded_String ("predicate/invariant evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Blocked_By_Dataflow =>
            return To_Unbounded_String ("dataflow or initialization evidence blocks RM-completion recheck");
         when RM_Completion_Recheck_Multiple_Prerequisites =>
            return To_Unbounded_String ("multiple RM-completion prerequisites must be split before recheck");
         when RM_Completion_Recheck_Indeterminate =>
            return To_Unbounded_String ("RM-completion prerequisite remains indeterminate");
         when RM_Completion_Recheck_Not_Checked =>
            return To_Unbounded_String ("RM-completion recheck eligibility not checked");
      end case;
   end Message_For;

   function Is_Blocked (Status : RM_Completion_Recheck_Status) return Boolean is
   begin
      return Status not in RM_Completion_Recheck_Not_Checked |
                           RM_Completion_Recheck_Not_Required_Current |
                           RM_Completion_Recheck_Eligible_Now;
   end Is_Blocked;

   function Fingerprint_For
     (Item   : Worklist.RM_Completion_Worklist_Item;
      Status : RM_Completion_Recheck_Status;
      Action : RM_Completion_Recheck_Action) return Natural is
      F : Natural := 12_410;
   begin
      F := Mix (F, Natural (Item.Id));
      F := Mix (F, Natural (Item.Diagnostic_Row));
      F := Mix (F, Worklist.RM_Completion_Worklist_Action'Pos (Item.Action));
      F := Mix (F, Worklist.RM_Completion_Worklist_Priority'Pos (Item.Priority));
      F := Mix (F, RM_Completion_Recheck_Status'Pos (Status));
      F := Mix (F, RM_Completion_Recheck_Action'Pos (Action));
      F := Mix (F, Worklist.Diagnostics.RM_Completion_Diagnostic_Family'Pos (Item.Family));
      F := Mix (F, Natural (Item.Node));
      F := Mix (F, Item.Source_Fingerprint);
      F := Mix (F, Item.Substitution_Fingerprint);
      F := Mix (F, Item.Worklist_Fingerprint);
      return F;
   end Fingerprint_For;

   procedure Increment_Counters
     (Model : in out RM_Completion_Recheck_Model;
      Row   : RM_Completion_Recheck_Row) is
   begin
      if Row.Current_Evidence then
         Model.Current_Evidence_Total := Model.Current_Evidence_Total + 1;
      end if;
      if Row.Status = RM_Completion_Recheck_Eligible_Now then
         Model.Eligible_Total := Model.Eligible_Total + 1;
      end if;
      if Is_Blocked (Row.Status) then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;

      case Row.Status is
         when RM_Completion_Recheck_Blocked_By_Stale_Or_Fingerprint => Model.Fingerprint_Total := Model.Fingerprint_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Generic_Substitution => Model.Generic_Substitution_Total := Model.Generic_Substitution_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Prior_Dataflow => Model.Prior_Dataflow_Total := Model.Prior_Dataflow_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Volatile_Atomic => Model.Volatile_Atomic_Total := Model.Volatile_Atomic_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Representation => Model.Representation_Total := Model.Representation_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Tasking_Protected => Model.Tasking_Total := Model.Tasking_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Accessibility => Model.Accessibility_Total := Model.Accessibility_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Discriminant_Variant => Model.Discriminant_Total := Model.Discriminant_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Exception_Finalization => Model.Exception_Total := Model.Exception_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Renaming_Alias => Model.Renaming_Total := Model.Renaming_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Predicate_Invariant => Model.Predicate_Total := Model.Predicate_Total + 1;
         when RM_Completion_Recheck_Blocked_By_Dataflow => Model.Dataflow_Total := Model.Dataflow_Total + 1;
         when RM_Completion_Recheck_Multiple_Prerequisites => Model.Multiple_Total := Model.Multiple_Total + 1;
         when RM_Completion_Recheck_Indeterminate => Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others => null;
      end case;
   end Increment_Counters;

   procedure Append_Row
     (Model : in out RM_Completion_Recheck_Model;
      Item  : Worklist.RM_Completion_Worklist_Item) is
      Status : constant RM_Completion_Recheck_Status := Status_For (Item);
      Action : constant RM_Completion_Recheck_Action := Action_For (Status);
      Row    : RM_Completion_Recheck_Row;
   begin
      Row.Id := RM_Completion_Recheck_Id (Natural (Model.Rows.Length) + 1);
      Row.Worklist_Item := Item.Id;
      Row.Diagnostic_Row := Item.Diagnostic_Row;
      Row.Work_Action := Item.Action;
      Row.Work_Priority := Item.Priority;
      Row.Status := Status;
      Row.Action := Action;
      Row.Family := Item.Family;
      Row.Node := Item.Node;
      Row.Current_Evidence := Worklist.Is_Current_Evidence (Item);
      Row.Ready_For_Recheck := Status = RM_Completion_Recheck_Eligible_Now;
      Row.Blocks_Downstream := Is_Blocked (Status) or else Worklist.Blocks_Downstream (Item);
      Row.Priority_Rank := Rank_For (Item.Priority);
      Row.Source_Fingerprint := Item.Source_Fingerprint;
      Row.Substitution_Fingerprint := Item.Substitution_Fingerprint;
      Row.Worklist_Fingerprint := Item.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Fingerprint_For (Item, Status, Action);
      Row.Start_Line := Item.Start_Line;
      Row.Start_Column := Item.Start_Column;
      Row.End_Line := Item.End_Line;
      Row.End_Column := Item.End_Column;
      Row.Message := Message_For (Status);

      Model.Rows.Append (Row);
      Increment_Counters (Model, Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Eligibility_Fingerprint);
   end Append_Row;

   procedure Clear (Model : in out RM_Completion_Recheck_Model) is
   begin
      Model.Rows.Clear;
      Model.Current_Evidence_Total := 0;
      Model.Eligible_Total := 0;
      Model.Blocked_Total := 0;
      Model.Fingerprint_Total := 0;
      Model.Generic_Substitution_Total := 0;
      Model.Prior_Dataflow_Total := 0;
      Model.Volatile_Atomic_Total := 0;
      Model.Representation_Total := 0;
      Model.Tasking_Total := 0;
      Model.Accessibility_Total := 0;
      Model.Discriminant_Total := 0;
      Model.Exception_Total := 0;
      Model.Renaming_Total := 0;
      Model.Predicate_Total := 0;
      Model.Dataflow_Total := 0;
      Model.Multiple_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Work : Worklist.RM_Completion_Worklist_Model)
      return RM_Completion_Recheck_Model is
      Model : RM_Completion_Recheck_Model;
   begin
      for Index in 1 .. Worklist.Count (Work) loop
         Append_Row (Model, Worklist.Row_At (Work, Index));
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : RM_Completion_Recheck_Model;
      Index : Positive) return RM_Completion_Recheck_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Completion_Recheck_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Completion_Recheck_Set;
      Index : Positive) return RM_Completion_Recheck_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Add_To_Set
     (Set : in out RM_Completion_Recheck_Set;
      Row : RM_Completion_Recheck_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
   end Add_To_Set;

   function Query_Status
     (Model  : RM_Completion_Recheck_Model;
      Status : RM_Completion_Recheck_Status)
      return RM_Completion_Recheck_Set is
      Set : RM_Completion_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : RM_Completion_Recheck_Model;
      Action : RM_Completion_Recheck_Action)
      return RM_Completion_Recheck_Set is
      Set : RM_Completion_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : RM_Completion_Recheck_Model;
      Family : RM_Completion_Recheck_Family)
      return RM_Completion_Recheck_Set is
      Set : RM_Completion_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Node
     (Model : RM_Completion_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Completion_Recheck_Set is
      Set : RM_Completion_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : RM_Completion_Recheck_Model;
      Fingerprint : Natural)
      return RM_Completion_Recheck_Set is
      Set : RM_Completion_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Status
     (Model  : RM_Completion_Recheck_Model;
      Status : RM_Completion_Recheck_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : RM_Completion_Recheck_Model;
      Action : RM_Completion_Recheck_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : RM_Completion_Recheck_Model;
      Family : RM_Completion_Recheck_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Current_Evidence_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Current_Evidence_Total;
   end Current_Evidence_Count;

   function Eligible_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Eligible_Total;
   end Eligible_Count;

   function Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Fingerprint_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Fingerprint_Total;
   end Fingerprint_Blocked_Count;

   function Generic_Substitution_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Generic_Substitution_Total;
   end Generic_Substitution_Blocked_Count;

   function Prior_Dataflow_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Prior_Dataflow_Total;
   end Prior_Dataflow_Blocked_Count;

   function Volatile_Atomic_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Volatile_Atomic_Total;
   end Volatile_Atomic_Blocked_Count;

   function Representation_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Representation_Total;
   end Representation_Blocked_Count;

   function Tasking_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Tasking_Total;
   end Tasking_Blocked_Count;

   function Accessibility_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Accessibility_Total;
   end Accessibility_Blocked_Count;

   function Discriminant_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Discriminant_Total;
   end Discriminant_Blocked_Count;

   function Exception_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Exception_Total;
   end Exception_Blocked_Count;

   function Renaming_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Renaming_Total;
   end Renaming_Blocked_Count;

   function Predicate_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Predicate_Total;
   end Predicate_Blocked_Count;

   function Dataflow_Blocked_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Dataflow_Total;
   end Dataflow_Blocked_Count;

   function Multiple_Prerequisite_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Multiple_Total;
   end Multiple_Prerequisite_Count;

   function Indeterminate_Count (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : RM_Completion_Recheck_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;
