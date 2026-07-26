with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Command_Palette.Rows is

   function Truncate_With_Ellipsis
     (Text        : String;
      Max_Columns : Natural) return String
   is
   begin
      if Max_Columns = 0 then
         return "";
      elsif Text'Length <= Max_Columns then
         return Text;
      elsif Max_Columns = 1 then
         return "~";
      else
         declare
            Prefix : constant String :=
              Text (Text'First .. Text'First + Max_Columns - 2);
            Last   : Integer := Prefix'Last;
         begin
            if Last >= Prefix'First
              and then (Prefix (Last) = '.' or else Prefix (Last) = ' ')
            then
               Last := Last - 1;
            end if;
            if Last < Prefix'First then
               return "~";
            else
               return Prefix (Prefix'First .. Last) & "~";
            end if;
         end;
      end if;
   end Truncate_With_Ellipsis;

   function Layout_Command_Row
     (Row_Width_Columns : Natural;
      Label_Length      : Natural;
      Secondary_Length  : Natural;
      Keybinding_Length : Natural;
      Is_Selected       : Boolean;
      Is_Available      : Boolean) return Command_Palette_Row_Layout
   is
      pragma Unreferenced (Is_Available);
      Result : Command_Palette_Row_Layout;
      Binding_Gap : constant Natural := 2;
      Secondary_Gap : constant Natural := 3;
      Main_Columns : Natural := Row_Width_Columns;
      Wants_Secondary : constant Boolean := Is_Selected and then Secondary_Length > 0;
   begin
      if Row_Width_Columns = 0 then
         return Result;
      end if;

      Result.Show_Keybinding :=
        Keybinding_Length > 0
        and then Row_Width_Columns >= Keybinding_Length + Binding_Gap + 2;

      if Result.Show_Keybinding then
         Result.Keybinding_Start_Column := Row_Width_Columns - Keybinding_Length;
         Result.Keybinding_Column := Result.Keybinding_Start_Column;
         Result.Keybinding_Columns := Keybinding_Length;
         Main_Columns := Result.Keybinding_Start_Column - Binding_Gap;
      end if;

      Result.Label_Start_Column := 0;

      if Main_Columns = 0 then
         return Result;
      end if;

      if Wants_Secondary and then Main_Columns > Secondary_Gap + 1 then
         declare
            Full_Label_With_Gap : constant Natural := Label_Length + Secondary_Gap;
            Minimum_Label       : constant Natural :=
              (if Label_Length = 0 then 0 else 1);
         begin
            Result.Show_Secondary := True;

            if Full_Label_With_Gap + Secondary_Length <= Main_Columns then
               Result.Label_Columns := Label_Length;
               Result.Secondary_Start_Column := Full_Label_With_Gap;
               Result.Secondary_Columns := Secondary_Length;
            elsif Label_Length + Secondary_Gap < Main_Columns then
               Result.Label_Columns := Label_Length;
               Result.Secondary_Start_Column := Full_Label_With_Gap;
               Result.Secondary_Columns := Main_Columns - Full_Label_With_Gap;
            else
               Result.Label_Columns :=
                 Natural'Max
                   (Minimum_Label,
                    Natural'Min
                      (Label_Length,
                       Main_Columns - Secondary_Gap - 1));
               Result.Secondary_Start_Column :=
                 Result.Label_Columns + Secondary_Gap;
               Result.Secondary_Columns :=
                 Main_Columns - Result.Secondary_Start_Column;
            end if;

            if Result.Secondary_Columns = 0 then
               Result.Show_Secondary := False;
               Result.Secondary_Start_Column := 0;
               Result.Label_Columns := Natural'Min (Label_Length, Main_Columns);
            end if;
         end;
      else
         Result.Label_Columns := Natural'Min (Label_Length, Main_Columns);
      end if;

      return Result;
   end Layout_Command_Row;

   function Project_Command_Row_Layout
     (Candidate   : Editor.Commands.Palette_Model.Command_Palette_Candidate;
      Is_Selected : Boolean;
      Row_Columns : Natural) return Command_Palette_Row_Layout
   is
      Label_Text : constant String := To_String (Candidate.Label);
      Binding_Text : constant String :=
        (if Candidate.Has_Keybinding
         then To_String (Candidate.Keybinding_Display)
         else "");
      Secondary_Text : constant String :=
        (if Is_Selected and then not Candidate.Available
         then (if Length (Candidate.Reason) > 0
               then To_String (Candidate.Reason)
               else "Command not available here")
         elsif Is_Selected and then Candidate.Available
            and then Length (Candidate.Description) > 0
         then To_String (Candidate.Description)
         else "");
      Result : Command_Palette_Row_Layout :=
        Layout_Command_Row
          (Row_Width_Columns => Row_Columns,
           Label_Length      => Label_Text'Length,
           Secondary_Length  => Secondary_Text'Length,
           Keybinding_Length => Binding_Text'Length,
           Is_Selected       => Is_Selected,
           Is_Available      => Candidate.Available);
      Main : Unbounded_String := Null_Unbounded_String;
   begin
      if Result.Label_Columns > 0 then
         Main := To_Unbounded_String
           (Truncate_With_Ellipsis (Label_Text, Result.Label_Columns));
      end if;

      if Result.Show_Secondary then
         Main := Main & " - "
           & Truncate_With_Ellipsis (Secondary_Text, Result.Secondary_Columns);
      end if;

      Result.Visible_Text := Main;
      if Result.Show_Keybinding then
         Result.Keybinding_Text := To_Unbounded_String (Binding_Text);
      end if;

      return Result;
   end Project_Command_Row_Layout;

end Editor.Command_Palette.Rows;
