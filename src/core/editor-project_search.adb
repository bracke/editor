with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Files;
with Editor.Project;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada_Regexp;
with Editor.Project_Search.Query_Controls;
with Editor.Project_Search.Navigation;
with Editor.Project_Search.Engine;
with Editor.Project_Search.Utilities; use Editor.Project_Search.Utilities;
with Editor.Project_Search.Replace_Preview;

package body Editor.Project_Search is

   use type Ada.Directories.File_Kind;
   use type Ada_Regexp.Regexp_Status;

   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Files.File_Open_Status;

   procedure Clear
     (State : in out Project_Search_State)
       renames Editor.Project_Search.Query_Controls.Clear;

   procedure Clear_Results_Preserve_Query
     (State : in out Project_Search_State)
       renames Editor.Project_Search.Query_Controls.Clear_Results_Preserve_Query;

   function Replacement_Text_Is_Valid
     (Text : String) return Boolean
   is
   begin
      return Editor.Project_Search.Utilities.Replacement_Text_Is_Valid (Text);
   end Replacement_Text_Is_Valid;

   function Find_Literal_Match_Column
     (Line           : String;
      Query          : String;
      Case_Sensitive : Boolean) return Natural
   is
   begin
      return Editor.Project_Search.Utilities.Find_Literal_Match_Column
        (Line, Query, Case_Sensitive);
   end Find_Literal_Match_Column;

   function Sanitize_Project_Search_Preview_Text
     (Line : String) return String
   is
   begin
      return Editor.Project_Search.Utilities.Sanitize_Project_Search_Preview_Text (Line);
   end Sanitize_Project_Search_Preview_Text;

   function Build_Project_Search_Line_Preview
     (Line         : String;
      Match_Column : Natural;
      Match_Length : Natural;
      Max_Length   : Natural := Max_Search_Result_Preview_Length) return String
   is
   begin
      return Editor.Project_Search.Utilities.Build_Project_Search_Line_Preview
        (Line, Match_Column, Match_Length, Max_Length);
   end Build_Project_Search_Line_Preview;

   procedure Build_Project_Search_Preview_Match_Range
     (Line                 : String;
      Match_Column         : Natural;
      Match_Length         : Natural;
      Preview              : String;
      Preview_Match_Start  : out Natural;
      Preview_Match_Length : out Natural)
   is
   begin
      Editor.Project_Search.Utilities.Build_Project_Search_Preview_Match_Range
        (Line, Match_Column, Match_Length, Preview, Preview_Match_Start, Preview_Match_Length);
   end Build_Project_Search_Preview_Match_Range;

   function Query
     (State : Project_Search_State) return String
       renames Editor.Project_Search.Query_Controls.Query;

   procedure Set_Query
     (State : in out Project_Search_State;
      Query : String)
       renames Editor.Project_Search.Query_Controls.Set_Query;

   function Has_Query
     (State : Project_Search_State) return Boolean
       renames Editor.Project_Search.Query_Controls.Has_Query;

   function Status
     (State : Project_Search_State) return Project_Search_Status
       renames Editor.Project_Search.Query_Controls.Status;

   procedure Set_Status
     (State  : in out Project_Search_State;
      Status : Project_Search_Status)
       renames Editor.Project_Search.Query_Controls.Set_Status;

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
      renames Editor.Project_Search.Replace_Preview.Set_Replace_Text;

   function Replace_Text
     (State : Project_Search_State) return String
      renames Editor.Project_Search.Replace_Preview.Replace_Text;

   function Replace_Text_Is_Valid
     (State : Project_Search_State) return Boolean
      renames Editor.Project_Search.Replace_Preview.Replace_Text_Is_Valid;

   function Replace_Mode_Active
     (State : Project_Search_State) return Boolean
      renames Editor.Project_Search.Replace_Preview.Replace_Mode_Active;

   procedure Set_Replace_Mode_Active
     (State  : in out Project_Search_State;
      Active : Boolean)
      renames Editor.Project_Search.Replace_Preview.Set_Replace_Mode_Active;

   procedure Clear_Replace_Preview
     (State : in out Project_Search_State)
      renames Editor.Project_Search.Replace_Preview.Clear_Replace_Preview;

   procedure Generate_Replace_Preview
     (State : in out Project_Search_State;
      Status : out Project_Replace_Preview_Status)
      renames Editor.Project_Search.Replace_Preview.Generate_Replace_Preview;

   function Replace_Preview_Status
     (State : Project_Search_State) return Project_Replace_Preview_Status
      renames Editor.Project_Search.Replace_Preview.Replace_Preview_Status;

   function Replace_Preview_Count
     (State : Project_Search_State) return Natural
      renames Editor.Project_Search.Replace_Preview.Replace_Preview_Count;

   function Included_Replacement_Count
     (State : Project_Search_State) return Natural
      renames Editor.Project_Search.Replace_Preview.Included_Replacement_Count;

   function Eligible_Replacement_Count
     (State : Project_Search_State) return Natural
      renames Editor.Project_Search.Replace_Preview.Eligible_Replacement_Count;

   function Eligible_Replacement_File_Count
     (State : Project_Search_State) return Natural
      renames Editor.Project_Search.Replace_Preview.Eligible_Replacement_File_Count;

   function Included_Replacement_File_Count
     (State : Project_Search_State) return Natural
      renames Editor.Project_Search.Replace_Preview.Included_Replacement_File_Count;

   function Replace_Preview_Row_At
     (State : Project_Search_State;
      Index : Positive) return Project_Replace_Preview_Row
      renames Editor.Project_Search.Replace_Preview.Replace_Preview_Row_At;

   function Selected_Replace_Preview_Index
     (State : Project_Search_State) return Natural
      renames Editor.Project_Search.Replace_Preview.Selected_Replace_Preview_Index;

   procedure Set_Selected_Replace_Preview_Index
     (State : in out Project_Search_State;
      Index : Natural)
      renames Editor.Project_Search.Replace_Preview.Set_Selected_Replace_Preview_Index;

   procedure Toggle_Selected_Replacement
     (State : in out Project_Search_State)
      renames Editor.Project_Search.Replace_Preview.Toggle_Selected_Replacement;

   procedure Include_Selected_Replacement
     (State : in out Project_Search_State)
      renames Editor.Project_Search.Replace_Preview.Include_Selected_Replacement;

   procedure Exclude_Selected_Replacement
     (State : in out Project_Search_State)
      renames Editor.Project_Search.Replace_Preview.Exclude_Selected_Replacement;

   procedure Include_File_Replacements
     (State : in out Project_Search_State;
      Relative_Path : String)
      renames Editor.Project_Search.Replace_Preview.Include_File_Replacements;

   procedure Exclude_File_Replacements
     (State : in out Project_Search_State;
      Relative_Path : String)
      renames Editor.Project_Search.Replace_Preview.Exclude_File_Replacements;

   procedure Include_All_Replacements
     (State : in out Project_Search_State)
      renames Editor.Project_Search.Replace_Preview.Include_All_Replacements;

   procedure Exclude_All_Replacements
     (State : in out Project_Search_State)
      renames Editor.Project_Search.Replace_Preview.Exclude_All_Replacements;

   function Replace_Preview_Is_Stale
     (State : Project_Search_State) return Boolean
      renames Editor.Project_Search.Replace_Preview.Replace_Preview_Is_Stale;

   procedure Mark_Replace_Preview_Stale
     (State : in out Project_Search_State)
      renames Editor.Project_Search.Replace_Preview.Mark_Replace_Preview_Stale;

   procedure Mark_Replace_Preview_Stale_For_File
     (State : in out Project_Search_State;
      Relative_Path : String)
      renames Editor.Project_Search.Replace_Preview.Mark_Replace_Preview_Stale_For_File;

   procedure Mark_Replace_Preview_Stale_For_Absolute_File
     (State : in out Project_Search_State;
      Absolute_Path : String)
      renames Editor.Project_Search.Replace_Preview.Mark_Replace_Preview_Stale_For_Absolute_File;

   function Included_Replacements_Overlap
     (State : Project_Search_State) return Boolean
      renames Editor.Project_Search.Replace_Preview.Included_Replacements_Overlap;

   function Apply_Included_Replacements_To_Text
     (State         : Project_Search_State;
      Relative_Path : String;
      Text          : String;
      Changed       : out Boolean;
      Replacement_Count : out Natural) return String
      renames Editor.Project_Search.Replace_Preview.Apply_Included_Replacements_To_Text;


   function Result_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result
       renames Editor.Project_Search.Navigation.Result_At;

   function Result_Key
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result_Key
       renames Editor.Project_Search.Navigation.Result_Key;

   function File_Group_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_File_Group
       renames Editor.Project_Search.Navigation.File_Group_At;

   function Selected_Result_Index
     (State : Project_Search_State) return Natural
       renames Editor.Project_Search.Navigation.Selected_Result_Index;

   procedure Set_Selected_Result_Index
     (State : in out Project_Search_State;
      Index : Natural)
       renames Editor.Project_Search.Navigation.Set_Selected_Result_Index;

   procedure Ensure_Valid_Selection
     (State : in out Project_Search_State)
       renames Editor.Project_Search.Navigation.Ensure_Valid_Selection;

   function Can_Move_Next
     (State : Project_Search_State) return Boolean
       renames Editor.Project_Search.Navigation.Can_Move_Next;

   function Can_Move_Previous
     (State : Project_Search_State) return Boolean
       renames Editor.Project_Search.Navigation.Can_Move_Previous;

   procedure Move_Selected_Result
     (State     : in out Project_Search_State;
      Direction : Project_Search_Result_Direction;
      Wrap      : Boolean := True)
       renames Editor.Project_Search.Navigation.Move_Selected_Result;

   procedure Select_First_Result
     (State : in out Project_Search_State)
       renames Editor.Project_Search.Navigation.Select_First_Result;

   procedure Select_Last_Result
     (State : in out Project_Search_State)
       renames Editor.Project_Search.Navigation.Select_Last_Result;

   function Select_First_Result_For_Path
     (State : in out Project_Search_State;
      Path  : String) return Boolean
       renames Editor.Project_Search.Navigation.Select_First_Result_For_Path;

   function Directory_Scope_Of_Path
     (Path : String) return String
       renames Editor.Project_Search.Navigation.Directory_Scope_Of_Path;

   function Selected_Result_Directory
     (State : Project_Search_State;
      Found : out Boolean) return String
       renames Editor.Project_Search.Navigation.Selected_Result_Directory;

   function Selected_Result
     (State : Project_Search_State;
      Found : out Boolean) return Project_Search_Result
       renames Editor.Project_Search.Navigation.Selected_Result;

   procedure Move_Selection_Down
     (State : in out Project_Search_State)
       renames Editor.Project_Search.Navigation.Move_Selection_Down;

   procedure Move_Selection_Up
     (State : in out Project_Search_State)
       renames Editor.Project_Search.Navigation.Move_Selection_Up;

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

   procedure Search_Project
     (State   : in out Project_Search_State;
      Tree    : Editor.File_Tree.File_Tree_State;
      Reader  : Read_File_Access;
      Options : Project_Search_Options)
       renames Editor.Project_Search.Engine.Search_Project;

   procedure Search_Known_Project_Files
     (State   : in out Project_Search_State;
      Project : Editor.Project.Project_State;
      Options : Project_Search_Options)
       renames Editor.Project_Search.Engine.Search_Known_Project_Files;

   procedure Search_Known_Project_Files
     (State   : in out Project_Search_State;
      Tree    : Editor.File_Tree.File_Tree_State;
      Project : Editor.Project.Project_State;
      Options : Project_Search_Options)
       renames Editor.Project_Search.Engine.Search_Known_Project_Files;

end Editor.Project_Search;
