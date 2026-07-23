with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Files;
with Editor.Project_Search.Utilities;

package body Editor.Project_Search.Replace_Preview is

   procedure Clear_Replace_Preview_State
     (State : in out Project_Search_State)
   is
   begin
      State.Replace_Rows.Clear;
      State.Replace_Selected_Index := 0;
      State.Replace_Status_Value := Project_Replace_No_Preview;
      State.Replace_Stale := False;
      State.Replace_Search_Token := 0;
   end Clear_Replace_Preview_State;

   function Replacement_Text_Is_Valid
     (Text : String) return Boolean
   is
   begin
      return Editor.Project_Search.Utilities.Replacement_Text_Is_Valid (Text);
   end Replacement_Text_Is_Valid;

   procedure Set_Replace_Text
     (State : in out Project_Search_State;
      Text  : String)
   is
      Text_Changed : constant Boolean :=
        To_String (State.Replace_Text_Value) /= Text;
   begin
      --  Calling Set_Replace_Text is itself explicit replacement-input
      --  intent.  This matters for delete-matches workflows where the
      --  replacement text is deliberately empty and may equal the initial
      --  default value.  The preview is only cleared when the actual text
      --  changes, so a harmless resync from the search bar does not discard an
      --  already-generated preview.
      State.Replace_Mode := True;

      if Text_Changed then
         State.Replace_Text_Value := To_Unbounded_String (Text);
         Clear_Replace_Preview_State (State);
      end if;
   end Set_Replace_Text;

   function Replace_Text
     (State : Project_Search_State) return String
   is
   begin
      return To_String (State.Replace_Text_Value);
   end Replace_Text;

   function Replace_Text_Is_Valid
     (State : Project_Search_State) return Boolean
   is
   begin
      return Replacement_Text_Is_Valid (To_String (State.Replace_Text_Value));
   end Replace_Text_Is_Valid;

   function Replace_Mode_Active
     (State : Project_Search_State) return Boolean
   is
   begin
      return State.Replace_Mode;
   end Replace_Mode_Active;

   procedure Set_Replace_Mode_Active
     (State  : in out Project_Search_State;
      Active : Boolean)
   is
   begin
      State.Replace_Mode := Active;
      if not Active then
         Clear_Replace_Preview_State (State);
      end if;
   end Set_Replace_Mode_Active;

   procedure Clear_Replace_Preview
     (State : in out Project_Search_State)
   is
   begin
      Clear_Replace_Preview_State (State);
   end Clear_Replace_Preview;

   function Build_Replacement_Line
     (Line       : String;
      Start_Col  : Natural;
      End_Col    : Natural;
      Replace_By : String) return String
   is
      Start_Index  : Natural := 0;
      Before_Last  : Natural := 0;
      After_First  : Natural := 0;
   begin
      if End_Col < Start_Col or else Start_Col > Line'Length then
         return Line;
      end if;

      Start_Index := Line'First + Start_Col;
      Before_Last := Start_Index - 1;
      After_First := Line'First + End_Col;

      return (if Start_Col > 0 and then Before_Last >= Line'First
              then Line (Line'First .. Before_Last)
              else "")
        & Replace_By
        & (if After_First <= Line'Last then Line (After_First .. Line'Last) else "");
   end Build_Replacement_Line;

   function Replacement_Excerpt
     (Text : String) return String
   is
   begin
      return Build_Project_Search_Line_Preview
        (Line         => Text,
         Match_Column => 1,
         Match_Length => Natural'Max (1, Text'Length),
         Max_Length   => Max_Search_Result_Preview_Length);
   end Replacement_Excerpt;

   function Is_UTF8_Boundary
     (Line        : String;
      Byte_Offset : Natural) return Boolean
   is
      Next_Index : Natural := 0;
      Next_Byte  : Natural := 0;
   begin
      if Byte_Offset = 0 or else Byte_Offset = Line'Length then
         return True;
      elsif Byte_Offset > Line'Length then
         return False;
      end if;

      --  Project Search result columns are byte offsets.  A valid replacement
      --  range must start and end on UTF-8 code point boundaries because the
      --  buffer editing path addresses code point columns.  Offsets that point
      --  before a continuation byte would split a multibyte character and must
      --  become invalid preview rows instead of later applying an ambiguous
      --  partial-codepoint edit.
      Next_Index := Line'First + Byte_Offset;
      Next_Byte := Character'Pos (Line (Next_Index));
      return not (Next_Byte in 16#80# .. 16#BF#);
   end Is_UTF8_Boundary;

   function Extract_Result_Match_Text
     (Line      : String;
      Start_Col : Natural;
      End_Col   : Natural;
      Valid     : out Boolean) return Unbounded_String
   is
      Start_Index : Natural := 0;
      Last_Index  : Natural := 0;
   begin
      Valid := End_Col > Start_Col
        and then Start_Col < Line'Length
        and then End_Col <= Line'Length
        and then Is_UTF8_Boundary (Line, Start_Col)
        and then Is_UTF8_Boundary (Line, End_Col);

      if not Valid then
         return Null_Unbounded_String;
      end if;

      Start_Index := Line'First + Start_Col;
      Last_Index := Line'First + End_Col - 1;
      return To_Unbounded_String (Line (Start_Index .. Last_Index));
   end Extract_Result_Match_Text;

   procedure Generate_Replace_Preview
     (State : in out Project_Search_State;
      Status : out Project_Replace_Preview_Status)
   is
      Replacement : constant String := To_String (State.Replace_Text_Value);
      Result            : Project_Search_Result;
      Row               : Project_Replace_Preview_Row;
      After_Line        : Unbounded_String;
      Valid_Row_Count   : Natural := 0;
      Preferred_Selected_Index : Natural := 0;
   begin
      Clear_Replace_Preview_State (State);
      State.Replace_Mode := True;

      if not Replacement_Text_Is_Valid (Replacement) then
         Status := Project_Replace_Invalid_Replacement_Text;
         State.Replace_Status_Value := Status;
         return;
      elsif Natural (State.Results.Length) = 0 then
         Status := Project_Replace_No_Search_Results;
         State.Replace_Status_Value := Status;
         return;
      elsif State.Stale then
         Status := Project_Replace_Search_Stale;
         State.Replace_Status_Value := Status;
         State.Replace_Stale := True;
         return;
      end if;

      for I in 1 .. Natural (State.Results.Length) loop
         Result := State.Results (I - 1);
         declare
            Line_Text_Str    : constant String := To_String (Result.Line_Text);
            Match_Valid      : Boolean := False;
            Match_Text_Value : constant Unbounded_String :=
              Extract_Result_Match_Text
                (Line      => Line_Text_Str,
                 Start_Col => Result.Start_Column,
                 End_Col   => Result.End_Column,
                 Valid     => Match_Valid);
         begin
            if Match_Valid then
               After_Line := To_Unbounded_String
                 (Build_Replacement_Line
                    (Line       => Line_Text_Str,
                     Start_Col  => Result.Start_Column,
                     End_Col    => Result.End_Column,
                     Replace_By => Replacement));
            else
               --  Invalid/drifted search-result ranges must remain purely
               --  diagnostic preview rows.  Do not even build a synthetic
               --  replacement line from an invalid target range: that can
               --  make a stale row look safely previewable and couples the
               --  preview renderer to undefined offset semantics.
               After_Line := To_Unbounded_String (Line_Text_Str);
            end if;

            Row :=
              (Search_Result_Id   => Result.Id,
               Relative_Path       => Result.Relative_Path,
               Absolute_Path       => Result.Absolute_Path,
               Row                 => Result.Row,
               Start_Column        => Result.Start_Column,
               End_Column          => Result.End_Column,
               Before_Excerpt      => Result.Line_Preview,
               After_Excerpt       =>
                 (if Match_Valid then
                    To_Unbounded_String
                      (Build_Project_Search_Line_Preview
                         (Line         => To_String (After_Line),
                          Match_Column => Result.Start_Column + 1,
                          Match_Length => Natural'Max (1, Replacement'Length),
                          Max_Length   => Max_Search_Result_Preview_Length))
                  else Result.Line_Preview),
               Match_Text          => Match_Text_Value,
               Replacement_Excerpt => To_Unbounded_String (Replacement_Excerpt (Replacement)),
               Included            => Match_Valid,
               Stale               => False,
               Invalid             => not Match_Valid,
               Selected            => False);
            State.Replace_Rows.Append (Row);
            if Natural (State.Replace_Rows.Length) = State.Selected_Index then
               --  Keep replacement-preview selection aligned with the visible
               --  Project Search result selection.  Invalid/stale rows remain
               --  excluded and ineligible, but selection identity must not
               --  silently jump to another result and make ``replace
               --  selected'' target a row the user did not select.
               Preferred_Selected_Index := Natural (State.Replace_Rows.Length);
            end if;

            if Match_Valid then
               Valid_Row_Count := Valid_Row_Count + 1;
            end if;
         end;
      end loop;

      if Natural (State.Replace_Rows.Length) > 0 then
         --  Replacement-preview selection must mirror the visible Project
         --  Search result selection.  If the result list deliberately has no
         --  selected row, preview generation must keep replacement selection
         --  at zero instead of silently choosing the first valid replacement
         --  row and making ``replace selected'' target an unselected match.
         State.Replace_Selected_Index := Preferred_Selected_Index;
         if State.Replace_Selected_Index in 1 .. Natural (State.Replace_Rows.Length) then
            Row := State.Replace_Rows (State.Replace_Selected_Index - 1);
            Row.Selected := True;
            State.Replace_Rows.Replace_Element (State.Replace_Selected_Index - 1, Row);
         end if;
      end if;

      State.Replace_Search_Token := State.Search_Token;
      State.Replace_Status_Value := Project_Replace_Preview_Ok;
      State.Replace_Stale := False;

      if Valid_Row_Count = 0 and then Natural (State.Replace_Rows.Length) > 0 then
         State.Replace_Status_Value := Project_Replace_Invalid_Target;
      elsif Included_Replacements_Overlap (State) then
         State.Replace_Status_Value := Project_Replace_Overlapping_Matches;
      end if;
      Status := State.Replace_Status_Value;
   end Generate_Replace_Preview;

   function Replace_Preview_Status
     (State : Project_Search_State) return Project_Replace_Preview_Status
   is
   begin
      return State.Replace_Status_Value;
   end Replace_Preview_Status;

   function Replace_Preview_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return Natural (State.Replace_Rows.Length);
   end Replace_Preview_Count;

   function Included_Replacement_Count
     (State : Project_Search_State) return Natural
   is
      Count : Natural := 0;
   begin
      if Replace_Preview_Is_Stale (State) then
         return 0;
      end if;

      for Row of State.Replace_Rows loop
         if Row.Included and then not Row.Stale and then not Row.Invalid then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Included_Replacement_Count;

   function Eligible_Replacement_Count
     (State : Project_Search_State) return Natural
   is
      Count : Natural := 0;
   begin
      if Replace_Preview_Is_Stale (State) then
         return 0;
      end if;

      for Row of State.Replace_Rows loop
         if not Row.Stale and then not Row.Invalid then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Eligible_Replacement_Count;

   function Eligible_Replacement_File_Count
     (State : Project_Search_State) return Natural
   is
      Count : Natural := 0;
      Seen  : Boolean;
   begin
      if Natural (State.Replace_Rows.Length) = 0
        or else Replace_Preview_Is_Stale (State)
      then
         return 0;
      end if;

      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         if not State.Replace_Rows (Natural (I)).Stale
           and then not State.Replace_Rows (Natural (I)).Invalid
         then
            Seen := False;
            for J in 0 .. I - 1 loop
               if not State.Replace_Rows (Natural (J)).Stale
                 and then not State.Replace_Rows (Natural (J)).Invalid
                 and then To_String (State.Replace_Rows (Natural (J)).Relative_Path) =
                   To_String (State.Replace_Rows (Natural (I)).Relative_Path)
               then
                  Seen := True;
               end if;
            end loop;
            if not Seen then
               Count := Count + 1;
            end if;
         end if;
      end loop;
      return Count;
   end Eligible_Replacement_File_Count;

   function Included_Replacement_File_Count
     (State : Project_Search_State) return Natural
   is
      Count : Natural := 0;
      Seen  : Boolean;
   begin
      if Natural (State.Replace_Rows.Length) = 0
        or else Replace_Preview_Is_Stale (State)
      then
         return 0;
      end if;

      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         if State.Replace_Rows (Natural (I)).Included
           and then not State.Replace_Rows (Natural (I)).Stale
           and then not State.Replace_Rows (Natural (I)).Invalid
         then
            Seen := False;
            for J in 0 .. I - 1 loop
               if State.Replace_Rows (Natural (J)).Included
                 and then not State.Replace_Rows (Natural (J)).Stale
                 and then not State.Replace_Rows (Natural (J)).Invalid
                 and then To_String (State.Replace_Rows (Natural (J)).Relative_Path) =
                   To_String (State.Replace_Rows (Natural (I)).Relative_Path)
               then
                  Seen := True;
               end if;
            end loop;
            if not Seen then
               Count := Count + 1;
            end if;
         end if;
      end loop;
      return Count;
   end Included_Replacement_File_Count;

   function Replace_Preview_Row_At
     (State : Project_Search_State;
      Index : Positive) return Project_Replace_Preview_Row
   is
   begin
      if Index > Natural (State.Replace_Rows.Length) then
         --  Out-of-range lookup must be a fail-closed row.  Direct executor
         --  paths defensively call this accessor after checking selection
         --  state, and a stale/corrupt selected index must never synthesize an
         --  apparently included replacement target with an empty path.
         return
           (Search_Result_Id => No_Project_Search_Result,
            Included         => False,
            Invalid          => True,
            others           => <>);
      end if;
      return State.Replace_Rows (Index - 1);
   end Replace_Preview_Row_At;

   function Selected_Replace_Preview_Index
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Replace_Selected_Index;
   end Selected_Replace_Preview_Index;

   procedure Refresh_Replace_Status
     (State : in out Project_Search_State);

   procedure Set_Selected_Replace_Preview_Index
     (State : in out Project_Search_State;
      Index : Natural)
   is
      Row : Project_Replace_Preview_Row;
   begin
      if Natural (State.Replace_Rows.Length) = 0 then
         State.Replace_Selected_Index := 0;
         return;
      end if;

      if State.Replace_Selected_Index in 1 .. Natural (State.Replace_Rows.Length) then
         Row := State.Replace_Rows (State.Replace_Selected_Index - 1);
         Row.Selected := False;
         State.Replace_Rows.Replace_Element (State.Replace_Selected_Index - 1, Row);
      end if;

      if Index = 0 or else Index > Natural (State.Replace_Rows.Length) then
         --  A replacement selection index is a precise identity link to the
         --  visible Project Search result row.  Do not clamp corrupt or stale
         --  indexes to the last preview row: doing so can make
         --  ``replace selected'' target a different match than the one shown
         --  as selected in Project Search.  Fail closed with no selected
         --  replacement row instead.
         State.Replace_Selected_Index := 0;
         return;
      end if;

      State.Replace_Selected_Index := Index;
      Row := State.Replace_Rows (State.Replace_Selected_Index - 1);
      Row.Selected := True;
      State.Replace_Rows.Replace_Element (State.Replace_Selected_Index - 1, Row);
   end Set_Selected_Replace_Preview_Index;

   procedure Set_Selected_Included
     (State    : in out Project_Search_State;
      Included : Boolean)
   is
      Row : Project_Replace_Preview_Row;
   begin
      if State.Replace_Selected_Index in 1 .. Natural (State.Replace_Rows.Length) then
         Row := State.Replace_Rows (State.Replace_Selected_Index - 1);
         if Included and then (Row.Stale or else Row.Invalid) then
            Row.Included := False;
         else
            Row.Included := Included;
         end if;
         State.Replace_Rows.Replace_Element (State.Replace_Selected_Index - 1, Row);
         Refresh_Replace_Status (State);
      end if;
   end Set_Selected_Included;

   procedure Toggle_Selected_Replacement
     (State : in out Project_Search_State)
   is
      Row : Project_Replace_Preview_Row;
   begin
      if State.Replace_Selected_Index in 1 .. Natural (State.Replace_Rows.Length) then
         Row := State.Replace_Rows (State.Replace_Selected_Index - 1);
         if Row.Stale or else Row.Invalid then
            Row.Included := False;
         else
            Row.Included := not Row.Included;
         end if;
         State.Replace_Rows.Replace_Element (State.Replace_Selected_Index - 1, Row);
         Refresh_Replace_Status (State);
      end if;
   end Toggle_Selected_Replacement;

   procedure Include_Selected_Replacement
     (State : in out Project_Search_State)
   is
   begin
      Set_Selected_Included (State, True);
   end Include_Selected_Replacement;

   procedure Exclude_Selected_Replacement
     (State : in out Project_Search_State)
   is
   begin
      Set_Selected_Included (State, False);
   end Exclude_Selected_Replacement;

   procedure Set_File_Included
     (State         : in out Project_Search_State;
      Relative_Path : String;
      Included      : Boolean)
   is
      Row : Project_Replace_Preview_Row;
   begin
      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         Row := State.Replace_Rows (Natural (I));
         if To_String (Row.Relative_Path) = Relative_Path then
            if Included and then (Row.Stale or else Row.Invalid) then
               Row.Included := False;
            else
               Row.Included := Included;
            end if;
            State.Replace_Rows.Replace_Element (Natural (I), Row);
         end if;
      end loop;
      Refresh_Replace_Status (State);
   end Set_File_Included;

   procedure Include_File_Replacements
     (State : in out Project_Search_State;
      Relative_Path : String)
   is
   begin
      Set_File_Included (State, Relative_Path, True);
   end Include_File_Replacements;

   procedure Exclude_File_Replacements
     (State : in out Project_Search_State;
      Relative_Path : String)
   is
   begin
      Set_File_Included (State, Relative_Path, False);
   end Exclude_File_Replacements;

   procedure Include_All_Replacements
     (State : in out Project_Search_State)
   is
      Row : Project_Replace_Preview_Row;
   begin
      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         Row := State.Replace_Rows (Natural (I));
         Row.Included := not Row.Stale and then not Row.Invalid;
         State.Replace_Rows.Replace_Element (Natural (I), Row);
      end loop;
      Refresh_Replace_Status (State);
   end Include_All_Replacements;

   procedure Exclude_All_Replacements
     (State : in out Project_Search_State)
   is
      Row : Project_Replace_Preview_Row;
   begin
      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         Row := State.Replace_Rows (Natural (I));
         Row.Included := False;
         State.Replace_Rows.Replace_Element (Natural (I), Row);
      end loop;
      Refresh_Replace_Status (State);
   end Exclude_All_Replacements;

   function Replace_Preview_Is_Stale
     (State : Project_Search_State) return Boolean
   is
   begin
      return State.Replace_Stale
        or else (Natural (State.Replace_Rows.Length) > 0
                 and then State.Replace_Search_Token /= State.Search_Token);
   end Replace_Preview_Is_Stale;

   procedure Mark_Replace_Preview_Stale
     (State : in out Project_Search_State)
   is
      Row : Project_Replace_Preview_Row;
      Has_Retained_Replace_Context : constant Boolean :=
        State.Replace_Mode
        and then (Natural (State.Replace_Rows.Length) > 0
                  or else Length (State.Query_Text) > 0
                  or else Length (State.Last_Query_Text) > 0
                  or else State.Last_Status /= Project_Search_Idle
                  or else State.Replace_Status_Value /= Project_Replace_No_Preview);
   begin
      --  completeness: File Tree mutations stale replace preview
      --  state even when the previous preview had no rows.  A retained
      --  zero-result preview can become applicable after a file create/rename,
      --  so the preview status must not remain fresh merely because there are
      --  no rows to annotate.  Entirely idle/no-preview state remains fresh.
      if Has_Retained_Replace_Context then
         State.Replace_Stale := True;
         State.Replace_Status_Value := Project_Replace_Search_Stale;
      end if;

      if Natural (State.Replace_Rows.Length) > 0 then
         for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
            Row := State.Replace_Rows (Natural (I));
            Row.Stale := True;
            Row.Included := False;
            State.Replace_Rows.Replace_Element (Natural (I), Row);
         end loop;
      end if;
   end Mark_Replace_Preview_Stale;

   procedure Mark_Replace_Preview_Stale_For_File
     (State : in out Project_Search_State;
      Relative_Path : String)
   is
      Row : Project_Replace_Preview_Row;
   begin
      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         Row := State.Replace_Rows (Natural (I));
         if To_String (Row.Relative_Path) = Relative_Path then
            Row.Stale := True;
            Row.Included := False;
            State.Replace_Rows.Replace_Element (Natural (I), Row);
            State.Replace_Stale := True;
            State.Replace_Status_Value := Project_Replace_Search_Stale;
         end if;
      end loop;
   end Mark_Replace_Preview_Stale_For_File;

   procedure Mark_Replace_Preview_Stale_For_Absolute_File
     (State : in out Project_Search_State;
      Absolute_Path : String)
   is
      Row : Project_Replace_Preview_Row;

      function Same_Absolute_File (Left, Right : String) return Boolean is
      begin
         return Left = Right
           or else Editor.Files.Canonical_Path_For_Existing_File (Left) =
             Editor.Files.Canonical_Path_For_Existing_File (Right);
      end Same_Absolute_File;
   begin
      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         Row := State.Replace_Rows (Natural (I));
         if Same_Absolute_File (To_String (Row.Absolute_Path), Absolute_Path) then
            Row.Stale := True;
            Row.Included := False;
            State.Replace_Rows.Replace_Element (Natural (I), Row);
            State.Replace_Stale := True;
            State.Replace_Status_Value := Project_Replace_Search_Stale;
         end if;
      end loop;
   end Mark_Replace_Preview_Stale_For_Absolute_File;

   function Included_Replacements_Overlap
     (State : Project_Search_State) return Boolean
   is
      A : Project_Replace_Preview_Row;
      B : Project_Replace_Preview_Row;
   begin
      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         A := State.Replace_Rows (Natural (I));
         if A.Included and then not A.Stale and then not A.Invalid then
            for J in I + 1 .. Integer (State.Replace_Rows.Length) - 1 loop
               B := State.Replace_Rows (Natural (J));
               if B.Included
                 and then not B.Stale
                 and then not B.Invalid
                 and then To_String (A.Relative_Path) = To_String (B.Relative_Path)
                 and then A.Row = B.Row
                 and then A.Start_Column < B.End_Column
                 and then B.Start_Column < A.End_Column
               then
                  return True;
               end if;
            end loop;
         end if;
      end loop;
      return False;
   end Included_Replacements_Overlap;

   function Included_Replacements_Overlap_For_File
     (State         : Project_Search_State;
      Relative_Path : String) return Boolean
   is
      A : Project_Replace_Preview_Row;
      B : Project_Replace_Preview_Row;
   begin
      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         A := State.Replace_Rows (Natural (I));
         if A.Included
           and then not A.Stale
           and then not A.Invalid
           and then To_String (A.Relative_Path) = Relative_Path
         then
            for J in I + 1 .. Integer (State.Replace_Rows.Length) - 1 loop
               B := State.Replace_Rows (Natural (J));
               if B.Included
                 and then not B.Stale
                 and then not B.Invalid
                 and then To_String (B.Relative_Path) = Relative_Path
                 and then A.Row = B.Row
                 and then A.Start_Column < B.End_Column
                 and then B.Start_Column < A.End_Column
               then
                  return True;
               end if;
            end loop;
         end if;
      end loop;
      return False;
   end Included_Replacements_Overlap_For_File;

   function Line_Start_Offset
     (Text : String;
      Row  : Natural) return Natural
   is
      Current_Row : Natural := 1;
   begin
      if Row <= 1 then
         return 0;
      end if;
      for I in Text'Range loop
         if Text (I) = ASCII.LF then
            Current_Row := Current_Row + 1;
            if Current_Row = Row then
               return Natural (I - Text'First + 1);
            end if;
         end if;
      end loop;
      return Text'Length;
   end Line_Start_Offset;

   function Text_Span_Matches
     (Text          : String;
      Absolute_Start: Natural;
      Delete_Count  : Natural;
      Expected      : String) return Boolean
   is
      First_Index : constant Natural := Text'First + Absolute_Start;
      Last_Index  : constant Integer := Integer (First_Index) + Integer (Delete_Count) - 1;
   begin
      if Delete_Count /= Expected'Length then
         return False;
      elsif Delete_Count = 0 then
         return True;
      elsif Absolute_Start > Text'Length
        or else First_Index > Text'Last
        or else Last_Index > Integer (Text'Last)
      then
         return False;
      end if;

      return Text (First_Index .. Natural (Last_Index)) = Expected;
   end Text_Span_Matches;

   function Fresh_Valid_Replace_Row_Count
     (State : Project_Search_State) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of State.Replace_Rows loop
         if not Row.Stale and then not Row.Invalid then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Fresh_Valid_Replace_Row_Count;

   procedure Refresh_Replace_Status
     (State : in out Project_Search_State)
   is
   begin
      if Natural (State.Replace_Rows.Length) = 0 then
         State.Replace_Status_Value := Project_Replace_No_Preview;
      elsif Replace_Preview_Is_Stale (State) then
         State.Replace_Status_Value := Project_Replace_Search_Stale;
      elsif Fresh_Valid_Replace_Row_Count (State) = 0 then
         --  Inclusion/exclusion commands may be invoked after preview
         --  generation has produced only invalid target rows.  Refreshing the
         --  status must not collapse that state back to Preview_Ok merely
         --  because no included rows overlap.  Keeping Invalid_Target here
         --  makes availability, render, and direct executor paths agree that
         --  the preview contains no apply-eligible rows and must be regenerated
         --  from fresh search results.
         State.Replace_Status_Value := Project_Replace_Invalid_Target;
      elsif Included_Replacements_Overlap (State) then
         State.Replace_Status_Value := Project_Replace_Overlapping_Matches;
      else
         State.Replace_Status_Value := Project_Replace_Preview_Ok;
      end if;
   end Refresh_Replace_Status;

   function Apply_Included_Replacements_To_Text
     (State         : Project_Search_State;
      Relative_Path : String;
      Text          : String;
      Changed       : out Boolean;
      Replacement_Count : out Natural) return String
   is
      Replacement : constant String := To_String (State.Replace_Text_Value);
      Result      : Unbounded_String := To_Unbounded_String (Text);
      Row         : Project_Replace_Preview_Row;
      Absolute_Start : Natural;
      Delete_Count   : Natural;
      Candidate_Count : Natural := 0;

      function Row_Applies_To_Target
        (Candidate : Project_Replace_Preview_Row) return Boolean
      is
      begin
         return Candidate.Included
           and then not Candidate.Stale
           and then not Candidate.Invalid
           and then To_String (Candidate.Relative_Path) = Relative_Path;
      end Row_Applies_To_Target;

      function Candidate_Absolute_Start
        (Candidate : Project_Replace_Preview_Row) return Natural
      is
      begin
         return Line_Start_Offset (Text, Candidate.Row) + Candidate.Start_Column;
      end Candidate_Absolute_Start;
   begin
      Changed := False;
      Replacement_Count := 0;

      if (not Replace_Text_Is_Valid (State))
        or else Replace_Preview_Is_Stale (State)
        or else Included_Replacements_Overlap_For_File (State, Relative_Path)
      then
         return Text;
      end if;

      --  Validate every target-file candidate against the original source text
      --  before mutating any text.  Replacement rows are preview data, not a
      --  trusted edit script; if any retained match has drifted, the whole
      --  per-file transaction fails closed and preserves the file unchanged.
      for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
         Row := State.Replace_Rows (Natural (I));
         if Row_Applies_To_Target (Row) then
            Absolute_Start := Candidate_Absolute_Start (Row);
            Delete_Count := Row.End_Column - Row.Start_Column;
            if (not Is_UTF8_Boundary (Text, Absolute_Start))
              or else (not Is_UTF8_Boundary (Text, Absolute_Start + Delete_Count))
              or else not Text_Span_Matches
                (Text           => Text,
                 Absolute_Start => Absolute_Start,
                 Delete_Count   => Delete_Count,
                 Expected       => To_String (Row.Match_Text))
            then
               Changed := False;
               Replacement_Count := 0;
               return Text;
            end if;
            Candidate_Count := Candidate_Count + 1;
         end if;
      end loop;

      if Candidate_Count = 0 then
         return Text;
      end if;

      --  Apply in deterministic descending source-offset order, independent of
      --  the vector order in which preview rows happen to be stored.  This is
      --  the offset-shift safety rule for project replacement: edits later in
      --  the file happen before earlier edits, so earlier byte offsets remain
      --  valid until their turn.
      declare
         Previous_Start : Natural := Natural'Last;
      begin
         loop
            declare
               Found      : Boolean := False;
               Best_Index : Natural := 0;
               Best_Start : Natural := 0;
            begin
               for I in 0 .. Integer (State.Replace_Rows.Length) - 1 loop
                  Row := State.Replace_Rows (Natural (I));
                  if Row_Applies_To_Target (Row) then
                     Absolute_Start := Candidate_Absolute_Start (Row);
                     if Absolute_Start < Previous_Start
                       and then (not Found or else Absolute_Start > Best_Start)
                     then
                        Found := True;
                        Best_Index := Natural (I);
                        Best_Start := Absolute_Start;
                     end if;
                  end if;
               end loop;

               exit when not Found;

               Row := State.Replace_Rows (Best_Index);
               Absolute_Start := Best_Start;
               Delete_Count := Row.End_Column - Row.Start_Column;

               declare
                  Current      : constant String := To_String (Result);
                  Prefix_Last  : constant Integer :=
                    Integer (Current'First) + Integer (Absolute_Start) - 1;
                  Suffix_First : constant Natural :=
                    Current'First + Absolute_Start + Delete_Count;
                  New_Text : constant String :=
                    (if Prefix_Last >= Integer (Current'First)
                     then Current (Current'First .. Natural (Prefix_Last))
                     else "")
                    & Replacement
                    & (if Suffix_First <= Current'Last
                       then Current (Suffix_First .. Current'Last)
                       else "");
               begin
                  if New_Text /= Current then
                     Result := To_Unbounded_String (New_Text);
                     Changed := True;
                  end if;
                  Replacement_Count := Replacement_Count + 1;
               end;

               Previous_Start := Best_Start;
            end;
         end loop;
      end;

      return To_String (Result);
   end Apply_Included_Replacements_To_Text;

end Editor.Project_Search.Replace_Preview;
