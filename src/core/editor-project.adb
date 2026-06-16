with Ada.Directories;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Text_IO;
with Ada.Text_IO;

package body Editor.Project is
   use type Ada.Directories.File_Kind;

   function Is_Separator (Ch : Character) return Boolean is
   begin
      return Ch = '/' or else Ch = '\';
   end Is_Separator;

   function Strip_Trailing_Separators (Path : String) return String is
      Last : Integer := Path'Last;
   begin
      if Path'Length = 0 then
         return Path;
      end if;

      while Last > Path'First and then Is_Separator (Path (Last)) loop
         Last := Last - 1;
      end loop;

      return Path (Path'First .. Last);
   end Strip_Trailing_Separators;

   function Normalize_For_Compare (Path : String) return String is
      Stripped : constant String := Strip_Trailing_Separators (Path);
      Result   : String (Stripped'Range);
   begin
      for I in Stripped'Range loop
         if Stripped (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Stripped (I);
         end if;
      end loop;
      return Result;
   end Normalize_For_Compare;

   function Comparable_Path (Path : String) return String is
   begin
      if Path'Length = 0 then
         return Path;
      elsif Ada.Directories.Exists (Path) then
         return Normalize_For_Compare (Ada.Directories.Full_Name (Path));
      else
         return Normalize_For_Compare (Path);
      end if;
   exception
      when others =>
         return Normalize_For_Compare (Path);
   end Comparable_Path;

   function Starts_With
     (Text   : String;
      Prefix : String) return Boolean
   is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   procedure Clear
     (State : in out Project_State)
   is
   begin
      State.Has_Root := False;
      State.Root_Path := Null_Unbounded_String;
      State.Display_Name := Null_Unbounded_String;
      State.Known_Files.Clear;
      State.Has_Last_Refresh := False;
      State.Last_Refresh := (others => <>);
   end Clear;

   function Has_Project
     (State : Project_State) return Boolean
   is
   begin
      return State.Has_Root;
   end Has_Project;

   function Root_Path
     (State : Project_State) return String
   is
   begin
      return To_String (State.Root_Path);
   end Root_Path;

   function Display_Name
     (State : Project_State) return String
   is
   begin
      return To_String (State.Display_Name);
   end Display_Name;

   function Display_Name_For_Path
     (Path : String) return String
   is
      Stripped : constant String := Strip_Trailing_Separators (Path);
   begin
      if Stripped'Length = 0 then
         return "";
      end if;

      declare
         Name : constant String := Ada.Directories.Simple_Name (Stripped);
      begin
         if Name'Length = 0 then
            return Stripped;
         else
            return Name;
         end if;
      end;
   exception
      when others =>
         return Strip_Trailing_Separators (Path);
   end Display_Name_For_Path;

   function Open_Project
     (Path : String) return Project_Open_Result
   is
      Result : Project_Open_Result;
   begin
      Result.Root_Path := To_Unbounded_String (Path);
      Result.Display_Name := To_Unbounded_String (Display_Name_For_Path (Path));

      if Path'Length = 0 then
         Result.Status := Project_Open_Invalid_Path;
         Result.Error_Text := To_Unbounded_String ("invalid path");
         return Result;
      end if;

      if not Ada.Directories.Exists (Path) then
         Result.Status := Project_Open_Not_Found;
         Result.Error_Text := To_Unbounded_String ("not found");
         return Result;
      end if;

      if Ada.Directories.Kind (Path) /= Ada.Directories.Directory then
         Result.Status := Project_Open_Not_Directory;
         Result.Error_Text := To_Unbounded_String ("not a directory");
         return Result;
      end if;

      Result.Status := Project_Open_Ok;
      Result.Root_Path := To_Unbounded_String (Ada.Directories.Full_Name (Path));
      Result.Display_Name := To_Unbounded_String
        (Display_Name_For_Path (To_String (Result.Root_Path)));
      Result.Error_Text := Null_Unbounded_String;
      return Result;

   exception
      when Ada.Directories.Name_Error =>
         Result.Status := Project_Open_Invalid_Path;
         Result.Error_Text := To_Unbounded_String ("invalid path");
         return Result;
      when Ada.Directories.Use_Error =>
         Result.Status := Project_Open_Permission_Denied;
         Result.Error_Text := To_Unbounded_String ("permission denied");
         return Result;
      when others =>
         Result.Status := Project_Open_Error;
         Result.Error_Text := To_Unbounded_String ("project open error");
         return Result;
   end Open_Project;

   function Is_Success
     (Result : Project_Open_Result) return Boolean
   is
   begin
      return Result.Status = Project_Open_Ok;
   end Is_Success;

   function Status_Message
     (Result : Project_Open_Result) return String
   is
   begin
      if Length (Result.Error_Text) > 0 then
         return To_String (Result.Error_Text);
      end if;

      case Result.Status is
         when Project_Open_Ok =>
            return "ok";
         when Project_Open_Invalid_Path =>
            return "invalid path";
         when Project_Open_Not_Found =>
            return "not found";
         when Project_Open_Not_Directory =>
            return "not a directory";
         when Project_Open_Permission_Denied =>
            return "permission denied";
         when Project_Open_Error =>
            return "project open error";
      end case;
   end Status_Message;

   procedure Apply_Open_Result
     (State  : in out Project_State;
      Result : Project_Open_Result)
   is
   begin
      if Is_Success (Result) then
         State.Has_Root := True;
         State.Root_Path := Result.Root_Path;
         State.Display_Name := Result.Display_Name;
         State.Known_Files.Clear;
         State.Has_Last_Refresh := False;
         State.Last_Refresh := (others => <>);
      end if;
   end Apply_Open_Result;

   function Is_Under_Project
     (State : Project_State;
      Path  : String) return Boolean
   is
      Root : constant String := Comparable_Path (To_String (State.Root_Path));
      Item : constant String := Comparable_Path (Path);
   begin
      if not State.Has_Root or else Root'Length = 0 or else Item'Length = 0 then
         return False;
      elsif Item = Root then
         return True;
      elsif Root = "/" then
         return Starts_With (Item, "/");
      else
         return Starts_With (Item, Root & "/");
      end if;
   end Is_Under_Project;

   function Relative_Path
     (State : Project_State;
      Path  : String) return String
   is
      Root : constant String := Comparable_Path (To_String (State.Root_Path));
      Item : constant String := Comparable_Path (Path);
   begin
      if not Is_Under_Project (State, Path) then
         return Path;
      elsif Item = Root then
         return ".";
      elsif Root = "/" then
         return Item (Item'First + 1 .. Item'Last);
      else
         return Item (Item'First + Root'Length + 1 .. Item'Last);
      end if;
   end Relative_Path;


   function Normalized_Project_Relative_Path (Path : String) return String is
      Result : String (Path'Range);
   begin
      for I in Path'Range loop
         if Path (I) = '\' then
            Result (I) := '/';
         else
            Result (I) := Path (I);
         end if;
      end loop;
      return Result;
   end Normalized_Project_Relative_Path;

   procedure Clear_Known_Files
     (State : in out Project_State)
   is
   begin
      State.Known_Files.Clear;
      State.Has_Last_Refresh := False;
      State.Last_Refresh := (others => <>);
   end Clear_Known_Files;

   procedure Add_Known_File
     (State         : in out Project_State;
      Relative_Path : String;
      Absolute_Path : String)
   is
      Normalized : constant String := Normalized_Project_Relative_Path (Relative_Path);
      Item      : constant Project_File_Entry :=
        (Relative_Path => To_Unbounded_String (Normalized),
         Absolute_Path => To_Unbounded_String (Absolute_Path));
      Inserted   : Boolean := False;
   begin
      if Normalized'Length = 0 then
         return;
      end if;

      if State.Known_Files.Length > 0 then
         for I in State.Known_Files.First_Index .. State.Known_Files.Last_Index loop
            declare
               Current : constant String :=
                 To_String (State.Known_Files (I).Relative_Path);
            begin
               if Current = Normalized then
                  return;
               elsif not Inserted and then Normalized < Current then
                  State.Known_Files.Insert (I, Item);
                  Inserted := True;
                  exit;
               end if;
            end;
         end loop;
      end if;

      if not Inserted then
         State.Known_Files.Append (Item);
      end if;
   end Add_Known_File;

   function Known_File_Count
     (State : Project_State) return Natural
   is
   begin
      return Natural (State.Known_Files.Length);
   end Known_File_Count;

   function Known_File_At
     (State : Project_State;
      Index : Positive) return Project_File_Entry
   is
   begin
      if Index > Natural (State.Known_Files.Length) then
         return (Relative_Path => Null_Unbounded_String,
                 Absolute_Path => Null_Unbounded_String);
      end if;
      return State.Known_Files (Index - 1);
   end Known_File_At;




   function Has_Known_File
     (State : Project_State;
      Relative_Path : String) return Boolean
   is
      Normalized : constant String := Normalized_Project_Relative_Path (Relative_Path);
   begin
      for I in 1 .. Known_File_Count (State) loop
         if To_String (Known_File_At (State, I).Relative_Path) = Normalized then
            return True;
         end if;
      end loop;
      return False;
   end Has_Known_File;

   function Absolute_Project_File_Path
     (State : Project_State;
      Relative_Path : String) return String
   is
      Root : constant String := Root_Path (State);
      Rel  : constant String := Normalized_Project_Relative_Path (Relative_Path);
   begin
      if Root'Length = 0 then
         return Rel;
      elsif Rel'Length = 0 then
         return Root;
      else
         declare
            Result        : Unbounded_String := To_Unbounded_String (Root);
            Segment_Start : Positive := Rel'First;

            procedure Append_Segment (Segment : String) is
            begin
               if Segment'Length = 0 then
                  return;
               end if;

               Result := To_Unbounded_String
                 (Ada.Directories.Compose (To_String (Result), Segment));
            end Append_Segment;
         begin
            for I in Rel'Range loop
               if Rel (I) = '/' then
                  if I > Segment_Start then
                     Append_Segment (Rel (Segment_Start .. I - 1));
                  end if;
                  Segment_Start := I + 1;
               end if;
            end loop;

            if Segment_Start <= Rel'Last then
               Append_Segment (Rel (Segment_Start .. Rel'Last));
            end if;

            return To_String (Result);
         end;
      end if;
   end Absolute_Project_File_Path;

   type Ignore_Rule_Kind is
     (Ignore_Directory_Prefix,
      Ignore_Literal_Path,
      Ignore_Basename_Suffix);

   type Ignore_Rule is record
      Kind    : Ignore_Rule_Kind := Ignore_Literal_Path;
      Pattern : Unbounded_String;
   end record;

   package Ignore_Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ignore_Rule);

   type Ignore_Load_Result is record
      Ok                    : Boolean := True;
      Rules                 : Ignore_Rule_Vectors.Vector;
      Invalid_Pattern_Count : Natural := 0;
      Failure_Reason        : Unbounded_String;
   end record;

   function Normalize_Project_Pattern (Text : String) return String is
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
   end Normalize_Project_Pattern;

   function Contains_Text (Text : String; Fragment : String) return Boolean is
   begin
      if Fragment'Length = 0 then
         return True;
      elsif Text'Length < Fragment'Length then
         return False;
      end if;

      for I in Text'First .. Text'Last - Fragment'Length + 1 loop
         if Text (I .. I + Fragment'Length - 1) = Fragment then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Text;

   function Basename_Of_Project_Path (Path : String) return String is
      Last_Sep : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' then
            Last_Sep := I;
         end if;
      end loop;

      if Last_Sep = 0 then
         return Path;
      elsif Last_Sep = Path'Last then
         return "";
      else
         return Path (Last_Sep + 1 .. Path'Last);
      end if;
   end Basename_Of_Project_Path;

   function Ends_With
     (Text   : String;
      Suffix : String) return Boolean
   is
   begin
      return Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   procedure Parse_Project_Ignore_Line
     (Line    : String;
      Rules   : in out Ignore_Rule_Vectors.Vector;
      Invalid : in out Natural)
   is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Line, Ada.Strings.Both);
   begin
      if Trimmed'Length = 0 then
         return;
      elsif Trimmed (Trimmed'First) = '#' then
         return;
      end if;

      declare
         Pattern : constant String := Normalize_Project_Pattern (Trimmed);
      begin
         if Pattern'Length = 0
           or else Pattern (Pattern'First) = '!'
           or else Pattern (Pattern'First) = '/'
           or else Contains_Text (Pattern, "**")
           or else Contains_Text (Pattern, "[")
           or else Contains_Text (Pattern, "]")
           or else Contains_Text (Pattern, "{")
           or else Contains_Text (Pattern, "}")
         then
            Invalid := Invalid + 1;
            return;
         end if;

         if Pattern (Pattern'Last) = '/' then
            if Pattern'Length = 1 then
               Invalid := Invalid + 1;
            else
               Rules.Append
                 (Ignore_Rule'
                   (Kind    => Ignore_Directory_Prefix,
                   Pattern => To_Unbounded_String
                     (Pattern (Pattern'First .. Pattern'Last - 1))));
            end if;
         elsif Pattern (Pattern'First) = '*' then
            if Pattern'Length >= 3 and then Pattern (Pattern'First + 1) = '.' then
               declare
                  Suffix : constant String := Pattern (Pattern'First + 1 .. Pattern'Last);
               begin
                  if Contains_Text (Suffix, "*") or else Contains_Text (Suffix, "/") then
                     Invalid := Invalid + 1;
                  else
                     Rules.Append
                 (Ignore_Rule'
                   (Kind    => Ignore_Basename_Suffix,
                         Pattern => To_Unbounded_String (Suffix)));
                  end if;
               end;
            else
               Invalid := Invalid + 1;
            end if;
         elsif Contains_Text (Pattern, "*") then
            Invalid := Invalid + 1;
         else
            Rules.Append
                 (Ignore_Rule'
                   (Kind    => Ignore_Literal_Path,
                Pattern => To_Unbounded_String (Pattern)));
         end if;
      end;
   end Parse_Project_Ignore_Line;

   function Load_Project_Ignore_Rules (Root : String) return Ignore_Load_Result is
      Ignore_Path : constant String := Ada.Directories.Compose (Root, ".projectignore");
      File        : Ada.Text_IO.File_Type;
      Result      : Ignore_Load_Result;
   begin
      if not Ada.Directories.Exists (Ignore_Path) then
         return Result;
      end if;

      Ada.Text_IO.Open
        (File, Ada.Text_IO.In_File, Ignore_Path);

      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : Unbounded_String;
         begin
            Ada.Strings.Unbounded.Text_IO.Get_Line (File, Line);
            Parse_Project_Ignore_Line
              (To_String (Line), Result.Rules, Result.Invalid_Pattern_Count);
         end;
      end loop;

      Ada.Text_IO.Close (File);
      return Result;
   exception
      when others =>
         begin
            if Ada.Text_IO.Is_Open (File) then
               Ada.Text_IO.Close (File);
            end if;
         exception
            when others =>
               null;
         end;
         Result.Ok := False;
         Result.Failure_Reason := To_Unbounded_String ("could not read .projectignore");
         return Result;
   end Load_Project_Ignore_Rules;

   function Path_Is_Under_Directory_Rule
     (Path   : String;
      Prefix : String) return Boolean
   is
   begin
      return Path = Prefix
        or else (Path'Length > Prefix'Length
                 and then Path (Path'First .. Path'First + Prefix'Length - 1) = Prefix
                 and then Path (Path'First + Prefix'Length) = '/');
   end Path_Is_Under_Directory_Rule;

   function Should_Ignore_Project_Path
     (Rules         : Ignore_Rule_Vectors.Vector;
      Relative_Path : String;
      Is_Directory  : Boolean) return Boolean
   is
      Normalized : constant String := Normalize_Project_Pattern (Relative_Path);
      Base       : constant String := Basename_Of_Project_Path (Normalized);
   begin
      for Rule of Rules loop
         declare
            Pattern : constant String := To_String (Rule.Pattern);
         begin
            case Rule.Kind is
               when Ignore_Directory_Prefix =>
                  if Path_Is_Under_Directory_Rule (Normalized, Pattern) then
                     return True;
                  end if;
               when Ignore_Literal_Path =>
                  if Normalized = Pattern
                    or else (Is_Directory and then Path_Is_Under_Directory_Rule (Normalized, Pattern))
                  then
                     return True;
                  end if;
               when Ignore_Basename_Suffix =>
                  if not Is_Directory and then Ends_With (Base, Pattern) then
                     return True;
                  end if;
            end case;
         end;
      end loop;
      return False;
   end Should_Ignore_Project_Path;

   function Is_Excluded_Project_Directory (Name : String) return Boolean is
   begin
      return Name = ".git"
        or else Name = ".hg"
        or else Name = ".svn"
        or else Name = "obj"
        or else Name = "bin"
        or else Name = "build"
        or else Name = "dist"
        or else Name = ".cache"
        or else Name = ".alire"
        or else Name = "node_modules"
        or else Name = "target";
   end Is_Excluded_Project_Directory;

   function Join_Relative_Path
     (Parent : String;
      Name   : String) return String
   is
   begin
      if Parent = "." or else Parent'Length = 0 then
         return Name;
      else
         return Parent & "/" & Name;
      end if;
   end Join_Relative_Path;

   procedure Collect_Project_Files
     (Target                  : in out Project_State;
      Directory_Path          : String;
      Parent_Relative         : String;
      Rules                   : Ignore_Rule_Vectors.Vector;
      Skipped_Directory_Count : in out Natural;
      Ignored_Path_Count      : in out Natural)
   is
      Search          : Ada.Directories.Search_Type;
      Search_Started  : Boolean := False;
   begin
      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Directory_Path,
         Pattern   => "*");
      Search_Started := True;

      while Ada.Directories.More_Entries (Search) loop
         declare
            Dir_Entry : Ada.Directories.Directory_Entry_Type;
         begin
            Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
               Abs_Path  : constant String := Ada.Directories.Compose (Directory_Path, Name);
               Rel  : constant String := Join_Relative_Path (Parent_Relative, Name);
            begin
               if Name /= "." and then Name /= ".." then
                  case Ada.Directories.Kind (Dir_Entry) is
                     when Ada.Directories.Directory =>
                        if Is_Excluded_Project_Directory (Name) then
                           Skipped_Directory_Count := Skipped_Directory_Count + 1;
                        elsif Should_Ignore_Project_Path (Rules, Rel, True) then
                           Ignored_Path_Count := Ignored_Path_Count + 1;
                        else
                           Collect_Project_Files
                             (Target,
                              Abs_Path,
                              Rel,
                              Rules,
                              Skipped_Directory_Count,
                              Ignored_Path_Count);
                        end if;
                     when Ada.Directories.Ordinary_File =>
                        if Should_Ignore_Project_Path (Rules, Rel, False) then
                           Ignored_Path_Count := Ignored_Path_Count + 1;
                        else
                           Add_Known_File (Target, Rel, Abs_Path);
                        end if;
                     when Ada.Directories.Special_File =>
                        null;
                  end case;
               end if;
            end;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
      Search_Started := False;
   exception
      when others =>
         if Search_Started then
            begin
               Ada.Directories.End_Search (Search);
            exception
               when others =>
                  null;
            end;
         end if;
         raise;
   end Collect_Project_Files;

   function Known_File_Relative_Path
     (State : Project_State;
      Index : Positive) return String
   is
   begin
      return To_String (Known_File_At (State, Index).Relative_Path);
   end Known_File_Relative_Path;

   procedure Compute_Refresh_Delta
     (Previous : Project_State;
      Current  : Project_State;
      Result   : in out Project_File_Refresh_Result)
   is
      I : Positive := 1;
      J : Positive := 1;
      Previous_Count : constant Natural := Known_File_Count (Previous);
      Current_Count  : constant Natural := Known_File_Count (Current);
   begin
      Result.Previous_Count := Previous_Count;
      Result.Total_Count := Current_Count;
      while I <= Previous_Count or else J <= Current_Count loop
         if I > Previous_Count then
            Result.Added_Count := Result.Added_Count + (Current_Count - J + 1);
            exit;
         elsif J > Current_Count then
            Result.Removed_Count := Result.Removed_Count + (Previous_Count - I + 1);
            exit;
         else
            declare
               Old_Path : constant String := Known_File_Relative_Path (Previous, I);
               New_Path : constant String := Known_File_Relative_Path (Current, J);
            begin
               if Old_Path = New_Path then
                  Result.Unchanged_Count := Result.Unchanged_Count + 1;
                  I := I + 1;
                  J := J + 1;
               elsif Old_Path < New_Path then
                  Result.Removed_Count := Result.Removed_Count + 1;
                  I := I + 1;
               else
                  Result.Added_Count := Result.Added_Count + 1;
                  J := J + 1;
               end if;
            end;
         end if;
      end loop;
   end Compute_Refresh_Delta;

   procedure Refresh_Known_Files
     (State  : in out Project_State;
      Result : out Project_File_Refresh_Result)
   is
      Previous : Project_State := State;
      Fresh    : Project_State := State;
      Root     : constant String := Root_Path (State);
      Skipped  : Natural := 0;
      Ignored  : Natural := 0;
      Ignore_Load : Ignore_Load_Result;
   begin
      Result := (others => <>);
      if not Has_Project (State) then
         Result.Status := Project_File_Refresh_No_Project;
         Result.Failure_Reason := To_Unbounded_String ("no project");
         return;
      elsif Root'Length = 0 then
         Result.Status := Project_File_Refresh_Invalid_Root;
         Result.Failure_Reason := To_Unbounded_String ("project root unavailable");
         return;
      elsif not Ada.Directories.Exists (Root) then
         Result.Status := Project_File_Refresh_Root_Not_Found;
         Result.Failure_Reason := To_Unbounded_String ("project root unavailable");
         return;
      elsif Ada.Directories.Kind (Root) /= Ada.Directories.Directory then
         Result.Status := Project_File_Refresh_Root_Not_Directory;
         Result.Failure_Reason := To_Unbounded_String ("project root unavailable");
         return;
      end if;

      Ignore_Load := Load_Project_Ignore_Rules (Ada.Directories.Full_Name (Root));
      if not Ignore_Load.Ok then
         Result.Status := Project_File_Refresh_Read_Error;
         Result.Failure_Reason := Ignore_Load.Failure_Reason;
         return;
      end if;

      Fresh.Known_Files.Clear;
      Fresh.Has_Last_Refresh := False;
      Fresh.Last_Refresh := (others => <>);
      Collect_Project_Files
        (Fresh, Ada.Directories.Full_Name (Root), ".", Ignore_Load.Rules, Skipped, Ignored);

      Result.Status := Project_File_Refresh_Ok;
      Result.Skipped_Directory_Count := Skipped;
      Result.Ignored_Path_Count := Ignored;
      Result.Invalid_Ignore_Pattern_Count := Ignore_Load.Invalid_Pattern_Count;
      Compute_Refresh_Delta (Previous, Fresh, Result);

      State.Known_Files := Fresh.Known_Files;
      State.Last_Refresh := Result;
      State.Has_Last_Refresh := True;
   exception
      when Ada.Directories.Use_Error =>
         Result := (others => <>);
         Result.Status := Project_File_Refresh_Permission_Denied;
         Result.Failure_Reason := To_Unbounded_String ("permission denied");
      when Ada.Directories.Name_Error =>
         Result := (others => <>);
         Result.Status := Project_File_Refresh_Invalid_Root;
         Result.Failure_Reason := To_Unbounded_String ("project root unavailable");
      when others =>
         Result := (others => <>);
         Result.Status := Project_File_Refresh_Read_Error;
         Result.Failure_Reason := To_Unbounded_String ("filesystem error");
   end Refresh_Known_Files;

   function Has_Last_Refresh_Summary
     (State : Project_State) return Boolean
   is
   begin
      return State.Has_Last_Refresh;
   end Has_Last_Refresh_Summary;

   function Last_Refresh_Summary
     (State : Project_State) return Project_File_Refresh_Result
   is
   begin
      return State.Last_Refresh;
   end Last_Refresh_Summary;


   function Validate_Project_Create_Path_Rules
     (State : Project_State;
      Relative_Path : String) return Project_Create_Path_Validation_Result
   is
      Root : constant String := Root_Path (State);
      Normalized : constant String := Normalized_Project_Relative_Path (Relative_Path);
      Segment : Unbounded_String := Null_Unbounded_String;
      Ignore_Load : Ignore_Load_Result;
      Result : Project_Create_Path_Validation_Result;
   begin
      if not Has_Project (State) then
         Result.Status := Project_Create_Path_No_Project;
         Result.Failure_Reason := To_Unbounded_String ("no project");
         return Result;
      elsif Root'Length = 0
        or else not Ada.Directories.Exists (Root)
        or else Ada.Directories.Kind (Root) /= Ada.Directories.Directory
      then
         Result.Status := Project_Create_Path_Invalid_Root;
         Result.Failure_Reason := To_Unbounded_String ("project root unavailable");
         return Result;
      end if;

      for Ch of Normalized loop
         if Ch = '/' then
            if Is_Excluded_Project_Directory (To_String (Segment)) then
               Result.Status := Project_Create_Path_Ignored;
               Result.Failure_Reason := To_Unbounded_String ("built-in excluded directory");
               return Result;
            end if;
            Segment := Null_Unbounded_String;
         else
            Append (Segment, Ch);
         end if;
      end loop;

      Ignore_Load := Load_Project_Ignore_Rules (Ada.Directories.Full_Name (Root));
      if not Ignore_Load.Ok then
         Result.Status := Project_Create_Path_Ignore_Read_Error;
         Result.Failure_Reason := Ignore_Load.Failure_Reason;
         return Result;
      end if;

      if Should_Ignore_Project_Path (Ignore_Load.Rules, Normalized, False) then
         Result.Status := Project_Create_Path_Ignored;
         Result.Failure_Reason := To_Unbounded_String ("project ignore rule");
         return Result;
      end if;

      Result.Status := Project_Create_Path_Ok;
      Result.Failure_Reason := Null_Unbounded_String;
      return Result;
   exception
      when Ada.Directories.Use_Error =>
         Result.Status := Project_Create_Path_Invalid_Root;
         Result.Failure_Reason := To_Unbounded_String ("project root unavailable");
         return Result;
      when others =>
         Result.Status := Project_Create_Path_Ignore_Read_Error;
         Result.Failure_Reason := To_Unbounded_String ("could not read .projectignore");
         return Result;
   end Validate_Project_Create_Path_Rules;

end Editor.Project;
