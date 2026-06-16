with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Editor.Buffers;
with Editor.Project;
with Editor.Quick_Open;
with Editor.Recent_Buffers;

package body Editor.Quick_Open_Markers is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Quick_Open.Quick_Open_Priority_Mode;
   use type Editor.Quick_Open.Quick_Open_Priority_Bucket;
   use type Editor.Quick_Open.Quick_Open_Match_Bucket;

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

   function Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image;

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
      P : constant String := Normalize_For_Compare (Path);
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
      Filter : Editor.Quick_Open.Quick_Open_File_Kind_Filter) return Boolean
   is
   begin
      case Filter is
         when Editor.Quick_Open.All_Files =>
            return True;
         when Editor.Quick_Open.Ada_Files =>
            return Is_Ada_File (Path);
         when Editor.Quick_Open.Test_Files =>
            return Is_Test_File (Path);
         when Editor.Quick_Open.Doc_Files =>
            return Is_Doc_File (Path);
         when Editor.Quick_Open.Other_Files =>
            return not Is_Test_File (Path)
              and then not Is_Ada_File (Path)
              and then not Is_Doc_File (Path);
      end case;
   end Matches_File_Kind;

   function In_Path_Scope (Path, Scope : String) return Boolean is
      P : constant String := Normalize_For_Compare (Path);
      S : constant String := Normalize_For_Compare (Scope);
   begin
      return S'Length = 0 or else Starts_With (P, S);
   end In_Path_Scope;

   function Path_Depth (Path : String) return Natural is
      P : constant String := Normalize_For_Compare (Path);
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
      P : constant String := Normalize_For_Compare
        (Ada.Strings.Fixed.Trim (Pattern, Ada.Strings.Both));
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
      P : constant String := Normalize_For_Compare
        (Ada.Strings.Fixed.Trim (Pattern, Ada.Strings.Both));
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
      Q : constant String := Normalize_For_Compare
        (Ada.Strings.Fixed.Trim (Query, Ada.Strings.Both));
      P : constant String := Normalize_For_Compare (Path);
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
      P : constant String := Normalize_For_Compare (Path);
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
      Normalized : constant String := Ada.Strings.Fixed.Trim
        (Normalize_For_Compare (Path), Ada.Strings.Both);
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

   function Match_Bucket_For
     (Query : String;
      Path  : String) return Editor.Quick_Open.Quick_Open_Match_Bucket
   is
      Q : constant String := Normalize_For_Compare
        (Ada.Strings.Fixed.Trim (Query, Ada.Strings.Both));
      P : constant String := Normalize_For_Compare (Path);
      B : constant String := Normalize_For_Compare (Base_Name (Path));
   begin
      if Q'Length = 0 then
         return Editor.Quick_Open.No_Match;
      elsif Query_Has_Path_Traversal_Term (Q)
        or else Query_Has_Project_Relative_Violation (Q)
      then
         return Editor.Quick_Open.No_Match;
      elsif B = Q then
         return Editor.Quick_Open.Basename_Exact;
      elsif Starts_With (B, Q) then
         return Editor.Quick_Open.Basename_Prefix;
      elsif Contains (B, Q) then
         return Editor.Quick_Open.Basename_Substring;
      elsif Has_Whitespace (Q) and then Ordered_Terms_Match (Q, P, True) then
         return Editor.Quick_Open.Path_Segment_Prefix;
      elsif Starts_With (P, Q) then
         return Editor.Quick_Open.Path_Prefix;
      elsif Segment_Contains (P, Q, True) then
         return Editor.Quick_Open.Path_Segment_Prefix;
      elsif Has_Whitespace (Q) and then Ordered_Terms_Match (Q, P, False) then
         return Editor.Quick_Open.Path_Segment_Substring;
      elsif Segment_Contains (P, Q, False) then
         return Editor.Quick_Open.Path_Segment_Substring;
      elsif Contains (P, Q) then
         return Editor.Quick_Open.Path_Substring;
      elsif Ordered_Basename_Fuzzy_Match (Q, B) then
         return Editor.Quick_Open.Basename_Fuzzy;
      elsif Ordered_Characters_Match (Q, P)
        and then not Ordered_Characters_Match (Q, B)
      then
         return Editor.Quick_Open.Path_Fuzzy;
      else
         return Editor.Quick_Open.No_Match;
      end if;
   end Match_Bucket_For;

   function Match_Bucket_Priority
     (Bucket : Editor.Quick_Open.Quick_Open_Match_Bucket) return Natural is
   begin
      case Bucket is
         when Editor.Quick_Open.Basename_Exact         => return 1;
         when Editor.Quick_Open.Basename_Prefix        => return 2;
         when Editor.Quick_Open.Basename_Substring     => return 3;
         when Editor.Quick_Open.Path_Segment_Prefix    => return 4;
         when Editor.Quick_Open.Path_Prefix            => return 4;
         when Editor.Quick_Open.Path_Segment_Substring => return 5;
         when Editor.Quick_Open.Path_Substring         => return 5;
         when Editor.Quick_Open.Basename_Fuzzy         => return 6;
         when Editor.Quick_Open.Path_Fuzzy             => return 7;
         when Editor.Quick_Open.No_Match               => return 8;
      end case;
   end Match_Bucket_Priority;

   function Priority_Bucket_Priority
     (Bucket : Editor.Quick_Open.Quick_Open_Priority_Bucket) return Natural is
   begin
      case Bucket is
         when Editor.Quick_Open.Active_File     => return 1;
         when Editor.Quick_Open.Open_Dirty_File => return 2;
         when Editor.Quick_Open.Open_Clean_File => return 3;
         when Editor.Quick_Open.Recent_File     => return 4;
         when Editor.Quick_Open.Ordinary_File   => return 5;
      end case;
   end Priority_Bucket_Priority;

   function Candidate_Before
     (Left  : Editor.Quick_Open.Quick_Open_Candidate_Snapshot;
      Right : Editor.Quick_Open.Quick_Open_Candidate_Snapshot) return Boolean
   is
      LP : constant String := Normalize_For_Compare
        (To_String (Left.Project_Relative_Path));
      RP : constant String := Normalize_For_Compare
        (To_String (Right.Project_Relative_Path));
      LO : constant String := To_String (Left.Project_Relative_Path);
      RO : constant String := To_String (Right.Project_Relative_Path);
   begin
      if Priority_Bucket_Priority (Left.Priority_Bucket)
        /= Priority_Bucket_Priority (Right.Priority_Bucket)
      then
         return Priority_Bucket_Priority (Left.Priority_Bucket)
           < Priority_Bucket_Priority (Right.Priority_Bucket);
      elsif Match_Bucket_Priority (Left.Match_Bucket)
        /= Match_Bucket_Priority (Right.Match_Bucket)
      then
         return Match_Bucket_Priority (Left.Match_Bucket)
           < Match_Bucket_Priority (Right.Match_Bucket);
      elsif Left.Priority_Bucket = Editor.Quick_Open.Recent_File
        and then Right.Priority_Bucket = Editor.Quick_Open.Recent_File
        and then Left.Recent_Rank /= Right.Recent_Rank
      then
         return Left.Recent_Rank < Right.Recent_Rank;
      elsif Left.Match_Bucket /= Editor.Quick_Open.Path_Substring
        and then Path_Depth (LO) /= Path_Depth (RO)
      then
         return Path_Depth (LO) < Path_Depth (RO);
      elsif Left.Match_Bucket /= Editor.Quick_Open.Path_Substring
        and then LO'Length /= RO'Length
      then
         return LO'Length < RO'Length;
      elsif LP /= RP then
         return LP < RP;
      else
         return LO < RO;
      end if;
   end Candidate_Before;

   procedure Sort_Candidates
     (Snapshot : in out Editor.Quick_Open.Quick_Open_Snapshot)
   is
      Tmp : Editor.Quick_Open.Quick_Open_Candidate_Snapshot;
   begin
      if Snapshot.Candidates.Length < 2 then
         return;
      end if;

      for I in Snapshot.Candidates.First_Index + 1 .. Snapshot.Candidates.Last_Index loop
         Tmp := Snapshot.Candidates (I);
         declare
            J : Natural := I;
         begin
            while J > Snapshot.Candidates.First_Index
              and then Candidate_Before (Tmp, Snapshot.Candidates (J - 1))
            loop
               Snapshot.Candidates.Replace_Element (J, Snapshot.Candidates (J - 1));
               J := J - 1;
            end loop;
            Snapshot.Candidates.Replace_Element (J, Tmp);
         end;
      end loop;
   end Sort_Candidates;

   function Build_Snapshot
     (State    : Editor.Quick_Open.Quick_Open_State;
      Registry : Editor.Buffers.Buffer_Registry)
      return Editor.Quick_Open.Quick_Open_Snapshot
   is
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot :=
        Editor.Quick_Open.Build_Snapshot (State);

      function Candidate_Index_For_Buffer_Path (Path : String) return Natural is
         Wanted : constant String := Normalize_For_Compare (Path);
      begin
         if Snapshot.Candidates.Length = 0 then
            return Natural'Last;
         end if;

         for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
            declare
               Candidate : constant String := Normalize_For_Compare
                 (To_String (Snapshot.Candidates (I).Project_Relative_Path));
            begin
               if Candidate = Wanted
                 or else (Wanted'Length > Candidate'Length
                          and then Ends_With (Wanted, Candidate)
                          and then Wanted (Wanted'Last - Candidate'Length) = '/')
               then
                  return I;
               end if;
            end;
         end loop;
         return Natural'Last;
      end Candidate_Index_For_Buffer_Path;

      procedure Refresh_Display_Text (Index : Natural) is
         Text : Unbounded_String := Snapshot.Candidates (Index).Project_Relative_Path;
      begin
         if Snapshot.Candidates (Index).Is_Open then
            Append (Text, " [open]");
         end if;
         if Snapshot.Candidates (Index).Is_Active then
            Append (Text, " [active]");
         end if;
         if Snapshot.Candidates (Index).Is_Dirty then
            Append (Text, " [dirty]");
         end if;
         Snapshot.Candidates (Index).Display_Text := Text;
      end Refresh_Display_Text;
   begin
      --  This overload has no authoritative Project_State.  It therefore must
      --  preserve the retained Quick Open candidate set from State and only
      --  annotate rows that already exist in that transient model.  Treating a
      --  missing explicit Project_State as "no project open" would erase valid
      --  rows after Recompute_Results(State, Project, ...), while adding
      --  registry-only rows would violate Phase 546's project-file candidate
      --  boundary.
      if Snapshot.Candidates.Length = 0 then
         return Snapshot;
      end if;

      for B in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, B);
            Index   : Natural := Natural'Last;
         begin
            if Summary.Has_Path then
               Index := Candidate_Index_For_Buffer_Path
                 (To_String (Summary.Path));
            end if;

            if Index /= Natural'Last then
               Snapshot.Candidates (Index).Buffer_Identity := Summary.Id;
               Snapshot.Candidates (Index).Is_Open := True;
               Snapshot.Candidates (Index).Is_Active :=
                 Summary.Id = Editor.Buffers.Active_Buffer (Registry);
               Snapshot.Candidates (Index).Is_Dirty :=
                 Editor.Buffers.Is_Dirty (Registry, Summary.Id);
               Refresh_Display_Text (Index);
            end if;
         end;
      end loop;

      return Snapshot;
   end Build_Snapshot;

   function Build_Snapshot
     (State    : Editor.Quick_Open.Quick_Open_State;
      Project  : Editor.Project.Project_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State)
      return Editor.Quick_Open.Quick_Open_Snapshot
   is
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot :=
        Editor.Quick_Open.Build_Snapshot (State);
      Retained_Result_Limit : constant Natural := Natural (Snapshot.Candidates.Length);
      Next_Recent_Rank : Natural := 0;

      function Candidate_Index (Path : String) return Natural is
         Wanted : constant String := Normalize_For_Compare (Path);
      begin
         if Snapshot.Candidates.Length = 0 then
            return Natural'Last;
         end if;

         for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
            if Normalize_For_Compare
              (To_String (Snapshot.Candidates (I).Project_Relative_Path)) = Wanted
            then
               return I;
            end if;
         end loop;
         return Natural'Last;
      end Candidate_Index;

      function Open_Buffer_Candidate_Index
        (Summary : Editor.Buffers.Buffer_Summary;
         Path    : String) return Natural
      is
         Wanted : constant String := Normalize_For_Compare (Path);
      begin
         if Snapshot.Candidates.Length = 0 then
            return Natural'Last;
         end if;

         for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
            if Snapshot.Candidates (I).Buffer_Identity = Summary.Id then
               return I;
            end if;
         end loop;

         --  Path-backed open buffers annotate an existing project/file candidate
         --  when the retained project source already owns that row.  No-path
         --  buffers never merge by label: their candidate identity is the
         --  canonical buffer id, not the display text.
         if Summary.Has_Path then
            for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
               if Snapshot.Candidates (I).Buffer_Identity = Editor.Buffers.No_Buffer
                 and then Normalize_For_Compare
                   (To_String (Snapshot.Candidates (I).Project_Relative_Path)) = Wanted
               then
                  return I;
               end if;
            end loop;
         end if;

         return Natural'Last;
      end Open_Buffer_Candidate_Index;

      procedure Refresh_Display_Text (Index : Natural);

      function Open_Buffer_Display_Path
        (Summary : Editor.Buffers.Buffer_Summary;
         Path    : String) return String
      is
         Name : constant String := To_String (Summary.Display_Name);
      begin
         if Path'Length > 0 then
            return Path;
         elsif not Summary.Has_Path then
            return "Untitled";
         elsif Name'Length > 0 then
            return Name;
         else
            return "Untitled";
         end if;
      end Open_Buffer_Display_Path;

      function Open_Buffer_May_Synthesize
        (Summary : Editor.Buffers.Buffer_Summary;
         Path    : String) return Boolean
      is
      begin
         if not Snapshot.Has_Query then
            return False;
         elsif not Summary.Has_Path then
            return Retained_Result_Limit > 0;
         elsif Editor.Project.Has_Known_File (Project, Path) then
            return False;
         else
            return Retained_Result_Limit > 0
              or else Editor.Project.Known_File_Count (Project) = 0;
         end if;
      end Open_Buffer_May_Synthesize;

      procedure Ensure_Open_Buffer_Candidate
        (Summary : Editor.Buffers.Buffer_Summary;
         Path    : String;
         Index   : out Natural)
      is
      begin
         Index := Open_Buffer_Candidate_Index (Summary, Path);
         if Index /= Natural'Last then
            Snapshot.Candidates (Index).Buffer_Identity := Summary.Id;
            return;
         end if;

         if Open_Buffer_May_Synthesize (Summary, Path) then
            declare
               Display_Path : constant String :=
                 Open_Buffer_Display_Path (Summary, Path);
            begin
               Snapshot.Candidates.Append
                 (Editor.Quick_Open.Quick_Open_Candidate_Snapshot'
                    (Project_Relative_Path => To_Unbounded_String (Display_Path),
                     Buffer_Identity       => Summary.Id,
                     Basename              =>
                       To_Unbounded_String (Base_Name (Display_Path)),
                     Match_Bucket          =>
                       Match_Bucket_For (To_String (Snapshot.Query), Display_Path),
                     Priority_Bucket       => Editor.Quick_Open.Ordinary_File,
                     Display_Text          => To_Unbounded_String (Display_Path),
                     Is_Open               => True,
                     Is_Active             =>
                       Summary.Id = Editor.Buffers.Active_Buffer (Registry),
                     Is_Dirty              =>
                       Editor.Buffers.Is_Dirty (Registry, Summary.Id),
                     Is_Recent             => False,
                     Recent_Rank           => 0,
                     Is_Selected           => False));
               Index := Snapshot.Candidates.Last_Index;
            end;
         end if;
      end Ensure_Open_Buffer_Candidate;

      function Resolve_Buffer_Project_Path
        (Id       : Editor.Buffers.Buffer_Id;
         Resolved : out Unbounded_String) return Boolean
      is
         Summary : Editor.Buffers.Buffer_Summary;
         Rel : Unbounded_String;
      begin
         Resolved := Null_Unbounded_String;
         if Id = Editor.Buffers.No_Buffer
           or else not Editor.Buffers.Contains (Registry, Id)
         then
            return False;
         end if;

         Summary := Editor.Buffers.Summary_For (Registry, Id);
         if not Summary.Has_Path then
            return False;
         end if;

         if Editor.Project.Has_Project (Project) then
            if not Editor.Project.Is_Under_Project (Project, To_String (Summary.Path)) then
               return False;
            end if;
            Rel := To_Unbounded_String
              (Editor.Project.Relative_Path (Project, To_String (Summary.Path)));
         else
            Rel := Summary.Path;
         end if;

         Resolved := Rel;
         return True;
      end Resolve_Buffer_Project_Path;

      procedure Refresh_Display_Text (Index : Natural) is
         Text : Unbounded_String := Snapshot.Candidates (Index).Project_Relative_Path;
      begin
         if Snapshot.Candidates (Index).Is_Open then
            Append (Text, " [open]");
         end if;
         if Snapshot.Candidates (Index).Is_Active then
            Append (Text, " [active]");
         end if;
         if Snapshot.Candidates (Index).Is_Dirty then
            Append (Text, " [dirty]");
         end if;
         if Snapshot.Candidates (Index).Is_Recent
           and then not Snapshot.Candidates (Index).Is_Open
         then
            Append (Text, " [recent]");
         end if;
         Snapshot.Candidates (Index).Display_Text := Text;
      end Refresh_Display_Text;

      procedure Refresh_Header_Text is
      begin
         Snapshot.Header_Text := To_Unbounded_String
           ("Kind: " & Editor.Quick_Open.File_Kind_Filter_Name (Snapshot.File_Kind_Filter)
            & (if Length (Snapshot.Path_Scope) > 0
               then " | Scope: " & To_String (Snapshot.Path_Scope)
               else "")
            & " | Priority: "
            & (if Snapshot.Priority_Mode = Editor.Quick_Open.Open_Recent
               then "Open/Recent" else "Path")
            & (if not Snapshot.Has_Project then " | No project open."
               elsif Snapshot.Known_Count = 0 then " | No project files."
               else " | Results: " & Image (Snapshot.Total_Filtered_Count)
                 & " of " & Image (Snapshot.Known_Count)));
      end Refresh_Header_Text;

      procedure Recompute_Selection_After_Sort is
         Selected : constant String := To_String (Snapshot.Selected_Path);
      begin
         Snapshot.Selected_Index := 0;
         if Snapshot.Candidates.Length = 0 then
            return;
         end if;

         for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
            Snapshot.Candidates (I).Is_Selected := False;
            if Selected'Length > 0
              and then To_String (Snapshot.Candidates (I).Project_Relative_Path) = Selected
            then
               Snapshot.Selected_Index := I + 1;
               Snapshot.Candidates (I).Is_Selected := True;
            end if;
         end loop;

         if Snapshot.Selected_Index = 0
           and then Natural (Snapshot.Candidates.Length) > 0
         then
            Snapshot.Selected_Index := 1;
            Snapshot.Selected_Path := Snapshot.Candidates (Snapshot.Candidates.First_Index).Project_Relative_Path;
            Snapshot.Candidates (Snapshot.Candidates.First_Index).Is_Selected := True;
         end if;
      end Recompute_Selection_After_Sort;

      procedure Rebuild_Project_Candidates_From_Retained_Source is
         Selected : constant String := To_String (Snapshot.Selected_Path);
         Retained : Editor.Quick_Open.Candidate_Snapshot_Vectors.Vector := Snapshot.Candidates;
      begin
         Snapshot.Candidates.Clear;
         Snapshot.Has_Project := Editor.Project.Has_Project (Project);
         Snapshot.Has_Query := Ada.Strings.Fixed.Trim
           (To_String (Snapshot.Query), Ada.Strings.Both)'Length > 0;
         Snapshot.Known_Count := Editor.Project.Known_File_Count (Project);
         Snapshot.Visible_Count := 0;
         Snapshot.Total_Filtered_Count := 0;
         Snapshot.Selected_Index := 0;

         --  The authoritative marker projection may re-check current project
         --  membership and recompute total filtered count from the current
         --  project list, but it must not add rows that Quick Open did not
         --  retain in its bounded transient result model.
         for I in 1 .. Editor.Project.Known_File_Count (Project) loop
            declare
               File_Item : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (Project, I);
               Path      : constant String := To_String (File_Item.Relative_Path);
               Bucket    : constant Editor.Quick_Open.Quick_Open_Match_Bucket :=
                 Match_Bucket_For (To_String (Snapshot.Query), Path);
            begin
               if Is_Project_Relative_File_Path (Path)
                 and then Editor.Project.Is_Under_Project
                   (Project, To_String (File_Item.Absolute_Path))
                 and then In_Path_Scope (Path, To_String (Snapshot.Path_Scope))
                 and then Matches_File_Kind (Path, Snapshot.File_Kind_Filter)
                 and then Bucket /= Editor.Quick_Open.No_Match
               then
                  Snapshot.Total_Filtered_Count := Snapshot.Total_Filtered_Count + 1;
               end if;
            end;
         end loop;

         if Retained.Length > 0 then
            for I in Retained.First_Index .. Retained.Last_Index loop
               declare
                  Path   : constant String :=
                    To_String (Retained (I).Project_Relative_Path);
                  Bucket : constant Editor.Quick_Open.Quick_Open_Match_Bucket :=
                    Match_Bucket_For (To_String (Snapshot.Query), Path);
                  Sel    : constant Boolean := Selected'Length > 0 and then Path = Selected;
               begin
                  if Is_Project_Relative_File_Path (Path)
                    and then Editor.Project.Has_Known_File (Project, Path)
                    and then In_Path_Scope (Path, To_String (Snapshot.Path_Scope))
                    and then Matches_File_Kind (Path, Snapshot.File_Kind_Filter)
                    and then Bucket /= Editor.Quick_Open.No_Match
                  then
                     if Sel then
                        Snapshot.Selected_Index := Natural (Snapshot.Candidates.Length) + 1;
                     end if;
                     Snapshot.Candidates.Append
                       (Editor.Quick_Open.Quick_Open_Candidate_Snapshot'(Project_Relative_Path => To_Unbounded_String (Path),
                         Buffer_Identity       => Editor.Buffers.No_Buffer,
                         Basename              => To_Unbounded_String (Base_Name (Path)),
                         Match_Bucket          => Bucket,
                         Priority_Bucket       => Editor.Quick_Open.Ordinary_File,
                         Display_Text          => To_Unbounded_String (Path),
                         Is_Open               => False,
                         Is_Active             => False,
                         Is_Dirty              => False,
                         Is_Recent             => False,
                         Recent_Rank           => 0,
                         Is_Selected           => Sel));
                  end if;
               end;
            end loop;
         end if;

         if Snapshot.Candidates.Length = 0
           and then Retained_Result_Limit > 0
           and then Snapshot.Has_Query
         then
            for I in 1 .. Editor.Project.Known_File_Count (Project) loop
               exit when Natural (Snapshot.Candidates.Length) >= Retained_Result_Limit;
               declare
                  File_Item : constant Editor.Project.Project_File_Entry :=
                    Editor.Project.Known_File_At (Project, I);
                  Path      : constant String :=
                    To_String (File_Item.Relative_Path);
                  Bucket    : constant Editor.Quick_Open.Quick_Open_Match_Bucket :=
                    Match_Bucket_For (To_String (Snapshot.Query), Path);
               begin
                  if Is_Project_Relative_File_Path (Path)
                    and then Editor.Project.Is_Under_Project
                      (Project, To_String (File_Item.Absolute_Path))
                    and then In_Path_Scope (Path, To_String (Snapshot.Path_Scope))
                    and then Matches_File_Kind (Path, Snapshot.File_Kind_Filter)
                  then
                     Snapshot.Candidates.Append
                       (Editor.Quick_Open.Quick_Open_Candidate_Snapshot'
                          (Project_Relative_Path => To_Unbounded_String (Path),
                           Buffer_Identity       => Editor.Buffers.No_Buffer,
                           Basename              => To_Unbounded_String (Base_Name (Path)),
                           Match_Bucket          => Bucket,
                           Priority_Bucket       => Editor.Quick_Open.Ordinary_File,
                           Display_Text          => To_Unbounded_String (Path),
                           Is_Open               => False,
                           Is_Active             => False,
                           Is_Dirty              => False,
                           Is_Recent             => False,
                           Recent_Rank           => 0,
                           Is_Selected           => False));
                  end if;
               end;
            end loop;
         end if;

         if Snapshot.Candidates.Length = 0 then
            Snapshot.Selected_Index := 0;
            Snapshot.Selected_Path := Null_Unbounded_String;
            if not Snapshot.Has_Project then
               Snapshot.Empty_Message := To_Unbounded_String ("No project open.");
            elsif Snapshot.Known_Count = 0 then
               Snapshot.Empty_Message := To_Unbounded_String ("No project files.");
            elsif not Snapshot.Has_Query then
               Snapshot.Empty_Message := To_Unbounded_String ("Type to open file.");
            else
               Snapshot.Empty_Message := To_Unbounded_String ("No Quick Open matches.");
            end if;
         else
            Sort_Candidates (Snapshot);
            Snapshot.Visible_Count := Natural (Snapshot.Candidates.Length);
            Recompute_Selection_After_Sort;
            Snapshot.Empty_Message := Null_Unbounded_String;
         end if;
         Refresh_Header_Text;
      end Rebuild_Project_Candidates_From_Retained_Source;
   begin
      if not Editor.Project.Has_Project (Project) then
         --  The marker-enriched projection is always bounded by the
         --  authoritative current project.  A stale retained Quick Open result
         --  vector may still exist briefly after project close/switch so that
         --  command availability can reject activation explicitly, but render
         --  must never project those old rows as current candidates.
         Snapshot.Candidates.Clear;
         Snapshot.Has_Project := False;
         Snapshot.Has_Query := Ada.Strings.Fixed.Trim
           (To_String (Snapshot.Query), Ada.Strings.Both)'Length > 0;
         Snapshot.Known_Count := 0;
         Snapshot.Visible_Count := 0;
         Snapshot.Total_Filtered_Count := 0;
         Snapshot.Selected_Index := 0;
         Snapshot.Selected_Path := Null_Unbounded_String;
         Snapshot.Empty_Message := To_Unbounded_String ("No project open.");
         Refresh_Header_Text;
         return Snapshot;
      end if;

      Rebuild_Project_Candidates_From_Retained_Source;
      for B in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
            declare
               Summary  : constant Editor.Buffers.Buffer_Summary :=
                 Editor.Buffers.Summary_At (Registry, B);
               Resolved : Unbounded_String;
               Index    : Natural := Natural'Last;
            begin
               if Resolve_Buffer_Project_Path (Summary.Id, Resolved) then
                  Ensure_Open_Buffer_Candidate (Summary, To_String (Resolved), Index);
               elsif not Summary.Has_Path then
                  Ensure_Open_Buffer_Candidate (Summary, "", Index);
               end if;

               if Index /= Natural'Last then
                  Snapshot.Candidates (Index).Is_Open := True;
                  Snapshot.Candidates (Index).Is_Active :=
                    Summary.Id = Editor.Buffers.Active_Buffer (Registry);
                  Snapshot.Candidates (Index).Is_Dirty :=
                    Editor.Buffers.Is_Dirty (Registry, Summary.Id);
               end if;
            end;
      end loop;

      for R in 1 .. Editor.Recent_Buffers.Count (Recent) loop
         declare
            Id       : constant Editor.Buffers.Buffer_Id :=
              Editor.Buffers.Buffer_Id (Editor.Recent_Buffers.Id_At (Recent, R));
            Resolved : Unbounded_String;
            Index    : Natural := Natural'Last;
         begin
            if Resolve_Buffer_Project_Path (Id, Resolved) then
               Index := Candidate_Index (To_String (Resolved));
               if Index /= Natural'Last
                 and then not Snapshot.Candidates (Index).Is_Recent
               then
                  Next_Recent_Rank := Next_Recent_Rank + 1;
                  Snapshot.Candidates (Index).Is_Recent := True;
                  Snapshot.Candidates (Index).Recent_Rank := Next_Recent_Rank;
               end if;
            end if;
         end;
      end loop;

      if Snapshot.Candidates.Length > 0 then
         for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
            if Snapshot.Candidates (I).Is_Active then
               Snapshot.Candidates (I).Priority_Bucket := Editor.Quick_Open.Active_File;
            elsif Snapshot.Candidates (I).Is_Open and then Snapshot.Candidates (I).Is_Dirty then
               Snapshot.Candidates (I).Priority_Bucket := Editor.Quick_Open.Open_Dirty_File;
            elsif Snapshot.Candidates (I).Is_Open then
               Snapshot.Candidates (I).Priority_Bucket := Editor.Quick_Open.Open_Clean_File;
            elsif Snapshot.Candidates (I).Is_Recent then
               Snapshot.Candidates (I).Priority_Bucket := Editor.Quick_Open.Recent_File;
            else
               Snapshot.Candidates (I).Priority_Bucket := Editor.Quick_Open.Ordinary_File;
            end if;
            Refresh_Display_Text (I);
         end loop;
      end if;

      if Snapshot.Priority_Mode = Editor.Quick_Open.Open_Recent then
         Sort_Candidates (Snapshot);
      end if;

      Snapshot.Visible_Count := Natural (Snapshot.Candidates.Length);
      if Snapshot.Candidates.Length > 0 then
         Snapshot.Empty_Message := Null_Unbounded_String;
      end if;
      Recompute_Selection_After_Sort;
      Refresh_Header_Text;

      return Snapshot;
   end Build_Snapshot;

end Editor.Quick_Open_Markers;
