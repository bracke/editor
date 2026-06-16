with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Ranking is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Expression_Types.Expression_Type_Id;
   use type Editor.Ada_Expression_Types.Call_Actual_Type_Resolution_Status;
   use type Editor.Ada_Expression_Types.Operator_Type_Inference_Status;
   use type Editor.Ada_Expression_Types.Universal_Numeric_Resolution_Status;
   use type Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 257) + (B * 19) + 313) mod 1_000_000_007;
   end Mix;

   function Status_Slot (Status : Overload_Ranking_Status) return Natural is
   begin
      return Overload_Ranking_Status'Pos (Status) + 1;
   end Status_Slot;

   function Source_Cause_For
     (Causes : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model;
      Node   : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic is
   begin
      return Editor.Ada_Overload_Ambiguity_Diagnostics.First_For_Node (Causes, Node);
   end Source_Cause_For;

   function Ranking_Fingerprint (Info : Overload_Ranking_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Expression) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Natural (Info.Source_Cause) + 1);
      H := Mix (H, Info.Candidate_Count + 1);
      H := Mix (H, Info.Exact_Match_Count + 1);
      H := Mix (H, Info.Implicit_Conversion_Count + 1);
      H := Mix (H, Info.Universal_Numeric_Count + 1);
      H := Mix (H, Info.Rejected_Count + 1);
      H := Mix (H, Info.Unknown_Count + 1);
      H := Mix (H, Info.Selected_Count + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      H := Mix (H, Info.Cause_Fingerprint + 1);
      H := Mix (H, Length (Info.Message) + Length (Info.Detail) + 1);
      return H;
   end Ranking_Fingerprint;

   function Message_For (Status : Overload_Ranking_Status) return String is
   begin
      case Status is
         when Overload_Ranking_Exact_Match =>
            return "overload ranking selected an exact match";
         when Overload_Ranking_Implicit_Conversion =>
            return "overload ranking selected through implicit conversion evidence";
         when Overload_Ranking_Universal_Numeric_Tie_Break =>
            return "universal numeric context breaks overload ranking tie";
         when Overload_Ranking_Ambiguous_After_Ranking =>
            return "overload ranking remains ambiguous";
         when Overload_Ranking_No_Ranked_Candidate =>
            return "overload ranking found no viable candidate";
         when Overload_Ranking_Unknown =>
            return "overload ranking is unknown";
         when others =>
            return "overload ranking metadata was not applicable";
      end case;
   end Message_For;

   function Classify (Info : Editor.Ada_Expression_Types.Expression_Type_Info)
      return Overload_Ranking_Status
   is
   begin
      case Info.Call_Actual_Type_Status is
         when Editor.Ada_Expression_Types.Call_Actual_Type_All_Compatible =>
            if Info.Call_Actual_Type_Mismatch_Count = 0
              and then Info.Call_Actual_Type_Unknown_Count = 0
            then
               return Overload_Ranking_Exact_Match;
            end if;
            return Overload_Ranking_Implicit_Conversion;
         when Editor.Ada_Expression_Types.Call_Actual_Type_Ambiguous_Call =>
            return Overload_Ranking_Ambiguous_After_Ranking;
         when Editor.Ada_Expression_Types.Call_Actual_Type_Actual_Mismatch =>
            return Overload_Ranking_No_Ranked_Candidate;
         when Editor.Ada_Expression_Types.Call_Actual_Type_Unresolved_Call |
              Editor.Ada_Expression_Types.Call_Actual_Type_Profile_Unavailable |
              Editor.Ada_Expression_Types.Call_Actual_Type_Actual_Unknown =>
            return Overload_Ranking_Unknown;
         when others =>
            null;
      end case;

      case Info.Operator_Status is
         when Editor.Ada_Expression_Types.Operator_Type_Resolved_Predefined |
              Editor.Ada_Expression_Types.Operator_Type_Resolved_Visible |
              Editor.Ada_Expression_Types.Operator_Type_Overload_Resolved =>
            if Info.Operator_Overload_Mismatch_Count > 0
              or else Info.Operator_Mismatched_Operand_Count > 0
            then
               return Overload_Ranking_Implicit_Conversion;
            end if;
            return Overload_Ranking_Exact_Match;
         when Editor.Ada_Expression_Types.Operator_Type_Ambiguous |
              Editor.Ada_Expression_Types.Operator_Type_Overload_Ambiguous =>
            return Overload_Ranking_Ambiguous_After_Ranking;
         when Editor.Ada_Expression_Types.Operator_Type_Operand_Mismatch |
              Editor.Ada_Expression_Types.Operator_Type_Overload_Mismatch =>
            return Overload_Ranking_No_Ranked_Candidate;
         when Editor.Ada_Expression_Types.Operator_Type_Operand_Unknown |
              Editor.Ada_Expression_Types.Operator_Type_Result_Unknown |
              Editor.Ada_Expression_Types.Operator_Type_Overload_Unknown =>
            return Overload_Ranking_Unknown;
         when others =>
            null;
      end case;

      case Info.Universal_Numeric_Status is
         when Editor.Ada_Expression_Types.Universal_Numeric_Integer_Resolved |
              Editor.Ada_Expression_Types.Universal_Numeric_Real_Resolved |
              Editor.Ada_Expression_Types.Universal_Numeric_Modular_Resolved |
              Editor.Ada_Expression_Types.Universal_Numeric_Fixed_Resolved |
              Editor.Ada_Expression_Types.Universal_Numeric_Range_Compatible =>
            if Length (Info.Universal_Numeric_Expected_Subtype) > 0 then
               return Overload_Ranking_Universal_Numeric_Tie_Break;
            end if;
            return Overload_Ranking_Exact_Match;
         when Editor.Ada_Expression_Types.Universal_Numeric_Expected_Mismatch |
              Editor.Ada_Expression_Types.Universal_Numeric_Range_Error =>
            return Overload_Ranking_No_Ranked_Candidate;
         when Editor.Ada_Expression_Types.Universal_Numeric_Static_Unknown =>
            return Overload_Ranking_Unknown;
         when others =>
            null;
      end case;

      return Overload_Ranking_Not_Overload;
   end Classify;

   function Make_Ranking
     (Info   : Editor.Ada_Expression_Types.Expression_Type_Info;
      Cause  : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic;
      Id     : Overload_Ranking_Id;
      Status : Overload_Ranking_Status) return Overload_Ranking_Info
   is
      Result : Overload_Ranking_Info;
   begin
      Result.Id := Id;
      Result.Expression := Info.Id;
      Result.Node := Info.Node;
      if Editor.Ada_Overload_Ambiguity_Diagnostics.Has_Diagnostic (Cause) then
         Result.Source_Cause := Cause.Id;
         Result.Cause_Fingerprint := Cause.Fingerprint;
      end if;
      Result.Status := Status;
      Result.Message := To_Unbounded_String (Message_For (Status));
      Result.Start_Line := Info.Start_Line;
      Result.Start_Column := 1;
      Result.End_Line := Info.End_Line;
      Result.End_Column := 1;
      Result.Source_Fingerprint := Info.Fingerprint;

      Result.Candidate_Count := Info.Call_Actual_Type_Candidate_Count +
        Info.Operator_Overload_Candidate_Count + Natural (Boolean'Pos
          (Length (Info.Universal_Numeric_Expected_Subtype) > 0));
      Result.Selected_Count := Info.Operator_Overload_Selected_Count +
        Natural (Boolean'Pos (Length (Info.Universal_Numeric_Result_Subtype) > 0));
      Result.Exact_Match_Count := Info.Call_Actual_Type_Compatible_Count +
        Info.Operator_Compatible_Operand_Count;
      Result.Implicit_Conversion_Count := Info.Operator_Overload_Mismatch_Count +
        Natural (Boolean'Pos (Status = Overload_Ranking_Implicit_Conversion));
      Result.Universal_Numeric_Count := Natural (Boolean'Pos
        (Status = Overload_Ranking_Universal_Numeric_Tie_Break));
      Result.Rejected_Count := Info.Call_Actual_Type_Mismatch_Count +
        Info.Operator_Mismatched_Operand_Count + Info.Operator_Overload_Mismatch_Count;
      Result.Unknown_Count := Info.Call_Actual_Type_Unknown_Count +
        Info.Operator_Unknown_Operand_Count;
      Result.Detail := To_Unbounded_String
        ("candidates=" & Natural'Image (Result.Candidate_Count) &
         " exact=" & Natural'Image (Result.Exact_Match_Count) &
         " implicit=" & Natural'Image (Result.Implicit_Conversion_Count) &
         " universal=" & Natural'Image (Result.Universal_Numeric_Count) &
         " rejected=" & Natural'Image (Result.Rejected_Count) &
         " unknown=" & Natural'Image (Result.Unknown_Count));
      Result.Fingerprint := Ranking_Fingerprint (Result);
      return Result;
   end Make_Ranking;

   procedure Append (Model : in out Overload_Ranking_Model; Info : Overload_Ranking_Info) is
   begin
      if not Has_Ranking (Info) then
         return;
      end if;
      Model.Rankings.Append (Info);
      case Info.Status is
         when Overload_Ranking_Exact_Match =>
            Model.Exact_Total := Model.Exact_Total + 1;
         when Overload_Ranking_Implicit_Conversion =>
            Model.Implicit_Total := Model.Implicit_Total + 1;
         when Overload_Ranking_Universal_Numeric_Tie_Break =>
            Model.Universal_Total := Model.Universal_Total + 1;
         when Overload_Ranking_Ambiguous_After_Ranking =>
            Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
         when Overload_Ranking_No_Ranked_Candidate =>
            Model.No_Candidate_Total := Model.No_Candidate_Total + 1;
         when Overload_Ranking_Unknown =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
         when others =>
            null;
      end case;
      Model.Rejection_Total := Model.Rejection_Total + Info.Rejected_Count + Info.Unknown_Count;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
   end Append;

   procedure Clear (Model : in out Overload_Ranking_Model) is
   begin
      Model.Rankings.Clear;
      Model.Exact_Total := 0;
      Model.Implicit_Total := 0;
      Model.Universal_Total := 0;
      Model.Ambiguous_Total := 0;
      Model.No_Candidate_Total := 0;
      Model.Unknown_Total := 0;
      Model.Rejection_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Causes      : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Model)
      return Overload_Ranking_Model
   is
      Model : Overload_Ranking_Model;
      Info  : Editor.Ada_Expression_Types.Expression_Type_Info;
      Status : Overload_Ranking_Status;
      Cause : Editor.Ada_Overload_Ambiguity_Diagnostics.Overload_Ambiguity_Diagnostic;
   begin
      Model.Result_Fingerprint := Mix
        (Editor.Ada_Expression_Types.Fingerprint (Expressions),
         Editor.Ada_Overload_Ambiguity_Diagnostics.Fingerprint (Causes));
      for I in 1 .. Editor.Ada_Expression_Types.Expression_Type_Count (Expressions) loop
         Info := Editor.Ada_Expression_Types.Expression_Type_At (Expressions, I);
         Status := Classify (Info);
         if Status /= Overload_Ranking_Not_Overload then
            Cause := Source_Cause_For (Causes, Info.Node);
            Append (Model, Make_Ranking
              (Info, Cause,
               Overload_Ranking_Id (Natural (Model.Rankings.Length) + 1),
               Status));
         end if;
      end loop;
      return Model;
   end Build;

   function Ranking_Count (Model : Overload_Ranking_Model) return Natural is
   begin
      return Natural (Model.Rankings.Length);
   end Ranking_Count;

   function Ranking_At
     (Model : Overload_Ranking_Model;
      Index : Positive) return Overload_Ranking_Info is
   begin
      if Index > Natural (Model.Rankings.Length) then
         return (others => <>);
      end if;
      return Model.Rankings.Element (Index);
   end Ranking_At;

   function Count_Status
     (Model  : Overload_Ranking_Model;
      Status : Overload_Ranking_Status) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Rankings loop
         if Item.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Exact_Match_Count (Model : Overload_Ranking_Model) return Natural is
   begin
      return Model.Exact_Total;
   end Exact_Match_Count;

   function Implicit_Conversion_Count (Model : Overload_Ranking_Model) return Natural is
   begin
      return Model.Implicit_Total;
   end Implicit_Conversion_Count;

   function Universal_Numeric_Tie_Break_Count (Model : Overload_Ranking_Model) return Natural is
   begin
      return Model.Universal_Total;
   end Universal_Numeric_Tie_Break_Count;

   function Ambiguous_After_Ranking_Count (Model : Overload_Ranking_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_After_Ranking_Count;

   function No_Ranked_Candidate_Count (Model : Overload_Ranking_Model) return Natural is
   begin
      return Model.No_Candidate_Total;
   end No_Ranked_Candidate_Count;

   function Unknown_Ranking_Count (Model : Overload_Ranking_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Ranking_Count;

   function Candidate_Rejection_Count (Model : Overload_Ranking_Model) return Natural is
   begin
      return Model.Rejection_Total;
   end Candidate_Rejection_Count;

   function First_For_Node
     (Model : Overload_Ranking_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Ranking_Info is
   begin
      for Item of Model.Rankings loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rankings_For_Node
     (Model : Overload_Ranking_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Overload_Ranking_Result_Set is
      Results : Overload_Ranking_Result_Set;
   begin
      for Item of Model.Rankings loop
         if Item.Node = Node then
            Results.Rankings.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Rankings_For_Node;

   function Result_Count (Results : Overload_Ranking_Result_Set) return Natural is
   begin
      return Natural (Results.Rankings.Length);
   end Result_Count;

   function Result_At
     (Results : Overload_Ranking_Result_Set;
      Index   : Positive) return Overload_Ranking_Info is
   begin
      if Index > Natural (Results.Rankings.Length) then
         return (others => <>);
      end if;
      return Results.Rankings.Element (Index);
   end Result_At;

   function Has_Ranking (Info : Overload_Ranking_Info) return Boolean is
   begin
      return Info.Id /= No_Overload_Ranking
        and then Info.Status not in Overload_Ranking_Not_Checked | Overload_Ranking_Not_Overload;
   end Has_Ranking;

   function Fingerprint (Model : Overload_Ranking_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Overload_Ranking;
