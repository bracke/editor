with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Generic_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Tasking_Deep.Deep_Tasking_Row_Id;
   use type Tasking_Shared.Tasking_Shared_State_Row_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Overload_Generic.Overload_Generic_Final_Row_Id;
   use type Rep_Generic.Representation_Generic_Final_Row_Id;
   use type Abstract_Consumers.Abstract_State_Consumer_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 16#9E37#) mod 2_147_483_647;
   end Mix;

   function Deep_Tasking_Accepted (Status : Tasking_Deep.Deep_Tasking_Status) return Boolean is
   begin
      return Tasking_Deep.Is_Legal (Status);
   end Deep_Tasking_Accepted;

   function Closure_Accepted (Status : Closure.Shared_State_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current
        or else Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Accepted (Status : Tasking_Generic_Final_Status) return Boolean is
   begin
      case Status is
         when Tasking_Generic_Final_Legal_Protected_Action_Accepted
            | Tasking_Generic_Final_Legal_Entry_Family_Queue_Accepted
            | Tasking_Generic_Final_Legal_Accept_Body_Effect_Accepted
            | Tasking_Generic_Final_Legal_Requeue_Path_Accepted
            | Tasking_Generic_Final_Legal_Select_Alternative_Accepted
            | Tasking_Generic_Final_Legal_Task_Activation_Accepted
            | Tasking_Generic_Final_Legal_Task_Termination_Accepted
            | Tasking_Generic_Final_Legal_Abort_Finalization_Accepted
            | Tasking_Generic_Final_Legal_Generic_Task_Body_Accepted
            | Tasking_Generic_Final_Legal_Generic_Protected_Body_Accepted
            | Tasking_Generic_Final_Legal_Abstract_State_Effect_Accepted
            | Tasking_Generic_Final_Legal_Representation_Sensitive_Effect_Accepted =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Tasking_Generic_Final_Status) return Boolean is
   begin
      return Status = Tasking_Generic_Final_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Tasking_Generic_Final_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Tasking_Generic_Final_Not_Checked
        and then Status /= Tasking_Generic_Final_Indeterminate;
   end Is_Blocked;

   function Accepted_For (Kind : Tasking_Generic_Final_Kind) return Tasking_Generic_Final_Status is
   begin
      case Kind is
         when Tasking_Generic_Final_Protected_Action =>
            return Tasking_Generic_Final_Legal_Protected_Action_Accepted;
         when Tasking_Generic_Final_Entry_Family_Queue =>
            return Tasking_Generic_Final_Legal_Entry_Family_Queue_Accepted;
         when Tasking_Generic_Final_Accept_Body_Effect =>
            return Tasking_Generic_Final_Legal_Accept_Body_Effect_Accepted;
         when Tasking_Generic_Final_Requeue_Path =>
            return Tasking_Generic_Final_Legal_Requeue_Path_Accepted;
         when Tasking_Generic_Final_Select_Alternative =>
            return Tasking_Generic_Final_Legal_Select_Alternative_Accepted;
         when Tasking_Generic_Final_Task_Activation =>
            return Tasking_Generic_Final_Legal_Task_Activation_Accepted;
         when Tasking_Generic_Final_Task_Termination =>
            return Tasking_Generic_Final_Legal_Task_Termination_Accepted;
         when Tasking_Generic_Final_Abort_Finalization =>
            return Tasking_Generic_Final_Legal_Abort_Finalization_Accepted;
         when Tasking_Generic_Final_Generic_Task_Body =>
            return Tasking_Generic_Final_Legal_Generic_Task_Body_Accepted;
         when Tasking_Generic_Final_Generic_Protected_Body =>
            return Tasking_Generic_Final_Legal_Generic_Protected_Body_Accepted;
         when Tasking_Generic_Final_Abstract_State_Effect =>
            return Tasking_Generic_Final_Legal_Abstract_State_Effect_Accepted;
         when Tasking_Generic_Final_Representation_Sensitive_Effect =>
            return Tasking_Generic_Final_Legal_Representation_Sensitive_Effect_Accepted;
         when Tasking_Generic_Final_Unknown =>
            return Tasking_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Tasking_Generic_Final_Status) return Tasking_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Tasking_Generic_Final_Missing_Deep_Tasking_Row | Tasking_Generic_Final_Deep_Tasking_Blocker =>
            return Tasking_Generic_Final_Blocker_Deep_Tasking;
         when Tasking_Generic_Final_Missing_Tasking_Shared_Row | Tasking_Generic_Final_Tasking_Shared_Blocker =>
            return Tasking_Generic_Final_Blocker_Tasking_Shared_State;
         when Tasking_Generic_Final_Missing_Generic_Replay_Row | Tasking_Generic_Final_Generic_Replay_Blocker =>
            return Tasking_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Tasking_Generic_Final_Missing_Overload_Generic_Row | Tasking_Generic_Final_Overload_Generic_Blocker =>
            return Tasking_Generic_Final_Blocker_Overload_Generic_Shared_State;
         when Tasking_Generic_Final_Missing_Representation_Generic_Row | Tasking_Generic_Final_Representation_Generic_Blocker =>
            return Tasking_Generic_Final_Blocker_Representation_Generic_Shared_State;
         when Tasking_Generic_Final_Missing_Abstract_Consumer_Row | Tasking_Generic_Final_Abstract_Consumer_Blocker =>
            return Tasking_Generic_Final_Blocker_Abstract_State_Consumer;
         when Tasking_Generic_Final_Missing_Stabilized_Closure_Row | Tasking_Generic_Final_Stabilized_Closure_Blocker =>
            return Tasking_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Tasking_Generic_Final_Protected_Action_Reentrancy_Blocker =>
            return Tasking_Generic_Final_Blocker_Protected_Action_Reentrancy;
         when Tasking_Generic_Final_Entry_Family_Queue_Blocker =>
            return Tasking_Generic_Final_Blocker_Entry_Family_Queue;
         when Tasking_Generic_Final_Accept_Requeue_Select_Blocker =>
            return Tasking_Generic_Final_Blocker_Accept_Requeue_Select;
         when Tasking_Generic_Final_Task_Activation_Termination_Blocker =>
            return Tasking_Generic_Final_Blocker_Task_Activation_Termination;
         when Tasking_Generic_Final_Abort_Finalization_Blocker =>
            return Tasking_Generic_Final_Blocker_Abort_Finalization;
         when Tasking_Generic_Final_Generic_Body_Effect_Blocker =>
            return Tasking_Generic_Final_Blocker_Generic_Body_Effect;
         when Tasking_Generic_Final_Representation_Sensitive_Tasking_Blocker =>
            return Tasking_Generic_Final_Blocker_Representation_Sensitive_Tasking;
         when Tasking_Generic_Final_Source_Fingerprint_Mismatch =>
            return Tasking_Generic_Final_Blocker_Source_Fingerprint;
         when Tasking_Generic_Final_Substitution_Fingerprint_Mismatch =>
            return Tasking_Generic_Final_Blocker_Substitution_Fingerprint;
         when Tasking_Generic_Final_Multiple_Blockers =>
            return Tasking_Generic_Final_Blocker_Multiple;
         when Tasking_Generic_Final_Indeterminate =>
            return Tasking_Generic_Final_Blocker_Indeterminate;
         when others =>
            return Tasking_Generic_Final_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Tasking_Generic_Final_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Protected_Action_Reentrancy_Blocker then Count := Count + 1; end if;
      if C.Entry_Family_Queue_Blocker then Count := Count + 1; end if;
      if C.Accept_Requeue_Select_Blocker then Count := Count + 1; end if;
      if C.Task_Activation_Termination_Blocker then Count := Count + 1; end if;
      if C.Abort_Finalization_Blocker then Count := Count + 1; end if;
      if C.Generic_Body_Effect_Blocker then Count := Count + 1; end if;
      if C.Representation_Sensitive_Tasking_Blocker then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Tasking_Generic_Final_Context) return Tasking_Generic_Final_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Tasking_Generic_Final_Multiple_Blockers;
      elsif C.Protected_Action_Reentrancy_Blocker then
         return Tasking_Generic_Final_Protected_Action_Reentrancy_Blocker;
      elsif C.Entry_Family_Queue_Blocker then
         return Tasking_Generic_Final_Entry_Family_Queue_Blocker;
      elsif C.Accept_Requeue_Select_Blocker then
         return Tasking_Generic_Final_Accept_Requeue_Select_Blocker;
      elsif C.Task_Activation_Termination_Blocker then
         return Tasking_Generic_Final_Task_Activation_Termination_Blocker;
      elsif C.Abort_Finalization_Blocker then
         return Tasking_Generic_Final_Abort_Finalization_Blocker;
      elsif C.Generic_Body_Effect_Blocker then
         return Tasking_Generic_Final_Generic_Body_Effect_Blocker;
      elsif C.Representation_Sensitive_Tasking_Blocker then
         return Tasking_Generic_Final_Representation_Sensitive_Tasking_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Tasking_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Tasking_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Deep_Tasking and then C.Deep_Tasking_Row = Tasking_Deep.No_Deep_Tasking_Row then
         return Tasking_Generic_Final_Missing_Deep_Tasking_Row;
      elsif C.Requires_Deep_Tasking and then not Deep_Tasking_Accepted (C.Deep_Tasking_Status) then
         return Tasking_Generic_Final_Deep_Tasking_Blocker;
      elsif C.Requires_Tasking_Shared and then C.Tasking_Shared_Row = Tasking_Shared.No_Tasking_Shared_State_Row then
         return Tasking_Generic_Final_Missing_Tasking_Shared_Row;
      elsif C.Requires_Tasking_Shared and then not Tasking_Shared.Is_Legal (C.Tasking_Shared_Status) then
         return Tasking_Generic_Final_Tasking_Shared_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then
         return Tasking_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then
         return Tasking_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Overload_Generic and then C.Overload_Generic_Row = Overload_Generic.No_Overload_Generic_Final_Row then
         return Tasking_Generic_Final_Missing_Overload_Generic_Row;
      elsif C.Requires_Overload_Generic and then not Overload_Generic.Is_Accepted (C.Overload_Generic_Status) then
         return Tasking_Generic_Final_Overload_Generic_Blocker;
      elsif C.Requires_Representation_Generic and then C.Representation_Generic_Row = Rep_Generic.No_Representation_Generic_Final_Row then
         return Tasking_Generic_Final_Missing_Representation_Generic_Row;
      elsif C.Requires_Representation_Generic and then not Rep_Generic.Is_Accepted (C.Representation_Generic_Status) then
         return Tasking_Generic_Final_Representation_Generic_Blocker;
      elsif C.Requires_Abstract_Consumer and then C.Abstract_Consumer_Row = Abstract_Consumers.No_Abstract_State_Consumer_Row then
         return Tasking_Generic_Final_Missing_Abstract_Consumer_Row;
      elsif C.Requires_Abstract_Consumer and then not Abstract_Consumers.Is_Accepted (C.Abstract_Consumer_Status) then
         return Tasking_Generic_Final_Abstract_Consumer_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then
         return Tasking_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Tasking_Generic_Final_Stabilized_Closure_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For
     (Status : Tasking_Generic_Final_Status;
      Kind   : Tasking_Generic_Final_Kind;
      Family : Tasking_Generic_Final_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("tasking/generic shared-state final legality " &
         Tasking_Generic_Final_Status'Image (Status) &
         " kind=" & Tasking_Generic_Final_Kind'Image (Kind) &
         " blocker=" & Tasking_Generic_Final_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Tasking_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Tasking_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Tasking_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Tasking_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row (C : Tasking_Generic_Final_Context; Index : Positive) return Tasking_Generic_Final_Row is
      Status : constant Tasking_Generic_Final_Status := Classify (C);
      Family : constant Tasking_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Tasking_Generic_Final_Row;
   begin
      Row.Id := Tasking_Generic_Final_Row_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Operation_Name := C.Operation_Name;
      Row.State_Name := C.State_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then
         Row.Blocker_Count := 1;
      end if;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Tasking_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Tasking_Generic_Final_Context_Model; Info : Tasking_Generic_Final_Context) is
      Local : Natural := Natural (Info.Id);
   begin
      Model.Items.Append (Info);
      Local := Mix (Local, Tasking_Generic_Final_Kind'Pos (Info.Kind) + 1);
      Local := Mix (Local, Natural (Info.Node));
      Local := Mix (Local, Info.Source_Fingerprint);
      Local := Mix (Local, Info.Substitution_Fingerprint);
      Model.Fingerprint := Mix (Model.Fingerprint, Local);
   end Add_Context;

   function Context_Count (Model : Tasking_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Tasking_Generic_Final_Context_Model; Index : Positive) return Tasking_Generic_Final_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Fingerprint (Model : Tasking_Generic_Final_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Tasking_Generic_Final_Context_Model) return Tasking_Generic_Final_Model is
      Result : Tasking_Generic_Final_Model;
      Index  : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Tasking_Generic_Final_Row := Make_Row (C, Index);
         begin
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end;
         Index := Index + 1;
      end loop;
      return Result;
   end Build;

   function Count (Model : Tasking_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Tasking_Generic_Final_Model; Index : Positive) return Tasking_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Tasking_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At (Set : Tasking_Generic_Final_Set; Index : Positive) return Tasking_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status (Model : Tasking_Generic_Final_Model; Status : Tasking_Generic_Final_Status) return Tasking_Generic_Final_Set is
      Result : Tasking_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family (Model : Tasking_Generic_Final_Model; Family : Tasking_Generic_Final_Blocker_Family) return Tasking_Generic_Final_Set is
      Result : Tasking_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node (Model : Tasking_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Generic_Final_Set is
      Result : Tasking_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Tasking_Generic_Final_Model; Source_Fingerprint : Natural) return Tasking_Generic_Final_Set is
      Result : Tasking_Generic_Final_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status (Model : Tasking_Generic_Final_Model; Status : Tasking_Generic_Final_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Tasking_Generic_Final_Model; Family : Tasking_Generic_Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Tasking_Generic_Final_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Accepted_Count;

   function Blocked_Count (Model : Tasking_Generic_Final_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Tasking_Generic_Final_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Tasking_Generic_Final_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
