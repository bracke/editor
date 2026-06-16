with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Final_Semantic_Blocker_Remediation_Order is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;
   use type Final_Blocker_Trace_Id;
   use type Final_Blocker_Trace_Status;
   use type Final_Blocker_Trace_Root;

   function Mix (Left : Natural; Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 16#0100_0193#
        + Hash_Value (Right)
        + 16#9E37_79B9#;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Status_For
     (T : Trace.Final_Blocker_Trace) return Final_Remediation_Status is
   begin
      case T.Status is
         when Trace.Final_Trace_Accepted_Legal =>
            return Final_Remediation_No_Action_Legal;
         when Trace.Final_Trace_Stale_Rejected =>
            return Final_Remediation_Reject_Stale_Input;
         when Trace.Final_Trace_View_Barrier =>
            return Final_Remediation_Resolve_View_Barrier;
         when Trace.Final_Trace_Multiple_Blockers =>
            return Final_Remediation_Split_Multiple_Blockers;
         when Trace.Final_Trace_Indeterminate =>
            return Final_Remediation_Indeterminate;
         when Trace.Final_Trace_Missing_Search_Index =>
            return Final_Remediation_Repair_AST_Coverage;
         when Trace.Final_Trace_Emitted_Error | Trace.Final_Trace_Emitted_Warning =>
            case T.Blocker_Family is
               when Final_Prov.Final_Blocker_AST_Repair |
                    Final_Prov.Final_Blocker_Coverage_Gate =>
                  return Final_Remediation_Repair_AST_Coverage;
               when Final_Prov.Final_Blocker_Cross_Unit =>
                  return Final_Remediation_Close_Cross_Unit_Dependency;
               when Final_Prov.Final_Blocker_View_Barrier =>
                  return Final_Remediation_Resolve_View_Barrier;
               when Final_Prov.Final_Blocker_Generic_Replay =>
                  return Final_Remediation_Restore_Generic_Replay;
               when Final_Prov.Final_Blocker_Overload_Type =>
                  return Final_Remediation_Restore_Overload_Type_Evidence;
               when Final_Prov.Final_Blocker_Representation_Freezing =>
                  return Final_Remediation_Restore_Representation_Freezing;
               when Final_Prov.Final_Blocker_Flow_Contract =>
                  return Final_Remediation_Restore_Flow_Contract_Proof;
               when Final_Prov.Final_Blocker_Tasking_Protected =>
                  return Final_Remediation_Restore_Tasking_Protected_Effects;
               when Final_Prov.Final_Blocker_Elaboration =>
                  return Final_Remediation_Restore_Elaboration_Evidence;
               when Final_Prov.Final_Blocker_Accessibility_Lifetime =>
                  return Final_Remediation_Restore_Accessibility_Lifetime;
               when Final_Prov.Final_Blocker_Discriminant_Variant =>
                  return Final_Remediation_Restore_Discriminant_Variant;
               when Final_Prov.Final_Blocker_Multiple =>
                  return Final_Remediation_Split_Multiple_Blockers;
               when Final_Prov.Final_Blocker_None =>
                  return Final_Remediation_Preserve_Error;
               when Final_Prov.Final_Blocker_Unknown =>
                  return Final_Remediation_Indeterminate;
            end case;
         when Trace.Final_Trace_Not_Checked =>
            return Final_Remediation_Not_Checked;
      end case;
   end Status_For;

   function Priority_For
     (Status : Final_Remediation_Status) return Final_Remediation_Priority is
   begin
      case Status is
         when Final_Remediation_No_Action_Legal | Final_Remediation_Not_Checked =>
            return Final_Remediation_Priority_None;
         when Final_Remediation_Reject_Stale_Input =>
            return Final_Remediation_Priority_Snapshot;
         when Final_Remediation_Repair_AST_Coverage =>
            return Final_Remediation_Priority_AST_Repair;
         when Final_Remediation_Close_Cross_Unit_Dependency =>
            return Final_Remediation_Priority_Dependency;
         when Final_Remediation_Resolve_View_Barrier =>
            return Final_Remediation_Priority_View;
         when Final_Remediation_Restore_Generic_Replay =>
            return Final_Remediation_Priority_Generic_Replay;
         when Final_Remediation_Restore_Overload_Type_Evidence =>
            return Final_Remediation_Priority_Core_Type;
         when Final_Remediation_Restore_Representation_Freezing =>
            return Final_Remediation_Priority_Representation;
         when Final_Remediation_Restore_Flow_Contract_Proof |
              Final_Remediation_Restore_Accessibility_Lifetime |
              Final_Remediation_Restore_Discriminant_Variant =>
            return Final_Remediation_Priority_Object_State;
         when Final_Remediation_Restore_Tasking_Protected_Effects |
              Final_Remediation_Restore_Elaboration_Evidence |
              Final_Remediation_Preserve_Error =>
            return Final_Remediation_Priority_Consumer_Chain;
         when Final_Remediation_Split_Multiple_Blockers =>
            return Final_Remediation_Priority_Multiple;
         when Final_Remediation_Indeterminate =>
            return Final_Remediation_Priority_Indeterminate;
      end case;
   end Priority_For;

   function Order_For (Priority : Final_Remediation_Priority) return Natural is
   begin
      case Priority is
         when Final_Remediation_Priority_Snapshot => return 1;
         when Final_Remediation_Priority_AST_Repair => return 2;
         when Final_Remediation_Priority_Dependency => return 3;
         when Final_Remediation_Priority_View => return 4;
         when Final_Remediation_Priority_Generic_Replay => return 5;
         when Final_Remediation_Priority_Core_Type => return 6;
         when Final_Remediation_Priority_Representation => return 7;
         when Final_Remediation_Priority_Object_State => return 8;
         when Final_Remediation_Priority_Consumer_Chain => return 9;
         when Final_Remediation_Priority_Multiple => return 10;
         when Final_Remediation_Priority_Indeterminate => return 11;
         when Final_Remediation_Priority_None => return 0;
      end case;
   end Order_For;

   function Unlocks_For
     (Status        : Final_Remediation_Status;
      Related_Count : Natural) return Natural is
   begin
      case Status is
         when Final_Remediation_No_Action_Legal |
              Final_Remediation_Not_Checked =>
            return 0;
         when Final_Remediation_Reject_Stale_Input =>
            return Related_Count + 8;
         when Final_Remediation_Repair_AST_Coverage =>
            return Related_Count + 7;
         when Final_Remediation_Close_Cross_Unit_Dependency |
              Final_Remediation_Resolve_View_Barrier =>
            return Related_Count + 6;
         when Final_Remediation_Restore_Generic_Replay |
              Final_Remediation_Restore_Overload_Type_Evidence |
              Final_Remediation_Restore_Representation_Freezing =>
            return Related_Count + 4;
         when Final_Remediation_Restore_Flow_Contract_Proof |
              Final_Remediation_Restore_Tasking_Protected_Effects |
              Final_Remediation_Restore_Elaboration_Evidence |
              Final_Remediation_Restore_Accessibility_Lifetime |
              Final_Remediation_Restore_Discriminant_Variant =>
            return Related_Count + 2;
         when Final_Remediation_Split_Multiple_Blockers |
              Final_Remediation_Preserve_Error |
              Final_Remediation_Indeterminate =>
            return Related_Count;
      end case;
   end Unlocks_For;

   function Contains_Position
     (Action : Final_Remediation_Action;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      if Line < Action.Start_Line or else Line > Action.End_Line then
         return False;
      end if;
      if Line = Action.Start_Line and then Column < Action.Start_Column then
         return False;
      end if;
      if Line = Action.End_Line and then Column > Action.End_Column then
         return False;
      end if;
      return True;
   end Contains_Position;

   function Action_Fingerprint (Action : Final_Remediation_Action) return Natural is
      H : Natural := Natural (Action.Id);
   begin
      H := Mix (H, Natural (Action.Trace_Id) + 1);
      H := Mix (H, Final_Remediation_Status'Pos (Action.Status) + 1);
      H := Mix (H, Final_Remediation_Priority'Pos (Action.Priority) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Action.Blocker_Family) + 1);
      H := Mix (H, Final_Blocker_Trace_Status'Pos (Action.Trace_Status) + 1);
      H := Mix (H, Final_Blocker_Trace_Root'Pos (Action.Trace_Root) + 1);
      H := Mix (H, Natural (Action.Node) + 1);
      H := Mix (H, Action.Start_Line);
      H := Mix (H, Action.Start_Column);
      H := Mix (H, Action.End_Line);
      H := Mix (H, Action.End_Column);
      H := Mix (H, Action.Dependency_Order + 1);
      H := Mix (H, Action.Unlocks_Count + 1);
      H := Mix (H, Action.Source_Fingerprint + 1);
      H := Mix (H, Action.Trace_Fingerprint + 1);
      return H;
   end Action_Fingerprint;

   procedure Append_Result
     (Set    : in out Final_Remediation_Set;
      Action : Final_Remediation_Action) is
   begin
      Set.Actions.Append (Action);
      Set.Fingerprint := Mix (Set.Fingerprint, Action.Fingerprint + 1);
   end Append_Result;

   procedure Accumulate
     (Model  : in out Final_Remediation_Model;
      Action : Final_Remediation_Action) is
   begin
      case Action.Priority is
         when Final_Remediation_Priority_None =>
            if Action.Status = Final_Remediation_No_Action_Legal then
               Model.Legal_Total := Model.Legal_Total + 1;
            end if;
         when Final_Remediation_Priority_Snapshot =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Remediation_Priority_AST_Repair =>
            Model.AST_Repair_Total := Model.AST_Repair_Total + 1;
         when Final_Remediation_Priority_Dependency =>
            Model.Dependency_Total := Model.Dependency_Total + 1;
         when Final_Remediation_Priority_View =>
            Model.View_Barrier_Total := Model.View_Barrier_Total + 1;
         when Final_Remediation_Priority_Generic_Replay =>
            Model.Generic_Replay_Total := Model.Generic_Replay_Total + 1;
         when Final_Remediation_Priority_Core_Type =>
            Model.Core_Type_Total := Model.Core_Type_Total + 1;
         when Final_Remediation_Priority_Representation =>
            Model.Representation_Total := Model.Representation_Total + 1;
         when Final_Remediation_Priority_Object_State =>
            Model.Object_State_Total := Model.Object_State_Total + 1;
         when Final_Remediation_Priority_Consumer_Chain =>
            Model.Consumer_Chain_Total := Model.Consumer_Chain_Total + 1;
         when Final_Remediation_Priority_Multiple =>
            Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
         when Final_Remediation_Priority_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end case;

      if Action.Blocks_Downstream then
         Model.Blocking_Total := Model.Blocking_Total + 1;
      end if;
      Model.Downstream_Unlock_Total := Model.Downstream_Unlock_Total + Action.Unlocks_Count;
   end Accumulate;

   procedure Clear (Model : in out Final_Remediation_Model) is
   begin
      Model.Actions.Clear;
      Model.Legal_Total := 0;
      Model.Stale_Total := 0;
      Model.AST_Repair_Total := 0;
      Model.Dependency_Total := 0;
      Model.View_Barrier_Total := 0;
      Model.Generic_Replay_Total := 0;
      Model.Core_Type_Total := 0;
      Model.Representation_Total := 0;
      Model.Object_State_Total := 0;
      Model.Consumer_Chain_Total := 0;
      Model.Multiple_Blocker_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Blocking_Total := 0;
      Model.Downstream_Unlock_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Trace_Model : Trace.Final_Blocker_Trace_Model)
      return Final_Remediation_Model
   is
      Model : Final_Remediation_Model;
   begin
      for I in 1 .. Trace.Trace_Count (Trace_Model) loop
         declare
            T : constant Trace.Final_Blocker_Trace := Trace.Trace_At (Trace_Model, I);
            Action : Final_Remediation_Action;
         begin
            Action.Id := Final_Remediation_Id (I);
            Action.Trace_Id := T.Id;
            Action.Status := Status_For (T);
            Action.Priority := Priority_For (Action.Status);
            Action.Blocker_Family := T.Blocker_Family;
            Action.Trace_Status := T.Status;
            Action.Trace_Root := T.Root;
            Action.Node := T.Node;
            Action.Start_Line := T.Start_Line;
            Action.Start_Column := T.Start_Column;
            Action.End_Line := T.End_Line;
            Action.End_Column := T.End_Column;
            Action.Dependency_Order := Order_For (Action.Priority);
            Action.Blocks_Downstream := Action.Priority /= Final_Remediation_Priority_None
              and then Action.Status /= Final_Remediation_No_Action_Legal
              and then Action.Status /= Final_Remediation_Not_Checked;
            Action.Unlocks_Count := Unlocks_For (Action.Status, T.Related_Count);
            Action.Source_Fingerprint := T.Source_Fingerprint;
            Action.Trace_Fingerprint := T.Fingerprint;
            Action.Fingerprint := Action_Fingerprint (Action);

            Model.Actions.Append (Action);
            Accumulate (Model, Action);
            Model.Fingerprint := Mix (Model.Fingerprint, Action.Fingerprint);
         end;
      end loop;

      Model.Fingerprint := Mix (Model.Fingerprint, Trace.Fingerprint (Trace_Model));
      return Model;
   end Build;

   function Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Natural (Model.Actions.Length);
   end Action_Count;

   function Action_At
     (Model : Final_Remediation_Model;
      Index : Positive) return Final_Remediation_Action is
   begin
      return Model.Actions.Element (Index);
   end Action_At;

   function Set_Count (Set : Final_Remediation_Set) return Natural is
   begin
      return Natural (Set.Actions.Length);
   end Set_Count;

   function Set_At
     (Set   : Final_Remediation_Set;
      Index : Positive) return Final_Remediation_Action is
   begin
      return Set.Actions.Element (Index);
   end Set_At;

   function Query_Status
     (Model  : Final_Remediation_Model;
      Status : Final_Remediation_Status) return Final_Remediation_Set is
      Set : Final_Remediation_Set;
   begin
      for Action of Model.Actions loop
         if Action.Status = Status then
            Append_Result (Set, Action);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Priority
     (Model    : Final_Remediation_Model;
      Priority : Final_Remediation_Priority) return Final_Remediation_Set is
      Set : Final_Remediation_Set;
   begin
      for Action of Model.Actions loop
         if Action.Priority = Priority then
            Append_Result (Set, Action);
         end if;
      end loop;
      return Set;
   end Query_Priority;

   function Query_Blocker
     (Model   : Final_Remediation_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Set is
      Set : Final_Remediation_Set;
   begin
      for Action of Model.Actions loop
         if Action.Blocker_Family = Blocker then
            Append_Result (Set, Action);
         end if;
      end loop;
      return Set;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Remediation_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Set is
      Set : Final_Remediation_Set;
   begin
      for Action of Model.Actions loop
         if Action.Node = Node then
            Append_Result (Set, Action);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Position
     (Model  : Final_Remediation_Model;
      Line   : Positive;
      Column : Positive) return Final_Remediation_Set is
      Set : Final_Remediation_Set;
   begin
      for Action of Model.Actions loop
         if Contains_Position (Action, Line, Column) then
            Append_Result (Set, Action);
         end if;
      end loop;
      return Set;
   end Query_Position;

   function First_Blocking_Action
     (Model : Final_Remediation_Model) return Final_Remediation_Action is
      Best : Final_Remediation_Action;
      Have : Boolean := False;
   begin
      for Action of Model.Actions loop
         if Action.Blocks_Downstream then
            if not Have
              or else Action.Dependency_Order < Best.Dependency_Order
              or else (Action.Dependency_Order = Best.Dependency_Order
                       and then Action.Unlocks_Count > Best.Unlocks_Count)
            then
               Best := Action;
               Have := True;
            end if;
         end if;
      end loop;
      return Best;
   end First_Blocking_Action;

   function Count_Status
     (Model  : Final_Remediation_Model;
      Status : Final_Remediation_Status) return Natural is
      Total : Natural := 0;
   begin
      for Action of Model.Actions loop
         if Action.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Status;

   function Count_Priority
     (Model    : Final_Remediation_Model;
      Priority : Final_Remediation_Priority) return Natural is
      Total : Natural := 0;
   begin
      for Action of Model.Actions loop
         if Action.Priority = Priority then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Priority;

   function Count_Blocker
     (Model   : Final_Remediation_Model;
      Blocker : Final_Blocker_Family) return Natural is
      Total : Natural := 0;
   begin
      for Action of Model.Actions loop
         if Action.Blocker_Family = Blocker then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Blocker;

   function Legal_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Action_Count;

   function Stale_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Action_Count;

   function AST_Repair_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.AST_Repair_Total;
   end AST_Repair_Action_Count;

   function Dependency_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Dependency_Total;
   end Dependency_Action_Count;

   function View_Barrier_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.View_Barrier_Total;
   end View_Barrier_Action_Count;

   function Generic_Replay_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Generic_Replay_Total;
   end Generic_Replay_Action_Count;

   function Core_Type_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Core_Type_Total;
   end Core_Type_Action_Count;

   function Representation_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Representation_Total;
   end Representation_Action_Count;

   function Object_State_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Object_State_Total;
   end Object_State_Action_Count;

   function Consumer_Chain_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Consumer_Chain_Total;
   end Consumer_Chain_Action_Count;

   function Multiple_Blocker_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Action_Count;

   function Indeterminate_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Action_Count;

   function Blocking_Action_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Blocking_Total;
   end Blocking_Action_Count;

   function Downstream_Unlock_Count (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Downstream_Unlock_Total;
   end Downstream_Unlock_Count;

   function Fingerprint (Model : Final_Remediation_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Blocker_Remediation_Order;
