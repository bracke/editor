with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality is

   pragma Suppress (Overflow_Check);
   use type Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 1) mod 1_000_000_007;
   end Mix;

   function Is_Accepted (Status : Remaining_RM_Edge_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in Remaining_RM_Edge_Stabilized_Closure_Accepted_Current |
                       Remaining_RM_Edge_Stabilized_Closure_Accepted_Not_Required;
   end Is_Accepted;

   function Is_Blocked (Status : Remaining_RM_Edge_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in Remaining_RM_Edge_Stabilized_Closure_Blocker_Remaining_Edge |
                       Remaining_RM_Edge_Stabilized_Closure_Blocker_Stabilized_Closure |
                       Remaining_RM_Edge_Stabilized_Closure_Blocker_Source_Fingerprint |
                       Remaining_RM_Edge_Stabilized_Closure_Blocker_Substitution_Fingerprint |
                       Remaining_RM_Edge_Stabilized_Closure_Blocker_Multiple_Prerequisites;
   end Is_Blocked;

   procedure Classify
     (Source : Gate.Remaining_RM_Edge_Stabilization_Gate_Row;
      Status : out Remaining_RM_Edge_Stabilized_Closure_Status;
      Action : out Remaining_RM_Edge_Stabilized_Closure_Action) is
   begin
      case Source.Status is
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Promoted_Current =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Accepted_Current;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Accept_Current;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Promoted_Not_Required =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Accepted_Not_Required;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Accept_Not_Required;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Withheld_Remaining_Edge =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Blocker_Remaining_Edge;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Block_Remaining_Edge;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Withheld_Stabilized_Closure =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Blocker_Stabilized_Closure;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Block_Stabilized_Closure;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Withheld_Source_Fingerprint =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Blocker_Source_Fingerprint;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Block_Source_Fingerprint;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Withheld_Substitution_Fingerprint =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Blocker_Substitution_Fingerprint;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Block_Substitution_Fingerprint;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Withheld_Multiple_Prerequisites =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Blocker_Multiple_Prerequisites;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Split_Prerequisites;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Withheld_Recheck_Required =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Recheck_Required;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Recheck;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Degraded_Indeterminate =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Indeterminate;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Degrade;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Recheck_Required =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Recheck_Required;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_Recheck;
         when Gate.Remaining_RM_Edge_Stabilization_Gate_Not_Checked =>
            Status := Remaining_RM_Edge_Stabilized_Closure_Not_Checked;
            Action := Remaining_RM_Edge_Stabilized_Closure_Action_None;
      end case;
   end Classify;

   function Message_For
     (Status : Remaining_RM_Edge_Stabilized_Closure_Status;
      Action : Remaining_RM_Edge_Stabilized_Closure_Action;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("remaining RM edge stabilized closure " &
         Remaining_RM_Edge_Stabilized_Closure_Status'Image (Status) &
         " action=" & Remaining_RM_Edge_Stabilized_Closure_Action'Image (Action) &
         " family=" & Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint
     (Row : Remaining_RM_Edge_Stabilized_Closure_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_910;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Stabilization_Id));
      H := Mix (H, Natural (Row.Convergence_Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Natural (Row.Worklist_Item));
      H := Mix (H, Natural (Row.Diagnostic_Row));
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Stabilization_Status'Pos (Row.Stabilization_Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Stabilization_Action'Pos (Row.Stabilization_Action) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Status'Pos (Row.Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Action'Pos (Row.Action) + 1);
      H := Mix (H, Diagnostics.Remaining_RM_Edge_Stabilized_Diagnostic_Family'Pos (Row.Family) + 1);
      H := Mix (H, Edge.Remaining_RM_Edge_Kind'Pos (Row.Remaining_Edge_Kind) + 1);
      H := Mix (H, Edge.Remaining_RM_Edge_Blocker_Family'Pos (Row.Remaining_Edge_Blocker) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Edge_Fingerprint);
      H := Mix (H, Row.Consumer_Closure_Fingerprint);
      H := Mix (H, Row.Diagnostic_Fingerprint);
      H := Mix (H, Row.Worklist_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      H := Mix (H, Row.Application_Fingerprint);
      H := Mix (H, Row.Convergence_Fingerprint);
      H := Mix (H, Row.Stabilization_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Gate.Remaining_RM_Edge_Stabilization_Gate_Row;
      Index  : Positive) return Remaining_RM_Edge_Stabilized_Closure_Row is
      Status : Remaining_RM_Edge_Stabilized_Closure_Status;
      Action : Remaining_RM_Edge_Stabilized_Closure_Action;
      Row    : Remaining_RM_Edge_Stabilized_Closure_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := Remaining_RM_Edge_Stabilized_Closure_Id (Index);
      Row.Stabilization_Id := Source.Id;
      Row.Convergence_Id := Source.Convergence_Id;
      Row.Application_Id := Source.Application_Id;
      Row.Eligibility_Id := Source.Eligibility_Id;
      Row.Worklist_Item := Source.Worklist_Item;
      Row.Diagnostic_Row := Source.Diagnostic_Row;
      Row.Stabilization_Status := Source.Status;
      Row.Stabilization_Action := Source.Action;
      Row.Status := Status;
      Row.Action := Action;
      Row.Family := Source.Family;
      Row.Remaining_Edge_Kind := Source.Remaining_Edge_Kind;
      Row.Remaining_Edge_Blocker := Source.Remaining_Edge_Blocker;
      Row.Node := Source.Node;
      Row.Accepted := Is_Accepted (Status);
      Row.Current := Status = Remaining_RM_Edge_Stabilized_Closure_Accepted_Current;
      Row.Blocked := Is_Blocked (Status);
      Row.Stable := Source.Stable and then Status /= Remaining_RM_Edge_Stabilized_Closure_Recheck_Required;
      Row.Recheck_Required := Status = Remaining_RM_Edge_Stabilized_Closure_Recheck_Required;
      Row.Blocks_Downstream := Row.Blocked or else Row.Recheck_Required or else
        Status = Remaining_RM_Edge_Stabilized_Closure_Indeterminate or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Substitution_Fingerprint := Source.Substitution_Fingerprint;
      Row.Edge_Fingerprint := Source.Edge_Fingerprint;
      Row.Consumer_Closure_Fingerprint := Source.Closure_Fingerprint;
      Row.Diagnostic_Fingerprint := Source.Diagnostic_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Application_Fingerprint := Source.Application_Fingerprint;
      Row.Convergence_Fingerprint := Source.Convergence_Fingerprint;
      Row.Stabilization_Fingerprint := Source.Stabilization_Fingerprint;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Message := Message_For (Status, Action, Source.Family);
      Row.Closure_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Remaining_RM_Edge_Stabilized_Closure_Model;
      Row   : Remaining_RM_Edge_Stabilized_Closure_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Closure_Fingerprint);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Blocked then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;
      if Row.Current then
         Model.Current_Total := Model.Current_Total + 1;
      end if;
      if Row.Recheck_Required then
         Model.Recheck_Total := Model.Recheck_Total + 1;
      end if;
      if Row.Status = Remaining_RM_Edge_Stabilized_Closure_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Closure_Model) is
   begin
      Model.Rows.Clear;
      Model.Accepted_Total := 0;
      Model.Blocked_Total := 0;
      Model.Current_Total := 0;
      Model.Recheck_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Gates : Gate.Remaining_RM_Edge_Stabilization_Gate_Model)
      return Remaining_RM_Edge_Stabilized_Closure_Model is
      Model : Remaining_RM_Edge_Stabilized_Closure_Model;
   begin
      for I in 1 .. Gate.Row_Count (Gates) loop
         Add_Row (Model, Make_Row (Gate.Row_At (Gates, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Closure_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Closure_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Closure_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Remaining_RM_Edge_Stabilized_Closure_Set;
      Row : Remaining_RM_Edge_Stabilized_Closure_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Closure_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Status) return Remaining_RM_Edge_Stabilized_Closure_Set is
      Result : Remaining_RM_Edge_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Action
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Action : Remaining_RM_Edge_Stabilized_Closure_Action) return Remaining_RM_Edge_Stabilized_Closure_Set is
      Result : Remaining_RM_Edge_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Action;

   function Query_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family) return Remaining_RM_Edge_Stabilized_Closure_Set is
      Result : Remaining_RM_Edge_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Family;

   function Find_By_Node
     (Model : Remaining_RM_Edge_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Stabilized_Closure_Set is
      Result : Remaining_RM_Edge_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Set is
      Result : Remaining_RM_Edge_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Find_By_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Set is
      Result : Remaining_RM_Edge_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Substitution_Fingerprint = Fingerprint then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Substitution_Fingerprint;

   function Count_By_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family) return Natural is
   begin
      return Query_Count (Query_Family (Model, Family));
   end Count_By_Family;

   function Accepted_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Current_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Remaining_RM_Edge_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Legality;
