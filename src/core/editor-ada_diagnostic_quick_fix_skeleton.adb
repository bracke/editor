with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Overload_Ranking_Provenance;

package body Editor.Ada_Diagnostic_Quick_Fix_Skeleton is

   pragma Suppress (Overflow_Check);

   use type Feed_Source;
   use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 197) + B + 151) mod 1_000_000_007;
   end Mix;

   function Source_Slot (Source : Feed_Source) return Natural is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return 2;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return 3;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return 4;
      end case;
   end Source_Slot;

   function Action_Slot (Action : Diagnostic_Quick_Fix_Action_Kind) return Natural is
   begin
      case Action is
         when Diagnostic_Quick_Fix_No_Action =>
            return 0;
         when Diagnostic_Quick_Fix_Navigate_To_Diagnostic =>
            return 1;
         when Diagnostic_Quick_Fix_Show_Explanation =>
            return 2;
         when Diagnostic_Quick_Fix_Review_Expression_Type =>
            return 3;
         when Diagnostic_Quick_Fix_Review_Overload_Ranking =>
            return 4;
         when Diagnostic_Quick_Fix_Review_Generic_Actual =>
            return 5;
         when Diagnostic_Quick_Fix_Review_Cross_Unit_Dependency =>
            return 6;
         when Diagnostic_Quick_Fix_Review_Representation_Item =>
            return 7;
      end case;
   end Action_Slot;

   function Severity_Slot (Severity : Feed_Severity) return Natural is
   begin
      case Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            return 3;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            return 2;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            return 1;
      end case;
   end Severity_Slot;

   function Source_Action (Source : Feed_Source) return Diagnostic_Quick_Fix_Action_Kind is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return Diagnostic_Quick_Fix_Review_Expression_Type;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return Diagnostic_Quick_Fix_Review_Generic_Actual;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return Diagnostic_Quick_Fix_Review_Cross_Unit_Dependency;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return Diagnostic_Quick_Fix_Review_Representation_Item;
      end case;
   end Source_Action;

   function Source_Label (Source : Feed_Source) return String is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return "Review expression typing";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return "Review generic actual contract";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return "Review cross-unit dependency";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return "Review representation item";
      end case;
   end Source_Label;

   function Ranking_Outcome_Detail
     (Outcome : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Outcome)
      return String
   is
   begin
      case Outcome is
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Exact =>
            return "Inspect the exact overload-ranking decision for this diagnostic; no edit is applied.";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Implicit_Conversion =>
            return "Inspect the implicit-conversion overload-ranking decision for this diagnostic; no edit is applied.";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Universal_Numeric =>
            return "Inspect the universal-numeric overload tie-break for this diagnostic; no edit is applied.";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Ambiguous =>
            return "Inspect the overload candidates that remained ambiguous after ranking; no edit is applied.";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_No_Candidate =>
            return "Inspect why no overload candidate survived ranking; no edit is applied.";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Unknown =>
            return "Inspect the unknown overload-ranking state for this diagnostic; no edit is applied.";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Not_Overload =>
            return "Inspect why this diagnostic has no overload-ranking evidence; no edit is applied.";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Unlinked =>
            return "Inspect unlinked overload-ranking provenance for this diagnostic; no edit is applied.";
      end case;
   end Ranking_Outcome_Detail;

   function Source_Detail (Source : Feed_Source) return String is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return "Projection-only action skeleton for the expression diagnostic source; no edit is applied.";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return "Projection-only action skeleton for the generic-contract diagnostic source; no edit is applied.";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return "Projection-only action skeleton for the cross-unit diagnostic source; no edit is applied.";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return "Projection-only action skeleton for the representation/freezing diagnostic source; no edit is applied.";
      end case;
   end Source_Detail;

   function Make_Candidate
     (Item       : Index_Entry;
      Candidate  : Diagnostic_Quick_Fix_Candidate_Id;
      Action     : Diagnostic_Quick_Fix_Action_Kind;
      Label      : String;
      Detail     : String;
      Confidence : Diagnostic_Quick_Fix_Confidence) return Diagnostic_Quick_Fix_Candidate
   is
      Result : Diagnostic_Quick_Fix_Candidate;
   begin
      Result.Id := Candidate;
      Result.Index_Id := Item.Id;
      Result.Feed_Index := Item.Feed_Index;
      Result.Diagnostic := Item.Diagnostic;
      Result.Action := Action;
      Result.Confidence := Confidence;
      Result.Severity := Item.Diagnostic.Severity;
      Result.Source := Item.Diagnostic.Source;
      Result.Token := Item.Diagnostic.Token;
      Result.Node := Item.Diagnostic.Node;
      Result.Label := To_Unbounded_String (Label);
      Result.Detail := To_Unbounded_String (Detail);
      Result.Has_Edit := False;
      Result.Start_Line := Item.Diagnostic.Start_Line;
      Result.Start_Column := Item.Diagnostic.Start_Column;
      Result.End_Line := Item.Diagnostic.End_Line;
      Result.End_Column := Item.Diagnostic.End_Column;
      Result.Fingerprint := Mix
        (Natural (Result.Id) + 1,
         Mix
           (Natural (Result.Index_Id) + 1,
            Mix
              (Result.Feed_Index + 1,
               Mix
                 (Item.Diagnostic.Fingerprint + 1,
                  Mix (Action_Slot (Action),
                       Mix (Severity_Slot (Result.Severity),
                            Result.Ranking_Fingerprint + 1))))));
      return Result;
   end Make_Candidate;

   procedure Append_Candidate
     (Model     : in out Diagnostic_Quick_Fix_Model;
      Candidate : Diagnostic_Quick_Fix_Candidate) is
   begin
      if Candidate.Id = No_Diagnostic_Quick_Fix_Candidate then
         return;
      end if;

      Model.Candidates.Append (Candidate);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Candidate.Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Source_Slot (Candidate.Source));

      case Candidate.Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      if Candidate.Has_Edit then
         Model.Editable_Total := Model.Editable_Total + 1;
      end if;

      case Candidate.Action is
         when Diagnostic_Quick_Fix_Navigate_To_Diagnostic =>
            Model.Navigate_Total := Model.Navigate_Total + 1;
         when Diagnostic_Quick_Fix_Show_Explanation =>
            Model.Explanation_Total := Model.Explanation_Total + 1;
         when Diagnostic_Quick_Fix_Review_Expression_Type =>
            Model.Expression_Total := Model.Expression_Total + 1;
         when Diagnostic_Quick_Fix_Review_Overload_Ranking =>
            Model.Overload_Ranking_Total := Model.Overload_Ranking_Total + 1;
         when Diagnostic_Quick_Fix_Review_Generic_Actual =>
            Model.Generic_Total := Model.Generic_Total + 1;
         when Diagnostic_Quick_Fix_Review_Cross_Unit_Dependency =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Diagnostic_Quick_Fix_Review_Representation_Item =>
            Model.Representation_Total := Model.Representation_Total + 1;
         when Diagnostic_Quick_Fix_No_Action =>
            null;
      end case;
   end Append_Candidate;


   function Matching_Ranking_Provenance
     (Item : Index_Entry;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model)
      return Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Item
   is
      use type Editor.Ada_Syntax_Tree.Node_Id;
   begin
      for Position in
        1 .. Editor.Ada_Overload_Ranking_Provenance.Item_Count (Ranking_Provenance)
      loop
         declare
            Ranking_Item : constant
              Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Item :=
                Editor.Ada_Overload_Ranking_Provenance.Item_At
                  (Ranking_Provenance, Position);
         begin
            if Ranking_Item.Node = Item.Diagnostic.Node
              and then Ranking_Item.Start_Line = Item.Diagnostic.Start_Line
              and then Ranking_Item.Start_Column = Item.Diagnostic.Start_Column
              and then Ranking_Item.End_Line = Item.Diagnostic.End_Line
              and then Ranking_Item.End_Column = Item.Diagnostic.End_Column
            then
               return Ranking_Item;
            end if;
         end;
      end loop;

      return (others => <>);
   end Matching_Ranking_Provenance;

   function Make_Ranking_Candidate
     (Item       : Index_Entry;
      Candidate  : Diagnostic_Quick_Fix_Candidate_Id;
      Ranking_Item :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Item)
      return Diagnostic_Quick_Fix_Candidate
   is
      Result : Diagnostic_Quick_Fix_Candidate :=
        Make_Candidate
          (Item,
           Candidate,
           Diagnostic_Quick_Fix_Review_Overload_Ranking,
           "Explain overload ranking",
           Ranking_Outcome_Detail (Ranking_Item.Outcome),
           Diagnostic_Quick_Fix_Medium_Confidence);
   begin
      Result.Ranking_Provenance := Ranking_Item.Id;
      Result.Ranking_Outcome := Ranking_Item.Outcome;
      Result.Ranking_Candidate_Count := Ranking_Item.Candidate_Count;
      Result.Ranking_Selected_Count := Ranking_Item.Selected_Count;
      Result.Ranking_Rejected_Count := Ranking_Item.Rejected_Count;
      Result.Ranking_Unknown_Count := Ranking_Item.Unknown_Count;
      Result.Ranking_Fingerprint := Ranking_Item.Fingerprint;
      Result.Fingerprint := Mix (Result.Fingerprint, Ranking_Item.Fingerprint + 1);
      return Result;
   end Make_Ranking_Candidate;

   procedure Clear (Model : in out Diagnostic_Quick_Fix_Model) is
   begin
      Model.Model_Status := Diagnostic_Quick_Fix_Current;
      Model.Candidates.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Rejected_Total := 0;
      Model.Editable_Total := 0;
      Model.Navigate_Total := 0;
      Model.Explanation_Total := 0;
      Model.Expression_Total := 0;
      Model.Overload_Ranking_Total := 0;
      Model.Generic_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Representation_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model)
      return Diagnostic_Quick_Fix_Model
   is
      Model : Diagnostic_Quick_Fix_Model;
      Next_Id : Diagnostic_Quick_Fix_Candidate_Id := 1;
   begin
      if Editor.Ada_Semantic_Diagnostic_Index.Rejected_Stale (Index) then
         Model.Model_Status := Diagnostic_Quick_Fix_Rejected_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Index);
         Model.Result_Fingerprint := Mix
           (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index),
            Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Result_Fingerprint := Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index);

      for Position in 1 .. Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index) loop
         declare
            Item : constant Index_Entry :=
              Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, Position);
         begin
            Append_Candidate
              (Model,
               Make_Candidate
                 (Item,
                  Next_Id,
                  Diagnostic_Quick_Fix_Navigate_To_Diagnostic,
                  "Go to diagnostic",
                  "Projection-only navigation action skeleton for this diagnostic span.",
                  Diagnostic_Quick_Fix_High_Confidence));
            Next_Id := Next_Id + 1;

            Append_Candidate
              (Model,
               Make_Candidate
                 (Item,
                  Next_Id,
                  Diagnostic_Quick_Fix_Show_Explanation,
                  "Explain diagnostic",
                  "Projection-only explanation action skeleton preserving diagnostic provenance metadata.",
                  Diagnostic_Quick_Fix_Medium_Confidence));
            Next_Id := Next_Id + 1;

            Append_Candidate
              (Model,
               Make_Candidate
                 (Item,
                  Next_Id,
                  Source_Action (Item.Diagnostic.Source),
                  Source_Label (Item.Diagnostic.Source),
                  Source_Detail (Item.Diagnostic.Source),
                  Diagnostic_Quick_Fix_Low_Confidence));
            Next_Id := Next_Id + 1;
         end;
      end loop;

      return Model;
   end Build;

   function Build_With_Overload_Ranking
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model)
      return Diagnostic_Quick_Fix_Model
   is
      Model : Diagnostic_Quick_Fix_Model;
      Next_Id : Diagnostic_Quick_Fix_Candidate_Id := 1;
   begin
      if Editor.Ada_Semantic_Diagnostic_Index.Rejected_Stale (Index) then
         Model.Model_Status := Diagnostic_Quick_Fix_Rejected_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Index);
         Model.Result_Fingerprint := Mix
           (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index),
            Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Result_Fingerprint := Mix
        (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index),
         Editor.Ada_Overload_Ranking_Provenance.Fingerprint
           (Ranking_Provenance) + 1);

      for Position in 1 .. Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index) loop
         declare
            Item : constant Index_Entry :=
              Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, Position);
            Ranking_Item : constant
              Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Item :=
                Matching_Ranking_Provenance (Item, Ranking_Provenance);
         begin
            Append_Candidate
              (Model,
               Make_Candidate
                 (Item,
                  Next_Id,
                  Diagnostic_Quick_Fix_Navigate_To_Diagnostic,
                  "Go to diagnostic",
                  "Projection-only navigation action skeleton for this diagnostic span.",
                  Diagnostic_Quick_Fix_High_Confidence));
            Next_Id := Next_Id + 1;

            Append_Candidate
              (Model,
               Make_Candidate
                 (Item,
                  Next_Id,
                  Diagnostic_Quick_Fix_Show_Explanation,
                  "Explain diagnostic",
                  "Projection-only explanation action skeleton preserving diagnostic provenance metadata.",
                  Diagnostic_Quick_Fix_Medium_Confidence));
            Next_Id := Next_Id + 1;

            if Editor.Ada_Overload_Ranking_Provenance.Has_Item (Ranking_Item) then
               Append_Candidate
                 (Model,
                  Make_Ranking_Candidate (Item, Next_Id, Ranking_Item));
               Next_Id := Next_Id + 1;
            end if;

            Append_Candidate
              (Model,
               Make_Candidate
                 (Item,
                  Next_Id,
                  Source_Action (Item.Diagnostic.Source),
                  Source_Label (Item.Diagnostic.Source),
                  Source_Detail (Item.Diagnostic.Source),
                  Diagnostic_Quick_Fix_Low_Confidence));
            Next_Id := Next_Id + 1;
         end;
      end loop;

      return Model;
   end Build_With_Overload_Ranking;

   function Status (Model : Diagnostic_Quick_Fix_Model) return Diagnostic_Quick_Fix_Status is
   begin
      return Model.Model_Status;
   end Status;

   function Current (Model : Diagnostic_Quick_Fix_Model) return Boolean is
   begin
      return Model.Model_Status = Diagnostic_Quick_Fix_Current;
   end Current;

   function Rejected_Stale (Model : Diagnostic_Quick_Fix_Model) return Boolean is
   begin
      return Model.Model_Status = Diagnostic_Quick_Fix_Rejected_Stale;
   end Rejected_Stale;

   function Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural is
   begin
      return Natural (Model.Candidates.Length);
   end Candidate_Count;

   function Candidate_At
     (Model : Diagnostic_Quick_Fix_Model;
      Index : Positive) return Diagnostic_Quick_Fix_Candidate is
   begin
      if Index > Natural (Model.Candidates.Length) then
         return (others => <>);
      end if;

      return Model.Candidates.Element (Index);
   end Candidate_At;

   function Error_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Candidate_Count;

   function Warning_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Candidate_Count;

   function Info_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Candidate_Count;

   function Rejected_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Candidate_Count;

   function Editable_Candidate_Count (Model : Diagnostic_Quick_Fix_Model) return Natural is
   begin
      return Model.Editable_Total;
   end Editable_Candidate_Count;

   function Overload_Ranking_Candidate_Count
     (Model : Diagnostic_Quick_Fix_Model) return Natural is
   begin
      return Model.Overload_Ranking_Total;
   end Overload_Ranking_Candidate_Count;

   function Count_Action
     (Model  : Diagnostic_Quick_Fix_Model;
      Action : Diagnostic_Quick_Fix_Action_Kind) return Natural is
   begin
      case Action is
         when Diagnostic_Quick_Fix_Navigate_To_Diagnostic =>
            return Model.Navigate_Total;
         when Diagnostic_Quick_Fix_Show_Explanation =>
            return Model.Explanation_Total;
         when Diagnostic_Quick_Fix_Review_Expression_Type =>
            return Model.Expression_Total;
         when Diagnostic_Quick_Fix_Review_Overload_Ranking =>
            return Model.Overload_Ranking_Total;
         when Diagnostic_Quick_Fix_Review_Generic_Actual =>
            return Model.Generic_Total;
         when Diagnostic_Quick_Fix_Review_Cross_Unit_Dependency =>
            return Model.Cross_Unit_Total;
         when Diagnostic_Quick_Fix_Review_Representation_Item =>
            return Model.Representation_Total;
         when Diagnostic_Quick_Fix_No_Action =>
            return 0;
      end case;
   end Count_Action;

   function Count_Source
     (Model  : Diagnostic_Quick_Fix_Model;
      Source : Feed_Source) return Natural
   is
      Total : Natural := 0;
   begin
      for Position in 1 .. Natural (Model.Candidates.Length) loop
         if Model.Candidates.Element (Position).Source = Source then
            Total := Total + 1;
         end if;
      end loop;

      return Total;
   end Count_Source;

   function First_For_Diagnostic
     (Model    : Diagnostic_Quick_Fix_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Quick_Fix_Candidate is
   begin
      for Position in 1 .. Natural (Model.Candidates.Length) loop
         declare
            Candidate : constant Diagnostic_Quick_Fix_Candidate :=
              Model.Candidates.Element (Position);
         begin
            if Candidate.Index_Id = Index_Id then
               return Candidate;
            end if;
         end;
      end loop;

      return (others => <>);
   end First_For_Diagnostic;

   function Candidates_For_Diagnostic
     (Model    : Diagnostic_Quick_Fix_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Quick_Fix_Result_Set
   is
      Results : Diagnostic_Quick_Fix_Result_Set;
   begin
      for Position in 1 .. Natural (Model.Candidates.Length) loop
         declare
            Candidate : constant Diagnostic_Quick_Fix_Candidate :=
              Model.Candidates.Element (Position);
         begin
            if Candidate.Index_Id = Index_Id then
               Results.Candidates.Append (Candidate);
               Results.Fingerprint := Mix (Results.Fingerprint, Candidate.Fingerprint);
            end if;
         end;
      end loop;

      return Results;
   end Candidates_For_Diagnostic;

   function Result_Count (Results : Diagnostic_Quick_Fix_Result_Set) return Natural is
   begin
      return Natural (Results.Candidates.Length);
   end Result_Count;

   function Result_At
     (Results : Diagnostic_Quick_Fix_Result_Set;
      Index   : Positive) return Diagnostic_Quick_Fix_Candidate is
   begin
      if Index > Natural (Results.Candidates.Length) then
         return (others => <>);
      end if;

      return Results.Candidates.Element (Index);
   end Result_At;

   function Has_Candidate (Candidate : Diagnostic_Quick_Fix_Candidate) return Boolean is
   begin
      return Candidate.Id /= No_Diagnostic_Quick_Fix_Candidate;
   end Has_Candidate;

   function Fingerprint (Model : Diagnostic_Quick_Fix_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
