with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 12_780) mod 2_147_483_647;
   end Mix;

   function Is_Stable_Withheld (Status : RM_Closure_Consumer_Convergence_Status) return Boolean is
   begin
      return Status in RM_Closure_Consumer_Stable_Withheld_Stale_Or_Fingerprint |
                       RM_Closure_Consumer_Stable_Withheld_AST_Or_Coverage |
                       RM_Closure_Consumer_Stable_Withheld_Cross_Unit |
                       RM_Closure_Consumer_Stable_Withheld_Generic_Substitution |
                       RM_Closure_Consumer_Stable_Withheld_Dataflow |
                       RM_Closure_Consumer_Stable_Withheld_Volatile_Atomic |
                       RM_Closure_Consumer_Stable_Withheld_Overload_Type |
                       RM_Closure_Consumer_Stable_Withheld_Representation |
                       RM_Closure_Consumer_Stable_Withheld_Tasking_Protected |
                       RM_Closure_Consumer_Stable_Withheld_Elaboration |
                       RM_Closure_Consumer_Stable_Withheld_Accessibility |
                       RM_Closure_Consumer_Stable_Withheld_Discriminant_Variant |
                       RM_Closure_Consumer_Stable_Withheld_Exception_Finalization |
                       RM_Closure_Consumer_Stable_Withheld_Renaming_Alias |
                       RM_Closure_Consumer_Stable_Withheld_Predicate_Invariant |
                       RM_Closure_Consumer_Stable_Withheld_Source_Fingerprint |
                       RM_Closure_Consumer_Stable_Withheld_Substitution_Fingerprint |
                       RM_Closure_Consumer_Stable_Multiple_Prerequisites |
                       RM_Closure_Consumer_Stable_Indeterminate;
   end Is_Stable_Withheld;

   procedure Classify
     (Source      : Apply.RM_Closure_Consumer_Application_Row;
      Previous_Fp : Natural;
      Current_Fp  : Natural;
      Status      : out RM_Closure_Consumer_Convergence_Status;
      Action      : out RM_Closure_Consumer_Convergence_Action) is
   begin
      if Previous_Fp /= 0 and then Previous_Fp /= Current_Fp then
         Status := RM_Closure_Consumer_Changed_Since_Previous;
         Action := RM_Closure_Consumer_Convergence_Action_Recheck_Again;
         return;
      end if;

      case Source.Status is
         when Apply.RM_Closure_Consumer_Application_Not_Checked =>
            Status := RM_Closure_Consumer_Stable_Indeterminate;
            Action := RM_Closure_Consumer_Convergence_Action_Degrade;
         when Apply.RM_Closure_Consumer_Application_Current_Accepted =>
            Status := RM_Closure_Consumer_Converged_Current;
            Action := RM_Closure_Consumer_Convergence_Action_Accept_Current;
         when Apply.RM_Closure_Consumer_Application_Current_Non_Diagnostic_Evidence |
              Apply.RM_Closure_Consumer_Application_Not_Required =>
            Status := RM_Closure_Consumer_Converged_Not_Required;
            Action := RM_Closure_Consumer_Convergence_Action_Skip_Not_Required;
         when Apply.RM_Closure_Consumer_Application_Withheld_Stale_Or_Fingerprint =>
            Status := RM_Closure_Consumer_Stable_Withheld_Stale_Or_Fingerprint;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Fingerprint_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_AST_Or_Coverage =>
            Status := RM_Closure_Consumer_Stable_Withheld_AST_Or_Coverage;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_AST_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Cross_Unit =>
            Status := RM_Closure_Consumer_Stable_Withheld_Cross_Unit;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Cross_Unit_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Generic_Substitution =>
            Status := RM_Closure_Consumer_Stable_Withheld_Generic_Substitution;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Generic_Substitution_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Dataflow =>
            Status := RM_Closure_Consumer_Stable_Withheld_Dataflow;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Dataflow_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Volatile_Atomic =>
            Status := RM_Closure_Consumer_Stable_Withheld_Volatile_Atomic;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Effect_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Overload_Type =>
            Status := RM_Closure_Consumer_Stable_Withheld_Overload_Type;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Type_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Representation =>
            Status := RM_Closure_Consumer_Stable_Withheld_Representation;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Representation_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Tasking_Protected =>
            Status := RM_Closure_Consumer_Stable_Withheld_Tasking_Protected;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Tasking_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Elaboration =>
            Status := RM_Closure_Consumer_Stable_Withheld_Elaboration;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Elaboration_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Accessibility =>
            Status := RM_Closure_Consumer_Stable_Withheld_Accessibility;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Accessibility_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Discriminant_Variant =>
            Status := RM_Closure_Consumer_Stable_Withheld_Discriminant_Variant;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Discriminant_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Exception_Finalization =>
            Status := RM_Closure_Consumer_Stable_Withheld_Exception_Finalization;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Exception_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Renaming_Alias =>
            Status := RM_Closure_Consumer_Stable_Withheld_Renaming_Alias;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Renaming_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Predicate_Invariant =>
            Status := RM_Closure_Consumer_Stable_Withheld_Predicate_Invariant;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Predicate_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Source_Fingerprint =>
            Status := RM_Closure_Consumer_Stable_Withheld_Source_Fingerprint;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Source_Fingerprint_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Substitution_Fingerprint =>
            Status := RM_Closure_Consumer_Stable_Withheld_Substitution_Fingerprint;
            Action := RM_Closure_Consumer_Convergence_Action_Retain_Stable_Substitution_Fingerprint_Blocker;
         when Apply.RM_Closure_Consumer_Application_Withheld_Multiple_Prerequisites =>
            Status := RM_Closure_Consumer_Stable_Multiple_Prerequisites;
            Action := RM_Closure_Consumer_Convergence_Action_Split_Prerequisites;
         when Apply.RM_Closure_Consumer_Application_Indeterminate =>
            Status := RM_Closure_Consumer_Stable_Indeterminate;
            Action := RM_Closure_Consumer_Convergence_Action_Degrade;
      end case;
   end Classify;

   function Message_For
     (Status : RM_Closure_Consumer_Convergence_Status;
      Action : RM_Closure_Consumer_Convergence_Action;
      Family : RM_Closure_Consumer_Convergence_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("RM-completion closure consumer recheck convergence " &
         RM_Closure_Consumer_Convergence_Status'Image (Status) &
         " action=" & RM_Closure_Consumer_Convergence_Action'Image (Action) &
         " family=" &
         Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : RM_Closure_Consumer_Convergence_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_780;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Apply.RM_Closure_Consumer_Application_Status'Pos (Row.Application_Status) + 1);
      H := Mix (H, Apply.RM_Closure_Consumer_Application_Action'Pos (Row.Application_Action) + 1);
      H := Mix (H, RM_Closure_Consumer_Convergence_Status'Pos (Row.Status) + 1);
      H := Mix (H, RM_Closure_Consumer_Convergence_Action'Pos (Row.Action) + 1);
      H := Mix (H, Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Semantic_Fingerprint);
      H := Mix (H, Row.Diagnostic_Fingerprint);
      H := Mix (H, Row.Worklist_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      H := Mix (H, Row.Application_Fingerprint);
      H := Mix (H, Row.Previous_Model_Fingerprint);
      H := Mix (H, Row.Current_Model_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source      : Apply.RM_Closure_Consumer_Application_Row;
      Index       : Positive;
      Previous_Fp : Natural;
      Model_Fp    : Natural) return RM_Closure_Consumer_Convergence_Row is
      Status : RM_Closure_Consumer_Convergence_Status;
      Action : RM_Closure_Consumer_Convergence_Action;
      Row    : RM_Closure_Consumer_Convergence_Row;
   begin
      Classify (Source, Previous_Fp, Model_Fp, Status, Action);
      Row.Id := RM_Closure_Consumer_Convergence_Id (Index);
      Row.Application_Id := Source.Id;
      Row.Eligibility_Id := Source.Eligibility_Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Diagnostic_Row := Source.Diagnostic_Row;
      Row.Application_Status := Source.Status;
      Row.Application_Action := Source.Action;
      Row.Status := Status;
      Row.Action := Action;
      Row.Family := Source.Family;
      Row.Node := Source.Node;
      Row.Current := Status = RM_Closure_Consumer_Converged_Current;
      Row.Stable := Status /= RM_Closure_Consumer_Changed_Since_Previous;
      Row.Withheld := Is_Stable_Withheld (Status);
      Row.Changed := Status = RM_Closure_Consumer_Changed_Since_Previous;
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Semantic_Fingerprint := Source.Semantic_Fingerprint;
      Row.Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Application_Fingerprint := Source.Application_Fingerprint;
      Row.Previous_Model_Fingerprint := Previous_Fp;
      Row.Current_Model_Fingerprint := Model_Fp;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Message := Message_For (Status, Action, Source.Family);
      Row.Convergence_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out RM_Closure_Consumer_Convergence_Model;
      Row   : RM_Closure_Consumer_Convergence_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Convergence_Fingerprint);
      if Row.Status in RM_Closure_Consumer_Converged_Current |
                       RM_Closure_Consumer_Converged_Not_Required
      then
         Model.Converged_Total := Model.Converged_Total + 1;
      end if;
      if Row.Withheld then
         Model.Stable_Withheld_Total := Model.Stable_Withheld_Total + 1;
      end if;
      if Row.Current then
         Model.Current_Total := Model.Current_Total + 1;
      end if;
      if Row.Changed then
         Model.Changed_Total := Model.Changed_Total + 1;
      end if;
      if Row.Status = RM_Closure_Consumer_Stable_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out RM_Closure_Consumer_Convergence_Model) is
   begin
      Model.Rows.Clear;
      Model.Converged_Total := 0;
      Model.Stable_Withheld_Total := 0;
      Model.Current_Total := 0;
      Model.Changed_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Applications               : Apply.RM_Closure_Consumer_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return RM_Closure_Consumer_Convergence_Model is
      Model   : RM_Closure_Consumer_Convergence_Model;
      Current : constant Natural := Apply.Stable_Fingerprint (Applications);
   begin
      for I in 1 .. Apply.Row_Count (Applications) loop
         Add_Row (Model, Make_Row (Apply.Row_At (Applications, I), I,
                                   Previous_Model_Fingerprint, Current));
      end loop;
      return Model;
   end Build;

   function Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : RM_Closure_Consumer_Convergence_Model;
      Index : Positive) return RM_Closure_Consumer_Convergence_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Closure_Consumer_Convergence_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Closure_Consumer_Convergence_Set;
      Index : Positive) return RM_Closure_Consumer_Convergence_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append
     (Set : in out RM_Closure_Consumer_Convergence_Set;
      Row : RM_Closure_Consumer_Convergence_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Convergence_Fingerprint);
   end Append;

   function Query_Status
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Status : RM_Closure_Consumer_Convergence_Status) return RM_Closure_Consumer_Convergence_Set is
      Set : RM_Closure_Consumer_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Action : RM_Closure_Consumer_Convergence_Action) return RM_Closure_Consumer_Convergence_Set is
      Set : RM_Closure_Consumer_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Family : RM_Closure_Consumer_Convergence_Family) return RM_Closure_Consumer_Convergence_Set is
      Set : RM_Closure_Consumer_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Find_By_Node
     (Model : RM_Closure_Consumer_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Closure_Consumer_Convergence_Set is
      Set : RM_Closure_Consumer_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Convergence_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Convergence_Set is
      Set : RM_Closure_Consumer_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Convergence_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Convergence_Set is
      Set : RM_Closure_Consumer_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Status : RM_Closure_Consumer_Convergence_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : RM_Closure_Consumer_Convergence_Model;
      Family : RM_Closure_Consumer_Convergence_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Converged_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural is
   begin
      return Model.Converged_Total;
   end Converged_Count;

   function Stable_Withheld_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural is
   begin
      return Model.Stable_Withheld_Total;
   end Stable_Withheld_Count;

   function Current_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Changed_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural is
   begin
      return Model.Changed_Total;
   end Changed_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Convergence_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : RM_Closure_Consumer_Convergence_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality;
