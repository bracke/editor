with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality is

   pragma Suppress (Overflow_Check);

   use type AST_Repair.Coverage_Proven_AST_Repair_Id;
   use type Cross_RM.Cross_Unit_RM_Completion_Closure_Id;
   use type Dataflow_Generic.Dataflow_Generic_Final_Row_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Exception_Generic.Exception_Generic_Final_Row_Id;
   use type Overload_RM.Overload_Generic_RM_Edge_Completion_Id;
   use type Predicate_Generic.Predicate_Generic_Final_Row_Id;
   use type Prior_Elab.Elaboration_Generic_Final_Row_Id;
   use type Renaming_Generic.Renaming_Generic_Final_Row_Id;
   use type Representation_RM.Representation_Generic_RM_Hard_Case_Id;
   use type Tasking_RM.Tasking_Generic_RM_Hard_Case_Id;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return ((Left * 131) + Right + 17) mod 2_147_483_647;
   end Mix;

   function Accepted_For (Kind : Elaboration_RM_Completion_Kind) return Elaboration_RM_Completion_Status is
   begin
      case Kind is
         when Elaboration_RM_Completion_Dispatching_Call => return Elaboration_RM_Completion_Legal_Dispatching_Call_Accepted;
         when Elaboration_RM_Completion_Default_Expression => return Elaboration_RM_Completion_Legal_Default_Expression_Accepted;
         when Elaboration_RM_Completion_Aspect_Expression => return Elaboration_RM_Completion_Legal_Aspect_Expression_Accepted;
         when Elaboration_RM_Completion_Representation_Item => return Elaboration_RM_Completion_Legal_Representation_Item_Accepted;
         when Elaboration_RM_Completion_Task_Activation => return Elaboration_RM_Completion_Legal_Task_Activation_Accepted;
         when Elaboration_RM_Completion_Task_Termination => return Elaboration_RM_Completion_Legal_Task_Termination_Accepted;
         when Elaboration_RM_Completion_Generic_Instance => return Elaboration_RM_Completion_Legal_Generic_Instance_Accepted;
         when Elaboration_RM_Completion_Generic_Body_Replay => return Elaboration_RM_Completion_Legal_Generic_Body_Replay_Accepted;
         when Elaboration_RM_Completion_Preelaboration_Policy => return Elaboration_RM_Completion_Legal_Preelaboration_Policy_Accepted;
         when Elaboration_RM_Completion_Pure_Policy => return Elaboration_RM_Completion_Legal_Pure_Policy_Accepted;
         when Elaboration_RM_Completion_Remote_Types_Policy => return Elaboration_RM_Completion_Legal_Remote_Types_Policy_Accepted;
         when Elaboration_RM_Completion_Shared_Passive_Policy => return Elaboration_RM_Completion_Legal_Shared_Passive_Policy_Accepted;
         when Elaboration_RM_Completion_Cross_Unit_Body => return Elaboration_RM_Completion_Legal_Cross_Unit_Body_Accepted;
         when Elaboration_RM_Completion_Exception_Finalization => return Elaboration_RM_Completion_Legal_Exception_Finalization_Accepted;
         when Elaboration_RM_Completion_Renamed_Elaboration_Source => return Elaboration_RM_Completion_Legal_Renamed_Source_Accepted;
         when Elaboration_RM_Completion_Predicate_Check => return Elaboration_RM_Completion_Legal_Predicate_Check_Accepted;
         when Elaboration_RM_Completion_Dataflow_Edge => return Elaboration_RM_Completion_Legal_Dataflow_Edge_Accepted;
         when Elaboration_RM_Completion_Unknown => return Elaboration_RM_Completion_Indeterminate;
      end case;
   end Accepted_For;

   function Is_Accepted (Status : Elaboration_RM_Completion_Status) return Boolean is
   begin
      case Status is
         when Elaboration_RM_Completion_Legal_Dispatching_Call_Accepted
            | Elaboration_RM_Completion_Legal_Default_Expression_Accepted
            | Elaboration_RM_Completion_Legal_Aspect_Expression_Accepted
            | Elaboration_RM_Completion_Legal_Representation_Item_Accepted
            | Elaboration_RM_Completion_Legal_Task_Activation_Accepted
            | Elaboration_RM_Completion_Legal_Task_Termination_Accepted
            | Elaboration_RM_Completion_Legal_Generic_Instance_Accepted
            | Elaboration_RM_Completion_Legal_Generic_Body_Replay_Accepted
            | Elaboration_RM_Completion_Legal_Preelaboration_Policy_Accepted
            | Elaboration_RM_Completion_Legal_Pure_Policy_Accepted
            | Elaboration_RM_Completion_Legal_Remote_Types_Policy_Accepted
            | Elaboration_RM_Completion_Legal_Shared_Passive_Policy_Accepted
            | Elaboration_RM_Completion_Legal_Cross_Unit_Body_Accepted
            | Elaboration_RM_Completion_Legal_Exception_Finalization_Accepted
            | Elaboration_RM_Completion_Legal_Renamed_Source_Accepted
            | Elaboration_RM_Completion_Legal_Predicate_Check_Accepted
            | Elaboration_RM_Completion_Legal_Dataflow_Edge_Accepted => return True;
         when others => return False;
      end case;
   end Is_Accepted;

   function Is_Indeterminate (Status : Elaboration_RM_Completion_Status) return Boolean is
   begin
      return Status = Elaboration_RM_Completion_Indeterminate;
   end Is_Indeterminate;

   function Is_Blocked (Status : Elaboration_RM_Completion_Status) return Boolean is
   begin
      return not Is_Accepted (Status)
        and then Status /= Elaboration_RM_Completion_Not_Checked
        and then not Is_Indeterminate (Status);
   end Is_Blocked;

   function Family_For (Status : Elaboration_RM_Completion_Status) return Elaboration_RM_Completion_Blocker_Family is
   begin
      case Status is
         when Elaboration_RM_Completion_Missing_Cross_Unit_RM_Row | Elaboration_RM_Completion_Cross_Unit_RM_Blocker => return Elaboration_RM_Completion_Blocker_Cross_Unit_RM_Completion;
         when Elaboration_RM_Completion_Missing_Prior_Elaboration_Row | Elaboration_RM_Completion_Prior_Elaboration_Blocker => return Elaboration_RM_Completion_Blocker_Prior_Elaboration;
         when Elaboration_RM_Completion_Missing_Overload_RM_Row | Elaboration_RM_Completion_Overload_RM_Blocker => return Elaboration_RM_Completion_Blocker_Overload_RM_Completion;
         when Elaboration_RM_Completion_Missing_Representation_RM_Row | Elaboration_RM_Completion_Representation_RM_Blocker => return Elaboration_RM_Completion_Blocker_Representation_RM_Completion;
         when Elaboration_RM_Completion_Missing_Tasking_RM_Row | Elaboration_RM_Completion_Tasking_RM_Blocker => return Elaboration_RM_Completion_Blocker_Tasking_RM_Completion;
         when Elaboration_RM_Completion_Missing_AST_Repair_Row | Elaboration_RM_Completion_AST_Repair_Blocker => return Elaboration_RM_Completion_Blocker_AST_Repair;
         when Elaboration_RM_Completion_Missing_Exception_Generic_Row | Elaboration_RM_Completion_Exception_Generic_Blocker => return Elaboration_RM_Completion_Blocker_Exception_Finalization;
         when Elaboration_RM_Completion_Missing_Renaming_Generic_Row | Elaboration_RM_Completion_Renaming_Generic_Blocker => return Elaboration_RM_Completion_Blocker_Renaming_Alias;
         when Elaboration_RM_Completion_Missing_Predicate_Generic_Row | Elaboration_RM_Completion_Predicate_Generic_Blocker => return Elaboration_RM_Completion_Blocker_Predicate_Invariant;
         when Elaboration_RM_Completion_Missing_Dataflow_Generic_Row | Elaboration_RM_Completion_Dataflow_Generic_Blocker => return Elaboration_RM_Completion_Blocker_Dataflow_Initialization;
         when Elaboration_RM_Completion_Elaboration_Order_Blocker => return Elaboration_RM_Completion_Blocker_Elaboration_Order;
         when Elaboration_RM_Completion_Preelaboration_Policy_Blocker => return Elaboration_RM_Completion_Blocker_Preelaboration_Policy;
         when Elaboration_RM_Completion_Pure_Policy_Blocker => return Elaboration_RM_Completion_Blocker_Pure_Policy;
         when Elaboration_RM_Completion_Remote_Types_Policy_Blocker => return Elaboration_RM_Completion_Blocker_Remote_Types_Policy;
         when Elaboration_RM_Completion_Shared_Passive_Policy_Blocker => return Elaboration_RM_Completion_Blocker_Shared_Passive_Policy;
         when Elaboration_RM_Completion_Generic_Body_Unavailable => return Elaboration_RM_Completion_Blocker_Generic_Body;
         when Elaboration_RM_Completion_View_Barrier => return Elaboration_RM_Completion_Blocker_View_Barrier;
         when Elaboration_RM_Completion_Source_Fingerprint_Mismatch => return Elaboration_RM_Completion_Blocker_Source_Fingerprint;
         when Elaboration_RM_Completion_Substitution_Fingerprint_Mismatch => return Elaboration_RM_Completion_Blocker_Substitution_Fingerprint;
         when Elaboration_RM_Completion_Multiple_Blockers => return Elaboration_RM_Completion_Blocker_Multiple;
         when Elaboration_RM_Completion_Indeterminate => return Elaboration_RM_Completion_Blocker_Indeterminate;
         when others => return Elaboration_RM_Completion_Blocker_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Elaboration_RM_Completion_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Elaboration_Order_Error then Count := Count + 1; end if;
      if C.Preelaboration_Policy_Error then Count := Count + 1; end if;
      if C.Pure_Policy_Error then Count := Count + 1; end if;
      if C.Remote_Types_Policy_Error then Count := Count + 1; end if;
      if C.Shared_Passive_Policy_Error then Count := Count + 1; end if;
      if C.Generic_Body_Unavailable then Count := Count + 1; end if;
      if C.View_Barrier then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify (C : Elaboration_RM_Completion_Context) return Elaboration_RM_Completion_Status is
   begin
      if Local_Blocker_Count (C) > 1 then
         return Elaboration_RM_Completion_Multiple_Blockers;
      elsif C.Elaboration_Order_Error then
         return Elaboration_RM_Completion_Elaboration_Order_Blocker;
      elsif C.Preelaboration_Policy_Error then
         return Elaboration_RM_Completion_Preelaboration_Policy_Blocker;
      elsif C.Pure_Policy_Error then
         return Elaboration_RM_Completion_Pure_Policy_Blocker;
      elsif C.Remote_Types_Policy_Error then
         return Elaboration_RM_Completion_Remote_Types_Policy_Blocker;
      elsif C.Shared_Passive_Policy_Error then
         return Elaboration_RM_Completion_Shared_Passive_Policy_Blocker;
      elsif C.Generic_Body_Unavailable then
         return Elaboration_RM_Completion_Generic_Body_Unavailable;
      elsif C.View_Barrier then
         return Elaboration_RM_Completion_View_Barrier;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Elaboration_RM_Completion_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Elaboration_RM_Completion_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Cross_RM and then C.Cross_RM_Row = Cross_RM.No_Cross_Unit_RM_Completion_Closure then
         return Elaboration_RM_Completion_Missing_Cross_Unit_RM_Row;
      elsif C.Requires_Cross_RM and then not Cross_RM.Is_Accepted (C.Cross_RM_Status) then
         return Elaboration_RM_Completion_Cross_Unit_RM_Blocker;
      elsif C.Requires_Prior_Elaboration and then C.Prior_Elaboration_Row = Prior_Elab.No_Elaboration_Generic_Final_Row then
         return Elaboration_RM_Completion_Missing_Prior_Elaboration_Row;
      elsif C.Requires_Prior_Elaboration and then not Prior_Elab.Is_Accepted (C.Prior_Elaboration_Status) then
         return Elaboration_RM_Completion_Prior_Elaboration_Blocker;
      elsif C.Requires_Overload_RM and then C.Overload_RM_Row = Overload_RM.No_Overload_Generic_RM_Edge_Completion then
         return Elaboration_RM_Completion_Missing_Overload_RM_Row;
      elsif C.Requires_Overload_RM and then not Overload_RM.Is_Accepted (C.Overload_RM_Status) then
         return Elaboration_RM_Completion_Overload_RM_Blocker;
      elsif C.Requires_Representation_RM and then C.Representation_RM_Row = Representation_RM.No_Representation_Generic_RM_Hard_Case then
         return Elaboration_RM_Completion_Missing_Representation_RM_Row;
      elsif C.Requires_Representation_RM and then not Representation_RM.Is_Accepted (C.Representation_RM_Status) then
         return Elaboration_RM_Completion_Representation_RM_Blocker;
      elsif C.Requires_Tasking_RM and then C.Tasking_RM_Row = Tasking_RM.No_Tasking_Generic_RM_Hard_Case then
         return Elaboration_RM_Completion_Missing_Tasking_RM_Row;
      elsif C.Requires_Tasking_RM and then not Tasking_RM.Is_Accepted (C.Tasking_RM_Status) then
         return Elaboration_RM_Completion_Tasking_RM_Blocker;
      elsif C.Requires_AST_Repair and then C.AST_Repair_Row = AST_Repair.No_Coverage_Proven_AST_Repair then
         return Elaboration_RM_Completion_Missing_AST_Repair_Row;
      elsif C.Requires_AST_Repair and then not AST_Repair.Is_Repaired (C.AST_Repair_Status) then
         return Elaboration_RM_Completion_AST_Repair_Blocker;
      elsif C.Requires_Exception_Generic and then C.Exception_Generic_Row = Exception_Generic.No_Exception_Generic_Final_Row then
         return Elaboration_RM_Completion_Missing_Exception_Generic_Row;
      elsif C.Requires_Exception_Generic and then not Exception_Generic.Is_Accepted (C.Exception_Generic_Status) then
         return Elaboration_RM_Completion_Exception_Generic_Blocker;
      elsif C.Requires_Renaming_Generic and then C.Renaming_Generic_Row = Renaming_Generic.No_Renaming_Generic_Final_Row then
         return Elaboration_RM_Completion_Missing_Renaming_Generic_Row;
      elsif C.Requires_Renaming_Generic and then not Renaming_Generic.Is_Accepted (C.Renaming_Generic_Status) then
         return Elaboration_RM_Completion_Renaming_Generic_Blocker;
      elsif C.Requires_Predicate_Generic and then C.Predicate_Generic_Row = Predicate_Generic.No_Predicate_Generic_Final_Row then
         return Elaboration_RM_Completion_Missing_Predicate_Generic_Row;
      elsif C.Requires_Predicate_Generic and then not Predicate_Generic.Is_Accepted (C.Predicate_Generic_Status) then
         return Elaboration_RM_Completion_Predicate_Generic_Blocker;
      elsif C.Requires_Dataflow_Generic and then C.Dataflow_Generic_Row = Dataflow_Generic.No_Dataflow_Generic_Final_Row then
         return Elaboration_RM_Completion_Missing_Dataflow_Generic_Row;
      elsif C.Requires_Dataflow_Generic and then not Dataflow_Generic.Is_Accepted (C.Dataflow_Generic_Status) then
         return Elaboration_RM_Completion_Dataflow_Generic_Blocker;
      else
         return Accepted_For (C.Kind);
      end if;
   end Classify;

   function Message_For (Status : Elaboration_RM_Completion_Status; Kind : Elaboration_RM_Completion_Kind; Family : Elaboration_RM_Completion_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("elaboration generic/shared-state RM completion legality " &
         Elaboration_RM_Completion_Status'Image (Status) &
         " kind=" & Elaboration_RM_Completion_Kind'Image (Kind) &
         " blocker=" & Elaboration_RM_Completion_Blocker_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Elaboration_RM_Completion_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Elaboration_RM_Completion_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Elaboration_RM_Completion_Status'Pos (Row.Status) + 1);
      H := Mix (H, Elaboration_RM_Completion_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Build_Row (C : Elaboration_RM_Completion_Context) return Elaboration_RM_Completion_Row is
      Status : constant Elaboration_RM_Completion_Status := Classify (C);
      Family : constant Elaboration_RM_Completion_Blocker_Family := Family_For (Status);
      Row : Elaboration_RM_Completion_Row;
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Blocker_Family := Family;
      Row.Node := C.Node;
      Row.Unit_Name := C.Unit_Name;
      Row.Target_Name := C.Target_Name;
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

   procedure Clear (Model : in out Elaboration_RM_Completion_Context_Model) is
   begin
      Model.Items.Clear;
      Model.Stable_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Elaboration_RM_Completion_Context_Model; Info : Elaboration_RM_Completion_Context) is
   begin
      Model.Items.Append (Info);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Id));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Elaboration_RM_Completion_Kind'Pos (Info.Kind) + 1);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Natural (Info.Node));
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Source_Fingerprint);
      Model.Stable_Fingerprint := Mix (Model.Stable_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Elaboration_RM_Completion_Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Context_At (Model : Elaboration_RM_Completion_Context_Model; Index : Positive) return Elaboration_RM_Completion_Context is
   begin
      return Model.Items.Element (Index);
   end Context_At;

   function Context_Fingerprint (Model : Elaboration_RM_Completion_Context_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Context_Fingerprint;

   function Build (Contexts : Elaboration_RM_Completion_Context_Model) return Elaboration_RM_Completion_Model is
      Result : Elaboration_RM_Completion_Model;
   begin
      for C of Contexts.Items loop
         declare
            Row : constant Elaboration_RM_Completion_Row := Build_Row (C);
         begin
            Result.Rows.Append (Row);
            Result.Stable_Fingerprint := Mix (Result.Stable_Fingerprint, Row.Fingerprint);
         end;
      end loop;
      return Result;
   end Build;

   function Count (Model : Elaboration_RM_Completion_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At (Model : Elaboration_RM_Completion_Model; Index : Positive) return Elaboration_RM_Completion_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Elaboration_RM_Completion_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At (Set : Elaboration_RM_Completion_Set; Index : Positive) return Elaboration_RM_Completion_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Query_Status (Model : Elaboration_RM_Completion_Model; Status : Elaboration_RM_Completion_Status) return Elaboration_RM_Completion_Set is
      Result : Elaboration_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker_Family (Model : Elaboration_RM_Completion_Model; Family : Elaboration_RM_Completion_Blocker_Family) return Elaboration_RM_Completion_Set is
      Result : Elaboration_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Family then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker_Family;

   function Find_By_Node (Model : Elaboration_RM_Completion_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Elaboration_RM_Completion_Set is
      Result : Elaboration_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint (Model : Elaboration_RM_Completion_Model; Source_Fingerprint : Natural) return Elaboration_RM_Completion_Set is
      Result : Elaboration_RM_Completion_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Source_Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status (Model : Elaboration_RM_Completion_Model; Status : Elaboration_RM_Completion_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker_Family (Model : Elaboration_RM_Completion_Model; Family : Elaboration_RM_Completion_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker_Family (Model, Family));
   end Count_By_Blocker_Family;

   function Accepted_Count (Model : Elaboration_RM_Completion_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Accepted then Total := Total + 1; end if;
      end loop;
      return Total;
   end Accepted_Count;

   function Blocked_Count (Model : Elaboration_RM_Completion_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Blocked then Total := Total + 1; end if;
      end loop;
      return Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Elaboration_RM_Completion_Model) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Indeterminate (Row.Status) then Total := Total + 1; end if;
      end loop;
      return Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Elaboration_RM_Completion_Model) return Natural is
   begin
      return Model.Stable_Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
