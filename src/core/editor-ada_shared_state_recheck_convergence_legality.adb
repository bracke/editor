with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Shared_State_Recheck_Convergence_Legality is

   pragma Suppress (Overflow_Check);
   use type Shared_State_Recheck_Blocker_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 65_537) + Right + 12_211) mod 2_147_483_647;
   end Mix;

   function Is_Stable_Withheld
     (Status : Shared_State_Recheck_Convergence_Status) return Boolean is
   begin
      return Status in Shared_State_Recheck_Stable_Withheld_Cross_Unit_Dependency |
                       Shared_State_Recheck_Stable_Withheld_View_Barrier |
                       Shared_State_Recheck_Stable_Withheld_Generic_Backmapping |
                       Shared_State_Recheck_Stable_Withheld_State_Visibility |
                       Shared_State_Recheck_Stable_Withheld_Abstract_State |
                       Shared_State_Recheck_Stable_Withheld_Volatile_Atomic |
                       Shared_State_Recheck_Stable_Withheld_Overload_Shared_State |
                       Shared_State_Recheck_Stable_Withheld_Representation_Freezing |
                       Shared_State_Recheck_Stable_Withheld_Tasking_Protected |
                       Shared_State_Recheck_Stable_Withheld_Source_Fingerprint |
                       Shared_State_Recheck_Stable_Withheld_Stale_Eligibility |
                       Shared_State_Recheck_Stable_Multiple_Prerequisites |
                       Shared_State_Recheck_Stable_Indeterminate;
   end Is_Stable_Withheld;

   procedure Classify
     (Source       : Apply.Shared_State_Recheck_Application_Row;
      Previous_Fp  : Natural;
      Model_Fp     : Natural;
      Status       : out Shared_State_Recheck_Convergence_Status;
      Action       : out Shared_State_Recheck_Convergence_Action) is
   begin
      if Previous_Fp /= 0 and then Previous_Fp /= Model_Fp then
         Status := Shared_State_Recheck_Changed_Since_Previous;
         Action := Shared_State_Recheck_Convergence_Action_Recheck_Again;
         return;
      end if;

      case Source.Status is
         when Apply.Shared_State_Recheck_Application_Not_Checked =>
            Status := Shared_State_Recheck_Convergence_Not_Checked;
            Action := Shared_State_Recheck_Convergence_Action_None;
         when Apply.Shared_State_Recheck_Application_Current_Accepted |
              Apply.Shared_State_Recheck_Application_Current_Non_Diagnostic_Evidence =>
            Status := Shared_State_Recheck_Converged_Current;
            Action := Shared_State_Recheck_Convergence_Action_Accept_Current;
         when Apply.Shared_State_Recheck_Application_Not_Required =>
            Status := Shared_State_Recheck_Converged_Not_Required;
            Action := Shared_State_Recheck_Convergence_Action_Skip_Not_Required;
         when Apply.Shared_State_Recheck_Application_Withheld_Cross_Unit_Dependency =>
            Status := Shared_State_Recheck_Stable_Withheld_Cross_Unit_Dependency;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_View_Barrier =>
            Status := Shared_State_Recheck_Stable_Withheld_View_Barrier;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_Generic_Backmapping =>
            Status := Shared_State_Recheck_Stable_Withheld_Generic_Backmapping;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_State_Visibility =>
            Status := Shared_State_Recheck_Stable_Withheld_State_Visibility;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_Abstract_State =>
            Status := Shared_State_Recheck_Stable_Withheld_Abstract_State;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_Volatile_Atomic =>
            Status := Shared_State_Recheck_Stable_Withheld_Volatile_Atomic;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_Overload_Shared_State =>
            Status := Shared_State_Recheck_Stable_Withheld_Overload_Shared_State;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_Representation_Freezing =>
            Status := Shared_State_Recheck_Stable_Withheld_Representation_Freezing;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_Tasking_Protected =>
            Status := Shared_State_Recheck_Stable_Withheld_Tasking_Protected;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Withheld;
         when Apply.Shared_State_Recheck_Application_Withheld_Source_Fingerprint =>
            Status := Shared_State_Recheck_Stable_Withheld_Source_Fingerprint;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Fingerprint_Blocker;
         when Apply.Shared_State_Recheck_Application_Withheld_Stale_Eligibility =>
            Status := Shared_State_Recheck_Stable_Withheld_Stale_Eligibility;
            Action := Shared_State_Recheck_Convergence_Action_Retain_Stable_Stale_Blocker;
         when Apply.Shared_State_Recheck_Application_Withheld_Multiple_Prerequisites =>
            Status := Shared_State_Recheck_Stable_Multiple_Prerequisites;
            Action := Shared_State_Recheck_Convergence_Action_Split_Prerequisites;
         when Apply.Shared_State_Recheck_Application_Indeterminate =>
            Status := Shared_State_Recheck_Stable_Indeterminate;
            Action := Shared_State_Recheck_Convergence_Action_Degrade;
      end case;
   end Classify;

   function Message_For
     (Status : Shared_State_Recheck_Convergence_Status;
      Action : Shared_State_Recheck_Convergence_Action;
      Family : Shared_State_Recheck_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("shared-state recheck convergence " &
         Shared_State_Recheck_Convergence_Status'Image (Status) &
         " action=" & Shared_State_Recheck_Convergence_Action'Image (Action) &
         " family=" & Shared_State_Recheck_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Shared_State_Recheck_Convergence_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_210;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Application_Id));
      H := Mix (H, Apply.Shared_State_Recheck_Application_Status'Pos (Row.Application_Status) + 1);
      H := Mix (H, Apply.Shared_State_Recheck_Application_Action'Pos (Row.Application_Action) + 1);
      H := Mix (H, Shared_State_Recheck_Convergence_Status'Pos (Row.Status) + 1);
      H := Mix (H, Shared_State_Recheck_Convergence_Action'Pos (Row.Action) + 1);
      H := Mix (H, Shared_State_Recheck_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Priority_Rank);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Worklist_Fingerprint);
      H := Mix (H, Row.Eligibility_Fingerprint);
      H := Mix (H, Row.Application_Fingerprint);
      H := Mix (H, Row.Previous_Model_Fingerprint);
      H := Mix (H, Row.Current_Model_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Source      : Apply.Shared_State_Recheck_Application_Row;
      Index       : Positive;
      Previous_Fp : Natural;
      Model_Fp    : Natural) return Shared_State_Recheck_Convergence_Row is
      Status : Shared_State_Recheck_Convergence_Status;
      Action : Shared_State_Recheck_Convergence_Action;
      Row    : Shared_State_Recheck_Convergence_Row;
   begin
      Classify (Source, Previous_Fp, Model_Fp, Status, Action);
      Row.Id := Shared_State_Recheck_Convergence_Id (Index);
      Row.Application_Id := Source.Id;
      Row.Application_Status := Source.Status;
      Row.Application_Action := Source.Action;
      Row.Status := Status;
      Row.Action := Action;
      Row.Blocker_Family := Source.Blocker_Family;
      Row.Node := Source.Node;
      Row.Unit_Name := Source.Unit_Name;
      Row.Dependency_Name := Source.Dependency_Name;
      Row.State_Name := Source.State_Name;
      Row.Current := Status = Shared_State_Recheck_Converged_Current;
      Row.Stable := Status /= Shared_State_Recheck_Changed_Since_Previous;
      Row.Withheld := Is_Stable_Withheld (Status);
      Row.Changed := Status = Shared_State_Recheck_Changed_Since_Previous;
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
      Row.Previous_Model_Fingerprint := Previous_Fp;
      Row.Current_Model_Fingerprint := Model_Fp;
      Row.Message := Message_For (Status, Action, Source.Blocker_Family);
      Row.Convergence_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Add_Row
     (Model : in out Shared_State_Recheck_Convergence_Model;
      Row   : Shared_State_Recheck_Convergence_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Convergence_Fingerprint);
      if Row.Status in Shared_State_Recheck_Converged_Current |
                       Shared_State_Recheck_Converged_Not_Required
      then
         Model.Converged_Total := Model.Converged_Total + 1;
      end if;
      if Row.Withheld then
         Model.Stable_Withheld_Total := Model.Stable_Withheld_Total + 1;
      end if;
      if Row.Current then
         Model.Current_Total := Model.Current_Total + 1;
      end if;
      if Row.Changed then
         Model.Changed_Total := Model.Changed_Total + 1;
      end if;
      if Row.Status = Shared_State_Recheck_Stable_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   procedure Clear (Model : in out Shared_State_Recheck_Convergence_Model) is
   begin
      Model.Rows.Clear;
      Model.Converged_Total := 0;
      Model.Stable_Withheld_Total := 0;
      Model.Current_Total := 0;
      Model.Changed_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Applications               : Apply.Shared_State_Recheck_Application_Model;
      Previous_Model_Fingerprint : Natural := 0)
      return Shared_State_Recheck_Convergence_Model is
      Model    : Shared_State_Recheck_Convergence_Model;
      Current  : constant Natural := Apply.Stable_Fingerprint (Applications);
   begin
      for I in 1 .. Apply.Row_Count (Applications) loop
         Add_Row (Model, Make_Row (Apply.Row_At (Applications, I), I, Previous_Model_Fingerprint, Current));
      end loop;
      return Model;
   end Build;

   function Count (Model : Shared_State_Recheck_Convergence_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Shared_State_Recheck_Convergence_Model;
      Index : Positive) return Shared_State_Recheck_Convergence_Row is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Shared_State_Recheck_Convergence_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Shared_State_Recheck_Convergence_Set;
      Index : Positive) return Shared_State_Recheck_Convergence_Row is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append_Query
     (Set : in out Shared_State_Recheck_Convergence_Set;
      Row : Shared_State_Recheck_Convergence_Row) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Convergence_Fingerprint);
   end Append_Query;

   function Query_Status
     (Model  : Shared_State_Recheck_Convergence_Model;
      Status : Shared_State_Recheck_Convergence_Status) return Shared_State_Recheck_Convergence_Set is
      Set : Shared_State_Recheck_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Action
     (Model  : Shared_State_Recheck_Convergence_Model;
      Action : Shared_State_Recheck_Convergence_Action) return Shared_State_Recheck_Convergence_Set is
      Set : Shared_State_Recheck_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Action = Action then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Action;

   function Query_Blocker_Family
     (Model  : Shared_State_Recheck_Convergence_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Shared_State_Recheck_Convergence_Set is
      Set : Shared_State_Recheck_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Shared_State_Recheck_Convergence_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Shared_State_Recheck_Convergence_Set is
      Set : Shared_State_Recheck_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model              : Shared_State_Recheck_Convergence_Model;
      Source_Fingerprint : Natural) return Shared_State_Recheck_Convergence_Set is
      Set : Shared_State_Recheck_Convergence_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Append_Query (Set, Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Shared_State_Recheck_Convergence_Model;
      Status : Shared_State_Recheck_Convergence_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Shared_State_Recheck_Convergence_Model;
      Family : Shared_State_Recheck_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Converged_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural is
   begin
      return Model.Converged_Total;
   end Converged_Count;

   function Stable_Withheld_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural is
   begin
      return Model.Stable_Withheld_Total;
   end Stable_Withheld_Count;

   function Current_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural is
   begin
      return Model.Current_Total;
   end Current_Count;

   function Changed_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural is
   begin
      return Model.Changed_Total;
   end Changed_Count;

   function Indeterminate_Count (Model : Shared_State_Recheck_Convergence_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Shared_State_Recheck_Convergence_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Shared_State_Recheck_Convergence_Legality;
