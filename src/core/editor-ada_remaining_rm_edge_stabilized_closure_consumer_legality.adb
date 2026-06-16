with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality is

   pragma Suppress (Overflow_Check);
   use type Closure.RM_Closure_Consumer_Stabilized_Closure_Id;
   use type Closure.RM_Closure_Consumer_Stabilized_Closure_Status;
   use type Closure.Gate.Conv.Apply.RM_Closure_Consumer_Application_Id;
   use type Edge.Remaining_RM_Edge_Kind;
   use type Edge.Remaining_RM_Edge_Blocker_Family;
   use type Editor.Ada_Syntax_Tree.Node_Id;


   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 1_127) + (B * 149) + 12_840) mod 1_000_000_007;
   end Mix;

   function Closure_Accepts
     (Status : Closure.RM_Closure_Consumer_Stabilized_Closure_Status) return Boolean is
   begin
      return Status in
        Closure.RM_Closure_Consumer_Stabilized_Closure_Accepted_Current |
        Closure.RM_Closure_Consumer_Stabilized_Closure_Accepted_Not_Required;
   end Closure_Accepts;

   function Closure_Current
     (Status : Closure.RM_Closure_Consumer_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.RM_Closure_Consumer_Stabilized_Closure_Accepted_Current;
   end Closure_Current;

   function Closure_Recheck_Required
     (Status : Closure.RM_Closure_Consumer_Stabilized_Closure_Status) return Boolean is
   begin
      return Status = Closure.RM_Closure_Consumer_Stabilized_Closure_Recheck_Required;
   end Closure_Recheck_Required;

   procedure Add_Blocker
     (Count   : in out Natural;
      Blocker : in out Remaining_RM_Edge_Stabilized_Consumer_Blocker;
      New_One : Remaining_RM_Edge_Stabilized_Consumer_Blocker) is
   begin
      Count := Count + 1;
      if Count = 1 then
         Blocker := New_One;
      else
         Blocker := Remaining_RM_Edge_Stabilized_Blocker_Multiple;
      end if;
   end Add_Blocker;

   function Find_Closure
     (Stable : Closure.RM_Closure_Consumer_Stabilized_Closure_Model;
      Edge_Row : Edge.Remaining_RM_Edge_Row)
      return Closure.RM_Closure_Consumer_Stabilized_Closure_Row is
      Candidate : Closure.RM_Closure_Consumer_Stabilized_Closure_Row;
   begin
      for I in 1 .. Closure.Count (Stable) loop
         Candidate := Closure.Row_At (Stable, I);
         if Candidate.Application_Id = Edge_Row.Application_Row then
            return Candidate;
         end if;
      end loop;
      for I in 1 .. Closure.Count (Stable) loop
         Candidate := Closure.Row_At (Stable, I);
         if Candidate.Node = Edge_Row.Node
           or else (Edge_Row.Source_Fingerprint /= 0
                    and then Candidate.Source_Fingerprint = Edge_Row.Source_Fingerprint)
         then
            return Candidate;
         end if;
      end loop;
      return (others => <>);
   end Find_Closure;

   function Search_Link_Count
     (Index    : Search.RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Edge_Row : Edge.Remaining_RM_Edge_Row) return Natural is
      Node_Results : constant Search.RM_Closure_Consumer_Stabilized_Search_Result_Set :=
        Search.Query_Node (Index, Edge_Row.Node);
      Source_Results : constant Search.RM_Closure_Consumer_Stabilized_Search_Result_Set :=
        Search.Query_Source_Fingerprint (Index, Edge_Row.Source_Fingerprint);
   begin
      return Search.Query_Count (Node_Results) + Search.Query_Count (Source_Results);
   end Search_Link_Count;

   function Search_Fingerprint_For
     (Index    : Search.RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Edge_Row : Edge.Remaining_RM_Edge_Row) return Natural is
      Node_Results : constant Search.RM_Closure_Consumer_Stabilized_Search_Result_Set :=
        Search.Query_Node (Index, Edge_Row.Node);
   begin
      if Search.Query_Count (Node_Results) > 0 then
         return Search.Query_At (Node_Results, 1).Feed_Item.Fingerprint;
      end if;
      return 0;
   end Search_Fingerprint_For;

   function Message_For
     (Status  : Remaining_RM_Edge_Stabilized_Consumer_Status;
      Blocker : Remaining_RM_Edge_Stabilized_Consumer_Blocker;
      Kind    : Edge.Remaining_RM_Edge_Kind;
      Edge_Blocker : Edge.Remaining_RM_Edge_Blocker_Family) return Unbounded_String is
   begin
      return To_Unbounded_String
        ("remaining RM edge stabilized closure consumer " &
         Remaining_RM_Edge_Stabilized_Consumer_Status'Image (Status) &
         " blocker=" & Remaining_RM_Edge_Stabilized_Consumer_Blocker'Image (Blocker) &
         " kind=" & Edge.Remaining_RM_Edge_Kind'Image (Kind) &
         " edge_blocker=" & Edge.Remaining_RM_Edge_Blocker_Family'Image (Edge_Blocker));
   end Message_For;

   function Row_Fingerprint
     (Row : Remaining_RM_Edge_Stabilized_Consumer_Row) return Natural is
      Text : constant String := To_String (Row.Message);
      H    : Natural := 12_840;
   begin
      H := Mix (H, Natural (Row.Id));
      H := Mix (H, Natural (Row.Remaining_Edge_Row));
      H := Mix (H, Edge.Remaining_RM_Edge_Kind'Pos (Row.Remaining_Edge_Kind) + 1);
      H := Mix (H, Edge.Remaining_RM_Edge_Status'Pos (Row.Remaining_Edge_Status) + 1);
      H := Mix (H, Edge.Remaining_RM_Edge_Blocker_Family'Pos (Row.Remaining_Edge_Blocker) + 1);
      H := Mix (H, Natural (Row.Stabilized_Closure_Row));
      H := Mix (H, Closure.RM_Closure_Consumer_Stabilized_Closure_Status'Pos (Row.Stabilized_Closure_Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Consumer_Status'Pos (Row.Status) + 1);
      H := Mix (H, Remaining_RM_Edge_Stabilized_Consumer_Blocker'Pos (Row.Blocker) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Row.Blocker_Count);
      H := Mix (H, Row.Search_Link_Count);
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Substitution_Fingerprint);
      H := Mix (H, Row.Edge_Fingerprint);
      H := Mix (H, Row.Closure_Fingerprint);
      H := Mix (H, Row.Search_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Edge_Row : Edge.Remaining_RM_Edge_Row;
      Stable_Row : Closure.RM_Closure_Consumer_Stabilized_Closure_Row;
      Index : Search.RM_Closure_Consumer_Stabilized_Search_Index_Model;
      Row_Index : Positive) return Remaining_RM_Edge_Stabilized_Consumer_Row is
      Row : Remaining_RM_Edge_Stabilized_Consumer_Row;
      Count : Natural := 0;
      Blocker : Remaining_RM_Edge_Stabilized_Consumer_Blocker := Remaining_RM_Edge_Stabilized_Blocker_None;
   begin
      Row.Id := Remaining_RM_Edge_Stabilized_Consumer_Id (Row_Index);
      Row.Remaining_Edge_Row := Edge_Row.Id;
      Row.Remaining_Edge_Kind := Edge_Row.Kind;
      Row.Remaining_Edge_Status := Edge_Row.Status;
      Row.Remaining_Edge_Blocker := Edge_Row.Blocker_Family;
      Row.Stabilized_Closure_Row := Stable_Row.Id;
      Row.Stabilized_Closure_Status := Stable_Row.Status;
      Row.Stabilized_Closure_Family := Stable_Row.Family;
      Row.Node := Edge_Row.Node;
      Row.Source_Fingerprint := Edge_Row.Source_Fingerprint;
      Row.Substitution_Fingerprint := Edge_Row.Substitution_Fingerprint;
      Row.Edge_Fingerprint := Edge_Row.Row_Fingerprint;
      Row.Closure_Fingerprint := Stable_Row.Closure_Fingerprint;
      Row.Search_Link_Count := Search_Link_Count (Index, Edge_Row);
      Row.Search_Linked := Row.Search_Link_Count > 0;
      Row.Search_Fingerprint := Search_Fingerprint_For (Index, Edge_Row);
      Row.Start_Line := Edge_Row.Start_Line;
      Row.Start_Column := Edge_Row.Start_Column;
      Row.End_Line := Edge_Row.End_Line;
      Row.End_Column := Edge_Row.End_Column;

      if Edge_Row.Blocked then
         Add_Blocker (Count, Blocker, Remaining_RM_Edge_Stabilized_Blocker_Remaining_Edge);
      end if;

      if Stable_Row.Id = Closure.No_RM_Closure_Consumer_Stabilized_Closure then
         Add_Blocker (Count, Blocker, Remaining_RM_Edge_Stabilized_Blocker_Stabilized_Closure);
      elsif not Closure_Accepts (Stable_Row.Status) then
         Add_Blocker (Count, Blocker, Remaining_RM_Edge_Stabilized_Blocker_Stabilized_Closure);
      end if;

      if Stable_Row.Id /= Closure.No_RM_Closure_Consumer_Stabilized_Closure
        and then Edge_Row.Source_Fingerprint /= 0
        and then Stable_Row.Source_Fingerprint /= 0
        and then Edge_Row.Source_Fingerprint /= Stable_Row.Source_Fingerprint
      then
         Add_Blocker (Count, Blocker, Remaining_RM_Edge_Stabilized_Blocker_Source_Fingerprint);
      end if;

      if Stable_Row.Id /= Closure.No_RM_Closure_Consumer_Stabilized_Closure
        and then Edge_Row.Substitution_Fingerprint /= 0
        and then Stable_Row.Substitution_Fingerprint /= 0
        and then Edge_Row.Substitution_Fingerprint /= Stable_Row.Substitution_Fingerprint
      then
         Add_Blocker (Count, Blocker, Remaining_RM_Edge_Stabilized_Blocker_Substitution_Fingerprint);
      end if;

      Row.Blocker_Count := Count;
      Row.Blocker := Blocker;

      if Count = 0 then
         if Closure_Current (Stable_Row.Status) then
            Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Accepted_Current;
            Row.Current := True;
         else
            Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Accepted_Not_Required;
         end if;
         Row.Accepted := True;
      elsif Count > 1 then
         Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Multiple_Blockers;
         Row.Blocker := Remaining_RM_Edge_Stabilized_Blocker_Multiple;
      elsif Edge_Row.Blocked then
         Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Remaining_Edge_Blocker;
      elsif Stable_Row.Id = Closure.No_RM_Closure_Consumer_Stabilized_Closure then
         Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Missing_Stabilized_Closure;
      elsif Closure_Recheck_Required (Stable_Row.Status) then
         Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Stabilized_Closure_Recheck_Required;
      elsif Row.Blocker = Remaining_RM_Edge_Stabilized_Blocker_Source_Fingerprint then
         Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Source_Fingerprint_Mismatch;
      elsif Row.Blocker = Remaining_RM_Edge_Stabilized_Blocker_Substitution_Fingerprint then
         Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Substitution_Fingerprint_Mismatch;
      elsif Row.Blocker = Remaining_RM_Edge_Stabilized_Blocker_Stabilized_Closure then
         Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Stabilized_Closure_Blocker;
      else
         Row.Status := Remaining_RM_Edge_Stabilized_Consumer_Indeterminate;
         Row.Blocker := Remaining_RM_Edge_Stabilized_Blocker_Indeterminate;
      end if;

      Row.Blocked := not Row.Accepted;
      Row.Blocks_Downstream := Row.Blocked;
      Row.Message := Message_For (Row.Status, Row.Blocker, Row.Remaining_Edge_Kind, Row.Remaining_Edge_Blocker);
      Row.Row_Fingerprint := Row_Fingerprint (Row);
      return Row;
   end Make_Row;

   procedure Clear (Model : in out Remaining_RM_Edge_Stabilized_Consumer_Model) is
   begin
      Model.Rows.Clear;
      Model.Accepted_Total := 0;
      Model.Blocked_Total := 0;
      Model.Search_Linked_Total := 0;
      Model.Recheck_Required_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Row
     (Model : in out Remaining_RM_Edge_Stabilized_Consumer_Model;
      Row   : Remaining_RM_Edge_Stabilized_Consumer_Row) is
   begin
      Model.Rows.Append (Row);
      if Row.Accepted then
         Model.Accepted_Total := Model.Accepted_Total + 1;
      end if;
      if Row.Blocked then
         Model.Blocked_Total := Model.Blocked_Total + 1;
      end if;
      if Row.Search_Linked then
         Model.Search_Linked_Total := Model.Search_Linked_Total + 1;
      end if;
      if Row.Status = Remaining_RM_Edge_Stabilized_Consumer_Stabilized_Closure_Recheck_Required then
         Model.Recheck_Required_Total := Model.Recheck_Required_Total + 1;
      end if;
      if Row.Status = Remaining_RM_Edge_Stabilized_Consumer_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Row_Fingerprint);
   end Add_Row;

   function Build
     (Edges   : Edge.Remaining_RM_Edge_Model;
      Stable  : Closure.RM_Closure_Consumer_Stabilized_Closure_Model;
      Index   : Search.RM_Closure_Consumer_Stabilized_Search_Index_Model)
      return Remaining_RM_Edge_Stabilized_Consumer_Model is
      Result : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Edge_Row : Edge.Remaining_RM_Edge_Row;
   begin
      for I in 1 .. Edge.Count (Edges) loop
         Edge_Row := Edge.Row_At (Edges, I);
         Add_Row
           (Result,
            Make_Row (Edge_Row, Find_Closure (Stable, Edge_Row), Index, I));
      end loop;
      return Result;
   end Build;

   function Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Count;

   function Row_At
     (Model : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Consumer_Row is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Remaining_RM_Edge_Stabilized_Consumer_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Remaining_RM_Edge_Stabilized_Consumer_Set;
      Index : Positive) return Remaining_RM_Edge_Stabilized_Consumer_Row is
   begin
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Append
     (Set : in out Remaining_RM_Edge_Stabilized_Consumer_Set;
      Row : Remaining_RM_Edge_Stabilized_Consumer_Row) is
   begin
      Set.Rows.Append (Row);
   end Append;

   function Query_Status
     (Model  : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Status : Remaining_RM_Edge_Stabilized_Consumer_Status)
      return Remaining_RM_Edge_Stabilized_Consumer_Set is
      Result : Remaining_RM_Edge_Stabilized_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Consumer_Blocker)
      return Remaining_RM_Edge_Stabilized_Consumer_Set is
      Result : Remaining_RM_Edge_Stabilized_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker = Blocker then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker;

   function Query_Edge_Kind
     (Model : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Kind  : Edge.Remaining_RM_Edge_Kind)
      return Remaining_RM_Edge_Stabilized_Consumer_Set is
      Result : Remaining_RM_Edge_Stabilized_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Remaining_Edge_Kind = Kind then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Edge_Kind;

   function Find_By_Node
     (Model : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id)
      return Remaining_RM_Edge_Stabilized_Consumer_Set is
      Result : Remaining_RM_Edge_Stabilized_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Node;

   function Find_By_Source_Fingerprint
     (Model       : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Fingerprint : Natural) return Remaining_RM_Edge_Stabilized_Consumer_Set is
      Result : Remaining_RM_Edge_Stabilized_Consumer_Set;
   begin
      for Row of Model.Rows loop
         if Row.Source_Fingerprint = Fingerprint then
            Append (Result, Row);
         end if;
      end loop;
      return Result;
   end Find_By_Source_Fingerprint;

   function Count_By_Status
     (Model  : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Status : Remaining_RM_Edge_Stabilized_Consumer_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_By_Status;

   function Count_By_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Blocker : Remaining_RM_Edge_Stabilized_Consumer_Blocker) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_By_Blocker;

   function Count_By_Edge_Blocker
     (Model   : Remaining_RM_Edge_Stabilized_Consumer_Model;
      Blocker : Edge.Remaining_RM_Edge_Blocker_Family) return Natural is
      Total : Natural := 0;
   begin
      for Row of Model.Rows loop
         if Row.Remaining_Edge_Blocker = Blocker then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_By_Edge_Blocker;

   function Accepted_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural is
   begin
      return Model.Accepted_Total;
   end Accepted_Count;

   function Blocked_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural is
   begin
      return Model.Blocked_Total;
   end Blocked_Count;

   function Search_Linked_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural is
   begin
      return Model.Search_Linked_Total;
   end Search_Linked_Count;

   function Recheck_Required_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural is
   begin
      return Model.Recheck_Required_Total;
   end Recheck_Required_Count;

   function Indeterminate_Count (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Stable_Fingerprint (Model : Remaining_RM_Edge_Stabilized_Consumer_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Stable_Fingerprint;

end Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality;
