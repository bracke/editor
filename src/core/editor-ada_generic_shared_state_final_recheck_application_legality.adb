with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality is
   use type Generic_Shared_State_Final_Application_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_421) mod 2_147_483_647;
   end Mix;

   procedure Classify
     (Source : Recheck.Generic_Shared_State_Final_Recheck_Row;
      Status : out Generic_Shared_State_Final_Application_Status;
      Action : out Generic_Shared_State_Final_Application_Action) is
   begin
      case Source.Status is
         when Recheck.Generic_Shared_State_Final_Recheck_Not_Checked =>
            Status := Generic_Shared_State_Final_Application_Withheld_Stale_Or_Fingerprint;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Fingerprint;
         when Recheck.Generic_Shared_State_Final_Recheck_Not_Required_Current =>
            Status := Generic_Shared_State_Final_Application_Current_Non_Diagnostic_Evidence;
            Action := Generic_Shared_State_Final_Application_Action_Keep_Non_Diagnostic_Evidence;
         when Recheck.Generic_Shared_State_Final_Recheck_Eligible_Now =>
            Status := Generic_Shared_State_Final_Application_Current_Accepted;
            Action := Generic_Shared_State_Final_Application_Action_Expose_Current;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Stale_Or_Fingerprint =>
            Status := Generic_Shared_State_Final_Application_Withheld_Stale_Or_Fingerprint;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Fingerprint;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_AST_Or_Coverage =>
            Status := Generic_Shared_State_Final_Application_Withheld_AST_Or_Coverage;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_AST_Repair;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Cross_Unit =>
            Status := Generic_Shared_State_Final_Application_Withheld_Cross_Unit;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Cross_Unit;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Generic_Replay =>
            Status := Generic_Shared_State_Final_Application_Withheld_Generic_Replay;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Generic_Replay;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Abstract_Or_Shared_State =>
            Status := Generic_Shared_State_Final_Application_Withheld_Abstract_Or_Shared_State;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Shared_State;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Volatile_Atomic =>
            Status := Generic_Shared_State_Final_Application_Withheld_Volatile_Atomic;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Volatile_Atomic;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Overload_Type =>
            Status := Generic_Shared_State_Final_Application_Withheld_Overload_Type;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Overload_Type;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Representation =>
            Status := Generic_Shared_State_Final_Application_Withheld_Representation;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Representation;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Tasking_Protected =>
            Status := Generic_Shared_State_Final_Application_Withheld_Tasking_Protected;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Tasking_Protected;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Elaboration =>
            Status := Generic_Shared_State_Final_Application_Withheld_Elaboration;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Elaboration;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Accessibility =>
            Status := Generic_Shared_State_Final_Application_Withheld_Accessibility;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Accessibility;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Discriminant_Variant =>
            Status := Generic_Shared_State_Final_Application_Withheld_Discriminant_Variant;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Discriminants;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Exception_Finalization =>
            Status := Generic_Shared_State_Final_Application_Withheld_Exception_Finalization;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Exception_Finalization;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Renaming_Alias =>
            Status := Generic_Shared_State_Final_Application_Withheld_Renaming_Alias;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Renaming;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Predicate_Invariant =>
            Status := Generic_Shared_State_Final_Application_Withheld_Predicate_Invariant;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Predicate;
         when Recheck.Generic_Shared_State_Final_Recheck_Blocked_By_Dataflow =>
            Status := Generic_Shared_State_Final_Application_Withheld_Dataflow;
            Action := Generic_Shared_State_Final_Application_Action_Withhold_For_Dataflow;
         when Recheck.Generic_Shared_State_Final_Recheck_Multiple_Prerequisites =>
            Status := Generic_Shared_State_Final_Application_Withheld_Multiple_Prerequisites;
            Action := Generic_Shared_State_Final_Application_Action_Split_Prerequisites;
         when Recheck.Generic_Shared_State_Final_Recheck_Indeterminate =>
            Status := Generic_Shared_State_Final_Application_Indeterminate;
            Action := Generic_Shared_State_Final_Application_Action_Degrade;
      end case;
   end Classify;

   function Is_Current (Status : Generic_Shared_State_Final_Application_Status) return Boolean is
   begin
      return Status in Generic_Shared_State_Final_Application_Current_Accepted |
                       Generic_Shared_State_Final_Application_Current_Non_Diagnostic_Evidence;
   end Is_Current;

   function Is_Accepted (Status : Generic_Shared_State_Final_Application_Status) return Boolean is
   begin
      return Status = Generic_Shared_State_Final_Application_Current_Accepted;
   end Is_Accepted;

   function Is_Withheld (Status : Generic_Shared_State_Final_Application_Status) return Boolean is
   begin
      return Status in Generic_Shared_State_Final_Application_Withheld_Stale_Or_Fingerprint |
                       Generic_Shared_State_Final_Application_Withheld_AST_Or_Coverage |
                       Generic_Shared_State_Final_Application_Withheld_Cross_Unit |
                       Generic_Shared_State_Final_Application_Withheld_Generic_Replay |
                       Generic_Shared_State_Final_Application_Withheld_Abstract_Or_Shared_State |
                       Generic_Shared_State_Final_Application_Withheld_Volatile_Atomic |
                       Generic_Shared_State_Final_Application_Withheld_Overload_Type |
                       Generic_Shared_State_Final_Application_Withheld_Representation |
                       Generic_Shared_State_Final_Application_Withheld_Tasking_Protected |
                       Generic_Shared_State_Final_Application_Withheld_Elaboration |
                       Generic_Shared_State_Final_Application_Withheld_Accessibility |
                       Generic_Shared_State_Final_Application_Withheld_Discriminant_Variant |
                       Generic_Shared_State_Final_Application_Withheld_Exception_Finalization |
                       Generic_Shared_State_Final_Application_Withheld_Renaming_Alias |
                       Generic_Shared_State_Final_Application_Withheld_Predicate_Invariant |
                       Generic_Shared_State_Final_Application_Withheld_Dataflow |
                       Generic_Shared_State_Final_Application_Withheld_Multiple_Prerequisites |
                       Generic_Shared_State_Final_Application_Indeterminate;
   end Is_Withheld;

   function Message_For
     (Status : Generic_Shared_State_Final_Application_Status;
      Action : Generic_Shared_State_Final_Application_Action;
      Family : Generic_Shared_State_Final_Application_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("generic/shared-state final recheck application " &
         Generic_Shared_State_Final_Application_Status'Image (Status) &
         " action=" & Generic_Shared_State_Final_Application_Action'Image (Action) &
         " family=" &
         Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Generic_Shared_State_Final_Application_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_420;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Recheck.Generic_Shared_State_Final_Recheck_Status'Pos (Row.Eligibility_Status) + 1);
      H := Mix (H, Recheck.Generic_Shared_State_Final_Recheck_Action'Pos (Row.Eligibility_Action) + 1);
      H := Mix (H, Generic_Shared_State_Final_Application_Status'Pos (Row.Status) + 1);
      H := Mix (H, Generic_Shared_State_Final_Application_Action'Pos (Row.Action) + 1);
      H := Mix (H, Recheck.Worklist.Diagnostics.Generic_Shared_State_Final_Diagnostic_Family'Pos (Row.Family) + 1);
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
     (Source : Recheck.Generic_Shared_State_Final_Recheck_Row;
      Index  : Positive) return Generic_Shared_State_Final_Application_Row is
      Status : Generic_Shared_State_Final_Application_Status;
      Action : Generic_Shared_State_Final_Application_Action;
      Row    : Generic_Shared_State_Final_Application_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := Generic_Shared_State_Final_Application_Id (Index);
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
     (Model : in out Generic_Shared_State_Final_Application_Model;
      Row   : Generic_Shared_State_Final_Application_Row) is
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
      if Row.Status = Generic_Shared_State_Final_Application_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Generic_Shared_State_Final_Application_Model) is
   begin
      Model.Rows.Clear;
      Model.Accepted_Total := 0;
      Model.Withheld_Total := 0;
      Model.Current_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Eligibility : Recheck.Generic_Shared_State_Final_Recheck_Model)
      return Generic_Shared_State_Final_Application_Model is
      Model : Generic_Shared_State_Final_Application_Model;
   begin
      for Index in 1 .. Recheck.Row_Count (Eligibility) loop
         Add_Row (Model, Make_Row (Recheck.Row_At (Eligibility, Index), Index));
      end loop;
      return Model;
   end Build;

   function Count (Model : Generic_Shared_State_Final_Application_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Generic_Shared_State_Final_Application_Model;
      Index : Positive) return Generic_Shared_State_Final_Application_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Generic_Shared_State_Final_Application_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Generic_Shared_State_Final_Application_Set;
      Index : Positive) return Generic_Shared_State_Final_Application_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Add_To_Set
     (Set : in out Generic_Shared_State_Final_Application_Set;
      Row : Generic_Shared_State_Final_Application_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Application_Fingerprint);
   end Add_To_Set;

   function Query_Status
     (Model  : Generic_Shared_State_Final_Application_Model;
      Status : Generic_Shared_State_Final_Application_Status)
      return Generic_Shared_State_Final_Application_Set is
      Set : Generic_Shared_State_Final_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Generic_Shared_State_Final_Application_Model;
      Action : Generic_Shared_State_Final_Application_Action)
      return Generic_Shared_State_Final_Application_Set is
      Set : Generic_Shared_State_Final_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Generic_Shared_State_Final_Application_Model;
      Family : Generic_Shared_State_Final_Application_Family)
      return Generic_Shared_State_Final_Application_Set is
      Set : Generic_Shared_State_Final_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Find_By_Node
     (Model : Generic_Shared_State_Final_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Generic_Shared_State_Final_Application_Set is
      Set : Generic_Shared_State_Final_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Generic_Shared_State_Final_Application_Model;
      Fingerprint : Natural)
      return Generic_Shared_State_Final_Application_Set is
      Set : Generic_Shared_State_Final_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : Generic_Shared_State_Final_Application_Model;
      Fingerprint : Natural)
      return Generic_Shared_State_Final_Application_Set is
      Set : Generic_Shared_State_Final_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Add_To_Set (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : Generic_Shared_State_Final_Application_Model;
      Status : Generic_Shared_State_Final_Application_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : Generic_Shared_State_Final_Application_Model;
      Family : Generic_Shared_State_Final_Application_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Accepted_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Withheld_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Current_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Indeterminate_Count (Model : Generic_Shared_State_Final_Application_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Generic_Shared_State_Final_Application_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality;
