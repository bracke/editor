with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Final_Semantic_Diagnostic_Integration is

   pragma Suppress (Overflow_Check);

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 131) + B + 1194) mod 2_147_483_647;
   end Mix;

   function Has (S, Pattern : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (S, Pattern) /= 0;
   end Has;

   procedure Add_Blocker
     (Candidate : Final_Diagnostic_Status;
      Result    : in out Final_Diagnostic_Status;
      Count     : in out Natural) is
   begin
      if Candidate /= Final_Diagnostic_Not_Checked then
         Count := Count + 1;
         if Result = Final_Diagnostic_Not_Checked then
            Result := Candidate;
         else
            Result := Final_Diagnostic_Multiple_Blockers;
         end if;
      end if;
   end Add_Blocker;

   function Status_From_Cross
     (Status : Cross_Final.Cross_Unit_Final_Status) return Final_Diagnostic_Status is
      Img : constant String := Cross_Final.Cross_Unit_Final_Status'Image (Status);
   begin
      if Cross_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Cross_Final.Is_Indeterminate (Status) then
         return Final_Diagnostic_Indeterminate;
      elsif Cross_Final.Is_View_Barrier (Status) then
         return Final_Diagnostic_View_Barrier;
      elsif Cross_Final.Is_Coverage_Error (Status) then
         return Final_Diagnostic_Coverage_Gate_Blocker;
      elsif Has (Img, "STALE") then
         return Final_Diagnostic_Stale_Input;
      else
         return Final_Diagnostic_Cross_Unit_Blocker;
      end if;
   end Status_From_Cross;

   function Status_From_Overload
     (Status : Overload_Final.Final_RM_Status) return Final_Diagnostic_Status is
      Img : constant String := Overload_Final.Final_RM_Status'Image (Status);
   begin
      if Overload_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Has (Img, "AST") then
         return Final_Diagnostic_AST_Repair_Blocker;
      elsif Has (Img, "INDETERMINATE") then
         return Final_Diagnostic_Indeterminate;
      elsif Has (Img, "STALE") then
         return Final_Diagnostic_Stale_Input;
      else
         return Final_Diagnostic_Overload_Type_Blocker;
      end if;
   end Status_From_Overload;

   function Status_From_Generic
     (Status : Generic_Final.Nested_Generic_Closure_Status) return Final_Diagnostic_Status is
      Img : constant String := Generic_Final.Nested_Generic_Closure_Status'Image (Status);
   begin
      if Generic_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Has (Img, "COVERAGE") then
         return Final_Diagnostic_Coverage_Gate_Blocker;
      elsif Has (Img, "INDETERMINATE") then
         return Final_Diagnostic_Indeterminate;
      elsif Has (Img, "STALE") then
         return Final_Diagnostic_Stale_Input;
      else
         return Final_Diagnostic_Generic_Replay_Blocker;
      end if;
   end Status_From_Generic;

   function Status_From_Representation
     (Status : Representation_Final.Final_Representation_Status) return Final_Diagnostic_Status is
      Img : constant String := Representation_Final.Final_Representation_Status'Image (Status);
   begin
      if Representation_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Representation_Final.Is_AST_Repair_Error (Status) then
         return Final_Diagnostic_AST_Repair_Blocker;
      elsif Representation_Final.Is_Indeterminate (Status) then
         return Final_Diagnostic_Indeterminate;
      elsif Has (Img, "COVERAGE") then
         return Final_Diagnostic_Coverage_Gate_Blocker;
      elsif Has (Img, "VIEW_BARRIER") then
         return Final_Diagnostic_View_Barrier;
      else
         return Final_Diagnostic_Representation_Freezing_Blocker;
      end if;
   end Status_From_Representation;

   function Status_From_Flow
     (Status : Flow_Final.Flow_Contract_Proof_Status) return Final_Diagnostic_Status is
   begin
      if Flow_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Flow_Final.Is_Indeterminate (Status) then
         return Final_Diagnostic_Indeterminate;
      else
         return Final_Diagnostic_Flow_Contract_Blocker;
      end if;
   end Status_From_Flow;

   function Status_From_Tasking
     (Status : Tasking_Final.Deep_Tasking_Status) return Final_Diagnostic_Status is
   begin
      if Tasking_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Tasking_Final.Is_Indeterminate (Status) then
         return Final_Diagnostic_Indeterminate;
      else
         return Final_Diagnostic_Tasking_Protected_Blocker;
      end if;
   end Status_From_Tasking;

   function Status_From_Elaboration
     (Status : Elaboration_Final.Final_Elaboration_Status) return Final_Diagnostic_Status is
   begin
      if Elaboration_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Elaboration_Final.Is_Indeterminate (Status) then
         return Final_Diagnostic_Indeterminate;
      else
         return Final_Diagnostic_Elaboration_Blocker;
      end if;
   end Status_From_Elaboration;

   function Status_From_Accessibility
     (Status : Access_Final.Master_Scope_Final_Status) return Final_Diagnostic_Status is
   begin
      if Access_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Access_Final.Is_Indeterminate (Status) then
         return Final_Diagnostic_Indeterminate;
      else
         return Final_Diagnostic_Accessibility_Lifetime_Blocker;
      end if;
   end Status_From_Accessibility;

   function Status_From_Discriminant
     (Status : Discriminant_Final.Discriminant_Consumer_Status) return Final_Diagnostic_Status is
   begin
      if Discriminant_Final.Is_Legal (Status) then
         return Final_Diagnostic_Not_Checked;
      elsif Discriminant_Final.Is_AST_Repair_Error (Status) then
         return Final_Diagnostic_AST_Repair_Blocker;
      else
         return Final_Diagnostic_Discriminant_Variant_Blocker;
      end if;
   end Status_From_Discriminant;

   function Classify
     (Context  : Final_Diagnostic_Context_Info;
      Blockers : out Natural) return Final_Diagnostic_Status is
      Result : Final_Diagnostic_Status := Final_Diagnostic_Not_Checked;
   begin
      Blockers := 0;

      if not Context.Input_Current then
         Add_Blocker (Final_Diagnostic_Stale_Input, Result, Blockers);
      end if;

      if Context.Expected_Source_Fingerprint /= 0
        and then Context.Source_Fingerprint /= Context.Expected_Source_Fingerprint
      then
         Add_Blocker (Final_Diagnostic_Stale_Input, Result, Blockers);
      end if;

      case Context.Family is
         when Final_Diagnostic_Cross_Unit =>
            Add_Blocker (Status_From_Cross (Context.Cross_Unit_Status), Result, Blockers);
         when Final_Diagnostic_Overload_Type =>
            Add_Blocker (Status_From_Overload (Context.Overload_Status), Result, Blockers);
         when Final_Diagnostic_Generic_Replay =>
            Add_Blocker (Status_From_Generic (Context.Generic_Status), Result, Blockers);
         when Final_Diagnostic_Representation_Freezing =>
            Add_Blocker (Status_From_Representation (Context.Representation_Status), Result, Blockers);
         when Final_Diagnostic_Flow_Contract =>
            Add_Blocker (Status_From_Flow (Context.Flow_Status), Result, Blockers);
         when Final_Diagnostic_Tasking_Protected =>
            Add_Blocker (Status_From_Tasking (Context.Tasking_Status), Result, Blockers);
         when Final_Diagnostic_Elaboration =>
            Add_Blocker (Status_From_Elaboration (Context.Elaboration_Status), Result, Blockers);
         when Final_Diagnostic_Accessibility_Lifetime =>
            Add_Blocker (Status_From_Accessibility (Context.Accessibility_Status), Result, Blockers);
         when Final_Diagnostic_Discriminant_Variant =>
            Add_Blocker (Status_From_Discriminant (Context.Discriminant_Status), Result, Blockers);
         when Final_Diagnostic_Multiple =>
            Add_Blocker (Status_From_Cross (Context.Cross_Unit_Status), Result, Blockers);
            Add_Blocker (Status_From_Overload (Context.Overload_Status), Result, Blockers);
            Add_Blocker (Status_From_Generic (Context.Generic_Status), Result, Blockers);
            Add_Blocker (Status_From_Representation (Context.Representation_Status), Result, Blockers);
            Add_Blocker (Status_From_Flow (Context.Flow_Status), Result, Blockers);
            Add_Blocker (Status_From_Tasking (Context.Tasking_Status), Result, Blockers);
            Add_Blocker (Status_From_Elaboration (Context.Elaboration_Status), Result, Blockers);
            Add_Blocker (Status_From_Accessibility (Context.Accessibility_Status), Result, Blockers);
            Add_Blocker (Status_From_Discriminant (Context.Discriminant_Status), Result, Blockers);
         when Final_Diagnostic_Unknown =>
            Add_Blocker (Final_Diagnostic_Indeterminate, Result, Blockers);
      end case;

      if Result = Final_Diagnostic_Not_Checked then
         return Final_Diagnostic_Withheld_Legal;
      else
         return Result;
      end if;
   end Classify;

   function Severity_For (Status : Final_Diagnostic_Status) return Final_Diagnostic_Severity is
   begin
      case Status is
         when Final_Diagnostic_Withheld_Legal =>
            return Final_Diagnostic_Severity_Info;
         when Final_Diagnostic_Indeterminate | Final_Diagnostic_Stale_Input | Final_Diagnostic_View_Barrier =>
            return Final_Diagnostic_Warning;
         when others =>
            return Final_Diagnostic_Error;
      end case;
   end Severity_For;

   function Message_For (Status : Final_Diagnostic_Status) return String is
   begin
      case Status is
         when Final_Diagnostic_Withheld_Legal => return "final semantic result withheld as legal non-diagnostic";
         when Final_Diagnostic_Multiple_Blockers => return "multiple final semantic blockers";
         when Final_Diagnostic_Indeterminate => return "final semantic state is indeterminate";
         when Final_Diagnostic_Stale_Input => return "final semantic input is stale";
         when others => return "final semantic blocker";
      end case;
   end Message_For;

   function Build_Row (Context : Final_Diagnostic_Context_Info) return Final_Diagnostic_Info is
      Blockers : Natural := 0;
      Status : constant Final_Diagnostic_Status := Classify (Context, Blockers);
      Row : Final_Diagnostic_Info;
   begin
      Row.Id := Context.Id;
      Row.Family := Context.Family;
      Row.Status := Status;
      Row.Severity := Severity_For (Status);
      Row.Node := Context.Node;
      if Length (Context.Message) = 0 then
         Row.Message := To_Unbounded_String (Message_For (Status));
      else
         Row.Message := Context.Message;
      end if;
      Row.Detail := To_Unbounded_String (Final_Diagnostic_Status'Image (Status));
      Row.Blocker_Count := Blockers;
      Row.Source_Fingerprint := Context.Source_Fingerprint;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Fingerprint := Mix (Natural (Row.Id), Natural (Row.Node));
      Row.Fingerprint := Mix (Row.Fingerprint, Final_Diagnostic_Status'Pos (Status));
      Row.Fingerprint := Mix (Row.Fingerprint, Final_Diagnostic_Source_Family'Pos (Row.Family));
      Row.Fingerprint := Mix (Row.Fingerprint, Row.Source_Fingerprint);
      return Row;
   end Build_Row;

   procedure Clear (Model : in out Final_Diagnostic_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Final_Diagnostic_Context_Model; Info : Final_Diagnostic_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Id));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Final_Diagnostic_Source_Family'Pos (Info.Family));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Natural (Info.Node));
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Source_Fingerprint);
   end Add_Context;

   function Context_Count (Model : Final_Diagnostic_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Final_Diagnostic_Context_Model; Index : Positive) return Final_Diagnostic_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Final_Diagnostic_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build (Contexts : Final_Diagnostic_Context_Model) return Final_Diagnostic_Model is
      Model : Final_Diagnostic_Model;
   begin
      for I in 1 .. Context_Count (Contexts) loop
         declare
            Row : constant Final_Diagnostic_Info := Build_Row (Context_At (Contexts, I));
         begin
            Model.Items.Append (Row);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
            case Row.Severity is
               when Final_Diagnostic_Error => Model.Error_Total := Model.Error_Total + 1;
               when Final_Diagnostic_Warning => Model.Warning_Total := Model.Warning_Total + 1;
               when Final_Diagnostic_Severity_Info => null;
            end case;
            if Row.Status = Final_Diagnostic_Withheld_Legal then
               Model.Withheld_Legal_Total := Model.Withheld_Legal_Total + 1;
            elsif Row.Status = Final_Diagnostic_Stale_Input then
               Model.Stale_Total := Model.Stale_Total + 1;
            elsif Row.Status = Final_Diagnostic_Indeterminate then
               Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            end if;
         end;
      end loop;
      return Model;
   end Build;

   function Row_Count (Model : Final_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Row_Count;

   function Row_At (Model : Final_Diagnostic_Model; Index : Positive) return Final_Diagnostic_Info is
   begin
      return Model.Items.Element (Index);
   end Row_At;

   function Rows_For_Status (Model : Final_Diagnostic_Model; Status : Final_Diagnostic_Status) return Final_Diagnostic_Set is
      Result : Final_Diagnostic_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         declare
            Row : constant Final_Diagnostic_Info := Row_At (Model, I);
         begin
            if Row.Status = Status then
               Result.Items.Append (Row);
               Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
            end if;
         end;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Family (Model : Final_Diagnostic_Model; Family : Final_Diagnostic_Source_Family) return Final_Diagnostic_Set is
      Result : Final_Diagnostic_Set;
   begin
      for I in 1 .. Row_Count (Model) loop
         declare
            Row : constant Final_Diagnostic_Info := Row_At (Model, I);
         begin
            if Row.Family = Family then
               Result.Items.Append (Row);
               Result.Result_Fingerprint := Mix (Result.Result_Fingerprint, Row.Fingerprint);
            end if;
         end;
      end loop;
      return Result;
   end Rows_For_Family;

   function Set_Count (Set : Final_Diagnostic_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Set_Count;

   function Set_At (Set : Final_Diagnostic_Set; Index : Positive) return Final_Diagnostic_Info is
   begin
      return Set.Items.Element (Index);
   end Set_At;

   function Count_Status (Model : Final_Diagnostic_Model; Status : Final_Diagnostic_Status) return Natural is
   begin
      return Set_Count (Rows_For_Status (Model, Status));
   end Count_Status;

   function Count_Family (Model : Final_Diagnostic_Model; Family : Final_Diagnostic_Source_Family) return Natural is
   begin
      return Set_Count (Rows_For_Family (Model, Family));
   end Count_Family;

   function Error_Count (Model : Final_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Final_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Withheld_Legal_Count (Model : Final_Diagnostic_Model) return Natural is
   begin
      return Model.Withheld_Legal_Total;
   end Withheld_Legal_Count;

   function Stale_Count (Model : Final_Diagnostic_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Count;

   function Indeterminate_Count (Model : Final_Diagnostic_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Final_Diagnostic_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Is_Emitted (Status : Final_Diagnostic_Status) return Boolean is
   begin
      return Status /= Final_Diagnostic_Withheld_Legal
        and then Status /= Final_Diagnostic_Not_Checked;
   end Is_Emitted;

   function Is_Blocker (Status : Final_Diagnostic_Status) return Boolean is
   begin
      return Status not in Final_Diagnostic_Not_Checked | Final_Diagnostic_Withheld_Legal | Final_Diagnostic_Indeterminate | Final_Diagnostic_Stale_Input;
   end Is_Blocker;

   function Is_Indeterminate (Status : Final_Diagnostic_Status) return Boolean is
   begin
      return Status = Final_Diagnostic_Indeterminate;
   end Is_Indeterminate;

end Editor.Ada_Final_Semantic_Diagnostic_Integration;
