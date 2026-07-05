with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Selected_Name_Attribute_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1316) mod 1_000_000_007;
   end Mix;

   function Compatible_Entity (Actual, Expected : Entity_Kind) return Boolean is
   begin
      if Expected = Entity_Unknown or else Actual = Entity_Unknown then
         return True;
      elsif Actual = Expected then
         return True;
      elsif Actual in Entity_Type | Entity_Subtype
        and then Expected in Entity_Type | Entity_Subtype
      then
         return True;
      elsif Actual in Entity_Subprogram | Entity_Entry
        and then Expected in Entity_Subprogram | Entity_Entry
      then
         return True;
      else
         return False;
      end if;
   end Compatible_Entity;

   function Is_Selection (Kind : Reference_Kind) return Boolean is
   begin
      return Kind in Reference_Selected_Name | Reference_Expanded_Name |
                     Reference_Discriminant | Reference_Record_Component |
                     Reference_Array_Component | Reference_Callable_Entity;
   end Is_Selection;

   function Is_Attribute (Kind : Reference_Kind) return Boolean is
   begin
      return Kind in Reference_Attribute | Reference_Access_Attribute |
                     Reference_Address_Attribute | Reference_Size_Attribute |
                     Reference_First_Last_Range_Attribute |
                     Reference_Image_Value_Attribute;
   end Is_Attribute;

   function Is_Indexing (Kind : Reference_Kind) return Boolean is
   begin
      return Kind in Reference_Array_Component | Reference_Generalized_Indexing;
   end Is_Indexing;

   function Is_Dereference (Kind : Reference_Kind) return Boolean is
   begin
      return Kind in Reference_Explicit_Dereference | Reference_Implicit_Dereference;
   end Is_Dereference;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Resolution_Blockers
        + R.Prefix_Visibility_Blockers
        + R.Selected_Visibility_Blockers
        + R.Prefix_Composite_Blockers
        + R.Missing_Selector_Blockers
        + R.Ambiguous_Selector_Blockers
        + R.Entity_Kind_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Attribute_Defined_Blockers
        + R.Attribute_Prefix_Blockers
        + R.Attribute_Result_Blockers
        + R.Attribute_Static_Blockers
        + R.Dereference_Blockers
        + R.Index_Profile_Blockers
        + R.Index_Count_Blockers
        + R.Component_Type_Blockers
        + R.Accessibility_Blockers
        + R.Representation_Blockers
        + R.Overload_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Resolution_Fingerprint_Blockers
        + R.View_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; Ref : Reference_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Resolution_Blockers > 0 then
         return Legality_Missing_Resolution_Evidence;
      elsif R.Prefix_Visibility_Blockers > 0 then
         return Legality_Prefix_Not_Visible;
      elsif R.Selected_Visibility_Blockers > 0 then
         return Legality_Selected_Entity_Not_Visible;
      elsif R.Prefix_Composite_Blockers > 0 then
         return Legality_Prefix_Not_Composite;
      elsif R.Missing_Selector_Blockers > 0 then
         return Legality_No_Such_Selector;
      elsif R.Ambiguous_Selector_Blockers > 0 then
         return Legality_Ambiguous_Selector;
      elsif R.Entity_Kind_Blockers > 0 then
         return Legality_Wrong_Entity_Kind;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Generic_Formal_View_Blockers > 0 then
         return Legality_Generic_Formal_View_Barrier;
      elsif R.Attribute_Defined_Blockers > 0 then
         return Legality_Attribute_Not_Defined;
      elsif R.Attribute_Prefix_Blockers > 0 then
         return Legality_Attribute_Prefix_Not_Allowed;
      elsif R.Attribute_Result_Blockers > 0 then
         return Legality_Attribute_Result_Type_Mismatch;
      elsif R.Attribute_Static_Blockers > 0 then
         return Legality_Attribute_Not_Static;
      elsif R.Dereference_Blockers > 0 then
         return Legality_Dereference_Non_Access;
      elsif R.Index_Profile_Blockers > 0 then
         return Legality_Index_Profile_Mismatch;
      elsif R.Index_Count_Blockers > 0 then
         return Legality_Index_Count_Mismatch;
      elsif R.Component_Type_Blockers > 0 then
         return Legality_Component_Type_Mismatch;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocker;
      elsif R.Representation_Blockers > 0 then
         return Legality_Representation_Blocker;
      elsif R.Overload_Blockers > 0 then
         return Legality_Overload_Blocker;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Resolution_Fingerprint_Blockers > 0 then
         return Legality_Resolution_Fingerprint_Mismatch;
      elsif R.View_Fingerprint_Blockers > 0 then
         return Legality_View_Fingerprint_Mismatch;
      elsif Ref.Kind = Reference_Unknown then
         return Legality_Indeterminate;
      elsif R.Null_Runtime_Check_Required then
         return Legality_Legal_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Check_Common (Ref : Reference_Info; R : in out Result_Info) is
   begin
      if not Ref.Has_AST_Coverage then
         R.AST_Blockers := R.AST_Blockers + 1;
      end if;

      if not Ref.Has_Resolution_Evidence then
         R.Resolution_Blockers := R.Resolution_Blockers + 1;
      end if;

      if not Ref.Prefix_Visible then
         R.Prefix_Visibility_Blockers := R.Prefix_Visibility_Blockers + 1;
      end if;

      if not Ref.Selected_Visible then
         R.Selected_Visibility_Blockers := R.Selected_Visibility_Blockers + 1;
      end if;

      if not Ref.Entity_Kind_Compatible
        or else not Compatible_Entity (Ref.Selected_Entity, Ref.Expected_Entity)
      then
         R.Entity_Kind_Blockers := R.Entity_Kind_Blockers + 1;
      end if;

      if Ref.Prefix_View = View_Private and then not Ref.Private_View_Allows_Selection then
         R.Private_View_Blockers := R.Private_View_Blockers + 1;
      end if;

      if Ref.Prefix_View = View_Limited and then not Ref.Limited_View_Allows_Selection then
         R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
      end if;

      if Ref.Prefix_View = View_Incomplete and then not Ref.Incomplete_View_Allows_Selection then
         R.Incomplete_View_Blockers := R.Incomplete_View_Blockers + 1;
      end if;

      if Ref.Prefix_View = View_Generic_Formal and then not Ref.Generic_Formal_View_Allows_Selection then
         R.Generic_Formal_View_Blockers := R.Generic_Formal_View_Blockers + 1;
      end if;

      if not Ref.Accessibility_OK then
         R.Accessibility_Blockers := R.Accessibility_Blockers + 1;
      end if;

      if not Ref.Representation_OK then
         R.Representation_Blockers := R.Representation_Blockers + 1;
      end if;

      if not Ref.Overload_OK then
         R.Overload_Blockers := R.Overload_Blockers + 1;
      end if;

      if Ref.Expected_Source_Fingerprint /= 0
        and then Ref.Expected_Source_Fingerprint /= Ref.Source_Fingerprint
      then
         R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
      end if;

      if Ref.Expected_AST_Fingerprint /= 0
        and then Ref.Expected_AST_Fingerprint /= Ref.AST_Fingerprint
      then
         R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
      end if;

      if Ref.Expected_Resolution_Fingerprint /= 0
        and then Ref.Expected_Resolution_Fingerprint /= Ref.Resolution_Fingerprint
      then
         R.Resolution_Fingerprint_Blockers := R.Resolution_Fingerprint_Blockers + 1;
      end if;

      if Ref.Expected_View_Fingerprint /= 0
        and then Ref.Expected_View_Fingerprint /= Ref.View_Fingerprint
      then
         R.View_Fingerprint_Blockers := R.View_Fingerprint_Blockers + 1;
      end if;
   end Check_Common;

   procedure Check_Reference_Family (Ref : Reference_Info; R : in out Result_Info) is
   begin
      if Is_Selection (Ref.Kind) then
         if not Ref.Prefix_Is_Composite
           and then Ref.Kind not in Reference_Expanded_Name | Reference_Callable_Entity
         then
            R.Prefix_Composite_Blockers := R.Prefix_Composite_Blockers + 1;
         end if;

         if not Ref.Selector_Exists then
            R.Missing_Selector_Blockers := R.Missing_Selector_Blockers + 1;
         end if;

         if Ref.Selector_Ambiguous then
            R.Ambiguous_Selector_Blockers := R.Ambiguous_Selector_Blockers + 1;
         end if;
      end if;

      if Is_Attribute (Ref.Kind) then
         if not Ref.Attribute_Defined or else Ref.Attribute = Attribute_Unknown then
            R.Attribute_Defined_Blockers := R.Attribute_Defined_Blockers + 1;
         end if;

         if not Ref.Attribute_Prefix_Allowed then
            R.Attribute_Prefix_Blockers := R.Attribute_Prefix_Blockers + 1;
         end if;

         if not Ref.Attribute_Result_Type_Compatible then
            R.Attribute_Result_Blockers := R.Attribute_Result_Blockers + 1;
         end if;

         if Ref.Attribute_Static_Required and then not Ref.Attribute_Is_Static then
            R.Attribute_Static_Blockers := R.Attribute_Static_Blockers + 1;
         end if;
      end if;

      if Is_Dereference (Ref.Kind) then
         if not Ref.Prefix_Is_Access then
            R.Dereference_Blockers := R.Dereference_Blockers + 1;
         elsif Ref.Access_Value_May_Be_Null and then Ref.Null_Check_Allowed then
            R.Null_Runtime_Check_Required := True;
         end if;
      end if;

      if Is_Indexing (Ref.Kind) then
         if not Ref.Index_Profile_Compatible then
            R.Index_Profile_Blockers := R.Index_Profile_Blockers + 1;
         end if;

         if not Ref.Index_Count_Compatible then
            R.Index_Count_Blockers := R.Index_Count_Blockers + 1;
         end if;
      end if;

      if Ref.Kind in Reference_Record_Component | Reference_Array_Component |
                     Reference_Generalized_Indexing
        and then not Ref.Component_Type_Compatible
      then
         R.Component_Type_Blockers := R.Component_Type_Blockers + 1;
      end if;
   end Check_Reference_Family;

   function Build (References : Reference_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for Ref of References.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Check := Ref.Id;
            R.Node := Ref.Node;
            R.Kind := Ref.Kind;

            Check_Common (Ref, R);
            Check_Reference_Family (Ref, R);

            R.Status := Status_For (R, Ref);
            R.Message := To_Unbounded_String
              ("Case 1316 selected-name/attribute/reference vertical-slice legality");
            R.Detail := Ref.Source_Name;
            R.Fingerprint := Mix
              (Natural (R.Id),
               Natural (Ref.Id) + Natural (Reference_Kind'Pos (Ref.Kind))
               + Natural (Entity_Kind'Pos (Ref.Prefix_Entity))
               + Natural (Entity_Kind'Pos (Ref.Selected_Entity))
               + Natural (View_Kind'Pos (Ref.Prefix_View))
               + Natural (Attribute_Class'Pos (Ref.Attribute))
               + Natural (Legality_Status'Pos (R.Status))
               + Blocker_Count (R) + Ref.Source_Fingerprint
               + Ref.AST_Fingerprint + Ref.Resolution_Fingerprint
               + Ref.View_Fingerprint);
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   procedure Clear (Model : in out Reference_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Reference (Model : in out Reference_Model; Info : Reference_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Reference_Kind'Pos (Info.Kind))
         + Info.Source_Fingerprint + Info.AST_Fingerprint
         + Info.Resolution_Fingerprint + Info.View_Fingerprint);
   end Add_Reference;

   function Reference_Count (Model : Reference_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Reference_Count;

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
        + Count_Status (Model, Legality_Legal_Runtime_Check);
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
   begin
      return Result_Count (Model) - Legal_Count (Model)
        - Count_Status (Model, Legality_Not_Checked);
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result and then Info.Status /= Legality_Not_Checked;
   end Has_Result;

end Editor.Ada_Selected_Name_Attribute_Vertical_Slice_Legality;
