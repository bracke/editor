package body Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index is

   use type Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Status;
   use type Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage;
   use type Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker;
   use type Prov.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status;
   use type Prov.Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family;
   use type Prov.Remaining_RM_Edge_Stabilized_Closure_Family;
   use type Prov.Remaining_RM_Edge_Kind;
   use type Prov.Remaining_RM_Edge_Blocker_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 269) + B + 1294) mod 2_147_483_647;
   end Mix;

   function Entry_Fingerprint
     (Item : Remaining_RM_Edge_Stabilized_Closure_Search_Entry) return Natural
   is
      H : Natural := Natural (Item.Id);
   begin
      H := Mix (H, Item.Provenance_Index + 1);
      H := Mix (H, Natural (Item.Provenance_Id) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Provenance_Status'Pos (Item.Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage'Pos (Item.Stage) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker'Pos (Item.Blocker) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status'Pos (Item.Diagnostic_Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family'Pos (Item.Diagnostic_Family) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Closure_Family'Pos (Item.Closure_Family) + 1);
      H := Mix (H, Remaining_RM_Edge_Kind'Pos (Item.Remaining_Edge_Kind) + 1);
      H := Mix (H, Remaining_RM_Edge_Blocker_Family'Pos (Item.Remaining_Edge_Blocker) + 1);
      H := Mix (H, Natural (Item.Node) + 1);
      H := Mix (H, Item.Source_Fingerprint + 1);
      H := Mix (H, Item.Substitution_Fingerprint + 1);
      H := Mix (H, Item.Edge_Fingerprint + 1);
      H := Mix (H, Item.Consumer_Closure_Fingerprint + 1);
      H := Mix (H, Item.Diagnostic_Fingerprint + 1);
      H := Mix (H, Item.Closure_Fingerprint + 1);
      H := Mix (H, Item.Provenance_Fingerprint + 1);
      H := Mix (H, Item.Start_Line);
      H := Mix (H, Item.Start_Column);
      H := Mix (H, Item.End_Line);
      H := Mix (H, Item.End_Column);
      if Item.Emitted then
         H := Mix (H, 3);
      end if;
      if Item.Withheld_Current then
         H := Mix (H, 5);
      end if;
      if Item.Requires_Recheck then
         H := Mix (H, 7);
      end if;
      if Item.Blocks_Downstream then
         H := Mix (H, 11);
      end if;
      if Item.Full_Chain_Linked then
         H := Mix (H, 13);
      end if;
      return H;
   end Entry_Fingerprint;

   function Overlaps_Line_Range
     (Item       : Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
      Start_Line : Positive;
      End_Line   : Positive) return Boolean
   is
      First_Line : constant Positive := Positive'Min (Start_Line, End_Line);
      Last_Line  : constant Positive := Positive'Max (Start_Line, End_Line);
   begin
      return Item.Start_Line <= Last_Line and then Item.End_Line >= First_Line;
   end Overlaps_Line_Range;

   function Contains_Position
     (Item   : Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      if Line < Item.Start_Line or else Line > Item.End_Line then
         return False;
      end if;
      if Line = Item.Start_Line and then Column < Item.Start_Column then
         return False;
      end if;
      if Line = Item.End_Line and then Column > Item.End_Column then
         return False;
      end if;
      return True;
   end Contains_Position;

   procedure Append_Result
     (Set   : in out Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      Index : Natural;
      Item : Remaining_RM_Edge_Stabilized_Closure_Search_Entry) is
   begin
      Set.Results.Append
        ((Index_Row        => Index,
          Provenance_Index => Item.Provenance_Index,
          Search_Entry     => Item));
      Set.Fingerprint := Mix (Set.Fingerprint, Item.Fingerprint + Index + 1);
   end Append_Result;

   procedure Accumulate
     (Model : in out Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Item : Remaining_RM_Edge_Stabilized_Closure_Search_Entry) is
   begin
      if Item.Withheld_Current then
         Model.Withheld_Total := Model.Withheld_Total + 1;
      end if;
      if Item.Emitted then
         Model.Emitted_Total := Model.Emitted_Total + 1;
      end if;
      case Item.Status is
         when Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Emitted_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Recheck_Required =>
            Model.Recheck_Total := Model.Recheck_Total + 1;
         when Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Multiple_Prerequisites =>
            Model.Multiple_Total := Model.Multiple_Total + 1;
         when others =>
            null;
      end case;
      if Item.Full_Chain_Linked then
         Model.Full_Chain_Link_Total := Model.Full_Chain_Link_Total + 1;
      end if;
   end Accumulate;

   function Make_Entry
     (Row   : Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Row;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Entry
   is
      Item : Remaining_RM_Edge_Stabilized_Closure_Search_Entry;
   begin
      Item.Id := Remaining_RM_Edge_Stabilized_Closure_Search_Index_Id (Index);
      Item.Provenance_Index := Index;
      Item.Provenance := Row;
      Item.Provenance_Id := Row.Id;
      Item.Status := Row.Status;
      Item.Stage := Row.Stage;
      Item.Blocker := Row.Blocker;
      Item.Diagnostic_Status := Row.Diagnostic_Status;
      Item.Diagnostic_Family := Row.Diagnostic_Family;
      Item.Closure_Family := Row.Closure_Family;
      Item.Remaining_Edge_Kind := Row.Remaining_Edge_Kind;
      Item.Remaining_Edge_Blocker := Row.Remaining_Edge_Blocker;
      Item.Node := Row.Node;
      Item.Source_Fingerprint := Row.Source_Fingerprint;
      Item.Substitution_Fingerprint := Row.Substitution_Fingerprint;
      Item.Edge_Fingerprint := Row.Edge_Fingerprint;
      Item.Consumer_Closure_Fingerprint := Row.Consumer_Closure_Fingerprint;
      Item.Diagnostic_Fingerprint := Row.Diagnostic_Fingerprint;
      Item.Closure_Fingerprint := Row.Closure_Fingerprint;
      Item.Provenance_Fingerprint := Row.Provenance_Fingerprint;
      Item.Emitted := Row.Emitted;
      Item.Withheld_Current := Row.Withheld_Current;
      Item.Requires_Recheck := Row.Requires_Recheck;
      Item.Blocks_Downstream := Row.Blocks_Downstream;
      Item.Full_Chain_Linked := Row.Full_Chain_Linked;
      Item.Start_Line := Row.Start_Line;
      Item.Start_Column := Row.Start_Column;
      Item.End_Line := Row.End_Line;
      Item.End_Column := Row.End_Column;
      Item.Fingerprint := Entry_Fingerprint (Item);
      return Item;
   end Make_Entry;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) is
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
     (Provenance : Prov.Remaining_RM_Edge_Stabilized_Closure_Provenance_Model)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model
   is
      Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
   begin
      for Index in 1 .. Prov.Row_Count (Provenance) loop
         declare
            Item : constant Remaining_RM_Edge_Stabilized_Closure_Search_Entry :=
              Make_Entry (Prov.Row_At (Provenance, Index), Index);
         begin
            Model.Entries.Append (Item);
            Accumulate (Model, Item);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Item.Fingerprint + Index);
         end;
      end loop;
      return Model;
   end Build;

   function Entry_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Entry is
   begin
      return Model.Entries.Element (Index);
   end Entry_At;

   function Query_Count (Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set) return Natural is
   begin
      return Natural (Results.Results.Length);
   end Query_Count;

   function Query_At
     (Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      Index   : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Result is
   begin
      return Results.Results.Element (Index);
   end Query_At;

   function Query_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Blocker = Blocker then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Blocker;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Status = Status then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Status;

   function Query_Diagnostic_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Diagnostic_Status = Status then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Diagnostic_Status;

   function Query_Diagnostic_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Diagnostic_Family = Family then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Diagnostic_Family;

   function Query_Closure_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Closure_Family = Family then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Closure_Family;

   function Query_Remaining_Edge_Kind
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Kind  : Remaining_RM_Edge_Kind)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Remaining_Edge_Kind = Kind then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Remaining_Edge_Kind;

   function Query_Remaining_Edge_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Blocker : Remaining_RM_Edge_Blocker_Family)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Remaining_Edge_Blocker = Blocker then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Remaining_Edge_Blocker;

   function Query_Stage
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Stage : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Stage = Stage then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Stage;

   function Query_Node
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Node = Node then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Node;

   function Query_Range
     (Model      : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Start_Line : Positive;
      End_Line   : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Overlaps_Line_Range (Item, Start_Line, End_Line) then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Range;

   function Query_Position
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Line   : Positive;
      Column : Positive) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Contains_Position (Item, Line, Column) then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Position;

   function Query_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Source_Fingerprint = Fingerprint then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Source_Fingerprint;

   function Query_Substitution_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Substitution_Fingerprint = Fingerprint then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Substitution_Fingerprint;

   function Query_Provenance_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set
   is
      Results : Remaining_RM_Edge_Stabilized_Closure_Search_Result_Set;
      N : Natural := 0;
   begin
      for Item of Model.Entries loop
         N := N + 1;
         if Item.Provenance_Fingerprint = Fingerprint then
            Append_Result (Results, N, Item);
         end if;
      end loop;
      return Results;
   end Query_Provenance_Fingerprint;

   function Has_Blocker_At
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Line    : Positive;
      Column  : Positive;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker) return Boolean is
   begin
      for Item of Model.Entries loop
         if Item.Blocker = Blocker and then Contains_Position (Item, Line, Column) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Blocker_At;

   function Count_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Closure_Provenance_Blocker) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Count_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Provenance_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Diagnostic_Status
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Status : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Status) return Natural is
   begin
      return Query_Count (Query_Diagnostic_Status (Model, Status));
   end Count_Diagnostic_Status;

   function Count_Diagnostic_Family
     (Model  : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Family : Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Family) return Natural is
   begin
      return Query_Count (Query_Diagnostic_Family (Model, Family));
   end Count_Diagnostic_Family;

   function Count_Stage
     (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model;
      Stage : Remaining_RM_Edge_Stabilized_Closure_Provenance_Stage) return Natural is
   begin
      return Query_Count (Query_Stage (Model, Stage));
   end Count_Stage;

   function Withheld_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Emitted_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Emitted_Total;
   end Emitted_Count;

   function Error_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Recheck_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Recheck_Total;
   end Recheck_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Multiple_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Multiple_Total;
   end Multiple_Count;

   function Full_Chain_Link_Count (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Full_Chain_Link_Total;
   end Full_Chain_Link_Count;

   function Fingerprint (Model : Remaining_RM_Edge_Stabilized_Closure_Search_Index_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index;
