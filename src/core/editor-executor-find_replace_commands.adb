with Editor.Commands.Availability_Metadata;
with Editor.Commands.Payloads;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
with Editor.Executor.Active_Find_Commands;
with Editor.Executor.Active_Replace_Commands;
with Editor.Executor.History;
with Editor.Executor.Find_Replace_Input_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.Search;
with Editor.Selection;
with Editor.State;

package body Editor.Executor.Find_Replace_Commands is

   function Active_Overlay_Is
     (S       : Editor.State.State_Type;
      Overlay : Editor.Overlay_Focus.Overlay_Target) return Boolean is
   begin
      return Editor.Overlay_Focus.Is_Active (S.Overlay_Focus, Overlay);
   end Active_Overlay_Is;

   function Find_Replace_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability
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
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Find_From_Selection =>
            if not Has_Buffer then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active buffer.");
            elsif not Has_Selection then
               return Editor.Commands.Availability_Metadata.Unavailable ("No selected text");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Find_From_Active_Word =>
            if not Has_Buffer then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Find_Hide =>
            if not Active_Overlay_Is
              (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
              or else not S.Active_Find_Prompt
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Replace_Hide =>
            if not S.Active_Replace_Prompt then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Replace_Text_Set =>
            if not S.Active_Replace_Prompt then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Replace_Text_Clear =>
            if not S.Active_Replace_Prompt then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            elsif Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0
            then
               return Editor.Commands.Availability_Metadata.Unavailable
                 ("No replacement text to clear");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Find_Query_Set =>
            if not Active_Overlay_Is
              (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
              or else not S.Active_Find_Prompt
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Find_Query_Clear =>
            if not Active_Overlay_Is
              (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
              or else not S.Active_Find_Prompt
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active overlay");
            elsif Length (S.Active_Find_Query) = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No find query");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when Command_Active_Find_Next
            | Command_Active_Find_Previous
            | Command_Find_First
            | Command_Find_Last
            | Command_Find_Reveal_Current
            | Command_Replace_Current
            | Command_Replace_All =>
            if not Editor.Executor.Active_Find_Commands.Has_Find_Target_Buffer
              (S)
            then
               return Editor.Commands.Availability_Metadata.Unavailable ("No active buffer.");
            elsif Length (S.Active_Find_Query) = 0 then
               return Editor.Commands.Availability_Metadata.Unavailable ("No find query");
            end if;
            return Editor.Commands.Availability_Metadata.Available;

         when others =>
            return Editor.Commands.Availability_Metadata.Unavailable
              ("Command is not a find/replace command");
      end case;
   end Find_Replace_Command_Availability;

   function Has_Find_Target_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Executor.Active_Find_Commands.Has_Find_Target_Buffer (S);
   end Has_Find_Target_Buffer;

   procedure Execute_Find_Show
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Find_Replace_Input_Commands.Execute_Find_Show (S);
   end Execute_Find_Show;

   procedure Execute_Find_Hide
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Find_Replace_Input_Commands.Execute_Find_Hide (S);
   end Execute_Find_Hide;

   procedure Execute_Find_Toggle
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Find_Replace_Input_Commands.Execute_Find_Toggle (S);
   end Execute_Find_Toggle;

   procedure Execute_Find_Set_Query
     (S    : in out Editor.State.State_Type;
      Text : String) is
   begin
      Editor.Executor.Find_Replace_Input_Commands.Execute_Find_Set_Query
        (S, Text);
   end Execute_Find_Set_Query;

   procedure Execute_Find_Clear_Query
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Find_Replace_Input_Commands.Execute_Find_Clear_Query
        (S);
   end Execute_Find_Clear_Query;

   procedure Execute_Find_Case_Toggle
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_Case_Toggle (S);
   end Execute_Find_Case_Toggle;

   procedure Execute_Find_Case_Clear
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_Case_Clear (S);
   end Execute_Find_Case_Clear;

   procedure Execute_Find_Whole_Word_Toggle
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_Whole_Word_Toggle (S);
   end Execute_Find_Whole_Word_Toggle;

   procedure Execute_Find_Whole_Word_Clear
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_Whole_Word_Clear (S);
   end Execute_Find_Whole_Word_Clear;

   procedure Execute_Find_From_Selection
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Find_Replace_Input_Commands.Execute_Find_From_Selection
        (S);
   end Execute_Find_From_Selection;

   procedure Execute_Find_From_Active_Word
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Find_Replace_Input_Commands.Execute_Find_From_Active_Word
        (S);
   end Execute_Find_From_Active_Word;

   procedure Execute_Find_Next
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_Next (S);
   end Execute_Find_Next;

   procedure Execute_Find_Previous
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_Previous (S);
   end Execute_Find_Previous;

   procedure Execute_Find_First
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_First (S);
   end Execute_Find_First;

   procedure Execute_Find_Last
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_Last (S);
   end Execute_Find_Last;

   procedure Execute_Find_Reveal_Current
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Find_Commands.Execute_Find_Reveal_Current (S);
   end Execute_Find_Reveal_Current;

   procedure Execute_Replace_Show
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Replace_Commands.Execute_Replace_Show (S);
   end Execute_Replace_Show;

   procedure Execute_Replace_Hide
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Replace_Commands.Execute_Replace_Hide (S);
   end Execute_Replace_Hide;

   procedure Execute_Replace_Toggle
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Replace_Commands.Execute_Replace_Toggle (S);
   end Execute_Replace_Toggle;

   procedure Execute_Replace_Set_Text
     (S    : in out Editor.State.State_Type;
      Text : String) is
   begin
      Editor.Executor.Active_Replace_Commands.Execute_Replace_Set_Text
        (S, Text);
   end Execute_Replace_Set_Text;

   procedure Execute_Replace_Clear_Text
     (S : in out Editor.State.State_Type) is
   begin
      Editor.Executor.Active_Replace_Commands.Execute_Replace_Clear_Text (S);
   end Execute_Replace_Clear_Text;

   function Is_Valid_Replace_Text (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Ch = Character'Val (10) or else Ch = Character'Val (13) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Replace_Text;

   procedure Report_Invalid_Replace_Text
     (S : in out Editor.State.State_Type) is
   begin
      S.Active_Replace_Error_Message :=
        To_Unbounded_String ("Replacement text must be single-line");
      Editor.Executor.Shared_Services.Report_Warning
        (S, "Replacement text must be single-line");
      Editor.Render_Cache.Invalidate_All;
   end Report_Invalid_Replace_Text;

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Payloads.Command;
      Pos          : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String) is
   begin
      Cmd.Positions.Append (Pos);
      Cmd.Delete_Counts.Append (Delete_Count);
      Cmd.Insert_Texts.Append (Insert_Text);
   end Append_Replace_Op;

   function Image_Of (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image_Of;

   procedure Append_Find_Replacement_Op
     (Cmd   : in out Editor.Commands.Payloads.Command;
      Match : Editor.Search.Search_Match;
      Text  : Unbounded_String) is
   begin
      Append_Replace_Op
        (Cmd,
         Match.Start_Index,
         Natural (Match.End_Index - Match.Start_Index),
         Text);
   end Append_Find_Replacement_Op;

   function Find_Ordinal_For_Same_Range
     (S     : Editor.State.State_Type;
      Prior : Editor.Search.Search_Match) return Natural is
   begin
      if not Editor.Search.Has_Match (Prior)
        or else S.Active_Find_Matches.Is_Empty
      then
         return 0;
      end if;

      for M of S.Active_Find_Matches loop
         if M.Start_Index = Prior.Start_Index
           and then M.End_Index = Prior.End_Index
         then
            return Natural (M.Index);
         end if;
      end loop;

      return 0;
   end Find_Ordinal_For_Same_Range;

   function First_Find_Ordinal_At_Or_After_Index
     (S      : Editor.State.State_Type;
      Origin : Natural) return Natural is
   begin
      if S.Active_Find_Matches.Is_Empty then
         return 0;
      end if;

      for M of S.Active_Find_Matches loop
         if Natural (M.Start_Index) >= Origin then
            return Natural (M.Index);
         end if;
      end loop;

      return Natural
        (S.Active_Find_Matches (S.Active_Find_Matches.First_Index).Index);
   end First_Find_Ordinal_At_Or_After_Index;

   procedure Select_Active_Find_At_Or_After_Index
     (S      : in out Editor.State.State_Type;
      Origin : Natural) is
      Ordinal : constant Natural :=
        First_Find_Ordinal_At_Or_After_Index (S, Origin);
   begin
      S.Active_Find_Match :=
        Editor.Executor.Active_Find_Commands.Find_Match_By_Ordinal
          (S, Ordinal);
   end Select_Active_Find_At_Or_After_Index;

   procedure Remove_Active_Find_Matches_Overlapping
     (S           : in out Editor.State.State_Type;
      Start_Index : Natural;
      Length      : Natural) is
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
            Filtered.Append (Match);
         end if;
      end loop;

      S.Active_Find_Matches := Filtered;
      S.Active_Find_Match := Editor.Search.No_Match;
   end Remove_Active_Find_Matches_Overlapping;

   procedure Recompute_Find_After_Replace
     (S           : in out Editor.State.State_Type;
      Edit_Origin : Natural) is
   begin
      Editor.Executor.Active_Find_Commands.Recompute_Active_Find_Matches (S);
      Select_Active_Find_At_Or_After_Index (S, Edit_Origin);
   end Recompute_Find_After_Replace;

   procedure Execute_Replace_Current
     (S : in out Editor.State.State_Type) is
      Before : Editor.State.State_Type := S;
      Before_Text : constant String := Editor.State.Current_Text (S);
      Query : constant String := To_String (S.Active_Find_Query);
      Replacement : constant String := To_String (S.Active_Replace_Text);
      Prior_Selected : constant Editor.Search.Search_Match := S.Active_Find_Match;
      Count : Natural := 0;
      Ordinal : Natural := 0;
      Match : Editor.Search.Search_Match := Editor.Search.No_Match;
      Edit_Origin : Natural := 0;
      Cmd : Editor.Commands.Payloads.Command;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Before := S;

      if not Editor.Executor.Active_Find_Commands.Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Length (S.Active_Replace_Error_Message) > 0 then
         Report_Invalid_Replace_Text (S);
         return;
      elsif not Is_Valid_Replace_Text (Replacement) then
         Report_Invalid_Replace_Text (S);
         return;
      end if;

      if not S.Active_Find_Stale
        and then S.Active_Find_Matches.Is_Empty
        and then S.Active_Find_Source_Buffer_Token =
          Editor.Executor.Active_Feature_Buffer_Token (S)
      then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Editor.Executor.Active_Find_Commands.Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Ordinal := Find_Ordinal_For_Same_Range (S, Prior_Selected);
      if Ordinal = 0 or else Ordinal > Count then
         Ordinal :=
           Editor.Executor.Active_Find_Commands.First_Find_Ordinal_At_Or_After_Caret
             (S);
      end if;

      Match := Editor.Executor.Active_Find_Commands.Find_Match_By_Ordinal
        (S, Ordinal);
      if not Editor.Search.Has_Match (Match) then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
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
     (S : in out Editor.State.State_Type) is
      Before : Editor.State.State_Type := S;
      Before_Text : constant String := Editor.State.Current_Text (S);
      Query : constant String := To_String (S.Active_Find_Query);
      Replacement : constant String := To_String (S.Active_Replace_Text);
      Count : Natural := 0;
      Edit_Origin : Natural := 0;
      Cmd : Editor.Commands.Payloads.Command;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Before := S;

      if not Editor.Executor.Active_Find_Commands.Has_Find_Target_Buffer (S) then
         Report_Warning (S, "No active buffer.");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Query'Length = 0 then
         Report_Info (S, "No find query");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Length (S.Active_Replace_Error_Message) > 0 then
         Report_Invalid_Replace_Text (S);
         return;
      elsif not Is_Valid_Replace_Text (Replacement) then
         Report_Invalid_Replace_Text (S);
         return;
      end if;

      Editor.Executor.Active_Find_Commands.Recompute_Active_Find_Matches (S);
      Count := Natural (S.Active_Find_Matches.Length);
      if Count = 0 then
         Report_Info (S, "No matches");
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      Edit_Origin :=
        Natural (S.Active_Find_Matches (S.Active_Find_Matches.First_Index).Start_Index);
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
      if Count = 1 then
         Report_Success (S, "Replaced 1 match");
      else
         Report_Success (S, "Replaced " & Image_Of (Count) & " matches");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_All;

   procedure Set_Active_Find_Query_And_Report
     (S    : in out Editor.State.State_Type;
      Text : String) is
   begin
      Editor.Executor.Active_Find_Commands.Set_Active_Find_Query_And_Report
        (S, Text);
   end Set_Active_Find_Query_And_Report;

end Editor.Executor.Find_Replace_Commands;
