with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Control_Flow_Statement_Vertical_Slice_Legality is

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1308) mod 1_000_000_007;
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

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Context_Blockers
        + R.Return_Missing_Blockers
        + R.Return_Unexpected_Blockers
        + R.Return_Type_Blockers
        + R.Return_Accessibility_Blockers
        + R.Return_Assignment_Blockers
        + R.Raise_Missing_Blockers
        + R.Raise_Visibility_Blockers
        + R.Exit_Target_Blockers
        + R.Exit_Target_Kind_Blockers
        + R.Goto_Target_Blockers
        + R.Goto_Scope_Blockers
        + R.Goto_Protected_Blockers
        + R.Condition_Blockers
        + R.Case_Type_Blockers
        + R.Case_Incomplete_Blockers
        + R.Case_Overlap_Blockers
        + R.Loop_Exit_Blockers
        + R.No_Return_Blockers
        + R.Unreachable_Blockers
        + R.Predicate_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; F : Flow_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Context_Blockers > 0 then
         return Legality_Missing_Context;
      elsif R.Return_Missing_Blockers > 0 then
         return Legality_Return_Missing_Expression;
      elsif R.Return_Unexpected_Blockers > 0 then
         return Legality_Return_Unexpected_Expression;
      elsif R.Return_Type_Blockers > 0 then
         return Legality_Return_Type_Mismatch;
      elsif R.Return_Accessibility_Blockers > 0 then
         return Legality_Return_Accessibility_Blocked;
      elsif R.Return_Assignment_Blockers > 0 then
         return Legality_Return_Definite_Assignment_Blocked;
      elsif R.Raise_Missing_Blockers > 0 then
         return Legality_Raise_Missing_Exception;
      elsif R.Raise_Visibility_Blockers > 0 then
         return Legality_Raise_Exception_Not_Visible;
      elsif R.Exit_Target_Blockers > 0 then
         return Legality_Exit_Target_Missing;
      elsif R.Exit_Target_Kind_Blockers > 0 then
         return Legality_Exit_Target_Not_Loop;
      elsif R.Goto_Target_Blockers > 0 then
         return Legality_Goto_Target_Missing;
      elsif R.Goto_Scope_Blockers > 0 then
         return Legality_Goto_Enters_Deeper_Scope;
      elsif R.Goto_Protected_Blockers > 0 then
         return Legality_Goto_Enters_Protected_Action;
      elsif R.Condition_Blockers > 0 then
         return Legality_Condition_Not_Boolean;
      elsif R.Case_Type_Blockers > 0 then
         return Legality_Case_Expression_Type_Mismatch;
      elsif R.Case_Incomplete_Blockers > 0 then
         return Legality_Case_Alternatives_Incomplete;
      elsif R.Case_Overlap_Blockers > 0 then
         return Legality_Case_Alternatives_Overlap;
      elsif R.Loop_Exit_Blockers > 0 then
         return Legality_Loop_Exit_Path_Missing;
      elsif R.No_Return_Blockers > 0 then
         return Legality_No_Return_Falls_Through;
      elsif R.Unreachable_Blockers > 0 then
         return Legality_Unreachable_Statement;
      elsif R.Predicate_Blockers > 0 then
         return Legality_Predicate_Blocked;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif F.Kind = Construct_Unknown then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_With_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   function Status_Code (Status : Legality_Status) return Natural is
   begin
      return Legality_Status'Pos (Status) + 1;
   end Status_Code;

   procedure Clear (Model : in out Flow_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Flow (Model : in out Flow_Model; Info : Flow_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Control_Construct_Kind'Pos (Info.Kind));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
   end Add_Flow;

   function Build (Flows : Flow_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for F of Flows.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Flow := F.Id;
            R.Node := F.Node;
            R.Kind := F.Kind;
            R.Resolved_Result_Type := F.Expected_Result_Type;
            R.Source_Fingerprint := F.Source_Fingerprint;
            R.AST_Fingerprint := F.AST_Fingerprint;

            if not F.Has_AST_Coverage then
               R.AST_Blockers := R.AST_Blockers + 1;
            end if;

            if not F.Has_Context then
               R.Context_Blockers := R.Context_Blockers + 1;
            end if;

            case F.Kind is
               when Construct_Return_Statement | Construct_Extended_Return |
                    Construct_Return_Expression =>
                  if F.Return_Expression_Required and then not F.Has_Return_Expression then
                     R.Return_Missing_Blockers := R.Return_Missing_Blockers + 1;
                  end if;

                  if F.In_Procedure and then F.Has_Return_Expression then
                     R.Return_Unexpected_Blockers := R.Return_Unexpected_Blockers + 1;
                  end if;

                  if F.In_Function
                    and then F.Has_Return_Expression
                    and then not Type_Compatible
                      (F.Actual_Result_Type, F.Expected_Result_Type, F.Universal_Compatible)
                  then
                     R.Return_Type_Blockers := R.Return_Type_Blockers + 1;
                  end if;

                  if not F.Return_Accessibility_Legal then
                     R.Return_Accessibility_Blockers := R.Return_Accessibility_Blockers + 1;
                  end if;

                  if not F.Return_Definite_Assignment_Legal then
                     R.Return_Assignment_Blockers := R.Return_Assignment_Blockers + 1;
                  end if;

               when Construct_Raise_Statement | Construct_Raise_Expression =>
                  if not F.Has_Exception_Entity then
                     R.Raise_Missing_Blockers := R.Raise_Missing_Blockers + 1;
                  elsif not F.Exception_Visible then
                     R.Raise_Visibility_Blockers := R.Raise_Visibility_Blockers + 1;
                  end if;

               when Construct_Exit_Statement =>
                  if not F.Has_Exit_Target then
                     R.Exit_Target_Blockers := R.Exit_Target_Blockers + 1;
                  elsif not F.Exit_Target_Is_Loop then
                     R.Exit_Target_Kind_Blockers := R.Exit_Target_Kind_Blockers + 1;
                  end if;

               when Construct_Goto_Statement =>
                  if not F.Has_Goto_Target then
                     R.Goto_Target_Blockers := R.Goto_Target_Blockers + 1;
                  end if;
                  if F.Goto_Enters_Deeper_Scope then
                     R.Goto_Scope_Blockers := R.Goto_Scope_Blockers + 1;
                  end if;
                  if F.Goto_Enters_Protected_Action then
                     R.Goto_Protected_Blockers := R.Goto_Protected_Blockers + 1;
                  end if;

               when Construct_If_Statement | Construct_If_Expression =>
                  if F.Condition_Type /= Type_Boolean then
                     R.Condition_Blockers := R.Condition_Blockers + 1;
                  end if;
                  if F.Kind = Construct_If_Expression and then F.Has_Return_Expression
                    and then not Type_Compatible
                      (F.Actual_Result_Type, F.Expected_Result_Type, F.Universal_Compatible)
                  then
                     R.Return_Type_Blockers := R.Return_Type_Blockers + 1;
                  end if;

               when Construct_Case_Statement | Construct_Case_Expression =>
                  if F.Case_Expression_Type /= Type_Unknown
                    and then F.Case_Alternative_Type /= Type_Unknown
                    and then not Type_Compatible
                      (F.Case_Alternative_Type, F.Case_Expression_Type, F.Universal_Compatible)
                  then
                     R.Case_Type_Blockers := R.Case_Type_Blockers + 1;
                  end if;
                  if not F.Case_Alternatives_Complete then
                     R.Case_Incomplete_Blockers := R.Case_Incomplete_Blockers + 1;
                  end if;
                  if F.Case_Alternatives_Overlap then
                     R.Case_Overlap_Blockers := R.Case_Overlap_Blockers + 1;
                  end if;
                  if F.Kind = Construct_Case_Expression and then F.Has_Return_Expression
                    and then not Type_Compatible
                      (F.Actual_Result_Type, F.Expected_Result_Type, F.Universal_Compatible)
                  then
                     R.Return_Type_Blockers := R.Return_Type_Blockers + 1;
                  end if;

               when Construct_Loop_Statement =>
                  if not F.Loop_Has_Exit_Path then
                     R.Loop_Exit_Blockers := R.Loop_Exit_Blockers + 1;
                  end if;

               when Construct_No_Return_Call =>
                  if F.No_Return_Expected and then F.May_Fall_Through then
                     R.No_Return_Blockers := R.No_Return_Blockers + 1;
                  end if;

               when Construct_Block_Statement | Construct_Unknown =>
                  null;
            end case;

            if not F.Statement_Reachable then
               R.Unreachable_Blockers := R.Unreachable_Blockers + 1;
            end if;

            if not F.Predicate_Legal then
               R.Predicate_Blockers := R.Predicate_Blockers + 1;
            elsif F.Runtime_Check_Required then
               R.Runtime_Check_Required := True;
            end if;

            if F.Expected_Source_Fingerprint /= 0
              and then F.Expected_Source_Fingerprint /= F.Source_Fingerprint
            then
               R.Source_Fingerprint_Blockers := R.Source_Fingerprint_Blockers + 1;
            end if;

            if F.Expected_AST_Fingerprint /= 0
              and then F.Expected_AST_Fingerprint /= F.AST_Fingerprint
            then
               R.AST_Fingerprint_Blockers := R.AST_Fingerprint_Blockers + 1;
            end if;

            R.Status := Status_For (R, F);
            R.Message := To_Unbounded_String ("control-flow statement legality");
            R.Detail := F.Source_Name;
            R.Fingerprint := Mix (Natural (R.Flow), Status_Code (R.Status));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, Blocker_Count (R));

            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;

      return Results;
   end Build;

   function Flow_Count (Model : Flow_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Flow_Count;

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
      Count : Natural := 0;
   begin
      for R of Model.Items loop
         if R.Status in Legality_Legal | Legality_Legal_With_Runtime_Check then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
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
      return Info.Id /= No_Result and then Info.Flow /= No_Flow;
   end Has_Result;

end Editor.Ada_Control_Flow_Statement_Vertical_Slice_Legality;
