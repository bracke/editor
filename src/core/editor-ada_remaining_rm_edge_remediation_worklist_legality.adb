package body Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality is

   pragma Suppress (Overflow_Check);
   use type Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family;
   use type Edge.Remaining_RM_Edge_Blocker_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 12_860) mod 2_147_483_647;
   end Mix;

   function Action_For
     (Row : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Row)
      return Remaining_RM_Edge_Worklist_Action is
   begin
      case Row.Status is
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Withheld_Accepted_Current |
              Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Withheld_Accepted_Not_Required =>
            return Remaining_RM_Edge_Worklist_Keep_Current_Evidence;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Remaining_Edge_Blocker =>
            return Remaining_RM_Edge_Worklist_Resolve_Remaining_Edge;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Missing_Stabilized_Closure |
              Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Stabilized_Closure_Blocker =>
            return Remaining_RM_Edge_Worklist_Resolve_Stabilized_Closure;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Stabilized_Closure_Recheck_Required =>
            return Remaining_RM_Edge_Worklist_Recheck_Required;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Source_Fingerprint_Mismatch =>
            return Remaining_RM_Edge_Worklist_Recheck_Source_Fingerprint;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Substitution_Fingerprint_Mismatch =>
            return Remaining_RM_Edge_Worklist_Recheck_Substitution_Fingerprint;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Multiple_Blockers =>
            return Remaining_RM_Edge_Worklist_Split_Multiple_Blockers;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Indeterminate =>
            return Remaining_RM_Edge_Worklist_Recheck_Indeterminate;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Not_Checked =>
            return Remaining_RM_Edge_Worklist_No_Action;
      end case;
   end Action_For;

   function Priority_For
     (Action : Remaining_RM_Edge_Worklist_Action) return Remaining_RM_Edge_Worklist_Priority is
   begin
      case Action is
         when Remaining_RM_Edge_Worklist_Keep_Current_Evidence =>
            return Remaining_RM_Edge_Worklist_Priority_Current_Evidence;
         when Remaining_RM_Edge_Worklist_Resolve_Remaining_Edge =>
            return Remaining_RM_Edge_Worklist_Priority_Remaining_Edge;
         when Remaining_RM_Edge_Worklist_Resolve_Stabilized_Closure =>
            return Remaining_RM_Edge_Worklist_Priority_Stabilized_Closure;
         when Remaining_RM_Edge_Worklist_Recheck_Source_Fingerprint |
              Remaining_RM_Edge_Worklist_Recheck_Substitution_Fingerprint =>
            return Remaining_RM_Edge_Worklist_Priority_Fingerprint;
         when Remaining_RM_Edge_Worklist_Split_Multiple_Blockers =>
            return Remaining_RM_Edge_Worklist_Priority_Multiple;
         when Remaining_RM_Edge_Worklist_Recheck_Required =>
            return Remaining_RM_Edge_Worklist_Priority_Recheck;
         when Remaining_RM_Edge_Worklist_Recheck_Indeterminate =>
            return Remaining_RM_Edge_Worklist_Priority_Indeterminate;
         when Remaining_RM_Edge_Worklist_No_Action =>
            return Remaining_RM_Edge_Worklist_Priority_None;
      end case;
   end Priority_For;

   function Fingerprint_For
     (Row      : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Row;
      Action   : Remaining_RM_Edge_Worklist_Action;
      Priority : Remaining_RM_Edge_Worklist_Priority) return Natural is
      F : Natural := 12_861;
   begin
      F := Mix (F, Natural (Row.Id));
      F := Mix (F, Natural (Row.Consumer_Row));
      F := Mix (F, Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Status'Pos (Row.Status));
      F := Mix (F, Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family'Pos (Row.Family));
      F := Mix (F, Edge.Remaining_RM_Edge_Kind'Pos (Row.Remaining_Edge_Kind));
      F := Mix (F, Edge.Remaining_RM_Edge_Blocker_Family'Pos (Row.Remaining_Edge_Blocker));
      F := Mix (F, Remaining_RM_Edge_Worklist_Action'Pos (Action));
      F := Mix (F, Remaining_RM_Edge_Worklist_Priority'Pos (Priority));
      F := Mix (F, Natural (Row.Node));
      F := Mix (F, Row.Source_Fingerprint);
      F := Mix (F, Row.Substitution_Fingerprint);
      F := Mix (F, Row.Edge_Fingerprint);
      F := Mix (F, Row.Closure_Fingerprint);
      F := Mix (F, Row.Diagnostic_Fingerprint);
      return F;
   end Fingerprint_For;

   procedure Append_Item
     (Model : in out Remaining_RM_Edge_Worklist_Model;
      Row   : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Row) is
      Action   : constant Remaining_RM_Edge_Worklist_Action := Action_For (Row);
      Priority : constant Remaining_RM_Edge_Worklist_Priority := Priority_For (Action);
      Item     : Remaining_RM_Edge_Worklist_Item;
   begin
      Item.Id := Remaining_RM_Edge_Worklist_Id (Natural (Model.Rows.Length) + 1);
      Item.Diagnostic_Row := Row.Id;
      Item.Diagnostic_Status := Row.Status;
      Item.Diagnostic_Family := Row.Family;
      Item.Remaining_Edge_Kind := Row.Remaining_Edge_Kind;
      Item.Remaining_Edge_Blocker := Row.Remaining_Edge_Blocker;
      Item.Action := Action;
      Item.Priority := Priority;
      Item.Node := Row.Node;
      Item.Current_Evidence := Diagnostics.Is_Withheld_Current (Row.Status);
      Item.Ready_For_Recheck := Action not in Remaining_RM_Edge_Worklist_No_Action |
                                           Remaining_RM_Edge_Worklist_Keep_Current_Evidence;
      Item.Blocks_Downstream := Item.Ready_For_Recheck or else Row.Blocks_Downstream or else Row.Emitted;
      Item.Source_Fingerprint := Row.Source_Fingerprint;
      Item.Substitution_Fingerprint := Row.Substitution_Fingerprint;
      Item.Edge_Fingerprint := Row.Edge_Fingerprint;
      Item.Closure_Fingerprint := Row.Closure_Fingerprint;
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
      if Action in Remaining_RM_Edge_Worklist_Recheck_Source_Fingerprint |
                   Remaining_RM_Edge_Worklist_Recheck_Substitution_Fingerprint then
         Model.Fingerprint_Mismatch_Total := Model.Fingerprint_Mismatch_Total + 1;
      end if;
      if Action = Remaining_RM_Edge_Worklist_Recheck_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;

      Model.Stable_Fingerprint_Value := Mix (Model.Stable_Fingerprint_Value, Item.Worklist_Fingerprint);
      Model.Rows.Append (Item);
   end Append_Item;

   procedure Clear (Model : in out Remaining_RM_Edge_Worklist_Model) is
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
     (Diagnostics_Model : Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Model)
      return Remaining_RM_Edge_Worklist_Model is
      Model : Remaining_RM_Edge_Worklist_Model;
   begin
      for Index in 1 .. Diagnostics.Row_Count (Diagnostics_Model) loop
         Append_Item (Model, Diagnostics.Row_At (Diagnostics_Model, Index));
      end loop;
      return Model;
   end Build;

   function Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Remaining_RM_Edge_Worklist_Model;
      Index : Positive) return Remaining_RM_Edge_Worklist_Item is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Worklist_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Worklist_Set;
      Index : Positive) return Remaining_RM_Edge_Worklist_Item is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append
     (Set : in out Remaining_RM_Edge_Worklist_Set;
      Row : Remaining_RM_Edge_Worklist_Item) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Worklist_Fingerprint);
   end Append;

   function Query_Action
     (Model  : Remaining_RM_Edge_Worklist_Model;
      Action : Remaining_RM_Edge_Worklist_Action) return Remaining_RM_Edge_Worklist_Set is
      Set : Remaining_RM_Edge_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Remaining_RM_Edge_Worklist_Model;
      Family : Remaining_RM_Edge_Worklist_Diagnostic_Family) return Remaining_RM_Edge_Worklist_Set is
      Set : Remaining_RM_Edge_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Diagnostic_Family = Family then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Priority
     (Model    : Remaining_RM_Edge_Worklist_Model;
      Priority : Remaining_RM_Edge_Worklist_Priority) return Remaining_RM_Edge_Worklist_Set is
      Set : Remaining_RM_Edge_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Priority = Priority then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Priority;

   function Query_Edge_Blocker
     (Model   : Remaining_RM_Edge_Worklist_Model;
      Blocker : Remaining_RM_Edge_Blocker_Family) return Remaining_RM_Edge_Worklist_Set is
      Set : Remaining_RM_Edge_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Remaining_Edge_Blocker = Blocker then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Edge_Blocker;

   function Query_Node
     (Model : Remaining_RM_Edge_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Worklist_Set is
      Set : Remaining_RM_Edge_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Worklist_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Worklist_Set is
      Set : Remaining_RM_Edge_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Action
     (Model  : Remaining_RM_Edge_Worklist_Model;
      Action : Remaining_RM_Edge_Worklist_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : Remaining_RM_Edge_Worklist_Model;
      Family : Remaining_RM_Edge_Worklist_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Count_Priority
     (Model    : Remaining_RM_Edge_Worklist_Model;
      Priority : Remaining_RM_Edge_Worklist_Priority) return Natural is
   begin
      return Query_Count (Query_Priority (Model, Priority));
   end Count_Priority;

   function Current_Evidence_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural is
   begin
      return Model.Current_Evidence_Total;
   end Current_Evidence_Count;

   function Ready_For_Recheck_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural is
   begin
      return Model.Ready_For_Recheck_Total;
   end Ready_For_Recheck_Count;

   function Blocked_Downstream_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural is
   begin
      return Model.Blocked_Downstream_Total;
   end Blocked_Downstream_Count;

   function Fingerprint_Mismatch_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural is
   begin
      return Model.Fingerprint_Mismatch_Total;
   end Fingerprint_Mismatch_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Worklist_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Remaining_RM_Edge_Worklist_Model) return Natural is
   begin
      return Model.Stable_Fingerprint_Value;
   end Stable_Fingerprint;

   function Is_Current_Evidence (Item : Remaining_RM_Edge_Worklist_Item) return Boolean is
   begin
      return Item.Current_Evidence;
   end Is_Current_Evidence;

   function Is_Ready_For_Recheck (Item : Remaining_RM_Edge_Worklist_Item) return Boolean is
   begin
      return Item.Ready_For_Recheck;
   end Is_Ready_For_Recheck;

   function Blocks_Downstream (Item : Remaining_RM_Edge_Worklist_Item) return Boolean is
   begin
      return Item.Blocks_Downstream;
   end Blocks_Downstream;

end Editor.Ada_Remaining_RM_Edge_Remediation_Worklist_Legality;
