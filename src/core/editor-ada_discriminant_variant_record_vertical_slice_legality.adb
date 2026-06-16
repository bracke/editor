with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Discriminant_Variant_Record_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1313) mod 1_000_000_007;
   end Mix;

   function Is_Record_View (View : Record_View_Kind) return Boolean is
   begin
      return View in View_Full_Record
        | View_Private_Record
        | View_Limited_Record
        | View_Tagged_Record
        | View_Record_Extension
        | View_Formal_Record;
   end Is_Record_View;

   function Needs_Record (Kind : Record_Construct_Kind) return Boolean is
   begin
      return Kind /= Unknown_Construct;
   end Needs_Record;

   function Needs_Discriminants (Kind : Record_Construct_Kind) return Boolean is
   begin
      return Kind in Discriminant_Part
        | Discriminant_Constraint
        | Variant_Part
        | Variant_Alternative;
   end Needs_Discriminants;

   function Needs_Aggregate_Check (Kind : Record_Construct_Kind) return Boolean is
   begin
      return Kind in Record_Aggregate | Record_Delta_Aggregate;
   end Needs_Aggregate_Check;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Context_Blockers
        + R.Record_View_Blockers
        + R.Discriminant_Missing_Blockers
        + R.Discriminant_Type_Blockers
        + R.Discriminant_Default_Blockers
        + R.Discriminant_Constraint_Blockers
        + R.Discriminant_Dependent_Component_Blockers
        + R.Variant_Governing_Discriminant_Blockers
        + R.Variant_Coverage_Blockers
        + R.Variant_Choice_Overlap_Blockers
        + R.Variant_Choice_Static_Blockers
        + R.Variant_Inactive_Component_Blockers
        + R.Aggregate_Discriminant_Blockers
        + R.Aggregate_Component_Missing_Blockers
        + R.Aggregate_Component_Duplicate_Blockers
        + R.Aggregate_Component_Type_Blockers
        + R.Aggregate_Named_Positional_Blockers
        + R.Delta_Target_Blockers
        + R.Delta_Component_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Tagged_Extension_Blockers
        + R.Representation_Layout_Blockers
        + R.Controlled_Finalization_Blockers
        + R.Accessibility_Blockers
        + R.Initialization_Blockers
        + R.Subtype_Range_Blockers
        + R.Predicate_Blockers
        + R.Overload_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Layout_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; Info : Record_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Context_Blockers > 0 then
         return Legality_Missing_Context;
      elsif R.Record_View_Blockers > 0 then
         return Legality_Not_Record;
      elsif R.Discriminant_Missing_Blockers > 0 then
         return Legality_Discriminant_Missing;
      elsif R.Discriminant_Type_Blockers > 0 then
         return Legality_Discriminant_Type_Mismatch;
      elsif R.Discriminant_Default_Blockers > 0 then
         return Legality_Discriminant_Default_Mismatch;
      elsif R.Discriminant_Constraint_Blockers > 0 then
         return Legality_Discriminant_Constraint_Mismatch;
      elsif R.Discriminant_Dependent_Component_Blockers > 0 then
         return Legality_Discriminant_Dependent_Component_Blocked;
      elsif R.Variant_Governing_Discriminant_Blockers > 0 then
         return Legality_Variant_Part_Missing_Discriminant;
      elsif R.Variant_Coverage_Blockers > 0 then
         return Legality_Variant_Coverage_Incomplete;
      elsif R.Variant_Choice_Overlap_Blockers > 0 then
         return Legality_Variant_Choice_Overlap;
      elsif R.Variant_Choice_Static_Blockers > 0 then
         return Legality_Variant_Choice_Not_Static;
      elsif R.Variant_Inactive_Component_Blockers > 0 then
         return Legality_Variant_Component_Inactive;
      elsif R.Aggregate_Discriminant_Blockers > 0 then
         return Legality_Record_Aggregate_Discriminant_Missing;
      elsif R.Aggregate_Component_Missing_Blockers > 0 then
         return Legality_Record_Aggregate_Component_Missing;
      elsif R.Aggregate_Component_Duplicate_Blockers > 0 then
         return Legality_Record_Aggregate_Component_Duplicate;
      elsif R.Aggregate_Component_Type_Blockers > 0 then
         return Legality_Record_Aggregate_Component_Type_Mismatch;
      elsif R.Aggregate_Named_Positional_Blockers > 0 then
         return Legality_Record_Aggregate_Named_Positional_Mix;
      elsif R.Delta_Target_Blockers > 0 then
         return Legality_Delta_Update_Target_Missing;
      elsif R.Delta_Component_Blockers > 0 then
         return Legality_Delta_Update_Component_Mismatch;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Tagged_Extension_Blockers > 0 then
         return Legality_Tagged_Extension_Blocked;
      elsif R.Representation_Layout_Blockers > 0 then
         return Legality_Representation_Layout_Conflict;
      elsif R.Controlled_Finalization_Blockers > 0 then
         return Legality_Controlled_Finalization_Blocked;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocked;
      elsif R.Initialization_Blockers > 0 then
         return Legality_Initialization_Blocked;
      elsif R.Subtype_Range_Blockers > 0 then
         return Legality_Subtype_Range_Blocked;
      elsif R.Predicate_Blockers > 0 then
         return Legality_Predicate_Blocked;
      elsif R.Overload_Blockers > 0 then
         return Legality_Overload_Blocked;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Legality_Type_Fingerprint_Mismatch;
      elsif R.Layout_Fingerprint_Blockers > 0 then
         return Legality_Layout_Fingerprint_Mismatch;
      elsif Info.Kind = Unknown_Construct
        or else Info.View = View_Unknown
        or else Info.Discriminant = Discriminant_Unknown
        or else Info.Coverage = Coverage_Unknown
      then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_With_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Clear (Model : in out Record_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Record (Model : in out Record_Model; Info : Record_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Record_Construct_Kind'Pos (Info.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Record_View_Kind'Pos (Info.View)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Layout_Fingerprint);
   end Add_Record;

   function Build (Records : Record_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for Info of Records.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Record_Ref := Info.Id;
            R.Node := Info.Node;
            R.Kind := Info.Kind;
            R.Runtime_Check_Required := Info.Runtime_Variant_Check_Required;
            R.Source_Fingerprint := Info.Source_Fingerprint;
            R.AST_Fingerprint := Info.AST_Fingerprint;
            R.Type_Fingerprint := Info.Type_Fingerprint;
            R.Layout_Fingerprint := Info.Layout_Fingerprint;

            if not Info.Has_AST_Coverage then
               R.AST_Blockers := R.AST_Blockers + 1;
            end if;
            if not Info.Has_Context then
               R.Context_Blockers := R.Context_Blockers + 1;
            end if;
            if Needs_Record (Info.Kind) and then not Is_Record_View (Info.View) then
               R.Record_View_Blockers := R.Record_View_Blockers + 1;
            end if;
            if Needs_Discriminants (Info.Kind)
              and then Info.Required_Discriminant_Count > Info.Supplied_Discriminant_Count
              and then Info.Discriminant /= Discriminant_Defaulted
            then
               R.Discriminant_Missing_Blockers := R.Discriminant_Missing_Blockers + 1;
            end if;
            if not Info.Discriminant_Type_Compatible then
               R.Discriminant_Type_Blockers := R.Discriminant_Type_Blockers + 1;
            end if;
            if not Info.Discriminant_Default_Compatible then
               R.Discriminant_Default_Blockers := R.Discriminant_Default_Blockers + 1;
            end if;
            if not Info.Discriminant_Constraint_Compatible then
               R.Discriminant_Constraint_Blockers := R.Discriminant_Constraint_Blockers + 1;
            end if;
            if not Info.Discriminant_Dependent_Component_Legal then
               R.Discriminant_Dependent_Component_Blockers := R.Discriminant_Dependent_Component_Blockers + 1;
            end if;
            if Info.Kind in Variant_Part | Variant_Alternative
              and then not Info.Variant_Has_Governing_Discriminant
            then
               R.Variant_Governing_Discriminant_Blockers := R.Variant_Governing_Discriminant_Blockers + 1;
            end if;
            if Info.Kind in Variant_Part | Variant_Alternative then
               case Info.Coverage is
                  when Coverage_Missing_Alternative =>
                     R.Variant_Coverage_Blockers := R.Variant_Coverage_Blockers + 1;
                  when Coverage_Overlapping_Choices =>
                     R.Variant_Choice_Overlap_Blockers := R.Variant_Choice_Overlap_Blockers + 1;
                  when Coverage_Non_Static_Choice =>
                     R.Variant_Choice_Static_Blockers := R.Variant_Choice_Static_Blockers + 1;
                  when others =>
                     null;
               end case;
            end if;
            if Info.Kind in Component_Selection | Record_Delta_Aggregate
              and then not Info.Selected_Variant_Active
              and then not Info.Runtime_Variant_Check_Required
            then
               R.Variant_Inactive_Component_Blockers := R.Variant_Inactive_Component_Blockers + 1;
            end if;
            if Needs_Aggregate_Check (Info.Kind) then
               if Info.Required_Discriminant_Count > Info.Supplied_Discriminant_Count
                 and then Info.Discriminant /= Discriminant_Defaulted
               then
                  R.Aggregate_Discriminant_Blockers := R.Aggregate_Discriminant_Blockers + 1;
               end if;
               if Info.Aggregate_Component_Count < Info.Required_Component_Count then
                  R.Aggregate_Component_Missing_Blockers := R.Aggregate_Component_Missing_Blockers + 1;
               end if;
               if Info.Has_Duplicate_Component then
                  R.Aggregate_Component_Duplicate_Blockers := R.Aggregate_Component_Duplicate_Blockers + 1;
               end if;
               if not Info.Component_Type_Compatible then
                  R.Aggregate_Component_Type_Blockers := R.Aggregate_Component_Type_Blockers + 1;
               end if;
               if Info.Mixes_Named_And_Positional then
                  R.Aggregate_Named_Positional_Blockers := R.Aggregate_Named_Positional_Blockers + 1;
               end if;
            end if;
            if Info.Kind = Record_Delta_Aggregate then
               if not Info.Has_Delta_Update_Target then
                  R.Delta_Target_Blockers := R.Delta_Target_Blockers + 1;
               end if;
               if not Info.Delta_Update_Component_Compatible then
                  R.Delta_Component_Blockers := R.Delta_Component_Blockers + 1;
               end if;
            end if;
            if Info.View = View_Private_Record and then not Info.Private_View_Available then
               R.Private_View_Blockers := R.Private_View_Blockers + 1;
            end if;
            if Info.View = View_Limited_Record and then not Info.Limited_View_Available then
               R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
            end if;
            if Info.Kind = Record_Extension_Declaration and then not Info.Tagged_Extension_Legal then
               R.Tagged_Extension_Blockers := R.Tagged_Extension_Blockers + 1;
            end if;
            if not Info.Representation_Layout_Legal then
               R.Representation_Layout_Blockers := R.Representation_Layout_Blockers + 1;
            end if;
            if not Info.Controlled_Finalization_Legal then
               R.Controlled_Finalization_Blockers := R.Controlled_Finalization_Blockers + 1;
            end if;
            if not Info.Accessibility_Legal then
               R.Accessibility_Blockers := R.Accessibility_Blockers + 1;
            end if;
            if not Info.Initialization_Legal then
               R.Initialization_Blockers := R.Initialization_Blockers + 1;
            end if;
            if not Info.Subtype_Range_Legal then
               R.Subtype_Range_Blockers := R.Subtype_Range_Blockers + 1;
            end if;
            if not Info.Predicate_Legal then
               R.Predicate_Blockers := R.Predicate_Blockers + 1;
            end if;
            if not Info.Overload_Legal then
               R.Overload_Blockers := R.Overload_Blockers + 1;
            end if;
            if Info.Expected_Source_Fingerprint /= 0
              and then Info.Expected_Source_Fingerprint /= Info.Source_Fingerprint
            then
               R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
            end if;
            if Info.Expected_AST_Fingerprint /= 0
              and then Info.Expected_AST_Fingerprint /= Info.AST_Fingerprint
            then
               R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
            end if;
            if Info.Expected_Type_Fingerprint /= 0
              and then Info.Expected_Type_Fingerprint /= Info.Type_Fingerprint
            then
               R.Type_Fingerprint_Blockers := R.Type_Fingerprint_Blockers + 1;
            end if;
            if Info.Expected_Layout_Fingerprint /= 0
              and then Info.Expected_Layout_Fingerprint /= Info.Layout_Fingerprint
            then
               R.Layout_Fingerprint_Blockers := R.Layout_Fingerprint_Blockers + 1;
            end if;

            R.Status := Status_For (R, Info);
            R.Message := To_Unbounded_String (Legality_Status'Image (R.Status));
            R.Detail := Info.Source_Name;
            R.Fingerprint := Mix (Natural (R.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Record_Construct_Kind'Pos (R.Kind)));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Record_View_Kind'Pos (Info.View)));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Type_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Layout_Fingerprint);

            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   function Record_Count (Model : Record_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Record_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Legal_Count (Model : Result_Model) return Natural is
   begin
      return Count_Status (Model, Legality_Legal)
        + Count_Status (Model, Legality_Legal_With_Runtime_Check);
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
   begin
      return Result_Count (Model) - Legal_Count (Model);
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result and then Info.Status /= Legality_Not_Checked;
   end Has_Result;

end Editor.Ada_Discriminant_Variant_Record_Vertical_Slice_Legality;
