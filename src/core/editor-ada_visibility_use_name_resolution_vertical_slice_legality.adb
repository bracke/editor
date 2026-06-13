with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1317) mod 1_000_000_007;
   end Mix;

   function Compatible_Declaration
     (Actual, Expected : Declaration_Kind) return Boolean is
   begin
      if Expected = Decl_Unknown or else Actual = Decl_Unknown then
         return True;
      elsif Actual = Expected then
         return True;
      elsif Actual in Decl_Type | Decl_Subtype
        and then Expected in Decl_Type | Decl_Subtype
      then
         return True;
      elsif Actual in Decl_Subprogram | Decl_Operator
        and then Expected in Decl_Subprogram | Decl_Operator
      then
         return True;
      elsif Actual = Decl_Renaming then
         return True;
      else
         return False;
      end if;
   end Compatible_Declaration;

   function Needs_Direct_Visibility (Kind : Lookup_Kind) return Boolean is
   begin
      return Kind in Lookup_Simple_Name | Lookup_Generic_Formal_Name |
                     Lookup_Renamed_Entity | Lookup_Attribute_Prefix;
   end Needs_Direct_Visibility;

   function Needs_Use_Visibility (Kind : Lookup_Kind) return Boolean is
   begin
      return Kind in Lookup_Use_Visible_Declaration | Lookup_Use_Visible_Operator;
   end Needs_Use_Visibility;

   function Needs_Selected_Visibility (Kind : Lookup_Kind) return Boolean is
   begin
      return Kind in Lookup_Selected_Name | Lookup_Expanded_Name |
                     Lookup_Child_Unit_Name | Lookup_Private_Child_Unit_Name;
   end Needs_Selected_Visibility;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Symbol_Blockers
        + R.No_Visible_Declaration_Blockers
        + R.Direct_Visibility_Blockers
        + R.Use_Clause_Blockers
        + R.Use_Type_Operator_Blockers
        + R.Hiding_Blockers
        + R.Homograph_Blockers
        + R.Ambiguous_Use_Blockers
        + R.Selected_Prefix_Blockers
        + R.Selected_Selector_Blockers
        + R.With_Clause_Blockers
        + R.Private_Child_Blockers
        + R.Limited_View_Blockers
        + R.Private_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Renaming_Blockers
        + R.Declaration_Kind_Blockers
        + R.Overload_Context_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Symbol_Fingerprint_Blockers
        + R.Visibility_Fingerprint_Blockers
        + R.View_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; L : Lookup_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Symbol_Blockers > 0 then
         return Legality_Missing_Symbol_Evidence;
      elsif R.No_Visible_Declaration_Blockers > 0 then
         return Legality_No_Visible_Declaration;
      elsif R.Direct_Visibility_Blockers > 0 then
         return Legality_Declaration_Not_Directly_Visible;
      elsif R.Use_Clause_Blockers > 0 then
         return Legality_Use_Clause_Not_Visible;
      elsif R.Use_Type_Operator_Blockers > 0 then
         return Legality_Use_Type_Operator_Not_Visible;
      elsif R.Hiding_Blockers > 0 then
         return Legality_Hidden_By_Inner_Declaration;
      elsif R.Homograph_Blockers > 0 then
         return Legality_Homograph_Conflict;
      elsif R.Ambiguous_Use_Blockers > 0 then
         return Legality_Ambiguous_Use_Visibility;
      elsif R.Selected_Prefix_Blockers > 0 then
         return Legality_Selected_Prefix_Not_Visible;
      elsif R.Selected_Selector_Blockers > 0 then
         return Legality_Selected_Selector_Not_Visible;
      elsif R.With_Clause_Blockers > 0 then
         return Legality_With_Clause_Missing;
      elsif R.Private_Child_Blockers > 0 then
         return Legality_Private_Child_Not_Visible;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Generic_Formal_View_Blockers > 0 then
         return Legality_Generic_Formal_View_Barrier;
      elsif R.Renaming_Blockers > 0 then
         return Legality_Renaming_Target_Not_Visible;
      elsif R.Declaration_Kind_Blockers > 0 then
         return Legality_Wrong_Declaration_Kind;
      elsif R.Overload_Context_Blockers > 0 then
         return Legality_Overload_Context_Blocker;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.Symbol_Fingerprint_Blockers > 0 then
         return Legality_Symbol_Fingerprint_Mismatch;
      elsif R.Visibility_Fingerprint_Blockers > 0 then
         return Legality_Visibility_Fingerprint_Mismatch;
      elsif R.View_Fingerprint_Blockers > 0 then
         return Legality_View_Fingerprint_Mismatch;
      elsif L.Kind = Lookup_Unknown then
         return Legality_Indeterminate;
      elsif L.Multiple_Use_Candidates and then L.Ambiguity_Allowed_By_Overload then
         return Legality_Legal_Ambiguous_Overload_Set;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Check_Lookup (L : Lookup_Info; R : in out Result_Info) is
   begin
      if not L.Has_AST_Coverage then
         R.AST_Blockers := R.AST_Blockers + 1;
      end if;

      if not L.Has_Symbol_Evidence then
         R.Symbol_Blockers := R.Symbol_Blockers + 1;
      end if;

      if not L.Has_Visible_Declaration then
         R.No_Visible_Declaration_Blockers := R.No_Visible_Declaration_Blockers + 1;
      end if;

      if Needs_Direct_Visibility (L.Kind) and then not L.Directly_Visible then
         R.Direct_Visibility_Blockers := R.Direct_Visibility_Blockers + 1;
      end if;

      if Needs_Use_Visibility (L.Kind) and then not L.Use_Clause_Visible then
         R.Use_Clause_Blockers := R.Use_Clause_Blockers + 1;
      end if;

      if L.Kind in Lookup_Operator_Symbol | Lookup_Use_Visible_Operator
        and then L.Source in Visibility_Use_Type | Visibility_Implicit_Operator
        and then not L.Use_Type_Operator_Visible
      then
         R.Use_Type_Operator_Blockers := R.Use_Type_Operator_Blockers + 1;
      end if;

      if L.Hidden_By_Inner_Declaration then
         R.Hiding_Blockers := R.Hiding_Blockers + 1;
      end if;

      if L.Homograph_Conflict then
         R.Homograph_Blockers := R.Homograph_Blockers + 1;
      end if;

      if L.Multiple_Use_Candidates and then not L.Ambiguity_Allowed_By_Overload then
         R.Ambiguous_Use_Blockers := R.Ambiguous_Use_Blockers + 1;
      end if;

      if Needs_Selected_Visibility (L.Kind) and then not L.Selected_Prefix_Visible then
         R.Selected_Prefix_Blockers := R.Selected_Prefix_Blockers + 1;
      end if;

      if Needs_Selected_Visibility (L.Kind) and then not L.Selected_Selector_Visible then
         R.Selected_Selector_Blockers := R.Selected_Selector_Blockers + 1;
      end if;

      if L.Kind in Lookup_Child_Unit_Name | Lookup_Private_Child_Unit_Name
        and then not L.With_Clause_Present
      then
         R.With_Clause_Blockers := R.With_Clause_Blockers + 1;
      end if;

      if L.Kind = Lookup_Private_Child_Unit_Name and then not L.Private_Child_Visible then
         R.Private_Child_Blockers := R.Private_Child_Blockers + 1;
      end if;

      if L.View = View_Limited and then not L.Limited_View_Allows_Use then
         R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
      end if;

      if L.View = View_Private and then not L.Private_View_Allows_Use then
         R.Private_View_Blockers := R.Private_View_Blockers + 1;
      end if;

      if L.View = View_Incomplete and then not L.Incomplete_View_Allows_Use then
         R.Incomplete_View_Blockers := R.Incomplete_View_Blockers + 1;
      end if;

      if L.View = View_Generic_Formal and then not L.Generic_Formal_View_Allows_Use then
         R.Generic_Formal_View_Blockers := R.Generic_Formal_View_Blockers + 1;
      end if;

      if L.Kind = Lookup_Renamed_Entity and then not L.Renaming_Target_Visible then
         R.Renaming_Blockers := R.Renaming_Blockers + 1;
      end if;

      if not L.Declaration_Kind_Compatible
        or else not Compatible_Declaration (L.Candidate_Kind, L.Expected_Kind)
      then
         R.Declaration_Kind_Blockers := R.Declaration_Kind_Blockers + 1;
      end if;

      if not L.Overload_Context_OK then
         R.Overload_Context_Blockers := R.Overload_Context_Blockers + 1;
      end if;

      if L.Expected_Source_Fingerprint /= 0
        and then L.Expected_Source_Fingerprint /= L.Source_Fingerprint
      then
         R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
      end if;

      if L.Expected_Symbol_Fingerprint /= 0
        and then L.Expected_Symbol_Fingerprint /= L.Symbol_Fingerprint
      then
         R.Symbol_Fingerprint_Blockers := R.Symbol_Fingerprint_Blockers + 1;
      end if;

      if L.Expected_Visibility_Fingerprint /= 0
        and then L.Expected_Visibility_Fingerprint /= L.Visibility_Fingerprint
      then
         R.Visibility_Fingerprint_Blockers := R.Visibility_Fingerprint_Blockers + 1;
      end if;

      if L.Expected_View_Fingerprint /= 0
        and then L.Expected_View_Fingerprint /= L.View_Fingerprint
      then
         R.View_Fingerprint_Blockers := R.View_Fingerprint_Blockers + 1;
      end if;
   end Check_Lookup;

   function Build (Lookups : Lookup_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for L of Lookups.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Lookup := L.Id;
            R.Node := L.Node;
            R.Kind := L.Kind;
            R.Resolved_Source := L.Source;
            Check_Lookup (L, R);
            R.Status := Status_For (R, L);
            R.Message := To_Unbounded_String
              ("Pass1317 visibility/use/name-resolution vertical-slice legality");
            R.Detail := L.Name;
            R.Fingerprint := Mix
              (Natural (R.Id),
               Natural (L.Id) + Natural (Lookup_Kind'Pos (L.Kind))
               + Natural (Declaration_Kind'Pos (L.Candidate_Kind))
               + Natural (Declaration_Kind'Pos (L.Expected_Kind))
               + Natural (Visibility_Source'Pos (L.Source))
               + Natural (View_Kind'Pos (L.View))
               + Natural (Legality_Status'Pos (R.Status))
               + Blocker_Count (R) + L.Source_Fingerprint
               + L.Symbol_Fingerprint + L.Visibility_Fingerprint
               + L.View_Fingerprint);
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   procedure Clear (Model : in out Lookup_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Lookup (Model : in out Lookup_Model; Info : Lookup_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Lookup_Kind'Pos (Info.Kind))
         + Info.Source_Fingerprint + Info.Symbol_Fingerprint
         + Info.Visibility_Fingerprint + Info.View_Fingerprint);
   end Add_Lookup;

   function Lookup_Count (Model : Lookup_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Lookup_Count;

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
        + Count_Status (Model, Legality_Legal_Ambiguous_Overload_Set);
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

end Editor.Ada_Visibility_Use_Name_Resolution_Vertical_Slice_Legality;
