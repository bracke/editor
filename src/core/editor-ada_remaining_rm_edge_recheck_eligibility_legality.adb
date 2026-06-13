package body Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 12_870) mod 2_147_483_647;
   end Mix;

   function Status_For
     (Item : Worklist.Remaining_RM_Edge_Worklist_Item)
      return Remaining_RM_Edge_Recheck_Status is
   begin
      case Item.Action is
         when Worklist.Remaining_RM_Edge_Worklist_Keep_Current_Evidence =>
            return Remaining_RM_Edge_Recheck_Not_Required_Current;
         when Worklist.Remaining_RM_Edge_Worklist_Resolve_Remaining_Edge =>
            return Remaining_RM_Edge_Recheck_Blocked_By_Remaining_Edge;
         when Worklist.Remaining_RM_Edge_Worklist_Resolve_Stabilized_Closure =>
            return Remaining_RM_Edge_Recheck_Blocked_By_Stabilized_Closure;
         when Worklist.Remaining_RM_Edge_Worklist_Recheck_Source_Fingerprint =>
            return Remaining_RM_Edge_Recheck_Blocked_By_Source_Fingerprint;
         when Worklist.Remaining_RM_Edge_Worklist_Recheck_Substitution_Fingerprint =>
            return Remaining_RM_Edge_Recheck_Blocked_By_Substitution_Fingerprint;
         when Worklist.Remaining_RM_Edge_Worklist_Split_Multiple_Blockers =>
            return Remaining_RM_Edge_Recheck_Multiple_Prerequisites;
         when Worklist.Remaining_RM_Edge_Worklist_Recheck_Required =>
            return Remaining_RM_Edge_Recheck_Recheck_Required;
         when Worklist.Remaining_RM_Edge_Worklist_Recheck_Indeterminate =>
            return Remaining_RM_Edge_Recheck_Indeterminate;
         when Worklist.Remaining_RM_Edge_Worklist_No_Action =>
            if Item.Ready_For_Recheck then
               return Remaining_RM_Edge_Recheck_Eligible_Now;
            else
               return Remaining_RM_Edge_Recheck_Not_Checked;
            end if;
      end case;
   end Status_For;

   function Action_For
     (Status : Remaining_RM_Edge_Recheck_Status)
      return Remaining_RM_Edge_Recheck_Action is
   begin
      case Status is
         when Remaining_RM_Edge_Recheck_Not_Required_Current =>
            return Remaining_RM_Edge_Recheck_Action_Keep_Current;
         when Remaining_RM_Edge_Recheck_Eligible_Now =>
            return Remaining_RM_Edge_Recheck_Action_Run_Now;
         when Remaining_RM_Edge_Recheck_Blocked_By_Remaining_Edge =>
            return Remaining_RM_Edge_Recheck_Action_Wait_For_Remaining_Edge;
         when Remaining_RM_Edge_Recheck_Blocked_By_Stabilized_Closure =>
            return Remaining_RM_Edge_Recheck_Action_Wait_For_Stabilized_Closure;
         when Remaining_RM_Edge_Recheck_Blocked_By_Source_Fingerprint =>
            return Remaining_RM_Edge_Recheck_Action_Wait_For_Source_Fingerprint;
         when Remaining_RM_Edge_Recheck_Blocked_By_Substitution_Fingerprint =>
            return Remaining_RM_Edge_Recheck_Action_Wait_For_Substitution_Fingerprint;
         when Remaining_RM_Edge_Recheck_Multiple_Prerequisites =>
            return Remaining_RM_Edge_Recheck_Action_Split_Prerequisites;
         when Remaining_RM_Edge_Recheck_Recheck_Required =>
            return Remaining_RM_Edge_Recheck_Action_Wait_For_Recheck_Gate;
         when Remaining_RM_Edge_Recheck_Indeterminate =>
            return Remaining_RM_Edge_Recheck_Action_Degrade;
         when Remaining_RM_Edge_Recheck_Not_Checked =>
            return Remaining_RM_Edge_Recheck_Action_None;
      end case;
   end Action_For;

   function Rank_For
     (Priority : Remaining_RM_Edge_Recheck_Work_Priority) return Natural is
   begin
      case Priority is
         when Worklist.Remaining_RM_Edge_Worklist_Priority_Current_Evidence => return 0;
         when Worklist.Remaining_RM_Edge_Worklist_Priority_Remaining_Edge => return 10;
         when Worklist.Remaining_RM_Edge_Worklist_Priority_Stabilized_Closure => return 20;
         when Worklist.Remaining_RM_Edge_Worklist_Priority_Fingerprint => return 30;
         when Worklist.Remaining_RM_Edge_Worklist_Priority_Multiple => return 40;
         when Worklist.Remaining_RM_Edge_Worklist_Priority_Recheck => return 50;
         when Worklist.Remaining_RM_Edge_Worklist_Priority_Indeterminate => return 60;
         when Worklist.Remaining_RM_Edge_Worklist_Priority_None => return 999;
      end case;
   end Rank_For;

   function Is_Blocked (Status : Remaining_RM_Edge_Recheck_Status) return Boolean is
   begin
      return Status not in Remaining_RM_Edge_Recheck_Not_Checked |
                           Remaining_RM_Edge_Recheck_Not_Required_Current |
                           Remaining_RM_Edge_Recheck_Eligible_Now;
   end Is_Blocked;

   function Fingerprint_For
     (Item   : Worklist.Remaining_RM_Edge_Worklist_Item;
      Status : Remaining_RM_Edge_Recheck_Status;
      Action : Remaining_RM_Edge_Recheck_Action) return Natural is
      F : Natural := 12_871;
   begin
      F := Mix (F, Natural (Item.Id));
      F := Mix (F, Natural (Item.Diagnostic_Row));
      F := Mix (F, Worklist.Remaining_RM_Edge_Worklist_Action'Pos (Item.Action));
      F := Mix (F, Worklist.Remaining_RM_Edge_Worklist_Priority'Pos (Item.Priority));
      F := Mix (F, Remaining_RM_Edge_Recheck_Status'Pos (Status));
      F := Mix (F, Remaining_RM_Edge_Recheck_Action'Pos (Action));
      F := Mix (F, Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family'Pos (Item.Diagnostic_Family));
      F := Mix (F, Edge.Remaining_RM_Edge_Kind'Pos (Item.Remaining_Edge_Kind));
      F := Mix (F, Edge.Remaining_RM_Edge_Blocker_Family'Pos (Item.Remaining_Edge_Blocker));
      F := Mix (F, Natural (Item.Node));
      F := Mix (F, Item.Source_Fingerprint);
      F := Mix (F, Item.Substitution_Fingerprint);
      F := Mix (F, Item.Edge_Fingerprint);
      F := Mix (F, Item.Closure_Fingerprint);
      F := Mix (F, Item.Diagnostic_Fingerprint);
      F := Mix (F, Item.Worklist_Fingerprint);
      return F;
   end Fingerprint_For;

   procedure Increment_Counters
     (Model : in out Remaining_RM_Edge_Recheck_Model;
      Row   : Remaining_RM_Edge_Recheck_Row) is
   begin
      if Row.Current_Evidence then
         Model.Current_Evidence_Total := Model.Current_Evidence_Total + 1;
      end if;
      if Row.Eligible_Now then
         Model.Eligible_Total := Model.Eligible_Total + 1;
      end if;
      if Is_Blocked (Row.Status) then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;

      case Row.Status is
         when Remaining_RM_Edge_Recheck_Blocked_By_Remaining_Edge =>
            Model.Remaining_Edge_Blocked_Total := Model.Remaining_Edge_Blocked_Total + 1;
         when Remaining_RM_Edge_Recheck_Blocked_By_Stabilized_Closure =>
            Model.Closure_Blocked_Total := Model.Closure_Blocked_Total + 1;
         when Remaining_RM_Edge_Recheck_Blocked_By_Source_Fingerprint |
              Remaining_RM_Edge_Recheck_Blocked_By_Substitution_Fingerprint =>
            Model.Fingerprint_Blocked_Total := Model.Fingerprint_Blocked_Total + 1;
         when Remaining_RM_Edge_Recheck_Multiple_Prerequisites =>
            Model.Multiple_Total := Model.Multiple_Total + 1;
         when Remaining_RM_Edge_Recheck_Recheck_Required =>
            Model.Recheck_Required_Total := Model.Recheck_Required_Total + 1;
         when Remaining_RM_Edge_Recheck_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others =>
            null;
      end case;
   end Increment_Counters;

   procedure Append_Row
     (Model : in out Remaining_RM_Edge_Recheck_Model;
      Item  : Worklist.Remaining_RM_Edge_Worklist_Item) is
      Status : constant Remaining_RM_Edge_Recheck_Status := Status_For (Item);
      Action : constant Remaining_RM_Edge_Recheck_Action := Action_For (Status);
      Row    : Remaining_RM_Edge_Recheck_Row;
   begin
      Row.Id := Remaining_RM_Edge_Recheck_Id (Natural (Model.Rows.Length) + 1);
      Row.Worklist_Item := Item.Id;
      Row.Diagnostic_Row := Item.Diagnostic_Row;
      Row.Diagnostic_Status := Item.Diagnostic_Status;
      Row.Diagnostic_Family := Item.Diagnostic_Family;
      Row.Remaining_Edge_Kind := Item.Remaining_Edge_Kind;
      Row.Remaining_Edge_Blocker := Item.Remaining_Edge_Blocker;
      Row.Work_Action := Item.Action;
      Row.Work_Priority := Item.Priority;
      Row.Status := Status;
      Row.Action := Action;
      Row.Node := Item.Node;
      Row.Current_Evidence := Item.Current_Evidence;
      Row.Eligible_Now := Status = Remaining_RM_Edge_Recheck_Eligible_Now;
      Row.Blocks_Downstream := Is_Blocked (Status) or else Item.Blocks_Downstream;
      Row.Priority_Rank := Rank_For (Item.Priority);
      Row.Source_Fingerprint := Item.Source_Fingerprint;
      Row.Substitution_Fingerprint := Item.Substitution_Fingerprint;
      Row.Edge_Fingerprint := Item.Edge_Fingerprint;
      Row.Closure_Fingerprint := Item.Closure_Fingerprint;
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

   procedure Clear (Model : in out Remaining_RM_Edge_Recheck_Model) is
   begin
      Model.Rows.Clear;
      Model.Current_Evidence_Total := 0;
      Model.Eligible_Total := 0;
      Model.Blocked_Total := 0;
      Model.Remaining_Edge_Blocked_Total := 0;
      Model.Closure_Blocked_Total := 0;
      Model.Fingerprint_Blocked_Total := 0;
      Model.Multiple_Total := 0;
      Model.Recheck_Required_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Stable_Fingerprint_Value := 0;
   end Clear;

   function Build
     (Work : Worklist.Remaining_RM_Edge_Worklist_Model)
      return Remaining_RM_Edge_Recheck_Model is
      Model : Remaining_RM_Edge_Recheck_Model;
   begin
      for Index in 1 .. Worklist.Count (Work) loop
         Append_Row (Model, Worklist.Row_At (Work, Index));
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Remaining_RM_Edge_Recheck_Model;
      Index : Positive) return Remaining_RM_Edge_Recheck_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Recheck_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Recheck_Set;
      Index : Positive) return Remaining_RM_Edge_Recheck_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append
     (Set : in out Remaining_RM_Edge_Recheck_Set;
      Row : Remaining_RM_Edge_Recheck_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
   end Append;

   function Query_Status
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Status : Remaining_RM_Edge_Recheck_Status) return Remaining_RM_Edge_Recheck_Set is
      Set : Remaining_RM_Edge_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Action : Remaining_RM_Edge_Recheck_Action) return Remaining_RM_Edge_Recheck_Set is
      Set : Remaining_RM_Edge_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Family : Remaining_RM_Edge_Recheck_Diagnostic_Family) return Remaining_RM_Edge_Recheck_Set is
      Set : Remaining_RM_Edge_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Diagnostic_Family = Family then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Node
     (Model : Remaining_RM_Edge_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Recheck_Set is
      Set : Remaining_RM_Edge_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Recheck_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Recheck_Set is
      Set : Remaining_RM_Edge_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Status
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Status : Remaining_RM_Edge_Recheck_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Action : Remaining_RM_Edge_Recheck_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : Remaining_RM_Edge_Recheck_Model;
      Family : Remaining_RM_Edge_Recheck_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Current_Evidence_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Current_Evidence_Total;
   end Current_Evidence_Count;

   function Eligible_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Eligible_Total;
   end Eligible_Count;

   function Blocked_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Remaining_Edge_Blocked_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Remaining_Edge_Blocked_Total;
   end Remaining_Edge_Blocked_Count;

   function Stabilized_Closure_Blocked_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Closure_Blocked_Total;
   end Stabilized_Closure_Blocked_Count;

   function Fingerprint_Blocked_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Fingerprint_Blocked_Total;
   end Fingerprint_Blocked_Count;

   function Multiple_Prerequisite_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Multiple_Total;
   end Multiple_Prerequisite_Count;

   function Recheck_Required_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Recheck_Required_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Remaining_RM_Edge_Recheck_Model) return Natural is
   begin
      return Model.Stable_Fingerprint_Value;
   end Stable_Fingerprint;

   function Is_Current_Evidence (Row : Remaining_RM_Edge_Recheck_Row) return Boolean is
   begin
      return Row.Current_Evidence;
   end Is_Current_Evidence;

   function Is_Eligible_Now (Row : Remaining_RM_Edge_Recheck_Row) return Boolean is
   begin
      return Row.Eligible_Now;
   end Is_Eligible_Now;

   function Blocks_Downstream (Row : Remaining_RM_Edge_Recheck_Row) return Boolean is
   begin
      return Row.Blocks_Downstream;
   end Blocks_Downstream;

end Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality;
