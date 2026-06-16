with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance is

   pragma Suppress (Overflow_Check);
   use type Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status;
   use type Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Severity;
   use type Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family;
   use type Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Id;
   use type Closure.Gate.Remaining_RM_Edge_Stabilization_Gate_Id;
   use type Closure.Gate.Conv.Remaining_RM_Edge_Convergence_Id;
   use type Closure.Gate.Conv.Apply.Remaining_RM_Edge_Application_Id;
   use type Closure.Gate.Conv.Apply.Recheck.Remaining_RM_Edge_Recheck_Id;
   use type Closure.Gate.Conv.Apply.Recheck.Worklist.Remaining_RM_Edge_Worklist_Id;
   use type Closure.Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return (A * 131 + B + 17) mod 2_147_483_647;
   end Mix;

   function Status_For
     (Source : Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Status is
   begin
      if Source.Withheld_Current then
         return Remaining_RM_Edge_Stabilized_Closure_Provenance_Withheld_Current_Evidence;
      elsif Source.Requires_Recheck then
         return Remaining_RM_Edge_Stabilized_Closure_Provenance_Recheck_Required;
      end if;

      case Source.Status is
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Not_Checked =>
            return Remaining_RM_Edge_Stabilized_Closure_Provenance_Not_Checked;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Multiple_Prerequisites =>
            return Remaining_RM_Edge_Stabilized_Closure_Provenance_Multiple_Prerequisites;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate =>
            return Remaining_RM_Edge_Stabilized_Closure_Provenance_Indeterminate;
         when others =>
            if Source.Severity = Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Error then
               return Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Error;
            else
               return Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Warning;
            end if;
      end case;
   end Status_For;

   function Blocker_For
     (Source : Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker is
   begin
      case Source.Family is
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Accepted =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_None;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Remaining_Edge =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_Remaining_Edge;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Stabilized_Closure =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_Stabilized_Closure;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Source_Fingerprint =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_Source_Fingerprint;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Substitution_Fingerprint =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_Substitution_Fingerprint;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Multiple =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_Multiple;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Recheck_Required =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_Recheck_Required;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Indeterminate =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_Indeterminate;
         when Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Unknown =>
            return Remaining_RM_Edge_Stabilized_Closure_Blocker_Unknown;
      end case;
   end Blocker_For;

   function Has_Full_Chain
     (Source : Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row) return Boolean is
   begin
      return Source.Closure_Row /= Closure.No_Remaining_RM_Edge_Stabilized_Closure
        and then Source.Stabilization_Id /= Closure.Gate.No_Remaining_RM_Edge_Stabilization_Gate
        and then Source.Convergence_Id /= Closure.Gate.Conv.No_Remaining_RM_Edge_Convergence
        and then Source.Application_Id /= Closure.Gate.Conv.Apply.No_Remaining_RM_Edge_Application
        and then Source.Eligibility_Id /= Closure.Gate.Conv.Apply.Recheck.No_Remaining_RM_Edge_Recheck
        and then Source.Worklist_Item /= Closure.Gate.Conv.Apply.Recheck.Worklist.No_Remaining_RM_Edge_Worklist_Item
        and then Source.Prior_Diagnostic_Row /= Closure.Diagnostics.No_Remaining_RM_Edge_Stabilized_Diagnostic;
   end Has_Full_Chain;

   function Make_Row
     (Source : Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Row;
      Index  : Positive) return Remaining_RM_Edge_Stabilized_Closure_Provenance_Row is
      Row  : Remaining_RM_Edge_Stabilized_Closure_Provenance_Row;
      Text : constant String := To_String (Source.Message);
   begin
      Row.Id := Remaining_RM_Edge_Stabilized_Closure_Provenance_Id (Index);
      Row.Stabilized_Diagnostic := Source.Id;
      Row.Closure_Row := Source.Closure_Row;
      Row.Stabilization_Id := Source.Stabilization_Id;
      Row.Convergence_Id := Source.Convergence_Id;
      Row.Application_Id := Source.Application_Id;
      Row.Eligibility_Id := Source.Eligibility_Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Prior_Diagnostic_Row := Source.Prior_Diagnostic_Row;
      Row.Closure_Status := Source.Closure_Status;
      Row.Diagnostic_Status := Source.Status;
      Row.Diagnostic_Family := Source.Family;
      Row.Diagnostic_Severity := Source.Severity;
      Row.Closure_Family := Source.Closure_Family;
      Row.Status := Status_For (Source);
      Row.Stage := Remaining_RM_Edge_Stabilized_Closure_Stage_Stabilized_Closure_Diagnostic;
      Row.Blocker := Blocker_For (Source);
      Row.Remaining_Edge_Kind := Source.Remaining_Edge_Kind;
      Row.Remaining_Edge_Blocker := Source.Remaining_Edge_Blocker;
      Row.Node := Source.Node;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Edge_Fingerprint := Source.Edge_Fingerprint;
      Row.Consumer_Closure_Fingerprint := Source.Consumer_Closure_Fingerprint;
      Row.Prior_Diagnostic_Fingerprint := Source.Prior_Diagnostic_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Application_Fingerprint := Source.Application_Fingerprint;
      Row.Convergence_Fingerprint := Source.Convergence_Fingerprint;
      Row.Stabilization_Fingerprint := Source.Stabilization_Fingerprint;
      Row.Closure_Fingerprint := Source.Closure_Fingerprint;
      Row.Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
      Row.Emitted := Source.Emitted;
      Row.Withheld_Current := Source.Withheld_Current;
      Row.Requires_Recheck := Source.Requires_Recheck;
      Row.Blocks_Downstream := Source.Blocks_Downstream;
      Row.Full_Chain_Linked := Has_Full_Chain (Source);
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Message := Source.Message;
      Row.Chain_Summary := To_Unbounded_String
        ("Pass1293 provenance chain: stabilized remaining-edge closure diagnostic -> stabilized closure -> stabilization gate -> convergence -> recheck application -> eligibility -> remediation worklist -> prior remaining-edge diagnostic -> original remaining-edge precision evidence.");

      Row.Provenance_Fingerprint := Mix (12_930, Natural (Row.Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Stabilized_Diagnostic));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Closure_Row));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Stabilization_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Convergence_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Application_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Eligibility_Id));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Worklist_Item));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Natural (Row.Prior_Diagnostic_Row));
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Remaining_RM_Edge_Stabilized_Closure_Provenance_Status'Pos (Row.Status) + 1);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker'Pos (Row.Blocker) + 1);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Edge.Remaining_RM_Edge_Kind'Pos (Row.Remaining_Edge_Kind) + 1);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Row.Source_Fingerprint);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Row.Substitution_Fingerprint);
      Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Row.Closure_Fingerprint);
      for C of Text loop
         Row.Provenance_Fingerprint := Mix (Row.Provenance_Fingerprint, Character'Pos (C));
      end loop;
      return Row;
   end Make_Row;

   procedure Note
     (Model : in out Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Row   : Remaining_RM_Edge_Stabilized_Closure_Provenance_Row) is
   begin
      if Row.Withheld_Current then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;
      if Row.Emitted then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      end if;
      case Row.Status is
         when Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Remaining_RM_Edge_Stabilized_Closure_Provenance_Recheck_Required =>
            Model.Recheck_Total := Model.Recheck_Total + 1;
         when Remaining_RM_Edge_Stabilized_Closure_Provenance_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when Remaining_RM_Edge_Stabilized_Closure_Provenance_Multiple_Prerequisites =>
            Model.Multiple_Total := Model.Multiple_Total + 1;
         when others =>
            null;
      end case;
      if Row.Full_Chain_Linked then
         Model.Full_Chain_Total := Model.Full_Chain_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Provenance_Fingerprint);
   end Note;

   procedure Append
     (Set : in out Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
      Row : Remaining_RM_Edge_Stabilized_Closure_Provenance_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Provenance_Fingerprint);
   end Append;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) is
   begin
      Model.Rows.Clear;
      Model.Withheld_Total := 0;
      Model.Emitted_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Recheck_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Multiple_Total := 0;
      Model.Full_Chain_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Diagnostic_Model : Diagnostics.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Model)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Model is
      Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Row   : Remaining_RM_Edge_Stabilized_Closure_Provenance_Row;
   begin
      for I in 1 .. Diagnostics.Row_Count (Diagnostic_Model) loop
         Row := Make_Row (Diagnostics.Row_At (Diagnostic_Model, I), I);
         Model.Rows.Append (Row);
         Note (Model, Row);
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Provenance_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Provenance_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker = Blocker then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Blocker;

   function Query_Stage
     (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Stage : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Stage = Stage then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Stage;

   function Query_Node
     (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Provenance_Set is
      Set : Remaining_RM_Edge_Stabilized_Closure_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Count_Stage
     (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model;
      Stage : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage) return Natural is
   begin
      return Query_Count (Query_Stage (Model, Stage));
   end Count_Stage;

   function Withheld_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Emitted_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Error_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Multiple_Prerequisite_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Multiple_Total;
   end Multiple_Prerequisite_Count;

   function Full_Chain_Link_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Full_Chain_Total;
   end Full_Chain_Link_Count;

   function Fingerprint (Model : Remaining_RM_Edge_Stabilized_Closure_Provenance_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance;
