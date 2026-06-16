with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Call_And_Operator_Overload_Resolution_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 257) + 1297) mod 1_000_000_007;
   end Mix;

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));
   end Normalize;

   function Same (Left, Right : Unbounded_String) return Boolean is
   begin
      return Normalize (To_String (Left)) = Normalize (To_String (Right));
   end Same;

   function Profile_Count (Profile : Unbounded_String) return Natural is
      S : constant String := Ada.Strings.Fixed.Trim (To_String (Profile), Ada.Strings.Both);
      Count : Natural := 1;
   begin
      if S'Length = 0 then
         return 0;
      end if;
      for Ch of S loop
         if Ch = '|' then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Profile_Count;

   function Type_At (Profile : Unbounded_String; Index : Positive) return String is
      S : constant String := To_String (Profile);
      Current : Positive := 1;
      Start : Positive := S'First;
   begin
      if S'Length = 0 then
         return "";
      end if;

      for Pos in S'Range loop
         if S (Pos) = '|' then
            if Current = Index then
               return Normalize (S (Start .. Pos - 1));
            end if;
            Current := Current + 1;
            if Pos < S'Last then
               Start := Pos + 1;
            end if;
         end if;
      end loop;

      if Current = Index then
         return Normalize (S (Start .. S'Last));
      end if;
      return "";
   end Type_At;

   function Is_Integer_Type (Name : String) return Boolean is
      N : constant String := Normalize (Name);
   begin
      return N = "integer" or else N = "natural" or else N = "positive"
        or else N = "universal_integer" or else N = "root_integer";
   end Is_Integer_Type;

   function Is_Real_Type (Name : String) return Boolean is
      N : constant String := Normalize (Name);
   begin
      return N = "float" or else N = "long_float" or else N = "universal_real"
        or else N = "root_real" or else N = "fixed" or else N = "root_fixed";
   end Is_Real_Type;

   function Is_Numeric_Type (Name : String) return Boolean is
   begin
      return Is_Integer_Type (Name) or else Is_Real_Type (Name);
   end Is_Numeric_Type;

   function Is_Universal_Integer (Name : String) return Boolean is
   begin
      return Normalize (Name) = "universal_integer";
   end Is_Universal_Integer;

   function Is_Universal_Real (Name : String) return Boolean is
   begin
      return Normalize (Name) = "universal_real";
   end Is_Universal_Real;

   function Is_Access_Type (Name : String) return Boolean is
      N : constant String := Normalize (Name);
   begin
      return N'Length >= 6 and then N (N'First .. N'First + 5) = "access";
   end Is_Access_Type;

   function Type_Compatible (Actual, Formal : String) return Boolean is
      A : constant String := Normalize (Actual);
      F : constant String := Normalize (Formal);
   begin
      if A = F then
         return True;
      elsif Is_Universal_Integer (A) and then Is_Integer_Type (F) then
         return True;
      elsif Is_Universal_Real (A) and then Is_Real_Type (F) then
         return True;
      elsif Is_Numeric_Type (A) and then Is_Numeric_Type (F) then
         return True;
      elsif Is_Access_Type (A) and then Is_Access_Type (F) then
         return True;
      else
         return False;
      end if;
   end Type_Compatible;

   function Exact_Profile (Actuals, Formals : Unbounded_String) return Boolean is
      Actual_Count : constant Natural := Profile_Count (Actuals);
      Formal_Count : constant Natural := Profile_Count (Formals);
   begin
      if Actual_Count /= Formal_Count then
         return False;
      end if;
      for I in 1 .. Actual_Count loop
         if Type_At (Actuals, I) /= Type_At (Formals, I) then
            return False;
         end if;
      end loop;
      return True;
   end Exact_Profile;

   function Compatible_Profile (Actuals, Formals : Unbounded_String) return Boolean is
      Actual_Count : constant Natural := Profile_Count (Actuals);
      Formal_Count : constant Natural := Profile_Count (Formals);
   begin
      if Actual_Count /= Formal_Count then
         return False;
      end if;
      for I in 1 .. Actual_Count loop
         if not Type_Compatible (Type_At (Actuals, I), Type_At (Formals, I)) then
            return False;
         end if;
      end loop;
      return True;
   end Compatible_Profile;

   function Has_Universal_Integer (Actuals : Unbounded_String) return Boolean is
   begin
      for I in 1 .. Profile_Count (Actuals) loop
         if Is_Universal_Integer (Type_At (Actuals, I)) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Universal_Integer;

   function Has_Universal_Real (Actuals : Unbounded_String) return Boolean is
   begin
      for I in 1 .. Profile_Count (Actuals) loop
         if Is_Universal_Real (Type_At (Actuals, I)) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Universal_Real;

   function Has_Implicit_Numeric (Actuals, Formals : Unbounded_String) return Boolean is
   begin
      for I in 1 .. Profile_Count (Actuals) loop
         declare
            A : constant String := Type_At (Actuals, I);
            F : constant String := Type_At (Formals, I);
         begin
            if Normalize (A) /= Normalize (F)
              and then Is_Numeric_Type (A)
              and then Is_Numeric_Type (F)
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Implicit_Numeric;

   function Expected_Result_Matches
     (Context : Context_Info;
      Candidate : Candidate_Info) return Boolean is
      Expected : constant String := Normalize (To_String (Context.Expected_Result_Type));
      Result   : constant String := Normalize (To_String (Candidate.Result_Type));
   begin
      return Expected'Length > 0 and then Result'Length > 0
        and then Normalize (Result) = Normalize (Expected);
   end Expected_Result_Matches;

   function Arity_Compatible
     (Context : Context_Info;
      Candidate : Candidate_Info) return Boolean
   is
      Actual_Count : constant Natural := Profile_Count (Context.Actual_Profile);
      Formal_Count : constant Natural :=
        (if Candidate.Formal_Count = 0 then Profile_Count (Candidate.Formal_Profile)
         else Candidate.Formal_Count);
   begin
      return Actual_Count >= Candidate.Required_Actual_Count
        and then Actual_Count <= Formal_Count;
   end Arity_Compatible;

   function Score
     (Context : Context_Info;
      Candidate : Candidate_Info) return Natural
   is
      S : Natural := 0;
   begin
      if Exact_Profile (Context.Actual_Profile, Candidate.Formal_Profile) then
         S := S + 1_000;
      elsif Compatible_Profile (Context.Actual_Profile, Candidate.Formal_Profile) then
         S := S + 500;
      else
         return 0;
      end if;

      if Expected_Result_Matches (Context, Candidate) then
         S := S + 200;
      end if;
      if Has_Universal_Integer (Context.Actual_Profile) then
         S := S + 100;
      end if;
      if Has_Universal_Real (Context.Actual_Profile) then
         S := S + 100;
      end if;
      if Has_Implicit_Numeric (Context.Actual_Profile, Candidate.Formal_Profile) then
         S := S + 50;
      end if;
      if Candidate.Is_Primitive_Operator or else Candidate.Is_Use_Type_Primitive then
         S := S + 40;
      end if;
      if Candidate.Is_Access_To_Subprogram then
         S := S + 30;
      end if;
      if Candidate.Has_Class_Wide_Result then
         S := S + 20;
      end if;
      if Candidate.Is_Generic_Formal_Subprogram then
         S := S + 10;
      end if;
      return S;
   end Score;

   function Status_For_Selected
     (Context : Context_Info;
      Candidate : Candidate_Info) return Resolution_Status is
   begin
      if Candidate.Is_Generic_Formal_Subprogram then
         return Resolution_Legal_Generic_Formal_Subprogram;
      elsif Candidate.Is_Access_To_Subprogram then
         return Resolution_Legal_Access_Profile;
      elsif Candidate.Has_Class_Wide_Result then
         return Resolution_Legal_Class_Wide_Result;
      elsif Expected_Result_Matches (Context, Candidate) then
         return Resolution_Legal_Expected_Result;
      elsif Has_Universal_Integer (Context.Actual_Profile) then
         return Resolution_Legal_Universal_Integer;
      elsif Has_Universal_Real (Context.Actual_Profile) then
         return Resolution_Legal_Universal_Real;
      elsif Candidate.Is_Primitive_Operator or else Candidate.Is_Use_Type_Primitive then
         return Resolution_Legal_Primitive_Operator;
      elsif Has_Implicit_Numeric (Context.Actual_Profile, Candidate.Formal_Profile) then
         return Resolution_Legal_Implicit_Numeric;
      else
         return Resolution_Legal_Exact;
      end if;
   end Status_For_Selected;

   function Is_Legal (Status : Resolution_Status) return Boolean is
   begin
      return Status in
        Resolution_Legal_Exact |
        Resolution_Legal_Expected_Result |
        Resolution_Legal_Universal_Integer |
        Resolution_Legal_Universal_Real |
        Resolution_Legal_Primitive_Operator |
        Resolution_Legal_Implicit_Numeric |
        Resolution_Legal_Access_Profile |
        Resolution_Legal_Class_Wide_Result |
        Resolution_Legal_Generic_Formal_Subprogram;
   end Is_Legal;

   function Message_For (Status : Resolution_Status) return String is
   begin
      case Status is
         when Resolution_Legal_Exact => return "overload resolution selected an exact profile match";
         when Resolution_Legal_Expected_Result => return "expected result type selected the overloaded interpretation";
         when Resolution_Legal_Universal_Integer => return "universal integer actuals resolved against the selected profile";
         when Resolution_Legal_Universal_Real => return "universal real actuals resolved against the selected profile";
         when Resolution_Legal_Primitive_Operator => return "primitive operator visibility selected the overloaded operator";
         when Resolution_Legal_Implicit_Numeric => return "implicit numeric compatibility selected the overloaded interpretation";
         when Resolution_Legal_Access_Profile => return "access-to-subprogram profile selected the overloaded call";
         when Resolution_Legal_Class_Wide_Result => return "class-wide controlling result selected the overloaded call";
         when Resolution_Legal_Generic_Formal_Subprogram => return "generic formal subprogram profile selected the overloaded call";
         when Resolution_No_Candidate => return "no overload candidate denotes the call or operator designator";
         when Resolution_No_Visible_Candidate => return "overload candidates exist but none are visible";
         when Resolution_Arity_Mismatch => return "no overload candidate has an arity compatible with the actual part";
         when Resolution_Actual_Type_Mismatch => return "no arity-compatible overload candidate accepts the actual expression types";
         when Resolution_Ambiguous => return "overload resolution remains ambiguous after profile and preference filtering";
         when Resolution_Private_View_Barrier => return "private view blocks overload resolution";
         when Resolution_Limited_View_Barrier => return "limited view blocks overload resolution";
         when Resolution_Cross_Unit_Blocker => return "cross-unit evidence blocks overload resolution";
         when Resolution_Indeterminate => return "overload resolution is indeterminate";
         when Resolution_Not_Checked => return "overload resolution was not checked";
      end case;
   end Message_For;

   function Context_Fingerprint (Info : Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Length (Info.Designator) + 1);
      H := Mix (H, Length (Info.Actual_Profile) + 1);
      H := Mix (H, Length (Info.Expected_Result_Type) + 1);
      H := Mix (H, Info.Region_Source_Fingerprint + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Candidate_Fingerprint (Info : Candidate_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Natural (Info.Declaration) + 1);
      H := Mix (H, Length (Info.Designator) + 1);
      H := Mix (H, Length (Info.Formal_Profile) + 1);
      H := Mix (H, Length (Info.Result_Type) + 1);
      H := Mix (H, Info.Required_Actual_Count + 1);
      H := Mix (H, Info.Formal_Count + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Is_Visible)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Is_Primitive_Operator)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Is_Use_Type_Primitive)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Is_Generic_Formal_Subprogram)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Is_Access_To_Subprogram)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Has_Class_Wide_Result)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Private_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Limited_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Cross_Unit_Blocker)) + 1);
      H := Mix (H, Info.Candidate_Fingerprint + 1);
      return H;
   end Candidate_Fingerprint;

   function Resolution_Fingerprint (Info : Resolution_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Resolution_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Selected_Candidate) + 1);
      H := Mix (H, Natural (Info.Selected_Declaration) + 1);
      H := Mix (H, Info.Candidate_Count + 1);
      H := Mix (H, Info.Visible_Candidate_Count + 1);
      H := Mix (H, Info.Arity_Compatible_Count + 1);
      H := Mix (H, Info.Type_Compatible_Count + 1);
      H := Mix (H, Info.Expected_Result_Match_Count + 1);
      H := Mix (H, Info.Universal_Integer_Match_Count + 1);
      H := Mix (H, Info.Universal_Real_Match_Count + 1);
      H := Mix (H, Info.Primitive_Operator_Count + 1);
      H := Mix (H, Info.Access_Profile_Count + 1);
      H := Mix (H, Info.Generic_Formal_Subprogram_Count + 1);
      H := Mix (H, Info.Rejected_Count + 1);
      H := Mix (H, Info.Best_Score + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Candidate_Fingerprint + 1);
      H := Mix (H, Length (Info.Message) + Length (Info.Detail) + 1);
      return H;
   end Resolution_Fingerprint;

   function Empty_Resolution return Resolution_Info is
   begin
      return (Id => No_Resolution,
              Context => No_Overload_Context,
              Kind => Context_Unknown,
              Node => Editor.Ada_Syntax_Tree.No_Node,
              Status => Resolution_Not_Checked,
              Selected_Candidate => No_Candidate,
              Selected_Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Candidate_Count => 0,
              Visible_Candidate_Count => 0,
              Arity_Compatible_Count => 0,
              Type_Compatible_Count => 0,
              Expected_Result_Match_Count => 0,
              Universal_Integer_Match_Count => 0,
              Universal_Real_Match_Count => 0,
              Primitive_Operator_Count => 0,
              Access_Profile_Count => 0,
              Generic_Formal_Subprogram_Count => 0,
              Rejected_Count => 0,
              Best_Score => 0,
              Message => Null_Unbounded_String,
              Detail => Null_Unbounded_String,
              Source_Fingerprint => 0,
              Candidate_Fingerprint => 0,
              Fingerprint => 0);
   end Empty_Resolution;

   procedure Clear (Model : in out Context_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Clear (Model : in out Candidate_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Context_Model;
      Info  : Context_Info)
   is
      Row : Context_Info := Info;
   begin
      if Row.Id = No_Overload_Context then
         Row.Id := Overload_Context_Id (Natural (Model.Items.Length) + 1);
      end if;
      Model.Items.Append (Row);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context_Fingerprint (Row));
   end Add_Context;

   procedure Add_Candidate
     (Model : in out Candidate_Model;
      Info  : Candidate_Info)
   is
      Row : Candidate_Info := Info;
   begin
      if Row.Id = No_Candidate then
         Row.Id := Candidate_Id (Natural (Model.Items.Length) + 1);
      end if;
      if Row.Formal_Count = 0 then
         Row.Formal_Count := Profile_Count (Row.Formal_Profile);
      end if;
      Model.Items.Append (Row);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Candidate_Fingerprint (Row));
   end Add_Candidate;

   procedure Add_Resolution
     (Model : in out Resolution_Model;
      Info  : in out Resolution_Info) is
   begin
      Info.Id := Resolution_Id (Natural (Model.Items.Length) + 1);
      Info.Message := To_Unbounded_String (Message_For (Info.Status));
      Info.Detail := To_Unbounded_String
        ("candidates=" & Natural'Image (Info.Candidate_Count) &
         " visible=" & Natural'Image (Info.Visible_Candidate_Count) &
         " arity=" & Natural'Image (Info.Arity_Compatible_Count) &
         " type=" & Natural'Image (Info.Type_Compatible_Count) &
         " expected=" & Natural'Image (Info.Expected_Result_Match_Count) &
         " score=" & Natural'Image (Info.Best_Score));
      Info.Fingerprint := Resolution_Fingerprint (Info);
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
      if Is_Legal (Info.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      elsif Info.Status = Resolution_Ambiguous then
         Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
         Model.Error_Total := Model.Error_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;
   end Add_Resolution;

   function Build
     (Contexts   : Context_Model;
      Candidates : Candidate_Model) return Resolution_Model
   is
      Model : Resolution_Model;
   begin
      for Context of Contexts.Items loop
         declare
            Result : Resolution_Info := Empty_Resolution;
            Best : Candidate_Info;
            Best_Score : Natural := 0;
            Best_Count : Natural := 0;
            Saw_Private : Boolean := False;
            Saw_Limited : Boolean := False;
            Saw_Cross : Boolean := False;
            Saw_Arity_Mismatch : Boolean := False;
            Saw_Type_Mismatch : Boolean := False;
         begin
            Result.Context := Context.Id;
            Result.Kind := Context.Kind;
            Result.Node := Context.Node;
            Result.Source_Fingerprint := Context.Source_Fingerprint;

            for Candidate of Candidates.Items loop
               if Candidate.Context = Context.Id and then Same (Candidate.Designator, Context.Designator) then
                  Result.Candidate_Count := Result.Candidate_Count + 1;
                  Result.Candidate_Fingerprint := Mix
                    (Result.Candidate_Fingerprint, Candidate_Fingerprint (Candidate));

                  if Candidate.Private_View_Barrier then
                     Saw_Private := True;
                  end if;
                  if Candidate.Limited_View_Barrier then
                     Saw_Limited := True;
                  end if;
                  if Candidate.Cross_Unit_Blocker then
                     Saw_Cross := True;
                  end if;

                  if Candidate.Is_Visible
                    and then not Candidate.Private_View_Barrier
                    and then not Candidate.Limited_View_Barrier
                    and then not Candidate.Cross_Unit_Blocker
                  then
                     Result.Visible_Candidate_Count := Result.Visible_Candidate_Count + 1;
                     if Arity_Compatible (Context, Candidate) then
                        Result.Arity_Compatible_Count := Result.Arity_Compatible_Count + 1;
                        if Compatible_Profile (Context.Actual_Profile, Candidate.Formal_Profile) then
                           declare
                              This_Score : constant Natural := Score (Context, Candidate);
                           begin
                              Result.Type_Compatible_Count := Result.Type_Compatible_Count + 1;
                              if Expected_Result_Matches (Context, Candidate) then
                                 Result.Expected_Result_Match_Count := Result.Expected_Result_Match_Count + 1;
                              end if;
                              if Has_Universal_Integer (Context.Actual_Profile) then
                                 Result.Universal_Integer_Match_Count := Result.Universal_Integer_Match_Count + 1;
                              end if;
                              if Has_Universal_Real (Context.Actual_Profile) then
                                 Result.Universal_Real_Match_Count := Result.Universal_Real_Match_Count + 1;
                              end if;
                              if Candidate.Is_Primitive_Operator or else Candidate.Is_Use_Type_Primitive then
                                 Result.Primitive_Operator_Count := Result.Primitive_Operator_Count + 1;
                              end if;
                              if Candidate.Is_Access_To_Subprogram then
                                 Result.Access_Profile_Count := Result.Access_Profile_Count + 1;
                              end if;
                              if Candidate.Is_Generic_Formal_Subprogram then
                                 Result.Generic_Formal_Subprogram_Count := Result.Generic_Formal_Subprogram_Count + 1;
                              end if;

                              if This_Score > Best_Score then
                                 Best := Candidate;
                                 Best_Score := This_Score;
                                 Best_Count := 1;
                              elsif This_Score = Best_Score then
                                 Best_Count := Best_Count + 1;
                              end if;
                           end;
                        else
                           Saw_Type_Mismatch := True;
                        end if;
                     else
                        Saw_Arity_Mismatch := True;
                     end if;
                  end if;
               end if;
            end loop;

            Result.Rejected_Count := Result.Candidate_Count - Result.Type_Compatible_Count;
            Result.Best_Score := Best_Score;

            if Result.Candidate_Count = 0 then
               Result.Status := Resolution_No_Candidate;
            elsif Saw_Private then
               Result.Status := Resolution_Private_View_Barrier;
            elsif Saw_Limited then
               Result.Status := Resolution_Limited_View_Barrier;
            elsif Saw_Cross then
               Result.Status := Resolution_Cross_Unit_Blocker;
            elsif Result.Visible_Candidate_Count = 0 then
               Result.Status := Resolution_No_Visible_Candidate;
            elsif Result.Type_Compatible_Count = 0 and then Saw_Arity_Mismatch then
               Result.Status := Resolution_Arity_Mismatch;
            elsif Result.Type_Compatible_Count = 0 and then Saw_Type_Mismatch then
               Result.Status := Resolution_Actual_Type_Mismatch;
            elsif Best_Count > 1 then
               Result.Status := Resolution_Ambiguous;
            elsif Best_Count = 1 then
               Result.Selected_Candidate := Best.Id;
               Result.Selected_Declaration := Best.Declaration;
               Result.Status := Status_For_Selected (Context, Best);
            else
               Result.Status := Resolution_Indeterminate;
            end if;

            Add_Resolution (Model, Result);
         end;
      end loop;

      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Contexts.Result_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Candidates.Result_Fingerprint);
      return Model;
   end Build;

   function Context_Count (Model : Context_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Context_Count;

   function Candidate_Count (Model : Candidate_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Candidate_Count;

   function Resolution_Count (Model : Resolution_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Resolution_Count;

   function Resolution_At
     (Model : Resolution_Model;
      Index : Positive) return Resolution_Info is
   begin
      if Index > Natural (Model.Items.Length) then
         return Empty_Resolution;
      end if;
      return Model.Items (Index);
   end Resolution_At;

   function First_For_Node
     (Model : Resolution_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Resolution_Info is
   begin
      for Info of Model.Items loop
         if Info.Node = Node then
            return Info;
         end if;
      end loop;
      return Empty_Resolution;
   end First_For_Node;

   function Count_Status
     (Model  : Resolution_Model;
      Status : Resolution_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Items loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Legal_Count (Model : Resolution_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Resolution_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Ambiguous_Count (Model : Resolution_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Count;

   function Fingerprint (Model : Resolution_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Resolution (Info : Resolution_Info) return Boolean is
   begin
      return Info.Id /= No_Resolution;
   end Has_Resolution;

end Editor.Ada_Call_And_Operator_Overload_Resolution_Legality;
