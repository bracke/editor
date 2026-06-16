package body Editor.Ada_Final_Semantic_Blocker_Trace_Closure is

   pragma Suppress (Overflow_Check);

   use type Final_Prov.Final_Blocker_Family;
   use type Final_Prov.Final_Provenance_Status;
   use type Final_Prov.Final_Provenance_Stage;
   use type Feed.Semantic_Diagnostic_Feed_Id;
   use type Base_Index.Semantic_Diagnostic_Index_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 163) + B + 1198) mod 1_000_000_007;
   end Mix;

   function Root_For (Blocker : Final_Blocker_Family) return Final_Blocker_Trace_Root is
   begin
      case Blocker is
         when Final_Prov.Final_Blocker_None =>
            return Final_Trace_Root_Local;
         when Final_Prov.Final_Blocker_Cross_Unit =>
            return Final_Trace_Root_Cross_Unit;
         when Final_Prov.Final_Blocker_Overload_Type =>
            return Final_Trace_Root_Local;
         when Final_Prov.Final_Blocker_Generic_Replay =>
            return Final_Trace_Root_Generic_Replay;
         when Final_Prov.Final_Blocker_Representation_Freezing =>
            return Final_Trace_Root_Representation_Freezing;
         when Final_Prov.Final_Blocker_Flow_Contract =>
            return Final_Trace_Root_Flow_Contract;
         when Final_Prov.Final_Blocker_Tasking_Protected =>
            return Final_Trace_Root_Tasking_Protected;
         when Final_Prov.Final_Blocker_Elaboration =>
            return Final_Trace_Root_Elaboration;
         when Final_Prov.Final_Blocker_Accessibility_Lifetime =>
            return Final_Trace_Root_Accessibility_Lifetime;
         when Final_Prov.Final_Blocker_Discriminant_Variant =>
            return Final_Trace_Root_Discriminant_Variant;
         when Final_Prov.Final_Blocker_AST_Repair =>
            return Final_Trace_Root_AST_Repair;
         when Final_Prov.Final_Blocker_Coverage_Gate =>
            return Final_Trace_Root_Coverage_Gate;
         when Final_Prov.Final_Blocker_View_Barrier =>
            return Final_Trace_Root_View_Barrier;
         when Final_Prov.Final_Blocker_Multiple =>
            return Final_Trace_Root_Multiple;
         when Final_Prov.Final_Blocker_Unknown =>
            return Final_Trace_Root_Unknown;
      end case;
   end Root_For;

   function Status_For (Status : Final_Provenance_Status) return Final_Blocker_Trace_Status is
   begin
      case Status is
         when Final_Prov.Final_Provenance_Withheld_Legal =>
            return Final_Trace_Accepted_Legal;
         when Final_Prov.Final_Provenance_Emitted_Error =>
            return Final_Trace_Emitted_Error;
         when Final_Prov.Final_Provenance_Emitted_Warning =>
            return Final_Trace_Emitted_Warning;
         when Final_Prov.Final_Provenance_View_Barrier =>
            return Final_Trace_View_Barrier;
         when Final_Prov.Final_Provenance_Stale_Rejected =>
            return Final_Trace_Stale_Rejected;
         when Final_Prov.Final_Provenance_Indeterminate =>
            return Final_Trace_Indeterminate;
         when Final_Prov.Final_Provenance_Multiple_Blockers =>
            return Final_Trace_Multiple_Blockers;
         when Final_Prov.Final_Provenance_Not_Checked =>
            return Final_Trace_Not_Checked;
      end case;
   end Status_For;

   function Contains_Position
     (Trace  : Final_Blocker_Trace;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      if Line < Trace.Start_Line or else Line > Trace.End_Line then
         return False;
      end if;

      if Line = Trace.Start_Line and then Column < Trace.Start_Column then
         return False;
      end if;

      if Line = Trace.End_Line and then Column > Trace.End_Column then
         return False;
      end if;

      return True;
   end Contains_Position;

   function Same_Chain
     (Left  : Final_Blocker_Trace;
      Right : Final_Blocker_Trace) return Boolean is
   begin
      return Left.Blocker_Family = Right.Blocker_Family
        and then Left.Node = Right.Node
        and then Left.Source_Fingerprint = Right.Source_Fingerprint;
   end Same_Chain;

   function Trace_Fingerprint (Trace : Final_Blocker_Trace) return Natural is
      H : Natural := Natural (Trace.Id);
   begin
      H := Mix (H, Final_Blocker_Trace_Status'Pos (Trace.Status) + 1);
      H := Mix (H, Final_Blocker_Trace_Root'Pos (Trace.Root) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Trace.Blocker_Family) + 1);
      H := Mix (H, Final_Provenance_Status'Pos (Trace.Provenance_Status) + 1);
      H := Mix (H, Final_Provenance_Stage'Pos (Trace.Stage) + 1);
      H := Mix (H, Natural (Trace.Node) + 1);
      H := Mix (H, Trace.Start_Line);
      H := Mix (H, Trace.Start_Column);
      H := Mix (H, Trace.End_Line);
      H := Mix (H, Trace.End_Column);
      H := Mix (H, Trace.Source_Fingerprint + 1);
      H := Mix (H, Trace.Search_Link.Search_Index_Row + 1);
      H := Mix (H, Trace.Search_Link.Provenance_Index + 1);
      H := Mix (H, Natural (Trace.Search_Link.Feed_Entry) + 1);
      H := Mix (H, Natural (Trace.Search_Link.Index_Entry) + 1);
      H := Mix (H, Trace.Related_Count + 1);
      return H;
   end Trace_Fingerprint;

   procedure Append_Result
     (Set   : in out Final_Blocker_Trace_Set;
      Trace : Final_Blocker_Trace) is
   begin
      Set.Traces.Append (Trace);
      Set.Fingerprint := Mix (Set.Fingerprint, Trace.Fingerprint + 1);
   end Append_Result;

   procedure Accumulate (Model : in out Final_Blocker_Trace_Model; Trace : Final_Blocker_Trace) is
   begin
      case Trace.Status is
         when Final_Trace_Accepted_Legal =>
            Model.Legal_Total := Model.Legal_Total + 1;
         when Final_Trace_Emitted_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Trace_Emitted_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Final_Trace_View_Barrier =>
            Model.View_Barrier_Total := Model.View_Barrier_Total + 1;
         when Final_Trace_Stale_Rejected =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Trace_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
         when Final_Trace_Multiple_Blockers =>
            Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
         when Final_Trace_Missing_Search_Index =>
            Model.Missing_Search_Index_Total := Model.Missing_Search_Index_Total + 1;
         when Final_Trace_Not_Checked =>
            null;
      end case;

      if Trace.Has_Feed_Link then
         Model.Feed_Link_Total := Model.Feed_Link_Total + 1;
      end if;

      if Trace.Has_Index_Link then
         Model.Index_Link_Total := Model.Index_Link_Total + 1;
      end if;
   end Accumulate;

   procedure Clear (Model : in out Final_Blocker_Trace_Model) is
   begin
      Model.Traces.Clear;
      Model.Legal_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.View_Barrier_Total := 0;
      Model.Stale_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Multiple_Blocker_Total := 0;
      Model.Feed_Link_Total := 0;
      Model.Index_Link_Total := 0;
      Model.Missing_Search_Index_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   function Build
     (Search_Index : Final_Index.Final_Search_Index_Model)
      return Final_Blocker_Trace_Model
   is
      Model : Final_Blocker_Trace_Model;
   begin
      if Final_Index.Rejected_Stale (Search_Index)
        and then Final_Index.Entry_Count (Search_Index) = 0
      then
         Model.Stale_Total := Final_Index.Stale_Rejected_Count (Search_Index);
         Model.Fingerprint := Mix (Final_Index.Fingerprint (Search_Index), Model.Stale_Total + 1);
         return Model;
      end if;

      for I in 1 .. Final_Index.Entry_Count (Search_Index) loop
         declare
            Feed_Item : constant Final_Index.Final_Search_Entry := Final_Index.Entry_At (Search_Index, I);
            Trace : Final_Blocker_Trace;
         begin
            Trace.Id := Final_Blocker_Trace_Id (I);
            Trace.Status := Status_For (Feed_Item.Provenance_Status);
            Trace.Root := Root_For (Feed_Item.Blocker_Family);
            Trace.Blocker_Family := Feed_Item.Blocker_Family;
            Trace.Provenance_Status := Feed_Item.Provenance_Status;
            Trace.Stage := Feed_Item.Provenance_Stage;
            Trace.Node := Feed_Item.Node;
            Trace.Start_Line := Feed_Item.Start_Line;
            Trace.Start_Column := Feed_Item.Start_Column;
            Trace.End_Line := Feed_Item.End_Line;
            Trace.End_Column := Feed_Item.End_Column;
            Trace.Source_Fingerprint := Feed_Item.Source_Fingerprint;
            Trace.Search_Link.Search_Index_Row := I;
            Trace.Search_Link.Provenance_Index := Feed_Item.Provenance_Index;
            Trace.Search_Link.Feed_Entry := Feed_Item.Feed_Entry;
            Trace.Search_Link.Index_Entry := Feed_Item.Index_Entry;
            Trace.Search_Link.Fingerprint := Feed_Item.Fingerprint;
            Trace.Has_Feed_Link := Feed_Item.Feed_Entry /= Feed.No_Semantic_Diagnostic_Feed_Entry;
            Trace.Has_Index_Link := Feed_Item.Index_Entry /= Base_Index.No_Semantic_Diagnostic_Index_Entry;

            for J in 1 .. Final_Index.Entry_Count (Search_Index) loop
               declare
                  Other_Entry : constant Final_Index.Final_Search_Entry := Final_Index.Entry_At (Search_Index, J);
                  Other_Trace : Final_Blocker_Trace := Trace;
               begin
                  Other_Trace.Blocker_Family := Other_Entry.Blocker_Family;
                  Other_Trace.Node := Other_Entry.Node;
                  Other_Trace.Source_Fingerprint := Other_Entry.Source_Fingerprint;
                  if Same_Chain (Trace, Other_Trace) then
                     Trace.Related_Count := Trace.Related_Count + 1;
                  end if;
               end;
            end loop;

            Trace.Fingerprint := Trace_Fingerprint (Trace);
            Model.Traces.Append (Trace);
            Accumulate (Model, Trace);
            Model.Fingerprint := Mix (Model.Fingerprint, Trace.Fingerprint);
         end;
      end loop;

      Model.Fingerprint := Mix (Model.Fingerprint, Final_Index.Fingerprint (Search_Index));
      return Model;
   end Build;

   function Build_With_Provenance
     (Search_Index : Final_Index.Final_Search_Index_Model;
      Provenance   : Final_Prov.Final_Provenance_Model)
      return Final_Blocker_Trace_Model
   is
      Model : Final_Blocker_Trace_Model := Build (Search_Index);
   begin
      if Final_Prov.Row_Count (Provenance) > Final_Index.Entry_Count (Search_Index) then
         for I in Final_Index.Entry_Count (Search_Index) + 1 .. Final_Prov.Row_Count (Provenance) loop
            declare
               Source : constant Final_Prov.Final_Provenance_Info := Final_Prov.Row_At (Provenance, I);
               Trace  : Final_Blocker_Trace;
            begin
               Trace.Id := Final_Blocker_Trace_Id (Trace_Count (Model) + 1);
               Trace.Status := Final_Trace_Missing_Search_Index;
               Trace.Root := Root_For (Source.Blocker_Family);
               Trace.Blocker_Family := Source.Blocker_Family;
               Trace.Provenance_Status := Source.Status;
               Trace.Stage := Source.Stage;
               Trace.Node := Source.Node;
               Trace.Start_Line := Source.Start_Line;
               Trace.Start_Column := Source.Start_Column;
               Trace.End_Line := Source.End_Line;
               Trace.End_Column := Source.End_Column;
               Trace.Source_Fingerprint := Source.Source_Fingerprint;
               Trace.Search_Link.Provenance_Index := I;
               Trace.Search_Link.Fingerprint := Source.Fingerprint;
               Trace.Related_Count := 1;
               Trace.Fingerprint := Trace_Fingerprint (Trace);
               Model.Traces.Append (Trace);
               Accumulate (Model, Trace);
               Model.Fingerprint := Mix (Model.Fingerprint, Trace.Fingerprint);
            end;
         end loop;
      end if;

      Model.Fingerprint := Mix (Model.Fingerprint, Final_Prov.Fingerprint (Provenance));
      return Model;
   end Build_With_Provenance;

   function Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Natural (Model.Traces.Length);
   end Trace_Count;

   function Trace_At
     (Model : Final_Blocker_Trace_Model;
      Index : Positive) return Final_Blocker_Trace is
   begin
      if Index > Natural (Model.Traces.Length) then
         return (others => <>);
      end if;
      return Model.Traces.Element (Index);
   end Trace_At;

   function Set_Count (Set : Final_Blocker_Trace_Set) return Natural is
   begin
      return Natural (Set.Traces.Length);
   end Set_Count;

   function Set_At
     (Set   : Final_Blocker_Trace_Set;
      Index : Positive) return Final_Blocker_Trace is
   begin
      if Index > Natural (Set.Traces.Length) then
         return (others => <>);
      end if;
      return Set.Traces.Element (Index);
   end Set_At;

   function Query_Blocker
     (Model   : Final_Blocker_Trace_Model;
      Blocker : Final_Blocker_Family) return Final_Blocker_Trace_Set
   is
      Set : Final_Blocker_Trace_Set;
   begin
      for I in 1 .. Trace_Count (Model) loop
         declare
            Trace : constant Final_Blocker_Trace := Trace_At (Model, I);
         begin
            if Trace.Blocker_Family = Blocker then
               Append_Result (Set, Trace);
            end if;
         end;
      end loop;
      return Set;
   end Query_Blocker;

   function Query_Status
     (Model  : Final_Blocker_Trace_Model;
      Status : Final_Blocker_Trace_Status) return Final_Blocker_Trace_Set
   is
      Set : Final_Blocker_Trace_Set;
   begin
      for I in 1 .. Trace_Count (Model) loop
         declare
            Trace : constant Final_Blocker_Trace := Trace_At (Model, I);
         begin
            if Trace.Status = Status then
               Append_Result (Set, Trace);
            end if;
         end;
      end loop;
      return Set;
   end Query_Status;

   function Query_Root
     (Model : Final_Blocker_Trace_Model;
      Root  : Final_Blocker_Trace_Root) return Final_Blocker_Trace_Set
   is
      Set : Final_Blocker_Trace_Set;
   begin
      for I in 1 .. Trace_Count (Model) loop
         declare
            Trace : constant Final_Blocker_Trace := Trace_At (Model, I);
         begin
            if Trace.Root = Root then
               Append_Result (Set, Trace);
            end if;
         end;
      end loop;
      return Set;
   end Query_Root;

   function Query_Node
     (Model : Final_Blocker_Trace_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Blocker_Trace_Set
   is
      Set : Final_Blocker_Trace_Set;
   begin
      for I in 1 .. Trace_Count (Model) loop
         declare
            Trace : constant Final_Blocker_Trace := Trace_At (Model, I);
         begin
            if Trace.Node = Node then
               Append_Result (Set, Trace);
            end if;
         end;
      end loop;
      return Set;
   end Query_Node;

   function Query_Position
     (Model  : Final_Blocker_Trace_Model;
      Line   : Positive;
      Column : Positive) return Final_Blocker_Trace_Set
   is
      Set : Final_Blocker_Trace_Set;
   begin
      for I in 1 .. Trace_Count (Model) loop
         declare
            Trace : constant Final_Blocker_Trace := Trace_At (Model, I);
         begin
            if Contains_Position (Trace, Line, Column) then
               Append_Result (Set, Trace);
            end if;
         end;
      end loop;
      return Set;
   end Query_Position;

   function Query_Source_Fingerprint
     (Model       : Final_Blocker_Trace_Model;
      Fingerprint : Natural) return Final_Blocker_Trace_Set
   is
      Set : Final_Blocker_Trace_Set;
   begin
      for I in 1 .. Trace_Count (Model) loop
         declare
            Trace : constant Final_Blocker_Trace := Trace_At (Model, I);
         begin
            if Trace.Source_Fingerprint = Fingerprint then
               Append_Result (Set, Trace);
            end if;
         end;
      end loop;
      return Set;
   end Query_Source_Fingerprint;

   function Count_Blocker
     (Model   : Final_Blocker_Trace_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Set_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Count_Status
     (Model  : Final_Blocker_Trace_Model;
      Status : Final_Blocker_Trace_Status) return Natural is
   begin
      return Set_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Root
     (Model : Final_Blocker_Trace_Model;
      Root  : Final_Blocker_Trace_Root) return Natural is
   begin
      return Set_Count (Query_Root (Model, Root));
   end Count_Root;

   function Legal_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Trace_Count;

   function Error_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Trace_Count;

   function Warning_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Trace_Count;

   function View_Barrier_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.View_Barrier_Total;
   end View_Barrier_Trace_Count;

   function Stale_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Trace_Count;

   function Indeterminate_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Trace_Count;

   function Multiple_Blocker_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Trace_Count;

   function Feed_Link_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Feed_Link_Total;
   end Feed_Link_Trace_Count;

   function Index_Link_Trace_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Index_Link_Total;
   end Index_Link_Trace_Count;

   function Missing_Search_Index_Count (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Missing_Search_Index_Total;
   end Missing_Search_Index_Count;

   function Fingerprint (Model : Final_Blocker_Trace_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Blocker_Trace_Closure;
