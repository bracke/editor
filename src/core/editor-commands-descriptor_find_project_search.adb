with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_Find_Project_Search is

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
         when Command_Rerun_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Rerun Project Search",
               Description => "Rerun the current Project Search query.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search",
               Description => "Toggle Project Search.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
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
         when Command_Open_Selected_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Project Search Result",
               Description => "Open the selected project search result.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
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
         when others =>
            raise Program_Error with "command is not owned by Descriptor_Find_Project_Search";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_Find_Project_Search;
