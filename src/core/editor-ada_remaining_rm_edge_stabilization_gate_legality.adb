with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 12_900) mod 2_147_483_647;
   end Mix;

   function Is_Promoted (Status : Remaining_RM_Edge_Stabilization_Gate_Status) return Boolean is
   begin
      return Status in Remaining_RM_Edge_Stabilization_Gate_Promoted_Current |
                       Remaining_RM_Edge_Stabilization_Gate_Promoted_Not_Required;
   end Is_Promoted;

   function Is_Withheld (Status : Remaining_RM_Edge_Stabilization_Gate_Status) return Boolean is
   begin
      return Status in Remaining_RM_Edge_Stabilization_Gate_Withheld_Remaining_Edge |
                       Remaining_RM_Edge_Stabilization_Gate_Withheld_Stabilized_Closure |
                       Remaining_RM_Edge_Stabilization_Gate_Withheld_Source_Fingerprint |
                       Remaining_RM_Edge_Stabilization_Gate_Withheld_Substitution_Fingerprint |
                       Remaining_RM_Edge_Stabilization_Gate_Withheld_Multiple_Prerequisites |
                       Remaining_RM_Edge_Stabilization_Gate_Withheld_Recheck_Required |
                       Remaining_RM_Edge_Stabilization_Gate_Degraded_Indeterminate;
   end Is_Withheld;

   procedure Classify
     (Source : Conv.Remaining_RM_Edge_Convergence_Row;
      Status : out Remaining_RM_Edge_Stabilization_Gate_Status;
      Action : out Remaining_RM_Edge_Stabilization_Gate_Action) is
   begin
      case Source.Status is
         when Conv.Remaining_RM_Edge_Convergence_Not_Checked =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Degraded_Indeterminate;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Degrade;
         when Conv.Remaining_RM_Edge_Converged_Current =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Promoted_Current;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Promote_Current;
         when Conv.Remaining_RM_Edge_Converged_Not_Required =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Promoted_Not_Required;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Promote_Not_Required;
         when Conv.Remaining_RM_Edge_Stable_Withheld_Remaining_Edge =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Withheld_Remaining_Edge;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Retain_Remaining_Edge_Blocker;
         when Conv.Remaining_RM_Edge_Stable_Withheld_Stabilized_Closure =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Withheld_Stabilized_Closure;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Retain_Stabilized_Closure_Blocker;
         when Conv.Remaining_RM_Edge_Stable_Withheld_Source_Fingerprint =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Withheld_Source_Fingerprint;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Retain_Source_Fingerprint_Blocker;
         when Conv.Remaining_RM_Edge_Stable_Withheld_Substitution_Fingerprint =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Withheld_Substitution_Fingerprint;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Retain_Substitution_Fingerprint_Blocker;
         when Conv.Remaining_RM_Edge_Stable_Multiple_Prerequisites =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Withheld_Multiple_Prerequisites;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Split_Prerequisites;
         when Conv.Remaining_RM_Edge_Stable_Recheck_Required =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Withheld_Recheck_Required;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Wait_For_Recheck_Gate;
         when Conv.Remaining_RM_Edge_Stable_Indeterminate =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Degraded_Indeterminate;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Degrade;
         when Conv.Remaining_RM_Edge_Changed_Since_Previous =>
            Status := Remaining_RM_Edge_Stabilization_Gate_Recheck_Required;
            Action := Remaining_RM_Edge_Stabilization_Gate_Action_Recheck;
      end case;
   end Classify;

   function Message_For
     (Status : Remaining_RM_Edge_Stabilization_Gate_Status;
      Action : Remaining_RM_Edge_Stabilization_Gate_Action;
      Family : Remaining_RM_Edge_Stabilization_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("remaining RM edge stabilization gate " &
         Remaining_RM_Edge_Stabilization_Gate_Status'Image (Status) &
         " action=" & Remaining_RM_Edge_Stabilization_Gate_Action'Image (Action) &
         " family=" & Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint
     (Row : Remaining_RM_Edge_Stabilization_Gate_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_900;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Convergence_Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Conv.Remaining_RM_Edge_Convergence_Status'Pos (Row.Convergence_Status) + 1);
      H := Mix (H, Conv.Remaining_RM_Edge_Convergence_Action'Pos (Row.Convergence_Action) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilization_Gate_Status'Pos (Row.Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilization_Gate_Action'Pos (Row.Action) + 1);
      H := Mix (H, Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family'Pos (Row.Family) + 1);
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
      H := Mix (H, Row.Application_Fingerprint);
      H := Mix (H, Row.Convergence_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Conv.Remaining_RM_Edge_Convergence_Row;
      Index  : Positive) return Remaining_RM_Edge_Stabilization_Gate_Row is
      Status : Remaining_RM_Edge_Stabilization_Gate_Status;
      Action : Remaining_RM_Edge_Stabilization_Gate_Action;
      Row    : Remaining_RM_Edge_Stabilization_Gate_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := Remaining_RM_Edge_Stabilization_Gate_Id (Index);
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
      Row.Remaining_Edge_Kind := Source.Remaining_Edge_Kind;
      Row.Remaining_Edge_Blocker := Source.Remaining_Edge_Blocker;
      Row.Node := Source.Node;
      Row.Promoted := Is_Promoted (Status);
      Row.Current := Status = Remaining_RM_Edge_Stabilization_Gate_Promoted_Current;
      Row.Withheld := Is_Withheld (Status);
      Row.Stable := Status /= Remaining_RM_Edge_Stabilization_Gate_Recheck_Required;
      Row.Recheck_Required := Status = Remaining_RM_Edge_Stabilization_Gate_Recheck_Required;
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Edge_Fingerprint := Source.Edge_Fingerprint;
      Row.Closure_Fingerprint := Source.Closure_Fingerprint;
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
     (Model : in out Remaining_RM_Edge_Stabilization_Gate_Model;
      Row   : Remaining_RM_Edge_Stabilization_Gate_Row) is
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
      if Row.Status = Remaining_RM_Edge_Stabilization_Gate_Degraded_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilization_Gate_Model) is
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
     (Convergence : Conv.Remaining_RM_Edge_Convergence_Model)
      return Remaining_RM_Edge_Stabilization_Gate_Model is
      Model : Remaining_RM_Edge_Stabilization_Gate_Model;
   begin
      for I in 1 .. Conv.Row_Count (Convergence) loop
         Add_Row (Model, Make_Row (Conv.Row_At (Convergence, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Remaining_RM_Edge_Stabilization_Gate_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilization_Gate_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Stabilization_Gate_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Stabilization_Gate_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilization_Gate_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append
     (Set : in out Remaining_RM_Edge_Stabilization_Gate_Set;
      Row : Remaining_RM_Edge_Stabilization_Gate_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Stabilization_Fingerprint);
   end Append;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Status : Remaining_RM_Edge_Stabilization_Gate_Status) return Remaining_RM_Edge_Stabilization_Gate_Set is
      Set : Remaining_RM_Edge_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Action : Remaining_RM_Edge_Stabilization_Gate_Action) return Remaining_RM_Edge_Stabilization_Gate_Set is
      Set : Remaining_RM_Edge_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Family
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Family : Remaining_RM_Edge_Stabilization_Family) return Remaining_RM_Edge_Stabilization_Gate_Set is
      Set : Remaining_RM_Edge_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Family;

   function Query_Node
     (Model : Remaining_RM_Edge_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Stabilization_Gate_Set is
      Set : Remaining_RM_Edge_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilization_Gate_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilization_Gate_Set is
      Set : Remaining_RM_Edge_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Query_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilization_Gate_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilization_Gate_Set is
      Set : Remaining_RM_Edge_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Append (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Substitution_Fingerprint;

   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Status : Remaining_RM_Edge_Stabilization_Gate_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Action
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Action : Remaining_RM_Edge_Stabilization_Gate_Action) return Natural is
   begin
      return Query_Count (Query_Action (Model, Action));
   end Count_Action;

   function Count_Family
     (Model  : Remaining_RM_Edge_Stabilization_Gate_Model;
      Family : Remaining_RM_Edge_Stabilization_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_Family;

   function Promoted_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Promoted_Total;
   end Promoted_Count;

   function Withheld_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Current_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Remaining_RM_Edge_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Remaining_RM_Edge_Stabilization_Gate_Legality;
