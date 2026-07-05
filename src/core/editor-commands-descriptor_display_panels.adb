with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_Display_Panels is

   function Make_Descriptor
     (Id          : Command_Id;
      Name        : String;
      Description : String;
      Category    : Command_Category;
      Visibility  : Command_Visibility) return Command_Descriptor
   is
      Effective_Description : constant String :=
        (if Id = No_Command then Description
         elsif Description'Length = 0 then "Execute " & Name & "."
         else Description);
   begin
      return Descriptor_Factory.Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Command_Name (Id),
         Label         => Name,
         Description   => Effective_Description,
         Category      => Category,
         Visible       => Visibility = Palette_Command,
         Bindable      => Id /= No_Command
           and then not Is_Public_Build_Command (Id),
         Destructive   => Is_Destructive_Command (Id),
         Lifecycle     => Is_Lifecycle_Command (Id),
         Configuration => Is_Configuration_Command (Id));
   end Make_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      case Id is
         when Command_Toggle_Format_On_Save =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Format On Save",
               Description => "Toggle automatic formatting before file saves.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Theme =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Theme",
               Description => "Switch between available editor themes.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Theme_Light =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Theme Light",
               Description => "Use the light editor theme.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Theme_Dark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Theme Dark",
               Description => "Use the dark editor theme.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Minimap =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Minimap",
               Description => "Show or hide the minimap.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Scrollbars =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Scrollbars",
               Description => "Show or hide editor scrollbars.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Line Numbers",
               Description => "Show or hide gutter line numbers",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Line_Number_Mode =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Line Number Mode",
               Description => "Cycle the editor line-number display mode.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Absolute_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Absolute Line Numbers",
               Description => "Show absolute document line numbers",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Set_Relative_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Relative Line Numbers",
               Description => "Show relative distances in the gutter",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Set_Hybrid_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hybrid Line Numbers",
               Description => "Show the current line as absolute and other lines as relative",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Current_Line_Highlight =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Current Line Highlight",
               Description => "Show or hide the current-line highlights",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Cursor_Blink =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Cursor Blink",
               Description => "Enable or disable cursor blinking.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Syntax_Colouring =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Syntax Colouring",
               Description => "Enable or disable syntax colouring",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Diagnostics =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Diagnostics",
               Description => "Show or hide diagnostic decorations",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Problems_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Problems",
               Description => "Show or hide the Problems panel",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Cursor_Style =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Cursor Style",
               Description => "Cycle cursor style",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Editor_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Editor",
               Description => "Return keyboard focus to editor text",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Search_Results =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Project Search Results",
               Description => "Focus Project Search results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Problems =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Problems",
               Description => "Move keyboard focus to the Problems panel",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Bottom_Panel_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Bottom Panel Focus",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Problems_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Problem Selection Up",
               Description => "Move the focused Problems selection up",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Problem Selection Down",
               Description => "Move the focused Problems selection down",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Page Up",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Problems_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Page Down",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Problems_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Problem",
               Description => "Open the currently selected Problems row",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show All Problems",
               Description => "Clear the Problems severity filter.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Problem Errors",
               Description => "Filter the Problems panel to errors.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Problem Warnings",
               Description => "Filter the Problems panel to warnings.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Problem Info",
               Description => "Filter the Problems panel to info diagnostics.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_Hints =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Problem Hints",
               Description => "Filter the Problems panel to hints.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Sort_By_Location =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Problems by Location",
               Description => "Sort Problems rows by source location.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Sort_By_Severity =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Problems by Severity",
               Description => "Sort Problems rows by diagnostic severity.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Sort_By_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Problems by Source",
               Description => "Sort Problems rows by source file.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Group_By_Severity =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Group Problems by Severity",
               Description => "Group Problems review rows by diagnostic severity.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Group_By_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Group Problems by Source",
               Description => "Group Problems review rows by source file.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Focus_Editor =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Focus Editor",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when others =>
            raise Program_Error with "command is not owned by Descriptor_Display_Panels";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_Display_Panels;
