with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Feature_Panel;
with Editor.Outline.Activation; use Editor.Outline.Activation;
with Editor.Outline.Filtering; use Editor.Outline.Filtering;
with Editor.Outline.Projection; use Editor.Outline.Projection;

package body Editor.Outline.Selection is

   procedure Clear_Outline_Selection (Outline : in out Outline_State) is
   begin
      Outline.Selected := 0;
   end Clear_Outline_Selection;

   procedure Select_Item
     (Outline : in out Outline_State;
      Index   : Natural)
   is
   begin
      if Index = 0 or else Index > Item_Count (Outline) then
         Outline.Selected := 0;
      else
         Outline.Selected := Index;
      end if;
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Select_Item: " &
           Debug_Summary (Outline));
   end Select_Item;

   function Selected_Index
     (Outline : Outline_State) return Natural
   is
   begin
      if Outline.Selected <= Item_Count (Outline) then
         return Outline.Selected;
      end if;
      return 0;
   end Selected_Index;

   function Has_Selected_Item
     (Outline : Outline_State) return Boolean
   is
   begin
      return Selected_Index (Outline) /= 0;
   end Has_Selected_Item;


   procedure Clear_Current_Symbol
     (Outline : in out Outline_State)
   is
   begin
      Outline.Current_Symbol := 0;
      Outline.Has_Current := False;
      Outline.Current_Label := To_Unbounded_String ("");
      Outline.Current_Line := 0;
   end Clear_Current_Symbol;

   procedure Set_Current_Symbol_Index
     (Outline : in out Outline_State;
      Index   : Natural)
   is
   begin
      if Index = 0
        or else Index > Item_Count (Outline)
        or else not Is_Selectable_Target_Row (Outline, Positive (Index))
      then
         Clear_Current_Symbol (Outline);
      else
         Outline.Current_Symbol := Index;
         Outline.Has_Current := True;
         Outline.Current_Label := Outline.Items (Index - 1).Label;
         Outline.Current_Line := Outline.Items (Index - 1).Line;
      end if;
      pragma Assert
        (Invariant_Holds (Outline),
         "Outline invariant failed after Set_Current_Symbol_Index: " &
           Debug_Summary (Outline));
   end Set_Current_Symbol_Index;

   function Current_Symbol_Index
     (Outline : Outline_State) return Natural
   is
   begin
      if Outline.Has_Current
        and then Outline.Current_Symbol /= 0
        and then Outline.Current_Symbol <= Item_Count (Outline)
      then
         return Outline.Current_Symbol;
      end if;
      return 0;
   end Current_Symbol_Index;

   function Has_Current_Symbol
     (Outline : Outline_State) return Boolean
   is
   begin
      return Current_Symbol_Index (Outline) /= 0;
   end Has_Current_Symbol;

   function Current_Symbol_Label
     (Outline : Outline_State) return String
   is
   begin
      if Has_Current_Symbol (Outline) then
         return To_String (Outline.Current_Label);
      end if;
      return "";
   end Current_Symbol_Label;

   function Current_Symbol_Line
     (Outline : Outline_State) return Natural
   is
   begin
      if Has_Current_Symbol (Outline) then
         return Outline.Current_Line;
      end if;
      return 0;
   end Current_Symbol_Line;


   function Detail_Range_End_Line (Detail : String) return Natural
   is
      Dash  : Natural := 0;
      Value : Natural := 0;
      I     : Natural;
   begin
      if Ada.Strings.Fixed.Index (Detail, "lines ") /= Detail'First then
         return 0;
      end if;

      for J in Detail'Range loop
         if Detail (J) = '-' then
            Dash := J;
            exit;
         end if;
      end loop;

      if Dash = 0 or else Dash = Detail'Last then
         return 0;
      end if;

      I := Dash + 1;
      while I <= Detail'Last
        and then Detail (I) >= '0'
        and then Detail (I) <= '9'
      loop
         Value := Value * 10 + Character'Pos (Detail (I)) - Character'Pos ('0');
         I := I + 1;
      end loop;

      return Value;
   end Detail_Range_End_Line;

   function Find_Enclosing_Ranged_Item_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural
   is
      pragma Unreferenced (Column);
      Best       : Natural := 0;
      Best_Span  : Natural := Natural'Last;
      Best_Depth : Natural := 0;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
         then
            declare
               Start_Line : constant Natural := Item_Line (Outline, I);
               End_Line   : constant Natural :=
                 Detail_Range_End_Line (To_String (Outline.Items (I - 1).Detail));
            begin
               if End_Line > Start_Line
                 and then Start_Line <= Line
                 and then Line <= End_Line
               then
                  declare
                     Span  : constant Natural := End_Line - Start_Line;
                     Depth : constant Natural := Item_Depth (Outline, I);
                  begin
                     if Best = 0
                       or else Span < Best_Span
                       or else (Span = Best_Span and then Depth > Best_Depth)
                     then
                        Best := I;
                        Best_Span := Span;
                        Best_Depth := Depth;
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;

      return Best;
   end Find_Enclosing_Ranged_Item_For_Position;

   function Find_Current_Symbol_For_Cursor
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural
   is
      Nearest_On_Line : constant Natural :=
        Find_Nearest_Item_For_Position
          (Outline, Buffer_Token, Line, Natural'Last);
      Nearest : constant Natural :=
        Find_Nearest_Item_For_Position (Outline, Buffer_Token, Line, Column);
      Ranged : constant Natural :=
        Find_Enclosing_Ranged_Item_For_Position
          (Outline, Buffer_Token, Line, Column);
   begin
      if Nearest_On_Line /= 0
        and then Item_Line (Outline, Positive (Nearest_On_Line)) = Line
      then
         return Nearest_On_Line;
      end if;

      if Ranged /= 0 then
         return Ranged;
      end if;

      return Nearest;
   end Find_Current_Symbol_For_Cursor;

   procedure Update_Current_Symbol_For_Cursor
     (Outline      : in out Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1)
   is
   begin
      Set_Current_Symbol_Index
        (Outline, Find_Current_Symbol_For_Cursor (Outline, Buffer_Token, Line, Column));
   end Update_Current_Symbol_For_Cursor;

   function Outline_Header_Text
     (Outline : Outline_State) return String
   is
      Count          : constant Natural := Navigable_Symbol_Count (Outline);
      Filtered_Count : constant Natural := Filtered_Navigable_Symbol_Count (Outline);
   begin
      case Outline.Source is
         when Extracted_Outline =>
            if Outline.Last_Extraction_Source = Stale_Extracted_Outline then
               return "Outline: stale";
            elsif Outline.Filter_Active or else Outline.Filter_Input_Active then
               if Filtered_Count = 0 and then Outline.Filter_Active then
                  return "Outline: filter """ & Filter_Text (Outline) & """ -- no matches";
               elsif Outline.Filter_Active then
                  return "Outline: filter """ & Filter_Text (Outline) & """ --" &
                    Natural'Image (Filtered_Count) &
                    " of" & Natural'Image (Count) & " symbols";
               else
                  return "Outline: filter --" & Natural'Image (Count) & " symbols";
               end if;
            elsif Has_Current_Symbol (Outline) then
               return "Outline: " & Current_Symbol_Label (Outline);
            elsif Count = 0 then
               return "Outline: no items";
            elsif Count = 1 then
               return "Outline: 1 symbol";
            else
               return "Outline:" & Natural'Image (Count) & " symbols";
            end if;
         when Unsupported_Content =>
            if To_String (Outline.Last_Extraction_Message) = Message_Outline_No_Symbols then
               return "Outline: no items";
            else
               return "Outline: unavailable";
            end if;
         when Extraction_Failed =>
            return "Outline: refresh failed";
         when Stale_Extracted_Outline =>
            return "Outline: may be stale";
         when No_Outline =>
            return "Outline: not refreshed";
      end case;
   end Outline_Header_Text;


   function Outline_Empty_State_Label
     (Outline : Outline_State) return String
   is
   begin
      case Outline.Source is
         when No_Outline =>
            if To_String (Outline.Last_Extraction_Message) = Message_Outline_No_Active_Buffer then
               return "No active buffer.";
            else
               return "Outline not refreshed.";
            end if;
         when Unsupported_Content =>
            if To_String (Outline.Last_Extraction_Message) = Message_Outline_No_Symbols then
               return "No outline items found.";
            else
               declare
                  Message : constant String :=
                    To_String (Outline.Last_Extraction_Message);
               begin
                  if Message'Length = 0 then
                     return "Outline unavailable for this buffer.";
                  elsif Message (Message'Last) = '.' then
                     return Message;
                  else
                     return Message & ".";
                  end if;
               end;
            end if;
         when Extraction_Failed =>
            return "Outline refresh failed.";
         when Stale_Extracted_Outline =>
            return "Outline may be stale.";
         when Extracted_Outline =>
            return "No outline items found.";
      end case;
   end Outline_Empty_State_Label;

   function Is_Current_Symbol_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean
   is
   begin
      return Has_Current_Symbol (Outline)
        and then Current_Symbol_Index (Outline) = Index
        and then Is_Selectable_Target_Row (Outline, Index);
   end Is_Current_Symbol_Row;

   function Is_Selectable_Target_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean
   is
      Item : constant Outline_Item := Outline.Items (Index - 1);
   begin
      return Outline.Source = Extracted_Outline
        and then Item.Target_Kind = Buffer_Position_Target
        and then Item.Buffer_Token /= 0
        and then Item.Line /= 0
        and then Item.Kind not in Outline_Header | Outline_Section;
   end Is_Selectable_Target_Row;

   function Has_Selectable_Filter_Match
     (Outline : Outline_State) return Boolean
   is
   begin
      if Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
      then
         return False;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I)
           and then Is_Selectable_Target_Row (Outline, I)
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Selectable_Filter_Match;

   function Navigable_Symbol_Count
     (Outline : Outline_State) return Natural
   is
      Count : Natural := 0;
   begin
      if Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
      then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Navigable_Symbol_Count;

   function Filtered_Navigable_Symbol_Count
     (Outline : Outline_State) return Natural
   is
      Count : Natural := 0;
   begin
      if Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
      then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I)
           and then Is_Selectable_Target_Row (Outline, I)
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Filtered_Navigable_Symbol_Count;


   function Can_Reveal_Current_Symbol
     (Outline             : Outline_State;
      Panel               : Editor.Feature_Panel.Feature_Panel_State;
      Active_Buffer_Token : Natural) return Boolean
   is
      Index : constant Natural := Current_Symbol_Index (Outline);
   begin
      if Index = 0
        or else Active_Buffer_Token = 0
        or else Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
        or else Index > Item_Count (Outline)
      then
         return False;
      end if;

      declare
         Visible : constant Natural := Visible_Row_For_Outline_Row (Outline, Index);
      begin
         if Visible = 0 or else Visible > Editor.Feature_Panel.Row_Count (Panel) then
            return False;
         end if;
         return Is_Selectable_Target_Row (Outline, Positive (Index))
           and then Item_Buffer_Token (Outline, Positive (Index)) = Active_Buffer_Token
           and then Feature_Row_Maps_To_Item (Outline, Panel, Positive (Visible))
           and then Editor.Feature_Panel.Row_Is_Current_Symbol (Panel, Positive (Visible));
      end;
   end Can_Reveal_Current_Symbol;

   function Same_Outline_Target
     (Left, Right : Outline_Item) return Boolean
   is
   begin
      return Left.Target_Kind = Buffer_Position_Target
        and then Right.Target_Kind = Buffer_Position_Target
        and then Left.Buffer_Token /= 0
        and then Left.Buffer_Token = Right.Buffer_Token
        and then Left.Line = Right.Line
        and then Left.Column = Right.Column;
   end Same_Outline_Target;

   function Same_Outline_Symbol
     (Left, Right : Outline_Item) return Boolean
   is
   begin
      return Same_Outline_Target (Left, Right)
        and then Left.Kind = Right.Kind
        and then To_String (Left.Label) = To_String (Right.Label)
        and then Left.Depth = Right.Depth;
   end Same_Outline_Symbol;

   function Outline_Buffer_Identity_Matches
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean
   is
      Saw_Navigable : Boolean := False;
   begin
      if Buffer_Token = 0
        or else Outline.Source /= Extracted_Outline
        or else Outline.Last_Extraction_Source = Stale_Extracted_Outline
      then
         return False;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I) then
            Saw_Navigable := True;
            if Item_Buffer_Token (Outline, I) /= Buffer_Token then
               return False;
            end if;
         end if;
      end loop;

      return Saw_Navigable;
   end Outline_Buffer_Identity_Matches;

   function Has_Navigable_Symbol_For_Buffer
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean
   is
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return False;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Navigable_Symbol_For_Buffer;

   function Selection_Preservation_Score
     (Previous, Candidate : Outline_Item) return Natural
   is
      Score : Natural := 0;
      Prev_Label : constant String := To_String (Previous.Label);
      Cand_Label : constant String := To_String (Candidate.Label);
   begin
      if Previous.Target_Kind /= Buffer_Position_Target
        or else Candidate.Target_Kind /= Buffer_Position_Target
        or else Previous.Buffer_Token = 0
        or else Previous.Buffer_Token /= Candidate.Buffer_Token
        or else Candidate.Line = 0
      then
         return 0;
      end if;

      if Same_Outline_Symbol (Previous, Candidate) then
         return 1_000;
      end if;

      if Same_Outline_Target (Previous, Candidate) then
         Score := 800;
      end if;

      if Previous.Kind = Candidate.Kind and then Prev_Label = Cand_Label then
         if Previous.Line = Candidate.Line then
            Score := Natural'Max (Score, 700);
         elsif (if Previous.Line > Candidate.Line
                then Previous.Line - Candidate.Line
                else Candidate.Line - Previous.Line) <= 3
         then
            Score := Natural'Max (Score, 600);
         else
            Score := Natural'Max (Score, 500);
         end if;
      end if;

      if Candidate.Line <= Previous.Line then
         declare
            Distance : constant Natural := Previous.Line - Candidate.Line;
         begin
            if Distance < 100 then
               Score := Natural'Max (Score, 300 - Distance);
            end if;
         end;
      end if;

      return Score;
   end Selection_Preservation_Score;

   function Find_Nearest_Item_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural
   is
      Best       : Natural := 0;
      Best_Line  : Natural := 0;
      Best_Col   : Natural := 0;
      Best_Depth : Natural := Natural'Last;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
           and then Item_Line (Outline, I) <= Line
           and then (Item_Line (Outline, I) < Line
                     or else Item_Column (Outline, I) <= Column)
         then
            declare
               Candidate_Line  : constant Natural := Item_Line (Outline, I);
               Candidate_Col   : constant Natural := Item_Column (Outline, I);
               Candidate_Depth : constant Natural := Item_Depth (Outline, I);
            begin
               if Best = 0
                 or else Candidate_Line > Best_Line
                 or else (Candidate_Line = Best_Line
                          and then Candidate_Col > Best_Col)
                 or else (Candidate_Line = Best_Line
                          and then Candidate_Col = Best_Col
                          and then Candidate_Depth < Best_Depth)
               then
                  Best := I;
                  Best_Line := Candidate_Line;
                  Best_Col := Candidate_Col;
                  Best_Depth := Candidate_Depth;
               end if;
            end;
         end if;
      end loop;

      return Best;
   end Find_Nearest_Item_For_Position;

   function Position_Is_After
     (Candidate_Line   : Natural;
      Candidate_Column : Natural;
      Line             : Positive;
      Column           : Natural) return Boolean
   is
   begin
      return Candidate_Line > Line
        or else (Candidate_Line = Line and then Candidate_Column > Column);
   end Position_Is_After;

   function Position_Is_Before
     (Candidate_Line   : Natural;
      Candidate_Column : Natural;
      Line             : Positive;
      Column           : Natural) return Boolean
   is
   begin
      return Candidate_Line < Line
        or else (Candidate_Line = Line and then Candidate_Column < Column);
   end Position_Is_Before;

   function Candidate_Is_Before_Best
     (Outline   : Outline_State;
      Candidate : Positive;
      Best      : Natural) return Boolean
   is
   begin
      if Best = 0 then
         return True;
      end if;

      return Item_Line (Outline, Candidate) < Item_Line (Outline, Positive (Best))
        or else
          (Item_Line (Outline, Candidate) = Item_Line (Outline, Positive (Best))
           and then Item_Column (Outline, Candidate) <
             Item_Column (Outline, Positive (Best)))
        or else
          (Item_Line (Outline, Candidate) = Item_Line (Outline, Positive (Best))
           and then Item_Column (Outline, Candidate) =
             Item_Column (Outline, Positive (Best))
           and then Candidate < Best);
   end Candidate_Is_Before_Best;

   function Candidate_Is_After_Best
     (Outline   : Outline_State;
      Candidate : Positive;
      Best      : Natural) return Boolean
   is
   begin
      if Best = 0 then
         return True;
      end if;

      return Item_Line (Outline, Candidate) > Item_Line (Outline, Positive (Best))
        or else
          (Item_Line (Outline, Candidate) = Item_Line (Outline, Positive (Best))
           and then Item_Column (Outline, Candidate) >
             Item_Column (Outline, Positive (Best)))
        or else
          (Item_Line (Outline, Candidate) = Item_Line (Outline, Positive (Best))
           and then Item_Column (Outline, Candidate) =
             Item_Column (Outline, Positive (Best))
           and then Candidate > Best);
   end Candidate_Is_After_Best;

   function Find_Next_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural
   is
      Best       : Natural := 0;
      Wrap_Best  : Natural := 0;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
         then
            if Position_Is_After (Item_Line (Outline, I), Item_Column (Outline, I), Line, Column)
              and then Candidate_Is_Before_Best (Outline, I, Best)
            then
               Best := I;
            elsif Wrap and then Candidate_Is_Before_Best (Outline, I, Wrap_Best) then
               Wrap_Best := I;
            end if;
         end if;
      end loop;

      if Best /= 0 then
         return Best;
      end if;
      return Wrap_Best;
   end Find_Next_Symbol_For_Position;

   function Find_Previous_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural
   is
      Best       : Natural := 0;
      Wrap_Best  : Natural := 0;
   begin
      if not Outline_Buffer_Identity_Matches (Outline, Buffer_Token) then
         return 0;
      end if;

      for I in 1 .. Item_Count (Outline) loop
         if Is_Selectable_Target_Row (Outline, I)
           and then Item_Buffer_Token (Outline, I) = Buffer_Token
         then
            if Position_Is_Before (Item_Line (Outline, I), Item_Column (Outline, I), Line, Column)
              and then Candidate_Is_After_Best (Outline, I, Best)
            then
               Best := I;
            elsif Wrap and then Candidate_Is_After_Best (Outline, I, Wrap_Best) then
               Wrap_Best := I;
            end if;
         end if;
      end loop;

      if Best /= 0 then
         return Best;
      end if;
      return Wrap_Best;
   end Find_Previous_Symbol_For_Position;

   function Select_Next_Selectable
     (Outline : in out Outline_State) return Boolean
   is
      Start : constant Natural := Selected_Index (Outline);
   begin
      for I in Start + 1 .. Item_Count (Outline) loop
         if Row_Matches_Filter (Outline, I)
           and then Is_Selectable_Target_Row (Outline, I) then
            Select_Item (Outline, I);
            return True;
         end if;
      end loop;

      if Start = 0 then
         for I in 1 .. Item_Count (Outline) loop
            if Row_Matches_Filter (Outline, I)
              and then Is_Selectable_Target_Row (Outline, I) then
               Select_Item (Outline, I);
               return True;
            end if;
         end loop;
      end if;

      return False;
   end Select_Next_Selectable;

   function Select_Previous_Selectable
     (Outline : in out Outline_State) return Boolean
   is
      Start : constant Natural :=
        (if Selected_Index (Outline) = 0
         then Item_Count (Outline) + 1
         else Selected_Index (Outline));
   begin
      if Start > 1 then
         for I in reverse 1 .. Start - 1 loop
            if Row_Matches_Filter (Outline, I)
              and then Is_Selectable_Target_Row (Outline, I) then
               Select_Item (Outline, I);
               return True;
            end if;
         end loop;
      end if;

      return False;
   end Select_Previous_Selectable;

end Editor.Outline.Selection;
