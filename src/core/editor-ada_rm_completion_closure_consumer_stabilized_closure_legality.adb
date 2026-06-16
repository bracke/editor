with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality is

   pragma Suppress (Overflow_Check);
   use type Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 1_109) + (B * 137) + 12_800) mod 1_000_000_007;
   end Mix;

   function Is_Accepted
     (Status : RM_Closure_Consumer_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in RM_Closure_Consumer_Stabilized_Closure_Accepted_Current |
                       RM_Closure_Consumer_Stabilized_Closure_Accepted_Not_Required;
   end Is_Accepted;

   function Is_Blocked
     (Status : RM_Closure_Consumer_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in RM_Closure_Consumer_Stabilized_Closure_Blocker_Stale_Or_Fingerprint ..
                       RM_Closure_Consumer_Stabilized_Closure_Blocker_Multiple_Prerequisites;
   end Is_Blocked;

   procedure Classify
     (Source : Gate.RM_Closure_Consumer_Stabilization_Gate_Row;
      Status : out RM_Closure_Consumer_Stabilized_Closure_Status;
      Action : out RM_Closure_Consumer_Stabilized_Closure_Action) is
   begin
      case Source.Status is
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Not_Checked =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Not_Checked;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_None;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Promoted_Current =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Accepted_Current;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Accept_Current;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Promoted_Not_Required =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Accepted_Not_Required;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Accept_Not_Required;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Stale_Or_Fingerprint =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Stale_Or_Fingerprint;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Fingerprint;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_AST_Or_Coverage =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_AST_Or_Coverage;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_AST;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Cross_Unit =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Cross_Unit;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Cross_Unit;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Generic_Substitution =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Generic_Substitution;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Generic_Substitution;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Dataflow =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Dataflow;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Dataflow;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Volatile_Atomic =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Volatile_Atomic;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Effects;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Overload_Type =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Overload_Type;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Type;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Representation =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Representation;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Representation;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Tasking_Protected =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Tasking_Protected;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Tasking;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Elaboration =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Elaboration;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Elaboration;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Accessibility =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Accessibility;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Accessibility;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Discriminant_Variant =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Discriminant_Variant;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Discriminant;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Exception_Finalization =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Exception_Finalization;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Exception;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Renaming_Alias =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Renaming_Alias;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Renaming;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Predicate_Invariant =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Predicate_Invariant;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Predicate;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Source_Fingerprint =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Source_Fingerprint;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Source_Fingerprint;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Substitution_Fingerprint =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Substitution_Fingerprint;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Block_Substitution_Fingerprint;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Withheld_Multiple_Prerequisites =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Blocker_Multiple_Prerequisites;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Split_Prerequisites;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Degraded_Indeterminate =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Indeterminate;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Degrade;
         when Gate.RM_Closure_Consumer_Stabilization_Gate_Recheck_Required =>
            Status := RM_Closure_Consumer_Stabilized_Closure_Recheck_Required;
            Action := RM_Closure_Consumer_Stabilized_Closure_Action_Recheck;
      end case;
   end Classify;

   function Message_For
     (Status : RM_Closure_Consumer_Stabilized_Closure_Status;
      Action : RM_Closure_Consumer_Stabilized_Closure_Action;
      Family : RM_Closure_Consumer_Closure_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("RM-completion closure consumer stabilized closure " &
         RM_Closure_Consumer_Stabilized_Closure_Status'Image (Status) &
         " action=" & RM_Closure_Consumer_Stabilized_Closure_Action'Image (Action) &
         " family=" &
         Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint
     (Row : RM_Closure_Consumer_Stabilized_Closure_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_800;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Stabilization_Id));
      H := Mix (H, Natural (Row.Convergence_Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, RM_Closure_Consumer_Stabilization_Status'Pos (Row.Stabilization_Status) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilization_Action'Pos (Row.Stabilization_Action) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilized_Closure_Status'Pos (Row.Status) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilized_Closure_Action'Pos (Row.Action) + 1);
      H := Mix (H, Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Semantic_Fingerprint);
      H := Mix (H, Row.Diagnostic_Fingerprint);
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
     (Source : Gate.RM_Closure_Consumer_Stabilization_Gate_Row;
      Index  : Positive) return RM_Closure_Consumer_Stabilized_Closure_Row is
      Status : RM_Closure_Consumer_Stabilized_Closure_Status;
      Action : RM_Closure_Consumer_Stabilized_Closure_Action;
      Row    : RM_Closure_Consumer_Stabilized_Closure_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := RM_Closure_Consumer_Stabilized_Closure_Id (Index);
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
      Row.Accepted := Is_Accepted (Status);
      Row.Current := Status = RM_Closure_Consumer_Stabilized_Closure_Accepted_Current;
      Row.Blocked := Is_Blocked (Status);
      Row.Stable := Source.Stable and then Status /= RM_Closure_Consumer_Stabilized_Closure_Recheck_Required;
      Row.Recheck_Required := Status = RM_Closure_Consumer_Stabilized_Closure_Recheck_Required;
      Row.Blocks_Downstream := Row.Blocked or else Row.Recheck_Required or else
        Status = RM_Closure_Consumer_Stabilized_Closure_Indeterminate or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Semantic_Fingerprint := Source.Semantic_Fingerprint;
      Row.Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
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
     (Model : in out RM_Closure_Consumer_Stabilized_Closure_Model;
      Row   : RM_Closure_Consumer_Stabilized_Closure_Row) is
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
      if Row.Status = RM_Closure_Consumer_Stabilized_Closure_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilized_Closure_Model) is
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
     (Gates : Gate.RM_Closure_Consumer_Stabilization_Gate_Model)
      return RM_Closure_Consumer_Stabilized_Closure_Model is
      Model : RM_Closure_Consumer_Stabilized_Closure_Model;
   begin
      for I in 1 .. Gate.Row_Count (Gates) loop
         Add_Row (Model, Make_Row (Gate.Row_At (Gates, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : RM_Closure_Consumer_Stabilized_Closure_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Closure_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Closure_Consumer_Stabilized_Closure_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Closure_Consumer_Stabilized_Closure_Set;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Closure_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out RM_Closure_Consumer_Stabilized_Closure_Set;
      Row : RM_Closure_Consumer_Stabilized_Closure_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Closure_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Status : RM_Closure_Consumer_Stabilized_Closure_Status) return RM_Closure_Consumer_Stabilized_Closure_Set is
      Result : RM_Closure_Consumer_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Action
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Action : RM_Closure_Consumer_Stabilized_Closure_Action) return RM_Closure_Consumer_Stabilized_Closure_Set is
      Result : RM_Closure_Consumer_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Action;

   function Query_Family
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Family : RM_Closure_Consumer_Closure_Family) return RM_Closure_Consumer_Stabilized_Closure_Set is
      Result : RM_Closure_Consumer_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Family;

   function Find_By_Node
     (Model : RM_Closure_Consumer_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Closure_Consumer_Stabilized_Closure_Set is
      Result : RM_Closure_Consumer_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Closure_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Closure_Set is
      Result : RM_Closure_Consumer_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Closure_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Closure_Set is
      Result : RM_Closure_Consumer_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Status : RM_Closure_Consumer_Stabilized_Closure_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : RM_Closure_Consumer_Stabilized_Closure_Model;
      Family : RM_Closure_Consumer_Closure_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Accepted_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Current_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Recheck_Required_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : RM_Closure_Consumer_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality;
