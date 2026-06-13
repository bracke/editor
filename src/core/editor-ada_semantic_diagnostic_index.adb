package body Editor.Ada_Semantic_Diagnostic_Index is

   use type Feed_Severity;
   use type Feed_Source;
   use type Editor.Syntax.Token_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 137) + B + 59) mod 1_000_000_007;
   end Mix;

   function Entry_Fingerprint
     (Feed_Item : Semantic_Diagnostic_Index_Entry) return Natural
   is
      H : Natural := Natural (Feed_Item.Id);
   begin
      H := Mix (H, Feed_Item.Feed_Index + 1);
      H := Mix (H, Feed_Item.Diagnostic.Fingerprint + 1);
      H := Mix (H, Feed_Item.Diagnostic.Start_Line);
      H := Mix (H, Feed_Item.Diagnostic.Start_Column);
      H := Mix (H, Feed_Item.Diagnostic.End_Line);
      H := Mix (H, Feed_Item.Diagnostic.End_Column);
      return H;
   end Entry_Fingerprint;

   function Overlaps_Line_Range
     (Feed_Item      : Feed_Entry;
      Start_Line : Positive;
      End_Line   : Positive) return Boolean
   is
      First_Line : constant Positive := Positive'Min (Start_Line, End_Line);
      Last_Line  : constant Positive := Positive'Max (Start_Line, End_Line);
   begin
      return Feed_Item.Start_Line <= Last_Line and then Feed_Item.End_Line >= First_Line;
   end Overlaps_Line_Range;

   function Contains_Position
     (Feed_Item  : Feed_Entry;
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
     (Set        : in out Semantic_Diagnostic_Query_Set;
      Feed_Index : Natural;
      Diagnostic : Feed_Entry) is
   begin
      Set.Results.Append
        (Semantic_Diagnostic_Query_Result'
           (Feed_Index => Feed_Index,
            Diagnostic => Diagnostic));
      Set.Fingerprint := Mix (Set.Fingerprint, Diagnostic.Fingerprint + Feed_Index + 1);
   end Append_Result;

   procedure Clear (Model : in out Semantic_Diagnostic_Index_Model) is
   begin
      Model.Entries.Clear;
      Model.Index_Status := Semantic_Diagnostic_Index_Current;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Rejected_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Feed : Editor.Ada_Semantic_Diagnostic_Feed.Semantic_Diagnostic_Feed_Model)
      return Semantic_Diagnostic_Index_Model
   is
      Model : Semantic_Diagnostic_Index_Model;
   begin
      if Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Stale (Feed) then
         Model.Index_Status := Semantic_Diagnostic_Index_Rejected_Stale;
         Model.Rejected_Total :=
           Editor.Ada_Semantic_Diagnostic_Feed.Rejected_Entry_Count (Feed);
         Model.Result_Fingerprint :=
           Mix (Editor.Ada_Semantic_Diagnostic_Feed.Fingerprint (Feed),
                Model.Rejected_Total + 1);
         return Model;
      end if;

      Model.Error_Total := Editor.Ada_Semantic_Diagnostic_Feed.Error_Count (Feed);
      Model.Warning_Total := Editor.Ada_Semantic_Diagnostic_Feed.Warning_Count (Feed);
      Model.Info_Total := Editor.Ada_Semantic_Diagnostic_Feed.Info_Count (Feed);
      Model.Result_Fingerprint := Editor.Ada_Semantic_Diagnostic_Feed.Fingerprint (Feed);

      for Index in 1 .. Editor.Ada_Semantic_Diagnostic_Feed.Entry_Count (Feed) loop
         declare
            Source : constant Feed_Entry :=
              Editor.Ada_Semantic_Diagnostic_Feed.Entry_At (Feed, Index);
            Feed_Item : Semantic_Diagnostic_Index_Entry;
         begin
            Feed_Item.Id := Semantic_Diagnostic_Index_Id (Index);
            Feed_Item.Feed_Index := Index;
            Feed_Item.Diagnostic := Source;
            Feed_Item.Fingerprint := Entry_Fingerprint (Feed_Item);
            Model.Entries.Append (Feed_Item);
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Feed_Item.Fingerprint);
         end;
      end loop;

      return Model;
   end Build;

   function Status (Model : Semantic_Diagnostic_Index_Model) return Semantic_Diagnostic_Index_Status is
   begin
      return Model.Index_Status;
   end Status;

   function Current (Model : Semantic_Diagnostic_Index_Model) return Boolean is
   begin
      return Model.Index_Status = Semantic_Diagnostic_Index_Current;
   end Current;

   function Rejected_Stale (Model : Semantic_Diagnostic_Index_Model) return Boolean is
   begin
      return Model.Index_Status = Semantic_Diagnostic_Index_Rejected_Stale;
   end Rejected_Stale;

   function Entry_Count (Model : Semantic_Diagnostic_Index_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Entry_Count;

   function Entry_At
     (Model : Semantic_Diagnostic_Index_Model;
      Index : Positive) return Semantic_Diagnostic_Index_Entry
   is
   begin
      if Index > Natural (Model.Entries.Length) then
         return (others => <>);
      end if;
      return Model.Entries.Element (Index);
   end Entry_At;

   function Error_Count (Model : Semantic_Diagnostic_Index_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Semantic_Diagnostic_Index_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Semantic_Diagnostic_Index_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Rejected_Entry_Count (Model : Semantic_Diagnostic_Index_Model) return Natural is
   begin
      return Model.Rejected_Total;
   end Rejected_Entry_Count;

   function Fingerprint (Model : Semantic_Diagnostic_Index_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Query_Count (Results : Semantic_Diagnostic_Query_Set) return Natural is
   begin
      return Natural (Results.Results.Length);
   end Query_Count;

   function Query_At
     (Results : Semantic_Diagnostic_Query_Set;
      Index   : Positive) return Semantic_Diagnostic_Query_Result
   is
   begin
      if Index > Natural (Results.Results.Length) then
         return (others => <>);
      end if;
      return Results.Results.Element (Index);
   end Query_At;

   function Query_Range
     (Model      : Semantic_Diagnostic_Index_Model;
      Start_Line : Positive;
      End_Line   : Positive) return Semantic_Diagnostic_Query_Set
   is
      Set : Semantic_Diagnostic_Query_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Feed_Item of Model.Entries loop
         if Overlaps_Line_Range (Feed_Item.Diagnostic, Start_Line, End_Line) then
            Append_Result (Set, Feed_Item.Feed_Index, Feed_Item.Diagnostic);
         end if;
      end loop;
      return Set;
   end Query_Range;

   function Query_Position
     (Model  : Semantic_Diagnostic_Index_Model;
      Line   : Positive;
      Column : Positive) return Semantic_Diagnostic_Query_Set
   is
      Set : Semantic_Diagnostic_Query_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Feed_Item of Model.Entries loop
         if Contains_Position (Feed_Item.Diagnostic, Line, Column) then
            Append_Result (Set, Feed_Item.Feed_Index, Feed_Item.Diagnostic);
         end if;
      end loop;
      return Set;
   end Query_Position;

   function Query_Severity
     (Model    : Semantic_Diagnostic_Index_Model;
      Severity : Feed_Severity) return Semantic_Diagnostic_Query_Set
   is
      Set : Semantic_Diagnostic_Query_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Feed_Item of Model.Entries loop
         if Feed_Item.Diagnostic.Severity = Severity then
            Append_Result (Set, Feed_Item.Feed_Index, Feed_Item.Diagnostic);
         end if;
      end loop;
      return Set;
   end Query_Severity;

   function Query_Source
     (Model  : Semantic_Diagnostic_Index_Model;
      Source : Feed_Source) return Semantic_Diagnostic_Query_Set
   is
      Set : Semantic_Diagnostic_Query_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Feed_Item of Model.Entries loop
         if Feed_Item.Diagnostic.Source = Source then
            Append_Result (Set, Feed_Item.Feed_Index, Feed_Item.Diagnostic);
         end if;
      end loop;
      return Set;
   end Query_Source;

   function Query_Token
     (Model : Semantic_Diagnostic_Index_Model;
      Token : Editor.Syntax.Token_Kind) return Semantic_Diagnostic_Query_Set
   is
      Set : Semantic_Diagnostic_Query_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Feed_Item of Model.Entries loop
         if Feed_Item.Diagnostic.Token = Token then
            Append_Result (Set, Feed_Item.Feed_Index, Feed_Item.Diagnostic);
         end if;
      end loop;
      return Set;
   end Query_Token;

   function Query_Node
     (Model : Semantic_Diagnostic_Index_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Semantic_Diagnostic_Query_Set
   is
      Set : Semantic_Diagnostic_Query_Set;
   begin
      if not Current (Model) then
         return Set;
      end if;

      for Feed_Item of Model.Entries loop
         if Feed_Item.Diagnostic.Node = Node then
            Append_Result (Set, Feed_Item.Feed_Index, Feed_Item.Diagnostic);
         end if;
      end loop;
      return Set;
   end Query_Node;

   function Has_Diagnostic_At
     (Model  : Semantic_Diagnostic_Index_Model;
      Line   : Positive;
      Column : Positive) return Boolean is
   begin
      return Query_Count (Query_Position (Model, Line, Column)) > 0;
   end Has_Diagnostic_At;

end Editor.Ada_Semantic_Diagnostic_Index;
