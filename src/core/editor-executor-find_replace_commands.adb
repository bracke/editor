with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Text_Buffer;

with Editor.Buffers;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor.History;
with Editor.Executor.Find_Replace_Input_Commands;
with Editor.Input_Field;
with Editor.Navigation; use Editor.Navigation;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.Search;
with Editor.Selection;
with Editor.State;
with Editor.View;

package body Editor.Executor.Find_Replace_Commands is

   use type Ada.Containers.Count_Type;
   use type Editor.Search.Search_Match_Index;

   function Active_Overlay_Is
     (S       : Editor.State.State_Type;
      Overlay : Editor.Overlay_Focus.Overlay_Target) return Boolean is
   begin
      return Editor.Overlay_Focus.Is_Active (S.Overlay_Focus, Overlay);
   end Active_Overlay_Is;

   function Find_Replace_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;

      function Has_Selection return Boolean is
      begin
         return Has_Buffer and then Editor.Selection.Has_Selection (S);
      end Has_Selection;
   begin
      case Id is
         when Command_Find_Show
            | Command_Find_Toggle
            | Command_Replace_Show
            | Command_Replace_Toggle
            | Command_Find_Case_Toggle
            | Command_Find_Case_Clear
            | Command_Find_Whole_Word_Toggle
            | Command_Find_Whole_Word_Clear =>
            return Editor.Commands.Available;

         when Command_Find_From_Selection =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Has_Selection then
               return Editor.Commands.Unavailable ("No selected text");
            end if;
            return Editor.Commands.Available;

         when Command_Find_From_Active_Word =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Available;

         when Command_Find_Hide =>
            if not Active_Overlay_Is
              (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
              or else not S.Active_Find_Prompt
            then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Command_Replace_Hide =>
            if not S.Active_Replace_Prompt then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Command_Replace_Text_Set =>
            if not S.Active_Replace_Prompt then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Command_Replace_Text_Clear =>
            if not S.Active_Replace_Prompt then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0
            then
               return Editor.Commands.Unavailable
                 ("No replacement text to clear");
            end if;
            return Editor.Commands.Available;

         when Command_Find_Query_Set =>
            if not Active_Overlay_Is
              (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
              or else not S.Active_Find_Prompt
            then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Command_Find_Query_Clear =>
            if not Active_Overlay_Is
              (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
              or else not S.Active_Find_Prompt
            then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Length (S.Active_Find_Query) = 0 then
               return Editor.Commands.Unavailable ("No find query");
            end if;
            return Editor.Commands.Available;

         when Command_Active_Find_Next
            | Command_Active_Find_Previous
            | Command_Find_First
            | Command_Find_Last
            | Command_Find_Reveal_Current
            | Command_Replace_Current
            | Command_Replace_All =>
            if not Has_Find_Target_Buffer (S) then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif Length (S.Active_Find_Query) = 0 then
               return Editor.Commands.Unavailable ("No find query");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a find/replace command");
      end case;
   end Find_Replace_Command_Availability;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Warning;

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

   function Find_Query_Has_Line_Break (Query : String) return Boolean is
   begin
      for Ch of Query loop
         if Ch = ASCII.LF or else Ch = ASCII.CR then
            return True;
         end if;
      end loop;
      return False;
   end Find_Query_Has_Line_Break;

   function Image_Of (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image_Of;

   function Has_Find_Target_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.State.Has_Active_Buffer (S)
        and then (S.Buffer_Revision > 0
                  or else S.File_Info.Has_Path
                  or else Buffer_Length (S) > 0);
   end Has_Find_Target_Buffer;

   function Is_Find_Word_Character (Ch : Character) return Boolean is
   begin
      return (Ch in 'A' .. 'Z')
        or else (Ch in 'a' .. 'z')
        or else (Ch in '0' .. '9')
        or else Ch = '_';
   end Is_Find_Word_Character;

   function Is_Whole_Word_Find_Match
     (S     : Editor.State.State_Type;
      Match : Editor.Search.Search_Match) return Boolean
   is
      Length       : constant Natural := Text_Buffer.Length (S.Buffer);
      Start_Index  : constant Natural := Natural (Match.Start_Index);
      End_Index    : constant Natural := Natural (Match.End_Index);
      Before_Is_Word : Boolean := False;
      After_Is_Word  : Boolean := False;
   begin
      if Start_Index > 0 then
         Before_Is_Word := Is_Find_Word_Character
           (Text_Buffer.Character_At (S.Buffer, Start_Index - 1));
      end if;

      if End_Index < Length then
         After_Is_Word := Is_Find_Word_Character
           (Text_Buffer.Character_At (S.Buffer, End_Index));
      end if;

      return not Before_Is_Word and then not After_Is_Word;
   end Is_Whole_Word_Find_Match;

   procedure Append_Active_Find_Match
     (Matches : in out Editor.Search.Search_Match_Vectors.Vector;
      Match   : Editor.Search.Search_Match)
   is
      Renumbered : Editor.Search.Search_Match := Match;
   begin
      Renumbered.Index := Editor.Search.Search_Match_Index
        (Natural (Matches.Length) + 1);
      Matches.Append (Renumbered);
   end Append_Active_Find_Match;

   procedure Recompute_Active_Find_Matches
     (S : in out Editor.State.State_Type)
   is
      Options : constant Editor.Search.Search_Options :=
        (Case_Sensitive => S.Active_Find_Case_Sensitive, Wrap => True);
      Query   : constant String := To_String (S.Active_Find_Query);
      Candidates : Editor.Search.Search_Match_Vectors.Vector;
   begin
      if not Editor.Buffers.Global_Registry_Current_For (S) then
         Editor.Buffers.Ensure_Global_Registry (S);
      end if;

      S.Active_Find_Matches.Clear;
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Active_Find_Stale := False;
      S.Active_Find_Wrapped := False;
      S.Active_Find_Source_Buffer_Token := 0;

      if Query'Length = 0 or else Find_Query_Has_Line_Break (Query) then
         return;
      elsif not Has_Find_Target_Buffer (S) then
         S.Active_Find_Stale := True;
         return;
      end if;

      S.Active_Find_Source_Buffer_Token := Active_Feature_Buffer_Token (S);
      Editor.Search.Find_All (S.Buffer, Query, Options, Candidates);

      if not S.Active_Find_Whole_Word then
         S.Active_Find_Matches := Candidates;
      else
         for Match of Candidates loop
            if Is_Whole_Word_Find_Match (S, Match) then
               Append_Active_Find_Match (S.Active_Find_Matches, Match);
            end if;
         end loop;
      end if;
   end Recompute_Active_Find_Matches;

   function Find_Match_By_Ordinal
     (S       : Editor.State.State_Type;
      Ordinal : Natural) return Editor.Search.Search_Match
   is
      Zero : Natural := 0;
   begin
      if Ordinal = 0 or else S.Active_Find_Matches.Is_Empty then
         return Editor.Search.No_Match;
      end if;
      Zero := S.Active_Find_Matches.First_Index + Ordinal - 1;
      if Zero > S.Active_Find_Matches.Last_Index then
         return Editor.Search.No_Match;
      end if;
      return S.Active_Find_Matches (Zero);
   end Find_Match_By_Ordinal;

   function Selected_Find_Ordinal
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if S.Active_Find_Match.Index = Editor.Search.No_Search_Match then
         return 0;
      end if;
      return Natural (S.Active_Find_Match.Index);
   end Selected_Find_Ordinal;

   function Active_Find_Match_Is_Selected
     (S : Editor.State.State_Type) return Boolean
   is
      Start_Index : constant Natural :=
        Natural (S.Active_Find_Match.Start_Index);
      End_Index   : constant Natural :=
        Natural (S.Active_Find_Match.End_Index);
      Pos         : Natural := 0;
      Anchor      : Natural := 0;
   begin
      if S.Active_Find_Match.Index = Editor.Search.No_Search_Match
        or else S.Carets.Length = 0
      then
         return False;
      end if;

      Pos := Natural (S.Carets (S.Carets.First_Index).Pos);
      Anchor := Natural (S.Carets (S.Carets.First_Index).Anchor);
      return (Anchor = Start_Index and then Pos = Start_Index)
        or else (Anchor = Start_Index and then Pos = End_Index)
        or else (Anchor = End_Index and then Pos = Start_Index);
   end Active_Find_Match_Is_Selected;

   function Active_Find_Match_Is_Current
     (S : Editor.State.State_Type) return Boolean
   is
      Ordinal : constant Natural := Selected_Find_Ordinal (S);
      Match   : Editor.Search.Search_Match;
   begin
      if Ordinal = 0 then
         return False;
      end if;

      Match := Find_Match_By_Ordinal (S, Ordinal);
      return Editor.Search.Has_Match (Match)
        and then Match.Start_Index = S.Active_Find_Match.Start_Index
        and then Match.End_Index = S.Active_Find_Match.End_Index;
   end Active_Find_Match_Is_Current;

   function First_Find_Ordinal_At_Or_After_Caret
     (S : Editor.State.State_Type) return Natural
   is
      Origin : Natural := 0;
   begin
      if S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      if S.Carets.Length > 0 then
         Origin := Natural (Safe_Caret (S));
      end if;

      for M of S.Active_Find_Matches loop
         if Natural (M.Start_Index) >= Origin then
            return Natural (M.Index);
         end if;
      end loop;

      return Natural (S.Active_Find_Matches (S.Active_Find_Matches.First_Index).Index);
   end First_Find_Ordinal_At_Or_After_Caret;

   function First_Find_Ordinal_Before_Caret
     (S : Editor.State.State_Type) return Natural
   is
      Origin : Natural := 0;
   begin
      if S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      if S.Carets.Length > 0 then
         Origin := Natural (Safe_Caret (S));
      end if;

      for I in reverse S.Active_Find_Matches.First_Index .. S.Active_Find_Matches.Last_Index loop
         declare
            M : constant Editor.Search.Search_Match := S.Active_Find_Matches (I);
         begin
            if Natural (M.Start_Index) < Origin then
               return Natural (M.Index);
            end if;
         end;
      end loop;

      return Natural (S.Active_Find_Matches (S.Active_Find_Matches.Last_Index).Index);
   end First_Find_Ordinal_Before_Caret;

   procedure Select_Active_Find_Nearest_Caret
     (S : in out Editor.State.State_Type)
   is
      Ordinal : constant Natural := First_Find_Ordinal_At_Or_After_Caret (S);
   begin
      S.Active_Find_Match := Find_Match_By_Ordinal (S, Ordinal);
   end Select_Active_Find_Nearest_Caret;

   procedure Select_Active_Find_Containing_Caret_Or_Nearest
     (S : in out Editor.State.State_Type)
   is
      Origin : Natural := 0;
   begin
      if S.Active_Find_Matches.Is_Empty then
         S.Active_Find_Match := Editor.Search.No_Match;
         return;
      end if;

      if S.Carets.Length > 0 then
         Origin := Natural (Safe_Caret (S));
      end if;

      for Match of S.Active_Find_Matches loop
         if Origin >= Natural (Match.Start_Index)
           and then Origin < Natural (Match.End_Index)
         then
            S.Active_Find_Match := Match;
            return;
         end if;
      end loop;

      Select_Active_Find_Nearest_Caret (S);
   end Select_Active_Find_Containing_Caret_Or_Nearest;

   Max_Find_Context_Query_Length : constant Natural := 256;

   type Find_Context_Query_Status is
     (Find_Context_Query_Ready,
      Find_Context_No_Active_Buffer,
      Find_Context_No_Selected_Text,
      Find_Context_No_Searchable_Text,
      Find_Context_Selection_Multiline,
      Find_Context_Query_Too_Long);

   function Find_Context_Message
     (Status : Find_Context_Query_Status) return String
   is
   begin
      case Status is
         when Find_Context_Query_Ready =>
            return "";
         when Find_Context_No_Active_Buffer =>
            return "No active buffer.";
         when Find_Context_No_Selected_Text =>
            return "No selected text";
         when Find_Context_No_Searchable_Text =>
            return "No searchable text at cursor";
         when Find_Context_Selection_Multiline =>
            return "Selected text is not a single-line find query";
         when Find_Context_Query_Too_Long =>
            return "Selected text is too long";
      end case;
   end Find_Context_Message;

   function Is_Find_Context_Word_Character (Ch : Character) return Boolean is
   begin
      return (Ch in 'A' .. 'Z')
        or else (Ch in 'a' .. 'z')
        or else (Ch in '0' .. '9')
        or else Ch = '_';
   end Is_Find_Context_Word_Character;

   function Is_Find_Context_Line_Terminator (Ch : Character) return Boolean is
   begin
      return Ch = Character'Val (10) or else Ch = Character'Val (13);
   end Is_Find_Context_Line_Terminator;

   function Trim_Outer_Find_Context_Line_Terminators
     (Text : String) return String
   is
      First : Integer := Text'First;
      Last  : Integer := Text'Last;
   begin
      if Text'Length = 0 then
         return "";
      end if;

      while First <= Last
        and then Is_Find_Context_Line_Terminator (Text (First))
      loop
         First := First + 1;
      end loop;

      while Last >= First
        and then Is_Find_Context_Line_Terminator (Text (Last))
      loop
         Last := Last - 1;
      end loop;

      if First > Last then
         return "";
      end if;

      return Text (First .. Last);
   end Trim_Outer_Find_Context_Line_Terminators;

   function Has_Find_Context_Line_Terminator (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Is_Find_Context_Line_Terminator (Ch) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Find_Context_Line_Terminator;

   function Find_Query_From_Selection
     (S      : Editor.State.State_Type;
      Status : out Find_Context_Query_Status) return String
   is
      Selection_Range : Editor.Selection.Active_Selection_Range;
      Selection_Status : constant Editor.Selection.Selection_Validation_Status :=
        Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      pragma Unreferenced (Selection_Range);
   begin
      case Selection_Status is
         when Editor.Selection.Selection_No_Active_Buffer =>
            Status := Find_Context_No_Active_Buffer;
            return "";
         when Editor.Selection.Selection_No_Caret
            | Editor.Selection.Selection_Empty
            | Editor.Selection.Selection_Invalid =>
            Status := Find_Context_No_Selected_Text;
            return "";
         when Editor.Selection.Selection_Ok =>
            null;
      end case;

      declare
         Raw_Text : constant String :=
           To_String (Editor.Selection.Extract_Selected_Text (S));
         Text     : constant String :=
           Trim_Outer_Find_Context_Line_Terminators (Raw_Text);
      begin
         if Text'Length = 0 then
            Status := Find_Context_No_Selected_Text;
            return "";
         elsif Has_Find_Context_Line_Terminator (Text) then
            Status := Find_Context_Selection_Multiline;
            return "";
         elsif Text'Length > Max_Find_Context_Query_Length then
            Status := Find_Context_Query_Too_Long;
            return "";
         else
            Status := Find_Context_Query_Ready;
            return Text;
         end if;
      end;
   end Find_Query_From_Selection;

   function Find_Query_From_Active_Word
     (S      : Editor.State.State_Type;
      Status : out Find_Context_Query_Status) return String
   is
      Length : Natural := 0;
      Probe  : Natural := Natural (Safe_Caret (S));
      First  : Natural := 0;
      Last   : Natural := 0;
   begin
      Status := Find_Context_No_Searchable_Text;
      if not Editor.State.Has_Active_Buffer (S) then
         Status := Find_Context_No_Active_Buffer;
         return "";
      end if;

      Length := Text_Buffer.Length (S.Buffer);
      if Length = 0 or else Probe >= Length then
         return "";
      end if;

      if not Is_Find_Context_Word_Character
        (Text_Buffer.Character_At (S.Buffer, Probe))
      then
         return "";
      end if;

      First := Probe;
      while First > 0
        and then Is_Find_Context_Word_Character
          (Text_Buffer.Character_At (S.Buffer, First - 1))
      loop
         First := First - 1;
      end loop;

      Last := Probe;
      while Last + 1 < Length
        and then Is_Find_Context_Word_Character
          (Text_Buffer.Character_At (S.Buffer, Last + 1))
      loop
         Last := Last + 1;
      end loop;

      declare
         Text : constant String := To_String
           (Extract_Text (S.Buffer, First, Last - First + 1));
      begin
         if Text'Length = 0 then
            return "";
         elsif Text'Length > Max_Find_Context_Query_Length then
            Status := Find_Context_Query_Too_Long;
            return "";
         else
            Status := Find_Context_Query_Ready;
            return Text;
         end if;
      end;
   end Find_Query_From_Active_Word;

   procedure Apply_Find_Context_Query
     (S     : in out Editor.State.State_Type;
      Query : String)
   is
   begin
      if not S.Active_Find_Prompt then
         Activate_Overlay (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
      end if;

      S.Active_Find_Prompt := True;
      Set_Active_Find_Query_And_Report (S, Query);
      Select_Active_Find_Containing_Caret_Or_Nearest (S);
      Editor.Render_Cache.Invalidate_All;
   end Apply_Find_Context_Query;

   procedure Execute_Find_From_Selection
     (S : in out Editor.State.State_Type)
   is
      Status : Find_Context_Query_Status := Find_Context_Query_Ready;
      Query  : constant String := Find_Query_From_Selection (S, Status);
   begin
      if Status /= Find_Context_Query_Ready then
         Report_Info (S, Find_Context_Message (Status));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Apply_Find_Context_Query (S, Query);
   end Execute_Find_From_Selection;

   procedure Execute_Find_From_Active_Word
     (S : in out Editor.State.State_Type)
   is
      Status : Find_Context_Query_Status := Find_Context_Query_Ready;
      Query  : constant String := Find_Query_From_Active_Word (S, Status);
   begin
      if Status /= Find_Context_Query_Ready then
         Report_Info (S, Find_Context_Message (Status));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Apply_Find_Context_Query (S, Query);
   end Execute_Find_From_Active_Word;

   procedure Clear_Active_Replace_State
     (S : in out Editor.State.State_Type);

   procedure Reset_Active_Find_Query_State
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Input_Field.Set_Text (S.Active_Find_Input, "");
      S.Active_Find_Query := To_Unbounded_String ("");
      S.Active_Find_Matches.Clear;
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Active_Find_Stale := False;
      S.Active_Find_Wrapped := False;
      S.Active_Find_Source_Buffer_Token := 0;
   end Reset_Active_Find_Query_State;

   procedure Set_Active_Find_Query_And_Report
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
      Query : constant String := Text;
      Count : Natural := 0;
   begin
      Editor.Input_Field.Set_Text (S.Active_Find_Input, Query);
      S.Active_Find_Query := To_Unbounded_String (Query);

      if Query'Length = 0 then
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := False;
         S.Active_Find_Source_Buffer_Token := 0;
         Report_Info (S, "No find query");
      elsif not Has_Find_Target_Buffer (S) then
         --  Preserve the transient query, but do not manufacture an empty
         --  result set for a buffer that Find cannot search.  The next
         --  explicit find navigation against a real active buffer will
         --  recompute from current in-memory text.
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := True;
         S.Active_Find_Source_Buffer_Token := 0;
         Report_Warning (S, "No active buffer.");
      else
         Recompute_Active_Find_Matches (S);
         Select_Active_Find_Nearest_Caret (S);
         Count := Natural (S.Active_Find_Matches.Length);
         if Count = 0 then
            Report_Info (S, "Find query set: no matches");
         else
            Report_Info (S, "Find query set: " & Image_Of (Count) & " matches");
         end if;
      end if;
   end Set_Active_Find_Query_And_Report;

   procedure Sync_Active_Find_Input_From_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Input_Field.Set_Text
        (S.Active_Find_Input, To_String (S.Active_Find_Query));
   end Sync_Active_Find_Input_From_Query;

   procedure Execute_Find_Show
     (S : in out Editor.State.State_Type)
   is
      Was_Visible : constant Boolean :=
        S.Active_Find_Prompt;
      Status : Find_Context_Query_Status := Find_Context_Query_Ready;
      Query  : Unbounded_String := Null_Unbounded_String;
   begin
      Activate_Overlay (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
      S.Active_Find_Prompt := True;
      Editor.Input_Field.Set_Text (S.Active_Find_Input, To_String (S.Active_Find_Query));

      if Was_Visible then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Report_Info (S, "Find shown");
      else
         S.Active_Find_Case_Sensitive := False;
         S.Active_Find_Whole_Word := False;
         Query := To_Unbounded_String (Find_Query_From_Selection (S, Status));
         if Status = Find_Context_Query_Ready then
            Set_Active_Find_Query_And_Report (S, To_String (Query));
         else
            --  Ordinary prompt show is intentionally quiet for absent,
            --  multiline, or too-long selections.  Explicit context commands
            --  report those failures, but show simply prepares an empty prompt.
            Reset_Active_Find_Query_State (S);
            Report_Info (S, "Find shown");
         end if;
      end if;

      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Show;

   procedure Execute_Find_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
      then
         Dismiss_Active_Overlay (S, Editor.Overlay_Focus.Dismiss_Command);
      else
         Editor.Input_Field.Clear (S.Active_Find_Input);
      end if;
      Editor.Input_Field.Set_Text (S.Active_Find_Input, "");
      S.Active_Find_Query := To_Unbounded_String ("");
      S.Active_Find_Matches.Clear;
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Active_Find_Stale := False;
      S.Active_Find_Wrapped := False;
      S.Active_Find_Case_Sensitive := False;
      S.Active_Find_Whole_Word := False;
      S.Active_Find_Source_Buffer_Token := 0;
      S.Active_Find_Prompt := False;
      Clear_Active_Replace_State (S);
      Report_Info (S, "Find hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Hide;

   procedure Execute_Find_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.Active_Find_Prompt
        and then Editor.Overlay_Focus.Is_Active
          (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
      then
         Execute_Find_Hide (S);
      else
         Execute_Find_Show (S);
      end if;
   end Execute_Find_Toggle;

   procedure Execute_Find_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      if not S.Active_Find_Prompt then
         Activate_Overlay (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
         Editor.Input_Field.Set_Text (S.Active_Find_Input, To_String (S.Active_Find_Query));
      end if;
      S.Active_Find_Prompt := True;
      Set_Active_Find_Query_And_Report (S, Text);
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Set_Query;

   procedure Execute_Find_Clear_Query
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Input_Field.Set_Text (S.Active_Find_Input, "");
      S.Active_Find_Query := To_Unbounded_String ("");
      S.Active_Find_Matches.Clear;
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Active_Find_Stale := False;
      S.Active_Find_Source_Buffer_Token := 0;
      Report_Info (S, "Find query cleared");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Clear_Query;



   function Find_Option_Message
     (S       : Editor.State.State_Type;
      Prefix  : String;
      Include_Count : Boolean) return String
   is
      Count : constant Natural := Natural (S.Active_Find_Matches.Length);
   begin
      if not Include_Count then
         return Prefix;
      elsif Count = 0 then
         return Prefix & "; no matches";
      else
         return Prefix & "; " & Image_Of (Count) & " matches";
      end if;
   end Find_Option_Message;

   procedure Recompute_Find_After_Option_Change
     (S : in out Editor.State.State_Type)
   is
   begin
      if Length (S.Active_Find_Query) = 0 then
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := False;
         S.Active_Find_Source_Buffer_Token := 0;
      elsif Has_Find_Target_Buffer (S) then
         Recompute_Active_Find_Matches (S);
         Select_Active_Find_Nearest_Caret (S);
      else
         --  A non-empty query without a searchable active buffer remains a
         --  stale transient Find query.  Option commands must not convert it
         --  into a current empty result set, because the next active-buffer
         --  navigation should recompute using the current case/whole-word
         --  options once a target buffer exists.
         S.Active_Find_Matches.Clear;
         S.Active_Find_Match := Editor.Search.No_Match;
         S.Active_Find_Stale := True;
         S.Active_Find_Source_Buffer_Token := 0;
      end if;
   end Recompute_Find_After_Option_Change;

   procedure Execute_Find_Case_Toggle
     (S : in out Editor.State.State_Type)
   is
      Include_Count : constant Boolean := Length (S.Active_Find_Query) > 0;
   begin
      S.Active_Find_Case_Sensitive := not S.Active_Find_Case_Sensitive;
      Recompute_Find_After_Option_Change (S);
      Report_Info
        (S,
         Find_Option_Message
           (S,
            (if S.Active_Find_Case_Sensitive
             then "Find case: sensitive"
             else "Find case: insensitive"),
            Include_Count and then Has_Find_Target_Buffer (S)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Case_Toggle;

   procedure Execute_Find_Case_Clear
     (S : in out Editor.State.State_Type)
   is
      Include_Count : constant Boolean := Length (S.Active_Find_Query) > 0;
   begin
      if not S.Active_Find_Case_Sensitive then
         Report_Info (S, "Find case already insensitive");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      S.Active_Find_Case_Sensitive := False;
      Recompute_Find_After_Option_Change (S);
      Report_Info
        (S,
         Find_Option_Message
           (S, "Find case: insensitive",
            Include_Count and then Has_Find_Target_Buffer (S)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Case_Clear;

   procedure Execute_Find_Whole_Word_Toggle
     (S : in out Editor.State.State_Type)
   is
      Include_Count : constant Boolean := Length (S.Active_Find_Query) > 0;
   begin
      S.Active_Find_Whole_Word := not S.Active_Find_Whole_Word;
      Recompute_Find_After_Option_Change (S);
      Report_Info
        (S,
         Find_Option_Message
           (S,
            (if S.Active_Find_Whole_Word
             then "Find whole word: on"
             else "Find whole word: off"),
            Include_Count and then Has_Find_Target_Buffer (S)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Whole_Word_Toggle;

   procedure Execute_Find_Whole_Word_Clear
     (S : in out Editor.State.State_Type)
   is
      Include_Count : constant Boolean := Length (S.Active_Find_Query) > 0;
   begin
      if not S.Active_Find_Whole_Word then
         Report_Info (S, "Find whole word already off");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      S.Active_Find_Whole_Word := False;
      Recompute_Find_After_Option_Change (S);
      Report_Info
        (S,
         Find_Option_Message
           (S, "Find whole word: off",
            Include_Count and then Has_Find_Target_Buffer (S)));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Whole_Word_Clear;

   procedure Move_To_Find_Match
     (S        : in out Editor.State.State_Type;
     Match    : Editor.Search.Search_Match;
     Previous : Editor.Navigation_History.Navigation_Location;
     Reason   : Editor.Navigation_History.Navigation_History_Reason)
   is
      pragma Unreferenced (Previous);
      Effective_Previous : Editor.Navigation_History.Navigation_Location;
      Target : Editor.Navigation_History.Navigation_Location;
   begin
      if not Editor.Buffers.Global_Registry_Current_For (S) then
         Editor.Buffers.Ensure_Global_Registry (S);
      end if;
      Effective_Previous := Current_Navigation_Location (S, Reason);

      S.Active_Find_Match := Match;
      Apply_Feature_Target_Handoff (S, Match.Start_Row, Match.Start_Column);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Match.Start_Index,
           Anchor                => Match.Start_Index,
           Virtual_Column        => 0,
           Anchor_Virtual_Column => 0));
      S.Preferred_Column := Match.Start_Column;

      Target :=
        (Buffer_Id      => Active_Feature_Buffer_Token (S),
         Has_File_Path  => S.File_Info.Has_Path,
         File_Path      => S.File_Info.Path,
         Display_Path   => S.File_Info.Display_Name,
         Line           => Natural (Match.Start_Row) + 1,
         Column         => Natural (Match.Start_Column),
         Viewport_Row   => Editor.View.Scroll_Y,
         Reason         => Reason);
      Record_Navigation_If_Target_Changed (S, Effective_Previous, Target);
   end Move_To_Find_Match;

   procedure Execute_Find_Next
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Ordinal : Natural := 0;
      Prior_Ordinal : Natural := 0;
      Wrapped : Boolean := False;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Prior_Ordinal :=
        (if Active_Find_Match_Is_Selected (S)
           or else Active_Find_Match_Is_Current (S)
         then Selected_Find_Ordinal (S)
         else 0);
      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Prior_Ordinal = 0 or else Prior_Ordinal > Count then
         Ordinal := First_Find_Ordinal_At_Or_After_Caret (S);
         Wrapped := Ordinal = 1
           and then S.Carets.Length > 0
           and then Natural (Safe_Caret (S)) > Natural (S.Active_Find_Matches (S.Active_Find_Matches.Last_Index).Start_Index);
      else
         Ordinal := Prior_Ordinal + 1;
         if Ordinal > Count then
            Ordinal := 1;
            Wrapped := True;
         end if;
      end if;

      S.Active_Find_Wrapped := Wrapped;
      Match := Find_Match_By_Ordinal (S, Ordinal);
      Previous := Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Find_Next);
      Move_To_Find_Match
        (S, Match, Previous, Editor.Navigation_History.Navigation_Reason_Find_Next);
      Report_Success
        (S, "Found match " & Image_Of (Ordinal) & " of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Next;

   procedure Execute_Find_Previous
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Ordinal : Natural := 0;
      Prior_Ordinal : Natural := 0;
      Wrapped : Boolean := False;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Prior_Ordinal :=
        (if Active_Find_Match_Is_Selected (S)
           or else Active_Find_Match_Is_Current (S)
         then Selected_Find_Ordinal (S)
         else 0);
      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Prior_Ordinal = 0 or else Prior_Ordinal > Count then
         Ordinal := First_Find_Ordinal_Before_Caret (S);
         Wrapped := Ordinal = Count
           and then S.Carets.Length > 0
           and then Natural (Safe_Caret (S)) <= Natural (S.Active_Find_Matches (S.Active_Find_Matches.First_Index).Start_Index);
      else
         Ordinal := Prior_Ordinal;
         if Ordinal <= 1 then
            Ordinal := Count;
            Wrapped := True;
         else
            Ordinal := Ordinal - 1;
         end if;
      end if;

      S.Active_Find_Wrapped := Wrapped;
      Match := Find_Match_By_Ordinal (S, Ordinal);
      Previous := Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Find_Previous);
      Move_To_Find_Match
        (S, Match, Previous, Editor.Navigation_History.Navigation_Reason_Find_Previous);
      Report_Success
        (S, "Found previous match " & Image_Of (Ordinal) & " of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Previous;



   function Find_Match_Contains_Caret
     (S     : Editor.State.State_Type;
      Match : Editor.Search.Search_Match) return Boolean
   is
      Origin : Natural := 0;
   begin
      if S.Carets.Length > 0 then
         Origin := Natural (Safe_Caret (S));
      end if;

      return Origin >= Natural (Match.Start_Index)
        and then Origin < Natural (Match.End_Index);
   end Find_Match_Contains_Caret;

   function Find_Ordinal_Containing_Caret
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      for M of S.Active_Find_Matches loop
         if Find_Match_Contains_Caret (S, M) then
            return Natural (M.Index);
         end if;
      end loop;

      return 0;
   end Find_Ordinal_Containing_Caret;

   function Find_Ordinal_For_Current_Caret
     (S : Editor.State.State_Type) return Natural
   is
      Containing : constant Natural := Find_Ordinal_Containing_Caret (S);
   begin
      if Containing /= 0 then
         return Containing;
      end if;
      return First_Find_Ordinal_At_Or_After_Caret (S);
   end Find_Ordinal_For_Current_Caret;

   procedure Execute_Find_First
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Match := Find_Match_By_Ordinal (S, 1);
      Previous := Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Find_Next);
      Move_To_Find_Match
        (S, Match, Previous, Editor.Navigation_History.Navigation_Reason_Find_Next);
      Report_Success
        (S, "Found first match 1 of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_First;

   procedure Execute_Find_Last
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Previous : Editor.Navigation_History.Navigation_Location;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Match := Find_Match_By_Ordinal (S, Count);
      Previous := Current_Navigation_Location
        (S, Editor.Navigation_History.Navigation_Reason_Find_Previous);
      Move_To_Find_Match
        (S, Match, Previous, Editor.Navigation_History.Navigation_Reason_Find_Previous);
      Report_Success
        (S, "Found last match " & Image_Of (Count) & " of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Last;

   procedure Execute_Find_Reveal_Current
     (S : in out Editor.State.State_Type)
   is
      Query : constant String := To_String (S.Active_Find_Query);
      Count : Natural := 0;
      Ordinal : Natural := 0;
   begin
      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      S.Active_Find_Prompt := True;
      Activate_Overlay (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
      Editor.Input_Field.Set_Text (S.Active_Find_Input, To_String (S.Active_Find_Query));
      Editor.Input_Field.Set_Text (S.Active_Find_Input, Query);

      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Ordinal := Find_Ordinal_For_Current_Caret (S);
      S.Active_Find_Match := Find_Match_By_Ordinal (S, Ordinal);
      Report_Success
        (S, "Selected find match " & Image_Of (Ordinal) & " of " & Image_Of (Count));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Find_Reveal_Current;


   procedure Clear_Active_Replace_State
     (S : in out Editor.State.State_Type)
   is
   begin
      S.Active_Replace_Prompt := False;
      S.Active_Replace_Text := Null_Unbounded_String;
      S.Active_Replace_Error_Message := Null_Unbounded_String;
   end Clear_Active_Replace_State;

   procedure Execute_Replace_Show
     (S : in out Editor.State.State_Type)
   is
   begin
      Activate_Overlay (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;
      S.Active_Replace_Error_Message := Null_Unbounded_String;
      Editor.Input_Field.Set_Text (S.Active_Find_Input, To_String (S.Active_Find_Query));
      Report_Info (S, "Replace shown");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Show;

   procedure Execute_Replace_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Clear_Active_Replace_State (S);
      Report_Info (S, "Replace hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Hide;

   procedure Execute_Replace_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.Active_Replace_Prompt then Execute_Replace_Hide (S); else Execute_Replace_Show (S); end if;
   end Execute_Replace_Toggle;

   function Is_Valid_Replace_Text (Text : String) return Boolean;

   procedure Report_Invalid_Replace_Text (S : in out Editor.State.State_Type);

   procedure Execute_Replace_Set_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Activate_Overlay (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;

      if not Is_Valid_Replace_Text (Text) then
         Report_Invalid_Replace_Text (S);
         return;
      end if;

      S.Active_Replace_Text := To_Unbounded_String (Text);
      S.Active_Replace_Error_Message := Null_Unbounded_String;
      Report_Info (S, "Replace text set");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Set_Text;

   procedure Execute_Replace_Clear_Text
     (S : in out Editor.State.State_Type)
   is
   begin
      if Length (S.Active_Replace_Text) = 0 and then Length (S.Active_Replace_Error_Message) = 0 then
         Report_Info (S, "No replacement text to clear");
      else
         S.Active_Replace_Text := Null_Unbounded_String;
         S.Active_Replace_Error_Message := Null_Unbounded_String;
         Report_Info (S, "Replace text cleared");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Clear_Text;

   function Is_Valid_Replace_Text (Text : String) return Boolean
   is
   begin
      for Ch of Text loop
         if Ch = Character'Val (10) or else Ch = Character'Val (13) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Replace_Text;

   procedure Report_Invalid_Replace_Text (S : in out Editor.State.State_Type)
   is
   begin
      S.Active_Replace_Error_Message :=
        To_Unbounded_String ("Replacement text must be single-line");
      Report_Warning (S, "Replacement text must be single-line");
      Editor.Render_Cache.Invalidate_All;
   end Report_Invalid_Replace_Text;

   procedure Append_Find_Replacement_Op
     (Cmd   : in out Editor.Commands.Command;
      Match : Editor.Search.Search_Match;
      Text  : Unbounded_String)
   is
   begin
      Append_Replace_Op (Cmd, Match.Start_Index, Natural (Match.End_Index - Match.Start_Index), Text);
   end Append_Find_Replacement_Op;

   function Find_Ordinal_For_Same_Range
     (S     : Editor.State.State_Type;
      Prior : Editor.Search.Search_Match) return Natural
   is
   begin
      if not Editor.Search.Has_Match (Prior) or else S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      for M of S.Active_Find_Matches loop
         if M.Start_Index = Prior.Start_Index and then M.End_Index = Prior.End_Index then
            return Natural (M.Index);
         end if;
      end loop;

      return 0;
   end Find_Ordinal_For_Same_Range;

   function First_Find_Ordinal_At_Or_After_Index
     (S      : Editor.State.State_Type;
      Origin : Natural) return Natural
   is
   begin
      if S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      for M of S.Active_Find_Matches loop
         if Natural (M.Start_Index) >= Origin then
            return Natural (M.Index);
         end if;
      end loop;

      return Natural (S.Active_Find_Matches (S.Active_Find_Matches.First_Index).Index);
   end First_Find_Ordinal_At_Or_After_Index;

   procedure Select_Active_Find_At_Or_After_Index
     (S      : in out Editor.State.State_Type;
      Origin : Natural)
   is
      Ordinal : constant Natural := First_Find_Ordinal_At_Or_After_Index (S, Origin);
   begin
      S.Active_Find_Match := Find_Match_By_Ordinal (S, Ordinal);
   end Select_Active_Find_At_Or_After_Index;

   procedure Remove_Active_Find_Matches_Overlapping
     (S           : in out Editor.State.State_Type;
      Start_Index : Natural;
      Length      : Natural)
   is
      Stop_Index : constant Natural := Start_Index + Length;
      Filtered   : Editor.Search.Search_Match_Vectors.Vector;
   begin
      if Length = 0 or else S.Active_Find_Matches.Is_Empty then
         return;
      end if;

      for Match of S.Active_Find_Matches loop
         if Natural (Match.End_Index) <= Start_Index
           or else Natural (Match.Start_Index) >= Stop_Index
         then
            Append_Active_Find_Match (Filtered, Match);
         end if;
      end loop;

      S.Active_Find_Matches := Filtered;
      S.Active_Find_Match := Editor.Search.No_Match;
   end Remove_Active_Find_Matches_Overlapping;

   procedure Recompute_Find_After_Replace
     (S           : in out Editor.State.State_Type;
      Edit_Origin : Natural)
   is
   begin
      Recompute_Active_Find_Matches (S);
      Select_Active_Find_At_Or_After_Index (S, Edit_Origin);
   end Recompute_Find_After_Replace;

   procedure Execute_Replace_Current
     (S : in out Editor.State.State_Type)
   is
      Before : Editor.State.State_Type := S;
      Before_Text : constant String := Editor.State.Current_Text (S);
      Query : constant String := To_String (S.Active_Find_Query);
      Replacement : constant String := To_String (S.Active_Replace_Text);
      Prior_Selected : constant Editor.Search.Search_Match := S.Active_Find_Match;
      Count : Natural := 0;
      Ordinal : Natural := 0;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Edit_Origin : Natural := 0;
      Cmd : Editor.Commands.Command;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Before := S;

      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer."); Editor.Render_Cache.Invalidate_All; return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query"); Editor.Render_Cache.Invalidate_All; return;
      elsif Length (S.Active_Replace_Error_Message) > 0 then
         Report_Invalid_Replace_Text (S); return;
      elsif not Is_Valid_Replace_Text (Replacement) then
         Report_Invalid_Replace_Text (S); return;
      end if;

      if not S.Active_Find_Stale
        and then S.Active_Find_Matches.Is_Empty
        and then S.Active_Find_Source_Buffer_Token = Active_Feature_Buffer_Token (S)
      then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then Report_Info (S, "No matches"); Editor.Render_Cache.Invalidate_All; return; end if;

      Ordinal := Find_Ordinal_For_Same_Range (S, Prior_Selected);
      if Ordinal = 0 or else Ordinal > Count then
         Ordinal := First_Find_Ordinal_At_Or_After_Caret (S);
      end if;

      Match := Find_Match_By_Ordinal (S, Ordinal);
      if not Editor.Search.Has_Match (Match) then
         Report_Info (S, "No matches"); Editor.Render_Cache.Invalidate_All; return;
      end if;

      Edit_Origin := Natural (Match.Start_Index);
      Cmd.Kind := Apply_Replace_Batch;
      Append_Find_Replacement_Op (Cmd, Match, S.Active_Replace_Text);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Cmd);
      if Editor.State.Current_Text (S) /= Before_Text then
         Editor.Executor.History.Log_Edit (Before, S, Cmd);
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;
      S.Active_Replace_Error_Message := Null_Unbounded_String;
      Recompute_Find_After_Replace (S, Edit_Origin);
      if Replacement /= Query then
         Remove_Active_Find_Matches_Overlapping
           (S, Edit_Origin, Replacement'Length);
         Select_Active_Find_At_Or_After_Index (S, Edit_Origin);
      end if;
      if S.Active_Find_Matches.Is_Empty then
         Report_Success (S, "Replaced current match; no more matches");
      else
         Report_Success (S, "Replaced current match");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Current;

   procedure Execute_Replace_All
     (S : in out Editor.State.State_Type)
   is
      Before : Editor.State.State_Type := S;
      Before_Text : constant String := Editor.State.Current_Text (S);
      Query : constant String := To_String (S.Active_Find_Query);
      Replacement : constant String := To_String (S.Active_Replace_Text);
      Count : Natural := 0;
      Edit_Origin : Natural := 0;
      Cmd : Editor.Commands.Command;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Before := S;

      if not Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer."); Editor.Render_Cache.Invalidate_All; return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query"); Editor.Render_Cache.Invalidate_All; return;
      elsif Length (S.Active_Replace_Error_Message) > 0 then
         Report_Invalid_Replace_Text (S); return;
      elsif not Is_Valid_Replace_Text (Replacement) then
         Report_Invalid_Replace_Text (S); return;
      end if;

      Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then Report_Info (S, "No matches"); Editor.Render_Cache.Invalidate_All; return; end if;

      Edit_Origin := Natural (S.Active_Find_Matches (S.Active_Find_Matches.First_Index).Start_Index);
      Cmd.Kind := Apply_Replace_Batch;
      for Match of S.Active_Find_Matches loop
         Append_Find_Replacement_Op (Cmd, Match, S.Active_Replace_Text);
      end loop;
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Cmd);
      if Editor.State.Current_Text (S) /= Before_Text then
         Editor.Executor.History.Log_Edit (Before, S, Cmd);
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;
      S.Active_Replace_Error_Message := Null_Unbounded_String;
      Recompute_Find_After_Replace (S, Edit_Origin);
      if Count = 1 then Report_Success (S, "Replaced 1 match"); else Report_Success (S, "Replaced " & Image_Of (Count) & " matches"); end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_All;

   procedure Execute_Find_Replace_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String := "")
   is
   begin
      case Kind is
         when Active_Find_Show =>
            Execute_Find_Show (S);
         when Active_Find_Hide =>
            Execute_Find_Hide (S);
         when Active_Find_Toggle =>
            Execute_Find_Toggle (S);
         when Active_Find_Query_Set =>
            Execute_Find_Set_Query (S, Text);
         when Active_Find_Query_Clear =>
            Execute_Find_Clear_Query (S);
         when Active_Find_Case_Toggle =>
            Execute_Find_Case_Toggle (S);
         when Active_Find_Case_Clear =>
            Execute_Find_Case_Clear (S);
         when Active_Find_Whole_Word_Toggle =>
            Execute_Find_Whole_Word_Toggle (S);
         when Active_Find_Whole_Word_Clear =>
            Execute_Find_Whole_Word_Clear (S);
         when Active_Find_From_Selection =>
            Execute_Find_From_Selection (S);
         when Active_Find_From_Active_Word =>
            Execute_Find_From_Active_Word (S);
         when Active_Find_Next =>
            Execute_Find_Next (S);
         when Active_Find_Previous =>
            Execute_Find_Previous (S);
         when Active_Find_First =>
            Execute_Find_First (S);
         when Active_Find_Last =>
            Execute_Find_Last (S);
         when Active_Find_Reveal_Current =>
            Execute_Find_Reveal_Current (S);
         when Active_Replace_Show =>
            Execute_Replace_Show (S);
         when Active_Replace_Hide =>
            Execute_Replace_Hide (S);
         when Active_Replace_Toggle =>
            Execute_Replace_Toggle (S);
         when Active_Replace_Text_Set =>
            Execute_Replace_Set_Text (S, Text);
         when Active_Replace_Text_Clear =>
            Execute_Replace_Clear_Text (S);
         when Active_Replace_Current =>
            Execute_Replace_Current (S);
         when Active_Replace_All =>
            Execute_Replace_All (S);
         when Active_Find_Input_Insert_Text =>
            Editor.Executor.Find_Replace_Input_Commands
              .Execute_Active_Find_Input_Insert_Text (S, Text);
         when Active_Find_Input_Backspace =>
            Editor.Executor.Find_Replace_Input_Commands
              .Execute_Active_Find_Input_Backspace (S);
         when Active_Find_Input_Delete_Forward =>
            Editor.Executor.Find_Replace_Input_Commands
              .Execute_Active_Find_Input_Delete_Forward (S);
         when Active_Find_Input_Move_Cursor_Left =>
            Editor.Executor.Find_Replace_Input_Commands
              .Execute_Active_Find_Input_Move_Cursor_Left (S);
         when Active_Find_Input_Move_Cursor_Right =>
            Editor.Executor.Find_Replace_Input_Commands
              .Execute_Active_Find_Input_Move_Cursor_Right (S);
         when others =>
            raise Program_Error with "unsupported find/replace command kind";
      end case;
   end Execute_Find_Replace_Kind;


end Editor.Executor.Find_Replace_Commands;
