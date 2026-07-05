with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors;  use Editor.Cursors;
with Editor.Executor.Edits; use Editor.Executor.Edits;
with Editor.Executor.History;
with Editor.Navigation; use Editor.Navigation;
with Editor.State;

package body Editor.Executor.Indentation_Commands is

   use type Editor.Executor_Edit_Status.Line_Edit_Status;
   use Cursors_Vector;

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets.Element (S.Carets.First_Index).Pos;
      end if;
   end Safe_Caret;

   function Missing_Active_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return not Editor.State.Has_Active_Buffer (S);
   end Missing_Active_Buffer;

   procedure Current_Line_Bounds
     (S         : Editor.State.State_Type;
      Row       : out Natural;
      Col       : out Natural;
      Start_Pos : out Natural;
      End_Pos   : out Natural)
   is
   begin
      Line_Column_For_Index
        (S,
         Natural'Min (Natural (Safe_Caret (S)), Text_Buffer.Length (S.Buffer)),
         Row,
         Col);
      Start_Pos := Index_For_Line_Column (S, Row, 0);
      End_Pos := Start_Pos + Line_Length (S, Row);
   end Current_Line_Bounds;

   procedure Set_Single_Caret
     (S      : in out Editor.State.State_Type;
      Row    : Natural;
      Column : Natural)
   is
      Safe_Row : Natural := Row;
      Line_Len : Natural := 0;
      Pos      : Cursor_Index := 0;
   begin
      if Editor.State.Line_Count (S) = 0 then
         Safe_Row := 0;
      else
         Safe_Row := Natural'Min (Safe_Row, Editor.State.Line_Count (S) - 1);
      end if;

      Line_Len := Line_Length (S, Safe_Row);
      Pos := Cursor_Index
        (Index_For_Line_Column (S, Safe_Row, Natural'Min (Column, Line_Len)));
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => Pos,
         Anchor => Pos,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
   end Set_Single_Caret;

   function Canonical_Indentation_Unit return String is
   begin
      --  the indentation unit is intentionally local and
      --  hardcoded.  It is not a setting, workspace value, language policy,
      --  tab-width interpretation, or persistence domain.
      return "  ";
   end Canonical_Indentation_Unit;

   function Removable_Indentation_Prefix
     (S         : Editor.State.State_Type;
      Start_Pos : Natural;
      End_Pos   : Natural) return Natural
   is
      Unit : constant String := Canonical_Indentation_Unit;
      Available_Spaces : Natural := 0;
   begin
      if Start_Pos >= End_Pos then
         return 0;
      end if;

      if Text_Buffer.Character_At (S.Buffer, Start_Pos) = ASCII.HT then
         return 1;
      end if;

      while Start_Pos + Available_Spaces < End_Pos
        and then Text_Buffer.Character_At
          (S.Buffer, Start_Pos + Available_Spaces) = ' '
      loop
         Available_Spaces := Available_Spaces + 1;
      end loop;

      if Available_Spaces >= Unit'Length then
         return Unit'Length;
      else
         return Available_Spaces;
      end if;
   end Removable_Indentation_Prefix;

   function Canonical_Leading_Whitespace_Length
     (S         : Editor.State.State_Type;
      Start_Pos : Natural;
      End_Pos   : Natural) return Natural
   is
      Len : Natural := 0;
      Ch  : Character := ASCII.NUL;
   begin
      while Start_Pos + Len < End_Pos loop
         Ch := Text_Buffer.Character_At (S.Buffer, Start_Pos + Len);
         exit when Ch /= ' ' and then Ch /= ASCII.HT;
         Len := Len + 1;
      end loop;

      return Len;
   end Canonical_Leading_Whitespace_Length;

   procedure Perform_Indent_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Unit      : constant String := Canonical_Indentation_Unit;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Indent;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      declare
         Line_Was_Whitespace_Only : constant Boolean :=
           Canonical_Leading_Whitespace_Length (S, Start_Pos, End_Pos)
           = End_Pos - Start_Pos;
      begin
         Append_Replace_Op
           (Forward_Cmd, Cursor_Index (Start_Pos), 0, To_Unbounded_String (Unit));
         Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);
         if Line_Was_Whitespace_Only and then Col = 0 then
            Set_Single_Caret (S, Row, End_Pos - Start_Pos + Unit'Length);
         else
            Set_Single_Caret (S, Row, Col + Unit'Length);
         end if;
      end;
      New_Caret := Safe_Caret (S);
      Status := Line_Indented;
      Changed := True;
   exception
      when others =>
         Status := Line_Edit_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Indent_Current_Line;

   procedure Perform_Outdent_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Remove    : Natural := 0;
      New_Col   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Outdent;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      Remove := Removable_Indentation_Prefix (S, Start_Pos, End_Pos);

      if Remove = 0 then
         Status := Nothing_To_Outdent;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Append_Replace_Op
        (Forward_Cmd, Cursor_Index (Start_Pos), Remove, Null_Unbounded_String);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      if Col > Remove then
         New_Col := Col - Remove;
      else
         New_Col := 0;
      end if;

      Set_Single_Caret (S, Row, New_Col);
      New_Caret := Safe_Caret (S);
      Status := Line_Outdented;
      Changed := True;
   exception
      when others =>
         Status := Line_Edit_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Outdent_Current_Line;

   Canonical_Line_Comment_Insert_Marker : constant String := "-- ";
   Canonical_Line_Comment_Bare_Marker   : constant String := "--";

   function Canonical_Line_Comment_Marker return String is
   begin
      --  this remains the single production line-comment marker
      --  source.  It is intentionally hardcoded and isolated from settings,
      --  workspace values, file-extension policy, language services, render
      --  state, and persistence domains.
      return Canonical_Line_Comment_Insert_Marker;
   end Canonical_Line_Comment_Marker;

   type Line_Comment_State is (Line_Comment_Absent, Line_Comment_Present);

   function Line_Comment_Marker_Position
     (S         : Editor.State.State_Type;
      Start_Pos : Natural;
      End_Pos   : Natural) return Natural
   is
   begin
      --  all line-comment commands share the same canonical
      --  post-indentation marker position.  This deliberately ignores the
      --  caret column, selected text, rendered rows, visual wraps, syntax
      --  tokens, and language services.
      return Start_Pos
        + Canonical_Leading_Whitespace_Length (S, Start_Pos, End_Pos);
   end Line_Comment_Marker_Position;

   function Removable_Line_Comment_Marker_Length
     (S          : Editor.State.State_Type;
      Marker_Pos : Natural;
      End_Pos    : Natural) return Natural
   is
   begin
      --  Recognized removable markers are exactly the canonical inserted
      --  marker and the canonical bare marker at the already-computed
      --  post-leading-whitespace prefix position.  Callers are responsible
      --  for passing only that canonical position; internal markers elsewhere
      --  in the line are intentionally ignored.
      if Marker_Pos + Canonical_Line_Comment_Bare_Marker'Length > End_Pos then
         return 0;
      end if;

      for I in Canonical_Line_Comment_Bare_Marker'Range loop
         if Text_Buffer.Character_At
           (S.Buffer, Marker_Pos + I - Canonical_Line_Comment_Bare_Marker'First)
           /= Canonical_Line_Comment_Bare_Marker (I)
         then
            return 0;
         end if;
      end loop;

      if Marker_Pos + Canonical_Line_Comment_Insert_Marker'Length <= End_Pos
      then
         declare
            Full_Marker_Matches : Boolean := True;
         begin
            for I in Canonical_Line_Comment_Insert_Marker'Range loop
               if Text_Buffer.Character_At
                 (S.Buffer,
                  Marker_Pos + I - Canonical_Line_Comment_Insert_Marker'First)
                 /= Canonical_Line_Comment_Insert_Marker (I)
               then
                  Full_Marker_Matches := False;
               end if;
            end loop;

            if Full_Marker_Matches then
               return Canonical_Line_Comment_Insert_Marker'Length;
            end if;
         end;
      end if;

      return Canonical_Line_Comment_Bare_Marker'Length;
   end Removable_Line_Comment_Marker_Length;

   function Classify_Current_Line_Comment_State
     (S             : Editor.State.State_Type;
      Start_Pos     : Natural;
      End_Pos       : Natural;
      Marker_Pos    : out Natural;
      Marker_Length : out Natural) return Line_Comment_State
   is
   begin
      Marker_Pos := Line_Comment_Marker_Position (S, Start_Pos, End_Pos);
      Marker_Length :=
        Removable_Line_Comment_Marker_Length (S, Marker_Pos, End_Pos);

      if Marker_Length > 0 then
         return Line_Comment_Present;
      else
         return Line_Comment_Absent;
      end if;
   end Classify_Current_Line_Comment_State;

   procedure Perform_Comment_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Lead      : Natural := 0;
      Insert_At : Natural := 0;
      Existing  : Natural := 0;
      Marker    : constant String := Canonical_Line_Comment_Marker;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Comment;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      Insert_At := Line_Comment_Marker_Position (S, Start_Pos, End_Pos);
      Lead := Insert_At - Start_Pos;

      if Classify_Current_Line_Comment_State
        (S, Start_Pos, End_Pos, Insert_At, Existing) = Line_Comment_Present
      then
         Status := Line_Already_Commented;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Insert_At),
         0,
         To_Unbounded_String (Marker));
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      if Col >= Lead then
         Set_Single_Caret (S, Row, Col + Marker'Length);
      else
         Set_Single_Caret (S, Row, Col);
      end if;

      New_Caret := Safe_Caret (S);
      Status := Line_Commented;
      Changed := True;
   exception
      when others =>
         Status := Comment_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Comment_Current_Line;

   procedure Perform_Uncomment_Current_Line
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Lead      : Natural := 0;
      Marker_At : Natural := 0;
      Remove    : Natural := 0;
      New_Col   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Uncomment;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      if Classify_Current_Line_Comment_State
        (S, Start_Pos, End_Pos, Marker_At, Remove) = Line_Comment_Absent
      then
         Status := Nothing_To_Uncomment;
         New_Caret := Safe_Caret (S);
         return;
      end if;
      Lead := Marker_At - Start_Pos;

      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Marker_At),
         Remove,
         Null_Unbounded_String);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      if Col > Lead + Remove then
         New_Col := Col - Remove;
      elsif Col >= Lead then
         New_Col := Lead;
      else
         New_Col := Col;
      end if;

      Set_Single_Caret (S, Row, New_Col);
      New_Caret := Safe_Caret (S);
      Status := Line_Uncommented;
      Changed := True;
   exception
      when others =>
         Status := Uncomment_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Uncomment_Current_Line;

   procedure Perform_Toggle_Current_Line_Comment
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Row       : Natural := 0;
      Col       : Natural := 0;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
      Marker_At : Natural := 0;
      Remove    : Natural := 0;
   begin
      if Missing_Active_Buffer (S) then
         Changed := False;
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         Forward_Cmd.Kind := Apply_Replace_Batch;
         return;
      elsif S.Carets.Length = 0 then
         Changed := False;
         Status := No_Caret_Location;
         New_Caret := 0;
         Forward_Cmd.Kind := Apply_Replace_Batch;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Changed := False;
         Status := Nothing_To_Comment;
         New_Caret := Safe_Caret (S);
         Forward_Cmd.Kind := Apply_Replace_Batch;
         return;
      end if;

      Current_Line_Bounds (S, Row, Col, Start_Pos, End_Pos);
      pragma Unreferenced (Row, Col);

      if Classify_Current_Line_Comment_State
        (S, Start_Pos, End_Pos, Marker_At, Remove) = Line_Comment_Present
      then
         Perform_Uncomment_Current_Line
           (S, New_Caret, Forward_Cmd, Changed, Status);
      else
         Perform_Comment_Current_Line
           (S, New_Caret, Forward_Cmd, Changed, Status);
      end if;
   exception
      when others =>
         Status := Comment_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
         Forward_Cmd.Kind := Apply_Replace_Batch;
   end Perform_Toggle_Current_Line_Comment;

end Editor.Executor.Indentation_Commands;
