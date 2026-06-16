with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Exception_Finalization_RM_Completion_Closure_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Accessibility.Accessibility_RM_Closure_Consumer_Id;
   use type Accessibility.Accessibility_RM_Closure_Consumer_Status;
   use type Closure.RM_Completion_Stabilized_Closure_Id;
   use type Closure.RM_Completion_Stabilized_Closure_Status;
   use type Cross_Unit.Cross_Unit_RM_Closure_Consumer_Id;
   use type Cross_Unit.Cross_Unit_RM_Closure_Consumer_Status;
   use type Dataflow.Dataflow_RM_Closure_Consumer_Id;
   use type Dataflow.Dataflow_RM_Closure_Consumer_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Elaboration.Elaboration_RM_Closure_Consumer_Id;
   use type Elaboration.Elaboration_RM_Closure_Consumer_Status;
   use type Overload.Overload_RM_Closure_Consumer_Id;
   use type Overload.Overload_RM_Closure_Consumer_Status;
   use type Prior.Exception_RM_Completion_Kind;
   use type Prior.Exception_RM_Completion_Row_Id;
   use type Prior.Exception_RM_Completion_Status;
   use type Representation.Representation_RM_Closure_Consumer_Id;
   use type Representation.Representation_RM_Closure_Consumer_Status;
   use type Tasking.Tasking_RM_Closure_Consumer_Id;
   use type Tasking.Tasking_RM_Closure_Consumer_Status;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right + 12_670) mod 2_147_483_647;
   end Mix;

   function Closure_Accepted
     (Status : Closure.RM_Completion_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.RM_Completion_Stabilized_Closure_Accepted_Current
        or else Status = Closure.RM_Completion_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Prior_Accepted (Status : Prior.Exception_RM_Completion_Status) return Boolean is
   begin
      return Prior.Is_Accepted (Status);
   end Prior_Accepted;

   function Closure_Status_To_Consumer
     (Status : Closure.RM_Completion_Stabilized_Closure_Status)
      return Exception_Finalization_RM_Closure_Consumer_Status is
   begin
      case Status is
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Stale_Or_Fingerprint =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_AST_Or_Coverage =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_AST_Or_Coverage;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Cross_Unit =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Cross_Unit;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Generic_Substitution =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Generic_Substitution;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Prior_Dataflow =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Prior_Dataflow;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Volatile_Atomic =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Volatile_Atomic;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Overload_Type =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Overload_Type;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Representation =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Representation;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Tasking_Protected =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Tasking_Protected;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Elaboration =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Elaboration;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Accessibility =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Accessibility;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Discriminant_Variant =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Discriminant_Variant;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Exception_Finalization =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Exception_Finalization;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Renaming_Alias =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Renaming_Alias;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Predicate_Invariant =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Predicate_Invariant;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Dataflow =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Dataflow;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Multiple_Prerequisites =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Multiple_Prerequisites;
         when Closure.RM_Completion_Stabilized_Closure_Recheck_Required =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Recheck_Required;
         when Closure.RM_Completion_Stabilized_Closure_Indeterminate =>
            return Exception_Finalization_RM_Closure_Consumer_Closure_Indeterminate;
         when others =>
            return Exception_Finalization_RM_Closure_Consumer_Indeterminate;
      end case;
   end Closure_Status_To_Consumer;

   function Family_For
     (Status : Exception_Finalization_RM_Closure_Consumer_Status)
      return Exception_Finalization_RM_Closure_Consumer_Family is
   begin
      case Status is
         when Exception_Finalization_RM_Closure_Consumer_Missing_Exception_Finalization_RM_Row |
              Exception_Finalization_RM_Closure_Consumer_Exception_Finalization_RM_Blocker =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Exception_Finalization_RM;
         when Exception_Finalization_RM_Closure_Consumer_Missing_Stabilized_Closure =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Stabilized_Closure;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Stale_Or_Fingerprint;
         when Exception_Finalization_RM_Closure_Consumer_Closure_AST_Or_Coverage =>
            return Exception_Finalization_RM_Closure_Consumer_Family_AST_Or_Coverage;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Cross_Unit |
              Exception_Finalization_RM_Closure_Consumer_Missing_Cross_Unit_Consumer |
              Exception_Finalization_RM_Closure_Consumer_Cross_Unit_Consumer_Blocker =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Cross_Unit;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Generic_Substitution =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Generic_Substitution;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Prior_Dataflow |
              Exception_Finalization_RM_Closure_Consumer_Closure_Dataflow |
              Exception_Finalization_RM_Closure_Consumer_Missing_Dataflow_Consumer |
              Exception_Finalization_RM_Closure_Consumer_Dataflow_Consumer_Blocker =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Dataflow;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Volatile_Atomic =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Volatile_Atomic;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Overload_Type |
              Exception_Finalization_RM_Closure_Consumer_Missing_Overload_Consumer |
              Exception_Finalization_RM_Closure_Consumer_Overload_Consumer_Blocker =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Overload_Type;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Representation |
              Exception_Finalization_RM_Closure_Consumer_Missing_Representation_Consumer |
              Exception_Finalization_RM_Closure_Consumer_Representation_Consumer_Blocker =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Representation;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Tasking_Protected |
              Exception_Finalization_RM_Closure_Consumer_Missing_Tasking_Consumer |
              Exception_Finalization_RM_Closure_Consumer_Tasking_Consumer_Blocker =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Tasking_Protected;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Elaboration |
              Exception_Finalization_RM_Closure_Consumer_Missing_Elaboration_Consumer |
              Exception_Finalization_RM_Closure_Consumer_Elaboration_Consumer_Blocker =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Elaboration;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Accessibility |
              Exception_Finalization_RM_Closure_Consumer_Missing_Accessibility_Consumer |
              Exception_Finalization_RM_Closure_Consumer_Accessibility_Consumer_Blocker =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Accessibility;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Discriminant_Variant =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Discriminant_Variant;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Exception_Finalization =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Exception_Finalization;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Renaming_Alias =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Renaming_Alias;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Predicate_Invariant =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Predicate_Invariant;
         when Exception_Finalization_RM_Closure_Consumer_Source_Fingerprint_Mismatch =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Source_Fingerprint;
         when Exception_Finalization_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Substitution_Fingerprint;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Multiple_Prerequisites |
              Exception_Finalization_RM_Closure_Consumer_Multiple_Blockers =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Multiple;
         when Exception_Finalization_RM_Closure_Consumer_Closure_Indeterminate |
              Exception_Finalization_RM_Closure_Consumer_Indeterminate =>
            return Exception_Finalization_RM_Closure_Consumer_Family_Indeterminate;
         when others =>
            return Exception_Finalization_RM_Closure_Consumer_Family_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Exception_Finalization_RM_Closure_Consumer_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      if C.Requires_Exception_Finalization_RM and then (C.Exception_Finalization_RM_Row = Prior.No_Exception_RM_Completion_Row or else not Prior_Accepted (C.Exception_Finalization_RM_Status)) then Count := Count + 1; end if;
      if C.Requires_Stabilized_Closure and then (C.Stabilized_Closure_Row = Closure.No_RM_Completion_Stabilized_Closure or else not Closure_Accepted (C.Stabilized_Closure_Status)) then Count := Count + 1; end if;
      if C.Requires_Cross_Unit_Consumer and then (C.Cross_Unit_Consumer_Row = Cross_Unit.No_Cross_Unit_RM_Closure_Consumer or else C.Cross_Unit_Consumer_Status /= Cross_Unit.Cross_Unit_RM_Closure_Consumer_Accepted) then Count := Count + 1; end if;
      if C.Requires_Elaboration_Consumer and then (C.Elaboration_Consumer_Row = Elaboration.No_Elaboration_RM_Closure_Consumer or else C.Elaboration_Consumer_Status /= Elaboration.Elaboration_RM_Closure_Consumer_Accepted) then Count := Count + 1; end if;
      if C.Requires_Accessibility_Consumer and then (C.Accessibility_Consumer_Row = Accessibility.No_Accessibility_RM_Closure_Consumer or else C.Accessibility_Consumer_Status /= Accessibility.Accessibility_RM_Closure_Consumer_Accepted) then Count := Count + 1; end if;
      if C.Requires_Overload_Consumer and then (C.Overload_Consumer_Row = Overload.No_Overload_RM_Closure_Consumer or else C.Overload_Consumer_Status /= Overload.Overload_RM_Closure_Consumer_Accepted) then Count := Count + 1; end if;
      if C.Requires_Representation_Consumer and then (C.Representation_Consumer_Row = Representation.No_Representation_RM_Closure_Consumer or else C.Representation_Consumer_Status /= Representation.Representation_RM_Closure_Consumer_Accepted) then Count := Count + 1; end if;
      if C.Requires_Tasking_Consumer and then (C.Tasking_Consumer_Row = Tasking.No_Tasking_RM_Closure_Consumer or else C.Tasking_Consumer_Status /= Tasking.Tasking_RM_Closure_Consumer_Accepted) then Count := Count + 1; end if;
      if C.Requires_Dataflow_Consumer and then (C.Dataflow_Consumer_Row = Dataflow.No_Dataflow_RM_Closure_Consumer or else C.Dataflow_Consumer_Status /= Dataflow.Dataflow_RM_Closure_Consumer_Accepted) then Count := Count + 1; end if;
      return Count;
   end Local_Blocker_Count;

   function Classify
     (C : Exception_Finalization_RM_Closure_Consumer_Context)
      return Exception_Finalization_RM_Closure_Consumer_Status is
      Blockers : constant Natural := Local_Blocker_Count (C);
   begin
      if Blockers > 1 then
         return Exception_Finalization_RM_Closure_Consumer_Multiple_Blockers;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Exception_Finalization_RM_Closure_Consumer_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Exception_Finalization_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Exception_Finalization_RM and then C.Exception_Finalization_RM_Row = Prior.No_Exception_RM_Completion_Row then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Exception_Finalization_RM_Row;
      elsif C.Requires_Exception_Finalization_RM and then not Prior_Accepted (C.Exception_Finalization_RM_Status) then
         return Exception_Finalization_RM_Closure_Consumer_Exception_Finalization_RM_Blocker;
      elsif C.Requires_Stabilized_Closure and then C.Stabilized_Closure_Row = Closure.No_RM_Completion_Stabilized_Closure then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Stabilized_Closure;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Closure_Status_To_Consumer (C.Stabilized_Closure_Status);
      elsif C.Requires_Cross_Unit_Consumer and then C.Cross_Unit_Consumer_Row = Cross_Unit.No_Cross_Unit_RM_Closure_Consumer then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Cross_Unit_Consumer;
      elsif C.Requires_Cross_Unit_Consumer and then C.Cross_Unit_Consumer_Status /= Cross_Unit.Cross_Unit_RM_Closure_Consumer_Accepted then
         return Exception_Finalization_RM_Closure_Consumer_Cross_Unit_Consumer_Blocker;
      elsif C.Requires_Elaboration_Consumer and then C.Elaboration_Consumer_Row = Elaboration.No_Elaboration_RM_Closure_Consumer then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Elaboration_Consumer;
      elsif C.Requires_Elaboration_Consumer and then C.Elaboration_Consumer_Status /= Elaboration.Elaboration_RM_Closure_Consumer_Accepted then
         return Exception_Finalization_RM_Closure_Consumer_Elaboration_Consumer_Blocker;
      elsif C.Requires_Accessibility_Consumer and then C.Accessibility_Consumer_Row = Accessibility.No_Accessibility_RM_Closure_Consumer then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Accessibility_Consumer;
      elsif C.Requires_Accessibility_Consumer and then C.Accessibility_Consumer_Status /= Accessibility.Accessibility_RM_Closure_Consumer_Accepted then
         return Exception_Finalization_RM_Closure_Consumer_Accessibility_Consumer_Blocker;
      elsif C.Requires_Overload_Consumer and then C.Overload_Consumer_Row = Overload.No_Overload_RM_Closure_Consumer then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Overload_Consumer;
      elsif C.Requires_Overload_Consumer and then C.Overload_Consumer_Status /= Overload.Overload_RM_Closure_Consumer_Accepted then
         return Exception_Finalization_RM_Closure_Consumer_Overload_Consumer_Blocker;
      elsif C.Requires_Representation_Consumer and then C.Representation_Consumer_Row = Representation.No_Representation_RM_Closure_Consumer then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Representation_Consumer;
      elsif C.Requires_Representation_Consumer and then C.Representation_Consumer_Status /= Representation.Representation_RM_Closure_Consumer_Accepted then
         return Exception_Finalization_RM_Closure_Consumer_Representation_Consumer_Blocker;
      elsif C.Requires_Tasking_Consumer and then C.Tasking_Consumer_Row = Tasking.No_Tasking_RM_Closure_Consumer then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Tasking_Consumer;
      elsif C.Requires_Tasking_Consumer and then C.Tasking_Consumer_Status /= Tasking.Tasking_RM_Closure_Consumer_Accepted then
         return Exception_Finalization_RM_Closure_Consumer_Tasking_Consumer_Blocker;
      elsif C.Requires_Dataflow_Consumer and then C.Dataflow_Consumer_Row = Dataflow.No_Dataflow_RM_Closure_Consumer then
         return Exception_Finalization_RM_Closure_Consumer_Missing_Dataflow_Consumer;
      elsif C.Requires_Dataflow_Consumer and then C.Dataflow_Consumer_Status /= Dataflow.Dataflow_RM_Closure_Consumer_Accepted then
         return Exception_Finalization_RM_Closure_Consumer_Dataflow_Consumer_Blocker;
      elsif C.Kind = Prior.Exception_RM_Completion_Unknown then
         return Exception_Finalization_RM_Closure_Consumer_Indeterminate;
      else
         return Exception_Finalization_RM_Closure_Consumer_Accepted;
      end if;
   end Classify;

   function Is_Accepted (Status : Exception_Finalization_RM_Closure_Consumer_Status) return Boolean is
   begin
      return Status = Exception_Finalization_RM_Closure_Consumer_Accepted;
   end Is_Accepted;

   function Is_Indeterminate (Status : Exception_Finalization_RM_Closure_Consumer_Status) return Boolean is
   begin
      return Status = Exception_Finalization_RM_Closure_Consumer_Indeterminate
        or else Status = Exception_Finalization_RM_Closure_Consumer_Closure_Indeterminate;
   end Is_Indeterminate;

   function Message_For
     (Status : Exception_Finalization_RM_Closure_Consumer_Status;
      Kind   : Exception_Finalization_RM_Kind;
      Family : Exception_Finalization_RM_Closure_Consumer_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("exception/finalization RM-completion stabilized closure consumer " &
         Exception_Finalization_RM_Closure_Consumer_Status'Image (Status) &
         " kind=" & Prior.Exception_RM_Completion_Kind'Image (Kind) &
         " family=" & Exception_Finalization_RM_Closure_Consumer_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Exception_Finalization_RM_Closure_Consumer_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_670;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Prior.Exception_RM_Completion_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Exception_Finalization_RM_Closure_Consumer_Status'Pos (Row.Status) + 1);
      H := Mix (H, Exception_Finalization_RM_Closure_Consumer_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Exception_Finalization_RM_Closure_Consumer_Context;
      Index : Positive) return Exception_Finalization_RM_Closure_Consumer_Row is
      Status : constant Exception_Finalization_RM_Closure_Consumer_Status := Classify (C);
      Family : constant Exception_Finalization_RM_Closure_Consumer_Family := Family_For (Status);
      Row    : Exception_Finalization_RM_Closure_Consumer_Row;
      pragma Unreferenced (Index);
   begin
      Row.Id := C.Id;
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Family := Family;
      Row.Node := C.Node;
      Row.Unit_Name := C.Unit_Name;
      Row.Target_Name := C.Target_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := not Row.Accepted and then not Is_Indeterminate (Status)
        and then Status /= Exception_Finalization_RM_Closure_Consumer_Not_Checked;
      Row.Blocks_Downstream := Row.Blocked;
      Row.Source_Fingerprint := C.Source_Fingerprint;
      Row.Substitution_Fingerprint := C.Substitution_Fingerprint;
      Row.Start_Line := C.Start_Line;
      Row.Start_Column := C.Start_Column;
      Row.End_Line := C.End_Line;
      Row.End_Column := C.End_Column;
      Row.Message := Message_For (Status, C.Kind, Family);
      Row.Row_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Exception_Finalization_RM_Closure_Consumer_Context_Model) is
   begin
      Model.Contexts.Clear;
   end Clear;

   procedure Add_Context
     (Model   : in out Exception_Finalization_RM_Closure_Consumer_Context_Model;
      Context : Exception_Finalization_RM_Closure_Consumer_Context) is
   begin
      Model.Contexts.Append (Context);
   end Add_Context;

   function Build (Contexts : Exception_Finalization_RM_Closure_Consumer_Context_Model) return Exception_Finalization_RM_Closure_Consumer_Model is
      Model : Exception_Finalization_RM_Closure_Consumer_Model;
      Row   : Exception_Finalization_RM_Closure_Consumer_Row;
      Index : Positive := 1;
   begin
      for C of Contexts.Contexts loop
         Row := Make_Row (C, Index);
         Model.Rows.Append (Row);
         if Row.Accepted then
            Model.Accepted_Total := Model.Accepted_Total + 1;
         elsif Is_Indeterminate (Row.Status) then
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         elsif Row.Blocked then
            Model.Blocked_Total := Model.Blocked_Total + 1;
         end if;
         Model.Fingerprint := Mix (Model.Fingerprint, Row.Row_Fingerprint);
         Index := Index + 1;
      end loop;
      return Model;
   end Build;

   function Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Exception_Finalization_RM_Closure_Consumer_Model;
      Index : Positive) return Exception_Finalization_RM_Closure_Consumer_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Exception_Finalization_RM_Closure_Consumer_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Exception_Finalization_RM_Closure_Consumer_Set;
      Index : Positive) return Exception_Finalization_RM_Closure_Consumer_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Count_By_Status
     (Model  : Exception_Finalization_RM_Closure_Consumer_Model;
      Status : Exception_Finalization_RM_Closure_Consumer_Status) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Status;

   function Count_By_Family
     (Model  : Exception_Finalization_RM_Closure_Consumer_Model;
      Family : Exception_Finalization_RM_Closure_Consumer_Family) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Family;

   function Accepted_Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Find_By_Node
     (Model : Exception_Finalization_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Exception_Finalization_RM_Closure_Consumer_Set is
      Result : Exception_Finalization_RM_Closure_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Exception_Finalization_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Exception_Finalization_RM_Closure_Consumer_Set is
      Result : Exception_Finalization_RM_Closure_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Stable_Fingerprint (Model : Exception_Finalization_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Exception_Finalization_RM_Completion_Closure_Consumer_Legality;
