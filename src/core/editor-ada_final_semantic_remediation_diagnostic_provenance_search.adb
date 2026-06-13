with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;

package body Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search is

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Final_Blocker_Family;
   use type Final_Remediation_Diagnostic_Status;
   use type Final_Remediation_Provenance_Status;
   use type Final_Remediation_Provenance_Stage;
   use type Feed.Semantic_Diagnostic_Feed_Id;
   use type Index.Semantic_Diagnostic_Index_Id;
   use type Base_Prov.Diagnostic_Provenance_Id;
   use type Closure.Final_Remediation_Closure_Id;
   use type Gate.Final_Gate_Id;
   use type Trace.Final_Blocker_Trace_Id;

   function Mix (Left : Natural; Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 16#0100_0193# + Hash_Value (Right) + 1203;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Status_For
     (Row : Remed_Diag.Final_Remediation_Diagnostic_Row)
      return Final_Remediation_Provenance_Status is
   begin
      case Row.Status is
         when Remed_Diag.Final_Remediation_Diagnostic_Withheld_Legal =>
            return Final_Remediation_Provenance_Withheld_Legal;
         when Remed_Diag.Final_Remediation_Diagnostic_Stale_Prerequisite =>
            return Final_Remediation_Provenance_Stale_Rejected;
         when Remed_Diag.Final_Remediation_Diagnostic_Preserved_Semantic_Error =>
            return Final_Remediation_Provenance_Preserved_Semantic_Error;
         when Remed_Diag.Final_Remediation_Diagnostic_Indeterminate =>
            return Final_Remediation_Provenance_Indeterminate;
         when Remed_Diag.Final_Remediation_Diagnostic_Multiple_Prerequisites =>
            return Final_Remediation_Provenance_Multiple_Blockers;
         when Remed_Diag.Final_Remediation_Diagnostic_Not_Checked =>
            return Final_Remediation_Provenance_Not_Checked;
         when others =>
            case Row.Severity is
               when Remed_Diag.Final_Remediation_Diagnostic_Error =>
                  return Final_Remediation_Provenance_Emitted_Error;
               when Remed_Diag.Final_Remediation_Diagnostic_Warning =>
                  return Final_Remediation_Provenance_Emitted_Warning;
               when Remed_Diag.Final_Remediation_Diagnostic_Info =>
                  return Final_Remediation_Provenance_Emitted_Warning;
            end case;
      end case;
   end Status_For;

   function Stage_For
     (Status : Final_Remediation_Provenance_Status)
      return Final_Remediation_Provenance_Stage is
   begin
      case Status is
         when Final_Remediation_Provenance_Withheld_Legal =>
            return Final_Remediation_Stage_Withheld_Legal;
         when Final_Remediation_Provenance_Stale_Rejected =>
            return Final_Remediation_Stage_Stale_Rejection;
         when others =>
            return Final_Remediation_Stage_Diagnostic_Integration;
      end case;
   end Stage_For;

   function Message_For
     (Status  : Final_Remediation_Provenance_Status;
      Blocker : Final_Blocker_Family) return Unbounded_String is
   begin
      case Status is
         when Final_Remediation_Provenance_Withheld_Legal =>
            return To_Unbounded_String
              ("final remediation provenance withheld a confident legal row");
         when Final_Remediation_Provenance_Emitted_Error =>
            return To_Unbounded_String
              ("final remediation provenance emitted prerequisite blocker error: " &
               Final_Blocker_Family'Image (Blocker));
         when Final_Remediation_Provenance_Emitted_Warning =>
            return To_Unbounded_String
              ("final remediation provenance emitted prerequisite blocker warning: " &
               Final_Blocker_Family'Image (Blocker));
         when Final_Remediation_Provenance_Stale_Rejected =>
            return To_Unbounded_String
              ("final remediation provenance rejected stale prerequisite evidence");
         when Final_Remediation_Provenance_Preserved_Semantic_Error =>
            return To_Unbounded_String
              ("final remediation provenance preserved original semantic error");
         when Final_Remediation_Provenance_Indeterminate =>
            return To_Unbounded_String
              ("final remediation provenance preserved indeterminate prerequisite state");
         when Final_Remediation_Provenance_Multiple_Blockers =>
            return To_Unbounded_String
              ("final remediation provenance preserved multiple prerequisite blockers");
         when Final_Remediation_Provenance_Not_Checked =>
            return To_Unbounded_String
              ("final remediation provenance was not checked");
      end case;
   end Message_For;

   function Matching_Feed
     (Feed_Model : Feed.Semantic_Diagnostic_Feed_Model;
      Row        : Remed_Diag.Final_Remediation_Diagnostic_Row)
      return Feed.Semantic_Diagnostic_Feed_Entry is
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
      Row         : Remed_Diag.Final_Remediation_Diagnostic_Row)
      return Index.Semantic_Diagnostic_Index_Entry is
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
      Row        : Remed_Diag.Final_Remediation_Diagnostic_Row)
      return Base_Prov.Diagnostic_Provenance_Item is
      Candidate : Base_Prov.Diagnostic_Provenance_Item;
   begin
      for I in 1 .. Base_Prov.Item_Count (Provenance) loop
         Candidate := Base_Prov.Item_At (Provenance, I);
         if Candidate.Node = Row.Node
           or else Candidate.Source_Fingerprint = Row.Source_Fingerprint
         then
            return Candidate;
         end if;
      end loop;
      return (others => <>);
   end Matching_Base;

   function Matching_Closure
     (Closures : Closure.Final_Remediation_Closure_Model;
      Row      : Remed_Diag.Final_Remediation_Diagnostic_Row)
      return Closure.Final_Remediation_Closure_Row is
      Candidate : Closure.Final_Remediation_Closure_Row;
   begin
      for I in 1 .. Closure.Row_Count (Closures) loop
         Candidate := Closure.Row_At (Closures, I);
         if Candidate.Id = Row.Closure_Id
           or else Candidate.Node = Row.Node
           or else Candidate.Source_Fingerprint = Row.Source_Fingerprint
         then
            return Candidate;
         end if;
      end loop;
      return (others => <>);
   end Matching_Closure;

   function Matching_Gate
     (Gates : Gate.Final_Gated_Model;
      Row   : Remed_Diag.Final_Remediation_Diagnostic_Row)
      return Gate.Final_Gated_Result is
      Candidate : Gate.Final_Gated_Result;
   begin
      for I in 1 .. Gate.Row_Count (Gates) loop
         Candidate := Gate.Row_At (Gates, I);
         if Candidate.Node = Row.Node
           or else Candidate.Source_Fingerprint = Row.Source_Fingerprint
         then
            return Candidate;
         end if;
      end loop;
      return (others => <>);
   end Matching_Gate;

   function Matching_Trace
     (Traces : Trace.Final_Blocker_Trace_Model;
      Row    : Remed_Diag.Final_Remediation_Diagnostic_Row)
      return Trace.Final_Blocker_Trace is
      Candidate : Trace.Final_Blocker_Trace;
   begin
      for I in 1 .. Trace.Trace_Count (Traces) loop
         Candidate := Trace.Trace_At (Traces, I);
         if Candidate.Node = Row.Node
           or else Candidate.Source_Fingerprint = Row.Source_Fingerprint
           or else Candidate.Blocker_Family = Row.Blocker_Family
         then
            return Candidate;
         end if;
      end loop;
      return (others => <>);
   end Matching_Trace;

   function Row_Fingerprint (Row : Final_Remediation_Provenance_Info) return Natural is
      Text : constant String := To_String (Row.Message) & To_String (Row.Chain_Summary);
      H : Natural := Natural (Row.Id);
   begin
      H := Mix (H, Remed_Diag.Final_Remediation_Diagnostic_Status'Pos (Row.Diagnostic_Status) + 1);
      H := Mix (H, Remed_Diag.Final_Remediation_Diagnostic_Family'Pos (Row.Diagnostic_Family) + 1);
      H := Mix (H, Closure.Final_Remediation_Closure_Status'Pos (Row.Closure_Status) + 1);
      H := Mix (H, Gate.Final_Gate_Status'Pos (Row.Gate_Status) + 1);
      H := Mix (H, Gate.Final_Gate_Action'Pos (Row.Gate_Action) + 1);
      H := Mix (H, Trace.Final_Blocker_Trace_Root'Pos (Row.Trace_Root) + 1);
      H := Mix (H, Final_Blocker_Family'Pos (Row.Blocker_Family) + 1);
      H := Mix (H, Final_Remediation_Provenance_Status'Pos (Row.Status) + 1);
      H := Mix (H, Final_Remediation_Provenance_Stage'Pos (Row.Stage) + 1);
      H := Mix (H, Natural (Row.Node));
      H := Mix (H, Natural (Row.Feed_Entry));
      H := Mix (H, Natural (Row.Index_Entry));
      H := Mix (H, Natural (Row.Base_Provenance));
      H := Mix (H, Row.Source_Fingerprint);
      H := Mix (H, Row.Diagnostic_Fingerprint);
      H := Mix (H, Row.Closure_Fingerprint);
      H := Mix (H, Row.Gate_Fingerprint);
      H := Mix (H, Row.Trace_Fingerprint);
      H := Mix (H, Row.Feed_Fingerprint);
      H := Mix (H, Row.Index_Fingerprint);
      H := Mix (H, Row.Base_Fingerprint);
      for C of Text loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Row_Fingerprint;

   function Make_Row
     (Diagnostic : Remed_Diag.Final_Remediation_Diagnostic_Row;
      Row_Index  : Positive;
      Closure_Row : Closure.Final_Remediation_Closure_Row;
      Gate_Row    : Gate.Final_Gated_Result;
      Trace_Row   : Trace.Final_Blocker_Trace;
      Feed_Row    : Feed.Semantic_Diagnostic_Feed_Entry;
      Index_Row   : Index.Semantic_Diagnostic_Index_Entry;
      Base_Row    : Base_Prov.Diagnostic_Provenance_Item)
      return Final_Remediation_Provenance_Info is
      Status : constant Final_Remediation_Provenance_Status := Status_For (Diagnostic);
      Result : Final_Remediation_Provenance_Info;
   begin
      Result.Id := Final_Remediation_Provenance_Id (Row_Index);
      Result.Diagnostic_Id := Diagnostic.Id;
      Result.Diagnostic_Status := Diagnostic.Status;
      Result.Diagnostic_Family := Diagnostic.Family;
      Result.Closure_Id := Diagnostic.Closure_Id;
      Result.Closure_Status := Diagnostic.Closure_Status;
      Result.Status := Status;
      Result.Stage := Stage_For (Status);
      Result.Blocker_Family := Diagnostic.Blocker_Family;
      Result.Node := Diagnostic.Node;
      Result.Message := Message_For (Status, Diagnostic.Blocker_Family);
      Result.Chain_Summary := To_Unbounded_String
        ("diagnostic=" & Remed_Diag.Final_Remediation_Diagnostic_Id'Image (Diagnostic.Id) &
         "; diagnostic_status=" & Remed_Diag.Final_Remediation_Diagnostic_Status'Image (Diagnostic.Status) &
         "; closure=" & Closure.Final_Remediation_Closure_Id'Image (Diagnostic.Closure_Id) &
         "; closure_status=" & Closure.Final_Remediation_Closure_Status'Image (Diagnostic.Closure_Status) &
         "; blocker=" & Final_Blocker_Family'Image (Diagnostic.Blocker_Family));
      Result.Start_Line := Diagnostic.Start_Line;
      Result.Start_Column := Diagnostic.Start_Column;
      Result.End_Line := Diagnostic.End_Line;
      Result.End_Column := Diagnostic.End_Column;
      Result.Source_Fingerprint := Diagnostic.Source_Fingerprint;
      Result.Diagnostic_Fingerprint := Diagnostic.Fingerprint;
      Result.Closure_Fingerprint := Diagnostic.Closure_Fingerprint;

      if Closure_Row.Id /= Closure.No_Final_Remediation_Closure then
         Result.Closure_Id := Closure_Row.Id;
         Result.Closure_Status := Closure_Row.Status;
         Result.Closure_Fingerprint := Closure_Row.Fingerprint;
         Result.Stage := Final_Remediation_Stage_Closure;
      end if;

      if Gate_Row.Id /= Gate.No_Final_Gate then
         Result.Gate_Id := Gate_Row.Id;
         Result.Gate_Status := Gate_Row.Status;
         Result.Gate_Action := Gate_Row.Action;
         Result.Gate_Fingerprint := Gate_Row.Fingerprint;
         Result.Stage := Final_Remediation_Stage_Gate;
      end if;

      if Trace_Row.Id /= Trace.No_Final_Blocker_Trace then
         Result.Trace_Id := Trace_Row.Id;
         Result.Trace_Root := Trace_Row.Root;
         Result.Trace_Fingerprint := Trace_Row.Fingerprint;
         Result.Stage := Final_Remediation_Stage_Trace;
      end if;

      if Feed_Row.Id /= Feed.No_Semantic_Diagnostic_Feed_Entry then
         Result.Feed_Entry := Feed_Row.Id;
         Result.Feed_Fingerprint := Feed_Row.Fingerprint;
         Result.Stage := Final_Remediation_Stage_Unified_Feed;
      end if;

      if Index_Row.Id /= Index.No_Semantic_Diagnostic_Index_Entry then
         Result.Index_Entry := Index_Row.Id;
         Result.Index_Fingerprint := Index_Row.Fingerprint;
         Result.Stage := Final_Remediation_Stage_Index;
      end if;

      if Base_Prov.Has_Item (Base_Row) then
         Result.Base_Provenance := Base_Row.Id;
         Result.Base_Fingerprint := Base_Row.Fingerprint;
         Result.Stage := Final_Remediation_Stage_Base_Provenance;
      end if;

      if Status = Final_Remediation_Provenance_Withheld_Legal then
         Result.Stage := Final_Remediation_Stage_Withheld_Legal;
      elsif Status = Final_Remediation_Provenance_Stale_Rejected then
         Result.Stage := Final_Remediation_Stage_Stale_Rejection;
      end if;

      Result.Fingerprint := Row_Fingerprint (Result);
      return Result;
   end Make_Row;

   procedure Clear (Model : in out Final_Remediation_Provenance_Model) is
   begin
      Model.Rows.Clear;
      Model.Withheld_Total := 0;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Stale_Total := 0;
      Model.Preserved_Error_Total := 0;
      Model.Indeterminate_Total := 0;
      Model.Multiple_Blocker_Total := 0;
      Model.Feed_Link_Total := 0;
      Model.Index_Link_Total := 0;
      Model.Base_Link_Total := 0;
      Model.Closure_Link_Total := 0;
      Model.Gate_Link_Total := 0;
      Model.Trace_Link_Total := 0;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Row
     (Model : in out Final_Remediation_Provenance_Model;
      Row   : Final_Remediation_Provenance_Info) is
   begin
      Model.Rows.Append (Row);
      case Row.Status is
         when Final_Remediation_Provenance_Withheld_Legal =>
            Model.Withheld_Total := Model.Withheld_Total + 1;
         when Final_Remediation_Provenance_Emitted_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Remediation_Provenance_Emitted_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Final_Remediation_Provenance_Stale_Rejected =>
            Model.Stale_Total := Model.Stale_Total + 1;
         when Final_Remediation_Provenance_Preserved_Semantic_Error =>
            Model.Preserved_Error_Total := Model.Preserved_Error_Total + 1;
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Remediation_Provenance_Indeterminate =>
            Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
            Model.Warning_Total := Model.Warning_Total + 1;
         when Final_Remediation_Provenance_Multiple_Blockers =>
            Model.Multiple_Blocker_Total := Model.Multiple_Blocker_Total + 1;
            Model.Error_Total := Model.Error_Total + 1;
         when Final_Remediation_Provenance_Not_Checked =>
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
      if Row.Closure_Id /= Closure.No_Final_Remediation_Closure then
         Model.Closure_Link_Total := Model.Closure_Link_Total + 1;
      end if;
      if Row.Gate_Id /= Gate.No_Final_Gate then
         Model.Gate_Link_Total := Model.Gate_Link_Total + 1;
      end if;
      if Row.Trace_Id /= Trace.No_Final_Blocker_Trace then
         Model.Trace_Link_Total := Model.Trace_Link_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Add_Row;

   function Build
     (Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model)
      return Final_Remediation_Provenance_Model is
      Empty_Closure : Closure.Final_Remediation_Closure_Row;
      Empty_Gate    : Gate.Final_Gated_Result;
      Empty_Trace   : Trace.Final_Blocker_Trace;
      Empty_Feed    : Feed.Semantic_Diagnostic_Feed_Entry;
      Empty_Index   : Index.Semantic_Diagnostic_Index_Entry;
      Empty_Base    : Base_Prov.Diagnostic_Provenance_Item;
      Result        : Final_Remediation_Provenance_Model;
   begin
      for I in 1 .. Remed_Diag.Row_Count (Diagnostics) loop
         Add_Row
           (Result,
            Make_Row
              (Remed_Diag.Row_At (Diagnostics, I),
               I,
               Empty_Closure,
               Empty_Gate,
               Empty_Trace,
               Empty_Feed,
               Empty_Index,
               Empty_Base));
      end loop;
      Result.Fingerprint := Mix (Result.Fingerprint, Remed_Diag.Fingerprint (Diagnostics));
      return Result;
   end Build;

   function Build_With_Closure_Gate_Trace
     (Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Closures    : Closure.Final_Remediation_Closure_Model;
      Gates       : Gate.Final_Gated_Model;
      Traces      : Trace.Final_Blocker_Trace_Model)
      return Final_Remediation_Provenance_Model is
      Empty_Feed  : Feed.Semantic_Diagnostic_Feed_Entry;
      Empty_Index : Index.Semantic_Diagnostic_Index_Entry;
      Empty_Base  : Base_Prov.Diagnostic_Provenance_Item;
      Result      : Final_Remediation_Provenance_Model;
   begin
      for I in 1 .. Remed_Diag.Row_Count (Diagnostics) loop
         declare
            D : constant Remed_Diag.Final_Remediation_Diagnostic_Row := Remed_Diag.Row_At (Diagnostics, I);
         begin
            Add_Row
              (Result,
               Make_Row
                 (D,
                  I,
                  Matching_Closure (Closures, D),
                  Matching_Gate (Gates, D),
                  Matching_Trace (Traces, D),
                  Empty_Feed,
                  Empty_Index,
                  Empty_Base));
         end;
      end loop;
      Result.Fingerprint := Mix (Result.Fingerprint, Remed_Diag.Fingerprint (Diagnostics));
      Result.Fingerprint := Mix (Result.Fingerprint, Closure.Fingerprint (Closures));
      Result.Fingerprint := Mix (Result.Fingerprint, Gate.Fingerprint (Gates));
      Result.Fingerprint := Mix (Result.Fingerprint, Trace.Fingerprint (Traces));
      return Result;
   end Build_With_Closure_Gate_Trace;

   function Build_With_Feed_Index_And_Base
     (Diagnostics : Remed_Diag.Final_Remediation_Diagnostic_Model;
      Closures    : Closure.Final_Remediation_Closure_Model;
      Gates       : Gate.Final_Gated_Model;
      Traces      : Trace.Final_Blocker_Trace_Model;
      Feed_Model  : Feed.Semantic_Diagnostic_Feed_Model;
      Index_Model : Index.Semantic_Diagnostic_Index_Model;
      Provenance  : Base_Prov.Diagnostic_Provenance_Model)
      return Final_Remediation_Provenance_Model is
      Result : Final_Remediation_Provenance_Model;
   begin
      for I in 1 .. Remed_Diag.Row_Count (Diagnostics) loop
         declare
            D : constant Remed_Diag.Final_Remediation_Diagnostic_Row := Remed_Diag.Row_At (Diagnostics, I);
         begin
            Add_Row
              (Result,
               Make_Row
                 (D,
                  I,
                  Matching_Closure (Closures, D),
                  Matching_Gate (Gates, D),
                  Matching_Trace (Traces, D),
                  Matching_Feed (Feed_Model, D),
                  Matching_Index (Index_Model, D),
                  Matching_Base (Provenance, D)));
         end;
      end loop;
      Result.Fingerprint := Mix (Result.Fingerprint, Remed_Diag.Fingerprint (Diagnostics));
      Result.Fingerprint := Mix (Result.Fingerprint, Closure.Fingerprint (Closures));
      Result.Fingerprint := Mix (Result.Fingerprint, Gate.Fingerprint (Gates));
      Result.Fingerprint := Mix (Result.Fingerprint, Trace.Fingerprint (Traces));
      Result.Fingerprint := Mix (Result.Fingerprint, Feed.Fingerprint (Feed_Model));
      Result.Fingerprint := Mix (Result.Fingerprint, Index.Fingerprint (Index_Model));
      Result.Fingerprint := Mix (Result.Fingerprint, Base_Prov.Fingerprint (Provenance));
      return Result;
   end Build_With_Feed_Index_And_Base;

   function Row_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At
     (Model : Final_Remediation_Provenance_Model;
      Index : Positive) return Final_Remediation_Provenance_Info is
   begin
      if Index > Natural (Model.Rows.Length) then
         return (others => <>);
      end if;
      return Model.Rows.Element (Index);
   end Row_At;

   function Query_Count (Set : Final_Remediation_Provenance_Set) return Natural is
   begin
      return Natural (Set.Rows.Length);
   end Query_Count;

   function Query_At
     (Set   : Final_Remediation_Provenance_Set;
      Index : Positive) return Final_Remediation_Provenance_Info is
   begin
      if Index > Natural (Set.Rows.Length) then
         return (others => <>);
      end if;
      return Set.Rows.Element (Index);
   end Query_At;

   procedure Add_Query
     (Set : in out Final_Remediation_Provenance_Set;
      Row : Final_Remediation_Provenance_Info) is
   begin
      Set.Rows.Append (Row);
      Set.Fingerprint := Mix (Set.Fingerprint, Row.Fingerprint);
   end Add_Query;

   function Query_Status
     (Model  : Final_Remediation_Provenance_Model;
      Status : Final_Remediation_Provenance_Status) return Final_Remediation_Provenance_Set is
      Result : Final_Remediation_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Status = Status then
            Add_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Status;

   function Query_Stage
     (Model : Final_Remediation_Provenance_Model;
      Stage : Final_Remediation_Provenance_Stage) return Final_Remediation_Provenance_Set is
      Result : Final_Remediation_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Stage = Stage then
            Add_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Stage;

   function Query_Blocker
     (Model   : Final_Remediation_Provenance_Model;
      Blocker : Final_Blocker_Family) return Final_Remediation_Provenance_Set is
      Result : Final_Remediation_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Blocker_Family = Blocker then
            Add_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Blocker;

   function Query_Node
     (Model : Final_Remediation_Provenance_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Final_Remediation_Provenance_Set is
      Result : Final_Remediation_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Node = Node then
            Add_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Node;

   function Query_Position
     (Model  : Final_Remediation_Provenance_Model;
      Line   : Positive;
      Column : Positive) return Final_Remediation_Provenance_Set is
      Result : Final_Remediation_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Start_Line <= Line and then Row.End_Line >= Line
           and then Row.Start_Column <= Column and then Row.End_Column >= Column
         then
            Add_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Position;

   function Query_Feed_Link
     (Model : Final_Remediation_Provenance_Model;
      Link  : Feed.Semantic_Diagnostic_Feed_Id) return Final_Remediation_Provenance_Set is
      Result : Final_Remediation_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Feed_Entry = Link then
            Add_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Feed_Link;

   function Query_Index_Link
     (Model : Final_Remediation_Provenance_Model;
      Link  : Index.Semantic_Diagnostic_Index_Id) return Final_Remediation_Provenance_Set is
      Result : Final_Remediation_Provenance_Set;
   begin
      for Row of Model.Rows loop
         if Row.Index_Entry = Link then
            Add_Query (Result, Row);
         end if;
      end loop;
      return Result;
   end Query_Index_Link;

   function Count_Status
     (Model  : Final_Remediation_Provenance_Model;
      Status : Final_Remediation_Provenance_Status) return Natural is
   begin
      return Query_Count (Query_Status (Model, Status));
   end Count_Status;

   function Count_Stage
     (Model : Final_Remediation_Provenance_Model;
      Stage : Final_Remediation_Provenance_Stage) return Natural is
   begin
      return Query_Count (Query_Stage (Model, Stage));
   end Count_Stage;

   function Count_Blocker
     (Model   : Final_Remediation_Provenance_Model;
      Blocker : Final_Blocker_Family) return Natural is
   begin
      return Query_Count (Query_Blocker (Model, Blocker));
   end Count_Blocker;

   function Withheld_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Withheld_Total;
   end Withheld_Count;

   function Error_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Stale_Rejected_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Stale_Total;
   end Stale_Rejected_Count;

   function Preserved_Error_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Preserved_Error_Total;
   end Preserved_Error_Count;

   function Indeterminate_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Multiple_Blocker_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Multiple_Blocker_Total;
   end Multiple_Blocker_Count;

   function Feed_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Feed_Link_Total;
   end Feed_Link_Count;

   function Index_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Index_Link_Total;
   end Index_Link_Count;

   function Base_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Base_Link_Total;
   end Base_Link_Count;

   function Closure_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Closure_Link_Total;
   end Closure_Link_Count;

   function Gate_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Gate_Link_Total;
   end Gate_Link_Count;

   function Trace_Link_Count (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Trace_Link_Total;
   end Trace_Link_Count;

   function Fingerprint (Model : Final_Remediation_Provenance_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search;
