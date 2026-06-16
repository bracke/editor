with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tagged_Dispatching_Vertical_Slice_Legality is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 65599) + (B * 1009) + 1311) mod 1_000_000_007;
   end Mix;

   function Is_Tagged (Kind : Type_Class) return Boolean is
   begin
      return Kind in Type_Tagged
        | Type_Tagged_Private
        | Type_Tagged_Limited
        | Type_Class_Wide
        | Type_Interface
        | Type_Synchronized_Interface
        | Type_Task_Interface
        | Type_Protected_Interface
        | Type_Abstract_Tagged;
   end Is_Tagged;

   function Is_Interface (Kind : Type_Class) return Boolean is
   begin
      return Kind in Type_Interface
        | Type_Synchronized_Interface
        | Type_Task_Interface
        | Type_Protected_Interface;
   end Is_Interface;

   function Is_Extension (Kind : Dispatch_Kind) return Boolean is
   begin
      return Kind in Dispatch_Type_Extension
        | Dispatch_Private_Extension
        | Dispatch_Null_Extension;
   end Is_Extension;

   function Is_Primitive_Context (Kind : Dispatch_Kind) return Boolean is
   begin
      return Kind in Dispatch_Primitive_Declaration
        | Dispatch_Primitive_Override
        | Dispatch_Inherited_Primitive
        | Dispatch_Abstract_Primitive;
   end Is_Primitive_Context;

   function Is_Dispatch_Call (Kind : Dispatch_Kind) return Boolean is
   begin
      return Kind in Dispatch_Dispatching_Call
        | Dispatch_Class_Wide_Call
        | Dispatch_Controlling_Result_Call;
   end Is_Dispatch_Call;

   function Blocker_Count (R : Result_Info) return Natural is
   begin
      return R.AST_Blockers
        + R.Context_Blockers
        + R.Not_Tagged_Blockers
        + R.Parent_Missing_Blockers
        + R.Parent_Not_Tagged_Blockers
        + R.Private_View_Blockers
        + R.Limited_View_Blockers
        + R.Interface_Mismatch_Blockers
        + R.Interface_Missing_Blockers
        + R.Abstract_Not_Overridden_Blockers
        + R.Concrete_Required_Blockers
        + R.Profile_Blockers
        + R.Overriding_Required_Blockers
        + R.Overriding_Forbidden_Blockers
        + R.Inherited_Hidden_Blockers
        + R.Dispatch_Target_Blockers
        + R.Controlling_Operand_Blockers
        + R.Controlling_Result_Blockers
        + R.Class_Wide_Blockers
        + R.Ambiguous_Dispatch_Blockers
        + R.Non_Dispatching_Blockers
        + R.Accessibility_Blockers
        + R.Generic_Contract_Blockers
        + R.Renaming_Blockers
        + R.Exception_Finalization_Blockers
        + R.Source_Fingerprint_Blockers
        + R.AST_Fingerprint_Blockers
        + R.Profile_Fingerprint_Blockers
        + R.Substitution_Fingerprint_Blockers;
   end Blocker_Count;

   function Status_For (R : Result_Info; Info : Dispatch_Info) return Legality_Status is
      Count : constant Natural := Blocker_Count (R);
   begin
      if Count > 1 then
         return Legality_Multiple_Blockers;
      elsif R.AST_Blockers > 0 then
         return Legality_Missing_AST_Coverage;
      elsif R.Context_Blockers > 0 then
         return Legality_Missing_Context;
      elsif R.Not_Tagged_Blockers > 0 then
         return Legality_Not_Tagged;
      elsif R.Parent_Missing_Blockers > 0 then
         return Legality_Parent_Missing;
      elsif R.Parent_Not_Tagged_Blockers > 0 then
         return Legality_Parent_Not_Tagged;
      elsif R.Private_View_Blockers > 0 then
         return Legality_Private_View_Barrier;
      elsif R.Limited_View_Blockers > 0 then
         return Legality_Limited_View_Barrier;
      elsif R.Interface_Mismatch_Blockers > 0 then
         return Legality_Interface_Mismatch;
      elsif R.Interface_Missing_Blockers > 0 then
         return Legality_Interface_Not_Implemented;
      elsif R.Abstract_Not_Overridden_Blockers > 0 then
         return Legality_Abstract_Primitive_Not_Overridden;
      elsif R.Concrete_Required_Blockers > 0 then
         return Legality_Concrete_Primitive_Required;
      elsif R.Profile_Blockers > 0 then
         return Legality_Primitive_Profile_Mismatch;
      elsif R.Overriding_Required_Blockers > 0 then
         return Legality_Overriding_Required;
      elsif R.Overriding_Forbidden_Blockers > 0 then
         return Legality_Overriding_Forbidden;
      elsif R.Inherited_Hidden_Blockers > 0 then
         return Legality_Inherited_Primitive_Hidden;
      elsif R.Dispatch_Target_Blockers > 0 then
         return Legality_Dispatching_Target_Missing;
      elsif R.Controlling_Operand_Blockers > 0 then
         return Legality_Controlling_Operand_Missing;
      elsif R.Controlling_Result_Blockers > 0 then
         return Legality_Controlling_Result_Mismatch;
      elsif R.Class_Wide_Blockers > 0 then
         return Legality_Class_Wide_Mismatch;
      elsif R.Ambiguous_Dispatch_Blockers > 0 then
         return Legality_Ambiguous_Dispatching_Call;
      elsif R.Non_Dispatching_Blockers > 0 then
         return Legality_Non_Dispatching_Call;
      elsif R.Accessibility_Blockers > 0 then
         return Legality_Accessibility_Blocked;
      elsif R.Generic_Contract_Blockers > 0 then
         return Legality_Generic_Contract_Blocked;
      elsif R.Renaming_Blockers > 0 then
         return Legality_Renaming_Blocked;
      elsif R.Exception_Finalization_Blockers > 0 then
         return Legality_Exception_Finalization_Blocked;
      elsif R.Source_Fingerprint_Blockers > 0 then
         return Legality_Source_Fingerprint_Mismatch;
      elsif R.AST_Fingerprint_Blockers > 0 then
         return Legality_AST_Fingerprint_Mismatch;
      elsif R.Profile_Fingerprint_Blockers > 0 then
         return Legality_Profile_Fingerprint_Mismatch;
      elsif R.Substitution_Fingerprint_Blockers > 0 then
         return Legality_Substitution_Fingerprint_Mismatch;
      elsif Info.Kind = Dispatch_Unknown or else Info.Controlling = Controlling_Unknown then
         return Legality_Indeterminate;
      elsif R.Runtime_Check_Required then
         return Legality_Legal_With_Runtime_Check;
      else
         return Legality_Legal;
      end if;
   end Status_For;

   procedure Clear (Model : in out Dispatch_Model) is
   begin
      Model.Items.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Dispatch (Model : in out Dispatch_Model; Info : Dispatch_Info) is
   begin
      Model.Items.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Dispatch_Kind'Pos (Info.Kind)));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.AST_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Profile_Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Substitution_Fingerprint);
   end Add_Dispatch;

   function Build (Dispatches : Dispatch_Model) return Result_Model is
      Results : Result_Model;
      Next_Id : Natural := 1;
   begin
      for Info of Dispatches.Items loop
         declare
            R : Result_Info;
         begin
            R.Id := Result_Id (Next_Id);
            R.Dispatch := Info.Id;
            R.Node := Info.Node;
            R.Kind := Info.Kind;
            R.Runtime_Check_Required := Info.Runtime_Tag_Check_Required;
            R.Source_Fingerprint := Info.Source_Fingerprint;
            R.AST_Fingerprint := Info.AST_Fingerprint;
            R.Profile_Fingerprint := Info.Profile_Fingerprint;
            R.Substitution_Fingerprint := Info.Substitution_Fingerprint;

            if not Info.Has_AST_Coverage then
               R.AST_Blockers := R.AST_Blockers + 1;
            end if;
            if not Info.Has_Context then
               R.Context_Blockers := R.Context_Blockers + 1;
            end if;
            if not Is_Tagged (Info.Type_Kind) then
               R.Not_Tagged_Blockers := R.Not_Tagged_Blockers + 1;
            end if;
            if Is_Extension (Info.Kind) then
               if not Info.Has_Parent_Type then
                  R.Parent_Missing_Blockers := R.Parent_Missing_Blockers + 1;
               elsif not Is_Tagged (Info.Parent_Type_Kind) then
                  R.Parent_Not_Tagged_Blockers := R.Parent_Not_Tagged_Blockers + 1;
               elsif not Info.Parent_Visible then
                  R.Private_View_Blockers := R.Private_View_Blockers + 1;
               end if;
            end if;
            if Info.Kind = Dispatch_Private_Extension and then not Info.Private_View_Available then
               R.Private_View_Blockers := R.Private_View_Blockers + 1;
            end if;
            if Info.Type_Kind = Type_Tagged_Limited and then not Info.Limited_View_Available then
               R.Limited_View_Blockers := R.Limited_View_Blockers + 1;
            end if;
            if Info.Kind in Dispatch_Interface_Implementation | Dispatch_Interface_Type then
               if not Is_Interface (Info.Parent_Type_Kind) and then Info.Kind = Dispatch_Interface_Implementation then
                  R.Interface_Mismatch_Blockers := R.Interface_Mismatch_Blockers + 1;
               end if;
               if not Info.Required_Interface_Present or else not Info.Implements_Interface then
                  R.Interface_Missing_Blockers := R.Interface_Missing_Blockers + 1;
               end if;
               if not Info.Interface_Profile_Conformant then
                  R.Interface_Mismatch_Blockers := R.Interface_Mismatch_Blockers + 1;
               end if;
            end if;
            if Info.Kind = Dispatch_Null_Extension and then not Info.Null_Extension_Legal then
               R.Interface_Mismatch_Blockers := R.Interface_Mismatch_Blockers + 1;
            end if;
            if Is_Primitive_Context (Info.Kind) then
               if Info.Override = Override_Required and then not Info.Has_Overridden_Primitive then
                  R.Overriding_Required_Blockers := R.Overriding_Required_Blockers + 1;
               end if;
               if Info.Override = Override_Forbidden and then Info.Has_Overridden_Primitive then
                  R.Overriding_Forbidden_Blockers := R.Overriding_Forbidden_Blockers + 1;
               end if;
               if not Info.Profile_Conformant then
                  R.Profile_Blockers := R.Profile_Blockers + 1;
               end if;
               if not Info.Abstract_Primitive_Overridden then
                  R.Abstract_Not_Overridden_Blockers := R.Abstract_Not_Overridden_Blockers + 1;
               end if;
               if Info.Primitive_Kind /= Primitive_Abstract and then not Info.Concrete_Primitive_Available then
                  R.Concrete_Required_Blockers := R.Concrete_Required_Blockers + 1;
               end if;
               if Info.Kind = Dispatch_Inherited_Primitive and then not Info.Inherited_Primitive_Visible then
                  R.Inherited_Hidden_Blockers := R.Inherited_Hidden_Blockers + 1;
               end if;
            end if;
            if Is_Dispatch_Call (Info.Kind) then
               if not Info.Has_Dispatching_Target then
                  R.Dispatch_Target_Blockers := R.Dispatch_Target_Blockers + 1;
               end if;
               if Info.Controlling in Controlling_Operand | Controlling_Operand_And_Result
                 and then not Info.Has_Controlling_Operand
               then
                  R.Controlling_Operand_Blockers := R.Controlling_Operand_Blockers + 1;
               end if;
               if Info.Kind = Dispatch_Class_Wide_Call and then not Info.Controlling_Operand_Class_Wide then
                  R.Class_Wide_Blockers := R.Class_Wide_Blockers + 1;
               end if;
               if Info.Controlling in Controlling_Result | Controlling_Operand_And_Result
                 and then not Info.Controlling_Result_Compatible
               then
                  R.Controlling_Result_Blockers := R.Controlling_Result_Blockers + 1;
               end if;
               if not Info.Class_Wide_Compatible then
                  R.Class_Wide_Blockers := R.Class_Wide_Blockers + 1;
               end if;
               if Info.Visible_Candidate_Count > 1 then
                  R.Ambiguous_Dispatch_Blockers := R.Ambiguous_Dispatch_Blockers + 1;
               end if;
               if Info.Candidate_Count = 0 or else Info.Visible_Candidate_Count = 0 then
                  R.Dispatch_Target_Blockers := R.Dispatch_Target_Blockers + 1;
               end if;
               if not Info.Dispatching_Call_Expected then
                  R.Non_Dispatching_Blockers := R.Non_Dispatching_Blockers + 1;
               end if;
            end if;
            if not Info.Accessibility_Legal then
               R.Accessibility_Blockers := R.Accessibility_Blockers + 1;
            end if;
            if not Info.Generic_Contract_Legal then
               R.Generic_Contract_Blockers := R.Generic_Contract_Blockers + 1;
            end if;
            if not Info.Renaming_Legal then
               R.Renaming_Blockers := R.Renaming_Blockers + 1;
            end if;
            if not Info.Exception_Finalization_Legal then
               R.Exception_Finalization_Blockers := R.Exception_Finalization_Blockers + 1;
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
            if Info.Expected_Profile_Fingerprint /= 0
              and then Info.Expected_Profile_Fingerprint /= Info.Profile_Fingerprint
            then
               R.Profile_Fingerprint_Blockers := R.Profile_Fingerprint_Blockers + 1;
            end if;
            if Info.Expected_Substitution_Fingerprint /= 0
              and then Info.Expected_Substitution_Fingerprint /= Info.Substitution_Fingerprint
            then
               R.Substitution_Fingerprint_Blockers := R.Substitution_Fingerprint_Blockers + 1;
            end if;

            R.Status := Status_For (R, Info);
            R.Message := To_Unbounded_String (Legality_Status'Image (R.Status));
            R.Detail := Info.Source_Name;
            R.Fingerprint := Mix (Natural (R.Id), Natural (Legality_Status'Pos (R.Status)));
            R.Fingerprint := Mix (R.Fingerprint, Natural (Dispatch_Kind'Pos (R.Kind)));
            R.Fingerprint := Mix (R.Fingerprint, R.Source_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.AST_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Profile_Fingerprint);
            R.Fingerprint := Mix (R.Fingerprint, R.Substitution_Fingerprint);

            Results.Items.Append (R);
            Results.Result_Fingerprint := Mix (Results.Result_Fingerprint, R.Fingerprint);
            Next_Id := Next_Id + 1;
         end;
      end loop;
      return Results;
   end Build;

   function Dispatch_Count (Model : Dispatch_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Dispatch_Count;

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

end Editor.Ada_Tagged_Dispatching_Vertical_Slice_Legality;
