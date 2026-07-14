with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Files;
with Editor.Project;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada_Regexp;

package body Editor.Project_Search is

   use type Ada.Directories.File_Kind;
   use type Ada_Regexp.Regexp_Status;

   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Files.File_Open_Status;

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


   type Preserved_Result_Key is record
      Has_Value   : Boolean := False;
      Path        : Unbounded_String := Null_Unbounded_String;
      Row         : Natural := 0;
      Occurrence  : Natural := 0;
   end record;

   function Capture_Selected_Key
     (State : Project_Search_State) return Preserved_Result_Key
   is
      Selected : constant Natural := State.Selected_Index;
      Result   : Project_Search_Result;
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
            Candidate : constant Project_Search_Result := State.Results (I - 1);
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
     (State : in out Project_Search_State;
      Key   : Preserved_Result_Key)
   is
      Seen : Natural := 0;
   begin
      if Natural (State.Results.Length) = 0 then
         State.Selected_Index := 0;
         if Natural (State.Replace_Rows.Length) > 0 then
            Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
         end if;
         return;
      end if;

      if Key.Has_Value then
         for I in 1 .. Natural (State.Results.Length) loop
            declare
               Candidate : constant Project_Search_Result := State.Results (I - 1);
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

   function Contains_Newline (Text : String) return Boolean;

   procedure Reset_Results
     (State  : in out Project_Search_State;
      Status : Project_Search_Status := Project_Search_Idle);

   procedure Preserve_Results_For_Precondition_Failure
     (State  : in out Project_Search_State;
      Status : Project_Search_Status;
      Query  : String);

   procedure Begin_Search_Run
     (State             : in out Project_Search_State;
      Query             : String;
      Project_Open      : Boolean;
      File_Total        : Natural;
      No_Project_Status : Project_Search_Status;
      No_Files_Status   : Project_Search_Status;
      Previous_Key      : out Preserved_Result_Key;
      Effective_Options : in out Project_Search_Options;
      Regex_Compile     : out Ada_Regexp.Compile_Result;
      Ready             : out Boolean)
   is
   begin
      Previous_Key := Capture_Selected_Key (State);
      Effective_Options.Case_Sensitive := State.Case_Sensitive_Search;
      Ready := False;

      if Query'Length = 0 or else Contains_Newline (Query) then
         --  invalid/no-query execution clears transient results so
         --  render can show the no-query state without stale rows.
         Reset_Results (State, Project_Search_Empty_Query);
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
            Reset_Results (State, Project_Search_Invalid_Regex);
            State.Last_Query_Text := To_Unbounded_String (Query);
            State.Last_Regex_Error :=
              To_Unbounded_String (Ada_Regexp.Status_Image (Regex_Compile.Status));
            return;
         end if;
      end if;

      Reset_Results (State, Project_Search_Idle);
      State.Last_Query_Text := To_Unbounded_String (Query);
      Ready := True;
   end Begin_Search_Run;

   procedure Finalize_Search_Run
     (State             : in out Project_Search_State;
      Previous_Key      : Preserved_Result_Key;
      Effective_Options : Project_Search_Options;
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

      State.Last_Status := Project_Search_Ok;
   end Finalize_Search_Run;

   function Fold_Case (Text : String) return String is
      Result : String (Text'Range);
   begin
      for I in Text'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (Text (I));
      end loop;
      return Result;
   end Fold_Case;

   function Contains_Newline (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Ch = ASCII.LF or else Ch = ASCII.CR then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Newline;

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
         --  Very long query/match: keep the beginning of the match deterministically.
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
      Max_Length   : Natural := Max_Search_Result_Preview_Length) return String
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
     (Line                : String;
      Match_Column        : Natural;
      Match_Length        : Natural;
      Preview             : String;
      Preview_Match_Start : out Natural;
      Preview_Match_Length: out Natural)
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

   procedure Internal_Clear_Replace_Preview
     (State : in out Project_Search_State)
   is
   begin
      State.Replace_Rows.Clear;
      State.Replace_Selected_Index := 0;
      State.Replace_Status_Value := Project_Replace_No_Preview;
      State.Replace_Stale := False;
      State.Replace_Search_Token := 0;
   end Internal_Clear_Replace_Preview;

   procedure Reset_Results
     (State  : in out Project_Search_State;
      Status : Project_Search_Status := Project_Search_Idle)
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
     (State  : in out Project_Search_State;
      Status : Project_Search_Status;
      Query  : String)
   is
   begin
      State.Last_Status := Status;
      State.Last_Query_Text := To_Unbounded_String (Query);
      if Natural (State.Results.Length) > 0 then
         State.Stale := True;
         Mark_Replace_Preview_Stale (State);
      end if;
   end Preserve_Results_For_Precondition_Failure;

   procedure Clear
     (State : in out Project_Search_State)
   is
   begin
      State.Query_Text := Null_Unbounded_String;
      State.Kind_Filter := Project_Search_Kind_All;
      State.Scope_Text := Null_Unbounded_String;
      State.Include_Filter_Text := Null_Unbounded_String;
      State.Exclude_Filter_Text := Null_Unbounded_String;
      State.Case_Sensitive_Search := False;
      State.Whole_Word_Search := False;
      State.Regex_Search := False;
      State.Last_Regex_Error := Null_Unbounded_String;
      State.Replace_Text_Value := Null_Unbounded_String;
      State.Replace_Mode := False;
      Reset_Results (State, Project_Search_Idle);
   end Clear;

   procedure Clear_Results_Preserve_Query
     (State : in out Project_Search_State)
   is
   begin
      Reset_Results (State, Project_Search_Idle);
   end Clear_Results_Preserve_Query;

   function Query
     (State : Project_Search_State) return String
   is
   begin
      return To_String (State.Query_Text);
   end Query;

   procedure Set_Query
     (State : in out Project_Search_State;
      Query : String)
   is
   begin
      if To_String (State.Query_Text) /= Query then
         State.Query_Text := To_Unbounded_String (Query);
         Clear_Results_Preserve_Query (State);
      end if;
   end Set_Query;

   function Has_Query
     (State : Project_Search_State) return Boolean
   is
   begin
      return Length (State.Query_Text) > 0;
   end Has_Query;

   function Status
     (State : Project_Search_State) return Project_Search_Status
   is
   begin
      return State.Last_Status;
   end Status;

   procedure Set_Status
     (State  : in out Project_Search_State;
      Status : Project_Search_Status)
   is
   begin
      State.Last_Status := Status;
   end Set_Status;

   function Result_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return Natural (State.Results.Length);
   end Result_Count;

   function Has_Results
     (State : Project_Search_State) return Boolean
   is
   begin
      return Natural (State.Results.Length) > 0;
   end Has_Results;

   function File_Group_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return Natural (State.File_Groups.Length);
   end File_Group_Count;


   function Project_Search_No_Duplicate_Lifecycle_State
     (State : Project_Search_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      --  Project_Search_State has no file-lifecycle-visible
      --  duplicate state: no result path cache beyond retained result rows,
      --  dirty hint cache, lifecycle status cache, target history, operation
      --  history, prompt input cache, filesystem probe cache, association
      --  repair cache, project/searchable-file repair cache, or imported
      --  Quick Open/Open Buffer Switcher projection state.
      return True;
   end Project_Search_No_Duplicate_Lifecycle_State;

   function Project_Search_No_Prompt_State
     (State : Project_Search_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      --  Explicit-target prompts remain owned by the canonical Executor prompt
      --  plumbing.  Project Search carries no pending target command, prompt
      --  input, prompt render cache, or prompt persistence fields.
      return True;
   end Project_Search_No_Prompt_State;

   function Project_Search_Query_Selection_Source_Target_Boundary
     (State : Project_Search_State) return Boolean
   is
      Count    : constant Natural := Natural (State.Results.Length);
      Selected : constant Natural := State.Selected_Index;
   begin
      --  Query and selection are Project Search UI state only.  They are not
      --  source overrides, target prompt seeds, lifecycle target histories, or
      --  command execution inputs.  The only structural invariant Project
      --  Search can own here is that selection references the current retained
      --  result vector or is empty.
      return (if Count = 0 then Selected = 0 else Selected in 1 .. Count);
   end Project_Search_Query_Selection_Source_Target_Boundary;

   function Project_Search_Project_Source_Boundary_Canonical
     (State : Project_Search_State) return Boolean
   is
      Expected_First : Natural := 1;
      Seen_Results   : Natural := 0;
      Group          : Project_Search_File_Group;
      Result         : Project_Search_Result;
   begin
      --  Retained project/searchable-file rows remain grouped by retained
      --  source path.  Lifecycle observation does not rescan, repair, add,
      --  remove, or promote targets into searchable sources.
      for G in 1 .. Natural (State.File_Groups.Length) loop
         Group := State.File_Groups (G - 1);
         if Group.First_Result_Index /= Expected_First
           or else Group.Result_Count = 0
           or else Group.First_Result_Index + Group.Result_Count - 1 > Natural (State.Results.Length)
         then
            return False;
         end if;

         for R in Group.First_Result_Index .. Group.First_Result_Index + Group.Result_Count - 1 loop
            Result := State.Results (R - 1);
            if Result.File_Node_Id /= Group.File_Node_Id
              or else To_String (Result.Relative_Path) /= To_String (Group.Relative_Path)
              or else To_String (Result.Absolute_Path) /= To_String (Group.Absolute_Path)
            then
               return False;
            end if;
            Seen_Results := Seen_Results + 1;
         end loop;
         Expected_First := Expected_First + Group.Result_Count;
      end loop;

      return Seen_Results = Natural (State.Results.Length);
   end Project_Search_Project_Source_Boundary_Canonical;

   function Project_Search_File_Lifecycle_Observation_Canonical
     (State : Project_Search_State) return Boolean
   is
   begin
      return Project_Search_No_Duplicate_Lifecycle_State (State)
        and then Project_Search_No_Prompt_State (State)
        and then Project_Search_Query_Selection_Source_Target_Boundary (State)
        and then Project_Search_Project_Source_Boundary_Canonical (State);
   end Project_Search_File_Lifecycle_Observation_Canonical;

   function Project_Search_File_Lifecycle_Observation_Frozen
     (State : Project_Search_State) return Boolean
   is
   begin
      --  final freeze composes the canonical structural predicates.
      --  Product truth remains in retained Project Search result/query/selection
      --  state and canonical buffer/project sources supplied to snapshot builders;
      --  there is deliberately no second Project Search lifecycle model to check.
      return Project_Search_File_Lifecycle_Observation_Canonical (State);
   end Project_Search_File_Lifecycle_Observation_Frozen;

   function Files_Searched
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Files_Searched_Count;
   end Files_Searched;

   function Files_With_Matches
     (State : Project_Search_State) return Natural
   is
   begin
      return Natural (State.File_Groups.Length);
   end Files_With_Matches;

   function Eligible_File_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Eligible_File_Total;
   end Eligible_File_Count;

   function Read_Error_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Read_Error_Count;
   end Read_Error_Count;

   function Skipped_File_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Read_Error_Count
        + State.Skipped_Missing_Total
        + State.Skipped_Large_Total
        + State.Skipped_Binary_Total;
   end Skipped_File_Count;

   function Skipped_Missing_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Skipped_Missing_Total;
   end Skipped_Missing_Count;

   function Skipped_Large_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Skipped_Large_Total;
   end Skipped_Large_Count;

   function Skipped_Binary_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Skipped_Binary_Total;
   end Skipped_Binary_Count;

   function Matches_Truncated_Count
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Matches_Truncated_Total;
   end Matches_Truncated_Count;

   function Was_Truncated
     (State : Project_Search_State) return Boolean
   is
   begin
      return State.Truncated;
   end Was_Truncated;

   function Results_Truncated
     (State : Project_Search_State) return Boolean
   is
   begin
      return State.Truncated;
   end Results_Truncated;

   function Last_Run_Query
     (State : Project_Search_State) return String
   is
   begin
      return To_String (State.Last_Query_Text);
   end Last_Run_Query;

   function File_Kind_Filter
     (State : Project_Search_State) return Project_Search_File_Kind_Filter
   is
   begin
      return State.Kind_Filter;
   end File_Kind_Filter;

   function File_Kind_Filter_Image
     (Kind : Project_Search_File_Kind_Filter) return String
   is
   begin
      case Kind is
         when Project_Search_Kind_All => return "all";
         when Project_Search_Kind_Ada => return "Ada";
         when Project_Search_Kind_Tests => return "Tests";
         when Project_Search_Kind_Docs => return "Docs";
         when Project_Search_Kind_Other => return "Other";
      end case;
   end File_Kind_Filter_Image;

   procedure Cycle_File_Kind_Filter
     (State : in out Project_Search_State;
      Forward : Boolean := True)
   is
   begin
      if Forward then
         case State.Kind_Filter is
            when Project_Search_Kind_All => State.Kind_Filter := Project_Search_Kind_Ada;
            when Project_Search_Kind_Ada => State.Kind_Filter := Project_Search_Kind_Tests;
            when Project_Search_Kind_Tests => State.Kind_Filter := Project_Search_Kind_Docs;
            when Project_Search_Kind_Docs => State.Kind_Filter := Project_Search_Kind_Other;
            when Project_Search_Kind_Other => State.Kind_Filter := Project_Search_Kind_All;
         end case;
      else
         case State.Kind_Filter is
            when Project_Search_Kind_All => State.Kind_Filter := Project_Search_Kind_Other;
            when Project_Search_Kind_Ada => State.Kind_Filter := Project_Search_Kind_All;
            when Project_Search_Kind_Tests => State.Kind_Filter := Project_Search_Kind_Ada;
            when Project_Search_Kind_Docs => State.Kind_Filter := Project_Search_Kind_Tests;
            when Project_Search_Kind_Other => State.Kind_Filter := Project_Search_Kind_Docs;
         end case;
      end if;
      Clear_Results_Preserve_Query (State);
   end Cycle_File_Kind_Filter;

   procedure Clear_File_Kind_Filter
     (State : in out Project_Search_State)
   is
   begin
      if State.Kind_Filter /= Project_Search_Kind_All then
         State.Kind_Filter := Project_Search_Kind_All;
         Clear_Results_Preserve_Query (State);
      end if;
   end Clear_File_Kind_Filter;

   function Path_Scope
     (State : Project_Search_State) return String
   is
   begin
      return To_String (State.Scope_Text);
   end Path_Scope;

   function Include_Path_Filter
     (State : Project_Search_State) return String
   is
   begin
      return To_String (State.Include_Filter_Text);
   end Include_Path_Filter;

   function Exclude_Path_Filter
     (State : Project_Search_State) return String
   is
   begin
      return To_String (State.Exclude_Filter_Text);
   end Exclude_Path_Filter;

   function Normalize_Path_Scope
     (Scope : String;
      Valid : out Boolean) return String
   is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Scope, Ada.Strings.Both);
      Text    : Unbounded_String := Null_Unbounded_String;
      Ch      : Character;
   begin
      Valid := False;
      if Trimmed'Length = 0 then
         Valid := True;
         return "";
      elsif Trimmed'Length >= 2 and then Trimmed (Trimmed'First + 1) = ':' then
         return "";
      end if;

      for I in Trimmed'Range loop
         Ch := Trimmed (I);
         if Ch = '\' then
            Ch := '/';
         end if;
         if Ch = '/' then
            if Length (Text) > 0 and then Element (Text, Length (Text)) /= '/' then
               Append (Text, Ch);
            end if;
         else
            Append (Text, Ch);
         end if;
      end loop;

      declare
         Normal : String := To_String (Text);
      begin
         if Normal'Length = 0 then
            Valid := True;
            return "";
         end if;
         declare
            Start : Positive := Normal'First;
            Stop  : Natural;
         begin
            while Start <= Normal'Last loop
               Stop := Start;
               while Stop <= Normal'Last and then Normal (Stop) /= '/' loop
                  Stop := Stop + 1;
               end loop;
               declare
                  Segment : constant String := Normal (Start .. Stop - 1);
               begin
                  if Segment = ".." or else Segment = "." then
                     return "";
                  end if;
               end;
               Start := Stop + 1;
            end loop;
         end;
         Valid := True;
         if Normal (Normal'Last) /= '/' then
            return Normal & "/";
         else
            return Normal;
         end if;
      end;
   exception
      when others =>
         Valid := False;
         return "";
   end Normalize_Path_Scope;

   procedure Set_Path_Scope
     (State : in out Project_Search_State;
      Scope : String;
      Valid : out Boolean)
   is
      Normal : constant String := Normalize_Path_Scope (Scope, Valid);
   begin
      if Valid
        and then (To_String (State.Scope_Text) /= Normal
                  or else (Normal'Length = 0
                           and then Natural (State.Results.Length) > 0))
      then
         State.Scope_Text := To_Unbounded_String (Normal);
         Clear_Results_Preserve_Query (State);
      end if;
   end Set_Path_Scope;

   procedure Clear_Path_Scope
     (State : in out Project_Search_State)
   is
   begin
      if Length (State.Scope_Text) > 0 then
         State.Scope_Text := Null_Unbounded_String;
         Clear_Results_Preserve_Query (State);
      end if;
   end Clear_Path_Scope;

   function Normalize_Path_Filter
     (Filter : String;
      Valid  : out Boolean) return String
   is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Filter, Ada.Strings.Both);
      Result  : Unbounded_String := Null_Unbounded_String;

      procedure Append_Normalized_Token (Raw_Token : String) is
         Raw_Trimmed : constant String := Ada.Strings.Fixed.Trim (Raw_Token, Ada.Strings.Both);
         Token       : Unbounded_String := Null_Unbounded_String;
         Ch          : Character;
      begin
         if Raw_Trimmed'Length = 0 then
            Valid := False;
            return;
         elsif Raw_Trimmed'Length >= 2
           and then Raw_Trimmed (Raw_Trimmed'First + 1) = ':'
         then
            Valid := False;
            return;
         elsif Raw_Trimmed (Raw_Trimmed'First) = '/'
           or else Raw_Trimmed (Raw_Trimmed'First) = '\'
         then
            Valid := False;
            return;
         end if;

         for I in Raw_Trimmed'Range loop
            Ch := Raw_Trimmed (I);
            if Ch = '\' then
               Ch := '/';
            end if;

            if Ch = ASCII.LF
              or else Ch = ASCII.CR
              or else Character'Pos (Ch) < 32
            then
               Valid := False;
               return;
            end if;

            Append (Token, Ch);
         end loop;

         declare
            Normal : constant String := To_String (Token);
            Start  : Positive := Normal'First;
            Stop   : Natural;
         begin
            while Start <= Normal'Last loop
               Stop := Start;
               while Stop <= Normal'Last and then Normal (Stop) /= '/' loop
                  Stop := Stop + 1;
               end loop;
               declare
                  Segment : constant String := Normal (Start .. Stop - 1);
               begin
                  if Segment = ".." or else Segment = "." then
                     Valid := False;
                     return;
                  end if;
               end;
               Start := Stop + 1;
            end loop;

            if Length (Result) > 0 then
               Append (Result, ',');
            end if;
            Append (Result, Normal);
            Valid := True;
         end;
      end Append_Normalized_Token;

      Token_Start : Positive;
   begin
      Valid := False;
      if Trimmed'Length = 0 then
         Valid := True;
         return "";
      end if;

      Token_Start := Trimmed'First;
      for I in Trimmed'Range loop
         if Trimmed (I) = ',' or else Trimmed (I) = ';' then
            Append_Normalized_Token (Trimmed (Token_Start .. I - 1));
            if not Valid and then Length (Result) = 0 then
               return "";
            elsif not Valid then
               return "";
            end if;
            Token_Start := I + 1;
         end if;
      end loop;

      Append_Normalized_Token (Trimmed (Token_Start .. Trimmed'Last));
      if not Valid and then Length (Result) = 0 then
         return "";
      elsif not Valid then
         return "";
      end if;

      Valid := True;
      return To_String (Result);
   exception
      when others =>
         Valid := False;
         return "";
   end Normalize_Path_Filter;

   procedure Set_Include_Path_Filter
     (State  : in out Project_Search_State;
      Filter : String;
      Valid  : out Boolean)
   is
      Normal : constant String := Normalize_Path_Filter (Filter, Valid);
   begin
      if Valid and then To_String (State.Include_Filter_Text) /= Normal then
         State.Include_Filter_Text := To_Unbounded_String (Normal);
         Clear_Results_Preserve_Query (State);
      end if;
   end Set_Include_Path_Filter;

   procedure Set_Exclude_Path_Filter
     (State  : in out Project_Search_State;
      Filter : String;
      Valid  : out Boolean)
   is
      Normal : constant String := Normalize_Path_Filter (Filter, Valid);
   begin
      if Valid and then To_String (State.Exclude_Filter_Text) /= Normal then
         State.Exclude_Filter_Text := To_Unbounded_String (Normal);
         Clear_Results_Preserve_Query (State);
      end if;
   end Set_Exclude_Path_Filter;

   procedure Clear_Include_Path_Filter
     (State : in out Project_Search_State)
   is
   begin
      if Length (State.Include_Filter_Text) > 0 then
         State.Include_Filter_Text := Null_Unbounded_String;
         Clear_Results_Preserve_Query (State);
      end if;
   end Clear_Include_Path_Filter;

   procedure Clear_Exclude_Path_Filter
     (State : in out Project_Search_State)
   is
   begin
      if Length (State.Exclude_Filter_Text) > 0 then
         State.Exclude_Filter_Text := Null_Unbounded_String;
         Clear_Results_Preserve_Query (State);
      end if;
   end Clear_Exclude_Path_Filter;

   function Case_Sensitive
     (State : Project_Search_State) return Boolean
   is
   begin
      return State.Case_Sensitive_Search;
   end Case_Sensitive;

   procedure Set_Case_Sensitive
     (State : in out Project_Search_State;
      Value : Boolean)
   is
   begin
      if State.Case_Sensitive_Search /= Value then
         State.Case_Sensitive_Search := Value;
         Clear_Results_Preserve_Query (State);
      end if;
   end Set_Case_Sensitive;

   procedure Toggle_Case_Sensitive
     (State : in out Project_Search_State)
   is
   begin
      Set_Case_Sensitive (State, not State.Case_Sensitive_Search);
   end Toggle_Case_Sensitive;

   function Whole_Word
     (State : Project_Search_State) return Boolean
   is
   begin
      return State.Whole_Word_Search;
   end Whole_Word;

   procedure Set_Whole_Word
     (State : in out Project_Search_State;
      Value : Boolean)
   is
   begin
      if State.Whole_Word_Search /= Value then
         State.Whole_Word_Search := Value;
         Clear_Results_Preserve_Query (State);
      end if;
   end Set_Whole_Word;

   procedure Toggle_Whole_Word
     (State : in out Project_Search_State)
   is
   begin
      Set_Whole_Word (State, not State.Whole_Word_Search);
   end Toggle_Whole_Word;

   function Regex_Enabled
     (State : Project_Search_State) return Boolean
   is
   begin
      return State.Regex_Search;
   end Regex_Enabled;

   function Regex_Error
     (State : Project_Search_State) return String
   is
   begin
      return To_String (State.Last_Regex_Error);
   end Regex_Error;

   procedure Set_Regex_Enabled
     (State : in out Project_Search_State;
      Value : Boolean)
   is
   begin
      if State.Regex_Search /= Value then
         State.Regex_Search := Value;
         State.Last_Regex_Error := Null_Unbounded_String;
         Clear_Results_Preserve_Query (State);
      end if;
   end Set_Regex_Enabled;

   procedure Toggle_Regex
     (State : in out Project_Search_State)
   is
   begin
      Set_Regex_Enabled (State, not State.Regex_Search);
   end Toggle_Regex;

   procedure Clear_Regex
     (State : in out Project_Search_State)
   is
   begin
      Set_Regex_Enabled (State, False);
   end Clear_Regex;

   function Is_Stale
     (State : Project_Search_State) return Boolean
   is
   begin
      return State.Stale;
   end Is_Stale;

   procedure Mark_Stale
     (State : in out Project_Search_State)
   is
   begin
      --  completeness: File Tree mutations can invalidate a
      --  retained search even when the last run produced zero rows.  Creating
      --  or renaming a file can introduce matches for the same query, so the
      --  stale marker follows the retained query/run status as well as visible
      --  result rows.  Keep an entirely idle/no-query surface unstale.
      if Natural (State.Results.Length) > 0
        or else Length (State.Query_Text) > 0
        or else Length (State.Last_Query_Text) > 0
        or else State.Last_Status /= Project_Search_Idle
        or else Natural (State.Replace_Rows.Length) > 0
      then
         State.Stale := True;
         Mark_Replace_Preview_Stale (State);
      end if;
   end Mark_Stale;

   procedure Mark_Stale_Unconditionally
     (State : in out Project_Search_State)
   is
   begin
      State.Stale := True;
      State.Replace_Stale := True;
      State.Replace_Status_Value := Project_Replace_Search_Stale;
      Mark_Replace_Preview_Stale (State);
   end Mark_Stale_Unconditionally;

   procedure Clear_Stale
     (State : in out Project_Search_State)
   is
   begin
      State.Stale := False;
   end Clear_Stale;

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
         Internal_Clear_Replace_Preview (State);
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
         Internal_Clear_Replace_Preview (State);
      end if;
   end Set_Replace_Mode_Active;

   procedure Clear_Replace_Preview
     (State : in out Project_Search_State)
   is
   begin
      Internal_Clear_Replace_Preview (State);
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
      Internal_Clear_Replace_Preview (State);
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

   function Result_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result
   is
   begin
      if Index > Natural (State.Results.Length) then
         return (others => <>);
      end if;
      return State.Results (Index - 1);
   end Result_At;

   function Result_Key
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result_Key
   is
      Result : constant Project_Search_Result := Result_At (State, Index);
   begin
      if Result.Id = No_Project_Search_Result then
         return (others => <>);
      end if;
      return
        (Project_Relative_Path => Result.Relative_Path,
         Line_Number           => Result.Row,
         Result_Ordinal        => Index);
   end Result_Key;

   function File_Group_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_File_Group
   is
   begin
      if Index > Natural (State.File_Groups.Length) then
         return (others => <>);
      end if;
      return State.File_Groups (Index - 1);
   end File_Group_At;

   function Selected_Result_Index
     (State : Project_Search_State) return Natural
   is
   begin
      return State.Selected_Index;
   end Selected_Result_Index;

   procedure Set_Selected_Result_Index
     (State : in out Project_Search_State;
      Index : Natural)
   is
   begin
      if Index = 0 or else Natural (State.Results.Length) = 0 then
         State.Selected_Index := 0;
      elsif Index > Natural (State.Results.Length) then
         State.Selected_Index := Natural (State.Results.Length);
      else
         State.Selected_Index := Index;
      end if;
      if Natural (State.Replace_Rows.Length) > 0 then
         Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
      end if;
   end Set_Selected_Result_Index;

   procedure Ensure_Valid_Selection
     (State : in out Project_Search_State)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
      elsif State.Selected_Index = 0 then
         State.Selected_Index := 1;
      elsif State.Selected_Index > Count then
         State.Selected_Index := Count;
      end if;
      if Natural (State.Replace_Rows.Length) > 0 then
         Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
      end if;
   end Ensure_Valid_Selection;

   function Can_Move_Next
     (State : Project_Search_State) return Boolean
   is
   begin
      return Natural (State.Results.Length) > 0;
   end Can_Move_Next;

   function Can_Move_Previous
     (State : Project_Search_State) return Boolean
   is
   begin
      return Natural (State.Results.Length) > 0;
   end Can_Move_Previous;

   procedure Move_Selected_Result
     (State     : in out Project_Search_State;
      Direction : Project_Search_Result_Direction;
      Wrap      : Boolean := True)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         return;
      end if;

      if State.Selected_Index = 0 then
         --  A no-selection state is valid after results are rebuilt or when
         --  command availability is checked before the user has visited the
         --  result list.  Treat next/previous as initial selection commands:
         --  next lands on the first result, previous lands on the last result.
         case Direction is
            when Next_Result =>
               State.Selected_Index := 1;
            when Previous_Result =>
               State.Selected_Index := Count;
         end case;
         if Natural (State.Replace_Rows.Length) > 0 then
            Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
         end if;
         return;
      end if;

      Ensure_Valid_Selection (State);
      case Direction is
         when Next_Result =>
            if State.Selected_Index < Count then
               State.Selected_Index := State.Selected_Index + 1;
            elsif Wrap then
               State.Selected_Index := 1;
            end if;
         when Previous_Result =>
            if State.Selected_Index > 1 then
               State.Selected_Index := State.Selected_Index - 1;
            elsif Wrap then
               State.Selected_Index := Count;
            end if;
      end case;
      if Natural (State.Replace_Rows.Length) > 0 then
         Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
      end if;
   end Move_Selected_Result;


   procedure Select_First_Result
     (State : in out Project_Search_State)
   is
   begin
      if Natural (State.Results.Length) = 0 then
         State.Selected_Index := 0;
      else
         State.Selected_Index := 1;
      end if;
      if Natural (State.Replace_Rows.Length) > 0 then
         Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
      end if;
   end Select_First_Result;

   procedure Select_Last_Result
     (State : in out Project_Search_State)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      State.Selected_Index := Count;
      if Natural (State.Replace_Rows.Length) > 0 then
         Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
      end if;
   end Select_Last_Result;

   function Select_First_Result_For_Path
     (State : in out Project_Search_State;
      Path  : String) return Boolean
   is
   begin
      if Natural (State.Results.Length) = 0 then
         State.Selected_Index := 0;
         return False;
      end if;

      if State.Selected_Index in 1 .. Natural (State.Results.Length) then
         declare
            Current : constant Project_Search_Result :=
              State.Results (State.Selected_Index - 1);
         begin
            if To_String (Current.Relative_Path) = Path then
               return True;
            end if;
         end;
      end if;

      for I in 1 .. Natural (State.Results.Length) loop
         declare
            Candidate : constant Project_Search_Result := State.Results (I - 1);
         begin
            if To_String (Candidate.Relative_Path) = Path then
               State.Selected_Index := I;
               if Natural (State.Replace_Rows.Length) > 0 then
                  Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
               end if;
               return True;
            end if;
         end;
      end loop;

      return False;
   end Select_First_Result_For_Path;

   function Directory_Scope_Of_Path
     (Path : String) return String
   is
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' then
            Last_Slash := I;
         end if;
      end loop;

      if Last_Slash = 0 then
         return "";
      else
         return Path (Path'First .. Last_Slash);
      end if;
   end Directory_Scope_Of_Path;

   function Selected_Result_Directory
     (State : Project_Search_State;
      Found : out Boolean) return String
   is
      Result : Project_Search_Result;
   begin
      Found := State.Selected_Index in 1 .. Natural (State.Results.Length);
      if not Found then
         return "";
      end if;

      Result := State.Results (State.Selected_Index - 1);
      return Directory_Scope_Of_Path (To_String (Result.Relative_Path));
   end Selected_Result_Directory;

   function Selected_Result
     (State : Project_Search_State;
      Found : out Boolean) return Project_Search_Result
   is
   begin
      Found := State.Selected_Index in 1 .. Natural (State.Results.Length);
      if Found then
         return State.Results (State.Selected_Index - 1);
      else
         return (others => <>);
      end if;
   end Selected_Result;

   procedure Move_Selection_Down
     (State : in out Project_Search_State)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
      elsif State.Selected_Index = 0 or else State.Selected_Index >= Count then
         State.Selected_Index := 1;
      else
         State.Selected_Index := State.Selected_Index + 1;
      end if;

      if Natural (State.Replace_Rows.Length) > 0 then
         Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
      end if;
   end Move_Selection_Down;

   procedure Move_Selection_Up
     (State : in out Project_Search_State)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
      elsif State.Selected_Index <= 1 then
         State.Selected_Index := Count;
      else
         State.Selected_Index := State.Selected_Index - 1;
      end if;

      if Natural (State.Replace_Rows.Length) > 0 then
         Set_Selected_Replace_Preview_Index (State, State.Selected_Index);
      end if;
   end Move_Selection_Up;

   procedure Append_Result
     (State      : in out Project_Search_State;
      Node       : Editor.File_Tree.File_Tree_Node_Summary;
      Row        : Natural;
      Start_Col  : Natural;
      End_Col    : Natural;
      Line       : String;
      Query_Length : Natural;
      Options    : Project_Search_Options;
      File_Count : in out Natural)
   is
      Result : Project_Search_Result;
      Group  : Project_Search_File_Group;
      Match_Column : constant Natural := Start_Col + 1;
      Preview_Max : constant Natural := Natural'Min
        (Max_Search_Result_Preview_Length, Natural'Max (1, Options.Max_Line_Length));
      Preview : constant String := Build_Project_Search_Line_Preview
        (Line         => Line,
         Match_Column => Match_Column,
         Match_Length => Query_Length,
         Max_Length   => Preview_Max);
      Preview_Start  : Natural := 0;
      Preview_Length : Natural := 0;
   begin
      if Natural (State.Results.Length) >= Options.Max_Result_Count then
         State.Truncated := True;
         State.Matches_Truncated_Total := State.Matches_Truncated_Total + 1;
         return;
      end if;

      if State.File_Groups.Length = 0
        or else State.File_Groups.Last_Element.File_Node_Id /= Node.Id
      then
         Group :=
           (File_Node_Id       => Node.Id,
            Relative_Path      => Node.Relative_Path,
            Absolute_Path      => Node.Absolute_Path,
            First_Result_Index => Natural (State.Results.Length) + 1,
            Result_Count       => 0);
         State.File_Groups.Append (Group);
         File_Count := File_Count + 1;
      end if;

      Build_Project_Search_Preview_Match_Range
        (Line                 => Line,
         Match_Column         => Match_Column,
         Match_Length         => Query_Length,
         Preview              => Preview,
         Preview_Match_Start  => Preview_Start,
         Preview_Match_Length => Preview_Length);

      Result :=
        (Id                   => Project_Search_Result_Id (Natural (State.Results.Length) + 1),
         File_Node_Id         => Node.Id,
         Relative_Path        => Node.Relative_Path,
         Absolute_Path        => Node.Absolute_Path,
         Row                  => Row,
         Start_Column         => Start_Col,
         End_Column           => End_Col,
         Match_Column         => Match_Column,
         Original_Line_Length => Line'Length,
         Line_Text            => To_Unbounded_String (Line),
         Line_Preview         => To_Unbounded_String (Preview),
         Preview_Match_Start  => Preview_Start,
         Preview_Match_Length => Preview_Length);
      State.Results.Append (Result);

      Group := State.File_Groups.Last_Element;
      Group.Result_Count := Group.Result_Count + 1;
      State.File_Groups.Replace_Element (State.File_Groups.Last_Index, Group);
   end Append_Result;

   function Is_Project_Search_Word_Character (Ch : Character) return Boolean is
   begin
      return Ada.Characters.Handling.Is_Alphanumeric (Ch) or else Ch = '_';
   end Is_Project_Search_Word_Character;

   function Whole_Word_Boundary
     (Line         : String;
      Hit          : Natural;
      Match_Length : Natural) return Boolean
   is
      Match_Last : constant Natural := Hit + Match_Length - 1;
   begin
      if Hit = 0 or else Match_Length = 0 then
         return False;
      end if;

      return (Hit = Line'First
              or else not Is_Project_Search_Word_Character (Line (Hit - 1)))
        and then (Match_Last >= Line'Last
                  or else not Is_Project_Search_Word_Character (Line (Match_Last + 1)));
   end Whole_Word_Boundary;

   function Find_Match_From
     (Line              : String;
      Comparable_Line   : String;
      Comparable_Needle : String;
      Whole_Word        : Boolean;
      From              : Positive) return Natural
   is
      Hit   : Natural := 0;
      Start : Positive := From;
   begin
      while Start <= Comparable_Line'Last loop
         Hit := Ada.Strings.Fixed.Index
           (Source  => Comparable_Line (Start .. Comparable_Line'Last),
            Pattern => Comparable_Needle);
         if Hit = 0 then
            return 0;
         elsif (not Whole_Word)
           or else Whole_Word_Boundary
             (Line         => Line,
              Hit          => Line'First + Natural (Hit - Comparable_Line'First),
              Match_Length => Comparable_Needle'Length)
         then
            return Hit;
         else
            Start := Hit + 1;
         end if;
      end loop;
      return 0;
   end Find_Match_From;

   procedure Search_Line
     (State             : in out Project_Search_State;
      Node              : Editor.File_Tree.File_Tree_Node_Summary;
      Line              : String;
      Row               : Natural;
      Needle            : String;
      Comparable_Needle : String;
      Regex             : Ada_Regexp.Regexp;
      Use_Regex         : Boolean;
      Options           : Project_Search_Options;
      File_Matches      : in out Natural;
      File_Count        : in out Natural)
   is
      Source_Line : constant String := Line;
      Comparable_Line : constant String :=
        (if Options.Case_Sensitive then Source_Line else Fold_Case (Source_Line));
      Hit        : Natural := 0;
      Next_Start : Positive := Comparable_Line'First;
      Match      : Ada_Regexp.Match_Result;
   begin
      if Needle'Length = 0 or else Source_Line'Length = 0 then
         return;
      elsif Options.Max_Matches_Per_File = 0 then
         State.Truncated := True;
         State.Matches_Truncated_Total := State.Matches_Truncated_Total + 1;
         return;
      end if;

      while Next_Start <= Source_Line'Last
        and then not State.Truncated
        and then File_Matches < Options.Max_Matches_Per_File
      loop
         if Use_Regex then
            Match := Ada_Regexp.Find_From
              (Expression => Regex,
               Text       => Source_Line,
               From       => Next_Start,
               Options    =>
                 (Case_Sensitive => Options.Case_Sensitive,
                  Whole_Word     => State.Whole_Word_Search,
                  Max_Steps      => Options.Regex_Max_Steps));

            if Match.Status = Ada_Regexp.No_Match then
               exit;
            elsif Match.Status = Ada_Regexp.Match_Limit_Exceeded then
               State.Truncated := True;
               State.Matches_Truncated_Total := State.Matches_Truncated_Total + 1;
               exit;
            elsif Match.Status /= Ada_Regexp.Match_Ok then
               State.Last_Regex_Error :=
                 To_Unbounded_String (Ada_Regexp.Status_Image (Match.Status));
               Reset_Results (State, Project_Search_Invalid_Regex);
               State.Last_Query_Text := To_Unbounded_String (Needle);
               return;
            end if;

            if Match.Last >= Match.First then
               Append_Result
                 (State        => State,
                  Node         => Node,
                  Row          => Row,
                  Start_Col    => Natural (Match.First - Source_Line'First),
                  End_Col      => Natural (Match.Last - Source_Line'First + 1),
                  Line         => Source_Line,
                  Query_Length => Natural (Match.Last - Match.First + 1),
                  Options      => Options,
                  File_Count   => File_Count);
            end if;
            File_Matches := File_Matches + 1;

            if File_Matches >= Options.Max_Matches_Per_File then
               State.Truncated := True;
               State.Matches_Truncated_Total := State.Matches_Truncated_Total + 1;
            elsif Match.Last < Match.First then
               --  Zero-length regex matches are allowed by the library, but
               --  Project Search must make progress and must not retain
               --  unbounded zero-width rows.
               Next_Start := Natural'Min (Source_Line'Last + 1, Match.First + 1);
            elsif Match.Last >= Source_Line'Last then
               exit;
            else
               Next_Start := Match.Last + 1;
            end if;
         else
            Hit := Find_Match_From
              (Line              => Source_Line,
               Comparable_Line   => Comparable_Line,
               Comparable_Needle => Comparable_Needle,
               Whole_Word        => State.Whole_Word_Search,
               From              => Next_Start);
            exit when Hit = 0;

            Append_Result
              (State        => State,
               Node         => Node,
               Row          => Row,
               Start_Col    => Natural (Hit - Comparable_Line'First),
               End_Col      => Natural (Hit - Comparable_Line'First + Needle'Length),
               Line         => Source_Line,
               Query_Length => Needle'Length,
               Options      => Options,
               File_Count   => File_Count);
            File_Matches := File_Matches + 1;

            if File_Matches >= Options.Max_Matches_Per_File then
               State.Truncated := True;
               State.Matches_Truncated_Total := State.Matches_Truncated_Total + 1;
            elsif Hit + Comparable_Needle'Length > Comparable_Line'Last then
               exit;
            else
               Next_Start := Hit + Comparable_Needle'Length;
            end if;
         end if;
      end loop;
   end Search_Line;

   procedure Search_Text
     (State      : in out Project_Search_State;
      Node       : Editor.File_Tree.File_Tree_Node_Summary;
      Text       : String;
      Needle     : String;
      Regex      : Ada_Regexp.Regexp;
      Use_Regex  : Boolean;
      Options    : Project_Search_Options;
      File_Count : in out Natural)
   is
      Comparable_Needle : constant String :=
        (if Options.Case_Sensitive then Needle else Fold_Case (Needle));
      Line_Start   : Positive := Text'First;
      Row          : Natural := 1;
      File_Matches : Natural := 0;
      Line_End     : Natural := 0;
   begin
      if Text'Length = 0 then
         return;
      end if;

      while Line_Start <= Text'Last loop
         Line_End := Line_Start;
         while Line_End <= Text'Last and then Text (Line_End) /= ASCII.LF loop
            Line_End := Line_End + 1;
         end loop;

         declare
            Last_Char : Natural := Line_End - 1;
         begin
            if Last_Char >= Line_Start and then Text (Last_Char) = ASCII.CR then
               Last_Char := Last_Char - 1;
            end if;

            if Last_Char >= Line_Start then
               Search_Line
                 (State             => State,
                  Node              => Node,
                  Line              => Text (Line_Start .. Last_Char),
                  Row               => Row,
                  Needle            => Needle,
                  Comparable_Needle => Comparable_Needle,
                  Regex             => Regex,
                  Use_Regex         => Use_Regex,
                  Options           => Options,
                  File_Matches      => File_Matches,
                  File_Count        => File_Count);
            end if;
         end;

         exit when State.Truncated
           or else File_Matches >= Options.Max_Matches_Per_File;
         Row := Row + 1;
         Line_Start := Line_End + 1;
      end loop;
   end Search_Text;

   function Ends_With (Text : String; Suffix : String) return Boolean;

   function Basename (Path : String) return String;

   function Matches_Kind
     (Path : String;
      Kind : Project_Search_File_Kind_Filter) return Boolean;

   function In_Scope (Path : String; Scope : String) return Boolean;

   function Project_Search_Filter_Matches_Path
     (Path   : String;
      Filter : String) return Boolean;

   function Matches_Path_Filters
     (Path    : String;
      Include : String;
      Exclude : String) return Boolean;

   function Project_Relative_Path_Is_Safe
     (Path : String) return Boolean;

   function Absolute_Path_Is_Under_Root
     (Root : String;
      Path : String) return Boolean;

   procedure Search_Project
     (State   : in out Project_Search_State;
      Tree    : Editor.File_Tree.File_Tree_State;
      Reader  : Read_File_Access;
      Options : Project_Search_Options)
   is
      Q              : constant String := To_String (State.Query_Text);
      Scope          : constant String := To_String (State.Scope_Text);
      Include_Filter : constant String := To_String (State.Include_Filter_Text);
      Exclude_Filter : constant String := To_String (State.Exclude_Filter_Text);
      Effective_Options : Project_Search_Options := Options;
      File_Total : constant Natural := Editor.File_Tree.File_Node_Count (Tree);
      Project_Root : constant String :=
        To_String (Editor.File_Tree.Scan_Status (Tree).Root_Path);
      Scanned    : Natural := 0;
      Processed  : Natural := 0;
      Eligible   : Natural := 0;
      File_Count : Natural := 0;
      Regex_Compile : Ada_Regexp.Compile_Result;
      Previous_Key  : Preserved_Result_Key;
      Ready         : Boolean := False;
   begin
      Begin_Search_Run
        (State             => State,
         Query             => Q,
         Project_Open      => True,
         File_Total        => File_Total,
         No_Project_Status => Project_Search_No_Project,
         No_Files_Status   => Project_Search_No_Files,
         Previous_Key      => Previous_Key,
         Effective_Options => Effective_Options,
         Regex_Compile     => Regex_Compile,
         Ready             => Ready);

      if not Ready then
         return;
      end if;

      for I in 1 .. File_Total loop
         declare
            Node : constant Editor.File_Tree.File_Tree_Node_Summary :=
              Editor.File_Tree.File_Node_At (Tree, I);
            Rel_Path : constant String := To_String (Node.Relative_Path);
         begin
            if Node.Id /= Editor.File_Tree.No_File_Tree_Node
              and then Node.Kind = Editor.File_Tree.File_Node
              and then In_Scope (Rel_Path, Scope)
              and then Matches_Path_Filters (Rel_Path, Include_Filter, Exclude_Filter)
              and then Matches_Kind (Rel_Path, State.Kind_Filter)
            then
               declare
                  Abs_Path : constant String := To_String (Node.Absolute_Path);
               begin
                  if not Project_Relative_Path_Is_Safe (Rel_Path)
                    or else not Absolute_Path_Is_Under_Root (Project_Root, Abs_Path)
                  then
                     State.Read_Error_Count := State.Read_Error_Count + 1;
                  else
                     Eligible := Eligible + 1;

                     if Processed < Effective_Options.Max_File_Count
                       and then not State.Truncated
                     then
                        Processed := Processed + 1;

                        declare
                           Size     : Natural := 0;
                           Can_Read : Boolean := True;
                           Content  : Unbounded_String := Null_Unbounded_String;
                           Ok       : Boolean := False;
                        begin
                           if Abs_Path'Length = 0
                             or else not Ada.Directories.Exists (Abs_Path)
                           then
                              State.Skipped_Missing_Total :=
                                State.Skipped_Missing_Total + 1;
                              Can_Read := False;
                           elsif Ada.Directories.Kind (Abs_Path) /=
                             Ada.Directories.Ordinary_File
                           then
                              State.Read_Error_Count := State.Read_Error_Count + 1;
                              Can_Read := False;
                           else
                              begin
                                 Size := Natural (Ada.Directories.Size (Abs_Path));
                              exception
                                 when others =>
                                    State.Read_Error_Count := State.Read_Error_Count + 1;
                                    Can_Read := False;
                              end;

                              if Can_Read
                                and then Effective_Options.Max_File_Size_Bytes > 0
                                and then Size > Effective_Options.Max_File_Size_Bytes
                              then
                                 State.Skipped_Large_Total :=
                                   State.Skipped_Large_Total + 1;
                                 Can_Read := False;
                              end if;
                           end if;

                           if Can_Read then
                              --  completeness: classify binary/decode
                              --  failures before invoking the caller-provided
                              --  reader.  The File Tree-backed search path now
                              --  reports binary files in the same skipped-file
                              --  category as the known-project-file path instead
                              --  of collapsing them into a generic read error.
                              declare
                                 Probe : constant Editor.Files.File_Open_Result :=
                                   Editor.Files.Open_File (Abs_Path);
                              begin
                                 if Probe.Status = Editor.Files.File_Open_Decode_Error then
                                    State.Skipped_Binary_Total :=
                                      State.Skipped_Binary_Total + 1;
                                    Can_Read := False;
                                 elsif Probe.Status = Editor.Files.File_Open_Not_Found then
                                    State.Skipped_Missing_Total :=
                                      State.Skipped_Missing_Total + 1;
                                    Can_Read := False;
                                 elsif Probe.Status /= Editor.Files.File_Open_Ok then
                                    State.Read_Error_Count := State.Read_Error_Count + 1;
                                    Can_Read := False;
                                 end if;
                              end;
                           end if;

                           if Can_Read then
                              Ok := Reader (Abs_Path, Content);
                              if Ok then
                                 Scanned := Scanned + 1;
                                 Search_Text
                                   (State      => State,
                                    Node       => Node,
                                    Text       => To_String (Content),
                                    Needle     => Q,
                                    Regex      => Regex_Compile.Expression,
                                    Use_Regex  => State.Regex_Search,
                                    Options    => Effective_Options,
                                    File_Count => File_Count);
                                 if State.Last_Status = Project_Search_Invalid_Regex then
                                    return;
                                 end if;
                              else
                                 State.Read_Error_Count := State.Read_Error_Count + 1;
                              end if;
                           end if;
                        exception
                           when Ada.Directories.Name_Error =>
                              State.Skipped_Missing_Total :=
                                State.Skipped_Missing_Total + 1;
                           when others =>
                              State.Read_Error_Count := State.Read_Error_Count + 1;
                        end;
                     end if;
                  end if;
               end;
            end if;
         end;
      end loop;

      Finalize_Search_Run
        (State             => State,
         Previous_Key      => Previous_Key,
         Effective_Options => Effective_Options,
         Eligible          => Eligible,
         Scanned           => Scanned,
         Processed         => Processed);
   end Search_Project;


   function Known_File_Summary
     (Item : Editor.Project.Project_File_Entry;
      Index : Positive) return Editor.File_Tree.File_Tree_Node_Summary
   is
   begin
      return
        (Id            => Editor.File_Tree.File_Tree_Node_Id (Index),
         Parent        => Editor.File_Tree.No_File_Tree_Node,
         Kind          => Editor.File_Tree.File_Node,
         Name          => Item.Relative_Path,
         Absolute_Path => Item.Absolute_Path,
         Relative_Path => Item.Relative_Path,
         Depth         => 0,
         Is_Expanded   => False,
         Has_Children  => False);
   end Known_File_Summary;

   function Ends_With (Text : String; Suffix : String) return Boolean is
   begin
      return Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Basename (Path : String) return String is
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = '\' then
            Last_Slash := I;
         end if;
      end loop;
      if Last_Slash = 0 then
         return Path;
      elsif Last_Slash = Path'Last then
         return "";
      else
         return Path (Last_Slash + 1 .. Path'Last);
      end if;
   end Basename;

   function Matches_Kind
     (Path : String;
      Kind : Project_Search_File_Kind_Filter) return Boolean
   is
      Lower : constant String := Fold_Case (Path);
      Base  : constant String := Basename (Lower);
      Is_Ada : constant Boolean := Ends_With (Lower, ".adb") or else Ends_With (Lower, ".ads");
      Is_Test : constant Boolean := Ada.Strings.Fixed.Index (Lower, "/test/") > 0
        or else Ada.Strings.Fixed.Index (Lower, "/tests/") > 0
        or else (Base'Length >= 5 and then Base (Base'First .. Base'First + 4) = "test_")
        or else Ada.Strings.Fixed.Index (Base, "_test.") > 0;
      Is_Doc : constant Boolean := Ends_With (Lower, ".md")
        or else Ends_With (Lower, ".txt")
        or else Ends_With (Lower, ".rst")
        or else Ends_With (Lower, ".adoc");
   begin
      case Kind is
         when Project_Search_Kind_All => return True;
         when Project_Search_Kind_Ada => return Is_Ada;
         when Project_Search_Kind_Tests => return Is_Test;
         when Project_Search_Kind_Docs => return Is_Doc;
         when Project_Search_Kind_Other => return not (Is_Ada or else Is_Test or else Is_Doc);
      end case;
   end Matches_Kind;

   function In_Scope (Path : String; Scope : String) return Boolean is
   begin
      return Scope'Length = 0
        or else (Path'Length >= Scope'Length
                 and then Path (Path'First .. Path'First + Scope'Length - 1) = Scope);
   end In_Scope;

   function Project_Search_Filter_Matches_Path
     (Path   : String;
      Filter : String) return Boolean
   is
      Has_Wildcard : Boolean := False;

      function Match_From
        (Path_Index   : Natural;
         Filter_Index : Natural) return Boolean
      is
         P : Natural := Path_Index;
         F : Natural := Filter_Index;
      begin
         while F <= Filter'Last loop
            if Filter (F) = '*' then
               while F <= Filter'Last and then Filter (F) = '*' loop
                  F := F + 1;
               end loop;

               if F > Filter'Last then
                  return True;
               end if;

               for Candidate in P .. Path'Last + 1 loop
                  if Match_From (Candidate, F) then
                     return True;
                  end if;
               end loop;
               return False;
            end if;

            if P > Path'Last or else Path (P) /= Filter (F) then
               return False;
            end if;

            P := P + 1;
            F := F + 1;
         end loop;

         return P > Path'Last;
      end Match_From;
   begin
      if Filter'Length = 0 then
         return True;
      end if;

      for Ch of Filter loop
         if Ch = '*' then
            Has_Wildcard := True;
            exit;
         end if;
      end loop;

      if not Has_Wildcard then
         return Ada.Strings.Fixed.Index (Path, Filter) > 0;
      end if;

      --  completeness: simple '*' wildcard only.  This is an
      --  in-process deterministic matcher, not shell glob expansion.  It is
      --  anchored to the project-relative path so patterns like "*.adb" and
      --  "src/*" work predictably without escaping the project root.
      return Match_From (Path'First, Filter'First);
   end Project_Search_Filter_Matches_Path;

   function Any_Path_Filter_Matches
     (Path    : String;
      Filters : String) return Boolean
   is
      Token_Start : Positive;
   begin
      if Filters'Length = 0 then
         return False;
      end if;

      Token_Start := Filters'First;
      for I in Filters'Range loop
         if Filters (I) = ',' then
            declare
               Token : constant String := Ada.Strings.Fixed.Trim
                 (Filters (Token_Start .. I - 1), Ada.Strings.Both);
            begin
               if Token'Length > 0
                 and then Project_Search_Filter_Matches_Path (Path, Token)
               then
                  return True;
               end if;
            end;
            Token_Start := I + 1;
         end if;
      end loop;

      declare
         Token : constant String := Ada.Strings.Fixed.Trim
           (Filters (Token_Start .. Filters'Last), Ada.Strings.Both);
      begin
         return Token'Length > 0
           and then Project_Search_Filter_Matches_Path (Path, Token);
      end;
   end Any_Path_Filter_Matches;

   function Matches_Path_Filters
     (Path    : String;
      Include : String;
      Exclude : String) return Boolean
   is
   begin
      if Include'Length > 0
        and then not Any_Path_Filter_Matches (Path, Include)
      then
         return False;
      end if;

      if Exclude'Length > 0
        and then Any_Path_Filter_Matches (Path, Exclude)
      then
         return False;
      end if;

      return True;
   end Matches_Path_Filters;

   function Is_Path_Separator (Ch : Character) return Boolean is
   begin
      return Ch = '/' or else Ch = '\';
   end Is_Path_Separator;

   function Project_Relative_Path_Is_Safe
     (Path : String) return Boolean
   is
      Segment_Start : Positive;
      Stop          : Natural;
   begin
      if Path'Length = 0 then
         return False;
      elsif Is_Path_Separator (Path (Path'First)) then
         return False;
      elsif Path'Length >= 2 and then Path (Path'First + 1) = ':' then
         return False;
      end if;

      for Ch of Path loop
         if Ch = ASCII.LF
           or else Ch = ASCII.CR
           or else Character'Pos (Ch) < 32
         then
            return False;
         end if;
      end loop;

      Segment_Start := Path'First;
      while Segment_Start <= Path'Last loop
         Stop := Segment_Start;
         while Stop <= Path'Last and then not Is_Path_Separator (Path (Stop)) loop
            Stop := Stop + 1;
         end loop;

         declare
            Segment : constant String := Path (Segment_Start .. Stop - 1);
         begin
            if Segment'Length = 0
              or else Segment = "."
              or else Segment = ".."
            then
               return False;
            end if;
         end;

         Segment_Start := Stop + 1;
      end loop;

      return True;
   exception
      when others =>
         return False;
   end Project_Relative_Path_Is_Safe;

   function Absolute_Path_Is_Under_Root
     (Root : String;
      Path : String) return Boolean
   is
      Root_Full : constant String := Ada.Directories.Full_Name (Root);
      Path_Text : constant String :=
        (if Ada.Directories.Exists (Path) then Ada.Directories.Full_Name (Path) else Path);
   begin
      if Root_Full'Length = 0 or else Path_Text'Length <= Root_Full'Length then
         return False;
      elsif Path_Text (Path_Text'First .. Path_Text'First + Root_Full'Length - 1) /= Root_Full then
         return False;
      else
         return Is_Path_Separator (Path_Text (Path_Text'First + Root_Full'Length));
      end if;
   exception
      when others =>
         return False;
   end Absolute_Path_Is_Under_Root;

   procedure Search_Known_Project_Files
     (State   : in out Project_Search_State;
      Project : Editor.Project.Project_State;
      Options : Project_Search_Options)
   is
      Q              : constant String := To_String (State.Query_Text);
      Scope          : constant String := To_String (State.Scope_Text);
      Include_Filter : constant String := To_String (State.Include_Filter_Text);
      Exclude_Filter : constant String := To_String (State.Exclude_Filter_Text);
      Project_Open   : constant Boolean := Editor.Project.Has_Project (Project);
      Project_Root   : constant String := Editor.Project.Root_Path (Project);
      Effective_Options : Project_Search_Options := Options;
      File_Total      : constant Natural := Editor.Project.Known_File_Count (Project);
      Scanned         : Natural := 0;
      Processed       : Natural := 0;
      Eligible        : Natural := 0;
      File_Count      : Natural := 0;
      Regex_Compile : Ada_Regexp.Compile_Result;
      Previous_Key    : Preserved_Result_Key;
      Ready           : Boolean := False;
   begin
      Begin_Search_Run
        (State             => State,
         Query             => Q,
         Project_Open      => Project_Open,
         File_Total        => File_Total,
         No_Project_Status => Project_Search_No_Project,
         No_Files_Status   => Project_Search_No_Files,
         Previous_Key      => Previous_Key,
         Effective_Options => Effective_Options,
         Regex_Compile     => Regex_Compile,
         Ready             => Ready);

      if not Ready then
         return;
      end if;

      for I in 1 .. File_Total loop
         declare
            Item : constant Editor.Project.Project_File_Entry :=
              Editor.Project.Known_File_At (Project, I);
            Rel_Path : constant String := To_String (Item.Relative_Path);
            Abs_Path : constant String := To_String (Item.Absolute_Path);
            Size : Natural := 0;
            Result : Editor.Files.File_Open_Result;
         begin
            if In_Scope (Rel_Path, Scope)
              and then Matches_Path_Filters (Rel_Path, Include_Filter, Exclude_Filter)
              and then Matches_Kind (Rel_Path, State.Kind_Filter)
            then
               if not Project_Relative_Path_Is_Safe (Rel_Path)
                 or else not Absolute_Path_Is_Under_Root (Project_Root, Abs_Path)
               then
                  State.Read_Error_Count := State.Read_Error_Count + 1;
               else
                  Eligible := Eligible + 1;
               if Processed < Effective_Options.Max_File_Count
                 and then not State.Truncated
               then
                  Processed := Processed + 1;
                  if Abs_Path'Length = 0 or else not Ada.Directories.Exists (Abs_Path) then
                     State.Skipped_Missing_Total := State.Skipped_Missing_Total + 1;
                  elsif Ada.Directories.Kind (Abs_Path) /= Ada.Directories.Ordinary_File then
                     State.Read_Error_Count := State.Read_Error_Count + 1;
                  else
                     begin
                        Size := Natural (Ada.Directories.Size (Abs_Path));
                     exception
                        when others =>
                           State.Read_Error_Count := State.Read_Error_Count + 1;
                           Size := Effective_Options.Max_File_Size_Bytes + 1;
                     end;

                     if Effective_Options.Max_File_Size_Bytes > 0
                       and then Size > Effective_Options.Max_File_Size_Bytes
                     then
                        State.Skipped_Large_Total := State.Skipped_Large_Total + 1;
                     else
                        Result := Editor.Files.Open_File (Abs_Path);
                        if Result.Status = Editor.Files.File_Open_Ok then
                           Scanned := Scanned + 1;
                           Search_Text
                             (State      => State,
                              Node       => Known_File_Summary (Item, I),
                              Text       => To_String (Result.Contents),
                              Needle     => Q,
                              Regex      => Regex_Compile.Expression,
                              Use_Regex  => State.Regex_Search,
                              Options    => Effective_Options,
                              File_Count => File_Count);
                           if State.Last_Status = Project_Search_Invalid_Regex then
                              return;
                           end if;
                        elsif Result.Status = Editor.Files.File_Open_Not_Found then
                           State.Skipped_Missing_Total := State.Skipped_Missing_Total + 1;
                        elsif Result.Status = Editor.Files.File_Open_Decode_Error then
                           State.Skipped_Binary_Total := State.Skipped_Binary_Total + 1;
                        else
                           State.Read_Error_Count := State.Read_Error_Count + 1;
                        end if;
                     end if;
                  end if;
               end if;
               end if;
            end if;
         exception
            when Ada.Directories.Name_Error =>
               if Processed <= Effective_Options.Max_File_Count
                 and then not State.Truncated
               then
                  State.Skipped_Missing_Total := State.Skipped_Missing_Total + 1;
               end if;
            when others =>
               if Processed <= Effective_Options.Max_File_Count
                 and then not State.Truncated
               then
                  State.Read_Error_Count := State.Read_Error_Count + 1;
               end if;
        end;
      end loop;

      Finalize_Search_Run
        (State             => State,
         Previous_Key      => Previous_Key,
         Effective_Options => Effective_Options,
         Eligible          => Eligible,
         Scanned           => Scanned,
         Processed         => Processed);
   end Search_Known_Project_Files;

   procedure Search_Known_Project_Files
     (State   : in out Project_Search_State;
      Tree    : Editor.File_Tree.File_Tree_State;
      Project : Editor.Project.Project_State;
      Options : Project_Search_Options)
   is
      pragma Unreferenced (Project);
   begin
      Search_Project
        (State   => State,
         Tree    => Tree,
         Reader  => Read_Search_File'Access,
         Options => Options);
   end Search_Known_Project_Files;

end Editor.Project_Search;
