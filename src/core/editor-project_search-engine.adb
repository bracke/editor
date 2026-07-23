with Ada.Characters.Handling;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada_Regexp;
with Editor.Files;
with Editor.Project;
with Editor.Project_Search.Utilities; use Editor.Project_Search.Utilities;

package body Editor.Project_Search.Engine is

   use type Ada.Directories.File_Kind;
   use type Ada_Regexp.Regexp_Status;
   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Files.File_Open_Status;

   procedure Append_Result
     (State        : in out Project_Search_State;
      Node         : Editor.File_Tree.File_Tree_Node_Summary;
      Row          : Natural;
      Start_Col    : Natural;
      End_Col      : Natural;
      Line         : String;
      Query_Length : Natural;
      Options      : Project_Search_Options;
      File_Count   : in out Natural)
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

end Editor.Project_Search.Engine;
