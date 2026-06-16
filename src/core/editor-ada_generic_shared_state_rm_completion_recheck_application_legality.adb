with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality is

   pragma Suppress (Overflow_Check);
   use type RM_Completion_Application_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_421) mod 2_147_483_647;
   end Mix;

   procedure Classify
     (Source : Recheck.RM_Completion_Recheck_Row;
      Status : out RM_Completion_Application_Status;
      Action : out RM_Completion_Application_Action) is
   begin
      case Source.Status is
         when Recheck.RM_Completion_Recheck_Not_Checked =>
            Status := RM_Completion_Application_Withheld_Stale_Or_Fingerprint;
            Action := RM_Completion_Application_Action_Withhold_For_Fingerprint;
         when Recheck.RM_Completion_Recheck_Not_Required_Current =>
            Status := RM_Completion_Application_Current_Non_Diagnostic_Evidence;
            Action := RM_Completion_Application_Action_Keep_Non_Diagnostic_Evidence;
         when Recheck.RM_Completion_Recheck_Eligible_Now =>
            Status := RM_Completion_Application_Current_Accepted;
            Action := RM_Completion_Application_Action_Expose_Current;
         when Recheck.RM_Completion_Recheck_Blocked_By_Stale_Or_Fingerprint =>
            Status := RM_Completion_Application_Withheld_Stale_Or_Fingerprint;
            Action := RM_Completion_Application_Action_Withhold_For_Fingerprint;
         when Recheck.RM_Completion_Recheck_Blocked_By_AST_Or_Coverage =>
            Status := RM_Completion_Application_Withheld_AST_Or_Coverage;
            Action := RM_Completion_Application_Action_Withhold_For_AST_Repair;
         when Recheck.RM_Completion_Recheck_Blocked_By_Cross_Unit =>
            Status := RM_Completion_Application_Withheld_Cross_Unit;
            Action := RM_Completion_Application_Action_Withhold_For_Cross_Unit;
         when Recheck.RM_Completion_Recheck_Blocked_By_Generic_Substitution =>
            Status := RM_Completion_Application_Withheld_Generic_Substitution;
            Action := RM_Completion_Application_Action_Withhold_For_Generic_Substitution;
         when Recheck.RM_Completion_Recheck_Blocked_By_Prior_Dataflow =>
            Status := RM_Completion_Application_Withheld_Prior_Dataflow;
            Action := RM_Completion_Application_Action_Withhold_For_Prior_Dataflow;
         when Recheck.RM_Completion_Recheck_Blocked_By_Volatile_Atomic =>
            Status := RM_Completion_Application_Withheld_Volatile_Atomic;
            Action := RM_Completion_Application_Action_Withhold_For_Volatile_Atomic;
         when Recheck.RM_Completion_Recheck_Blocked_By_Overload_Type =>
            Status := RM_Completion_Application_Withheld_Overload_Type;
            Action := RM_Completion_Application_Action_Withhold_For_Overload_Type;
         when Recheck.RM_Completion_Recheck_Blocked_By_Representation =>
            Status := RM_Completion_Application_Withheld_Representation;
            Action := RM_Completion_Application_Action_Withhold_For_Representation;
         when Recheck.RM_Completion_Recheck_Blocked_By_Tasking_Protected =>
            Status := RM_Completion_Application_Withheld_Tasking_Protected;
            Action := RM_Completion_Application_Action_Withhold_For_Tasking_Protected;
         when Recheck.RM_Completion_Recheck_Blocked_By_Elaboration =>
            Status := RM_Completion_Application_Withheld_Elaboration;
            Action := RM_Completion_Application_Action_Withhold_For_Elaboration;
         when Recheck.RM_Completion_Recheck_Blocked_By_Accessibility =>
            Status := RM_Completion_Application_Withheld_Accessibility;
            Action := RM_Completion_Application_Action_Withhold_For_Accessibility;
         when Recheck.RM_Completion_Recheck_Blocked_By_Discriminant_Variant =>
            Status := RM_Completion_Application_Withheld_Discriminant_Variant;
            Action := RM_Completion_Application_Action_Withhold_For_Discriminants;
         when Recheck.RM_Completion_Recheck_Blocked_By_Exception_Finalization =>
            Status := RM_Completion_Application_Withheld_Exception_Finalization;
            Action := RM_Completion_Application_Action_Withhold_For_Exception_Finalization;
         when Recheck.RM_Completion_Recheck_Blocked_By_Renaming_Alias =>
            Status := RM_Completion_Application_Withheld_Renaming_Alias;
            Action := RM_Completion_Application_Action_Withhold_For_Renaming;
         when Recheck.RM_Completion_Recheck_Blocked_By_Predicate_Invariant =>
            Status := RM_Completion_Application_Withheld_Predicate_Invariant;
            Action := RM_Completion_Application_Action_Withhold_For_Predicate;
         when Recheck.RM_Completion_Recheck_Blocked_By_Dataflow =>
            Status := RM_Completion_Application_Withheld_Dataflow;
            Action := RM_Completion_Application_Action_Withhold_For_Dataflow;
         when Recheck.RM_Completion_Recheck_Multiple_Prerequisites =>
            Status := RM_Completion_Application_Withheld_Multiple_Prerequisites;
            Action := RM_Completion_Application_Action_Split_Prerequisites;
         when Recheck.RM_Completion_Recheck_Indeterminate =>
            Status := RM_Completion_Application_Indeterminate;
            Action := RM_Completion_Application_Action_Degrade;
      end case;
   end Classify;

   function Is_Current (Status : RM_Completion_Application_Status) return Boolean is
   begin
      return Status in RM_Completion_Application_Current_Accepted |
                       RM_Completion_Application_Current_Non_Diagnostic_Evidence;
   end Is_Current;

   function Is_Accepted (Status : RM_Completion_Application_Status) return Boolean is
   begin
      return Status = RM_Completion_Application_Current_Accepted;
   end Is_Accepted;

   function Is_Withheld (Status : RM_Completion_Application_Status) return Boolean is
   begin
      return Status in RM_Completion_Application_Withheld_Stale_Or_Fingerprint |
                       RM_Completion_Application_Withheld_AST_Or_Coverage |
                       RM_Completion_Application_Withheld_Cross_Unit |
                       RM_Completion_Application_Withheld_Generic_Substitution |
                       RM_Completion_Application_Withheld_Prior_Dataflow |
                       RM_Completion_Application_Withheld_Volatile_Atomic |
                       RM_Completion_Application_Withheld_Overload_Type |
                       RM_Completion_Application_Withheld_Representation |
                       RM_Completion_Application_Withheld_Tasking_Protected |
                       RM_Completion_Application_Withheld_Elaboration |
                       RM_Completion_Application_Withheld_Accessibility |
                       RM_Completion_Application_Withheld_Discriminant_Variant |
                       RM_Completion_Application_Withheld_Exception_Finalization |
                       RM_Completion_Application_Withheld_Renaming_Alias |
                       RM_Completion_Application_Withheld_Predicate_Invariant |
                       RM_Completion_Application_Withheld_Dataflow |
                       RM_Completion_Application_Withheld_Multiple_Prerequisites |
                       RM_Completion_Application_Indeterminate;
   end Is_Withheld;

   function Message_For
     (Status : RM_Completion_Application_Status;
      Action : RM_Completion_Application_Action;
      Family : RM_Completion_Application_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("RM-completed generic/shared-state recheck application " &
         RM_Completion_Application_Status'Image (Status) &
         " action=" & RM_Completion_Application_Action'Image (Action) &
         " family=" &
         Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : RM_Completion_Application_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_420;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Recheck.RM_Completion_Recheck_Status'Pos (Row.Eligibility_Status) + 1);
      H := Mix (H, Recheck.RM_Completion_Recheck_Action'Pos (Row.Eligibility_Action) + 1);
      H := Mix (H, RM_Completion_Application_Status'Pos (Row.Status) + 1);
      H := Mix (H, RM_Completion_Application_Action'Pos (Row.Action) + 1);
      H := Mix (H, Recheck.Worklist.Diagnostics.RM_Completion_Diagnostic_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Worklist_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Recheck.RM_Completion_Recheck_Row;
      Index  : Positive) return RM_Completion_Application_Row is
      Status : RM_Completion_Application_Status;
      Action : RM_Completion_Application_Action;
      Row    : RM_Completion_Application_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := RM_Completion_Application_Id (Index);
      Row.Eligibility_Id := Source.Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Diagnostic_Row := Source.Diagnostic_Row;
      Row.Eligibility_Status := Source.Status;
      Row.Eligibility_Action := Source.Action;
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
      Row.Current := Is_Current (Status);
      Row.Accepted := Is_Accepted (Status);
      Row.Withheld := Is_Withheld (Status);
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Message := Message_For (Status, Action, Source.Family);
      Row.Application_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out RM_Completion_Application_Model;
      Row   : RM_Completion_Application_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Application_Fingerprint);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Withheld then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;
      if Row.Current then
         Model.Current_Total := Model.Current_Total + 1;
      end if;
      if Row.Status = RM_Completion_Application_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out RM_Completion_Application_Model) is
   begin
      Model.Rows.Clear;
      Model.Accepted_Total := 0;
      Model.Withheld_Total := 0;
      Model.Current_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Eligibility : Recheck.RM_Completion_Recheck_Model)
      return RM_Completion_Application_Model is
      Model : RM_Completion_Application_Model;
   begin
      for Index in 1 .. Recheck.Row_Count (Eligibility) loop
         Add_Row (Model, Make_Row (Recheck.Row_At (Eligibility, Index), Index));
      end loop;
      return Model;
   end Build;

   function Count (Model : RM_Completion_Application_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : RM_Completion_Application_Model;
      Index : Positive) return RM_Completion_Application_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : RM_Completion_Application_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : RM_Completion_Application_Set;
      Index : Positive) return RM_Completion_Application_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Add_To_Set
     (Set : in out RM_Completion_Application_Set;
      Row : RM_Completion_Application_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Application_Fingerprint);
   end Add_To_Set;

   function Query_Status
     (Model  : RM_Completion_Application_Model;
      Status : RM_Completion_Application_Status)
      return RM_Completion_Application_Set is
      Set : RM_Completion_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : RM_Completion_Application_Model;
      Action : RM_Completion_Application_Action)
      return RM_Completion_Application_Set is
      Set : RM_Completion_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : RM_Completion_Application_Model;
      Family : RM_Completion_Application_Family)
      return RM_Completion_Application_Set is
      Set : RM_Completion_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Find_By_Node
     (Model : RM_Completion_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Completion_Application_Set is
      Set : RM_Completion_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : RM_Completion_Application_Model;
      Fingerprint : Natural)
      return RM_Completion_Application_Set is
      Set : RM_Completion_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : RM_Completion_Application_Model;
      Fingerprint : Natural)
      return RM_Completion_Application_Set is
      Set : RM_Completion_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : RM_Completion_Application_Model;
      Status : RM_Completion_Application_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : RM_Completion_Application_Model;
      Family : RM_Completion_Application_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Accepted_Count (Model : RM_Completion_Application_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Withheld_Count (Model : RM_Completion_Application_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Current_Count (Model : RM_Completion_Application_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Indeterminate_Count (Model : RM_Completion_Application_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : RM_Completion_Application_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality;
