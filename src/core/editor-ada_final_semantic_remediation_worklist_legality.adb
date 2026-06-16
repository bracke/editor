with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Final_Semantic_Remediation_Worklist_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;
   use type Final_Remediation_Provenance_Status;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 17) mod 2_147_483_647;
   end Mix;

   function Priority_For
     (Status  : Final_Remediation_Work_Status;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      case Status is
         when Final_Work_Stale_Reanalysis_Required => return 10;
         when Final_Work_AST_Repair_Required => return 20;
         when Final_Work_Cross_Unit_Closure_Required => return 30;
         when Final_Work_View_Barrier_Repair_Required => return 31;
         when Final_Work_Generic_Replay_Required => return 40;
         when Final_Work_Overload_Type_Required => return 41;
         when Final_Work_Representation_Freezing_Required => return 50;
         when Final_Work_Flow_Contract_Proof_Required => return 51;
         when Final_Work_Tasking_Protected_Effects_Required => return 60;
         when Final_Work_Elaboration_Closure_Required => return 61;
         when Final_Work_Accessibility_Lifetime_Required => return 62;
         when Final_Work_Discriminant_Variant_Required => return 70;
         when Final_Work_Preserved_Semantic_Error => return 80;
         when Final_Work_Multiple_Blockers_To_Split => return 90;
         when Final_Work_Indeterminate_Degraded => return 100;
         when Final_Work_Accepted_No_Action => return 1_000;
         when Final_Work_Not_Checked =>
            case Blocker is
               when Final_Prov.Final_Blocker_AST_Repair | Final_Prov.Final_Blocker_Coverage_Gate => return 20;
               when Final_Prov.Final_Blocker_Cross_Unit => return 30;
               when Final_Prov.Final_Blocker_View_Barrier => return 31;
               when Final_Prov.Final_Blocker_Generic_Replay => return 40;
               when Final_Prov.Final_Blocker_Overload_Type => return 41;
               when Final_Prov.Final_Blocker_Representation_Freezing => return 50;
               when Final_Prov.Final_Blocker_Flow_Contract => return 51;
               when Final_Prov.Final_Blocker_Tasking_Protected => return 60;
               when Final_Prov.Final_Blocker_Elaboration => return 61;
               when Final_Prov.Final_Blocker_Accessibility_Lifetime => return 62;
               when Final_Prov.Final_Blocker_Discriminant_Variant => return 70;
               when Final_Prov.Final_Blocker_Multiple => return 90;
               when others => return 100;
            end case;
      end case;
   end Priority_For;

   procedure Classify
     (Source : Remed_Prov.Final_Remediation_Provenance_Info;
      Status : out Final_Remediation_Work_Status;
      Action : out Final_Remediation_Work_Action;
      Phase  : out Final_Remediation_Work_Phase) is
   begin
      if Source.Status = Remed_Prov.Final_Remediation_Provenance_Withheld_Legal
        or else Source.Blocker_Family = Final_Prov.Final_Blocker_None
      then
         Status := Final_Work_Accepted_No_Action;
         Action := Final_Work_Action_None;
         Phase := Final_Work_Phase_None;
         return;
      elsif Source.Status = Remed_Prov.Final_Remediation_Provenance_Stale_Rejected then
         Status := Final_Work_Stale_Reanalysis_Required;
         Action := Final_Work_Action_Recompute_Snapshot;
         Phase := Final_Work_Phase_Stale_Input;
         return;
      elsif Source.Status = Remed_Prov.Final_Remediation_Provenance_Preserved_Semantic_Error then
         Status := Final_Work_Preserved_Semantic_Error;
         Action := Final_Work_Action_Preserve_Semantic_Error;
         Phase := Final_Work_Phase_Preserved_Error;
         return;
      elsif Source.Status = Remed_Prov.Final_Remediation_Provenance_Multiple_Blockers
        or else Source.Blocker_Family = Final_Prov.Final_Blocker_Multiple
      then
         Status := Final_Work_Multiple_Blockers_To_Split;
         Action := Final_Work_Action_Split_Multiple_Blockers;
         Phase := Final_Work_Phase_Indeterminate;
         return;
      elsif Source.Status = Remed_Prov.Final_Remediation_Provenance_Indeterminate then
         Status := Final_Work_Indeterminate_Degraded;
         Action := Final_Work_Action_Degrade_Indeterminate;
         Phase := Final_Work_Phase_Indeterminate;
         return;
      end if;

      case Source.Blocker_Family is
         when Final_Prov.Final_Blocker_AST_Repair | Final_Prov.Final_Blocker_Coverage_Gate =>
            Status := Final_Work_AST_Repair_Required;
            Action := Final_Work_Action_Repair_AST_Coverage;
            Phase := Final_Work_Phase_AST_And_Coverage;
         when Final_Prov.Final_Blocker_Cross_Unit =>
            Status := Final_Work_Cross_Unit_Closure_Required;
            Action := Final_Work_Action_Resolve_Cross_Unit;
            Phase := Final_Work_Phase_Cross_Unit_And_View;
         when Final_Prov.Final_Blocker_View_Barrier =>
            Status := Final_Work_View_Barrier_Repair_Required;
            Action := Final_Work_Action_Resolve_View_Barrier;
            Phase := Final_Work_Phase_Cross_Unit_And_View;
         when Final_Prov.Final_Blocker_Generic_Replay =>
            Status := Final_Work_Generic_Replay_Required;
            Action := Final_Work_Action_Replay_Generic;
            Phase := Final_Work_Phase_Generic_And_Type;
         when Final_Prov.Final_Blocker_Overload_Type =>
            Status := Final_Work_Overload_Type_Required;
            Action := Final_Work_Action_Resolve_Overload_Type;
            Phase := Final_Work_Phase_Generic_And_Type;
         when Final_Prov.Final_Blocker_Representation_Freezing =>
            Status := Final_Work_Representation_Freezing_Required;
            Action := Final_Work_Action_Recheck_Representation_Freezing;
            Phase := Final_Work_Phase_Representation_And_Flow;
         when Final_Prov.Final_Blocker_Flow_Contract =>
            Status := Final_Work_Flow_Contract_Proof_Required;
            Action := Final_Work_Action_Prove_Flow_Contract;
            Phase := Final_Work_Phase_Representation_And_Flow;
         when Final_Prov.Final_Blocker_Tasking_Protected =>
            Status := Final_Work_Tasking_Protected_Effects_Required;
            Action := Final_Work_Action_Recheck_Tasking_Protected;
            Phase := Final_Work_Phase_Task_Elaboration_Access;
         when Final_Prov.Final_Blocker_Elaboration =>
            Status := Final_Work_Elaboration_Closure_Required;
            Action := Final_Work_Action_Recheck_Elaboration;
            Phase := Final_Work_Phase_Task_Elaboration_Access;
         when Final_Prov.Final_Blocker_Accessibility_Lifetime =>
            Status := Final_Work_Accessibility_Lifetime_Required;
            Action := Final_Work_Action_Recheck_Accessibility;
            Phase := Final_Work_Phase_Task_Elaboration_Access;
         when Final_Prov.Final_Blocker_Discriminant_Variant =>
            Status := Final_Work_Discriminant_Variant_Required;
            Action := Final_Work_Action_Recheck_Discriminants;
            Phase := Final_Work_Phase_Discriminant_And_Final;
         when Final_Prov.Final_Blocker_Multiple =>
            Status := Final_Work_Multiple_Blockers_To_Split;
            Action := Final_Work_Action_Split_Multiple_Blockers;
            Phase := Final_Work_Phase_Indeterminate;
         when others =>
            Status := Final_Work_Indeterminate_Degraded;
            Action := Final_Work_Action_Degrade_Indeterminate;
            Phase := Final_Work_Phase_Indeterminate;
      end case;
   end Classify;

   function Depth_For (Phase : Final_Remediation_Work_Phase) return Natural is
   begin
      case Phase is
         when Final_Work_Phase_None => return 0;
         when Final_Work_Phase_Stale_Input => return 1;
         when Final_Work_Phase_AST_And_Coverage => return 2;
         when Final_Work_Phase_Cross_Unit_And_View => return 3;
         when Final_Work_Phase_Generic_And_Type => return 4;
         when Final_Work_Phase_Representation_And_Flow => return 5;
         when Final_Work_Phase_Task_Elaboration_Access => return 6;
         when Final_Work_Phase_Discriminant_And_Final => return 7;
         when Final_Work_Phase_Preserved_Error => return 8;
         when Final_Work_Phase_Indeterminate => return 9;
      end case;
   end Depth_For;

   function Message_For
     (Status  : Final_Remediation_Work_Status;
      Action  : Final_Remediation_Work_Action;
      Blocker : Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("final semantic remediation worklist " &
         Final_Remediation_Work_Status'Image (Status) &
         " action=" & Final_Remediation_Work_Action'Image (Action) &
         " blocker=" & Final_Blocker_Family'Image (Blocker));
   end Message_For;

   function Row_Fingerprint (Row : Final_Remediation_Work_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Provenance_Id));
      H := Mix (H, Remed_Prov.Final_Remediation_Provenance_Status'Pos (Row.Provenance_Status) + 1);
      H := Mix (H, Remed_Prov.Final_Remediation_Provenance_Stage'Pos (Row.Provenance_Stage) + 1);
      H := Mix (H, Final_Remediation_Work_Status'Pos (Row.Status) + 1);
      H := Mix (H, Final_Remediation_Work_Action'Pos (Row.Action) + 1);
      H := Mix (H, Final_Remediation_Work_Phase'Pos (Row.Phase) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority);
      H := Mix (H, Row.Dependency_Depth);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Provenance_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Remed_Prov.Final_Remediation_Provenance_Info;
      Index  : Positive) return Final_Remediation_Work_Row is
      Status : Final_Remediation_Work_Status;
      Action : Final_Remediation_Work_Action;
      Phase  : Final_Remediation_Work_Phase;
      Result : Final_Remediation_Work_Row;
   begin
      Classify (Source, Status, Action, Phase);
      Result.Id := Final_Remediation_Work_Id (Index);
      Result.Provenance_Id := Source.Id;
      Result.Provenance_Status := Source.Status;
      Result.Provenance_Stage := Source.Stage;
      Result.Status := Status;
      Result.Action := Action;
      Result.Phase := Phase;
      Result.Blocker_Family := Source.Blocker_Family;
      Result.Node := Source.Node;
      Result.Priority := Priority_For (Status, Source.Blocker_Family);
      Result.Dependency_Depth := Depth_For (Phase);
      Result.Start_Line := Source.Start_Line;
      Result.Start_Column := Source.Start_Column;
      Result.End_Line := Source.End_Line;
      Result.End_Column := Source.End_Column;
      Result.Source_Fingerprint := Source.Source_Fingerprint;
      Result.Provenance_Fingerprint := Source.Fingerprint;
      Result.Message := Message_For (Status, Action, Source.Blocker_Family);
      Result.Work_Fingerprint := Row_Fingerprint (Result);
      return Result;
   end Make_Row;

   procedure Add_Row
     (Model : in out Final_Remediation_Worklist_Model;
      Row   : Final_Remediation_Work_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Work_Fingerprint);
      case Row.Status is
         when Final_Work_Stale_Reanalysis_Required => Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Work_AST_Repair_Required => Model.AST_Total := Model.AST_Total + 1;
         when Final_Work_Cross_Unit_Closure_Required | Final_Work_View_Barrier_Repair_Required =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Final_Work_Generic_Replay_Required => Model.Generic_Total := Model.Generic_Total + 1;
         when Final_Work_Overload_Type_Required => Model.Overload_Total := Model.Overload_Total + 1;
         when Final_Work_Representation_Freezing_Required => Model.Representation_Total := Model.Representation_Total + 1;
         when Final_Work_Flow_Contract_Proof_Required => Model.Flow_Total := Model.Flow_Total + 1;
         when Final_Work_Tasking_Protected_Effects_Required => Model.Tasking_Total := Model.Tasking_Total + 1;
         when Final_Work_Elaboration_Closure_Required => Model.Elaboration_Total := Model.Elaboration_Total + 1;
         when Final_Work_Accessibility_Lifetime_Required => Model.Accessibility_Total := Model.Accessibility_Total + 1;
         when Final_Work_Discriminant_Variant_Required => Model.Discriminant_Total := Model.Discriminant_Total + 1;
         when Final_Work_Preserved_Semantic_Error => Model.Preserved_Error_Total := Model.Preserved_Error_Total + 1;
         when Final_Work_Multiple_Blockers_To_Split => Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
         when Final_Work_Indeterminate_Degraded => Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others => null;
      end case;
   end Add_Row;

   procedure Clear (Model : in out Final_Remediation_Worklist_Model) is
   begin
      Model.Rows.Clear;
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
      Model.Preserved_Error_Total := 0;
      Model.Multiple_Blocker_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Provenance : Remed_Prov.Final_Remediation_Provenance_Model)
      return Final_Remediation_Worklist_Model is
      Result : Final_Remediation_Worklist_Model;
   begin
      for I in 1 .. Remed_Prov.Row_Count (Provenance) loop
         Add_Row (Result, Make_Row (Remed_Prov.Row_At (Provenance, I), I));
      end loop;
      return Result;
   end Build;

   function Row_Count (Model : Final_Remediation_Worklist_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Remediation_Worklist_Model;
      Index : Positive) return Final_Remediation_Work_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Final_Remediation_Worklist_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Final_Remediation_Worklist_Set;
      Index : Positive) return Final_Remediation_Work_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Final_Remediation_Worklist_Set;
      Row : Final_Remediation_Work_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Work_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Final_Remediation_Worklist_Model;
      Status : Final_Remediation_Work_Status) return Final_Remediation_Worklist_Set is
      Result : Final_Remediation_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Action
     (Model  : Final_Remediation_Worklist_Model;
      Action : Final_Remediation_Work_Action) return Final_Remediation_Worklist_Set is
      Result : Final_Remediation_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Action;

   function Query_Phase
     (Model : Final_Remediation_Worklist_Model;
      Phase : Final_Remediation_Work_Phase) return Final_Remediation_Worklist_Set is
      Result : Final_Remediation_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Phase = Phase then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Phase;

   function Query_Blocker
     (Model   : Final_Remediation_Worklist_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Worklist_Set is
      Result : Final_Remediation_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Remediation_Worklist_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Worklist_Set is
      Result : Final_Remediation_Worklist_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Count_Status
     (Model  : Final_Remediation_Worklist_Model;
      Status : Final_Remediation_Work_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : Final_Remediation_Worklist_Model;
      Action : Final_Remediation_Work_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Phase
     (Model : Final_Remediation_Worklist_Model;
      Phase : Final_Remediation_Work_Phase) return Natural is
   begin
      return Query_Count (Query_Phase (Model, Phase));
   end Count_Phase;

   function Count_Blocker
     (Model   : Final_Remediation_Worklist_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Stale_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Stale_Total; end Stale_Work_Count;
   function AST_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.AST_Total; end AST_Work_Count;
   function Cross_Unit_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Cross_Unit_Total; end Cross_Unit_Work_Count;
   function Generic_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Generic_Total; end Generic_Work_Count;
   function Overload_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Overload_Total; end Overload_Work_Count;
   function Representation_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Representation_Total; end Representation_Work_Count;
   function Flow_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Flow_Total; end Flow_Work_Count;
   function Tasking_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Tasking_Total; end Tasking_Work_Count;
   function Elaboration_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Elaboration_Total; end Elaboration_Work_Count;
   function Accessibility_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Accessibility_Total; end Accessibility_Work_Count;
   function Discriminant_Work_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Discriminant_Total; end Discriminant_Work_Count;
   function Preserved_Error_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Preserved_Error_Total; end Preserved_Error_Count;
   function Multiple_Blocker_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Multiple_Blocker_Total; end Multiple_Blocker_Count;
   function Indeterminate_Count (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Indeterminate_Total; end Indeterminate_Count;
   function Fingerprint (Model : Final_Remediation_Worklist_Model) return Natural is begin return Model.Fingerprint; end Fingerprint;

end Editor.Ada_Final_Semantic_Remediation_Worklist_Legality;
