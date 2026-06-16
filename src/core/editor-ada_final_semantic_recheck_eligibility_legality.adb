with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 19) mod 2_147_483_647;
   end Mix;

   function Is_Blocked (Status : Final_Recheck_Eligibility_Status) return Boolean is
   begin
      case Status is
         when Final_Recheck_Blocked_By_Stale_Input
            | Final_Recheck_Blocked_By_AST_Coverage
            | Final_Recheck_Blocked_By_Cross_Unit
            | Final_Recheck_Blocked_By_View_Barrier
            | Final_Recheck_Blocked_By_Generic_Replay
            | Final_Recheck_Blocked_By_Overload_Type
            | Final_Recheck_Blocked_By_Representation_Freezing
            | Final_Recheck_Blocked_By_Flow_Contract
            | Final_Recheck_Blocked_By_Tasking_Protected
            | Final_Recheck_Blocked_By_Elaboration
            | Final_Recheck_Blocked_By_Accessibility
            | Final_Recheck_Blocked_By_Discriminant_Variant
            | Final_Recheck_Multiple_Prerequisites
            | Final_Recheck_Indeterminate =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Blocked;

   procedure Classify
     (Source : Worklist.Final_Remediation_Work_Row;
      Status : out Final_Recheck_Eligibility_Status;
      Action : out Final_Recheck_Action) is
   begin
      case Source.Status is
         when Worklist.Final_Work_Accepted_No_Action =>
            Status := Final_Recheck_Not_Required;
            Action := Final_Recheck_Action_None;
         when Worklist.Final_Work_Stale_Reanalysis_Required =>
            Status := Final_Recheck_Blocked_By_Stale_Input;
            Action := Final_Recheck_Action_Wait_For_Snapshot;
         when Worklist.Final_Work_AST_Repair_Required =>
            Status := Final_Recheck_Blocked_By_AST_Coverage;
            Action := Final_Recheck_Action_Wait_For_AST_Coverage;
         when Worklist.Final_Work_Cross_Unit_Closure_Required =>
            Status := Final_Recheck_Blocked_By_Cross_Unit;
            Action := Final_Recheck_Action_Wait_For_Cross_Unit;
         when Worklist.Final_Work_View_Barrier_Repair_Required =>
            Status := Final_Recheck_Blocked_By_View_Barrier;
            Action := Final_Recheck_Action_Wait_For_View_Repair;
         when Worklist.Final_Work_Generic_Replay_Required =>
            Status := Final_Recheck_Blocked_By_Generic_Replay;
            Action := Final_Recheck_Action_Wait_For_Generic_Replay;
         when Worklist.Final_Work_Overload_Type_Required =>
            Status := Final_Recheck_Blocked_By_Overload_Type;
            Action := Final_Recheck_Action_Wait_For_Overload_Type;
         when Worklist.Final_Work_Representation_Freezing_Required =>
            Status := Final_Recheck_Blocked_By_Representation_Freezing;
            Action := Final_Recheck_Action_Wait_For_Representation;
         when Worklist.Final_Work_Flow_Contract_Proof_Required =>
            Status := Final_Recheck_Blocked_By_Flow_Contract;
            Action := Final_Recheck_Action_Wait_For_Flow_Contract;
         when Worklist.Final_Work_Tasking_Protected_Effects_Required =>
            Status := Final_Recheck_Blocked_By_Tasking_Protected;
            Action := Final_Recheck_Action_Wait_For_Tasking;
         when Worklist.Final_Work_Elaboration_Closure_Required =>
            Status := Final_Recheck_Blocked_By_Elaboration;
            Action := Final_Recheck_Action_Wait_For_Elaboration;
         when Worklist.Final_Work_Accessibility_Lifetime_Required =>
            Status := Final_Recheck_Blocked_By_Accessibility;
            Action := Final_Recheck_Action_Wait_For_Accessibility;
         when Worklist.Final_Work_Discriminant_Variant_Required =>
            Status := Final_Recheck_Blocked_By_Discriminant_Variant;
            Action := Final_Recheck_Action_Wait_For_Discriminants;
         when Worklist.Final_Work_Preserved_Semantic_Error =>
            Status := Final_Recheck_Preserved_Semantic_Error;
            Action := Final_Recheck_Action_Preserve_Error;
         when Worklist.Final_Work_Multiple_Blockers_To_Split =>
            Status := Final_Recheck_Multiple_Prerequisites;
            Action := Final_Recheck_Action_Split_Prerequisites;
         when Worklist.Final_Work_Indeterminate_Degraded =>
            Status := Final_Recheck_Indeterminate;
            Action := Final_Recheck_Action_Degrade;
         when others =>
            Status := Final_Recheck_Eligible_Now;
            Action := Final_Recheck_Action_Run_Now;
      end case;
   end Classify;

   function Prerequisite_Depth_For
     (Status : Final_Recheck_Eligibility_Status;
      Work_Depth : Natural) return Natural is
   begin
      if Status = Final_Recheck_Not_Required then
         return 0;
      elsif Status = Final_Recheck_Eligible_Now then
         return Work_Depth;
      else
         return Work_Depth + 1;
      end if;
   end Prerequisite_Depth_For;

   function Message_For
     (Status  : Final_Recheck_Eligibility_Status;
      Action  : Final_Recheck_Action;
      Blocker : Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("final semantic recheck eligibility " &
         Final_Recheck_Eligibility_Status'Image (Status) &
         " action=" & Final_Recheck_Action'Image (Action) &
         " blocker=" & Final_Blocker_Family'Image (Blocker));
   end Message_For;

   function Row_Fingerprint (Row : Final_Recheck_Eligibility_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Work_Id));
      H := Mix (H, Worklist.Final_Remediation_Work_Status'Pos (Row.Work_Status) + 1);
      H := Mix (H, Worklist.Final_Remediation_Work_Action'Pos (Row.Work_Action) + 1);
      H := Mix (H, Worklist.Final_Remediation_Work_Phase'Pos (Row.Work_Phase) + 1);
      H := Mix (H, Final_Recheck_Eligibility_Status'Pos (Row.Status) + 1);
      H := Mix (H, Final_Recheck_Action'Pos (Row.Action) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority);
      H := Mix (H, Row.Dependency_Depth);
      H := Mix (H, Row.Prerequisite_Depth);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Work_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Worklist.Final_Remediation_Work_Row;
      Index  : Positive) return Final_Recheck_Eligibility_Row is
      Status : Final_Recheck_Eligibility_Status;
      Action : Final_Recheck_Action;
      Result : Final_Recheck_Eligibility_Row;
   begin
      Classify (Source, Status, Action);
      Result.Id := Final_Recheck_Eligibility_Id (Index);
      Result.Work_Id := Source.Id;
      Result.Work_Status := Source.Status;
      Result.Work_Action := Source.Action;
      Result.Work_Phase := Source.Phase;
      Result.Status := Status;
      Result.Action := Action;
      Result.Blocker_Family := Source.Blocker_Family;
      Result.Node := Source.Node;
      Result.Priority := Source.Priority;
      Result.Dependency_Depth := Source.Dependency_Depth;
      Result.Prerequisite_Depth := Prerequisite_Depth_For (Status, Source.Dependency_Depth);
      Result.Start_Line := Source.Start_Line;
      Result.Start_Column := Source.Start_Column;
      Result.End_Line := Source.End_Line;
      Result.End_Column := Source.End_Column;
      Result.Source_Fingerprint := Source.Source_Fingerprint;
      Result.Work_Fingerprint := Source.Work_Fingerprint;
      Result.Message := Message_For (Status, Action, Source.Blocker_Family);
      Result.Eligibility_Fingerprint := Row_Fingerprint (Result);
      return Result;
   end Make_Row;

   procedure Add_Row
     (Model : in out Final_Recheck_Eligibility_Model;
      Row   : Final_Recheck_Eligibility_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Eligibility_Fingerprint);

      if Row.Status = Final_Recheck_Eligible_Now then
         Model.Eligible_Total := Model.Eligible_Total + 1;
      end if;
      if Is_Blocked (Row.Status) then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;

      case Row.Status is
         when Final_Recheck_Blocked_By_Stale_Input => Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Recheck_Blocked_By_AST_Coverage => Model.AST_Total := Model.AST_Total + 1;
         when Final_Recheck_Blocked_By_Cross_Unit | Final_Recheck_Blocked_By_View_Barrier =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Final_Recheck_Blocked_By_Generic_Replay => Model.Generic_Total := Model.Generic_Total + 1;
         when Final_Recheck_Blocked_By_Overload_Type => Model.Overload_Total := Model.Overload_Total + 1;
         when Final_Recheck_Blocked_By_Representation_Freezing => Model.Representation_Total := Model.Representation_Total + 1;
         when Final_Recheck_Blocked_By_Flow_Contract => Model.Flow_Total := Model.Flow_Total + 1;
         when Final_Recheck_Blocked_By_Tasking_Protected => Model.Tasking_Total := Model.Tasking_Total + 1;
         when Final_Recheck_Blocked_By_Elaboration => Model.Elaboration_Total := Model.Elaboration_Total + 1;
         when Final_Recheck_Blocked_By_Accessibility => Model.Accessibility_Total := Model.Accessibility_Total + 1;
         when Final_Recheck_Blocked_By_Discriminant_Variant => Model.Discriminant_Total := Model.Discriminant_Total + 1;
         when Final_Recheck_Multiple_Prerequisites => Model.Multiple_Prerequisite_Total := Model.Multiple_Prerequisite_Total + 1;
         when Final_Recheck_Indeterminate => Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others => null;
      end case;
   end Add_Row;

   procedure Clear (Model : in out Final_Recheck_Eligibility_Model) is
   begin
      Model.Rows.Clear;
      Model.Eligible_Total := 0;
      Model.Blocked_Total := 0;
      Model.Stale_Total := 0;
      Model.AST_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Generic_Total := 0;
      Model.Overload_Total := 0;
      Model.Representation_Total := 0;
      Model.Flow_Total := 0;
      Model.Tasking_Total := 0;
      Model.Elaboration_Total := 0;
      Model.Accessibility_Total := 0;
      Model.Discriminant_Total := 0;
      Model.Multiple_Prerequisite_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Work : Worklist.Final_Remediation_Worklist_Model)
      return Final_Recheck_Eligibility_Model is
      Result : Final_Recheck_Eligibility_Model;
   begin
      for I in 1 .. Worklist.Row_Count (Work) loop
         Add_Row (Result, Make_Row (Worklist.Row_At (Work, I), I));
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Recheck_Eligibility_Model;
      Index : Positive) return Final_Recheck_Eligibility_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Final_Recheck_Eligibility_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Final_Recheck_Eligibility_Set;
      Index : Positive) return Final_Recheck_Eligibility_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Final_Recheck_Eligibility_Set;
      Row : Final_Recheck_Eligibility_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Eligibility_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Final_Recheck_Eligibility_Model;
      Status : Final_Recheck_Eligibility_Status) return Final_Recheck_Eligibility_Set is
      Result : Final_Recheck_Eligibility_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Action
     (Model  : Final_Recheck_Eligibility_Model;
      Action : Final_Recheck_Action) return Final_Recheck_Eligibility_Set is
      Result : Final_Recheck_Eligibility_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Action;

   function Query_Blocker
     (Model   : Final_Recheck_Eligibility_Model;
      Blocker : Final_Blocker_Family) return Final_Recheck_Eligibility_Set is
      Result : Final_Recheck_Eligibility_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Recheck_Eligibility_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Recheck_Eligibility_Set is
      Result : Final_Recheck_Eligibility_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Count_Status
     (Model  : Final_Recheck_Eligibility_Model;
      Status : Final_Recheck_Eligibility_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : Final_Recheck_Eligibility_Model;
      Action : Final_Recheck_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Blocker
     (Model   : Final_Recheck_Eligibility_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Eligible_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Eligible_Total;
   end Eligible_Count;

   function Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Stale_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Blocked_Count;

   function AST_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.AST_Total;
   end AST_Blocked_Count;

   function Cross_Unit_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Cross_Unit_Total;
   end Cross_Unit_Blocked_Count;

   function Generic_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Generic_Total;
   end Generic_Blocked_Count;

   function Overload_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Overload_Total;
   end Overload_Blocked_Count;

   function Representation_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Representation_Total;
   end Representation_Blocked_Count;

   function Flow_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Flow_Total;
   end Flow_Blocked_Count;

   function Tasking_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Tasking_Total;
   end Tasking_Blocked_Count;

   function Elaboration_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Elaboration_Total;
   end Elaboration_Blocked_Count;

   function Accessibility_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Accessibility_Total;
   end Accessibility_Blocked_Count;

   function Discriminant_Blocked_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Discriminant_Total;
   end Discriminant_Blocked_Count;

   function Multiple_Prerequisite_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Multiple_Prerequisite_Total;
   end Multiple_Prerequisite_Count;

   function Indeterminate_Count (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Final_Recheck_Eligibility_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality;
