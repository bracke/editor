with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Commands.Descriptor_Metadata is

   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor
   is
      pragma Unreferenced (Stable_Name);
   begin
      return
        (Id            => Id,
         Name          => To_Unbounded_String (Label),
         Description   => To_Unbounded_String (Description),
         Category      => Category,
         Visibility    => (if Visible then Palette_Command else Hidden_Command),
         Bindable      => Bindable,
         Destructive   => Destructive,
         Lifecycle     => Lifecycle,
         Configuration => Configuration,
         Summary       => To_Unbounded_String (Command_Summary (Id)),
         Availability_Summary => To_Unbounded_String (Command_Availability_Summary (Id)),
         Mutation_Summary => To_Unbounded_String (Command_Mutation_Summary (Id)),
         Filesystem_Effect_Summary => To_Unbounded_String (Command_Filesystem_Effect_Summary (Id)),
         State_Preservation_Summary => To_Unbounded_String (Command_State_Preservation_Summary (Id)),
         Non_Goal_Summary => To_Unbounded_String (Command_Non_Goal_Summary (Id)),
         Requires_Explicit_Target => Command_Requires_Explicit_Target (Id),
         Target_Prompt_Capable => Command_Is_Target_Prompt_Capable (Id),
         Target_Prompt_Label => To_Unbounded_String (Command_Target_Prompt_Label (Id)),
         Family        => Command_Family (Id),
         Effect_Classification => Command_Effect_Classification (Id));
   end Make_Command_Descriptor;

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
      return Make_Command_Descriptor
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
         when No_Command =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "No Command",
               Description => "",
               Category    => Internal_Category,
               Visibility  => Hidden_Command);
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
         when Command_Select_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select All",
               Description => "Select all text in the current buffer.",
               Category    => Selection_Category,
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
         when Command_Toggle_Format_On_Save =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Format On Save",
               Description => "Toggle automatic formatting before file saves.",
               Category    => Settings_Category,
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
         when Command_Save_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save File",
               Description => "Save the active buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Save_File_As =>
            --  target acquisition is canonical, so Save As is
            --  projected and bindable through the transient file-target prompt.
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Save File As",
               Description   => "Save the current buffer to an explicit path.",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Reload_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload File",
               Description => "Reload the active clean file-backed buffer from disk; dirty buffers are blocked.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Revert_Active_Buffer =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Revert File",
               Description   => "Discard unsaved changes in the active file-backed buffer by rereading disk contents",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_File_Conflict_Keep_Buffer =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Keep Buffer Changes",
               Description   => "Dismiss the active file conflict without reading or writing",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => False,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Reload_From_Disk =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Reload Conflict From Disk",
               Description   => "Replace the conflicted buffer from disk after explicit confirmation",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => True,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Overwrite_Disk =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Overwrite Disk From Buffer",
               Description   => "Overwrite the conflicted backing file with current buffer text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => True,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Cancel =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Cancel File Conflict",
               Description   => "Cancel the active file conflict prompt and preserve buffer text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => False,
               Lifecycle     => True,
               Configuration => False);
         when Command_Rename_Buffer_File =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Rename Buffer File",
               Description   => "Rename the active clean file-backed buffer's backing file to an explicit path",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Delete_Buffer_File =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Delete Buffer File",
               Description   => "Delete the active clean file-backed buffer's backing file and keep the buffer open as unsaved text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Copy_Buffer_File =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Copy Buffer File",
               Description   => "Copy the active clean file-backed buffer's backing file to an explicit path without changing the active association",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Move_Buffer_File =>
            return Make_Command_Descriptor
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
         when Command_Open_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Quick Open",
               Description => "Show project files and filter them by path.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Close_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Quick Open",
               Description => "Hide the Quick Open panel.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Toggle_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Quick Open",
               Description => "Show or hide the Quick Open panel.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Accept_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Quick Open Result",
               Description => "Open or activate the selected Quick Open file.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Next_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Quick Open Result",
               Description => "Select the next visible Quick Open result.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Previous_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Quick Open Result",
               Description => "Select the previous visible Quick Open result.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Quick Open Query",
                  Description => "Replace the Quick Open query with literal text.",
                  Category    => Project_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Quick_Open_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Query",
               Description => "Clear the Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Quick Open File Kind",
               Description => "Cycle Quick Open to the next file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Quick Open File Kind",
               Description => "Cycle Quick Open to the previous file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open File Kind",
               Description => "Clear the Quick Open file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Quick Open Scope",
                  Description => "Set the Quick Open project-relative path scope.",
                  Category    => Project_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Quick_Open_Scope_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Scope",
               Description => "Clear the Quick Open path scope.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_From_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Quick Open to Selected Directory",
               Description => "Scope Quick Open to the selected file directory.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_Parent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Quick Open Parent Scope",
               Description => "Move Quick Open scope to the parent directory.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Reveal_Active =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active File in Quick Open",
               Description => "Show Quick Open with the active project file selected.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Scope_Active_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Quick Open to Active Directory",
               Description => "Show Quick Open scoped to the active file directory.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Create_From_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File from Quick Open Query",
               Description => "Create an empty project file from the current Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Create_With_Parents_From_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File with Parent Directories from Quick Open Query",
               Description => "Create missing parent directories and an empty project file from the current Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Priority_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Quick Open Recent Priority",
               Description => "Toggle Quick Open between path ordering and recent-file priority ordering.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Priority_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Priority",
               Description => "Restore Quick Open to deterministic path ordering.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Open_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Open Buffer List",
               Description => "Inspect and switch among currently open buffers",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Close_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Open Buffer List",
               Description => "Hide the open-buffer list",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Accept_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch To Selected Buffer",
               Description => "Switch to the selected open buffer-list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Next_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Buffer List Row",
               Description => "Select the next open-buffer list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Previous_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Buffer List Row",
               Description => "Select the previous open-buffer list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Open Buffer List Filter",
               Description => "Clear the active open-buffer list filter.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Pinned =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List to Pinned Buffers",
               Description => "Show only pinned open buffers in the Open Buffer List.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List by Group",
               Description => "Show only open buffers in the named session-local group.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List by Label",
               Description => "Show only open buffers with the named session-local label.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Noted =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List to Noted Buffers",
               Description => "Show only open buffers that have session-local notes.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Default =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List Default",
               Description => "Use the default Open Buffer List order.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Recent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Recent",
               Description => "Order Open Buffer List rows by recent activation.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Name =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Name",
               Description => "Order Open Buffer List rows by display name.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Pinned =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List Pinned First",
               Description => "Order pinned open buffers before unpinned buffers in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Group",
               Description => "Order grouped open buffers by group name in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Label",
               Description => "Order labeled open buffers by label text in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Open Buffer List Sort",
               Description => "Cycle to the next Open Buffer List sort mode.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Open Buffer List Sort",
               Description => "Cycle to the previous Open Buffer List sort mode.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Close =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Selected Buffer List Row",
               Description => "Close the selected open buffer from the buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Pin Selected Open Buffer",
               Description => "Pin the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Unpin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Unpin Selected Open Buffer",
               Description => "Unpin the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Toggle_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Selected Open Buffer Pin",
               Description => "Toggle pin state for the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Group_Assign =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Selected Open Buffer Group",
               Description => "Assign the selected open buffer to a session-local group from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Group_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Group",
               Description => "Clear the selected open buffer group from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Label_Set =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Selected Open Buffer Label",
               Description => "Set the selected open buffer label from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Label_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Label",
               Description => "Clear the selected open buffer label from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Note_Set =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Selected Open Buffer Note",
               Description => "Set the selected open buffer note from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Note_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Note",
               Description => "Clear the selected open buffer note from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Open Buffer List Preview",
               Description => "Show or hide the selected open-buffer preview in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Open Buffer List Preview",
               Description => "Show a compact read-only preview for the selected open buffer.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Open Buffer List Preview",
               Description => "Hide the selected open-buffer preview in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Next_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Buffer List Preview Next Line",
               Description => "Scroll the selected-buffer preview down by one line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Previous_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Buffer List Preview Previous Line",
               Description => "Scroll the selected-buffer preview up by one line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Center_Cursor =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Center Open Buffer List Preview on Cursor",
               Description => "Return the selected-buffer preview to that buffer's cursor line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Mark_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Selected Buffer Mark", Description => "Mark or unmark the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Set =>
            return Make_Descriptor (Id => Id, Name => "Mark Selected Open Buffer", Description => "Mark the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear =>
            return Make_Descriptor (Id => Id, Name => "Unmark Selected Open Buffer", Description => "Clear the mark from the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_All =>
            return Make_Descriptor (Id => Id, Name => "Clear Open Buffer List Marks", Description => "Clear all temporary Open Buffer List marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Invert_Visible =>
            return Make_Descriptor (Id => Id, Name => "Invert Visible Open Buffer List Marks", Description => "Invert marks for the currently visible open-buffer rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Visible =>
            return Make_Descriptor (Id => Id, Name => "Mark Visible Open Buffers", Description => "Mark all currently visible open-buffer list rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_Visible =>
            return Make_Descriptor (Id => Id, Name => "Clear Visible Buffer Marks", Description => "Clear marks from currently visible open-buffer list rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Pinned =>
            return Make_Descriptor (Id => Id, Name => "Mark Pinned Open Buffers", Description => "Mark all currently open pinned buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group =>
            return Make_Descriptor (Id => Id, Name => "Mark Open Buffers by Group", Description => "Mark all currently open buffers in a session-local group.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label =>
            return Make_Descriptor (Id => Id, Name => "Mark Open Buffers by Label", Description => "Mark all currently open buffers with a session-local label.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Noted =>
            return Make_Descriptor (Id => Id, Name => "Mark Noted Open Buffers", Description => "Mark all currently open buffers that have session-local notes.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Close_Marked =>
            return Make_Descriptor (Id => Id, Name => "Prepare Close Marked Open Buffers", Description => "Prepare confirmation for closing all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Confirm =>
            return Make_Descriptor (Id => Id, Name => "Confirm Marked Buffer Action", Description => "Confirm the pending marked buffer action.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Marked Buffer Action", Description => "Cancel the pending marked buffer action without mutation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Pin_Marked =>
            return Make_Descriptor (Id => Id, Name => "Pin Marked Open Buffers", Description => "Pin all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Unpin_Marked =>
            return Make_Descriptor (Id => Id, Name => "Unpin Marked Open Buffers", Description => "Unpin all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_Metadata =>
            return Make_Descriptor (Id => Id, Name => "Clear Marked Buffer Details", Description => "Clear group, label, and note details from all marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group_Assign =>
            return Make_Descriptor (Id => Id, Name => "Assign Group to Marked Open Buffers", Description => "Assign a group to all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Group from Marked Open Buffers", Description => "Clear group names from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label_Set =>
            return Make_Descriptor (Id => Id, Name => "Set Label on Marked Open Buffers", Description => "Set a label on all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Label from Marked Open Buffers", Description => "Clear labels from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Note_Set =>
            return Make_Descriptor (Id => Id, Name => "Set Note on Marked Open Buffers", Description => "Set a note on all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Note_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Note from Marked Open Buffers", Description => "Clear notes from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Marked Buffer Review", Description => "Show or hide a marked-only review view in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Marked Buffer Review", Description => "Show only currently marked open buffers in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Marked Buffer Review", Description => "Return the open-buffer list to its normal view.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Pending Marked Close Review", Description => "Show or hide the captured pending marked-close target review in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Pending Marked Close Review", Description => "Show captured pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Pending Marked Close Review", Description => "Hide pending marked-close target review without cancelling the pending action.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Pending Marked Close Target", Description => "Move open-buffer list selection to the next captured pending close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Pending Marked Close Target", Description => "Move open-buffer list selection to the previous captured pending close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Pending Marked Close", Description => "Report captured and still-open pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Pending Marked Close Target", Description => "Remove the selected buffer from the captured pending marked-close targets without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Pruned Pending Marked Close Target", Description => "Restore the most recently pruned pending marked-close target without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Pruned Pending Marked Close Targets", Description => "Report pruned pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Pruned Pending Marked Close Target", Description => "Move open-buffer list selection to the next still-open pruned pending marked-close target without restoring it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Pruned Pending Marked Close Target", Description => "Move open-buffer list selection to the previous still-open pruned pending marked-close target without restoring it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Pruned Pending Marked Close Review", Description => "Show or hide pruned pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Pruned Pending Marked Close Review", Description => "Show still-open pruned pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Pruned Pending Marked Close Review", Description => "Hide pruned pending marked-close target review without restoring targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            return Make_Descriptor (Id => Id, Name => "Restore Selected Pruned Pending Marked Close Target", Description => "Restore the selected still-open pruned pending marked-close target without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Pending Marked Close Targets", Description => "Report dirty still-open pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Pending Marked Close Target", Description => "Move open-buffer list selection to the next dirty pending marked-close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Pending Marked Close Target", Description => "Move open-buffer list selection to the previous dirty pending marked-close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Pending Marked Close Target", Description => "Remove the selected dirty pending marked-close target without closing, saving, discarding, or changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview =>
            return Make_Descriptor (Id => Id, Name => "Prepare Dirty Pending Marked Close Prune", Description => "Capture all currently dirty pending marked-close targets for explicit bulk pruning.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply =>
            return Make_Descriptor (Id => Id, Name => "Prepare Dirty Prune Apply Confirmation", Description => "Capture the current dirty-prune preview targets for explicit apply confirmation without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm =>
            return Make_Descriptor (Id => Id, Name => "Confirm Dirty Prune Apply", Description => "Confirm and prune captured dirty-prune apply targets that are still open, pending, and dirty.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Dirty Prune Apply Confirmation", Description => "Clear the pending dirty-prune apply confirmation without mutating preview or pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Prune Apply Targets", Description => "Report captured and still-applicable dirty-prune apply confirmation targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Prune Apply Target", Description => "Move open-buffer list selection to the next captured dirty-prune apply target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Prune Apply Target", Description => "Move open-buffer list selection to the previous captured dirty-prune apply target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Dirty Prune Apply Review", Description => "Toggle review of captured dirty-prune apply targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Dirty Prune Apply Review", Description => "Show captured dirty-prune apply targets in the Open Buffer List without confirming them.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Dirty Prune Apply Review", Description => "Return the open-buffer list to its normal view without clearing dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Prune Apply Target", Description => "Remove the selected buffer from dirty-prune apply confirmation without mutating the preview or pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Removed Dirty Prune Apply Target", Description => "Restore the most recently removed buffer to dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Removed Dirty Prune Apply Targets", Description => "Report targets removed from the current dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Removed Dirty Prune Apply Target", Description => "Move open-buffer list selection to the next still-open target removed from dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Removed Dirty Prune Apply Target", Description => "Move open-buffer list selection to the previous still-open target removed from dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale =>
            return Make_Descriptor (Id => Id, Name => "Clear Stale Dirty Prune Apply Targets", Description => "Remove stale targets from dirty-prune apply confirmation without recording removals or pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Stale Dirty Prune Apply Targets", Description => "Report stale targets in the pending dirty-prune apply confirmation without mutating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Dirty Pending Marked Close Prune", Description => "Clear the prepared dirty pending marked-close prune without mutation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Pending Marked Close Prune", Description => "Report captured and still-applicable dirty pending marked-close prune targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Prune Preview Target", Description => "Move open-buffer list selection to the next captured dirty-prune preview target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Prune Preview Target", Description => "Move open-buffer list selection to the previous captured dirty-prune preview target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Dirty Prune Preview Review", Description => "Toggle review of captured dirty-prune preview targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Dirty Prune Preview Review", Description => "Show captured dirty-prune preview targets in the Open Buffer List without applying them.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Dirty Prune Preview Review", Description => "Return the open-buffer list to its normal view without clearing the dirty-prune preview.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Prune Preview Target", Description => "Remove the selected buffer from the prepared dirty-prune preview without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Removed Dirty Prune Preview Target", Description => "Restore the most recently removed buffer to the prepared dirty-prune preview without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Removed Dirty Prune Preview Targets", Description => "Report dirty-prune preview targets removed from the current prepared preview.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Removed Dirty Prune Preview Target", Description => "Move open-buffer list selection to the next still-open target removed from the dirty-prune preview without restoring or activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Removed Dirty Prune Preview Target", Description => "Move open-buffer list selection to the previous still-open target removed from the dirty-prune preview without restoring or activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale =>
            return Make_Descriptor (Id => Id, Name => "Clear Stale Dirty Prune Preview Targets", Description => "Remove stale targets from the prepared dirty-prune preview without pruning active pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Stale Dirty Prune Preview Targets", Description => "Report stale targets in the prepared dirty-prune preview without mutating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Marked Open Buffer", Description => "Move the open-buffer list selection to the next marked candidate without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Marked Open Buffer", Description => "Move the open-buffer list selection to the previous marked candidate without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Buffer Marks", Description => "Report the current count of marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Open_Command_Palette =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Command Palette",
               Description => "Open the command palette overlay for command discovery and execution.",
               Category    => Overlay_Category,
               Visibility  => Hidden_Command);
         when Command_Palette_Show_Command_Help =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Command Help",
               Description => "Toggle display-only help for the selected command palette command without executing it.",
               Category    => Overlay_Category,
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
         when Command_Cancel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel",
               Description => "",
               Category    => Overlay_Category,
               Visibility  => Hidden_Command);
         when Command_Open_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open File",
               Description => "Open a file",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Open_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Project",
               Description => "Open a folder as the current project",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Project",
               Description => "Switch explicitly to another project after any required dirty-buffer review.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Show_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Recent Projects",
               Description => "Show known project roots",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Open_Selected_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Recent Project",
               Description => "Open the selected recent project",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Clear_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Recent Projects",
               Description => "Forget the list of recent project roots",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Remove_Selected_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Selected Recent Project",
               Description => "Forget the selected recent project",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Remove_Missing_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Missing Recent Projects",
               Description => "Forget recent projects whose paths are unavailable",
               Category    => Project_Category,
               Visibility  => Palette_Command);
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
         when Command_Close_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Project",
               Description => "Close the current project and project-scoped UI state; does not delete project files.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Context",
               Description => "Clear the current project root and project-scoped UI state.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Refresh_File_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh File Tree",
               Description => "Refresh the project File Tree.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Refresh_Project_Files =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Project Files",
               Description => "Refresh the project file list for Quick Open.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Project_Files_Summary =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Files Summary",
               Description => "Show the current project file count.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Reveal_Active_File_In_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active File in File Tree",
               Description => "Select the active file in the project File Tree without opening files.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_New_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "New Buffer",
               Description => "Create a new untitled buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Buffer",
               Description => "Close the active buffer; dirty buffers open a save/discard/cancel review.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Confirm_Close_Save =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Close: Save",
               Description => "Save dirty file-backed close candidates, then close only successfully saved buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Confirm_Close_Discard =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Close: Discard",
               Description => "Explicitly discard dirty close candidates without deleting backing files.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Cancel_Close =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Close",
               Description => "Cancel the active dirty-buffer close review without mutating buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Reopen_Closed_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reopen Closed Buffer",
               Description => "Reopen the most recently closed clean file-backed buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_Other_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Other Buffers",
               Description => "Close every non-active clean buffer and leave dirty buffers open.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_All_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close All Buffers",
               Description => "Close all buffers, requiring explicit confirmation when dirty buffers would be discarded.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_All_Clean_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close All Clean Buffers",
               Description => "Close clean buffers while leaving dirty buffers open.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Pin_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Pin Buffer",
               Description => "Mark the active buffer as pinned for this session.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Unpin_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Unpin Buffer",
               Description => "Clear the active buffer pinned marker.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Buffer_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Buffer Pin",
               Description => "Toggle the active buffer pinned state.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Set_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Buffer Label",
               Description => "Set or replace the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Label",
               Description => "Clear the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Edit_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Edit Buffer Label",
               Description => "Edit the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Buffer Label",
               Description => "Show the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Set_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Buffer Note",
               Description => "Set or replace the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Note",
               Description => "Clear the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Edit_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Edit Buffer Note",
               Description => "Edit the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Buffer Note",
               Description => "Show the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Assign_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Buffer Group",
               Description => "Assign the active buffer to a session-local group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Group",
               Description => "Remove the active buffer from its session-local group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Buffer Group",
               Description => "Switch the active buffer group filter by name.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Next_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Buffer Group",
               Description => "Cycle to the next existing buffer group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Buffer Group",
               Description => "Cycle to the previous existing buffer group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_All_Buffer_Groups =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show All Buffer Groups",
               Description => "Clear the active buffer group filter and show all open buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Cancel_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Pending Transition",
               Description => "Cancel the blocked operation without saving or discarding files.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Retry_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Retry Pending Transition",
               Description => "Retry the blocked operation after unsaved changes are resolved.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Discard_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Discard and Continue Pending Transition",
               Description => "Explicitly discard affected dirty buffers and continue the blocked project operation.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Next_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Buffer",
               Description => "Switch to the next open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Buffer",
               Description => "Switch to the previous open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Recent_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Recent Buffer",
               Description => "Switch to the most recently used non-active open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Next_Recent_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Recent Buffer",
               Description => "Move forward through recent-buffer traversal",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Buffer",
               Description => "",
               Category    => File_Category,
               Visibility  => Hidden_Command);
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
         when Command_Next_Diagnostic =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Diagnostic",
               Description => "Jump to the next diagnostic",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Diagnostic =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Diagnostic",
               Description => "Jump to the previous diagnostic",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Bookmark",
               Description => "Bookmarks: toggle a bookmark on the current row",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Next_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Bookmark",
               Description => "Bookmarks: jump to the next bookmark",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Bookmark",
               Description => "Bookmarks: jump to the previous bookmark",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Bookmarks =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Bookmarks",
               Description => "Bookmarks: clear bookmarks in the active buffer",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Clear_All_Bookmarks =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear All Bookmarks",
               Description => "Bookmarks: clear bookmarks in all open buffers",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Toggle_Current_Location =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmark: Toggle Current Location",
               Description => "Toggle a session-local bookmark at the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Clear_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Clear All",
               Description => "Clear all session-local bookmarks",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Next",
               Description => "Select the next bookmark row without opening a file",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Previous",
               Description => "Select the previous bookmark row without opening a file",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Goto_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Go To Next",
               Description => "Open the next bookmark after the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Goto_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Go To Previous",
               Description => "Open the previous bookmark before the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Open Selected",
               Description => "Open the selected bookmark through the existing file-open path",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Reveal_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Reveal Current",
               Description => "Select the bookmark nearest to the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Remove_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Remove Selected",
               Description => "Remove the selected session-local bookmark row",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Show",
               Description => "Show the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Hide",
               Description => "Hide the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Hidden_Command);
         when Command_Bookmark_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Toggle",
               Description => "Toggle the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Cursor_Style =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Cursor Style",
               Description => "Cycle cursor style",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Line",
               Description => "Show a line-number input for jumping in the active buffer",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Go to Line",
               Description => "Toggle the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Prefill_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Current Line",
               Description => "Prefill the go-to-line input from the active caret line",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Go to Line Query",
                  Description => "Replace the go-to-line input with the entered line number",
                  Category    => Navigation_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Goto_Line_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Go to Line Query",
               Description => "Clear the go-to-line input",
               Category    => Navigation_Category,
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
         when Command_Close_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Go to Line",
               Description => "Close the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Accept_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Accept Go to Line",
               Description => "Jump to the line entered in the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Find_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find",
               Description => "Show a literal find prompt for the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Find",
               Description => "Hide Find and clear the current find text",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Find_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find",
               Description => "Toggle the Find prompt for the current buffer.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Find Query",
                  Description => "Replace the Find text for the active buffer",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Find_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Query",
               Description => "Clear the Find text for the active buffer",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Find_Case_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find Case Sensitivity",
               Description => "Toggle Find between case-insensitive and case-sensitive matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Case_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Case Sensitivity",
               Description => "Reset Find to case-insensitive matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Whole_Word_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find Whole Word",
               Description => "Toggle Find between substring and whole-word matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Whole_Word_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Whole Word",
               Description => "Reset Find to substring matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_From_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find from Selection",
               Description => "Use the active single-line selection as the Find text",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_From_Active_Word =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find from Active Word",
               Description => "Use the word under the primary caret as the Find text",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Active_Find_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Next in Active Buffer",
               Description => "Move to the next literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Active_Find_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Previous in Active Buffer",
               Description => "Move to the previous literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_First =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find First in Active Buffer",
               Description => "Move to the first literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Last =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Last in Active Buffer",
               Description => "Move to the last literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Reveal_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Current Find Match",
               Description => "Select the Find match at or after the current caret without moving the caret",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Replace_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Replace", Description => "Show the literal Replace field attached to Find", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Replace", Description => "Hide Replace and clear the replacement text", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Replace_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Replace", Description => "Toggle the Replace field", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_Text_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor (Id => Id, Name => "Set Replace Text", Description => "Set the literal replacement text", Category => Search_Category, Visibility => Hidden_Command);
            begin
               D.Bindable := False; return D;
            end;
         when Command_Replace_Text_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Replace Text", Description => "Clear the literal replacement text", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Replace_Current =>
            return Make_Descriptor (Id => Id, Name => "Replace Current Find Match", Description => "Replace the selected Find match with literal replacement text", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_All =>
            return Make_Descriptor (Id => Id, Name => "Replace All Find Matches", Description => "Replace every current Find match with literal replacement text", Category => Search_Category, Visibility => Palette_Command);
         when Command_Goto_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Goto Start",
               Description => "Move to document start",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Goto End",
               Description => "Move to document end",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Run_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project",
               Description => "Search known project files for the current query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Rerun_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Rerun Project Search",
               Description => "Rerun the current Project Search query.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Open_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search",
               Description => "Show Project Search.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search",
               Description => "Toggle Project Search.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Close_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Project Search",
               Description => "Hide Project Search without changing files.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Run_Project_Search_From_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Project Search Query",
               Description => "Set the Project Search query from the active input and run search.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_From_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project for Selection",
               Description => "Search Project for the active single-line selection.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_From_Active_Word =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project for Active Word",
               Description => "Search Project for the word under the primary caret.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Active_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Active Directory",
               Description => "Search the active file directory for the active selection or word.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Query",
               Description => "Clear the Project Search query, replacement text, and retained results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Open_Selected_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Project Search Result",
               Description => "Open the selected project search result.",
               Category    => Search_Category,
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
         when Command_Next_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Project Search Result",
               Description => "Move to the next Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Project Search Result",
               Description => "Move to the previous Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_First_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "First Project Search Result",
               Description => "Select the first Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Last_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Last Project Search Result",
               Description => "Select the last Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Reveal_Active_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active Project Search Result",
               Description => "Reveal the active buffer in Project Search results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Scope_Selected_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Project Search to Selected Directory",
               Description => "Scope Project Search to the selected result's directory.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Project Search Kind Filter",
               Description => "Select the next Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Project Search Kind Filter",
               Description => "Select the previous Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Kind Filter",
               Description => "Clear the Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Scope_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Scope",
                  Description => "Set the Project Search path scope.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Scope_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Scope",
               Description => "Clear the Project Search path scope.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Case_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Case Sensitivity",
               Description => "Toggle case-sensitive Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Case_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Case Sensitivity",
               Description => "Clear case-sensitive Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Whole_Word_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Whole Word",
               Description => "Toggle whole-word Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Whole_Word_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Whole Word",
               Description => "Clear whole-word Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Regex_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Regex",
               Description => "Toggle regex Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Regex_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Regex",
               Description => "Clear regex Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Include_Filter_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Include Filter",
                  Description => "Set the Project Search include path filter.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Exclude_Filter_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Exclude Filter",
                  Description => "Set the Project Search exclude path filter.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Include_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Include Filter",
               Description => "Clear the Project Search include path filter.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Exclude_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Exclude Filter",
               Description => "Clear the Project Search exclude path filter.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Replace_Preview =>
            return Make_Descriptor (Id => Id, Name => "Preview Project Search Replacements", Description => "Preview replacements for current Project Search results.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_Toggle_Selected =>
            return Make_Descriptor (Id => Id, Name => "Toggle Selected Project Search Replacement", Description => "Include or exclude the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_Selected =>
            return Make_Descriptor (Id => Id, Name => "Include Selected Project Search Replacement", Description => "Include the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_Selected =>
            return Make_Descriptor (Id => Id, Name => "Exclude Selected Project Search Replacement", Description => "Exclude the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_File =>
            return Make_Descriptor (Id => Id, Name => "Include File Project Search Replacements", Description => "Include all replacement preview rows for the selected file group", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_File =>
            return Make_Descriptor (Id => Id, Name => "Exclude File Project Search Replacements", Description => "Exclude all replacement preview rows for the selected file group", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_All =>
            return Make_Descriptor (Id => Id, Name => "Include All Project Search Replacements", Description => "Include all replacement preview rows", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_All =>
            return Make_Descriptor (Id => Id, Name => "Exclude All Project Search Replacements", Description => "Exclude all replacement preview rows", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Selected =>
            return Make_Descriptor (Id => Id, Name => "Replace Selected Project Search Match", Description => "Replace the selected Project Search match.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_All_Included =>
            return Make_Descriptor (Id => Id, Name => "Replace All Included Project Search Matches", Description => "Replace all included Project Search matches.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_Clear_Preview =>
            return Make_Descriptor (Id => Id, Name => "Clear Project Search Replacement Preview", Description => "Clear Project Search replacement preview without changing files.", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Show_Search_Results_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search Results",
               Description => "Show Project Search results.",
               Category    => Search_Category,
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
         when Command_Search_Results_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Up",
               Description => "Move the Project Search result selection up.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Down",
               Description => "Move the Project Search result selection down.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Search Page Up",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Search_Results_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Search Page Down",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Search_Results_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Search Result",
               Description => "Open the selected Search Result.",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
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
         when Command_Focus_File_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus File Tree",
               Description => "Move keyboard focus to the project file tree",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Move Up",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Move Down",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Page Up",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Page Down",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected File",
               Description => "Open or toggle the selected File Tree row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Create_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File",
               Description => "Create an empty file under the active project from a selected directory name or project-relative path.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Create_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create Directory",
               Description => "Create a directory under the active project from a selected directory name or project-relative path.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Rename_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Rename File or Directory",
               Description => "Rename the selected project file or directory from explicit input.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Delete_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete File or Directory",
               Description => "Delete the selected project file or directory after explicit confirmation text.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Expand_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Expand Selected File Tree Item",
               Description => "Expand the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Collapse_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Collapse Selected File Tree Item",
               Description => "Collapse the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Toggle_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Selected File Tree Item",
               Description => "Toggle the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Collapse_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Collapse All File Tree Directories",
               Description => "Collapse all directories in the File Tree view state only.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Expand_To_Active_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Expand File Tree to Active File",
               Description => "Expand parent directories and select the active project file.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Save_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save All",
               Description => "Save all dirty file-backed buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Save_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Settings",
               Description => "Save global editor preferences.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Reload_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload Settings",
               Description => "Reload global editor preferences from disk.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Reset_Settings_To_Defaults =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Settings to Defaults",
               Description => "Reset global editor preferences to built-in defaults.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Save_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Keybindings",
               Description => "Save global keybinding overrides.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Reload_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload Keybindings",
               Description => "Reload global keybinding overrides from disk.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Validate_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Validate Keybindings",
               Description => "Validate active keybindings against known commands and conflicts.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Keybindings",
               Description => "Show the keybinding management surface.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Keybindings",
               Description => "Focus the keybinding management surface.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Assign_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Selected Keybinding",
               Description => "Start explicit shortcut capture for the selected bindable command.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Remove_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Selected Keybinding",
               Description => "Remove the selected user keybinding or selected chord.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Reset_To_Defaults =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Keybindings to Defaults",
               Description => "Request explicit reset of user keybinding overrides to defaults.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Filter_Conflicts =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Keybinding Conflicts",
               Description => "Show keybindings with active/default conflicts.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Filter_Unbound =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Unbound Commands",
               Description => "Show bindable commands that currently have no active shortcut.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Clear_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Keybinding Filter",
               Description => "Clear the keybinding filter text.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Cancel_Capture =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Keybinding Capture",
               Description => "Cancel pending keybinding capture or replacement confirmation.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Startup_Show_Summary =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Startup Summary",
               Description => "Show the startup and recovery summary without loading, saving, or repairing configuration.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Recover_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Configuration Recovery",
               Description => "Show bounded configuration recovery status for settings, keybindings, workspace, and recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Audit =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Review Configuration",
               Description => "Review configuration and recovery readiness without changing settings.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Settings Domain",
               Description => "Reset settings to safe defaults without touching keybindings, workspace, or recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Keybindings Domain",
               Description => "Reset keybindings to safe defaults without touching settings, workspace, or recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Workspace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Workspace Domain",
               Description => "Clear structural workspace state without touching settings, keybindings, or recent projects.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Recent Projects Domain",
               Description => "Clear recent projects without touching settings, keybindings, or workspace state.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset All Configuration Domains",
               Description => "Request explicit confirmation before resetting settings, keybindings, workspace, and recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All_Confirm =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Reset All Configuration Domains",
               Description => "Confirm the pending reset-all request; project files and dirty buffers are not changed.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All_Cancel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Reset All Configuration Domains",
               Description => "Cancel the pending reset-all confirmation without changing configuration domains.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Settings",
               Description => "Write supported settings fields only; does not write other configuration domains.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Keybindings",
               Description => "Write normalized valid keybindings only; does not write settings or workspace state.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Workspace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Workspace",
               Description => "Write structural workspace fields only; does not write settings, keybindings, or recent projects.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Recent Projects",
               Description => "Write lightweight recent project entries only; does not write workspace or settings data.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Save_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Workspace State",
               Description => "Save structural workspace/session state; does not save dirty file contents.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Restore_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Restore Workspace",
               Description => "Restore saved workspace/session state without saving or restoring unsaved text.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Workspace State",
               Description => "Delete the saved structural workspace/session state for the current project; does not delete project files.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Feature Panel",
               Description => "Show or hide the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Feature Panel",
               Description => "Show the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Hide_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Feature Panel",
               Description => "Hide the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Feature Panel",
               Description => "Move focus to the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Feature Panel",
               Description => "Clear feature panel rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Feature_Panel_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Feature Panel Select Next",
               Description => "Select the next feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Feature_Panel_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Feature Panel Select Previous",
               Description => "Select the previous feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Feature_Panel_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Feature Panel Row",
               Description => "Open the selected feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Refresh_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Outline",
               Description => "Refresh Outline for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Refresh_Outline_Project_Index =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Outline Project Index",
               Description => "Refresh the Ada language index from known project Ada source files for Outline navigation.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Declaration =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Declaration",
               Description => "Open the declaration target for the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Body =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Body",
               Description => "Open the body target for the selected Outline symbol when available.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Spec =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Spec",
               Description => "Open the spec target for the selected Outline symbol when available.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Find_References =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find References",
               Description => "Show indexed references for the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Workspace_Symbols =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Workspace Symbols",
               Description => "Show indexed workspace symbols matching the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Show_Hover =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Hover",
               Description => "Show indexed language details for the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Show_Completions =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Completions",
               Description => "Show indexed language completion candidates matching the selected Outline symbol prefix.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Semantic_Completion_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Completion",
               Description => "Move to the next item in the visible completion menu.",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Semantic_Completion_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Completion",
               Description => "Move to the previous item in the visible completion menu.",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Semantic_Completion_Accept =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Accept Completion",
               Description => "Insert the selected item from the visible completion menu.",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Semantic_Popup_Dismiss =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Dismiss Semantic Popup",
               Description => "Close the visible hover or completion popup.",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Rename_Symbol_Preview =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Preview Rename Symbol",
               Description => "Preview the indexed rename impact for the selected Outline symbol without editing files.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Rename_Symbol_Apply =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Apply Rename Symbol",
               Description => "Apply a conflict-free indexed rename for the selected Outline symbol in the active buffer.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Semantic_Refresh_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Semantic Colouring",
               Description => "Refresh Ada semantic colouring data for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Semantic_Refresh_Project_Index =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Semantic Project Index",
               Description => "Refresh known project Ada source files in the language index and update semantic colouring for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Language_Index_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Language Index",
               Description => "Clear the Ada language index without changing files or buffers.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Language_Index_Status =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Language Index Status",
               Description => "Show the Ada language index file count, symbol count, overflow state, and fingerprint.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline",
               Description => "Clear Outline rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Outline",
               Description => "Show the Outline panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Outline",
               Description => "Move focus to the Outline panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Open_Selected_Outline_Item =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Outline Item",
               Description => "Open the selected Outline item.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Select_Current_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Current Outline Symbol",
               Description => "Select the current outline symbol tracked from the active editor cursor.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Reveal_Current_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Current Outline Symbol",
               Description => "Reveal and select the current outline symbol without moving the editor cursor.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Next_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Outline Symbol",
               Description => "Move the editor caret to the next Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Outline Symbol",
               Description => "Move the editor caret to the previous Outline symbol.",
               Category    => Navigation_Category,
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
         when Command_Focus_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Outline Filter",
               Description => "Focus the Outline filter input.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Filter_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Outline Symbols",
               Description => "Apply the Outline filter to the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline Filter",
               Description => "Clear the Outline filter and show all Outline items.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Outline Filter",
               Description => "Toggle focus for the local outline filter input.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Outline_Filter_History_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Outline: Previous Filter",
               Description => "Replace the active outline filter with the previous session-local filter history entry.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Outline_Filter_History_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Outline: Next Filter",
               Description => "Replace the active outline filter with the next session-local filter history entry.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline_Filter_History =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline Filter History",
               Description => "Clear session-local outline filter history without changing accepted outline rows.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Show_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Show Panel",
               Description => "Show the session-local Messages feature panel without diagnostics, LSP, search, persistence, or background collection.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear",
               Description => "Clear session-local Messages rows without mutating outline state.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Search_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Active Buffer",
               Description => "Search the current active buffer snapshot with the current literal search query and replace Search Results rows.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Focus_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Search Query",
               Description => "Focus the session-local Search Results query input without mutating editor text.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Repeat_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Repeat Active Buffer Search",
               Description => "Rerun the last literal Search Results query against the current active buffer.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Query_History_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Search Query",
               Description => "Move the active Search Results query input to the previous session-local query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Query_History_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Search Query",
               Description => "Move the active Search Results query input to the next session-local query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Toggle_Case_Sensitive =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Search Case Sensitivity",
               Description => "Toggle literal Search Results case sensitivity without adding regex or fuzzy behavior.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Show_Search_Results_Feature =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search Results",
               Description => "Show Project Search Results without running a new search.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Search_Results_Feature =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Results",
               Description => "Clear Project Search Results without changing files, Outline, or Messages.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Diagnostics",
               Description => "Show the current Diagnostics panel without scanning, background collection, or changing editor text.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Diagnostics",
               Description => "Clear session-local Diagnostics rows without mutating Outline, Messages, or Search Results.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Info Diagnostics",
               Description => "Show or hide informational Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Warning Diagnostics",
               Description => "Show or hide warning Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Error Diagnostics",
               Description => "Show or hide error Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Show_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show All Diagnostics",
               Description => "Clear Diagnostics filtering and restore all severity and source visibility flags.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Diagnostics Filter",
               Description => "Clear Diagnostics filtering and restore all severity and source visibility flags.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Error Diagnostics",
               Description => "Show only error Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Warning Diagnostics",
               Description => "Show only warning Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Info_Notes =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Info and Note Diagnostics",
               Description => "Show only informational Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Diagnostics from Selected Source",
               Description => "Show only Diagnostics rows from the selected diagnostic source.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Build =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Build Diagnostics",
               Description => "Show Diagnostics reported by the last build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Build =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Build Diagnostics",
               Description => "Clear only build-produced Diagnostics rows without mutating Build result or output details.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Diagnostic",
               Description => "Open the file location for the selected Diagnostic when available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Open_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Open Source",
               Description => "Open the source location for the selected Diagnostic row from any diagnostic surface.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Suppress_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Suppress Selected",
               Description => "Request suppression for the selected Diagnostic when suppression is available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Show_Suppressed =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Show Suppressed",
               Description => "Show the session suppressed Diagnostic count and latest suppressed row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Restore_Last_Suppressed =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Restore Last Suppressed",
               Description => "Restore the most recently suppressed Diagnostic for review.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Restore_Selected_Suppressed =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Restore Selected Suppressed",
               Description => "Restore the selected suppressed Diagnostic for review.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Clear_Suppressed =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Clear Suppressed",
               Description => "Clear suppressed Diagnostics without restoring them.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Apply_Quick_Fix =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Apply Quick Fix",
               Description => "Apply the selected Diagnostic quick fix when a fix is available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Execute_Selected_Action =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Execute Selected Diagnostic Action",
               Description => "Execute the primary code action for the selected Diagnostic when available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Diagnostic",
               Description => "Move selection to the next visible Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Diagnostic",
               Description => "Move selection to the previous visible Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Diagnostic",
               Description => "Clear the selected Diagnostic.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Copy_Selected_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Copy Selected Diagnostic Text",
               Description => "Copy deterministic text for the selected Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Info Diagnostics",
               Description => "Clear info Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Warning Diagnostics",
               Description => "Clear warning Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Error Diagnostics",
               Description => "Clear error Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Editor_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Editor Diagnostics",
               Description => "Show or hide editor Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_File_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle File Diagnostics",
               Description => "Show or hide file Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Project_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Diagnostics",
               Description => "Show or hide project Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_External_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle External Diagnostics",
               Description => "Show or hide external Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Unknown_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Unknown Diagnostics",
               Description => "Show or hide Diagnostics rows from unknown sources.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Selected_Message =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Selected",
               Description => "Clear the selected session-local Messages row by stable Message_Id.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Copy_Selected_Message_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Copy Selected Text",
               Description => "Copy deterministic selected Messages row text without exposing internal ids.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Info_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Info",
               Description => "Clear informational Messages rows while preserving filters and warnings/errors.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Warning_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Warnings",
               Description => "Clear warning Messages rows while preserving filters and info/errors.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Error_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Errors",
               Description => "Clear error Messages rows while preserving filters and info/warnings.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Info",
               Description => "Toggle visibility for informational Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Warnings",
               Description => "Toggle visibility for warning Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Errors",
               Description => "Toggle visibility for error Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_All_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Show All Messages",
               Description => "Clear Messages filters and show all session-local Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Message_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Filter",
               Description => "Clear Messages filter text and restore all severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Dismiss_Latest_Message =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Dismiss Latest Message",
               Description => "Dismiss the most recent message.",
               Category    => Message_Category,
               Visibility  => Hidden_Command);
         when Command_Dismiss_All_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Dismiss All Messages",
               Description => "Dismiss all messages.",
               Category    => Message_Category,
               Visibility  => Palette_Command);
         when Command_Run_Project =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Project: Run",
                  Description => "Run the default project task through the structured project task runner.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Run_Tests =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Project: Run Tests",
                  Description => "Run the default project test task through the structured project task runner.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Terminal_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Toggle",
               Description => "Show or hide the integrated terminal and task panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Show",
               Description => "Show the integrated terminal and task panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Hide",
               Description => "Hide the integrated terminal and task panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Focus",
               Description => "Show and focus the integrated terminal and task panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Clear Tasks",
               Description => "Clear terminal task rows and output.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Clear_Output =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Clear Output",
               Description => "Clear bounded terminal output while preserving task rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Select_Next_Task =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Select Next Task",
               Description => "Move terminal task selection to the next row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Select_Previous_Task =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Terminal: Select Previous Task",
               Description => "Move terminal task selection to the previous row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Terminal_Run_Selected_Task =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Terminal: Run Selected Task",
                  Description => "Run the selected structured terminal task.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Terminal_Rerun_Last_Task =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Terminal: Rerun Last Task",
                  Description => "Run the most recently executed terminal task again.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Terminal_Cancel_Task =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Terminal: Cancel Task",
                  Description => "Request cancellation of the active terminal task when a backend is running it.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Build_UI_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Build Output",
               Description => "Show or hide the build output panel without refreshing candidates or running a build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Build Output",
               Description => "Show the current build output without starting a new build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Build Output",
               Description => "Hide the build output panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Build Output",
               Description => "Show and focus the build output panel without changing request, candidate, or confirmation state.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_Result_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Focus Latest Result",
               Description => "Focus the latest build result summary when a result is available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_Output_Details_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Focus Output Details",
               Description => "Focus the latest build stdout/stderr details when output details are available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_Output_Details_Select_Stdout =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Stdout Output",
               Description => "Show stdout as the selected latest build output stream.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Output_Details_Select_Stderr =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Stderr Output",
               Description => "Show stderr as the selected latest build output stream.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Output_Details_Select_Merged =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Merged Output",
               Description => "Show merged stdout/stderr as the selected latest build output stream.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Refresh_Candidates =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Refresh Candidates",
               Description => "Refresh build candidates for the current project without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Select_First_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select First Candidate",
               Description => "Select the first discovered build candidate without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Select_Next_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Next Candidate",
               Description => "Select the next discovered build candidate without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Select_Previous_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Previous Candidate",
               Description => "Select the previous discovered build candidate without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Clear_Selected_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Clear Selected Candidate",
               Description => "Clear the selected build candidate and require confirmation before the next run.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Default =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Default",
               Description => "Set the build mode to the default profile.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Debug =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Debug",
               Description => "Set the selected GPRbuild candidate to the debug profile (-g).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Release =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Release",
               Description => "Set the selected GPRbuild candidate to the release profile (-O2 -gnatp).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Validation =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Validation",
               Description => "Set the selected GPRbuild candidate to the validation profile (-gnata -gnatwa).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Diagnostics_Ingestion =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Diagnostics Ingestion",
               Description => "Toggle whether build results update Diagnostics after the next run.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Cycle_Output_Limit =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Cycle Output Capture Limit",
               Description => "Cycle the build output capture limit.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Option_Verbose =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Verbose Output",
               Description => "Toggle the fixed verbose-output request option where supported by the selected candidate.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Option_Keep_Going =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Keep Going",
               Description => "Toggle the fixed keep-going request option where supported by the selected candidate.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Acknowledge_Consent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Acknowledge Consent",
               Description => "Confirm the current build request before running it.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Clear_Consent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Clear Consent",
               Description => "Clear build confirmation without changing candidates or request options.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Cancel =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Cancel Build",
                  Description => "Request cancellation of the currently active build job.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Build_Run =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Run Build",
                  Description => "Run the currently selected build request after explicit confirmation.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Build_Run_User_Opt_In_Test_Seam =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Build: Run User Opt-In Test Command",
                  Description => "Internal test-only command for structured user opt-in build command validation.",
                  Category    => Internal_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
      end case;
   end Descriptor;


end Editor.Commands.Descriptor_Metadata;
