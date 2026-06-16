with Editor.Ada_Direct_Visibility;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Ambiguity_Diagnostics is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Expression_Types.Expression_Type_Id;
   use type Editor.Ada_Expression_Types.Call_Actual_Type_Resolution_Status;
   use type Editor.Ada_Expression_Types.Operator_Type_Inference_Status;
   use type Editor.Ada_Expression_Types.Universal_Numeric_Resolution_Status;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 239) + B + 211) mod 1_000_000_007;
   end Mix;

   function Kind_Slot (Kind : Overload_Ambiguity_Kind) return Natural is
   begin
      return Overload_Ambiguity_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Severity_Slot (Severity : Overload_Ambiguity_Severity) return Natural is
   begin
      return Overload_Ambiguity_Severity'Pos (Severity) + 1;
   end Severity_Slot;

   function Is_Call_Kind (Kind : Overload_Ambiguity_Kind) return Boolean is
   begin
      return Kind in Overload_Ambiguity_Call_Unresolved ..
        Overload_Ambiguity_Call_Actual_Unknown;
   end Is_Call_Kind;

   function Is_Operator_Kind (Kind : Overload_Ambiguity_Kind) return Boolean is
   begin
      return Kind in Overload_Ambiguity_Operator_Ambiguous ..
        Overload_Ambiguity_Operator_Overload_Unknown;
   end Is_Operator_Kind;

   function Is_Universal_Kind (Kind : Overload_Ambiguity_Kind) return Boolean is
   begin
      return Kind in Overload_Ambiguity_Universal_Numeric_Mismatch ..
        Overload_Ambiguity_Universal_Numeric_Unknown;
   end Is_Universal_Kind;

   function Is_Ambiguous_Kind (Kind : Overload_Ambiguity_Kind) return Boolean is
   begin
      return Kind in Overload_Ambiguity_Call_Ambiguous |
        Overload_Ambiguity_Operator_Ambiguous |
        Overload_Ambiguity_Operator_Overload_Ambiguous;
   end Is_Ambiguous_Kind;

   function Is_Mismatch_Kind (Kind : Overload_Ambiguity_Kind) return Boolean is
   begin
      return Kind in Overload_Ambiguity_Call_Actual_Mismatch |
        Overload_Ambiguity_Operator_Operand_Mismatch |
        Overload_Ambiguity_Operator_Overload_Mismatch |
        Overload_Ambiguity_Universal_Numeric_Mismatch |
        Overload_Ambiguity_Universal_Numeric_Range_Error;
   end Is_Mismatch_Kind;

   function Is_Unknown_Kind (Kind : Overload_Ambiguity_Kind) return Boolean is
   begin
      return Kind in Overload_Ambiguity_Call_Unresolved |
        Overload_Ambiguity_Call_Profile_Unavailable |
        Overload_Ambiguity_Call_Actual_Unknown |
        Overload_Ambiguity_Operator_Operand_Unknown |
        Overload_Ambiguity_Operator_Result_Unknown |
        Overload_Ambiguity_Operator_Overload_Unknown |
        Overload_Ambiguity_Universal_Numeric_Unknown;
   end Is_Unknown_Kind;

   function Diagnostic_Fingerprint
     (Diagnostic : Overload_Ambiguity_Diagnostic) return Natural is
      H : Natural := Natural (Diagnostic.Id) + 1;
   begin
      H := Mix (H, Natural (Diagnostic.Expression) + 1);
      H := Mix (H, Natural (Diagnostic.Node) + 1);
      H := Mix (H, Kind_Slot (Diagnostic.Kind));
      H := Mix (H, Severity_Slot (Diagnostic.Severity));
      H := Mix (H, Diagnostic.Candidate_Count + 1);
      H := Mix (H, Diagnostic.Selected_Count + 1);
      H := Mix (H, Diagnostic.Compatible_Count + 1);
      H := Mix (H, Diagnostic.Mismatch_Count + 1);
      H := Mix (H, Diagnostic.Unknown_Count + 1);
      H := Mix (H, Diagnostic.Start_Line);
      H := Mix (H, Diagnostic.End_Line);
      H := Mix (H, Length (Diagnostic.Message) + Length (Diagnostic.Detail) + 1);
      H := Mix (H, Diagnostic.Source_Fingerprint + 1);
      return H;
   end Diagnostic_Fingerprint;

   function Make_Diagnostic
     (Info     : Expression_Info;
      Id       : Overload_Ambiguity_Diagnostic_Id;
      Kind     : Overload_Ambiguity_Kind;
      Severity : Overload_Ambiguity_Severity;
      Message  : String;
      Detail   : String) return Overload_Ambiguity_Diagnostic
   is
      Result : Overload_Ambiguity_Diagnostic;
   begin
      Result.Id := Id;
      Result.Expression := Info.Id;
      Result.Node := Info.Node;
      Result.Kind := Kind;
      Result.Severity := Severity;
      Result.Message := To_Unbounded_String (Message);
      Result.Detail := To_Unbounded_String (Detail);
      Result.Start_Line := Info.Start_Line;
      Result.Start_Column := 1;
      Result.End_Line := Info.End_Line;
      Result.End_Column := 1;
      Result.Source_Fingerprint := Info.Fingerprint;

      if Is_Call_Kind (Kind) then
         Result.Candidate_Count := Info.Call_Actual_Type_Candidate_Count;
         Result.Selected_Count := Natural (Boolean'Pos
           (Info.Call_Actual_Type_Selected_Declaration /=
            Editor.Ada_Direct_Visibility.No_Declaration));
         Result.Compatible_Count := Info.Call_Actual_Type_Compatible_Count;
         Result.Mismatch_Count := Info.Call_Actual_Type_Mismatch_Count;
         Result.Unknown_Count := Info.Call_Actual_Type_Unknown_Count;
      elsif Is_Operator_Kind (Kind) then
         Result.Candidate_Count := Info.Operator_Overload_Candidate_Count;
         Result.Selected_Count := Info.Operator_Overload_Selected_Count;
         Result.Compatible_Count := Info.Operator_Compatible_Operand_Count;
         Result.Mismatch_Count :=
           Info.Operator_Mismatched_Operand_Count + Info.Operator_Overload_Mismatch_Count;
         Result.Unknown_Count := Info.Operator_Unknown_Operand_Count;
      elsif Is_Universal_Kind (Kind) then
         Result.Candidate_Count := Natural (Boolean'Pos
           (Length (Info.Universal_Numeric_Expected_Subtype) > 0));
         Result.Selected_Count := Natural (Boolean'Pos
           (Length (Info.Universal_Numeric_Result_Subtype) > 0));
         if Kind = Overload_Ambiguity_Universal_Numeric_Range_Error or else
           Kind = Overload_Ambiguity_Universal_Numeric_Mismatch
         then
            Result.Mismatch_Count := 1;
         else
            Result.Unknown_Count := 1;
         end if;
      end if;

      Result.Fingerprint := Diagnostic_Fingerprint (Result);
      return Result;
   end Make_Diagnostic;

   procedure Append
     (Model      : in out Overload_Ambiguity_Model;
      Diagnostic : Overload_Ambiguity_Diagnostic) is
   begin
      if not Has_Diagnostic (Diagnostic) then
         return;
      end if;

      Model.Diagnostics.Append (Diagnostic);
      case Diagnostic.Severity is
         when Overload_Ambiguity_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Overload_Ambiguity_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Overload_Ambiguity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      if Is_Call_Kind (Diagnostic.Kind) then
         Model.Call_Total := Model.Call_Total + 1;
      elsif Is_Operator_Kind (Diagnostic.Kind) then
         Model.Operator_Total := Model.Operator_Total + 1;
      elsif Is_Universal_Kind (Diagnostic.Kind) then
         Model.Universal_Total := Model.Universal_Total + 1;
      end if;

      if Diagnostic.Candidate_Count > 0 and then
        (Diagnostic.Mismatch_Count > 0 or else Diagnostic.Unknown_Count > 0)
      then
         Model.Candidate_Rejection_Total :=
           Model.Candidate_Rejection_Total + Diagnostic.Mismatch_Count + Diagnostic.Unknown_Count;
      end if;

      if Is_Ambiguous_Kind (Diagnostic.Kind) then
         Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
      end if;
      if Is_Mismatch_Kind (Diagnostic.Kind) then
         Model.Mismatch_Total := Model.Mismatch_Total + 1;
      end if;
      if Is_Unknown_Kind (Diagnostic.Kind) then
         Model.Unknown_Total := Model.Unknown_Total + 1;
      end if;

      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Diagnostic.Fingerprint);
   end Append;

   procedure Append_For_Expression
     (Model : in out Overload_Ambiguity_Model;
      Info  : Expression_Info) is
      Next_Id : constant Overload_Ambiguity_Diagnostic_Id :=
        Overload_Ambiguity_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
   begin
      case Info.Call_Actual_Type_Status is
         when Editor.Ada_Expression_Types.Call_Actual_Type_Unresolved_Call =>
            Append (Model, Make_Diagnostic
              (Info, Next_Id, Overload_Ambiguity_Call_Unresolved,
               Overload_Ambiguity_Error,
               "call target is unresolved",
               "No callable declaration was selected for this call."));
         when Editor.Ada_Expression_Types.Call_Actual_Type_Ambiguous_Call =>
            Append (Model, Make_Diagnostic
              (Info, Next_Id, Overload_Ambiguity_Call_Ambiguous,
               Overload_Ambiguity_Error,
               "call target remains ambiguous",
               "Multiple callable candidates remain after available actual-type filtering."));
         when Editor.Ada_Expression_Types.Call_Actual_Type_Profile_Unavailable =>
            Append (Model, Make_Diagnostic
              (Info, Next_Id, Overload_Ambiguity_Call_Profile_Unavailable,
               Overload_Ambiguity_Warning,
               "call profile is unavailable",
               "The selected callable lacks enough profile metadata for actual/formal checks."));
         when Editor.Ada_Expression_Types.Call_Actual_Type_Actual_Mismatch =>
            Append (Model, Make_Diagnostic
              (Info, Next_Id, Overload_Ambiguity_Call_Actual_Mismatch,
               Overload_Ambiguity_Error,
               "call actual does not match its formal subtype",
               "At least one actual expression subtype is incompatible with the selected formal."));
         when Editor.Ada_Expression_Types.Call_Actual_Type_Actual_Unknown =>
            Append (Model, Make_Diagnostic
              (Info, Next_Id, Overload_Ambiguity_Call_Actual_Unknown,
               Overload_Ambiguity_Warning,
               "call actual subtype is unknown",
               "At least one actual expression could not be typed, so overload filtering remains incomplete."));
         when others =>
            null;
      end case;

      declare
         Id : constant Overload_Ambiguity_Diagnostic_Id :=
           Overload_Ambiguity_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      begin
         case Info.Operator_Status is
            when Editor.Ada_Expression_Types.Operator_Type_Ambiguous =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Operator_Ambiguous,
                  Overload_Ambiguity_Error,
                  "operator result remains ambiguous",
                  "The operator expression has more than one plausible interpretation."));
            when Editor.Ada_Expression_Types.Operator_Type_Operand_Mismatch =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Operator_Operand_Mismatch,
                  Overload_Ambiguity_Error,
                  "operator operand subtype mismatch",
                  "At least one operand is incompatible with the selected operator shape."));
            when Editor.Ada_Expression_Types.Operator_Type_Operand_Unknown =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Operator_Operand_Unknown,
                  Overload_Ambiguity_Warning,
                  "operator operand subtype is unknown",
                  "Operand typing is incomplete, so overload selection cannot be final."));
            when Editor.Ada_Expression_Types.Operator_Type_Result_Unknown =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Operator_Result_Unknown,
                  Overload_Ambiguity_Warning,
                  "operator result subtype is unknown",
                  "The operands were inspected but no deterministic result subtype is available."));
            when Editor.Ada_Expression_Types.Operator_Type_Overload_Ambiguous =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Operator_Overload_Ambiguous,
                  Overload_Ambiguity_Error,
                  "primitive operator overload remains ambiguous",
                  "Visible primitive operator candidates are not reduced to one declaration."));
            when Editor.Ada_Expression_Types.Operator_Type_Overload_Mismatch =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Operator_Overload_Mismatch,
                  Overload_Ambiguity_Error,
                  "primitive operator candidate rejected by operands",
                  "Visible primitive operator candidates do not accept the inferred operand subtypes."));
            when Editor.Ada_Expression_Types.Operator_Type_Overload_Unknown =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Operator_Overload_Unknown,
                  Overload_Ambiguity_Warning,
                  "primitive operator overload is unknown",
                  "Visible primitive operator metadata is insufficient for final overload selection."));
            when others =>
               null;
         end case;
      end;

      declare
         Id : constant Overload_Ambiguity_Diagnostic_Id :=
           Overload_Ambiguity_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      begin
         case Info.Universal_Numeric_Status is
            when Editor.Ada_Expression_Types.Universal_Numeric_Expected_Mismatch =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Universal_Numeric_Mismatch,
                  Overload_Ambiguity_Error,
                  "universal numeric value does not match expected subtype",
                  "The universal numeric expression cannot be resolved to the expected numeric family."));
            when Editor.Ada_Expression_Types.Universal_Numeric_Range_Error =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Universal_Numeric_Range_Error,
                  Overload_Ambiguity_Error,
                  "universal numeric value is outside the expected range",
                  "Static range metadata rejects this universal numeric conversion."));
            when Editor.Ada_Expression_Types.Universal_Numeric_Static_Unknown =>
               Append (Model, Make_Diagnostic
                 (Info, Id, Overload_Ambiguity_Universal_Numeric_Unknown,
                  Overload_Ambiguity_Warning,
                  "universal numeric value is not statically known",
                  "Expected numeric context exists, but static value resolution is incomplete."));
            when others =>
               null;
         end case;
      end;
   end Append_For_Expression;

   procedure Clear (Model : in out Overload_Ambiguity_Model) is
   begin
      Model.Diagnostics.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Call_Total := 0;
      Model.Operator_Total := 0;
      Model.Universal_Total := 0;
      Model.Candidate_Rejection_Total := 0;
      Model.Ambiguous_Total := 0;
      Model.Mismatch_Total := 0;
      Model.Unknown_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Overload_Ambiguity_Model is
      Model : Overload_Ambiguity_Model;
   begin
      Model.Result_Fingerprint := Editor.Ada_Expression_Types.Fingerprint (Expressions);
      for Index in 1 .. Editor.Ada_Expression_Types.Expression_Type_Count (Expressions) loop
         Append_For_Expression
           (Model, Editor.Ada_Expression_Types.Expression_Type_At (Expressions, Index));
      end loop;
      return Model;
   end Build;

   function Diagnostic_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Natural (Model.Diagnostics.Length);
   end Diagnostic_Count;

   function Diagnostic_At
     (Model : Overload_Ambiguity_Model;
      Index : Positive) return Overload_Ambiguity_Diagnostic is
   begin
      if Index > Natural (Model.Diagnostics.Length) then
         return (others => <>);
      end if;
      return Model.Diagnostics.Element (Index);
   end Diagnostic_At;

   function Error_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Call_Cause_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Call_Total;
   end Call_Cause_Count;

   function Operator_Cause_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Operator_Total;
   end Operator_Cause_Count;

   function Universal_Numeric_Cause_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Universal_Total;
   end Universal_Numeric_Cause_Count;

   function Candidate_Rejection_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Candidate_Rejection_Total;
   end Candidate_Rejection_Count;

   function Ambiguous_Cause_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Cause_Count;

   function Mismatch_Cause_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Mismatch_Total;
   end Mismatch_Cause_Count;

   function Unknown_Cause_Count (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Cause_Count;

   function Count_Kind
     (Model : Overload_Ambiguity_Model;
      Kind  : Overload_Ambiguity_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Diagnostic of Model.Diagnostics loop
         if Diagnostic.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function First_For_Node
     (Model : Overload_Ambiguity_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Ambiguity_Diagnostic is
   begin
      for Diagnostic of Model.Diagnostics loop
         if Diagnostic.Node = Node then
            return Diagnostic;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Diagnostics_For_Node
     (Model : Overload_Ambiguity_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Ambiguity_Result_Set is
      Results : Overload_Ambiguity_Result_Set;
   begin
      for Diagnostic of Model.Diagnostics loop
         if Diagnostic.Node = Node then
            Results.Diagnostics.Append (Diagnostic);
            Results.Fingerprint := Mix (Results.Fingerprint, Diagnostic.Fingerprint);
         end if;
      end loop;
      return Results;
   end Diagnostics_For_Node;

   function Result_Count (Results : Overload_Ambiguity_Result_Set) return Natural is
   begin
      return Natural (Results.Diagnostics.Length);
   end Result_Count;

   function Result_At
     (Results : Overload_Ambiguity_Result_Set;
      Index   : Positive) return Overload_Ambiguity_Diagnostic is
   begin
      if Index > Natural (Results.Diagnostics.Length) then
         return (others => <>);
      end if;
      return Results.Diagnostics.Element (Index);
   end Result_At;

   function Has_Diagnostic (Diagnostic : Overload_Ambiguity_Diagnostic) return Boolean is
   begin
      return Diagnostic.Id /= No_Overload_Ambiguity_Diagnostic
        and then Diagnostic.Kind /= Overload_Ambiguity_No_Kind;
   end Has_Diagnostic;

   function Fingerprint (Model : Overload_Ambiguity_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Overload_Ambiguity_Diagnostics;
