with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_RM_Completion_Closure_Consumer_Legality is

   pragma Suppress (Overflow_Check);
   use type Closure.RM_Completion_Stabilized_Closure_Status;
   use type Prior.Tasking_Generic_RM_Hard_Case_Id;
   use type Closure.RM_Completion_Stabilized_Closure_Id;
   use type Prior.Tasking_Generic_RM_Hard_Case_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right + 12_641) mod 2_147_483_647;
   end Mix;

   function Closure_Accepted
     (Status : Closure.RM_Completion_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.RM_Completion_Stabilized_Closure_Accepted_Current
        or else Status = Closure.RM_Completion_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Closure_Status_To_Consumer
     (Status : Closure.RM_Completion_Stabilized_Closure_Status)
      return Tasking_RM_Closure_Consumer_Status is
   begin
      case Status is
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Stale_Or_Fingerprint =>
            return Tasking_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_AST_Or_Coverage =>
            return Tasking_RM_Closure_Consumer_Closure_AST_Or_Coverage;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Cross_Unit =>
            return Tasking_RM_Closure_Consumer_Closure_Cross_Unit;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Generic_Substitution =>
            return Tasking_RM_Closure_Consumer_Closure_Generic_Substitution;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Prior_Dataflow =>
            return Tasking_RM_Closure_Consumer_Closure_Prior_Dataflow;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Volatile_Atomic =>
            return Tasking_RM_Closure_Consumer_Closure_Volatile_Atomic;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Overload_Type =>
            return Tasking_RM_Closure_Consumer_Closure_Overload_Type;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Representation =>
            return Tasking_RM_Closure_Consumer_Closure_Representation;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Tasking_Protected =>
            return Tasking_RM_Closure_Consumer_Closure_Tasking_Protected;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Elaboration =>
            return Tasking_RM_Closure_Consumer_Closure_Elaboration;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Accessibility =>
            return Tasking_RM_Closure_Consumer_Closure_Accessibility;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Discriminant_Variant =>
            return Tasking_RM_Closure_Consumer_Closure_Discriminant_Variant;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Exception_Finalization =>
            return Tasking_RM_Closure_Consumer_Closure_Exception_Finalization;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Renaming_Alias =>
            return Tasking_RM_Closure_Consumer_Closure_Renaming_Alias;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Predicate_Invariant =>
            return Tasking_RM_Closure_Consumer_Closure_Predicate_Invariant;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Dataflow =>
            return Tasking_RM_Closure_Consumer_Closure_Dataflow;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Multiple_Prerequisites =>
            return Tasking_RM_Closure_Consumer_Closure_Multiple_Prerequisites;
         when Closure.RM_Completion_Stabilized_Closure_Recheck_Required =>
            return Tasking_RM_Closure_Consumer_Closure_Recheck_Required;
         when Closure.RM_Completion_Stabilized_Closure_Indeterminate =>
            return Tasking_RM_Closure_Consumer_Closure_Indeterminate;
         when others =>
            return Tasking_RM_Closure_Consumer_Indeterminate;
      end case;
   end Closure_Status_To_Consumer;

   function Family_For
     (Status : Tasking_RM_Closure_Consumer_Status)
      return Tasking_RM_Closure_Consumer_Family is
   begin
      case Status is
         when Tasking_RM_Closure_Consumer_Missing_Tasking_RM_Row |
              Tasking_RM_Closure_Consumer_Tasking_RM_Blocker =>
            return Tasking_RM_Closure_Consumer_Family_Tasking_RM;
         when Tasking_RM_Closure_Consumer_Missing_Stabilized_Closure |
              Tasking_RM_Closure_Consumer_Closure_Overload_Type =>
            return Tasking_RM_Closure_Consumer_Family_Stabilized_Closure;
         when Tasking_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint =>
            return Tasking_RM_Closure_Consumer_Family_Stale_Or_Fingerprint;
         when Tasking_RM_Closure_Consumer_Closure_AST_Or_Coverage =>
            return Tasking_RM_Closure_Consumer_Family_AST_Or_Coverage;
         when Tasking_RM_Closure_Consumer_Closure_Cross_Unit =>
            return Tasking_RM_Closure_Consumer_Family_Cross_Unit;
         when Tasking_RM_Closure_Consumer_Closure_Generic_Substitution =>
            return Tasking_RM_Closure_Consumer_Family_Generic_Substitution;
         when Tasking_RM_Closure_Consumer_Closure_Prior_Dataflow |
              Tasking_RM_Closure_Consumer_Closure_Dataflow =>
            return Tasking_RM_Closure_Consumer_Family_Dataflow;
         when Tasking_RM_Closure_Consumer_Closure_Volatile_Atomic =>
            return Tasking_RM_Closure_Consumer_Family_Volatile_Atomic;
         when Tasking_RM_Closure_Consumer_Closure_Representation =>
            return Tasking_RM_Closure_Consumer_Family_Representation;
         when Tasking_RM_Closure_Consumer_Closure_Tasking_Protected =>
            return Tasking_RM_Closure_Consumer_Family_Tasking_Protected;
         when Tasking_RM_Closure_Consumer_Closure_Elaboration =>
            return Tasking_RM_Closure_Consumer_Family_Elaboration;
         when Tasking_RM_Closure_Consumer_Closure_Accessibility =>
            return Tasking_RM_Closure_Consumer_Family_Accessibility;
         when Tasking_RM_Closure_Consumer_Closure_Discriminant_Variant =>
            return Tasking_RM_Closure_Consumer_Family_Discriminant_Variant;
         when Tasking_RM_Closure_Consumer_Closure_Exception_Finalization =>
            return Tasking_RM_Closure_Consumer_Family_Exception_Finalization;
         when Tasking_RM_Closure_Consumer_Closure_Renaming_Alias =>
            return Tasking_RM_Closure_Consumer_Family_Renaming_Alias;
         when Tasking_RM_Closure_Consumer_Closure_Predicate_Invariant =>
            return Tasking_RM_Closure_Consumer_Family_Predicate_Invariant;
         when Tasking_RM_Closure_Consumer_Source_Fingerprint_Mismatch =>
            return Tasking_RM_Closure_Consumer_Family_Source_Fingerprint;
         when Tasking_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch =>
            return Tasking_RM_Closure_Consumer_Family_Substitution_Fingerprint;
         when Tasking_RM_Closure_Consumer_Closure_Multiple_Prerequisites |
              Tasking_RM_Closure_Consumer_Multiple_Blockers =>
            return Tasking_RM_Closure_Consumer_Family_Multiple;
         when Tasking_RM_Closure_Consumer_Closure_Indeterminate |
              Tasking_RM_Closure_Consumer_Indeterminate =>
            return Tasking_RM_Closure_Consumer_Family_Indeterminate;
         when others =>
            return Tasking_RM_Closure_Consumer_Family_None;
      end case;
   end Family_For;

   function Local_Blocker_Count (C : Tasking_RM_Closure_Consumer_Context) return Natural is
      Count : Natural := 0;
   begin
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         Count := Count + 1;
      end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         Count := Count + 1;
      end if;
      if C.Requires_Tasking_RM
        and then (C.Tasking_RM_Row = Prior.No_Tasking_Generic_RM_Hard_Case
                  or else not Prior.Is_Accepted (C.Tasking_RM_Status))
      then
         Count := Count + 1;
      end if;
      if C.Requires_Stabilized_Closure
        and then (C.Stabilized_Closure_Row = Closure.No_RM_Completion_Stabilized_Closure
                  or else not Closure_Accepted (C.Stabilized_Closure_Status))
      then
         Count := Count + 1;
      end if;
      return Count;
   end Local_Blocker_Count;

   function Classify
     (C : Tasking_RM_Closure_Consumer_Context)
      return Tasking_RM_Closure_Consumer_Status is
      Blockers : constant Natural := Local_Blocker_Count (C);
   begin
      if Blockers > 1 then
         return Tasking_RM_Closure_Consumer_Multiple_Blockers;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Tasking_RM_Closure_Consumer_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Tasking_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Tasking_RM
        and then C.Tasking_RM_Row = Prior.No_Tasking_Generic_RM_Hard_Case
      then
         return Tasking_RM_Closure_Consumer_Missing_Tasking_RM_Row;
      elsif C.Requires_Tasking_RM and then not Prior.Is_Accepted (C.Tasking_RM_Status) then
         return Tasking_RM_Closure_Consumer_Tasking_RM_Blocker;
      elsif C.Requires_Stabilized_Closure
        and then C.Stabilized_Closure_Row = Closure.No_RM_Completion_Stabilized_Closure
      then
         return Tasking_RM_Closure_Consumer_Missing_Stabilized_Closure;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Closure_Status_To_Consumer (C.Stabilized_Closure_Status);
      elsif C.Kind = Prior.Tasking_Generic_RM_Hard_Case_Unknown then
         return Tasking_RM_Closure_Consumer_Indeterminate;
      else
         return Tasking_RM_Closure_Consumer_Accepted;
      end if;
   end Classify;

   function Is_Accepted (Status : Tasking_RM_Closure_Consumer_Status) return Boolean is
   begin
      return Status = Tasking_RM_Closure_Consumer_Accepted;
   end Is_Accepted;

   function Is_Indeterminate (Status : Tasking_RM_Closure_Consumer_Status) return Boolean is
   begin
      return Status = Tasking_RM_Closure_Consumer_Indeterminate
        or else Status = Tasking_RM_Closure_Consumer_Closure_Indeterminate;
   end Is_Indeterminate;

   function Message_For
     (Status : Tasking_RM_Closure_Consumer_Status;
      Kind   : Tasking_RM_Kind;
      Family : Tasking_RM_Closure_Consumer_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("tasking/protected RM-completion stabilized closure consumer " &
         Tasking_RM_Closure_Consumer_Status'Image (Status) &
         " kind=" & Prior.Tasking_Generic_RM_Hard_Case_Kind'Image (Kind) &
         " family=" & Tasking_RM_Closure_Consumer_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Tasking_RM_Closure_Consumer_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_664;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Prior.Tasking_Generic_RM_Hard_Case_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Tasking_RM_Closure_Consumer_Status'Pos (Row.Status) + 1);
      H := Mix (H, Tasking_RM_Closure_Consumer_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Tasking_RM_Closure_Consumer_Context;
      Index : Positive) return Tasking_RM_Closure_Consumer_Row is
      Status : constant Tasking_RM_Closure_Consumer_Status := Classify (C);
      Family : constant Tasking_RM_Closure_Consumer_Family := Family_For (Status);
      Row    : Tasking_RM_Closure_Consumer_Row;
   begin
      Row.Id := Tasking_RM_Closure_Consumer_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Status := Status;
      Row.Family := Family;
      Row.Node := C.Node;
      Row.Operation_Name := C.Operation_Name;
      Row.Type_Name := C.Type_Name;
      Row.State_Name := C.State_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := not Row.Accepted and then not Is_Indeterminate (Status);
      Row.Blocks_Downstream := Row.Blocked or else Is_Indeterminate (Status);
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

   procedure Clear (Model : in out Tasking_RM_Closure_Consumer_Context_Model) is
   begin
      Model.Contexts.Clear;
   end Clear;

   procedure Add_Context
     (Model   : in out Tasking_RM_Closure_Consumer_Context_Model;
      Context : Tasking_RM_Closure_Consumer_Context) is
   begin
      Model.Contexts.Append (Context);
   end Add_Context;

   function Build (Contexts : Tasking_RM_Closure_Consumer_Context_Model) return Tasking_RM_Closure_Consumer_Model is
      Model : Tasking_RM_Closure_Consumer_Model;
      Index : Positive := 1;
   begin
      for C of Contexts.Contexts loop
         declare
            Row : constant Tasking_RM_Closure_Consumer_Row := Make_Row (C, Index);
         begin
            Model.Rows.Append (Row);
            Model.Fingerprint := Mix (Model.Fingerprint, Row.Row_Fingerprint);
            if Row.Accepted then
               Model.Accepted_Total := Model.Accepted_Total + 1;
            end if;
            if Row.Blocked then
               Model.Blocked_Total := Model.Blocked_Total + 1;
            end if;
            if Is_Indeterminate (Row.Status) then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
            Index := Index + 1;
         end;
      end loop;
      return Model;
   end Build;

   function Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Tasking_RM_Closure_Consumer_Model;
      Index : Positive) return Tasking_RM_Closure_Consumer_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Tasking_RM_Closure_Consumer_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Tasking_RM_Closure_Consumer_Set;
      Index : Positive) return Tasking_RM_Closure_Consumer_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Count_By_Status
     (Model  : Tasking_RM_Closure_Consumer_Model;
      Status : Tasking_RM_Closure_Consumer_Status) return Natural is
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
     (Model  : Tasking_RM_Closure_Consumer_Model;
      Family : Tasking_RM_Closure_Consumer_Family) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Family;

   function Accepted_Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Tasking_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Find_By_Node
     (Model : Tasking_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_RM_Closure_Consumer_Set is
      Result : Tasking_RM_Closure_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Tasking_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Tasking_RM_Closure_Consumer_Set is
      Result : Tasking_RM_Closure_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Stable_Fingerprint (Model : Tasking_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Tasking_RM_Completion_Closure_Consumer_Legality;
