package body Editor.Ada_Final_Semantic_Diagnostic_Search_Index is

   pragma Suppress (Overflow_Check);

   use type Final_Prov.Final_Blocker_Family;
   use type Final_Prov.Final_Provenance_Status;
   use type Final_Prov.Final_Provenance_Stage;
   use type Final_Diag.Final_Diagnostic_Status;
   use type Feed.Semantic_Diagnostic_Feed_Id;
   use type Base_Index.Semantic_Diagnostic_Index_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 149) + B + 97) mod 1_000_000_007;
   end Mix;

   function Entry_Fingerprint (Feed_Item : Final_Search_Entry) return Natural is
      H : Natural := Natural (Feed_Item.Id);
   begin
      H := Mix (H, Feed_Item.Provenance_Index + 1);
      H := Mix (H, Natural (Feed_Item.Provenance.Id) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Feed_Item.Blocker_Family) + 1);
      H := Mix (H, Final_Provenance_Status'Pos (Feed_Item.Provenance_Status) + 1);
      H := Mix (H, Final_Provenance_Stage'Pos (Feed_Item.Provenance_Stage) + 1);
      H := Mix (H, Final_Diagnostic_Status'Pos (Feed_Item.Final_Status) + 1);
      H := Mix (H, Natural (Feed_Item.Node) + 1);
      H := Mix (H, Natural (Feed_Item.Feed_Entry) + 1);
      H := Mix (H, Natural (Feed_Item.Index_Entry) + 1);
      H := Mix (H, Feed_Item.Start_Line);
      H := Mix (H, Feed_Item.Start_Column);
      H := Mix (H, Feed_Item.End_Line);
      H := Mix (H, Feed_Item.End_Column);
      H := Mix (H, Feed_Item.Source_Fingerprint + 1);
      H := Mix (H, Feed_Item.Provenance.Fingerprint + 1);
      return H;
   end Entry_Fingerprint;

   function Overlaps_Line_Range
     (Feed_Item      : Final_Search_Entry;
      Start_Line : Positive;
      End_Line   : Positive) return Boolean
   is
      First_Line : constant Positive := Positive'Min (Start_Line, End_Line);
      Last_Line  : constant Positive := Positive'Max (Start_Line, End_Line);
   begin
      return Feed_Item.Start_Line <= Last_Line and then Feed_Item.End_Line >= First_Line;
   end Overlaps_Line_Range;

   function Contains_Position
     (Feed_Item  : Final_Search_Entry;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      if Line < Feed_Item.Start_Line or else Line > Feed_Item.End_Line then
         return False;
      end if;

      if Line = Feed_Item.Start_Line and then Column < Feed_Item.Start_Column then
         return False;
      end if;

      if Line = Feed_Item.End_Line and then Column > Feed_Item.End_Column then
         return False;
      end if;

      return True;
   end Contains_Position;

   procedure Append_Result
     (Set   : in out Final_Search_Result_Set;
      Index : Natural;
      Feed_Item : Final_Search_Entry) is
   begin
      Set.Results.Append
        (Final_Search_Result'
           (Index_Row        => Index,
            Provenance_Index => Feed_Item.Provenance_Index,
            Feed_Item        => Feed_Item));
      Set.Fingerprint := Mix (Set.Fingerprint, Feed_Item.Fingerprint + Index + 1);
   end Append_Result;

   procedure Accumulate (Model : in out Final_Search_Index_Model; Feed_Item : Final_Search_Entry) is
   begin
      case Feed_Item.Provenance_Status is
         when Final_Prov.Final_Provenance_Withheld_Legal =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
         when Final_Prov.Final_Provenance_Emitted_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Prov.Final_Provenance_Emitted_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Final_Prov.Final_Provenance_Stale_Rejected =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Prov.Final_Provenance_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when Final_Prov.Final_Provenance_Multiple_Blockers =>
            Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
         when others =>
            null;
      end case;

      if Feed_Item.Feed_Entry /= Feed.No_Semantic_Diagnostic_Feed_Entry then
         Model.Feed_Link_Total := Model.Feed_Link_Total + 1;
      end if;

      if Feed_Item.Index_Entry /= Base_Index.No_Semantic_Diagnostic_Index_Entry then
         Model.Index_Link_Total := Model.Index_Link_Total + 1;
      end if;
   end Accumulate;

   procedure Clear (Model : in out Final_Search_Index_Model) is
   begin
      Model.Entries.Clear;
      Model.Index_Status := Final_Search_Index_Current;
      Model.Withheld_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Stale_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Multiple_Blocker_Total := 0;
      Model.Feed_Link_Total := 0;
      Model.Index_Link_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Provenance : Final_Prov.Final_Provenance_Model)
      return Final_Search_Index_Model
   is
      Model : Final_Search_Index_Model;
   begin
      Model.Stale_Total := Final_Prov.Stale_Rejected_Count (Provenance);
      if Final_Prov.Row_Count (Provenance) = 0
        and then Model.Stale_Total > 0
      then
         Model.Index_Status := Final_Search_Index_Rejected_Stale;
         Model.Result_Fingerprint := Mix (Final_Prov.Fingerprint (Provenance), Model.Stale_Total + 1);
         return Model;
      end if;

      for Index in 1 .. Final_Prov.Row_Count (Provenance) loop
         declare
            Source : constant Final_Prov.Final_Provenance_Info :=
              Final_Prov.Row_At (Provenance, Index);
            Feed_Item  : Final_Search_Entry;
         begin
            Feed_Item.Id := Final_Search_Index_Id (Index);
            Feed_Item.Provenance_Index := Index;
            Feed_Item.Provenance := Source;
            Feed_Item.Blocker_Family := Source.Blocker_Family;
            Feed_Item.Provenance_Status := Source.Status;
            Feed_Item.Provenance_Stage := Source.Stage;
            Feed_Item.Final_Status := Source.Final_Status;
            Feed_Item.Node := Source.Node;
            Feed_Item.Feed_Entry := Source.Feed_Entry;
            Feed_Item.Index_Entry := Source.Index_Entry;
            Feed_Item.Start_Line := Source.Start_Line;
            Feed_Item.Start_Column := Source.Start_Column;
            Feed_Item.End_Line := Source.End_Line;
            Feed_Item.End_Column := Source.End_Column;
            Feed_Item.Source_Fingerprint := Source.Source_Fingerprint;
            Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);
            Model.Entries.Append (Feed_Item);
            Accumulate (Model, Feed_Item);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
         end;
      end loop;

      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Final_Prov.Fingerprint (Provenance));
      return Model;
   end Build;

   function Status (Model : Final_Search_Index_Model) return Final_Search_Index_Status is
   begin
      return Model.Index_Status;
   end Status;

   function Current (Model : Final_Search_Index_Model) return Boolean is
   begin
      return Model.Index_Status = Final_Search_Index_Current;
   end Current;

   function Rejected_Stale (Model : Final_Search_Index_Model) return Boolean is
   begin
      return Model.Index_Status = Final_Search_Index_Rejected_Stale;
   end Rejected_Stale;

   function Entry_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : Final_Search_Index_Model;
      Index : Positive) return Final_Search_Entry
   is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Entry_At;

   function Query_Count (Results : Final_Search_Result_Set) return Natural is
   begin
      return Natural (Results.Results.Length);
   end Query_Count;

   function Query_At
     (Results : Final_Search_Result_Set;
      Index   : Positive) return Final_Search_Result
   is
   begin
      if Index > Natural (Results.Results.Length) then
         return (others => <>);
      end if;
      return Results.Results.Element (Index);
   end Query_At;

   function Query_Blocker
     (Model   : Final_Search_Index_Model;
      Blocker : Final_Blocker_Family) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Feed_Item.Blocker_Family = Blocker then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Blocker;

   function Query_Provenance_Status
     (Model  : Final_Search_Index_Model;
      Status : Final_Provenance_Status) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Feed_Item.Provenance_Status = Status then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Provenance_Status;

   function Query_Final_Status
     (Model  : Final_Search_Index_Model;
      Status : Final_Diagnostic_Status) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Feed_Item.Final_Status = Status then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Final_Status;

   function Query_Stage
     (Model : Final_Search_Index_Model;
      Stage : Final_Provenance_Stage) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Feed_Item.Provenance_Stage = Stage then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Stage;

   function Query_Node
     (Model : Final_Search_Index_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Feed_Item.Node = Node then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Node;

   function Query_Range
     (Model      : Final_Search_Index_Model;
      Start_Line : Positive;
      End_Line   : Positive) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Overlaps_Line_Range (Feed_Item, Start_Line, End_Line) then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Range;

   function Query_Position
     (Model  : Final_Search_Index_Model;
      Line   : Positive;
      Column : Positive) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Contains_Position (Feed_Item, Line, Column) then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Position;

   function Query_Source_Fingerprint
     (Model       : Final_Search_Index_Model;
      Fingerprint : Natural) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Feed_Item.Source_Fingerprint = Fingerprint then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Query_Feed_Link
     (Model : Final_Search_Index_Model;
      Link  : Feed.Semantic_Diagnostic_Feed_Id) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Feed_Item.Feed_Entry = Link then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Feed_Link;

   function Query_Index_Link
     (Model : Final_Search_Index_Model;
      Link  : Base_Index.Semantic_Diagnostic_Index_Id) return Final_Search_Result_Set
   is
      Set : Final_Search_Result_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Index in 1 .. Natural (Model.Entries.Length) loop
         declare
            Feed_Item : constant Final_Search_Entry := Model.Entries.Element (Index);
         begin
            if Feed_Item.Index_Entry = Link then
               Append_Result (Set, Index, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Index_Link;

   function Has_Blocker_At
     (Model   : Final_Search_Index_Model;
      Line    : Positive;
      Column  : Positive;
      Blocker : Final_Blocker_Family) return Boolean
   is
      Hits : constant Final_Search_Result_Set := Query_Position (Model, Line, Column);
   begin
      for Index in 1 .. Query_Count (Hits) loop
         if Query_At (Hits, Index).Feed_Item.Blocker_Family = Blocker then
            return True;
         end if;
      end loop;
      return False;
   end Has_Blocker_At;

   function Count_Blocker
     (Model   : Final_Search_Index_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Count_Provenance_Status
     (Model  : Final_Search_Index_Model;
      Status : Final_Provenance_Status) return Natural is
   begin
      return Query_Count (Query_Provenance_Status (Model, Status));
   end Count_Provenance_Status;

   function Count_Final_Status
     (Model  : Final_Search_Index_Model;
      Status : Final_Diagnostic_Status) return Natural is
   begin
      return Query_Count (Query_Final_Status (Model, Status));
   end Count_Final_Status;

   function Count_Stage
     (Model : Final_Search_Index_Model;
      Stage : Final_Provenance_Stage) return Natural is
   begin
      return Query_Count (Query_Stage (Model, Stage));
   end Count_Stage;

   function Withheld_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Emitted_Error_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Error_Total;
   end Emitted_Error_Count;

   function Emitted_Warning_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Emitted_Warning_Count;

   function Stale_Rejected_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Rejected_Count;

   function Indeterminate_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Multiple_Blocker_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Count;

   function Feed_Link_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Feed_Link_Total;
   end Feed_Link_Count;

   function Index_Link_Count (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Index_Link_Total;
   end Index_Link_Count;

   function Fingerprint (Model : Final_Search_Index_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Diagnostic_Search_Index;
