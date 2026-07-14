with Ada.Characters.Handling;
with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.IO_Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Ada_Language_Model;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Build_Candidates;
with Editor.Build_UI;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Feature_Diagnostics;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.File_Tree.File_Tree_Node_Kind;
use type Editor.File_Tree.File_Tree_Scan_Status;
with Editor.File_Tree_View;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Outline;
with Editor.Project;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Render_Cache;
with Editor.State;
with Editor.Syntax_Semantics;

package body Editor.Executor.File_Tree_Mutation_Commands is

   function File_Tree_Input_Text
     (Cmd : Editor.Commands.Command) return String
   is
   begin
      --  File Tree project-explorer commands consume only explicit prompt text.
      --  Path payloads are deliberately ignored so Command Palette entries and
      --  keybindings cannot smuggle filesystem targets into create/rename/delete.
      --  The explicit text is normalized at the command boundary so whitespace-
      --  only prompts are rejected as empty names and confirmations tolerate
      --  ordinary prompt padding without changing the accepted tokens.
      return Ada.Strings.Fixed.Trim (To_String (Cmd.Text), Ada.Strings.Both);
   end File_Tree_Input_Text;

   function Contains_Parent_Traversal (Value : String) return Boolean is
      Segment : Unbounded_String := Null_Unbounded_String;

      procedure Check_Segment (Found : in out Boolean) is
      begin
         if To_String (Segment) = ".." then
            Found := True;
         end if;
         Segment := Null_Unbounded_String;
      end Check_Segment;

      Found : Boolean := False;
   begin
      for Ch of Value loop
         if Ch = '/' or else Ch = Character'Val (16#5C#) then
            Check_Segment (Found);
            exit when Found;
         else
            Append (Segment, Ch);
         end if;
      end loop;
      if not Found then
         Check_Segment (Found);
      end if;
      return Found;
   end Contains_Parent_Traversal;

   function Contains_Current_Directory_Segment (Value : String) return Boolean is
      Segment : Unbounded_String := Null_Unbounded_String;

      procedure Check_Segment (Found : in out Boolean) is
      begin
         if To_String (Segment) = "." then
            Found := True;
         end if;
         Segment := Null_Unbounded_String;
      end Check_Segment;

      Found : Boolean := False;
   begin
      --  completeness: File Tree create/rename targets are explicit
      --  user-facing names, not shell paths.  Reject no-op current-directory
      --  segments so prompts such as ".", "./file", or "src/./file" do
      --  not reach filesystem mutation or produce misleading already-exists
      --  messages.  Parent traversal remains rejected separately.
      for Ch of Value loop
         if Ch = '/' or else Ch = Character'Val (16#5C#) then
            Check_Segment (Found);
            exit when Found;
         else
            Append (Segment, Ch);
         end if;
      end loop;
      if not Found then
         Check_Segment (Found);
      end if;
      return Found;
   end Contains_Current_Directory_Segment;



   function Contains_Control_File_Tree_Input_Character
     (Value : String) return Boolean
   is
   begin
      --  completeness: project-explorer names are prompt text, not
      --  raw byte payloads.  Reject ASCII control characters before filesystem
      --  mutation so embedded newlines, tabs, or NUL-like characters cannot
      --  become host filenames or confusing command messages.
      for Ch of Value loop
         if Character'Pos (Ch) < 32 or else Character'Pos (Ch) = 127 then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Control_File_Tree_Input_Character;



   function Strip_Trailing_File_Tree_Path_Separators
     (Value : String) return String;

   function Is_Absolute_Path (Path : String) return Boolean;

   function Contains_Empty_Relative_Path_Segment (Value : String) return Boolean is
      Effective : constant String :=
        Strip_Trailing_File_Tree_Path_Separators (Value);
      Previous_Was_Separator : Boolean := False;
      Saw_Separator          : Boolean := False;
   begin
      --  completeness: project-explorer prompts are explicit names
      --  or simple project-relative paths, not shell-normalized path strings.
      --  Reject empty relative path components such as "src//file" or
      --  "src\\\\file" before filesystem mutation so they cannot be silently
      --  normalized by the host runtime or produce misleading target paths.
      --  Absolute paths are left to the canonical project-boundary check so
      --  outside-root absolutes still report the boundary failure.
      if Effective'Length = 0
        or else Is_Absolute_Path (Effective)
      then
         return False;
      end if;

      for Ch of Effective loop
         if Ch = '/' or else Ch = Character'Val (16#5C#) then
            if not Saw_Separator then
               Saw_Separator := True;
            end if;
            if Previous_Was_Separator then
               return True;
            end if;
            Previous_Was_Separator := True;
         else
            Previous_Was_Separator := False;
         end if;
      end loop;

      return False;
   end Contains_Empty_Relative_Path_Segment;

   function Has_Trailing_Path_Separator (Value : String) return Boolean is
   begin
      return Value'Length > 0
        and then (Value (Value'Last) = '/'
                  or else Value (Value'Last) = Character'Val (16#5C#));
   end Has_Trailing_Path_Separator;

   function Strip_Trailing_File_Tree_Path_Separators
     (Value : String) return String
   is
      Last : Integer := Value'Last;
   begin
      if Value'Length = 0 then
         return Value;
      end if;

      while Last > Value'First
        and then (Value (Last) = '/'
                  or else Value (Last) = Character'Val (16#5C#))
      loop
         Last := Last - 1;
      end loop;

      return Value (Value'First .. Last);
   end Strip_Trailing_File_Tree_Path_Separators;

   function Is_Absolute_Path (Path : String) return Boolean is
   begin
      return Path'Length > 0
        and then (Path (Path'First) = '/'
                  or else (Path'Length >= 3
                           and then Path (Path'First + 1) = ':'
                           and then (Path (Path'First + 2) = '/'
                                     or else Path (Path'First + 2) = Character'Val (16#5C#))));
   end Is_Absolute_Path;

   function Normalize_File_Tree_Input_Separators
     (Value : String) return String
   is
      Result : String (Value'Range);
   begin
      --  completeness: prompt paths are project-relative editor
      --  paths, not host-shell payloads.  Treat both supported prompt
      --  separators consistently before composing with the project root or a
      --  selected directory so an input such as "src\helper.adb" cannot be
      --  interpreted as a single root-level filename on hosts where backslash
      --  is not a directory separator.
      for I in Value'Range loop
         if Value (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         else
            Result (I) := Value (I);
         end if;
      end loop;
      return Result;
   end Normalize_File_Tree_Input_Separators;

   function Selected_File_Tree_Base_Directory
     (S     : Editor.State.State_Type;
      Found : out Boolean) return String
   is
      Node_Id : constant Editor.File_Tree.File_Tree_Node_Id :=
        Editor.Executor.Selected_File_Tree_Node (S, Found);
      Summary : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if not Found then
         --  No selected File Tree row is not the same as selecting the project
         --  root.  Callers may still use the root as the composition base for
         --  an explicit project-relative target such as "src/new.adb", but a
         --  bare name must report "No target directory selected" instead of
         --  silently creating at the root.
         if Editor.Project.Has_Project (S.Project) then
            return Editor.Project.Root_Path (S.Project);
         end if;
         return "";
      end if;

      Summary := Editor.File_Tree.Node (S.File_Tree, Node_Id);
      if Summary.Kind = Editor.File_Tree.Directory_Node then
         return To_String (Summary.Absolute_Path);
      else
         --  completeness: a selected file is not a selected target
         --  directory.  Bare create input must therefore fail with
         --  "No target directory selected" rather than silently creating a
         --  sibling next to the selected file.  Explicit project-relative
         --  input remains valid because Build_File_Tree_Target_Path composes
         --  such paths from the project root and ignores this base value.
         Found := False;
         if Editor.Project.Has_Project (S.Project) then
            return Editor.Project.Root_Path (S.Project);
         else
            return "";
         end if;
      end if;
   end Selected_File_Tree_Base_Directory;

   function Build_File_Tree_Target_Path
     (S     : Editor.State.State_Type;
      Input : String;
      Base  : String) return String
   is
      Effective : constant String :=
        Normalize_File_Tree_Input_Separators
          (Strip_Trailing_File_Tree_Path_Separators (Input));
   begin
      if Effective'Length = 0 then
         return "";
      elsif Is_Absolute_Path (Effective) then
         return Effective;
      elsif Ada.Strings.Fixed.Index (Effective, "/") /= 0
        or else Ada.Strings.Fixed.Index (Effective, "\") /= 0
      then
         return Editor.Project.Absolute_Project_File_Path (S.Project, Effective);
      else
         return Ada.Directories.Compose (Base, Effective);
      end if;
   end Build_File_Tree_Target_Path;



   function Is_Windows_Drive_Qualified_File_Tree_Input
     (Value : String) return Boolean
   is
      First : constant Integer := Value'First;

      function Is_Ascii_Letter (Ch : Character) return Boolean is
      begin
         return (Ch >= 'A' and then Ch <= 'Z')
           or else (Ch >= 'a' and then Ch <= 'z');
      end Is_Ascii_Letter;
   begin
      --  completeness: prompt text is project-relative editor
      --  input, not host-shell path text.  Reject Windows drive-qualified
      --  strings before target composition on every host.  Drive-rooted
      --  forms such as "C:/tmp/file" are absolute.  Drive-relative forms
      --  such as "C:tmp/file" are not portable project-relative paths and
      --  must not become filenames containing a colon under the project root.
      return Value'Length >= 2
        and then Is_Ascii_Letter (Value (First))
        and then Value (First + 1) = ':';
   end Is_Windows_Drive_Qualified_File_Tree_Input;

   function Is_Windows_Drive_Absolute_File_Tree_Input
     (Value : String) return Boolean
   is
      First : constant Integer := Value'First;
   begin
      return Is_Windows_Drive_Qualified_File_Tree_Input (Value)
        and then Value'Length >= 3
        and then (Value (First + 2) = '/'
                  or else Value (First + 2) = Character'Val (16#5C#));
   end Is_Windows_Drive_Absolute_File_Tree_Input;

   function File_Tree_Input_Is_Absolute
     (Input : String) return Boolean
   is
      Raw       : constant String :=
        Strip_Trailing_File_Tree_Path_Separators (Input);
      Effective : constant String :=
        Normalize_File_Tree_Input_Separators (Raw);
   begin
      return Effective'Length > 0
        and then (Is_Absolute_Path (Effective)
                  or else Is_Windows_Drive_Qualified_File_Tree_Input (Raw)
                  or else Is_Windows_Drive_Absolute_File_Tree_Input (Input));
   end File_Tree_Input_Is_Absolute;

   function Absolute_File_Tree_Input_Message
     (S     : Editor.State.State_Type;
      Input : String) return String
   is
      pragma Unreferenced (S, Input);
   begin
      --  completeness: create-file/create-directory input is an
      --  editor project-relative path, not a raw filesystem payload.  Guided
      --  prompt validation is intentionally side-effect-free and cannot safely
      --  probe whether an absolute host path happens to sit inside the active
      --  project.  Keep direct Executor revalidation aligned with that input
      --  model: any absolute or drive-qualified create target is rejected as
      --  non project-relative before path composition or mutation.
      return "Target path must be project-relative";
   end Absolute_File_Tree_Input_Message;

   function File_Tree_Input_Has_Explicit_Directory
     (Input : String) return Boolean
   is
      Effective : constant String :=
        Normalize_File_Tree_Input_Separators
          (Strip_Trailing_File_Tree_Path_Separators (Input));
   begin
      --  A trailing separator by itself does not make a bare name an explicit
      --  project-relative path.  With no selected directory, "newdir/" must
      --  not silently target the project root; "src/newdir/" remains an
      --  explicit project-relative path.
      return Effective'Length > 0
        and then (Is_Absolute_Path (Effective)
                  or else Ada.Strings.Fixed.Index (Effective, "/") /= 0
                  or else Ada.Strings.Fixed.Index (Effective, "\") /= 0);
   end File_Tree_Input_Has_Explicit_Directory;

   function Project_Bounded_File_Tree_Target
     (S      : Editor.State.State_Type;
      Input  : String;
      Base   : String;
      Target : out Unbounded_String) return Boolean
   is
      Candidate : constant String := Build_File_Tree_Target_Path (S, Input, Base);
   begin
      Target := Null_Unbounded_String;
      if Input'Length = 0 or else Candidate'Length = 0 then
         return False;
      elsif Contains_Parent_Traversal (Input) then
         return False;
      elsif not Editor.Project.Is_Under_Project (S.Project, Candidate) then
         return False;
      else
         Target := To_Unbounded_String (Candidate);
         return True;
      end if;
   end Project_Bounded_File_Tree_Target;


   function File_Tree_Parent_Directory_Available
     (S      : Editor.State.State_Type;
      Target : String) return Boolean
   is
      Parent : constant String := Ada.Directories.Containing_Directory (Target);
      Canonical_Parent : Unbounded_String := Null_Unbounded_String;
   begin
      if Parent'Length = 0
        or else not Ada.Directories.Exists (Parent)
        or else Ada.Directories.Kind (Parent) /= Ada.Directories.Directory
      then
         return False;
      end if;

      --  completeness: target validation must be project-root
      --  bounded at the filesystem operation boundary, not only by the raw
      --  composed prompt string.  Re-check the existing parent directory
      --  through the filesystem's canonical name so create/rename cannot use
      --  an in-project path component that resolves to a directory outside
      --  the active project root.
      Canonical_Parent := To_Unbounded_String (Ada.Directories.Full_Name (Parent));
      return Editor.Project.Is_Under_Project
        (S.Project, To_String (Canonical_Parent));
   exception
      when others =>
         return False;
   end File_Tree_Parent_Directory_Available;

   function Delete_Confirmation_Accepted
     (Kind    : Editor.File_Tree.File_Tree_Node_Kind;
      Confirm : String) return Boolean
   is
      pragma Unreferenced (Kind);
      Token : constant String := Ada.Characters.Handling.To_Lower (Confirm);
   begin
      --  baseline policy deletes files and empty directories only.
      --  Recursive directory deletion is deliberately not exposed here, so the
      --  same explicit confirmation token is sufficient for both safe delete
      --  targets.  Directory emptiness is revalidated immediately before the
      --  filesystem mutation.
      return Token = "confirm";
   end Delete_Confirmation_Accepted;

   function File_Tree_Outcome_Kind_Label
     (Kind : Editor.File_Tree.File_Tree_Node_Kind) return String
   is
   begin
      case Kind is
         when Editor.File_Tree.Directory_Node =>
            return "Directory";
         when Editor.File_Tree.File_Node =>
            return "File";
      end case;
   end File_Tree_Outcome_Kind_Label;

   function Directory_Is_Empty (Path : String) return Boolean
   is
      function Pattern_Has_Entry (Pattern : String) return Boolean
      is
         Search         : Ada.Directories.Search_Type;
         Search_Started : Boolean := False;
      begin
         Ada.Directories.Start_Search
           (Search    => Search,
            Directory => Path,
            Pattern   => Pattern);
         Search_Started := True;

         while Ada.Directories.More_Entries (Search) loop
            declare
               Dir_Entry : Ada.Directories.Directory_Entry_Type;
            begin
               Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
               declare
                  Entry_Name : constant String :=
                    Ada.Directories.Simple_Name (Dir_Entry);
               begin
                  if Entry_Name /= "." and then Entry_Name /= ".." then
                     Ada.Directories.End_Search (Search);
                     return True;
                  end if;
               end;
            end;
         end loop;

         Ada.Directories.End_Search (Search);
         return False;
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
            --  Treat unreadable or otherwise unscannable directories as not
            --  empty so the delete workflow remains fail-before-mutation.
            return True;
      end Pattern_Has_Entry;
   begin
      --  completeness: the empty-directory-only delete policy must
      --  not depend on host glob behaviour for dotfiles.  Some directory
      --  searches with "*" can omit hidden entries, so also scan ".*" and
      --  ignore only the synthetic current/parent entries.  A directory that
      --  contains only ".keep" or another hidden file is still non-empty and
      --  must be rejected before Delete_Directory is attempted.
      return not Pattern_Has_Entry ("*")
        and then not Pattern_Has_Entry (".*");
   end Directory_Is_Empty;

   function File_Tree_Source_Matches_Filesystem
     (Summary : Editor.File_Tree.File_Tree_Node_Summary) return Boolean
   is
      Path : constant String := To_String (Summary.Absolute_Path);
   begin
      if Path'Length = 0 or else not Ada.Directories.Exists (Path) then
         return False;
      end if;

      case Summary.Kind is
         when Editor.File_Tree.File_Node =>
            return Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File;
         when Editor.File_Tree.Directory_Node =>
            return Ada.Directories.Kind (Path) = Ada.Directories.Directory;
      end case;
   exception
      when others =>
         return False;
   end File_Tree_Source_Matches_Filesystem;

   function File_Tree_Source_Project_Bounded
     (S       : Editor.State.State_Type;
      Summary : Editor.File_Tree.File_Tree_Node_Summary) return Boolean
   is
      Path           : constant String := To_String (Summary.Absolute_Path);
      Canonical_Path : Unbounded_String := Null_Unbounded_String;
   begin
      if Path'Length = 0
        or else not Ada.Directories.Exists (Path)
        or else not Editor.Project.Is_Under_Project (S.Project, Path)
      then
         return False;
      end if;

      --  completeness: selected File Tree rows are transient
      --  snapshots and must be revalidated at the filesystem operation
      --  boundary.  Checking only the stored path string is insufficient when
      --  stale/corrupt tree state or resolved filesystem alternate paths point outside
      --  the active project.  Rename/delete therefore require the existing
      --  source object's canonical filesystem name to remain project-bounded
      --  before any mutation is attempted.
      Canonical_Path := To_Unbounded_String (Ada.Directories.Full_Name (Path));
      return Editor.Project.Is_Under_Project
        (S.Project, To_String (Canonical_Path));
   exception
      when others =>
         return False;
   end File_Tree_Source_Project_Bounded;

   procedure Select_File_Tree_Path
     (S    : in out Editor.State.State_Type;
      Path : String)
   is
      Found     : Boolean := False;
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Row_Found : Boolean := False;
      Row       : Natural := 0;
   begin
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, Path, Found);
      if Found and then Node /= Editor.File_Tree.No_File_Tree_Node then
         Editor.File_Tree.Expand_Ancestors (S.File_Tree, Node);
         Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
         if Row_Found then
            Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
            Editor.File_Tree_View.Ensure_Selected_Row_Visible
              (S.File_Tree_View,
               S.File_Tree,
               Editor.File_Tree.Visible_Row_Count (S.File_Tree));
         end if;
      end if;
   end Select_File_Tree_Path;

   function Selected_File_Tree_Node_Summary
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.File_Tree.File_Tree_Node_Summary
   is
      Node : constant Editor.File_Tree.File_Tree_Node_Id :=
        Editor.Executor.Selected_File_Tree_Node (S, Found);
   begin
      if not Found then
         return (others => <>);
      end if;
      return Editor.File_Tree.Node (S.File_Tree, Node);
   end Selected_File_Tree_Node_Summary;

   function Normalize_File_Tree_Path_For_Compare
     (Path : String) return String
   is
      Result : String (Path'Range);
      Last   : Integer := Path'Last;
   begin
      for I in Path'Range loop
         if Path (I) = Character'Val (16#5C#) then
            Result (I) := '/';
         else
            Result (I) := Path (I);
         end if;
      end loop;

      while Last >= Result'First and then Result (Last) = '/' loop
         Last := Last - 1;
      end loop;

      if Last < Result'First then
         return "";
      else
         return Result (Result'First .. Last);
      end if;
   end Normalize_File_Tree_Path_For_Compare;

   function Same_Or_Descendant_File_Tree_Path
     (Path : String;
      Root : String) return Boolean
   is
      P : constant String := Normalize_File_Tree_Path_For_Compare (Path);
      R : constant String := Normalize_File_Tree_Path_For_Compare (Root);
   begin
      if P = R then
         return True;
      elsif R'Length = 0 or else P'Length <= R'Length then
         return False;
      else
         return P (P'First .. P'First + R'Length - 1) = R
           and then P (P'First + R'Length) = '/';
      end if;
   end Same_Or_Descendant_File_Tree_Path;

   function Open_Buffer_Blocks_File_Tree_Mutation
     (S          : Editor.State.State_Type;
      Source     : String;
      For_Delete : Boolean := False) return Boolean
   is
      pragma Unreferenced (S);
      pragma Unreferenced (For_Delete);
   begin
      --  Project-explorer rename/delete only block on dirty file-backed buffers.
      --  Clean open buffers are handled explicitly by the operation path: rename
      --  rebases their file paths, while delete closes them before removing the
      --  filesystem object.
      return Editor.Buffers.Global_Has_Dirty_File_Under_Path (Source);
   end Open_Buffer_Blocks_File_Tree_Mutation;

   function Rebased_File_Tree_Path
     (Path       : String;
      Old_Root   : String;
      New_Root   : String) return String
   is
      P : constant String := Normalize_File_Tree_Path_For_Compare (Path);
      R : constant String := Normalize_File_Tree_Path_For_Compare (Old_Root);
      Suffix_Start : Integer := P'First + R'Length;
   begin
      if P = R then
         return New_Root;
      elsif R'Length = 0 or else P'Length <= R'Length then
         return Path;
      elsif P (P'First .. P'First + R'Length - 1) /= R then
         return Path;
      elsif P (P'First + R'Length) /= '/' then
         return Path;
      else
         Suffix_Start := P'First + R'Length + 1;
         return Ada.Directories.Compose
           (New_Root, P (Suffix_Start .. P'Last));
      end if;
   end Rebased_File_Tree_Path;

   procedure Update_Active_Buffer_After_File_Tree_Rename
     (S        : in out Editor.State.State_Type;
      Old_Path : String;
      New_Path : String)
   is
      Updated : constant String :=
        Rebased_File_Tree_Path
          (To_String (S.File_Info.Path), Old_Path, New_Path);
   begin
      if S.File_Info.Has_Path
        and then Same_Or_Descendant_File_Tree_Path
          (To_String (S.File_Info.Path), Old_Path)
      then
         S.File_Info.Path := To_Unbounded_String (Updated);
         S.File_Info.Display_Name :=
           To_Unbounded_String
             (Editor.Files.Display_Name_For_Path (Updated));
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;
   end Update_Active_Buffer_After_File_Tree_Rename;

   function Refresh_File_Tree_Model_After_Operation
     (S : in out Editor.State.State_Type) return Boolean
   is
      Tree   : Editor.File_Tree.File_Tree_State;
      Result : Editor.File_Tree.File_Tree_Scan_Result;
      Selected_Found : Boolean := False;
      Selected_Node  : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Selected_Path  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.File_Tree.Clear (S.File_Tree);
         Editor.File_Tree_View.Clear_View (S.File_Tree_View);
         return False;
      end if;

      Selected_Node := Editor.File_Tree_View.Node_For_Row
        (S.File_Tree,
         Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View),
         Selected_Found);
      if Selected_Found then
         Selected_Path := Editor.File_Tree.Node
           (S.File_Tree, Selected_Node).Relative_Path;
      end if;

      Tree := Editor.File_Tree.Scan_Project (Editor.Project.Root_Path (S.Project));
      Result := Editor.File_Tree.Scan_Status (Tree);
      if Result.Status = Editor.File_Tree.File_Tree_Scan_Ok then
         Editor.File_Tree.Preserve_Expanded_Paths_From
           (Tree   => Tree,
            Source => S.File_Tree);
         S.File_Tree := Tree;
         Editor.Executor.Populate_Project_Known_Files_From_File_Tree (S);

         if Length (Selected_Path) > 0 then
            declare
               New_Found : Boolean := False;
               New_Node  : constant Editor.File_Tree.File_Tree_Node_Id :=
                 Editor.File_Tree.Find_By_Path
                   (S.File_Tree, To_String (Selected_Path), New_Found);
               Row_Found : Boolean := False;
               Row       : Natural := 0;
            begin
               if New_Found then
                  Row := Editor.File_Tree_View.Row_For_Node
                    (S.File_Tree, New_Node, Row_Found);
                  if Row_Found then
                     Editor.File_Tree_View.Set_Selected_Row_Index
                       (S.File_Tree_View, Row);
                  else
                     Editor.File_Tree_View.Set_Selected_Row_Index
                       (S.File_Tree_View, 0);
                  end if;
               else
                  Editor.File_Tree_View.Set_Selected_Row_Index
                    (S.File_Tree_View, 0);
               end if;
            end;
         end if;

         Editor.Executor.Validate_File_Tree_View (S);
         Editor.Executor.Project_Search_Result_Commands
           .Refresh_Project_Search_After_File_Lifecycle (S);
         if Editor.Quick_Open.Is_Open (S.Quick_Open) then
            Editor.Executor.Recompute_Quick_Open (S);
         end if;
      else
         --  completeness: after a filesystem mutation, a failed
         --  refresh must not leave pre-mutation File Tree rows or known-file
         --  indexes behind.  Clear transient explorer state while preserving
         --  the active project itself; the command outcome still reports the
         --  mutation plus refresh failure to the user.
         Editor.File_Tree.Clear (S.File_Tree);
         Editor.File_Tree_View.Clear_View (S.File_Tree_View);
         Editor.Project.Clear_Known_Files (S.Project);
         Editor.Project_Search.Mark_Stale (S.Project_Search);
         Editor.Quick_Open.Mark_Stale (S.Quick_Open);
      end if;

      return Result.Status = Editor.File_Tree.File_Tree_Scan_Ok;
   end Refresh_File_Tree_Model_After_Operation;

   function File_Tree_Build_Config_Path (Path : String) return Boolean
   is
      Name  : constant String :=
        Ada.Characters.Handling.To_Lower (Ada.Directories.Simple_Name (Path));
      Last4 : constant Natural := 4;
   begin
      if Name = "alire.toml" then
         return True;
      elsif Name'Length < Last4 then
         return False;
      else
         return Name (Name'Last - 3 .. Name'Last) = ".gpr";
      end if;
   exception
      when others =>
         return False;
   end File_Tree_Build_Config_Path;

   function File_Tree_Mutation_Affects_Path
     (Old_Path : String;
      New_Path : String;
      Path     : String) return Boolean
   is
   begin
      if Path'Length = 0 then
         return False;
      elsif Old_Path'Length > 0
        and then Same_Or_Descendant_File_Tree_Path (Path, Old_Path)
      then
         return True;
      elsif New_Path'Length > 0
        and then Same_Or_Descendant_File_Tree_Path (Path, New_Path)
      then
         return True;
      else
         return False;
      end if;
   end File_Tree_Mutation_Affects_Path;

   function File_Tree_Mutation_Affects_Known_Build_Config
     (S        : Editor.State.State_Type;
      Old_Path : String;
      New_Path : String) return Boolean
   is
      Count : constant Natural := Editor.File_Tree.File_Node_Count (S.File_Tree);
   begin
      --  completeness: build candidate staleness is not limited to
      --  mutations whose direct target is named alire.toml or *.gpr.  A
      --  directory rename/delete can move or remove build configuration files
      --  below the selected directory.  Use the pre-refresh File Tree snapshot
      --  as a side-effect-free ownership boundary to detect affected known
      --  build config files before the mutation refresh replaces the tree.
      for Index in 1 .. Count loop
         declare
            Node : constant Editor.File_Tree.File_Tree_Node_Summary :=
              Editor.File_Tree.File_Node_At (S.File_Tree, Index);
            Path : constant String := To_String (Node.Absolute_Path);
         begin
            if File_Tree_Build_Config_Path (Path)
              and then File_Tree_Mutation_Affects_Path (Old_Path, New_Path, Path)
            then
               return True;
            end if;
         end;
      end loop;

      return False;
   end File_Tree_Mutation_Affects_Known_Build_Config;

   function File_Tree_Mutation_Affects_Selected_Build_Candidate
     (S        : Editor.State.State_Type;
      Old_Path : String;
      New_Path : String) return Boolean
   is
      Selected_Id : constant String :=
        To_String (S.Build_UI.Selected_Build_Candidate_Id);
   begin
      if Selected_Id'Length = 0 then
         return False;
      end if;

      for Candidate of S.Build_UI.Build_Candidates loop
         if To_String (Candidate.Candidate_Id) = Selected_Id then
            declare
               Source : constant String :=
                 To_String (Candidate.Source_Path_If_Represented);
               Old_Relative : constant String :=
                 (if Old_Path'Length > 0
                    and then Editor.Project.Has_Project (S.Project)
                    and then Editor.Project.Is_Under_Project (S.Project, Old_Path)
                  then Editor.Project.Relative_Path (S.Project, Old_Path)
                  else "");
               New_Relative : constant String :=
                 (if New_Path'Length > 0
                    and then Editor.Project.Has_Project (S.Project)
                    and then Editor.Project.Is_Under_Project (S.Project, New_Path)
                  then Editor.Project.Relative_Path (S.Project, New_Path)
                  else "");
            begin
               --  completeness: selected build-candidate staleness
               --  must follow the candidate's represented source whether that
               --  source is stored as an absolute filesystem path or as a
               --  project-relative label.  File Tree mutation execution works
               --  with absolute paths, but Build UI candidate records may be
               --  projected through relative source labels; either spelling
               --  must invalidate consent and pending request state.
               return File_Tree_Mutation_Affects_Path
                   (Old_Path, New_Path, Source)
                 or else File_Tree_Mutation_Affects_Path
                   (Old_Relative, New_Relative, Source);
            end;
         end if;
      end loop;

      return False;
   end File_Tree_Mutation_Affects_Selected_Build_Candidate;

   procedure Invalidate_Project_State_After_File_Tree_Mutation
     (S        : in out Editor.State.State_Type;
      Old_Path : String;
      New_Path : String := "")
   is
      Affects_Active_File : constant Boolean :=
        S.File_Info.Has_Path
        and then File_Tree_Mutation_Affects_Path
          (Old_Path, New_Path, To_String (S.File_Info.Path));
      Affects_Build_Config : constant Boolean :=
        (Old_Path'Length > 0 and then File_Tree_Build_Config_Path (Old_Path))
        or else (New_Path'Length > 0 and then File_Tree_Build_Config_Path (New_Path))
        or else File_Tree_Mutation_Affects_Known_Build_Config
          (S, Old_Path, New_Path);
      Has_Selected_Build_Candidate : constant Boolean :=
        To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length > 0;
      Affects_Selected_Build_Candidate : constant Boolean :=
        File_Tree_Mutation_Affects_Selected_Build_Candidate
          (S, Old_Path, New_Path);
   begin
      --  filesystem mutations make project-derived surfaces stale
      --  through the owning runtime state, never through render, availability,
      --  Command Palette rows, keybinding payloads, or persisted operation data.
      Editor.Project_Search.Mark_Stale_Unconditionally (S.Project_Search);
      Editor.Project_Search.Mark_Replace_Preview_Stale (S.Project_Search);

      --  File Tree create/rename/delete changes the set
      --  of project source paths independently of active-buffer commands.
      --  Invalidate exact and subtree paths so indexed cross-file Outline and
      --  semantic navigation never points at removed, moved, or rebased Ada
      --  source files.  New paths are also dropped because clean open buffers
      --  may have been rebased to that target and must be re-indexed with the
      --  new lifecycle stamps before navigation can use them.
      if Old_Path'Length > 0 then
         Editor.Ada_Project_Index.Invalidate_Path_Subtree
           (S.Language_Index, Old_Path);
         Editor.Ada_Language_Service.Invalidate_Path_Subtree
           (S.Language_Service, Old_Path);
      end if;
      if New_Path'Length > 0 then
         Editor.Ada_Project_Index.Invalidate_Path_Subtree
           (S.Language_Index, New_Path);
         Editor.Ada_Language_Service.Invalidate_Path_Subtree
           (S.Language_Service, New_Path);
      end if;
      if Affects_Active_File and then S.Active_Buffer_Token /= 0 then
         Editor.Ada_Project_Index.Invalidate_Buffer
           (S.Language_Index, S.Active_Buffer_Token);
         Editor.Ada_Language_Service.Invalidate_Buffer
           (S.Language_Service, S.Active_Buffer_Token);
         Editor.Syntax_Semantics.Clear (S.Syntax_Symbols);
         Editor.Ada_Language_Model.Clear (S.Syntax_Analysis);
         S.Syntax_Symbols_Revision := Natural'Last;
         S.Syntax_Symbols_Buffer_Token := 0;
      end if;

      if Affects_Active_File then
         Editor.Outline.Clear (S.Outline);
         S.Outline_Cursor_Key_Valid := False;
         Editor.Diagnostics.Clear (S.Diagnostics);
         Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      end if;

      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
        (S.Feature_Diagnostics, Old_Path, New_Path);

      if Editor.Project.Has_Project (S.Project) then
         declare
            Old_Relative : constant String :=
              (if Old_Path'Length > 0
                 and then Editor.Project.Is_Under_Project (S.Project, Old_Path)
               then Editor.Project.Relative_Path (S.Project, Old_Path)
               else "");
            New_Relative : constant String :=
              (if New_Path'Length > 0
                 and then Editor.Project.Is_Under_Project (S.Project, New_Path)
               then Editor.Project.Relative_Path (S.Project, New_Path)
               else "");
         begin
            --  completeness: diagnostics rows often store
            --  project-relative source labels (for example "src/main.adb")
            --  while File Tree execution validates and mutates absolute
            --  filesystem paths.  Mark both absolute and project-relative
            --  spellings stale so directory/file rename/delete cannot leave
            --  stale diagnostics live merely because the source label used
            --  the UI-relative form.
            Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
              (S.Feature_Diagnostics, Old_Relative, New_Relative);
         end;
      end if;

      if Affects_Build_Config then
         --  completeness: .gpr/alire.toml creation, rename, or
         --  deletion invalidates the discovered build-candidate list itself,
         --  not only the currently selected candidate.  Do not refresh from
         --  this mutation path and do not preserve a runnable request; leave
         --  candidate discovery for the owning Build UI command.
         S.Build_UI.Build_Candidates :=
           Editor.Build_Candidates.Build_Candidate_Vectors.Empty_Vector;
         S.Build_UI.Candidate_Refresh_Status :=
           Editor.Build_UI.Build_Candidate_Refresh_Not_Requested;
         S.Build_UI.Candidate_Refresh_Message := To_Unbounded_String
           ("Build candidates are stale after File Tree mutation");
         S.Build_UI.Candidate_Discovery_Message := To_Unbounded_String
           ("Build candidates are stale after File Tree mutation");
         S.Build_UI.Last_Refresh_Candidate_Count := 0;
         S.Build_UI.Selected_Candidate_Preserved_On_Refresh := False;
         S.Build_UI.Selected_Candidate_Cleared_On_Refresh := False;
      end if;

      if (Affects_Build_Config and then Has_Selected_Build_Candidate)
        or else Affects_Selected_Build_Candidate
      then
         S.Build_UI.Selected_Candidate_Stale := True;
         S.Build_UI.Consent_Acknowledged := False;
         S.Build_UI.Pending_Public_Build_Request := False;
         S.Build_UI.Candidate_Selection_Message := To_Unbounded_String
           ("Selected build candidate is stale after File Tree mutation");
         S.Build_UI.Validation_Status :=
           Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale;
         S.Build_UI.Validation_Message := To_Unbounded_String
           (Editor.Build_UI.Validation_Message
              (Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale));
      end if;
   end Invalidate_Project_State_After_File_Tree_Mutation;

   procedure Execute_File_Tree_Create_File
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Base_Found : Boolean := False;
      Base       : constant String := Selected_File_Tree_Base_Directory (S, Base_Found);
      Input      : constant String := File_Tree_Input_Text (Cmd);
      Target     : Unbounded_String := Null_Unbounded_String;
      File       : Ada.Text_IO.File_Type;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif Input'Length = 0 then
         --  completeness: execution-time validation must mirror the
         --  guided prompt validation for empty File Tree mutation names.
         --  Even if a command reaches the Executor without prompt-local text,
         --  the operation should report the operation-model name guidance
         --  rather than a generic malformed-name diagnostic.
         Editor.Executor.Shared_Services.Report_Error (S, "Enter a name.");
         return;
      elsif Contains_Control_File_Tree_Input_Character (Input) then
         --  reject raw control characters
         --  before host-path classification.  A prompt such as "/tmp/\n"
         --  is malformed editor input, not merely an outside-project path,
         --  and must receive the canonical invalid file-name diagnostic.
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid file name");
         return;
      elsif Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        and then not Is_Windows_Drive_Absolute_File_Tree_Input (Input)
      then
         --  completeness: prompt validation rejects drive-relative
         --  text such as "C:tmp" as malformed File Tree input.  Execution-time
         --  validation must produce the same class of failure instead of
         --  treating it as a reusable host-path payload or a boundary-only
         --  error.  Drive-rooted forms continue through the absolute-path
         --  branch and report the project-boundary violation.
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid file name");
         return;
      elsif File_Tree_Input_Is_Absolute (Input) then
         Editor.Executor.Shared_Services.Report_Error (S, Absolute_File_Tree_Input_Message (S, Input));
         return;
      elsif Contains_Parent_Traversal (Input)
        or else Has_Trailing_Path_Separator (Input)
        or else Contains_Current_Directory_Segment (Input)
        or else Contains_Empty_Relative_Path_Segment (Input)
      then
         --  completeness: prompt validation reports traversal,
         --  current-directory segments, empty segments, and trailing
         --  separators as malformed File Tree input.  Execution-time
         --  validation must reject the same syntax class before the generic
         --  project-boundary fallback so confirm-time diagnostics remain
         --  aligned with the guided prompt.
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid file name");
         return;
      end if;

      declare
         Selected_Found   : Boolean := False;
         Selected_Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
           Selected_File_Tree_Node_Summary (S, Selected_Found);
      begin
         if Base_Found
           and then Selected_Found
           and then Selected_Summary.Kind = Editor.File_Tree.Directory_Node
           and then not File_Tree_Input_Has_Explicit_Directory (Input)
         then
            --  completeness: create operations using the selected
            --  directory as their base must revalidate that selected snapshot
            --  before target composition reaches the filesystem.  A stale
            --  directory row must not degrade into a generic missing-parent
            --  diagnostic or create relative to a replacement object.
            if not Ada.Directories.Exists
              (To_String (Selected_Summary.Absolute_Path))
              or else not File_Tree_Source_Matches_Filesystem
                (Selected_Summary)
            then
               Editor.Executor.Shared_Services.Report_Warning (S, Editor.Commands.Reason_File_Tree_Item_Stale);
               return;
            elsif not File_Tree_Source_Project_Bounded (S, Selected_Summary) then
               Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
               return;
            end if;
         end if;
      end;

      if not Base_Found
        and then not File_Tree_Input_Has_Explicit_Directory (Input)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "No target directory selected");
         return;
      elsif not Project_Bounded_File_Tree_Target (S, Input, Base, Target) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Open buffer already represents target path");
         return;
      elsif not File_Tree_Parent_Directory_Available (S, To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Parent directory unavailable");
         return;
      end if;

      begin
         Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, To_String (Target));
         Ada.Text_IO.Close (File);
         Invalidate_Project_State_After_File_Tree_Mutation
           (S, To_String (Target));
         if Refresh_File_Tree_Model_After_Operation (S) then
            Select_File_Tree_Path (S, To_String (Target));
            Editor.Executor.Shared_Services.Report_Success (S, "File created.");
         else
            Editor.Executor.Shared_Services.Report_Warning (S, "File created; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error | Ada.IO_Exceptions.Name_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid file name");
         when Ada.IO_Exceptions.Use_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Permission denied");
         when others =>
            begin
               if Ada.Text_IO.Is_Open (File) then
                  Ada.Text_IO.Close (File);
               end if;
            exception
               when others => null;
            end;
            Editor.Executor.Shared_Services.Report_Error (S, "Could not create file");
      end;
   end Execute_File_Tree_Create_File;

   procedure Execute_File_Tree_Create_Directory
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Base_Found : Boolean := False;
      Base       : constant String := Selected_File_Tree_Base_Directory (S, Base_Found);
      Input      : constant String := File_Tree_Input_Text (Cmd);
      Target     : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif Input'Length = 0 then
         --  completeness: keep empty create-directory execution
         --  aligned with the prompt-owned validation surface.
         Editor.Executor.Shared_Services.Report_Error (S, "Enter a name.");
         return;
      elsif Contains_Control_File_Tree_Input_Character (Input) then
         --  reject raw control characters
         --  before host-path classification.  Malformed prompt text should
         --  not be reported as an absolute/outside-project target.
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid directory name");
         return;
      elsif Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        and then not Is_Windows_Drive_Absolute_File_Tree_Input (Input)
      then
         --  completeness: keep guided prompt validation and
         --  execution-time validation aligned for drive-relative text.  It is
         --  malformed File Tree input, not a project-relative directory target
         --  and not a persisted filesystem payload.
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid directory name");
         return;
      elsif File_Tree_Input_Is_Absolute (Input) then
         Editor.Executor.Shared_Services.Report_Error (S, Absolute_File_Tree_Input_Message (S, Input));
         return;
      elsif Contains_Parent_Traversal (Input)
        or else Has_Trailing_Path_Separator (Input)
        or else Contains_Current_Directory_Segment (Input)
        or else Contains_Empty_Relative_Path_Segment (Input)
      then
         --  completeness: prompt validation and execution-time
         --  validation must agree.  Directory creation accepts explicit
         --  project-relative paths such as "src/generated", but traversal,
         --  current-directory segments, empty segments, and trailing
         --  separators are malformed input rather than shell-normalized
         --  directory paths.
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid directory name");
         return;
      end if;

      declare
         Selected_Found   : Boolean := False;
         Selected_Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
           Selected_File_Tree_Node_Summary (S, Selected_Found);
      begin
         if Base_Found
           and then Selected_Found
           and then Selected_Summary.Kind = Editor.File_Tree.Directory_Node
           and then not File_Tree_Input_Has_Explicit_Directory (Input)
         then
            --  completeness: create operations using the selected
            --  directory as their base must revalidate that selected snapshot
            --  before target composition reaches the filesystem.  A stale
            --  directory row must not degrade into a generic missing-parent
            --  diagnostic or create relative to a replacement object.
            if not Ada.Directories.Exists
              (To_String (Selected_Summary.Absolute_Path))
              or else not File_Tree_Source_Matches_Filesystem
                (Selected_Summary)
            then
               Editor.Executor.Shared_Services.Report_Warning (S, Editor.Commands.Reason_File_Tree_Item_Stale);
               return;
            elsif not File_Tree_Source_Project_Bounded (S, Selected_Summary) then
               Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
               return;
            end if;
         end if;
      end;

      if not Base_Found
        and then not File_Tree_Input_Has_Explicit_Directory (Input)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "No target directory selected");
         return;
      elsif not Project_Bounded_File_Tree_Target (S, Input, Base, Target) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Open buffer already represents target path");
         return;
      elsif not File_Tree_Parent_Directory_Available (S, To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Parent directory unavailable");
         return;
      end if;

      begin
         Ada.Directories.Create_Directory (To_String (Target));
         Invalidate_Project_State_After_File_Tree_Mutation
           (S, To_String (Target));
         if Refresh_File_Tree_Model_After_Operation (S) then
            Select_File_Tree_Path (S, To_String (Target));
            Editor.Executor.Shared_Services.Report_Success (S, "Directory created.");
         else
            Editor.Executor.Shared_Services.Report_Warning (S, "Directory created; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid directory name");
         when Ada.Directories.Use_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Permission denied");
         when others =>
            Editor.Executor.Shared_Services.Report_Error (S, "Could not create directory");
      end;
   end Execute_File_Tree_Create_Directory;

   procedure Execute_File_Tree_Rename_Selected
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Found   : Boolean := False;
      Summary : constant Editor.File_Tree.File_Tree_Node_Summary :=
        Selected_File_Tree_Node_Summary (S, Found);
      Input   : constant String := File_Tree_Input_Text (Cmd);
      Target  : Unbounded_String := Null_Unbounded_String;
      Parent_Path : Unbounded_String := Null_Unbounded_String;
      Active_Buffer_Was_Renamed : Boolean := False;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      elsif not Found then
         Editor.Executor.Shared_Services.Report_Warning (S, "No File Tree node selected");
         return;
      elsif not Editor.Project.Is_Under_Project
        (S.Project, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif Summary.Parent = Editor.File_Tree.No_File_Tree_Node then
         --  The project-root row is a real directory node, but it is not a
         --  valid rename source.  Report the project-root constraint before
         --  validating prompt text so root rename attempts cannot be confused
         --  with malformed user input.
         Editor.Executor.Shared_Services.Report_Warning (S, "Cannot rename project root");
         return;
      elsif Input'Length = 0 then
         --  completeness: rename uses the same empty-name
         --  validation language as the guided prompt.
         Editor.Executor.Shared_Services.Report_Error (S, "Enter a name.");
         return;
      elsif Ada.Strings.Fixed.Index (Input, "/") /= 0
        or else Ada.Strings.Fixed.Index (Input, "\") /= 0
      then
         --  completeness: rename is a leaf-name workflow even at
         --  direct Executor revalidation time.  Guided prompt validation
         --  already explains path fragments with the leaf-name-only policy;
         --  keep execution aligned so Command Palette/keybinding routes that
         --  reach the Executor without prompt-local blocking do not degrade to
         --  a generic invalid-target message.
         Editor.Executor.Shared_Services.Report_Error (S, "Rename expects a single new name");
         return;
      elsif Is_Windows_Drive_Qualified_File_Tree_Input (Input)
        or else Contains_Control_File_Tree_Input_Character (Input)
        or else Contains_Parent_Traversal (Input)
        or else Contains_Current_Directory_Segment (Input)
      then
         --  completeness: rename-selected accepts a new leaf name,
         --  not a host-path fragment.  Reject Windows drive-qualified text on
         --  every host so prompts such as "C:tmp" or "C:/tmp" cannot be
         --  interpreted as a colon-containing filename or as an accidental
         --  absolute path variant.
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid rename target");
         return;
      elsif not Ada.Directories.Exists (To_String (Summary.Absolute_Path)) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Target no longer exists.");
         return;
      elsif not File_Tree_Source_Project_Bounded (S, Summary) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif not File_Tree_Source_Matches_Filesystem (Summary) then
         Editor.Executor.Shared_Services.Report_Warning (S, Editor.Commands.Reason_File_Tree_Item_Stale);
         return;
      elsif Open_Buffer_Blocks_File_Tree_Mutation
        (S, To_String (Summary.Absolute_Path))
      then
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty buffer preserved.");
         return;
      end if;

      Parent_Path := Editor.File_Tree.Node (S.File_Tree, Summary.Parent).Absolute_Path;
      Target := To_Unbounded_String
        (Ada.Directories.Compose (To_String (Parent_Path), Input));
      Active_Buffer_Was_Renamed :=
        S.File_Info.Has_Path
        and then Same_Or_Descendant_File_Tree_Path
          (To_String (S.File_Info.Path), To_String (Summary.Absolute_Path));

      if not Editor.Project.Is_Under_Project (S.Project, To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target path is outside the project");
         return;
      elsif Same_Or_Descendant_File_Tree_Path
        (To_String (Summary.Absolute_Path), To_String (Target))
        and then Same_Or_Descendant_File_Tree_Path
          (To_String (Target), To_String (Summary.Absolute_Path))
      then
         --  completeness: a rename to the same filesystem path is
         --  neither a conflict nor a successful mutation.  Reject it
         --  explicitly before the generic target-exists check so the workflow
         --  does not report a misleading collision for an unchanged name.
         Editor.Executor.Shared_Services.Report_Warning (S, "Rename target is unchanged");
         return;
      elsif not File_Tree_Parent_Directory_Available (S, To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Parent directory unavailable");
         return;
      elsif Ada.Directories.Exists (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Target already exists");
         return;
      elsif Editor.Buffers.Global_Has_File_Under_Path (To_String (Target)) then
         Editor.Executor.Shared_Services.Report_Error (S, "Open buffer already represents target path");
         return;
      end if;

      begin
         Ada.Directories.Rename
           (Old_Name => To_String (Summary.Absolute_Path),
            New_Name => To_String (Target));

         declare
            Rebased_Count : Natural := 0;
         begin
            Editor.Buffers.Global_Rebase_Clean_File_Paths
              (Old_Root      => To_String (Summary.Absolute_Path),
               New_Root      => To_String (Target),
               Rebased_Count => Rebased_Count);
            if Rebased_Count > 0 then
               Editor.Executor.Semantic_Index_Commands.Load_Global_Active_Preserving_Language_Index (S);
               if Active_Buffer_Was_Renamed then
                  --  renaming an already-open clean file
                  --  is a navigation workflow as well as a File Tree mutation.
                  --  Once the buffer backing path has been rebased, return
                  --  focus to the renamed buffer so the daily loop continues
                  --  at the document the user was working in.  Pure File Tree
                  --  renames with no affected active buffer keep File Tree
                  --  focus below.
                  Editor.Focus_Management.Restore_Focus_To_Editor (S);
               end if;
            else
               Update_Active_Buffer_After_File_Tree_Rename
                 (S, To_String (Summary.Absolute_Path), To_String (Target));
            end if;
         end;

         Invalidate_Project_State_After_File_Tree_Mutation
           (S, To_String (Summary.Absolute_Path), To_String (Target));

         if Refresh_File_Tree_Model_After_Operation (S) then
            Select_File_Tree_Path (S, To_String (Target));
            Editor.Executor.Shared_Services.Report_Success
              (S, File_Tree_Outcome_Kind_Label (Summary.Kind) & " renamed.");
         else
            Editor.Executor.Shared_Services.Report_Warning
              (S, File_Tree_Outcome_Kind_Label (Summary.Kind)
                    & " renamed; refresh failed.");
         end if;
      exception
         when Ada.Directories.Name_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid rename target");
         when Ada.Directories.Use_Error =>
            Editor.Executor.Shared_Services.Report_Error (S, "Permission denied");
         when others =>
            Editor.Executor.Shared_Services.Report_Error (S, "Could not rename File Tree item");
      end;
   end Execute_File_Tree_Rename_Selected;

end Editor.Executor.File_Tree_Mutation_Commands;
