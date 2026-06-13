with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 12_880) mod 2_147_483_647;
   end Mix;

   procedure Classify
     (Source : Recheck.Remaining_RM_Edge_Recheck_Row;
      Status : out Remaining_RM_Edge_Application_Status;
      Action : out Remaining_RM_Edge_Application_Action) is
   begin
      case Source.Status is
         when Recheck.Remaining_RM_Edge_Recheck_Not_Checked =>
            Status := Remaining_RM_Edge_Application_Not_Checked;
            Action := Remaining_RM_Edge_Application_Action_None;
         when Recheck.Remaining_RM_Edge_Recheck_Not_Required_Current =>
            Status := Remaining_RM_Edge_Application_Current_Non_Diagnostic_Evidence;
            Action := Remaining_RM_Edge_Application_Action_Keep_Non_Diagnostic_Evidence;
         when Recheck.Remaining_RM_Edge_Recheck_Eligible_Now =>
            Status := Remaining_RM_Edge_Application_Current_Accepted;
            Action := Remaining_RM_Edge_Application_Action_Expose_Current;
         when Recheck.Remaining_RM_Edge_Recheck_Blocked_By_Remaining_Edge =>
            Status := Remaining_RM_Edge_Application_Withheld_Remaining_Edge;
            Action := Remaining_RM_Edge_Application_Action_Withhold_For_Remaining_Edge;
         when Recheck.Remaining_RM_Edge_Recheck_Blocked_By_Stabilized_Closure =>
            Status := Remaining_RM_Edge_Application_Withheld_Stabilized_Closure;
            Action := Remaining_RM_Edge_Application_Action_Withhold_For_Stabilized_Closure;
         when Recheck.Remaining_RM_Edge_Recheck_Blocked_By_Source_Fingerprint =>
            Status := Remaining_RM_Edge_Application_Withheld_Source_Fingerprint;
            Action := Remaining_RM_Edge_Application_Action_Withhold_For_Source_Fingerprint;
         when Recheck.Remaining_RM_Edge_Recheck_Blocked_By_Substitution_Fingerprint =>
            Status := Remaining_RM_Edge_Application_Withheld_Substitution_Fingerprint;
            Action := Remaining_RM_Edge_Application_Action_Withhold_For_Substitution_Fingerprint;
         when Recheck.Remaining_RM_Edge_Recheck_Multiple_Prerequisites =>
            Status := Remaining_RM_Edge_Application_Withheld_Multiple_Prerequisites;
            Action := Remaining_RM_Edge_Application_Action_Split_Prerequisites;
         when Recheck.Remaining_RM_Edge_Recheck_Recheck_Required =>
            Status := Remaining_RM_Edge_Application_Withheld_Recheck_Required;
            Action := Remaining_RM_Edge_Application_Action_Wait_For_Recheck_Gate;
         when Recheck.Remaining_RM_Edge_Recheck_Indeterminate =>
            Status := Remaining_RM_Edge_Application_Indeterminate;
            Action := Remaining_RM_Edge_Application_Action_Degrade;
      end case;
   end Classify;

   function Is_Current_Status (Status : Remaining_RM_Edge_Application_Status) return Boolean is
   begin
      return Status in Remaining_RM_Edge_Application_Current_Accepted |
                       Remaining_RM_Edge_Application_Current_Non_Diagnostic_Evidence;
   end Is_Current_Status;

   function Is_Accepted_Status (Status : Remaining_RM_Edge_Application_Status) return Boolean is
   begin
      return Status = Remaining_RM_Edge_Application_Current_Accepted;
   end Is_Accepted_Status;

   function Is_Withheld_Status (Status : Remaining_RM_Edge_Application_Status) return Boolean is
   begin
      return Status in Remaining_RM_Edge_Application_Withheld_Remaining_Edge |
                       Remaining_RM_Edge_Application_Withheld_Stabilized_Closure |
                       Remaining_RM_Edge_Application_Withheld_Source_Fingerprint |
                       Remaining_RM_Edge_Application_Withheld_Substitution_Fingerprint |
                       Remaining_RM_Edge_Application_Withheld_Multiple_Prerequisites |
                       Remaining_RM_Edge_Application_Withheld_Recheck_Required |
                       Remaining_RM_Edge_Application_Indeterminate;
   end Is_Withheld_Status;

   function Message_For
     (Status : Remaining_RM_Edge_Application_Status;
      Action : Remaining_RM_Edge_Application_Action;
      Family : Remaining_RM_Edge_Application_Diagnostic_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("remaining RM edge recheck application " &
         Remaining_RM_Edge_Application_Status'Image (Status) &
         " action=" & Remaining_RM_Edge_Application_Action'Image (Action) &
         " family=" & Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Remaining_RM_Edge_Application_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_881;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Recheck.Remaining_RM_Edge_Recheck_Status'Pos (Row.Eligibility_Status) + 1);
      H := Mix (H, Recheck.Remaining_RM_Edge_Recheck_Action'Pos (Row.Eligibility_Action) + 1);
      H := Mix (H, Remaining_RM_Edge_Application_Status'Pos (Row.Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Application_Action'Pos (Row.Action) + 1);
      H := Mix (H, Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family'Pos (Row.Diagnostic_Family) + 1);
      H := Mix (H, Edge.Remaining_RM_Edge_Kind'Pos (Row.Remaining_Edge_Kind) + 1);
      H := Mix (H, Edge.Remaining_RM_Edge_Blocker_Family'Pos (Row.Remaining_Edge_Blocker) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Edge_Fingerprint);
      H := Mix (H, Row.Closure_Fingerprint);
      H := Mix (H, Row.Diagnostic_Fingerprint);
      H := Mix (H, Row.Worklist_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Recheck.Remaining_RM_Edge_Recheck_Row;
      Index  : Positive) return Remaining_RM_Edge_Application_Row is
      Status : Remaining_RM_Edge_Application_Status;
      Action : Remaining_RM_Edge_Application_Action;
      Row    : Remaining_RM_Edge_Application_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := Remaining_RM_Edge_Application_Id (Index);
      Row.Eligibility_Id := Source.Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Diagnostic_Row := Source.Diagnostic_Row;
      Row.Diagnostic_Status := Source.Diagnostic_Status;
      Row.Diagnostic_Family := Source.Diagnostic_Family;
      Row.Remaining_Edge_Kind := Source.Remaining_Edge_Kind;
      Row.Remaining_Edge_Blocker := Source.Remaining_Edge_Blocker;
      Row.Eligibility_Status := Source.Status;
      Row.Eligibility_Action := Source.Action;
      Row.Status := Status;
      Row.Action := Action;
      Row.Node := Source.Node;
      Row.Current := Is_Current_Status (Status);
      Row.Accepted := Is_Accepted_Status (Status);
      Row.Withheld := Is_Withheld_Status (Status);
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Edge_Fingerprint := Source.Edge_Fingerprint;
      Row.Closure_Fingerprint := Source.Closure_Fingerprint;
      Row.Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Message := Message_For (Status, Action, Source.Diagnostic_Family);
      Row.Application_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Remaining_RM_Edge_Application_Model;
      Row   : Remaining_RM_Edge_Application_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Stable_Fingerprint_Value := Mix (Model.Stable_Fingerprint_Value, Row.Application_Fingerprint);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Withheld then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;
      if Row.Current then
         Model.Current_Total := Model.Current_Total + 1;
      end if;
      case Row.Status is
         when Remaining_RM_Edge_Application_Withheld_Remaining_Edge =>
            Model.Remaining_Edge_Withheld_Total := Model.Remaining_Edge_Withheld_Total + 1;
         when Remaining_RM_Edge_Application_Withheld_Stabilized_Closure =>
            Model.Closure_Withheld_Total := Model.Closure_Withheld_Total + 1;
         when Remaining_RM_Edge_Application_Withheld_Source_Fingerprint |
              Remaining_RM_Edge_Application_Withheld_Substitution_Fingerprint =>
            Model.Fingerprint_Withheld_Total := Model.Fingerprint_Withheld_Total + 1;
         when Remaining_RM_Edge_Application_Withheld_Recheck_Required =>
            Model.Recheck_Required_Total := Model.Recheck_Required_Total + 1;
         when Remaining_RM_Edge_Application_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when others =>
            null;
      end case;
   end Add_Row;

   procedure Clear (Model : in out Remaining_RM_Edge_Application_Model) is
   begin
      Model.Rows.Clear;
      Model.Accepted_Total := 0;
      Model.Withheld_Total := 0;
      Model.Current_Total := 0;
      Model.Remaining_Edge_Withheld_Total := 0;
      Model.Closure_Withheld_Total := 0;
      Model.Fingerprint_Withheld_Total := 0;
      Model.Recheck_Required_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Stable_Fingerprint_Value := 0;
   end Clear;

   function Build
     (Eligibility : Recheck.Remaining_RM_Edge_Recheck_Model)
      return Remaining_RM_Edge_Application_Model is
      Model : Remaining_RM_Edge_Application_Model;
   begin
      for Index in 1 .. Recheck.Row_Count (Eligibility) loop
         Add_Row (Model, Make_Row (Recheck.Row_At (Eligibility, Index), Index));
      end loop;
      return Model;
   end Build;

   function Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Remaining_RM_Edge_Application_Model;
      Index : Positive) return Remaining_RM_Edge_Application_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Application_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Application_Set;
      Index : Positive) return Remaining_RM_Edge_Application_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append
     (Set : in out Remaining_RM_Edge_Application_Set;
      Row : Remaining_RM_Edge_Application_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Application_Fingerprint);
   end Append;

   function Query_Status
     (Model  : Remaining_RM_Edge_Application_Model;
      Status : Remaining_RM_Edge_Application_Status) return Remaining_RM_Edge_Application_Set is
      Set : Remaining_RM_Edge_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Remaining_RM_Edge_Application_Model;
      Action : Remaining_RM_Edge_Application_Action) return Remaining_RM_Edge_Application_Set is
      Set : Remaining_RM_Edge_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Remaining_RM_Edge_Application_Model;
      Family : Remaining_RM_Edge_Application_Diagnostic_Family) return Remaining_RM_Edge_Application_Set is
      Set : Remaining_RM_Edge_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Diagnostic_Family = Family then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Node
     (Model : Remaining_RM_Edge_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Application_Set is
      Set : Remaining_RM_Edge_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Application_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Application_Set is
      Set : Remaining_RM_Edge_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Query_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Application_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Application_Set is
      Set : Remaining_RM_Edge_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Substitution_Fingerprint;

   function Count_Status
     (Model  : Remaining_RM_Edge_Application_Model;
      Status : Remaining_RM_Edge_Application_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : Remaining_RM_Edge_Application_Model;
      Action : Remaining_RM_Edge_Application_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : Remaining_RM_Edge_Application_Model;
      Family : Remaining_RM_Edge_Application_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Accepted_Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Withheld_Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Current_Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Remaining_Edge_Withheld_Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Remaining_Edge_Withheld_Total;
   end Remaining_Edge_Withheld_Count;

   function Stabilized_Closure_Withheld_Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Closure_Withheld_Total;
   end Stabilized_Closure_Withheld_Count;

   function Fingerprint_Withheld_Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Fingerprint_Withheld_Total;
   end Fingerprint_Withheld_Count;

   function Recheck_Required_Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Recheck_Required_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Remaining_RM_Edge_Application_Model) return Natural is
   begin
      return Model.Stable_Fingerprint_Value;
   end Stable_Fingerprint;

   function Is_Current (Row : Remaining_RM_Edge_Application_Row) return Boolean is
   begin
      return Row.Current;
   end Is_Current;

   function Is_Accepted (Row : Remaining_RM_Edge_Application_Row) return Boolean is
   begin
      return Row.Accepted;
   end Is_Accepted;

   function Is_Withheld (Row : Remaining_RM_Edge_Application_Row) return Boolean is
   begin
      return Row.Withheld;
   end Is_Withheld;

   function Blocks_Downstream (Row : Remaining_RM_Edge_Application_Row) return Boolean is
   begin
      return Row.Blocks_Downstream;
   end Blocks_Downstream;

end Editor.Ada_Remaining_RM_Edge_Recheck_Application_Legality;
