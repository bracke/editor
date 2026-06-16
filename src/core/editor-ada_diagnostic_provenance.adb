with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Diagnostic_Provenance is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id;

   use type Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Id;
   use type Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Id;
   use type Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Source;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 211) + B + 167) mod 1_000_000_007;
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

   function Stage_Slot (Stage : Diagnostic_Provenance_Stage) return Natural is
   begin
      case Stage is
         when Diagnostic_Provenance_No_Stage =>
            return 0;
         when Diagnostic_Provenance_Semantic_Source =>
            return 1;
         when Diagnostic_Provenance_Diagnostic_Projection =>
            return 2;
         when Diagnostic_Provenance_Colour_Projection =>
            return 3;
         when Diagnostic_Provenance_Snapshot_Guard =>
            return 4;
         when Diagnostic_Provenance_Unified_Feed =>
            return 5;
         when Diagnostic_Provenance_Index =>
            return 6;
         when Diagnostic_Provenance_Overload_Ranking =>
            return 7;
         when Diagnostic_Provenance_Integrated_Closure =>
            return 8;
      end case;
   end Stage_Slot;

   function Source_Label (Source : Feed_Source) return String is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return "Expression diagnostics";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return "Generic contract diagnostics";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return "Cross-unit diagnostics";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return "Representation and freezing diagnostics";
      end case;
   end Source_Label;

   function Source_Explanation (Source : Feed_Source) return String is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return "Produced by expression/type semantic analysis and projected " &
              "through the guarded semantic diagnostic feed.";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return "Produced by generic contract conformance analysis and projected " &
              "through the guarded semantic diagnostic feed.";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return "Produced by cross-unit closure and visibility analysis and " &
              "projected through the guarded semantic diagnostic feed.";
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return "Produced by representation, operational, layout, aspect, " &
              "and freezing analysis and projected through the guarded " &
              "semantic diagnostic feed.";
      end case;
   end Source_Explanation;

   function Closure_Status_Label
     (Status : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Status)
      return String is
   begin
      case Status is
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Not_Checked =>
            return "not checked";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_Local =>
            return "legal local semantic closure";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_Cross_Unit =>
            return "legal cross-unit semantic closure";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Legal_With_Use_Closure =>
            return "legal with/use semantic closure";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Limited_View_Barrier =>
            return "limited-view semantic barrier";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Private_View_Barrier =>
            return "private-view semantic barrier";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Missing_Dependency =>
            return "missing cross-unit dependency";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Ambiguous_Dependency =>
            return "ambiguous cross-unit dependency";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Dependency_Overflow =>
            return "dependency overflow";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Stale_Dependency =>
            return "stale dependency";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Rejected_Stale_Input =>
            return "rejected stale integrated closure input";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Wide_Legality_Blocker =>
            return "wide semantic legality blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Overload_Blocker =>
            return "overload resolution blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Staticness_Blocker =>
            return "staticness/range/predicate blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Accessibility_Blocker =>
            return "accessibility/lifetime blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Contract_Blocker =>
            return "contract/aspect blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Elaboration_Blocker =>
            return "elaboration/dependence blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Completion_Blocker =>
            return "unit completion/order blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Renaming_Blocker =>
            return "renaming/visibility blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Exception_Finalization_Blocker =>
            return "exception/finalization blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Representation_Blocker =>
            return "representation/layout/stream blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Definite_Initialization_Blocker =>
            return "definite-initialization/flow blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Dataflow_Blocker =>
            return "global/depends dataflow blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Refined_Global_Depends_Blocker =>
            return "refined global/depends conformance blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_AST_Coverage_Blocker =>
            return "parser/AST semantic coverage blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Coverage_Gate_Blocker =>
            return "semantic coverage gate blocker";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Multiple_Blockers =>
            return "multiple semantic blockers";
         when Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Indeterminate =>
            return "indeterminate semantic closure";
      end case;
   end Closure_Status_Label;

   function Matches_Integrated_Closure
     (Item    : Diagnostic_Provenance_Item;
      Closure : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Info)
      return Boolean is
   begin
      if Item.Node /= Closure.Node then
         return False;
      end if;

      if Item.Start_Line /= Closure.Start_Line
        or else Item.Start_Column /= Closure.Start_Column
        or else Item.End_Line /= Closure.End_Line
        or else Item.End_Column /= Closure.End_Column
      then
         return False;
      end if;

      return Closure.Fingerprint = 0
        or else Item.Source_Fingerprint = Closure.Fingerprint
        or else Item.Diagnostic_Fingerprint = Closure.Fingerprint;
   end Matches_Integrated_Closure;

   function Make_Integrated_Closure_Item
     (Base    : Diagnostic_Provenance_Item;
      Closure : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Info;
      Id      : Diagnostic_Provenance_Id) return Diagnostic_Provenance_Item
   is
      Item : Diagnostic_Provenance_Item := Base;
   begin
      Item.Id := Id;
      Item.Root_Stage := Diagnostic_Provenance_Integrated_Closure;
      Item.Integrated_Closure := Closure.Id;
      Item.Integrated_Closure_Status := Closure.Status;
      Item.Integrated_Closure_Blocker := Closure.Blocker;
      Item.Integrated_Closure_Dependency := Closure.Dependency;
      Item.Integrated_Closure_Fingerprint := Closure.Fingerprint;
      Item.Source_Label := To_Unbounded_String
        ("Integrated semantic closure provenance");
      Item.Explanation := To_Unbounded_String
        ("Integrated semantic closure links this diagnostic to " &
         Closure_Status_Label (Closure.Status) & ".");
      Item.Chain_Summary := To_Unbounded_String
        ("semantic legality layers -> integrated semantic closure -> " &
         "unified feed -> diagnostic index");
      Item.Fingerprint := Mix
        (Natural (Item.Id) + 1,
         Mix
           (Natural (Item.Index_Id) + 1,
            Mix
              (Natural (Item.Integrated_Closure) + 1,
               Mix
                 (Item.Integrated_Closure_Fingerprint + 1,
                  Mix
                    (Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Status'Pos
                       (Item.Integrated_Closure_Status) + 1,
                     Mix
                       (Editor.Ada_Integrated_Semantic_Closure.Closure_Blocker_Family'Pos
                          (Item.Integrated_Closure_Blocker) + 1,
                        Mix
                          (Editor.Ada_Integrated_Semantic_Closure.Closure_Dependency_State'Pos
                             (Item.Integrated_Closure_Dependency) + 1,
                           Mix
                             (Item.Diagnostic_Fingerprint + 1,
                              Stage_Slot (Item.Root_Stage)))))))));
      return Item;
   end Make_Integrated_Closure_Item;


   function Ranking_Outcome_Label
     (Outcome : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Outcome)
      return String is
   begin
      case Outcome is
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Exact =>
            return "exact overload ranking";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Implicit_Conversion =>
            return "implicit-conversion overload ranking";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Universal_Numeric =>
            return "universal numeric overload tie-break";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Ambiguous =>
            return "ambiguous overload ranking";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_No_Candidate =>
            return "no ranked overload candidate";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Unknown =>
            return "unknown overload ranking";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Not_Overload =>
            return "not an overload-ranking target";
         when Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Outcome_Unlinked =>
            return "unlinked overload-ranking provenance";
      end case;
   end Ranking_Outcome_Label;

   function Matches_Ranking_Provenance
     (Item    : Diagnostic_Provenance_Item;
      Ranking : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Item)
      return Boolean is
   begin
      if Item.Source /= Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression then
         return False;
      end if;

      if Item.Node /= Ranking.Node then
         return False;
      end if;

      if Item.Start_Line /= Ranking.Start_Line
        or else Item.Start_Column /= Ranking.Start_Column
        or else Item.End_Line /= Ranking.End_Line
        or else Item.End_Column /= Ranking.End_Column
      then
         return False;
      end if;

      return Ranking.Diagnostic_Fingerprint = 0
        or else Item.Diagnostic_Fingerprint = Ranking.Diagnostic_Fingerprint;
   end Matches_Ranking_Provenance;

   function Make_Ranking_Item
     (Base    : Diagnostic_Provenance_Item;
      Ranking : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Item;
      Id      : Diagnostic_Provenance_Id) return Diagnostic_Provenance_Item
   is
      Item : Diagnostic_Provenance_Item := Base;
   begin
      Item.Id := Id;
      Item.Root_Stage := Diagnostic_Provenance_Overload_Ranking;
      Item.Ranking_Provenance := Ranking.Id;
      Item.Ranking_Outcome := Ranking.Outcome;
      Item.Ranking_Candidate_Count := Ranking.Candidate_Count;
      Item.Ranking_Selected_Count := Ranking.Selected_Count;
      Item.Ranking_Rejected_Count := Ranking.Rejected_Count;
      Item.Ranking_Unknown_Count := Ranking.Unknown_Count;
      Item.Ranking_Fingerprint := Ranking.Fingerprint;
      Item.Source_Label := To_Unbounded_String
        ("Expression diagnostics with overload-ranking provenance");
      Item.Explanation := To_Unbounded_String
        ("Overload-ranking provenance links this diagnostic to " &
         Ranking_Outcome_Label (Ranking.Outcome) & ".");
      Item.Chain_Summary := To_Unbounded_String
        ("semantic source -> overload cause -> overload ranking -> " &
         "diagnostic projection -> semantic-colour projection -> " &
         "snapshot guard -> unified feed -> diagnostic index");
      Item.Fingerprint := Mix
        (Natural (Item.Id) + 1,
         Mix
           (Natural (Item.Index_Id) + 1,
            Mix
              (Natural (Item.Ranking_Provenance) + 1,
               Mix
                 (Item.Ranking_Fingerprint + 1,
                  Mix
                    (Item.Ranking_Candidate_Count + 1,
                     Mix
                       (Item.Ranking_Selected_Count + 1,
                        Mix
                          (Item.Ranking_Rejected_Count + 1,
                           Mix
                             (Item.Ranking_Unknown_Count + 1,
                              Mix
                                (Item.Diagnostic_Fingerprint + 1,
                                 Stage_Slot (Item.Root_Stage))))))))));
      return Item;
   end Make_Ranking_Item;

   function Make_Item
     (Feed_Item : Index_Entry;
      Id    : Diagnostic_Provenance_Id) return Diagnostic_Provenance_Item
   is
      Item : Diagnostic_Provenance_Item;
   begin
      Item.Id := Id;
      Item.Index_Id := Feed_Item.Id;
      Item.Feed_Index := Feed_Item.Feed_Index;
      Item.Diagnostic := Feed_Item.Diagnostic;
      Item.Severity := Feed_Item.Diagnostic.Severity;
      Item.Source := Feed_Item.Diagnostic.Source;
      Item.Token := Feed_Item.Diagnostic.Token;
      Item.Node := Feed_Item.Diagnostic.Node;
      Item.Root_Stage := Diagnostic_Provenance_Semantic_Source;
      Item.Source_Label := To_Unbounded_String (Source_Label (Feed_Item.Diagnostic.Source));
      Item.Explanation := To_Unbounded_String (Source_Explanation (Feed_Item.Diagnostic.Source));
      Item.Chain_Summary := To_Unbounded_String
        ("semantic source -> diagnostic projection -> semantic-colour " &
         "projection -> snapshot guard -> unified feed -> diagnostic index");
      Item.Start_Line := Feed_Item.Diagnostic.Start_Line;
      Item.Start_Column := Feed_Item.Diagnostic.Start_Column;
      Item.End_Line := Feed_Item.Diagnostic.End_Line;
      Item.End_Column := Feed_Item.Diagnostic.End_Column;
      Item.Source_Fingerprint := Feed_Item.Diagnostic.Source_Fingerprint;
      Item.Diagnostic_Fingerprint := Feed_Item.Diagnostic.Fingerprint;
      Item.Fingerprint := Mix
        (Natural (Item.Id) + 1,
         Mix
           (Natural (Item.Index_Id) + 1,
            Mix
              (Item.Feed_Index + 1,
               Mix
                 (Item.Diagnostic_Fingerprint + 1,
                  Mix
                    (Item.Source_Fingerprint + 1,
                     Mix
                       (Source_Slot (Item.Source),
                        Mix (Severity_Slot (Item.Severity), Stage_Slot (Item.Root_Stage))))))));
      return Item;
   end Make_Item;

   procedure Append_Item
     (Model : in out Diagnostic_Provenance_Model;
      Item  : Diagnostic_Provenance_Item) is
   begin
      if Item.Id = No_Diagnostic_Provenance then
         return;
      end if;

      Model.Items.Append (Item);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Source_Slot (Item.Source));

      case Item.Severity is
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;

      case Item.Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            Model.Expression_Total := Model.Expression_Total + 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            Model.Generic_Total := Model.Generic_Total + 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            Model.Cross_Unit_Total := Model.Cross_Unit_Total + 1;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            Model.Representation_Total := Model.Representation_Total + 1;
      end case;

      Model.Source_Stage_Total := Model.Source_Stage_Total + 1;
      Model.Projection_Stage_Total := Model.Projection_Stage_Total + 1;
      Model.Colour_Stage_Total := Model.Colour_Stage_Total + 1;
      Model.Guard_Stage_Total := Model.Guard_Stage_Total + 1;
      Model.Feed_Stage_Total := Model.Feed_Stage_Total + 1;
      Model.Index_Stage_Total := Model.Index_Stage_Total + 1;
      if Item.Root_Stage = Diagnostic_Provenance_Overload_Ranking then
         Model.Overload_Ranking_Stage_Total := Model.Overload_Ranking_Stage_Total + 1;
      elsif Item.Root_Stage = Diagnostic_Provenance_Integrated_Closure then
         Model.Integrated_Closure_Stage_Total := Model.Integrated_Closure_Stage_Total + 1;
      end if;
   end Append_Item;

   procedure Clear (Model : in out Diagnostic_Provenance_Model) is
   begin
      Model.Model_Status := Diagnostic_Provenance_Current;
      Model.Items.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Rejected_Total := 0;
      Model.Expression_Total := 0;
      Model.Generic_Total := 0;
      Model.Cross_Unit_Total := 0;
      Model.Representation_Total := 0;
      Model.Source_Stage_Total := 0;
      Model.Projection_Stage_Total := 0;
      Model.Colour_Stage_Total := 0;
      Model.Guard_Stage_Total := 0;
      Model.Feed_Stage_Total := 0;
      Model.Index_Stage_Total := 0;
      Model.Overload_Ranking_Stage_Total := 0;
      Model.Integrated_Closure_Stage_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model)
      return Diagnostic_Provenance_Model
   is
      Model : Diagnostic_Provenance_Model;
      Next_Id : Diagnostic_Provenance_Id := 1;
   begin
      if Editor.Ada_Semantic_Diagnostic_Index.Rejected_Stale (Index) then
         Model.Model_Status := Diagnostic_Provenance_Rejected_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Diagnostic_Index.Rejected_Entry_Count (Index);
         Model.Result_Fingerprint := Mix
           (Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index),
            Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Result_Fingerprint := Editor.Ada_Semantic_Diagnostic_Index.Fingerprint (Index);

      for Position in 1 .. Editor.Ada_Semantic_Diagnostic_Index.Entry_Count (Index) loop
         Append_Item
           (Model,
            Make_Item
              (Editor.Ada_Semantic_Diagnostic_Index.Entry_At (Index, Position),
               Next_Id));
         Next_Id := Next_Id + 1;
      end loop;

      return Model;
   end Build;


   function Build_With_Overload_Ranking
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Ranking_Provenance :
        Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Model)
      return Diagnostic_Provenance_Model
   is
      Model : Diagnostic_Provenance_Model := Build (Index);
      Next_Id : Diagnostic_Provenance_Id := Diagnostic_Provenance_Id (Item_Count (Model) + 1);
      Ranking_Item : Editor.Ada_Overload_Ranking_Provenance.Overload_Ranking_Provenance_Item;
      Base_Item : Diagnostic_Provenance_Item;
      Matched : Boolean;
   begin
      if Rejected_Stale (Model) then
         return Model;
      end if;

      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Editor.Ada_Overload_Ranking_Provenance.Fingerprint (Ranking_Provenance));

      for Ranking_Index in 1 .. Editor.Ada_Overload_Ranking_Provenance.Item_Count (Ranking_Provenance) loop
         Ranking_Item := Editor.Ada_Overload_Ranking_Provenance.Item_At
           (Ranking_Provenance, Ranking_Index);
         Matched := False;

         for Position in 1 .. Natural (Model.Items.Length) loop
            Base_Item := Model.Items.Element (Position);
            if Base_Item.Root_Stage /= Diagnostic_Provenance_Overload_Ranking
              and then Matches_Ranking_Provenance (Base_Item, Ranking_Item)
            then
               Append_Item (Model, Make_Ranking_Item (Base_Item, Ranking_Item, Next_Id));
               Next_Id := Next_Id + 1;
               Matched := True;
               exit;
            end if;
         end loop;

         if not Matched then
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Ranking_Item.Fingerprint + 1);
         end if;
      end loop;

      return Model;
   end Build_With_Overload_Ranking;

   function Build_With_Integrated_Closure
     (Index : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Model;
      Closure : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Model)
      return Diagnostic_Provenance_Model
   is
      Model : Diagnostic_Provenance_Model := Build (Index);
      Next_Id : Diagnostic_Provenance_Id := Diagnostic_Provenance_Id (Item_Count (Model) + 1);
      Closure_Row : Editor.Ada_Integrated_Semantic_Closure.Integrated_Closure_Info;
      Base_Item : Diagnostic_Provenance_Item;
      Matched : Boolean;
   begin
      if Rejected_Stale (Model) then
         return Model;
      end if;

      Model.Result_Fingerprint := Mix
        (Model.Result_Fingerprint,
         Editor.Ada_Integrated_Semantic_Closure.Fingerprint (Closure));

      for Closure_Index in 1 .. Editor.Ada_Integrated_Semantic_Closure.Closure_Count (Closure) loop
         Closure_Row := Editor.Ada_Integrated_Semantic_Closure.Closure_At
           (Closure, Closure_Index);
         Matched := False;

         for Position in 1 .. Natural (Model.Items.Length) loop
            Base_Item := Model.Items.Element (Position);
            if Base_Item.Root_Stage /= Diagnostic_Provenance_Integrated_Closure
              and then Matches_Integrated_Closure (Base_Item, Closure_Row)
            then
               Append_Item
                 (Model,
                  Make_Integrated_Closure_Item (Base_Item, Closure_Row, Next_Id));
               Next_Id := Next_Id + 1;
               Matched := True;
               exit;
            end if;
         end loop;

         if not Matched then
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Closure_Row.Fingerprint + 1);
         end if;
      end loop;

      return Model;
   end Build_With_Integrated_Closure;

   function Status (Model : Diagnostic_Provenance_Model) return Diagnostic_Provenance_Status is
   begin
      return Model.Model_Status;
   end Status;

   function Current (Model : Diagnostic_Provenance_Model) return Boolean is
   begin
      return Model.Model_Status = Diagnostic_Provenance_Current;
   end Current;

   function Rejected_Stale (Model : Diagnostic_Provenance_Model) return Boolean is
   begin
      return Model.Model_Status = Diagnostic_Provenance_Rejected_Stale;
   end Rejected_Stale;

   function Item_Count (Model : Diagnostic_Provenance_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Item_Count;

   function Item_At
     (Model : Diagnostic_Provenance_Model;
      Index : Positive) return Diagnostic_Provenance_Item is
   begin
      if Index > Natural (Model.Items.Length) then
         return (others => <>);
      end if;

      return Model.Items.Element (Index);
   end Item_At;

   function Error_Item_Count (Model : Diagnostic_Provenance_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Item_Count;

   function Warning_Item_Count (Model : Diagnostic_Provenance_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Item_Count;

   function Info_Item_Count (Model : Diagnostic_Provenance_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Item_Count;

   function Rejected_Item_Count (Model : Diagnostic_Provenance_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Item_Count;

   function Overload_Ranking_Item_Count (Model : Diagnostic_Provenance_Model) return Natural is
   begin
      return Model.Overload_Ranking_Stage_Total;
   end Overload_Ranking_Item_Count;

   function Integrated_Closure_Item_Count (Model : Diagnostic_Provenance_Model) return Natural is
   begin
      return Model.Integrated_Closure_Stage_Total;
   end Integrated_Closure_Item_Count;

   function Count_Source
     (Model  : Diagnostic_Provenance_Model;
      Source : Feed_Source) return Natural is
   begin
      case Source is
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Expression =>
            return Model.Expression_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Generic_Contract =>
            return Model.Generic_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Cross_Unit =>
            return Model.Cross_Unit_Total;
         when Editor.Ada_Semantic_Colour_Projection.Semantic_Colour_From_Representation =>
            return Model.Representation_Total;
      end case;
   end Count_Source;

   function Count_Stage
     (Model : Diagnostic_Provenance_Model;
      Stage : Diagnostic_Provenance_Stage) return Natural is
   begin
      case Stage is
         when Diagnostic_Provenance_Semantic_Source =>
            return Model.Source_Stage_Total;
         when Diagnostic_Provenance_Diagnostic_Projection =>
            return Model.Projection_Stage_Total;
         when Diagnostic_Provenance_Colour_Projection =>
            return Model.Colour_Stage_Total;
         when Diagnostic_Provenance_Snapshot_Guard =>
            return Model.Guard_Stage_Total;
         when Diagnostic_Provenance_Unified_Feed =>
            return Model.Feed_Stage_Total;
         when Diagnostic_Provenance_Index =>
            return Model.Index_Stage_Total;
         when Diagnostic_Provenance_Overload_Ranking =>
            return Model.Overload_Ranking_Stage_Total;
         when Diagnostic_Provenance_Integrated_Closure =>
            return Model.Integrated_Closure_Stage_Total;
         when Diagnostic_Provenance_No_Stage =>
            return 0;
      end case;
   end Count_Stage;

   function First_For_Diagnostic
     (Model    : Diagnostic_Provenance_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Provenance_Item is
   begin
      for Position in 1 .. Natural (Model.Items.Length) loop
         declare
            Item : constant Diagnostic_Provenance_Item := Model.Items.Element (Position);
         begin
            if Item.Index_Id = Index_Id then
               return Item;
            end if;
         end;
      end loop;

      return (others => <>);
   end First_For_Diagnostic;

   function Items_For_Diagnostic
     (Model    : Diagnostic_Provenance_Model;
      Index_Id : Editor.Ada_Semantic_Diagnostic_Index.Semantic_Diagnostic_Index_Id)
      return Diagnostic_Provenance_Result_Set
   is
      Results : Diagnostic_Provenance_Result_Set;
   begin
      for Position in 1 .. Natural (Model.Items.Length) loop
         declare
            Item : constant Diagnostic_Provenance_Item := Model.Items.Element (Position);
         begin
            if Item.Index_Id = Index_Id then
               Results.Items.Append (Item);
               Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint);
            end if;
         end;
      end loop;

      return Results;
   end Items_For_Diagnostic;

   function Result_Count (Results : Diagnostic_Provenance_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Diagnostic_Provenance_Result_Set;
      Index   : Positive) return Diagnostic_Provenance_Item is
   begin
      if Index > Natural (Results.Items.Length) then
         return (others => <>);
      end if;

      return Results.Items.Element (Index);
   end Result_At;

   function Has_Item (Item : Diagnostic_Provenance_Item) return Boolean is
   begin
      return Item.Id /= No_Diagnostic_Provenance;
   end Has_Item;

   function Fingerprint (Model : Diagnostic_Provenance_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Diagnostic_Provenance;
