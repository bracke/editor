with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality is

   use type Accessibility_RM.Accessibility_RM_Completion_Row_Id;
   use type AST_Repair.Coverage_Proven_AST_Repair_Id;
   use type Cross_RM.Cross_Unit_RM_Completion_Closure_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elaboration_RM.Elaboration_RM_Completion_Row_Id;
   use type Overload_RM.Overload_Generic_RM_Edge_Completion_Id;
   use type Prior_Exception.Exception_Generic_Final_Row_Id;
   use type Representation_RM.Representation_Generic_RM_Hard_Case_Id;
   use type Tasking_RM.Tasking_Generic_RM_Hard_Case_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 17) mod 2_147_483_647;
   end Mix;

   function Accepted_For (Kind : Exception_RM_Completion_Kind) return Exception_RM_Completion_Status is
   begin
      case Kind is
         when Exception_RM_Completion_Raise_Statement => return Exception_RM_Completion_Legal_Raise_Statement_Accepted;
         when Exception_RM_Completion_Raise_Expression => return Exception_RM_Completion_Legal_Raise_Expression_Accepted;
         when Exception_RM_Completion_Reraise => return Exception_RM_Completion_Legal_Reraise_Accepted;
         when Exception_RM_Completion_Handler_Choice => return Exception_RM_Completion_Legal_Handler_Choice_Accepted;
         when Exception_RM_Completion_Exception_Propagation => return Exception_RM_Completion_Legal_Exception_Propagation_Accepted;
         when Exception_RM_Completion_Controlled_Initialize => return Exception_RM_Completion_Legal_Controlled_Initialize_Accepted;
         when Exception_RM_Completion_Controlled_Adjust => return Exception_RM_Completion_Legal_Controlled_Adjust_Accepted;
         when Exception_RM_Completion_Controlled_Finalize => return Exception_RM_Completion_Legal_Controlled_Finalize_Accepted;
         when Exception_RM_Completion_Master_Finalization => return Exception_RM_Completion_Legal_Master_Finalization_Accepted;
         when Exception_RM_Completion_Cleanup_Action => return Exception_RM_Completion_Legal_Cleanup_Action_Accepted;
         when Exception_RM_Completion_Abort_Deferred_Finalization => return Exception_RM_Completion_Legal_Abort_Deferred_Finalization_Accepted;
         when Exception_RM_Completion_Task_Termination => return Exception_RM_Completion_Legal_Task_Termination_Accepted;
         when Exception_RM_Completion_No_Return_Path => return Exception_RM_Completion_Legal_No_Return_Path_Accepted;
         when Exception_RM_Completion_Generic_Replay_Finalization => return Exception_RM_Completion_Legal_Generic_Replay_Finalization_Accepted;
         when Exception_RM_Completion_Cross_Unit_Finalization => return Exception_RM_Completion_Legal_Cross_Unit_Finalization_Accepted;
         when Exception_RM_Completion_Dispatching_Exception_Effect => return Exception_RM_Completion_Legal_Dispatching_Exception_Effect_Accepted;
         when Exception_RM_Completion_Renamed_Handler_Source => return Exception_RM_Completion_Legal_Renamed_Handler_Source_Accepted;
         when Exception_RM_Completion_Predicate_Check_Finalization => return Exception_RM_Completion_Legal_Predicate_Check_Finalization_Accepted;
         when Exception_RM_Completion_Dataflow_Cleanup_Edge => return Exception_RM_Completion_Legal_Dataflow_Cleanup_Edge_Accepted;
         when Exception_RM_Completion_Accessibility_Master_Finalization => return Exception_RM_Completion_Legal_Accessibility_Master_Finalization_Accepted;
         when Exception_RM_Completion_Unknown => return Exception_RM_Completion_Indeterminate;
      end case;
   end Accepted_For;

   function Is_Accepted (Status : Exception_RM_Completion_Status) return Boolean is
   begin
      case Status is
         when Exception_RM_Completion_Legal_Raise_Statement_Accepted
            | Exception_RM_Completion_Legal_Raise_Expression_Accepted
            | Exception_RM_Completion_Legal_Reraise_Accepted
            | Exception_RM_Completion_Legal_Handler_Choice_Accepted
            | Exception_RM_Completion_Legal_Exception_Propagation_Accepted
            | Exception_RM_Completion_Legal_Controlled_Initialize_Accepted
            | Exception_RM_Completion_Legal_Controlled_Adjust_Accepted
            | Exception_RM_Completion_Legal_Controlled_Finalize_Accepted
            | Exception_RM_Completion_Legal_Master_Finalization_Accepted
            | Exception_RM_Completion_Legal_Cleanup_Action_Accepted
            | Exception_RM_Completion_Legal_Abort_Deferred_Finalization_Accepted
            | Exception_RM_Completion_Legal_Task_Termination_Accepted
            | Exception_RM_Completion_Legal_No_Return_Path_Accepted
            | Exception_RM_Completion_Legal_Generic_Replay_Finalization_Accepted
            | Exception_RM_Completion_Legal_Cross_Unit_Finalization_Accepted
            | Exception_RM_Completion_Legal_Dispatching_Exception_Effect_Accepted
            | Exception_RM_Completion_Legal_Renamed_Handler_Source_Accepted
            | Exception_RM_Completion_Legal_Predicate_Check_Finalization_Accepted
            | Exception_RM_Completion_Legal_Dataflow_Cleanup_Edge_Accepted
            | Exception_RM_Completion_Legal_Accessibility_Master_Finalization_Accepted => return True;
         when others => return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Exception_RM_Completion_Status) return Boolean is
   begin
      return Status = Exception_RM_Completion_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Exception_RM_Completion_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Exception_RM_Completion_Not_Checked
        and then not Is_Indeterminate (Status);
   end Is_Blocked;

   function Family_For (Status : Exception_RM_Completion_Status) return Exception_RM_Completion_Blocker_Family is
   begin
      case Status is
         when Exception_RM_Completion_Missing_Cross_Unit_RM_Row | Exception_RM_Completion_Cross_Unit_RM_Blocker => return Exception_RM_Completion_Blocker_Cross_Unit_RM_Completion;
         when Exception_RM_Completion_Missing_Prior_Exception_Row | Exception_RM_Completion_Prior_Exception_Blocker => return Exception_RM_Completion_Blocker_Prior_Exception_Finalization;
         when Exception_RM_Completion_Missing_Elaboration_RM_Row | Exception_RM_Completion_Elaboration_RM_Blocker => return Exception_RM_Completion_Blocker_Elaboration_RM_Completion;
         when Exception_RM_Completion_Missing_Accessibility_RM_Row | Exception_RM_Completion_Accessibility_RM_Blocker => return Exception_RM_Completion_Blocker_Accessibility_RM_Completion;
         when Exception_RM_Completion_Missing_Overload_RM_Row | Exception_RM_Completion_Overload_RM_Blocker => return Exception_RM_Completion_Blocker_Overload_RM_Completion;
         when Exception_RM_Completion_Missing_Representation_RM_Row | Exception_RM_Completion_Representation_RM_Blocker => return Exception_RM_Completion_Blocker_Representation_RM_Completion;
         when Exception_RM_Completion_Missing_Tasking_RM_Row | Exception_RM_Completion_Tasking_RM_Blocker => return Exception_RM_Completion_Blocker_Tasking_RM_Completion;
         when Exception_RM_Completion_Missing_AST_Repair_Row | Exception_RM_Completion_AST_Repair_Blocker => return Exception_RM_Completion_Blocker_AST_Repair;
         when Exception_RM_Completion_Exception_Propagation_Blocker => return Exception_RM_Completion_Blocker_Exception_Propagation;
         when Exception_RM_Completion_Handler_Resolution_Blocker => return Exception_RM_Completion_Blocker_Handler_Resolution;
         when Exception_RM_Completion_Finalize_Order_Blocker => return Exception_RM_Completion_Blocker_Finalize_Order;
         when Exception_RM_Completion_Controlled_Operation_Blocker => return Exception_RM_Completion_Blocker_Controlled_Operation;
         when Exception_RM_Completion_Abort_Deferred_Finalization_Blocker => return Exception_RM_Completion_Blocker_Abort_Deferred_Finalization;
         when Exception_RM_Completion_Task_Termination_Blocker => return Exception_RM_Completion_Blocker_Task_Termination;
         when Exception_RM_Completion_No_Return_Blocker => return Exception_RM_Completion_Blocker_No_Return;
         when Exception_RM_Completion_Cleanup_Path_Blocker => return Exception_RM_Completion_Blocker_Cleanup_Path;
         when Exception_RM_Completion_Generic_Body_Unavailable => return Exception_RM_Completion_Blocker_Generic_Body;
         when Exception_RM_Completion_View_Barrier => return Exception_RM_Completion_Blocker_View_Barrier;
         when Exception_RM_Completion_Source_Fingerprint_Mismatch => return Exception_RM_Completion_Blocker_Source_Fingerprint;
         when Exception_RM_Completion_Substitution_Fingerprint_Mismatch => return Exception_RM_Completion_Blocker_Substitution_Fingerprint;
         when Exception_RM_Completion_Multiple_Blockers => return Exception_RM_Completion_Blocker_Multiple;
         when Exception_RM_Completion_Indeterminate => return Exception_RM_Completion_Blocker_Indeterminate;
         when others => return Exception_RM_Completion_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Exception_RM_Completion_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Exception_Propagation_Error then Count := Count + 1; end if;
      if C.Handler_Resolution_Error then Count := Count + 1; end if;
      if C.Finalize_Order_Error then Count := Count + 1; end if;
      if C.Controlled_Operation_Error then Count := Count + 1; end if;
      if C.Abort_Deferred_Finalization_Error then Count := Count + 1; end if;
      if C.Task_Termination_Error then Count := Count + 1; end if;
      if C.No_Return_Error then Count := Count + 1; end if;
      if C.Cleanup_Path_Error then Count := Count + 1; end if;
      if C.Generic_Body_Unavailable then Count := Count + 1; end if;
      if C.View_Barrier then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Exception_RM_Completion_Context) return Exception_RM_Completion_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Exception_RM_Completion_Multiple_Blockers;
      elsif C.Exception_Propagation_Error then
         return Exception_RM_Completion_Exception_Propagation_Blocker;
      elsif C.Handler_Resolution_Error then
         return Exception_RM_Completion_Handler_Resolution_Blocker;
      elsif C.Finalize_Order_Error then
         return Exception_RM_Completion_Finalize_Order_Blocker;
      elsif C.Controlled_Operation_Error then
         return Exception_RM_Completion_Controlled_Operation_Blocker;
      elsif C.Abort_Deferred_Finalization_Error then
         return Exception_RM_Completion_Abort_Deferred_Finalization_Blocker;
      elsif C.Task_Termination_Error then
         return Exception_RM_Completion_Task_Termination_Blocker;
      elsif C.No_Return_Error then
         return Exception_RM_Completion_No_Return_Blocker;
      elsif C.Cleanup_Path_Error then
         return Exception_RM_Completion_Cleanup_Path_Blocker;
      elsif C.Generic_Body_Unavailable then
         return Exception_RM_Completion_Generic_Body_Unavailable;
      elsif C.View_Barrier then
         return Exception_RM_Completion_View_Barrier;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Exception_RM_Completion_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Exception_RM_Completion_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Cross_RM and then C.Cross_RM_Row = Cross_RM.No_Cross_Unit_RM_Completion_Closure then
         return Exception_RM_Completion_Missing_Cross_Unit_RM_Row;
      elsif C.Requires_Cross_RM and then not Cross_RM.Is_Accepted (C.Cross_RM_Status) then
         return Exception_RM_Completion_Cross_Unit_RM_Blocker;
      elsif C.Requires_Prior_Exception and then C.Prior_Exception_Row = Prior_Exception.No_Exception_Generic_Final_Row then
         return Exception_RM_Completion_Missing_Prior_Exception_Row;
      elsif C.Requires_Prior_Exception and then not Prior_Exception.Is_Accepted (C.Prior_Exception_Status) then
         return Exception_RM_Completion_Prior_Exception_Blocker;
      elsif C.Requires_Elaboration_RM and then C.Elaboration_RM_Row = Elaboration_RM.No_Elaboration_RM_Completion_Row then
         return Exception_RM_Completion_Missing_Elaboration_RM_Row;
      elsif C.Requires_Elaboration_RM and then not Elaboration_RM.Is_Accepted (C.Elaboration_RM_Status) then
         return Exception_RM_Completion_Elaboration_RM_Blocker;
      elsif C.Requires_Accessibility_RM and then C.Accessibility_RM_Row = Accessibility_RM.No_Accessibility_RM_Completion_Row then
         return Exception_RM_Completion_Missing_Accessibility_RM_Row;
      elsif C.Requires_Accessibility_RM and then not Accessibility_RM.Is_Accepted (C.Accessibility_RM_Status) then
         return Exception_RM_Completion_Accessibility_RM_Blocker;
      elsif C.Requires_Overload_RM and then C.Overload_RM_Row = Overload_RM.No_Overload_Generic_RM_Edge_Completion then
         return Exception_RM_Completion_Missing_Overload_RM_Row;
      elsif C.Requires_Overload_RM and then not Overload_RM.Is_Accepted (C.Overload_RM_Status) then
         return Exception_RM_Completion_Overload_RM_Blocker;
      elsif C.Requires_Representation_RM and then C.Representation_RM_Row = Representation_RM.No_Representation_Generic_RM_Hard_Case then
         return Exception_RM_Completion_Missing_Representation_RM_Row;
      elsif C.Requires_Representation_RM and then not Representation_RM.Is_Accepted (C.Representation_RM_Status) then
         return Exception_RM_Completion_Representation_RM_Blocker;
      elsif C.Requires_Tasking_RM and then C.Tasking_RM_Row = Tasking_RM.No_Tasking_Generic_RM_Hard_Case then
         return Exception_RM_Completion_Missing_Tasking_RM_Row;
      elsif C.Requires_Tasking_RM and then not Tasking_RM.Is_Accepted (C.Tasking_RM_Status) then
         return Exception_RM_Completion_Tasking_RM_Blocker;
      elsif C.Requires_AST_Repair and then C.AST_Repair_Row = AST_Repair.No_Coverage_Proven_AST_Repair then
         return Exception_RM_Completion_Missing_AST_Repair_Row;
      elsif C.Requires_AST_Repair and then not AST_Repair.Is_Repaired (C.AST_Repair_Status) then
         return Exception_RM_Completion_AST_Repair_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For (Status : Exception_RM_Completion_Status; Kind : Exception_RM_Completion_Kind; Family : Exception_RM_Completion_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("exception/finalization generic/shared-state RM completion legality " &
         Exception_RM_Completion_Status'Image (Status) &
         " kind=" & Exception_RM_Completion_Kind'Image (Kind) &
         " blocker=" & Exception_RM_Completion_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Exception_RM_Completion_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Exception_RM_Completion_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Exception_RM_Completion_Status'Pos (Row.Status) + 1);
      H := Mix (H, Exception_RM_Completion_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Exception_RM_Completion_Context) return Exception_RM_Completion_Row is
      Status : constant Exception_RM_Completion_Status := Classify (C);
      Family : constant Exception_RM_Completion_Blocker_Family := Family_For (Status);
      Row : Exception_RM_Completion_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Unit_Name := C.Unit_Name;
      Row.Exception_Name := C.Exception_Name;
      Row.Object_Name := C.Object_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := Is_Blocked (Status);
      Row.Blocks_Downstream := Row.Blocked;
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
   end Build_Row;

   procedure Clear (Model : in out Exception_RM_Completion_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Exception_RM_Completion_Context_Model; Info : Exception_RM_Completion_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Exception_RM_Completion_Kind'Pos (Info.Kind) + 1);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Exception_RM_Completion_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Exception_RM_Completion_Context_Model; Index : Positive) return Exception_RM_Completion_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Context_Fingerprint (Model : Exception_RM_Completion_Context_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Context_Fingerprint;

   function Build (Contexts : Exception_RM_Completion_Context_Model) return Exception_RM_Completion_Model is
      Result : Exception_RM_Completion_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Exception_RM_Completion_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Exception_RM_Completion_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Exception_RM_Completion_Model; Index : Positive) return Exception_RM_Completion_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Exception_RM_Completion_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At (Set : Exception_RM_Completion_Set; Index : Positive) return Exception_RM_Completion_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status (Model : Exception_RM_Completion_Model; Status : Exception_RM_Completion_Status) return Exception_RM_Completion_Set is
      Result : Exception_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family (Model : Exception_RM_Completion_Model; Family : Exception_RM_Completion_Blocker_Family) return Exception_RM_Completion_Set is
      Result : Exception_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node (Model : Exception_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Exception_RM_Completion_Set is
      Result : Exception_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Exception_RM_Completion_Model; Source_Fingerprint : Natural) return Exception_RM_Completion_Set is
      Result : Exception_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status (Model : Exception_RM_Completion_Model; Status : Exception_RM_Completion_Status) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Exception_RM_Completion_Model; Family : Exception_RM_Completion_Blocker_Family) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Exception_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Accepted_Count;

   function Blocked_Count (Model : Exception_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Blocked_Count;

   function Indeterminate_Count (Model : Exception_RM_Completion_Model) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Exception_RM_Completion_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
