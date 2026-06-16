with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality is

   pragma Suppress (Overflow_Check);

   use type Access_Generic.Accessibility_Generic_Final_Row_Id;
   use type Closure.Shared_State_Stabilized_Closure_Id;
   use type Closure.Shared_State_Stabilized_Closure_Status;
   use type Cross_Generic.Cross_Unit_Generic_Final_Row_Id;
   use type Disc_Generic.Discriminant_Generic_Final_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elab_Generic.Elaboration_Generic_Final_Row_Id;
   use type Exception_Final.Exception_Legality_Id;
   use type Generic_Replay.Generic_Abstract_Replay_Row_Id;
   use type Overload_Generic.Overload_Generic_Final_Row_Id;
   use type Rep_Generic.Representation_Generic_Final_Row_Id;
   use type Tasking_Generic.Tasking_Generic_Final_Row_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right * 17 + 23) mod 2_147_483_647;
   end Mix;

   function Exception_Status_Is_Legal (Status : Exception_Final.Exception_Legality_Status) return Boolean is
   begin
      case Status is
         when Exception_Final.Exception_Legality_Legal_Raise_Statement |
              Exception_Final.Exception_Legality_Legal_Raise_Expression |
              Exception_Final.Exception_Legality_Legal_Reraise |
              Exception_Final.Exception_Legality_Legal_Handler |
              Exception_Final.Exception_Legality_Legal_Exception_Renaming |
              Exception_Final.Exception_Legality_Legal_Propagation |
              Exception_Final.Exception_Legality_Legal_Finalization |
              Exception_Final.Exception_Legality_Legal_No_Return =>
            return True;
         when others =>
            return False;
      end case;
   end Exception_Status_Is_Legal;

   function Is_Accepted (Status : Exception_Generic_Final_Status) return Boolean is
   begin
      return Status in Exception_Generic_Final_Legal_Raise_Statement_Accepted ..
                       Exception_Generic_Final_Legal_Cross_Unit_Finalization_Accepted;
   end Is_Accepted;

   function Is_Blocked (Status : Exception_Generic_Final_Status) return Boolean is
   begin
      return Status in Exception_Generic_Final_Missing_Exception_Finalization_Row ..
                       Exception_Generic_Final_Indeterminate;
   end Is_Blocked;

   function Blocks_Downstream (Status : Exception_Generic_Final_Status) return Boolean is
   begin
      return Is_Blocked (Status);
   end Blocks_Downstream;

   function Accepted_For (Kind : Exception_Generic_Final_Kind) return Exception_Generic_Final_Status is
   begin
      case Kind is
         when Exception_Generic_Final_Raise_Statement => return Exception_Generic_Final_Legal_Raise_Statement_Accepted;
         when Exception_Generic_Final_Raise_Expression => return Exception_Generic_Final_Legal_Raise_Expression_Accepted;
         when Exception_Generic_Final_Reraise => return Exception_Generic_Final_Legal_Reraise_Accepted;
         when Exception_Generic_Final_Handler => return Exception_Generic_Final_Legal_Handler_Accepted;
         when Exception_Generic_Final_Exception_Propagation => return Exception_Generic_Final_Legal_Exception_Propagation_Accepted;
         when Exception_Generic_Final_Controlled_Initialize => return Exception_Generic_Final_Legal_Controlled_Initialize_Accepted;
         when Exception_Generic_Final_Controlled_Adjust => return Exception_Generic_Final_Legal_Controlled_Adjust_Accepted;
         when Exception_Generic_Final_Controlled_Finalize => return Exception_Generic_Final_Legal_Controlled_Finalize_Accepted;
         when Exception_Generic_Final_Master_Finalization => return Exception_Generic_Final_Legal_Master_Finalization_Accepted;
         when Exception_Generic_Final_Cleanup_Action => return Exception_Generic_Final_Legal_Cleanup_Action_Accepted;
         when Exception_Generic_Final_Abort_Deferred_Finalization => return Exception_Generic_Final_Legal_Abort_Deferred_Finalization_Accepted;
         when Exception_Generic_Final_Task_Termination => return Exception_Generic_Final_Legal_Task_Termination_Accepted;
         when Exception_Generic_Final_No_Return => return Exception_Generic_Final_Legal_No_Return_Accepted;
         when Exception_Generic_Final_Generic_Replay => return Exception_Generic_Final_Legal_Generic_Replay_Accepted;
         when Exception_Generic_Final_Cross_Unit_Finalization => return Exception_Generic_Final_Legal_Cross_Unit_Finalization_Accepted;
         when Exception_Generic_Final_Unknown => return Exception_Generic_Final_Indeterminate;
      end case;
   end Accepted_For;

   function Family_For (Status : Exception_Generic_Final_Status) return Exception_Generic_Final_Blocker_Family is
   begin
      case Status is
         when Exception_Generic_Final_Not_Checked |
              Exception_Generic_Final_Legal_Raise_Statement_Accepted ..
              Exception_Generic_Final_Legal_Cross_Unit_Finalization_Accepted =>
            return Exception_Generic_Final_Blocker_None;
         when Exception_Generic_Final_Missing_Exception_Finalization_Row |
              Exception_Generic_Final_Exception_Finalization_Blocker =>
            return Exception_Generic_Final_Blocker_Exception_Finalization;
         when Exception_Generic_Final_Missing_Cross_Unit_Generic_Row |
              Exception_Generic_Final_Cross_Unit_Generic_Blocker =>
            return Exception_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State;
         when Exception_Generic_Final_Missing_Elaboration_Generic_Row |
              Exception_Generic_Final_Elaboration_Generic_Blocker =>
            return Exception_Generic_Final_Blocker_Elaboration_Generic_Shared_State;
         when Exception_Generic_Final_Missing_Generic_Replay_Row |
              Exception_Generic_Final_Generic_Replay_Blocker =>
            return Exception_Generic_Final_Blocker_Generic_Abstract_Replay;
         when Exception_Generic_Final_Missing_Overload_Generic_Row |
              Exception_Generic_Final_Overload_Generic_Blocker =>
            return Exception_Generic_Final_Blocker_Overload_Generic_Shared_State;
         when Exception_Generic_Final_Missing_Representation_Generic_Row |
              Exception_Generic_Final_Representation_Generic_Blocker =>
            return Exception_Generic_Final_Blocker_Representation_Generic_Shared_State;
         when Exception_Generic_Final_Missing_Tasking_Generic_Row |
              Exception_Generic_Final_Tasking_Generic_Blocker =>
            return Exception_Generic_Final_Blocker_Tasking_Generic_Shared_State;
         when Exception_Generic_Final_Missing_Accessibility_Generic_Row |
              Exception_Generic_Final_Accessibility_Generic_Blocker =>
            return Exception_Generic_Final_Blocker_Accessibility_Generic_Shared_State;
         when Exception_Generic_Final_Missing_Discriminant_Generic_Row |
              Exception_Generic_Final_Discriminant_Generic_Blocker =>
            return Exception_Generic_Final_Blocker_Discriminant_Generic_Shared_State;
         when Exception_Generic_Final_Missing_Stabilized_Closure_Row |
              Exception_Generic_Final_Stabilized_Closure_Blocker =>
            return Exception_Generic_Final_Blocker_Stabilized_Shared_State_Closure;
         when Exception_Generic_Final_Exception_Propagation_Blocker => return Exception_Generic_Final_Blocker_Exception_Propagation;
         when Exception_Generic_Final_Handler_Coverage_Blocker => return Exception_Generic_Final_Blocker_Handler_Coverage;
         when Exception_Generic_Final_Finalization_Primitive_Blocker => return Exception_Generic_Final_Blocker_Finalization_Primitive;
         when Exception_Generic_Final_Finalization_Order_Blocker => return Exception_Generic_Final_Blocker_Finalization_Order;
         when Exception_Generic_Final_Abort_Finalization_Blocker => return Exception_Generic_Final_Blocker_Abort_Finalization;
         when Exception_Generic_Final_Task_Termination_Blocker => return Exception_Generic_Final_Blocker_Task_Termination;
         when Exception_Generic_Final_No_Return_Blocker => return Exception_Generic_Final_Blocker_No_Return;
         when Exception_Generic_Final_Accessibility_Master_Blocker => return Exception_Generic_Final_Blocker_Accessibility_Master;
         when Exception_Generic_Final_Discriminant_Finalization_Blocker => return Exception_Generic_Final_Blocker_Discriminant_Finalization;
         when Exception_Generic_Final_Representation_Finalization_Blocker => return Exception_Generic_Final_Blocker_Representation_Finalization;
         when Exception_Generic_Final_Source_Fingerprint_Mismatch => return Exception_Generic_Final_Blocker_Source_Fingerprint;
         when Exception_Generic_Final_Substitution_Fingerprint_Mismatch => return Exception_Generic_Final_Blocker_Substitution_Fingerprint;
         when Exception_Generic_Final_Multiple_Blockers => return Exception_Generic_Final_Blocker_Multiple;
         when Exception_Generic_Final_Indeterminate => return Exception_Generic_Final_Blocker_Indeterminate;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Exception_Generic_Final_Context) return Natural is
      N : Natural := 0;
   begin
      if C.Exception_Propagation_Blocker then N := N + 1; end if;
      if C.Handler_Coverage_Blocker then N := N + 1; end if;
      if C.Finalization_Primitive_Blocker then N := N + 1; end if;
      if C.Finalization_Order_Blocker then N := N + 1; end if;
      if C.Abort_Finalization_Blocker then N := N + 1; end if;
      if C.Task_Termination_Blocker then N := N + 1; end if;
      if C.No_Return_Blocker then N := N + 1; end if;
      if C.Accessibility_Master_Blocker then N := N + 1; end if;
      if C.Discriminant_Finalization_Blocker then N := N + 1; end if;
      if C.Representation_Finalization_Blocker then N := N + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then N := N + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then N := N + 1; end if;
      return N;
   end Local_Blocker_Count;

   function Classify (C : Exception_Generic_Final_Context) return Exception_Generic_Final_Status is
      Local_N : constant Natural := Local_Blocker_Count (C);
   begin
      if Local_N > 1 then return Exception_Generic_Final_Multiple_Blockers;
      elsif C.Exception_Propagation_Blocker then return Exception_Generic_Final_Exception_Propagation_Blocker;
      elsif C.Handler_Coverage_Blocker then return Exception_Generic_Final_Handler_Coverage_Blocker;
      elsif C.Finalization_Primitive_Blocker then return Exception_Generic_Final_Finalization_Primitive_Blocker;
      elsif C.Finalization_Order_Blocker then return Exception_Generic_Final_Finalization_Order_Blocker;
      elsif C.Abort_Finalization_Blocker then return Exception_Generic_Final_Abort_Finalization_Blocker;
      elsif C.Task_Termination_Blocker then return Exception_Generic_Final_Task_Termination_Blocker;
      elsif C.No_Return_Blocker then return Exception_Generic_Final_No_Return_Blocker;
      elsif C.Accessibility_Master_Blocker then return Exception_Generic_Final_Accessibility_Master_Blocker;
      elsif C.Discriminant_Finalization_Blocker then return Exception_Generic_Final_Discriminant_Finalization_Blocker;
      elsif C.Representation_Finalization_Blocker then return Exception_Generic_Final_Representation_Finalization_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then return Exception_Generic_Final_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then return Exception_Generic_Final_Substitution_Fingerprint_Mismatch;
      elsif C.Exception_Final_Row = Exception_Final.No_Exception_Legality then return Exception_Generic_Final_Missing_Exception_Finalization_Row;
      elsif not Exception_Status_Is_Legal (C.Exception_Final_Status) then return Exception_Generic_Final_Exception_Finalization_Blocker;
      elsif C.Cross_Generic_Row = Cross_Generic.No_Cross_Unit_Generic_Final_Row then return Exception_Generic_Final_Missing_Cross_Unit_Generic_Row;
      elsif not Cross_Generic.Is_Accepted (C.Cross_Generic_Status) then return Exception_Generic_Final_Cross_Unit_Generic_Blocker;
      elsif C.Requires_Elaboration_Generic and then C.Elaboration_Generic_Row = Elab_Generic.No_Elaboration_Generic_Final_Row then return Exception_Generic_Final_Missing_Elaboration_Generic_Row;
      elsif C.Requires_Elaboration_Generic and then not Elab_Generic.Is_Accepted (C.Elaboration_Generic_Status) then return Exception_Generic_Final_Elaboration_Generic_Blocker;
      elsif C.Requires_Generic_Replay and then C.Generic_Replay_Row = Generic_Replay.No_Generic_Abstract_Replay_Row then return Exception_Generic_Final_Missing_Generic_Replay_Row;
      elsif C.Requires_Generic_Replay and then not Generic_Replay.Is_Accepted (C.Generic_Replay_Status) then return Exception_Generic_Final_Generic_Replay_Blocker;
      elsif C.Requires_Overload_Generic and then C.Overload_Generic_Row = Overload_Generic.No_Overload_Generic_Final_Row then return Exception_Generic_Final_Missing_Overload_Generic_Row;
      elsif C.Requires_Overload_Generic and then not Overload_Generic.Is_Accepted (C.Overload_Generic_Status) then return Exception_Generic_Final_Overload_Generic_Blocker;
      elsif C.Requires_Representation_Generic and then C.Representation_Generic_Row = Rep_Generic.No_Representation_Generic_Final_Row then return Exception_Generic_Final_Missing_Representation_Generic_Row;
      elsif C.Requires_Representation_Generic and then not Rep_Generic.Is_Accepted (C.Representation_Generic_Status) then return Exception_Generic_Final_Representation_Generic_Blocker;
      elsif C.Requires_Tasking_Generic and then C.Tasking_Generic_Row = Tasking_Generic.No_Tasking_Generic_Final_Row then return Exception_Generic_Final_Missing_Tasking_Generic_Row;
      elsif C.Requires_Tasking_Generic and then not Tasking_Generic.Is_Accepted (C.Tasking_Generic_Status) then return Exception_Generic_Final_Tasking_Generic_Blocker;
      elsif C.Requires_Accessibility_Generic and then C.Accessibility_Generic_Row = Access_Generic.No_Accessibility_Generic_Final_Row then return Exception_Generic_Final_Missing_Accessibility_Generic_Row;
      elsif C.Requires_Accessibility_Generic and then not Access_Generic.Is_Accepted (C.Accessibility_Generic_Status) then return Exception_Generic_Final_Accessibility_Generic_Blocker;
      elsif C.Requires_Discriminant_Generic and then C.Discriminant_Generic_Row = Disc_Generic.No_Discriminant_Generic_Final_Row then return Exception_Generic_Final_Missing_Discriminant_Generic_Row;
      elsif C.Requires_Discriminant_Generic and then not Disc_Generic.Is_Accepted (C.Discriminant_Generic_Status) then return Exception_Generic_Final_Discriminant_Generic_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_Shared_State_Stabilized_Closure then return Exception_Generic_Final_Missing_Stabilized_Closure_Row;
      elsif C.Requires_Stabilized_Closure and then not (C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Current or else C.Stabilized_Closure_Status = Closure.Shared_State_Stabilized_Closure_Accepted_Not_Required) then return Exception_Generic_Final_Stabilized_Closure_Blocker;
      else return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Row_Fingerprint (Row : Exception_Generic_Final_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Exception_Generic_Final_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Exception_Generic_Final_Status'Pos (Row.Status) + 1);
      H := Mix (H, Exception_Generic_Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for Ch of Text loop H := Mix (H, Character'Pos (Ch)); end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Exception_Generic_Final_Context) return Exception_Generic_Final_Row is
      Status : constant Exception_Generic_Final_Status := Classify (C);
      Family : constant Exception_Generic_Final_Blocker_Family := Family_For (Status);
      Row : Exception_Generic_Final_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Exception_Name := C.Exception_Name;
      Row.Object_Name := C.Object_Name;
      Row.Type_Name := C.Type_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Blocks_Downstream (Status);
      Row.Blocker_Count := Local_Blocker_Count (C);
      if Row.Blocked and then Row.Blocker_Count = 0 then Row.Blocker_Count := 1; end if;
      Row.Start_Line := C.Start_Line; Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line; Row.End_Column := C.End_Column;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Message := To_Unbounded_String
        ("exception/finalization generic shared-state final legality " &
         Exception_Generic_Final_Status'Image (Status) &
         " kind=" & Exception_Generic_Final_Kind'Image (C.Kind) &
         " blocker=" & Exception_Generic_Final_Blocker_Family'Image (Family));
      Row.Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Build_Row;

   procedure Clear (Model : in out Exception_Generic_Final_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Exception_Generic_Final_Context_Model; Info : Exception_Generic_Final_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Exception_Generic_Final_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Build (Contexts : Exception_Generic_Final_Context_Model) return Exception_Generic_Final_Model is
      Result : Exception_Generic_Final_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Exception_Generic_Final_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Exception_Generic_Final_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Exception_Generic_Final_Model; Index : Positive) return Exception_Generic_Final_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Accepted_Count (Model : Exception_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Accepted then N := N + 1; end if; end loop;
      return N;
   end Accepted_Count;

   function Blocked_Count (Model : Exception_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Blocked then N := N + 1; end if; end loop;
      return N;
   end Blocked_Count;

   function Indeterminate_Count (Model : Exception_Generic_Final_Model) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Status = Exception_Generic_Final_Indeterminate then N := N + 1; end if; end loop;
      return N;
   end Indeterminate_Count;

   function Count_By_Status (Model : Exception_Generic_Final_Model; Status : Exception_Generic_Final_Status) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Status = Status then N := N + 1; end if; end loop;
      return N;
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Exception_Generic_Final_Model; Family : Exception_Generic_Final_Blocker_Family) return Natural is
      N : Natural := 0;
   begin
      for R of Model.Rows loop if R.Blocker_Family = Family then N := N + 1; end if; end loop;
      return N;
   end Count_By_Blocker_Family;

   function Find_By_Node (Model : Exception_Generic_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Exception_Generic_Final_Set is
      Result : Exception_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Node = Node then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Exception_Generic_Final_Model; Fingerprint : Natural) return Exception_Generic_Final_Set is
      Result : Exception_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Source_Fingerprint = Fingerprint then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Query_Blocker_Family (Model : Exception_Generic_Final_Model; Family : Exception_Generic_Final_Blocker_Family) return Exception_Generic_Final_Set is
      Result : Exception_Generic_Final_Set;
   begin
      for R of Model.Rows loop if R.Blocker_Family = Family then Result.Rows.Append (R); end if; end loop;
      return Result;
   end Query_Blocker_Family;

   function Query_Count (Set : Exception_Generic_Final_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_Row_At (Set : Exception_Generic_Final_Set; Index : Positive) return Exception_Generic_Final_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_Row_At;

   function Stable_Fingerprint (Model : Exception_Generic_Final_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
