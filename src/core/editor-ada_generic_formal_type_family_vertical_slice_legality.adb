with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1319) + 37) mod 1_000_000_007;
   end Mix;

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));
   end Normalize;

   function Empty (S : Unbounded_String) return Boolean is
   begin
      return Normalize (To_String (S)) = "";
   end Empty;

   function Same (L, R : Unbounded_String) return Boolean is
   begin
      return Normalize (To_String (L)) = Normalize (To_String (R));
   end Same;

   function Compatible_Text (Formal, Actual : Unbounded_String) return Boolean is
   begin
      return Empty (Formal) or else Same (Formal, Actual);
   end Compatible_Text;

   function Compatible_Family
     (Formal : Formal_Type_Family;
      Actual : Actual_Type_Family) return Boolean
   is
   begin
      case Formal is
         when Family_Private =>
            return Actual in Actual_Private | Actual_Limited_Private | Actual_Tagged |
              Actual_Enumeration | Actual_Signed_Integer | Actual_Modular |
              Actual_Floating | Actual_Ordinary_Fixed | Actual_Decimal_Fixed |
              Actual_Array | Actual_Access_Object | Actual_Access_Subprogram |
              Actual_Interface | Actual_Derived;
         when Family_Limited_Private =>
            return Actual in Actual_Limited_Private | Actual_Private | Actual_Tagged |
              Actual_Array | Actual_Derived;
         when Family_Tagged_Private =>
            return Actual in Actual_Tagged | Actual_Derived;
         when Family_Discrete =>
            return Actual in Actual_Enumeration | Actual_Signed_Integer | Actual_Modular;
         when Family_Signed_Integer =>
            return Actual = Actual_Signed_Integer;
         when Family_Modular =>
            return Actual = Actual_Modular;
         when Family_Floating =>
            return Actual = Actual_Floating;
         when Family_Ordinary_Fixed =>
            return Actual = Actual_Ordinary_Fixed;
         when Family_Decimal_Fixed =>
            return Actual = Actual_Decimal_Fixed;
         when Family_Array =>
            return Actual = Actual_Array;
         when Family_Access_Object =>
            return Actual = Actual_Access_Object;
         when Family_Access_Subprogram =>
            return Actual = Actual_Access_Subprogram;
         when Family_Interface =>
            return Actual = Actual_Interface or else Actual = Actual_Tagged or else Actual = Actual_Derived;
         when Family_Derived =>
            return Actual = Actual_Derived or else Actual = Actual_Tagged;
         when Family_Unknown =>
            return False;
      end case;
   end Compatible_Family;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.Missing_Formal_Blockers
        + R.Missing_Actual_Blockers
        + R.Extra_Actual_Blockers
        + R.Family_Blockers
        + R.Limitedness_Blockers
        + R.Taggedness_Blockers
        + R.Discriminant_Blockers
        + R.Array_Index_Blockers
        + R.Array_Component_Blockers
        + R.Access_Designated_Blockers
        + R.Access_Profile_Blockers
        + R.Interface_Blockers
        + R.Derived_Ancestor_Blockers
        + R.Object_Mode_Blockers
        + R.Subprogram_Profile_Blockers
        + R.Package_Contract_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Incomplete_View_Blockers
        + R.Body_Replay_Blockers
        + R.Nested_Cycle_Blockers
        + R.Source_Fingerprint_Blockers
        + R.Substitution_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; F : Formal_Info; A : Actual_Info) return Legality_Status is
      Blocks : constant Natural := Blocker_Count (R);
   begin
      if Blocks > 1 then
         return Legality_Multiple_Blockers;
      elsif R.Missing_Formal_Blockers > 0 then
         return Legality_Missing_Formal;
      elsif R.Missing_Actual_Blockers > 0 then
         return Legality_Missing_Actual;
      elsif R.Extra_Actual_Blockers > 0 then
         return Legality_Extra_Actual;
      elsif R.Family_Blockers > 0 then
         return Legality_Formal_Actual_Family_Mismatch;
      elsif R.Limitedness_Blockers > 0 then
         return Legality_Limitedness_Mismatch;
      elsif R.Taggedness_Blockers > 0 then
         return Legality_Taggedness_Mismatch;
      elsif R.Discriminant_Blockers > 0 then
         return Legality_Discriminant_Mismatch;
      elsif R.Array_Index_Blockers > 0 then
         return Legality_Array_Index_Mismatch;
      elsif R.Array_Component_Blockers > 0 then
         return Legality_Array_Component_Mismatch;
      elsif R.Access_Designated_Blockers > 0 then
         return Legality_Access_Designated_Type_Mismatch;
      elsif R.Access_Profile_Blockers > 0 then
         return Legality_Access_Profile_Mismatch;
      elsif R.Interface_Blockers > 0 then
         return Legality_Interface_Mismatch;
      elsif R.Derived_Ancestor_Blockers > 0 then
         return Legality_Derived_Ancestor_Mismatch;
      elsif R.Object_Mode_Blockers > 0 then
         return Legality_Formal_Object_Mode_Mismatch;
      elsif R.Subprogram_Profile_Blockers > 0 then
         return Legality_Formal_Subprogram_Profile_Mismatch;
      elsif R.Package_Contract_Blockers > 0 then
         return Legality_Formal_Package_Contract_Mismatch;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Incomplete_View_Blockers > 0 then
         return Legality_Incomplete_View_Barrier;
      elsif R.Body_Replay_Blockers > 0 then
         return Legality_Body_Replay_Unavailable;
      elsif R.Nested_Cycle_Blockers > 0 then
         return Legality_Nested_Instance_Cycle;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.Substitution_Fingerprint_Blockers > 0 then
         return Legality_Substitution_Fingerprint_Mismatch;
      elsif Blocks = 0 and then A.Id = No_Actual and then F.Has_Default then
         return Legality_Legal_Defaulted_Formal;
      elsif Blocks = 0 and then not Empty (F.Package_Contract) then
         return Legality_Legal_Formal_Package_Match;
      elsif Blocks = 0 and then A.Nested_Instance then
         return Legality_Legal_Nested_Substitution;
      elsif Blocks = 0 and then F.Family = Family_Private then
         return Legality_Legal_Class_Match;
      elsif Blocks = 0 then
         return Legality_Legal_Exact;
      else
         return Legality_Indeterminate;
      end if;
   end Status_For;

   function Find_Actual (Actuals : Actual_Model; Formal : Formal_Id) return Actual_Info is
   begin
      for A of Actuals.Items loop
         if A.Formal = Formal then
            return A;
         end if;
      end loop;
      return (others => <>);
   end Find_Actual;

   function Formal_Exists (Formals : Formal_Model; Id : Formal_Id) return Boolean is
   begin
      for F of Formals.Items loop
         if F.Id = Id then
            return True;
         end if;
      end loop;
      return False;
   end Formal_Exists;

   procedure Clear (Model : in out Formal_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Actual_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Formal (Model : in out Formal_Model; Info : Formal_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Formal;

   procedure Add_Actual (Model : in out Actual_Model; Info : Actual_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
   end Add_Actual;

   function Build (Formals : Formal_Model; Actuals : Actual_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for F of Formals.Items loop
         declare
            A : constant Actual_Info := Find_Actual (Actuals, F.Id);
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Instance := F.Instance;
            R.Formal := F.Id;
            R.Actual := A.Id;
            R.Node := F.Node;

            if F.Id = No_Formal then
               R.Missing_Formal_Blockers := 1;
            elsif A.Id = No_Actual then
               if not F.Has_Default then
                  R.Missing_Actual_Blockers := 1;
               end if;
            else
               R.Node := A.Node;
               if not Compatible_Family (F.Family, A.Family) then
                  R.Family_Blockers := 1;
               end if;
               if F.Requires_Limited and then not A.Is_Limited then
                  R.Limitedness_Blockers := 1;
               end if;
               if F.Requires_Tagged and then not A.Is_Tagged then
                  R.Taggedness_Blockers := 1;
               end if;
               if F.Requires_Definite and then not A.Is_Definite then
                  R.Discriminant_Blockers := 1;
               end if;
               if F.Has_Discriminants /= A.Has_Discriminants
                 or else not Compatible_Text (F.Discriminant_Profile, A.Discriminant_Profile)
               then
                  R.Discriminant_Blockers := R.Discriminant_Blockers + 1;
               end if;
               if not Compatible_Text (F.Array_Index_Profile, A.Array_Index_Profile) then
                  R.Array_Index_Blockers := 1;
               end if;
               if not Compatible_Text (F.Array_Component_Type, A.Array_Component_Type) then
                  R.Array_Component_Blockers := 1;
               end if;
               if not Compatible_Text (F.Access_Designated_Type, A.Access_Designated_Type) then
                  R.Access_Designated_Blockers := 1;
               end if;
               if not Compatible_Text (F.Access_Profile, A.Access_Profile) then
                  R.Access_Profile_Blockers := 1;
               end if;
               if not Compatible_Text (F.Interface_Name, A.Interface_Name) then
                  R.Interface_Blockers := 1;
               end if;
               if not Compatible_Text (F.Ancestor_Type, A.Ancestor_Type) then
                  R.Derived_Ancestor_Blockers := 1;
               end if;
               if F.Mode /= Mode_None and then A.Mode /= F.Mode then
                  R.Object_Mode_Blockers := 1;
               end if;
               if not Compatible_Text (F.Subprogram_Profile, A.Subprogram_Profile) then
                  R.Subprogram_Profile_Blockers := 1;
               end if;
               if not Compatible_Text (F.Package_Contract, A.Package_Contract) then
                  R.Package_Contract_Blockers := 1;
               end if;
               if A.View = View_Private and then not F.Allows_Private_View then
                  R.Private_View_Blockers := 1;
               end if;
               if A.View = View_Limited and then not F.Allows_Limited_View then
                  R.Limited_View_Blockers := 1;
               end if;
               if A.View = View_Incomplete then
                  R.Incomplete_View_Blockers := 1;
               end if;
               if not A.Body_Replay_Available then
                  R.Body_Replay_Blockers := 1;
               end if;
               if A.Nested_Cycle then
                  R.Nested_Cycle_Blockers := 1;
               end if;
               if F.Expected_Source_Fingerprint /= 0 and then F.Expected_Source_Fingerprint /= F.Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;
               if A.Expected_Source_Fingerprint /= 0 and then A.Expected_Source_Fingerprint /= A.Source_Fingerprint then
                  R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
               end if;
               if F.Expected_Substitution_Fingerprint /= 0
                 and then F.Expected_Substitution_Fingerprint /= F.Substitution_Fingerprint
               then
                  R.Substitution_Fingerprint_Blockers := R.Substitution_Fingerprint_Blockers + 1;
               end if;
               if A.Expected_Substitution_Fingerprint /= 0
                 and then A.Expected_Substitution_Fingerprint /= A.Substitution_Fingerprint
               then
                  R.Substitution_Fingerprint_Blockers := R.Substitution_Fingerprint_Blockers + 1;
               end if;
            end if;

            R.Status := Status_For (R, F, A);
            R.Message := To_Unbounded_String ("generic formal type family legality");
            R.Detail := To_Unbounded_String (To_String (F.Name) & " => " & To_String (A.Name));
            R.Fingerprint := Mix (Natural (Legality_Status'Pos (R.Status)), Natural (R.Formal));
            R.Fingerprint := Mix (R.Fingerprint, Natural (R.Actual));
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));
            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
         end;
      end loop;

      for A of Actuals.Items loop
         if not Formal_Exists (Formals, A.Formal) then
            declare
               R : Result_Info;
            begin
               R.Id := Result_Id (Next_Id);
               Next_Id := Next_Id + 1;
               R.Instance := A.Instance;
               R.Formal := A.Formal;
               R.Actual := A.Id;
               R.Node := A.Node;
               R.Extra_Actual_Blockers := 1;
               R.Status := Legality_Extra_Actual;
               R.Message := To_Unbounded_String ("extra generic actual without formal");
               R.Detail := A.Name;
               R.Fingerprint := Mix (Natural (Legality_Status'Pos (R.Status)), Natural (R.Actual));
               Results.Items.Append (R);
               Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            end;
         end if;
      end loop;

      return Results;
   end Build;

   function Formal_Count (Model : Formal_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Formal_Count;

   function Actual_Count (Model : Actual_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Actual_Count;

   function Result_Count (Model : Result_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Result_Count;

   function Result_At (Model : Result_Model; Index : Positive) return Result_Info is
   begin
      return Model.Items (Index);
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
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status in Legality_Legal_Exact | Legality_Legal_Class_Match |
           Legality_Legal_Defaulted_Formal | Legality_Legal_Formal_Package_Match |
           Legality_Legal_Nested_Substitution
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
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
      return Info.Id /= No_Result;
   end Has_Result;

end Editor.Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality;
