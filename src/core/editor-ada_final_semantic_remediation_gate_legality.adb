with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Final_Semantic_Remediation_Gate_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;
   use type Final_Gate_Action;
   use type Final_Gate_Status;
   use type Final_Remediation_Priority;
   use type Final_Remediation_Status;

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
     (Action : Remediation.Final_Remediation_Action) return Final_Gate_Status is
   begin
      case Action.Status is
         when Remediation.Final_Remediation_No_Action_Legal =>
            return Final_Gate_Confident_Legal;
         when Remediation.Final_Remediation_Reject_Stale_Input =>
            return Final_Gate_Withheld_Stale_Input;
         when Remediation.Final_Remediation_Repair_AST_Coverage =>
            return Final_Gate_Withheld_AST_Coverage;
         when Remediation.Final_Remediation_Close_Cross_Unit_Dependency =>
            return Final_Gate_Withheld_Cross_Unit_Dependency;
         when Remediation.Final_Remediation_Resolve_View_Barrier =>
            return Final_Gate_Withheld_View_Barrier;
         when Remediation.Final_Remediation_Restore_Generic_Replay =>
            return Final_Gate_Withheld_Generic_Replay;
         when Remediation.Final_Remediation_Restore_Overload_Type_Evidence =>
            return Final_Gate_Withheld_Overload_Type;
         when Remediation.Final_Remediation_Restore_Representation_Freezing =>
            return Final_Gate_Withheld_Representation_Freezing;
         when Remediation.Final_Remediation_Restore_Flow_Contract_Proof =>
            return Final_Gate_Withheld_Flow_Contract;
         when Remediation.Final_Remediation_Restore_Tasking_Protected_Effects =>
            return Final_Gate_Withheld_Tasking_Protected;
         when Remediation.Final_Remediation_Restore_Elaboration_Evidence =>
            return Final_Gate_Withheld_Elaboration;
         when Remediation.Final_Remediation_Restore_Accessibility_Lifetime =>
            return Final_Gate_Withheld_Accessibility_Lifetime;
         when Remediation.Final_Remediation_Restore_Discriminant_Variant =>
            return Final_Gate_Withheld_Discriminant_Variant;
         when Remediation.Final_Remediation_Split_Multiple_Blockers =>
            return Final_Gate_Withheld_Multiple_Blockers;
         when Remediation.Final_Remediation_Preserve_Error =>
            return Final_Gate_Preserve_Semantic_Error;
         when Remediation.Final_Remediation_Indeterminate =>
            return Final_Gate_Indeterminate;
         when Remediation.Final_Remediation_Not_Checked =>
            return Final_Gate_Not_Checked;
      end case;
   end Status_For;

   function Gate_Action_For
     (Status : Final_Gate_Status) return Final_Gate_Action is
   begin
      case Status is
         when Final_Gate_Confident_Legal =>
            return Final_Gate_Action_Allow_Confident_Result;
         when Final_Gate_Preserve_Semantic_Error =>
            return Final_Gate_Action_Preserve_Original_Error;
         when Final_Gate_Indeterminate | Final_Gate_Not_Checked =>
            return Final_Gate_Action_Degrade_To_Indeterminate;
         when others =>
            return Final_Gate_Action_Require_Prerequisite_Remediation;
      end case;
   end Gate_Action_For;

   function Is_Withheld (Status : Final_Gate_Status) return Boolean is
   begin
      case Status is
         when Final_Gate_Withheld_Stale_Input
            | Final_Gate_Withheld_AST_Coverage
            | Final_Gate_Withheld_Cross_Unit_Dependency
            | Final_Gate_Withheld_View_Barrier
            | Final_Gate_Withheld_Generic_Replay
            | Final_Gate_Withheld_Overload_Type
            | Final_Gate_Withheld_Representation_Freezing
            | Final_Gate_Withheld_Flow_Contract
            | Final_Gate_Withheld_Tasking_Protected
            | Final_Gate_Withheld_Elaboration
            | Final_Gate_Withheld_Accessibility_Lifetime
            | Final_Gate_Withheld_Discriminant_Variant
            | Final_Gate_Withheld_Multiple_Blockers =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Withheld;

   function Is_Object_State
     (Status : Final_Gate_Status;
      Priority : Final_Remediation_Priority) return Boolean is
   begin
      return Status in Final_Gate_Withheld_Flow_Contract
                    | Final_Gate_Withheld_Accessibility_Lifetime
                    | Final_Gate_Withheld_Discriminant_Variant
        or else Priority = Remediation.Final_Remediation_Priority_Object_State;
   end Is_Object_State;

   function Is_Consumer_Chain
     (Status : Final_Gate_Status;
      Priority : Final_Remediation_Priority) return Boolean is
   begin
      return Status in Final_Gate_Withheld_Tasking_Protected
                    | Final_Gate_Withheld_Elaboration
        or else Priority = Remediation.Final_Remediation_Priority_Consumer_Chain;
   end Is_Consumer_Chain;

   function From_Action
     (Id     : Final_Gate_Id;
      Source : Remediation.Final_Remediation_Action) return Final_Gated_Result is
      Status : constant Final_Gate_Status := Status_For (Source);
      Result : Final_Gated_Result;
   begin
      Result.Id := Id;
      Result.Remediation_Id := Source.Id;
      Result.Status := Status;
      Result.Action := Gate_Action_For (Status);
      Result.Remediation_Status := Source.Status;
      Result.Priority := Source.Priority;
      Result.Blocker_Family := Source.Blocker_Family;
      Result.Node := Source.Node;
      Result.Start_Line := Source.Start_Line;
      Result.Start_Column := Source.Start_Column;
      Result.End_Line := Source.End_Line;
      Result.End_Column := Source.End_Column;
      Result.Dependency_Order := Source.Dependency_Order;
      Result.Prerequisite_Blocking := Is_Withheld (Status)
        or else Status = Final_Gate_Indeterminate;
      Result.Legal_Result_Withheld := Is_Withheld (Status)
        or else Result.Action = Final_Gate_Action_Degrade_To_Indeterminate;
      Result.Downstream_Blocked := Source.Unlocks_Count;
      if Result.Prerequisite_Blocking and then Result.Downstream_Blocked = 0 then
         Result.Downstream_Blocked := 1;
      end if;
      Result.Source_Fingerprint := Source.Source_Fingerprint;
      Result.Remediation_Fingerprint := Source.Fingerprint;
      Result.Fingerprint := Mix (Natural (Id), Source.Fingerprint);
      Result.Fingerprint := Mix (Result.Fingerprint, Natural (Final_Gate_Status'Pos (Status)));
      Result.Fingerprint := Mix (Result.Fingerprint, Natural (Final_Gate_Action'Pos (Result.Action)));
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Natural (Final_Prov.Final_Blocker_Family'Pos (Result.Blocker_Family)));
      Result.Fingerprint := Mix (Result.Fingerprint, Result.Downstream_Blocked);
      return Result;
   end From_Action;

   procedure Note (Model : in out Final_Gated_Model; Row : Final_Gated_Result) is
   begin
      case Row.Status is
         when Final_Gate_Confident_Legal =>
            Model.Confident_Legal_Total := Model.Confident_Legal_Total + 1;
         when Final_Gate_Withheld_Stale_Input =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.Stale_Withheld_Total := Model.Stale_Withheld_Total + 1;
         when Final_Gate_Withheld_AST_Coverage =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.AST_Coverage_Withheld_Total := Model.AST_Coverage_Withheld_Total + 1;
         when Final_Gate_Withheld_Cross_Unit_Dependency =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.Dependency_Withheld_Total := Model.Dependency_Withheld_Total + 1;
         when Final_Gate_Withheld_View_Barrier =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.View_Barrier_Withheld_Total := Model.View_Barrier_Withheld_Total + 1;
         when Final_Gate_Withheld_Generic_Replay =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.Generic_Replay_Withheld_Total := Model.Generic_Replay_Withheld_Total + 1;
         when Final_Gate_Withheld_Overload_Type =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.Core_Type_Withheld_Total := Model.Core_Type_Withheld_Total + 1;
         when Final_Gate_Withheld_Representation_Freezing =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.Representation_Withheld_Total := Model.Representation_Withheld_Total + 1;
         when Final_Gate_Withheld_Flow_Contract
            | Final_Gate_Withheld_Accessibility_Lifetime
            | Final_Gate_Withheld_Discriminant_Variant =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.Object_State_Withheld_Total := Model.Object_State_Withheld_Total + 1;
         when Final_Gate_Withheld_Tasking_Protected
            | Final_Gate_Withheld_Elaboration =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.Consumer_Chain_Withheld_Total := Model.Consumer_Chain_Withheld_Total + 1;
         when Final_Gate_Withheld_Multiple_Blockers =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
            Model.Multiple_Blocker_Withheld_Total := Model.Multiple_Blocker_Withheld_Total + 1;
         when Final_Gate_Preserve_Semantic_Error =>
            Model.Preserved_Error_Total := Model.Preserved_Error_Total + 1;
         when Final_Gate_Indeterminate | Final_Gate_Not_Checked =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end case;

      if Is_Object_State (Row.Status, Row.Priority)
        and then Row.Status not in Final_Gate_Withheld_Flow_Contract
                              | Final_Gate_Withheld_Accessibility_Lifetime
                              | Final_Gate_Withheld_Discriminant_Variant
      then
         Model.Object_State_Withheld_Total := Model.Object_State_Withheld_Total + 1;
      end if;

      if Is_Consumer_Chain (Row.Status, Row.Priority)
        and then Row.Status not in Final_Gate_Withheld_Tasking_Protected
                              | Final_Gate_Withheld_Elaboration
      then
         Model.Consumer_Chain_Withheld_Total := Model.Consumer_Chain_Withheld_Total + 1;
      end if;

      if Row.Prerequisite_Blocking then
         Model.Prerequisite_Blocking_Total := Model.Prerequisite_Blocking_Total + 1;
      end if;
      if Row.Legal_Result_Withheld then
         Model.Legal_Result_Withheld_Total := Model.Legal_Result_Withheld_Total + 1;
      end if;
      Model.Downstream_Blocked_Total := Model.Downstream_Blocked_Total + Row.Downstream_Blocked;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Note;

   procedure Append (Set : in out Final_Gated_Result_Set; Row : Final_Gated_Result) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
   end Append;

   procedure Clear (Model : in out Final_Gated_Model) is
   begin
      Model.Rows.Clear;
      Model.Confident_Legal_Total := 0;
      Model.Withheld_Total := 0;
      Model.Stale_Withheld_Total := 0;
      Model.AST_Coverage_Withheld_Total := 0;
      Model.Dependency_Withheld_Total := 0;
      Model.View_Barrier_Withheld_Total := 0;
      Model.Generic_Replay_Withheld_Total := 0;
      Model.Core_Type_Withheld_Total := 0;
      Model.Representation_Withheld_Total := 0;
      Model.Object_State_Withheld_Total := 0;
      Model.Consumer_Chain_Withheld_Total := 0;
      Model.Multiple_Blocker_Withheld_Total := 0;
      Model.Preserved_Error_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Prerequisite_Blocking_Total := 0;
      Model.Legal_Result_Withheld_Total := 0;
      Model.Downstream_Blocked_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Remediation_Model : Remediation.Final_Remediation_Model)
      return Final_Gated_Model is
      Model : Final_Gated_Model;
      Row : Final_Gated_Result;
   begin
      for I in 1 .. Remediation.Action_Count (Remediation_Model) loop
         Row := From_Action
           (Final_Gate_Id (I),
            Remediation.Action_At (Remediation_Model, I));
         Model.Rows.Append (Row);
         Note (Model, Row);
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Gated_Model;
      Index : Positive) return Final_Gated_Result is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Set_Count (Set : Final_Gated_Result_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Final_Gated_Result_Set;
      Index : Positive) return Final_Gated_Result is
   begin
      return Set.Rows.Element (Index);
   end Set_At;

   function Query_Status
     (Model  : Final_Gated_Model;
      Status : Final_Gate_Status) return Final_Gated_Result_Set is
      Set : Final_Gated_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Final_Gated_Model;
      Action : Final_Gate_Action) return Final_Gated_Result_Set is
      Set : Final_Gated_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Blocker
     (Model   : Final_Gated_Model;
      Blocker : Final_Blocker_Family) return Final_Gated_Result_Set is
      Set : Final_Gated_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Gated_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Gated_Result_Set is
      Set : Final_Gated_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Position
     (Model  : Final_Gated_Model;
      Line   : Positive;
      Column : Positive) return Final_Gated_Result_Set is
      Set : Final_Gated_Result_Set;
   begin
      for Row of Model.Rows loop
         if Line >= Row.Start_Line
           and then Line <= Row.End_Line
           and then Column >= Row.Start_Column
           and then Column <= Row.End_Column
         then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Position;

   function Count_Status
     (Model  : Final_Gated_Model;
      Status : Final_Gate_Status) return Natural is
   begin
      return Set_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : Final_Gated_Model;
      Action : Final_Gate_Action) return Natural is
   begin
      return Set_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Blocker
     (Model   : Final_Gated_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Set_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Confident_Legal_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Confident_Legal_Total;
   end Confident_Legal_Count;

   function Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Stale_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Stale_Withheld_Total;
   end Stale_Withheld_Count;

   function AST_Coverage_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.AST_Coverage_Withheld_Total;
   end AST_Coverage_Withheld_Count;

   function Dependency_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Dependency_Withheld_Total;
   end Dependency_Withheld_Count;

   function View_Barrier_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.View_Barrier_Withheld_Total;
   end View_Barrier_Withheld_Count;

   function Generic_Replay_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Generic_Replay_Withheld_Total;
   end Generic_Replay_Withheld_Count;

   function Core_Type_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Core_Type_Withheld_Total;
   end Core_Type_Withheld_Count;

   function Representation_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Representation_Withheld_Total;
   end Representation_Withheld_Count;

   function Object_State_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Object_State_Withheld_Total;
   end Object_State_Withheld_Count;

   function Consumer_Chain_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Consumer_Chain_Withheld_Total;
   end Consumer_Chain_Withheld_Count;

   function Multiple_Blocker_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Withheld_Total;
   end Multiple_Blocker_Withheld_Count;

   function Preserved_Error_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Preserved_Error_Total;
   end Preserved_Error_Count;

   function Indeterminate_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Prerequisite_Blocking_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Prerequisite_Blocking_Total;
   end Prerequisite_Blocking_Count;

   function Legal_Result_Withheld_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Legal_Result_Withheld_Total;
   end Legal_Result_Withheld_Count;

   function Downstream_Blocked_Count (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Downstream_Blocked_Total;
   end Downstream_Blocked_Count;

   function First_Prerequisite_Blocker
     (Model : Final_Gated_Model) return Final_Gated_Result is
      Best : Final_Gated_Result;
      Have : Boolean := False;
   begin
      for Row of Model.Rows loop
         if Row.Prerequisite_Blocking then
            if not Have
              or else Row.Dependency_Order < Best.Dependency_Order
              or else (Row.Dependency_Order = Best.Dependency_Order
                       and then Natural (Row.Id) < Natural (Best.Id))
            then
               Best := Row;
               Have := True;
            end if;
         end if;
      end loop;
      return Best;
   end First_Prerequisite_Blocker;

   function Fingerprint (Model : Final_Gated_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Remediation_Gate_Legality;
