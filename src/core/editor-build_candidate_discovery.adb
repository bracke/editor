with Ada.Containers;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Candidates;
with Editor.Build_Working_Context;
with Editor.External_Producers;

package body Editor.Build_Candidate_Discovery is

   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;
   use type Editor.Build_Working_Context.Build_Working_Context_Kind;
   use type Editor.Build_Working_Context.Build_Working_Context_Validation_Status;
   use type Editor.External_Producers.Build_Tool_Kind;

   Max_Directories_Visited : constant Natural := 128;
   Max_Files_Inspected    : constant Natural := 2048;
   Max_Candidate_Count    : constant Natural := 64;
   Max_Nesting_Depth      : constant Natural := 8;
   Max_Directory_Queue    : constant Natural := Max_Directories_Visited;

   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Unbounded_String);

   procedure Sort_Strings (Items : in out String_Vectors.Vector) is
      Temp : Unbounded_String;
   begin
      if Items.Length < 2 then
         return;
      end if;
      for I in Items.First_Index .. Items.Last_Index loop
         for J in I + 1 .. Items.Last_Index loop
            if To_String (Items.Element (J)) < To_String (Items.Element (I)) then
               Temp := Items.Element (I);
               Items.Replace_Element (I, Items.Element (J));
               Items.Replace_Element (J, Temp);
            end if;
         end loop;
      end loop;
   end Sort_Strings;

   function Trim (S : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Trim;

   function Contains_Control (Text : String) return Boolean is
   begin
      for C of Text loop
         if Character'Pos (C) < 32 or else Character'Pos (C) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Control;

   function Safe_Root (Project_Root : String) return Boolean is
      Clean : constant String := Trim (Project_Root);
   begin
      --  Discovery never executes the project root through a shell, so ordinary
      --  filesystem characters such as '$', ';', or literal '..' inside a
      --  directory name must not reject an otherwise canonical active project.
      --  Reject only empty/control-bearing roots here; existence and directory
      --  kind are checked by the discovery entry points before traversal.
      return Clean'Length > 0 and then not Contains_Control (Clean);
   end Safe_Root;

   function Has_Gpr_Extension (Name : String) return Boolean is
   begin
      return Name'Length >= 5
        and then Name (Name'Last - 3 .. Name'Last) = ".gpr";
   end Has_Gpr_Extension;

   function Join_Relative (Parent, Name : String) return String is
   begin
      if Parent'Length = 0 then
         return Name;
      else
         return Parent & "/" & Name;
      end if;
   end Join_Relative;

   function Starts_With (Text, Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;


   function Lower (S : String) return String is
      Result : String := S;
   begin
      for I in Result'Range loop
         if Result (I) in 'A' .. 'Z' then
            Result (I) := Character'Val (Character'Pos (Result (I)) + 32);
         end if;
      end loop;
      return Result;
   end Lower;

   function Base_Name (Path : String) return String is
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = Character'Val (16#5C#) then
            Last_Slash := I;
         end if;
      end loop;
      if Last_Slash = 0 then
         return Path;
      elsif Last_Slash < Path'Last then
         return Path (Last_Slash + 1 .. Path'Last);
      else
         return "project";
      end if;
   end Base_Name;

   function Path_Depth (Path : String) return Natural is
      Depth : Natural := 0;
   begin
      for C of Path loop
         if C = '/' or else C = Character'Val (16#5C#) then
            Depth := Depth + 1;
         end if;
      end loop;
      return Depth;
   end Path_Depth;

   function Gpr_Discovery_Rank (Project_Root, Relative_Gpr_Path : String) return Natural is
      Rel : constant String := Lower (Relative_Gpr_Path);
      Base : constant String := Lower (Base_Name (Rel));
      Root_Base : constant String := Lower (Base_Name (Project_Root));
      Base_Without_Extension : constant String :=
        (if Base'Length > 4 and then Base (Base'Last - 3 .. Base'Last) = ".gpr" then
            Base (Base'First .. Base'Last - 4)
         else
            Base);
   begin
      if Path_Depth (Rel) = 0 and then Base_Without_Extension = Root_Base then
         return 5;
      elsif Path_Depth (Rel) = 0 then
         return 10;
      elsif Ada.Strings.Fixed.Index (Rel, "test") > 0
        or else Ada.Strings.Fixed.Index (Rel, "example") > 0
      then
         return 40 + Path_Depth (Rel);
      elsif Ada.Strings.Fixed.Index (Base, "app") > 0
        or else Ada.Strings.Fixed.Index (Base, "main") > 0
        or else Ada.Strings.Fixed.Index (Base, "demo") > 0
      then
         return 20 + Path_Depth (Rel);
      else
         return 30 + Path_Depth (Rel);
      end if;
   end Gpr_Discovery_Rank;

   function Gpr_Discovery_Less (Project_Root, Left, Right : String) return Boolean is
      Left_Rank  : constant Natural := Gpr_Discovery_Rank (Project_Root, Left);
      Right_Rank : constant Natural := Gpr_Discovery_Rank (Project_Root, Right);
   begin
      if Left_Rank /= Right_Rank then
         return Left_Rank < Right_Rank;
      end if;
      return Left < Right;
   end Gpr_Discovery_Less;

   procedure Sort_Gpr_Relative_Paths
     (Project_Root : String;
      Items        : in out String_Vectors.Vector)
   is
      Temp : Unbounded_String;
   begin
      if Items.Length < 2 then
         return;
      end if;
      for I in Items.First_Index .. Items.Last_Index loop
         for J in I + 1 .. Items.Last_Index loop
            if Gpr_Discovery_Less
              (Project_Root, To_String (Items.Element (J)), To_String (Items.Element (I)))
            then
               Temp := Items.Element (I);
               Items.Replace_Element (I, Items.Element (J));
               Items.Replace_Element (J, Temp);
            end if;
         end loop;
      end loop;
   end Sort_Gpr_Relative_Paths;


   function Image (Value : Natural) return String is
   begin
      return Trim (Natural'Image (Value));
   end Image;

   function Normalize_Separators (Path : String) return String is
      Result : String := Path;
   begin
      for I in Result'Range loop
         if Result (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         end if;
      end loop;
      return Result;
   end Normalize_Separators;

   function Canonical_Existing_Path (Path : String) return String is
   begin
      if Trim (Path)'Length = 0 then
         return "";
      elsif Ada.Directories.Exists (Path) then
         return Normalize_Separators (Ada.Directories.Full_Name (Path));
      else
         return Normalize_Separators (Path);
      end if;
   exception
      when others =>
         return Normalize_Separators (Path);
   end Canonical_Existing_Path;

   function Is_Path_Within_Project_Root (Path, Project_Root : String) return Boolean is
      Canonical_Path : constant String := Canonical_Existing_Path (Path);
      Canonical_Root : constant String := Canonical_Existing_Path (Project_Root);
   begin
      return Canonical_Path = Canonical_Root
        or else (Canonical_Path'Length > Canonical_Root'Length
                 and then Canonical_Path (Canonical_Path'First .. Canonical_Path'First + Canonical_Root'Length - 1) = Canonical_Root
                 and then Canonical_Path (Canonical_Path'First + Canonical_Root'Length) = '/');
   end Is_Path_Within_Project_Root;

   function Ignore_Build_Discovery_Directory
     (Project_Relative_Directory : String;
      Simple_Name : String) return Boolean
   is
      Rel : constant String := Project_Relative_Directory;
   begin
      if Simple_Name'Length = 0
        or else Simple_Name = "."
        or else Simple_Name = ".."
      then
         return True;
      elsif Simple_Name (Simple_Name'First) = '.' then
         return True;
      elsif Simple_Name = "obj" or else Simple_Name = "bin" then
         return True;
      elsif Simple_Name = ".git" or else Simple_Name = ".build" then
         return True;
      elsif Rel = "alire/cache" or else Starts_With (Rel, "alire/cache/") then
         return True;
      elsif Rel = "alire/build" or else Starts_With (Rel, "alire/build/") then
         return True;
      else
         return False;
      end if;
   end Ignore_Build_Discovery_Directory;

   function Discover_Alire_Build_Candidate
     (Project_Root : String) return Editor.Build_Candidates.Build_Candidate_Vector
   is
      Result : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Path : constant String := Project_Root & "/alire.toml";
   begin
      if Safe_Root (Project_Root)
        and then Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File
      then
         Editor.Build_Candidates.Append_Unique_Candidate
           (Result, Editor.Build_Candidates.Alire_Candidate (Project_Root));
      end if;
      return Result;
   exception
      when others =>
         return Result;
   end Discover_Alire_Build_Candidate;

   function Discover_GPR_Project_Candidates_Bounded
     (Project_Root : String;
      Directories_Visited : out Natural;
      Files_Inspected : out Natural;
      Skipped_Directory_Count : out Natural;
      Limit_Reached : out Boolean)
      return Editor.Build_Candidates.Build_Candidate_Vector
   is
      Result : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;

      procedure Visit_Directory
        (Directory_Path : String;
         Relative_Path  : String;
         Depth          : Natural)
      is
         Search : Ada.Directories.Search_Type;
         Dir_Entry  : Ada.Directories.Directory_Entry_Type;
         Started : Boolean := False;
         Directory_Names : String_Vectors.Vector;
         Gpr_Relative_Paths : String_Vectors.Vector;
         Non_Gpr_File_Count : Natural := 0;
         Gpr_Entries_Seen : Natural := 0;
         Child_Directory_Entries_Seen : Natural := 0;
         Directory_Entry_Scan_Count : Natural := 0;
         Directory_Queue_Overflow : Boolean := False;
         Gpr_File_Queue_Overflow : Boolean := False;

         procedure Queue_Gpr_Relative_Path (Rel : String) is
            Worst_Index : Natural := 0;
            Worst_Rel   : Unbounded_String;
            File_Capacity      : Natural := 0;
            Candidate_Capacity : Natural := 0;
            Capacity           : Natural := 0;
         begin
            if Files_Inspected < Max_Files_Inspected then
               File_Capacity := Max_Files_Inspected - Files_Inspected;
            end if;
            if Natural (Result.Length) < Max_Candidate_Count then
               Candidate_Capacity := Max_Candidate_Count - Natural (Result.Length);
            end if;
            Capacity := Natural'Min (File_Capacity, Candidate_Capacity);

            if Capacity = 0 then
               Gpr_File_Queue_Overflow := True;
               Limit_Reached := True;
               return;
            elsif Natural (Gpr_Relative_Paths.Length) < Capacity then
               Gpr_Relative_Paths.Append (To_Unbounded_String (Rel));
               return;
            end if;

            Gpr_File_Queue_Overflow := True;

            if Gpr_Relative_Paths.Is_Empty then
               return;
            end if;

            Worst_Index := Gpr_Relative_Paths.First_Index;
            Worst_Rel := Gpr_Relative_Paths.Element (Worst_Index);
            for I in Gpr_Relative_Paths.First_Index .. Gpr_Relative_Paths.Last_Index loop
               if Gpr_Discovery_Less
                 (Project_Root, To_String (Worst_Rel), To_String (Gpr_Relative_Paths.Element (I)))
               then
                  Worst_Index := I;
                  Worst_Rel := Gpr_Relative_Paths.Element (I);
               end if;
            end loop;

            if Gpr_Discovery_Less (Project_Root, Rel, To_String (Worst_Rel)) then
               Gpr_Relative_Paths.Replace_Element
                 (Worst_Index, To_Unbounded_String (Rel));
            end if;
         end Queue_Gpr_Relative_Path;

         procedure Queue_Directory_Name (Name : String) is
            Worst_Index : Natural := 0;
            Worst_Name  : Unbounded_String;
         begin
            if Natural (Directory_Names.Length) < Max_Directory_Queue then
               Directory_Names.Append (To_Unbounded_String (Name));
               return;
            end if;

            Directory_Queue_Overflow := True;
            Skipped_Directory_Count := Skipped_Directory_Count + 1;

            if Directory_Names.Is_Empty then
               return;
            end if;

            Worst_Index := Directory_Names.First_Index;
            Worst_Name := Directory_Names.Element (Worst_Index);
            for I in Directory_Names.First_Index .. Directory_Names.Last_Index loop
               if To_String (Directory_Names.Element (I)) > To_String (Worst_Name) then
                  Worst_Index := I;
                  Worst_Name := Directory_Names.Element (I);
               end if;
            end loop;

            if Name < To_String (Worst_Name) then
               Directory_Names.Replace_Element
                 (Worst_Index, To_Unbounded_String (Name));
            end if;
         end Queue_Directory_Name;
      begin
         if Limit_Reached then
            return;
         elsif Natural (Result.Length) >= Max_Candidate_Count then
            Limit_Reached := True;
            return;
         elsif Depth > Max_Nesting_Depth
           or else Directories_Visited >= Max_Directories_Visited
         then
            Limit_Reached := True;
            return;
         end if;

         Directories_Visited := Directories_Visited + 1;

         --  Candidate files are inspected first with a bounded direct pattern
         --  search.  The pass continues through the whole bounded scan window
         --  and replaces the worst staged GPR path when a better one appears,
         --  rather than stopping at the first queue overflow.  The staging
         --  queue is capped by both the remaining file-inspection budget and
         --  the remaining candidate-count budget, so discovery never buffers
         --  thousands of candidate rows just to truncate them later.
         Ada.Directories.Start_Search
           (Search    => Search,
            Directory => Directory_Path,
            Pattern   => "*.gpr",
            Filter    => (Ada.Directories.Ordinary_File => True,
                          Ada.Directories.Directory => False,
                          Ada.Directories.Special_File => False));
         Started := True;

         while Ada.Directories.More_Entries (Search) loop
            exit when Files_Inspected + Gpr_Entries_Seen >= Max_Files_Inspected;
            Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
               Rel  : constant String := Join_Relative (Relative_Path, Name);
            begin
               if Has_Gpr_Extension (Name) then
                  Gpr_Entries_Seen := Gpr_Entries_Seen + 1;
                  Queue_Gpr_Relative_Path (Rel);
               end if;
            exception
               when others =>
                  Skipped_Directory_Count := Skipped_Directory_Count + 1;
            end;
         end loop;

         if Ada.Directories.More_Entries (Search) then
            Limit_Reached := True;
         end if;

         Ada.Directories.End_Search (Search);
         Started := False;

         Sort_Gpr_Relative_Paths (Project_Root, Gpr_Relative_Paths);
         for Item of Gpr_Relative_Paths loop
            Editor.Build_Candidates.Append_Unique_Candidate
              (Result, Editor.Build_Candidates.Gprbuild_Candidate
                 (Project_Root, To_String (Item)));
         end loop;

         --  Files_Inspected is scan accounting, not retained-candidate count.
         --  A directory with thousands of GPR files may stage only the best
         --  remaining candidate rows, but every GPR entry observed inside the
         --  bounded search window still spends file-inspection budget.
         if Gpr_Entries_Seen > Max_Files_Inspected - Files_Inspected then
            Files_Inspected := Max_Files_Inspected;
            Limit_Reached := True;
         else
            Files_Inspected := Files_Inspected + Gpr_Entries_Seen;
         end if;

         if Gpr_File_Queue_Overflow
           or else Files_Inspected >= Max_Files_Inspected
         then
            Limit_Reached := True;
         end if;

         Ada.Directories.Start_Search
           (Search    => Search,
            Directory => Directory_Path,
            Pattern   => "*",
            Filter    => (Ada.Directories.Ordinary_File => True,
                          Ada.Directories.Directory => True,
                          Ada.Directories.Special_File => False));
         Started := True;

         while Ada.Directories.More_Entries (Search) loop
            exit when Directory_Entry_Scan_Count >=
              Max_Directory_Queue + Max_Files_Inspected;
            Directory_Entry_Scan_Count := Directory_Entry_Scan_Count + 1;
            Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
               Rel  : constant String := Join_Relative (Relative_Path, Name);
            begin
               if Name = "." or else Name = ".." then
                  null;
               elsif Ada.Directories.Kind (Dir_Entry) = Ada.Directories.Directory then
                  declare
                     Full : constant String := Directory_Path & "/" & Name;
                  begin
                     if Ignore_Build_Discovery_Directory (Rel, Name) then
                        Skipped_Directory_Count := Skipped_Directory_Count + 1;
                     elsif Is_Path_Within_Project_Root (Full, Project_Root) then
                        Child_Directory_Entries_Seen := Child_Directory_Entries_Seen + 1;
                        Queue_Directory_Name (Name);
                     else
                        Skipped_Directory_Count := Skipped_Directory_Count + 1;
                     end if;
                  end;
               elsif Ada.Directories.Kind (Dir_Entry) = Ada.Directories.Ordinary_File then
                  if not Has_Gpr_Extension (Name) then
                     if Non_Gpr_File_Count >= Max_Files_Inspected then
                        Limit_Reached := True;
                     else
                        Non_Gpr_File_Count := Non_Gpr_File_Count + 1;
                     end if;
                  end if;
               end if;
            exception
               when others =>
                  Skipped_Directory_Count := Skipped_Directory_Count + 1;
            end;
         end loop;

         if Ada.Directories.More_Entries (Search) then
            Limit_Reached := True;
         end if;

         Ada.Directories.End_Search (Search);
         Started := False;

         Sort_Strings (Directory_Names);

         --  GPR files in the current directory are staged and ranked before
         --  insertion, so filesystem enumeration order is not candidate
         --  identity.  Non-candidate ordinary files from this directory are
         --  accounted before descending into children: they must not starve
         --  current-directory project files, but they also must not be deferred
         --  until after nested traversal has already spent more than the global
         --  file-inspection budget.

         if Non_Gpr_File_Count > 0 then
            if Files_Inspected >= Max_Files_Inspected
              or else Non_Gpr_File_Count > Max_Files_Inspected - Files_Inspected
            then
               Files_Inspected := Max_Files_Inspected;
               Limit_Reached := True;
            else
               Files_Inspected := Files_Inspected + Non_Gpr_File_Count;
            end if;
         end if;

         --  Child directories are staged through a fixed queue before traversal.
         --  If this directory already exhausted the file budget, traversal stops
         --  here rather than discovering nested candidates beyond the declared
         --  bound.

         for Item of Directory_Names loop
            exit when Limit_Reached;
            declare
               Name : constant String := To_String (Item);
               Full : constant String := Directory_Path & "/" & Name;
               Rel  : constant String := Join_Relative (Relative_Path, Name);
            begin
               Visit_Directory (Full, Rel, Depth + 1);
            exception
               when others =>
                  Skipped_Directory_Count := Skipped_Directory_Count + 1;
            end;
         end loop;

         if Directory_Queue_Overflow then
            Limit_Reached := True;
         end if;
      exception
         when others =>
            if Started then
               Ada.Directories.End_Search (Search);
            end if;
            Skipped_Directory_Count := Skipped_Directory_Count + 1;
      end Visit_Directory;
   begin
      Directories_Visited := 0;
      Files_Inspected := 0;
      Skipped_Directory_Count := 0;
      Limit_Reached := False;

      if not Safe_Root (Project_Root)
        or else not Ada.Directories.Exists (Project_Root)
        or else Ada.Directories.Kind (Project_Root) /= Ada.Directories.Directory
      then
         return Result;
      end if;

      Visit_Directory (Project_Root, "", 0);
      Editor.Build_Candidates.Sort_Build_Candidates (Result);
      if Natural (Result.Length) > Max_Candidate_Count then
         Limit_Reached := True;
         while Natural (Result.Length) > Max_Candidate_Count loop
            Result.Delete_Last;
         end loop;
      end if;
      return Result;
   end Discover_GPR_Project_Candidates_Bounded;

   function Discover_Gprbuild_Candidates
     (Project_Root : String) return Editor.Build_Candidates.Build_Candidate_Vector
   is
      Dirs : Natural;
      Files : Natural;
      Skipped : Natural;
      Is_Limited : Boolean;
   begin
      return Discover_GPR_Project_Candidates_Bounded
        (Project_Root, Dirs, Files, Skipped, Is_Limited);
   end Discover_Gprbuild_Candidates;

   function Build_Candidate_Discovery_Summary
     (Result : Build_Candidate_Discovery_Result) return String
   is
      Total : constant Natural := Natural (Result.Candidates.Length);
      Text : Unbounded_String;
   begin
      if Result.Status = Build_Candidate_Discovery_No_Project_Context then
         return "Project root unavailable.";
      elsif Result.Status = Build_Candidate_Discovery_Rejected_Context then
         return "Project root rejected for build candidate discovery.";
      elsif Total = 0 then
         Text := To_Unbounded_String ("No build candidates found.");
         if Result.Limit_Reached then
            Append (Text, " Build candidate discovery limit reached.");
         end if;
         if Result.Skipped_Directory_Count > 0 then
            Append (Text, " Skipped ");
            Append (Text, Image (Result.Skipped_Directory_Count));
            Append (Text, " directories.");
         end if;
         return To_String (Text);
      end if;

      if Total = 1 then
         Text := To_Unbounded_String ("Found 1 build candidate");
      else
         Text := To_Unbounded_String ("Found " & Image (Total) & " build candidates");
      end if;
      Append (Text, ": ");
      Append (Text, Image (Result.Alire_Candidate_Count));
      Append (Text, " Alire, ");
      Append (Text, Image (Result.Gpr_Candidate_Count));
      Append (Text, " GPR.");
      if Result.Limit_Reached then
         Append (Text, " Build candidate discovery limit reached.");
      end if;
      if Result.Skipped_Directory_Count > 0 then
         Append (Text, " Skipped ");
         Append (Text, Image (Result.Skipped_Directory_Count));
         Append (Text, " directories.");
      end if;
      return To_String (Text);
   end Build_Candidate_Discovery_Summary;

   function Discover_Build_Candidates
     (Context : Editor.Build_Working_Context.Build_Working_Context_Record)
      return Build_Candidate_Discovery_Result
   is
      Project_Root : constant String :=
        To_String (Context.Canonical_Path_If_Available);
      Result : Build_Candidate_Discovery_Result;
      Gpr_Dirs : Natural := 0;
      Gpr_Files : Natural := 0;
      Gpr_Skipped : Natural := 0;
      Gpr_Limited : Boolean := False;
   begin
      Result.Checked_Project_Root := To_Unbounded_String (Project_Root);
      if Context.Kind not in
        Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root |
        Editor.Build_Working_Context.Build_Working_Context_Test_Fixture
      then
         Result.Status := Build_Candidate_Discovery_No_Project_Context;
         Result.Message := To_Unbounded_String ("Project root unavailable.");
         return Result;
      elsif Editor.Build_Working_Context.Validate_Build_Working_Context (Context) /=
        Editor.Build_Working_Context.Build_Working_Context_Valid
        or else not Safe_Root (Project_Root)
      then
         Result.Status := Build_Candidate_Discovery_Rejected_Context;
         Result.Message := To_Unbounded_String ("Project root rejected for build candidate discovery.");
         return Result;
      end if;

      for Candidate of Discover_Alire_Build_Candidate (Project_Root) loop
         Editor.Build_Candidates.Append_Unique_Candidate (Result.Candidates, Candidate);
         Result.Alire_Candidate_Count := Result.Alire_Candidate_Count + 1;
      end loop;
      declare
         Gpr_Candidates : constant Editor.Build_Candidates.Build_Candidate_Vector :=
           Discover_GPR_Project_Candidates_Bounded
             (Project_Root, Gpr_Dirs, Gpr_Files, Gpr_Skipped, Gpr_Limited);
      begin
         for Candidate of Gpr_Candidates loop
            if Natural (Result.Candidates.Length) < Max_Candidate_Count then
               Editor.Build_Candidates.Append_Unique_Candidate (Result.Candidates, Candidate);
               Result.Gpr_Candidate_Count := Result.Gpr_Candidate_Count + 1;
            else
               Gpr_Limited := True;
            end if;
         end loop;
      end;
      Result.Directories_Visited := Gpr_Dirs;
      Result.Files_Inspected := Gpr_Files;
      Result.Skipped_Directory_Count := Gpr_Skipped;
      Result.Limit_Reached := Gpr_Limited;

      if Result.Candidates.Is_Empty then
         Result.Status := Build_Candidate_Discovery_No_Candidates;
      else
         Result.Status := Build_Candidate_Discovery_Complete;
      end if;
      Result.Message := To_Unbounded_String (Build_Candidate_Discovery_Summary (Result));
      return Result;
   end Discover_Build_Candidates;

   function Assert_Build_Candidate_Discovery_Bounded
     (Result : Build_Candidate_Discovery_Result) return Boolean
   is
   begin
      if Result.Directories_Visited > Max_Directories_Visited
        or else Result.Files_Inspected > Max_Files_Inspected
        or else Natural (Result.Candidates.Length) > Max_Candidate_Count
      then
         return False;
      end if;
      for Candidate of Result.Candidates loop
         declare
            Status : constant Editor.Build_Candidates.Build_Candidate_Validation_Status :=
              Editor.Build_Candidates.Validate_Candidate (Candidate);
         begin
            --  permits safe disabled/unavailable candidates to be
            --  displayed when discovery can represent why they cannot form a
            --  runnable request.  The bounded-discovery audit must therefore
            --  reject unstructured/shell/persisted/process-bearing rows, but
            --  must not require every row to be currently runnable.
            if Status not in
              Editor.Build_Candidates.Build_Candidate_Valid |
              Editor.Build_Candidates.Build_Candidate_Unavailable
              or else Editor.Build_Candidates.Has_Raw_Shell_Command_Field (Candidate)
              or else Editor.Build_Candidates.Has_Process_State_Field (Candidate)
              or else Editor.Build_Candidates.Has_Remembered_Consent_Field (Candidate)
              or else Candidate.Tool_Kind = Editor.External_Producers.Custom_Build_Tool
              or else To_String (Candidate.Candidate_Id)'Length = 0
              or else To_String (Candidate.Display_Label) = To_String (Candidate.Candidate_Id)
            then
               return False;
            end if;
         end;
      end loop;
      return Editor.Build_Candidates.Assert_Build_Candidate_List_Is_Deterministic
        (Result.Candidates);
   end Assert_Build_Candidate_Discovery_Bounded;

   function Assert_Build_Candidate_Discovery_Does_Not_Execute
     (Result : Build_Candidate_Discovery_Result) return Boolean
   is
   begin
      for Candidate of Result.Candidates loop
         if Editor.Build_Candidates.Has_Process_State_Field (Candidate) then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Build_Candidate_Discovery_Does_Not_Execute;

   function Assert_Build_Candidate_Discovery_Does_Not_Use_Shell
     (Result : Build_Candidate_Discovery_Result) return Boolean
   is
   begin
      for Candidate of Result.Candidates loop
         if Editor.Build_Candidates.Has_Raw_Shell_Command_Field (Candidate) then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Build_Candidate_Discovery_Does_Not_Use_Shell;

   function Assert_Build_Candidate_Discovery_Does_Not_Scan_Outside_Project_Root
     (Result : Build_Candidate_Discovery_Result) return Boolean
   is
      Root : constant String := To_String (Result.Checked_Project_Root);
   begin
      for Candidate of Result.Candidates loop
         declare
            Path : constant String := To_String (Candidate.Source_Path_If_Represented);
         begin
            if Path'Length > 0
              and then not Is_Path_Within_Project_Root (Path, Root)
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Assert_Build_Candidate_Discovery_Does_Not_Scan_Outside_Project_Root;

   function Assert_Build_Candidate_Discovery_Depth_Coherent
     (Result : Build_Candidate_Discovery_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Discovery_Bounded (Result)
        and then Assert_Build_Candidate_Discovery_Does_Not_Execute (Result)
        and then Assert_Build_Candidate_Discovery_Does_Not_Use_Shell (Result)
        and then Assert_Build_Candidate_Discovery_Does_Not_Scan_Outside_Project_Root (Result)
        and then Result.Alire_Candidate_Count + Result.Gpr_Candidate_Count =
          Natural (Result.Candidates.Length)
        and then Length (Result.Message) > 0;
   end Assert_Build_Candidate_Discovery_Depth_Coherent;

end Editor.Build_Candidate_Discovery;
