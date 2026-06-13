with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Editor.Buffers;

package body Editor.Search_Results is

   function Trim_Natural (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim
        (Natural'Image (Value), Ada.Strings.Both);
   end Trim_Natural;


   function Replace_Status_Suffix
     (Search : Editor.Project_Search.Project_Search_State) return String
   is
   begin
      case Editor.Project_Search.Replace_Preview_Status (Search) is
         when Editor.Project_Search.Project_Replace_Search_Stale =>
            return " [stale]";
         when Editor.Project_Search.Project_Replace_Overlapping_Matches =>
            return " [overlap]";
         when Editor.Project_Search.Project_Replace_Invalid_Target =>
            return " [invalid]";
         when Editor.Project_Search.Project_Replace_Invalid_Replacement_Text =>
            return " [invalid replacement text]";
         when Editor.Project_Search.Project_Replace_No_Search_Results =>
            return " [no search results]";
         when Editor.Project_Search.Project_Replace_No_Preview =>
            return "";
         when Editor.Project_Search.Project_Replace_Preview_Ok =>
            return "";
      end case;
   end Replace_Status_Suffix;

   function Format_Options
     (Search : Editor.Project_Search.Project_Search_State) return String
   is
      Scope : constant String := Editor.Project_Search.Path_Scope (Search);
   begin
      declare
         Include_Filter : constant String := Editor.Project_Search.Include_Path_Filter (Search);
         Exclude_Filter : constant String := Editor.Project_Search.Exclude_Path_Filter (Search);
         Text : Unbounded_String := To_Unbounded_String
           ("Scope: " & (if Scope'Length = 0 then "all" else Scope)
            & " | Kind: "
            & Editor.Project_Search.File_Kind_Filter_Image
              (Editor.Project_Search.File_Kind_Filter (Search))
            & " | Case: "
            & (if Editor.Project_Search.Case_Sensitive (Search)
               then "sensitive" else "insensitive")
            & " | Whole word: "
            & (if Editor.Project_Search.Whole_Word (Search) then "on" else "off")
            & " | Regex: "
            & (if Editor.Project_Search.Regex_Enabled (Search) then "on" else "off"));
      begin
         if Include_Filter'Length > 0 then
            Append (Text, " | Include: " & Include_Filter);
         end if;
         if Exclude_Filter'Length > 0 then
            Append (Text, " | Exclude: " & Exclude_Filter);
         end if;
         return To_String (Text);
      end;
   end Format_Options;

   function Truncate_Text
     (Text        : String;
      Max_Columns : Natural) return String
   is
   begin
      if Max_Columns = 0 then
         return "";
      elsif Text'Length <= Max_Columns then
         return Text;
      elsif Max_Columns <= 3 then
         return Text (Text'First .. Text'First + Max_Columns - 1);
      else
         return Text (Text'First .. Text'First + Max_Columns - 4) & "...";
      end if;
   end Truncate_Text;

   function Format_Header
     (Search : Editor.Project_Search.Project_Search_State) return String
   is
      Results  : constant Natural := Editor.Project_Search.Result_Count (Search);
      Groups   : constant Natural := Editor.Project_Search.File_Group_Count (Search);
      Searched : constant Natural := Editor.Project_Search.Files_Searched (Search);
      Skipped  : constant Natural := Editor.Project_Search.Skipped_File_Count (Search);
      Query    : constant String := Editor.Project_Search.Last_Run_Query (Search);
      Text     : Unbounded_String;
      Suffix   : constant String :=
        (if Editor.Project_Search.Is_Stale (Search) then
            " - Results may be stale - rerun search"
         else "");
   begin
      case Editor.Project_Search.Status (Search) is
         when Editor.Project_Search.Project_Search_No_Project =>
            return "Search Project - No project open";
         when Editor.Project_Search.Project_Search_No_Files =>
            return "Search Project - No project files";
         when Editor.Project_Search.Project_Search_Empty_Query =>
            return "Search Project - Query is empty";
         when Editor.Project_Search.Project_Search_Read_Error =>
            return "Search Project: """ & Query & """ - File read error" & Suffix;
         when Editor.Project_Search.Project_Search_Invalid_Regex =>
            declare
               Error : constant String := Editor.Project_Search.Regex_Error (Search);
            begin
               return "Search Project: """ & Query & """ - Invalid regex"
                 & (if Error'Length > 0 then ": " & Error else "")
                 & " - " & Format_Options (Search) & Suffix;
            end;
         when Editor.Project_Search.Project_Search_Cancelled =>
            return "Search Project: """ & Query & """ - Cancelled";
         when Editor.Project_Search.Project_Search_Idle =>
            return "Search Project - " & Format_Options (Search);
         when Editor.Project_Search.Project_Search_Ok =>
            if Query'Length = 0 then
               return "Search Project - " & Format_Options (Search);
            elsif Editor.Project_Search.Eligible_File_Count (Search) = 0 then
               return "Search Project: """ & Query & """ - No project files match search scope";
            elsif Results = 0 then
               Text := To_Unbounded_String
                 ("Search Project: """ & Query & """ - 0 matches; searched "
                  & Trim_Natural (Searched) & " files");
            else
               Text := To_Unbounded_String
                 ("Search Project: """ & Query & """ - "
                  & Trim_Natural (Results) & " matches in "
                  & Trim_Natural (Groups) & " files; searched "
                  & Trim_Natural (Searched) & " files");
            end if;
            if Skipped > 0 then
               Append (Text, "; skipped " & Trim_Natural (Skipped));
               if Editor.Project_Search.Read_Error_Count (Search) > 0 then
                  Append (Text, " unreadable="
                    & Trim_Natural (Editor.Project_Search.Read_Error_Count (Search)));
               end if;
               if Editor.Project_Search.Skipped_Missing_Count (Search) > 0 then
                  Append (Text, " missing="
                    & Trim_Natural (Editor.Project_Search.Skipped_Missing_Count (Search)));
               end if;
               if Editor.Project_Search.Skipped_Large_Count (Search) > 0 then
                  Append (Text, " large="
                    & Trim_Natural (Editor.Project_Search.Skipped_Large_Count (Search)));
               end if;
               if Editor.Project_Search.Skipped_Binary_Count (Search) > 0 then
                  Append (Text, " binary="
                    & Trim_Natural (Editor.Project_Search.Skipped_Binary_Count (Search)));
               end if;
            end if;
            if Editor.Project_Search.Was_Truncated (Search) then
               Append (Text, "; result limit reached");
               if Editor.Project_Search.Matches_Truncated_Count (Search) > 0 then
                  Append (Text, " truncated="
                    & Trim_Natural (Editor.Project_Search.Matches_Truncated_Count (Search)));
               end if;
            end if;
            Append (Text, " - " & Format_Options (Search) & Suffix);
            if Editor.Project_Search.Replace_Preview_Count (Search) > 0 then
               Append
                 (Text, " | Replace preview: "
                  & Trim_Natural
                      (Editor.Project_Search.Included_Replacement_Count (Search))
                  & " included in "
                  & Trim_Natural
                      (Editor.Project_Search.Included_Replacement_File_Count (Search))
                  & " files"
                  & Replace_Status_Suffix (Search));
            end if;
            return To_String (Text);
      end case;
   end Format_Header;

   function Format_File_Row
     (Group : Editor.Project_Search.Project_Search_File_Group) return String
   is
   begin
      return To_String (Group.Relative_Path)
        & " (" & Trim_Natural (Group.Result_Count) & ")";
   end Format_File_Row;

   function Format_Result_Snippet
     (Result          : Editor.Project_Search.Project_Search_Result;
      Max_Columns     : Natural;
      Context_Columns : Natural := 40) return String
   is
      pragma Unreferenced (Context_Columns);
   begin
      return Truncate_Text (To_String (Result.Line_Preview), Max_Columns);
   end Format_Result_Snippet;

   function Format_Result_Row
     (Result : Editor.Project_Search.Project_Search_Result;
      Width  : Natural) return String
   is
      Prefix : constant String :=
        Trim_Natural (Result.Row)
        & (if Result.Match_Column > 0
           then ":" & Trim_Natural (Result.Match_Column) & ": "
           else ": ");
      Budget : constant Natural :=
        (if Width > Prefix'Length then Width - Prefix'Length else 0);
   begin
      return Prefix & Format_Result_Snippet (Result, Budget);
   end Format_Result_Row;

   function Format_Replace_Row
     (Row   : Editor.Project_Search.Project_Replace_Preview_Row;
      Width : Natural) return String
   is
      Prefix : constant String :=
        (if Row.Included then "[x] " else "[ ] ")
        & (if Row.Stale then "[stale] " elsif Row.Invalid then "[invalid] " else "")
        & Trim_Natural (Row.Row) & ":" & Trim_Natural (Row.Start_Column + 1) & ": ";
      Message_Body : constant String :=
        To_String (Row.Before_Excerpt) & " => " & To_String (Row.After_Excerpt);
      Budget : constant Natural :=
        (if Width > Prefix'Length then Width - Prefix'Length else 0);
   begin
      return Prefix & Truncate_Text (Message_Body, Budget);
   end Format_Replace_Row;

   procedure Clear
     (Snapshot : in out Search_Results_Snapshot)
   is
   begin
      Snapshot.Rows.Clear;
   end Clear;


   function Marker_Prefix
     (Is_Open   : Boolean;
      Is_Active : Boolean;
      Is_Dirty  : Boolean) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;
   begin
      if Is_Open then
         Append (Text, "[open] ");
      end if;
      if Is_Active then
         Append (Text, "[active] ");
      end if;
      if Is_Dirty then
         Append (Text, "[dirty] ");
      end if;
      return To_String (Text);
   end Marker_Prefix;

   procedure Resolve_Markers
     (Buffers   : Editor.Buffers.Buffer_Registry;
      Path      : String;
      Is_Open   : out Boolean;
      Is_Active : out Boolean;
      Is_Dirty  : out Boolean)
   is
      Found   : Boolean := False;
      Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      Is_Open := False;
      Is_Active := False;
      Is_Dirty := False;
      if Path'Length = 0 then
         return;
      end if;
      Id := Editor.Buffers.Find_By_Path (Buffers, Path, Found);
      if Found then
         Summary := Editor.Buffers.Summary_For (Buffers, Id);
         Is_Open := True;
         Is_Active := Summary.Is_Active;
         Is_Dirty := Summary.Is_Dirty;
      end if;
   end Resolve_Markers;

   function Build_Snapshot
     (Search : Editor.Project_Search.Project_Search_State;
      Config : Search_Results_View_Config) return Search_Results_Snapshot
   is
      Snapshot : Search_Results_Snapshot;
      Selected : constant Natural := Editor.Project_Search.Selected_Result_Index (Search);
   begin
      Snapshot.Project_Search_Visible := True;
      Snapshot.Project_Search_Query := To_Unbounded_String (Editor.Project_Search.Query (Search));
      Snapshot.Project_Search_File_Kind_Filter := Editor.Project_Search.File_Kind_Filter (Search);
      Snapshot.Project_Search_Path_Scope := To_Unbounded_String (Editor.Project_Search.Path_Scope (Search));
      Snapshot.Project_Search_Case_Sensitive := Editor.Project_Search.Case_Sensitive (Search);
      Snapshot.Project_Search_Result_Count := Editor.Project_Search.Result_Count (Search);
      Snapshot.Project_Search_Matched_File_Count := Editor.Project_Search.File_Group_Count (Search);
      Snapshot.Project_Search_Eligible_File_Count := Editor.Project_Search.Eligible_File_Count (Search);
      Snapshot.Project_Search_Searched_File_Count := Editor.Project_Search.Files_Searched (Search);
      Snapshot.Project_Search_Skipped_File_Count := Editor.Project_Search.Skipped_File_Count (Search);
      Snapshot.Project_Search_Truncated := Editor.Project_Search.Was_Truncated (Search);
      Snapshot.Project_Search_Selected_Index := Selected;
      Snapshot.Project_Search_Header_Text := To_Unbounded_String (Format_Header (Search));

      if Config.Show_Header then
         Snapshot.Rows.Append
           (Search_Results_Row'
             (Kind         => Search_Results_Header_Row,
             Result_Index => 0,
             File_Index   => 0,
             Text         => To_Unbounded_String (Format_Header (Search)),
             Project_Relative_Path => Null_Unbounded_String,
             Line_Number  => 0,
             Line_Preview => Null_Unbounded_String,
             Match_Column => 0,
             Preview_Match_Start => 0,
             Preview_Match_Length => 0,
             Display_Text => Null_Unbounded_String,
             Is_Open      => False,
             Is_Active    => False,
             Is_Dirty     => False,
             Is_Selected  => False));
      end if;

      if Editor.Project_Search.Result_Count (Search) = 0 then
         Snapshot.Project_Search_Empty_Message := To_Unbounded_String (Format_Header (Search));
         Snapshot.Rows.Append
           (Search_Results_Row'
             (Kind         => Search_Results_Empty_Row,
             Result_Index => 0,
             File_Index   => 0,
             Text         => To_Unbounded_String (Format_Header (Search)),
             Project_Relative_Path => Null_Unbounded_String,
             Line_Number  => 0,
             Line_Preview => Null_Unbounded_String,
             Match_Column => 0,
             Preview_Match_Start => 0,
             Preview_Match_Length => 0,
             Display_Text => Null_Unbounded_String,
             Is_Open      => False,
             Is_Active    => False,
             Is_Dirty     => False,
             Is_Selected  => False));
         return Snapshot;
      end if;

      for F in 1 .. Editor.Project_Search.File_Group_Count (Search) loop
         declare
            Group : constant Editor.Project_Search.Project_Search_File_Group :=
              Editor.Project_Search.File_Group_At (Search, F);
         begin
            if Config.Show_File_Group_Rows then
               Snapshot.Rows.Append
           (Search_Results_Row'
             (Kind         => Search_Results_File_Row,
                   Result_Index => Group.First_Result_Index,
                   File_Index   => F,
                   Text         => To_Unbounded_String (Format_File_Row (Group)),
                   Project_Relative_Path => Group.Relative_Path,
                   Line_Number  => 0,
                   Line_Preview => Null_Unbounded_String,
                   Match_Column => 0,
                   Preview_Match_Start => 0,
                   Preview_Match_Length => 0,
                   Display_Text => Null_Unbounded_String,
                   Is_Open      => False,
                   Is_Active    => False,
                   Is_Dirty     => False,
                   Is_Selected  => False));
            end if;

            for R in Group.First_Result_Index .. Group.First_Result_Index + Group.Result_Count - 1 loop
               declare
                  Result : constant Editor.Project_Search.Project_Search_Result :=
                    Editor.Project_Search.Result_At (Search, R);
                  Row_Prefix : constant String :=
                    (if Config.Show_File_Group_Rows then
                        (1 .. Config.Indent_Result_Columns => ' ')
                     else "");
                  Replace_Mode : constant Boolean :=
                    Editor.Project_Search.Replace_Preview_Count (Search) >= R;
                  Replace_Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
                    (if Replace_Mode then
                        Editor.Project_Search.Replace_Preview_Row_At (Search, R)
                     else
                        (others => <>));
                  Text : constant String :=
                    Row_Prefix
                    & To_String (Result.Relative_Path) & ":"
                    & (if Replace_Mode then
                          Format_Replace_Row (Replace_Row, Config.Max_Snippet_Columns)
                       else
                          Format_Result_Row (Result, Config.Max_Snippet_Columns));
               begin
                  Snapshot.Rows.Append
           (Search_Results_Row'
             (Kind         => Search_Results_Match_Row,
                      Result_Index => R,
                      File_Index   => F,
                      Text         => To_Unbounded_String (Text),
                      Project_Relative_Path => Result.Relative_Path,
                      Line_Number  => Result.Row,
                      Line_Preview => (if Replace_Mode then Replace_Row.After_Excerpt else Result.Line_Preview),
                      Match_Column => Result.Match_Column,
                      Preview_Match_Start => Result.Preview_Match_Start,
                      Preview_Match_Length => Result.Preview_Match_Length,
                      Display_Text => To_Unbounded_String (Text),
                      Is_Open      => False,
                      Is_Active    => False,
                      Is_Dirty     => False,
                      Is_Selected  => (if Replace_Mode then Replace_Row.Selected else R = Selected)));
               end;
            end loop;
         end;
      end loop;

      return Snapshot;
   end Build_Snapshot;

   function Build_Snapshot
     (Search  : Editor.Project_Search.Project_Search_State;
      Config  : Search_Results_View_Config;
      Buffers : Editor.Buffers.Buffer_Registry) return Search_Results_Snapshot
   is
      Snapshot : Search_Results_Snapshot := Build_Snapshot (Search, Config);
      R        : Search_Results_Row;
      Result   : Editor.Project_Search.Project_Search_Result;
      Is_Open  : Boolean := False;
      Is_Active : Boolean := False;
      Is_Dirty : Boolean := False;
   begin
      for I in 1 .. Natural (Snapshot.Rows.Length) loop
         R := Snapshot.Rows (I - 1);
         if R.Kind = Search_Results_Match_Row and then R.Result_Index > 0 then
            Result := Editor.Project_Search.Result_At (Search, Positive (R.Result_Index));
            Resolve_Markers
              (Buffers, To_String (Result.Absolute_Path),
               Is_Open, Is_Active, Is_Dirty);
            R.Is_Open := Is_Open;
            R.Is_Active := Is_Active;
            R.Is_Dirty := Is_Dirty;
            if Is_Open or else Is_Active or else Is_Dirty then
               declare
                  Marked_Text : constant String :=
                    Marker_Prefix (Is_Open, Is_Active, Is_Dirty) & To_String (R.Text);
               begin
                  R.Text := To_Unbounded_String (Marked_Text);
                  R.Display_Text := To_Unbounded_String (Marked_Text);
               end;
            end if;
            Snapshot.Rows.Replace_Element (I - 1, R);
         end if;
      end loop;
      return Snapshot;
   end Build_Snapshot;

   function Row_Count
     (Snapshot : Search_Results_Snapshot) return Natural
   is
   begin
      return Natural (Snapshot.Rows.Length);
   end Row_Count;

   function Row
     (Snapshot : Search_Results_Snapshot;
      Index    : Positive) return Search_Results_Row
   is
   begin
      if Index > Natural (Snapshot.Rows.Length) then
         return (others => <>);
      end if;
      return Snapshot.Rows (Index - 1);
   end Row;


   function Row_For_Result
     (Snapshot     : Search_Results_Snapshot;
      Result_Index : Natural;
      Found        : out Boolean) return Natural
   is
      R : Search_Results_Row;
   begin
      Found := False;
      if Result_Index = 0 then
         return 0;
      end if;
      for I in 1 .. Natural (Snapshot.Rows.Length) loop
         R := Snapshot.Rows (I - 1);
         if R.Kind = Search_Results_Match_Row and then R.Result_Index = Result_Index then
            Found := True;
            return I;
         end if;
      end loop;
      return 0;
   end Row_For_Result;

   function Result_For_Row
     (Snapshot  : Search_Results_Snapshot;
      Row_Index : Natural;
      Found     : out Boolean) return Natural
   is
      R : Search_Results_Row;
   begin
      Found := False;
      if Row_Index = 0 or else Row_Index > Natural (Snapshot.Rows.Length) then
         return 0;
      end if;
      R := Snapshot.Rows (Row_Index - 1);
      if R.Kind = Search_Results_Match_Row and then R.Result_Index > 0 then
         Found := True;
         return R.Result_Index;
      end if;
      return 0;
   end Result_For_Row;

   function First_Result_In_File_Group
     (Snapshot : Search_Results_Snapshot;
      File_Row : Natural;
      Found    : out Boolean) return Natural
   is
      R : Search_Results_Row;
   begin
      Found := False;
      if File_Row = 0 or else File_Row > Natural (Snapshot.Rows.Length) then
         return 0;
      end if;
      R := Snapshot.Rows (File_Row - 1);
      if R.Kind = Search_Results_File_Row and then R.Result_Index > 0 then
         Found := True;
         return R.Result_Index;
      end if;
      return 0;
   end First_Result_In_File_Group;

   procedure Ensure_Selected_Row_Visible
     (View_State        : in out Search_Results_View_State;
      Snapshot          : Search_Results_Snapshot;
      Selected_Result   : Natural;
      Visible_Row_Count : Natural)
   is
      Found : Boolean := False;
      Row   : constant Natural := Row_For_Result (Snapshot, Selected_Result, Found);
      Count : constant Natural := Natural (Snapshot.Rows.Length);
      Last_Allowed : Natural := 1;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         View_State.Top_Row := 1;
         return;
      end if;

      if Visible_Row_Count >= Count then
         Last_Allowed := 1;
      else
         Last_Allowed := Count - Visible_Row_Count + 1;
      end if;
      if View_State.Top_Row = 0 then
         View_State.Top_Row := 1;
      elsif View_State.Top_Row > Last_Allowed then
         View_State.Top_Row := Last_Allowed;
      end if;

      if Found then
         if Row < View_State.Top_Row then
            View_State.Top_Row := Row;
         elsif Row >= View_State.Top_Row + Visible_Row_Count then
            View_State.Top_Row := Row - Visible_Row_Count + 1;
         end if;
      end if;
   end Ensure_Selected_Row_Visible;

   procedure Clamp_Viewport
     (View_State        : in out Search_Results_View_State;
      Snapshot          : Search_Results_Snapshot;
      Visible_Row_Count : Natural)
   is
      Count        : constant Natural := Natural (Snapshot.Rows.Length);
      Last_Allowed : Natural := 1;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         View_State.Top_Row := 1;
         return;
      end if;

      if Count > Visible_Row_Count then
         Last_Allowed := Count - Visible_Row_Count + 1;
      end if;

      if View_State.Top_Row = 0 then
         View_State.Top_Row := 1;
      elsif View_State.Top_Row > Last_Allowed then
         View_State.Top_Row := Last_Allowed;
      end if;
   end Clamp_Viewport;

   procedure Scroll_By
     (View_State        : in out Search_Results_View_State;
      Snapshot          : Search_Results_Snapshot;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer)
   is
      Count        : constant Natural := Natural (Snapshot.Rows.Length);
      Last_Allowed : Natural := 1;
      Desired      : Integer := Integer (View_State.Top_Row) + Step_Delta;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         View_State.Top_Row := 1;
         return;
      end if;

      if Count > Visible_Row_Count then
         Last_Allowed := Count - Visible_Row_Count + 1;
      end if;

      if Desired < 1 then
         Desired := 1;
      elsif Desired > Integer (Last_Allowed) then
         Desired := Integer (Last_Allowed);
      end if;

      View_State.Top_Row := Natural (Desired);
   end Scroll_By;

   procedure Move_Row_Selection
     (View_State : in out Search_Results_View_State;
      Search     : in out Editor.Project_Search.Project_Search_State;
      Snapshot   : Search_Results_Snapshot;
      Direction  : Search_Results_Row_Direction)
   is
   begin
      case Direction is
         when Next_Row =>
            Editor.Project_Search.Move_Selected_Result
              (Search, Editor.Project_Search.Next_Result, False);
         when Previous_Row =>
            Editor.Project_Search.Move_Selected_Result
              (Search, Editor.Project_Search.Previous_Result, False);
      end case;
      Ensure_Selected_Row_Visible
        (View_State, Snapshot, Editor.Project_Search.Selected_Result_Index (Search),
         Natural'Max (1, Natural (Snapshot.Rows.Length)));
   end Move_Row_Selection;

   function Visible_Snapshot
     (Snapshot          : Search_Results_Snapshot;
      View_State        : Search_Results_View_State;
      Visible_Row_Count : Natural) return Search_Results_Snapshot
   is
      Result : Search_Results_Snapshot;
      Start  : Natural := Natural'Max (1, View_State.Top_Row);
      Count  : constant Natural := Natural (Snapshot.Rows.Length);
      Stop   : Natural := 0;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         return Result;
      end if;
      if Start > Count then
         Start := Count;
      end if;
      if Visible_Row_Count >= Count - Start + 1 then
         Stop := Count;
      else
         Stop := Start + Visible_Row_Count - 1;
      end if;
      for I in Start .. Stop loop
         Result.Rows.Append (Snapshot.Rows (I - 1));
      end loop;
      return Result;
   end Visible_Snapshot;

   function Hit_Test
     (Panel_Rect  : Editor.Layout.Rect;
      Config      : Search_Results_View_Config;
      Snapshot    : Search_Results_Snapshot;
      Cell_Height : Natural;
      X           : Integer;
      Y           : Integer) return Search_Results_Hit_Result
   is
      Rel_Y : Integer := 0;
      Logical_Row_Height : Natural := 0;
      Row_Index : Natural := 0;
      R : Search_Results_Row;
   begin
      if X < Panel_Rect.X or else Y < Panel_Rect.Y
        or else X >= Panel_Rect.X + Integer (Panel_Rect.Width)
        or else Y >= Panel_Rect.Y + Integer (Panel_Rect.Height)
      then
         return (others => <>);
      end if;

      if Cell_Height = 0 then
         return (Zone => Search_Results_Background_Zone, others => <>);
      end if;

      Logical_Row_Height := Natural'Max (1, Config.Row_Height_In_Rows) * Cell_Height;
      Rel_Y := Y - Panel_Rect.Y;
      Row_Index := Natural (Rel_Y / Integer (Logical_Row_Height)) + 1;
      if Row_Index = 0 or else Row_Index > Natural (Snapshot.Rows.Length) then
         return (Zone => Search_Results_Background_Zone, others => <>);
      end if;

      R := Row (Snapshot, Positive (Row_Index));
      case R.Kind is
         when Search_Results_Header_Row =>
            return (Zone => Search_Results_Header_Zone,
                    Row_Index => Row_Index,
                    Result_Index => R.Result_Index);
         when Search_Results_File_Row =>
            return (Zone => Search_Results_File_Row_Zone,
                    Row_Index => Row_Index,
                    Result_Index => R.Result_Index);
         when Search_Results_Match_Row =>
            return (Zone => Search_Results_Match_Row_Zone,
                    Row_Index => Row_Index,
                    Result_Index => R.Result_Index);
         when Search_Results_Empty_Row =>
            return (Zone => Search_Results_Background_Zone,
                    Row_Index => Row_Index,
                    Result_Index => 0);
      end case;
   end Hit_Test;

end Editor.Search_Results;
