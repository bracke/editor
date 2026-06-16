with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality is

   pragma Suppress (Overflow_Check);
   use type Closure.Generic_Shared_State_Final_Stabilized_Closure_Status;
   use type Previous.Tasking_Generic_Final_Row_Id;
   use type Representation_Hard_Cases.Representation_Generic_RM_Hard_Case_Id;
   use type Overload_Edges.Overload_Generic_RM_Edge_Completion_Id;
   use type Closure.Generic_Shared_State_Final_Stabilized_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 17) mod 2_147_483_647;
   end Mix;

   function Closure_Accepted (Status : Closure.Generic_Shared_State_Final_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Current
        or else Status = Closure.Generic_Shared_State_Final_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Is_Accepted (Status : Tasking_Generic_RM_Hard_Case_Status) return Boolean is
   begin
      case Status is
         when Tasking_Generic_RM_Hard_Case_Legal_Protected_Action_Reentrancy_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Callback_Reentrancy_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Entry_Family_Queue_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Requeue_Select_Path_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Accept_Body_Effect_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Abort_Finalization_Ordering_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Task_Termination_Ordering_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Protected_Shared_State_Access_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Abstract_State_Backed_Task_Effect_Accepted
            | Tasking_Generic_RM_Hard_Case_Legal_Generic_Task_Protected_Body_Effect_Accepted => return True;
         when others => return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Tasking_Generic_RM_Hard_Case_Status) return Boolean is
   begin
      return Status = Tasking_Generic_RM_Hard_Case_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Tasking_Generic_RM_Hard_Case_Status) return Boolean is
   begin
      return not Is_Accepted (Status) and then Status /= Tasking_Generic_RM_Hard_Case_Not_Checked and then Status /= Tasking_Generic_RM_Hard_Case_Indeterminate;
   end Is_Blocked;

   function Accepted_For (Kind : Tasking_Generic_RM_Hard_Case_Kind) return Tasking_Generic_RM_Hard_Case_Status is
   begin
      case Kind is
         when Tasking_Generic_RM_Hard_Case_Protected_Action_Reentrancy => return Tasking_Generic_RM_Hard_Case_Legal_Protected_Action_Reentrancy_Accepted;
         when Tasking_Generic_RM_Hard_Case_Callback_Reentrancy => return Tasking_Generic_RM_Hard_Case_Legal_Callback_Reentrancy_Accepted;
         when Tasking_Generic_RM_Hard_Case_Entry_Family_Queue => return Tasking_Generic_RM_Hard_Case_Legal_Entry_Family_Queue_Accepted;
         when Tasking_Generic_RM_Hard_Case_Requeue_Select_Path => return Tasking_Generic_RM_Hard_Case_Legal_Requeue_Select_Path_Accepted;
         when Tasking_Generic_RM_Hard_Case_Accept_Body_Effect => return Tasking_Generic_RM_Hard_Case_Legal_Accept_Body_Effect_Accepted;
         when Tasking_Generic_RM_Hard_Case_Abort_Finalization_Ordering => return Tasking_Generic_RM_Hard_Case_Legal_Abort_Finalization_Ordering_Accepted;
         when Tasking_Generic_RM_Hard_Case_Task_Termination_Ordering => return Tasking_Generic_RM_Hard_Case_Legal_Task_Termination_Ordering_Accepted;
         when Tasking_Generic_RM_Hard_Case_Protected_Shared_State_Access => return Tasking_Generic_RM_Hard_Case_Legal_Protected_Shared_State_Access_Accepted;
         when Tasking_Generic_RM_Hard_Case_Abstract_State_Backed_Task_Effect => return Tasking_Generic_RM_Hard_Case_Legal_Abstract_State_Backed_Task_Effect_Accepted;
         when Tasking_Generic_RM_Hard_Case_Generic_Task_Protected_Body_Effect => return Tasking_Generic_RM_Hard_Case_Legal_Generic_Task_Protected_Body_Effect_Accepted;
         when others => return Tasking_Generic_RM_Hard_Case_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Tasking_Generic_RM_Hard_Case_Status) return Tasking_Generic_RM_Hard_Case_Blocker_Family is
   begin
      case Status is
         when Tasking_Generic_RM_Hard_Case_Missing_Previous_Tasking_Row | Tasking_Generic_RM_Hard_Case_Previous_Tasking_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Previous_Tasking;
         when Tasking_Generic_RM_Hard_Case_Missing_Representation_RM_Hard_Case_Row | Tasking_Generic_RM_Hard_Case_Representation_RM_Hard_Case_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Representation_RM_Hard_Case;
         when Tasking_Generic_RM_Hard_Case_Missing_Overload_RM_Edge_Row | Tasking_Generic_RM_Hard_Case_Overload_RM_Edge_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Overload_RM_Edge;
         when Tasking_Generic_RM_Hard_Case_Missing_Stabilized_Closure_Row | Tasking_Generic_RM_Hard_Case_Stabilized_Closure_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Stabilized_Closure;
         when Tasking_Generic_RM_Hard_Case_Protected_Action_Reentrancy_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Protected_Action_Reentrancy;
         when Tasking_Generic_RM_Hard_Case_Callback_Reentrancy_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Callback_Reentrancy;
         when Tasking_Generic_RM_Hard_Case_Entry_Family_Queue_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Entry_Family_Queue;
         when Tasking_Generic_RM_Hard_Case_Requeue_Select_Path_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Requeue_Select_Path;
         when Tasking_Generic_RM_Hard_Case_Accept_Body_Effect_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Accept_Body_Effect;
         when Tasking_Generic_RM_Hard_Case_Abort_Finalization_Ordering_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Abort_Finalization_Ordering;
         when Tasking_Generic_RM_Hard_Case_Task_Termination_Ordering_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Task_Termination_Ordering;
         when Tasking_Generic_RM_Hard_Case_Protected_Shared_State_Access_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Protected_Shared_State_Access;
         when Tasking_Generic_RM_Hard_Case_Abstract_State_Backed_Task_Effect_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Abstract_State_Backed_Task_Effect;
         when Tasking_Generic_RM_Hard_Case_Generic_Task_Protected_Body_Effect_Blocker => return Tasking_Generic_RM_Hard_Case_Blocker_Generic_Task_Protected_Body_Effect;
         when Tasking_Generic_RM_Hard_Case_Source_Fingerprint_Mismatch => return Tasking_Generic_RM_Hard_Case_Blocker_Source_Fingerprint;
         when Tasking_Generic_RM_Hard_Case_Substitution_Fingerprint_Mismatch => return Tasking_Generic_RM_Hard_Case_Blocker_Substitution_Fingerprint;
         when Tasking_Generic_RM_Hard_Case_Multiple_Blockers => return Tasking_Generic_RM_Hard_Case_Blocker_Multiple;
         when Tasking_Generic_RM_Hard_Case_Indeterminate => return Tasking_Generic_RM_Hard_Case_Blocker_Indeterminate;
         when others => return Tasking_Generic_RM_Hard_Case_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Tasking_Generic_RM_Hard_Case_Context) return Natural is
      Result : Natural := 0;
   begin
      if C.Requires_Previous_Tasking and then (C.Previous_Tasking_Row = Previous.No_Tasking_Generic_Final_Row or else not Previous.Is_Accepted (C.Previous_Tasking_Status)) then Result := Result + 1; end if;
      if C.Requires_Representation_RM_Hard_Case and then (C.Representation_RM_Hard_Case_Row = Representation_Hard_Cases.No_Representation_Generic_RM_Hard_Case or else not Representation_Hard_Cases.Is_Accepted (C.Representation_RM_Hard_Case_Status)) then Result := Result + 1; end if;
      if C.Requires_Overload_RM_Edge and then (C.Overload_RM_Edge_Row = Overload_Edges.No_Overload_Generic_RM_Edge_Completion or else not Overload_Edges.Is_Accepted (C.Overload_RM_Edge_Status)) then Result := Result + 1; end if;
      if C.Requires_Stabilized_Closure and then (C.Stabilized_Closure_Row = Closure.No_Generic_Shared_State_Final_Stabilized_Closure or else not Closure_Accepted (C.Stabilized_Closure_Status)) then Result := Result + 1; end if;
      if C.Protected_Action_Reentrancy_Blocker then Result := Result + 1; end if;
      if C.Callback_Reentrancy_Blocker then Result := Result + 1; end if;
      if C.Entry_Family_Queue_Blocker then Result := Result + 1; end if;
      if C.Requeue_Select_Path_Blocker then Result := Result + 1; end if;
      if C.Accept_Body_Effect_Blocker then Result := Result + 1; end if;
      if C.Abort_Finalization_Ordering_Blocker then Result := Result + 1; end if;
      if C.Task_Termination_Ordering_Blocker then Result := Result + 1; end if;
      if C.Protected_Shared_State_Access_Blocker then Result := Result + 1; end if;
      if C.Abstract_State_Backed_Task_Effect_Blocker then Result := Result + 1; end if;
      if C.Generic_Task_Protected_Body_Effect_Blocker then Result := Result + 1; end if;
      if C.Expected_Source_Fingerprint /= 0 and then C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Result := Result + 1; end if;
      if C.Expected_Substitution_Fingerprint /= 0 and then C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Result := Result + 1; end if;
      return Result;
   end Local_Blocker_Count;

   function Classify (C : Tasking_Generic_RM_Hard_Case_Context) return Tasking_Generic_RM_Hard_Case_Status is
      Blockers : constant Natural := Local_Blocker_Count (C);
   begin
      if C.Kind = Tasking_Generic_RM_Hard_Case_Unknown then return Tasking_Generic_RM_Hard_Case_Indeterminate;
      elsif Blockers > 1 then return Tasking_Generic_RM_Hard_Case_Multiple_Blockers;
      elsif C.Protected_Action_Reentrancy_Blocker then return Tasking_Generic_RM_Hard_Case_Protected_Action_Reentrancy_Blocker;
      elsif C.Callback_Reentrancy_Blocker then return Tasking_Generic_RM_Hard_Case_Callback_Reentrancy_Blocker;
      elsif C.Entry_Family_Queue_Blocker then return Tasking_Generic_RM_Hard_Case_Entry_Family_Queue_Blocker;
      elsif C.Requeue_Select_Path_Blocker then return Tasking_Generic_RM_Hard_Case_Requeue_Select_Path_Blocker;
      elsif C.Accept_Body_Effect_Blocker then return Tasking_Generic_RM_Hard_Case_Accept_Body_Effect_Blocker;
      elsif C.Abort_Finalization_Ordering_Blocker then return Tasking_Generic_RM_Hard_Case_Abort_Finalization_Ordering_Blocker;
      elsif C.Task_Termination_Ordering_Blocker then return Tasking_Generic_RM_Hard_Case_Task_Termination_Ordering_Blocker;
      elsif C.Protected_Shared_State_Access_Blocker then return Tasking_Generic_RM_Hard_Case_Protected_Shared_State_Access_Blocker;
      elsif C.Abstract_State_Backed_Task_Effect_Blocker then return Tasking_Generic_RM_Hard_Case_Abstract_State_Backed_Task_Effect_Blocker;
      elsif C.Generic_Task_Protected_Body_Effect_Blocker then return Tasking_Generic_RM_Hard_Case_Generic_Task_Protected_Body_Effect_Blocker;
      elsif C.Expected_Source_Fingerprint /= 0 and then C.Source_Fingerprint /= C.Expected_Source_Fingerprint then return Tasking_Generic_RM_Hard_Case_Source_Fingerprint_Mismatch;
      elsif C.Expected_Substitution_Fingerprint /= 0 and then C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then return Tasking_Generic_RM_Hard_Case_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Previous_Tasking and then C.Previous_Tasking_Row = Previous.No_Tasking_Generic_Final_Row then return Tasking_Generic_RM_Hard_Case_Missing_Previous_Tasking_Row;
      elsif C.Requires_Previous_Tasking and then not Previous.Is_Accepted (C.Previous_Tasking_Status) then return Tasking_Generic_RM_Hard_Case_Previous_Tasking_Blocker;
      elsif C.Requires_Representation_RM_Hard_Case and then C.Representation_RM_Hard_Case_Row = Representation_Hard_Cases.No_Representation_Generic_RM_Hard_Case then return Tasking_Generic_RM_Hard_Case_Missing_Representation_RM_Hard_Case_Row;
      elsif C.Requires_Representation_RM_Hard_Case and then not Representation_Hard_Cases.Is_Accepted (C.Representation_RM_Hard_Case_Status) then return Tasking_Generic_RM_Hard_Case_Representation_RM_Hard_Case_Blocker;
      elsif C.Requires_Overload_RM_Edge and then C.Overload_RM_Edge_Row = Overload_Edges.No_Overload_Generic_RM_Edge_Completion then return Tasking_Generic_RM_Hard_Case_Missing_Overload_RM_Edge_Row;
      elsif C.Requires_Overload_RM_Edge and then not Overload_Edges.Is_Accepted (C.Overload_RM_Edge_Status) then return Tasking_Generic_RM_Hard_Case_Overload_RM_Edge_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Generic_Shared_State_Final_Stabilized_Closure then return Tasking_Generic_RM_Hard_Case_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then return Tasking_Generic_RM_Hard_Case_Stabilized_Closure_Blocker;
      else return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For (Status : Tasking_Generic_RM_Hard_Case_Status; Kind : Tasking_Generic_RM_Hard_Case_Kind; Family : Tasking_Generic_RM_Hard_Case_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String ("tasking/generic shared-state RM hard-case completion legality " & Tasking_Generic_RM_Hard_Case_Status'Image (Status) & " kind=" & Tasking_Generic_RM_Hard_Case_Kind'Image (Kind) & " blocker=" & Tasking_Generic_RM_Hard_Case_Blocker_Family'Image (Family));
   end Message_For;

   function Compute_Row_Fingerprint (Row : Tasking_Generic_RM_Hard_Case_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context)); H := Mix (H, Tasking_Generic_RM_Hard_Case_Kind'Pos (Row.Kind) + 1); H := Mix (H, Tasking_Generic_RM_Hard_Case_Status'Pos (Row.Status) + 1); H := Mix (H, Tasking_Generic_RM_Hard_Case_Blocker_Family'Pos (Row.Blocker_Family) + 1); H := Mix (H, Natural (Row.Node)); H := Mix (H, Row.Blocker_Count); H := Mix (H, Row.Source_Fingerprint); H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop H := Mix (H, Character'Pos (C)); end loop;
      return H;
   end Compute_Row_Fingerprint;

   function Make_Row (C : Tasking_Generic_RM_Hard_Case_Context; Index : Positive) return Tasking_Generic_RM_Hard_Case_Row is
      Status : constant Tasking_Generic_RM_Hard_Case_Status := Classify (C);
      Family : constant Tasking_Generic_RM_Hard_Case_Blocker_Family := Family_For (Status);
      Row : Tasking_Generic_RM_Hard_Case_Row;
   begin
      Row.Id := Tasking_Generic_RM_Hard_Case_Id (Index); Row.Context := C.Id; Row.Kind := C.Kind; Row.Status := Status; Row.Blocker_Family := Family; Row.Node := C.Node; Row.Operation_Name := C.Operation_Name; Row.State_Name := C.State_Name; Row.Generic_Unit_Name := C.Generic_Unit_Name; Row.Instance_Name := C.Instance_Name; Row.Accepted := Is_Accepted (Status); Row.Blocked := Is_Blocked (Status); Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status); Row.Blocker_Count := Local_Blocker_Count (C); if Row.Blocked and then Row.Blocker_Count = 0 then Row.Blocker_Count := 1; end if; Row.Source_Fingerprint := C.Source_Fingerprint; Row.Substitution_Fingerprint := C.Substitution_Fingerprint; Row.Start_Line := C.Start_Line; Row.Start_Column := C.Start_Column; Row.End_Line := C.End_Line; Row.End_Column := C.End_Column; Row.Message := Message_For (Status, C.Kind, Family); Row.Row_Fingerprint := Compute_Row_Fingerprint (Row); return Row;
   end Make_Row;

   procedure Clear (Model : in out Tasking_Generic_RM_Hard_Case_Context_Model) is begin Model.Items.Clear; Model.Fingerprint := 0; end Clear;
   procedure Add_Context (Model : in out Tasking_Generic_RM_Hard_Case_Context_Model; Context : Tasking_Generic_RM_Hard_Case_Context) is
      H : Natural := Model.Fingerprint;
   begin
      Model.Items.Append (Context); H := Mix (H, Natural (Context.Id)); H := Mix (H, Tasking_Generic_RM_Hard_Case_Kind'Pos (Context.Kind) + 1); H := Mix (H, Natural (Context.Node)); H := Mix (H, Context.Source_Fingerprint); H := Mix (H, Context.Substitution_Fingerprint); Model.Fingerprint := H;
   end Add_Context;
   function Context_Count (Model : Tasking_Generic_RM_Hard_Case_Context_Model) return Natural is begin return Natural (Model.Items.Length); end Context_Count;
   function Context_At (Model : Tasking_Generic_RM_Hard_Case_Context_Model; Index : Positive) return Tasking_Generic_RM_Hard_Case_Context is begin return Model.Items.Element (Index); end Context_At;
   function Context_Fingerprint (Model : Tasking_Generic_RM_Hard_Case_Context_Model) return Natural is begin return Model.Fingerprint; end Context_Fingerprint;

   function Build (Contexts : Tasking_Generic_RM_Hard_Case_Context_Model) return Tasking_Generic_RM_Hard_Case_Model is
      Result : Tasking_Generic_RM_Hard_Case_Model; H : Natural := Contexts.Fingerprint; I : Positive := 1;
   begin
      for C of Contexts.Items loop
         declare Row : constant Tasking_Generic_RM_Hard_Case_Row := Make_Row (C, I); begin Result.Rows.Append (Row); H := Mix (H, Row.Row_Fingerprint); end;
         I := I + 1;
      end loop;
      Result.Fingerprint := H; return Result;
   end Build;
   function Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural is begin return Natural (Model.Rows.Length); end Count;
   function Row_At (Model : Tasking_Generic_RM_Hard_Case_Model; Index : Positive) return Tasking_Generic_RM_Hard_Case_Row is begin return Model.Rows.Element (Index); end Row_At;
   function Query_Count (Set : Tasking_Generic_RM_Hard_Case_Set) return Natural is begin return Natural (Set.Rows.Length); end Query_Count;
   function Query_At (Set : Tasking_Generic_RM_Hard_Case_Set; Index : Positive) return Tasking_Generic_RM_Hard_Case_Row is begin return Set.Rows.Element (Index); end Query_At;
   function Query_Status (Model : Tasking_Generic_RM_Hard_Case_Model; Status : Tasking_Generic_RM_Hard_Case_Status) return Tasking_Generic_RM_Hard_Case_Set is Result : Tasking_Generic_RM_Hard_Case_Set; begin for Row of Model.Rows loop if Row.Status = Status then Result.Rows.Append (Row); end if; end loop; return Result; end Query_Status;
   function Query_Blocker_Family (Model : Tasking_Generic_RM_Hard_Case_Model; Family : Tasking_Generic_RM_Hard_Case_Blocker_Family) return Tasking_Generic_RM_Hard_Case_Set is Result : Tasking_Generic_RM_Hard_Case_Set; begin for Row of Model.Rows loop if Row.Blocker_Family = Family then Result.Rows.Append (Row); end if; end loop; return Result; end Query_Blocker_Family;
   function Find_By_Node (Model : Tasking_Generic_RM_Hard_Case_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Generic_RM_Hard_Case_Set is Result : Tasking_Generic_RM_Hard_Case_Set; begin for Row of Model.Rows loop if Row.Node = Node then Result.Rows.Append (Row); end if; end loop; return Result; end Find_By_Node;
   function Find_By_Source_Fingerprint (Model : Tasking_Generic_RM_Hard_Case_Model; Source_Fingerprint : Natural) return Tasking_Generic_RM_Hard_Case_Set is Result : Tasking_Generic_RM_Hard_Case_Set; begin for Row of Model.Rows loop if Row.Source_Fingerprint = Source_Fingerprint then Result.Rows.Append (Row); end if; end loop; return Result; end Find_By_Source_Fingerprint;
   function Count_By_Status (Model : Tasking_Generic_RM_Hard_Case_Model; Status : Tasking_Generic_RM_Hard_Case_Status) return Natural is begin return Query_Count (Query_Status (Model, Status)); end Count_By_Status;
   function Count_By_Blocker_Family (Model : Tasking_Generic_RM_Hard_Case_Model; Family : Tasking_Generic_RM_Hard_Case_Blocker_Family) return Natural is begin return Query_Count (Query_Blocker_Family (Model, Family)); end Count_By_Blocker_Family;
   function Accepted_Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural is N : Natural := 0; begin for Row of Model.Rows loop if Row.Accepted then N := N + 1; end if; end loop; return N; end Accepted_Count;
   function Blocked_Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural is N : Natural := 0; begin for Row of Model.Rows loop if Row.Blocked then N := N + 1; end if; end loop; return N; end Blocked_Count;
   function Indeterminate_Count (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural is N : Natural := 0; begin for Row of Model.Rows loop if Is_Indeterminate (Row.Status) then N := N + 1; end if; end loop; return N; end Indeterminate_Count;
   function Stable_Fingerprint (Model : Tasking_Generic_RM_Hard_Case_Model) return Natural is begin return Model.Fingerprint; end Stable_Fingerprint;

end Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality;
