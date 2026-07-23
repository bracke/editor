with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Project_Search.Replace_Preview;
with Editor.Project_Search.Utilities;

package body Editor.Project_Search.Query_Controls is

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
      Editor.Project_Search.Utilities.Reset_Results
        (State, Project_Search_Idle);
   end Clear;

   procedure Clear_Results_Preserve_Query
     (State : in out Project_Search_State)
   is
   begin
      Editor.Project_Search.Utilities.Reset_Results
        (State, Project_Search_Idle);
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
      if Natural (State.Results.Length) > 0
        or else Length (State.Query_Text) > 0
        or else Length (State.Last_Query_Text) > 0
        or else State.Last_Status /= Project_Search_Idle
        or else Natural (State.Replace_Rows.Length) > 0
      then
         State.Stale := True;
         Editor.Project_Search.Replace_Preview.Mark_Replace_Preview_Stale (State);
      end if;
   end Mark_Stale;

   procedure Mark_Stale_Unconditionally
     (State : in out Project_Search_State)
   is
   begin
      State.Stale := True;
      State.Replace_Stale := True;
      State.Replace_Status_Value := Project_Replace_Search_Stale;
      Editor.Project_Search.Replace_Preview.Mark_Replace_Preview_Stale (State);
   end Mark_Stale_Unconditionally;

   procedure Clear_Stale
     (State : in out Project_Search_State)
   is
   begin
      State.Stale := False;
   end Clear_Stale;

end Editor.Project_Search.Query_Controls;
