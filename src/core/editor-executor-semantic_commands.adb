with Ada.Containers;
with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with Text_Buffer;

with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Live_Semantic_Diagnostics;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.History;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Semantic_Completion_Commands;
with Editor.Feature_Diagnostics;
with Editor.Project;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Navigation;
with Editor.Outline;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Recent_Projects;
with Editor.Render_Cache;
with Editor.State;
with Editor.Syntax_Semantics;
with Editor.UTF8;

package body Editor.Executor.Semantic_Commands is

   use Ada.Strings.Unbounded;
   use Editor.Commands;
   use Editor.Cursors;
   use Editor.Navigation;
   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Language_Model.Symbol_Kind;
   use type Editor.Ada_Language_Service.Service_Status;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Id;
   use type Editor.Files.File_Save_Status;
   use type Editor.Files.File_Open_Status;
   use type Editor.Outline.Outline_Freshness;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.State.Semantic_Popup_Kind;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   function Active_Feature_Buffer_Token
     (S : Editor.State.State_Type) return Natural
      renames Editor.Executor.Active_Feature_Buffer_Token;

   function Safe_Caret
     (S : Editor.State.State_Type) return Editor.Cursors.Cursor_Index
      renames Editor.Executor.Safe_Caret;

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Command;
      Pos          : Editor.Cursors.Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String)
      renames Editor.Executor.Append_Replace_Op;

   function Extract_Text
     (Buffer : Text_Buffer.Buffer_Type;
      Pos    : Natural;
      Count  : Natural) return Unbounded_String
      renames Editor.Executor.Extract_Text;

   function Ends_With
     (Text   : String;
      Suffix : String) return Boolean
   is
   begin
      return Text'Length >= Suffix'Length
        and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix;
   end Ends_With;

   function Is_Ada_Source_Path
     (Path : String) return Boolean
   is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Path);
   begin
      return Ends_With (Lower, ".adb") or else Ends_With (Lower, ".ads");
   end Is_Ada_Source_Path;

   function To_Feature_Severity
     (Severity : Editor.Ada_Language_Service.Semantic_Diagnostic_Severity)
      return Editor.Feature_Diagnostics.Diagnostic_Severity
   is
   begin
      case Severity is
         when Editor.Ada_Language_Service.Semantic_Error =>
            return Editor.Feature_Diagnostics.Diagnostic_Error;
         when Editor.Ada_Language_Service.Semantic_Warning =>
            return Editor.Feature_Diagnostics.Diagnostic_Warning;
         when Editor.Ada_Language_Service.Semantic_Info =>
            return Editor.Feature_Diagnostics.Diagnostic_Info;
         when Editor.Ada_Language_Service.Semantic_Hint =>
            return Editor.Feature_Diagnostics.Diagnostic_Note;
      end case;
   end To_Feature_Severity;

   procedure Publish_Service_Diagnostics_To_Feature
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Buffer_Token : Natural)
   is
      Removed : Natural;
      Added   : Natural := 0;
   begin
      Removed := Editor.Feature_Diagnostics.Clear_Diagnostics_By_Source_And_Label
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Path);

      for I in 1 ..
        Editor.Ada_Language_Service.Semantic_Diagnostic_Count_For_Path
          (S.Language_Service, Path)
      loop
         declare
            Diagnostic : constant Editor.Ada_Language_Service.Semantic_Diagnostic :=
              Editor.Ada_Language_Service.Semantic_Diagnostic_At_For_Path
                (S.Language_Service, Path, I);
         begin
            if Diagnostic.Has_Command_Descriptor then
               Editor.Feature_Diagnostics.Add_Diagnostic_Command_Descriptor
                 (S.Feature_Diagnostics,
                  Diagnostic.Command_Descriptor,
                  Source_Label  => Path,
                  Target_Buffer => Buffer_Token);
            else
               Editor.Feature_Diagnostics.Add_Diagnostic
                 (S.Feature_Diagnostics,
                  Severity      => To_Feature_Severity (Diagnostic.Severity),
                  Message       => To_String (Diagnostic.Message),
                  Source_Label  => Path,
                  Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
                  Has_Target    => Diagnostic.Has_Location and then Buffer_Token /= 0,
                  Target_Buffer => Buffer_Token,
                  Target_Line   => (if Diagnostic.Has_Location then Diagnostic.Line else 0),
                  Target_Column => (if Diagnostic.Has_Location then Diagnostic.Column else 0));
            end if;
            Added := Added + 1;
         end;
      end loop;

      if Removed > 0 or else Added > 0 then
         Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
           (S.Feature_Diagnostics, S.Feature_Panel);
      end if;
   end Publish_Service_Diagnostics_To_Feature;

   procedure Refresh_Project_Language_Index
     (S                  : in out Editor.State.State_Type;
      Build_Semantics    : Boolean;
      Indexed_File_Count : out Natural;
      Indexed_Symbols    : out Natural;
      Skipped_File_Count : out Natural;
      Read_Error_Count   : out Natural)
   is
      Active_Path : constant String :=
        (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "");
      Active_Text : constant String := Editor.State.Current_Text (S);
      Active_Buffer_Token : constant Natural := Active_Feature_Buffer_Token (S);

      procedure Index_Text
        (Path                 : String;
         Text                 : String;
         Buffer_Token         : Natural;
         Buffer_Revision      : Natural;
         Lifecycle_Generation : Natural;
         Update_Semantics     : Boolean)
      is
         Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
           Editor.Ada_Declaration_Parser.Parse (Text, Path);
      begin
         Editor.Ada_Project_Index.Put_Analysis
           (S.Language_Index,
            Path,
            Buffer_Token,
            Buffer_Revision,
            Lifecycle_Generation,
            Analysis);

         if Update_Semantics then
            Editor.Syntax_Semantics.Clear (S.Syntax_Symbols);
            S.Syntax_Analysis := Analysis;
            Editor.Syntax_Semantics.Build_Map_From_Analysis
              (S.Syntax_Symbols, Analysis);
            S.Syntax_Symbols_Revision := Editor.State.Current_Buffer_Revision (S);
            S.Syntax_Symbols_Buffer_Token := Active_Buffer_Token;
            Editor.Ada_Live_Semantic_Diagnostics.Publish
              (S.Language_Service,
               Path,
               Text,
               Buffer_Token,
               Buffer_Revision,
               Lifecycle_Generation,
               Analysis);
            Publish_Service_Diagnostics_To_Feature (S, Path, Buffer_Token);
         end if;
      end Index_Text;

      procedure Index_Open_Buffer_Overlays is
         Registry : constant Editor.Buffers.Buffer_Registry :=
           Editor.Buffers.Global_Registry_For_UI;
      begin
         --  project refresh must not be limited
         --  to filesystem/project-list contents plus the active buffer.  Open
         --  file-backed Ada buffers may hold unsaved text for project files
         --  that were already indexed from disk, or newly opened files whose
         --  text should be preferred over a stale filesystem snapshot.  Overlay
         --  every open Ada buffer with parser-owned snapshot text while keeping
         --  the active buffer on the already-stamped active-state path above.
         for J in 1 .. Editor.Buffers.Count (Registry) loop
            exit when Editor.Ada_Project_Index.File_Count (S.Language_Index) >=
              Editor.Ada_Project_Index.Max_Index_Files;

            declare
               Summary : constant Editor.Buffers.Buffer_Summary :=
                 Editor.Buffers.Summary_At (Registry, J);
               Path : constant String := To_String (Summary.Path);
            begin
               if Summary.Has_Path
                 and then Path'Length > 0
                 and then Is_Ada_Source_Path (Path)
                 and then Natural (Summary.Id) /= Active_Buffer_Token
               then
                  declare
                     Buffer_State : constant Editor.State.State_Type :=
                       Editor.Buffers.Buffer (Registry, Summary.Id);
                  begin
                     --  Invalidate before overlaying so platform/native path
                     --  spelling cannot leave a stale disk-indexed duplicate
                     --  beside the open-buffer row.
                     Editor.Ada_Project_Index.Invalidate_Path
                       (S.Language_Index, Path);
                     Index_Text
                       (Path,
                        Editor.State.Current_Text (Buffer_State),
                        Natural (Summary.Id),
                        Editor.State.Current_Buffer_Revision (Buffer_State),
                        Editor.State.Current_Lifecycle_Generation (Buffer_State),
                        False);
                  end;
               end if;
            end;
         end loop;
      end Index_Open_Buffer_Overlays;
   begin
      Indexed_File_Count := 0;
      Indexed_Symbols := 0;
      Skipped_File_Count := 0;
      Read_Error_Count := 0;

      Editor.Ada_Project_Index.Clear (S.Language_Index);

      if Editor.Project.Has_Project (S.Project) then
         declare
            Refresh_Result : Editor.Project.Project_File_Refresh_Result;
         begin
            Editor.Project.Refresh_Known_Files (S.Project, Refresh_Result);
            if Refresh_Result.Status /= Editor.Project.Project_File_Refresh_Ok then
               Read_Error_Count := Read_Error_Count + 1;
            end if;
         end;

         --  editor-owned snapshots must have precedence
         --  over filesystem snapshots during explicit project-index refresh.
         --  Index the active buffer and every other open Ada buffer before the
         --  disk/project-file scan so a large project cannot fill the bounded
         --  index and starve unsaved open-buffer analyses.
         if Active_Path'Length > 0
           and then Is_Ada_Source_Path (Active_Path)
           and then Editor.Ada_Project_Index.File_Count (S.Language_Index) <
             Editor.Ada_Project_Index.Max_Index_Files
         then
            Index_Text
              (Active_Path,
               Active_Text,
               Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Build_Semantics);
         end if;

         Index_Open_Buffer_Overlays;

         for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
            exit when Editor.Ada_Project_Index.File_Count (S.Language_Index) >=
              Editor.Ada_Project_Index.Max_Index_Files;

            declare
               Known : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (S.Project, I);
               Path : constant String := To_String (Known.Absolute_Path);
            begin
               if Path'Length = 0 or else not Is_Ada_Source_Path (Path) then
                  Skipped_File_Count := Skipped_File_Count + 1;
               elsif Editor.Ada_Project_Index.Contains_Path
                 (S.Language_Index, Path)
               then
                  --  Open-buffer overlay rows are already parser-owned from
                  --  immutable editor snapshots.  Do not replace them with a
                  --  potentially stale disk read merely because the project
                  --  file list contains the same path spelling.
                  null;
               else
                  declare
                     Opened : constant Editor.Files.File_Open_Result :=
                       Editor.Files.Open_File (Path);
                  begin
                     if Opened.Status = Editor.Files.File_Open_Ok then
                        Index_Text
                          (To_String (Opened.Path),
                           To_String (Opened.Contents),
                           0,
                           0,
                           0,
                           False);
                     else
                        Read_Error_Count := Read_Error_Count + 1;
                     end if;
                  end;
               end if;
            end;
         end loop;
      else
         declare
            Label : constant String :=
              (if Active_Path'Length > 0 then Active_Path
               else To_String (S.File_Info.Display_Name));
         begin
            if Label'Length > 0 and then Is_Ada_Source_Path (Label) then
               Index_Text
                 (Label,
                  Active_Text,
                  Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Build_Semantics);
            else
               Skipped_File_Count := Skipped_File_Count + 1;
            end if;
         end;
      end if;

      Indexed_File_Count := Editor.Ada_Project_Index.File_Count (S.Language_Index);
      Indexed_Symbols := Editor.Ada_Project_Index.Symbol_Count (S.Language_Index);
      Editor.Ada_Language_Service.Put_Index
        (S.Language_Service, S.Language_Index);
      if Build_Semantics then
         if Active_Path'Length > 0 and then Is_Ada_Source_Path (Active_Path) then
            Editor.Ada_Live_Semantic_Diagnostics.Publish
              (S.Language_Service,
               Active_Path,
               Active_Text,
               Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               S.Syntax_Analysis);
         end if;

         Editor.Ada_Live_Semantic_Diagnostics.Publish_Cross_Unit
           (S.Language_Service, S.Language_Index);

         for I in 1 .. Editor.Ada_Project_Index.File_Count (S.Language_Index) loop
            declare
               Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
                 Editor.Ada_Project_Index.File_Key_At (S.Language_Index, I);
            begin
               Publish_Service_Diagnostics_To_Feature
                 (S, To_String (Key.Path), Key.Buffer_Token);
            end;
         end loop;
      end if;
   end Refresh_Project_Language_Index;

   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type)
   is
      Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
        S.Language_Index;
      Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
        S.Language_Service;
   begin
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.Language_Index := Saved_Index;
      S.Language_Service := Saved_Service;
   end Load_Global_Active_Preserving_Language_Index;

   procedure Rebuild_Language_Index_After_File_Lifecycle
     (S : in out Editor.State.State_Type)
   is
      Saved_Project : constant Editor.Project.Project_State := S.Project;
      Indexed_Files : Natural := 0;
      Indexed_Symbols : Natural := 0;
      Skipped_Files : Natural := 0;
      Read_Errors : Natural := 0;
   begin
      Refresh_Project_Language_Index
        (S,
         Build_Semantics    => True,
         Indexed_File_Count => Indexed_Files,
         Indexed_Symbols    => Indexed_Symbols,
         Skipped_File_Count => Skipped_Files,
         Read_Error_Count   => Read_Errors);

      if Indexed_Files = Natural'Last
        and then Indexed_Symbols = Natural'Last
        and then Skipped_Files = Natural'Last
        and then Read_Errors = Natural'Last
      then
         null;
      end if;

      S.Project := Saved_Project;
   end Rebuild_Language_Index_After_File_Lifecycle;

   procedure Clear_Service_Semantic_Diagnostics_From_Feature
     (S : in out Editor.State.State_Type)
   is
      Removed : Natural := 0;
   begin
      for I in 1 ..
        Editor.Ada_Language_Service.Semantic_Diagnostic_Count (S.Language_Service)
      loop
         declare
            Diagnostic : constant Editor.Ada_Language_Service.Semantic_Diagnostic :=
              Editor.Ada_Language_Service.Semantic_Diagnostic_At
                (S.Language_Service, I);
            Path : constant String := To_String (Diagnostic.Path);
         begin
            if Path'Length > 0 then
               Removed := Removed +
                 Editor.Feature_Diagnostics.Clear_Diagnostics_By_Source_And_Label
                   (S.Feature_Diagnostics,
                    Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
                    Path);
            end if;
         end;
      end loop;

      if Removed > 0 then
         Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
           (S.Feature_Diagnostics, S.Feature_Panel);
      end if;
   end Clear_Service_Semantic_Diagnostics_From_Feature;

   type Selected_Outline_Semantic_Symbol is record
      Available : Boolean := False;
      Name      : Unbounded_String := Null_Unbounded_String;
      Kind      : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
      Profile   : Unbounded_String := Null_Unbounded_String;
   end record;

   function Semantic_Hover
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Ada_Language_Service.Hover_Result;

   function Has_Indexed_Outline_Target
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return Boolean;

   type Outline_Indexed_Target is record
      Available : Boolean := False;
      Path      : Unbounded_String := Null_Unbounded_String;
      Key       : Editor.Ada_Project_Index.Indexed_File_Key;
      Line      : Positive := 1;
      Column    : Positive := 1;
   end record;

   function Strip_Trailing_Word
     (Text : String;
      Word : String) return String
   is
   begin
      if Text'Length > Word'Length
        and then Text (Text'Last - Word'Length + 1 .. Text'Last) = Word
      then
         declare
            Last : Natural := Text'Last - Word'Length;
         begin
            while Last >= Text'First
              and then (Text (Last) = ' ' or else Text (Last) = ASCII.HT)
            loop
               exit when Last = Text'First;
               Last := Last - 1;
            end loop;
            if Last >= Text'First then
               return Text (Text'First .. Last);
            end if;
         end;
      end if;
      return Text;
   end Strip_Trailing_Word;

   function Strip_Prefix
     (Text   : String;
      Prefix : String) return String
   is
   begin
      if Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix
      then
         if Text'First + Prefix'Length <= Text'Last then
            return Text (Text'First + Prefix'Length .. Text'Last);
         else
            return "";
         end if;
      end if;
      return Text;
   end Strip_Prefix;

   function Outline_Row_Base_Name
     (S           : Editor.State.State_Type;
      Outline_Row : Positive) return String
   is
      Label : constant String := Editor.Outline.Item_Label (S.Outline, Outline_Row);
      Name  : Unbounded_String := To_Unbounded_String (Label);
   begin
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic package "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "package body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "package "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic subprogram body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic subprogram "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic procedure body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic procedure "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "procedure body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "procedure "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic function body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic function "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "function body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "function "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "record extension type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "private extension type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "null extension type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "variant record type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "record type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "task body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "task type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "task "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "protected body "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "protected type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "protected "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "entry "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "subtype "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "field "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "discriminant "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "literal "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "object "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "constant "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "exception "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal package "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal procedure "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal function "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal type "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "generic formal object "));
      Name := To_Unbounded_String (Strip_Prefix (To_String (Name), "separate body "));
      Name := To_Unbounded_String (Strip_Trailing_Word (To_String (Name), " renames"));
      Name := To_Unbounded_String (Strip_Trailing_Word (To_String (Name), " instantiation"));
      return To_String (Name);
   end Outline_Row_Base_Name;

   function Outline_Row_Is_Body
     (S           : Editor.State.State_Type;
      Outline_Row : Positive) return Boolean
   is
      Label : constant String := Editor.Outline.Item_Label (S.Outline, Outline_Row);
   begin
      return Label'Length >= 13
        and then
          (Strip_Prefix (Label, "package body ") /= Label
           or else Strip_Prefix (Label, "procedure body ") /= Label
           or else Strip_Prefix (Label, "function body ") /= Label
           or else Strip_Prefix (Label, "generic procedure body ") /= Label
           or else Strip_Prefix (Label, "generic function body ") /= Label
           or else Strip_Prefix (Label, "generic subprogram body ") /= Label
           or else Strip_Prefix (Label, "separate body ") /= Label);
   end Outline_Row_Is_Body;

   function Outline_Row_Is_Separate_Body
     (S           : Editor.State.State_Type;
      Outline_Row : Positive) return Boolean
   is
      Label : constant String := Editor.Outline.Item_Label (S.Outline, Outline_Row);
   begin
      return Strip_Prefix (Label, "separate body ") /= Label;
   end Outline_Row_Is_Separate_Body;

   function Current_File_Has_Indexed_Separate_Body
     (S           : Editor.State.State_Type;
      Name        : String) return Boolean
   is
      Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve (S.Language_Index, Name);
      Path : constant String :=
        (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "");
   begin
      if Path'Length = 0 or else Matches.Overflow then
         return False;
      end if;

      for Match of Matches.Matches loop
         if To_String (Match.Path) = Path
           and then Match.Symbol.Kind =
             Editor.Ada_Language_Model.Symbol_Separate_Body
         then
            return True;
         end if;
      end loop;

      return False;
   end Current_File_Has_Indexed_Separate_Body;

   function Outline_Row_Profile
     (S           : Editor.State.State_Type;
      Outline_Row : Positive) return String
   is
      Detail : constant String := Editor.Outline.Item_Detail (S.Outline, Outline_Row);
      First_Paren : Natural := 0;
      Return_Pos  : Natural := 0;
   begin
      --  Outline details generated from Ada_Language_Model place retained
      --  callable profile summaries after the stable line/form prefix, for
      --  example "line 12 (X : Integer)" or
      --  "line 12 body return Boolean".  Keep this parser deliberately
      --  conservative: it extracts only the two profile shapes currently
      --  emitted by Symbol_Detail and otherwise leaves navigation name/kind
      --  matching unchanged.
      for I in Detail'Range loop
         if Detail (I) = '(' then
            First_Paren := I;
            exit;
         end if;
      end loop;

      if First_Paren /= 0 then
         return Ada.Strings.Fixed.Trim
           (Detail (First_Paren .. Detail'Last), Ada.Strings.Both);
      end if;

      if Detail'Length >= 8 then
         for I in Detail'First .. Detail'Last - 7 loop
            if Detail (I .. I + 7) = " return " then
               Return_Pos := I + 1;
            end if;
         end loop;
      end if;

      if Return_Pos /= 0 then
         return Ada.Strings.Fixed.Trim
           (Detail (Return_Pos .. Detail'Last), Ada.Strings.Both);
      end if;

      return "";
   end Outline_Row_Profile;

   function Selected_Outline_Symbol
     (S : Editor.State.State_Type) return Selected_Outline_Semantic_Symbol
   is
      Panel_Row   : Natural := 0;
      Outline_Row : Natural := 0;
      Row_Kind    : Editor.Outline.Outline_Item_Kind := Editor.Outline.Outline_Unknown;
      Name        : Unbounded_String := Null_Unbounded_String;
      Kind        : Editor.Ada_Language_Model.Symbol_Kind :=
        Editor.Ada_Language_Model.Symbol_Unknown;
   begin
      if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
        or else not Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
      then
         return (others => <>);
      end if;

      Panel_Row := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
      Outline_Row := Editor.Outline.Map_Panel_Row_To_Outline_Row
        (S.Outline, S.Feature_Panel, Panel_Row);
      if Outline_Row = 0
        or else not Editor.Outline.Validate_Outline_Row_For_Selection
          (S.Outline, S.Feature_Panel, Panel_Row)
      then
         return (others => <>);
      end if;

      Name := To_Unbounded_String
        (Outline_Row_Base_Name (S, Positive (Outline_Row)));
      if Length (Name) = 0 then
         return (others => <>);
      end if;

      Row_Kind := Editor.Outline.Item_Kind (S.Outline, Positive (Outline_Row));
      case Row_Kind is
         when Editor.Outline.Outline_Package =>
            Kind := Editor.Ada_Language_Model.Symbol_Package;
         when Editor.Outline.Outline_Package_Body =>
            Kind := Editor.Ada_Language_Model.Symbol_Package_Body;
         when Editor.Outline.Outline_Procedure =>
            Kind := Editor.Ada_Language_Model.Symbol_Procedure;
         when Editor.Outline.Outline_Function =>
            Kind := Editor.Ada_Language_Model.Symbol_Function;
         when Editor.Outline.Outline_Subprogram =>
            Kind := Editor.Ada_Language_Model.Symbol_Procedure;
         when Editor.Outline.Outline_Type =>
            Kind := Editor.Ada_Language_Model.Symbol_Type;
         when Editor.Outline.Outline_Task =>
            Kind := Editor.Ada_Language_Model.Symbol_Task;
         when Editor.Outline.Outline_Protected =>
            Kind := Editor.Ada_Language_Model.Symbol_Protected;
         when Editor.Outline.Outline_Field =>
            Kind := Editor.Ada_Language_Model.Symbol_Record_Component;
         when Editor.Outline.Outline_Discriminant =>
            Kind := Editor.Ada_Language_Model.Symbol_Discriminant;
         when Editor.Outline.Outline_Enum_Literal =>
            Kind := Editor.Ada_Language_Model.Symbol_Enumeration_Literal;
         when Editor.Outline.Outline_Exception =>
            Kind := Editor.Ada_Language_Model.Symbol_Exception;
         when Editor.Outline.Outline_Object =>
            Kind := Editor.Ada_Language_Model.Symbol_Object;
         when Editor.Outline.Outline_Generic_Formal =>
            Kind := Editor.Ada_Language_Model.Symbol_Generic_Formal_Type;
         when others =>
            Kind := Editor.Ada_Language_Model.Symbol_Unknown;
      end case;

      if Kind = Editor.Ada_Language_Model.Symbol_Unknown then
         return (others => <>);
      end if;

      return
        (Available => True,
         Name      => Name,
         Kind      => Kind,
         Profile   => To_Unbounded_String
           (Outline_Row_Profile (S, Positive (Outline_Row))));
   end Selected_Outline_Symbol;

   function Is_Ada_Identifier_Start (Ch : Character) return Boolean is
   begin
      return (Ch >= 'A' and then Ch <= 'Z')
        or else (Ch >= 'a' and then Ch <= 'z');
   end Is_Ada_Identifier_Start;

   function Is_Ada_Identifier_Part (Ch : Character) return Boolean is
   begin
      return Is_Ada_Identifier_Start (Ch)
        or else (Ch >= '0' and then Ch <= '9')
        or else Ch = '_';
   end Is_Ada_Identifier_Part;

   function Caret_Semantic_Symbol
     (S : Editor.State.State_Type) return Selected_Outline_Semantic_Symbol
   is
      Text       : constant String := Editor.State.Current_Text (S);
      Caret_Pos  : Natural := 0;
      Probe      : Natural;
      First_Char : Natural;
      Last_Char  : Natural;
   begin
      if Text'Length = 0 or else S.Carets.Length = 0 then
         return (others => <>);
      end if;

      Caret_Pos := Natural (S.Carets (S.Carets.First_Index).Pos);
      if Caret_Pos >= Text'Length then
         Probe := Text'Last;
      else
         Probe := Text'First + Caret_Pos;
      end if;

      if not Is_Ada_Identifier_Part (Text (Probe))
        and then Probe > Text'First
        and then Is_Ada_Identifier_Part (Text (Probe - 1))
      then
         Probe := Probe - 1;
      end if;

      if not Is_Ada_Identifier_Part (Text (Probe)) then
         return (others => <>);
      end if;

      First_Char := Probe;
      while First_Char > Text'First
        and then Is_Ada_Identifier_Part (Text (First_Char - 1))
      loop
         First_Char := First_Char - 1;
      end loop;

      Last_Char := Probe;
      while Last_Char < Text'Last
        and then Is_Ada_Identifier_Part (Text (Last_Char + 1))
      loop
         Last_Char := Last_Char + 1;
      end loop;

      if not Is_Ada_Identifier_Start (Text (First_Char)) then
         return (others => <>);
      end if;

      return
        (Available => True,
         Name      => To_Unbounded_String (Text (First_Char .. Last_Char)),
         Kind      => Editor.Ada_Language_Model.Symbol_Unknown,
         Profile   => Null_Unbounded_String);
   end Caret_Semantic_Symbol;

   function Current_Semantic_Symbol
     (S : Editor.State.State_Type) return Selected_Outline_Semantic_Symbol
   is
      Outline_Symbol : constant Selected_Outline_Semantic_Symbol :=
        Selected_Outline_Symbol (S);
   begin
      if Outline_Symbol.Available then
         return Outline_Symbol;
      end if;

      return Caret_Semantic_Symbol (S);
   end Current_Semantic_Symbol;

   function Current_Completion_Symbol
     (S : Editor.State.State_Type) return Selected_Outline_Semantic_Symbol
   is
      Caret_Symbol : constant Selected_Outline_Semantic_Symbol :=
        Caret_Semantic_Symbol (S);
   begin
      if Caret_Symbol.Available then
         return Caret_Symbol;
      end if;

      return Selected_Outline_Symbol (S);
   end Current_Completion_Symbol;

   function Current_Semantic_Symbol_Name
     (State : Editor.State.State_Type) return String
   is
      Symbol : constant Selected_Outline_Semantic_Symbol :=
        Current_Semantic_Symbol (State);
   begin
      if Symbol.Available then
         return To_String (Symbol.Name);
      end if;

      return "";
   end Current_Semantic_Symbol_Name;

   function Service_Status_Image
     (Status : Editor.Ada_Language_Service.Service_Status) return String
   is
   begin
      case Status is
         when Editor.Ada_Language_Service.Service_Success =>
            return "success";
         when Editor.Ada_Language_Service.Service_Unavailable =>
            return "unavailable";
         when Editor.Ada_Language_Service.Service_Ambiguous =>
            return "ambiguous";
         when Editor.Ada_Language_Service.Service_Overflow =>
            return "overflow";
         when Editor.Ada_Language_Service.Service_Stale =>
            return "stale";
      end case;
   end Service_Status_Image;

   function Current_Language_Service
     (S : Editor.State.State_Type)
      return Editor.Ada_Language_Service.Service_State
   is
      Service_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Service);
      Index_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Index);
   begin
      if Service_Status.File_Count = Index_Status.File_Count
        and then Service_Status.Unit_Count = Index_Status.Unit_Count
        and then Service_Status.Symbol_Count = Index_Status.Symbol_Count
        and then Service_Status.Fingerprint = Index_Status.Fingerprint
        and then Service_Status.Overflowed = Index_Status.Overflowed
      then
         return S.Language_Service;
      end if;

      return Editor.Ada_Language_Service.From_Index (S.Language_Index);
   end Current_Language_Service;

   procedure Ensure_Current_Language_Service
     (S : in out Editor.State.State_Type)
   is
      Service_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Service);
      Index_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Index);
   begin
      if Service_Status.File_Count /= Index_Status.File_Count
        or else Service_Status.Unit_Count /= Index_Status.Unit_Count
        or else Service_Status.Symbol_Count /= Index_Status.Symbol_Count
        or else Service_Status.Fingerprint /= Index_Status.Fingerprint
        or else Service_Status.Overflowed /= Index_Status.Overflowed
      then
         Editor.Ada_Language_Service.Put_Index
         (S.Language_Service, S.Language_Index);
      end if;
   end Ensure_Current_Language_Service;

   function Current_Semantic_Analysis_Fingerprint
     (S    : Editor.State.State_Type;
      Path : String) return Natural
   is
      Indexed_Fingerprint : constant Natural :=
        Editor.Ada_Project_Index.Current_Analysis_Fingerprint
          (S.Language_Index,
           Path,
           S.Active_Buffer_Token,
           Editor.State.Current_Buffer_Revision (S),
           Editor.State.Current_Lifecycle_Generation (S));
   begin
      if Indexed_Fingerprint /= 0 then
         return Indexed_Fingerprint;
      end if;

      return Editor.Ada_Language_Model.Fingerprint (S.Syntax_Analysis);
   end Current_Semantic_Analysis_Fingerprint;

   function Semantic_Declaration_Target
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Symbol  : Selected_Outline_Semantic_Symbol)
      return Editor.Ada_Language_Service.Language_Target
   is
      Name         : constant String := To_String (Symbol.Name);
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Target       : Editor.Ada_Language_Service.Language_Target;
      Req          : Editor.Ada_Language_Service.Semantic_Request_Id;
   begin
      if Current_File.Has_Path
        and then S.Active_Buffer_Token /= 0
      then
         declare
            Current_Path : constant String := To_String (Current_File.Path);
            Fingerprint  : constant Natural :=
              Current_Semantic_Analysis_Fingerprint (S, Current_Path);
         begin
            Req := Editor.Ada_Language_Service.Begin_Semantic_Request
              (Service,
               Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration,
                  Name, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint,
                  Detail => Editor.Ada_Language_Model.Symbol_Kind'Image
                    (Symbol.Kind)));
            Target := Editor.Ada_Language_Service.Request_Goto_Declaration_Current
              (Service, Req, Name, Symbol.Kind, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint);
         end;
      else
         Req := Editor.Ada_Language_Service.Begin_Semantic_Request
           (Service,
            Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration,
            Editor.Ada_Language_Service.Semantic_Request_Query_Key
              (Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration,
               Name,
               Detail => Editor.Ada_Language_Model.Symbol_Kind'Image
                 (Symbol.Kind)));
         Target := Editor.Ada_Language_Service.Request_Goto_Declaration
           (Service, Req, Name, Symbol.Kind);
      end if;

      if Target.Status = Editor.Ada_Language_Service.Service_Success
        or else Symbol.Kind /= Editor.Ada_Language_Model.Symbol_Unknown
      then
         return Target;
      end if;

      declare
         Hover : constant Editor.Ada_Language_Service.Hover_Result :=
           Semantic_Hover (S, Service, Name);
      begin
         if Hover.Status = Editor.Ada_Language_Service.Service_Success then
            return
              (Status => Hover.Status,
               Target => Hover.Target,
               Key    => Hover.Key,
               Name   => Hover.Label,
               Detail => Hover.Detail);
         end if;

         Target.Status := Hover.Status;
      end;

      return Target;
   end Semantic_Declaration_Target;

   function Active_Outline_Source_Is_Current
     (S : Editor.State.State_Type) return Boolean
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Freshness : Editor.Outline.Outline_Freshness;
   begin
      if not Current_File.Has_Path
        or else S.Active_Buffer_Token = 0
      then
         return True;
      end if;

      Freshness := Editor.Outline.Freshness_For_Active_Buffer
        (S.Outline,
         S.Active_Buffer_Token,
         Editor.State.Current_Buffer_Revision (S));
      return Freshness /= Editor.Outline.Outline_Stale;
   end Active_Outline_Source_Is_Current;

   function Semantic_Find_References
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Ada_Language_Service.Language_Target_Set
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Req : Editor.Ada_Language_Service.Semantic_Request_Id;
   begin
      if Current_File.Has_Path
        and then S.Active_Buffer_Token /= 0
      then
         declare
            Current_Path : constant String := To_String (Current_File.Path);
            Fingerprint  : constant Natural :=
              Current_Semantic_Analysis_Fingerprint (S, Current_Path);
         begin
            Req := Editor.Ada_Language_Service.Begin_Semantic_Request
              (Service,
               Editor.Ada_Language_Service.Semantic_Request_Find_References,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Find_References,
                  Name, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint));
            return Editor.Ada_Language_Service.Request_Find_Current_References
              (Service, Req, Name, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint);
         end;
      end if;

      Req := Editor.Ada_Language_Service.Begin_Semantic_Request
        (Service, Editor.Ada_Language_Service.Semantic_Request_Find_References,
         Name);
      return Editor.Ada_Language_Service.Request_Find_References
        (Service, Req, Name);
   end Semantic_Find_References;

   function Semantic_Workspace_Symbols
     (Service : in out Editor.Ada_Language_Service.Service_State;
      Query   : String)
      return Editor.Ada_Language_Service.Language_Target_Set
   is
      Req : constant Editor.Ada_Language_Service.Semantic_Request_Id :=
        Editor.Ada_Language_Service.Begin_Semantic_Request
          (Service,
           Editor.Ada_Language_Service.Semantic_Request_Workspace_Symbols,
           Query);
   begin
      return Editor.Ada_Language_Service.Request_Workspace_Symbols
        (Service, Req, Query);
   end Semantic_Workspace_Symbols;

   function Semantic_Hover
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Name    : String)
      return Editor.Ada_Language_Service.Hover_Result
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Req : Editor.Ada_Language_Service.Semantic_Request_Id;
   begin
      if Current_File.Has_Path
        and then S.Active_Buffer_Token /= 0
      then
         declare
            Current_Path : constant String := To_String (Current_File.Path);
            Fingerprint  : constant Natural :=
              Current_Semantic_Analysis_Fingerprint (S, Current_Path);
         begin
            Req := Editor.Ada_Language_Service.Begin_Semantic_Request
              (Service, Editor.Ada_Language_Service.Semantic_Request_Hover,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Hover,
                  Name, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint));
            return Editor.Ada_Language_Service.Request_Hover_Current
              (Service, Req, Name, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint);
         end;
      end if;

      Req := Editor.Ada_Language_Service.Begin_Semantic_Request
        (Service, Editor.Ada_Language_Service.Semantic_Request_Hover, Name);
      return Editor.Ada_Language_Service.Request_Hover (Service, Req, Name);
   end Semantic_Hover;

   function Semantic_Complete
     (S       : Editor.State.State_Type;
      Service : in out Editor.Ada_Language_Service.Service_State;
      Prefix  : String;
      Limit   : Positive)
      return Editor.Ada_Language_Service.Completion_Result
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Req : Editor.Ada_Language_Service.Semantic_Request_Id;
   begin
      if Current_File.Has_Path
        and then S.Active_Buffer_Token /= 0
      then
         declare
            Current_Path : constant String := To_String (Current_File.Path);
            Fingerprint  : constant Natural :=
              Current_Semantic_Analysis_Fingerprint (S, Current_Path);
         begin
            Req := Editor.Ada_Language_Service.Begin_Semantic_Request
              (Service, Editor.Ada_Language_Service.Semantic_Request_Completion,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Completion,
                  Prefix, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint,
                  Detail => Positive'Image (Limit)));
            return Editor.Ada_Language_Service.Request_Complete_Current
              (Service, Req, Prefix, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint,
               Limit);
         end;
      end if;

      Req := Editor.Ada_Language_Service.Begin_Semantic_Request
        (Service, Editor.Ada_Language_Service.Semantic_Request_Completion,
         Editor.Ada_Language_Service.Semantic_Request_Query_Key
           (Editor.Ada_Language_Service.Semantic_Request_Completion,
            Prefix, Detail => Positive'Image (Limit)));
      return Editor.Ada_Language_Service.Request_Complete
        (Service, Req, Prefix, Limit);
   end Semantic_Complete;

   procedure Clear_Semantic_Popup
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Completion_Commands
        .Clear_Semantic_Popup;

   function Semantic_Completion_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean
      renames Editor.Executor.Semantic_Completion_Commands
        .Semantic_Completion_Popup_Is_Active;

   procedure Execute_Semantic_Completion_Select
     (S    : in out Editor.State.State_Type;
      Next : Boolean)
      renames Editor.Executor.Semantic_Completion_Commands
        .Execute_Semantic_Completion_Select;

   procedure Execute_Semantic_Completion_Accept
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Semantic_Completion_Commands
        .Execute_Semantic_Completion_Accept;

   function Semantic_Rename_Preview
     (S        : Editor.State.State_Type;
      Service  : in out Editor.Ada_Language_Service.Service_State;
      Old_Name : String;
      New_Name : String)
      return Editor.Ada_Language_Service.Rename_Preview
   is
      Current_File : constant Editor.State.File_State :=
        Editor.State.Current_File (S);
      Req : Editor.Ada_Language_Service.Semantic_Request_Id;
   begin
      if Current_File.Has_Path
        and then S.Active_Buffer_Token /= 0
      then
         declare
            Current_Path : constant String := To_String (Current_File.Path);
            Fingerprint  : constant Natural :=
              Current_Semantic_Analysis_Fingerprint (S, Current_Path);
         begin
            Req := Editor.Ada_Language_Service.Begin_Semantic_Request
              (Service, Editor.Ada_Language_Service.Semantic_Request_Rename,
               Editor.Ada_Language_Service.Semantic_Current_Request_Query_Key
                 (Editor.Ada_Language_Service.Semantic_Request_Rename,
                  Old_Name, Current_Path,
                  S.Active_Buffer_Token,
                  Editor.State.Current_Buffer_Revision (S),
                  Editor.State.Current_Lifecycle_Generation (S),
                  Fingerprint,
                  Detail => New_Name));
            return Editor.Ada_Language_Service.Request_Preview_Rename_Current
              (Service, Req, Old_Name, New_Name, Current_Path,
               S.Active_Buffer_Token,
               Editor.State.Current_Buffer_Revision (S),
               Editor.State.Current_Lifecycle_Generation (S),
               Fingerprint);
         end;
      end if;

      Req := Editor.Ada_Language_Service.Begin_Semantic_Request
        (Service, Editor.Ada_Language_Service.Semantic_Request_Rename,
         Editor.Ada_Language_Service.Semantic_Request_Query_Key
           (Editor.Ada_Language_Service.Semantic_Request_Rename,
            Old_Name, Detail => New_Name));
      return Editor.Ada_Language_Service.Request_Preview_Rename
        (Service, Req, Old_Name, New_Name);
   end Semantic_Rename_Preview;

   function Selected_Outline_Language_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      Symbol  : constant Selected_Outline_Semantic_Symbol :=
        (if Id = Editor.Commands.Command_Show_Completions
         then Current_Completion_Symbol (S)
         else Current_Semantic_Symbol (S));
      Service : Editor.Ada_Language_Service.Service_State :=
        Current_Language_Service (S);
      Name    : constant String := To_String (Symbol.Name);
   begin
      if not Symbol.Available then
         return Editor.Commands.Unavailable ("No semantic symbol at cursor or Outline selection.");
      end if;

      case Id is
         when Editor.Commands.Command_Find_References =>
            declare
               Result : constant Editor.Ada_Language_Service.Language_Target_Set :=
                 Semantic_Find_References (S, Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("References unavailable for " & Name & ": " &
                 Service_Status_Image (Result.Status) & ".");
            end;

         when Editor.Commands.Command_Workspace_Symbols =>
            declare
               Result : constant Editor.Ada_Language_Service.Language_Target_Set :=
                 Semantic_Workspace_Symbols (Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("Workspace symbols unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
            end;

         when Editor.Commands.Command_Show_Hover =>
            declare
               Result : constant Editor.Ada_Language_Service.Hover_Result :=
                 Semantic_Hover (S, Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("Hover unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
            end;

         when Editor.Commands.Command_Show_Completions =>
            declare
               Result : constant Editor.Ada_Language_Service.Completion_Result :=
                 Semantic_Complete (S, Service, Name, 20);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("Completions unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
            end;

         when Editor.Commands.Command_Rename_Symbol_Preview =>
            declare
               Result : constant Editor.Ada_Language_Service.Rename_Preview :=
                 Semantic_Rename_Preview
                   (S, Service, Name, Name & "_Renamed");
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success
                 or else Result.Status = Editor.Ada_Language_Service.Service_Ambiguous
               then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable
                 ("Rename preview unavailable for " & Name & ": " &
                 Service_Status_Image (Result.Status) & ".");
            end;

         when Editor.Commands.Command_Rename_Symbol_Apply =>
            declare
               Result : constant Editor.Ada_Language_Service.Rename_Preview :=
                 Semantic_Rename_Preview
                   (S, Service, Name, Name & "_Renamed");
               Reason : Unbounded_String;
            begin
               if Editor.Executor.Rename_Preview_Is_Open_Buffers_Applyable
                 (S, Result, Reason)
               then
                  return Editor.Commands.Available;
               end if;
               return Editor.Commands.Unavailable (To_String (Reason));
            end;

         when others =>
            return Editor.Commands.Unavailable ("Unsupported language command.");
      end case;
   end Selected_Outline_Language_Command_Availability;

   function Semantic_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Refresh_Outline_Project_Index
            | Editor.Commands.Command_Semantic_Refresh_Buffer
            | Editor.Commands.Command_Semantic_Refresh_Project_Index =>
            if not Editor.State.Has_Active_Buffer (S) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Active_Buffer);
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Language_Index_Clear
            | Editor.Commands.Command_Language_Index_Status =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Goto_Declaration =>
            if Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
              and then Editor.Executor.Has_Selected_Outline_Activation_Target (S)
            then
               return Editor.Commands.Available;
            else
               declare
                  Symbol  : constant Selected_Outline_Semantic_Symbol :=
                    Current_Semantic_Symbol (S);
                  Service : Editor.Ada_Language_Service.Service_State :=
                    Current_Language_Service (S);
                  Target  : Editor.Ada_Language_Service.Language_Target;
               begin
                  if not Symbol.Available then
                     return Editor.Commands.Unavailable
                       ("No semantic symbol at cursor or Outline selection.");
                  end if;

                  Target := Semantic_Declaration_Target (S, Service, Symbol);
                  if Target.Status =
                    Editor.Ada_Language_Service.Service_Success
                  then
                     return Editor.Commands.Available;
                  end if;

                  return Editor.Commands.Unavailable
                    ("Declaration unavailable for " & To_String (Symbol.Name) &
                     ": " & Service_Status_Image (Target.Status) & ".");
               end;
            end if;

         when Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec =>
            if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_Feature_Panel_Hidden);
            elsif not Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
              or else not Editor.Outline.Validate_Outline_Row_For_Selection
                (S.Outline,
                 S.Feature_Panel,
                 Editor.Feature_Panel.Selected_Row (S.Feature_Panel))
            then
               return Editor.Commands.Unavailable
                 (Editor.Outline.Reason_No_Outline_Item_Selected);
            elsif not Has_Indexed_Outline_Target (S, Id) then
               return Editor.Commands.Unavailable
                 ("Outline indexed target unavailable");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Find_References
            | Editor.Commands.Command_Workspace_Symbols
            | Editor.Commands.Command_Show_Hover
            | Editor.Commands.Command_Show_Completions
            | Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply =>
            return Selected_Outline_Language_Command_Availability (S, Id);

         when Editor.Commands.Command_Semantic_Completion_Select_Next
            | Editor.Commands.Command_Semantic_Completion_Select_Previous
            | Editor.Commands.Command_Semantic_Completion_Accept =>
            if Semantic_Completion_Popup_Is_Active (S) then
               return Editor.Commands.Available;
            end if;
            return Editor.Commands.Unavailable ("No completion menu is open.");

         when Editor.Commands.Command_Semantic_Popup_Dismiss =>
            if S.Semantic_Popup.Active then
               return Editor.Commands.Available;
            end if;
            return Editor.Commands.Unavailable ("No semantic popup is open.");

         when others =>
            return Editor.Commands.Unavailable
              ("Unsupported semantic command.");
      end case;
   end Semantic_Command_Availability;

   function Execute_Selected_Outline_Language_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Target_Name : String := "")
      return Editor.Command_Execution.Command_Execution_Result
   is
      Symbol  : constant Selected_Outline_Semantic_Symbol :=
        (if Id = Editor.Commands.Command_Show_Completions
         then Current_Completion_Symbol (S)
         else Current_Semantic_Symbol (S));
      Name    : constant String := To_String (Symbol.Name);
      Rename_To : constant String :=
        (if Target_Name'Length > 0 then Target_Name else Name & "_Renamed");
   begin
      Ensure_Current_Language_Service (S);
      if not Symbol.Available then
         Report_Info (S, "No semantic symbol at cursor or Outline selection.");
         Editor.Render_Cache.Invalidate_All;
         return Editor.Command_Execution.Unavailable (Id);
      end if;

      case Id is
         when Editor.Commands.Command_Find_References =>
            declare
               Result : constant Editor.Ada_Language_Service.Language_Target_Set :=
                 Semantic_Find_References (S, S.Language_Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  Editor.Feature_Search_Results.Begin_External_Result_Set
                    (S.Feature_Search_Results,
                     Query        => "references: " & Name,
                     Source_Label => "Ada semantic references");

                  for Target of Result.Targets loop
                     declare
                        Path   : constant String := To_String (Target.Target.Path);
                        Line   : constant Natural := Target.Target.Line;
                        Column : constant Natural := Target.Target.Column;
                        Label  : constant String :=
                          Name & " at " & Path & ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both) &
                          ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Column), Ada.Strings.Both);
                     begin
                        Editor.Feature_Search_Results.Add_Search_Result
                          (S.Feature_Search_Results,
                           Label         => Label,
                           Source_Label  => Path,
                           Has_Target    => Target.Key.Buffer_Token /= 0,
                           Target_Buffer => Target.Key.Buffer_Token,
                           Target_Line   => Line,
                           Target_Column => Column,
                           Query         => Name,
                           Match_Line    => Line,
                           Match_Column  => Column,
                           Match_Length  => Name'Length);
                     end;
                  end loop;

                  Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
                    (S.Feature_Search_Results, S.Feature_Panel,
                     Select_First_When_Available => True);
                  Editor.Panels.Set_Bottom_Content
                    (S.Panels, Editor.Panels.Search_Results_Content);
                  Editor.Panels.Set_Visible
                    (S.Panels, Editor.Panels.Bottom_Panel, True);
                  if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
                     Editor.Focus_Management.Set_Focus_Owner
                       (S, Editor.Focus_Management.Focus_Project_Search_Results);
                  end if;
                  Editor.Panels.Set_Current (S.Panels);
                  Report_Info
                    (S,
                     "References for " & Name & ":" &
                     Natural'Image (Natural (Result.Targets.Length)) & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "References unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Workspace_Symbols =>
            declare
               Result : constant Editor.Ada_Language_Service.Language_Target_Set :=
                 Semantic_Workspace_Symbols (S.Language_Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  Editor.Feature_Search_Results.Begin_External_Result_Set
                    (S.Feature_Search_Results,
                     Query        => "symbols: " & Name,
                     Source_Label => "Ada workspace symbols");

                  for Target of Result.Targets loop
                     declare
                        Path   : constant String := To_String (Target.Target.Path);
                        Line   : constant Natural := Target.Target.Line;
                        Column : constant Natural := Target.Target.Column;
                        Symbol_Name : constant String := To_String (Target.Name);
                        Label  : constant String :=
                          Symbol_Name & " at " & Path & ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both) &
                          ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Column), Ada.Strings.Both);
                     begin
                        Editor.Feature_Search_Results.Add_Search_Result
                          (S.Feature_Search_Results,
                           Label         => Label,
                           Source_Label  => Path,
                           Has_Target    => Target.Key.Buffer_Token /= 0,
                           Target_Buffer => Target.Key.Buffer_Token,
                           Target_Line   => Line,
                           Target_Column => Column,
                           Query         => Name,
                           Match_Line    => Line,
                           Match_Column  => Column,
                           Match_Length  => Symbol_Name'Length);
                     end;
                  end loop;

                  Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
                    (S.Feature_Search_Results, S.Feature_Panel,
                     Select_First_When_Available => True);
                  Editor.Panels.Set_Bottom_Content
                    (S.Panels, Editor.Panels.Search_Results_Content);
                  Editor.Panels.Set_Visible
                    (S.Panels, Editor.Panels.Bottom_Panel, True);
                  if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
                     Editor.Focus_Management.Set_Focus_Owner
                       (S, Editor.Focus_Management.Focus_Project_Search_Results);
                  end if;
                  Editor.Panels.Set_Current (S.Panels);
                  Report_Info
                    (S,
                     "Workspace symbols for " & Name & ":" &
                     Natural'Image (Natural (Result.Targets.Length)) & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "Workspace symbols unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Show_Hover =>
            declare
               Result : constant Editor.Ada_Language_Service.Hover_Result :=
                 Semantic_Hover (S, S.Language_Service, Name);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  declare
                     Anchor_Row : Natural := 0;
                     Anchor_Col : Natural := 0;
                     Path   : constant String := To_String (Result.Target.Path);
                     Line   : constant Natural := Result.Target.Line;
                     Column : constant Natural := Result.Target.Column;
                     Detail : constant String := To_String (Result.Detail);
                     Label  : constant String :=
                       "hover " & To_String (Result.Label) &
                       (if Detail'Length > 0 then " - " & Detail else "") &
                       " at " & Path & ":" &
                       Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both) &
                       ":" &
                        Ada.Strings.Fixed.Trim (Natural'Image (Column), Ada.Strings.Both);
                  begin
                     Editor.State.Row_Col_For_Index
                       (S, Safe_Caret (S), Anchor_Row, Anchor_Col);
                     S.Semantic_Popup :=
                       (Active => True,
                        Kind => Editor.State.Semantic_Hover_Popup,
                        Anchor_Row => Anchor_Row,
                        Anchor_Column => Anchor_Col,
                        Title => Result.Label,
                        Detail => Result.Detail,
                        Item_Count => 0,
                        Selected_Item => 0,
                        Items => (others => (others => <>)));
                     Editor.Feature_Search_Results.Begin_External_Result_Set
                       (S.Feature_Search_Results,
                        Query        => "hover: " & Name,
                        Source_Label => "Ada semantic hover");
                     Editor.Feature_Search_Results.Add_Search_Result
                       (S.Feature_Search_Results,
                        Label         => Label,
                        Source_Label  => Path,
                        Has_Target    => Result.Key.Buffer_Token /= 0,
                        Target_Buffer => Result.Key.Buffer_Token,
                        Target_Line   => Line,
                        Target_Column => Column,
                        Query         => Name,
                        Match_Line    => Line,
                        Match_Column  => Column,
                        Match_Length  => Name'Length);
                     Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
                       (S.Feature_Search_Results, S.Feature_Panel,
                        Select_First_When_Available => True);
                  end;
                  Report_Info
                    (S,
                     "Hover: " & To_String (Result.Label) &
                     (if Length (Result.Detail) > 0
                      then " - " & To_String (Result.Detail)
                      else "") & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "Hover unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Show_Completions =>
            declare
               Result : constant Editor.Ada_Language_Service.Completion_Result :=
                 Semantic_Complete (S, S.Language_Service, Name, 20);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success then
                  declare
                     Anchor_Row : Natural := 0;
                     Anchor_Col : Natural := 0;
                     Popup : Editor.State.Semantic_Popup_State;
                     Row : Natural := 0;
                  begin
                     Editor.State.Row_Col_For_Index
                       (S, Safe_Caret (S), Anchor_Row, Anchor_Col);
                     Popup.Active := True;
                     Popup.Kind := Editor.State.Semantic_Completion_Popup;
                     Popup.Anchor_Row := Anchor_Row;
                     Popup.Anchor_Column := Anchor_Col;
                     Popup.Title := To_Unbounded_String ("Completions for " & Name);
                     Popup.Selected_Item :=
                       (if Result.Items.Length > 0 then 1 else 0);
                     for Item of Result.Items loop
                        exit when Row >= Editor.State.Max_Semantic_Completion_Items;
                        Row := Row + 1;
                        Popup.Items (Editor.State.Semantic_Completion_Item_Index (Row)) :=
                          (Label  => Item.Label,
                           Detail => Item.Detail);
                     end loop;
                     Popup.Item_Count := Row;
                     S.Semantic_Popup := Popup;
                  end;

                  Editor.Feature_Search_Results.Begin_External_Result_Set
                    (S.Feature_Search_Results,
                     Query        => "completions: " & Name,
                     Source_Label => "Ada semantic completions");

                  for Item of Result.Items loop
                     declare
                        Path   : constant String := To_String (Item.Target.Path);
                        Line   : constant Natural := Item.Target.Line;
                        Column : constant Natural := Item.Target.Column;
                        Item_Label : constant String := To_String (Item.Label);
                        Detail : constant String := To_String (Item.Detail);
                        Label  : constant String :=
                          Item_Label &
                          (if Detail'Length > 0 then " - " & Detail else "") &
                          " at " & Path & ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both) &
                          ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Column), Ada.Strings.Both);
                     begin
                        Editor.Feature_Search_Results.Add_Search_Result
                          (S.Feature_Search_Results,
                           Label         => Label,
                           Source_Label  => Path,
                           Has_Target    => Item.Key.Buffer_Token /= 0,
                           Target_Buffer => Item.Key.Buffer_Token,
                           Target_Line   => Line,
                           Target_Column => Column,
                           Query         => Name,
                           Match_Line    => Line,
                           Match_Column  => Column,
                           Match_Length  => Item_Label'Length);
                     end;
                  end loop;

                  Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
                    (S.Feature_Search_Results, S.Feature_Panel,
                     Select_First_When_Available => True);
                  Report_Info
                    (S,
                     "Completions for " & Name & ":" &
                     Natural'Image (Natural (Result.Items.Length)) & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "Completions unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Rename_Symbol_Preview =>
            declare
               Result : constant Editor.Ada_Language_Service.Rename_Preview :=
                 Semantic_Rename_Preview
                   (S, S.Language_Service, Name, Rename_To);
            begin
               if Result.Status = Editor.Ada_Language_Service.Service_Success
                 or else Result.Status = Editor.Ada_Language_Service.Service_Ambiguous
               then
                  Editor.Feature_Search_Results.Begin_External_Result_Set
                    (S.Feature_Search_Results,
                     Query        => "rename: " & Name & " -> " & Rename_To,
                     Source_Label => "Ada semantic rename preview");

                  for Target of Result.Edits loop
                     declare
                        Path   : constant String := To_String (Target.Target.Path);
                        Line   : constant Natural := Target.Target.Line;
                        Column : constant Natural := Target.Target.Column;
                        Label  : constant String :=
                          "edit " & Name & " -> " & Rename_To & " at " &
                          Path & ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both) &
                          ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Column), Ada.Strings.Both);
                     begin
                        Editor.Feature_Search_Results.Add_Search_Result
                          (S.Feature_Search_Results,
                           Label         => Label,
                           Source_Label  => Path,
                           Has_Target    => Target.Key.Buffer_Token /= 0,
                           Target_Buffer => Target.Key.Buffer_Token,
                           Target_Line   => Line,
                           Target_Column => Column,
                           Query         => Name,
                           Match_Line    => Line,
                           Match_Column  => Column,
                           Match_Length  => Name'Length);
                     end;
                  end loop;

                  for Target of Result.Conflicts loop
                     declare
                        Path   : constant String := To_String (Target.Target.Path);
                        Line   : constant Natural := Target.Target.Line;
                        Column : constant Natural := Target.Target.Column;
                        Conflict_Name : constant String := To_String (Target.Name);
                        Label  : constant String :=
                          "conflict " & Conflict_Name & " at " & Path & ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Line), Ada.Strings.Both) &
                          ":" &
                          Ada.Strings.Fixed.Trim (Natural'Image (Column), Ada.Strings.Both);
                     begin
                        Editor.Feature_Search_Results.Add_Search_Result
                          (S.Feature_Search_Results,
                           Label         => Label,
                           Source_Label  => Path,
                           Has_Target    => Target.Key.Buffer_Token /= 0,
                           Target_Buffer => Target.Key.Buffer_Token,
                           Target_Line   => Line,
                           Target_Column => Column,
                           Query         => Conflict_Name,
                           Match_Line    => Line,
                           Match_Column  => Column,
                           Match_Length  => Conflict_Name'Length);
                     end;
                  end loop;

                  Editor.Feature_Search_Results.Reconcile_Search_Results_After_Row_Change
                    (S.Feature_Search_Results, S.Feature_Panel,
                     Select_First_When_Available => True);
                  Editor.Panels.Set_Bottom_Content
                    (S.Panels, Editor.Panels.Search_Results_Content);
                  Editor.Panels.Set_Visible
                    (S.Panels, Editor.Panels.Bottom_Panel, True);
                  if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
                     Editor.Focus_Management.Set_Focus_Owner
                       (S, Editor.Focus_Management.Focus_Project_Search_Results);
                  end if;
                  Editor.Panels.Set_Current (S.Panels);
                  Report_Info
                    (S,
                     "Rename preview for " & Name & ":" &
                     Natural'Image (Result.Edit_Count) & " edits," &
                     Natural'Image (Result.Conflict_Count) & " conflicts.");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Executed (Id);
               end if;

               Report_Info
                 (S, "Rename preview unavailable for " & Name & ": " &
                  Service_Status_Image (Result.Status) & ".");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Rename_Symbol_Apply =>
            declare
               Result : constant Editor.Ada_Language_Service.Rename_Preview :=
                 Semantic_Rename_Preview
                   (S, S.Language_Service, Name, Rename_To);
               Reason : Unbounded_String;
               Applied_Count : Natural := 0;
               Processed : Editor.Ada_Language_Service.Language_Target_Vectors.Vector;

               function Same_Apply_Target
                 (Left, Right : Editor.Ada_Language_Service.Language_Target)
                  return Boolean
               is
               begin
                  if Left.Key.Buffer_Token /= 0
                    and then Right.Key.Buffer_Token /= 0
                  then
                     return Left.Key.Buffer_Token = Right.Key.Buffer_Token;
                  end if;

                  return To_String (Left.Target.Path) =
                    To_String (Right.Target.Path);
               end Same_Apply_Target;
            begin
               Editor.Buffers.Ensure_Global_Registry (S);

               if not Editor.Executor.Rename_Preview_Is_Open_Buffers_Applyable
                 (S, Result, Reason)
               then
                  Report_Info (S, To_String (Reason));
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Unavailable (Id);
               end if;

               for Target of Result.Edits loop
                  declare
                     Already_Processed : Boolean := False;
                  begin
                     for Seen of Processed loop
                        if Same_Apply_Target (Seen, Target) then
                           Already_Processed := True;
                           exit;
                        end if;
                     end loop;

                     if not Already_Processed then
                        declare
                           Found_Open : Boolean := False;
                           Buffer_Id  : Editor.Buffers.Buffer_Id :=
                             Editor.Buffers.No_Buffer;
                           Buffer_State : Editor.State.State_Type;
                           Open_Result : Editor.Files.File_Open_Result;
                           Cmd : Editor.Commands.Command;
                           Before_Text : Unbounded_String;
                           Replaced : Boolean := False;
                        begin
                           if Target.Key.Buffer_Token = S.Active_Buffer_Token then
                              Buffer_Id := Editor.Buffers.Buffer_Id
                                (S.Active_Buffer_Token);
                              Found_Open := True;
                              Buffer_State := S;
                           elsif Target.Key.Buffer_Token /= 0
                             and then Editor.Buffers.Global_Contains
                               (Editor.Buffers.Buffer_Id
                                  (Target.Key.Buffer_Token))
                           then
                              Buffer_Id := Editor.Buffers.Buffer_Id
                                (Target.Key.Buffer_Token);
                              Found_Open := True;
                              Buffer_State :=
                                Editor.Buffers.Global_Buffer (Buffer_Id);
                           else
                              Buffer_Id := Editor.Buffers.Global_Find_By_Path
                                (To_String (Target.Target.Path), Found_Open);
                              if Found_Open then
                                 Buffer_State :=
                                   Editor.Buffers.Global_Buffer (Buffer_Id);
                              else
                                 Open_Result := Editor.Files.Open_File
                                   (To_String (Target.Target.Path));
                                 Editor.State.Initialize (Buffer_State);
                                 Editor.State.Replace_Buffer_Contents
                                   (Buffer_State,
                                    To_String (Open_Result.Contents));
                                 Buffer_State.File_Info.Has_Path := True;
                                 Buffer_State.File_Info.Path :=
                                   Open_Result.Path;
                                 Buffer_State.File_Info.Display_Name :=
                                   Open_Result.Display_Name;
                              end if;
                           end if;

                           Before_Text := To_Unbounded_String
                             (Editor.State.Current_Text (Buffer_State));
                           Cmd.Kind := Editor.Commands.Apply_Replace_Batch;

                           for Edit of Result.Edits loop
                              if Same_Apply_Target (Edit, Target) then
                                 declare
                                    Pos : constant Natural :=
                                      Editor.Navigation.Index_For_Line_Column
                                        (Buffer_State,
                                         Edit.Target.Line - 1,
                                         Edit.Target.Column - 1);
                                    Current : constant String :=
                                      To_String
                                        (Extract_Text
                                           (Buffer_State.Buffer, Pos,
                                            Name'Length));
                                 begin
                                    if Current = Name then
                                       Append_Replace_Op
                                         (Cmd, Cursor_Index (Pos),
                                          Name'Length,
                                          To_Unbounded_String (Rename_To));
                                    end if;
                                 end;
                              end if;
                           end loop;

                           if Cmd.Positions.Length > 0 then
                              Editor.Executor.History.Apply_Replace_Batch_Command
                                (Buffer_State, Cmd);
                              if Editor.State.Current_Text (Buffer_State) /=
                                Before_Text
                              then
                                 if Found_Open then
                                    Editor.Buffers.Global_Replace_Buffer_Contents
                                      (Buffer_Id,
                                       Editor.State.Current_Text
                                         (Buffer_State),
                                       Replaced);
                                 else
                                    Replaced :=
                                      Editor.Files.Save_File
                                        (To_String (Target.Target.Path),
                                         Editor.State.Current_Text
                                           (Buffer_State)).Status =
                                      Editor.Files.File_Save_Ok;
                                 end if;

                                 if Replaced then
                                    if Found_Open then
                                       Editor.Ada_Project_Index.Invalidate_Buffer
                                         (S.Language_Index,
                                          Natural (Buffer_Id));
                                       Editor.Ada_Language_Service.Invalidate_Buffer
                                         (S.Language_Service,
                                          Natural (Buffer_Id));
                                    else
                                       Editor.Ada_Project_Index.Invalidate_Path
                                         (S.Language_Index,
                                          To_String (Target.Target.Path));
                                       Editor.Ada_Language_Service.Invalidate_Path
                                         (S.Language_Service,
                                          To_String (Target.Target.Path));
                                    end if;

                                    Applied_Count :=
                                      Applied_Count +
                                      Natural (Cmd.Positions.Length);
                                 end if;
                              end if;
                           end if;
                        end;

                        Processed.Append (Target);
                     end if;
                  end;
               end loop;

               if Applied_Count = 0 then
                  Report_Info
                    (S, "Rename apply for " & Name & ": no edits.");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.No_Op (Id);
               end if;

               Editor.Buffers.Load_Global_Active_Into_State (S);

               Report_Info
                 (S,
                  "Rename applied for " & Name & ":" &
                  Natural'Image (Applied_Count) & " edits.");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Executed (Id);
            end;

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Selected_Outline_Language_Command;

   function Find_Indexed_Outline_Target
     (S             : Editor.State.State_Type;
      Id            : Editor.Commands.Command_Id;
      Service       : in out Editor.Ada_Language_Service.Service_State;
      Track_Request : Boolean := False) return Outline_Indexed_Target
   is
      Panel_Row : Natural := 0;
      Outline_Row : Natural := 0;
      Name : Unbounded_String := Null_Unbounded_String;
      Row_Kind : Editor.Outline.Outline_Item_Kind := Editor.Outline.Outline_Unknown;
      Row_Is_Body : Boolean := False;
      Row_Profile : Unbounded_String := Null_Unbounded_String;
      Wanted : Editor.Ada_Language_Model.Symbol_Kind := Editor.Ada_Language_Model.Symbol_Unknown;
   begin
      if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
        or else not Editor.Feature_Panel.Has_Selection (S.Feature_Panel)
      then
         return (others => <>);
      elsif not Active_Outline_Source_Is_Current (S) then
         return (others => <>);
      end if;

      Panel_Row := Editor.Feature_Panel.Selected_Row (S.Feature_Panel);
      Outline_Row := Editor.Outline.Map_Panel_Row_To_Outline_Row
        (S.Outline, S.Feature_Panel, Panel_Row);
      if Outline_Row = 0
        or else not Editor.Outline.Validate_Outline_Row_For_Selection
          (S.Outline, S.Feature_Panel, Panel_Row)
      then
         return (others => <>);
      end if;

      Name := To_Unbounded_String
        (Outline_Row_Base_Name (S, Positive (Outline_Row)));
      if Length (Name) = 0 then
         return (others => <>);
      end if;

      Row_Kind := Editor.Outline.Item_Kind (S.Outline, Positive (Outline_Row));
      Row_Is_Body := Outline_Row_Is_Body (S, Positive (Outline_Row));
      Row_Profile := To_Unbounded_String
        (Outline_Row_Profile (S, Positive (Outline_Row)));

      if Id = Editor.Commands.Command_Goto_Body then
         if Row_Kind = Editor.Outline.Outline_Package then
            Wanted := Editor.Ada_Language_Model.Symbol_Package_Body;
         elsif Row_Kind = Editor.Outline.Outline_Procedure
           and then not Row_Is_Body
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Procedure;
         elsif Row_Kind = Editor.Outline.Outline_Function
           and then not Row_Is_Body
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Function;
         else
            return (others => <>);
         end if;
      elsif Id = Editor.Commands.Command_Goto_Spec then
         if Outline_Row_Is_Separate_Body (S, Positive (Outline_Row))
           or else Current_File_Has_Indexed_Separate_Body
             (S, To_String (Name))
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Separate_Body;
         elsif Row_Kind = Editor.Outline.Outline_Package_Body then
            Wanted := Editor.Ada_Language_Model.Symbol_Package;
         elsif Row_Kind = Editor.Outline.Outline_Procedure
           and then Row_Is_Body
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Procedure;
         elsif Row_Kind = Editor.Outline.Outline_Function
           and then Row_Is_Body
         then
            Wanted := Editor.Ada_Language_Model.Symbol_Function;
         else
            return (others => <>);
         end if;
      else
         return (others => <>);
      end if;

      if Track_Request then
         declare
            Req : constant Editor.Ada_Language_Service.Semantic_Request_Id :=
              Editor.Ada_Language_Service.Begin_Semantic_Request
                (Service,
                 (if Id = Editor.Commands.Command_Goto_Body
                  then Editor.Ada_Language_Service.Semantic_Request_Goto_Body
                  else Editor.Ada_Language_Service.Semantic_Request_Goto_Spec),
                 Editor.Ada_Language_Service.Semantic_Request_Query_Key
                   ((if Id = Editor.Commands.Command_Goto_Body
                     then Editor.Ada_Language_Service.Semantic_Request_Goto_Body
                     else Editor.Ada_Language_Service.Semantic_Request_Goto_Spec),
                    To_String (Name),
                    To_String (Row_Profile),
                    Detail => Editor.Ada_Language_Model.Symbol_Kind'Image
                      (Wanted)));
            Target_Set : constant Editor.Ada_Language_Service.Language_Target_Set :=
              (if Id = Editor.Commands.Command_Goto_Body then
                 Editor.Ada_Language_Service.Request_Goto_Body
                   (Service, Req, To_String (Name), Wanted,
                    To_String (Row_Profile))
               else
                 Editor.Ada_Language_Service.Request_Goto_Spec
                   (Service, Req, To_String (Name), Wanted,
                    To_String (Row_Profile)));
         begin
            if Target_Set.Status = Editor.Ada_Language_Service.Service_Success
              and then Natural (Target_Set.Targets.Length) = 1
            then
               declare
                  Target : constant Editor.Ada_Language_Service.Language_Target :=
                    Target_Set.Targets (Target_Set.Targets.First_Index);
               begin
                  return
                    (Available => True,
                     Path      => Target.Target.Path,
                     Key       => Target.Key,
                     Line      => Target.Target.Line,
                     Column    => Target.Target.Column);
               end;
            end if;
         end;

         return (others => <>);
      end if;

      if Row_Kind = Editor.Outline.Outline_Package
        or else Row_Kind = Editor.Outline.Outline_Package_Body
      then
         declare
            Unit_Target : constant Editor.Ada_Project_Index.Unique_Target_Result :=
              Editor.Ada_Project_Index.Resolve_Unique_Unit_Target
                (S.Language_Index,
                 To_String (Name),
                 (if Id = Editor.Commands.Command_Goto_Body then
                    Editor.Ada_Project_Index.Unit_Package_Body
                  else
                    Editor.Ada_Project_Index.Unit_Package_Spec));
         begin
            if Unit_Target.Available then
               return
                 (Available => True,
                  Path      => Unit_Target.Target.Path,
                  Key       => Unit_Target.Target.Key,
                  Line      => Unit_Target.Target.Symbol.Source_Span.Start_Line,
                  Column    => Unit_Target.Target.Symbol.Source_Span.Start_Column);
            elsif Unit_Target.Ambiguous or else Unit_Target.Overflow then
               return (others => <>);
            end if;
         end;
      end if;

      declare
         Target_Set : constant Editor.Ada_Language_Service.Language_Target_Set :=
           (if Id = Editor.Commands.Command_Goto_Body then
              Editor.Ada_Language_Service.Goto_Body
                (Service, To_String (Name), Wanted, To_String (Row_Profile))
            else
              Editor.Ada_Language_Service.Goto_Spec
                (Service, To_String (Name), Wanted, To_String (Row_Profile)));
      begin
         if Target_Set.Status = Editor.Ada_Language_Service.Service_Success
           and then Natural (Target_Set.Targets.Length) = 1
         then
            declare
               Target : constant Editor.Ada_Language_Service.Language_Target :=
                 Target_Set.Targets (Target_Set.Targets.First_Index);
            begin
               return
                 (Available => True,
                  Path      => Target.Target.Path,
                  Key       => Target.Key,
                  Line      => Target.Target.Line,
                  Column    => Target.Target.Column);
            end;
         end if;
      end;

      return (others => <>);
   end Find_Indexed_Outline_Target;

   function Has_Indexed_Outline_Target
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return Boolean
   is
      Service : Editor.Ada_Language_Service.Service_State :=
        Current_Language_Service (S);
   begin
      return Find_Indexed_Outline_Target (S, Id, Service).Available;
   end Has_Indexed_Outline_Target;

   function Navigate_To_Indexed_Outline_Target
     (S      : in out Editor.State.State_Type;
      Target : Outline_Indexed_Target) return Boolean
   is
      Path : constant String := To_String (Target.Path);

      function Same_Target_Path (Left : String; Right : String) return Boolean is
      begin
         --  target-key validation already normalizes retained
         --  project-index paths, but execution still compared the active
         --  editor path with raw string equality before and after opening the
         --  target file.  Keep navigation conservative without rejecting a
         --  live target solely because one side used backslashes, redundant
         --  separators, or another normalized spelling retained by the index.
         return Editor.Recent_Projects.Normalized_Root_Path (Left) =
           Editor.Recent_Projects.Normalized_Root_Path (Right);
      end Same_Target_Path;
   begin
      if not Target.Available or else Path'Length = 0 then
         return False;
      end if;

      if not Editor.Ada_Project_Index.Contains_Key
        (S.Language_Index, Target.Key)
      then
         --  command availability may have observed an indexed
         --  target earlier than execution.  Revalidate the exact parser-owned
         --  file key before opening or moving the caret so clears, project
         --  switches, file lifecycle invalidations, and refreshes cannot leave
         --  an executable stale body/spec navigation target.
         return False;
      end if;

      if not S.File_Info.Has_Path
        or else not Same_Target_Path (To_String (S.File_Info.Path), Path)
      then
         declare
            Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
              S.Language_Index;
            Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
              S.Language_Service;
         begin
            Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
            S.Language_Index := Saved_Index;
            S.Language_Service := Saved_Service;
         end;
      end if;

      if not S.File_Info.Has_Path
        or else not Same_Target_Path (To_String (S.File_Info.Path), Path)
      then
         return False;
      end if;

      if Target.Key.Buffer_Token /= 0
        and then not Editor.Ada_Project_Index.Contains_Open_Buffer_Key
          (S.Language_Index,
           Target.Key,
           Path,
           Active_Feature_Buffer_Token (S),
           Editor.State.Current_Buffer_Revision (S),
           Editor.State.Current_Lifecycle_Generation (S))
      then
         --  Open-buffer targets are editor-owned snapshots.  Require the
         --  current active buffer stamp to still match the indexed key before
         --  applying the navigation handoff.  Disk-indexed targets keep the
         --  zero-token key and are validated by exact retained-key presence.
         return False;
      end if;

      if Natural (Target.Line) > Editor.State.Line_Count (S)
        or else Natural (Target.Column) - 1 >
          Editor.Navigation.Line_Length (S, Natural (Target.Line) - 1)
      then
         return False;
      end if;

      Apply_Feature_Target_Handoff
        (S,
         Natural (Target.Line) - 1,
         Natural (Target.Column) - 1);
      return True;
   end Navigate_To_Indexed_Outline_Target;



   function Execute_Semantic_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result
   is
      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
         return Editor.Command_Execution.Command_Execution_Result is
      begin
         return Editor.Command_Execution.Executed (Command);
      end Result_After_Command;
   begin
      case Id is
         when Editor.Commands.Command_Refresh_Outline_Project_Index =>
            declare
               Indexed_Files : Natural;
               Indexed_Symbols : Natural;
               Skipped_Files : Natural;
               Read_Errors : Natural;
            begin
               Editor.Executor.Refresh_Project_Language_Index
                 (S,
                  Build_Semantics    => False,
                  Indexed_File_Count => Indexed_Files,
                  Indexed_Symbols    => Indexed_Symbols,
                  Skipped_File_Count => Skipped_Files,
                  Read_Error_Count   => Read_Errors);
               Report_Info
                 (S,
                  "Language project index refreshed: " &
                  Natural'Image (Indexed_Files) & " files, " &
                  Natural'Image (Indexed_Symbols) & " symbols, " &
                  Natural'Image (Skipped_Files) & " skipped, " &
                  Natural'Image (Read_Errors) & " read errors.");
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;

         when Editor.Commands.Command_Semantic_Refresh_Buffer =>
            declare
               Text : constant String := Editor.State.Current_Text (S);
               Label : constant String :=
                 (if S.File_Info.Has_Path
                  then To_String (S.File_Info.Path)
                  else To_String (S.File_Info.Display_Name));
               Buffer_Token : constant Natural := Active_Feature_Buffer_Token (S);
               Buffer_Revision : constant Natural :=
                 Editor.State.Current_Buffer_Revision (S);
               Lifecycle_Generation : constant Natural :=
                 Editor.State.Current_Lifecycle_Generation (S);
               Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
                 Editor.Ada_Declaration_Parser.Parse (Text, Label);
            begin
               Editor.Syntax_Semantics.Clear (S.Syntax_Symbols);
               S.Syntax_Analysis := Analysis;
               Editor.Syntax_Semantics.Build_Map_From_Analysis
                 (S.Syntax_Symbols, Analysis);
               S.Syntax_Symbols_Revision := Buffer_Revision;
               S.Syntax_Symbols_Buffer_Token := Buffer_Token;
               if Label'Length > 0
                 and then Editor.Executor.Is_Ada_Source_Path (Label)
               then
                  Editor.Ada_Project_Index.Put_Analysis
                    (S.Language_Index,
                     Label,
                     Buffer_Token,
                     Buffer_Revision,
                     Lifecycle_Generation,
                     Analysis);
                  Editor.Ada_Language_Service.Put_Index
                    (S.Language_Service, S.Language_Index);
                  Editor.Ada_Live_Semantic_Diagnostics.Publish
                    (S.Language_Service,
                     Label,
                     Text,
                     Buffer_Token,
                     Buffer_Revision,
                     Lifecycle_Generation,
                     Analysis);
                  Editor.Executor.Publish_Service_Diagnostics_To_Feature
                    (S, Label, Buffer_Token);
               end if;
               Report_Info
                 (S,
                  "Semantic colouring refreshed for active buffer: " &
                  Natural'Image (Editor.Syntax_Semantics.Symbol_Count (S.Syntax_Symbols)) &
                  " symbols.");
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;

         when Editor.Commands.Command_Semantic_Refresh_Project_Index =>
            declare
               Indexed_Files : Natural;
               Indexed_Symbols : Natural;
               Skipped_Files : Natural;
               Read_Errors : Natural;
            begin
               Editor.Executor.Refresh_Project_Language_Index
                 (S,
                  Build_Semantics    => True,
                  Indexed_File_Count => Indexed_Files,
                  Indexed_Symbols    => Indexed_Symbols,
                  Skipped_File_Count => Skipped_Files,
                  Read_Error_Count   => Read_Errors);
               Report_Info
                 (S,
                  "Semantic project index refreshed: " &
                  Natural'Image (Indexed_Files) & " files, " &
                  Natural'Image (Indexed_Symbols) & " symbols, " &
                  Natural'Image (Skipped_Files) & " skipped, " &
                  Natural'Image (Read_Errors) & " read errors.");
               Editor.Render_Cache.Invalidate_All;
               return Result_After_Command (Id);
            end;

         when Editor.Commands.Command_Language_Index_Clear =>
            Editor.Executor.Clear_Service_Semantic_Diagnostics_From_Feature (S);
            Editor.Ada_Project_Index.Clear (S.Language_Index);
            Editor.Ada_Language_Service.Clear (S.Language_Service);
            Report_Info (S, "Language index cleared.");
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Language_Index_Status =>
            declare
               Compiler : constant
                 Editor.Ada_Language_Service.Compiler_Backend_Status :=
                   Editor.Ada_Language_Service.Compiler_Status
                     (S.Language_Service);
               Backend : constant
                 Editor.Ada_Language_Service.Semantic_Backend_Status :=
                   Editor.Ada_Language_Service.Backend_Status
                     (S.Language_Service);
               Caps : constant
                 Editor.Ada_Language_Service.Language_Service_Capabilities :=
                   Editor.Ada_Language_Service.Capabilities
                     (S.Language_Service);
               Semantic : constant
                 Editor.Ada_Language_Service.Semantic_Diagnostic_Status :=
                   Editor.Ada_Language_Service.Semantic_Diagnostics_Status
                     (S.Language_Service);
               Current_File : constant Editor.State.File_State :=
                 Editor.State.Current_File (S);
               Active_Compiler : constant
                 Editor.Ada_Language_Service.Compiler_Backend_Status :=
                 (if Current_File.Has_Path
                  then Editor.Ada_Language_Service.Compiler_Status_For_Path
                    (S.Language_Service, To_String (Current_File.Path))
                  else (others => <>));
               Active_Semantic : constant
                 Editor.Ada_Language_Service.Semantic_Diagnostic_Status :=
                 (if Current_File.Has_Path
                  then Editor.Ada_Language_Service.Semantic_Diagnostics_Status_For_Path
                    (S.Language_Service, To_String (Current_File.Path))
                  else (others => <>));
               function Img (Value : Natural) return String is
               begin
                  return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
               end Img;

               function Ready_Label
                 (Supported : Boolean;
                  Ready     : Boolean) return String is
               begin
                  if not Supported then
                     return "-";
                  elsif Ready then
                     return "+";
                  else
                     return "!";
                  end if;
               end Ready_Label;

               function Request_Kind_Label
                 (Kind : Editor.Ada_Language_Service.Semantic_Request_Kind)
                  return String
               is
               begin
                  case Kind is
                     when Editor.Ada_Language_Service.Semantic_Request_None =>
                        return "none";
                     when Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration =>
                        return "declaration";
                     when Editor.Ada_Language_Service.Semantic_Request_Goto_Body =>
                        return "body";
                     when Editor.Ada_Language_Service.Semantic_Request_Goto_Spec =>
                        return "spec";
                     when Editor.Ada_Language_Service.Semantic_Request_Find_References =>
                        return "references";
                     when Editor.Ada_Language_Service.Semantic_Request_Workspace_Symbols =>
                        return "workspace-symbols";
                     when Editor.Ada_Language_Service.Semantic_Request_Completion =>
                        return "completion";
                     when Editor.Ada_Language_Service.Semantic_Request_Hover =>
                        return "hover";
                     when Editor.Ada_Language_Service.Semantic_Request_Rename =>
                        return "rename";
                  end case;
               end Request_Kind_Label;

               function Request_Status_Label
                 (Status :
                    Editor.Ada_Language_Service.Semantic_Request_Status_Kind)
                  return String
               is
               begin
                  case Status is
                     when Editor.Ada_Language_Service.Semantic_Request_No_Request =>
                        return "none";
                     when Editor.Ada_Language_Service.Semantic_Request_Pending =>
                        return "pending";
                     when Editor.Ada_Language_Service.Semantic_Request_Completed =>
                        return "completed";
                     when Editor.Ada_Language_Service.Semantic_Request_Cancelled =>
                        return "cancelled";
                     when Editor.Ada_Language_Service.Semantic_Request_Superseded =>
                        return "superseded";
                     when Editor.Ada_Language_Service.Semantic_Request_Stale =>
                        return "stale";
                  end case;
               end Request_Status_Label;
            begin
               Report_Info
                 (S,
                  "Language index status:" &
                  "backend=" &
                  Editor.Ada_Language_Service.Backend_Label (Backend) &
                  " files symbols" &
                  " compiler=" &
                  (if Compiler.Has_Run
                   then Img (Compiler.Diagnostic_Count)
                   else "not-run") &
                  (if Compiler.Has_Run
                   then " warn=" & Img (Compiler.Warning_Count)
                   else "") &
                  " d=" &
                  (if Current_File.Has_Path
                   then Img (Active_Compiler.Diagnostic_Count)
                   else "none") &
                  " semantic=" &
                  Img (Semantic.Diagnostic_Count) &
                  (if Semantic.Overflowed then " overflow" else "") &
                  " sd=" &
                  (if Current_File.Has_Path
                   then Img (Active_Semantic.Diagnostic_Count)
                   else "none") &
                  " rq=" &
                  Request_Kind_Label (Backend.Active_Request_Kind) &
                  "/" &
                  Request_Status_Label (Backend.Active_Request_Status) &
                  " cancel=" &
                  (if Backend.Semantic_Requests_Cancellable then "yes" else "no") &
                  " prev=" &
                  Request_Status_Label (Backend.Previous_Request_Status) &
                  " caps=nav" &
                  Ready_Label
                    (Caps.Navigation_Supported, Caps.Navigation_Ready) &
                  ",ref" &
                  Ready_Label
                    (Caps.References_Supported, Caps.References_Ready) &
                  ",sym" &
                  Ready_Label
                    (Caps.Workspace_Symbols_Supported,
                     Caps.Workspace_Symbols_Ready) &
                  ",cmp" &
                  Ready_Label
                    (Caps.Completion_Supported, Caps.Completion_Ready) &
                  ",hov" &
                  Ready_Label (Caps.Hover_Supported, Caps.Hover_Ready) &
                  ",ren" &
                  Ready_Label
                    (Caps.Rename_Preview_Supported,
                     Caps.Rename_Preview_Ready) &
                  ",diag" &
                  Ready_Label
                    (Caps.Diagnostics_Supported,
                     Caps.Internal_Diagnostics_Ready
                       or else Caps.Compiler_Diagnostics_Ready) &
                  ",req" &
                  Ready_Label
                    (Caps.Request_Lifecycle_Supported,
                     Caps.Request_Cancellation_Available));
            end;
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when Editor.Commands.Command_Goto_Declaration =>
            if Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
              and then Editor.Executor.Has_Selected_Outline_Activation_Target (S)
            then
               --  The active Outline row already carries the validated
               --  declaration target.  Keep this path sharing the existing
               --  stale-row and lifecycle checks.
               return Execute_Command_With_Result
                 (S, Editor.Commands.Command_Open_Selected_Outline_Item);
            else
               declare
                  Symbol  : constant Selected_Outline_Semantic_Symbol :=
                    Current_Semantic_Symbol (S);
                  Target  : Editor.Ada_Language_Service.Language_Target;
               begin
                  Ensure_Current_Language_Service (S);
                  if not Symbol.Available then
                     Report_Info
                       (S, "No semantic symbol at cursor or Outline selection.");
                     Editor.Render_Cache.Invalidate_All;
                     return Editor.Command_Execution.Unavailable (Id);
                  end if;

                  Target := Semantic_Declaration_Target
                    (S, S.Language_Service, Symbol);
                  if Target.Status = Editor.Ada_Language_Service.Service_Success
                    and then Navigate_To_Indexed_Outline_Target
                      (S,
                       (Available => True,
                        Path      => Target.Target.Path,
                        Key       => Target.Key,
                        Line      => Target.Target.Line,
                        Column    => Target.Target.Column))
                  then
                     Editor.Render_Cache.Invalidate_All;
                     return Result_After_Command (Id);
                  end if;

                  Report_Info
                    (S,
                     "Declaration unavailable for " & To_String (Symbol.Name) &
                     ": " & Service_Status_Image (Target.Status) & ".");
                  Editor.Render_Cache.Invalidate_All;
                  return Editor.Command_Execution.Unavailable (Id);
               end;
            end if;

         when Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec =>
            declare
               Target : Outline_Indexed_Target;
            begin
               Ensure_Current_Language_Service (S);
               Target := Find_Indexed_Outline_Target
                 (S, Id, S.Language_Service, Track_Request => True);
               if Navigate_To_Indexed_Outline_Target (S, Target) then
                  Editor.Render_Cache.Invalidate_All;
                  return Result_After_Command (Id);
               end if;

               Report_Info (S, "Outline indexed target unavailable");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end;

         when Editor.Commands.Command_Find_References
            | Editor.Commands.Command_Workspace_Symbols
            | Editor.Commands.Command_Show_Hover
            | Editor.Commands.Command_Show_Completions =>
            return Execute_Selected_Outline_Language_Command (S, Id);

         when Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply =>
            return Execute_Selected_Outline_Language_Command
              (S, Id, To_String (Cmd.Text));

         when Editor.Commands.Command_Semantic_Completion_Select_Next =>
            Execute_Semantic_Completion_Select (S, Next => True);
            return Result_After_Command (Id);

         when Editor.Commands.Command_Semantic_Completion_Select_Previous =>
            Execute_Semantic_Completion_Select (S, Next => False);
            return Result_After_Command (Id);

         when Editor.Commands.Command_Semantic_Completion_Accept =>
            if not Semantic_Completion_Popup_Is_Active (S) then
               Report_Info (S, "No completion menu is open.");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end if;
            Execute_Semantic_Completion_Accept (S);
            return Result_After_Command (Id);

         when Editor.Commands.Command_Semantic_Popup_Dismiss =>
            if not S.Semantic_Popup.Active then
               Report_Info (S, "No semantic popup is open.");
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end if;
            Clear_Semantic_Popup (S);
            Editor.Render_Cache.Invalidate_All;
            return Result_After_Command (Id);

         when others =>
            return Editor.Command_Execution.Unavailable (Id);
      end case;
   end Execute_Semantic_Command;

   procedure Execute_Semantic_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      procedure Run (Id : Editor.Commands.Command_Id);

      procedure Run (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Execute_Semantic_Command (S, Id, Cmd);
         pragma Unreferenced (Result);
      begin
         null;
      end Run;
   begin
      case Cmd.Kind is
         when Goto_Declaration =>
            Run (Command_Goto_Declaration);

         when Goto_Body =>
            Run (Command_Goto_Body);

         when Goto_Spec =>
            Run (Command_Goto_Spec);

         when Find_References =>
            Run (Command_Find_References);

         when Workspace_Symbols =>
            Run (Command_Workspace_Symbols);

         when Show_Hover =>
            Run (Command_Show_Hover);

         when Show_Completions =>
            Run (Command_Show_Completions);

         when Semantic_Completion_Select_Next =>
            Run (Command_Semantic_Completion_Select_Next);

         when Semantic_Completion_Select_Previous =>
            Run (Command_Semantic_Completion_Select_Previous);

         when Semantic_Completion_Accept =>
            Run (Command_Semantic_Completion_Accept);

         when Semantic_Popup_Dismiss =>
            Run (Command_Semantic_Popup_Dismiss);

         when Rename_Symbol_Preview =>
            Run (Command_Rename_Symbol_Preview);

         when Rename_Symbol_Apply =>
            Run (Command_Rename_Symbol_Apply);

         when Semantic_Refresh_Buffer =>
            Run (Command_Semantic_Refresh_Buffer);

         when Semantic_Refresh_Project_Index =>
            Run (Command_Semantic_Refresh_Project_Index);

         when Language_Index_Clear =>
            Run (Command_Language_Index_Clear);

         when Language_Index_Status =>
            Run (Command_Language_Index_Status);

         when others =>
            raise Program_Error with "unsupported semantic command kind";
      end case;
   end Execute_Semantic_Kind;

end Editor.Executor.Semantic_Commands;
