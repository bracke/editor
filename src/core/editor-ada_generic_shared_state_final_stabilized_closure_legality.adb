with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality is
   use type Generic_Shared_State_Final_Closure_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_445) mod 2_147_483_647;
   end Mix;

   function Is_Accepted
     (Status : Generic_Shared_State_Final_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current |
                       Generic_Shared_State_Final_Stabilized_Closure_Accepted_Not_Required;
   end Is_Accepted;

   function Is_Blocked
     (Status : Generic_Shared_State_Final_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in Generic_Shared_State_Final_Stabilized_Closure_Blocker_Stale_Or_Fingerprint |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_AST_Or_Coverage |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Cross_Unit |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Generic_Replay |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Abstract_Or_Shared_State |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Volatile_Atomic |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Overload_Type |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Representation |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Tasking_Protected |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Elaboration |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Accessibility |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Discriminant_Variant |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Exception_Finalization |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Renaming_Alias |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Predicate_Invariant |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Dataflow |
                       Generic_Shared_State_Final_Stabilized_Closure_Blocker_Multiple_Prerequisites;
   end Is_Blocked;

   procedure Classify
     (Source : Gate.Generic_Shared_State_Final_Stabilization_Gate_Row;
      Status : out Generic_Shared_State_Final_Stabilized_Closure_Status;
      Action : out Generic_Shared_State_Final_Stabilized_Closure_Action) is
   begin
      case Source.Status is
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Not_Checked =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Not_Checked;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_None;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Promoted_Current =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Accept_Current;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Promoted_Not_Required =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Accepted_Not_Required;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Accept_Not_Required;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Stale_Or_Fingerprint =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Stale_Or_Fingerprint;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Fingerprint;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_AST_Or_Coverage =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_AST_Or_Coverage;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_AST;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Cross_Unit =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Cross_Unit;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Cross_Unit;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Generic_Replay =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Generic_Replay;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Generic;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Abstract_Or_Shared_State =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Abstract_Or_Shared_State;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Shared_State;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Volatile_Atomic =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Volatile_Atomic;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Effects;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Overload_Type =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Overload_Type;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Type;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Representation =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Representation;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Representation;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Tasking_Protected =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Tasking_Protected;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Tasking;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Elaboration =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Elaboration;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Elaboration;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Accessibility =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Accessibility;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Accessibility;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Discriminant_Variant =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Discriminant_Variant;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Discriminant;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Exception_Finalization =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Exception_Finalization;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Exception;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Renaming_Alias =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Renaming_Alias;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Renaming;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Predicate_Invariant =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Predicate_Invariant;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Predicate;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Dataflow =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Dataflow;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Block_Dataflow;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Withheld_Multiple_Prerequisites =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Blocker_Multiple_Prerequisites;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Split_Prerequisites;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Degraded_Indeterminate =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Indeterminate;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Degrade;
         when Gate.Generic_Shared_State_Final_Stabilization_Gate_Recheck_Required =>
            Status := Generic_Shared_State_Final_Stabilized_Closure_Recheck_Required;
            Action := Generic_Shared_State_Final_Stabilized_Closure_Action_Recheck;
      end case;
   end Classify;

   function Message_For
     (Status : Generic_Shared_State_Final_Stabilized_Closure_Status;
      Action : Generic_Shared_State_Final_Stabilized_Closure_Action;
      Family : Generic_Shared_State_Final_Closure_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("generic/shared-state final stabilized closure " &
         Generic_Shared_State_Final_Stabilized_Closure_Status'Image (Status) &
         " action=" & Generic_Shared_State_Final_Stabilized_Closure_Action'Image (Action) &
         " family=" & Gate.Conv.Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint
     (Row : Generic_Shared_State_Final_Stabilized_Closure_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_445;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Stabilization_Id));
      H := Mix (H, Natural (Row.Convergence_Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Generic_Shared_State_Final_Stabilization_Status'Pos (Row.Stabilization_Status) + 1);
      H := Mix (H, Generic_Shared_State_Final_Stabilization_Action'Pos (Row.Stabilization_Action) + 1);
      H := Mix (H, Generic_Shared_State_Final_Stabilized_Closure_Status'Pos (Row.Status) + 1);
      H := Mix (H, Generic_Shared_State_Final_Stabilized_Closure_Action'Pos (Row.Action) + 1);
      H := Mix (H, Gate.Conv.Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Worklist_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      H := Mix (H, Row.Application_Fingerprint);
      H := Mix (H, Row.Convergence_Fingerprint);
      H := Mix (H, Row.Stabilization_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Gate.Generic_Shared_State_Final_Stabilization_Gate_Row;
      Index  : Positive) return Generic_Shared_State_Final_Stabilized_Closure_Row is
      Status : Generic_Shared_State_Final_Stabilized_Closure_Status;
      Action : Generic_Shared_State_Final_Stabilized_Closure_Action;
      Row    : Generic_Shared_State_Final_Stabilized_Closure_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := Generic_Shared_State_Final_Stabilized_Closure_Id (Index);
      Row.Stabilization_Id := Source.Id;
      Row.Convergence_Id := Source.Convergence_Id;
      Row.Application_Id := Source.Application_Id;
      Row.Eligibility_Id := Source.Eligibility_Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Diagnostic_Row := Source.Diagnostic_Row;
      Row.Stabilization_Status := Source.Status;
      Row.Stabilization_Action := Source.Action;
      Row.Status := Status;
      Row.Action := Action;
      Row.Family := Source.Family;
      Row.Node := Source.Node;
      Row.Object_Name := Source.Object_Name;
      Row.Component_Name := Source.Component_Name;
      Row.Operation_Name := Source.Operation_Name;
      Row.Generic_Unit_Name := Source.Generic_Unit_Name;
      Row.Instance_Name := Source.Instance_Name;
      Row.State_Name := Source.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Current := Status = Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current;
      Row.Blocked := Is_Blocked (Status);
      Row.Stable := Source.Stable and then Status /= Generic_Shared_State_Final_Stabilized_Closure_Recheck_Required;
      Row.Recheck_Required := Status = Generic_Shared_State_Final_Stabilized_Closure_Recheck_Required;
      Row.Blocks_Downstream := Row.Blocked or else Row.Recheck_Required or else
        Status = Generic_Shared_State_Final_Stabilized_Closure_Indeterminate or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Application_Fingerprint := Source.Application_Fingerprint;
      Row.Convergence_Fingerprint := Source.Convergence_Fingerprint;
      Row.Stabilization_Fingerprint := Source.Stabilization_Fingerprint;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Message := Message_For (Status, Action, Source.Family);
      Row.Closure_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Generic_Shared_State_Final_Stabilized_Closure_Model;
      Row   : Generic_Shared_State_Final_Stabilized_Closure_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Closure_Fingerprint);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Blocked then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;
      if Row.Current then
         Model.Current_Total := Model.Current_Total + 1;
      end if;
      if Row.Recheck_Required then
         Model.Recheck_Total := Model.Recheck_Total + 1;
      end if;
      if Row.Status = Generic_Shared_State_Final_Stabilized_Closure_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Generic_Shared_State_Final_Stabilized_Closure_Model) is
   begin
      Model.Rows.Clear;
      Model.Accepted_Total := 0;
      Model.Blocked_Total := 0;
      Model.Current_Total := 0;
      Model.Recheck_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Stabilization : Gate.Generic_Shared_State_Final_Stabilization_Gate_Model)
      return Generic_Shared_State_Final_Stabilized_Closure_Model is
      Model : Generic_Shared_State_Final_Stabilized_Closure_Model;
   begin
      for I in 1 .. Gate.Row_Count (Stabilization) loop
         Add_Row (Model, Make_Row (Gate.Row_At (Stabilization, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Index : Positive) return Generic_Shared_State_Final_Stabilized_Closure_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Generic_Shared_State_Final_Stabilized_Closure_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Generic_Shared_State_Final_Stabilized_Closure_Set;
      Index : Positive) return Generic_Shared_State_Final_Stabilized_Closure_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Generic_Shared_State_Final_Stabilized_Closure_Set;
      Row : Generic_Shared_State_Final_Stabilized_Closure_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Closure_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Status : Generic_Shared_State_Final_Stabilized_Closure_Status) return Generic_Shared_State_Final_Stabilized_Closure_Set is
      Set : Generic_Shared_State_Final_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Action : Generic_Shared_State_Final_Stabilized_Closure_Action) return Generic_Shared_State_Final_Stabilized_Closure_Set is
      Set : Generic_Shared_State_Final_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Family : Generic_Shared_State_Final_Closure_Family) return Generic_Shared_State_Final_Stabilized_Closure_Set is
      Set : Generic_Shared_State_Final_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Find_By_Node
     (Model : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Shared_State_Final_Stabilized_Closure_Set is
      Set : Generic_Shared_State_Final_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Stabilized_Closure_Set is
      Set : Generic_Shared_State_Final_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Stabilized_Closure_Set is
      Set : Generic_Shared_State_Final_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Status : Generic_Shared_State_Final_Stabilized_Closure_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : Generic_Shared_State_Final_Stabilized_Closure_Model;
      Family : Generic_Shared_State_Final_Closure_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Accepted_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Current_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Recheck_Required_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality;
