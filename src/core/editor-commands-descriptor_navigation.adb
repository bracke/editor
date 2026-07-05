with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_Navigation is

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
         when Command_Move_Left =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Left",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Right =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Right",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Up",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Down",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Line_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Line Start",
               Description => "Move to the start of the current line",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Move_Line_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Line End",
               Description => "Move to the end of the current line",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Move_Document_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Document Start",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Document_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Document End",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Word_Left =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Word Left",
               Description => "Move the caret to the previous word boundary",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Move_Word_Right =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Word Right",
               Description => "Move the caret to the next word boundary",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Page Up",
               Description => "Move up by one viewport page",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Page Down",
               Description => "Move down by one viewport page",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Select_Left =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Left",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Right =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Right",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Up",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Down",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Word_Left =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Extend Selection Word Left",
               Description => "Selection: extend to the previous word boundary",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Select_Word_Right =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Extend Selection Word Right",
               Description => "Selection: extend to the next word boundary",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Select_Word =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Word",
               Description => "Selection: select the word or symbol run at the caret",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Select_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Line",
               Description => "Selection: select the current full line",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Start_Rectangular_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Start Rectangular Selection",
               Description => "Selection: start a grid-cell rectangular selection at the caret",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Rectangular_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Rectangular Selection",
               Description => "Selection: clear the active rectangular selection",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Extend_Selection_Line_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Extend Selection Line Up",
               Description => "Selection: extend upward by one full line",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Extend_Selection_Line_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Extend Selection Line Down",
               Description => "Selection: extend downward by one full line",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Select_Line_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Line Start",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Line_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Line End",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Document_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Document Start",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Document_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Document End",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Page Up",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Page Down",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select All",
               Description => "Select all text in the current buffer.",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Move_Buffer_File =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Move Buffer File",
               Description   => "Move the active clean file-backed buffer's backing file to an explicit path and update the active association after success",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Select_Next_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Recent Project",
               Description => "Move Recent Projects selection to the next entry",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Previous_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Recent Project",
               Description => "Move Recent Projects selection to the previous entry",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Navigation_Back =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Navigation Back",
               Description => "Return to the previous editor navigation location",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Navigation_Forward =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Navigation Forward",
               Description => "Move to the next editor navigation location",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Navigation_History_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Navigation History",
               Description => "Clear the session navigation back and forward stacks",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Move_Project_Search_Selection_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Up",
               Description => "Move the Project Search selection up without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Project_Search_Selection_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Down",
               Description => "Move the Project Search selection down without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Current_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Current Outline Symbol",
               Description => "Select the current outline symbol tracked from the active editor cursor.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Select_Next_Outline_Item =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Outline Symbol",
               Description => "Move outline selection to the next selectable symbol row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Select_Previous_Outline_Item =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Outline Symbol",
               Description => "Move outline selection to the previous selectable symbol row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when others =>
            raise Program_Error with "command is not owned by Descriptor_Navigation";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_Navigation;
