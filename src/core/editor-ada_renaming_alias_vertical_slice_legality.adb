with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Renaming_Alias_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1309) mod 1_000_000_007;
   end Mix;

   function Numeric_Compatible (Actual, Expected : Type_Class) return Boolean is
   begin
      if Actual = Expected then
         return True;
      elsif Expected in Type_Integer | Type_Modular and then Actual = Type_Universal_Integer then
         return True;
      elsif Expected = Type_Real and then Actual in Type_Universal_Real | Type_Universal_Integer then
         return True;
      else
         return False;
      end if;
   end Numeric_Compatible;

   function Type_Compatible (Actual, Expected : Type_Class; Universal_OK : Boolean) return Boolean is
   begin
      if Expected = Type_Unknown or else Actual = Type_Unknown then
         return True;
      elsif Actual = Expected then
         return True;
      elsif Universal_OK then
         return Numeric_Compatible (Actual, Expected);
      else
         return False;
      end if;
   end Type_Compatible;

   function Expected_Entity_For (Kind : Rename_Kind) return Entity_Kind is
   begin
      case Kind is
         when Rename_Object       => return Entity_Object;
         when Rename_Exception    => return Entity_Exception;
         when Rename_Package      => return Entity_Package;
         when Rename_Subprogram   => return Entity_Subprogram;
         when Rename_Generic_Unit => return Entity_Generic_Unit;
         when Rename_Entry        => return Entity_Entry;
         when Rename_Operator     => return Entity_Operator;
         when Rename_Unknown      => return Entity_Unknown;
      end case;
   end Expected_Entity_For;

   function Kind_Compatible (R : Rename_Info) return Boolean is
      Expected : constant Entity_Kind :=
        (if R.Expected_Target_Kind = Entity_Unknown
         then Expected_Entity_For (R.Kind)
         else R.Expected_Target_Kind);
   begin
      if Expected = Entity_Unknown or else R.Actual_Target_Kind = Entity_Unknown then
         return True;
      elsif R.Actual_Target_Kind = Expected then
         return True;
      elsif R.Kind = Rename_Object
        and then R.Actual_Target_Kind in Entity_Constant | Entity_Component | Entity_Function_Result
      then
         return True;
      elsif R.Kind = Rename_Subprogram
        and then R.Actual_Target_Kind = Entity_Operator
      then
         return True;
      else
         return False;
      end if;
   end Kind_Compatible;

   function Mode_Compatible (Actual, Expected : Mode_Kind) return Boolean is
   begin
      if Expected = Mode_None or else Actual = Mode_None then
         return True;
      elsif Actual = Expected then
         return True;
      elsif Expected = Mode_In and then Actual in Mode_In_Out | Mode_Out then
         return True;
      else
         return False;
      end if;
   end Mode_Compatible;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Context_Blockers
        + R.Target_Missing_Blockers
        + R.Target_Visibility_Blockers
        + R.Kind_Blockers
        + R.Type_Blockers
        + R.Mode_Blockers
        + R.Constant_View_Blockers
        + R.Limited_View_Blockers
        + R.Private_View_Blockers
        + R.Accessibility_Blockers
        + R.Subprogram_Profile_Blockers
        + R.Operator_Profile_Blockers
        + R.Generic_Contract_Blockers
        + R.Package_Contract_Blockers
        + R.Entry_Family_Blockers
        + R.Alias_Cycle_Blockers
        + R.Alias_Depth_Blockers
        + R.Predicate_Blockers
        + R.Shared_State_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Substitution_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; Info : Rename_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Context_Blockers > 0 then
         return Legality_Missing_Context;
      elsif R.Target_Missing_Blockers > 0 then
         return Legality_Target_Missing;
      elsif R.Target_Visibility_Blockers > 0 then
         return Legality_Target_Not_Visible;
      elsif R.Kind_Blockers > 0 then
         return Legality_Renamed_Kind_Mismatch;
      elsif R.Type_Blockers > 0 then
         return Legality_Object_Type_Mismatch;
      elsif R.Mode_Blockers > 0 then
         return Legality_Object_Mode_Mismatch;
      elsif R.Constant_View_Blockers > 0 then
         return Legality_Constant_View_Mismatch;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Blocked;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Blocked;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocked;
      elsif R.Subprogram_Profile_Blockers > 0 then
         return Legality_Subprogram_Profile_Mismatch;
      elsif R.Operator_Profile_Blockers > 0 then
         return Legality_Operator_Profile_Mismatch;
      elsif R.Generic_Contract_Blockers > 0 then
         return Legality_Generic_Contract_Mismatch;
      elsif R.Package_Contract_Blockers > 0 then
         return Legality_Package_Contract_Mismatch;
      elsif R.Entry_Family_Blockers > 0 then
         return Legality_Entry_Family_Mismatch;
      elsif R.Alias_Cycle_Blockers > 0 then
         return Legality_Alias_Cycle;
      elsif R.Alias_Depth_Blockers > 0 then
         return Legality_Alias_Depth_Exceeded;
      elsif R.Predicate_Blockers > 0 then
         return Legality_Predicate_Blocked;
      elsif R.Shared_State_Blockers > 0 then
         return Legality_Shared_State_Blocked;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Substitution_Fingerprint_Blockers > 0 then
         return Legality_Substitution_Fingerprint_Mismatch;
      elsif Info.Kind = Rename_Unknown then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_With_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Clear (Model : in out Rename_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Renaming (Model : in out Rename_Model; Info : Rename_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Kind'Pos));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Renaming;

   function Build (Renamings : Rename_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for Info of Renamings.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Rename := Info.Id;
            R.Node := Info.Node;
            R.Kind := Info.Kind;
            R.Resolved_Target_Kind := Info.Actual_Target_Kind;
            R.Resolved_Type := Info.Actual_Type;
            R.Source_Fingerprint := Info.Source_Fingerprint;
            R.AST_Fingerprint := Info.AST_Fingerprint;
            R.Substitution_Fingerprint := Info.Substitution_Fingerprint;
            R.Runtime_Check_Required := Info.Runtime_Check_Required;

            if not Info.Has_AST_Coverage then
               R.AST_Blockers := R.AST_Blockers + 1;
            end if;
            if not Info.Has_Context then
               R.Context_Blockers := R.Context_Blockers + 1;
            end if;
            if not Info.Has_Target then
               R.Target_Missing_Blockers := R.Target_Missing_Blockers + 1;
            elsif not Info.Target_Visible then
               R.Target_Visibility_Blockers := R.Target_Visibility_Blockers + 1;
            end if;
            if Info.Has_Target and then not Kind_Compatible (Info) then
               R.Kind_Blockers := R.Kind_Blockers + 1;
            end if;
            if Info.Kind = Rename_Object
              and then not Type_Compatible (Info.Actual_Type, Info.Expected_Type, Info.Universal_Compatible)
            then
               R.Type_Blockers := R.Type_Blockers + 1;
            end if;
            if Info.Kind = Rename_Object
              and then not Mode_Compatible (Info.Actual_Mode, Info.Expected_Mode)
            then
               R.Mode_Blockers := R.Mode_Blockers + 1;
            end if;
            if Info.Kind = Rename_Object
              and then not Info.Renaming_Defines_Constant_View
              and then not Info.Target_Is_Variable
            then
               R.Constant_View_Blockers := R.Constant_View_Blockers + 1;
            end if;
            if Info.Target_Is_Limited_View then
               R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
            end if;
            if Info.Target_Is_Private_View and then not Info.Full_View_Visible then
               R.Private_View_Blockers := R.Private_View_Blockers + 1;
            end if;
            if not Info.Accessibility_Legal then
               R.Accessibility_Blockers := R.Accessibility_Blockers + 1;
            end if;
            if Info.Kind = Rename_Subprogram and then not Info.Subprogram_Profile_Matches then
               R.Subprogram_Profile_Blockers := R.Subprogram_Profile_Blockers + 1;
            end if;
            if Info.Kind = Rename_Operator and then not Info.Operator_Profile_Matches then
               R.Operator_Profile_Blockers := R.Operator_Profile_Blockers + 1;
            end if;
            if Info.Kind = Rename_Generic_Unit and then not Info.Generic_Contract_Matches then
               R.Generic_Contract_Blockers := R.Generic_Contract_Blockers + 1;
            end if;
            if Info.Kind = Rename_Package and then not Info.Package_Contract_Matches then
               R.Package_Contract_Blockers := R.Package_Contract_Blockers + 1;
            end if;
            if Info.Kind = Rename_Entry and then not Info.Entry_Family_Profile_Matches then
               R.Entry_Family_Blockers := R.Entry_Family_Blockers + 1;
            end if;
            if Info.Alias_Cycle_Detected then
               R.Alias_Cycle_Blockers := R.Alias_Cycle_Blockers + 1;
            end if;
            if Info.Alias_Depth_Limit > 0 and then Info.Alias_Depth > Info.Alias_Depth_Limit then
               R.Alias_Depth_Blockers := R.Alias_Depth_Blockers + 1;
            end if;
            if not Info.Predicate_Legal then
               R.Predicate_Blockers := R.Predicate_Blockers + 1;
            end if;
            if not Info.Shared_State_Legal then
               R.Shared_State_Blockers := R.Shared_State_Blockers + 1;
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
            if Info.Expected_Substitution_Fingerprint /= 0
              and then Info.Expected_Substitution_Fingerprint /= Info.Substitution_Fingerprint
            then
               R.Substitution_Fingerprint_Blockers := R.Substitution_Fingerprint_Blockers + 1;
            end if;

            R.Status := Status_For (R, Info);
            R.Message := To_Unbounded_String (Legality_Status'Image (R.Status));
            R.Detail := Info.Source_Name;
            R.Fingerprint := Mix (Natural (R.Id), Natural (R.Status'Pos));
            R.Fingerprint := Mix (R.Fingerprint, Natural (R.Kind'Pos));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Substitution_Fingerprint);

            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   function Rename_Count (Model : Rename_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Rename_Count;

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

end Editor.Ada_Renaming_Alias_Vertical_Slice_Legality;
