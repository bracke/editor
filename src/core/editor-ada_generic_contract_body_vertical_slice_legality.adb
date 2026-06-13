with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Generic_Contract_Body_Vertical_Slice_Legality is

   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 521) + 1298) mod 1_000_000_007;
   end Mix;

   function Normalize (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));
   end Normalize;

   function Same (Left, Right : Unbounded_String) return Boolean is
   begin
      return Normalize (To_String (Left)) = Normalize (To_String (Right));
   end Same;

   function Empty (Value : Unbounded_String) return Boolean is
   begin
      return Normalize (To_String (Value)) = "";
   end Empty;

   function Actual_Kind_For (Kind : Formal_Kind) return Actual_Kind is
   begin
      case Kind is
         when Formal_Type => return Actual_Type;
         when Formal_Object => return Actual_Object;
         when Formal_Subprogram => return Actual_Subprogram;
         when Formal_Package => return Actual_Package;
         when Formal_Unknown => return Actual_Unknown;
      end case;
   end Actual_Kind_For;

   function Compatible_Type_Class
     (Formal : Unbounded_String;
      Actual : Unbounded_String) return Boolean
   is
      F : constant String := Normalize (To_String (Formal));
      A : constant String := Normalize (To_String (Actual));
   begin
      if F = "" or else F = "any" or else F = A then
         return True;
      end if;
      if F = "discrete" then
         return A = "integer" or else A = "enumeration" or else A = "modular";
      elsif F = "integer" then
         return A = "integer" or else A = "universal_integer";
      elsif F = "real" then
         return A = "real" or else A = "float" or else A = "fixed"
           or else A = "universal_real";
      elsif F = "private" then
         return A = "private" or else A = "tagged_private" or else A = "limited_private";
      elsif F = "tagged" then
         return A = "tagged" or else A = "tagged_private" or else A = "class_wide";
      elsif F = "limited" then
         return A = "limited" or else A = "limited_private";
      end if;
      return False;
   end Compatible_Type_Class;

   function Compatible_Mode (Formal, Actual : Formal_Mode) return Boolean is
   begin
      return Formal = Mode_None or else Formal = Actual;
   end Compatible_Mode;

   function Compatible_Text
     (Formal : Unbounded_String;
      Actual : Unbounded_String) return Boolean is
   begin
      return Empty (Formal) or else Same (Formal, Actual);
   end Compatible_Text;

   procedure Clear (Model : in out Instance_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

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

   procedure Add_Instance (Model : in out Instance_Model; Info : Instance_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Info.Formal_Fingerprint + Info.Actual_Fingerprint
         + Info.Substitution_Fingerprint + Info.Source_Fingerprint);
   end Add_Instance;

   procedure Add_Formal (Model : in out Formal_Model; Info : Formal_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Instance) + Info.Formal_Fingerprint);
   end Add_Formal;

   procedure Add_Actual (Model : in out Actual_Model; Info : Actual_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Natural (Info.Id) + Natural (Info.Instance) + Info.Actual_Fingerprint);
   end Add_Actual;

   function Matching_Actual
     (Actuals : Actual_Model;
      Inst    : Instance_Id;
      Formal  : Formal_Info) return Actual_Info
   is
   begin
      for A of Actuals.Items loop
         if A.Instance = Inst and then Same (A.Formal_Name, Formal.Name) then
            return A;
         end if;
      end loop;
      return (others => <>);
   end Matching_Actual;

   function Has_Formal
     (Formals : Formal_Model;
      Inst    : Instance_Id;
      Name    : Unbounded_String) return Boolean is
   begin
      for F of Formals.Items loop
         if F.Instance = Inst and then Same (F.Name, Name) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Formal;

   function Status_For (R : Result_Info; Inst : Instance_Info) return Generic_Status is
   begin
      if R.Fingerprint_Blockers > 0 then
         return Generic_Substitution_Fingerprint_Mismatch;
      elsif Inst.Nested_Cycle then
         return Generic_Nested_Instance_Cycle;
      elsif R.Private_View_Blockers > 0 then
         return Generic_Private_View_Barrier;
      elsif R.Kind_Mismatches > 0 then
         return Generic_Formal_Actual_Kind_Mismatch;
      elsif R.Type_Class_Mismatches > 0 then
         return Generic_Type_Class_Mismatch;
      elsif R.Mode_Mismatches > 0 then
         return Generic_Object_Mode_Mismatch;
      elsif R.Profile_Mismatches > 0 then
         return Generic_Subprogram_Profile_Mismatch;
      elsif R.Package_Contract_Mismatches > 0 then
         return Generic_Package_Contract_Mismatch;
      elsif R.Missing_Formals > 0 then
         return Generic_Missing_Actual;
      elsif R.Extra_Actuals > 0 then
         return Generic_Extra_Actual;
      elsif Inst.Requires_Body_Replay and then not Inst.Body_Available then
         return Generic_Body_Unavailable;
      elsif Inst.Requires_Body_Replay and then not Inst.Body_Replay_Accepted then
         return Generic_Body_Replay_Failed;
      elsif Inst.Nested_Instance then
         return Generic_Legal_Nested_Instance;
      elsif R.Defaulted_Formals > 0 then
         return Generic_Legal_Defaulted_Formal_Object;
      elsif R.Package_Contract_Mismatches = 0 and then R.Matched_Formals > 0 then
         if R.Profile_Mismatches = 0 then
            return Generic_Legal_Exact;
         end if;
      end if;
      return Generic_Legal_Exact;
   end Status_For;

   function Is_Legal (Status : Generic_Status) return Boolean is
   begin
      return Status in Generic_Legal_Exact
        | Generic_Legal_Defaulted_Formal_Object
        | Generic_Legal_Formal_Subprogram_Profile
        | Generic_Legal_Formal_Package_Contract
        | Generic_Legal_Nested_Instance;
   end Is_Legal;

   function Build
     (Instances : Instance_Model;
      Formals   : Formal_Model;
      Actuals   : Actual_Model) return Result_Model
   is
      Result : Result_Model;
      Next_Id : Natural := 1;
   begin
      for Inst of Instances.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            Next_Id := Next_Id + 1;
            R.Instance := Inst.Id;
            R.Node := Inst.Node;
            R.Source_Fingerprint := Inst.Source_Fingerprint;
            R.Substitution_Fingerprint := Inst.Substitution_Fingerprint;

            if Inst.Substitution_Fingerprint = 0
              or else Inst.Formal_Fingerprint = 0
              or else Inst.Actual_Fingerprint = 0
            then
               R.Fingerprint_Blockers := R.Fingerprint_Blockers + 1;
            end if;

            for F of Formals.Items loop
               if F.Instance = Inst.Id then
                  declare
                     A : constant Actual_Info := Matching_Actual (Actuals, Inst.Id, F);
                  begin
                     if A.Id = No_Actual then
                        if F.Has_Default and then F.Kind = Formal_Object then
                           R.Defaulted_Formals := R.Defaulted_Formals + 1;
                        elsif F.Required then
                           R.Missing_Formals := R.Missing_Formals + 1;
                        end if;
                     else
                        R.Matched_Formals := R.Matched_Formals + 1;
                        if A.Kind /= Actual_Kind_For (F.Kind) then
                           R.Kind_Mismatches := R.Kind_Mismatches + 1;
                        elsif F.Kind = Formal_Type and then
                          not Compatible_Type_Class (F.Type_Class, A.Type_Class)
                        then
                           R.Type_Class_Mismatches := R.Type_Class_Mismatches + 1;
                        elsif F.Kind = Formal_Object and then
                          (not Compatible_Type_Class (F.Type_Class, A.Type_Class)
                           or else not Compatible_Mode (F.Mode, A.Mode))
                        then
                           if not Compatible_Mode (F.Mode, A.Mode) then
                              R.Mode_Mismatches := R.Mode_Mismatches + 1;
                           else
                              R.Type_Class_Mismatches := R.Type_Class_Mismatches + 1;
                           end if;
                        elsif F.Kind = Formal_Subprogram and then
                          not Compatible_Text (F.Profile, A.Profile)
                        then
                           R.Profile_Mismatches := R.Profile_Mismatches + 1;
                        elsif F.Kind = Formal_Package and then
                          not Compatible_Text (F.Package_Contract, A.Package_Contract)
                        then
                           R.Package_Contract_Mismatches := R.Package_Contract_Mismatches + 1;
                        end if;

                        if F.Requires_Private_View and then A.Uses_Private_View
                          and then not Inst.Private_View_Allowed
                        then
                           R.Private_View_Blockers := R.Private_View_Blockers + 1;
                        end if;
                     end if;
                  end;
               end if;
            end loop;

            for A of Actuals.Items loop
               if A.Instance = Inst.Id and then not Has_Formal (Formals, Inst.Id, A.Formal_Name) then
                  R.Extra_Actuals := R.Extra_Actuals + 1;
               end if;
            end loop;

            if Inst.Requires_Body_Replay and then
              (not Inst.Body_Available or else not Inst.Body_Replay_Accepted)
            then
               R.Body_Blockers := 1;
            end if;

            if Inst.Nested_Cycle then
               R.Nested_Blockers := 1;
            end if;

            R.Status := Status_For (R, Inst);
            if R.Status = Generic_Legal_Formal_Subprogram_Profile then
               null;
            elsif R.Status = Generic_Legal_Exact then
               for F of Formals.Items loop
                  if F.Instance = Inst.Id and then F.Kind = Formal_Subprogram then
                     R.Status := Generic_Legal_Formal_Subprogram_Profile;
                  elsif F.Instance = Inst.Id and then F.Kind = Formal_Package then
                     R.Status := Generic_Legal_Formal_Package_Contract;
                  end if;
               end loop;
            end if;

            if Is_Legal (R.Status) then
               R.Message := To_Unbounded_String ("generic contract accepted");
               Result.Legal_Total := Result.Legal_Total + 1;
            else
               R.Message := To_Unbounded_String ("generic contract rejected");
               Result.Error_Total := Result.Error_Total + 1;
            end if;

            R.Detail := To_Unbounded_String
              ("matched=" & Natural'Image (R.Matched_Formals)
               & " missing=" & Natural'Image (R.Missing_Formals)
               & " extra=" & Natural'Image (R.Extra_Actuals));
            R.Fingerprint := Mix
              (Inst.Source_Fingerprint,
               Inst.Substitution_Fingerprint + R.Matched_Formals + R.Missing_Formals
               + R.Extra_Actuals + R.Kind_Mismatches + R.Type_Class_Mismatches
               + R.Mode_Mismatches + R.Profile_Mismatches
               + R.Package_Contract_Mismatches + R.Private_View_Blockers
               + R.Body_Blockers + R.Nested_Blockers + Natural (Generic_Status'Pos (R.Status)));
            Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, R.Fingerprint);
            Result.Items.Append (R);
         end;
      end loop;
      return Result;
   end Build;

   function Instance_Count (Model : Instance_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Instance_Count;

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
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items (Index);
   end Result_At;

   function First_For_Node
     (Model : Result_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Result_Info is
   begin
      for R of Model.Items loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Count_Status (Model : Result_Model; Status : Generic_Status) return Natural is
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
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Result_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Fingerprint (Model : Result_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Result (Info : Result_Info) return Boolean is
   begin
      return Info.Id /= No_Result;
   end Has_Result;

end Editor.Ada_Generic_Contract_Body_Vertical_Slice_Legality;
