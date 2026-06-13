with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Cursors;

package body Editor.Problems is

   use type Editor.Diagnostics.Diagnostic_Index;



   procedure Clear_View
     (View : in out Problems_View_State)
   is
   begin
      View.Selected_Row_Index := 0;
      View.Top_Row := 1;
   end Clear_View;

   function Selected_Row_Index
     (View : Problems_View_State) return Natural
   is
   begin
      return View.Selected_Row_Index;
   end Selected_Row_Index;

   procedure Set_Selected_Row_Index
     (View  : in out Problems_View_State;
      Index : Natural)
   is
   begin
      View.Selected_Row_Index := Index;
   end Set_Selected_Row_Index;

   function Top_Row
     (View : Problems_View_State) return Natural
   is
   begin
      return View.Top_Row;
   end Top_Row;

   procedure Set_Top_Row
     (View : in out Problems_View_State;
      Row  : Natural)
   is
   begin
      View.Top_Row := Natural'Max (1, Row);
   end Set_Top_Row;

   function Natural_Image
     (Value : Natural) return String
   is
      Image : constant String := Natural'Image (Value);
   begin
      if Image'Length > 0 and then Image (Image'First) = ' ' then
         return Image (Image'First + 1 .. Image'Last);
      else
         return Image;
      end if;
   end Natural_Image;

   function Severity_Name
     (Severity : Problem_Row_Severity) return String
   is
   begin
      case Severity is
         when Problem_Error   => return "Error";
         when Problem_Warning => return "Warning";
         when Problem_Info    => return "Info";
         when Problem_Hint    => return "Hint";
      end case;
   end Severity_Name;

   function Map_Severity
     (Severity : Editor.Diagnostics.Diagnostic_Severity) return Problem_Row_Severity
   is
   begin
      case Severity is
         when Editor.Diagnostics.Error       => return Problem_Error;
         when Editor.Diagnostics.Warning     => return Problem_Warning;
         when Editor.Diagnostics.Note        => return Problem_Info;
         when Editor.Diagnostics.Information => return Problem_Info;
         when Editor.Diagnostics.Hint        => return Problem_Hint;
         when Editor.Diagnostics.Unknown     => return Problem_Info;
      end case;
   end Map_Severity;

   function Default_Message
     (Severity   : Problem_Row_Severity;
      Diagnostic : Editor.Diagnostics.Diagnostic_Range) return String
   is
   begin
      if Length (Diagnostic.Message) > 0 then
         return To_String (Diagnostic.Message);
      else
         return Severity_Name (Severity);
      end if;
   end Default_Message;

   procedure Append_Diagnostic
     (Snapshot         : in out Problems_Snapshot;
      Diagnostic_Index : Editor.Diagnostics.Diagnostic_Index;
      Diagnostic       : Editor.Diagnostics.Diagnostic_Range;
      Row              : Natural;
      Column           : Natural;
      Source_File      : String := "")
   is
      Severity : constant Problem_Row_Severity := Map_Severity (Diagnostic.Severity);
   begin
      Snapshot.Rows.Append
        (Problem_Row'
          (Diagnostic_Index => Diagnostic_Index,
          Severity         => Severity,
          Row              => Row,
          Column           => Column,
          Message          => To_Unbounded_String
            (Default_Message (Severity, Diagnostic)),
          Source_File      => To_Unbounded_String (Source_File)));
   end Append_Diagnostic;

   procedure Clear
     (Snapshot : in out Problems_Snapshot)
   is
   begin
      Snapshot.Rows.Clear;
   end Clear;

   function Row_Count
     (Snapshot : Problems_Snapshot) return Natural
   is
   begin
      return Natural (Snapshot.Rows.Length);
   end Row_Count;

   function Row
     (Snapshot : Problems_Snapshot;
      Index    : Positive) return Problem_Row
   is
   begin
      return Snapshot.Rows.Element (Index);
   end Row;

   function Build_Snapshot
     (Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector)
      return Problems_Snapshot
   is
      Result : Problems_Snapshot;
   begin
      for Ordered_Pos in 1 .. Editor.Diagnostics.Ordered_Diagnostic_Count (Diagnostics) loop
         declare
            Diagnostic_Index : constant Editor.Diagnostics.Diagnostic_Index :=
              Editor.Diagnostics.Ordered_Diagnostic_Index_At
                (Diagnostics, Ordered_Pos);
            Diagnostic : constant Editor.Diagnostics.Diagnostic_Range :=
              Editor.Diagnostics.Diagnostic_At
                (Diagnostics, Positive (Natural (Diagnostic_Index)));
            Target : constant Editor.Diagnostics.Diagnostic_Target :=
              Editor.Diagnostics.Target_For_Diagnostic
                (Diagnostics, Diagnostic_Index);
         begin
            Append_Diagnostic
              (Snapshot         => Result,
               Diagnostic_Index => Diagnostic_Index,
               Diagnostic       => Diagnostic,
               Row              => Target.Row,
               Column           => Target.Column);
         end;
      end loop;

      return Result;
   end Build_Snapshot;


   function Format_Header
     (Config : Problems_View_Config;
      Count  : Natural) return String
   is
      pragma Unreferenced (Config);
   begin
      return "Problems: " & Natural_Image (Count);
   end Format_Header;

   function Truncate_Text
     (Text        : String;
      Max_Columns : Natural) return String
   is
   begin
      if Text'Length <= Max_Columns then
         return Text;
      elsif Max_Columns = 0 then
         return "";
      elsif Max_Columns <= 3 then
         return Text (Text'First .. Text'First + Max_Columns - 1);
      else
         return Text (Text'First .. Text'First + Max_Columns - 4) & "...";
      end if;
   end Truncate_Text;

   function Format_Row
     (Config : Problems_View_Config;
      Row    : Problem_Row;
      Width  : Natural) return String
   is
      Row_Display : constant Natural := Row.Row + 1;
      Col_Display : constant Natural := Row.Column + 1;
      Prefix : Unbounded_String := Null_Unbounded_String;
      Raw    : Unbounded_String := Null_Unbounded_String;
   begin
      if Config.Show_File_Name and then Length (Row.Source_File) > 0 then
         Append (Prefix, Row.Source_File);
         Append (Prefix, ":");
         Append (Prefix, Natural_Image (Row_Display));
         Append (Prefix, ":");
         Append (Prefix, Natural_Image (Col_Display));
         Append (Prefix, " ");
      end if;

      if Config.Show_Severity then
         Append (Prefix, Severity_Name (Row.Severity));
      end if;

      if Config.Show_Row_Column then
         if Length (Prefix) > 0 then
            Append (Prefix, " ");
         end if;
         Append (Prefix, "Ln ");
         Append (Prefix, Natural_Image (Row_Display));
         Append (Prefix, ", Col ");
         Append (Prefix, Natural_Image (Col_Display));
      end if;

      Raw := Prefix;
      if Length (Raw) > 0 then
         Append (Raw, ": ");
      end if;
      Append (Raw, Truncate_Text (To_String (Row.Message), Config.Maximum_Message_Columns));

      return Truncate_Text (To_String (Raw), Width);
   end Format_Row;



   function Row_For_Diagnostic
     (Snapshot         : Problems_Snapshot;
      Diagnostic_Index : Editor.Diagnostics.Diagnostic_Index;
      Found            : out Boolean) return Natural
   is
      R : Problem_Row;
   begin
      Found := False;
      if Diagnostic_Index = Editor.Diagnostics.No_Diagnostic then
         return 0;
      end if;

      for I in 1 .. Natural (Snapshot.Rows.Length) loop
         R := Snapshot.Rows.Element (Positive (I));
         if R.Diagnostic_Index = Diagnostic_Index then
            Found := True;
            return I;
         end if;
      end loop;
      return 0;
   end Row_For_Diagnostic;

   function Diagnostic_For_Row
     (Snapshot  : Problems_Snapshot;
      Row_Index : Natural;
      Found     : out Boolean)
      return Editor.Diagnostics.Diagnostic_Index
   is
   begin
      Found := False;
      if Row_Index = 0 or else Row_Index > Natural (Snapshot.Rows.Length) then
         return Editor.Diagnostics.No_Diagnostic;
      end if;

      declare
         R : constant Problem_Row := Snapshot.Rows.Element (Positive (Row_Index));
      begin
         if R.Diagnostic_Index /= Editor.Diagnostics.No_Diagnostic then
            Found := True;
            return R.Diagnostic_Index;
         end if;
      end;
      return Editor.Diagnostics.No_Diagnostic;
   end Diagnostic_For_Row;

   function First_Diagnostic_Row
     (Snapshot : Problems_Snapshot;
      Found    : out Boolean) return Natural
   is
      Dummy : Editor.Diagnostics.Diagnostic_Index;
   begin
      for I in 1 .. Natural (Snapshot.Rows.Length) loop
         Dummy := Diagnostic_For_Row (Snapshot, I, Found);
         if Found then
            return I;
         end if;
      end loop;
      Found := False;
      return 0;
   end First_Diagnostic_Row;

   function Last_Diagnostic_Row
     (Snapshot : Problems_Snapshot;
      Found    : out Boolean) return Natural
   is
      Dummy : Editor.Diagnostics.Diagnostic_Index;
   begin
      if Natural (Snapshot.Rows.Length) = 0 then
         Found := False;
         return 0;
      end if;

      for I in reverse 1 .. Natural (Snapshot.Rows.Length) loop
         Dummy := Diagnostic_For_Row (Snapshot, I, Found);
         if Found then
            return I;
         end if;
      end loop;
      Found := False;
      return 0;
   end Last_Diagnostic_Row;

   procedure Ensure_Valid_Selection
     (View     : in out Problems_View_State;
      Snapshot : Problems_Snapshot)
   is
      Found : Boolean := False;
      Dummy : Editor.Diagnostics.Diagnostic_Index;
      First : Natural := 0;
   begin
      Dummy := Diagnostic_For_Row (Snapshot, View.Selected_Row_Index, Found);
      if Found then
         return;
      end if;

      First := First_Diagnostic_Row (Snapshot, Found);
      if Found then
         View.Selected_Row_Index := First;
      else
         View.Selected_Row_Index := 0;
      end if;
   end Ensure_Valid_Selection;

   procedure Move_Selection
     (View      : in out Problems_View_State;
      Snapshot  : Problems_Snapshot;
      Direction : Problems_Row_Direction;
      Wrap      : Boolean := True)
   is
      Found : Boolean := False;
      Candidate : Natural := 0;
      Current : Natural := 0;
      Count : constant Natural := Natural (Snapshot.Rows.Length);
      Dummy : Editor.Diagnostics.Diagnostic_Index;
   begin
      Ensure_Valid_Selection (View, Snapshot);
      if View.Selected_Row_Index = 0 or else Count = 0 then
         return;
      end if;

      Current := View.Selected_Row_Index;
      case Direction is
         when Next_Row =>
            if Current < Count then
               for I in Current + 1 .. Count loop
                  Dummy := Diagnostic_For_Row (Snapshot, I, Found);
                  if Found then
                     View.Selected_Row_Index := I;
                     return;
                  end if;
               end loop;
            end if;
            if Wrap then
               Candidate := First_Diagnostic_Row (Snapshot, Found);
               if Found then
                  View.Selected_Row_Index := Candidate;
               end if;
            end if;
         when Previous_Row =>
            if Current > 1 then
               for I in reverse 1 .. Current - 1 loop
                  Dummy := Diagnostic_For_Row (Snapshot, I, Found);
                  if Found then
                     View.Selected_Row_Index := I;
                     return;
                  end if;
               end loop;
            end if;
            if Wrap then
               Candidate := Last_Diagnostic_Row (Snapshot, Found);
               if Found then
                  View.Selected_Row_Index := Candidate;
               end if;
            end if;
      end case;
   end Move_Selection;

   procedure Ensure_Selected_Row_Visible
     (View              : in out Problems_View_State;
      Snapshot          : Problems_Snapshot;
      Visible_Row_Count : Natural)
   is
      Count : constant Natural := Natural (Snapshot.Rows.Length);
      Visible : constant Natural := Natural'Max (1, Visible_Row_Count);
      Last_Allowed : Natural := 1;
   begin
      Ensure_Valid_Selection (View, Snapshot);

      if Count = 0 then
         View.Top_Row := 1;
         return;
      end if;

      if Visible >= Count then
         Last_Allowed := 1;
      else
         Last_Allowed := Count - Visible + 1;
      end if;

      if View.Top_Row = 0 then
         View.Top_Row := 1;
      elsif View.Top_Row > Last_Allowed then
         View.Top_Row := Last_Allowed;
      end if;

      if View.Selected_Row_Index /= 0 then
         if View.Selected_Row_Index < View.Top_Row then
            View.Top_Row := View.Selected_Row_Index;
         elsif View.Selected_Row_Index >= View.Top_Row + Visible then
            View.Top_Row := View.Selected_Row_Index - Visible + 1;
         end if;
      end if;
   end Ensure_Selected_Row_Visible;

   procedure Clamp_Viewport
     (View              : in out Problems_View_State;
      Snapshot          : Problems_Snapshot;
      Visible_Row_Count : Natural)
   is
      Count        : constant Natural := Natural (Snapshot.Rows.Length);
      Visible      : constant Natural := Natural'Max (Visible_Row_Count, 1);
      Last_Allowed : Natural := 1;
   begin
      if Count = 0 then
         View.Top_Row := 1;
         return;
      end if;

      if Count > Visible then
         Last_Allowed := Count - Visible + 1;
      end if;

      if View.Top_Row = 0 then
         View.Top_Row := 1;
      elsif View.Top_Row > Last_Allowed then
         View.Top_Row := Last_Allowed;
      end if;
   end Clamp_Viewport;

   procedure Scroll_By
     (View              : in out Problems_View_State;
      Snapshot          : Problems_Snapshot;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer)
   is
      Count        : constant Natural := Natural (Snapshot.Rows.Length);
      Visible      : constant Natural := Natural'Max (Visible_Row_Count, 1);
      Last_Allowed : Natural := 1;
      Desired      : Integer := Integer (View.Top_Row) + Step_Delta;
   begin
      if Count = 0 then
         View.Top_Row := 1;
         return;
      end if;

      if Count > Visible then
         Last_Allowed := Count - Visible + 1;
      end if;

      if Desired < 1 then
         Desired := 1;
      elsif Desired > Integer (Last_Allowed) then
         Desired := Integer (Last_Allowed);
      end if;

      View.Top_Row := Natural (Desired);
   end Scroll_By;

   function Visible_Snapshot
     (Snapshot          : Problems_Snapshot;
      View              : Problems_View_State;
      Visible_Row_Count : Natural) return Problems_Snapshot
   is
      Result : Problems_Snapshot;
      Count  : constant Natural := Natural (Snapshot.Rows.Length);
      Start  : Natural := Natural'Max (1, View.Top_Row);
      Stop   : Natural := 0;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         return Result;
      end if;

      if Start > Count then
         Start := Count;
      end if;

      if Visible_Row_Count >= Count - Start + 1 then
         Stop := Count;
      else
         Stop := Start + Visible_Row_Count - 1;
      end if;

      for I in Start .. Stop loop
         Result.Rows.Append (Snapshot.Rows.Element (Positive (I)));
      end loop;

      return Result;
   end Visible_Snapshot;

   function Hit_Test
     (Panel_Rect  : Editor.Layout.Rect;
      Config      : Problems_View_Config;
      Snapshot    : Problems_Snapshot;
      Cell_Height : Natural;
      X           : Integer;
      Y           : Integer) return Problems_Hit_Result
   is
      Capacity_Rows : Natural := 0;
      Header_Rows   : Natural := 0;
      Row_Area_Y    : Integer := Panel_Rect.Y;
      Row_Number    : Natural := 0;
   begin
      if Panel_Rect.Width = 0 or else Panel_Rect.Height = 0
        or else Cell_Height = 0
      then
         return (Zone => Outside_Problems, Row => 0, Diagnostic_Index => Editor.Diagnostics.No_Diagnostic);
      end if;

      if X < Panel_Rect.X or else Y < Panel_Rect.Y
        or else X >= Panel_Rect.X + Integer (Panel_Rect.Width)
        or else Y >= Panel_Rect.Y + Integer (Panel_Rect.Height)
      then
         return (Zone => Outside_Problems, Row => 0, Diagnostic_Index => Editor.Diagnostics.No_Diagnostic);
      end if;

      Capacity_Rows := Panel_Rect.Height / Cell_Height;
      if Capacity_Rows = 0 then
         return (Zone => Problems_Background_Zone, Row => 0, Diagnostic_Index => Editor.Diagnostics.No_Diagnostic);
      end if;

      if Config.Show_Header then
         Header_Rows := Natural'Min (Config.Header_Height_In_Rows, Capacity_Rows);
         if Y < Panel_Rect.Y + Integer (Header_Rows * Cell_Height) then
            return (Zone => Problems_Header_Zone, Row => 0, Diagnostic_Index => Editor.Diagnostics.No_Diagnostic);
         end if;
      end if;

      if Capacity_Rows <= Header_Rows then
         return (Zone => Problems_Background_Zone, Row => 0, Diagnostic_Index => Editor.Diagnostics.No_Diagnostic);
      end if;

      Row_Area_Y := Panel_Rect.Y + Integer (Header_Rows * Cell_Height);
      Row_Number := Natural ((Y - Row_Area_Y) / Integer (Cell_Height)) + 1;

      if Row_Number <= Row_Count (Snapshot)
        and then Row_Number <= Capacity_Rows - Header_Rows
      then
         declare
            Problem : constant Problem_Row := Row (Snapshot, Positive (Row_Number));
         begin
            return
              (Zone             => Problems_Row_Zone,
               Row              => Row_Number,
               Diagnostic_Index => Problem.Diagnostic_Index);
         end;
      end if;

      return (Zone => Problems_Background_Zone, Row => 0, Diagnostic_Index => Editor.Diagnostics.No_Diagnostic);
   end Hit_Test;

end Editor.Problems;
