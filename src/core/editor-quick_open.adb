with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Containers; use Ada.Containers;
with Editor.Input_Field;
with Editor.Buffer_Types;

package body Editor.Quick_Open is
   use type Editor.File_Tree.File_Tree_Scan_Status;
   use type Editor.File_Tree.File_Tree_Node_Id;

   function Lower (Text : String) return String is
      Result : String (Text'Range);
   begin
      for I in Text'Range loop
         Result (I) := Ada.Characters.Handling.To_Lower (Text (I));
      end loop;
      return Result;
   end Lower;

   function Trim_Query (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim_Query;

   function Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image;

   function Normalize_For_Compare (Text : String) return String is
      Result : String (Text'Range);
   begin
      for I in Text'Range loop
         if Text (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Ada.Characters.Handling.To_Lower (Text (I));
         end if;
      end loop;
      return Result;
   end Normalize_For_Compare;

   function Normalize_Display_Path (Text : String) return String is
      Result : String (Text'Range);
   begin
      for I in Text'Range loop
         if Text (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Text (I);
         end if;
      end loop;
      return Result;
   end Normalize_Display_Path;

   function Base_Name (Path : String) return String is
      Last_Sep : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = '\' then
            Last_Sep := I;
         end if;
      end loop;

      if Last_Sep = 0 then
         return Path;
      elsif Last_Sep >= Path'Last then
         return "";
      else
         return Path (Last_Sep + 1 .. Path'Last);
      end if;
   end Base_Name;

   function Starts_With (Text, Prefix : String) return Boolean is
   begin
      return Prefix'Length <= Text'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Contains (Text, Part : String) return Boolean is
   begin
      if Part'Length = 0 then
         return True;
      elsif Part'Length > Text'Length then
         return False;
      end if;

      for I in Text'First .. Text'Last - Part'Length + 1 loop
         if Text (I .. I + Part'Length - 1) = Part then
            return True;
         end if;
      end loop;
      return False;
   end Contains;


   function Ends_With (Text, Suffix : String) return Boolean is
   begin
      return Suffix'Length <= Text'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Extension_Of (Path : String) return String is
      Name : constant String := Normalize_For_Compare (Base_Name (Path));
   begin
      for I in reverse Name'Range loop
         if Name (I) = '.' then
            return Name (I .. Name'Last);
         end if;
      end loop;
      return "";
   end Extension_Of;

   function Is_Ada_File (Path : String) return Boolean is
      Ext : constant String := Extension_Of (Path);
   begin
      return Ext = ".adb" or else Ext = ".ads";
   end Is_Ada_File;

   function Is_Doc_File (Path : String) return Boolean is
      Ext : constant String := Extension_Of (Path);
   begin
      return Ext = ".md" or else Ext = ".txt" or else Ext = ".rst" or else Ext = ".adoc";
   end Is_Doc_File;

   function Is_Test_File (Path : String) return Boolean is
      P : constant String := Normalize_For_Compare (Normalize_Display_Path (Path));
      B : constant String := Normalize_For_Compare (Base_Name (Path));
      Ext : constant String := Extension_Of (Path);
      Stem_Last : constant Natural := (if Ext'Length > 0 then B'Last - Ext'Length else B'Last);
      Stem : constant String := (if Stem_Last >= B'First then B (B'First .. Stem_Last) else "");
   begin
      return Contains (P, "/test/")
        or else Contains (P, "/tests/")
        or else Starts_With (P, "test/")
        or else Starts_With (P, "tests/")
        or else Starts_With (B, "test_")
        or else Ends_With (Stem, "_test");
   end Is_Test_File;

   function Matches_File_Kind
     (Path   : String;
      Filter : Quick_Open_File_Kind_Filter) return Boolean
   is
   begin
      case Filter is
         when All_Files =>
            return True;
         when Ada_Files =>
            return Is_Ada_File (Path);
         when Test_Files =>
            return Is_Test_File (Path);
         when Doc_Files =>
            return Is_Doc_File (Path);
         when Other_Files =>
            return not Is_Test_File (Path)
              and then not Is_Ada_File (Path)
              and then not Is_Doc_File (Path);
      end case;
   end Matches_File_Kind;

   function In_Path_Scope (Path, Scope : String) return Boolean is
      P : constant String := Normalize_For_Compare (Normalize_Display_Path (Path));
      S : constant String := Normalize_For_Compare (Scope);
   begin
      return S'Length = 0 or else Starts_With (P, S);
   end In_Path_Scope;

   function Path_Depth (Path : String) return Natural is
      P : constant String := Normalize_Display_Path (Path);
      Count : Natural := 0;
   begin
      for Ch of P loop
         if Ch = '/' then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Path_Depth;

   function Is_Term_Boundary (Ch : Character) return Boolean is
   begin
      return Ch = '/' or else Ch = '-' or else Ch = '_' or else Ch = '.' or else Ch = ' ';
   end Is_Term_Boundary;

   function Has_Whitespace (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Ch = ' ' or else Ch = Character'Val (9) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Whitespace;

   function Ordered_Characters_Match
     (Pattern : String;
      Text    : String) return Boolean
   is
      P : constant String := Normalize_For_Compare (Trim_Query (Pattern));
      T : constant String := Normalize_For_Compare (Text);
      Pos : Natural := T'First;
      Found : Boolean;
   begin
      if P'Length = 0 then
         return True;
      elsif T'Length = 0 then
         return False;
      end if;

      for Ch of P loop
         if Ch = ' ' or else Ch = '/' then
            null;
         else
            Found := False;
            while Pos <= T'Last loop
               if T (Pos) = Ch then
                  Found := True;
                  Pos := Pos + 1;
                  exit;
               end if;
               Pos := Pos + 1;
            end loop;
            if not Found then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Ordered_Characters_Match;

   function Ordered_Basename_Fuzzy_Match
     (Pattern : String;
      Text    : String) return Boolean
   is
      P : constant String := Normalize_For_Compare (Trim_Query (Pattern));
      T : constant String := Normalize_For_Compare (Text);
   begin
      return P'Length > 0
        and then T'Length > 0
        and then T (T'First) = P (P'First)
        and then Ordered_Characters_Match (P, T);
   end Ordered_Basename_Fuzzy_Match;

   function Ordered_Terms_Match
     (Query       : String;
      Path        : String;
      Prefix_Only : Boolean) return Boolean
   is
      Q : constant String := Normalize_For_Compare (Trim_Query (Query));
      P : constant String := Normalize_For_Compare (Normalize_Display_Path (Path));
      Term : Unbounded_String := Null_Unbounded_String;
      Search_From : Natural := P'First;

      function Find_Term (Term_Text : String) return Boolean is
      begin
         if Term_Text'Length = 0 then
            return True;
         end if;

         if P'Length = 0 or else Search_From > P'Last then
            return False;
         end if;

         for I in Search_From .. P'Last loop
            if I + Term_Text'Length - 1 <= P'Last
              and then P (I .. I + Term_Text'Length - 1) = Term_Text
              and then ((not Prefix_Only)
                        or else I = P'First
                        or else Is_Term_Boundary (P (I - 1)))
            then
               Search_From := I + Term_Text'Length;
               return True;
            end if;
         end loop;
         return False;
      end Find_Term;

      procedure Flush_Term (Ok : in out Boolean) is
      begin
         if Length (Term) > 0 then
            Ok := Ok and then Find_Term (To_String (Term));
            Term := Null_Unbounded_String;
         end if;
      end Flush_Term;

      Ok : Boolean := True;
   begin
      if Q'Length = 0 then
         return True;
      end if;

      for Ch of Q loop
         if Ch = ' ' or else Ch = Character'Val (9) then
            Flush_Term (Ok);
            if not Ok then
               return False;
            end if;
         elsif Ch = '.' then
            --  Directory traversal terms are never interpreted as a way to
            --  escape the already project-relative candidate set.  Treat dots
            --  as ordinary filename separators for matching only.
            Append (Term, Ch);
         else
            Append (Term, Ch);
         end if;
      end loop;
      Flush_Term (Ok);
      return Ok;
   end Ordered_Terms_Match;

   function Segment_Contains
     (Path : String;
      Term : String;
      Prefix_Only : Boolean) return Boolean
   is
      P : constant String := Normalize_For_Compare (Normalize_Display_Path (Path));
      T : constant String := Normalize_For_Compare (Term);
      Segment_Start : Natural := P'First;
   begin
      if T'Length = 0 then
         return True;
      end if;

      for I in P'Range loop
         if P (I) = '/' then
            if I > Segment_Start then
               declare
                  Segment : constant String := P (Segment_Start .. I - 1);
               begin
                  if (Prefix_Only and then Starts_With (Segment, T))
                    or else ((not Prefix_Only) and then Contains (Segment, T))
                  then
                     return True;
                  end if;
               end;
            end if;
            Segment_Start := I + 1;
         end if;
      end loop;

      if Segment_Start <= P'Last then
         declare
            Segment : constant String := P (Segment_Start .. P'Last);
         begin
            return (Prefix_Only and then Starts_With (Segment, T))
              or else ((not Prefix_Only) and then Contains (Segment, T));
         end;
      end if;
      return False;
   end Segment_Contains;


   function Query_Has_Path_Traversal_Term (Query : String) return Boolean is
      Q : constant String := Normalize_For_Compare
        (Ada.Strings.Fixed.Trim (Query, Ada.Strings.Both));
      Term : Unbounded_String := Null_Unbounded_String;

      function Bad_Term return Boolean is
         T : constant String := To_String (Term);
      begin
         return T = "." or else T = "..";
      end Bad_Term;
   begin
      for Ch of Q loop
         if Ch = '/' or else Ch = ' ' or else Ch = Character'Val (9) then
            if Bad_Term then
               return True;
            end if;
            Term := Null_Unbounded_String;
         else
            Append (Term, Ch);
         end if;
      end loop;

      return Bad_Term;
   end Query_Has_Path_Traversal_Term;


   function Query_Has_Project_Relative_Violation (Query : String) return Boolean is
      Q : constant String := Normalize_For_Compare
        (Ada.Strings.Fixed.Trim (Query, Ada.Strings.Both));
      Term : Unbounded_String := Null_Unbounded_String;

      function Bad_Term return Boolean is
         T : constant String := To_String (Term);
      begin
         return T'Length > 0
           and then (T (T'First) = '/'
                     or else T (T'First) = '\'
                     or else (T'Length >= 2
                              and then T (T'First + 1) = ':'));
      end Bad_Term;
   begin
      --  Quick Open queries are matched only against normalized
      --  project-relative paths.  Absolute-looking and drive-qualified
      --  query text must therefore produce no file rows instead of being
      --  interpreted as a weak path-substring or fuzzy query.  Apply the
      --  same project-relative constraint to every whitespace-separated
      --  query term, so "src /main" or "src C:/main" cannot be
      --  rescued by ordered path-term matching.
      if Q'Length = 0 then
         return False;
      end if;

      for Ch of Q loop
         if Ch = ' ' or else Ch = Character'Val (9) then
            if Bad_Term then
               return True;
            end if;
            Term := Null_Unbounded_String;
         else
            Append (Term, Ch);
         end if;
      end loop;

      return Bad_Term;
   end Query_Has_Project_Relative_Violation;


   function Is_Project_Relative_File_Path (Path : String) return Boolean is
      Normalized : constant String := Normalize_Display_Path
        (Ada.Strings.Fixed.Trim (Path, Ada.Strings.Both));
      Segment : Unbounded_String := Null_Unbounded_String;

      procedure Check_Segment (Bad : in out Boolean) is
         S : constant String := To_String (Segment);
      begin
         if S'Length = 0 or else S = "." or else S = ".." then
            Bad := True;
         end if;
         Segment := Null_Unbounded_String;
      end Check_Segment;

      Bad : Boolean := False;
   begin
      if Normalized'Length = 0
        or else Normalized (Normalized'First) = '/'
        or else Normalized (Normalized'First) = '\'
        or else (Normalized'Length >= 2
                 and then Normalized (Normalized'First + 1) = ':')
      then
         return False;
      end if;

      for Ch of Normalized loop
         if Ch = '/' then
            Check_Segment (Bad);
            if Bad then
               return False;
            end if;
         else
            Append (Segment, Ch);
         end if;
      end loop;

      Check_Segment (Bad);
      return not Bad;
   end Is_Project_Relative_File_Path;

   function Bucket_Priority (Bucket : Quick_Open_Match_Bucket) return Natural is
   begin
      case Bucket is
         when Basename_Exact             => return 1;
         when Basename_Prefix            => return 2;
         when Basename_Substring         => return 3;
         when Path_Segment_Prefix        => return 4;
         when Path_Prefix                => return 4;
         when Path_Segment_Substring     => return 5;
         when Path_Substring             => return 5;
         when Basename_Fuzzy             => return 6;
         when Path_Fuzzy                 => return 7;
         when No_Match                   => return 8;
      end case;
   end Bucket_Priority;

   function Quick_Open_Match_Bucket_For
     (Query : String;
      Path  : String) return Quick_Open_Match_Bucket
   is
      Q : constant String := Normalize_For_Compare (Trim_Query (Query));
      P : constant String := Normalize_For_Compare (Normalize_Display_Path (Path));
      B : constant String := Normalize_For_Compare (Base_Name (Path));
   begin
      if Q'Length = 0 then
         return No_Match;
      elsif Query_Has_Path_Traversal_Term (Q)
        or else Query_Has_Project_Relative_Violation (Q)
      then
         return No_Match;
      elsif B = Q then
         return Basename_Exact;
      elsif Starts_With (B, Q) then
         return Basename_Prefix;
      elsif Contains (B, Q) then
         return Basename_Substring;
      elsif Has_Whitespace (Q) and then Ordered_Terms_Match (Q, P, True) then
         return Path_Segment_Prefix;
      elsif Starts_With (P, Q) then
         return Path_Prefix;
      elsif Segment_Contains (P, Q, True) then
         return Path_Segment_Prefix;
      elsif Has_Whitespace (Q) and then Ordered_Terms_Match (Q, P, False) then
         return Path_Segment_Substring;
      elsif Segment_Contains (P, Q, False) then
         return Path_Segment_Substring;
      elsif Contains (P, Q) then
         return Path_Substring;
      elsif Ordered_Basename_Fuzzy_Match (Q, B) then
         return Basename_Fuzzy;
      elsif Ordered_Characters_Match (Q, P)
        and then not Ordered_Characters_Match (Q, B)
      then
         return Path_Fuzzy;
      else
         return No_Match;
      end if;
   end Quick_Open_Match_Bucket_For;

   function Before (L, R : Quick_Open_Result) return Boolean is
      LP : constant String := Normalize_For_Compare (To_String (L.Display_Path));
      RP : constant String := Normalize_For_Compare (To_String (R.Display_Path));
      LO : constant String := To_String (L.Display_Path);
      RO : constant String := To_String (R.Display_Path);
      LD : constant Natural := Path_Depth (LO);
      RD : constant Natural := Path_Depth (RO);
   begin
      if Bucket_Priority (L.Match_Bucket) /= Bucket_Priority (R.Match_Bucket) then
         return Bucket_Priority (L.Match_Bucket) < Bucket_Priority (R.Match_Bucket);
      elsif L.Match_Bucket /= Path_Substring and then LD /= RD then
         return LD < RD;
      elsif L.Match_Bucket /= Path_Substring and then LO'Length /= RO'Length then
         return LO'Length < RO'Length;
      elsif LP /= RP then
         return LP < RP;
      else
         return LO < RO;
      end if;
   end Before;

   procedure Sort_Results (Results : in out Result_Vectors.Vector) is
      Tmp : Quick_Open_Result;
   begin
      if Results.Length < 2 then
         return;
      end if;

      for I in Results.First_Index + 1 .. Results.Last_Index loop
         Tmp := Results (I);
         declare
            J : Natural := I;
         begin
            while J > Results.First_Index and then Before (Tmp, Results (J - 1)) loop
               Results.Replace_Element (J, Results (J - 1));
               J := J - 1;
            end loop;
            Results.Replace_Element (J, Tmp);
         end;
      end loop;
   end Sort_Results;

   procedure Clamp_Window (State : in out Quick_Open_State) is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
      else
         if State.Selected_Index = 0 or else State.Selected_Index > Count then
            State.Selected_Index := 1;
         end if;
         if State.Top_Index = 0 or else State.Top_Index > State.Selected_Index then
            State.Top_Index := State.Selected_Index;
         elsif State.Selected_Index >= State.Top_Index + State.Visible_Window then
            State.Top_Index := State.Selected_Index - State.Visible_Window + 1;
         end if;
      end if;
   end Clamp_Window;

   procedure Clear (State : in out Quick_Open_State) is
   begin
      State.Opened := False;
      State.Visible_Window := 12;
      Editor.Input_Field.Clear (State.Query_Field);
      State.Kind_Filter := All_Files;
      State.Scope := Null_Unbounded_String;
      State.Results.Clear;
      State.Results_Stale := False;
      State.Project_Available := False;
      State.Known_Total := 0;
      State.Filtered_Total := 0;
      State.Selected_Index := 0;
      State.Top_Index := 1;
      State.Priority := Path;
   end Clear;

   procedure Mark_Stale
     (State : in out Quick_Open_State) is
   begin
      --  Phase 572 completeness: File Tree filesystem mutations invalidate
      --  Quick Open's retained candidate/result projection.  Keep the prompt
      --  query, filters, scope, and open/closed state as UI state, but clear
      --  stale rows so accepting an old result cannot target a moved or
      --  deleted file before the owning Quick Open command recomputes.
      State.Results.Clear;
      State.Results_Stale := True;
      --  Phase 572 completeness pass 34: known/filtered counts are part of
      --  the retained candidate projection.  A File Tree mutation must not
      --  leave stale candidate totals visible to snapshots while result rows
      --  have been cleared; the next explicit Quick Open recompute owns
      --  rebuilding both rows and counts.
      State.Known_Total := 0;
      State.Filtered_Total := 0;
      State.Selected_Index := 0;
      State.Top_Index := 1;
   end Mark_Stale;

   function Results_Are_Stale
     (State : Quick_Open_State) return Boolean is
   begin
      return State.Results_Stale;
   end Results_Are_Stale;

   procedure Open (State : in out Quick_Open_State) is
   begin
      State.Opened := True;
      State.Visible_Window := 12;
      Editor.Input_Field.Clear (State.Query_Field);
      State.Kind_Filter := All_Files;
      State.Scope := Null_Unbounded_String;
      State.Results.Clear;
      State.Results_Stale := False;
      State.Project_Available := False;
      State.Known_Total := 0;
      State.Filtered_Total := 0;
      State.Selected_Index := 0;
      State.Top_Index := 1;
      State.Priority := Path;
   end Open;

   procedure Close (State : in out Quick_Open_State) is
   begin
      State.Opened := False;
   end Close;

   function Is_Open (State : Quick_Open_State) return Boolean is
   begin
      return State.Opened;
   end Is_Open;

   function Query_Text (State : Quick_Open_State) return String is
   begin
      return Editor.Input_Field.Text (State.Query_Field);
   end Query_Text;

   procedure Set_Query_Text (State : in out Quick_Open_State; Text : String) is
   begin
      Editor.Input_Field.Set_Text (State.Query_Field, Text);
   end Set_Query_Text;


   function File_Kind_Filter
     (State : Quick_Open_State) return Quick_Open_File_Kind_Filter is
   begin
      return State.Kind_Filter;
   end File_Kind_Filter;

   function File_Kind_Filter_Name
     (Filter : Quick_Open_File_Kind_Filter) return String is
   begin
      case Filter is
         when All_Files  => return "All";
         when Ada_Files  => return "Ada";
         when Test_Files => return "Tests";
         when Doc_Files  => return "Docs";
         when Other_Files => return "Other";
      end case;
   end File_Kind_Filter_Name;

   procedure Cycle_File_Kind_Next
     (State : in out Quick_Open_State) is
   begin
      case State.Kind_Filter is
         when All_Files  => State.Kind_Filter := Ada_Files;
         when Ada_Files  => State.Kind_Filter := Test_Files;
         when Test_Files => State.Kind_Filter := Doc_Files;
         when Doc_Files  => State.Kind_Filter := Other_Files;
         when Other_Files => State.Kind_Filter := All_Files;
      end case;
   end Cycle_File_Kind_Next;

   procedure Cycle_File_Kind_Previous
     (State : in out Quick_Open_State) is
   begin
      case State.Kind_Filter is
         when All_Files  => State.Kind_Filter := Other_Files;
         when Ada_Files  => State.Kind_Filter := All_Files;
         when Test_Files => State.Kind_Filter := Ada_Files;
         when Doc_Files  => State.Kind_Filter := Test_Files;
         when Other_Files => State.Kind_Filter := Doc_Files;
      end case;
   end Cycle_File_Kind_Previous;

   procedure Clear_File_Kind_Filter
     (State : in out Quick_Open_State) is
   begin
      State.Kind_Filter := All_Files;
   end Clear_File_Kind_Filter;

   function Path_Scope
     (State : Quick_Open_State) return String is
   begin
      return To_String (State.Scope);
   end Path_Scope;


   function Create_Target_From_Query
     (State : Quick_Open_State) return Quick_Open_Create_Target_Result
   is
      Query : constant String := Trim_Query (Query_Text (State));
      Scope : constant String := To_String (State.Scope);
      Normalized_Query : Unbounded_String := Null_Unbounded_String;
      Target : Unbounded_String := Null_Unbounded_String;
      Segment : Unbounded_String := Null_Unbounded_String;
      Previous_Was_Slash : Boolean := False;
      Result : Quick_Open_Create_Target_Result;

      function Invalid return Quick_Open_Create_Target_Result is
      begin
         return (Status => Quick_Open_Create_Target_Invalid_Path,
                 Project_Relative_Path => Null_Unbounded_String);
      end Invalid;

      procedure Check_Segment (Bad : in out Boolean) is
         S : constant String := To_String (Segment);
      begin
         if S = ".." or else S = "." then
            Bad := True;
         end if;
         Segment := Null_Unbounded_String;
      end Check_Segment;
   begin
      if Query'Length = 0 then
         return (Status => Quick_Open_Create_Target_No_Query,
                 Project_Relative_Path => Null_Unbounded_String);
      end if;

      if Query (Query'First) = '/' or else Query (Query'First) = '\' then
         return Invalid;
      end if;

      if Query'Length >= 2 and then Query (Query'First + 1) = ':' then
         return Invalid;
      end if;

      declare
         Bad : Boolean := False;
      begin
         for Ch of Query loop
            if Ch = '/' or else Ch = '\' then
               if Previous_Was_Slash then
                  null;
               elsif Length (Segment) = 0 then
                  Bad := True;
               else
                  Check_Segment (Bad);
                  Append (Normalized_Query, '/');
                  Previous_Was_Slash := True;
               end if;
            else
               Append (Segment, Ch);
               Append (Normalized_Query, Ch);
               Previous_Was_Slash := False;
            end if;
         end loop;

         if Previous_Was_Slash or else Length (Segment) = 0 then
            Bad := True;
         else
            Check_Segment (Bad);
         end if;

         if Bad or else Length (Normalized_Query) = 0 then
            return Invalid;
         end if;
      end;

      if Scope'Length > 0 then
         Target := To_Unbounded_String (Scope);
         Append (Target, To_String (Normalized_Query));
      else
         Target := Normalized_Query;
      end if;

      --  Re-validate the complete target, not only the query fragment.
      --  Scope normally comes from normalized Quick Open helpers, but command
      --  execution must still be safe if a future route or test installs an
      --  invalid transient scope directly.
      declare
         Target_Text : constant String := To_String (Target);
         Target_Segment : Unbounded_String := Null_Unbounded_String;
         Bad_Target : Boolean := False;
      begin
         if Target_Text'Length = 0
           or else Target_Text (Target_Text'First) = '/'
           or else Target_Text (Target_Text'First) = '\'
           or else (Target_Text'Length >= 2
                    and then Target_Text (Target_Text'First + 1) = ':')
         then
            return Invalid;
         end if;

         for Ch of Target_Text loop
            if Ch = '/' or else Ch = '\' then
               declare
                  Part : constant String := To_String (Target_Segment);
               begin
                  if Part'Length = 0 or else Part = "." or else Part = ".." then
                     Bad_Target := True;
                  end if;
               end;
               Target_Segment := Null_Unbounded_String;
            else
               Append (Target_Segment, Ch);
            end if;
         end loop;

         declare
            Part : constant String := To_String (Target_Segment);
         begin
            if Part'Length = 0 or else Part = "." or else Part = ".." then
               Bad_Target := True;
            end if;
         end;

         if Bad_Target then
            return Invalid;
         end if;
      end;

      Result.Status := Quick_Open_Create_Target_Ok;
      Result.Project_Relative_Path := Target;
      return Result;
   end Create_Target_From_Query;

   function Priority_Mode
     (State : Quick_Open_State) return Quick_Open_Priority_Mode is
   begin
      return State.Priority;
   end Priority_Mode;

   procedure Toggle_Priority_Mode
     (State : in out Quick_Open_State) is
   begin
      case State.Priority is
         when Path =>
            State.Priority := Open_Recent;
         when Open_Recent =>
            State.Priority := Path;
      end case;
   end Toggle_Priority_Mode;

   procedure Clear_Priority_Mode
     (State : in out Quick_Open_State) is
   begin
      State.Priority := Path;
   end Clear_Priority_Mode;

   function Normalize_Quick_Open_Scope
     (Text : String) return String
   is
      Raw : constant String := Normalize_Display_Path
        (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
      First : Natural := Raw'First;
      Last  : Natural := Raw'Last;
      Result : Unbounded_String := Null_Unbounded_String;
      Segment : Unbounded_String := Null_Unbounded_String;

      procedure Flush_Segment (Bad : in out Boolean) is
         S : constant String := To_String (Segment);
      begin
         if S'Length = 0 then
            null;
         elsif S = "." or else S = ".." then
            Bad := True;
         else
            if Length (Result) > 0 then
               Append (Result, '/');
            end if;
            Append (Result, S);
         end if;
         Segment := Null_Unbounded_String;
      end Flush_Segment;

      Bad : Boolean := False;
   begin
      while First <= Last and then Raw (First) = '/' loop
         First := First + 1;
      end loop;
      while Last >= First and then Raw (Last) = '/' loop
         Last := Last - 1;
      end loop;
      if First > Last then
         return "";
      end if;

      if Last - First + 1 >= 2 and then Raw (First + 1) = ':' then
         return "";
      end if;

      for I in First .. Last loop
         if Raw (I) = '/' then
            Flush_Segment (Bad);
            if Bad then
               return "";
            end if;
         else
            Append (Segment, Raw (I));
         end if;
      end loop;

      Flush_Segment (Bad);
      if Bad or else Length (Result) = 0 then
         return "";
      end if;

      return To_String (Result) & "/";
   end Normalize_Quick_Open_Scope;

   procedure Set_Path_Scope
     (State : in out Quick_Open_State;
      Scope : String) is
   begin
      State.Scope := To_Unbounded_String (Normalize_Quick_Open_Scope (Scope));
   end Set_Path_Scope;

   procedure Clear_Path_Scope
     (State : in out Quick_Open_State) is
   begin
      State.Scope := Null_Unbounded_String;
   end Clear_Path_Scope;

   function Directory_Scope_Of_Path
     (Path : String) return String is
      Normalized : constant String := Normalize_Display_Path (Path);
      Last_Sep : Natural := 0;
   begin
      for I in Normalized'Range loop
         if Normalized (I) = '/' then
            Last_Sep := I;
         end if;
      end loop;

      if Last_Sep = 0 then
         return "";
      else
         return Normalize_Quick_Open_Scope (Normalized (Normalized'First .. Last_Sep));
      end if;
   end Directory_Scope_Of_Path;

   procedure Select_Path
     (State : in out Quick_Open_State;
      Path  : String;
      Found : out Boolean)
   is
      Wanted : constant String := Normalize_Display_Path (Path);
   begin
      Found := False;
      State.Selected_Index := 0;

      if State.Results.Length = 0 then
         State.Top_Index := 1;
         return;
      end if;

      for I in State.Results.First_Index .. State.Results.Last_Index loop
         if To_String (State.Results (I).Display_Path) = Wanted then
            State.Selected_Index := I + 1;
            Found := True;
            exit;
         end if;
      end loop;

      if Found then
         Clamp_Window (State);
      else
         State.Top_Index := 1;
      end if;
   end Select_Path;

   function Selected_Directory_Scope
     (State : Quick_Open_State;
      Found : out Boolean) return String
   is
      Result : constant Quick_Open_Result := Selected_Result (State, Found);
   begin
      if not Found then
         return "";
      end if;
      return Directory_Scope_Of_Path (To_String (Result.Display_Path));
   end Selected_Directory_Scope;

   function Parent_Scope
     (Scope : String;
      Found : out Boolean) return String
   is
      Normalized : constant String := Normalize_Quick_Open_Scope (Scope);
      Last : Natural := Normalized'Last;
      Parent_End : Natural := 0;
   begin
      if Normalized'Length = 0 then
         Found := False;
         return "";
      end if;

      if Normalized (Last) = '/' then
         Last := Last - 1;
      end if;

      for I in reverse Normalized'First .. Last loop
         if Normalized (I) = '/' then
            Parent_End := I;
            exit;
         end if;
      end loop;

      Found := True;
      if Parent_End = 0 then
         return "";
      else
         return Normalize_Quick_Open_Scope (Normalized (Normalized'First .. Parent_End));
      end if;
   end Parent_Scope;

   procedure Set_Path_Scope_From_Selected
     (State : in out Quick_Open_State;
      Found : out Boolean)
   is
      Scope : constant String := Selected_Directory_Scope (State, Found);
   begin
      if Found then
         State.Scope := To_Unbounded_String (Scope);
      end if;
   end Set_Path_Scope_From_Selected;

   procedure Move_Path_Scope_To_Parent
     (State : in out Quick_Open_State;
      Found : out Boolean)
   is
      Scope : constant String := Parent_Scope (To_String (State.Scope), Found);
   begin
      if Found then
         State.Scope := To_Unbounded_String (Scope);
      end if;
   end Move_Path_Scope_To_Parent;

   function Known_Count
     (State : Quick_Open_State) return Natural is
   begin
      return State.Known_Total;
   end Known_Count;

   function Visible_Count
     (State : Quick_Open_State) return Natural is
   begin
      return Natural (State.Results.Length);
   end Visible_Count;

   function Total_Filtered_Count
     (State : Quick_Open_State) return Natural is
   begin
      return State.Filtered_Total;
   end Total_Filtered_Count;

   procedure Insert_Text (State : in out Quick_Open_State; Text : String) is
   begin
      Editor.Input_Field.Insert_Text (State.Query_Field, Text);
   end Insert_Text;

   procedure Backspace (State : in out Quick_Open_State) is
   begin
      Editor.Input_Field.Backspace (State.Query_Field);
   end Backspace;

   procedure Delete_Forward (State : in out Quick_Open_State) is
   begin
      Editor.Input_Field.Delete_Forward (State.Query_Field);
   end Delete_Forward;

   procedure Move_Cursor_Left (State : in out Quick_Open_State) is
   begin
      Editor.Input_Field.Move_Cursor_Left (State.Query_Field);
   end Move_Cursor_Left;

   procedure Move_Cursor_Right (State : in out Quick_Open_State) is
   begin
      Editor.Input_Field.Move_Cursor_Right (State.Query_Field);
   end Move_Cursor_Right;

   procedure Move_Cursor_Start (State : in out Quick_Open_State) is
   begin
      Editor.Input_Field.Move_Cursor_Start (State.Query_Field);
   end Move_Cursor_Start;

   procedure Move_Cursor_End (State : in out Quick_Open_State) is
   begin
      Editor.Input_Field.Move_Cursor_End (State.Query_Field);
   end Move_Cursor_End;

   procedure Select_All (State : in out Quick_Open_State) is
   begin
      Editor.Input_Field.Select_All (State.Query_Field);
   end Select_All;

   procedure Set_Cursor_From_Visible_Column
     (State           : in out Quick_Open_State;
      Visible_Column  : Natural;
      Visible_Columns : Natural) is
   begin
      Editor.Input_Field.Set_Cursor_From_Visible_Column
        (State.Query_Field, Visible_Column, Visible_Columns);
   end Set_Cursor_From_Visible_Column;

   procedure Move_Selection_Down (State : in out Quick_Open_State) is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
      elsif State.Selected_Index = 0 or else State.Selected_Index >= Count then
         State.Selected_Index := 1;
         State.Top_Index := 1;
      else
         State.Selected_Index := State.Selected_Index + 1;
      end if;

      if State.Selected_Index >= State.Top_Index + State.Visible_Window then
         State.Top_Index := State.Selected_Index - State.Visible_Window + 1;
      elsif State.Selected_Index < State.Top_Index then
         State.Top_Index := State.Selected_Index;
      end if;
   end Move_Selection_Down;

   procedure Move_Selection_Up (State : in out Quick_Open_State) is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      if Count = 0 then
         State.Selected_Index := 0;
         State.Top_Index := 1;
      elsif State.Selected_Index <= 1 then
         State.Selected_Index := Count;
      else
         State.Selected_Index := State.Selected_Index - 1;
      end if;

      if State.Selected_Index < State.Top_Index then
         State.Top_Index := State.Selected_Index;
      elsif State.Selected_Index >= State.Top_Index + State.Visible_Window then
         State.Top_Index := State.Selected_Index - State.Visible_Window + 1;
      end if;
   end Move_Selection_Up;

   procedure Append_Literal_Project_Result
     (State   : in out Quick_Open_State;
      Project : Editor.Project.Project_State;
      Index   : Positive;
      Query   : String);

   procedure Preserve_Or_First_Selection
     (State         : in out Quick_Open_State;
      Previous_Path : String);

   procedure Recompute_Results
     (State  : in out Quick_Open_State;
      Tree   : Editor.File_Tree.File_Tree_State;
      Config : Quick_Open_Config)
   is
      Query         : constant String := Editor.Input_Field.Text (State.Query_Field);
      Previous_Path : Unbounded_String := Null_Unbounded_String;
   begin
      if State.Selected_Index /= 0
        and then State.Selected_Index <= Natural (State.Results.Length)
      then
         Previous_Path := State.Results (State.Selected_Index - 1).Display_Path;
      end if;

      State.Visible_Window := Natural'Max (1, Config.Max_Visible_Results);
      State.Results.Clear;
      State.Results_Stale := False;
      State.Project_Available :=
        Editor.File_Tree.Scan_Status (Tree).Status /= Editor.File_Tree.File_Tree_No_Project;
      State.Known_Total := Editor.File_Tree.File_Node_Count (Tree);
      State.Filtered_Total := 0;
      for I in 1 .. Editor.File_Tree.File_Node_Count (Tree) loop
         declare
            Node : constant Editor.File_Tree.File_Tree_Node_Summary :=
              Editor.File_Tree.File_Node_At (Tree, I);
            Path   : constant String := Normalize_Display_Path (To_String (Node.Relative_Path));
            Bucket : constant Quick_Open_Match_Bucket :=
              Quick_Open_Match_Bucket_For (Query, Path);
         begin
            if Node.Id /= Editor.File_Tree.No_File_Tree_Node
              and then Is_Project_Relative_File_Path (Path)
              and then In_Path_Scope (Path, To_String (State.Scope))
              and then Matches_File_Kind (Path, State.Kind_Filter)
              and then Bucket /= No_Match
            then
               State.Filtered_Total := State.Filtered_Total + 1;
               State.Results.Append
                 (Quick_Open_Result'
                   (Node_Id       => Node.Id,
                   Display_Path  => To_Unbounded_String (Path),
                   Absolute_Path => Node.Absolute_Path,
                   Match_Bucket  => Bucket));
            end if;
         end;
      end loop;

      Sort_Results (State.Results);
      while Natural (State.Results.Length) > Config.Max_Result_Count loop
         State.Results.Delete_Last;
      end loop;
      Preserve_Or_First_Selection (State, To_String (Previous_Path));
   end Recompute_Results;


   procedure Recompute_Results
     (State   : in out Quick_Open_State;
      Project : Editor.Project.Project_State;
      Config  : Quick_Open_Config)
   is
      Query         : constant String := Editor.Input_Field.Text (State.Query_Field);
      Previous_Path : Unbounded_String := Null_Unbounded_String;
   begin
      if State.Selected_Index /= 0
        and then State.Selected_Index <= Natural (State.Results.Length)
      then
         Previous_Path := State.Results (State.Selected_Index - 1).Display_Path;
      end if;

      State.Visible_Window := Natural'Max (1, Config.Max_Visible_Results);
      State.Results.Clear;
      State.Results_Stale := False;
      State.Project_Available := Editor.Project.Has_Project (Project);
      State.Known_Total := Editor.Project.Known_File_Count (Project);
      State.Filtered_Total := 0;

      for I in 1 .. Editor.Project.Known_File_Count (Project) loop
         Append_Literal_Project_Result (State, Project, I, Query);
      end loop;

      Sort_Results (State.Results);
      while Natural (State.Results.Length) > Config.Max_Result_Count loop
         State.Results.Delete_Last;
      end loop;

      Preserve_Or_First_Selection (State, To_String (Previous_Path));
   end Recompute_Results;


   procedure Append_Literal_Project_Result
     (State   : in out Quick_Open_State;
      Project : Editor.Project.Project_State;
      Index   : Positive;
      Query   : String)
   is
      File_Item : constant Editor.Project.Project_File_Entry :=
        Editor.Project.Known_File_At (Project, Index);
      Path      : constant String := Normalize_Display_Path (To_String (File_Item.Relative_Path));
      Bucket    : constant Quick_Open_Match_Bucket :=
        Quick_Open_Match_Bucket_For (Query, Path);
   begin
      if Is_Project_Relative_File_Path (Path)
        and then Editor.Project.Is_Under_Project (Project, To_String (File_Item.Absolute_Path))
        and then In_Path_Scope (Path, To_String (State.Scope))
        and then Matches_File_Kind (Path, State.Kind_Filter)
        and then Bucket /= No_Match
      then
         State.Filtered_Total := State.Filtered_Total + 1;
         State.Results.Append
                    (Quick_Open_Result'
                      (Node_Id       => Editor.File_Tree.No_File_Tree_Node,
             Display_Path  => To_Unbounded_String (Path),
             Absolute_Path => File_Item.Absolute_Path,
             Match_Bucket  => Bucket));
      end if;
   end Append_Literal_Project_Result;

   procedure Preserve_Or_First_Selection
     (State         : in out Quick_Open_State;
      Previous_Path : String)
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      State.Selected_Index := 0;
      if Count = 0 then
         State.Top_Index := 1;
         return;
      end if;

      if Previous_Path'Length > 0 then
         for I in State.Results.First_Index .. State.Results.Last_Index loop
            if To_String (State.Results (I).Display_Path) = Previous_Path then
               State.Selected_Index := I + 1;
               exit;
            end if;
         end loop;
      end if;

      if State.Selected_Index = 0 then
         State.Selected_Index := 1;
      end if;
      State.Top_Index := 1;
      Clamp_Window (State);
   end Preserve_Or_First_Selection;

   function Result_Count (State : Quick_Open_State) return Natural is
   begin
      return Natural (State.Results.Length);
   end Result_Count;

   function Selected_Result_Index (State : Quick_Open_State) return Natural is
   begin
      return State.Selected_Index;
   end Selected_Result_Index;

   function Top_Result_Index (State : Quick_Open_State) return Natural is
   begin
      return State.Top_Index;
   end Top_Result_Index;

   function Query_Cursor (State : Quick_Open_State) return Natural is
   begin
      return Editor.Input_Field.Cursor_Column (State.Query_Field);
   end Query_Cursor;

   function Query_Snapshot
     (State           : Quick_Open_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot is
   begin
      return Editor.Input_Field.Snapshot (State.Query_Field, Visible_Columns);
   end Query_Snapshot;

   function Selected_Result (State : Quick_Open_State; Found : out Boolean) return Quick_Open_Result is
   begin
      if State.Selected_Index = 0 or else State.Selected_Index > Natural (State.Results.Length) then
         Found := False;
         return (others => <>);
      end if;
      Found := True;
      return State.Results (State.Selected_Index - 1);
   end Selected_Result;

   function Result_At (State : Quick_Open_State; Index : Natural) return Quick_Open_Result is
   begin
      if Index = 0 or else Index > Natural (State.Results.Length) then
         return (others => <>);
      end if;
      return State.Results (Index - 1);
   end Result_At;


   function Quick_Open_No_Duplicate_Lifecycle_State
     (State : Quick_Open_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return True;
   end Quick_Open_No_Duplicate_Lifecycle_State;

   function Quick_Open_No_Prompt_State
     (State : Quick_Open_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return True;
   end Quick_Open_No_Prompt_State;

   function Quick_Open_Query_Selection_Source_Target_Boundary
     (State : Quick_Open_State) return Boolean
   is
      Count : constant Natural := Natural (State.Results.Length);
   begin
      return State.Selected_Index <= Count
        and then State.Top_Index >= 1
        and then (Count = 0 or else State.Top_Index <= Count)
        and then State.Known_Total >= Count
        and then State.Filtered_Total >= Count;
   end Quick_Open_Query_Selection_Source_Target_Boundary;

   function Quick_Open_File_Lifecycle_Observation_Canonical
     (State : Quick_Open_State) return Boolean
   is
   begin
      return Quick_Open_No_Duplicate_Lifecycle_State (State)
        and then Quick_Open_No_Prompt_State (State)
        and then Quick_Open_Query_Selection_Source_Target_Boundary (State);
   end Quick_Open_File_Lifecycle_Observation_Canonical;

   function Quick_Open_File_Lifecycle_Observation_Frozen
     (State : Quick_Open_State) return Boolean
   is
   begin
      return Quick_Open_File_Lifecycle_Observation_Canonical (State);
   end Quick_Open_File_Lifecycle_Observation_Frozen;

   function Build_Snapshot
     (State : Quick_Open_State) return Quick_Open_Snapshot
   is
      Snapshot : Quick_Open_Snapshot;
   begin
      Snapshot.Visible := State.Opened;
      Snapshot.Query := To_Unbounded_String (Query_Text (State));
      Snapshot.File_Kind_Filter := State.Kind_Filter;
      Snapshot.Path_Scope := State.Scope;
      Snapshot.Priority_Mode := State.Priority;
      Snapshot.Visible_Count := Natural (State.Results.Length);
      Snapshot.Known_Count := State.Known_Total;
      Snapshot.Total_Filtered_Count := State.Filtered_Total;
      Snapshot.Has_Project := State.Project_Available;
      Snapshot.Has_Query := Trim_Query (Query_Text (State))'Length > 0;
      Snapshot.Header_Text := To_Unbounded_String
        ("Kind: " & File_Kind_Filter_Name (State.Kind_Filter)
         & (if Length (State.Scope) > 0 then " | Scope: " & To_String (State.Scope) else "")
         & " | Priority: "
         & (if State.Priority = Open_Recent then "Open/Recent" else "Path")
         & (if State.Results_Stale then " | Results stale."
            elsif not State.Project_Available then " | No project open."
            elsif State.Known_Total = 0 then " | No project files."
            else " | Results: " & Image (State.Filtered_Total) & " of " & Image (State.Known_Total)));
      Snapshot.Selected_Index := State.Selected_Index;

      if not State.Opened then
         Snapshot.Empty_Message := Null_Unbounded_String;
         return Snapshot;
      elsif Natural (State.Results.Length) = 0 then
         if State.Results_Stale then
            Snapshot.Empty_Message := To_Unbounded_String ("Quick Open results are stale.");
         elsif not State.Project_Available then
            Snapshot.Empty_Message := To_Unbounded_String ("No project open.");
         elsif State.Known_Total = 0 then
            Snapshot.Empty_Message := To_Unbounded_String ("No project files.");
         elsif not Snapshot.Has_Query then
            Snapshot.Empty_Message := To_Unbounded_String ("Type to open file.");
         else
            Snapshot.Empty_Message := To_Unbounded_String ("No Quick Open matches.");
         end if;
      end if;

      for I in 1 .. Natural (State.Results.Length) loop
         declare
            Result : constant Quick_Open_Result := Result_At (State, I);
            Path   : constant Unbounded_String := Result.Display_Path;
            Sel    : constant Boolean := I = State.Selected_Index;
         begin
            if Sel then
               Snapshot.Selected_Path := Path;
            end if;
            Snapshot.Candidates.Append
              (Quick_Open_Candidate_Snapshot'
                (Project_Relative_Path => Path,
                Buffer_Identity       => Editor.Buffer_Types.No_Buffer,
                Basename              => To_Unbounded_String (Base_Name (To_String (Path))),
                Match_Bucket          => Result.Match_Bucket,
                Priority_Bucket       => Ordinary_File,
                Display_Text          => Path,
                Is_Open               => False,
                Is_Active             => False,
                Is_Dirty              => False,
                Is_Recent             => False,
                Recent_Rank           => 0,
                Is_Selected           => Sel));
         end;
      end loop;

      return Snapshot;
   end Build_Snapshot;


   function Geometry
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Quick_Open_Config;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Editor.Layout.Rect
   is
      Wanted_W : constant Natural := Config.Overlay_Width_In_Columns * Cell_Width;
      Margin   : constant Natural := 2 * Cell_Width;
      Width    : constant Natural :=
        (if Body_Rect.Width > 2 * Margin
         then Natural'Min (Wanted_W, Body_Rect.Width - 2 * Margin)
         else Body_Rect.Width);
      Rows     : constant Natural :=
        Config.Header_Height_In_Rows + Config.Field_Height_In_Rows +
        Config.Max_Visible_Results * Config.Row_Height_In_Rows;
      Height   : constant Natural := Rows * Cell_Height;
      X        : constant Integer :=
        Body_Rect.X + Integer ((if Body_Rect.Width > Width then (Body_Rect.Width - Width) / 2 else 0));
      Y        : constant Integer := Body_Rect.Y + Integer (Cell_Height);
   begin
      return (X => X, Y => Y, Width => Width, Height => Height);
   end Geometry;

   function Hit_Test
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Quick_Open_Config;
      State       : Quick_Open_State;
      X           : Integer;
      Y           : Integer;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Quick_Open_Hit_Result
   is
      G : constant Editor.Layout.Rect := Geometry (Body_Rect, Config, Cell_Width, Cell_Height);
      Rel_Y : Integer;
      Row_Start : constant Natural :=
        (Config.Header_Height_In_Rows + Config.Field_Height_In_Rows) * Cell_Height;
      Row_H : constant Positive := Positive'Max (1, Config.Row_Height_In_Rows * Cell_Height);
      Row : Natural;
   begin
      if not State.Opened or else X < G.X or else Y < G.Y
        or else X >= G.X + Integer (G.Width) or else Y >= G.Y + Integer (G.Height)
      then
         return (Zone => Outside_Quick_Open, Result_Index => 0);
      end if;

      Rel_Y := Y - G.Y;
      if Rel_Y < Integer (Config.Header_Height_In_Rows * Cell_Height) then
         return (Zone => Quick_Open_Background_Zone, Result_Index => 0);
      elsif Rel_Y < Integer ((Config.Header_Height_In_Rows + Config.Field_Height_In_Rows) * Cell_Height) then
         return (Zone => Quick_Open_Query_Field_Zone, Result_Index => 0);
      elsif Rel_Y >= Integer (Row_Start) then
         Row := Natural ((Rel_Y - Integer (Row_Start)) / Row_H) + 1;
         if Row <= Config.Max_Visible_Results
           and then State.Top_Index + Row - 1 <= Natural (State.Results.Length)
         then
            return (Zone => Quick_Open_Result_Row_Zone,
                    Result_Index => State.Top_Index + Row - 1);
         end if;
      end if;

      return (Zone => Quick_Open_Background_Zone, Result_Index => 0);
   end Hit_Test;

end Editor.Quick_Open;
