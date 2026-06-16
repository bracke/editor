with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Final_Semantic_Diagnostic_Provenance is

   pragma Suppress (Overflow_Check);

   use type Base_Prov.Diagnostic_Provenance_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Feed.Semantic_Diagnostic_Feed_Id;
   use type Index.Semantic_Diagnostic_Index_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 191) + B + 1196) mod 2_147_483_647;
   end Mix;

   function Blocker_For
     (Row : Final_Diag.Final_Diagnostic_Info) return Final_Blocker_Family is
   begin
      case Row.Status is
         when Final_Diag.Final_Diagnostic_Withheld_Legal |
              Final_Diag.Final_Diagnostic_Not_Checked |
              Final_Diag.Final_Diagnostic_Stale_Input |
              Final_Diag.Final_Diagnostic_Indeterminate =>
            return Final_Blocker_None;
         when Final_Diag.Final_Diagnostic_Cross_Unit_Blocker =>
            return Final_Blocker_Cross_Unit;
         when Final_Diag.Final_Diagnostic_Overload_Type_Blocker =>
            return Final_Blocker_Overload_Type;
         when Final_Diag.Final_Diagnostic_Generic_Replay_Blocker =>
            return Final_Blocker_Generic_Replay;
         when Final_Diag.Final_Diagnostic_Representation_Freezing_Blocker =>
            return Final_Blocker_Representation_Freezing;
         when Final_Diag.Final_Diagnostic_Flow_Contract_Blocker =>
            return Final_Blocker_Flow_Contract;
         when Final_Diag.Final_Diagnostic_Tasking_Protected_Blocker =>
            return Final_Blocker_Tasking_Protected;
         when Final_Diag.Final_Diagnostic_Elaboration_Blocker =>
            return Final_Blocker_Elaboration;
         when Final_Diag.Final_Diagnostic_Accessibility_Lifetime_Blocker =>
            return Final_Blocker_Accessibility_Lifetime;
         when Final_Diag.Final_Diagnostic_Discriminant_Variant_Blocker =>
            return Final_Blocker_Discriminant_Variant;
         when Final_Diag.Final_Diagnostic_AST_Repair_Blocker =>
            return Final_Blocker_AST_Repair;
         when Final_Diag.Final_Diagnostic_Coverage_Gate_Blocker =>
            return Final_Blocker_Coverage_Gate;
         when Final_Diag.Final_Diagnostic_View_Barrier =>
            return Final_Blocker_View_Barrier;
         when Final_Diag.Final_Diagnostic_Multiple_Blockers =>
            return Final_Blocker_Multiple;
      end case;
   end Blocker_For;

   function Status_For
     (Row : Final_Diag.Final_Diagnostic_Info) return Final_Provenance_Status is
   begin
      case Row.Status is
         when Final_Diag.Final_Diagnostic_Withheld_Legal =>
            return Final_Provenance_Withheld_Legal;
         when Final_Diag.Final_Diagnostic_View_Barrier =>
            return Final_Provenance_View_Barrier;
         when Final_Diag.Final_Diagnostic_Stale_Input =>
            return Final_Provenance_Stale_Rejected;
         when Final_Diag.Final_Diagnostic_Indeterminate =>
            return Final_Provenance_Indeterminate;
         when Final_Diag.Final_Diagnostic_Multiple_Blockers =>
            return Final_Provenance_Multiple_Blockers;
         when Final_Diag.Final_Diagnostic_Not_Checked =>
            return Final_Provenance_Not_Checked;
         when others =>
            case Row.Severity is
               when Final_Diag.Final_Diagnostic_Error =>
                  return Final_Provenance_Emitted_Error;
               when Final_Diag.Final_Diagnostic_Warning =>
                  return Final_Provenance_Emitted_Warning;
               when Final_Diag.Final_Diagnostic_Severity_Info =>
                  return Final_Provenance_Emitted_Warning;
            end case;
      end case;
   end Status_For;

   function Severity_For
     (Row : Final_Diag.Final_Diagnostic_Info) return Feed.Semantic_Diagnostic_Feed_Severity is
   begin
      case Row.Severity is
         when Final_Diag.Final_Diagnostic_Error =>
            return Feed.Semantic_Diagnostic_Feed_Error;
         when Final_Diag.Final_Diagnostic_Warning =>
            return Feed.Semantic_Diagnostic_Feed_Warning;
         when Final_Diag.Final_Diagnostic_Severity_Info =>
            return Feed.Semantic_Diagnostic_Feed_Info;
      end case;
   end Severity_For;

   function Stage_For
     (Status : Final_Provenance_Status) return Final_Provenance_Stage is
   begin
      case Status is
         when Final_Provenance_Withheld_Legal =>
            return Final_Stage_Withheld_Legal;
         when Final_Provenance_Stale_Rejected =>
            return Final_Stage_Stale_Rejection;
         when others =>
            return Final_Stage_Final_Semantic_Integration;
      end case;
   end Stage_For;

   function Message_For
     (Row : Final_Diag.Final_Diagnostic_Info;
      Status : Final_Provenance_Status;
      Blocker : Final_Blocker_Family) return String is
      pragma Unreferenced (Row);
   begin
      case Status is
         when Final_Provenance_Withheld_Legal =>
            return "final semantic provenance withheld a confident legal result";
         when Final_Provenance_Emitted_Error =>
            return "final semantic provenance emitted a semantic blocker as an error";
         when Final_Provenance_Emitted_Warning =>
            return "final semantic provenance emitted a semantic warning";
         when Final_Provenance_View_Barrier =>
            return "final semantic provenance preserved a view barrier";
         when Final_Provenance_Stale_Rejected =>
            return "final semantic provenance rejected stale final semantic input";
         when Final_Provenance_Indeterminate =>
            return "final semantic provenance preserved indeterminate final semantic closure";
         when Final_Provenance_Multiple_Blockers =>
            return "final semantic provenance preserved multiple final semantic blockers";
         when Final_Provenance_Not_Checked =>
            if Blocker /= Final_Blocker_None then
               return "final semantic provenance found an unchecked semantic blocker";
            end if;
            return "final semantic provenance was not checked";
      end case;
   end Message_For;

   function Entry_Fingerprint (Row : Final_Provenance_Info) return Natural is
      Text : constant String := To_String (Row.Message) & To_String (Row.Chain_Summary);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Final_Diag.Final_Diagnostic_Status'Pos (Row.Final_Status) + 1);
      H := Mix (H, Final_Diag.Final_Diagnostic_Source_Family'Pos (Row.Final_Family) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Final_Provenance_Status'Pos (Row.Status) + 1);
      H := Mix (H, Final_Provenance_Stage'Pos (Row.Stage) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Natural (Row.Feed_Entry));
      H := Mix (H, Natural (Row.Index_Entry));
      H := Mix (H, Natural (Row.Base_Provenance));
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Diagnostic_Fingerprint);
      H := Mix (H, Row.Feed_Fingerprint);
      H := Mix (H, Row.Index_Fingerprint);
      H := Mix (H, Row.Base_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Entry_Fingerprint;

   function Matching_Feed
     (Feed_Model : Feed.Semantic_Diagnostic_Feed_Model;
      Row        : Final_Diag.Final_Diagnostic_Info) return Feed.Semantic_Diagnostic_Feed_Entry is
      Candidate : Feed.Semantic_Diagnostic_Feed_Entry;
   begin
      for I in 1 .. Feed.Entry_Count (Feed_Model) loop
         Candidate := Feed.Entry_At (Feed_Model, I);
         if Candidate.Node = Row.Node
           or else Candidate.Source_Fingerprint = Row.Source_Fingerprint
         then
            return Candidate;
         end if;
      end loop;
      return (others => <>);
   end Matching_Feed;

   function Matching_Index
     (Index_Model : Index.Semantic_Diagnostic_Index_Model;
      Row         : Final_Diag.Final_Diagnostic_Info) return Index.Semantic_Diagnostic_Index_Entry is
      Candidate : Index.Semantic_Diagnostic_Index_Entry;
   begin
      for I in 1 .. Index.Entry_Count (Index_Model) loop
         Candidate := Index.Entry_At (Index_Model, I);
         if Candidate.Diagnostic.Node = Row.Node
           or else Candidate.Diagnostic.Source_Fingerprint = Row.Source_Fingerprint
         then
            return Candidate;
         end if;
      end loop;
      return (others => <>);
   end Matching_Index;

   function Matching_Base
     (Provenance : Base_Prov.Diagnostic_Provenance_Model;
      Row        : Final_Diag.Final_Diagnostic_Info) return Base_Prov.Diagnostic_Provenance_Item is
      Candidate : Base_Prov.Diagnostic_Provenance_Item;
   begin
      for I in 1 .. Base_Prov.Item_Count (Provenance) loop
         Candidate := Base_Prov.Item_At (Provenance, I);
         if Candidate.Diagnostic.Node = Row.Node
           or else Candidate.Diagnostic.Source_Fingerprint = Row.Source_Fingerprint
         then
            return Candidate;
         end if;
      end loop;
      return (others => <>);
   end Matching_Base;

   function Make_Row
     (Diagnostic : Final_Diag.Final_Diagnostic_Info;
      Row_Index  : Positive;
      Feed_Item  : Feed.Semantic_Diagnostic_Feed_Entry;
      Index_Item : Index.Semantic_Diagnostic_Index_Entry;
      Base_Item  : Base_Prov.Diagnostic_Provenance_Item) return Final_Provenance_Info is
      Blocker : constant Final_Blocker_Family := Blocker_For (Diagnostic);
      Status  : constant Final_Provenance_Status := Status_For (Diagnostic);
      Row     : Final_Provenance_Info;
   begin
      Row.Id := Final_Provenance_Id (Row_Index);
      Row.Final_Diagnostic := Diagnostic.Id;
      Row.Final_Status := Diagnostic.Status;
      Row.Final_Family := Diagnostic.Family;
      Row.Blocker_Family := Blocker;
      Row.Status := Status;
      Row.Stage := Stage_For (Status);
      Row.Severity := Severity_For (Diagnostic);
      Row.Node := Diagnostic.Node;
      Row.Message := To_Unbounded_String (Message_For (Diagnostic, Status, Blocker));
      Row.Chain_Summary := To_Unbounded_String
        ("final=" & Final_Diag.Final_Diagnostic_Id'Image (Diagnostic.Id) &
         "; status=" & Final_Diag.Final_Diagnostic_Status'Image (Diagnostic.Status) &
         "; family=" & Final_Diag.Final_Diagnostic_Source_Family'Image (Diagnostic.Family) &
         "; blocker=" & Final_Blocker_Family'Image (Blocker));
      Row.Start_Line := Diagnostic.Start_Line;
      Row.Start_Column := Diagnostic.Start_Column;
      Row.End_Line := Diagnostic.End_Line;
      Row.End_Column := Diagnostic.End_Column;
      Row.Source_Fingerprint := Diagnostic.Source_Fingerprint;
      Row.Diagnostic_Fingerprint := Diagnostic.Fingerprint;

      if Feed_Item.Id /= Feed.No_Semantic_Diagnostic_Feed_Entry then
         Row.Feed_Entry := Feed_Item.Id;
         Row.Feed_Fingerprint := Feed_Item.Fingerprint;
         Row.Stage := Final_Stage_Unified_Feed;
      end if;

      if Index_Item.Id /= Index.No_Semantic_Diagnostic_Index_Entry then
         Row.Index_Entry := Index_Item.Id;
         Row.Index_Fingerprint := Index_Item.Fingerprint;
         Row.Stage := Final_Stage_Index;
      end if;

      if Base_Prov.Has_Item (Base_Item) then
         Row.Base_Provenance := Base_Item.Id;
         Row.Base_Stage := Base_Item.Root_Stage;
         Row.Base_Fingerprint := Base_Item.Fingerprint;
         Row.Stage := Final_Stage_Base_Provenance;
      end if;

      Row.Fingerprint := Entry_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Final_Provenance_Model) is
   begin
      Model.Rows.Clear;
      Model.Withheld_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.View_Barrier_Total := 0;
      Model.Stale_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Multiple_Blocker_Total := 0;
      Model.Feed_Link_Total := 0;
      Model.Index_Link_Total := 0;
      Model.Base_Link_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Row
     (Model : in out Final_Provenance_Model;
      Row   : Final_Provenance_Info) is
   begin
      Model.Rows.Append (Row);
      case Row.Status is
         when Final_Provenance_Withheld_Legal =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
         when Final_Provenance_Emitted_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Provenance_Emitted_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Final_Provenance_View_Barrier =>
            Model.View_Barrier_Total := Model.View_Barrier_Total + 1;
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Provenance_Stale_Rejected =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Provenance_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            Model.Warning_Total := Model.Warning_Total + 1;
         when Final_Provenance_Multiple_Blockers =>
            Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Provenance_Not_Checked =>
            null;
      end case;
      if Row.Feed_Entry /= Feed.No_Semantic_Diagnostic_Feed_Entry then
         Model.Feed_Link_Total := Model.Feed_Link_Total + 1;
      end if;
      if Row.Index_Entry /= Index.No_Semantic_Diagnostic_Index_Entry then
         Model.Index_Link_Total := Model.Index_Link_Total + 1;
      end if;
      if Row.Base_Provenance /= Base_Prov.No_Diagnostic_Provenance then
         Model.Base_Link_Total := Model.Base_Link_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Add_Row;

   function Build
     (Diagnostics : Final_Diag.Final_Diagnostic_Model)
      return Final_Provenance_Model is
      Empty_Feed  : Feed.Semantic_Diagnostic_Feed_Entry;
      Empty_Index : Index.Semantic_Diagnostic_Index_Entry;
      Empty_Base  : Base_Prov.Diagnostic_Provenance_Item;
      Result      : Final_Provenance_Model;
   begin
      for I in 1 .. Final_Diag.Row_Count (Diagnostics) loop
         Add_Row
           (Result,
            Make_Row
              (Final_Diag.Row_At (Diagnostics, I),
               I,
               Empty_Feed,
               Empty_Index,
               Empty_Base));
      end loop;
      Result.Fingerprint := Mix (Result.Fingerprint, Final_Diag.Fingerprint (Diagnostics));
      return Result;
   end Build;

   function Build_With_Feed_And_Index
     (Diagnostics : Final_Diag.Final_Diagnostic_Model;
      Feed_Model  : Feed.Semantic_Diagnostic_Feed_Model;
      Index_Model : Index.Semantic_Diagnostic_Index_Model)
      return Final_Provenance_Model is
      Empty_Base : Base_Prov.Diagnostic_Provenance_Item;
      Result     : Final_Provenance_Model;
   begin
      for I in 1 .. Final_Diag.Row_Count (Diagnostics) loop
         declare
            D  : constant Final_Diag.Final_Diagnostic_Info := Final_Diag.Row_At (Diagnostics, I);
            FE : constant Feed.Semantic_Diagnostic_Feed_Entry := Matching_Feed (Feed_Model, D);
            IX : constant Index.Semantic_Diagnostic_Index_Entry := Matching_Index (Index_Model, D);
         begin
            Add_Row (Result, Make_Row (D, I, FE, IX, Empty_Base));
         end;
      end loop;
      Result.Fingerprint := Mix (Result.Fingerprint, Final_Diag.Fingerprint (Diagnostics));
      Result.Fingerprint := Mix (Result.Fingerprint, Feed.Fingerprint (Feed_Model));
      Result.Fingerprint := Mix (Result.Fingerprint, Index.Fingerprint (Index_Model));
      return Result;
   end Build_With_Feed_And_Index;

   function Build_With_Base_Provenance
     (Diagnostics : Final_Diag.Final_Diagnostic_Model;
      Feed_Model  : Feed.Semantic_Diagnostic_Feed_Model;
      Index_Model : Index.Semantic_Diagnostic_Index_Model;
      Provenance  : Base_Prov.Diagnostic_Provenance_Model)
      return Final_Provenance_Model is
      Result : Final_Provenance_Model;
   begin
      for I in 1 .. Final_Diag.Row_Count (Diagnostics) loop
         declare
            D  : constant Final_Diag.Final_Diagnostic_Info := Final_Diag.Row_At (Diagnostics, I);
            FE : constant Feed.Semantic_Diagnostic_Feed_Entry := Matching_Feed (Feed_Model, D);
            IX : constant Index.Semantic_Diagnostic_Index_Entry := Matching_Index (Index_Model, D);
            BP : constant Base_Prov.Diagnostic_Provenance_Item := Matching_Base (Provenance, D);
         begin
            Add_Row (Result, Make_Row (D, I, FE, IX, BP));
         end;
      end loop;
      Result.Fingerprint := Mix (Result.Fingerprint, Final_Diag.Fingerprint (Diagnostics));
      Result.Fingerprint := Mix (Result.Fingerprint, Feed.Fingerprint (Feed_Model));
      Result.Fingerprint := Mix (Result.Fingerprint, Index.Fingerprint (Index_Model));
      Result.Fingerprint := Mix (Result.Fingerprint, Base_Prov.Fingerprint (Provenance));
      return Result;
   end Build_With_Base_Provenance;

   function Row_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Provenance_Model;
      Index : Positive) return Final_Provenance_Info is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Rows_For_Status
     (Model  : Final_Provenance_Model;
      Status : Final_Provenance_Status) return Final_Provenance_Set is
      Result : Final_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Blocker
     (Model   : Final_Provenance_Model;
      Blocker : Final_Blocker_Family) return Final_Provenance_Set is
      Result : Final_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Blocker;

   function Rows_For_Stage
     (Model : Final_Provenance_Model;
      Stage : Final_Provenance_Stage) return Final_Provenance_Set is
      Result : Final_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Stage = Stage then
            Result.Rows.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Stage;

   function First_For_Node
     (Model : Final_Provenance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Provenance_Info is
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Set_Count (Set : Final_Provenance_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Set_Count;

   function Set_At
     (Set   : Final_Provenance_Set;
      Index : Positive) return Final_Provenance_Info is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Set_At;

   function Count_Status
     (Model  : Final_Provenance_Model;
      Status : Final_Provenance_Status) return Natural is
   begin
      return Set_Count (Rows_For_Status (Model, Status));
   end Count_Status;

   function Count_Blocker
     (Model   : Final_Provenance_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Set_Count (Rows_For_Blocker (Model, Blocker));
   end Count_Blocker;

   function Count_Stage
     (Model : Final_Provenance_Model;
      Stage : Final_Provenance_Stage) return Natural is
   begin
      return Set_Count (Rows_For_Stage (Model, Stage));
   end Count_Stage;

   function Withheld_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Error_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function View_Barrier_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.View_Barrier_Total;
   end View_Barrier_Count;

   function Stale_Rejected_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Rejected_Count;

   function Indeterminate_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Multiple_Blocker_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Count;

   function Feed_Link_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Feed_Link_Total;
   end Feed_Link_Count;

   function Index_Link_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Index_Link_Total;
   end Index_Link_Count;

   function Base_Link_Count (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Base_Link_Total;
   end Base_Link_Count;

   function Fingerprint (Model : Final_Provenance_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Diagnostic_Provenance;
