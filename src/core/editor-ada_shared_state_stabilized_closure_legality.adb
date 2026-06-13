with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Shared_State_Stabilized_Closure_Legality is

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_223) mod 2_147_483_647;
   end Mix;

   function Is_Accepted (Status : Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Shared_State_Stabilized_Closure_Accepted_Current
        or else Status = Shared_State_Stabilized_Closure_Accepted_Not_Required;
   end Is_Accepted;

   function Is_Blocked (Status : Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in Shared_State_Stabilized_Closure_Blocker_Cross_Unit_Dependency |
                       Shared_State_Stabilized_Closure_Blocker_View_Barrier |
                       Shared_State_Stabilized_Closure_Blocker_Generic_Backmapping |
                       Shared_State_Stabilized_Closure_Blocker_State_Visibility |
                       Shared_State_Stabilized_Closure_Blocker_Abstract_State |
                       Shared_State_Stabilized_Closure_Blocker_Volatile_Atomic |
                       Shared_State_Stabilized_Closure_Blocker_Overload_Shared_State |
                       Shared_State_Stabilized_Closure_Blocker_Representation_Freezing |
                       Shared_State_Stabilized_Closure_Blocker_Tasking_Protected |
                       Shared_State_Stabilized_Closure_Blocker_Source_Fingerprint |
                       Shared_State_Stabilized_Closure_Blocker_Stale_Eligibility |
                       Shared_State_Stabilized_Closure_Blocker_Multiple_Prerequisites;
   end Is_Blocked;

   procedure Classify
     (Source : Gate.Shared_State_Stabilization_Gate_Row;
      Status : out Shared_State_Stabilized_Closure_Status;
      Action : out Shared_State_Stabilized_Closure_Action) is
   begin
      case Source.Status is
         when Gate.Shared_State_Stabilization_Gate_Promoted_Current =>
            Status := Shared_State_Stabilized_Closure_Accepted_Current;
            Action := Shared_State_Stabilized_Closure_Action_Accept;
         when Gate.Shared_State_Stabilization_Gate_Promoted_Not_Required =>
            Status := Shared_State_Stabilized_Closure_Accepted_Not_Required;
            Action := Shared_State_Stabilized_Closure_Action_Accept_Not_Required;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Cross_Unit_Dependency =>
            Status := Shared_State_Stabilized_Closure_Blocker_Cross_Unit_Dependency;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_View_Barrier =>
            Status := Shared_State_Stabilized_Closure_Blocker_View_Barrier;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Generic_Backmapping =>
            Status := Shared_State_Stabilized_Closure_Blocker_Generic_Backmapping;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_State_Visibility =>
            Status := Shared_State_Stabilized_Closure_Blocker_State_Visibility;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Abstract_State =>
            Status := Shared_State_Stabilized_Closure_Blocker_Abstract_State;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Volatile_Atomic =>
            Status := Shared_State_Stabilized_Closure_Blocker_Volatile_Atomic;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Overload_Shared_State =>
            Status := Shared_State_Stabilized_Closure_Blocker_Overload_Shared_State;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Representation_Freezing =>
            Status := Shared_State_Stabilized_Closure_Blocker_Representation_Freezing;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Tasking_Protected =>
            Status := Shared_State_Stabilized_Closure_Blocker_Tasking_Protected;
            Action := Shared_State_Stabilized_Closure_Action_Block_Prerequisite;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Source_Fingerprint =>
            Status := Shared_State_Stabilized_Closure_Blocker_Source_Fingerprint;
            Action := Shared_State_Stabilized_Closure_Action_Retain_Fingerprint_Blocker;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Stale_Eligibility =>
            Status := Shared_State_Stabilized_Closure_Blocker_Stale_Eligibility;
            Action := Shared_State_Stabilized_Closure_Action_Retain_Stale_Blocker;
         when Gate.Shared_State_Stabilization_Gate_Withheld_Multiple_Prerequisites =>
            Status := Shared_State_Stabilized_Closure_Blocker_Multiple_Prerequisites;
            Action := Shared_State_Stabilized_Closure_Action_Split_Prerequisites;
         when Gate.Shared_State_Stabilization_Gate_Degraded_Indeterminate =>
            Status := Shared_State_Stabilized_Closure_Indeterminate;
            Action := Shared_State_Stabilized_Closure_Action_Degrade;
         when Gate.Shared_State_Stabilization_Gate_Recheck_Required =>
            Status := Shared_State_Stabilized_Closure_Recheck_Required;
            Action := Shared_State_Stabilized_Closure_Action_Recheck;
         when Gate.Shared_State_Stabilization_Gate_Not_Checked =>
            Status := Shared_State_Stabilized_Closure_Not_Checked;
            Action := Shared_State_Stabilized_Closure_Action_None;
      end case;
   end Classify;

   function Message_For
     (Status  : Shared_State_Stabilized_Closure_Status;
      Action  : Shared_State_Stabilized_Closure_Action;
      Blocker : Shared_State_Recheck_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("shared-state stabilized closure " &
         Shared_State_Stabilized_Closure_Status'Image (Status) &
         " action=" & Shared_State_Stabilized_Closure_Action'Image (Action) &
         " blocker=" & Shared_State_Recheck_Blocker_Family'Image (Blocker));
   end Message_For;

   function Row_Fingerprint (Row : Shared_State_Stabilized_Closure_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Stabilization_Id));
      H := Mix (H, Gate.Shared_State_Stabilization_Gate_Status'Pos (Row.Stabilization_Status) + 1);
      H := Mix (H, Gate.Shared_State_Stabilization_Gate_Action'Pos (Row.Stabilization_Action) + 1);
      H := Mix (H, Shared_State_Stabilized_Closure_Status'Pos (Row.Status) + 1);
      H := Mix (H, Shared_State_Stabilized_Closure_Action'Pos (Row.Action) + 1);
      H := Mix (H, Shared_State_Recheck_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
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
     (Source : Gate.Shared_State_Stabilization_Gate_Row;
      Index  : Positive) return Shared_State_Stabilized_Closure_Row is
      Status : Shared_State_Stabilized_Closure_Status;
      Action : Shared_State_Stabilized_Closure_Action;
      Result : Shared_State_Stabilized_Closure_Row;
   begin
      Classify (Source, Status, Action);
      Result.Id := Shared_State_Stabilized_Closure_Id (Index);
      Result.Stabilization_Id := Source.Id;
      Result.Stabilization_Status := Source.Status;
      Result.Stabilization_Action := Source.Action;
      Result.Status := Status;
      Result.Action := Action;
      Result.Blocker_Family := Source.Blocker_Family;
      Result.Node := Source.Node;
      Result.Unit_Name := Source.Unit_Name;
      Result.Dependency_Name := Source.Dependency_Name;
      Result.State_Name := Source.State_Name;
      Result.Accepted := Is_Accepted (Status);
      Result.Current := Result.Accepted and then Source.Current;
      Result.Blocked := Is_Blocked (Status);
      Result.Stable := Source.Stable;
      Result.Recheck_Required := Status = Shared_State_Stabilized_Closure_Recheck_Required;
      Result.Blocks_Downstream := Result.Blocked or else Result.Recheck_Required or else
        Status = Shared_State_Stabilized_Closure_Indeterminate;
      Result.Priority_Rank := Source.Priority_Rank;
      Result.Start_Line := Source.Start_Line;
      Result.Start_Column := Source.Start_Column;
      Result.End_Line := Source.End_Line;
      Result.End_Column := Source.End_Column;
      Result.Source_Fingerprint := Source.Source_Fingerprint;
      Result.Worklist_Fingerprint := Source.Worklist_Fingerprint;
      Result.Eligibility_Fingerprint := Source.Eligibility_Fingerprint;
      Result.Application_Fingerprint := Source.Application_Fingerprint;
      Result.Convergence_Fingerprint := Source.Convergence_Fingerprint;
      Result.Stabilization_Fingerprint := Source.Stabilization_Fingerprint;
      Result.Message := Message_For (Status, Action, Source.Blocker_Family);
      Result.Closure_Fingerprint := Row_Fingerprint (Result);
      return Result;
   end Make_Row;

   procedure Add_Row
     (Model : in out Shared_State_Stabilized_Closure_Model;
      Row   : Shared_State_Stabilized_Closure_Row) is
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
      if Row.Status = Shared_State_Stabilized_Closure_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Shared_State_Stabilized_Closure_Model) is
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
     (Stabilization : Gate.Shared_State_Stabilization_Gate_Model)
      return Shared_State_Stabilized_Closure_Model is
      Result : Shared_State_Stabilized_Closure_Model;
   begin
      for I in 1 .. Gate.Count (Stabilization) loop
         Add_Row (Result, Make_Row (Gate.Row_At (Stabilization, I), I));
      end loop;
      return Result;
   end Build;

   function Count (Model : Shared_State_Stabilized_Closure_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Shared_State_Stabilized_Closure_Model;
      Index : Positive) return Shared_State_Stabilized_Closure_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Shared_State_Stabilized_Closure_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Shared_State_Stabilized_Closure_Set;
      Index : Positive) return Shared_State_Stabilized_Closure_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Shared_State_Stabilized_Closure_Set;
      Row : Shared_State_Stabilized_Closure_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Closure_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Shared_State_Stabilized_Closure_Model;
      Status : Shared_State_Stabilized_Closure_Status) return Shared_State_Stabilized_Closure_Set is
      Result : Shared_State_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Action
     (Model  : Shared_State_Stabilized_Closure_Model;
      Action : Shared_State_Stabilized_Closure_Action) return Shared_State_Stabilized_Closure_Set is
      Result : Shared_State_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Action;

   function Query_Blocker_Family
     (Model  : Shared_State_Stabilized_Closure_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Shared_State_Stabilized_Closure_Set is
      Result : Shared_State_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Shared_State_Stabilized_Closure_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Stabilized_Closure_Set is
      Result : Shared_State_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Shared_State_Stabilized_Closure_Model;
      Source_Fingerprint : Natural) return Shared_State_Stabilized_Closure_Set is
      Result : Shared_State_Stabilized_Closure_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Append_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Shared_State_Stabilized_Closure_Model;
      Status : Shared_State_Stabilized_Closure_Status) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Shared_State_Stabilized_Closure_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Current_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Recheck_Required_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Shared_State_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Shared_State_Stabilized_Closure_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Shared_State_Stabilized_Closure_Legality;
