with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Overload_Ranking_Provenance is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Overload_Ranking.Overload_Ranking_Id;
   use type Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 263) + (B * 23) + 401) mod 1_000_000_007;
   end Mix;

   function Outcome_For (Status : Ranking_Status) return Overload_Ranking_Provenance_Outcome is
   begin
      case Status is
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Exact_Match =>
            return Overload_Ranking_Outcome_Exact;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Implicit_Conversion =>
            return Overload_Ranking_Outcome_Implicit_Conversion;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Universal_Numeric_Tie_Break =>
            return Overload_Ranking_Outcome_Universal_Numeric;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Ambiguous_After_Ranking =>
            return Overload_Ranking_Outcome_Ambiguous;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_No_Ranked_Candidate =>
            return Overload_Ranking_Outcome_No_Candidate;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Unknown =>
            return Overload_Ranking_Outcome_Unknown;
         when Editor.Ada_Overload_Ranking.Overload_Ranking_Not_Overload |
              Editor.Ada_Overload_Ranking.Overload_Ranking_Not_Checked =>
            return Overload_Ranking_Outcome_Not_Overload;
      end case;
   end Outcome_For;

   function Outcome_Slot (Outcome : Overload_Ranking_Provenance_Outcome) return Natural is
   begin
      return Overload_Ranking_Provenance_Outcome'Pos (Outcome) + 1;
   end Outcome_Slot;

   function Stage_Slot (Stage : Overload_Ranking_Provenance_Stage) return Natural is
   begin
      return Overload_Ranking_Provenance_Stage'Pos (Stage) + 1;
   end Stage_Slot;

   function Status_Slot (Status : Overload_Ranking_Provenance_Status) return Natural is
   begin
      return Overload_Ranking_Provenance_Status'Pos (Status) + 1;
   end Status_Slot;

   function Explanation_For
     (Outcome : Overload_Ranking_Provenance_Outcome;
      Linked_Diagnostic : Boolean) return String is
   begin
      case Outcome is
         when Overload_Ranking_Outcome_Exact =>
            return "ranking evidence selected an exact overload candidate";
         when Overload_Ranking_Outcome_Implicit_Conversion =>
            return "ranking evidence selected a candidate through implicit conversion metadata";
         when Overload_Ranking_Outcome_Universal_Numeric =>
            return "expected universal numeric context supplied the overload tie-break";
         when Overload_Ranking_Outcome_Ambiguous =>
            return "candidate evidence remained ambiguous after ranking";
         when Overload_Ranking_Outcome_No_Candidate =>
            return "candidate evidence left no ranked overload candidate";
         when Overload_Ranking_Outcome_Unknown =>
            return "ranking evidence was incomplete or unknown";
         when Overload_Ranking_Outcome_Not_Overload =>
            return "expression was not classified as an overload-ranking target";
         when Overload_Ranking_Outcome_Unlinked =>
            if Linked_Diagnostic then
               return "overload-ranking diagnostic did not have matching ranking metadata";
            end if;
            return "ranking metadata did not have a matching diagnostic projection";
      end case;
   end Explanation_For;

   function Make_Fingerprint (Item : Overload_Ranking_Provenance_Item) return Natural is
      H : Natural := Natural (Item.Id) + 1;
   begin
      H := Mix (H, Natural (Item.Ranking) + 1);
      H := Mix (H, Natural (Item.Expression_Diagnostic) + 1);
      H := Mix (H, Natural (Item.Node) + 1);
      H := Mix (H, Status_Slot (Item.Status));
      H := Mix (H, Outcome_Slot (Item.Outcome));
      H := Mix (H, Stage_Slot (Item.Stage));
      H := Mix (H, Item.Candidate_Count + 1);
      H := Mix (H, Item.Exact_Match_Count + 1);
      H := Mix (H, Item.Implicit_Conversion_Count + 1);
      H := Mix (H, Item.Universal_Numeric_Count + 1);
      H := Mix (H, Item.Rejected_Count + 1);
      H := Mix (H, Item.Unknown_Count + 1);
      H := Mix (H, Item.Selected_Count + 1);
      H := Mix (H, Item.Start_Line);
      H := Mix (H, Item.Start_Column);
      H := Mix (H, Item.End_Line);
      H := Mix (H, Item.End_Column);
      H := Mix (H, Item.Ranking_Fingerprint + 1);
      H := Mix (H, Item.Diagnostic_Fingerprint + 1);
      H := Mix (H, Length (Item.Message) + Length (Item.Detail) + Length (Item.Explanation) + 1);
      return H;
   end Make_Fingerprint;

   function From_Ranking
     (Ranking : Ranking_Info;
      Id      : Overload_Ranking_Provenance_Id) return Overload_Ranking_Provenance_Item
   is
      Item : Overload_Ranking_Provenance_Item;
   begin
      Item.Id := Id;
      Item.Status := Overload_Ranking_Provenance_Unlinked_Ranking;
      Item.Outcome := Outcome_For (Ranking.Status);
      Item.Stage := Overload_Ranking_Stage_Ranking_Decision;
      Item.Ranking := Ranking.Id;
      Item.Ranking_Status := Ranking.Status;
      Item.Node := Ranking.Node;
      Item.Message := Ranking.Message;
      Item.Detail := Ranking.Detail;
      Item.Explanation := To_Unbounded_String (Explanation_For (Item.Outcome, False));
      Item.Candidate_Count := Ranking.Candidate_Count;
      Item.Exact_Match_Count := Ranking.Exact_Match_Count;
      Item.Implicit_Conversion_Count := Ranking.Implicit_Conversion_Count;
      Item.Universal_Numeric_Count := Ranking.Universal_Numeric_Count;
      Item.Rejected_Count := Ranking.Rejected_Count;
      Item.Unknown_Count := Ranking.Unknown_Count;
      Item.Selected_Count := Ranking.Selected_Count;
      Item.Start_Line := Ranking.Start_Line;
      Item.Start_Column := Ranking.Start_Column;
      Item.End_Line := Ranking.End_Line;
      Item.End_Column := Ranking.End_Column;
      Item.Ranking_Fingerprint := Ranking.Fingerprint;
      Item.Fingerprint := Make_Fingerprint (Item);
      return Item;
   end From_Ranking;

   function From_Diagnostic
     (Diagnostic : Expression_Diagnostic;
      Ranking    : Ranking_Info;
      Id         : Overload_Ranking_Provenance_Id) return Overload_Ranking_Provenance_Item
   is
      Item : Overload_Ranking_Provenance_Item;
      Linked : constant Boolean :=
        Editor.Ada_Overload_Ranking.Has_Ranking (Ranking)
        and then Ranking.Id = Diagnostic.Overload_Ranking;
   begin
      Item.Id := Id;
      if Linked then
         Item.Status := Overload_Ranking_Provenance_Current;
         Item.Outcome := Outcome_For (Ranking.Status);
         Item.Stage := Overload_Ranking_Stage_Diagnostic_Projection;
         Item.Ranking := Ranking.Id;
         Item.Ranking_Status := Ranking.Status;
         Item.Ranking_Fingerprint := Ranking.Fingerprint;
         Item.Candidate_Count := Ranking.Candidate_Count;
         Item.Exact_Match_Count := Ranking.Exact_Match_Count;
         Item.Implicit_Conversion_Count := Ranking.Implicit_Conversion_Count;
         Item.Universal_Numeric_Count := Ranking.Universal_Numeric_Count;
         Item.Rejected_Count := Ranking.Rejected_Count;
         Item.Unknown_Count := Ranking.Unknown_Count;
         Item.Selected_Count := Ranking.Selected_Count;
      else
         Item.Status := Overload_Ranking_Provenance_Unlinked_Diagnostic;
         Item.Outcome := Overload_Ranking_Outcome_Unlinked;
         Item.Stage := Overload_Ranking_Stage_Diagnostic_Projection;
         Item.Ranking := Diagnostic.Overload_Ranking;
         Item.Ranking_Status := Diagnostic.Overload_Ranking_Status;
         Item.Candidate_Count := Diagnostic.Candidate_Count;
         Item.Rejected_Count := Diagnostic.Mismatch_Count;
         Item.Unknown_Count := Diagnostic.Unknown_Count;
         Item.Selected_Count := Diagnostic.Selected_Count;
      end if;

      Item.Expression_Diagnostic := Diagnostic.Id;
      Item.Node := Diagnostic.Node;
      Item.Severity := Diagnostic.Severity;
      Item.Message := Diagnostic.Message;
      Item.Detail := Diagnostic.Detail;
      Item.Explanation := To_Unbounded_String (Explanation_For (Item.Outcome, True));
      Item.Start_Line := Diagnostic.Start_Line;
      Item.Start_Column := Diagnostic.Start_Column;
      Item.End_Line := Diagnostic.End_Line;
      Item.End_Column := Diagnostic.End_Column;
      Item.Diagnostic_Fingerprint := Diagnostic.Fingerprint;
      Item.Fingerprint := Make_Fingerprint (Item);
      return Item;
   end From_Diagnostic;

   function Find_Ranking
     (Rankings : Editor.Ada_Overload_Ranking.Overload_Ranking_Model;
      Id       : Editor.Ada_Overload_Ranking.Overload_Ranking_Id) return Ranking_Info
   is
      Candidate : Ranking_Info;
   begin
      if Id = Editor.Ada_Overload_Ranking.No_Overload_Ranking then
         return Candidate;
      end if;

      for Index in 1 .. Editor.Ada_Overload_Ranking.Ranking_Count (Rankings) loop
         Candidate := Editor.Ada_Overload_Ranking.Ranking_At (Rankings, Index);
         if Candidate.Id = Id then
            return Candidate;
         end if;
      end loop;

      return Candidate;
   end Find_Ranking;

   function Has_Diagnostic_For_Ranking
     (Diagnostics : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Ranking     : Editor.Ada_Overload_Ranking.Overload_Ranking_Id) return Boolean is
      Diagnostic : Expression_Diagnostic;
   begin
      if Ranking = Editor.Ada_Overload_Ranking.No_Overload_Ranking then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Expression_Diagnostics.Diagnostic_Count (Diagnostics) loop
         Diagnostic := Editor.Ada_Expression_Diagnostics.Diagnostic_At (Diagnostics, Index);
         if Diagnostic.From_Overload_Ranking
           and then Diagnostic.Overload_Ranking = Ranking
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Diagnostic_For_Ranking;

   procedure Append (Model : in out Overload_Ranking_Provenance_Model; Item : Overload_Ranking_Provenance_Item) is
   begin
      if not Has_Item (Item) then
         return;
      end if;

      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);

      case Item.Outcome is
         when Overload_Ranking_Outcome_Exact =>
            Model.Exact_Total := Model.Exact_Total + 1;
         when Overload_Ranking_Outcome_Implicit_Conversion =>
            Model.Implicit_Total := Model.Implicit_Total + 1;
         when Overload_Ranking_Outcome_Universal_Numeric =>
            Model.Universal_Total := Model.Universal_Total + 1;
         when Overload_Ranking_Outcome_Ambiguous =>
            Model.Ambiguous_Total := Model.Ambiguous_Total + 1;
         when Overload_Ranking_Outcome_No_Candidate =>
            Model.Rejected_Total := Model.Rejected_Total + 1;
         when Overload_Ranking_Outcome_Unknown =>
            Model.Unknown_Total := Model.Unknown_Total + 1;
         when Overload_Ranking_Outcome_Not_Overload =>
            Model.Not_Overload_Total := Model.Not_Overload_Total + 1;
         when Overload_Ranking_Outcome_Unlinked =>
            null;
      end case;

      case Item.Status is
         when Overload_Ranking_Provenance_Unlinked_Diagnostic =>
            Model.Unlinked_Diagnostic_Total := Model.Unlinked_Diagnostic_Total + 1;
         when Overload_Ranking_Provenance_Unlinked_Ranking =>
            Model.Unlinked_Ranking_Total := Model.Unlinked_Ranking_Total + 1;
         when Overload_Ranking_Provenance_Current =>
            null;
      end case;

      Model.Evidence_Stage_Total := Model.Evidence_Stage_Total + 1;
      if Item.Ranking /= Editor.Ada_Overload_Ranking.No_Overload_Ranking then
         Model.Ranking_Stage_Total := Model.Ranking_Stage_Total + 1;
      end if;
      if Item.Diagnostic_Fingerprint /= 0 then
         Model.Diagnostic_Stage_Total := Model.Diagnostic_Stage_Total + 1;
      end if;
      if Item.Ranking_Fingerprint /= 0 then
         Model.Cause_Stage_Total := Model.Cause_Stage_Total + 1;
      end if;
   end Append;

   procedure Clear (Model : in out Overload_Ranking_Provenance_Model) is
   begin
      Model.Items.Clear;
      Model.Exact_Total := 0;
      Model.Implicit_Total := 0;
      Model.Universal_Total := 0;
      Model.Ambiguous_Total := 0;
      Model.Rejected_Total := 0;
      Model.Unknown_Total := 0;
      Model.Not_Overload_Total := 0;
      Model.Unlinked_Diagnostic_Total := 0;
      Model.Unlinked_Ranking_Total := 0;
      Model.Evidence_Stage_Total := 0;
      Model.Cause_Stage_Total := 0;
      Model.Ranking_Stage_Total := 0;
      Model.Diagnostic_Stage_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Diagnostics : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Model;
      Rankings    : Editor.Ada_Overload_Ranking.Overload_Ranking_Model)
      return Overload_Ranking_Provenance_Model
   is
      Model : Overload_Ranking_Provenance_Model;
      Next_Id : Overload_Ranking_Provenance_Id := 1;
      Diagnostic : Expression_Diagnostic;
      Ranking : Ranking_Info;
   begin
      Model.Result_Fingerprint := Mix
        (Editor.Ada_Expression_Diagnostics.Fingerprint (Diagnostics),
         Editor.Ada_Overload_Ranking.Fingerprint (Rankings));

      for Index in 1 .. Editor.Ada_Expression_Diagnostics.Diagnostic_Count (Diagnostics) loop
         Diagnostic := Editor.Ada_Expression_Diagnostics.Diagnostic_At (Diagnostics, Index);
         if Diagnostic.From_Overload_Ranking then
            Ranking := Find_Ranking (Rankings, Diagnostic.Overload_Ranking);
            Append (Model, From_Diagnostic (Diagnostic, Ranking, Next_Id));
            Next_Id := Next_Id + 1;
         end if;
      end loop;

      for Index in 1 .. Editor.Ada_Overload_Ranking.Ranking_Count (Rankings) loop
         Ranking := Editor.Ada_Overload_Ranking.Ranking_At (Rankings, Index);
         if not Has_Diagnostic_For_Ranking (Diagnostics, Ranking.Id) then
            Append (Model, From_Ranking (Ranking, Next_Id));
            Next_Id := Next_Id + 1;
         end if;
      end loop;

      return Model;
   end Build;

   function Item_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Item_Count;

   function Item_At
     (Model : Overload_Ranking_Provenance_Model;
      Index : Positive) return Overload_Ranking_Provenance_Item is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;
      return Model.Items.Element (Index);
   end Item_At;

   function Count_Outcome
     (Model   : Overload_Ranking_Provenance_Model;
      Outcome : Overload_Ranking_Provenance_Outcome) return Natural is
   begin
      case Outcome is
         when Overload_Ranking_Outcome_Exact => return Model.Exact_Total;
         when Overload_Ranking_Outcome_Implicit_Conversion => return Model.Implicit_Total;
         when Overload_Ranking_Outcome_Universal_Numeric => return Model.Universal_Total;
         when Overload_Ranking_Outcome_Ambiguous => return Model.Ambiguous_Total;
         when Overload_Ranking_Outcome_No_Candidate => return Model.Rejected_Total;
         when Overload_Ranking_Outcome_Unknown => return Model.Unknown_Total;
         when Overload_Ranking_Outcome_Not_Overload => return Model.Not_Overload_Total;
         when Overload_Ranking_Outcome_Unlinked =>
            return Model.Unlinked_Diagnostic_Total + Model.Unlinked_Ranking_Total;
      end case;
   end Count_Outcome;

   function Count_Stage
     (Model : Overload_Ranking_Provenance_Model;
      Stage : Overload_Ranking_Provenance_Stage) return Natural is
   begin
      case Stage is
         when Overload_Ranking_Stage_Expression_Evidence => return Model.Evidence_Stage_Total;
         when Overload_Ranking_Stage_Overload_Cause => return Model.Cause_Stage_Total;
         when Overload_Ranking_Stage_Ranking_Decision => return Model.Ranking_Stage_Total;
         when Overload_Ranking_Stage_Diagnostic_Projection => return Model.Diagnostic_Stage_Total;
         when Overload_Ranking_Stage_None => return 0;
      end case;
   end Count_Stage;

   function Exact_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Exact_Total;
   end Exact_Outcome_Count;

   function Implicit_Conversion_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Implicit_Total;
   end Implicit_Conversion_Outcome_Count;

   function Universal_Numeric_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Universal_Total;
   end Universal_Numeric_Outcome_Count;

   function Ambiguous_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Ambiguous_Total;
   end Ambiguous_Outcome_Count;

   function Rejected_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Outcome_Count;

   function Unknown_Outcome_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Unknown_Total;
   end Unknown_Outcome_Count;

   function Unlinked_Diagnostic_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Unlinked_Diagnostic_Total;
   end Unlinked_Diagnostic_Count;

   function Unlinked_Ranking_Count (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Unlinked_Ranking_Total;
   end Unlinked_Ranking_Count;

   function First_For_Ranking
     (Model   : Overload_Ranking_Provenance_Model;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Id)
      return Overload_Ranking_Provenance_Item is
   begin
      for Item of Model.Items loop
         if Item.Ranking = Ranking then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Ranking;

   function Items_For_Ranking
     (Model   : Overload_Ranking_Provenance_Model;
      Ranking : Editor.Ada_Overload_Ranking.Overload_Ranking_Id)
      return Overload_Ranking_Provenance_Result_Set
   is
      Results : Overload_Ranking_Provenance_Result_Set;
   begin
      for Item of Model.Items loop
         if Item.Ranking = Ranking then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
         end if;
      end loop;
      return Results;
   end Items_For_Ranking;

   function First_For_Diagnostic
     (Model      : Overload_Ranking_Provenance_Model;
      Diagnostic : Editor.Ada_Expression_Diagnostics.Expression_Diagnostic_Id)
      return Overload_Ranking_Provenance_Item is
   begin
      for Item of Model.Items loop
         if Item.Expression_Diagnostic = Diagnostic then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Diagnostic;

   function Result_Count (Results : Overload_Ranking_Provenance_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Overload_Ranking_Provenance_Result_Set;
      Index   : Positive) return Overload_Ranking_Provenance_Item is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Has_Item (Item : Overload_Ranking_Provenance_Item) return Boolean is
   begin
      return Item.Id /= No_Overload_Ranking_Provenance;
   end Has_Item;

   function Fingerprint (Model : Overload_Ranking_Provenance_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Overload_Ranking_Provenance;
