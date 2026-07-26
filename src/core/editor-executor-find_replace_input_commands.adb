with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Ada.Containers;
with Ada.Strings.Fixed;
with Editor.Input_Field;
with Editor.Render_Cache;
with Editor.Search;
with Editor.Selection;
with Editor.State;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Text_Buffer;

package body Editor.Executor.Find_Replace_Input_Commands is

   use type Ada.Containers.Count_Type;
   use type Editor.Search.Search_Match_Index;

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

   function Image_Of (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image_Of;

   function Has_Find_Target_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.State.Has_Active_Buffer (S)
        and then (S.Buffer_Lifecycle.Buffer_Revision > 0
                  or else S.Buffer_Lifecycle.File_Info.Has_Path
                  or else Text_Buffer.Length (S.Buffer) > 0);
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
      Length         : constant Natural := Text_Buffer.Length (S.Buffer);
      Start_Index     : constant Natural := Natural (Match.Start_Index);
      End_Index       : constant Natural := Natural (Match.End_Index);
      Before_Is_Word  : Boolean := False;
      After_Is_Word   : Boolean := False;
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

      if Query'Length = 0 or else Has_Find_Context_Line_Terminator (Query) then
         return;
      elsif not Has_Find_Target_Buffer (S) then
         S.Active_Find_Stale := True;
         return;
      end if;

      S.Active_Find_Source_Buffer_Token := Editor.Executor.Active_Feature_Buffer_Token (S);
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
         Origin := Natural (Editor.Executor.Safe_Caret (S));
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
         Origin := Natural (Editor.Executor.Safe_Caret (S));
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
         Origin := Natural (Editor.Executor.Safe_Caret (S));
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
      Probe  : Natural := Natural (Editor.Executor.Safe_Caret (S));
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
           (Editor.Executor.Extract_Text (S.Buffer, First, Last - First + 1));
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
         Editor.Executor.Activate_Overlay
           (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
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

   procedure Execute_Find_Show
     (S : in out Editor.State.State_Type)
   is
      Was_Visible : constant Boolean :=
        S.Active_Find_Prompt;
      Status : Find_Context_Query_Status := Find_Context_Query_Ready;
      Query  : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
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
         Editor.Executor.Dismiss_Active_Overlay
           (S, Editor.Overlay_Focus.Dismiss_Command);
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
      S.Active_Replace_Prompt := False;
      S.Active_Replace_Text := Null_Unbounded_String;
      S.Active_Replace_Error_Message := Null_Unbounded_String;
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
         Editor.Executor.Activate_Overlay
           (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
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
      elsif not Editor.Executor.Find_Replace_Commands.Has_Find_Target_Buffer (S) then
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

   procedure Execute_Active_Find_Input_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String) is
   begin
      if not S.Active_Find_Prompt then
         return;
      end if;
      Editor.Input_Field.Insert_Text (S.Active_Find_Input, Text);
      Editor.Executor.Find_Replace_Commands.Set_Active_Find_Query_And_Report
        (S, Editor.Input_Field.Text (S.Active_Find_Input));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Active_Find_Input_Insert_Text;

   procedure Execute_Active_Find_Input_Backspace
     (S : in out Editor.State.State_Type) is
   begin
      if not S.Active_Find_Prompt then
         return;
      end if;
      Editor.Input_Field.Backspace (S.Active_Find_Input);
      Editor.Executor.Find_Replace_Commands.Set_Active_Find_Query_And_Report
        (S, Editor.Input_Field.Text (S.Active_Find_Input));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Active_Find_Input_Backspace;

   procedure Execute_Active_Find_Input_Delete_Forward
     (S : in out Editor.State.State_Type) is
   begin
      if not S.Active_Find_Prompt then
         return;
      end if;
      Editor.Input_Field.Delete_Forward (S.Active_Find_Input);
      Editor.Executor.Find_Replace_Commands.Set_Active_Find_Query_And_Report
        (S, Editor.Input_Field.Text (S.Active_Find_Input));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Active_Find_Input_Delete_Forward;

   procedure Execute_Active_Find_Input_Move_Cursor_Left
     (S : in out Editor.State.State_Type) is
   begin
      if S.Active_Find_Prompt then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Editor.Input_Field.Move_Cursor_Left (S.Active_Find_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Active_Find_Input_Move_Cursor_Left;

   procedure Execute_Active_Find_Input_Move_Cursor_Right
     (S : in out Editor.State.State_Type) is
   begin
      if S.Active_Find_Prompt then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Editor.Input_Field.Move_Cursor_Right (S.Active_Find_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Active_Find_Input_Move_Cursor_Right;

   procedure Execute_Active_Find_Input_Move_Cursor_Start
     (S : in out Editor.State.State_Type) is
   begin
      if S.Active_Find_Prompt then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Editor.Input_Field.Move_Cursor_Start (S.Active_Find_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Active_Find_Input_Move_Cursor_Start;

   procedure Execute_Active_Find_Input_Move_Cursor_End
     (S : in out Editor.State.State_Type) is
   begin
      if S.Active_Find_Prompt then
         Editor.Input_Field.Set_Text
           (S.Active_Find_Input, To_String (S.Active_Find_Query));
         Editor.Input_Field.Move_Cursor_End (S.Active_Find_Input);
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Execute_Active_Find_Input_Move_Cursor_End;

end Editor.Executor.Find_Replace_Input_Commands;
