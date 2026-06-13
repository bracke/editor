with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Discriminant_Dependent_Legality is

   package Record_Agg renames Editor.Ada_Record_Variant_Aggregate_Legality;
   package Assignments renames Editor.Ada_Assignment_Legality;
   package Conv renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   package Returns renames Editor.Ada_Return_Legality;
   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Record_Agg.Record_Aggregate_Legality_Status;
   use type Assignments.Assignment_Legality_Status;
   use type Conv.Semantic_Legality_Status;
   use type Returns.Return_Legality_Status;
   use type Replay.Replay_Status;
   use type Gates.Enforcement_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 311) + (B * 53) + 1142) mod 1_000_000_007;
   end Mix;

   function Lower (S : String) return String is
      R : String := S;
   begin
      for I in R'Range loop
         R (I) := Ada.Characters.Handling.To_Lower (R (I));
      end loop;
      return R;
   end Lower;

   function Kind_Slot (Kind : Discriminant_Context_Kind) return Natural is
   begin
      return Discriminant_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Discriminant_Legality_Status) return Natural is
   begin
      return Discriminant_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Gate_Is_Blocker (Status : Gates.Enforcement_Status) return Boolean is
   begin
      return Status in
        Gates.Enforcement_Degraded_To_Indeterminate |
        Gates.Enforcement_Cross_Unit_Closure_Required |
        Gates.Enforcement_Legal_Result_Suppressed |
        Gates.Enforcement_Derived_Result_Suppressed |
        Gates.Enforcement_Parser_AST_Blocker |
        Gates.Enforcement_Metadata_Blocker |
        Gates.Enforcement_Consumer_Integration_Blocker |
        Gates.Enforcement_Unsafe_Result_Blocked;
   end Gate_Is_Blocker;

   function Record_Is_Error (Status : Record_Agg.Record_Aggregate_Legality_Status) return Boolean is
   begin
      return Status in
        Record_Agg.Record_Aggregate_Legality_Missing_Component |
        Record_Agg.Record_Aggregate_Legality_Duplicate_Component |
        Record_Agg.Record_Aggregate_Legality_Component_Type_Mismatch |
        Record_Agg.Record_Aggregate_Legality_Positional_After_Named |
        Record_Agg.Record_Aggregate_Legality_Missing_Discriminant |
        Record_Agg.Record_Aggregate_Legality_Duplicate_Discriminant |
        Record_Agg.Record_Aggregate_Legality_Discriminant_Type_Mismatch |
        Record_Agg.Record_Aggregate_Legality_Unconstrained_Without_Discriminants |
        Record_Agg.Record_Aggregate_Legality_Variant_Choice_Missing |
        Record_Agg.Record_Aggregate_Legality_Variant_Choice_Duplicate |
        Record_Agg.Record_Aggregate_Legality_Variant_Choice_Overlap |
        Record_Agg.Record_Aggregate_Legality_Variant_Coverage_Incomplete |
        Record_Agg.Record_Aggregate_Legality_Variant_Choice_Unreachable |
        Record_Agg.Record_Aggregate_Legality_Variant_Layout_Hole |
        Record_Agg.Record_Aggregate_Legality_Variant_Layout_Overlap |
        Record_Agg.Record_Aggregate_Legality_Discriminant_Layout_Error |
        Record_Agg.Record_Aggregate_Legality_Linked_Aggregate_Error |
        Record_Agg.Record_Aggregate_Legality_Linked_Predicate_Invariant_Error |
        Record_Agg.Record_Aggregate_Legality_Linked_Representation_Error |
        Record_Agg.Record_Aggregate_Legality_Private_View_Barrier |
        Record_Agg.Record_Aggregate_Legality_Limited_View_Barrier |
        Record_Agg.Record_Aggregate_Legality_Cross_Unit_Unresolved_View |
        Record_Agg.Record_Aggregate_Legality_Indeterminate;
   end Record_Is_Error;

   function Assignment_Is_Error (Status : Assignments.Assignment_Legality_Status) return Boolean is
   begin
      return Status in
        Assignments.Assignment_Legality_Incompatible_Subtype |
        Assignments.Assignment_Legality_Class_Wide_Incompatible |
        Assignments.Assignment_Legality_Target_Unresolved |
        Assignments.Assignment_Legality_Source_Unresolved |
        Assignments.Assignment_Legality_Private_View_Barrier |
        Assignments.Assignment_Legality_Limited_View_Barrier |
        Assignments.Assignment_Legality_Cross_Unit_Unresolved_View |
        Assignments.Assignment_Legality_Assignment_To_Constant |
        Assignments.Assignment_Legality_Assignment_To_In_Formal |
        Assignments.Assignment_Legality_Null_Exclusion_Violation |
        Assignments.Assignment_Legality_Static_Range_Violation |
        Assignments.Assignment_Legality_Universal_Numeric_Unresolved |
        Assignments.Assignment_Legality_Indeterminate;
   end Assignment_Is_Error;

   function Conversion_Is_Error (Status : Conv.Semantic_Legality_Status) return Boolean is
   begin
      return Status in
        Conv.Semantic_Legality_Target_Unresolved |
        Conv.Semantic_Legality_Operand_Unresolved |
        Conv.Semantic_Legality_Incompatible_Type |
        Conv.Semantic_Legality_Private_View_Barrier |
        Conv.Semantic_Legality_Limited_View_Barrier |
        Conv.Semantic_Legality_Cross_Unit_Unresolved_View |
        Conv.Semantic_Legality_Static_Range_Violation |
        Conv.Semantic_Legality_Null_Exclusion_Violation |
        Conv.Semantic_Legality_Access_Kind_Mismatch |
        Conv.Semantic_Legality_Accessibility_Indeterminate |
        Conv.Semantic_Legality_Illegal_Access_Conversion |
        Conv.Semantic_Legality_Allocator_Designated_Subtype_Mismatch |
        Conv.Semantic_Legality_Aggregate_Missing_Component |
        Conv.Semantic_Legality_Aggregate_Duplicate_Component |
        Conv.Semantic_Legality_Aggregate_Component_Type_Mismatch |
        Conv.Semantic_Legality_Aggregate_Positional_After_Named |
        Conv.Semantic_Legality_Aggregate_Index_Coverage_Error |
        Conv.Semantic_Legality_Container_Aggregate_Missing_Aspect |
        Conv.Semantic_Legality_Universal_Numeric_Unresolved |
        Conv.Semantic_Legality_Indeterminate;
   end Conversion_Is_Error;

   function Return_Is_Error (Status : Returns.Return_Legality_Status) return Boolean is
   begin
      return Status in
        Returns.Return_Legality_Procedure_Return_With_Expression |
        Returns.Return_Legality_Function_Return_Missing_Expression |
        Returns.Return_Legality_Result_Incompatible_Subtype |
        Returns.Return_Legality_Result_Class_Wide_Incompatible |
        Returns.Return_Legality_Result_Private_View_Barrier |
        Returns.Return_Legality_Result_Limited_View_Barrier |
        Returns.Return_Legality_Result_Cross_Unit_Unresolved_View |
        Returns.Return_Legality_Result_Target_Unresolved |
        Returns.Return_Legality_Result_Source_Unresolved |
        Returns.Return_Legality_Result_Static_Range_Violation |
        Returns.Return_Legality_Result_Universal_Numeric_Unresolved |
        Returns.Return_Legality_No_Return_Subprogram_Return |
        Returns.Return_Legality_Indeterminate;
   end Return_Is_Error;

   function Replay_Is_Error (Status : Replay.Replay_Status) return Boolean is
   begin
      return Status in
        Replay.Replay_Generic_Expansion_Error |
        Replay.Replay_Overload_Preference_Error |
        Replay.Replay_Flow_Effect_Error |
        Replay.Replay_Predicate_Propagation_Error |
        Replay.Replay_Accessibility_Precision_Error |
        Replay.Replay_Representation_Freezing_Error |
        Replay.Replay_Coverage_Gate_Blocker |
        Replay.Replay_Source_Instance_Mapping_Missing |
        Replay.Replay_Formal_Actual_Mapping_Missing |
        Replay.Replay_Diagnostic_Backmap_Missing |
        Replay.Replay_Multiple_Blockers |
        Replay.Replay_Indeterminate;
   end Replay_Is_Error;

   function Is_Legal (Status : Discriminant_Legality_Status) return Boolean is
   begin
      return Status in
        Discriminant_Legality_Legal_Constrained_Record |
        Discriminant_Legality_Legal_Unconstrained_With_Defaults |
        Discriminant_Legality_Legal_Discriminant_Default |
        Discriminant_Legality_Legal_Variant_Presence |
        Discriminant_Legality_Legal_Aggregate_Discriminants |
        Discriminant_Legality_Legal_Assignment_Check |
        Discriminant_Legality_Legal_Conversion_Check |
        Discriminant_Legality_Legal_Return_Check |
        Discriminant_Legality_Legal_Allocator_Check |
        Discriminant_Legality_Legal_Generic_Actual_Check;
   end Is_Legal;

   function Context_Fingerprint (Info : Discriminant_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Length (Info.Type_Name) + 1);
      H := Mix (H, Length (Info.Object_Name) + 1);
      H := Mix (H, Info.Discriminant_Count + 1);
      H := Mix (H, Info.Expected_Discriminant_Count + 1);
      H := Mix (H, Info.Missing_Discriminant_Count + 1);
      H := Mix (H, Info.Duplicate_Discriminant_Count + 1);
      H := Mix (H, Info.Type_Mismatch_Count + 1);
      H := Mix (H, Info.Defaulted_Discriminant_Count + 1);
      H := Mix (H, Info.Nonstatic_Default_Count + 1);
      H := Mix (H, Info.Out_Of_Range_Default_Count + 1);
      H := Mix (H, Info.Later_Dependent_Default_Count + 1);
      H := Mix (H, Boolean'Pos (Info.Type_Is_Constrained) + 1);
      H := Mix (H, Boolean'Pos (Info.Type_Is_Unconstrained) + 1);
      H := Mix (H, Boolean'Pos (Info.Object_Is_Constrained) + 1);
      H := Mix (H, Boolean'Pos (Info.Discriminant_Value_Changed) + 1);
      H := Mix (H, Info.Variant_Choice_Count + 1);
      H := Mix (H, Info.Expected_Variant_Choice_Count + 1);
      H := Mix (H, Boolean'Pos (Info.Missing_Variant_For_Value) + 1);
      H := Mix (H, Boolean'Pos (Info.Forbidden_Variant_For_Value) + 1);
      H := Mix (H, Info.Variant_Overlap_Count + 1);
      H := Mix (H, Info.Variant_Coverage_Gap_Count + 1);
      H := Mix (H, Boolean'Pos (Info.Private_Full_View_Mismatch) + 1);
      H := Mix (H, Gates.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Discriminant_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Type_Name) + Length (Info.Object_Name) + 1);
      H := Mix (H, Info.Discriminant_Count + 1);
      H := Mix (H, Info.Expected_Discriminant_Count + 1);
      H := Mix (H, Info.Variant_Choice_Count + 1);
      H := Mix (H, Info.Expected_Variant_Choice_Count + 1);
      H := Mix (H, Info.Blocker_Count + 1);
      H := Mix (H, Gates.Enforcement_Status'Pos (Info.Gate_Status) + 1);
      H := Mix (H, Length (Info.Message) + Length (Info.Detail) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Discriminant_Legality_Status) return String is
   begin
      case Status is
         when Discriminant_Legality_Legal_Constrained_Record =>
            return "constrained discriminated record is legal";
         when Discriminant_Legality_Legal_Unconstrained_With_Defaults =>
            return "unconstrained discriminated record has usable defaults";
         when Discriminant_Legality_Legal_Discriminant_Default =>
            return "discriminant default is static and range compatible";
         when Discriminant_Legality_Legal_Variant_Presence =>
            return "variant part is present exactly for the governing discriminant value";
         when Discriminant_Legality_Legal_Aggregate_Discriminants =>
            return "aggregate discriminant associations are legal";
         when Discriminant_Legality_Legal_Assignment_Check =>
            return "assignment preserves discriminant constraints";
         when Discriminant_Legality_Legal_Conversion_Check =>
            return "conversion preserves discriminant constraints";
         when Discriminant_Legality_Legal_Return_Check =>
            return "return preserves discriminant constraints";
         when Discriminant_Legality_Legal_Allocator_Check =>
            return "allocator preserves discriminant constraints";
         when Discriminant_Legality_Legal_Generic_Actual_Check =>
            return "generic actual satisfies formal discriminant constraints";
         when Discriminant_Legality_Missing_Discriminant_Constraint =>
            return "required discriminant constraint is missing";
         when Discriminant_Legality_Duplicate_Discriminant_Constraint =>
            return "duplicate discriminant constraint";
         when Discriminant_Legality_Discriminant_Type_Mismatch =>
            return "discriminant constraint type mismatch";
         when Discriminant_Legality_Default_Not_Static =>
            return "discriminant default is not static";
         when Discriminant_Legality_Default_Out_Of_Range =>
            return "discriminant default is outside the discriminant subtype";
         when Discriminant_Legality_Default_Depends_On_Later_Discriminant =>
            return "discriminant default depends on a later discriminant";
         when Discriminant_Legality_Unconstrained_Record_Without_Defaults =>
            return "unconstrained discriminated record has no usable defaults";
         when Discriminant_Legality_Constrained_Object_Discriminant_Changed =>
            return "constrained object's discriminant value would change";
         when Discriminant_Legality_Assignment_Discriminant_Mismatch =>
            return "assignment discriminant values do not match";
         when Discriminant_Legality_Conversion_Discriminant_Mismatch =>
            return "conversion discriminant values do not match";
         when Discriminant_Legality_Return_Discriminant_Mismatch =>
            return "return discriminant values do not match";
         when Discriminant_Legality_Allocator_Discriminant_Mismatch =>
            return "allocator discriminant values do not match";
         when Discriminant_Legality_Generic_Actual_Discriminant_Mismatch =>
            return "generic actual discriminants do not satisfy the formal";
         when Discriminant_Legality_Variant_Missing_For_Value =>
            return "variant component is missing for the governing discriminant value";
         when Discriminant_Legality_Variant_Forbidden_For_Value =>
            return "variant component is present for a nonmatching discriminant value";
         when Discriminant_Legality_Variant_Choice_Overlap =>
            return "variant choices overlap";
         when Discriminant_Legality_Variant_Choice_Coverage_Gap =>
            return "variant choices do not cover required discriminant values";
         when Discriminant_Legality_Linked_Record_Aggregate_Error =>
            return "linked record/variant aggregate legality failed";
         when Discriminant_Legality_Linked_Assignment_Error =>
            return "linked assignment legality failed";
         when Discriminant_Legality_Linked_Conversion_Error =>
            return "linked conversion/allocator legality failed";
         when Discriminant_Legality_Linked_Return_Error =>
            return "linked return legality failed";
         when Discriminant_Legality_Linked_Generic_Replay_Error =>
            return "linked generic replay legality failed";
         when Discriminant_Legality_Private_Full_View_Mismatch =>
            return "private view and full view have incompatible discriminant facts";
         when Discriminant_Legality_Coverage_Gate_Blocker =>
            return "coverage gate blocks confident discriminant-dependent legality";
         when Discriminant_Legality_Multiple_Blockers =>
            return "multiple discriminant-dependent legality blockers";
         when Discriminant_Legality_Indeterminate =>
            return "discriminant-dependent legality is indeterminate";
         when Discriminant_Legality_Not_Checked =>
            return "discriminant-dependent legality was not checked";
      end case;
   end Message_For;

   function Detail_For (Info : Discriminant_Context_Info) return String is
   begin
      return "type=" & To_String (Info.Type_Name) &
        ", object=" & To_String (Info.Object_Name) &
        ", discriminants=" & Natural'Image (Info.Discriminant_Count) &
        ", expected=" & Natural'Image (Info.Expected_Discriminant_Count) &
        ", variants=" & Natural'Image (Info.Variant_Choice_Count);
   end Detail_For;

   function Determine_Status (Info : Discriminant_Context_Info) return Discriminant_Legality_Status is
      Blockers : Natural := 0;
      Result   : Discriminant_Legality_Status := Discriminant_Legality_Not_Checked;
   begin
      if Gate_Is_Blocker (Info.Gate_Status) then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Coverage_Gate_Blocker;
      end if;
      if Record_Is_Error (Info.Linked_Record_Status) then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Linked_Record_Aggregate_Error;
      end if;
      if Assignment_Is_Error (Info.Linked_Assignment_Status) then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Linked_Assignment_Error;
      end if;
      if Conversion_Is_Error (Info.Linked_Conversion_Status) then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Linked_Conversion_Error;
      end if;
      if Return_Is_Error (Info.Linked_Return_Status) then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Linked_Return_Error;
      end if;
      if Replay_Is_Error (Info.Linked_Replay_Status) then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Linked_Generic_Replay_Error;
      end if;
      if Info.Private_Full_View_Mismatch then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Private_Full_View_Mismatch;
      end if;
      if Info.Missing_Discriminant_Count > 0 then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Missing_Discriminant_Constraint;
      end if;
      if Info.Duplicate_Discriminant_Count > 0 then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Duplicate_Discriminant_Constraint;
      end if;
      if Info.Type_Mismatch_Count > 0 then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Discriminant_Type_Mismatch;
      end if;
      if Info.Nonstatic_Default_Count > 0 then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Default_Not_Static;
      end if;
      if Info.Out_Of_Range_Default_Count > 0 then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Default_Out_Of_Range;
      end if;
      if Info.Later_Dependent_Default_Count > 0 then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Default_Depends_On_Later_Discriminant;
      end if;
      if Info.Type_Is_Unconstrained and then Info.Defaulted_Discriminant_Count = 0
        and then Info.Expected_Discriminant_Count > 0
      then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Unconstrained_Record_Without_Defaults;
      end if;
      if Info.Object_Is_Constrained and then Info.Discriminant_Value_Changed then
         Blockers := Blockers + 1;
         case Info.Kind is
            when Discriminant_Context_Assignment =>
               Result := Discriminant_Legality_Assignment_Discriminant_Mismatch;
            when Discriminant_Context_Conversion =>
               Result := Discriminant_Legality_Conversion_Discriminant_Mismatch;
            when Discriminant_Context_Return =>
               Result := Discriminant_Legality_Return_Discriminant_Mismatch;
            when Discriminant_Context_Allocator =>
               Result := Discriminant_Legality_Allocator_Discriminant_Mismatch;
            when Discriminant_Context_Generic_Actual =>
               Result := Discriminant_Legality_Generic_Actual_Discriminant_Mismatch;
            when others =>
               Result := Discriminant_Legality_Constrained_Object_Discriminant_Changed;
         end case;
      end if;
      if Info.Missing_Variant_For_Value then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Variant_Missing_For_Value;
      end if;
      if Info.Forbidden_Variant_For_Value then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Variant_Forbidden_For_Value;
      end if;
      if Info.Variant_Overlap_Count > 0 then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Variant_Choice_Overlap;
      end if;
      if Info.Variant_Coverage_Gap_Count > 0 then
         Blockers := Blockers + 1;
         Result := Discriminant_Legality_Variant_Choice_Coverage_Gap;
      end if;

      if Blockers > 1 then
         return Discriminant_Legality_Multiple_Blockers;
      elsif Blockers = 1 then
         return Result;
      end if;

      case Info.Kind is
         when Discriminant_Context_Record_Type =>
            if Info.Type_Is_Constrained then
               return Discriminant_Legality_Legal_Constrained_Record;
            elsif Info.Defaulted_Discriminant_Count > 0 then
               return Discriminant_Legality_Legal_Unconstrained_With_Defaults;
            else
               return Discriminant_Legality_Indeterminate;
            end if;
         when Discriminant_Context_Discriminant_Default =>
            return Discriminant_Legality_Legal_Discriminant_Default;
         when Discriminant_Context_Variant_Part =>
            return Discriminant_Legality_Legal_Variant_Presence;
         when Discriminant_Context_Record_Aggregate |
              Discriminant_Context_Discriminant_Constraint =>
            return Discriminant_Legality_Legal_Aggregate_Discriminants;
         when Discriminant_Context_Assignment =>
            return Discriminant_Legality_Legal_Assignment_Check;
         when Discriminant_Context_Conversion =>
            return Discriminant_Legality_Legal_Conversion_Check;
         when Discriminant_Context_Return =>
            return Discriminant_Legality_Legal_Return_Check;
         when Discriminant_Context_Allocator =>
            return Discriminant_Legality_Legal_Allocator_Check;
         when Discriminant_Context_Generic_Actual =>
            return Discriminant_Legality_Legal_Generic_Actual_Check;
         when others =>
            return Discriminant_Legality_Indeterminate;
      end case;
   end Determine_Status;

   function Blocker_Count (Info : Discriminant_Context_Info) return Natural is
      Count : Natural := 0;
   begin
      if Gate_Is_Blocker (Info.Gate_Status) then Count := Count + 1; end if;
      if Record_Is_Error (Info.Linked_Record_Status) then Count := Count + 1; end if;
      if Assignment_Is_Error (Info.Linked_Assignment_Status) then Count := Count + 1; end if;
      if Conversion_Is_Error (Info.Linked_Conversion_Status) then Count := Count + 1; end if;
      if Return_Is_Error (Info.Linked_Return_Status) then Count := Count + 1; end if;
      if Replay_Is_Error (Info.Linked_Replay_Status) then Count := Count + 1; end if;
      if Info.Private_Full_View_Mismatch then Count := Count + 1; end if;
      Count := Count + Info.Missing_Discriminant_Count + Info.Duplicate_Discriminant_Count + Info.Type_Mismatch_Count;
      Count := Count + Info.Nonstatic_Default_Count + Info.Out_Of_Range_Default_Count + Info.Later_Dependent_Default_Count;
      if Info.Type_Is_Unconstrained and then Info.Defaulted_Discriminant_Count = 0
        and then Info.Expected_Discriminant_Count > 0
      then Count := Count + 1; end if;
      if Info.Object_Is_Constrained and then Info.Discriminant_Value_Changed then Count := Count + 1; end if;
      if Info.Missing_Variant_For_Value then Count := Count + 1; end if;
      if Info.Forbidden_Variant_For_Value then Count := Count + 1; end if;
      Count := Count + Info.Variant_Overlap_Count + Info.Variant_Coverage_Gap_Count;
      return Count;
   end Blocker_Count;

   procedure Clear (Model : in out Discriminant_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Discriminant_Context_Model;
      Info  : Discriminant_Context_Info)
   is
      Next : Discriminant_Context_Info := Info;
   begin
      if Next.Id = No_Discriminant_Context then
         Next.Id := Discriminant_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      Model.Contexts.Append (Next);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context_Fingerprint (Next));
   end Add_Context;

   function Context_Count (Model : Discriminant_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Discriminant_Context_Model;
      Index : Positive) return Discriminant_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Discriminant_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Discriminant_Context_Model) return Discriminant_Legality_Model is
      Model : Discriminant_Legality_Model;
   begin
      for Index in 1 .. Natural (Contexts.Contexts.Length) loop
         declare
            C : constant Discriminant_Context_Info := Contexts.Contexts.Element (Index);
            R : Discriminant_Legality_Info;
         begin
            R.Id := Discriminant_Legality_Id (Index);
            R.Context := C.Id;
            R.Kind := C.Kind;
            R.Node := C.Node;
            R.Status := Determine_Status (C);
            R.Type_Name := C.Type_Name;
            R.Object_Name := C.Object_Name;
            R.Message := To_Unbounded_String (Message_For (R.Status));
            R.Detail := To_Unbounded_String (Detail_For (C));
            R.Discriminant_Count := C.Discriminant_Count;
            R.Expected_Discriminant_Count := C.Expected_Discriminant_Count;
            R.Variant_Choice_Count := C.Variant_Choice_Count;
            R.Expected_Variant_Choice_Count := C.Expected_Variant_Choice_Count;
            R.Blocker_Count := Blocker_Count (C);
            R.Gate_Status := C.Gate_Status;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Fingerprint := Row_Fingerprint (R);
            Model.Rows.Append (R);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Discriminant_Legality_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Discriminant_Legality_Model;
      Index : Positive) return Discriminant_Legality_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node
     (Model : Discriminant_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Discriminant_Legality_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Discriminant_Legality_Model;
      Status : Discriminant_Legality_Status) return Discriminant_Result_Set is
      Results : Discriminant_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Discriminant_Legality_Model;
      Kind  : Discriminant_Context_Kind) return Discriminant_Result_Set is
      Results : Discriminant_Result_Set;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Type
     (Model     : Discriminant_Legality_Model;
      Type_Name : String) return Discriminant_Result_Set is
      Results : Discriminant_Result_Set;
      Key     : constant String := Lower (Type_Name);
   begin
      for Row of Model.Rows loop
         if Lower (To_String (Row.Type_Name)) = Key then
            Results.Items.Append (Row);
            Results.Fingerprint := Mix (Results.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rows_For_Type;

   function Result_Count (Results : Discriminant_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Discriminant_Result_Set;
      Index   : Positive) return Discriminant_Legality_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Discriminant_Legality_Model;
      Status : Discriminant_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Discriminant_Legality_Model;
      Kind  : Discriminant_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Kind = Kind then Count := Count + 1; end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Discriminant_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Is_Legal (Row.Status) then Count := Count + 1; end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Discriminant_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if not Is_Legal (Row.Status)
           and then Row.Status /= Discriminant_Legality_Not_Checked
           and then Row.Status /= Discriminant_Legality_Indeterminate
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Variant_Error_Count (Model : Discriminant_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Discriminant_Legality_Variant_Missing_For_Value |
           Discriminant_Legality_Variant_Forbidden_For_Value |
           Discriminant_Legality_Variant_Choice_Overlap |
           Discriminant_Legality_Variant_Choice_Coverage_Gap
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Variant_Error_Count;

   function Default_Error_Count (Model : Discriminant_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Discriminant_Legality_Default_Not_Static |
           Discriminant_Legality_Default_Out_Of_Range |
           Discriminant_Legality_Default_Depends_On_Later_Discriminant
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Default_Error_Count;

   function Use_Site_Error_Count (Model : Discriminant_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Discriminant_Legality_Constrained_Object_Discriminant_Changed |
           Discriminant_Legality_Assignment_Discriminant_Mismatch |
           Discriminant_Legality_Conversion_Discriminant_Mismatch |
           Discriminant_Legality_Return_Discriminant_Mismatch |
           Discriminant_Legality_Allocator_Discriminant_Mismatch |
           Discriminant_Legality_Generic_Actual_Discriminant_Mismatch
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Use_Site_Error_Count;

   function Linked_Error_Count (Model : Discriminant_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Discriminant_Legality_Linked_Record_Aggregate_Error |
           Discriminant_Legality_Linked_Assignment_Error |
           Discriminant_Legality_Linked_Conversion_Error |
           Discriminant_Legality_Linked_Return_Error |
           Discriminant_Legality_Linked_Generic_Replay_Error |
           Discriminant_Legality_Multiple_Blockers
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Linked_Error_Count;

   function Coverage_Gate_Error_Count (Model : Discriminant_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status in Discriminant_Legality_Coverage_Gate_Blocker |
           Discriminant_Legality_Multiple_Blockers
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Coverage_Gate_Error_Count;

   function Indeterminate_Count (Model : Discriminant_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Status = Discriminant_Legality_Indeterminate then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Indeterminate_Count;

   function Fingerprint (Model : Discriminant_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Discriminant_Legality_Info) return Boolean is
   begin
      return Info.Status /= Discriminant_Legality_Not_Checked;
   end Has_Legality;

end Editor.Ada_Discriminant_Dependent_Legality;
