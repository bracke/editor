with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_Editing is

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
         when Command_Insert_Newline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Insert Newline",
               Description => "",
               Category    => Edit_Category,
               Visibility  => Hidden_Command);
         when Command_Undo =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Undo",
               Description => "Undo the most recent text edit in the current buffer.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Redo =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Redo",
               Description => "Redo the most recently undone text edit in the current buffer.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Edit_History_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Edit History",
               Description => "Clear undo and redo history for the current buffer.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Copy =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Copy",
               Description => "Copy the active selected text into the editor clipboard",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Cut =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cut",
               Description => "Cut the active selected text into the editor clipboard",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Paste =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Paste",
               Description => "Paste editor clipboard text into the active buffer",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Clipboard_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Clipboard",
               Description => "Clear the editor clipboard.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Selection_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selection",
               Description => "Clear the current text selection.",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Line_Delete =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Line",
               Description => "Delete the current logical line in the active buffer",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Duplicate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Duplicate Line",
               Description => "Duplicate the current logical line below itself",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Line Up",
               Description => "Move the current logical line one line upward",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Line Down",
               Description => "Move the current logical line one line downward",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Indent_Increase =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Indent Line",
               Description => "Increase indentation of the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Indent_Decrease =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Outdent Line",
               Description => "Decrease indentation of the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Comment_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Comment Line",
               Description => "Insert the canonical line comment marker on the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Uncomment_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Uncomment Line",
               Description => "Remove the canonical line comment marker from the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Line_Comment =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Line Comment",
               Description => "Toggle the canonical line comment marker on the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Join_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Join Line With Next",
               Description => "Join the current logical line with the following logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Split_At_Caret =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Split Line At Caret",
               Description => "Split the current logical line at the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Trim_Trailing_Whitespace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Trim Trailing Whitespace",
               Description => "Remove trailing spaces and tabs from the active buffer",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Format_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Format Buffer",
               Description => "Apply the explicit buffer formatting action to the active buffer.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Format_Selected_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Format Selection",
               Description => "Apply the explicit selection formatting action to selected logical lines.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Char_Delete_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Previous Character",
               Description => "Delete the character before the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Char_Delete_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Next Character",
               Description => "Delete the character after the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Word_Delete_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Previous Word",
               Description => "Delete the word-like text before the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Word_Delete_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Next Word",
               Description => "Delete the word-like text after the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Selection_Delete =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Selection",
               Description => "Delete the active selected text from the active buffer",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when others =>
            raise Program_Error with "command is not owned by Descriptor_Editing";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_Editing;
