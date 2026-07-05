with Text_Buffer;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Cursors;
with Editor.UTF8;
with Editor.Unicode;

package body Editor.Search is

   function Has_Match
     (Match : Search_Match) return Boolean is
   begin
      return Match.End_Index > Match.Start_Index;
   end Has_Match;


   procedure Clear
     (State : in out Search_State)
   is
   begin
      State.Query := Null_Unbounded_String;
      State.Active_Match := No_Search_Match;
      State.Matches.Clear;
   end Clear;

   procedure Set_Query
     (State : in out Search_State;
      Query : String)
   is
   begin
      State.Query := To_Unbounded_String (Query);
      State.Active_Match := No_Search_Match;
      State.Matches.Clear;
   end Set_Query;

   function Query
     (State : Search_State) return String
   is
   begin
      return To_String (State.Query);
   end Query;

   function Has_Query
     (State : Search_State) return Boolean
   is
   begin
      return Length (State.Query) > 0;
   end Has_Query;

   function Options
     (State : Search_State) return Search_Options
   is
   begin
      return State.Options;
   end Options;

   procedure Set_Options
     (State   : in out Search_State;
      Options : Search_Options)
   is
   begin
      State.Options := Options;
      State.Case_Sensitive := Options.Case_Sensitive;
      State.Active_Match := No_Search_Match;
      State.Matches.Clear;
   end Set_Options;

   procedure Recompute
     (State : in out Search_State;
      Text  : String)
   is
      Buffer : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Set_Text (Buffer, Text);
      State.Options.Case_Sensitive := State.Case_Sensitive;
      Find_All (Buffer, To_String (State.Query), State.Options, State.Matches);
      if State.Matches.Is_Empty then
         State.Active_Match := No_Search_Match;
      else
         State.Active_Match := State.Matches (State.Matches.First_Index).Index;
      end if;
   end Recompute;

   function Match_Count
     (State : Search_State) return Natural
   is
   begin
      return Natural (State.Matches.Length);
   end Match_Count;

   function Match_At
     (State : Search_State;
      Index : Positive) return Search_Match
   is
      Zero_Index : constant Natural := Index - 1;
   begin
      if State.Matches.Is_Empty
        or else Zero_Index < State.Matches.First_Index
        or else Zero_Index > State.Matches.Last_Index
      then
         return No_Match;
      end if;

      return State.Matches (Zero_Index);
   end Match_At;

   function Has_Active_Match
     (State : Search_State) return Boolean
   is
   begin
      return State.Active_Match /= No_Search_Match;
   end Has_Active_Match;

   function Active_Match_Index
     (State : Search_State) return Search_Match_Index
   is
   begin
      return State.Active_Match;
   end Active_Match_Index;

   function Active_Match
     (State : Search_State;
      Found : out Boolean) return Search_Match
   is
   begin
      Found := False;
      for M of State.Matches loop
         if M.Index = State.Active_Match then
            Found := True;
            return M;
         end if;
      end loop;
      return No_Match;
   end Active_Match;

   procedure Set_Active_Match
     (State : in out Search_State;
      Index : Search_Match_Index)
   is
   begin
      if Index = No_Search_Match then
         State.Active_Match := No_Search_Match;
         return;
      end if;

      for M of State.Matches loop
         if M.Index = Index then
            State.Active_Match := Index;
            return;
         end if;
      end loop;

      State.Active_Match := No_Search_Match;
   end Set_Active_Match;

   function Next_Match_After
     (State  : Search_State;
      Row    : Natural;
      Column : Natural;
      Wrap   : Boolean := True;
      Found  : out Boolean) return Search_Match_Index
   is
   begin
      Found := False;
      if State.Matches.Is_Empty then
         return No_Search_Match;
      end if;

      for M of State.Matches loop
         if M.Start_Row > Row
           or else (M.Start_Row = Row and then M.Start_Column > Column)
         then
            Found := True;
            return M.Index;
         end if;
      end loop;

      if Wrap then
         Found := True;
         return State.Matches (State.Matches.First_Index).Index;
      end if;

      return No_Search_Match;
   end Next_Match_After;

   function Previous_Match_Before
     (State  : Search_State;
      Row    : Natural;
      Column : Natural;
      Wrap   : Boolean := True;
      Found  : out Boolean) return Search_Match_Index
   is
   begin
      Found := False;
      if State.Matches.Is_Empty then
         return No_Search_Match;
      end if;

      for I in reverse State.Matches.First_Index .. State.Matches.Last_Index loop
         declare
            M : constant Search_Match := State.Matches (I);
         begin
            if M.Start_Row < Row
              or else (M.Start_Row = Row and then M.Start_Column < Column)
            then
               Found := True;
               return M.Index;
            end if;
         end;
      end loop;

      if Wrap then
         Found := True;
         return State.Matches (State.Matches.Last_Index).Index;
      end if;

      return No_Search_Match;
   end Previous_Match_Before;

   function Fold_ASCII (Ch : Character) return Character is
   begin
      if Ch in 'A' .. 'Z' then
         return Character'Val
           (Character'Pos (Ch) - Character'Pos ('A') + Character'Pos ('a'));
      else
         return Ch;
      end if;
   end Fold_ASCII;

   function Same_Code
     (A, B    : Editor.Unicode.Code_Point;
      Options : Search_Options) return Boolean is
      AV : constant Natural := Editor.Unicode.Code_Point'Pos (A);
      BV : constant Natural := Editor.Unicode.Code_Point'Pos (B);
   begin
      if Options.Case_Sensitive then
         return A = B;
      elsif AV <= 255 and then BV <= 255 then
         return Fold_ASCII (Character'Val (AV)) = Fold_ASCII (Character'Val (BV));
      else
         --  deliberately keeps case-insensitive search ASCII-only.
         return A = B;
      end if;
   end Same_Code;

   function Query_Code_Point_At
     (Query : String;
      Index : Natural) return Editor.Unicode.Code_Point
   is
      Seen   : Natural := 0;
      Result : Editor.Unicode.Code_Point := Wide_Wide_Character'Val (0);
      Done   : Boolean := False;
      procedure Visit (Code : Editor.Unicode.Code_Point) is
      begin
         if Done then
            return;
         elsif Seen = Index then
            Result := Code;
            Done := True;
         else
            Seen := Seen + 1;
         end if;
      end Visit;
   begin
      Editor.UTF8.Decode_UTF8 (Query, Visit'Access, Editor.UTF8.Replace);
      return Result;
   end Query_Code_Point_At;

   function Matches_At
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      Start   : Natural;
      Options : Search_Options) return Boolean
   is
      Offset : Natural := 0;
   begin
      while Offset < Text_Buffer.UTF8_Code_Point_Count (Query) loop
         if not Same_Code
           (Text_Buffer.Code_Point_At (Buffer, Start + Offset),
            Query_Code_Point_At (Query, Offset),
            Options)
         then
            return False;
         end if;

         Offset := Offset + 1;
      end loop;

      return True;
   end Matches_At;

   function Make_Match
     (Buffer       : Text_Buffer.Buffer_Type;
      Start        : Natural;
      Query_Length : Natural;
      Ordinal      : Search_Match_Index := No_Search_Match) return Search_Match
   is
      Start_Row : Natural := 0;
      Start_Col : Natural := 0;
      End_Row   : Natural := 0;
      End_Col   : Natural := 0;
      Stop      : constant Natural := Start + Query_Length;
   begin
      Text_Buffer.Row_Col_For_Index (Buffer, Start, Start_Row, Start_Col);
      Text_Buffer.Row_Col_For_Index (Buffer, Stop, End_Row, End_Col);
      return
        (Index        => Ordinal,
         Start_Index  => Editor.Cursors.Cursor_Index (Start),
         End_Index    => Editor.Cursors.Cursor_Index (Stop),
         Start_Row    => Start_Row,
         Start_Column => Start_Col,
         End_Row      => End_Row,
         End_Column   => End_Col);
   end Make_Match;

   function Find_Next_In_Buffer_Range
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      First   : Natural;
      Last    : Natural;
      Options : Search_Options) return Search_Match
   is
      Query_Length : constant Natural := Text_Buffer.UTF8_Code_Point_Count (Query);
   begin
      if First > Last then
         return No_Match;
      end if;

      for Candidate in First .. Last loop
         if Matches_At (Buffer, Query, Candidate, Options) then
            return Make_Match (Buffer, Candidate, Query_Length);
         end if;
      end loop;

      return No_Match;
   end Find_Next_In_Buffer_Range;

   function Find_Previous_In_Buffer_Range
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      First   : Natural;
      Last    : Natural;
      Options : Search_Options) return Search_Match
   is
      Query_Length : constant Natural := Text_Buffer.UTF8_Code_Point_Count (Query);
   begin
      if First > Last then
         return No_Match;
      end if;

      for Candidate in reverse First .. Last loop
         if Matches_At (Buffer, Query, Candidate, Options) then
            return Make_Match (Buffer, Candidate, Query_Length);
         end if;
      end loop;

      return No_Match;
   end Find_Previous_In_Buffer_Range;

   function Find_Next_In_Buffer
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      From    : Natural;
      Options : Search_Options) return Search_Match
   is
      Len          : constant Natural := Text_Buffer.Length (Buffer);
      Query_Length : constant Natural := Text_Buffer.UTF8_Code_Point_Count (Query);
      Last_Start   : Natural := 0;
      First_Start  : Natural := 0;
      Result       : Search_Match := No_Match;
   begin
      if Query_Length = 0 or else Query_Length > Len then
         return No_Match;
      end if;

      Last_Start := Len - Query_Length;
      First_Start := Natural'Min (From, Last_Start + 1);

      if First_Start <= Last_Start then
         Result := Find_Next_In_Buffer_Range
           (Buffer, Query, First_Start, Last_Start, Options);
         if Has_Match (Result) then
            return Result;
         end if;
      end if;

      if Options.Wrap and then First_Start > 0 then
         return Find_Next_In_Buffer_Range
           (Buffer, Query, 0, First_Start - 1, Options);
      end if;

      return No_Match;
   end Find_Next_In_Buffer;

   function Find_Previous_In_Buffer
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      From    : Natural;
      Options : Search_Options) return Search_Match
   is
      Len          : constant Natural := Text_Buffer.Length (Buffer);
      Query_Length : constant Natural := Text_Buffer.UTF8_Code_Point_Count (Query);
      Last_Start   : Natural := 0;
      First_Last   : Natural := 0;
      Result       : Search_Match := No_Match;
   begin
      if Query_Length = 0 or else Query_Length > Len then
         return No_Match;
      end if;

      Last_Start := Len - Query_Length;
      First_Last := Natural'Min (From, Last_Start);

      Result := Find_Previous_In_Buffer_Range
        (Buffer, Query, 0, First_Last, Options);
      if Has_Match (Result) then
         return Result;
      end if;

      if Options.Wrap and then First_Last < Last_Start then
         return Find_Previous_In_Buffer_Range
           (Buffer, Query, First_Last + 1, Last_Start, Options);
      end if;

      return No_Match;
   end Find_Previous_In_Buffer;

   procedure Find_All
     (Buffer  : Text_Buffer.Buffer_Type;
      Query   : String;
      Options : Search_Options;
      Matches : in out Search_Match_Vectors.Vector)
   is
      Len          : constant Natural := Text_Buffer.Length (Buffer);
      Query_Length : constant Natural := Text_Buffer.UTF8_Code_Point_Count (Query);
      Search_Opts  : Search_Options := Options;
      Candidate    : Natural := 0;
   begin
      Matches.Clear;

      if Query_Length = 0 or else Query_Length > Len then
         return;
      end if;

      Search_Opts.Wrap := False;

      while Candidate <= Len - Query_Length loop
         if Matches_At (Buffer, Query, Candidate, Search_Opts) then
            Matches.Append
              (Make_Match
                 (Buffer, Candidate, Query_Length,
                  Search_Match_Index (Natural (Matches.Length) + 1)));
            Candidate := Candidate + Query_Length;
         else
            Candidate := Candidate + 1;
         end if;
      end loop;
   end Find_All;



end Editor.Search;
