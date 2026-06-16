with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality is

   pragma Suppress (Overflow_Check);
   use type Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 1_103) + (B * 131) + 12_790) mod 1_000_000_007;
   end Mix;

   function Is_Promoted
     (Status : RM_Closure_Consumer_Stabilization_Gate_Status) return Boolean is
   begin
      return Status in RM_Closure_Consumer_Stabilization_Gate_Promoted_Current |
                       RM_Closure_Consumer_Stabilization_Gate_Promoted_Not_Required;
   end Is_Promoted;

   function Is_Withheld
     (Status : RM_Closure_Consumer_Stabilization_Gate_Status) return Boolean is
   begin
      return Status in RM_Closure_Consumer_Stabilization_Gate_Withheld_Stale_Or_Fingerprint ..
                       RM_Closure_Consumer_Stabilization_Gate_Withheld_Multiple_Prerequisites;
   end Is_Withheld;

   procedure Classify
     (Source : Conv.RM_Closure_Consumer_Convergence_Row;
      Status : out RM_Closure_Consumer_Stabilization_Gate_Status;
      Action : out RM_Closure_Consumer_Stabilization_Gate_Action) is
   begin
      case Source.Status is
         when Conv.RM_Closure_Consumer_Convergence_Not_Checked =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Not_Checked;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_None;
         when Conv.RM_Closure_Consumer_Converged_Current =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Promoted_Current;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Promote_Current;
         when Conv.RM_Closure_Consumer_Converged_Not_Required =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Promoted_Not_Required;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Promote_Not_Required;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Stale_Or_Fingerprint =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Stale_Or_Fingerprint;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Fingerprint_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_AST_Or_Coverage =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_AST_Or_Coverage;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_AST_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Cross_Unit =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Cross_Unit;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Cross_Unit_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Generic_Substitution =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Generic_Substitution;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Generic_Substitution_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Dataflow =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Dataflow;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Dataflow_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Volatile_Atomic =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Volatile_Atomic;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Effect_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Overload_Type =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Overload_Type;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Type_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Representation =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Representation;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Representation_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Tasking_Protected =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Tasking_Protected;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Tasking_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Elaboration =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Elaboration;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Elaboration_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Accessibility =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Accessibility;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Accessibility_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Discriminant_Variant =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Discriminant_Variant;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Discriminant_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Exception_Finalization =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Exception_Finalization;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Exception_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Renaming_Alias =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Renaming_Alias;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Renaming_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Predicate_Invariant =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Predicate_Invariant;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Predicate_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Source_Fingerprint =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Source_Fingerprint;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Source_Fingerprint_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Withheld_Substitution_Fingerprint =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Substitution_Fingerprint;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Retain_Substitution_Fingerprint_Blocker;
         when Conv.RM_Closure_Consumer_Stable_Multiple_Prerequisites =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Withheld_Multiple_Prerequisites;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Split_Prerequisites;
         when Conv.RM_Closure_Consumer_Stable_Indeterminate =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Degraded_Indeterminate;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Degrade;
         when Conv.RM_Closure_Consumer_Changed_Since_Previous =>
            Status := RM_Closure_Consumer_Stabilization_Gate_Recheck_Required;
            Action := RM_Closure_Consumer_Stabilization_Gate_Action_Recheck;
      end case;
   end Classify;

   function Message_For
     (Status : RM_Closure_Consumer_Stabilization_Gate_Status;
      Action : RM_Closure_Consumer_Stabilization_Gate_Action;
      Family : RM_Closure_Consumer_Stabilization_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("RM-completion closure consumer stabilization gate " &
         RM_Closure_Consumer_Stabilization_Gate_Status'Image (Status) &
         " action=" & RM_Closure_Consumer_Stabilization_Gate_Action'Image (Action) &
         " family=" &
         Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint
     (Row : RM_Closure_Consumer_Stabilization_Gate_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_790;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Convergence_Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, RM_Closure_Consumer_Convergence_Status'Pos (Row.Convergence_Status) + 1);
      H := Mix (H, RM_Closure_Consumer_Convergence_Action'Pos (Row.Convergence_Action) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilization_Gate_Status'Pos (Row.Status) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilization_Gate_Action'Pos (Row.Action) + 1);
      H := Mix (H, Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Pos (Row.Family) + 1);
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
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Conv.RM_Closure_Consumer_Convergence_Row;
      Index  : Positive) return RM_Closure_Consumer_Stabilization_Gate_Row is
      Status : RM_Closure_Consumer_Stabilization_Gate_Status;
      Action : RM_Closure_Consumer_Stabilization_Gate_Action;
      Row    : RM_Closure_Consumer_Stabilization_Gate_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := RM_Closure_Consumer_Stabilization_Gate_Id (Index);
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
      Row.Promoted := Is_Promoted (Status);
      Row.Current := Status = RM_Closure_Consumer_Stabilization_Gate_Promoted_Current;
      Row.Withheld := Is_Withheld (Status);
      Row.Stable := Status /= RM_Closure_Consumer_Stabilization_Gate_Recheck_Required;
      Row.Recheck_Required := Status = RM_Closure_Consumer_Stabilization_Gate_Recheck_Required;
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Semantic_Fingerprint := Source.Semantic_Fingerprint;
      Row.Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
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
     (Model : in out RM_Closure_Consumer_Stabilization_Gate_Model;
      Row   : RM_Closure_Consumer_Stabilization_Gate_Row) is
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
      if Row.Status = RM_Closure_Consumer_Stabilization_Gate_Degraded_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilization_Gate_Model) is
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
     (Convergence : Conv.RM_Closure_Consumer_Convergence_Model)
      return RM_Closure_Consumer_Stabilization_Gate_Model is
      Model : RM_Closure_Consumer_Stabilization_Gate_Model;
   begin
      for I in 1 .. Conv.Row_Count (Convergence) loop
         Add_Row (Model, Make_Row (Conv.Row_At (Convergence, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : RM_Closure_Consumer_Stabilization_Gate_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilization_Gate_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Closure_Consumer_Stabilization_Gate_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Closure_Consumer_Stabilization_Gate_Set;
      Index : Positive) return RM_Closure_Consumer_Stabilization_Gate_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out RM_Closure_Consumer_Stabilization_Gate_Set;
      Row : RM_Closure_Consumer_Stabilization_Gate_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Stabilization_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Status : RM_Closure_Consumer_Stabilization_Gate_Status) return RM_Closure_Consumer_Stabilization_Gate_Set is
      Result : RM_Closure_Consumer_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Action
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Action : RM_Closure_Consumer_Stabilization_Gate_Action) return RM_Closure_Consumer_Stabilization_Gate_Set is
      Result : RM_Closure_Consumer_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Action;

   function Query_Family
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Family : RM_Closure_Consumer_Stabilization_Family) return RM_Closure_Consumer_Stabilization_Gate_Set is
      Result : RM_Closure_Consumer_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Family;

   function Find_By_Node
     (Model : RM_Closure_Consumer_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Closure_Consumer_Stabilization_Gate_Set is
      Result : RM_Closure_Consumer_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilization_Gate_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilization_Gate_Set is
      Result : RM_Closure_Consumer_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilization_Gate_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilization_Gate_Set is
      Result : RM_Closure_Consumer_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Status : RM_Closure_Consumer_Stabilization_Gate_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : RM_Closure_Consumer_Stabilization_Gate_Model;
      Family : RM_Closure_Consumer_Stabilization_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Promoted_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Promoted_Total;
   end Promoted_Count;

   function Withheld_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Current_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Recheck_Required_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : RM_Closure_Consumer_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilization_Gate_Legality;
