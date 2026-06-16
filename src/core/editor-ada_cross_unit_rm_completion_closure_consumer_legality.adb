with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality is

   pragma Suppress (Overflow_Check);

   use type Closure.RM_Completion_Stabilized_Closure_Id;
   use type Closure.RM_Completion_Stabilized_Closure_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Prior.Cross_Unit_RM_Completion_Closure_Id;
   use type Prior.Cross_Unit_RM_Completion_Kind;

   function Mix (Left, Right : Natural) return Natural is
   begin
      return (Left * 131 + Right + 12_683) mod 2_147_483_647;
   end Mix;

   function Closure_Accepted
     (Status : Closure.RM_Completion_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.RM_Completion_Stabilized_Closure_Accepted_Current
        or else Status = Closure.RM_Completion_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepted;

   function Dependency_Status
     (State : Cross_Unit_RM_Dependency_State)
      return Cross_Unit_RM_Closure_Consumer_Status is
   begin
      case State is
         when Prior.RM_Dependency_Missing =>
            return Cross_Unit_RM_Closure_Consumer_Missing_Dependency;
         when Prior.RM_Dependency_Ambiguous =>
            return Cross_Unit_RM_Closure_Consumer_Ambiguous_Dependency;
         when Prior.RM_Dependency_Overflow =>
            return Cross_Unit_RM_Closure_Consumer_Dependency_Overflow;
         when Prior.RM_Dependency_Stale =>
            return Cross_Unit_RM_Closure_Consumer_Stale_Dependency;
         when Prior.RM_Dependency_Unknown =>
            return Cross_Unit_RM_Closure_Consumer_Indeterminate;
         when others =>
            return Cross_Unit_RM_Closure_Consumer_Not_Checked;
      end case;
   end Dependency_Status;

   function Closure_Status_To_Consumer
     (Status : Closure.RM_Completion_Stabilized_Closure_Status)
      return Cross_Unit_RM_Closure_Consumer_Status is
   begin
      case Status is
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Stale_Or_Fingerprint =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_AST_Or_Coverage =>
            return Cross_Unit_RM_Closure_Consumer_Closure_AST_Or_Coverage;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Cross_Unit =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Cross_Unit;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Generic_Substitution =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Generic_Substitution;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Prior_Dataflow =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Prior_Dataflow;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Volatile_Atomic =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Volatile_Atomic;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Overload_Type =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Overload_Type;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Representation =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Representation;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Tasking_Protected =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Tasking_Protected;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Elaboration =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Elaboration;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Accessibility =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Accessibility;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Discriminant_Variant =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Discriminant_Variant;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Exception_Finalization =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Exception_Finalization;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Renaming_Alias =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Renaming_Alias;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Predicate_Invariant =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Predicate_Invariant;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Dataflow =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Dataflow;
         when Closure.RM_Completion_Stabilized_Closure_Blocker_Multiple_Prerequisites =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Multiple_Prerequisites;
         when Closure.RM_Completion_Stabilized_Closure_Recheck_Required =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Recheck_Required;
         when Closure.RM_Completion_Stabilized_Closure_Indeterminate =>
            return Cross_Unit_RM_Closure_Consumer_Closure_Indeterminate;
         when others =>
            return Cross_Unit_RM_Closure_Consumer_Indeterminate;
      end case;
   end Closure_Status_To_Consumer;

   function Family_For
     (Status : Cross_Unit_RM_Closure_Consumer_Status)
      return Cross_Unit_RM_Closure_Consumer_Family is
   begin
      case Status is
         when Cross_Unit_RM_Closure_Consumer_Missing_Cross_Unit_RM_Row |
              Cross_Unit_RM_Closure_Consumer_Cross_Unit_RM_Blocker =>
            return Cross_Unit_RM_Closure_Consumer_Family_Cross_Unit_RM;
         when Cross_Unit_RM_Closure_Consumer_Missing_Stabilized_Closure =>
            return Cross_Unit_RM_Closure_Consumer_Family_Stabilized_Closure;
         when Cross_Unit_RM_Closure_Consumer_Closure_Stale_Or_Fingerprint =>
            return Cross_Unit_RM_Closure_Consumer_Family_Stale_Or_Fingerprint;
         when Cross_Unit_RM_Closure_Consumer_Closure_AST_Or_Coverage =>
            return Cross_Unit_RM_Closure_Consumer_Family_AST_Or_Coverage;
         when Cross_Unit_RM_Closure_Consumer_Closure_Cross_Unit =>
            return Cross_Unit_RM_Closure_Consumer_Family_Cross_Unit;
         when Cross_Unit_RM_Closure_Consumer_Closure_Generic_Substitution =>
            return Cross_Unit_RM_Closure_Consumer_Family_Generic_Substitution;
         when Cross_Unit_RM_Closure_Consumer_Closure_Prior_Dataflow |
              Cross_Unit_RM_Closure_Consumer_Closure_Dataflow =>
            return Cross_Unit_RM_Closure_Consumer_Family_Dataflow;
         when Cross_Unit_RM_Closure_Consumer_Closure_Volatile_Atomic =>
            return Cross_Unit_RM_Closure_Consumer_Family_Volatile_Atomic;
         when Cross_Unit_RM_Closure_Consumer_Closure_Overload_Type =>
            return Cross_Unit_RM_Closure_Consumer_Family_Overload_Type;
         when Cross_Unit_RM_Closure_Consumer_Closure_Representation =>
            return Cross_Unit_RM_Closure_Consumer_Family_Representation;
         when Cross_Unit_RM_Closure_Consumer_Closure_Tasking_Protected =>
            return Cross_Unit_RM_Closure_Consumer_Family_Tasking_Protected;
         when Cross_Unit_RM_Closure_Consumer_Closure_Elaboration =>
            return Cross_Unit_RM_Closure_Consumer_Family_Elaboration;
         when Cross_Unit_RM_Closure_Consumer_Closure_Accessibility =>
            return Cross_Unit_RM_Closure_Consumer_Family_Accessibility;
         when Cross_Unit_RM_Closure_Consumer_Closure_Discriminant_Variant =>
            return Cross_Unit_RM_Closure_Consumer_Family_Discriminant_Variant;
         when Cross_Unit_RM_Closure_Consumer_Closure_Exception_Finalization =>
            return Cross_Unit_RM_Closure_Consumer_Family_Exception_Finalization;
         when Cross_Unit_RM_Closure_Consumer_Closure_Renaming_Alias =>
            return Cross_Unit_RM_Closure_Consumer_Family_Renaming_Alias;
         when Cross_Unit_RM_Closure_Consumer_Closure_Predicate_Invariant =>
            return Cross_Unit_RM_Closure_Consumer_Family_Predicate_Invariant;
         when Cross_Unit_RM_Closure_Consumer_Missing_Dependency |
              Cross_Unit_RM_Closure_Consumer_Ambiguous_Dependency |
              Cross_Unit_RM_Closure_Consumer_Dependency_Overflow |
              Cross_Unit_RM_Closure_Consumer_Stale_Dependency =>
            return Cross_Unit_RM_Closure_Consumer_Family_Dependency;
         when Cross_Unit_RM_Closure_Consumer_Limited_View_Barrier |
              Cross_Unit_RM_Closure_Consumer_Private_View_Barrier =>
            return Cross_Unit_RM_Closure_Consumer_Family_View_Barrier;
         when Cross_Unit_RM_Closure_Consumer_Private_Child_Visibility_Blocker =>
            return Cross_Unit_RM_Closure_Consumer_Family_Private_Child;
         when Cross_Unit_RM_Closure_Consumer_Separate_Body_Blocker =>
            return Cross_Unit_RM_Closure_Consumer_Family_Separate_Body;
         when Cross_Unit_RM_Closure_Consumer_Generic_Body_Unavailable =>
            return Cross_Unit_RM_Closure_Consumer_Family_Generic_Body;
         when Cross_Unit_RM_Closure_Consumer_Generic_Backmapping_Blocker =>
            return Cross_Unit_RM_Closure_Consumer_Family_Generic_Backmapping;
         when Cross_Unit_RM_Closure_Consumer_State_Visibility_Blocker =>
            return Cross_Unit_RM_Closure_Consumer_Family_State_Visibility;
         when Cross_Unit_RM_Closure_Consumer_Source_Fingerprint_Mismatch =>
            return Cross_Unit_RM_Closure_Consumer_Family_Source_Fingerprint;
         when Cross_Unit_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch =>
            return Cross_Unit_RM_Closure_Consumer_Family_Substitution_Fingerprint;
         when Cross_Unit_RM_Closure_Consumer_Closure_Multiple_Prerequisites |
              Cross_Unit_RM_Closure_Consumer_Multiple_Blockers =>
            return Cross_Unit_RM_Closure_Consumer_Family_Multiple;
         when Cross_Unit_RM_Closure_Consumer_Closure_Indeterminate |
              Cross_Unit_RM_Closure_Consumer_Indeterminate =>
            return Cross_Unit_RM_Closure_Consumer_Family_Indeterminate;
         when others =>
            return Cross_Unit_RM_Closure_Consumer_Family_None;
      end case;
   end Family_For;

   function Local_Blocker_Count
     (C : Cross_Unit_RM_Closure_Consumer_Context) return Natural is
      Count : Natural := 0;
   begin
      if Dependency_Status (C.Dependency) /= Cross_Unit_RM_Closure_Consumer_Not_Checked then
         Count := Count + 1;
      end if;
      if C.Limited_View_Barrier then Count := Count + 1; end if;
      if C.Private_View_Barrier then Count := Count + 1; end if;
      if C.Private_Child_Visibility_Blocker then Count := Count + 1; end if;
      if C.Separate_Body_Blocker then Count := Count + 1; end if;
      if C.Generic_Body_Unavailable then Count := Count + 1; end if;
      if C.Generic_Backmapping_Blocker then Count := Count + 1; end if;
      if C.State_Visibility_Blocker then Count := Count + 1; end if;
      if C.Source_Fingerprint /= C.Expected_Source_Fingerprint then Count := Count + 1; end if;
      if C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then Count := Count + 1; end if;
      if C.Requires_Cross_Unit_RM
        and then (C.Cross_Unit_RM_Row = Prior.No_Cross_Unit_RM_Completion_Closure
                  or else not Prior.Is_Accepted (C.Cross_Unit_RM_Status))
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
     (C : Cross_Unit_RM_Closure_Consumer_Context)
      return Cross_Unit_RM_Closure_Consumer_Status is
      Dep_Status : constant Cross_Unit_RM_Closure_Consumer_Status := Dependency_Status (C.Dependency);
      Blockers   : constant Natural := Local_Blocker_Count (C);
   begin
      if Blockers > 1 then
         return Cross_Unit_RM_Closure_Consumer_Multiple_Blockers;
      elsif Dep_Status /= Cross_Unit_RM_Closure_Consumer_Not_Checked then
         return Dep_Status;
      elsif C.Limited_View_Barrier then
         return Cross_Unit_RM_Closure_Consumer_Limited_View_Barrier;
      elsif C.Private_View_Barrier then
         return Cross_Unit_RM_Closure_Consumer_Private_View_Barrier;
      elsif C.Private_Child_Visibility_Blocker then
         return Cross_Unit_RM_Closure_Consumer_Private_Child_Visibility_Blocker;
      elsif C.Separate_Body_Blocker then
         return Cross_Unit_RM_Closure_Consumer_Separate_Body_Blocker;
      elsif C.Generic_Body_Unavailable then
         return Cross_Unit_RM_Closure_Consumer_Generic_Body_Unavailable;
      elsif C.Generic_Backmapping_Blocker then
         return Cross_Unit_RM_Closure_Consumer_Generic_Backmapping_Blocker;
      elsif C.State_Visibility_Blocker then
         return Cross_Unit_RM_Closure_Consumer_State_Visibility_Blocker;
      elsif C.Source_Fingerprint /= C.Expected_Source_Fingerprint then
         return Cross_Unit_RM_Closure_Consumer_Source_Fingerprint_Mismatch;
      elsif C.Substitution_Fingerprint /= C.Expected_Substitution_Fingerprint then
         return Cross_Unit_RM_Closure_Consumer_Substitution_Fingerprint_Mismatch;
      elsif C.Requires_Cross_Unit_RM
        and then C.Cross_Unit_RM_Row = Prior.No_Cross_Unit_RM_Completion_Closure
      then
         return Cross_Unit_RM_Closure_Consumer_Missing_Cross_Unit_RM_Row;
      elsif C.Requires_Cross_Unit_RM and then not Prior.Is_Accepted (C.Cross_Unit_RM_Status) then
         return Cross_Unit_RM_Closure_Consumer_Cross_Unit_RM_Blocker;
      elsif C.Requires_Stabilized_Closure
        and then C.Stabilized_Closure_Row = Closure.No_RM_Completion_Stabilized_Closure
      then
         return Cross_Unit_RM_Closure_Consumer_Missing_Stabilized_Closure;
      elsif C.Requires_Stabilized_Closure and then not Closure_Accepted (C.Stabilized_Closure_Status) then
         return Closure_Status_To_Consumer (C.Stabilized_Closure_Status);
      elsif C.Kind = Prior.Cross_Unit_RM_Completion_Unknown then
         return Cross_Unit_RM_Closure_Consumer_Indeterminate;
      else
         return Cross_Unit_RM_Closure_Consumer_Accepted;
      end if;
   end Classify;

   function Is_Accepted (Status : Cross_Unit_RM_Closure_Consumer_Status) return Boolean is
   begin
      return Status = Cross_Unit_RM_Closure_Consumer_Accepted;
   end Is_Accepted;

   function Is_Indeterminate (Status : Cross_Unit_RM_Closure_Consumer_Status) return Boolean is
   begin
      return Status = Cross_Unit_RM_Closure_Consumer_Indeterminate
        or else Status = Cross_Unit_RM_Closure_Consumer_Closure_Indeterminate;
   end Is_Indeterminate;

   function Message_For
     (Status : Cross_Unit_RM_Closure_Consumer_Status;
      Kind   : Cross_Unit_RM_Kind;
      Family : Cross_Unit_RM_Closure_Consumer_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("cross-unit RM-completion stabilized closure consumer " &
         Cross_Unit_RM_Closure_Consumer_Status'Image (Status) &
         " kind=" & Prior.Cross_Unit_RM_Completion_Kind'Image (Kind) &
         " family=" & Cross_Unit_RM_Closure_Consumer_Family'Image (Family));
   end Message_For;

   function Row_Fingerprint (Row : Cross_Unit_RM_Closure_Consumer_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_668;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Context));
      H := Mix (H, Prior.Cross_Unit_RM_Completion_Kind'Pos (Row.Kind) + 1);
      H := Mix (H, Prior.Cross_Unit_RM_Dependency_State'Pos (Row.Dependency) + 1);
      H := Mix (H, Cross_Unit_RM_Closure_Consumer_Status'Pos (Row.Status) + 1);
      H := Mix (H, Cross_Unit_RM_Closure_Consumer_Family'Pos (Row.Family) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Natural (Row.Unit_Node));
      H := Mix (H, Natural (Row.Dependency_Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (C     : Cross_Unit_RM_Closure_Consumer_Context;
      Index : Positive) return Cross_Unit_RM_Closure_Consumer_Row is
      Status : constant Cross_Unit_RM_Closure_Consumer_Status := Classify (C);
      Family : constant Cross_Unit_RM_Closure_Consumer_Family := Family_For (Status);
      Row    : Cross_Unit_RM_Closure_Consumer_Row;
   begin
      Row.Id := Cross_Unit_RM_Closure_Consumer_Id (Index);
      Row.Context := C.Id;
      Row.Kind := C.Kind;
      Row.Dependency := C.Dependency;
      Row.Status := Status;
      Row.Family := Family;
      Row.Node := C.Node;
      Row.Unit_Node := C.Unit_Node;
      Row.Dependency_Node := C.Dependency_Node;
      Row.Unit_Name := C.Unit_Name;
      Row.Dependency_Name := C.Dependency_Name;
      Row.Generic_Unit_Name := C.Generic_Unit_Name;
      Row.Instance_Name := C.Instance_Name;
      Row.State_Name := C.State_Name;
      Row.Accepted := Is_Accepted (Status);
      Row.Blocked := not Row.Accepted and then not Is_Indeterminate (Status);
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
      Row.Row_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Cross_Unit_RM_Closure_Consumer_Context_Model) is
   begin
      Model.Contexts.Clear;
   end Clear;

   procedure Add_Context
     (Model   : in out Cross_Unit_RM_Closure_Consumer_Context_Model;
      Context : Cross_Unit_RM_Closure_Consumer_Context) is
   begin
      Model.Contexts.Append (Context);
   end Add_Context;

   function Build
     (Contexts : Cross_Unit_RM_Closure_Consumer_Context_Model)
      return Cross_Unit_RM_Closure_Consumer_Model is
      Model : Cross_Unit_RM_Closure_Consumer_Model;
      Index : Positive := 1;
   begin
      for C of Contexts.Contexts loop
         declare
            Row : constant Cross_Unit_RM_Closure_Consumer_Row := Make_Row (C, Index);
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

   function Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Cross_Unit_RM_Closure_Consumer_Model;
      Index : Positive) return Cross_Unit_RM_Closure_Consumer_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Cross_Unit_RM_Closure_Consumer_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Cross_Unit_RM_Closure_Consumer_Set;
      Index : Positive) return Cross_Unit_RM_Closure_Consumer_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   function Count_By_Status
     (Model  : Cross_Unit_RM_Closure_Consumer_Model;
      Status : Cross_Unit_RM_Closure_Consumer_Status) return Natural is
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
     (Model  : Cross_Unit_RM_Closure_Consumer_Model;
      Family : Cross_Unit_RM_Closure_Consumer_Family) return Natural is
      Result : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Family = Family then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_By_Family;

   function Accepted_Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Indeterminate_Count (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Find_By_Node
     (Model : Cross_Unit_RM_Closure_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_RM_Closure_Consumer_Set is
      Result : Cross_Unit_RM_Closure_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Unit
     (Model : Cross_Unit_RM_Closure_Consumer_Model;
      Unit  : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_RM_Closure_Consumer_Set is
      Result : Cross_Unit_RM_Closure_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Unit_Node = Unit then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Unit;

   function Find_By_Source_Fingerprint
     (Model       : Cross_Unit_RM_Closure_Consumer_Model;
      Fingerprint : Natural) return Cross_Unit_RM_Closure_Consumer_Set is
      Result : Cross_Unit_RM_Closure_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Result.Rows.Append (Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Stable_Fingerprint (Model : Cross_Unit_RM_Closure_Consumer_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality;
