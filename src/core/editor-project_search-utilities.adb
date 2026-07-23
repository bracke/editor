with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada_Regexp;
with Editor.Files;

package body Editor.Project_Search.Utilities is

  use type Ada.Containers.Count_Type;
  use type Editor.Files.File_Open_Status;
  use type Ada_Regexp.Regexp_Status;

   function Read_Search_File
     (Path : String;
      Text : out Unbounded_String) return Boolean
   is
      Result : Editor.Files.File_Open_Result;
   begin
      Result := Editor.Files.Open_File (Path);
      if Result.Status = Editor.Files.File_Open_Ok then
         Text := Result.Contents;
         return True;
      else
         Text := Null_Unbounded_String;
         return False;
      end if;
   end Read_Search_File;

   function Capture_Selected_Key
     (State : Editor.Project_Search.Project_Search_State)
      return Preserved_Result_Key
   is
      Selected : constant Natural := State.Selected_Index;
      Result   : Editor.Project_Search.Project_Search_Result;
      Key      : Preserved_Result_Key;
   begin
      if Selected = 0 or else Selected > Natural (State.Results.Length) then
         return Key;
      end if;

      Result := State.Results (Selected - 1);
      Key.Has_Value := True;
      Key.Path := Result.Relative_Path;
      Key.Row := Result.Row;
      for I in 1 .. Selected loop
         declare
            Candidate : constant Editor.Project_Search.Project_Search_Result := State.Results (I - 1);
         begin
            if To_String (Candidate.Relative_Path) = To_String (Result.Relative_Path)
              and then Candidate.Row = Result.Row
            then
               Key.Occurrence := Key.Occurrence + 1;
            end if;
         end;
      end loop;
      return Key;
   end Capture_Selected_Key;

   procedure Restore_Selected_Key
     (State : in out Editor.Project_Search.Project_Search_State;
      Key   : Preserved_Result_Key)
   is
      Seen : Natural := 0;
   begin
      if Natural (State.Results.Length) = 0 then
         State.Selected_Index := 0;
         if Natural (State.Replace_Rows.Length) > 0 then
            Editor.Project_Search.Set_Selected_Replace_Preview_Index
              (State, State.Selected_Index);
         end if;
         return;
      end if;

      if Key.Has_Value then
         for I in 1 .. Natural (State.Results.Length) loop
            declare
               Candidate : constant Editor.Project_Search.Project_Search_Result := State.Results (I - 1);
            begin
               if To_String (Candidate.Relative_Path) = To_String (Key.Path)
                 and then Candidate.Row = Key.Row
               then
                  Seen := Seen + 1;
                  if Seen = Natural'Max (1, Key.Occurrence) then
                     State.Selected_Index := I;
                     return;
                  end if;
               end if;
            end;
         end loop;
      end if;

      State.Selected_Index := 1;
   end Restore_Selected_Key;

   function Contains_Newline (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Ch = ASCII.LF or else Ch = ASCII.CR then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Newline;

   procedure Internal_Clear_Replace_Preview
     (State : in out Editor.Project_Search.Project_Search_State)
   is
   begin
      State.Replace_Rows.Clear;
      State.Replace_Selected_Index := 0;
      State.Replace_Status_Value := Editor.Project_Search.Project_Replace_No_Preview;
      State.Replace_Stale := False;
      State.Replace_Search_Token := 0;
   end Internal_Clear_Replace_Preview;

   procedure Reset_Results
     (State  : in out Editor.Project_Search.Project_Search_State;
      Status : Editor.Project_Search.Project_Search_Status :=
        Editor.Project_Search.Project_Search_Idle)
   is
   begin
      State.Results.Clear;
      State.File_Groups.Clear;
      State.Last_Query_Text := Null_Unbounded_String;
      State.Selected_Index := 0;
      State.Last_Status := Status;
      State.Eligible_File_Total := 0;
      State.Files_Searched_Count := 0;
      State.Read_Error_Count := 0;
      State.Skipped_Missing_Total := 0;
      State.Skipped_Large_Total := 0;
      State.Skipped_Binary_Total := 0;
      State.Matches_Truncated_Total := 0;
      State.Truncated := False;
      State.Stale := False;
      State.Search_Token := State.Search_Token + 1;
      Internal_Clear_Replace_Preview (State);
   end Reset_Results;

   procedure Preserve_Results_For_Precondition_Failure
     (State  : in out Editor.Project_Search.Project_Search_State;
      Status : Editor.Project_Search.Project_Search_Status;
      Query  : String)
   is
   begin
      State.Last_Status := Status;
      State.Last_Query_Text := To_Unbounded_String (Query);
      if Natural (State.Results.Length) > 0 then
         State.Stale := True;
         Editor.Project_Search.Mark_Replace_Preview_Stale (State);
      end if;
   end Preserve_Results_For_Precondition_Failure;

   procedure Begin_Search_Run
     (State             : in out Editor.Project_Search.Project_Search_State;
      Query             : String;
      Project_Open      : Boolean;
      File_Total        : Natural;
      No_Project_Status : Editor.Project_Search.Project_Search_Status;
      No_Files_Status   : Editor.Project_Search.Project_Search_Status;
      Previous_Key      : out Preserved_Result_Key;
      Effective_Options : in out Editor.Project_Search.Project_Search_Options;
      Regex_Compile     : out Ada_Regexp.Compile_Result;
      Ready             : out Boolean)
   is
   begin
      Previous_Key := Capture_Selected_Key (State);
      Effective_Options.Case_Sensitive := State.Case_Sensitive_Search;
      Ready := False;

      if Query'Length = 0 or else Contains_Newline (Query) then
         Reset_Results (State, Editor.Project_Search.Project_Search_Empty_Query);
         State.Last_Query_Text := Null_Unbounded_String;
         return;
      elsif not Project_Open then
         Preserve_Results_For_Precondition_Failure
           (State, No_Project_Status, Query);
         return;
      elsif File_Total = 0 then
         Preserve_Results_For_Precondition_Failure
           (State, No_Files_Status, Query);
         return;
      end if;

      State.Last_Regex_Error := Null_Unbounded_String;
      if State.Regex_Search then
         Regex_Compile := Ada_Regexp.Compile (Query);
         if Regex_Compile.Status /= Ada_Regexp.Compile_Ok then
            Reset_Results (State, Editor.Project_Search.Project_Search_Invalid_Regex);
            State.Last_Query_Text := To_Unbounded_String (Query);
            State.Last_Regex_Error :=
              To_Unbounded_String (Ada_Regexp.Status_Image (Regex_Compile.Status));
            return;
         end if;
      end if;

      Reset_Results (State, Editor.Project_Search.Project_Search_Idle);
      State.Last_Query_Text := To_Unbounded_String (Query);
      Ready := True;
   end Begin_Search_Run;

   procedure Finalize_Search_Run
     (State             : in out Editor.Project_Search.Project_Search_State;
      Previous_Key      : Preserved_Result_Key;
      Effective_Options : Editor.Project_Search.Project_Search_Options;
      Eligible          : Natural;
      Scanned           : Natural;
      Processed         : Natural)
   is
   begin
      State.Eligible_File_Total := Eligible;
      State.Files_Searched_Count := Scanned;

      if Processed >= Effective_Options.Max_File_Count and then Eligible > Processed then
         State.Truncated := True;
      end if;

      if Natural (State.Results.Length) > 0 then
         Restore_Selected_Key (State, Previous_Key);
      else
         State.Selected_Index := 0;
      end if;

      State.Last_Status := Editor.Project_Search.Project_Search_Ok;
   end Finalize_Search_Run;

   function Fold_Case (Text : String) return String is
      Result : String (Text'Range);
   begin
      for I in Text'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (Text (I));
      end loop;
      return Result;
   end Fold_Case;

   function Replacement_Text_Is_Valid
     (Text : String) return Boolean
   is
   begin
      return not Contains_Newline (Text);
   end Replacement_Text_Is_Valid;

   function Find_Literal_Match_Column
     (Line           : String;
      Query          : String;
      Case_Sensitive : Boolean) return Natural
   is
      Comparable_Line  : constant String :=
        (if Case_Sensitive then Line else Fold_Case (Line));
      Comparable_Query : constant String :=
        (if Case_Sensitive then Query else Fold_Case (Query));
      Hit : Natural := 0;
   begin
      if Line'Length = 0 or else Query'Length = 0 then
         return 0;
      end if;

      Hit := Ada.Strings.Fixed.Index
        (Source  => Comparable_Line,
         Pattern => Comparable_Query);
      if Hit = 0 then
         return 0;
      else
         return Natural (Hit - Comparable_Line'First + 1);
      end if;
   end Find_Literal_Match_Column;

   function Sanitize_Project_Search_Preview_Text
     (Line : String) return String
   is
      Result : String (Line'Range);
      Ch     : Character;
   begin
      for I in Line'Range loop
         Ch := Line (I);
         if Ch = ASCII.HT then
            Result (I) := Ch;
         elsif Character'Pos (Ch) < 32 or else Character'Pos (Ch) = 127 then
            Result (I) := '?';
         else
            Result (I) := Ch;
         end if;
      end loop;
      return Result;
   end Sanitize_Project_Search_Preview_Text;

   procedure Compute_Project_Search_Preview_Window
     (Line_Length    : Natural;
      Match_Column   : Natural;
      Match_Length   : Natural;
      Max_Length     : Natural;
      Window_Start   : out Natural;
      Window_End     : out Natural;
      Left_Ellipsis  : out Boolean;
      Right_Ellipsis : out Boolean)
   is
      Ellipsis_Length : constant Natural := 3;
      Match_Start : Natural := Natural'Max (1, Match_Column);
      Match_End   : Natural := 0;
      Core_Budget : Natural := 0;
   begin
      Window_Start := 0;
      Window_End := 0;
      Left_Ellipsis := False;
      Right_Ellipsis := False;

      if Max_Length = 0 or else Line_Length = 0 then
         return;
      elsif Line_Length <= Max_Length then
         Window_Start := 1;
         Window_End := Line_Length;
         return;
      elsif Max_Length <= Ellipsis_Length then
         Window_Start := 1;
         Window_End := Natural'Min (Line_Length, Max_Length);
         return;
      end if;

      if Match_Start > Line_Length then
         Match_Start := 1;
      end if;

      Match_End := Natural'Min
        (Line_Length, Match_Start + Natural'Max (1, Match_Length) - 1);

      Window_Start :=
        (if Match_Start > Search_Result_Context_Before
         then Match_Start - Search_Result_Context_Before
         else 1);
      Left_Ellipsis := Window_Start > 1;
      Right_Ellipsis := True;

      Core_Budget := Max_Length;
      if Left_Ellipsis and then Core_Budget > Ellipsis_Length then
         Core_Budget := Core_Budget - Ellipsis_Length;
      end if;
      if Right_Ellipsis and then Core_Budget > Ellipsis_Length then
         Core_Budget := Core_Budget - Ellipsis_Length;
      end if;
      if Core_Budget = 0 then
         Window_Start := 1;
         Window_End := Natural'Min (Line_Length, Max_Length);
         Left_Ellipsis := False;
         Right_Ellipsis := False;
         return;
      end if;

      if Match_End >= Window_Start + Core_Budget then
         Window_Start := Match_Start;
         Left_Ellipsis := Window_Start > 1;
         Core_Budget := Max_Length;
         if Left_Ellipsis and then Core_Budget > Ellipsis_Length then
            Core_Budget := Core_Budget - Ellipsis_Length;
         end if;
         if Core_Budget > Ellipsis_Length then
            Core_Budget := Core_Budget - Ellipsis_Length;
            Right_Ellipsis := True;
         end if;
      end if;

      Window_End := Natural'Min (Line_Length, Window_Start + Core_Budget - 1);
      Right_Ellipsis := Window_End < Line_Length;
   end Compute_Project_Search_Preview_Window;

   function Build_Project_Search_Line_Preview
     (Line         : String;
      Match_Column : Natural;
      Match_Length : Natural;
      Max_Length   : Natural := Editor.Project_Search.Max_Search_Result_Preview_Length)
      return String
   is
      Clean : constant String := Sanitize_Project_Search_Preview_Text (Line);
      Ellipsis : constant String := "...";
      Window_Start : Natural := 0;
      Window_End   : Natural := 0;
      Left_Ellipsis : Boolean := False;
      Right_Ellipsis : Boolean := False;
   begin
      Compute_Project_Search_Preview_Window
        (Line_Length    => Clean'Length,
         Match_Column   => Match_Column,
         Match_Length   => Match_Length,
         Max_Length     => Max_Length,
         Window_Start   => Window_Start,
         Window_End     => Window_End,
         Left_Ellipsis  => Left_Ellipsis,
         Right_Ellipsis => Right_Ellipsis);

      if Window_Start = 0 or else Window_End = 0 then
         return "";
      end if;

      declare
         Core : constant String :=
           Clean (Clean'First + Window_Start - 1 .. Clean'First + Window_End - 1);
      begin
         return (if Left_Ellipsis then Ellipsis else "")
           & Core
           & (if Right_Ellipsis then Ellipsis else "");
      end;
   end Build_Project_Search_Line_Preview;

   procedure Build_Project_Search_Preview_Match_Range
     (Line                 : String;
      Match_Column         : Natural;
      Match_Length         : Natural;
      Preview              : String;
      Preview_Match_Start  : out Natural;
      Preview_Match_Length : out Natural)
   is
      Clean : constant String := Sanitize_Project_Search_Preview_Text (Line);
      Match_Start : constant Natural := Match_Column;
      Effective_Length : constant Natural := Natural'Max (1, Match_Length);
      Match_End : Natural := 0;
      Window_Start : Natural := 0;
      Window_End   : Natural := 0;
      Left_Ellipsis : Boolean := False;
      Unused_Right_Ellipsis : Boolean := False;
      Prefix_Length : Natural := 0;
   begin
      Preview_Match_Start := 0;
      Preview_Match_Length := 0;
      if Clean'Length = 0 or else Preview'Length = 0 or else Match_Start = 0 then
         return;
      end if;
      if Match_Start > Clean'Length then
         return;
      end if;

      Compute_Project_Search_Preview_Window
        (Line_Length    => Clean'Length,
         Match_Column   => Match_Start,
         Match_Length   => Effective_Length,
         Max_Length     => Preview'Length,
         Window_Start   => Window_Start,
         Window_End     => Window_End,
         Left_Ellipsis  => Left_Ellipsis,
         Right_Ellipsis => Unused_Right_Ellipsis);

      if Window_Start = 0 or else Window_End = 0 then
         return;
      end if;

      Match_End := Natural'Min (Clean'Length, Match_Start + Effective_Length - 1);
      if Match_Start < Window_Start or else Match_Start > Window_End then
         return;
      end if;

      Prefix_Length := (if Left_Ellipsis then 3 else 0);
      Preview_Match_Start := Prefix_Length + (Match_Start - Window_Start) + 1;
      Preview_Match_Length := Natural'Min (Match_End, Window_End) - Match_Start + 1;
   end Build_Project_Search_Preview_Match_Range;

end Editor.Project_Search.Utilities;
