with Ada.Directories;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor.History;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Messages;
with Editor.Navigation; use Editor.Navigation;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Recent_Buffers;
with Editor.Render_Cache;
with Editor.State;
with Editor.UTF8;

package body Editor.Executor.Project_Search_Replace_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Project_Search.Project_Replace_Preview_Status;
   use type Editor.Project_Search.Project_Search_Result_Id;
   use type Ada.Directories.File_Kind;
   use type Ada.Containers.Count_Type;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Success;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Report_Warning;

   function Image_Of (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image_Of;

   procedure Show_Search_Results_Panel
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Search_Results_Content);
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, True);
      if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Show_Search_Results_Panel;

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Command;
      Pos          : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String) is
   begin
      Cmd.Positions.Append (Pos);
      Cmd.Delete_Counts.Append (Delete_Count);
      Cmd.Insert_Texts.Append (Insert_Text);
   end Append_Replace_Op;

   function Mark_Dirty_Open_Project_Replace_Targets_Stale
     (S : in out Editor.State.State_Type) return Natural
   is
      Row   : Editor.Project_Search.Project_Replace_Preview_Row;
      Count : Natural := 0;
   begin
      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
         if Row.Search_Result_Id /= Editor.Project_Search.No_Project_Search_Result
           and then not Row.Stale
           and then not Row.Invalid
           and then Editor.Buffers.Global_File_Is_Dirty
             (To_String (Row.Absolute_Path))
         then
            Editor.Project_Search.Mark_Replace_Preview_Stale_For_Absolute_File
              (S.Project_Search, To_String (Row.Absolute_Path));
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Mark_Dirty_Open_Project_Replace_Targets_Stale;

   function Project_Search_Replace_Pending_Blocked
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions);
   end Project_Search_Replace_Pending_Blocked;

   procedure Report_Project_Search_Replace_Pending_Blocked
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Warning (S, "Command unavailable while confirmation is pending");
      Editor.Render_Cache.Invalidate_All;
   end Report_Project_Search_Replace_Pending_Blocked;

   procedure Execute_Project_Search_Replace_Preview
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Project_Search.Project_Replace_Preview_Status;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Project_Search_Replace_Pending_Blocked (S);
         return;
      end if;

      Editor.Project_Search.Generate_Replace_Preview (S.Project_Search, Status);
      if Status = Editor.Project_Search.Project_Replace_Preview_Ok
        and then Mark_Dirty_Open_Project_Replace_Targets_Stale (S) > 0
      then
         --  Project Search currently scans file text from the project file
         --  system.  If a target file is already open and dirty, replacement
         --  preview rows for that file are not based on the current buffer
         --  text and must fail before inclusion/apply can treat them as a
         --  valid edit script.
         Status := Editor.Project_Search.Project_Replace_Search_Stale;
      end if;
      Show_Search_Results_Panel (S);
      case Status is
         when Editor.Project_Search.Project_Replace_Preview_Ok =>
            Report_Info
              (S, "Preview: "
               & Natural'Image (Editor.Project_Search.Included_Replacement_Count (S.Project_Search))
               & " replacements in"
               & Natural'Image (Editor.Project_Search.Included_Replacement_File_Count (S.Project_Search))
               & " files.");
         when Editor.Project_Search.Project_Replace_No_Search_Results =>
            Report_Info (S, "No search results to replace.");
         when Editor.Project_Search.Project_Replace_Search_Stale =>
            Report_Warning (S, "Search results are stale; rerun search.");
         when Editor.Project_Search.Project_Replace_Overlapping_Matches =>
            Report_Warning (S, "Replacement preview has overlapping matches; refine search.");
         when Editor.Project_Search.Project_Replace_Invalid_Replacement_Text =>
            Report_Warning (S, "Replacement text must be single-line.");
         when Editor.Project_Search.Project_Replace_Invalid_Target =>
            Report_Warning (S, "Replacement preview contains invalid target ranges; rerun search.");
         when others =>
            Report_Warning (S, "Replacement preview unavailable.");
      end case;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Preview;

   procedure Execute_Project_Search_Replace_Toggle_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Toggle_Selected_Replacement (S.Project_Search);
               Report_Info (S, "Replacement selection toggled");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Toggle_Selected;

   procedure Execute_Project_Search_Replace_Include_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Include_Selected_Replacement (S.Project_Search);
               Report_Info (S, "Replacement included");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_Selected;

   procedure Execute_Project_Search_Replace_Exclude_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Exclude_Selected_Replacement (S.Project_Search);
               Report_Info (S, "Replacement excluded");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_Selected;

   procedure Execute_Project_Search_Replace_Include_File
     (S : in out Editor.State.State_Type)
   is
      Index : constant Natural :=
        Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Index = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, Index);
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Include_File_Replacements
                 (S.Project_Search, To_String (Row.Relative_Path));
               Report_Info (S, "Replacement file included");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_File;

   procedure Execute_Project_Search_Replace_Exclude_File
     (S : in out Editor.State.State_Type)
   is
      Index : constant Natural :=
        Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Index = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, Index);
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Exclude_File_Replacements
                 (S.Project_Search, To_String (Row.Relative_Path));
               Report_Info (S, "Replacement file excluded");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_File;

   procedure Execute_Project_Search_Replace_Include_All
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Eligible_Replacement_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No eligible replacements");
      else
         Editor.Project_Search.Include_All_Replacements (S.Project_Search);
         Report_Info (S, "All eligible replacement preview rows included");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_All;

   procedure Execute_Project_Search_Replace_Exclude_All
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      else
         Editor.Project_Search.Exclude_All_Replacements (S.Project_Search);
         Report_Info (S, "All replacement preview rows excluded");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_All;

   procedure Focus_Project_Replace_Target_File
     (S      : in out Editor.State.State_Type;
      Path   : String;
      Opened : out Boolean)
   is
      Result : Editor.Files.File_Open_Result;
      Found  : Boolean := False;
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;

      function Same_File_Path (Left, Right : String) return Boolean is
      begin
         return Left = Right
           or else Editor.Files.Canonical_Path_For_Existing_File (Left) =
             Editor.Files.Canonical_Path_For_Existing_File (Right);
      end Same_File_Path;

      function Current_State_Is_Disposable_Initial_Untitled return Boolean is
      begin
         return Editor.Buffers.Global_Count = 0
           and then not S.File_Info.Has_Path
           and then not S.File_Info.Dirty
           and then Editor.State.Current_Text (S) = "";
      end Current_State_Is_Disposable_Initial_Untitled;
   begin
      Opened := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if S.File_Info.Has_Path
        and then Same_File_Path (To_String (S.File_Info.Path), Path)
      then
         Opened := True;
         return;
      end if;

      Id := Editor.Buffers.Global_Find_By_Path (Path, Found);
      if Found then
         Editor.Buffers.Global_Set_Active_Buffer (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
         Opened := S.File_Info.Has_Path
           and then Same_File_Path (To_String (S.File_Info.Path), Path);
         return;
      end if;

      Result := Editor.Files.Open_File (Path);
      if not Editor.Files.Is_Success (Result) then
         return;
      end if;

      --  Replacement apply is the primary command outcome.  Loading a closed
      --  target file must therefore use the same buffer/file lifecycle model
      --  as explicit open, but without posting an additional "Opened ..."
      --  status message before the replacement summary.
      if not Current_State_Is_Disposable_Initial_Untitled then
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      Id := Editor.Buffers.Global_Find_By_Path (To_String (Result.Path), Found);
      if Found then
         Editor.Buffers.Global_Set_Active_Buffer (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
      else
         Editor.Buffers.Global_Add_File_Buffer
           (Path         => To_String (Result.Path),
            Display_Name => To_String (Result.Display_Name),
            Contents     => To_String (Result.Contents),
            New_Id       => Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Editor.Recent_Buffers.Mark_Activated (S.Recent_Buffers, Natural (Id));
      end if;

      Opened := S.File_Info.Has_Path
        and then Same_File_Path (To_String (S.File_Info.Path), Path);
   end Focus_Project_Replace_Target_File;

   procedure Apply_Project_Search_Replacements_For_File
     (S             : in out Editor.State.State_Type;
      Relative_Path : String;
      Selected_Only    : Boolean;
      Selected_Id      : Editor.Project_Search.Project_Search_Result_Id;
      Changed          : out Boolean;
      Replaced      : out Natural;
      Failed        : out Boolean;
      Failure_Message : out Unbounded_String;
      Preserve_Project_Search_Preview : Boolean := False)
   is
      Before      : Editor.State.State_Type;
      Before_Text : Unbounded_String := Null_Unbounded_String;
      Project_Search_Before_Edit : Editor.Project_Search.Project_Search_State;
      Cmd         : Editor.Commands.Command;
      Row         : Editor.Project_Search.Project_Replace_Preview_Row;
      Path        : Unbounded_String := Null_Unbounded_String;
      Pos         : Natural := 0;
      Del         : Natural := 0;
      Current     : Unbounded_String := Null_Unbounded_String;
      Replacement : constant Unbounded_String :=
        To_Unbounded_String
          (Editor.Project_Search.Replace_Text (S.Project_Search));
      Candidate_Count : Natural := 0;
      Path_Mismatch    : Boolean := False;

      function Same_Target_Path (Left, Right : String) return Boolean is
      begin
         return Left = Right
           or else Editor.Files.Canonical_Path_For_Existing_File (Left) =
             Editor.Files.Canonical_Path_For_Existing_File (Right);
      end Same_Target_Path;

      function Row_Is_Candidate
        (R : Editor.Project_Search.Project_Replace_Preview_Row) return Boolean
      is
      begin
         return R.Included
           and then not R.Stale
           and then not R.Invalid
           and then To_String (R.Relative_Path) = Relative_Path
           and then ((not Selected_Only) or else R.Search_Result_Id = Selected_Id);
      end Row_Is_Candidate;

      function Current_Line_Text
        (Target_Row : Natural) return String
      is
         Start_Pos : Natural := 0;
         Len       : Natural := 0;
      begin
         if Target_Row >= Editor.State.Line_Count (S) then
            return "";
         end if;

         Start_Pos := Index_For_Line_Column (S, Target_Row, 0);
         Len := Line_Length (S, Target_Row);
         return To_String (Extract_Text (S.Buffer, Start_Pos, Len));
      end Current_Line_Text;

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

         Next_Index := Line'First + Byte_Offset;
         Next_Byte := Character'Pos (Line (Next_Index));
         return not (Next_Byte in 16#80# .. 16#BF#);
      end Is_UTF8_Boundary;

      function Code_Point_Column_For_Byte_Offset
        (Line        : String;
         Byte_Offset : Natural;
         Valid       : out Boolean) return Natural
      is
         Last_Byte : Natural := 0;
      begin
         Valid := Byte_Offset <= Line'Length
           and then Is_UTF8_Boundary (Line, Byte_Offset);
         if not Valid or else Byte_Offset = 0 then
            return 0;
         end if;

         Last_Byte := Line'First + Byte_Offset - 1;
         return Editor.UTF8.Code_Point_Count
           (Line (Line'First .. Last_Byte));
      end Code_Point_Column_For_Byte_Offset;
   begin
      Changed := False;
      Replaced := 0;
      Failed := False;
      Failure_Message := Null_Unbounded_String;
      Cmd.Kind := Apply_Replace_Batch;

      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
         if Row_Is_Candidate (Row) then
            Candidate_Count := Candidate_Count + 1;
            if Length (Path) = 0 then
               Path := Row.Absolute_Path;
            elsif not Same_Target_Path (To_String (Path), To_String (Row.Absolute_Path)) then
               --  A replacement transaction is keyed by a project-relative
               --  file group, but mutation opens exactly one absolute file.
               --  If stale or malformed preview rows disagree about the
               --  backing absolute path, fail the whole file group instead
               --  of applying some rows to a different buffer than the row
               --  describes.
               Path_Mismatch := True;
            end if;
         end if;
      end loop;

      if not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Failed := True;
         Failure_Message := To_Unbounded_String ("Replacement text must be single-line.");
         return;
      elsif Candidate_Count = 0 then
         return;
      elsif Length (Path) = 0 or else Path_Mismatch then
         Failed := True;
         Failure_Message := To_Unbounded_String ("Replacement target changed; rerun search.");
         return;
      elsif not Editor.Project.Has_Project (S.Project)
        or else not Editor.Project.Is_Under_Project (S.Project, To_String (Path))
      then
         Failed := True;
         Failure_Message := To_Unbounded_String ("Replacement target is outside project.");
         return;
      end if;

      begin
         if not Ada.Directories.Exists (To_String (Path)) then
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target no longer exists.");
            return;
         elsif Ada.Directories.Kind (To_String (Path)) /= Ada.Directories.Ordinary_File then
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target is not a regular file.");
            return;
         elsif not Editor.Files.Existing_File_Is_Writable (To_String (Path)) then
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target is read-only.");
            return;
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target path is invalid.");
            return;
         when Ada.Directories.Use_Error =>
            Failed := True;
            Failure_Message := To_Unbounded_String ("Replacement target is unavailable.");
            return;
      end;

      if Editor.Buffers.Global_File_Is_Dirty (To_String (Path)) then
         --  Project Search replacement rows are generated from the retained
         --  search result text.  If an already-open target buffer is dirty at
         --  apply time, the preview is no longer a valid edit script for the
         --  current in-memory file.  Fail before focusing/mutating the buffer
         --  rather than relying on later text-span validation or accidentally
         --  editing unsaved user changes.
         Failed := True;
         Failure_Message := To_Unbounded_String ("Search result is stale; rerun search.");
         return;
      end if;

      declare
         Target_Opened : Boolean := False;
      begin
         Focus_Project_Replace_Target_File (S, To_String (Path), Target_Opened);
         if not Target_Opened then
            Failed := True;
            Failure_Message := To_Unbounded_String ("Could not open file for replacement.");
            return;
         end if;
      end;

      --  Validate every candidate before applying any mutation to this file.
      --  This preserves the per-file transaction boundary: stale offsets or
      --  mismatched current text fail the whole file without partial edits.
      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
         if Row_Is_Candidate (Row) then
            if Row.Row = 0 or else Row.End_Column < Row.Start_Column then
               Failed := True;
               Failure_Message := To_Unbounded_String ("Search result is stale; rerun search.");
               return;
            end if;

            declare
               Line_Text : constant String := Current_Line_Text (Row.Row - 1);
               Start_OK  : Boolean := False;
               End_OK    : Boolean := False;
               Start_CP  : constant Natural :=
                 Code_Point_Column_For_Byte_Offset
                   (Line_Text, Row.Start_Column, Start_OK);
               End_CP    : constant Natural :=
                 Code_Point_Column_For_Byte_Offset
                   (Line_Text, Row.End_Column, End_OK);
            begin
               if not Start_OK or else not End_OK or else End_CP < Start_CP then
                  Failed := True;
                  Failure_Message := To_Unbounded_String ("Search result is stale; rerun search.");
                  return;
               end if;

               Pos := Index_For_Line_Column (S, Row.Row - 1, Start_CP);
               Del := End_CP - Start_CP;
               Current := Extract_Text (S.Buffer, Pos, Del);
               if To_String (Current) /= To_String (Row.Match_Text) then
                  Failed := True;
                  Failure_Message := To_Unbounded_String ("Search result is stale; rerun search.");
                  return;
               end if;

               if To_String (Current) /= To_String (Replacement) then
                  Append_Replace_Op (Cmd, Cursor_Index (Pos), Del, Replacement);
               end if;
            end;
         end if;
      end loop;

      if Cmd.Positions.Length = 0 then
         return;
      end if;

      Before := S;
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      if Preserve_Project_Search_Preview then
         Project_Search_Before_Edit := S.Project_Search;
      end if;
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Cmd);
      if Preserve_Project_Search_Preview then
         S.Project_Search := Project_Search_Before_Edit;
      end if;
      if Editor.State.Current_Text (S) /= To_String (Before_Text) then
         Editor.Executor.History.Log_Edit (Before, S, Cmd);
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Changed := True;
         Replaced := Natural (Cmd.Positions.Length);
      end if;
   end Apply_Project_Search_Replacements_For_File;

   procedure Execute_Project_Search_Replace_Selected
     (S : in out Editor.State.State_Type)
   is
      Index : constant Natural :=
        Editor.Project_Search.Selected_Replace_Preview_Index (S.Project_Search);
      Row : Editor.Project_Search.Project_Replace_Preview_Row;
      Changed  : Boolean := False;
      Failed   : Boolean := False;
      Replaced : Natural := 0;
      Failure_Message : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Project_Search_Replace_Pending_Blocked (S);
         return;
      end if;

      if Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0
        or else Index = 0
      then
         Report_Warning (S, "No replacement selected");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, Positive'Max (1, Index));
      if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
         Report_Warning (S, "No replacement selected");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Row.Stale then
         Report_Warning (S, "Selected replacement is stale");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Row.Invalid then
         Report_Warning (S, "Selected replacement is invalid");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Row.Included then
         Report_Warning (S, "Selected replacement is excluded");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Apply_Project_Search_Replacements_For_File
        (S             => S,
         Relative_Path => To_String (Row.Relative_Path),
         Selected_Only    => True,
         Selected_Id      => Row.Search_Result_Id,
         Changed          => Changed,
         Replaced      => Replaced,
         Failed        => Failed,
         Failure_Message => Failure_Message);

      if Failed then
         Editor.Project_Search.Mark_Replace_Preview_Stale_For_File
           (S.Project_Search, To_String (Row.Relative_Path));
         if Length (Failure_Message) > 0 then
            Report_Warning (S, To_String (Failure_Message));
         else
            Report_Warning (S, "Project replacement failed.");
         end if;
      elsif Changed then
         Editor.Project_Search.Mark_Replace_Preview_Stale_For_File
           (S.Project_Search, To_String (Row.Relative_Path));
         Report_Success (S, "Replaced selected project match");
      else
         Report_Info (S, "Selected replacement made no text change");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Selected;

   procedure Execute_Project_Search_Replace_All_Included
     (S : in out Editor.State.State_Type)
   is
      Row             : Editor.Project_Search.Project_Replace_Preview_Row;
      Changed         : Boolean := False;
      File_Failed     : Boolean := False;
      File_Replaced   : Natural := 0;
      File_Failure_Message : Unbounded_String := Null_Unbounded_String;
      Last_Failure_Message : Unbounded_String := Null_Unbounded_String;
      Total_Replaced  : Natural := 0;
      Changed_Files   : Natural := 0;
      Failed_Files    : Natural := 0;
      Candidate_Files : Natural := 0;

      function Eligible_Apply_Row
        (R : Editor.Project_Search.Project_Replace_Preview_Row) return Boolean
      is
      begin
         return R.Included and then not R.Stale and then not R.Invalid;
      end Eligible_Apply_Row;

      function Path_Seen_Before
        (Limit : Positive;
         Path  : String) return Boolean
      is
         Prior : Editor.Project_Search.Project_Replace_Preview_Row;
      begin
         if Limit = 1 then
            return False;
         end if;

         for J in 1 .. Limit - 1 loop
            Prior := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, J);
            if Eligible_Apply_Row (Prior)
              and then To_String (Prior.Relative_Path) = Path
            then
               return True;
            end if;
         end loop;
         return False;
      end Path_Seen_Before;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Project_Search_Replace_Pending_Blocked (S);
         return;
      elsif Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Included_Replacement_Count (S.Project_Search) = 0 then
         Report_Info (S, "No included replacements");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Included_Replacements_Overlap (S.Project_Search) then
         Report_Warning (S, "Replacement preview has overlapping matches; refine search.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      ------------------------------------------------------------------
      -- Snapshot the file set before any mutation.
      --
      -- Applying one file may focus another buffer and may mark rows stale
      -- after a failed or successful mutation.  Replace-all must still be a
      -- deterministic operation over the explicitly included fresh candidate
      -- set that existed at command start, not over a live row list whose
      -- global stale flag changes during the same command.
      ------------------------------------------------------------------
      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
         if Eligible_Apply_Row (Row)
           and then not Path_Seen_Before (I, To_String (Row.Relative_Path))
         then
            Candidate_Files := Candidate_Files + 1;
         end if;
      end loop;

      if Candidate_Files = 0 then
         Report_Info (S, "No included replacements");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      declare
         type Path_Array is array (Positive range <>) of Unbounded_String;
         Paths : Path_Array (1 .. Candidate_Files);
         Next  : Natural := 0;
      begin
         for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Project_Search) loop
            Row := Editor.Project_Search.Replace_Preview_Row_At (S.Project_Search, I);
            if Eligible_Apply_Row (Row)
              and then not Path_Seen_Before (I, To_String (Row.Relative_Path))
            then
               Next := Next + 1;
               Paths (Next) := Row.Relative_Path;
            end if;
         end loop;

         for I in Paths'Range loop
            Apply_Project_Search_Replacements_For_File
              (S             => S,
               Relative_Path => To_String (Paths (I)),
               Selected_Only => False,
               Selected_Id   => Editor.Project_Search.No_Project_Search_Result,
               Changed       => Changed,
               Replaced      => File_Replaced,
               Failed        => File_Failed,
               Failure_Message => File_Failure_Message,
               Preserve_Project_Search_Preview => True);

            if File_Failed then
               Failed_Files := Failed_Files + 1;
               if Length (File_Failure_Message) > 0 then
                  Last_Failure_Message := File_Failure_Message;
               end if;
               Editor.Project_Search.Mark_Replace_Preview_Stale_For_File
                 (S.Project_Search, To_String (Paths (I)));
            elsif Changed then
               Changed_Files := Changed_Files + 1;
               Total_Replaced := Total_Replaced + File_Replaced;
            end if;
         end loop;
      end;

      if Changed_Files > 0 then
         Editor.Project_Search.Mark_Replace_Preview_Stale (S.Project_Search);
      end if;

      if Failed_Files > 0 and then Changed_Files > 0 then
         Report_Warning
           (S,
            "Replaced " & Image_Of (Total_Replaced) & " matches in"
            & Image_Of (Changed_Files) & " files;"
            & Image_Of (Failed_Files) & " files failed.");
      elsif Failed_Files > 0 then
         if Failed_Files = 1 and then Length (Last_Failure_Message) > 0 then
            Report_Warning (S, To_String (Last_Failure_Message));
         else
            Report_Warning (S, "Some replacements failed.");
         end if;
      elsif Total_Replaced = 0 then
         Report_Info (S, "Included replacements made no text changes");
      else
         Report_Success
           (S,
            "Replaced " & Image_Of (Total_Replaced) & " matches in"
            & Image_Of (Changed_Files) & " files");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_All_Included;

   procedure Execute_Project_Search_Replace_Clear_Preview
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Clear_Replace_Preview (S.Project_Search);
      Report_Info (S, "Replacement preview cleared");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Clear_Preview;

end Editor.Executor.Project_Search_Replace_Commands;
