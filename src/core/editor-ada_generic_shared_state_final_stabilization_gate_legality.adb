with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality is
   use type Generic_Shared_State_Final_Stabilization_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_440) mod 2_147_483_647;
   end Mix;

   function Is_Promoted
     (Status : Generic_Shared_State_Final_Stabilization_Gate_Status) return Boolean is
   begin
      return Status in Generic_Shared_State_Final_Stabilization_Gate_Promoted_Current |
                       Generic_Shared_State_Final_Stabilization_Gate_Promoted_Not_Required;
   end Is_Promoted;

   function Is_Withheld
     (Status : Generic_Shared_State_Final_Stabilization_Gate_Status) return Boolean is
   begin
      return Status in Generic_Shared_State_Final_Stabilization_Gate_Withheld_Stale_Or_Fingerprint |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_AST_Or_Coverage |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Cross_Unit |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Generic_Replay |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Abstract_Or_Shared_State |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Volatile_Atomic |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Overload_Type |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Representation |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Tasking_Protected |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Elaboration |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Accessibility |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Discriminant_Variant |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Exception_Finalization |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Renaming_Alias |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Predicate_Invariant |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Dataflow |
                       Generic_Shared_State_Final_Stabilization_Gate_Withheld_Multiple_Prerequisites;
   end Is_Withheld;

   procedure Classify
     (Source : Conv.Generic_Shared_State_Final_Convergence_Row;
      Status : out Generic_Shared_State_Final_Stabilization_Gate_Status;
      Action : out Generic_Shared_State_Final_Stabilization_Gate_Action) is
   begin
      case Source.Status is
         when Conv.Generic_Shared_State_Final_Convergence_Not_Checked =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Not_Checked;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_None;
         when Conv.Generic_Shared_State_Final_Converged_Current =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Promoted_Current;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Promote_Current;
         when Conv.Generic_Shared_State_Final_Converged_Not_Required =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Promoted_Not_Required;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Promote_Not_Required;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Stale_Or_Fingerprint =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Stale_Or_Fingerprint;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Fingerprint_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_AST_Or_Coverage =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_AST_Or_Coverage;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_AST_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Cross_Unit =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Cross_Unit;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Cross_Unit_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Generic_Replay =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Generic_Replay;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Generic_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Abstract_Or_Shared_State =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Abstract_Or_Shared_State;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Shared_State_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Volatile_Atomic =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Volatile_Atomic;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Effect_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Overload_Type =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Overload_Type;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Type_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Representation =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Representation;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Representation_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Tasking_Protected =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Tasking_Protected;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Tasking_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Elaboration =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Elaboration;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Elaboration_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Accessibility =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Accessibility;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Accessibility_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Discriminant_Variant =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Discriminant_Variant;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Discriminant_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Exception_Finalization =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Exception_Finalization;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Exception_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Renaming_Alias =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Renaming_Alias;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Renaming_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Predicate_Invariant =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Predicate_Invariant;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Predicate_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Withheld_Dataflow =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Dataflow;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Retain_Dataflow_Blocker;
         when Conv.Generic_Shared_State_Final_Stable_Multiple_Prerequisites =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Withheld_Multiple_Prerequisites;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Split_Prerequisites;
         when Conv.Generic_Shared_State_Final_Stable_Indeterminate =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Degraded_Indeterminate;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Degrade;
         when Conv.Generic_Shared_State_Final_Changed_Since_Previous =>
            Status := Generic_Shared_State_Final_Stabilization_Gate_Recheck_Required;
            Action := Generic_Shared_State_Final_Stabilization_Gate_Action_Recheck;
      end case;
   end Classify;

   function Message_For
     (Status : Generic_Shared_State_Final_Stabilization_Gate_Status;
      Action : Generic_Shared_State_Final_Stabilization_Gate_Action;
      Family : Generic_Shared_State_Final_Stabilization_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("generic/shared-state final stabilization gate " &
         Generic_Shared_State_Final_Stabilization_Gate_Status'Image (Status) &
         " action=" & Generic_Shared_State_Final_Stabilization_Gate_Action'Image (Action) &
         " family=" & Conv.Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint
     (Row : Generic_Shared_State_Final_Stabilization_Gate_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_440;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Convergence_Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Generic_Shared_State_Final_Convergence_Status'Pos (Row.Convergence_Status) + 1);
      H := Mix (H, Generic_Shared_State_Final_Convergence_Action'Pos (Row.Convergence_Action) + 1);
      H := Mix (H, Generic_Shared_State_Final_Stabilization_Gate_Status'Pos (Row.Status) + 1);
      H := Mix (H, Generic_Shared_State_Final_Stabilization_Gate_Action'Pos (Row.Action) + 1);
      H := Mix (H, Conv.Apply.Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Worklist_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      H := Mix (H, Row.Application_Fingerprint);
      H := Mix (H, Row.Convergence_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Conv.Generic_Shared_State_Final_Convergence_Row;
      Index  : Positive) return Generic_Shared_State_Final_Stabilization_Gate_Row is
      Status : Generic_Shared_State_Final_Stabilization_Gate_Status;
      Action : Generic_Shared_State_Final_Stabilization_Gate_Action;
      Row    : Generic_Shared_State_Final_Stabilization_Gate_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := Generic_Shared_State_Final_Stabilization_Gate_Id (Index);
      Row.Convergence_Id := Source.Id;
      Row.Application_Id := Source.Application_Id;
      Row.Eligibility_Id := Source.Eligibility_Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Diagnostic_Row := Source.Diagnostic_Row;
      Row.Convergence_Status := Source.Status;
      Row.Convergence_Action := Source.Action;
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
      Row.Promoted := Is_Promoted (Status);
      Row.Current := Status = Generic_Shared_State_Final_Stabilization_Gate_Promoted_Current;
      Row.Withheld := Is_Withheld (Status);
      Row.Stable := Status /= Generic_Shared_State_Final_Stabilization_Gate_Recheck_Required;
      Row.Recheck_Required := Status = Generic_Shared_State_Final_Stabilization_Gate_Recheck_Required;
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Application_Fingerprint := Source.Application_Fingerprint;
      Row.Convergence_Fingerprint := Source.Convergence_Fingerprint;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Message := Message_For (Status, Action, Source.Family);
      Row.Stabilization_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Generic_Shared_State_Final_Stabilization_Gate_Model;
      Row   : Generic_Shared_State_Final_Stabilization_Gate_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Stabilization_Fingerprint);
      if Row.Promoted then
         Model.Promoted_Total := Model.Promoted_Total + 1;
      end if;
      if Row.Withheld then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;
      if Row.Current then
         Model.Current_Total := Model.Current_Total + 1;
      end if;
      if Row.Recheck_Required then
         Model.Recheck_Total := Model.Recheck_Total + 1;
      end if;
      if Row.Status = Generic_Shared_State_Final_Stabilization_Gate_Degraded_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Generic_Shared_State_Final_Stabilization_Gate_Model) is
   begin
      Model.Rows.Clear;
      Model.Promoted_Total := 0;
      Model.Withheld_Total := 0;
      Model.Current_Total := 0;
      Model.Recheck_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Convergence : Conv.Generic_Shared_State_Final_Convergence_Model)
      return Generic_Shared_State_Final_Stabilization_Gate_Model is
      Model : Generic_Shared_State_Final_Stabilization_Gate_Model;
   begin
      for I in 1 .. Conv.Row_Count (Convergence) loop
         Add_Row (Model, Make_Row (Conv.Row_At (Convergence, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Index : Positive) return Generic_Shared_State_Final_Stabilization_Gate_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Generic_Shared_State_Final_Stabilization_Gate_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Generic_Shared_State_Final_Stabilization_Gate_Set;
      Index : Positive) return Generic_Shared_State_Final_Stabilization_Gate_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Generic_Shared_State_Final_Stabilization_Gate_Set;
      Row : Generic_Shared_State_Final_Stabilization_Gate_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Stabilization_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Status : Generic_Shared_State_Final_Stabilization_Gate_Status) return Generic_Shared_State_Final_Stabilization_Gate_Set is
      Set : Generic_Shared_State_Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Action : Generic_Shared_State_Final_Stabilization_Gate_Action) return Generic_Shared_State_Final_Stabilization_Gate_Set is
      Set : Generic_Shared_State_Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Family : Generic_Shared_State_Final_Stabilization_Family) return Generic_Shared_State_Final_Stabilization_Gate_Set is
      Set : Generic_Shared_State_Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Find_By_Node
     (Model : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Generic_Shared_State_Final_Stabilization_Gate_Set is
      Set : Generic_Shared_State_Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Stabilization_Gate_Set is
      Set : Generic_Shared_State_Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Fingerprint : Natural) return Generic_Shared_State_Final_Stabilization_Gate_Set is
      Set : Generic_Shared_State_Final_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Status : Generic_Shared_State_Final_Stabilization_Gate_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : Generic_Shared_State_Final_Stabilization_Gate_Model;
      Family : Generic_Shared_State_Final_Stabilization_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Promoted_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Promoted_Total;
   end Promoted_Count;

   function Withheld_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Current_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Recheck_Required_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality;
