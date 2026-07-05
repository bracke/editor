with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Text_Buffer;

with Editor.Buffers;
with Editor.Cursors;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Folding;
with Editor.Focus_Management;
with Editor.Layout;
with Editor.Messages;
with Editor.Navigation;
with Editor.Navigation_History;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Project;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Render_Cache;
with Editor.Selection;
with Editor.State;
with Editor.View;

package body Editor.Executor.Project_Search_Result_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Project_Search.Project_Search_Status;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Warning;

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

   function Structured_File_Navigation_Target
     (Path   : String;
      Line   : Natural := 1;
      Column : Natural := 0;
      Reason : Editor.Navigation_History.Navigation_History_Reason :=
        Editor.Navigation_History.Navigation_Reason_Unknown)
      return Editor.Navigation_History.Navigation_Location
   is
   begin
      if Path'Length = 0 or else Line = 0 then
         return (others => <>);
      end if;

      return
        (Buffer_Id      => 0,
         Has_File_Path  => True,
         File_Path      => To_Unbounded_String (Path),
         Display_Path   => To_Unbounded_String (Path),
         Line           => Line,
         Column         => Column,
         Viewport_Row   => 0,
         Reason         => Reason);
   end Structured_File_Navigation_Target;

   procedure Execute_Run_Project_Search
     (S     : in out Editor.State.State_Type;
      Query : String)
   is
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);

      function Search_Image (Value : Natural) return String is
      begin
         return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
      end Search_Image;

      function Search_Summary_Message return String is
         Matches : constant Natural := Editor.Project_Search.Result_Count (S.Project_Search);
         Files   : constant Natural := Editor.Project_Search.Files_With_Matches (S.Project_Search);
         Skipped : constant Natural := Editor.Project_Search.Skipped_File_Count (S.Project_Search);
         Text    : Unbounded_String;
      begin
         if Matches = 0 then
            Text := To_Unbounded_String ("Project search completed: no matches.");
         else
            Text := To_Unbounded_String
              ("Project search completed: " & Search_Image (Matches) &
               " matches in " & Search_Image (Files) & " files");
         end if;
         Append (Text, "; searched "
           & Search_Image (Editor.Project_Search.Files_Searched (S.Project_Search))
           & " files");

         if Skipped > 0 then
            Append (Text, "; skipped " & Search_Image (Skipped));
            if Editor.Project_Search.Skipped_Missing_Count (S.Project_Search) > 0 then
               Append (Text, " missing=" & Search_Image
                 (Editor.Project_Search.Skipped_Missing_Count (S.Project_Search)));
            end if;
            if Editor.Project_Search.Skipped_Large_Count (S.Project_Search) > 0 then
               Append (Text, " large=" & Search_Image
                 (Editor.Project_Search.Skipped_Large_Count (S.Project_Search)));
            end if;
            if Editor.Project_Search.Skipped_Binary_Count (S.Project_Search) > 0 then
               Append (Text, " binary=" & Search_Image
                 (Editor.Project_Search.Skipped_Binary_Count (S.Project_Search)));
            end if;
            if Editor.Project_Search.Read_Error_Count (S.Project_Search) > 0 then
               Append (Text, " unreadable=" & Search_Image
                 (Editor.Project_Search.Read_Error_Count (S.Project_Search)));
            end if;
         end if;
         if Editor.Project_Search.Was_Truncated (S.Project_Search) then
            Append (Text, "; result limit reached");
            if Editor.Project_Search.Matches_Truncated_Count (S.Project_Search) > 0 then
               Append (Text, ": truncated " & Search_Image
                 (Editor.Project_Search.Matches_Truncated_Count (S.Project_Search))
                 & " matches");
            end if;
         end if;
         return To_String (Text);
      end Search_Summary_Message;
   begin
      Editor.Project_Search.Set_Query (S.Project_Search, Query);
      Show_Search_Results_Panel (S);

      if not Editor.Project.Has_Project (S.Project) then
         Editor.Project_Search.Set_Status
           (S.Project_Search, Editor.Project_Search.Project_Search_No_Project);
         Report_Warning (S, "No project open");
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Editor.Project_Search.Set_Status
           (S.Project_Search, Editor.Project_Search.Project_Search_No_Files);
         Report_Warning (S, "No project files available.");
         return;
      elsif Query'Length = 0 then
         Editor.Project_Search.Set_Status
           (S.Project_Search, Editor.Project_Search.Project_Search_Empty_Query);
         Report_Info (S, "No project search query");
         return;
      end if;

      for Ch of Query loop
         if Ch = ASCII.LF or else Ch = ASCII.CR then
            Editor.Project_Search.Set_Status
              (S.Project_Search, Editor.Project_Search.Project_Search_Empty_Query);
            Report_Warning (S, "No project search query");
            return;
         end if;
      end loop;

      Editor.Project_Search.Search_Known_Project_Files
        (State   => S.Project_Search,
         Project => S.Project,
         Options => Options);

      Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
      if Editor.Project_Search.Status (S.Project_Search)
        = Editor.Project_Search.Project_Search_Invalid_Regex
      then
         Report_Warning
           (S, "Invalid regex"
            & (if Editor.Project_Search.Regex_Error (S.Project_Search)'Length > 0
               then ": " & Editor.Project_Search.Regex_Error (S.Project_Search)
               else ""));
      elsif Editor.Project_Search.Eligible_File_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project files match search scope");
      else
         Report_Info (S, Search_Summary_Message);
      end if;
   end Execute_Run_Project_Search;

   procedure Execute_Rerun_Project_Search
     (S : in out Editor.State.State_Type)
   is
      Query : constant String :=
        (if Editor.Project_Search.Has_Query (S.Project_Search) then
            Editor.Project_Search.Query (S.Project_Search)
         else
            Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar));
   begin
      if Query'Length = 0 then
         Report_Info (S, "No project search query");
         Editor.Project_Search.Set_Status
           (S.Project_Search, Editor.Project_Search.Project_Search_Empty_Query);
         Show_Search_Results_Panel (S);
      else
         Execute_Run_Project_Search (S, Query);
         Editor.Project_Search.Clear_Stale (S.Project_Search);
      end if;
   end Execute_Rerun_Project_Search;

   Max_Context_Search_Query_Length : constant Natural := 256;

   type Context_Search_Query_Status is
     (Context_Query_Ready,
      Context_No_Active_Buffer,
      Context_No_Selected_Text,
      Context_No_Searchable_Text,
      Context_Selection_Multiline,
      Context_Query_Too_Long,
      Context_Active_Buffer_Not_Known_Project_File,
      Context_No_Project,
      Context_No_Known_Files);

   function Context_Search_Message
     (Status : Context_Search_Query_Status) return String
   is
   begin
      case Status is
         when Context_Query_Ready =>
            return "";
         when Context_No_Active_Buffer =>
            return "No active buffer.";
         when Context_No_Selected_Text =>
            return "No selected text";
         when Context_No_Searchable_Text =>
            return "No searchable text at cursor";
         when Context_Selection_Multiline =>
            return "Selected text is not a single-line search query";
         when Context_Query_Too_Long =>
            return "Selected text is too long";
         when Context_Active_Buffer_Not_Known_Project_File =>
            return "Active buffer is not a known project file";
         when Context_No_Project =>
            return "No project open";
         when Context_No_Known_Files =>
            return "No project open.";
      end case;
   end Context_Search_Message;

   function Is_Context_Word_Character (Ch : Character) return Boolean is
   begin
      return (Ch in 'A' .. 'Z')
        or else (Ch in 'a' .. 'z')
        or else (Ch in '0' .. '9')
        or else Ch = '_';
   end Is_Context_Word_Character;

   function Context_Query_From_Selection
     (S      : Editor.State.State_Type;
      Status : out Context_Search_Query_Status) return String
   is
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Selection_Status : constant Editor.Selection.Selection_Validation_Status :=
        Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      Start_Row        : Natural := 0;
      Start_Col        : Natural := 0;
      End_Row          : Natural := 0;
      End_Col          : Natural := 0;
   begin
      case Selection_Status is
         when Editor.Selection.Selection_No_Active_Buffer =>
            Status := Context_No_Active_Buffer;
            return "";
         when Editor.Selection.Selection_No_Caret
            | Editor.Selection.Selection_Empty
            | Editor.Selection.Selection_Invalid =>
            Status := Context_No_Selected_Text;
            return "";
         when Editor.Selection.Selection_Ok =>
            null;
      end case;

      Editor.State.Row_Col_For_Index (S, Selection_Range.Low, Start_Row, Start_Col);
      Editor.State.Row_Col_For_Index (S, Selection_Range.High, End_Row, End_Col);
      if Start_Row /= End_Row then
         Status := Context_Selection_Multiline;
         return "";
      end if;

      declare
         Text : constant String := Ada.Strings.Fixed.Trim
           (To_String (Editor.Selection.Extract_Selected_Text (S)),
            Ada.Strings.Both);
      begin
         if Text'Length = 0 then
            Status := Context_No_Selected_Text;
            return "";
         elsif Text'Length > Max_Context_Search_Query_Length then
            Status := Context_Query_Too_Long;
            return "";
         else
            Status := Context_Query_Ready;
            return Text;
         end if;
      end;
   end Context_Query_From_Selection;

   function Context_Query_From_Active_Word
     (S      : Editor.State.State_Type;
      Status : out Context_Search_Query_Status) return String
   is
      Length : Natural := 0;
      Probe  : Natural := Natural (Editor.Executor.Safe_Caret (S));
      First  : Natural := 0;
      Last   : Natural := 0;
   begin
      Status := Context_No_Searchable_Text;
      if not Editor.State.Has_Active_Buffer (S) then
         Status := Context_No_Active_Buffer;
         return "";
      end if;

      Length := Text_Buffer.Length (S.Buffer);
      if Length = 0 then
         return "";
      end if;

      if Probe >= Length then
         return "";
      end if;

      if not Is_Context_Word_Character
        (Text_Buffer.Character_At (S.Buffer, Probe))
      then
         return "";
      end if;

      First := Probe;
      while First > 0
        and then Is_Context_Word_Character
          (Text_Buffer.Character_At (S.Buffer, First - 1))
      loop
         First := First - 1;
      end loop;

      Last := Probe;
      while Last + 1 < Length
        and then Is_Context_Word_Character
          (Text_Buffer.Character_At (S.Buffer, Last + 1))
      loop
         Last := Last + 1;
      end loop;

      declare
         Text : constant String := To_String
           (Editor.Executor.Extract_Text (S.Buffer, First, Last - First + 1));
      begin
         if Text'Length = 0 then
            return "";
         elsif Text'Length > Max_Context_Search_Query_Length then
            Status := Context_Query_Too_Long;
            return "";
         else
            Status := Context_Query_Ready;
            return Text;
         end if;
      end;
   end Context_Query_From_Active_Word;

   function Context_Query_From_Selection_Or_Word
     (S      : Editor.State.State_Type;
      Status : out Context_Search_Query_Status) return String
   is
      Text : constant String := Context_Query_From_Selection (S, Status);
   begin
      if Status = Context_Query_Ready
        or else Status = Context_Selection_Multiline
        or else Status = Context_Query_Too_Long
      then
         return Text;
      end if;
      return Context_Query_From_Active_Word (S, Status);
   end Context_Query_From_Selection_Or_Word;

   function Directory_Scope_For_Project_File (Path : String) return String is
      Last_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' then
            Last_Slash := I;
         end if;
      end loop;
      if Last_Slash = 0 then
         return "";
      else
         return Path (Path'First .. Last_Slash);
      end if;
   end Directory_Scope_For_Project_File;

   procedure Run_Project_Search_From_Context
     (S          : in out Editor.State.State_Type;
      Query      : String;
      Set_Scope  : Boolean;
      Scope_Text : String := "")
   is
      Valid : Boolean := False;
   begin
      if Set_Scope then
         Editor.Project_Search.Set_Path_Scope
           (S.Project_Search, Scope_Text, Valid);
         if not Valid then
            Report_Warning (S, "Active buffer is not a known project file");
            return;
         end if;
      end if;

      Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, Query);
      Execute_Run_Project_Search (S, Query);
      Editor.Project_Search.Clear_Stale (S.Project_Search);
   end Run_Project_Search_From_Context;

   procedure Execute_Project_Search_From_Selection
     (S : in out Editor.State.State_Type)
   is
      Status : Context_Search_Query_Status := Context_Query_Ready;
      Query  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, Context_Search_Message (Context_No_Project));
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Report_Warning (S, Context_Search_Message (Context_No_Known_Files));
         return;
      end if;

      Query := To_Unbounded_String (Context_Query_From_Selection (S, Status));
      if Status /= Context_Query_Ready then
         Report_Info (S, Context_Search_Message (Status));
         return;
      end if;

      Run_Project_Search_From_Context
        (S, To_String (Query), Set_Scope => False);
   end Execute_Project_Search_From_Selection;

   procedure Execute_Project_Search_From_Active_Word
     (S : in out Editor.State.State_Type)
   is
      Status : Context_Search_Query_Status := Context_Query_Ready;
      Query  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, Context_Search_Message (Context_No_Project));
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Report_Warning (S, Context_Search_Message (Context_No_Known_Files));
         return;
      end if;

      Query := To_Unbounded_String (Context_Query_From_Active_Word (S, Status));
      if Status /= Context_Query_Ready then
         Report_Info (S, Context_Search_Message (Status));
         return;
      end if;

      Run_Project_Search_From_Context
        (S, To_String (Query), Set_Scope => False);
   end Execute_Project_Search_From_Active_Word;

   procedure Execute_Project_Search_Active_Directory
     (S : in out Editor.State.State_Type)
   is
      Status : Context_Search_Query_Status := Context_Query_Ready;
      Query  : Unbounded_String := Null_Unbounded_String;
      Found  : Boolean := False;
      Path   : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Warning (S, Context_Search_Message (Context_No_Project));
         return;
      elsif Editor.Project.Known_File_Count (S.Project) = 0 then
         Report_Warning (S, Context_Search_Message (Context_No_Known_Files));
         return;
      elsif not Editor.State.Has_Active_Buffer (S) then
         Report_Info (S, Context_Search_Message (Context_No_Active_Buffer));
         return;
      end if;

      Path := To_Unbounded_String
        (Editor.Executor.Active_Buffer_Known_Project_File (S, Found));
      if not Found then
         Report_Info
           (S, Context_Search_Message
              (Context_Active_Buffer_Not_Known_Project_File));
         return;
      end if;

      Query := To_Unbounded_String (Context_Query_From_Selection_Or_Word (S, Status));
      if Status /= Context_Query_Ready then
         Report_Info (S, Context_Search_Message (Status));
         return;
      end if;

      Run_Project_Search_From_Context
        (S,
         To_String (Query),
         Set_Scope  => True,
         Scope_Text => Directory_Scope_For_Project_File (To_String (Path)));
   end Execute_Project_Search_Active_Directory;

   procedure Execute_Clear_Project_Search
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Project_Search.Clear (S.Project_Search);
      if Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar) then
         Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, "");
         Editor.Project_Search_Bar.Set_Replace_Text (S.Project_Search_Bar, "");
      end if;
      Show_Search_Results_Panel (S);
      Report_Info (S, "Project search query cleared");
      if Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
        Editor.Panel_Focus.Search_Results_Focus
      then
         Editor.Focus_Management.Restore_Focus_To_Editor (S);
      end if;
   end Execute_Clear_Project_Search;

   procedure Jump_To_Project_Search_Result
     (S      : in out Editor.State.State_Type;
      Result : Editor.Project_Search.Project_Search_Result)
   is
      Target_Path     : constant String := To_String (Result.Absolute_Path);
      Relative_Path   : constant String := To_String (Result.Relative_Path);
      Was_Open        : Boolean := False;
      Line_Available  : Boolean := True;
      Target_Index    : Editor.Cursors.Cursor_Index := 0;
      End_Index       : Editor.Cursors.Cursor_Index := 0;
      Target_Row      : Natural := (if Result.Row = 0 then 0 else Result.Row - 1);
      Start_Column    : Natural := Result.Start_Column;
      End_Column      : Natural := Result.End_Column;
      Viewport_Rows   : Natural := 1;
      Desired         : Natural := 0;
      Visible_Row     : Natural := 0;
      Visible_Found   : Boolean := False;
      Visible_Count   : Natural := 1;
      Layout          : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Before_Location : constant Editor.Navigation_History.Navigation_Location :=
        Editor.Executor.Current_Navigation_Location
          (S, Editor.Navigation_History.Navigation_Reason_Unknown);

      function Result_Target_Is_Current_Project_File return Boolean is
      begin
         if not Editor.Project.Has_Project (S.Project) then
            return False;
         end if;

         for I in 1 .. Editor.Project.Known_File_Count (S.Project) loop
            declare
               Item : constant Editor.Project.Project_File_Entry :=
                 Editor.Project.Known_File_At (S.Project, I);
            begin
               if To_String (Item.Relative_Path) = Relative_Path
                 and then To_String (Item.Absolute_Path) = Target_Path
               then
                  return True;
               end if;
            end;
         end loop;

         return False;
      end Result_Target_Is_Current_Project_File;
   begin
      if Editor.Project_Search.Is_Stale (S.Project_Search) then
         Report_Warning (S, "Search result is stale; run Project Search again.");
         Show_Search_Results_Panel (S);
         return;
      elsif not Result_Target_Is_Current_Project_File then
         Report_Warning (S, "Search result target unavailable.");
         Show_Search_Results_Panel (S);
         return;
      elsif Target_Path'Length = 0 or else not Ada.Directories.Exists (Target_Path) then
         Report_Warning
           (S,
            "Could not open " & Relative_Path & ": file not found");
         Show_Search_Results_Panel (S);
         return;
      end if;

      declare
         Found_Open : Boolean := False;
         Found_Id   : constant Editor.Buffers.Buffer_Id :=
           Editor.Buffers.Global_Find_By_Path (Target_Path, Found_Open);
      begin
         Was_Open := Found_Open and then Found_Id /= Editor.Buffers.No_Buffer;
      end;

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Target_Path);
      Editor.Messages.Dismiss_Latest (S.Messages);

      if not S.File_Info.Has_Path
        or else To_String (S.File_Info.Path) /= Target_Path
      then
         Report_Warning (S, "Could not open " & Relative_Path);
         Show_Search_Results_Panel (S);
         return;
      end if;

      if Target_Row >= Editor.State.Line_Count (S)
        or else End_Column > Editor.Navigation.Line_Length (S, Target_Row)
      then
         Line_Available := False;
         Report_Warning
           (S,
            "Search result target unavailable: line "
            & Ada.Strings.Fixed.Trim (Natural'Image (Result.Row), Ada.Strings.Both)
            & " is no longer available in " & Relative_Path);
         Show_Search_Results_Panel (S);
         return;
      end if;

      Start_Column := Natural'Min
        (Start_Column, Editor.Navigation.Line_Length (S, Target_Row));
      End_Column := Natural'Min
        (Natural'Max (End_Column, Start_Column),
         Editor.Navigation.Line_Length (S, Target_Row));

      Editor.Folding.Expand_To_Reveal_Row (S.Folding, Target_Row);
      Target_Index := Editor.Cursors.Cursor_Index
        (Editor.Navigation.Index_For_Line_Column (S, Target_Row, Start_Column));
      End_Index := Editor.Cursors.Cursor_Index
        (Editor.Navigation.Index_For_Line_Column (S, Target_Row, End_Column));

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => End_Index,
           Anchor                => Target_Index,
           Virtual_Column        => 0,
           Anchor_Virtual_Column => 0));
      S.Preferred_Column := End_Column;

      Editor.Executor.Record_Navigation_If_Target_Changed
        (S, Before_Location,
         Structured_File_Navigation_Target
           (Target_Path, Result.Row, Start_Column));

      Visible_Row := Editor.Folding.Document_Row_To_Visible_Row
        (S.Folding, Target_Row, Visible_Found);
      if not Visible_Found then
         Visible_Row := Target_Row;
      end if;

      Viewport_Rows := Natural'Max
        (1, Editor.Layout.Visible_Row_Count (Layout, Editor.View.Viewport_Height));
      Visible_Count := Natural'Max
        (1, Editor.Folding.Visible_Row_Count (S.Folding, Editor.State.Line_Count (S)));

      if Visible_Row > Viewport_Rows / 2 then
         Desired := Visible_Row - Viewport_Rows / 2;
      else
         Desired := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Visible_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired);
      Editor.View.Clear_User_Scroll_Override;
      if Line_Available then
         Report_Info
           (S,
            (if Was_Open then "Activated " else "Opened ")
            & Relative_Path & ":" & Ada.Strings.Fixed.Trim (Natural'Image (Result.Row), Ada.Strings.Both));
      else
         Report_Info
           (S,
            (if Was_Open then "Activated " else "Opened ")
            & Relative_Path & "; line "
            & Ada.Strings.Fixed.Trim (Natural'Image (Result.Row), Ada.Strings.Both)
            & " is no longer available");
      end if;
      Show_Search_Results_Panel (S);
   end Jump_To_Project_Search_Result;

   procedure Execute_Open_Project_Search_Result
     (S            : in out Editor.State.State_Type;
      Result_Index : Natural)
   is
      Result : Editor.Project_Search.Project_Search_Result;
   begin
      if Result_Index = 0
        or else Result_Index > Editor.Project_Search.Result_Count (S.Project_Search)
      then
         Report_Warning (S, "No search result selected.");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Project_Search.Set_Selected_Result_Index (S.Project_Search, Result_Index);
      Result := Editor.Project_Search.Result_At (S.Project_Search, Positive (Result_Index));
      Jump_To_Project_Search_Result (S, Result);
   end Execute_Open_Project_Search_Result;

   procedure Execute_Open_Selected_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
      Found  : Boolean := False;
      Result : constant Editor.Project_Search.Project_Search_Result :=
        Editor.Project_Search.Selected_Result (S.Project_Search, Found);
   begin
      if Found then
         Jump_To_Project_Search_Result (S, Result);
      else
         Report_Warning (S, "No search result selected.");
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Open_Selected_Project_Search_Result;

   procedure Execute_Move_Project_Search_Selection_Down
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
      else
         Editor.Project_Search.Move_Selected_Result
           (S.Project_Search, Editor.Project_Search.Next_Result, True);
         Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
         Show_Search_Results_Panel (S);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Move_Project_Search_Selection_Down;

   procedure Execute_Move_Project_Search_Selection_Up
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
      else
         Editor.Project_Search.Move_Selected_Result
           (S.Project_Search, Editor.Project_Search.Previous_Result, True);
         Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
         Show_Search_Results_Panel (S);
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Move_Project_Search_Selection_Up;

   procedure Execute_Next_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;
      Editor.Project_Search.Move_Selected_Result
        (S.Project_Search, Editor.Project_Search.Next_Result, True);
      Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info (S, "Selected next project search result");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Next_Project_Search_Result;

   procedure Execute_Previous_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;
      Editor.Project_Search.Move_Selected_Result
        (S.Project_Search, Editor.Project_Search.Previous_Result, True);
      Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info (S, "Selected previous project search result");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Previous_Project_Search_Result;

   procedure Execute_First_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Project_Search.Select_First_Result (S.Project_Search);
      Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info (S, "Selected first project search result");
      Editor.Render_Cache.Invalidate_All;
   end Execute_First_Project_Search_Result;

   procedure Execute_Last_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Project_Search.Select_Last_Result (S.Project_Search);
      Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info (S, "Selected last project search result");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Last_Project_Search_Result;

   procedure Execute_Reveal_Active_Project_Search_Result
     (S : in out Editor.State.State_Type)
   is
      Found_Path : Boolean := False;
      Path       : constant String :=
        Editor.Executor.Active_Buffer_Known_Project_File (S, Found_Path);
      Selected   : Boolean := False;
      Result     : Editor.Project_Search.Project_Search_Result;
   begin
      if not Editor.State.Has_Active_Buffer (S)
        or else not Editor.State.Current_File (S).Has_Path
      then
         Report_Info (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Report_Info (S, "No project search results");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif not Found_Path then
         Report_Info (S, "Active buffer is not a known project file");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Selected := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, Path);
      if not Selected then
         Report_Info (S, "No project search result for active file");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Result := Editor.Project_Search.Result_At
        (S.Project_Search,
         Positive (Editor.Project_Search.Selected_Result_Index (S.Project_Search)));
      Editor.Executor.Search_Results_Commands.Ensure_Search_Result_Visible (S);
      Show_Search_Results_Panel (S);
      Report_Info
        (S, "Selected project search result in active file: "
         & To_String (Result.Relative_Path) & ":"
         & Ada.Strings.Fixed.Trim (Natural'Image (Result.Row), Ada.Strings.Both));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Reveal_Active_Project_Search_Result;

end Editor.Executor.Project_Search_Result_Commands;
