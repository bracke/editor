with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Aggregate_Legality_Vertical_Slice is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 31337) + 1326) mod 1_000_000_007;
   end Mix;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Aggregate_Blockers
        + R.Missing_Expected_Type_Blockers
        + R.Kind_Blockers
        + R.Association_Form_Blockers
        + R.Missing_Association_Blockers
        + R.Extra_Association_Blockers
        + R.Duplicate_Association_Blockers
        + R.Component_Type_Blockers
        + R.Static_Choice_Blockers
        + R.Choice_Overlap_Blockers
        + R.Discriminant_Blockers
        + R.Variant_Blockers
        + R.Extension_Ancestor_Blockers
        + R.Delta_Target_Blockers
        + R.Container_Profile_Blockers
        + R.Null_Aggregate_Blockers
        + R.Controlled_Finalized_Blockers
        + R.Accessibility_Blockers
        + R.Predicate_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Generic_Formal_View_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Type_Fingerprint_Blockers
        + R.Static_Fingerprint_Blockers;
   end Blocker_Count;

   function Compatible_Kind (Agg : Aggregate_Kind; Typ : Expected_Type_Kind) return Boolean is
   begin
      case Agg is
         when Aggregate_Array =>
            return Typ = Expected_Array;
         when Aggregate_Record =>
            return Typ = Expected_Record or else Typ = Expected_Tagged_Record;
         when Aggregate_Extension =>
            return Typ = Expected_Tagged_Record;
         when Aggregate_Delta =>
            return Typ = Expected_Array
              or else Typ = Expected_Record
              or else Typ = Expected_Tagged_Record;
         when Aggregate_Container =>
            return Typ = Expected_Container;
         when Aggregate_Null =>
            return Typ = Expected_Null_Record
              or else Typ = Expected_Record
              or else Typ = Expected_Tagged_Record;
         when Aggregate_Unknown =>
            return False;
      end case;
   end Compatible_Kind;

   procedure Add_View_Blocker (View : Aggregate_View_Kind; R : in out Result_Info) is
   begin
      case View is
         when View_Private => R.Private_View_Blockers := 1;
         when View_Limited => R.Limited_View_Blockers := 1;
         when View_Incomplete => R.Incomplete_View_Blockers := 1;
         when View_Generic_Formal => R.Generic_Formal_View_Blockers := 1;
         when others => null;
      end case;
   end Add_View_Blocker;

   function Status_For (R : Result_Info) return Aggregate_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Aggregate_Multiple_Blockers;
      elsif R.Missing_Aggregate_Blockers > 0 then
         return Aggregate_Missing_Aggregate;
      elsif R.Missing_Expected_Type_Blockers > 0 then
         return Aggregate_Missing_Expected_Type;
      elsif R.Kind_Blockers > 0 then
         return Aggregate_Kind_Mismatch;
      elsif R.Association_Form_Blockers > 0 then
         return Aggregate_Association_Form_Mismatch;
      elsif R.Missing_Association_Blockers > 0 then
         return Aggregate_Missing_Component_Association;
      elsif R.Extra_Association_Blockers > 0 then
         return Aggregate_Extra_Component_Association;
      elsif R.Duplicate_Association_Blockers > 0 then
         return Aggregate_Duplicate_Component_Association;
      elsif R.Component_Type_Blockers > 0 then
         return Aggregate_Component_Type_Mismatch;
      elsif R.Static_Choice_Blockers > 0 then
         return Aggregate_Static_Choice_Required;
      elsif R.Choice_Overlap_Blockers > 0 then
         return Aggregate_Choice_Overlap;
      elsif R.Discriminant_Blockers > 0 then
         return Aggregate_Discriminant_Mismatch;
      elsif R.Variant_Blockers > 0 then
         return Aggregate_Variant_Mismatch;
      elsif R.Extension_Ancestor_Blockers > 0 then
         return Aggregate_Extension_Ancestor_Mismatch;
      elsif R.Delta_Target_Blockers > 0 then
         return Aggregate_Delta_Target_Mismatch;
      elsif R.Container_Profile_Blockers > 0 then
         return Aggregate_Container_Profile_Mismatch;
      elsif R.Null_Aggregate_Blockers > 0 then
         return Aggregate_Null_Not_Allowed;
      elsif R.Controlled_Finalized_Blockers > 0 then
         return Aggregate_Controlled_Finalized_Component_Blocker;
      elsif R.Accessibility_Blockers > 0 then
         return Aggregate_Accessibility_Blocker;
      elsif R.Predicate_Blockers > 0 then
         return Aggregate_Predicate_Blocker;
      elsif R.Private_View_Blockers > 0 then
         return Aggregate_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Aggregate_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Aggregate_Incomplete_View_Barrier;
      elsif R.Generic_Formal_View_Blockers > 0 then
         return Aggregate_Generic_Formal_View_Barrier;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Aggregate_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Aggregate_AST_Fingerprint_Mismatch;
      elsif R.Type_Fingerprint_Blockers > 0 then
         return Aggregate_Type_Fingerprint_Mismatch;
      elsif R.Static_Fingerprint_Blockers > 0 then
         return Aggregate_Static_Fingerprint_Mismatch;
      elsif Blocks = 0 and then R.Runtime_Check_Count > 0 then
         return Aggregate_Legal_With_Runtime_Check;
      elsif Blocks = 0 and then R.Defaulted_Component_Count > 0 then
         return Aggregate_Legal_With_Defaulted_Components;
      elsif Blocks = 0 then
         return Aggregate_Legal;
      else
         return Aggregate_Indeterminate;
      end if;
   end Status_For;

   function Find_Type (Model : Expected_Type_Model; Id : Type_Id) return Expected_Type_Info is
   begin
      for T of Model.Items loop
         if T.Id = Id then
            return T;
         end if;
      end loop;
      return (others => <>);
   end Find_Type;

   procedure Clear (Model : in out Aggregate_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Expected_Type_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Aggregate (Model : in out Aggregate_Model; Info : Aggregate_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
   end Add_Aggregate;

   procedure Add_Expected_Type (Model : in out Expected_Type_Model; Info : Expected_Type_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Type_Fingerprint);
   end Add_Expected_Type;

   function Build
     (Aggregates : Aggregate_Model;
      Expected_Types : Expected_Type_Model) return Result_Model
   is
      Results : Result_Model;
   begin
      for A of Aggregates.Items loop
         declare
            T : constant Expected_Type_Info := Find_Type (Expected_Types, A.Expected_Type);
            R : Result_Info;
         begin
            R.Id := Result_Id (Natural (A.Id));
            R.Aggregate := A.Id;
            R.Expected_Type := A.Expected_Type;

            if A.Id = No_Aggregate then
               R.Missing_Aggregate_Blockers := 1;
            end if;

            Add_View_Blocker (A.View, R);

            if A.Source_Fingerprint /= A.Expected_Source_Fingerprint then
               R.Source_Fingerprint_Blockers := 1;
            end if;
            if A.AST_Fingerprint /= A.Expected_AST_Fingerprint then
               R.AST_Fingerprint_Blockers := 1;
            end if;
            if A.Type_Fingerprint /= A.Expected_Type_Fingerprint then
               R.Type_Fingerprint_Blockers := 1;
            end if;
            if A.Static_Fingerprint /= A.Expected_Static_Fingerprint then
               R.Static_Fingerprint_Blockers := 1;
            end if;

            if T.Id = No_Type then
               R.Missing_Expected_Type_Blockers := 1;
            else
               Add_View_Blocker (T.View, R);
               if T.Source_Fingerprint /= T.Expected_Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := 1;
               end if;
               if T.Type_Fingerprint /= T.Expected_Type_Fingerprint then
                  R.Type_Fingerprint_Blockers := 1;
               end if;

               if not Compatible_Kind (A.Kind, T.Kind) then
                  R.Kind_Blockers := 1;
               end if;

               if A.Associations = Associations_Mixed then
                  R.Association_Form_Blockers := 1;
               end if;

               if A.Kind = Aggregate_Array
                 and then A.Associations = Associations_Named
                 and then A.Static_Choices_Required
                 and then not A.Static_Choices_Present
               then
                  R.Static_Choice_Blockers := 1;
               end if;

               if A.Kind = Aggregate_Null and then not T.Allows_Null_Aggregate then
                  R.Null_Aggregate_Blockers := 1;
               end if;

               R.Defaulted_Component_Count := A.Defaulted_Component_Count;
               R.Missing_Association_Blockers := A.Missing_Associations;
               R.Extra_Association_Blockers := A.Extra_Associations;
               R.Duplicate_Association_Blockers := A.Duplicate_Associations;
               R.Component_Type_Blockers := A.Component_Type_Mismatches;
               R.Choice_Overlap_Blockers := A.Choice_Overlaps;

               if A.Association_Count < T.Required_Component_Count then
                  if T.Allows_Defaulted_Components then
                     R.Defaulted_Component_Count := T.Required_Component_Count - A.Association_Count;
                  else
                     R.Missing_Association_Blockers :=
                       R.Missing_Association_Blockers + (T.Required_Component_Count - A.Association_Count);
                  end if;
               end if;

               if not A.Discriminants_OK or else not T.Discriminants_Conformant then
                  R.Discriminant_Blockers := 1;
               end if;
               if not A.Variants_OK or else not T.Variants_Conformant then
                  R.Variant_Blockers := 1;
               end if;
               if A.Kind = Aggregate_Extension and then not A.Extension_Ancestor_OK then
                  R.Extension_Ancestor_Blockers := 1;
               end if;
               if A.Kind = Aggregate_Delta and then not A.Delta_Target_OK then
                  R.Delta_Target_Blockers := 1;
               end if;
               if A.Kind = Aggregate_Container
                 and then (not A.Container_Profile_OK or else not T.Container_Profile_Conformant)
               then
                  R.Container_Profile_Blockers := 1;
               end if;
               if not T.Component_Types_Conformant then
                  R.Component_Type_Blockers := R.Component_Type_Blockers + 1;
               end if;
               if T.Controlled_Or_Finalized_Component then
                  R.Controlled_Finalized_Blockers := 1;
               end if;
            end if;

            if not A.Accessibility_OK then
               R.Accessibility_Blockers := 1;
            end if;
            if not A.Predicate_OK then
               R.Predicate_Blockers := 1;
            end if;
            if A.Runtime_Check_Required then
               R.Runtime_Check_Count := 1;
            end if;

            R.Status := Status_For (R);
            R.Fingerprint := Mix (Natural (R.Id), Natural (Aggregate_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            R.Fingerprint := Mix (R.Fingerprint, R.Defaulted_Component_Count);
            R.Fingerprint := Mix (R.Fingerprint, R.Runtime_Check_Count);
            R.Message := To_Unbounded_String ("aggregate legality vertical slice");
            R.Detail := To_Unbounded_String (Aggregate_Status'Image (R.Status));
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;
      return Results;
   end Build;

   function Aggregate_Count (Model : Aggregate_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Aggregate_Count;

   function Expected_Type_Count (Model : Expected_Type_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Expected_Type_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items.Element (Index);
   end Result_At;

   function Count_Status (Model : Result_Model; Status : Aggregate_Status) return Natural is
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
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status = Aggregate_Legal
           or else R.Status = Aggregate_Legal_With_Defaulted_Components
           or else R.Status = Aggregate_Legal_With_Runtime_Check
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status /= Aggregate_Legal
           and then R.Status /= Aggregate_Legal_With_Defaulted_Components
           and then R.Status /= Aggregate_Legal_With_Runtime_Check
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result and then Info.Status /= Aggregate_Not_Checked;
   end Has_Result;

end Editor.Ada_Aggregate_Legality_Vertical_Slice;
