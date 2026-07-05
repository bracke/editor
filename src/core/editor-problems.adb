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
      View.Severity_Filter := Problems_Show_All;
      View.Sort_Mode := Problems_Sort_By_Location;
      View.Group_Mode := Problems_Group_By_Severity;
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

   function Severity_Filter
     (View : Problems_View_State) return Problems_Severity_Filter
   is
   begin
      return View.Severity_Filter;
   end Severity_Filter;

   procedure Set_Severity_Filter
     (View   : in out Problems_View_State;
      Filter : Problems_Severity_Filter)
   is
   begin
      View.Severity_Filter := Filter;
      View.Top_Row := 1;
      View.Selected_Row_Index := 0;
   end Set_Severity_Filter;

   function Severity_Filter_Label
     (Filter : Problems_Severity_Filter) return String
   is
   begin
      case Filter is
         when Problems_Show_All =>
            return "all";
         when Problems_Show_Errors =>
            return "errors";
         when Problems_Show_Warnings =>
            return "warnings";
         when Problems_Show_Info =>
            return "info";
         when Problems_Show_Hints =>
            return "hints";
      end case;
   end Severity_Filter_Label;

   function Source_Group_Label (Source_File : Unbounded_String) return String is
   begin
      if Length (Source_File) = 0 then
         return "current buffer";
      else
         return To_String (Source_File);
      end if;
   end Source_Group_Label;

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

   function Sort_Mode_Label
     (Sort : Problems_Sort_Mode) return String
   is
   begin
      case Sort is
         when Problems_Sort_By_Location =>
            return "location";
         when Problems_Sort_By_Severity =>
            return "severity";
         when Problems_Sort_By_Source =>
            return "source";
      end case;
   end Sort_Mode_Label;

   function Group_Mode_Label
     (Group : Problems_Group_Mode) return String
   is
   begin
      case Group is
         when Problems_Group_By_Severity =>
            return "severity";
         when Problems_Group_By_Source =>
            return "source";
      end case;
   end Group_Mode_Label;

   function Header_Action_At_X
     (Panel_Width : Natural;
      X_Offset    : Natural) return Problems_Header_Action
   is
      Third : constant Natural := Natural'Max (1, Panel_Width / 3);
   begin
      if X_Offset < Third then
         return Problems_Header_Filter_Action;
      elsif X_Offset < Third * 2 then
         return Problems_Header_Sort_Action;
      else
         return Problems_Header_Group_Action;
      end if;
   end Header_Action_At_X;

   function Header_Action_Label
     (View   : Problems_View_State;
      Action : Problems_Header_Action) return String
   is
   begin
      case Action is
         when Problems_Header_Filter_Action =>
            return "[filter " & Severity_Filter_Label (View.Severity_Filter) & "]";
         when Problems_Header_Sort_Action =>
            return "[sort " & Sort_Mode_Label (View.Sort_Mode) & "]";
         when Problems_Header_Group_Action =>
            return "[group " & Group_Mode_Label (View.Group_Mode) & "]";
      end case;
   end Header_Action_Label;

   function Header_Action_Hint
     (View : Problems_View_State) return String
   is
   begin
      return "actions: "
        & Header_Action_Label (View, Problems_Header_Filter_Action)
        & " "
        & Header_Action_Label (View, Problems_Header_Sort_Action)
        & " "
        & Header_Action_Label (View, Problems_Header_Group_Action);
   end Header_Action_Hint;

   function Group_Label
     (Row  : Problem_Row;
      Mode : Problems_Group_Mode) return String
   is
   begin
      case Mode is
         when Problems_Group_By_Severity =>
            return Severity_Name (Row.Severity);
         when Problems_Group_By_Source =>
            return Source_Group_Label (Row.Source_File);
      end case;
   end Group_Label;

   function Severity_Rank
     (Severity : Problem_Row_Severity) return Natural
   is
   begin
      case Severity is
         when Problem_Error   => return 1;
         when Problem_Warning => return 2;
         when Problem_Info    => return 3;
         when Problem_Hint    => return 4;
      end case;
   end Severity_Rank;

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
          Source_File      => To_Unbounded_String (Source_File),
          Has_Target       => Diagnostic.Has_Location,
          Quick_Fix_Label  => Diagnostic.Quick_Fix_Label,
          Quick_Fix_Detail => Diagnostic.Quick_Fix_Detail));
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

   function Severity_Count
     (Snapshot : Problems_Snapshot;
      Severity : Problem_Row_Severity) return Natural
   is
      Count : Natural := 0;
   begin
      for Problem of Snapshot.Rows loop
         if Problem.Severity = Severity then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Severity_Count;

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

   function Message_No_Problems return String is
   begin
      return "No diagnostics.";
   end Message_No_Problems;

   function Message_No_Visible_Problems return String is
   begin
      return "No diagnostics match the current filter.";
   end Message_No_Visible_Problems;

   function Empty_State_Message
     (Visible_Count : Natural;
      Total_Count   : Natural) return String
   is
   begin
      if Visible_Count > 0 then
         return "";
      elsif Total_Count > 0 then
         return Message_No_Visible_Problems;
      else
         return Message_No_Problems;
      end if;
   end Empty_State_Message;

   function Format_Header
     (Config : Problems_View_Config;
      Count  : Natural;
      Filter : Problems_Severity_Filter := Problems_Show_All) return String
   is
      pragma Unreferenced (Config);
   begin
      if Filter = Problems_Show_All then
         return "Problems: " & Natural_Image (Count);
      else
         return "Problems: " & Natural_Image (Count)
           & " (" & Severity_Filter_Label (Filter) & ")";
      end if;
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
      if Length (Row.Quick_Fix_Label) > 0 then
         Append (Raw, " | action: ");
         Append (Raw, To_String (Row.Quick_Fix_Label));
         if Length (Row.Quick_Fix_Detail) > 0 then
            Append (Raw, " | ");
            Append (Raw, To_String (Row.Quick_Fix_Detail));
         end if;
      end if;

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

   function Row_Has_Target
     (Row : Problem_Row) return Boolean
   is
   begin
      return Row.Diagnostic_Index /= Editor.Diagnostics.No_Diagnostic
        and then Row.Has_Target;
   end Row_Has_Target;

   function Row_Target_Unavailable_Label
     (Row : Problem_Row) return String
   is
   begin
      if Row.Diagnostic_Index = Editor.Diagnostics.No_Diagnostic then
         return "No diagnostic selected";
      elsif not Row.Has_Target then
         return "Selected diagnostic has no source target.";
      else
         return "";
      end if;
   end Row_Target_Unavailable_Label;

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
      Filtered : constant Problems_Snapshot := Review_Snapshot (Snapshot, View);
      Result : Problems_Snapshot;
      Count  : Natural := 0;
      Start  : Natural := Natural'Max (1, View.Top_Row);
      Stop   : Natural := 0;
   begin
      Count := Natural (Filtered.Rows.Length);

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
         Result.Rows.Append (Filtered.Rows.Element (Positive (I)));
      end loop;

      return Result;
   end Visible_Snapshot;

   function Filtered_Snapshot
     (Snapshot : Problems_Snapshot;
      View     : Problems_View_State) return Problems_Snapshot
   is
      Result : Problems_Snapshot;

      function Matches_Filter
        (Problem : Problem_Row) return Boolean
      is
      begin
         case View.Severity_Filter is
            when Problems_Show_All =>
               return True;
            when Problems_Show_Errors =>
               return Problem.Severity = Problem_Error;
            when Problems_Show_Warnings =>
               return Problem.Severity = Problem_Warning;
            when Problems_Show_Info =>
               return Problem.Severity = Problem_Info;
            when Problems_Show_Hints =>
               return Problem.Severity = Problem_Hint;
         end case;
      end Matches_Filter;
   begin
      for Problem of Snapshot.Rows loop
         if Matches_Filter (Problem) then
            Result.Rows.Append (Problem);
         end if;
      end loop;

      return Result;
   end Filtered_Snapshot;

   function Problem_Less
     (Left  : Problem_Row;
      Right : Problem_Row;
      Sort  : Problems_Sort_Mode) return Boolean
   is
      Left_Source  : constant String := Source_Group_Label (Left.Source_File);
      Right_Source : constant String := Source_Group_Label (Right.Source_File);
   begin
      case Sort is
         when Problems_Sort_By_Severity =>
            if Severity_Rank (Left.Severity) /= Severity_Rank (Right.Severity) then
               return Severity_Rank (Left.Severity) < Severity_Rank (Right.Severity);
            end if;
         when Problems_Sort_By_Source =>
            if Left_Source /= Right_Source then
               return Left_Source < Right_Source;
            end if;
         when Problems_Sort_By_Location =>
            null;
      end case;

      if Left.Row /= Right.Row then
         return Left.Row < Right.Row;
      elsif Left.Column /= Right.Column then
         return Left.Column < Right.Column;
      else
         return Natural (Left.Diagnostic_Index) < Natural (Right.Diagnostic_Index);
      end if;
   end Problem_Less;

   function Sorted_Snapshot
     (Snapshot : Problems_Snapshot;
      Sort     : Problems_Sort_Mode) return Problems_Snapshot
   is
      Result : Problems_Snapshot;
      Inserted : Boolean := False;
   begin
      for Problem of Snapshot.Rows loop
         Inserted := False;
         for I in 1 .. Natural (Result.Rows.Length) loop
            if Problem_Less (Problem, Result.Rows.Element (Positive (I)), Sort) then
               Result.Rows.Insert (Before => Positive (I), New_Item => Problem);
               Inserted := True;
               exit;
            end if;
         end loop;
         if not Inserted then
            Result.Rows.Append (Problem);
         end if;
      end loop;
      return Result;
   end Sorted_Snapshot;

   function Review_Snapshot
     (Snapshot : Problems_Snapshot;
      View     : Problems_View_State) return Problems_Snapshot
   is
   begin
      return Sorted_Snapshot (Filtered_Snapshot (Snapshot, View), View.Sort_Mode);
   end Review_Snapshot;

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
