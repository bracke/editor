with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Remaining_RM_Edge_Precision_Legality is
   use type Application.RM_Closure_Consumer_Application_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 16_777_619 + Right + 12_777) mod 1_000_000_007;
   end Mix;

   function Application_Allows_Current
     (Status : Application.RM_Closure_Consumer_Application_Status) return Boolean is
   begin
      return Status in
        Application.RM_Closure_Consumer_Application_Current_Accepted |
        Application.RM_Closure_Consumer_Application_Current_Non_Diagnostic_Evidence |
        Application.RM_Closure_Consumer_Application_Not_Required;
   end Application_Allows_Current;

   function Local_Status_For
     (Kind : Remaining_RM_Edge_Kind) return Remaining_RM_Edge_Status is
   begin
      case Kind is
         when Remaining_RM_Edge_Dispatching_Abstract_State_Effect =>
            return Remaining_RM_Edge_Legal_Dispatching_Abstract_State_Effect;
         when Remaining_RM_Edge_Renamed_Primitive =>
            return Remaining_RM_Edge_Legal_Renamed_Primitive;
         when Remaining_RM_Edge_Inherited_Private_Extension_Primitive_Hiding =>
            return Remaining_RM_Edge_Legal_Inherited_Private_Extension_Primitive_Hiding;
         when Remaining_RM_Edge_Access_Subprogram_Effect_Profile =>
            return Remaining_RM_Edge_Legal_Access_Subprogram_Effect_Profile;
         when Remaining_RM_Edge_Generic_Formal_Subprogram_Call =>
            return Remaining_RM_Edge_Legal_Generic_Formal_Subprogram_Call;
         when Remaining_RM_Edge_Universal_Numeric_Stateful_Expected_Context =>
            return Remaining_RM_Edge_Legal_Universal_Numeric_Stateful_Expected_Context;
         when Remaining_RM_Edge_Volatile_Atomic_Representation_Clause =>
            return Remaining_RM_Edge_Legal_Volatile_Atomic_Representation_Clause;
         when Remaining_RM_Edge_Protected_Action_Reentrancy =>
            return Remaining_RM_Edge_Legal_Protected_Action_Reentrancy;
         when Remaining_RM_Edge_Entry_Family_Queue =>
            return Remaining_RM_Edge_Legal_Entry_Family_Queue;
         when Remaining_RM_Edge_Requeue_Select_Path =>
            return Remaining_RM_Edge_Legal_Requeue_Select_Path;
         when Remaining_RM_Edge_Abort_Deferred_Finalization =>
            return Remaining_RM_Edge_Legal_Abort_Deferred_Finalization;
         when Remaining_RM_Edge_Controlled_Finalized_Discriminant_Component =>
            return Remaining_RM_Edge_Legal_Controlled_Finalized_Discriminant_Component;
         when Remaining_RM_Edge_Unknown =>
            return Remaining_RM_Edge_Indeterminate;
      end case;
   end Local_Status_For;

   procedure Add_Blocker
     (Count  : in out Natural;
      Family : in out Remaining_RM_Edge_Blocker_Family;
      New_Family : Remaining_RM_Edge_Blocker_Family) is
   begin
      Count := Count + 1;
      if Count = 1 then
         Family := New_Family;
      else
         Family := Remaining_RM_Edge_Blocker_Multiple;
      end if;
   end Add_Blocker;

   procedure Classify
     (Context : Remaining_RM_Edge_Context;
      Status  : out Remaining_RM_Edge_Status;
      Family  : out Remaining_RM_Edge_Blocker_Family;
      Count   : out Natural) is
   begin
      Status := Local_Status_For (Context.Kind);
      Family := Remaining_RM_Edge_Blocker_None;
      Count := 0;

      if Context.Requires_Application
        and then Context.Application_Row = Application.No_RM_Closure_Consumer_Application
      then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_RM_Completion_Consumer_Application);
         Status := Remaining_RM_Edge_Missing_Application_Row;
      elsif Context.Requires_Application
        and then not Application_Allows_Current (Context.Application_Status)
      then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_RM_Completion_Consumer_Application);
         Status := Remaining_RM_Edge_Application_Blocker;
      end if;

      if Context.Expected_Source_Fingerprint /= 0
        and then Context.Source_Fingerprint /= Context.Expected_Source_Fingerprint
      then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Source_Fingerprint);
         Status := Remaining_RM_Edge_Source_Fingerprint_Mismatch;
      end if;

      if Context.Expected_Substitution_Fingerprint /= 0
        and then Context.Substitution_Fingerprint /= Context.Expected_Substitution_Fingerprint
      then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Substitution_Fingerprint);
         Status := Remaining_RM_Edge_Substitution_Fingerprint_Mismatch;
      end if;

      if Context.Dispatching_Abstract_State_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Dispatching_Abstract_State);
         Status := Remaining_RM_Edge_Dispatching_Abstract_State_Mismatch;
      end if;
      if Context.Renamed_Primitive_Visibility_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Renamed_Primitive);
         Status := Remaining_RM_Edge_Renamed_Primitive_Visibility_Mismatch;
      end if;
      if Context.Inherited_Primitive_Hiding_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Inherited_Primitive_Hiding);
         Status := Remaining_RM_Edge_Inherited_Primitive_Hiding_Mismatch;
      end if;
      if Context.Access_Profile_Effect_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Access_Profile);
         Status := Remaining_RM_Edge_Access_Profile_Effect_Mismatch;
      end if;
      if Context.Generic_Formal_Subprogram_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Generic_Formal_Subprogram);
         Status := Remaining_RM_Edge_Generic_Formal_Subprogram_Mismatch;
      end if;
      if Context.Universal_Numeric_State_Ambiguous then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Universal_Numeric_State);
         Status := Remaining_RM_Edge_Universal_Numeric_State_Ambiguous;
      end if;
      if Context.Volatile_Atomic_Representation_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Volatile_Atomic_Representation);
         Status := Remaining_RM_Edge_Volatile_Atomic_Representation_Mismatch;
      end if;
      if Context.Protected_Reentrancy_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Protected_Reentrancy);
         Status := Remaining_RM_Edge_Protected_Reentrancy_Mismatch;
      end if;
      if Context.Entry_Family_Queue_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Entry_Family_Queue);
         Status := Remaining_RM_Edge_Entry_Family_Queue_Mismatch;
      end if;
      if Context.Requeue_Select_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Requeue_Select);
         Status := Remaining_RM_Edge_Requeue_Select_Mismatch;
      end if;
      if Context.Abort_Finalization_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Abort_Finalization);
         Status := Remaining_RM_Edge_Abort_Finalization_Mismatch;
      end if;
      if Context.Controlled_Discriminant_Mismatch then
         Add_Blocker (Count, Family, Remaining_RM_Edge_Blocker_Controlled_Discriminant);
         Status := Remaining_RM_Edge_Controlled_Discriminant_Mismatch;
      end if;

      if Count > 1 then
         Status := Remaining_RM_Edge_Multiple_Blockers;
         Family := Remaining_RM_Edge_Blocker_Multiple;
      elsif Context.Kind = Remaining_RM_Edge_Unknown and then Count = 0 then
         Count := 1;
         Family := Remaining_RM_Edge_Blocker_Indeterminate;
         Status := Remaining_RM_Edge_Indeterminate;
      end if;
   end Classify;

   function Message_For
     (Status : Remaining_RM_Edge_Status;
      Family : Remaining_RM_Edge_Blocker_Family;
      Kind   : Remaining_RM_Edge_Kind) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("remaining Ada RM edge precision " &
         Remaining_RM_Edge_Status'Image (Status) &
         " family=" & Remaining_RM_Edge_Blocker_Family'Image (Family) &
         " kind=" & Remaining_RM_Edge_Kind'Image (Kind));
   end Message_For;

   function Row_Fingerprint (Row : Remaining_RM_Edge_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_770;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Remaining_RM_Edge_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Remaining_RM_Edge_Status'Pos (Row.Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Natural (Row.Application_Row));
      H := Mix (H, Application.RM_Closure_Consumer_Application_Status'Pos (Row.Application_Status) + 1);
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Is_Accepted (Status : Remaining_RM_Edge_Status) return Boolean is
   begin
      return Status in
        Remaining_RM_Edge_Legal_Dispatching_Abstract_State_Effect |
        Remaining_RM_Edge_Legal_Renamed_Primitive |
        Remaining_RM_Edge_Legal_Inherited_Private_Extension_Primitive_Hiding |
        Remaining_RM_Edge_Legal_Access_Subprogram_Effect_Profile |
        Remaining_RM_Edge_Legal_Generic_Formal_Subprogram_Call |
        Remaining_RM_Edge_Legal_Universal_Numeric_Stateful_Expected_Context |
        Remaining_RM_Edge_Legal_Volatile_Atomic_Representation_Clause |
        Remaining_RM_Edge_Legal_Protected_Action_Reentrancy |
        Remaining_RM_Edge_Legal_Entry_Family_Queue |
        Remaining_RM_Edge_Legal_Requeue_Select_Path |
        Remaining_RM_Edge_Legal_Abort_Deferred_Finalization |
        Remaining_RM_Edge_Legal_Controlled_Finalized_Discriminant_Component;
   end Is_Accepted;

   function Make_Row
     (Context : Remaining_RM_Edge_Context;
      Index   : Positive) return Remaining_RM_Edge_Row is
      Status : Remaining_RM_Edge_Status;
      Family : Remaining_RM_Edge_Blocker_Family;
      Blockers : Natural;
      Row : Remaining_RM_Edge_Row;
   begin
      Classify (Context, Status, Family, Blockers);
      Row.Id := Remaining_RM_Edge_Precision_Id (Index);
      Row.Context := Context.Id;
      Row.Kind := Context.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := Context.Node;
      Row.Unit_Name := Context.Unit_Name;
      Row.Operation_Name := Context.Operation_Name;
      Row.Type_Name := Context.Type_Name;
      Row.State_Name := Context.State_Name;
      Row.Application_Row := Context.Application_Row;
      Row.Application_Status := Context.Application_Status;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := not Row.Accepted;
      Row.Blocks_Downstream := Row.Blocked;
      Row.Blocker_Count := Blockers;
      Row.Source_Fingerprint := Context.Source_Fingerprint;
      Row.Substitution_Fingerprint := Context.Substitution_Fingerprint;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Message := Message_For (Status, Family, Context.Kind);
      Row.Row_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Remaining_RM_Edge_Context_Model) is
   begin
      Model.Contexts.Clear;
   end Clear;

   procedure Add_Context
     (Model   : in out Remaining_RM_Edge_Context_Model;
      Context : Remaining_RM_Edge_Context) is
   begin
      Model.Contexts.Append (Context);
   end Add_Context;

   procedure Add_Row
     (Model : in out Remaining_RM_Edge_Model;
      Row   : Remaining_RM_Edge_Row) is
   begin
      Model.Rows.Append (Row);
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Row_Fingerprint);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Blocked then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;
      if Row.Status = Remaining_RM_Edge_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
   end Add_Row;

   function Build (Contexts : Remaining_RM_Edge_Context_Model) return Remaining_RM_Edge_Model is
      Model : Remaining_RM_Edge_Model;
   begin
      for Index in 1 .. Natural (Contexts.Contexts.Length) loop
         Add_Row (Model, Make_Row (Contexts.Contexts.Element (Index), Index));
      end loop;
      return Model;
   end Build;

   function Count (Model : Remaining_RM_Edge_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Remaining_RM_Edge_Model;
      Index : Positive) return Remaining_RM_Edge_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Set;
      Index : Positive) return Remaining_RM_Edge_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status
     (Model  : Remaining_RM_Edge_Model;
      Status : Remaining_RM_Edge_Status) return Remaining_RM_Edge_Set is
      Set : Remaining_RM_Edge_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Set.Rows.Append (Row);
         end if;
      end loop;
      return Set;
   end Query_Status;

   function Query_Blocker_Family
     (Model  : Remaining_RM_Edge_Model;
      Family : Remaining_RM_Edge_Blocker_Family) return Remaining_RM_Edge_Set is
      Set : Remaining_RM_Edge_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Set.Rows.Append (Row);
         end if;
      end loop;
      return Set;
   end Query_Blocker_Family;

   function Find_By_Node
     (Model : Remaining_RM_Edge_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Remaining_RM_Edge_Set is
      Set : Remaining_RM_Edge_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Set.Rows.Append (Row);
         end if;
      end loop;
      return Set;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Set is
      Set : Remaining_RM_Edge_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Set.Rows.Append (Row);
         end if;
      end loop;
      return Set;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Remaining_RM_Edge_Model;
      Status : Remaining_RM_Edge_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family
     (Model  : Remaining_RM_Edge_Model;
      Family : Remaining_RM_Edge_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Remaining_RM_Edge_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Remaining_RM_Edge_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Remaining_RM_Edge_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Remaining_RM_Edge_Precision_Legality;
