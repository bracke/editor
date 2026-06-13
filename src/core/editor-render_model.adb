with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Editor.Cursors; use Editor.Cursors;
with Editor.State;
with Editor.View;
with Editor.Layout;
with Editor.Wrap;
with Editor.Minimap;
with Editor.Diagnostics;
with Editor.Settings;
with Editor.Scrollbars;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Messages;
with Editor.Dirty_Lines;
with Editor.Rectangle_Selection;
with Editor.Selection;
with Editor.Project;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Feature_Panel;
with Editor.Input_Field;
with Editor.Go_To_Line;
with Editor.Feature_Search_Results;
with Editor.Outline;
with Editor.Buffers;
with Editor.Bookmarks;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Empty_State_Guidance;
with Editor.Guided_Prompts;
with Editor.Keybinding_Management;
with Editor.Settings_Management;
with Editor.Search;
with Editor.Syntax_Cache;
with Editor.Syntax_Semantics;
with Editor.Syntax_Overlays;
with Editor.Syntax;
use type Editor.Search.Search_Match_Index;
use type Editor.Wrap.Wrap_Mode;
use type Editor.Selection.Selection_Validation_Status;
use type Editor.Diagnostics.Diagnostic_Severity;
use type Editor.Syntax_Overlays.Overlay_Kind;
use type Editor.Syntax.Syntax_Kind;
with Editor.Ada_Language_Model;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

use type Editor.Buffers.Buffer_Id;

package body Editor.Render_Model is

   function Natural_Text (Value : Natural) return String
   is
      Image : constant String := Natural'Image (Value);
   begin
      return Image (Image'First + 1 .. Image'Last);
   end Natural_Text;

   function Dirty_Close_Summary_Message
     (Dirty_Count      : Natural;
      File_Backed_Count : Natural;
      Untitled_Count   : Natural) return String
   is
      Message : Unbounded_String := Null_Unbounded_String;
   begin
      Append
        (Message,
         Natural_Text (Dirty_Count)
         & (if Dirty_Count = 1 then
               " dirty buffer requires confirmation"
            else
               " dirty buffers require confirmation"));

      if File_Backed_Count > 0 or else Untitled_Count > 0 then
         Append (Message, " (");
         declare
            Categories : Unbounded_String := Null_Unbounded_String;

            procedure Add
              (Count : Natural;
               Label : String)
            is
            begin
               if Count > 0 then
                  if Length (Categories) > 0 then
                     Append (Categories, ", ");
                  end if;
                  Append (Categories, Natural_Text (Count) & " " & Label);
               end if;
            end Add;
         begin
            Add (File_Backed_Count, "file-backed");
            Add (Untitled_Count, "scratch");
            Append (Message, To_String (Categories));
         end;
         Append (Message, ")");
      end if;

      Append (Message, ".");
      return To_String (Message);
   end Dirty_Close_Summary_Message;

   use Line_Start_Vectors;

   function Active_Find_Buffer_Token
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if S.Active_Buffer_Token /= 0 then
         return S.Active_Buffer_Token;
      elsif Editor.Buffers.Global_Count > 1
        and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
      then
         return Natural (Editor.Buffers.Global_Active_Buffer);
      else
         return S.Registry_Token;
      end if;
   end Active_Find_Buffer_Token;

   function Active_Find_Source_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return S.Active_Find_Source_Buffer_Token /= 0
        and then S.Active_Find_Source_Buffer_Token = Active_Find_Buffer_Token (S);
   end Active_Find_Source_Current;

   function Dirty_Close_Open_Buffer_Fingerprint return Natural
   is
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Fingerprint : Natural := 0;
   begin
      for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
         declare
            Item : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Item.Id /= Editor.Buffers.No_Buffer then
               Fingerprint := Fingerprint + Natural (Item.Id) * Index;
            end if;
         end;
      end loop;
      return Fingerprint;
   end Dirty_Close_Open_Buffer_Fingerprint;

   function Dirty_Close_Dirty_Buffer_Fingerprint return Natural
   is
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Fingerprint : Natural := 0;
   begin
      for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
         declare
            Item : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Item.Id /= Editor.Buffers.No_Buffer and then Item.Is_Dirty then
               Fingerprint := Fingerprint + Natural (Item.Id) * Index;
            end if;
         end;
      end loop;
      return Fingerprint;
   end Dirty_Close_Dirty_Buffer_Fingerprint;

   function Dirty_Close_Buffer_Id_Token
     (Id : Editor.Buffers.Buffer_Id) return String
   is
   begin
      return "|"
        & Ada.Strings.Fixed.Trim
            (Natural'Image (Natural (Id)), Ada.Strings.Both)
        & "|";
   end Dirty_Close_Buffer_Id_Token;

   function Dirty_Close_Dirty_Buffer_Id_List return Ada.Strings.Unbounded.Unbounded_String
   is
      Result : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
   begin
      for Index in 1 .. Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Summary.Id /= Editor.Buffers.No_Buffer
              and then Summary.Is_Dirty
            then
               Ada.Strings.Unbounded.Append
                 (Result, Dirty_Close_Buffer_Id_Token (Summary.Id));
            end if;
         end;
      end loop;
      return Result;
   end Dirty_Close_Dirty_Buffer_Id_List;

   function Dirty_Close_Current_Open_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean
   is
      Review : constant String :=
        Ada.Strings.Unbounded.To_String
          (S.Dirty_Close_Prompt_Buffer_Ids);
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
   begin
      if Editor.Buffers.Global_Count /= S.Dirty_Close_Prompt_Buffer_Count then
         return False;
      end if;

      for Index in 1 .. Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Summary.Id /= Editor.Buffers.No_Buffer
              and then Ada.Strings.Fixed.Index
                (Review, Dirty_Close_Buffer_Id_Token (Summary.Id)) = 0
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Dirty_Close_Current_Open_Set_Was_Reviewed;

   function Dirty_Close_Current_Dirty_Set_Was_Reviewed
     (S : Editor.State.State_Type) return Boolean
   is
      Review : constant String :=
        Ada.Strings.Unbounded.To_String
          (S.Dirty_Close_Prompt_Dirty_Buffer_Ids);
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
      Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
   begin
      for Index in 1 .. Count loop
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Summary.Id /= Editor.Buffers.No_Buffer
              and then Summary.Is_Dirty
              and then Ada.Strings.Fixed.Index
                (Review, Dirty_Close_Buffer_Id_Token (Summary.Id)) = 0
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Dirty_Close_Current_Dirty_Set_Was_Reviewed;

   function Dirty_Close_Current_Dirty_Set_Equals_Review
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      --  Phase 575 completeness pass 33: render mirrors the Executor's exact
      --  dirty-set equality guard.  Fingerprints are useful stale-review
      --  summaries but exact transient dirty-id text decides whether Save/
      --  Discard may be shown for an unchanged review.
      return Dirty_Close_Dirty_Buffer_Id_List =
        S.Dirty_Close_Prompt_Dirty_Buffer_Ids;
   end Dirty_Close_Current_Dirty_Set_Equals_Review;

   function Dirty_Close_All_Buffer_Identity_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Dirty_Close_Current_Open_Set_Was_Reviewed (S)
        and then Dirty_Close_Open_Buffer_Fingerprint =
          S.Dirty_Close_Prompt_Buffer_Fingerprint;
   end Dirty_Close_All_Buffer_Identity_Current;

   function Dirty_Close_All_Buffer_Review_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Dirty_Close_All_Buffer_Identity_Current (S)
        and then Dirty_Close_Dirty_Buffer_Fingerprint =
          S.Dirty_Close_Prompt_Dirty_Fingerprint
        and then Dirty_Close_Current_Dirty_Set_Equals_Review (S);
   end Dirty_Close_All_Buffer_Review_Current;


   function Logical_Line_Length
     (S   : Editor.State.State_Type;
      Row : Natural) return Natural
   is
      Start : constant Natural := Natural (Editor.State.Line_Start (S, Row));
      Stop  : constant Natural := Natural (Editor.State.Line_End (S, Row));
   begin
      if Stop >= Start then
         return Stop - Start;
      else
         return 0;
      end if;
   end Logical_Line_Length;

   function Effective_Wrap_Col
     (S : Editor.State.State_Type) return Positive
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Minimap : constant Editor.Minimap.Minimap_Config :=
        Editor.Minimap.Current;
      Effective_Minimap_Enabled : constant Boolean :=
        Editor.Settings.Show_Minimap and then Minimap.Enabled;
      Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Effective_Viewport_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Scrollbars);
      Text_W : constant Natural :=
        (if Effective_Minimap_Enabled then
            Editor.Layout.Text_Viewport_Width
              (Layout,
               Natural'Max (1, Editor.State.Line_Count (S)),
               Effective_Viewport_W,
               Minimap.Enabled,
               Minimap.Width,
               Minimap.Padding_Left,
               Minimap.Padding_Right)
         else
            Editor.Layout.Text_Viewport_Width
              (Layout,
               Natural'Max (1, Editor.State.Line_Count (S)),
               Effective_Viewport_W));
   begin
      return Editor.Wrap.Wrap_Column (Text_W, Editor.Layout.Cell_W);
   end Effective_Wrap_Col;

   function Visual_Row_Ordinal_For_Caret
     (S        : Editor.State.State_Type;
      Row      : Natural;
      Col      : Natural;
      Wrap_Col : Positive) return Natural
   is
      Ordinal       : Natural := 0;
      Effective_Row : Natural := Row;
      Effective_Col : Natural := Col;
      Found         : Boolean := False;
   begin
      if Editor.Folding.Is_Row_Hidden (S.Folding, Effective_Row) then
         Effective_Row :=
           Editor.Folding.Fold_Start_For_Hidden_Row
             (S.Folding, Effective_Row, Found);
         Effective_Col := 0;
      end if;

      if Effective_Row > 0 then
         for R in 0 .. Effective_Row - 1 loop
            if not Editor.Folding.Is_Row_Hidden (S.Folding, R) then
               Ordinal := Ordinal +
                 Natural
                   (Editor.Wrap.Visual_Row_Count_For_Logical_Line
                      (Logical_Line_Length (S, R), Wrap_Col));
            end if;
         end loop;
      end if;

      return Ordinal + (Effective_Col / Natural (Wrap_Col));
   end Visual_Row_Ordinal_For_Caret;

   procedure Append_Line_Starts_For_Range
     (S         : Editor.State.State_Type;
      First_Row : Natural;
      Last_Row  : Natural;
      O         : in out Render_Snapshot)
   is
      Doc_Last  : constant Natural := Editor.State.Line_Count (S) - 1;
      FR        : constant Natural := Natural'Min (First_Row, Doc_Last);
      LR        : constant Natural := Natural'Min (Last_Row, Doc_Last);
      Copy_Last : constant Natural := (if LR < Doc_Last then LR + 1 else LR);
   begin
      O.Line_Start_Row_Base := FR;
      for Row in FR .. Copy_Last loop
         O.Line_Starts.Append (Natural (Editor.State.Line_Start (S, Row)));
      end loop;
   end Append_Line_Starts_For_Range;

   procedure Build_Unwrapped_Visuals
     (S : Editor.State.State_Type;
      O : in out Render_Snapshot)
   is
      Last_Row : constant Natural := Editor.State.Line_Count (S) - 1;
      FR       : constant Natural := Natural'Min (O.Visible_First_Row, Last_Row);
      LR       : constant Natural := Natural'Min (O.Visible_Last_Row, Last_Row);
      Count    : Natural := 0;
      Layout   : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Minimap  : constant Editor.Minimap.Minimap_Config :=
        Editor.Minimap.Current;
      Effective_Minimap_Enabled : constant Boolean :=
        Editor.Settings.Show_Minimap and then Minimap.Enabled;
      Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Base_Viewport_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Scrollbars);
      Effective_Viewport_W : constant Natural :=
        (if Effective_Minimap_Enabled
          and then Base_Viewport_W > Editor.Minimap.Reserved_Width (Minimap)
         then Base_Viewport_W - Editor.Minimap.Reserved_Width (Minimap)
         elsif Effective_Minimap_Enabled
         then 0
         else Base_Viewport_W);
      Last_Col : constant Natural :=
        Editor.Layout.Last_Visible_Text_Column
          (Layout,
           Natural'Max (1, Editor.State.Line_Count (S)),
           Effective_Viewport_W,
           Editor.View.Scroll_X);
   begin
      for Row in FR .. LR loop
         exit when Count >= Max_Visible_Visual_Rows;
         if not Editor.Folding.Is_Row_Hidden (S.Folding, Row) then
            declare
               Line_Len : constant Natural := Logical_Line_Length (S, Row);
               Start_Col : constant Natural := Natural'Min (Editor.View.Scroll_X, Line_Len);
               End_Col : constant Natural :=
                 (if Last_Col = Natural'Last
                  then Line_Len
                  else Natural'Min (Line_Len, Natural'Max (Start_Col, Last_Col + 1)));
            begin
               Count := Count + 1;
               O.Visible_Visual_Rows (Count) :=
                 (Logical_Row => Row,
                  Start_Col   => Start_Col,
                  End_Col     => End_Col);
            end;
         end if;
      end loop;
      O.Visible_Visual_Count := Count;
   end Build_Unwrapped_Visuals;

   procedure Build_Wrapped_Visuals
     (S : Editor.State.State_Type;
      O : in out Render_Snapshot)
   is
      Last_Row      : constant Natural := Editor.State.Line_Count (S) - 1;
      Scrollbars    : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Effective_Viewport_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Scrollbars);
      Visible_Cap   : constant Natural :=
        (if Effective_Viewport_H = 0 then Max_Visible_Visual_Rows
         else Natural'Min
           (Max_Visible_Visual_Rows,
            Natural'Max
              (1,
               Editor.Layout.Visible_Row_Count
                 (Editor.Layout.Current, Effective_Viewport_H))));
      Remaining     : Natural := Editor.View.Scroll_Y;
      First_Row     : Natural := Last_Row;
      First_Part    : Natural := 0;
      Found         : Boolean := False;
      Count         : Natural := 0;
      Logical_First : Natural := Last_Row;
      Logical_Last  : Natural := Last_Row;
   begin
      for Row in 0 .. Last_Row loop
         if not Editor.Folding.Is_Row_Hidden (S.Folding, Row) then
            declare
               Parts : constant Natural :=
                 Natural
                   (Editor.Wrap.Visual_Row_Count_For_Logical_Line
                      (Logical_Line_Length (S, Row), O.Wrap_Col));
            begin
               if Remaining < Parts then
                  First_Row := Row;
                  First_Part := Remaining;
                  Found := True;
                  exit;
               else
                  Remaining := Remaining - Parts;
               end if;
            end;
         end if;
      end loop;

      if not Found then
         First_Row := Last_Row;
         First_Part :=
           Natural
             (Editor.Wrap.Visual_Row_Count_For_Logical_Line
                (Logical_Line_Length (S, Last_Row), O.Wrap_Col)) - 1;
      end if;

      Logical_First := First_Row;
      Logical_Last := First_Row;

      for Row in First_Row .. Last_Row loop
         if not Editor.Folding.Is_Row_Hidden (S.Folding, Row) then
            declare
               Line_Len : constant Natural := Logical_Line_Length (S, Row);
               Parts    : constant Natural :=
                 Natural
                   (Editor.Wrap.Visual_Row_Count_For_Logical_Line
                      (Line_Len, O.Wrap_Col));
               Start_Part : constant Natural := (if Row = First_Row then First_Part else 0);
            begin
               for Part in Start_Part .. Parts - 1 loop
                  exit when Count >= Visible_Cap;
                  Count := Count + 1;
                  O.Visible_Visual_Rows (Count) :=
                    Editor.Wrap.Visual_Segment (Row, Part, Line_Len, O.Wrap_Col);
                  Logical_Last := Row;
               end loop;
               exit when Count >= Visible_Cap;
            end;
         end if;
      end loop;

      O.Visible_Visual_Count := Count;
      O.Visible_First_Row := Logical_First;
      O.Visible_Last_Row := Logical_Last;
   end Build_Wrapped_Visuals;


   function Total_Visible_Visual_Row_Count
     (S        : Editor.State.State_Type;
      Wrap_Col : Positive) return Natural
   is
      Count : Natural := 0;
   begin
      if Editor.State.Line_Count (S) = 0 then
         return 0;
      end if;

      for Row in 0 .. Editor.State.Line_Count (S) - 1 loop
         if not Editor.Folding.Is_Row_Hidden (S.Folding, Row) then
            Count := Count +
              Natural
                (Editor.Wrap.Visual_Row_Count_For_Logical_Line
                   (Logical_Line_Length (S, Row), Wrap_Col));
         end if;
      end loop;

      return Count;
   end Total_Visible_Visual_Row_Count;

   function Build_Snapshot
     (S : Editor.State.State_Type) return Editor_Snapshot
   is
      Copy : Editor.State.State_Type := S;
      O    : Editor_Snapshot;
   begin
      Build_Render_Snapshot (Copy, O);
      return O;
   end Build_Snapshot;

   procedure Build_Render_Snapshot
     (S : in out Editor.State.State_Type;
      O : out Render_Snapshot)
   is
   begin
      O.Length := 0;
      O.Text_Base_Index := 0;
      O.Caret_Count := 0;
      O.Caret_Pos := (others => 0);
      O.Line_Starts.Clear;
      O.Visible_First_Row := 0;
      O.Visible_Last_Row := Natural'Last;
      O.Selection_Count := 0;
      O.Selected_Character_Count := 0;
      O.Selected_Line_Count := 0;
      O.Sel_Start := (others => 0);
      O.Sel_End := (others => 0);
      O.Caret_Virtual_Column := (others => 0);
      O.Sel_Start_Virtual_Column := (others => 0);
      O.Sel_End_Virtual_Column := (others => 0);
      O.Line_Start_Row_Base := 0;
      O.Total_Line_Count := Editor.State.Line_Count (S);
      O.Folding := S.Folding;
      O.Gutter_Markers := S.Gutter_Markers;
      O.Gutter_Marker_Hover := S.Gutter_Marker_Hover;
      O.Messages := S.Messages;
      declare
         Snapshot : Editor.Bookmarks.Bookmark_Snapshot;
      begin
         Editor.Bookmarks.Build_Snapshot (S.Bookmarks, Snapshot);
         O.Bookmarks_Visible := Snapshot.Bookmarks_Visible;
         O.Bookmark_Count := Snapshot.Bookmark_Count;
         O.Bookmark_Selected_Index := Snapshot.Bookmark_Selected_Index;
         O.Bookmark_Selected_Key_File_Path := Snapshot.Bookmark_Selected_Key_File_Path;
         O.Bookmark_Selected_Key_Line_Number := Snapshot.Bookmark_Selected_Key_Line_Number;
         O.Bookmark_Selected_Key_Column := Snapshot.Bookmark_Selected_Key_Column;
         O.Bookmark_Selected_Key_Has_Column := Snapshot.Bookmark_Selected_Key_Has_Column;
         O.Bookmark_Has_Selected_Key := Snapshot.Bookmark_Has_Selected_Key;
         O.Bookmark_Rows := Snapshot.Bookmark_Rows;
         O.Bookmark_Empty_Message := Snapshot.Bookmark_Empty_Message;
         declare
            Registry : constant Editor.Buffers.Buffer_Registry :=
              Editor.Buffers.Global_Registry_For_UI;
            Summary  : Editor.Buffers.Buffer_Summary;
            Buffer   : Editor.State.State_Type;
            Row      : Editor.Bookmarks.Bookmark_Row;
         begin
            if O.Bookmark_Rows.Length > 0 then
               for I in O.Bookmark_Rows.First_Index .. O.Bookmark_Rows.Last_Index loop
                  Row := O.Bookmark_Rows (I);
                  for J in 1 .. Editor.Buffers.Count (Registry) loop
                     Summary := Editor.Buffers.Summary_At (Registry, J);
                     Buffer := Editor.Buffers.Buffer (Registry, Summary.Id);
                     if Buffer.File_Info.Has_Path
                       and then To_String (Buffer.File_Info.Path) = To_String (Row.File_Path)
                     then
                        Row.Is_Open := True;
                        Row.Is_Dirty := Buffer.File_Info.Dirty;
                        Row.Is_Active := Summary.Is_Active;
                     end if;
                  end loop;
                  O.Bookmark_Rows.Replace_Element (I, Row);
               end loop;
            end if;
         end;

         --  Phase 343: project session-local bookmarks onto the active
         --  editor buffer as lightweight line-level markers.  The marker is
         --  derived only from bookmark state and the active buffer's stable
         --  file identity; it does not validate paths, open files, move the
         --  caret, or mutate bookmark/open-buffer state.
         if S.File_Info.Has_Path and then O.Bookmark_Rows.Length > 0 then
            for I in O.Bookmark_Rows.First_Index .. O.Bookmark_Rows.Last_Index loop
               declare
                  Row : constant Editor.Bookmarks.Bookmark_Row :=
                    O.Bookmark_Rows (I);
               begin
                  if To_String (Row.File_Path) = To_String (S.File_Info.Path)
                    and then Row.Line_Number > 0
                    and then Row.Line_Number <= Editor.State.Line_Count (S)
                  then
                     Editor.Gutter_Markers.Add_Marker
                       (O.Gutter_Markers,
                        Row.Line_Number - 1,
                        Editor.Gutter_Markers.Bookmark_Marker);
                  end if;
               end;
            end loop;
         end if;
      end;
      O.Post_Restore_Feedback_Current := S.Post_Restore_Feedback_Current;

      if S.Diagnostics.Length > 0 then
         for D of S.Diagnostics loop
            declare
               Row : constant Natural :=
                 Editor.State.Row_For_Index (S, D.Start_Index);
            begin
               case D.Severity is
                  when Editor.Diagnostics.Error =>
                     Editor.Gutter_Markers.Add_Marker
                       (O.Gutter_Markers, Row,
                        Editor.Gutter_Markers.Diagnostic_Error_Marker);
                  when Editor.Diagnostics.Warning =>
                     Editor.Gutter_Markers.Add_Marker
                       (O.Gutter_Markers, Row,
                        Editor.Gutter_Markers.Diagnostic_Warning_Marker);
                  when others =>
                     null;
               end case;
            end;
         end loop;
      end if;
      O.Primary_Caret_Row := 0;
      O.Primary_Caret_Col := 0;
      O.Primary_Caret_Logical_Row := 0;
      O.Minimap_Sample_Count := 0;
      O.Minimap_Samples :=
        (others =>
           (Row         => 0,
            Start_Y     => 0.0,
            Height      => 1.0,
            Has_Text    => False,
            Text_Length => 0));
      O.Diagnostic_Count := 0;
      O.Diagnostics :=
        (others =>
           (Start_Index => 0,
            End_Index   => 0,
            Severity    => Editor.Diagnostics.Hint,
            Message     => Ada.Strings.Unbounded.Null_Unbounded_String,
            Has_Location => False,
            Start_Row    => 0,
            Start_Column => 0));
      O.Active_Find_Match_Count := 0;
      O.Active_Find_Matches := (others => Editor.Search.No_Match);
      O.Syntax_Span_Count := 0;
      O.Syntax_Spans := (others => (others => <>));
      declare
         Active_Find_Renderable : constant Boolean :=
           S.Active_Find_Prompt
           and then Length (S.Active_Find_Query) > 0
           and then not S.Active_Find_Stale
           and then Active_Find_Source_Current (S);
      begin
         O.Active_Find_Match :=
           (if Active_Find_Renderable then S.Active_Find_Match
            else Editor.Search.No_Match);
      end;
      if S.File_Info.Has_Path then
         O.File_Name := S.File_Info.Display_Name;
      elsif Length (S.File_Info.Display_Name) > 0 then
         O.File_Name := S.File_Info.Display_Name;
      else
         O.File_Name := To_Unbounded_String ("Untitled");
      end if;
      declare
         Id : constant Editor.Buffers.Buffer_Id := Editor.Buffers.Global_Active_Buffer;
      begin
         if Id /= Editor.Buffers.No_Buffer
           and then Editor.Buffers.Global_Has_Buffer_Label (Id)
         then
            Append (O.File_Name, " [label: " & Editor.Buffers.Global_Buffer_Label (Id) & "]");
         end if;
         if Id /= Editor.Buffers.No_Buffer
           and then Editor.Buffers.Global_Has_Buffer_Note (Id)
         then
            Append (O.File_Name, " — " & Editor.Buffers.Global_Buffer_Note (Id));
         end if;
      end;
      O.Is_Dirty := S.File_Info.Dirty;
      declare
         Active_Find_Renderable : constant Boolean :=
           S.Active_Find_Prompt
           and then Length (S.Active_Find_Query) > 0
           and then not S.Active_Find_Stale
           and then Active_Find_Source_Current (S);
      begin
         O.Total_Find_Match_Count :=
           (if Active_Find_Renderable
            then Natural (S.Active_Find_Matches.Length)
            else 0);
      end;
      O.Total_Diagnostic_Count := Natural (S.Diagnostics.Length);
      O.Has_Project := Editor.Project.Has_Project (S.Project);
      if O.Has_Project then
         O.Project_Label := To_Unbounded_String (Editor.Project.Display_Name (S.Project));
      else
         O.Project_Label := Null_Unbounded_String;
      end if;
      declare
         Active_Id : constant Editor.Buffers.Buffer_Id :=
           Editor.Buffers.Global_Active_Buffer;
      begin
         if Active_Id /= Editor.Buffers.No_Buffer
           and then Editor.Buffers.Global_Contains (Active_Id)
         then
            declare
               Metadata : constant Editor.Buffers.Buffer_Metadata_Snapshot :=
                 Editor.Buffers.Global_Metadata_For (S.Project, Active_Id);
            begin
               O.Active_Buffer_Has_Metadata := True;
               O.Active_Buffer_Ownership_Label := Metadata.Ownership_Label;
               O.Active_Buffer_Lifecycle_Label := Metadata.Lifecycle_Status_Label;
               O.Active_Buffer_Workspace_Persistability_Label :=
                 To_Unbounded_String
                   (Editor.Buffers.Workspace_Persistability_Label
                      (Metadata.Workspace_Persistability));
               O.Active_Buffer_Stale_Backing_State :=
                 Metadata.Stale_Backing_State;
               O.Active_Buffer_Close_Eligibility_Label :=
                 To_Unbounded_String
                   (Editor.Buffers.Close_Eligibility_Label
                      (Metadata.Close_Eligibility));
            end;
         else
            O.Active_Buffer_Has_Metadata := False;
            O.Active_Buffer_Ownership_Label := Null_Unbounded_String;
            O.Active_Buffer_Lifecycle_Label := Null_Unbounded_String;
            O.Active_Buffer_Workspace_Persistability_Label := Null_Unbounded_String;
            O.Active_Buffer_Stale_Backing_State := False;
            O.Active_Buffer_Close_Eligibility_Label := Null_Unbounded_String;
         end if;
      end;
      O.Panel_Focus_Target := Editor.Panel_Focus.Target (S.Panel_Focus);
      O.Bottom_Focus_Content := Editor.Panel_Focus.Bottom_Content (S.Panel_Focus);
      O.Active_Overlay := Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      O.Goto_Line_Visible := Editor.Go_To_Line.Is_Open (S.Go_To_Line);
      O.Goto_Line_Query := To_Unbounded_String (Editor.Go_To_Line.Text (S.Go_To_Line));
      O.Goto_Line_Error_Message :=
        To_Unbounded_String (Editor.Go_To_Line.Error_Text (S.Go_To_Line));
      O.Goto_Line_Field := Editor.Go_To_Line.Snapshot (S.Go_To_Line, 30);
      declare
         Active_Find_Renderable : constant Boolean :=
           S.Active_Find_Prompt
           and then Length (S.Active_Find_Query) > 0
           and then not S.Active_Find_Stale
           and then Active_Find_Source_Current (S);
      begin
         O.Find_Visible := S.Active_Find_Prompt;
         O.Find_Query :=
           (if S.Active_Find_Prompt
            then S.Active_Find_Query
            else Null_Unbounded_String);
         O.Find_Case_Sensitive := S.Active_Find_Case_Sensitive;
         O.Find_Whole_Word := S.Active_Find_Whole_Word;
         O.Find_Matches_Stale := S.Active_Find_Stale;
         O.Find_Wrapped := Active_Find_Renderable and then S.Active_Find_Wrapped;
         O.Find_Matches_For_Active_Buffer := Active_Find_Source_Current (S);
         O.Find_Match_Count :=
           (if Active_Find_Renderable
            then Natural (S.Active_Find_Matches.Length)
            else 0);
         O.Find_Selected_Match_Index :=
           (if Active_Find_Renderable then
               (if S.Active_Find_Match.Index = Editor.Search.No_Search_Match
                then 0
                else Natural (S.Active_Find_Match.Index))
            else 0);
         O.Find_Selected_Match_Ordinal := O.Find_Selected_Match_Index;
         if not O.Find_Visible then
            O.Find_Status_Text := Null_Unbounded_String;
         elsif Length (O.Find_Query) = 0 then
            O.Find_Status_Text := To_Unbounded_String ("No query");
         elsif O.Find_Matches_Stale or else not O.Find_Matches_For_Active_Buffer then
            O.Find_Status_Text := To_Unbounded_String ("Stale");
         elsif O.Find_Match_Count = 0 then
            O.Find_Status_Text := To_Unbounded_String ("No matches");
         elsif O.Find_Selected_Match_Ordinal > 0 then
            O.Find_Status_Text := To_Unbounded_String
              (Ada.Strings.Fixed.Trim
                 (Natural'Image (O.Find_Selected_Match_Ordinal), Ada.Strings.Both)
               & "/"
               & Ada.Strings.Fixed.Trim
                 (Natural'Image (O.Find_Match_Count), Ada.Strings.Both));
         else
            O.Find_Status_Text := To_Unbounded_String
              (Ada.Strings.Fixed.Trim
                 (Natural'Image (O.Find_Match_Count), Ada.Strings.Both)
               & (if O.Find_Match_Count = 1 then " match" else " matches"));
         end if;
         O.Find_Error_Message :=
           (if Active_Find_Renderable
               and then Length (S.Active_Find_Query) > 0
               and then Natural (S.Active_Find_Matches.Length) = 0
            then To_Unbounded_String ("No matches")
            else Null_Unbounded_String);
      end;
      declare
         Canonical_Active_Find_Field : Editor.Input_Field.Input_Field_State := S.Active_Find_Input;
      begin
         if S.Active_Find_Prompt then
            Editor.Input_Field.Set_Text
              (Canonical_Active_Find_Field, To_String (S.Active_Find_Query));
         end if;
         O.Active_Find_Field := Editor.Input_Field.Snapshot (Canonical_Active_Find_Field, 30);
      end;
      O.Replace_Visible := S.Active_Replace_Prompt and then S.Active_Find_Prompt;
      O.Replace_Text :=
        (if O.Replace_Visible then S.Active_Replace_Text else Null_Unbounded_String);
      O.Replace_Error_Message :=
        (if O.Replace_Visible then S.Active_Replace_Error_Message else Null_Unbounded_String);
      O.File_Target_Prompt_Visible := S.File_Target_Prompt_Active;
      O.File_Target_Prompt_Label :=
        (if S.File_Target_Prompt_Active then S.File_Target_Prompt_Label else Null_Unbounded_String);
      O.File_Target_Prompt_Field :=
        Editor.Input_Field.Snapshot (S.File_Target_Prompt_Input, 48);
      O.Dirty_Close_Prompt_Visible := S.Dirty_Close_Prompt_Active;
      O.Dirty_Close_Scope := S.Dirty_Close_Prompt_Scope;
      O.Dirty_Close_All_Buffers := S.Dirty_Close_Prompt_All_Buffers;
      O.Dirty_Close_Target_Buffer := S.Dirty_Close_Prompt_Buffer;
      O.Dirty_Close_Buffer_Count := S.Dirty_Close_Prompt_Buffer_Count;
      O.Dirty_Close_Buffer_Fingerprint :=
        S.Dirty_Close_Prompt_Buffer_Fingerprint;
      O.Dirty_Close_Dirty_Fingerprint :=
        S.Dirty_Close_Prompt_Dirty_Fingerprint;
      O.Dirty_Close_Buffer_Ids := S.Dirty_Close_Prompt_Buffer_Ids;
      O.Dirty_Close_Dirty_Buffer_Ids :=
        S.Dirty_Close_Prompt_Dirty_Buffer_Ids;
      O.Dirty_Close_Dirty_Count := S.Dirty_Close_Prompt_Dirty_Count;
      O.Dirty_Close_File_Backed_Count := S.Dirty_Close_Prompt_File_Backed_Count;
      O.Dirty_Close_Untitled_Count := S.Dirty_Close_Prompt_Untitled_Count;
      O.Dirty_Close_Conflicted_Count := S.Dirty_Close_Prompt_Conflicted_Count;
      O.Dirty_Close_Unwritable_Count := S.Dirty_Close_Prompt_Unwritable_Count;
      O.Dirty_Close_Missing_Count := S.Dirty_Close_Prompt_Missing_Count;
      O.Dirty_Close_Save_Failure_Count := S.Dirty_Close_Prompt_Save_Failure_Count;
      O.Dirty_Close_Discard_Action_Available := False;
      O.Dirty_Close_Cancel_Action_Available := S.Dirty_Close_Prompt_Active;
      O.Dirty_Close_Save_Action_Available := False;
      if S.Dirty_Close_Prompt_Active then
         if S.Dirty_Close_Prompt_All_Buffers then
            if Editor.Buffers.Global_Count = 0 then
               O.Dirty_Close_Discard_Action_Available := False;
            elsif Dirty_Close_All_Buffer_Review_Current (S) then
               O.Dirty_Close_Discard_Action_Available := True;
            else
               --  Phase 575 completeness pass 22: render mirrors Executor
               --  discard revalidation.  An unchanged all-buffer review
               --  whose dirty buffers all became clean can still be
               --  confirmed as close-only; changed or newly dirty state
               --  hides the destructive action and leaves Cancel visible.
               O.Dirty_Close_Discard_Action_Available :=
                 Dirty_Close_All_Buffer_Identity_Current (S)
                 and then Dirty_Close_Current_Dirty_Set_Was_Reviewed (S);
            end if;
         else
            declare
               Target : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Buffer_Id (S.Dirty_Close_Prompt_Buffer);
            begin
               O.Dirty_Close_Discard_Action_Available :=
                 Target /= Editor.Buffers.No_Buffer
                 and then Editor.Buffers.Global_Contains (Target);
            end;
         end if;

         if S.Dirty_Close_Prompt_All_Buffers then
            declare
               Registry : constant Editor.Buffers.Buffer_Registry :=
                 Editor.Buffers.Global_Registry_For_UI;
               Dirty_Count : Natural := 0;
               File_Backed_Count : Natural := 0;
            begin
               for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
                  declare
                     Summary : constant Editor.Buffers.Buffer_Summary :=
                       Editor.Buffers.Summary_At (Registry, Index);
                  begin
                     if Summary.Is_Dirty then
                        Dirty_Count := Dirty_Count + 1;
                        if Summary.Has_Path then
                           File_Backed_Count := File_Backed_Count + 1;
                        end if;
                     end if;
                  end;
               end loop;
               O.Dirty_Close_Save_Action_Available :=
                 (if Dirty_Count = 0 then
                    Dirty_Close_All_Buffer_Identity_Current (S)
                  else
                    Dirty_Close_All_Buffer_Identity_Current (S)
                    and then Dirty_Close_Current_Dirty_Set_Was_Reviewed (S)
                    and then File_Backed_Count > 0);
            end;
         else
            declare
               Target : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Buffer_Id (S.Dirty_Close_Prompt_Buffer);
            begin
               if Target /= Editor.Buffers.No_Buffer
                 and then Editor.Buffers.Global_Contains (Target)
               then
                  declare
                     Summary : constant Editor.Buffers.Buffer_Summary :=
                       Editor.Buffers.Global_Summary_For (Target);
                  begin
                     --  Phase 575 completeness pass 26: mirror Executor
                     --  live revalidation for single-buffer prompts.  Do not
                     --  expose Save from stale prompt counts when a target
                     --  loses its path, and do expose it when the target gained
                     --  a valid file-backed save path before confirmation.
                     O.Dirty_Close_Save_Action_Available :=
                       (not Summary.Is_Dirty) or else Summary.Has_Path;
                  end;
               else
                  O.Dirty_Close_Save_Action_Available := False;
               end if;
            end;
         end if;
      end if;
      if S.Dirty_Close_Prompt_Active then
         O.Dirty_Close_Message := To_Unbounded_String
           ((if S.Dirty_Close_Prompt_Save_Failure_Count > 0 then
                "Save failed; buffer remains open"
             elsif S.Dirty_Close_Prompt_Conflicted_Count > 0 then
                "File conflict requires resolution before save-and-close"
             elsif S.Dirty_Close_Prompt_Unwritable_Count > 0 then
                "Unwritable file blocks save-and-close"
             elsif S.Dirty_Close_Prompt_Missing_Count > 0 then
                "Missing backing file blocks save-and-close"
             elsif S.Dirty_Close_Prompt_All_Buffers then
                --  Phase 575 completeness pass 32: render should expose the
                --  same reviewed dirty-set summary as the Executor outcome
                --  message.  This is still an inert snapshot projection; it
                --  does not carry a close payload or mutate/persist anything.
                Dirty_Close_Summary_Message
                  (S.Dirty_Close_Prompt_Dirty_Count,
                   S.Dirty_Close_Prompt_File_Backed_Count,
                   S.Dirty_Close_Prompt_Untitled_Count)
             elsif S.Dirty_Close_Prompt_Untitled_Count > 0 then
                "Discard unsaved scratch buffer?"
             else
                "Unsaved changes require save, discard, or cancel"));
      else
         O.Dirty_Close_Message := Null_Unbounded_String;
      end if;
      declare
         Summary : constant Editor.Feature_Panel.Feature_Panel_Summary :=
           Editor.Feature_Panel.Summary (S.Feature_Panel);
      begin
         O.Feature_Panel_Visible := Summary.Visible;
         O.Feature_Panel_Focused := Summary.Focused;
         O.Search_Query_Input_Active :=
           Editor.Feature_Search_Results.Search_Input_Is_Active
             (S.Feature_Search_Results);
         O.Outline_Filter_Input_Active :=
           Editor.Outline.Filter_Input_Is_Active (S.Outline);
         O.Active_Feature := Editor.Feature_Panel.Active_Feature (S.Feature_Panel);
      end;
      O.Wrap_Mode := Editor.View.Wrap_Mode;
      O.Wrap_Col := Effective_Wrap_Col (S);
      if O.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         O.Visible_Line_Count :=
           Natural'Max (1, Total_Visible_Visual_Row_Count (S, O.Wrap_Col));
      else
         O.Visible_Line_Count :=
           Natural'Max
             (1, Editor.Folding.Visible_Row_Count (S.Folding, O.Total_Line_Count));
      end if;
      O.Visible_Visual_Count := 0;
      O.Visible_Visual_Rows := (others => (Logical_Row => 0, Start_Col => 0, End_Col => 0));

      declare
         Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
           Editor.Scrollbars.Current;
         Effective_Viewport_H : constant Natural :=
           Editor.Scrollbars.Effective_Viewport_Height
             (Editor.View.Viewport_Height, Scrollbars);
      begin
         if Editor.Layout.Text_Viewport_Height
              (Editor.Layout.Current, Effective_Viewport_H) = 0 then
            O.Visible_First_Row := 0;
            O.Visible_Last_Row := Editor.State.Line_Count (S) - 1;
         elsif O.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
            --  Wrapped scrolling is visual-row based.  Build_Wrapped_Visuals
            --  resolves Scroll_Y to concrete document rows after this block,
            --  so avoid interpreting a visual-row ordinal as a logical
            --  visible-line ordinal here.
            O.Visible_First_Row := 0;
            O.Visible_Last_Row := Editor.State.Line_Count (S) - 1;
         else
            declare
               Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
            begin
               declare
                  First_Visible : constant Natural :=
                    Natural'Min (Editor.View.Scroll_Y, O.Visible_Line_Count - 1);
                  Last_Visible  : constant Natural :=
                    Natural'Min
                      (Editor.Layout.Last_Visible_Row
                         (Editor.View.Scroll_Y, Layout, Effective_Viewport_H),
                       O.Visible_Line_Count - 1);
               begin
                  O.Visible_First_Row :=
                    Editor.Folding.Visible_Row_To_Document_Row
                      (S.Folding, First_Visible);
                  O.Visible_Last_Row :=
                    Editor.Folding.Visible_Row_To_Document_Row
                      (S.Folding, Last_Visible);
               end;
            end;
         end if;
      end;

      if S.Carets.Length > 0 then
         O.Primary_Caret_Row :=
           Editor.State.Row_For_Index (S, S.Carets (S.Carets.First_Index).Pos);
         O.Primary_Caret_Logical_Row := O.Primary_Caret_Row;
         O.Primary_Caret_Col :=
           Natural (S.Carets (S.Carets.First_Index).Pos)
           - Natural (Editor.State.Line_Start (S, O.Primary_Caret_Row));

         if S.Carets (S.Carets.First_Index).Virtual_Column > 0 then
            O.Primary_Caret_Col := S.Carets (S.Carets.First_Index).Virtual_Column;
         end if;

         declare
            Caret_Doc_Row : Natural := O.Primary_Caret_Logical_Row;
            Fold_Found    : Boolean := False;
            Visible_Found : Boolean := False;
         begin
            if Editor.Folding.Is_Row_Hidden (S.Folding, Caret_Doc_Row) then
               Caret_Doc_Row :=
                 Editor.Folding.Fold_Start_For_Hidden_Row
                   (S.Folding, Caret_Doc_Row, Fold_Found);
               O.Primary_Caret_Col := 0;
            end if;

            O.Primary_Caret_Row :=
              Editor.Folding.Document_Row_To_Visible_Row
                (S.Folding, Caret_Doc_Row, Visible_Found);
            if not Visible_Found then
               O.Primary_Caret_Row := 0;
            end if;

            if O.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
               O.Primary_Caret_Row :=
                 Visual_Row_Ordinal_For_Caret
                   (S, Caret_Doc_Row, O.Primary_Caret_Col, O.Wrap_Col);
               O.Primary_Caret_Col := O.Primary_Caret_Col mod Natural (O.Wrap_Col);
            end if;
         end;
      end if;

      if O.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         Build_Wrapped_Visuals (S, O);
      else
         Build_Unwrapped_Visuals (S, O);
      end if;

      --  Phase 64: dirty-line markers are derived from the active buffer's
      --  line-level baseline state at snapshot-build time and projected as
      --  diff-style marker kinds.  Gutter_Markers remains independent of
      --  Dirty_Lines ownership; hidden folded rows are naturally skipped
      --  because only visible visual rows are scanned.
      if Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) > 0 then
         for I in 1 .. O.Visible_Visual_Count loop
            declare
               Row  : constant Natural := O.Visible_Visual_Rows (I).Logical_Row;
               Kind : constant Editor.Dirty_Lines.Dirty_Line_Kind :=
                 Editor.Dirty_Lines.Kind_For_Row (S.Dirty_Lines, Row);
            begin
               case Kind is
                  when Editor.Dirty_Lines.Added_Line =>
                     Editor.Gutter_Markers.Add_Marker
                       (O.Gutter_Markers, Row,
                        Editor.Gutter_Markers.Added_Line_Marker);
                  when Editor.Dirty_Lines.Modified_Line =>
                     Editor.Gutter_Markers.Add_Marker
                       (O.Gutter_Markers, Row,
                        Editor.Gutter_Markers.Modified_Line_Marker);
                  when Editor.Dirty_Lines.Clean_Line =>
                     null;
               end case;
            end;
         end loop;
      end if;

      declare
         Last_Row : constant Natural := Editor.State.Line_Count (S) - 1;
         FR       : constant Natural := Natural'Min (O.Visible_First_Row, Last_Row);
         LR       : constant Natural := Natural'Min (O.Visible_Last_Row, Last_Row);
      begin
         Append_Line_Starts_For_Range (S, FR, LR, O);
      end;

      declare
         Start_Pos : Natural := Natural'Last;
         End_Pos   : Natural := 0;
         Doc_Len   : constant Natural := Text_Buffer.Length (S.Buffer);
      begin
         if O.Visible_Visual_Count = 0 then
            Start_Pos := 0;
            End_Pos := 0;
         else
            for I in 1 .. O.Visible_Visual_Count loop
               declare
                  Seg       : constant Editor.Wrap.Visual_Row_Info := O.Visible_Visual_Rows (I);
                  Row_Start : constant Natural := Natural (Editor.State.Line_Start (S, Seg.Logical_Row));
                  Abs_Start : constant Natural := Row_Start + Seg.Start_Col;
                  Abs_End   : constant Natural := Row_Start + Seg.End_Col;
               begin
                  Start_Pos := Natural'Min (Start_Pos, Abs_Start);
                  End_Pos := Natural'Max (End_Pos, Abs_End);
               end;
            end loop;
         end if;

         if Start_Pos = Natural'Last then
            Start_Pos := 0;
         end if;

         End_Pos := Natural'Min (End_Pos, Doc_Len);
         O.Text_Base_Index := Start_Pos;
         if End_Pos >= Start_Pos then
            O.Length := End_Pos - Start_Pos;
         else
            O.Length := 0;
         end if;

         pragma Assert (O.Text_Base_Index + O.Length <= Text_Buffer.Length (S.Buffer));
      end;

      if S.Carets.Length > 0 then
         declare
            Count : Natural := 0;
         begin
            for I in S.Carets.First_Index .. S.Carets.Last_Index loop
               exit when Count >= Max_Render_Carets;
               Count := Count + 1;
               O.Caret_Pos (Count) := S.Carets (I).Pos;
               O.Caret_Virtual_Column (Count) := S.Carets (I).Virtual_Column;
            end loop;
            O.Caret_Count := Count;
         end;
      end if;

      declare
         Visible_Start : constant Natural := O.Text_Base_Index;
         Visible_End   : constant Natural := O.Text_Base_Index + O.Length;
         Count         : Natural := 0;
      begin
         if Visible_End > Visible_Start and then S.Diagnostics.Length > 0 then
            for D of S.Diagnostics loop
               exit when Count >= Max_Render_Diagnostics;
               declare
                  Start_Pos : Natural := Natural (D.Start_Index);
                  End_Pos   : Natural := Natural (D.End_Index);
               begin
                  --  Line-only diagnostics are projected onto a deterministic
                  --  single visible cell at the reported row/column.  Invalid
                  --  rows are ignored rather than widened to the whole view.
                  if End_Pos <= Start_Pos and then D.Has_Location then
                     if D.Start_Row < Editor.State.Line_Count (S) then
                        declare
                           Line_Start : constant Natural :=
                             Natural (Editor.State.Line_Start (S, D.Start_Row));
                           Line_End : constant Natural :=
                             (if D.Start_Row + 1 < Editor.State.Line_Count (S)
                              then Natural (Editor.State.Line_Start (S, D.Start_Row + 1)) - 1
                              else Text_Buffer.Length (S.Buffer));
                        begin
                           Start_Pos := Natural'Min (Line_Start + D.Start_Column, Line_End);
                           End_Pos := Natural'Min (Start_Pos + 1, Line_End);
                           if End_Pos <= Start_Pos and then Start_Pos < Text_Buffer.Length (S.Buffer) then
                              End_Pos := Start_Pos + 1;
                           end if;
                        end;
                     end if;
                  end if;

                  if End_Pos > Visible_Start
                    and then Start_Pos < Visible_End
                    and then End_Pos > Start_Pos
                  then
                     Count := Count + 1;
                     O.Diagnostics (Count) :=
                       (Start_Index => Editor.Cursors.Cursor_Index
                                         (Natural'Max (Start_Pos, Visible_Start)),
                        End_Index   => Editor.Cursors.Cursor_Index
                                         (Natural'Min (End_Pos, Visible_End)),
                        Severity    => D.Severity,
                        Message     => D.Message,
                        Has_Location => D.Has_Location,
                        Start_Row    => D.Start_Row,
                        Start_Column => D.Start_Column);
                  end if;
               end;
            end loop;
         end if;
         O.Diagnostic_Count := Count;
      end;


      declare
         Visible_Start : constant Natural := O.Text_Base_Index;
         Visible_End   : constant Natural := O.Text_Base_Index + O.Length;
         Count         : Natural := 0;
      begin
         if Visible_End > Visible_Start
           and then S.Active_Find_Prompt
         then
            if S.Active_Find_Prompt
              and then Length (S.Active_Find_Query) > 0
              and then not S.Active_Find_Stale
              and then Active_Find_Source_Current (S)
            then
               for Match of S.Active_Find_Matches loop
                  exit when Count >= Max_Render_Active_Find_Matches;
                  if Natural (Match.End_Index) > Visible_Start
                    and then Natural (Match.Start_Index) < Visible_End
                  then
                     Count := Count + 1;
                     O.Active_Find_Matches (Count) :=
                       (Index        => Match.Index,
                        Start_Index  => Editor.Cursors.Cursor_Index
                                         (Natural'Max
                                            (Natural (Match.Start_Index),
                                             Visible_Start)),
                        End_Index    => Editor.Cursors.Cursor_Index
                                         (Natural'Min
                                            (Natural (Match.End_Index),
                                             Visible_End)),
                        Start_Row    => Match.Start_Row,
                        Start_Column => Match.Start_Column,
                        End_Row      => Match.End_Row,
                        End_Column   => Match.End_Column);
                  end if;
               end loop;
            end if;
         end if;
         O.Active_Find_Match_Count := Count;
      end;

      --  Phase 380 canonical selection projection: render the same valid
      --  normalized active-buffer selection range that Clipboard and Find
      --  consume.  Rendering must not expose stale/out-of-range ranges or
      --  secondary inactive caret ranges, and it must not repair state.
      declare
         Selection_Range  : Editor.Selection.Active_Selection_Range;
         Status : constant Editor.Selection.Selection_Validation_Status :=
           Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      begin
         O.Selection_Count := 0;
         O.Selected_Character_Count := 0;
         O.Selected_Line_Count := 0;
         if Status = Editor.Selection.Selection_Ok then
            O.Selection_Count := 1;
            O.Selected_Character_Count :=
              Editor.Selection.Selected_Character_Count (S);
            O.Selected_Line_Count :=
              Editor.Selection.Selected_Line_Count (S);
            O.Sel_Start (1) := Selection_Range.Low;
            O.Sel_End (1) := Selection_Range.High;
            O.Sel_Start_Virtual_Column (1) := 0;
            O.Sel_End_Virtual_Column (1) := 0;
         end if;
      end;

      --  Phase 68 rectangular-selection projection. The rectangular-selection
      --  model represents the active rectangle as one grid span per
      --  selected document row; expose that explicitly so packet generation
      --  no longer has to infer rectangular geometry from linear ranges.
      O.Rectangular_Selection_Count := 0;
      if S.Rect_Select_Active and then S.Carets.Length > 0 then
         declare
            Count : Natural := 0;
            Row   : Natural := 0;
            Col   : Natural := 0;
         begin
            for C of S.Carets loop
               exit when Count >= Max_Render_Selections;
               if Editor.Rectangle_Selection.Has_Selection (C) then
                  Editor.State.Row_Col_For_Index (S, C.Pos, Row, Col);
                  if Row >= O.Visible_First_Row and then Row <= O.Visible_Last_Row
                    and then not Editor.Folding.Is_Row_Hidden (S.Folding, Row)
                  then
                     Count := Count + 1;
                     O.Rectangular_Selections (Count) :=
                       (Row          => Row,
                        Start_Column =>
                          Editor.Rectangle_Selection.Selection_Left_Column (S, C),
                        End_Column   =>
                          Editor.Rectangle_Selection.Selection_Right_Column (S, C));
                  end if;
               end if;
            end loop;
            O.Rectangular_Selection_Count := Count;
         end;
      end if;

      --  Syntax colouring is prepared before packet construction and stored as
      --  immutable render spans.  The packet builder must only consume these
      --  spans; it must not invoke the lexer or mutate editor/buffer state.
      declare
         Count : Natural := 0;

         function Line_Text (Row : Natural) return String is
            Text : constant String := Editor.State.Current_Text (S);
            Current_Row : Natural := 0;
            Start : Natural := Text'First;
            Stop : Natural := Text'First - 1;
         begin
            if Text'Length = 0 then
               return "";
            end if;

            for I in Text'Range loop
               if Current_Row = Row then
                  Start := I;
                  Stop := I;
                  while Stop <= Text'Last
                    and then Text (Stop) /= ASCII.LF
                    and then Text (Stop) /= ASCII.CR
                  loop
                     Stop := Stop + 1;
                  end loop;
                  if Stop <= Start then
                     return "";
                  else
                     return Text (Start .. Stop - 1);
                  end if;
               end if;

               if Text (I) = ASCII.LF then
                  Current_Row := Current_Row + 1;
               end if;
            end loop;

            return "";
         end Line_Text;

         function Intersects (A_Start, A_End, B_Start, B_End : Natural) return Boolean is
         begin
            return A_End > B_Start and then A_Start < B_End;
         end Intersects;

         function Overlay_For (Start_Index, End_Index : Natural)
           return Editor.Syntax_Overlays.Overlay_Kind
         is
            Result : Editor.Syntax_Overlays.Overlay_Kind := Editor.Syntax_Overlays.No_Overlay;
         begin
            if Editor.Settings.Use_Diagnostic_Overlays then
               for I in 1 .. O.Diagnostic_Count loop
                  if Intersects
                      (Start_Index, End_Index,
                       Natural (O.Diagnostics (I).Start_Index),
                       Natural (O.Diagnostics (I).End_Index))
                  then
                     if O.Diagnostics (I).Severity = Editor.Diagnostics.Error then
                        Result := Editor.Syntax_Overlays.Diagnostic_Error_Overlay;
                     elsif O.Diagnostics (I).Severity = Editor.Diagnostics.Warning
                       and then Result /= Editor.Syntax_Overlays.Diagnostic_Error_Overlay
                     then
                        Result := Editor.Syntax_Overlays.Diagnostic_Warning_Overlay;
                     end if;
                  end if;
               end loop;
            end if;

            if Editor.Settings.Use_Search_Overlays then
               for I in 1 .. O.Active_Find_Match_Count loop
                  if Intersects
                    (Start_Index, End_Index,
                     Natural (O.Active_Find_Matches (I).Start_Index),
                     Natural (O.Active_Find_Matches (I).End_Index))
                  then
                     Result := Editor.Syntax_Overlays.Search_Match_Overlay;
                  end if;
               end loop;
            end if;

            for I in 1 .. O.Selection_Count loop
               if Intersects
                 (Start_Index, End_Index,
                  Natural (O.Sel_Start (I)), Natural (O.Sel_End (I)))
               then
                  return Editor.Syntax_Overlays.Selection_Overlay;
               end if;
            end loop;

            return Result;
         end Overlay_For;

         procedure Append_Span
           (Row         : Natural;
            Start_Index : Natural;
            End_Index   : Natural;
            Kind        : Editor.Syntax.Token_Kind)
         is
         begin
            if Count < Max_Render_Syntax_Spans and then End_Index > Start_Index then
               Count := Count + 1;
               O.Syntax_Spans (Count) :=
                 (Row         => Row,
                  Start_Index => Start_Index,
                  End_Index   => End_Index,
                  Kind        => Kind);
            end if;
         end Append_Span;

         procedure Append_Overlay_Only_Spans
           (Row       : Natural;
            Row_Start : Natural;
            Row_End   : Natural)
         is
            Cursor : Natural := Row_Start;
         begin
            --  When syntax colouring is disabled, or when a gap between
            --  lexical tokens has an editor overlay, do not prepare or consume
            --  a lexical token for that gap.  Selection/search/diagnostic
            --  overlays are still projected over the affected cells only.
            while Cursor < Row_End and then Count < Max_Render_Syntax_Spans loop
               declare
                  Overlay : constant Editor.Syntax_Overlays.Overlay_Kind :=
                    Overlay_For (Cursor, Cursor + 1);
                  Run_End : Natural := Cursor + 1;
               begin
                  while Run_End < Row_End
                    and then Overlay_For (Run_End, Run_End + 1) = Overlay
                  loop
                     Run_End := Run_End + 1;
                  end loop;

                  if Overlay /= Editor.Syntax_Overlays.No_Overlay then
                     Append_Span
                       (Row, Cursor, Run_End,
                        Editor.Syntax_Overlays.Merge
                          (Editor.Syntax.Plain_Text, Overlay));
                  end if;
                  Cursor := Run_End;
               end;
            end loop;
         end Append_Overlay_Only_Spans;

         procedure Append_Syntax_With_Overlays
           (Row         : Natural;
            Start_Index : Natural;
            End_Index   : Natural;
            Base        : Editor.Syntax.Token_Kind)
         is
            Cursor : Natural := Start_Index;
         begin
            --  Split tokens at overlay boundaries.  A diagnostic/search/
            --  selection range inside a string, keyword, or identifier should
            --  colour only that subrange; the remaining token cells keep their
            --  lexical/semantic colour.  This also gives selection/search the
            --  documented precedence over diagnostics without widening either
            --  overlay to the whole token.
            while Cursor < End_Index and then Count < Max_Render_Syntax_Spans loop
               declare
                  Overlay : constant Editor.Syntax_Overlays.Overlay_Kind :=
                    Overlay_For (Cursor, Cursor + 1);
                  Run_End : Natural := Cursor + 1;
               begin
                  while Run_End < End_Index
                    and then Overlay_For (Run_End, Run_End + 1) = Overlay
                  loop
                     Run_End := Run_End + 1;
                  end loop;

                  Append_Span
                    (Row, Cursor, Run_End,
                     Editor.Syntax_Overlays.Merge (Base, Overlay));
                  Cursor := Run_End;
               end;
            end loop;
         end Append_Syntax_With_Overlays;
      begin
         if O.Visible_First_Row <= O.Visible_Last_Row
           and then Editor.State.Line_Count (S) > 0
         then
            declare
               First_Row : constant Natural :=
                 Natural'Min (O.Visible_First_Row, Editor.State.Line_Count (S) - 1);
               Last_Row : constant Natural :=
                 Natural'Min (O.Visible_Last_Row, Editor.State.Line_Count (S) - 1);
            begin
               if Editor.Settings.Use_Syntax_Colouring then
                  Editor.State.Prepare_Syntax_For_Visible_Range
                    (S, First_Row, Last_Row,
                     Editor.Settings.Use_Semantic_Colouring);
               end if;

               for Row in First_Row .. Last_Row loop
                  exit when Count >= Max_Render_Syntax_Spans;
                  declare
                     Row_Start : constant Natural := Natural (Editor.State.Line_Start (S, Row));
                     Line : constant String := Line_Text (Row);
                     Row_End : constant Natural := Row_Start + Line'Length;
                  begin
                     if Editor.Settings.Use_Syntax_Colouring then
                        declare
                           Tokens : constant Editor.Syntax.Token_Span_Array :=
                             Editor.Syntax_Cache.Tokens_For_Line (S.Syntax_Cache, Row + 1);
                           Cursor : Natural := Row_Start;
                        begin
                           for T of Tokens loop
                              declare
                                 Base : Editor.Syntax.Token_Kind := T.Kind;
                                 Abs_Start : constant Natural := Row_Start + T.Start_Col;
                                 Abs_End   : constant Natural := Row_Start + T.End_Col;
                              begin
                                 if Abs_Start > Cursor then
                                    Append_Overlay_Only_Spans (Row, Cursor, Abs_Start);
                                 end if;

                                 if Base = Editor.Syntax.Identifier
                                   and then Editor.Settings.Use_Semantic_Colouring
                                   and then T.End_Col > T.Start_Col
                                   and then T.End_Col <= Line'Length
                                 then
                                    declare
                                       Token_Text : constant String :=
                                         Line (Line'First + T.Start_Col .. Line'First + T.End_Col - 1);
                                    begin
                                       if Editor.Ada_Language_Model.Symbol_Count (S.Syntax_Analysis) > 0 then
                                          declare
                                             Scope : constant Editor.Ada_Language_Model.Symbol_Id :=
                                               Editor.Ada_Language_Model.Scope_For_Position
                                                 (S.Syntax_Analysis, Positive (Row + 1),
                                                  Positive (T.Start_Col + 1));
                                          begin
                                             Base := Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope
                                               (S.Syntax_Analysis, Token_Text, Scope);
                                          end;

                                          --  Pass 188: scope-aware lookup is preferred for parser-owned
                                          --  symbols.  The bounded flat map remains a fallback
                                          --  for conservative legacy/line-learned entries and
                                          --  parser gaps.
                                          if Base = Editor.Syntax.Identifier then
                                             Base := Editor.Syntax_Semantics.Kind_For_Identifier
                                               (S.Syntax_Symbols, Token_Text);
                                          end if;
                                       else
                                          Base := Editor.Syntax_Semantics.Kind_For_Identifier
                                            (S.Syntax_Symbols, Token_Text);
                                       end if;
                                    end;
                                 end if;

                                 Append_Syntax_With_Overlays
                                   (Row, Abs_Start, Abs_End, Base);

                                 if Abs_End > Cursor then
                                    Cursor := Abs_End;
                                 end if;
                              end;
                           end loop;

                           if Cursor < Row_End then
                              Append_Overlay_Only_Spans (Row, Cursor, Row_End);
                           end if;
                        end;
                     else
                        Append_Overlay_Only_Spans (Row, Row_Start, Row_End);
                     end if;
                  end;
               end loop;
            end;
         end if;
         O.Syntax_Span_Count := Count;
      end;

      declare
         Minimap : constant Editor.Minimap.Minimap_Config :=
           Editor.Minimap.Current;
         Effective_Minimap_Enabled : constant Boolean :=
           Editor.Settings.Show_Minimap and then Minimap.Enabled;
         Sample_Count : Natural := 0;
         Total_Lines  : constant Natural := Natural'Max (1, Editor.State.Line_Count (S));

         function Has_Non_Whitespace
           (Start : Natural;
            Stop  : Natural) return Boolean
         is
            Found : Boolean := False;

            procedure Visit
              (Ch : Character)
            is
            begin
               if Ch /= ' ' and then Ch /= ASCII.HT then
                  Found := True;
               end if;
            end Visit;
         begin
            if Stop <= Start then
               return False;
            end if;

            Text_Buffer.For_Each_Char_Range
              (S.Buffer, Start, Stop, Visit'Access);
            return Found;
         end Has_Non_Whitespace;
      begin
         declare
            Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
              Editor.Scrollbars.Current;
            Effective_Viewport_H : constant Natural :=
              Editor.Layout.Text_Viewport_Height
                (Editor.Layout.Current,
                 Editor.Scrollbars.Effective_Viewport_Height
                   (Editor.View.Viewport_Height, Scrollbars));
         begin
         if Effective_Minimap_Enabled and then Effective_Viewport_H > 0 then
            Sample_Count := Natural'Min (Max_Minimap_Samples, Total_Lines);

            for Sample in 0 .. Sample_Count - 1 loop
               declare
                  Row : constant Natural :=
                    (if Sample_Count = Total_Lines then Sample
                     else Natural'Min
                       (Total_Lines - 1,
                        Sample * Total_Lines / Sample_Count));
                  Start : constant Natural :=
                    Natural (Editor.State.Line_Start (S, Row));
                  Stop  : constant Natural :=
                    Natural (Editor.State.Line_End (S, Row));
                  Len   : constant Natural :=
                    (if Stop >= Start then Stop - Start else 0);
               begin
                  O.Minimap_Samples (Sample) :=
                    (Row         => Row,
                     Start_Y     => Editor.Minimap.Row_Y
                       (Row, Total_Lines, Effective_Viewport_H),
                     Height      => 1.0,
                     Has_Text    => Has_Non_Whitespace (Start, Stop),
                     Text_Length => Len);
               end;
            end loop;

            O.Minimap_Sample_Count := Sample_Count;
         end if;
         end;
      end;

      O.Build_UI := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      O.Keybindings_UI := Editor.Keybinding_Management.Build_Surface_Snapshot;
      O.Settings_UI := Editor.Settings_Management.Build_Current_Surface_Snapshot (S.Settings);
      O.Configuration_Audit_UI :=
        Editor.Settings_Management.Build_Current_Configuration_Audit_Surface
          (S.Settings);
      O.Settings_Command_Catalog_UI :=
        Editor.Settings_Management.Build_Current_Settings_Command_Catalog;

      --  Phase 569: build empty-state guidance once through the canonical
      --  aggregate helper, then project each slot into the render snapshot.
      --  This keeps render-model fields synchronized with the array contract
      --  used by tests and prevents future per-surface drift.
      declare
         Empty_States : constant
           Editor.Empty_State_Guidance.Empty_State_Snapshot_Array :=
             Editor.Empty_State_Guidance.Build_All_Empty_State_Snapshots (S);
      begin
         O.Main_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.Main_Surface));
         O.File_Tree_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.File_Tree_Surface));
         O.Quick_Open_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.Quick_Open_Surface));
         O.Project_Search_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.Project_Search_Surface));
         O.Outline_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.Outline_Surface));
         O.Diagnostics_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.Diagnostics_Surface));
         O.Build_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.Build_Surface));
         O.Recent_Projects_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.Recent_Projects_Surface));
         O.Configuration_Recovery_Empty_State :=
           Empty_States
             (Editor.Empty_State_Guidance.Empty_State_Slot_For_Surface
                (Editor.Empty_State_Guidance.Configuration_Recovery_Surface));
      end;
      O.Guided_Prompt := Editor.Guided_Prompts.Snapshot (S.Guided_Prompt);

   end Build_Render_Snapshot;

end Editor.Render_Model;
