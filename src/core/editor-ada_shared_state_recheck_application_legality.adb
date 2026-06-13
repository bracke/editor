with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Shared_State_Recheck_Application_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_203) mod 2_147_483_647;
   end Mix;

   procedure Classify
     (Source : Recheck.Shared_State_Recheck_Row;
      Status : out Shared_State_Recheck_Application_Status;
      Action : out Shared_State_Recheck_Application_Action) is
   begin
      case Source.Status is
         when Recheck.Shared_State_Recheck_Not_Checked =>
            Status := Shared_State_Recheck_Application_Withheld_Stale_Eligibility;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Stale_Eligibility;
         when Recheck.Shared_State_Recheck_Not_Required_Current =>
            Status := Shared_State_Recheck_Application_Current_Non_Diagnostic_Evidence;
            Action := Shared_State_Recheck_Application_Action_Keep_Non_Diagnostic_Evidence;
         when Recheck.Shared_State_Recheck_Eligible_Now =>
            Status := Shared_State_Recheck_Application_Current_Accepted;
            Action := Shared_State_Recheck_Application_Action_Expose_Current;
         when Recheck.Shared_State_Recheck_Blocked_By_Cross_Unit =>
            Status := Shared_State_Recheck_Application_Withheld_Cross_Unit_Dependency;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Cross_Unit;
         when Recheck.Shared_State_Recheck_Blocked_By_View_Barrier =>
            Status := Shared_State_Recheck_Application_Withheld_View_Barrier;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_View_Barrier;
         when Recheck.Shared_State_Recheck_Blocked_By_Generic_Backmapping =>
            Status := Shared_State_Recheck_Application_Withheld_Generic_Backmapping;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Generic_Backmapping;
         when Recheck.Shared_State_Recheck_Blocked_By_State_Visibility =>
            Status := Shared_State_Recheck_Application_Withheld_State_Visibility;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_State_Visibility;
         when Recheck.Shared_State_Recheck_Blocked_By_Abstract_State =>
            Status := Shared_State_Recheck_Application_Withheld_Abstract_State;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Abstract_State;
         when Recheck.Shared_State_Recheck_Blocked_By_Volatile_Atomic =>
            Status := Shared_State_Recheck_Application_Withheld_Volatile_Atomic;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Volatile_Atomic;
         when Recheck.Shared_State_Recheck_Blocked_By_Overload_Type =>
            Status := Shared_State_Recheck_Application_Withheld_Overload_Shared_State;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Overload_Type;
         when Recheck.Shared_State_Recheck_Blocked_By_Representation =>
            Status := Shared_State_Recheck_Application_Withheld_Representation_Freezing;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Representation;
         when Recheck.Shared_State_Recheck_Blocked_By_Tasking_Protected =>
            Status := Shared_State_Recheck_Application_Withheld_Tasking_Protected;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Tasking;
         when Recheck.Shared_State_Recheck_Blocked_By_Fingerprint =>
            Status := Shared_State_Recheck_Application_Withheld_Source_Fingerprint;
            Action := Shared_State_Recheck_Application_Action_Withhold_For_Source_Fingerprint;
         when Recheck.Shared_State_Recheck_Multiple_Prerequisites =>
            Status := Shared_State_Recheck_Application_Withheld_Multiple_Prerequisites;
            Action := Shared_State_Recheck_Application_Action_Split_Prerequisites;
         when Recheck.Shared_State_Recheck_Indeterminate =>
            Status := Shared_State_Recheck_Application_Indeterminate;
            Action := Shared_State_Recheck_Application_Action_Degrade;
      end case;
   end Classify;

   function Is_Current (Status : Shared_State_Recheck_Application_Status) return Boolean is
   begin
      return Status in Shared_State_Recheck_Application_Current_Accepted |
                       Shared_State_Recheck_Application_Current_Non_Diagnostic_Evidence;
   end Is_Current;

   function Is_Accepted (Status : Shared_State_Recheck_Application_Status) return Boolean is
   begin
      return Status = Shared_State_Recheck_Application_Current_Accepted;
   end Is_Accepted;

   function Is_Withheld (Status : Shared_State_Recheck_Application_Status) return Boolean is
   begin
      return Status in Shared_State_Recheck_Application_Withheld_Cross_Unit_Dependency |
                       Shared_State_Recheck_Application_Withheld_View_Barrier |
                       Shared_State_Recheck_Application_Withheld_Generic_Backmapping |
                       Shared_State_Recheck_Application_Withheld_State_Visibility |
                       Shared_State_Recheck_Application_Withheld_Abstract_State |
                       Shared_State_Recheck_Application_Withheld_Volatile_Atomic |
                       Shared_State_Recheck_Application_Withheld_Overload_Shared_State |
                       Shared_State_Recheck_Application_Withheld_Representation_Freezing |
                       Shared_State_Recheck_Application_Withheld_Tasking_Protected |
                       Shared_State_Recheck_Application_Withheld_Source_Fingerprint |
                       Shared_State_Recheck_Application_Withheld_Stale_Eligibility |
                       Shared_State_Recheck_Application_Withheld_Multiple_Prerequisites |
                       Shared_State_Recheck_Application_Indeterminate;
   end Is_Withheld;

   function Message_For
     (Status : Shared_State_Recheck_Application_Status;
      Action : Shared_State_Recheck_Application_Action;
      Family : Shared_State_Recheck_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("shared-state recheck application " &
         Shared_State_Recheck_Application_Status'Image (Status) &
         " action=" & Shared_State_Recheck_Application_Action'Image (Action) &
         " family=" & Shared_State_Recheck_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Shared_State_Recheck_Application_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_200;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Eligibility_Id));
      H := Mix (H, Recheck.Shared_State_Recheck_Status'Pos (Row.Eligibility_Status) + 1);
      H := Mix (H, Recheck.Shared_State_Recheck_Action'Pos (Row.Eligibility_Action) + 1);
      H := Mix (H, Shared_State_Recheck_Application_Status'Pos (Row.Status) + 1);
      H := Mix (H, Shared_State_Recheck_Application_Action'Pos (Row.Action) + 1);
      H := Mix (H, Stable.Shared_State_Stabilized_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Worklist_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source : Recheck.Shared_State_Recheck_Row;
      Index  : Positive) return Shared_State_Recheck_Application_Row is
      Status : Shared_State_Recheck_Application_Status;
      Action : Shared_State_Recheck_Application_Action;
      Row    : Shared_State_Recheck_Application_Row;
   begin
      Classify (Source, Status, Action);
      Row.Id := Shared_State_Recheck_Application_Id (Index);
      Row.Eligibility_Id := Source.Id;
      Row.Eligibility_Status := Source.Status;
      Row.Eligibility_Action := Source.Action;
      Row.Status := Status;
      Row.Action := Action;
      Row.Blocker_Family := Source.Family;
      Row.Node := Source.Node;
      Row.Unit_Name := Source.Unit_Name;
      Row.Dependency_Name := Source.Dependency_Name;
      Row.State_Name := Source.State_Name;
      Row.Current := Is_Current (Status);
      Row.Accepted := Is_Accepted (Status);
      Row.Withheld := Is_Withheld (Status);
      Row.Blocks_Downstream := Row.Withheld or else Source.Blocks_Downstream;
      Row.Priority_Rank := Source.Priority_Rank;
      Row.Start_Line := Source.Start_Line;
      Row.Start_Column := Source.Start_Column;
      Row.End_Line := Source.End_Line;
      Row.End_Column := Source.End_Column;
      Row.Source_Fingerprint := Source.Source_Fingerprint;
      Row.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Row.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Row.Message := Message_For (Status, Action, Source.Family);
      Row.Application_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Shared_State_Recheck_Application_Model;
      Row   : Shared_State_Recheck_Application_Row) is
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
      if Row.Status = Shared_State_Recheck_Application_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Shared_State_Recheck_Application_Model) is
   begin
      Model.Rows.Clear;
      Model.Accepted_Total := 0;
      Model.Withheld_Total := 0;
      Model.Current_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Eligibility : Recheck.Shared_State_Recheck_Model)
      return Shared_State_Recheck_Application_Model is
      Model : Shared_State_Recheck_Application_Model;
   begin
      for I in 1 .. Recheck.Row_Count (Eligibility) loop
         Add_Row (Model, Make_Row (Recheck.Row_At (Eligibility, I), I));
      end loop;
      return Model;
   end Build;

   function Count (Model : Shared_State_Recheck_Application_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Shared_State_Recheck_Application_Model;
      Index : Positive) return Shared_State_Recheck_Application_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Shared_State_Recheck_Application_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Shared_State_Recheck_Application_Set;
      Index : Positive) return Shared_State_Recheck_Application_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Shared_State_Recheck_Application_Set;
      Row : Shared_State_Recheck_Application_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Application_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Shared_State_Recheck_Application_Model;
      Status : Shared_State_Recheck_Application_Status) return Shared_State_Recheck_Application_Set is
      Set : Shared_State_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Shared_State_Recheck_Application_Model;
      Action : Shared_State_Recheck_Application_Action) return Shared_State_Recheck_Application_Set is
      Set : Shared_State_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Blocker_Family
     (Model  : Shared_State_Recheck_Application_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Shared_State_Recheck_Application_Set is
      Set : Shared_State_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Shared_State_Recheck_Application_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Recheck_Application_Set is
      Set : Shared_State_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Shared_State_Recheck_Application_Model;
      Source_Fingerprint : Natural) return Shared_State_Recheck_Application_Set is
      Set : Shared_State_Recheck_Application_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Shared_State_Recheck_Application_Model;
      Status : Shared_State_Recheck_Application_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Shared_State_Recheck_Application_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Shared_State_Recheck_Application_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Withheld_Count (Model : Shared_State_Recheck_Application_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Current_Count (Model : Shared_State_Recheck_Application_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Indeterminate_Count (Model : Shared_State_Recheck_Application_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Shared_State_Recheck_Application_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Shared_State_Recheck_Application_Legality;
