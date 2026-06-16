with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Shared_State_Recheck_Eligibility_Legality is

   pragma Suppress (Overflow_Check);
   use type Shared_State_Recheck_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 2_191) mod 2_147_483_647;
   end Mix;

   function Status_For
     (Item : Worklist.Shared_State_Worklist_Item)
      return Shared_State_Recheck_Status is
   begin
      case Item.Action is
         when Worklist.Shared_State_Worklist_Keep_Current_Evidence =>
            return Shared_State_Recheck_Not_Required_Current;
         when Worklist.Shared_State_Worklist_Close_Cross_Unit_Dependency =>
            return Shared_State_Recheck_Blocked_By_Cross_Unit;
         when Worklist.Shared_State_Worklist_Resolve_View_Barrier =>
            return Shared_State_Recheck_Blocked_By_View_Barrier;
         when Worklist.Shared_State_Worklist_Repair_Generic_Backmapping =>
            return Shared_State_Recheck_Blocked_By_Generic_Backmapping;
         when Worklist.Shared_State_Worklist_Repair_State_Visibility =>
            return Shared_State_Recheck_Blocked_By_State_Visibility;
         when Worklist.Shared_State_Worklist_Resolve_Abstract_State =>
            return Shared_State_Recheck_Blocked_By_Abstract_State;
         when Worklist.Shared_State_Worklist_Resolve_Volatile_Atomic =>
            return Shared_State_Recheck_Blocked_By_Volatile_Atomic;
         when Worklist.Shared_State_Worklist_Resolve_Overload_Type =>
            return Shared_State_Recheck_Blocked_By_Overload_Type;
         when Worklist.Shared_State_Worklist_Resolve_Representation =>
            return Shared_State_Recheck_Blocked_By_Representation;
         when Worklist.Shared_State_Worklist_Resolve_Tasking_Protected =>
            return Shared_State_Recheck_Blocked_By_Tasking_Protected;
         when Worklist.Shared_State_Worklist_Recheck_Source_Fingerprint =>
            return Shared_State_Recheck_Blocked_By_Fingerprint;
         when Worklist.Shared_State_Worklist_Split_Multiple_Blockers =>
            return Shared_State_Recheck_Multiple_Prerequisites;
         when Worklist.Shared_State_Worklist_Recheck_Indeterminate =>
            return Shared_State_Recheck_Indeterminate;
         when Worklist.Shared_State_Worklist_No_Action =>
            if Worklist.Is_Ready_For_Recheck (Item) then
               return Shared_State_Recheck_Eligible_Now;
            else
               return Shared_State_Recheck_Not_Checked;
            end if;
      end case;
   end Status_For;

   function Action_For
     (Status : Shared_State_Recheck_Status)
      return Shared_State_Recheck_Action is
   begin
      case Status is
         when Shared_State_Recheck_Not_Required_Current =>
            return Shared_State_Recheck_Action_Keep_Current;
         when Shared_State_Recheck_Eligible_Now =>
            return Shared_State_Recheck_Action_Run_Now;
         when Shared_State_Recheck_Blocked_By_Cross_Unit =>
            return Shared_State_Recheck_Action_Wait_For_Cross_Unit;
         when Shared_State_Recheck_Blocked_By_View_Barrier =>
            return Shared_State_Recheck_Action_Wait_For_View_Repair;
         when Shared_State_Recheck_Blocked_By_Generic_Backmapping =>
            return Shared_State_Recheck_Action_Wait_For_Generic_Backmapping;
         when Shared_State_Recheck_Blocked_By_State_Visibility =>
            return Shared_State_Recheck_Action_Wait_For_State_Visibility;
         when Shared_State_Recheck_Blocked_By_Abstract_State =>
            return Shared_State_Recheck_Action_Wait_For_Abstract_State;
         when Shared_State_Recheck_Blocked_By_Volatile_Atomic =>
            return Shared_State_Recheck_Action_Wait_For_Volatile_Atomic;
         when Shared_State_Recheck_Blocked_By_Overload_Type =>
            return Shared_State_Recheck_Action_Wait_For_Overload_Type;
         when Shared_State_Recheck_Blocked_By_Representation =>
            return Shared_State_Recheck_Action_Wait_For_Representation;
         when Shared_State_Recheck_Blocked_By_Tasking_Protected =>
            return Shared_State_Recheck_Action_Wait_For_Tasking_Protected;
         when Shared_State_Recheck_Blocked_By_Fingerprint =>
            return Shared_State_Recheck_Action_Wait_For_Source_Fingerprint;
         when Shared_State_Recheck_Multiple_Prerequisites =>
            return Shared_State_Recheck_Action_Split_Prerequisites;
         when Shared_State_Recheck_Indeterminate =>
            return Shared_State_Recheck_Action_Degrade;
         when Shared_State_Recheck_Not_Checked =>
            return Shared_State_Recheck_Action_None;
      end case;
   end Action_For;

   function Rank_For
     (Priority : Shared_State_Recheck_Work_Priority) return Natural is
   begin
      case Priority is
         when Worklist.Shared_State_Worklist_Priority_Current_Evidence => return 0;
         when Worklist.Shared_State_Worklist_Priority_Stale_Or_Fingerprint => return 10;
         when Worklist.Shared_State_Worklist_Priority_Dependency => return 20;
         when Worklist.Shared_State_Worklist_Priority_View => return 30;
         when Worklist.Shared_State_Worklist_Priority_Generic_Backmapping => return 40;
         when Worklist.Shared_State_Worklist_Priority_State_Metadata => return 50;
         when Worklist.Shared_State_Worklist_Priority_Abstract_State => return 60;
         when Worklist.Shared_State_Worklist_Priority_Volatile_Atomic => return 70;
         when Worklist.Shared_State_Worklist_Priority_Overload_Type => return 80;
         when Worklist.Shared_State_Worklist_Priority_Representation => return 90;
         when Worklist.Shared_State_Worklist_Priority_Tasking_Protected => return 100;
         when Worklist.Shared_State_Worklist_Priority_Multiple => return 110;
         when Worklist.Shared_State_Worklist_Priority_Indeterminate => return 120;
         when Worklist.Shared_State_Worklist_Priority_None => return 999;
      end case;
   end Rank_For;

   function Message_For
     (Status : Shared_State_Recheck_Status) return Unbounded_String is
   begin
      case Status is
         when Shared_State_Recheck_Not_Required_Current =>
            return To_Unbounded_String ("shared-state evidence is current and does not require recheck");
         when Shared_State_Recheck_Eligible_Now =>
            return To_Unbounded_String ("shared-state semantic row is eligible for bounded recheck now");
         when Shared_State_Recheck_Blocked_By_Cross_Unit =>
            return To_Unbounded_String ("cross-unit shared-state dependency must close before recheck");
         when Shared_State_Recheck_Blocked_By_View_Barrier =>
            return To_Unbounded_String ("private or limited view barrier blocks shared-state recheck");
         when Shared_State_Recheck_Blocked_By_Generic_Backmapping =>
            return To_Unbounded_String ("generic source/instance backmapping blocks shared-state recheck");
         when Shared_State_Recheck_Blocked_By_State_Visibility =>
            return To_Unbounded_String ("abstract-state visibility metadata blocks shared-state recheck");
         when Shared_State_Recheck_Blocked_By_Abstract_State =>
            return To_Unbounded_String ("abstract/refined-state evidence blocks shared-state recheck");
         when Shared_State_Recheck_Blocked_By_Volatile_Atomic =>
            return To_Unbounded_String ("volatile/atomic/shared-variable evidence blocks shared-state recheck");
         when Shared_State_Recheck_Blocked_By_Overload_Type =>
            return To_Unbounded_String ("overload/type shared-state evidence blocks shared-state recheck");
         when Shared_State_Recheck_Blocked_By_Representation =>
            return To_Unbounded_String ("representation/freezing shared-state evidence blocks shared-state recheck");
         when Shared_State_Recheck_Blocked_By_Tasking_Protected =>
            return To_Unbounded_String ("tasking/protected shared-state evidence blocks shared-state recheck");
         when Shared_State_Recheck_Blocked_By_Fingerprint =>
            return To_Unbounded_String ("source fingerprint mismatch blocks shared-state recheck");
         when Shared_State_Recheck_Multiple_Prerequisites =>
            return To_Unbounded_String ("multiple shared-state prerequisites must be split before recheck");
         when Shared_State_Recheck_Indeterminate =>
            return To_Unbounded_String ("shared-state prerequisite remains indeterminate");
         when Shared_State_Recheck_Not_Checked =>
            return To_Unbounded_String ("shared-state recheck eligibility not checked");
      end case;
   end Message_For;

   function Is_Blocked (Status : Shared_State_Recheck_Status) return Boolean is
   begin
      return Status not in Shared_State_Recheck_Not_Checked |
                           Shared_State_Recheck_Not_Required_Current |
                           Shared_State_Recheck_Eligible_Now;
   end Is_Blocked;

   function Fingerprint_For
     (Item   : Worklist.Shared_State_Worklist_Item;
      Status : Shared_State_Recheck_Status;
      Action : Shared_State_Recheck_Action) return Natural is
      F : Natural := 12_190;
   begin
      F := Mix (F, Natural (Item.Id));
      F := Mix (F, Natural (Item.Stabilized_Row));
      F := Mix (F, Worklist.Shared_State_Worklist_Action'Pos (Item.Action));
      F := Mix (F, Worklist.Shared_State_Worklist_Priority'Pos (Item.Priority));
      F := Mix (F, Shared_State_Recheck_Status'Pos (Status));
      F := Mix (F, Shared_State_Recheck_Action'Pos (Action));
      F := Mix (F, Stable.Shared_State_Stabilized_Family'Pos (Item.Family));
      F := Mix (F, Natural (Item.Node));
      F := Mix (F, Item.Source_Fingerprint);
      F := Mix (F, Item.Worklist_Fingerprint);
      return F;
   end Fingerprint_For;

   procedure Increment_Counters
     (Model : in out Shared_State_Recheck_Model;
      Row   : Shared_State_Recheck_Row) is
   begin
      if Row.Current_Evidence then
         Model.Current_Evidence_Total := Model.Current_Evidence_Total + 1;
      end if;
      if Row.Status = Shared_State_Recheck_Eligible_Now then
         Model.Eligible_Total := Model.Eligible_Total + 1;
      end if;
      if Is_Blocked (Row.Status) then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;

      case Row.Status is
         when Shared_State_Recheck_Blocked_By_Cross_Unit => Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Shared_State_Recheck_Blocked_By_View_Barrier => Model.View_Total := Model.View_Total + 1;
         when Shared_State_Recheck_Blocked_By_Generic_Backmapping => Model.Generic_Total := Model.Generic_Total + 1;
         when Shared_State_Recheck_Blocked_By_State_Visibility => Model.State_Visibility_Total := Model.State_Visibility_Total + 1;
         when Shared_State_Recheck_Blocked_By_Abstract_State => Model.Abstract_State_Total := Model.Abstract_State_Total + 1;
         when Shared_State_Recheck_Blocked_By_Volatile_Atomic => Model.Volatile_Atomic_Total := Model.Volatile_Atomic_Total + 1;
         when Shared_State_Recheck_Blocked_By_Overload_Type => Model.Overload_Total := Model.Overload_Total + 1;
         when Shared_State_Recheck_Blocked_By_Representation => Model.Representation_Total := Model.Representation_Total + 1;
         when Shared_State_Recheck_Blocked_By_Tasking_Protected => Model.Tasking_Total := Model.Tasking_Total + 1;
         when Shared_State_Recheck_Blocked_By_Fingerprint => Model.Fingerprint_Total := Model.Fingerprint_Total + 1;
         when Shared_State_Recheck_Multiple_Prerequisites => Model.Multiple_Total := Model.Multiple_Total + 1;
         when Shared_State_Recheck_Indeterminate => Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others => null;
      end case;
   end Increment_Counters;

   procedure Append_Row
     (Model : in out Shared_State_Recheck_Model;
      Item  : Worklist.Shared_State_Worklist_Item) is
      Status : constant Shared_State_Recheck_Status := Status_For (Item);
      Action : constant Shared_State_Recheck_Action := Action_For (Status);
      Row    : Shared_State_Recheck_Row;
   begin
      Row.Id := Shared_State_Recheck_Id (Natural (Model.Rows.Length) + 1);
      Row.Worklist_Item := Item.Id;
      Row.Work_Action := Item.Action;
      Row.Work_Priority := Item.Priority;
      Row.Status := Status;
      Row.Action := Action;
      Row.Family := Item.Family;
      Row.Node := Item.Node;
      Row.Unit_Name := Item.Unit_Name;
      Row.Dependency_Name := Item.Dependency_Name;
      Row.State_Name := Item.State_Name;
      Row.Current_Evidence := Worklist.Is_Current_Evidence (Item);
      Row.Ready_For_Recheck := Status = Shared_State_Recheck_Eligible_Now;
      Row.Blocks_Downstream := Is_Blocked (Status) or else Worklist.Blocks_Downstream (Item);
      Row.Priority_Rank := Rank_For (Item.Priority);
      Row.Source_Fingerprint := Item.Source_Fingerprint;
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

   procedure Clear (Model : in out Shared_State_Recheck_Model) is
   begin
      Model.Rows.Clear;
      Model.Current_Evidence_Total := 0;
      Model.Eligible_Total := 0;
      Model.Blocked_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.View_Total := 0;
      Model.Generic_Total := 0;
      Model.State_Visibility_Total := 0;
      Model.Abstract_State_Total := 0;
      Model.Volatile_Atomic_Total := 0;
      Model.Overload_Total := 0;
      Model.Representation_Total := 0;
      Model.Tasking_Total := 0;
      Model.Fingerprint_Total := 0;
      Model.Multiple_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Work : Worklist.Shared_State_Worklist_Model)
      return Shared_State_Recheck_Model is
      Model : Shared_State_Recheck_Model;
   begin
      for Index in 1 .. Worklist.Row_Count (Work) loop
         Append_Row (Model, Worklist.Row_At (Work, Index));
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Shared_State_Recheck_Model;
      Index : Positive) return Shared_State_Recheck_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Shared_State_Recheck_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Shared_State_Recheck_Set;
      Index : Positive) return Shared_State_Recheck_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Add_To_Set
     (Set : in out Shared_State_Recheck_Set;
      Row : Shared_State_Recheck_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
   end Add_To_Set;

   function Query_Status
     (Model  : Shared_State_Recheck_Model;
      Status : Shared_State_Recheck_Status) return Shared_State_Recheck_Set is
      Set : Shared_State_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Shared_State_Recheck_Model;
      Action : Shared_State_Recheck_Action) return Shared_State_Recheck_Set is
      Set : Shared_State_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Shared_State_Recheck_Model;
      Family : Shared_State_Recheck_Family) return Shared_State_Recheck_Set is
      Set : Shared_State_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Node
     (Model : Shared_State_Recheck_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Recheck_Set is
      Set : Shared_State_Recheck_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Count_Status
     (Model  : Shared_State_Recheck_Model;
      Status : Shared_State_Recheck_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : Shared_State_Recheck_Model;
      Action : Shared_State_Recheck_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : Shared_State_Recheck_Model;
      Family : Shared_State_Recheck_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Current_Evidence_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Current_Evidence_Total;
   end Current_Evidence_Count;

   function Eligible_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Eligible_Total;
   end Eligible_Count;

   function Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Cross_Unit_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Cross_Unit_Total;
   end Cross_Unit_Blocked_Count;

   function View_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.View_Total;
   end View_Blocked_Count;

   function Generic_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Generic_Total;
   end Generic_Blocked_Count;

   function State_Visibility_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.State_Visibility_Total;
   end State_Visibility_Blocked_Count;

   function Abstract_State_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Abstract_State_Total;
   end Abstract_State_Blocked_Count;

   function Volatile_Atomic_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Volatile_Atomic_Total;
   end Volatile_Atomic_Blocked_Count;

   function Overload_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Overload_Total;
   end Overload_Blocked_Count;

   function Representation_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Representation_Total;
   end Representation_Blocked_Count;

   function Tasking_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Tasking_Total;
   end Tasking_Blocked_Count;

   function Fingerprint_Blocked_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Fingerprint_Total;
   end Fingerprint_Blocked_Count;

   function Multiple_Prerequisite_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Multiple_Total;
   end Multiple_Prerequisite_Count;

   function Indeterminate_Count (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Shared_State_Recheck_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Shared_State_Recheck_Eligibility_Legality;
