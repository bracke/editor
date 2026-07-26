with Editor.Command_Ids; use Editor.Command_Ids;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Text_Buffer;

with Editor.Buffers;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor.History;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Input_Field;
with Editor.Navigation; use Editor.Navigation;
with Editor.Navigation_History;
with Editor.Render_Cache;
with Editor.Search;
with Editor.State;
with Editor.View;

package body Editor.Executor.Active_Find_Commands is

   use type Ada.Containers.Count_Type;
   use type Editor.Search.Search_Match_Index;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Warning;

   function Image_Of (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image_Of;

   function Has_Find_Target_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.State.Has_Active_Buffer (S)
        and then (S.Buffer_Revision > 0
                  or else S.File_Info.Has_Path
                  or else Text_Buffer.Length (S.Buffer) > 0);
   end Has_Find_Target_Buffer;

   function Is_Find_Word_Character (Ch : Character) return Boolean is
   begin
      return (Ch in 'A' .. 'Z')
        or else (Ch in 'a' .. 'z')
        or else (Ch in '0' .. '9')
        or else Ch = '_';
   end Is_Find_Word_Character;

   function Is_Whole_Word_Find_Match
     (S     : Editor.State.State_Type;
      Match : Editor.Search.Search_Match) return Boolean
   is
      Length       : constant Natural := Text_Buffer.Length (S.Buffer);
      Start_Index   : constant Natural := Natural (Match.Start_Index);
      End_Index     : constant Natural := Natural (Match.End_Index);
      Before_Is_Word : Boolean := False;
      After_Is_Word  : Boolean := False;
   begin
      if Start_Index > 0 then
         Before_Is_Word := Is_Find_Word_Character
           (Text_Buffer.Character_At (S.Buffer, Start_Index - 1));
      end if;

      if End_Index < Length then
         After_Is_Word := Is_Find_Word_Character
           (Text_Buffer.Character_At (S.Buffer, End_Index));
      end if;

      return not Before_Is_Word and then not After_Is_Word;
   end Is_Whole_Word_Find_Match;

   procedure Append_Active_Find_Match
     (Matches : in out Editor.Search.Search_Match_Vectors.Vector;
      Match   : Editor.Search.Search_Match)
   is
      Renumbered : Editor.Search.Search_Match := Match;
   begin
      Renumbered.Index := Editor.Search.Search_Match_Index
        (Natural (Matches.Length) + 1);
      Matches.Append (Renumbered);
   end Append_Active_Find_Match;

   procedure Recompute_Active_Find_Matches
     (S : in out Editor.State.State_Type)
   is
      Options : constant Editor.Search.Search_Options :=
        (Case_Sensitive => S.Active_Find_Case_Sensitive, Wrap => True);
      Query   : constant String := To_String (S.Active_Find_Query);
      Candidates : Editor.Search.Search_Match_Vectors.Vector;
   begin
      if not Editor.Buffers.Global_Registry_Current_For (S) then
         Editor.Buffers.Ensure_Global_Registry (S);
      end if;

      S.Active_Find_Matches.Clear;
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Active_Find_Stale := False;
      S.Active_Find_Wrapped := False;
      S.Active_Find_Source_Buffer_Token := 0;

      if Query'Length = 0 then
         return;
      elsif not Has_Find_Target_Buffer (S) then
         S.Active_Find_Stale := True;
         return;
      end if;

      S.Active_Find_Source_Buffer_Token := Active_Feature_Buffer_Token (S);
      Editor.Search.Find_All (S.Buffer, Query, Options, Candidates);

      if not S.Active_Find_Whole_Word then
         S.Active_Find_Matches := Candidates;
      else
         for Match of Candidates loop
            if Is_Whole_Word_Find_Match (S, Match) then
               Append_Active_Find_Match (S.Active_Find_Matches, Match);
            end if;
         end loop;
      end if;
   end Recompute_Active_Find_Matches;

   function Find_Match_By_Ordinal
     (S       : Editor.State.State_Type;
      Ordinal : Natural) return Editor.Search.Search_Match
   is
      Zero : Natural := 0;
   begin
      if Ordinal = 0 or else S.Active_Find_Matches.Is_Empty then
         return Editor.Search.No_Match;
      end if;
      Zero := S.Active_Find_Matches.First_Index + Ordinal - 1;
      if Zero > S.Active_Find_Matches.Last_Index then
         return Editor.Search.No_Match;
      end if;
      return S.Active_Find_Matches (Zero);
   end Find_Match_By_Ordinal;

   function Selected_Find_Ordinal
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if S.Active_Find_Match.Index = Editor.Search.No_Search_Match then
         return 0;
      end if;
      return Natural (S.Active_Find_Match.Index);
   end Selected_Find_Ordinal;

   function Active_Find_Match_Is_Selected
     (S : Editor.State.State_Type) return Boolean
   is
      Start_Index : constant Natural :=
        Natural (S.Active_Find_Match.Start_Index);
      End_Index   : constant Natural :=
        Natural (S.Active_Find_Match.End_Index);
      Pos         : Natural := 0;
      Anchor      : Natural := 0;
   begin
      if S.Active_Find_Match.Index = Editor.Search.No_Search_Match
        or else S.Carets.Length = 0
      then
         return False;
      end if;

      Pos := Natural (S.Carets (S.Carets.First_Index).Pos);
      Anchor := Natural (S.Carets (S.Carets.First_Index).Anchor);
      return (Anchor = Start_Index and then Pos = Start_Index)
        or else (Anchor = Start_Index and then Pos = End_Index)
        or else (Anchor = End_Index and then Pos = Start_Index);
   end Active_Find_Match_Is_Selected;

   function Active_Find_Match_Is_Current
     (S : Editor.State.State_Type) return Boolean
   is
      Ordinal : constant Natural := Selected_Find_Ordinal (S);
      Match   : Editor.Search.Search_Match;
   begin
      if Ordinal = 0 then
         return False;
      end if;

      Match := Find_Match_By_Ordinal (S, Ordinal);
      return Editor.Search.Has_Match (Match)
        and then Match.Start_Index = S.Active_Find_Match.Start_Index
        and then Match.End_Index = S.Active_Find_Match.End_Index;
   end Active_Find_Match_Is_Current;

   function First_Find_Ordinal_At_Or_After_Caret
     (S : Editor.State.State_Type) return Natural
   is
      Origin : Natural := 0;
   begin
      if S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      if S.Carets.Length > 0 then
         Origin := Natural (Safe_Caret (S));
      end if;

      for M of S.Active_Find_Matches loop
         if Natural (M.Start_Index) >= Origin then
            return Natural (M.Index);
         end if;
      end loop;

      return Natural (S.Active_Find_Matches (S.Active_Find_Matches.First_Index).Index);
   end First_Find_Ordinal_At_Or_After_Caret;

   function First_Find_Ordinal_Before_Caret
     (S : Editor.State.State_Type) return Natural
   is
      Origin : Natural := 0;
   begin
      if S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      if S.Carets.Length > 0 then
         Origin := Natural (Safe_Caret (S));
      end if;

      for I in reverse S.Active_Find_Matches.First_Index .. S.Active_Find_Matches.Last_Index loop
         declare
            M : constant Editor.Search.Search_Match := S.Active_Find_Matches (I);
         begin
            if Natural (M.Start_Index) < Origin then
               return Natural (M.Index);
            end if;
         end;
      end loop;

      return Natural (S.Active_Find_Matches (S.Active_Find_Matches.Last_Index).Index);
   end First_Find_Ordinal_Before_Caret;

   procedure Select_Active_Find_Nearest_Caret
     (S : in out Editor.State.State_Type)
   is
      Ordinal : constant Natural := First_Find_Ordinal_At_Or_After_Caret (S);
   begin
      S.Active_Find_Match := Find_Match_By_Ordinal (S, Ordinal);
   end Select_Active_Find_Nearest_Caret;

   function Find_Option_Message
     (S       : Editor.State.State_Type;
      Prefix  : String;
      Include_Count : Boolean) return String
   is
      Count : constant Natural := Natural (S.Active_Find_Matches.Length);
   begin
      if not Include_Count then
         return Prefix;
      elsif Count = 0 then
         return Prefix & "; no matches";
      else
         return Prefix & "; " & Image_Of (Count) & " matches";
      end if;
   end Find_Option_Message;

   procedure Recompute_Find_After_Option_Change
     (S : in out Editor.State.State_Type)
   is
   begin
      if Length (S.Active_Find_Query) = 0 then
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := False;
         S.Active_Find_Source_Buffer_Token := 0;
      elsif Has_Find_Target_Buffer (S) then
         Recompute_Active_Find_Matches (S);
         Select_Active_Find_Nearest_Caret (S);
      else
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := True;
         S.Active_Find_Source_Buffer_Token := 0;
      end if;
   end Recompute_Find_After_Option_Change;

   procedure Move_To_Find_Match
     (S        : in out Editor.State.State_Type;
      Match    : Editor.Search.Search_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
      Reason   : Editor.Navigation_History.Navigation_History_Reason)
   is
      pragma Unreferenced (Previous);
      Effective_Previous : Editor.Navigation_History.Navigation_Location;
      Target : Editor.Navigation_History.Navigation_Location;
   begin
      if not Editor.Buffers.Global_Registry_Current_For (S) then
         Editor.Buffers.Ensure_Global_Registry (S);
      end if;
      Effective_Previous := Current_Navigation_Location (S, Reason);

      S.Active_Find_Match := Match;
      Apply_Feature_Target_Handoff (S, Match.Start_Row, Match.Start_Column);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Match.Start_Index,
           Anchor                => Match.Start_Index,
           Virtual_Column        => 0,
           Anchor_Virtual_Column => 0));
      S.Preferred_Column := Match.Start_Column;

      Target :=
        (Buffer_Id      => Active_Feature_Buffer_Token (S),
         Has_File_Path  => S.File_Info.Has_Path,
         File_Path      => S.File_Info.Path,
         Display_Path   => S.File_Info.Display_Name,
         Line           => Natural (Match.Start_Row) + 1,
         Column         => Natural (Match.Start_Column),
         Viewport_Row   => Editor.View.Scroll_Y,
         Reason         => Reason);
      Record_Navigation_If_Target_Changed (S, Effective_Previous, Target);
   end Move_To_Find_Match;

   procedure Set_Active_Find_Query_And_Report
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
      Query : constant String := Text;
      Count : Natural := 0;
   begin
      Editor.Input_Field.Set_Text (S.Active_Find_Input, Query);
      S.Active_Find_Query := To_Unbounded_String (Query);

      if Query'Length = 0 then
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := False;
         S.Active_Find_Source_Buffer_Token := 0;
         Report_Info (S, "No find query");
      elsif not Has_Find_Target_Buffer (S) then
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := True;
         S.Active_Find_Source_Buffer_Token := 0;
         Report_Warning (S, "No active buffer.");
      else
         Recompute_Active_Find_Matches (S);
         Select_Active_Find_Nearest_Caret (S);
         Count := Natural (S.Active_Find_Matches.Length);
         if Count = 0 then
            Report_Info (S, "Find query set: no matches");
         else
            Report_Info (S, "Find query set: " & Image_Of (Count) & " matches");
         end if;
      end if;
   end Set_Active_Find_Query_And_Report;

   procedure Execute_Find_Case_Toggle
     (S : in out Editor.State.State_Type)
   is
      Include_Count : constant Boolean := Length (S.Active_Find_Query) > 0;
   begin
      S.Active_Find_Case_Sensitive := not S.Active_Find_Case_Sensitive;
      Recompute_Find_After_Option_Change (S);
      Report_Info
        (S,
         Find_Option_Message
           (S,
            (if S.Active_Find_Case_Sensitive
             then "Find case: sensitive"
             else "Find case: insensitive"),
            Include_Count and then Has_Find_Target_Buffer (S)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Case_Toggle;

   procedure Execute_Find_Case_Clear
     (S : in out Editor.State.State_Type)
   is
      Include_Count : constant Boolean := Length (S.Active_Find_Query) > 0;
   begin
      if not S.Active_Find_Case_Sensitive then
         Report_Info (S, "Find case already insensitive");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      S.Active_Find_Case_Sensitive := False;
      Recompute_Find_After_Option_Change (S);
      Report_Info
        (S,
         Find_Option_Message
           (S, "Find case: insensitive",
            Include_Count and then Has_Find_Target_Buffer (S)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Case_Clear;

   procedure Execute_Find_Whole_Word_Toggle
     (S : in out Editor.State.State_Type)
   is
      Include_Count : constant Boolean := Length (S.Active_Find_Query) > 0;
   begin
      S.Active_Find_Whole_Word := not S.Active_Find_Whole_Word;
      Recompute_Find_After_Option_Change (S);
      Report_Info
        (S,
         Find_Option_Message
           (S,
            (if S.Active_Find_Whole_Word
             then "Find whole word: on"
             else "Find whole word: off"),
            Include_Count and then Has_Find_Target_Buffer (S)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Whole_Word_Toggle;

   procedure Execute_Find_Whole_Word_Clear
     (S : in out Editor.State.State_Type)
   is
      Include_Count : constant Boolean := Length (S.Active_Find_Query) > 0;
   begin
      if not S.Active_Find_Whole_Word then
         Report_Info (S, "Find whole word already off");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      S.Active_Find_Whole_Word := False;
      Recompute_Find_After_Option_Change (S);
      Report_Info
        (S,
         Find_Option_Message
           (S, "Find whole word: off",
            Include_Count and then Has_Find_Target_Buffer (S)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Whole_Word_Clear;

   function Find_Match_Contains_Caret
     (S     : Editor.State.State_Type;
      Match : Editor.Search.Search_Match) return Boolean
   is
      Origin : Natural := 0;
   begin
      if S.Carets.Length > 0 then
         Origin := Natural (Safe_Caret (S));
      end if;

      return Origin >= Natural (Match.Start_Index)
        and then Origin < Natural (Match.End_Index);
   end Find_Match_Contains_Caret;

   function Find_Ordinal_Containing_Caret
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      for M of S.Active_Find_Matches loop
         if Find_Match_Contains_Caret (S, M) then
            return Natural (M.Index);
         end if;
      end loop;

      return 0;
   end Find_Ordinal_Containing_Caret;

   function Find_Ordinal_For_Current_Caret
     (S : Editor.State.State_Type) return Natural
   is
      Containing : constant Natural := Find_Ordinal_Containing_Caret (S);
   begin
      if Containing /= 0 then
         return Containing;
      end if;
      return First_Find_Ordinal_At_Or_After_Caret (S);
   end Find_Ordinal_For_Current_Caret;

   procedure Execute_Find_Next
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Ordinal : Natural := 0;
      Prior_Ordinal : Natural := 0;
      Wrapped : Boolean := False;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Prior_Ordinal :=
        (if Active_Find_Match_Is_Selected (S)
           or else Active_Find_Match_Is_Current (S)
         then Selected_Find_Ordinal (S)
         else 0);
      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Prior_Ordinal = 0 or else Prior_Ordinal > Count then
         Ordinal := First_Find_Ordinal_At_Or_After_Caret (S);
         Wrapped := Ordinal = 1
           and then S.Carets.Length > 0
           and then Natural (Safe_Caret (S)) > Natural (S.Active_Find_Matches (S.Active_Find_Matches.Last_Index).Start_Index);
      else
         Ordinal := Prior_Ordinal + 1;
         if Ordinal > Count then
            Ordinal := 1;
            Wrapped := True;
         end if;
      end if;

      S.Active_Find_Wrapped := Wrapped;
      Match := Find_Match_By_Ordinal (S, Ordinal);
      Previous := Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Find_Next);
      Move_To_Find_Match
        (S, Match, Previous, Editor.Navigation_History.Navigation_Reason_Find_Next);
      Report_Success
        (S, "Found match " & Image_Of (Ordinal) & " of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Next;

   procedure Execute_Find_Previous
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Ordinal : Natural := 0;
      Prior_Ordinal : Natural := 0;
      Wrapped : Boolean := False;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Prior_Ordinal :=
        (if Active_Find_Match_Is_Selected (S)
           or else Active_Find_Match_Is_Current (S)
         then Selected_Find_Ordinal (S)
         else 0);
      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Prior_Ordinal = 0 or else Prior_Ordinal > Count then
         Ordinal := First_Find_Ordinal_Before_Caret (S);
         Wrapped := Ordinal = Count
           and then S.Carets.Length > 0
           and then Natural (Safe_Caret (S)) <= Natural (S.Active_Find_Matches (S.Active_Find_Matches.First_Index).Start_Index);
      else
         Ordinal := Prior_Ordinal;
         if Ordinal <= 1 then
            Ordinal := Count;
            Wrapped := True;
         else
            Ordinal := Ordinal - 1;
         end if;
      end if;

      S.Active_Find_Wrapped := Wrapped;
      Match := Find_Match_By_Ordinal (S, Ordinal);
      Previous := Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Find_Previous);
      Move_To_Find_Match
        (S, Match, Previous, Editor.Navigation_History.Navigation_Reason_Find_Previous);
      Report_Success
        (S, "Found previous match " & Image_Of (Ordinal) & " of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Previous;

   procedure Execute_Find_First
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Match := Find_Match_By_Ordinal (S, 1);
      Previous := Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Find_Next);
      Move_To_Find_Match
        (S, Match, Previous, Editor.Navigation_History.Navigation_Reason_Find_Next);
      Report_Success
        (S, "Found first match 1 of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_First;

   procedure Execute_Find_Last
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Match := Find_Match_By_Ordinal (S, Count);
      Previous := Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Find_Previous);
      Move_To_Find_Match
        (S, Match, Previous, Editor.Navigation_History.Navigation_Reason_Find_Previous);
      Report_Success
        (S, "Found last match " & Image_Of (Count) & " of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Last;

   procedure Execute_Find_Reveal_Current
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Ordinal : Natural := 0;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Ordinal := Find_Ordinal_For_Current_Caret (S);
      S.Active_Find_Match := Find_Match_By_Ordinal (S, Ordinal);
      Report_Success
        (S, "Selected find match " & Image_Of (Ordinal) & " of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Reveal_Current;

end Editor.Executor.Active_Find_Commands;
