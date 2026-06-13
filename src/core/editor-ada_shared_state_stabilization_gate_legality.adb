with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Shared_State_Stabilization_Gate_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_221) mod 2_147_483_647;
   end Mix;

   function Is_Promoted (Status : Shared_State_Stabilization_Gate_Status) return Boolean is
   begin
      return Status = Shared_State_Stabilization_Gate_Promoted_Current
        or else Status = Shared_State_Stabilization_Gate_Promoted_Not_Required;
   end Is_Promoted;

   function Is_Withheld (Status : Shared_State_Stabilization_Gate_Status) return Boolean is
   begin
      return Status in Shared_State_Stabilization_Gate_Withheld_Cross_Unit_Dependency |
                       Shared_State_Stabilization_Gate_Withheld_View_Barrier |
                       Shared_State_Stabilization_Gate_Withheld_Generic_Backmapping |
                       Shared_State_Stabilization_Gate_Withheld_State_Visibility |
                       Shared_State_Stabilization_Gate_Withheld_Abstract_State |
                       Shared_State_Stabilization_Gate_Withheld_Volatile_Atomic |
                       Shared_State_Stabilization_Gate_Withheld_Overload_Shared_State |
                       Shared_State_Stabilization_Gate_Withheld_Representation_Freezing |
                       Shared_State_Stabilization_Gate_Withheld_Tasking_Protected |
                       Shared_State_Stabilization_Gate_Withheld_Source_Fingerprint |
                       Shared_State_Stabilization_Gate_Withheld_Stale_Eligibility |
                       Shared_State_Stabilization_Gate_Withheld_Multiple_Prerequisites;
   end Is_Withheld;

   procedure Classify
     (Source : Conv.Shared_State_Recheck_Convergence_Row;
      Status : out Shared_State_Stabilization_Gate_Status;
      Action : out Shared_State_Stabilization_Gate_Action) is
   begin
      case Source.Status is
         when Conv.Shared_State_Recheck_Convergence_Not_Checked =>
            Status := Shared_State_Stabilization_Gate_Not_Checked;
            Action := Shared_State_Stabilization_Gate_Action_None;
         when Conv.Shared_State_Recheck_Converged_Current =>
            Status := Shared_State_Stabilization_Gate_Promoted_Current;
            Action := Shared_State_Stabilization_Gate_Action_Promote_Current;
         when Conv.Shared_State_Recheck_Converged_Not_Required =>
            Status := Shared_State_Stabilization_Gate_Promoted_Not_Required;
            Action := Shared_State_Stabilization_Gate_Action_Promote_Not_Required;
         when Conv.Shared_State_Recheck_Stable_Withheld_Cross_Unit_Dependency =>
            Status := Shared_State_Stabilization_Gate_Withheld_Cross_Unit_Dependency;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_View_Barrier =>
            Status := Shared_State_Stabilization_Gate_Withheld_View_Barrier;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_Generic_Backmapping =>
            Status := Shared_State_Stabilization_Gate_Withheld_Generic_Backmapping;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_State_Visibility =>
            Status := Shared_State_Stabilization_Gate_Withheld_State_Visibility;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_Abstract_State =>
            Status := Shared_State_Stabilization_Gate_Withheld_Abstract_State;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_Volatile_Atomic =>
            Status := Shared_State_Stabilization_Gate_Withheld_Volatile_Atomic;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_Overload_Shared_State =>
            Status := Shared_State_Stabilization_Gate_Withheld_Overload_Shared_State;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_Representation_Freezing =>
            Status := Shared_State_Stabilization_Gate_Withheld_Representation_Freezing;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_Tasking_Protected =>
            Status := Shared_State_Stabilization_Gate_Withheld_Tasking_Protected;
            Action := Shared_State_Stabilization_Gate_Action_Withhold_Prerequisite;
         when Conv.Shared_State_Recheck_Stable_Withheld_Source_Fingerprint =>
            Status := Shared_State_Stabilization_Gate_Withheld_Source_Fingerprint;
            Action := Shared_State_Stabilization_Gate_Action_Retain_Fingerprint_Blocker;
         when Conv.Shared_State_Recheck_Stable_Withheld_Stale_Eligibility =>
            Status := Shared_State_Stabilization_Gate_Withheld_Stale_Eligibility;
            Action := Shared_State_Stabilization_Gate_Action_Retain_Stale_Blocker;
         when Conv.Shared_State_Recheck_Stable_Multiple_Prerequisites =>
            Status := Shared_State_Stabilization_Gate_Withheld_Multiple_Prerequisites;
            Action := Shared_State_Stabilization_Gate_Action_Split_Prerequisites;
         when Conv.Shared_State_Recheck_Stable_Indeterminate =>
            Status := Shared_State_Stabilization_Gate_Degraded_Indeterminate;
            Action := Shared_State_Stabilization_Gate_Action_Degrade;
         when Conv.Shared_State_Recheck_Changed_Since_Previous =>
            Status := Shared_State_Stabilization_Gate_Recheck_Required;
            Action := Shared_State_Stabilization_Gate_Action_Recheck;
      end case;
   end Classify;

   function Message_For
     (Status : Shared_State_Stabilization_Gate_Status;
      Action : Shared_State_Stabilization_Gate_Action;
      Family : Shared_State_Recheck_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("shared-state stabilization gate " &
         Shared_State_Stabilization_Gate_Status'Image (Status) &
         " action=" & Shared_State_Stabilization_Gate_Action'Image (Action) &
         " family=" & Shared_State_Recheck_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Shared_State_Stabilization_Gate_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_220;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Convergence_Id));
      H := Mix (H, Shared_State_Recheck_Convergence_Status'Pos (Row.Convergence_Status) + 1);
      H := Mix (H, Shared_State_Recheck_Convergence_Action'Pos (Row.Convergence_Action) + 1);
      H := Mix (H, Shared_State_Stabilization_Gate_Status'Pos (Row.Status) + 1);
      H := Mix (H, Shared_State_Stabilization_Gate_Action'Pos (Row.Action) + 1);
      H := Mix (H, Shared_State_Recheck_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
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
     (Source : Conv.Shared_State_Recheck_Convergence_Row;
      Index  : Positive) return Shared_State_Stabilization_Gate_Row is
      Status : Shared_State_Stabilization_Gate_Status;
      Action : Shared_State_Stabilization_Gate_Action;
      Row    : Shared_State_Stabilization_Gate_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := Shared_State_Stabilization_Gate_Id (Index);
      Row.Convergence_Id := Source.Id;
      Row.Convergence_Status := Source.Status;
      Row.Convergence_Action := Source.Action;
      Row.Status := Status;
      Row.Action := Action;
      Row.Blocker_Family := Source.Blocker_Family;
      Row.Node := Source.Node;
      Row.Unit_Name := Source.Unit_Name;
      Row.Dependency_Name := Source.Dependency_Name;
      Row.State_Name := Source.State_Name;
      Row.Promoted := Is_Promoted (Status);
      Row.Current := Status = Shared_State_Stabilization_Gate_Promoted_Current;
      Row.Withheld := Is_Withheld (Status);
      Row.Stable := Status /= Shared_State_Stabilization_Gate_Recheck_Required;
      Row.Recheck_Required := Status = Shared_State_Stabilization_Gate_Recheck_Required;
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Application_Fingerprint := Source.Application_Fingerprint;
      Row.Convergence_Fingerprint := Source.Convergence_Fingerprint;
      Row.Message := Message_For (Status, Action, Source.Blocker_Family);
      Row.Stabilization_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Shared_State_Stabilization_Gate_Model;
      Row   : Shared_State_Stabilization_Gate_Row) is
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
      if Row.Status = Shared_State_Stabilization_Gate_Degraded_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Shared_State_Stabilization_Gate_Model) is
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
     (Convergence : Conv.Shared_State_Recheck_Convergence_Model)
      return Shared_State_Stabilization_Gate_Model is
      Model : Shared_State_Stabilization_Gate_Model;
   begin
      for I in 1 .. Conv.Row_Count (Convergence) loop
         Add_Row (Model, Make_Row (Conv.Row_At (Convergence, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : Shared_State_Stabilization_Gate_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Shared_State_Stabilization_Gate_Model;
      Index : Positive) return Shared_State_Stabilization_Gate_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Shared_State_Stabilization_Gate_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Shared_State_Stabilization_Gate_Set;
      Index : Positive) return Shared_State_Stabilization_Gate_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Shared_State_Stabilization_Gate_Set;
      Row : Shared_State_Stabilization_Gate_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Stabilization_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Shared_State_Stabilization_Gate_Model;
      Status : Shared_State_Stabilization_Gate_Status) return Shared_State_Stabilization_Gate_Set is
      Set : Shared_State_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Shared_State_Stabilization_Gate_Model;
      Action : Shared_State_Stabilization_Gate_Action) return Shared_State_Stabilization_Gate_Set is
      Set : Shared_State_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Blocker_Family
     (Model  : Shared_State_Stabilization_Gate_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Shared_State_Stabilization_Gate_Set is
      Set : Shared_State_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Shared_State_Stabilization_Gate_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Stabilization_Gate_Set is
      Set : Shared_State_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Shared_State_Stabilization_Gate_Model;
      Source_Fingerprint : Natural) return Shared_State_Stabilization_Gate_Set is
      Set : Shared_State_Stabilization_Gate_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Shared_State_Stabilization_Gate_Model;
      Status : Shared_State_Stabilization_Gate_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Shared_State_Stabilization_Gate_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Promoted_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Promoted_Total;
   end Promoted_Count;

   function Withheld_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Current_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Recheck_Required_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Shared_State_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Shared_State_Stabilization_Gate_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Shared_State_Stabilization_Gate_Legality;
