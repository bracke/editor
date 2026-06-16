with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Shared_State_Remediation_Worklist_Legality is

   pragma Suppress (Overflow_Check);
   use type Shared_State_Worklist_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 2_181) mod 2_147_483_647;
   end Mix;

   function Is_Current_Evidence (Item : Shared_State_Worklist_Item) return Boolean is
   begin
      return Item.Current_Evidence;
   end Is_Current_Evidence;

   function Is_Ready_For_Recheck (Item : Shared_State_Worklist_Item) return Boolean is
   begin
      return Item.Ready_For_Recheck;
   end Is_Ready_For_Recheck;

   function Blocks_Downstream (Item : Shared_State_Worklist_Item) return Boolean is
   begin
      return Item.Blocks_Downstream;
   end Blocks_Downstream;

   procedure Clear (Model : in out Shared_State_Worklist_Model) is
   begin
      Model.Rows.Clear;
      Model.Current_Evidence_Total := 0;
      Model.Ready_For_Recheck_Total := 0;
      Model.Blocked_Downstream_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Action_For
     (Row : Stable.Shared_State_Stabilized_Row)
      return Shared_State_Worklist_Action is
   begin
      case Row.Status is
         when Stable.Shared_State_Stabilized_Withheld_Accepted_Current =>
            return Shared_State_Worklist_Keep_Current_Evidence;
         when Stable.Shared_State_Stabilized_Dependency_Blocker |
              Stable.Shared_State_Stabilized_Cross_Unit_Blocker =>
            return Shared_State_Worklist_Close_Cross_Unit_Dependency;
         when Stable.Shared_State_Stabilized_View_Barrier =>
            return Shared_State_Worklist_Resolve_View_Barrier;
         when Stable.Shared_State_Stabilized_Generic_Backmapping_Blocker =>
            return Shared_State_Worklist_Repair_Generic_Backmapping;
         when Stable.Shared_State_Stabilized_State_Visibility_Blocker =>
            return Shared_State_Worklist_Repair_State_Visibility;
         when Stable.Shared_State_Stabilized_Abstract_State_Blocker =>
            return Shared_State_Worklist_Resolve_Abstract_State;
         when Stable.Shared_State_Stabilized_Shared_State_Blocker =>
            return Shared_State_Worklist_Resolve_Volatile_Atomic;
         when Stable.Shared_State_Stabilized_Overload_Type_Blocker =>
            return Shared_State_Worklist_Resolve_Overload_Type;
         when Stable.Shared_State_Stabilized_Representation_Blocker =>
            return Shared_State_Worklist_Resolve_Representation;
         when Stable.Shared_State_Stabilized_Tasking_Protected_Blocker =>
            return Shared_State_Worklist_Resolve_Tasking_Protected;
         when Stable.Shared_State_Stabilized_Source_Fingerprint_Mismatch =>
            return Shared_State_Worklist_Recheck_Source_Fingerprint;
         when Stable.Shared_State_Stabilized_Multiple_Blockers =>
            return Shared_State_Worklist_Split_Multiple_Blockers;
         when Stable.Shared_State_Stabilized_Indeterminate =>
            return Shared_State_Worklist_Recheck_Indeterminate;
         when others =>
            return Shared_State_Worklist_No_Action;
      end case;
   end Action_For;

   function Priority_For
     (Action : Shared_State_Worklist_Action)
      return Shared_State_Worklist_Priority is
   begin
      case Action is
         when Shared_State_Worklist_Keep_Current_Evidence =>
            return Shared_State_Worklist_Priority_Current_Evidence;
         when Shared_State_Worklist_Recheck_Source_Fingerprint =>
            return Shared_State_Worklist_Priority_Stale_Or_Fingerprint;
         when Shared_State_Worklist_Close_Cross_Unit_Dependency =>
            return Shared_State_Worklist_Priority_Dependency;
         when Shared_State_Worklist_Resolve_View_Barrier =>
            return Shared_State_Worklist_Priority_View;
         when Shared_State_Worklist_Repair_Generic_Backmapping =>
            return Shared_State_Worklist_Priority_Generic_Backmapping;
         when Shared_State_Worklist_Repair_State_Visibility =>
            return Shared_State_Worklist_Priority_State_Metadata;
         when Shared_State_Worklist_Resolve_Abstract_State =>
            return Shared_State_Worklist_Priority_Abstract_State;
         when Shared_State_Worklist_Resolve_Volatile_Atomic =>
            return Shared_State_Worklist_Priority_Volatile_Atomic;
         when Shared_State_Worklist_Resolve_Overload_Type =>
            return Shared_State_Worklist_Priority_Overload_Type;
         when Shared_State_Worklist_Resolve_Representation =>
            return Shared_State_Worklist_Priority_Representation;
         when Shared_State_Worklist_Resolve_Tasking_Protected =>
            return Shared_State_Worklist_Priority_Tasking_Protected;
         when Shared_State_Worklist_Split_Multiple_Blockers =>
            return Shared_State_Worklist_Priority_Multiple;
         when Shared_State_Worklist_Recheck_Indeterminate =>
            return Shared_State_Worklist_Priority_Indeterminate;
         when Shared_State_Worklist_No_Action =>
            return Shared_State_Worklist_Priority_None;
      end case;
   end Priority_For;

   function Message_For
     (Action : Shared_State_Worklist_Action)
      return Unbounded_String is
   begin
      case Action is
         when Shared_State_Worklist_Keep_Current_Evidence =>
            return To_Unbounded_String ("shared-state semantic evidence is current");
         when Shared_State_Worklist_Close_Cross_Unit_Dependency =>
            return To_Unbounded_String ("close cross-unit shared-state dependency before downstream recheck");
         when Shared_State_Worklist_Resolve_View_Barrier =>
            return To_Unbounded_String ("resolve private or limited view barrier before shared-state recheck");
         when Shared_State_Worklist_Repair_Generic_Backmapping =>
            return To_Unbounded_String ("repair generic source/instance backmapping before shared-state recheck");
         when Shared_State_Worklist_Repair_State_Visibility =>
            return To_Unbounded_String ("repair cross-unit abstract-state visibility before shared-state recheck");
         when Shared_State_Worklist_Resolve_Abstract_State =>
            return To_Unbounded_String ("resolve abstract/refined state evidence before shared-state recheck");
         when Shared_State_Worklist_Resolve_Volatile_Atomic =>
            return To_Unbounded_String ("resolve volatile/atomic/shared-variable evidence before downstream recheck");
         when Shared_State_Worklist_Resolve_Overload_Type =>
            return To_Unbounded_String ("resolve overload/type shared-state evidence before downstream recheck");
         when Shared_State_Worklist_Resolve_Representation =>
            return To_Unbounded_String ("resolve representation/freezing shared-state evidence before downstream recheck");
         when Shared_State_Worklist_Resolve_Tasking_Protected =>
            return To_Unbounded_String ("resolve tasking/protected shared-state evidence before downstream recheck");
         when Shared_State_Worklist_Recheck_Source_Fingerprint =>
            return To_Unbounded_String ("refresh source fingerprint before trusting shared-state evidence");
         when Shared_State_Worklist_Split_Multiple_Blockers =>
            return To_Unbounded_String ("split multiple shared-state blockers into prerequisite work items");
         when Shared_State_Worklist_Recheck_Indeterminate =>
            return To_Unbounded_String ("recheck indeterminate shared-state evidence after prerequisites");
         when Shared_State_Worklist_No_Action =>
            return To_Unbounded_String ("no shared-state remediation action");
      end case;
   end Message_For;

   function Fingerprint_For
     (Row      : Stable.Shared_State_Stabilized_Row;
      Action   : Shared_State_Worklist_Action;
      Priority : Shared_State_Worklist_Priority) return Natural is
      F : Natural := 12_180;
   begin
      F := Mix (F, Natural (Row.Id));
      F := Mix (F, Natural (Row.Cross_Shared_Row));
      F := Mix (F, Shared_State_Worklist_Action'Pos (Action));
      F := Mix (F, Shared_State_Worklist_Priority'Pos (Priority));
      F := Mix (F, Stable.Shared_State_Stabilized_Status'Pos (Row.Status));
      F := Mix (F, Stable.Shared_State_Stabilized_Family'Pos (Row.Family));
      F := Mix (F, Natural (Row.Node));
      F := Mix (F, Row.Source_Fingerprint);
      F := Mix (F, Row.Diagnostic_Fingerprint);
      return F;
   end Fingerprint_For;

   procedure Append_Item
     (Model : in out Shared_State_Worklist_Model;
      Row   : Stable.Shared_State_Stabilized_Row) is
      Action   : constant Shared_State_Worklist_Action := Action_For (Row);
      Priority : constant Shared_State_Worklist_Priority := Priority_For (Action);
      Item     : Shared_State_Worklist_Item;
   begin
      Item.Id := Shared_State_Worklist_Id (Natural (Model.Rows.Length) + 1);
      Item.Stabilized_Row := Row.Id;
      Item.Stabilized_Status := Row.Status;
      Item.Family := Row.Family;
      Item.Action := Action;
      Item.Priority := Priority;
      Item.Node := Row.Node;
      Item.Unit_Name := Row.Unit_Name;
      Item.Dependency_Name := Row.Dependency_Name;
      Item.State_Name := Row.State_Name;
      Item.Current_Evidence := Stable.Is_Withheld_Current (Row.Status);
      Item.Ready_For_Recheck := Action not in Shared_State_Worklist_No_Action |
                                           Shared_State_Worklist_Keep_Current_Evidence;
      Item.Blocks_Downstream := Item.Ready_For_Recheck or else Stable.Is_Emitted (Row.Status);
      Item.Message := Message_For (Action);
      Item.Detail := Row.Detail;
      Item.Source_Fingerprint := Row.Source_Fingerprint;
      Item.Diagnostic_Fingerprint := Row.Diagnostic_Fingerprint;
      Item.Start_Line := Row.Start_Line;
      Item.Start_Column := Row.Start_Column;
      Item.End_Line := Row.End_Line;
      Item.End_Column := Row.End_Column;
      Item.Worklist_Fingerprint := Fingerprint_For (Row, Action, Priority);

      if Item.Current_Evidence then
         Model.Current_Evidence_Total := Model.Current_Evidence_Total + 1;
      end if;
      if Item.Ready_For_Recheck then
         Model.Ready_For_Recheck_Total := Model.Ready_For_Recheck_Total + 1;
      end if;
      if Item.Blocks_Downstream then
         Model.Blocked_Downstream_Total := Model.Blocked_Downstream_Total + 1;
      end if;

      Model.Fingerprint := Mix (Model.Fingerprint, Item.Worklist_Fingerprint);
      Model.Rows.Append (Item);
   end Append_Item;

   function Build
     (Diagnostics : Stable.Shared_State_Stabilized_Model)
      return Shared_State_Worklist_Model is
      Model : Shared_State_Worklist_Model;
   begin
      for Index in 1 .. Stable.Row_Count (Diagnostics) loop
         Append_Item (Model, Stable.Row_At (Diagnostics, Index));
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Shared_State_Worklist_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Shared_State_Worklist_Model;
      Index : Positive) return Shared_State_Worklist_Item is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Shared_State_Worklist_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Shared_State_Worklist_Set;
      Index : Positive) return Shared_State_Worklist_Item is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Action
     (Model  : Shared_State_Worklist_Model;
      Action : Shared_State_Worklist_Action) return Shared_State_Worklist_Set is
      Set : Shared_State_Worklist_Set;
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
     (Model  : Shared_State_Worklist_Model;
      Family : Shared_State_Worklist_Family) return Shared_State_Worklist_Set is
      Set : Shared_State_Worklist_Set;
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
     (Model    : Shared_State_Worklist_Model;
      Priority : Shared_State_Worklist_Priority) return Shared_State_Worklist_Set is
      Set : Shared_State_Worklist_Set;
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
     (Model : Shared_State_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Worklist_Set is
      Set : Shared_State_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Set.Rows.Append (Row);
            Set.Fingerprint := Mix (Set.Fingerprint, Row.Worklist_Fingerprint);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Count_Action
     (Model  : Shared_State_Worklist_Model;
      Action : Shared_State_Worklist_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : Shared_State_Worklist_Model;
      Family : Shared_State_Worklist_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Count_Priority
     (Model    : Shared_State_Worklist_Model;
      Priority : Shared_State_Worklist_Priority) return Natural is
   begin
      return Query_Count (Query_Priority (Model, Priority));
   end Count_Priority;

   function Current_Evidence_Count (Model : Shared_State_Worklist_Model) return Natural is
   begin
      return Model.Current_Evidence_Total;
   end Current_Evidence_Count;

   function Ready_For_Recheck_Count (Model : Shared_State_Worklist_Model) return Natural is
   begin
      return Model.Ready_For_Recheck_Total;
   end Ready_For_Recheck_Count;

   function Blocked_Downstream_Count (Model : Shared_State_Worklist_Model) return Natural is
   begin
      return Model.Blocked_Downstream_Total;
   end Blocked_Downstream_Count;

   function Fingerprint (Model : Shared_State_Worklist_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Shared_State_Remediation_Worklist_Legality;
