with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality is

   pragma Suppress (Overflow_Check);
   use type RM_Completion_Convergence_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_423) mod 2_147_483_647;
   end Mix;

   function Is_Stable_Withheld
     (Status : RM_Completion_Convergence_Status) return Boolean is
   begin
      return Status in RM_Completion_Stable_Withheld_Stale_Or_Fingerprint |
                       RM_Completion_Stable_Withheld_AST_Or_Coverage |
                       RM_Completion_Stable_Withheld_Cross_Unit |
                       RM_Completion_Stable_Withheld_Generic_Substitution |
                       RM_Completion_Stable_Withheld_Prior_Dataflow |
                       RM_Completion_Stable_Withheld_Volatile_Atomic |
                       RM_Completion_Stable_Withheld_Overload_Type |
                       RM_Completion_Stable_Withheld_Representation |
                       RM_Completion_Stable_Withheld_Tasking_Protected |
                       RM_Completion_Stable_Withheld_Elaboration |
                       RM_Completion_Stable_Withheld_Accessibility |
                       RM_Completion_Stable_Withheld_Discriminant_Variant |
                       RM_Completion_Stable_Withheld_Exception_Finalization |
                       RM_Completion_Stable_Withheld_Renaming_Alias |
                       RM_Completion_Stable_Withheld_Predicate_Invariant |
                       RM_Completion_Stable_Withheld_Dataflow |
                       RM_Completion_Stable_Multiple_Prerequisites |
                       RM_Completion_Stable_Indeterminate;
   end Is_Stable_Withheld;

   procedure Classify
     (Source      : Apply.RM_Completion_Application_Row;
      Previous_Fp : Natural;
      Model_Fp    : Natural;
      Status      : out RM_Completion_Convergence_Status;
      Action      : out RM_Completion_Convergence_Action) is
   begin
      if Previous_Fp /= 0 and then Previous_Fp /= Model_Fp then
         Status := RM_Completion_Changed_Since_Previous;
         Action := RM_Completion_Convergence_Action_Recheck_Again;
         return;
      end if;

      case Source.Status is
         when Apply.RM_Completion_Application_Not_Checked =>
            Status := RM_Completion_Stable_Withheld_Stale_Or_Fingerprint;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Fingerprint_Blocker;
         when Apply.RM_Completion_Application_Current_Accepted =>
            Status := RM_Completion_Converged_Current;
            Action := RM_Completion_Convergence_Action_Accept_Current;
         when Apply.RM_Completion_Application_Current_Non_Diagnostic_Evidence |
              Apply.RM_Completion_Application_Not_Required =>
            Status := RM_Completion_Converged_Not_Required;
            Action := RM_Completion_Convergence_Action_Skip_Not_Required;
         when Apply.RM_Completion_Application_Withheld_Stale_Or_Fingerprint =>
            Status := RM_Completion_Stable_Withheld_Stale_Or_Fingerprint;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Fingerprint_Blocker;
         when Apply.RM_Completion_Application_Withheld_AST_Or_Coverage =>
            Status := RM_Completion_Stable_Withheld_AST_Or_Coverage;
            Action := RM_Completion_Convergence_Action_Retain_Stable_AST_Blocker;
         when Apply.RM_Completion_Application_Withheld_Cross_Unit =>
            Status := RM_Completion_Stable_Withheld_Cross_Unit;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Cross_Unit_Blocker;
         when Apply.RM_Completion_Application_Withheld_Generic_Substitution =>
            Status := RM_Completion_Stable_Withheld_Generic_Substitution;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Generic_Substitution_Blocker;
         when Apply.RM_Completion_Application_Withheld_Prior_Dataflow =>
            Status := RM_Completion_Stable_Withheld_Prior_Dataflow;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Prior_Dataflow_Blocker;
         when Apply.RM_Completion_Application_Withheld_Volatile_Atomic =>
            Status := RM_Completion_Stable_Withheld_Volatile_Atomic;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Effect_Blocker;
         when Apply.RM_Completion_Application_Withheld_Overload_Type =>
            Status := RM_Completion_Stable_Withheld_Overload_Type;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Type_Blocker;
         when Apply.RM_Completion_Application_Withheld_Representation =>
            Status := RM_Completion_Stable_Withheld_Representation;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Representation_Blocker;
         when Apply.RM_Completion_Application_Withheld_Tasking_Protected =>
            Status := RM_Completion_Stable_Withheld_Tasking_Protected;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Tasking_Blocker;
         when Apply.RM_Completion_Application_Withheld_Elaboration =>
            Status := RM_Completion_Stable_Withheld_Elaboration;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Elaboration_Blocker;
         when Apply.RM_Completion_Application_Withheld_Accessibility =>
            Status := RM_Completion_Stable_Withheld_Accessibility;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Accessibility_Blocker;
         when Apply.RM_Completion_Application_Withheld_Discriminant_Variant =>
            Status := RM_Completion_Stable_Withheld_Discriminant_Variant;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Discriminant_Blocker;
         when Apply.RM_Completion_Application_Withheld_Exception_Finalization =>
            Status := RM_Completion_Stable_Withheld_Exception_Finalization;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Exception_Blocker;
         when Apply.RM_Completion_Application_Withheld_Renaming_Alias =>
            Status := RM_Completion_Stable_Withheld_Renaming_Alias;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Renaming_Blocker;
         when Apply.RM_Completion_Application_Withheld_Predicate_Invariant =>
            Status := RM_Completion_Stable_Withheld_Predicate_Invariant;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Predicate_Blocker;
         when Apply.RM_Completion_Application_Withheld_Dataflow =>
            Status := RM_Completion_Stable_Withheld_Dataflow;
            Action := RM_Completion_Convergence_Action_Retain_Stable_Dataflow_Blocker;
         when Apply.RM_Completion_Application_Withheld_Multiple_Prerequisites =>
            Status := RM_Completion_Stable_Multiple_Prerequisites;
            Action := RM_Completion_Convergence_Action_Split_Prerequisites;
         when Apply.RM_Completion_Application_Indeterminate =>
            Status := RM_Completion_Stable_Indeterminate;
            Action := RM_Completion_Convergence_Action_Degrade;
      end case;
   end Classify;

   function Message_For
     (Status : RM_Completion_Convergence_Status;
      Action : RM_Completion_Convergence_Action;
      Family : RM_Completion_Convergence_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("generic/shared-state RM-completion recheck convergence " &
         RM_Completion_Convergence_Status'Image (Status) &
         " action=" & RM_Completion_Convergence_Action'Image (Action) &
         " family=" & Apply.Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : RM_Completion_Convergence_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_430;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Apply.RM_Completion_Application_Status'Pos (Row.Application_Status) + 1);
      H := Mix (H, Apply.RM_Completion_Application_Action'Pos (Row.Application_Action) + 1);
      H := Mix (H, RM_Completion_Convergence_Status'Pos (Row.Status) + 1);
      H := Mix (H, RM_Completion_Convergence_Action'Pos (Row.Action) + 1);
      H := Mix (H, Apply.Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
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
     (Source      : Apply.RM_Completion_Application_Row;
      Index       : Positive;
      Previous_Fp : Natural;
      Model_Fp    : Natural) return RM_Completion_Convergence_Row is
      Status : RM_Completion_Convergence_Status;
      Action : RM_Completion_Convergence_Action;
      Row    : RM_Completion_Convergence_Row;
   begin
      Classify (Source, Previous_Fp, Model_Fp, Status, Action);
      Row.Id := RM_Completion_Convergence_Id (Index);
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
      Row.Object_Name := Source.Object_Name;
      Row.Component_Name := Source.Component_Name;
      Row.Operation_Name := Source.Operation_Name;
      Row.Generic_Unit_Name := Source.Generic_Unit_Name;
      Row.Instance_Name := Source.Instance_Name;
      Row.State_Name := Source.State_Name;
      Row.Current := Status = RM_Completion_Converged_Current;
      Row.Stable := Status /= RM_Completion_Changed_Since_Previous;
      Row.Withheld := Is_Stable_Withheld (Status);
      Row.Changed := Status = RM_Completion_Changed_Since_Previous;
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
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
     (Model : in out RM_Completion_Convergence_Model;
      Row   : RM_Completion_Convergence_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Convergence_Fingerprint);
      if Row.Status in RM_Completion_Converged_Current |
                       RM_Completion_Converged_Not_Required
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
      if Row.Status = RM_Completion_Stable_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out RM_Completion_Convergence_Model) is
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
     (Applications               : Apply.RM_Completion_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return RM_Completion_Convergence_Model is
      Model   : RM_Completion_Convergence_Model;
      Current : constant Natural := Apply.Stable_Fingerprint (Applications);
   begin
      for I in 1 .. Apply.Row_Count (Applications) loop
         Add_Row (Model, Make_Row (Apply.Row_At (Applications, I), I, Previous_Model_Fingerprint, Current));
      end loop;
      return Model;
   end Build;

   function Count (Model : RM_Completion_Convergence_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : RM_Completion_Convergence_Model;
      Index : Positive) return RM_Completion_Convergence_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Completion_Convergence_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Completion_Convergence_Set;
      Index : Positive) return RM_Completion_Convergence_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Add_To_Set
     (Set : in out RM_Completion_Convergence_Set;
      Row : RM_Completion_Convergence_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Convergence_Fingerprint);
   end Add_To_Set;

   function Query_Status
     (Model  : RM_Completion_Convergence_Model;
      Status : RM_Completion_Convergence_Status) return RM_Completion_Convergence_Set is
      Set : RM_Completion_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : RM_Completion_Convergence_Model;
      Action : RM_Completion_Convergence_Action) return RM_Completion_Convergence_Set is
      Set : RM_Completion_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : RM_Completion_Convergence_Model;
      Family : RM_Completion_Convergence_Family) return RM_Completion_Convergence_Set is
      Set : RM_Completion_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Find_By_Node
     (Model : RM_Completion_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return RM_Completion_Convergence_Set is
      Set : RM_Completion_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : RM_Completion_Convergence_Model;
      Fingerprint : Natural) return RM_Completion_Convergence_Set is
      Set : RM_Completion_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : RM_Completion_Convergence_Model;
      Fingerprint : Natural) return RM_Completion_Convergence_Set is
      Set : RM_Completion_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : RM_Completion_Convergence_Model;
      Status : RM_Completion_Convergence_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : RM_Completion_Convergence_Model;
      Family : RM_Completion_Convergence_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Converged_Count (Model : RM_Completion_Convergence_Model) return Natural is
   begin
      return Model.Converged_Total;
   end Converged_Count;

   function Stable_Withheld_Count (Model : RM_Completion_Convergence_Model) return Natural is
   begin
      return Model.Stable_Withheld_Total;
   end Stable_Withheld_Count;

   function Current_Count (Model : RM_Completion_Convergence_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Changed_Count (Model : RM_Completion_Convergence_Model) return Natural is
   begin
      return Model.Changed_Total;
   end Changed_Count;

   function Indeterminate_Count (Model : RM_Completion_Convergence_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : RM_Completion_Convergence_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality;
