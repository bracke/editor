with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Array_Container_Indexing_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1312) mod 1_000_000_007;
   end Mix;

   function Is_Array (Kind : Composite_Kind) return Boolean is
   begin
      return Kind in Composite_Array
        | Composite_Constrained_Array
        | Composite_Unconstrained_Array
        | Composite_Multidimensional_Array
        | Composite_String_Array
        | Composite_Formal_Array
        | Composite_Private_Array
        | Composite_Limited_View;
   end Is_Array;

   function Is_Container (Kind : Composite_Kind) return Boolean is
   begin
      return Kind = Composite_Container;
   end Is_Container;

   function Is_Discrete_Index (Kind : Index_Type_Kind) return Boolean is
   begin
      return Kind in Index_Type_Discrete
        | Index_Type_Integer
        | Index_Type_Modular
        | Index_Type_Enumeration
        | Index_Type_Boolean
        | Index_Type_Character
        | Index_Type_Universal_Integer;
   end Is_Discrete_Index;

   function Needs_Array (Kind : Indexing_Kind) return Boolean is
   begin
      return Kind in Index_Array_Type_Declaration
        | Index_Array_Object_Declaration
        | Index_Index_Constraint
        | Index_Array_Aggregate
        | Index_Named_Array_Aggregate
        | Index_Positional_Array_Aggregate
        | Index_Array_Slice
        | Index_Indexed_Component
        | Index_Delta_Aggregate_Update;
   end Needs_Array;

   function Needs_Container (Kind : Indexing_Kind) return Boolean is
   begin
      return Kind in Index_Generalized_Indexing
        | Index_Container_Aggregate
        | Index_Container_Iterator
        | Index_Parallel_Iterator;
   end Needs_Container;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Context_Blockers
        + R.Composite_Blockers
        + R.Index_Type_Blockers
        + R.Index_Range_Blockers
        + R.Index_Count_Blockers
        + R.Bounds_Blockers
        + R.Missing_Constraint_Blockers
        + R.Constraint_Conflict_Blockers
        + R.Missing_Component_Blockers
        + R.Duplicate_Component_Blockers
        + R.Component_Type_Blockers
        + R.Named_Positional_Mix_Blockers
        + R.Choice_Overlap_Blockers
        + R.Slice_Range_Blockers
        + R.Generalized_Profile_Missing_Blockers
        + R.Generalized_Profile_Mismatch_Blockers
        + R.Container_Profile_Blockers
        + R.Container_Element_Blockers
        + R.Iterator_Element_Blockers
        + R.Parallel_Shared_State_Blockers
        + R.Delta_Target_Blockers
        + R.Delta_Component_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Subtype_Range_Blockers
        + R.Predicate_Blockers
        + R.Accessibility_Blockers
        + R.Initialization_Blockers
        + R.Overload_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; Info : Indexing_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Context_Blockers > 0 then
         return Legality_Missing_Context;
      elsif R.Composite_Blockers > 0 then
         return Legality_Not_Array_Or_Container;
      elsif R.Index_Type_Blockers > 0 then
         return Legality_Index_Type_Not_Discrete;
      elsif R.Index_Range_Blockers > 0 then
         return Legality_Index_Range_Mismatch;
      elsif R.Index_Count_Blockers > 0 then
         return Legality_Index_Count_Mismatch;
      elsif R.Bounds_Blockers > 0 then
         return Legality_Index_Out_Of_Bounds;
      elsif R.Missing_Constraint_Blockers > 0 then
         return Legality_Unconstrained_Array_Missing_Constraint;
      elsif R.Constraint_Conflict_Blockers > 0 then
         return Legality_Constrained_Array_Constraint_Conflict;
      elsif R.Missing_Component_Blockers > 0 then
         return Legality_Aggregate_Component_Missing;
      elsif R.Duplicate_Component_Blockers > 0 then
         return Legality_Aggregate_Component_Duplicate;
      elsif R.Component_Type_Blockers > 0 then
         return Legality_Aggregate_Component_Type_Mismatch;
      elsif R.Named_Positional_Mix_Blockers > 0 then
         return Legality_Aggregate_Named_Positional_Mix;
      elsif R.Choice_Overlap_Blockers > 0 then
         return Legality_Aggregate_Choice_Overlap;
      elsif R.Slice_Range_Blockers > 0 then
         return Legality_Slice_Range_Mismatch;
      elsif R.Generalized_Profile_Missing_Blockers > 0 then
         return Legality_Generalized_Indexing_Profile_Missing;
      elsif R.Generalized_Profile_Mismatch_Blockers > 0 then
         return Legality_Generalized_Indexing_Profile_Mismatch;
      elsif R.Container_Profile_Blockers > 0 then
         return Legality_Container_Aggregate_Profile_Missing;
      elsif R.Container_Element_Blockers > 0 then
         return Legality_Container_Element_Type_Mismatch;
      elsif R.Iterator_Element_Blockers > 0 then
         return Legality_Iterator_Element_Type_Mismatch;
      elsif R.Parallel_Shared_State_Blockers > 0 then
         return Legality_Parallel_Iterator_Shared_State_Blocked;
      elsif R.Delta_Target_Blockers > 0 then
         return Legality_Delta_Update_Target_Missing;
      elsif R.Delta_Component_Blockers > 0 then
         return Legality_Delta_Update_Component_Mismatch;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Subtype_Range_Blockers > 0 then
         return Legality_Subtype_Range_Blocked;
      elsif R.Predicate_Blockers > 0 then
         return Legality_Predicate_Blocked;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocked;
      elsif R.Initialization_Blockers > 0 then
         return Legality_Initialization_Blocked;
      elsif R.Overload_Blockers > 0 then
         return Legality_Overload_Blocked;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Legality_Type_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Legality_Profile_Fingerprint_Mismatch;
      elsif Info.Kind = Index_Unknown
        or else Info.Composite = Composite_Unknown
        or else Info.Index_Type = Index_Type_Unknown
      then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_With_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Clear (Model : in out Indexing_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Indexing (Model : in out Indexing_Model; Info : Indexing_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Indexing_Kind'Pos (Info.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Profile_Fingerprint);
   end Add_Indexing;

   function Build (Indexings : Indexing_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for Info of Indexings.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Indexing := Info.Id;
            R.Node := Info.Node;
            R.Kind := Info.Kind;
            R.Runtime_Check_Required := Info.Runtime_Bounds_Check_Required;
            R.Source_Fingerprint := Info.Source_Fingerprint;
            R.AST_Fingerprint := Info.AST_Fingerprint;
            R.Type_Fingerprint := Info.Type_Fingerprint;
            R.Profile_Fingerprint := Info.Profile_Fingerprint;

            if not Info.Has_AST_Coverage then
               R.AST_Blockers := R.AST_Blockers + 1;
            end if;
            if not Info.Has_Context then
               R.Context_Blockers := R.Context_Blockers + 1;
            end if;
            if (Needs_Array (Info.Kind) and then not Is_Array (Info.Composite))
              or else (Needs_Container (Info.Kind) and then not Is_Container (Info.Composite))
            then
               R.Composite_Blockers := R.Composite_Blockers + 1;
            end if;
            if Needs_Array (Info.Kind) and then not Is_Discrete_Index (Info.Index_Type) then
               R.Index_Type_Blockers := R.Index_Type_Blockers + 1;
            end if;
            if not Info.Index_Range_Compatible then
               R.Index_Range_Blockers := R.Index_Range_Blockers + 1;
            end if;
            if Info.Supplied_Index_Count /= Info.Dimension_Count then
               R.Index_Count_Blockers := R.Index_Count_Blockers + 1;
            end if;
            if not Info.Index_Value_In_Bounds and then not Info.Runtime_Bounds_Check_Required then
               R.Bounds_Blockers := R.Bounds_Blockers + 1;
            end if;
            if Info.Composite = Composite_Unconstrained_Array and then not Info.Has_Index_Constraint then
               R.Missing_Constraint_Blockers := R.Missing_Constraint_Blockers + 1;
            end if;
            if Info.Is_Constrained_Array and then Info.Constraint_Conflicts_With_Type then
               R.Constraint_Conflict_Blockers := R.Constraint_Conflict_Blockers + 1;
            end if;
            if Info.Kind in Index_Array_Aggregate
              | Index_Named_Array_Aggregate
              | Index_Positional_Array_Aggregate
              | Index_Container_Aggregate
            then
               if Info.Aggregate_Component_Count < Info.Required_Component_Count then
                  R.Missing_Component_Blockers := R.Missing_Component_Blockers + 1;
               end if;
               if Info.Has_Duplicate_Component then
                  R.Duplicate_Component_Blockers := R.Duplicate_Component_Blockers + 1;
               end if;
               if not Info.Component_Type_Compatible then
                  R.Component_Type_Blockers := R.Component_Type_Blockers + 1;
               end if;
               if Info.Mixes_Named_And_Positional then
                  R.Named_Positional_Mix_Blockers := R.Named_Positional_Mix_Blockers + 1;
               end if;
               if Info.Aggregate_Choices_Overlap then
                  R.Choice_Overlap_Blockers := R.Choice_Overlap_Blockers + 1;
               end if;
            end if;
            if Info.Kind = Index_Array_Slice and then not Info.Slice_Range_Compatible then
               R.Slice_Range_Blockers := R.Slice_Range_Blockers + 1;
            end if;
            if Info.Kind = Index_Generalized_Indexing then
               if not Info.Has_Generalized_Indexing_Profile then
                  R.Generalized_Profile_Missing_Blockers := R.Generalized_Profile_Missing_Blockers + 1;
               elsif not Info.Generalized_Indexing_Profile_Compatible then
                  R.Generalized_Profile_Mismatch_Blockers := R.Generalized_Profile_Mismatch_Blockers + 1;
               end if;
            end if;
            if Info.Kind = Index_Container_Aggregate then
               if not Info.Has_Container_Aggregate_Profile
                 or else Info.Container_Profile = Container_Profile_None
               then
                  R.Container_Profile_Blockers := R.Container_Profile_Blockers + 1;
               end if;
               if not Info.Container_Element_Type_Compatible then
                  R.Container_Element_Blockers := R.Container_Element_Blockers + 1;
               end if;
            end if;
            if Info.Kind in Index_Container_Iterator | Index_Parallel_Iterator
              and then not Info.Iterator_Element_Type_Compatible
            then
               R.Iterator_Element_Blockers := R.Iterator_Element_Blockers + 1;
            end if;
            if Info.Kind = Index_Parallel_Iterator
              and then not Info.Parallel_Iterator_Shared_State_Legal
            then
               R.Parallel_Shared_State_Blockers := R.Parallel_Shared_State_Blockers + 1;
            end if;
            if Info.Kind = Index_Delta_Aggregate_Update then
               if not Info.Has_Delta_Update_Target then
                  R.Delta_Target_Blockers := R.Delta_Target_Blockers + 1;
               end if;
               if not Info.Delta_Update_Component_Compatible then
                  R.Delta_Component_Blockers := R.Delta_Component_Blockers + 1;
               end if;
            end if;
            if Info.Composite = Composite_Private_Array and then not Info.Private_View_Available then
               R.Private_View_Blockers := R.Private_View_Blockers + 1;
            end if;
            if Info.Composite = Composite_Limited_View and then not Info.Limited_View_Available then
               R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
            end if;
            if not Info.Subtype_Range_Legal then
               R.Subtype_Range_Blockers := R.Subtype_Range_Blockers + 1;
            end if;
            if not Info.Predicate_Legal then
               R.Predicate_Blockers := R.Predicate_Blockers + 1;
            end if;
            if not Info.Accessibility_Legal then
               R.Accessibility_Blockers := R.Accessibility_Blockers + 1;
            end if;
            if not Info.Initialization_Legal then
               R.Initialization_Blockers := R.Initialization_Blockers + 1;
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
            if Info.Expected_Profile_Fingerprint /= 0
              and then Info.Expected_Profile_Fingerprint /= Info.Profile_Fingerprint
            then
               R.Profile_Fingerprint_Blockers := R.Profile_Fingerprint_Blockers + 1;
            end if;

            R.Status := Status_For (R, Info);
            R.Message := To_Unbounded_String (Legality_Status'Image (R.Status));
            R.Detail := Info.Source_Name;
            R.Fingerprint := Mix (Natural (R.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Indexing_Kind'Pos (R.Kind)));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Type_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Profile_Fingerprint);

            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   function Indexing_Count (Model : Indexing_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Indexing_Count;

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

end Editor.Ada_Array_Container_Indexing_Vertical_Slice_Legality;
