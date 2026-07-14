with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Guikit.Draw;

package body Editor.Keybinding_Management.Surface_Projection is

   function Truncate_To_Columns
     (Text    : String;
      Columns : Natural) return String
   is
   begin
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      elsif Columns = 1 then
         return "~";
      else
         return Text (Text'First .. Text'First + Columns - 2) & "~";
      end if;
   end Truncate_To_Columns;

   function Filter_Index_For
     (Filter : Keybinding_Filter) return Positive
   is
   begin
      case Filter is
         when Filter_All =>
            return 1;
         when Filter_Bound =>
            return 2;
         when Filter_Unbound =>
            return 3;
         when Filter_Conflicts =>
            return 4;
         when Filter_Non_Bindable =>
            return 5;
      end case;
   end Filter_Index_For;

   procedure Append_Segment
     (Segments : in out Guikit.Segmented.Segment_Vectors.Vector;
      Label    : String)
   is
   begin
      Segments.Append
        (Guikit.Segmented.Segment'
           (Label   => To_Unbounded_String (Label),
            Tooltip => Null_Unbounded_String,
            Enabled => True));
   end Append_Segment;

   function Status_Line
     (Surface      : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;
      Text_Columns : Natural) return Unbounded_String
   is
   begin
      if Surface.Has_Pending_Reset then
         return To_Unbounded_String
           (Truncate_To_Columns
              ("Reset pending: run reset again to confirm, cancel to abort.",
               Text_Columns));
      elsif Surface.Last_Load_Ignored_Count > 0 then
         return To_Unbounded_String
           (Truncate_To_Columns
              (To_String (Surface.Last_Load_Diagnostic_Label),
               Text_Columns));
      elsif Surface.Row_Count = 0 then
         return To_Unbounded_String
           (Truncate_To_Columns ("No matching keybindings", Text_Columns));
      else
         return Null_Unbounded_String;
      end if;
   end Status_Line;

   function Detail_Text_For
     (Category : String;
      Source   : String) return String
   is
   begin
      return Category & " / " & Source;
   end Detail_Text_For;

   function Binding_Text_For
     (Row : Editor.Keybinding_Management.Keybinding_Row_Snapshot) return String
   is
   begin
      if Row.Has_Active_Chord then
         return To_String (Row.Active_Chords);
      elsif Row.Has_Default_Chord then
         return "default " & To_String (Row.Default_Chord);
      elsif Row.Bindable then
         return "unbound";
      else
         return "non-bindable";
      end if;
   end Binding_Text_For;

   function Source_Text_For
     (Row : Editor.Keybinding_Management.Keybinding_Chord_Row_Snapshot) return String
   is
   begin
      if Row.Default_Chord then
         return "default";
      elsif Row.User_Override then
         return "user";
      else
         return "runtime";
      end if;
   end Source_Text_For;

   function Project
     (Surface      : Editor.Keybinding_Management.Keybinding_Surface_Snapshot;
      Text_Columns : Natural)
      return Keybinding_Surface_Render_Projection
   is
      Result : Keybinding_Surface_Render_Projection;

      procedure Append_Command_Row
        (Row : Editor.Keybinding_Management.Keybinding_Row_Snapshot)
      is
      begin
         Result.Command_Rows.Append
           (Guikit.List_Panel.List_Panel_Row'
              (Label            =>
                 To_Unbounded_String
                   (Truncate_To_Columns (To_String (Row.Command_Title), Text_Columns)),
               Detail           =>
                 To_Unbounded_String
                   (Truncate_To_Columns
                      (Detail_Text_For
                         (To_String (Row.Category_Label),
                          To_String (Row.Source_Label)),
                       Text_Columns)),
               Shortcut         =>
                 To_Unbounded_String
                   (Truncate_To_Columns
                      (Binding_Text_For (Row)
                       & (if Row.Conflicting then " conflict" else ""),
                       Text_Columns)),
               Selected         => Row.Selected,
               Enabled          => Row.Bindable,
               Label_Color      => Guikit.Draw.Text_Color,
               Has_Background   => False,
               Background_Color => Guikit.Draw.Pane_Color,
               Accent_Color     =>
                 (if Row.Conflicting then Guikit.Draw.Error_Text_Color
                  else Guikit.Draw.Border_Color),
               Shortcut_Color   =>
                 (if Row.Conflicting then Guikit.Draw.Error_Text_Color
                  else Guikit.Draw.Muted_Text_Color)));
      end Append_Command_Row;

      procedure Append_Chord_Row
        (Row : Editor.Keybinding_Management.Keybinding_Chord_Row_Snapshot)
      is
      begin
         Result.Chord_Rows.Append
           (Guikit.List_Panel.List_Panel_Row'
              (Label            =>
                 To_Unbounded_String
                   (Truncate_To_Columns (To_String (Row.Chord_Label), Text_Columns)),
               Detail           =>
                 To_Unbounded_String
                   (Truncate_To_Columns
                      (Detail_Text_For
                         (To_String (Row.Category_Label),
                          Source_Text_For (Row)),
                       Text_Columns)),
               Shortcut         =>
                 To_Unbounded_String
                   (Truncate_To_Columns
                      (To_String (Row.Command_Title)
                       & (if Row.Conflicting then " conflict" else ""),
                       Text_Columns)),
               Selected         => Row.Selected,
               Enabled          => True,
               Label_Color      => Guikit.Draw.Text_Color,
               Has_Background   => False,
               Background_Color => Guikit.Draw.Pane_Color,
               Accent_Color     =>
                 (if Row.Conflicting then Guikit.Draw.Error_Text_Color
                  else Guikit.Draw.Border_Color),
               Shortcut_Color   =>
                 (if Row.Conflicting then Guikit.Draw.Error_Text_Color
                  else Guikit.Draw.Muted_Text_Color)));
      end Append_Chord_Row;
   begin
      Result.Filter_Index := Filter_Index_For (Surface.Filter);
      Append_Segment (Result.Segments, "all");
      Append_Segment (Result.Segments, "bound");
      Append_Segment (Result.Segments, "unbound");
      Append_Segment (Result.Segments, "conflicts");
      Append_Segment (Result.Segments, "non-bindable");

      for I in 1 .. Surface.Display_Row_Count loop
         Append_Command_Row (Surface.Display_Rows (I));
      end loop;

      for I in 1 .. Surface.Display_Chord_Row_Count loop
         Append_Chord_Row (Surface.Display_Chord_Rows (I));
      end loop;

      Result.Status_Line := Status_Line (Surface, Text_Columns);
      return Result;
   end Project;

end Editor.Keybinding_Management.Surface_Projection;
