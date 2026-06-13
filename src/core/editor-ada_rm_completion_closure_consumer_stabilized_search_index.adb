package body Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Search_Index is

   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Status;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Stage;
   use type Prov.RM_Closure_Consumer_Stabilized_Provenance_Blocker;
   use type Prov.RM_Closure_Consumer_Stabilized_Diagnostic_Status;
   use type Prov.RM_Closure_Consumer_Stabilized_Diagnostic_Family;
   use type Prov.RM_Closure_Consumer_Closure_Family;
   use type Prov.Diag.RM_Closure_Consumer_Stabilized_Closure_Id;
   use type Prov.Diag.Closure.Gate.RM_Closure_Consumer_Stabilization_Gate_Id;
   use type Prov.Diag.Closure.Gate.Conv.RM_Closure_Consumer_Convergence_Id;
   use type Prov.Diag.Closure.Gate.Conv.Apply.RM_Closure_Consumer_Application_Id;
   use type Prov.Diag.Closure.Gate.Conv.Apply.Recheck.RM_Closure_Consumer_Recheck_Id;
   use type Prov.Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.RM_Closure_Consumer_Worklist_Id;
   use type Prov.Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.RM_Closure_Consumer_Diagnostic_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 263) + B + 1283) mod 2_147_483_647;
   end Mix;

   function Full_Chain (Row : Prov.RM_Closure_Consumer_Stabilized_Provenance_Row) return Boolean is
   begin
      return Row.Closure_Id /= Prov.Diag.Closure.No_RM_Closure_Consumer_Stabilized_Closure
        and then Row.Stabilization_Id /= Prov.Diag.Closure.Gate.No_RM_Closure_Consumer_Stabilization_Gate
        and then Row.Convergence_Id /= Prov.Diag.Closure.Gate.Conv.No_RM_Closure_Consumer_Convergence
        and then Row.Application_Id /= Prov.Diag.Closure.Gate.Conv.Apply.No_RM_Closure_Consumer_Application
        and then Row.Eligibility_Id /= Prov.Diag.Closure.Gate.Conv.Apply.Recheck.No_RM_Closure_Consumer_Recheck
        and then Row.Worklist_Item /= Prov.Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.No_RM_Closure_Consumer_Worklist_Item
        and then Row.Original_Diagnostic /= Prov.Diag.Closure.Gate.Conv.Apply.Recheck.Worklist.Diagnostics.No_RM_Closure_Consumer_Diagnostic;
   end Full_Chain;

   function Entry_Fingerprint (Feed_Item : RM_Closure_Consumer_Stabilized_Search_Entry) return Natural is
      H : Natural := Natural (Feed_Item.Id);
   begin
      H := Mix (H, Feed_Item.Provenance_Index + 1);
      H := Mix (H, Natural (Feed_Item.Provenance_Id) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilized_Provenance_Status'Pos (Feed_Item.Status) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilized_Provenance_Stage'Pos (Feed_Item.Stage) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilized_Provenance_Blocker'Pos (Feed_Item.Blocker) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilized_Diagnostic_Status'Pos (Feed_Item.Diagnostic_Status) + 1);
      H := Mix (H, RM_Closure_Consumer_Stabilized_Diagnostic_Family'Pos (Feed_Item.Diagnostic_Family) + 1);
      H := Mix (H, RM_Closure_Consumer_Closure_Family'Pos (Feed_Item.Closure_Family) + 1);
      H := Mix (H, Natural (Feed_Item.Node) + 1);
      H := Mix (H, Feed_Item.Source_Fingerprint + 1);
      H := Mix (H, Feed_Item.Substitution_Fingerprint + 1);
      H := Mix (H, Feed_Item.Semantic_Fingerprint + 1);
      H := Mix (H, Feed_Item.Diagnostic_Fingerprint + 1);
      H := Mix (H, Feed_Item.Closure_Fingerprint + 1);
      H := Mix (H, Feed_Item.Provenance_Fingerprint + 1);
      H := Mix (H, Feed_Item.Start_Line);
      H := Mix (H, Feed_Item.Start_Column);
      H := Mix (H, Feed_Item.End_Line);
      H := Mix (H, Feed_Item.End_Column);
      if Feed_Item.Emitted then
         H := Mix (H, 3);
      end if;
      if Feed_Item.Withheld_Current then
         H := Mix (H, 5);
      end if;
      if Feed_Item.Requires_Recheck then
         H := Mix (H, 7);
      end if;
      if Feed_Item.Blocks_Downstream then
         H := Mix (H, 11);
      end if;
      if Feed_Item.Full_Chain_Linked then
         H := Mix (H, 13);
      end if;
      return H;
   end Entry_Fingerprint;

   function Overlaps_Line_Range
     (Feed_Item      : RM_Closure_Consumer_Stabilized_Search_Entry;
      Start_Line : Positive;
      End_Line   : Positive) return Boolean
   is
      First_Line : constant Positive := Positive'Min (Start_Line, End_Line);
      Last_Line  : constant Positive := Positive'Max (Start_Line, End_Line);
   begin
      return Feed_Item.Start_Line <= Last_Line and then Feed_Item.End_Line >= First_Line;
   end Overlaps_Line_Range;

   function Contains_Position
     (Feed_Item  : RM_Closure_Consumer_Stabilized_Search_Entry;
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
     (Set   : in out RM_Closure_Consumer_Stabilized_Search_Result_Set;
      Index : Natural;
      Feed_Item : RM_Closure_Consumer_Stabilized_Search_Entry) is
   begin
      Set.Results.Append
        ((Index_Row        => Index,
          Provenance_Index => Feed_Item.Provenance_Index,
          Feed_Item            => Feed_Item));
      Set.Fingerprint := Mix (Set.Fingerprint, Feed_Item.Fingerprint + Index + 1);
   end Append_Result;

   procedure Accumulate
     (Model : in out RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Feed_Item : RM_Closure_Consumer_Stabilized_Search_Entry) is
   begin
      if Feed_Item.Withheld_Current then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;
      if Feed_Item.Emitted then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      end if;
      case Feed_Item.Status is
         when Prov.RM_Closure_Consumer_Stabilized_Provenance_Emitted_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Prov.RM_Closure_Consumer_Stabilized_Provenance_Emitted_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Prov.RM_Closure_Consumer_Stabilized_Provenance_Recheck_Required =>
            Model.Recheck_Total := Model.Recheck_Total + 1;
         when Prov.RM_Closure_Consumer_Stabilized_Provenance_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when Prov.RM_Closure_Consumer_Stabilized_Provenance_Multiple_Prerequisites =>
            Model.Multiple_Total := Model.Multiple_Total + 1;
         when others =>
            null;
      end case;
      if Feed_Item.Full_Chain_Linked then
         Model.Full_Chain_Link_Total := Model.Full_Chain_Link_Total + 1;
      end if;
   end Accumulate;

   function Make_Entry
     (Row   : Prov.RM_Closure_Consumer_Stabilized_Provenance_Row;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Search_Entry is
      Feed_Item : RM_Closure_Consumer_Stabilized_Search_Entry;
   begin
      Feed_Item.Id := RM_Closure_Consumer_Stabilized_Search_Index_Id (Index);
      Feed_Item.Provenance_Index := Index;
      Feed_Item.Provenance := Row;
      Feed_Item.Provenance_Id := Row.Id;
      Feed_Item.Status := Row.Status;
      Feed_Item.Stage := Row.Stage;
      Feed_Item.Blocker := Row.Blocker;
      Feed_Item.Diagnostic_Status := Row.Diagnostic_Status;
      Feed_Item.Diagnostic_Family := Row.Diagnostic_Family;
      Feed_Item.Closure_Family := Row.Closure_Family;
      Feed_Item.Node := Row.Node;
      Feed_Item.Source_Fingerprint := Row.Source_Fingerprint;
      Feed_Item.Substitution_Fingerprint := Row.Substitution_Fingerprint;
      Feed_Item.Semantic_Fingerprint := Row.Semantic_Fingerprint;
      Feed_Item.Diagnostic_Fingerprint := Row.Diagnostic_Fingerprint;
      Feed_Item.Closure_Fingerprint := Row.Closure_Fingerprint;
      Feed_Item.Provenance_Fingerprint := Row.Provenance_Fingerprint;
      Feed_Item.Emitted := Row.Emitted;
      Feed_Item.Withheld_Current := Row.Withheld_Current;
      Feed_Item.Requires_Recheck := Row.Requires_Recheck;
      Feed_Item.Blocks_Downstream := Row.Blocks_Downstream;
      Feed_Item.Full_Chain_Linked := Full_Chain (Row);
      Feed_Item.Start_Line := Row.Start_Line;
      Feed_Item.Start_Column := Row.Start_Column;
      Feed_Item.End_Line := Row.End_Line;
      Feed_Item.End_Column := Row.End_Column;
      Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);
      return Feed_Item;
   end Make_Entry;

   procedure Clear (Model : in out RM_Closure_Consumer_Stabilized_Search_Index_Model) is
   begin
      Model.Entries.Clear;
      Model.Withheld_Total := 0;
      Model.Emitted_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Recheck_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Multiple_Total := 0;
      Model.Full_Chain_Link_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Provenance : Prov.RM_Closure_Consumer_Stabilized_Provenance_Model)
      return RM_Closure_Consumer_Stabilized_Search_Index_Model
   is
      Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Feed_Item : RM_Closure_Consumer_Stabilized_Search_Entry;
   begin
      for I in 1 .. Prov.Row_Count (Provenance) loop
         Feed_Item := Make_Entry (Prov.Row_At (Provenance, I), I);
         Model.Entries.Append (Feed_Item);
         Accumulate (Model, Feed_Item);
         Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
      end loop;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Prov.Fingerprint (Provenance));
      return Model;
   end Build;

   function Entry_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Index : Positive) return RM_Closure_Consumer_Stabilized_Search_Entry is
   begin
      if Index > Entry_Count (Model) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Entry_At;

   function Query_Count (Results : RM_Closure_Consumer_Stabilized_Search_Result_Set) return Natural is
   begin
      return Natural (Results.Results.Length);
   end Query_Count;

   function Query_At
     (Results : RM_Closure_Consumer_Stabilized_Search_Result_Set;
      Index   : Positive) return RM_Closure_Consumer_Stabilized_Search_Result is
   begin
      if Index > Query_Count (Results) then
         return (others => <>);
      end if;
      return Results.Results.Element (Index);
   end Query_At;

   function Query_Blocker
     (Model   : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Blocker = Blocker then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Blocker;

   function Query_Status
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Status : RM_Closure_Consumer_Stabilized_Provenance_Status)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Status = Status then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Status;

   function Query_Diagnostic_Status
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Diagnostic_Status = Status then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Diagnostic_Status;

   function Query_Diagnostic_Family
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Diagnostic_Family = Family then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Diagnostic_Family;

   function Query_Closure_Family
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Family : RM_Closure_Consumer_Closure_Family)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Closure_Family = Family then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Closure_Family;

   function Query_Stage
     (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Stage : RM_Closure_Consumer_Stabilized_Provenance_Stage)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Stage = Stage then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Stage;

   function Query_Node
     (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Node = Node then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Node;

   function Query_Range
     (Model      : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Start_Line : Positive;
      End_Line   : Positive) return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Overlaps_Line_Range (Feed_Item, Start_Line, End_Line) then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Range;

   function Query_Position
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Line   : Positive;
      Column : Positive) return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Contains_Position (Feed_Item, Line, Column) then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Position;

   function Query_Source_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Source_Fingerprint = Fingerprint then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Query_Substitution_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Substitution_Fingerprint = Fingerprint then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Substitution_Fingerprint;

   function Query_Provenance_Fingerprint
     (Model       : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Fingerprint : Natural) return RM_Closure_Consumer_Stabilized_Search_Result_Set is
      Set : RM_Closure_Consumer_Stabilized_Search_Result_Set;
   begin
      for I in 1 .. Entry_Count (Model) loop
         declare
            Feed_Item : constant RM_Closure_Consumer_Stabilized_Search_Entry := Model.Entries.Element (I);
         begin
            if Feed_Item.Provenance_Fingerprint = Fingerprint then
               Append_Result (Set, I, Feed_Item);
            end if;
         end;
      end loop;
      return Set;
   end Query_Provenance_Fingerprint;

   function Has_Blocker_At
     (Model   : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Line    : Positive;
      Column  : Positive;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker) return Boolean
   is
      Hits : constant RM_Closure_Consumer_Stabilized_Search_Result_Set := Query_Position (Model, Line, Column);
   begin
      for I in 1 .. Query_Count (Hits) loop
         if Query_At (Hits, I).Feed_Item.Blocker = Blocker then
            return True;
         end if;
      end loop;
      return False;
   end Has_Blocker_At;

   function Count_Blocker
     (Model   : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Blocker : RM_Closure_Consumer_Stabilized_Provenance_Blocker) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Count_Status
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Status : RM_Closure_Consumer_Stabilized_Provenance_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Diagnostic_Status
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Status : RM_Closure_Consumer_Stabilized_Diagnostic_Status) return Natural is
   begin
      return Query_Count (Query_Diagnostic_Status (Model, Status));
   end Count_Diagnostic_Status;

   function Count_Diagnostic_Family
     (Model  : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Family : RM_Closure_Consumer_Stabilized_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Diagnostic_Family (Model, Family));
   end Count_Diagnostic_Family;

   function Count_Stage
     (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Stage : RM_Closure_Consumer_Stabilized_Provenance_Stage) return Natural is
   begin
      return Query_Count (Query_Stage (Model, Stage));
   end Count_Stage;

   function Withheld_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Emitted_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Error_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Recheck_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Count;

   function Indeterminate_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Multiple_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Multiple_Total;
   end Multiple_Count;

   function Full_Chain_Link_Count (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Full_Chain_Link_Total;
   end Full_Chain_Link_Count;

   function Fingerprint (Model : RM_Closure_Consumer_Stabilized_Search_Index_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Search_Index;
