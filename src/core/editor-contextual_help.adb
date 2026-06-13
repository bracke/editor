with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Keybindings;

package body Editor.Contextual_Help is

   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;

   function Truncate
     (Text        : String;
      Max_Columns : Natural) return String
   is
      Ellipsis : constant String := "...";
   begin
      if Max_Columns = 0 then
         return "";
      elsif Text'Length <= Max_Columns then
         return Text;
      elsif Max_Columns <= 3 then
         return Text (Text'First .. Text'First + Max_Columns - 1);
      else
         return Text (Text'First .. Text'First + Max_Columns - 4) & Ellipsis;
      end if;
   end Truncate;

   function Shortcut_Text
     (Command        : Editor.Commands.Command_Id;
      Show_Shortcuts : Boolean) return String
   is
      Info : Editor.Keybindings.Command_Keybinding_Info;
   begin
      if not Show_Shortcuts
        or else not Editor.Commands.Is_Bindable_Command (Command)
        or else Editor.Commands.Is_Internal_Build_Test_Seam_Command (Command)
        or else Editor.Commands.Is_Public_Build_Command (Command)
      then
         return "";
      end if;

      Info := Editor.Keybindings.Primary_Binding_For_Command (Command);
      if Info.Has_Binding then
         return Ada.Strings.Unbounded.To_String (Info.Display);
      end if;
      return "";
   end Shortcut_Text;

   function With_Shortcut
     (Text           : String;
      Command        : Editor.Commands.Command_Id;
      Show_Shortcuts : Boolean) return String
   is
      Shortcut : constant String := Shortcut_Text (Command, Show_Shortcuts);
   begin
      if Shortcut'Length = 0 then
         return Text;
      else
         return Text & " [" & Shortcut & "]";
      end if;
   end With_Shortcut;

   function Empty_Messages_Detail return String is
   begin
      return "Command feedback appears here; nothing to clear.";
   end Empty_Messages_Detail;

   function Empty_Diagnostics_Detail return String is
   begin
      return "Diagnostics appear here; nothing to navigate.";
   end Empty_Diagnostics_Detail;

   function Empty_Search_Results_Detail
     (Has_Query : Boolean) return String
   is
   begin
      if Has_Query then
         return "No matches in the active buffer.";
      else
         return "Search the active buffer to list matches here.";
      end if;
   end Empty_Search_Results_Detail;

   function Empty_Outline_Detail
     (Has_Active_Buffer : Boolean := True) return String
   is
   begin
      if Has_Active_Buffer then
         return "Refresh the active buffer outline to list symbols here.";
      else
         return "Open a buffer before refreshing the outline.";
      end if;
   end Empty_Outline_Detail;

   function Empty_File_Tree_Text
     (Has_Project : Boolean) return String
   is
   begin
      if Has_Project then
         return "No project files";
      else
         return "Open a project to show files";
      end if;
   end Empty_File_Tree_Text;

   function Empty_Open_Buffers_Text return String is
   begin
      return "No open buffers";
   end Empty_Open_Buffers_Text;

   function Command_Palette_No_Match_Detail
     (Query_Is_Empty : Boolean) return String
   is
   begin
      if Query_Is_Empty then
         return "Open a file or project to make more commands available.";
      else
         return "Clear the query to show available commands.";
      end if;
   end Command_Palette_No_Match_Detail;

   function Focus_Hint
     (Focus_Label    : String;
      Show_Shortcuts : Boolean) return String
   is
   begin
      if Focus_Label = "Command Palette" then
         return Keyboard_Action_Hint (Focus_Label, Show_Shortcuts);
      elsif Focus_Label = "Feature Panel" then
         return Keyboard_Action_Hint (Focus_Label, Show_Shortcuts);
      elsif Focus_Label = "File Tree" then
         return Keyboard_Action_Hint (Focus_Label, Show_Shortcuts);
      elsif Focus_Label = "Search Results" then
         return Keyboard_Action_Hint (Focus_Label, Show_Shortcuts);
      elsif Focus_Label = "Problems" then
         return Keyboard_Action_Hint (Focus_Label, Show_Shortcuts);
      elsif Focus_Label = "Quick Open" then
         return "type to filter, Enter to open, Esc to close";
      elsif Focus_Label = "Find" then
         return "type query, Enter to find, Esc to close";
      elsif Focus_Label = "Project Search" then
         return "type query, Enter to search, Esc to close";
      elsif Focus_Label = "Search Query" then
         return "type query, Enter to search, Esc to cancel";
      elsif Focus_Label = "Outline Filter" then
         return "type filter, Enter to apply, Esc to cancel";
      elsif Focus_Label = "Settings Input" then
         return "type value, Enter to confirm, Esc to cancel";
      elsif Focus_Label = "Keybinding Input" then
         return "press shortcut, Enter to confirm, Esc to cancel";
      elsif Focus_Label = "Editor" then
         return With_Shortcut
           ("editor focus", Editor.Commands.Command_Open_Command_Palette,
            Show_Shortcuts);
      else
         return "";
      end if;
   end Focus_Hint;

   function Keyboard_Action_Hint
     (Focus_Label    : String;
      Show_Shortcuts : Boolean) return String
   is
      pragma Unreferenced (Show_Shortcuts);
   begin
      if Focus_Label = "Command Palette" then
         return "type to filter, Enter to run, Esc to close";
      elsif Focus_Label = "Feature Panel" then
         return "Up/Down to move, Enter to open, Esc to editor";
      elsif Focus_Label = "File Tree" then
         return "Up/Down to move, Enter to open, Esc to editor";
      elsif Focus_Label = "Search Results" then
         return "Up/Down to move, Enter to open, Esc to editor";
      elsif Focus_Label = "Problems" then
         return "Up/Down to move, Enter to open, Esc to editor";
      else
         return "";
      end if;
   end Keyboard_Action_Hint;

   function Severity_Text
     (Severity : Editor.Feature_Panel.Feature_Row_Severity) return String
   is
   begin
      case Severity is
         when Editor.Feature_Panel.Feature_Row_Info_Severity =>
            return "info";
         when Editor.Feature_Panel.Feature_Row_Warning_Severity =>
            return "warning";
         when Editor.Feature_Panel.Feature_Row_Error_Severity =>
            return "error";
         when Editor.Feature_Panel.Feature_Row_No_Severity =>
            return "";
      end case;
   end Severity_Text;

   function Row_Accessible_Label
     (Row : Editor.Feature_Panel.Feature_Panel_Render_Row) return String
   is
      Label    : constant String := Ada.Strings.Unbounded.To_String (Row.Label);
      Detail   : constant String := Ada.Strings.Unbounded.To_String (Row.Detail);
      Severity : constant String := Severity_Text (Row.Severity);
      Prefix   : constant String :=
        (if Row.Kind = Editor.Feature_Panel.Feature_Row_Header then "section"
         elsif Row.Kind = Editor.Feature_Panel.Feature_Row_Empty_State then "empty"
         elsif Severity'Length > 0 then Severity
         elsif Row.Is_Current_Symbol then "current symbol"
         else "row");
      Message_Body     : constant String :=
        (if Label'Length > 0 then Label
         elsif Detail'Length > 0 then Detail
         else "unlabelled row");
   begin
      if Detail'Length > 0 and then Detail /= Message_Body then
         return Prefix & ": " & Message_Body & " — " & Detail;
      else
         return Prefix & ": " & Message_Body;
      end if;
   end Row_Accessible_Label;

   function Command_Row_Accessible_Label
     (Label          : String;
      Category_Label : String;
      Description    : String;
      Available      : Boolean;
      Reason         : String) return String
   is
      Base : constant String :=
        (if Label'Length > 0 then Label else "unnamed command");
      Category_Text : constant String :=
        (if Category_Label'Length > 0 then " (" & Category_Label & ")" else "");
      Detail_Text : constant String :=
        (if Available then Description
         elsif Reason'Length > 0 then Reason
         else "Command not available here");
   begin
      if Detail_Text'Length > 0 then
         return Base & Category_Text & " — " & Detail_Text;
      else
         return Base & Category_Text;
      end if;
   end Command_Row_Accessible_Label;

   function File_Tree_Row_Accessible_Label
     (Display_Label : String;
      Is_Directory  : Boolean;
      Is_Selected   : Boolean) return String
   is
      Kind_Text : constant String := (if Is_Directory then "folder" else "file");
      Name_Text : constant String :=
        (if Display_Label'Length > 0 then Display_Label else "unnamed");
      Selected_Text : constant String :=
        (if Is_Selected then " selected" else "");
   begin
      return Kind_Text & Selected_Text & ": " & Name_Text;
   end File_Tree_Row_Accessible_Label;

   function Selected_Row_Action_Hint
     (Row            : Editor.Feature_Panel.Feature_Panel_Render_Row;
      Show_Shortcuts : Boolean) return String
   is
      Primary : Unbounded_String := Null_Unbounded_String;
   begin
      if Row.Kind = Editor.Feature_Panel.Feature_Row_Empty_State
        or else not Row.Selectable
      then
         return "";
      elsif Row.Can_Open or else (Row.Activatable and then Row.Has_Target) then
         Primary := To_Unbounded_String
           (With_Shortcut
              ("Enter opens selected row",
               Editor.Commands.Command_Feature_Panel_Open_Selected,
               Show_Shortcuts));
      elsif Row.Activatable then
         Primary := To_Unbounded_String
           (With_Shortcut
              ("Enter activates selected row",
               Editor.Commands.Command_Feature_Panel_Open_Selected,
               Show_Shortcuts));
      else
         return "Selected row cannot be opened here";
      end if;

      if Row.Can_Copy then
         Append (Primary, ", copy available");
      end if;
      if Row.Can_Clear then
         Append (Primary, ", clear available");
      end if;
      if Row.Can_Reveal then
         Append (Primary, ", reveal available");
      end if;

      return To_String (Primary);
   end Selected_Row_Action_Hint;

   function Command_Row_Action_Hint
     (Command         : Editor.Commands.Command_Id;
      Available       : Boolean;
      Disabled_Reason : String;
      Show_Shortcuts  : Boolean) return String
   is
   begin
      if Available then
         return With_Shortcut
           ("Enter runs selected command",
            Command,
            Show_Shortcuts);
      elsif Disabled_Reason'Length > 0 then
         return Disabled_Reason;
      else
         return "Command not available here";
      end if;
   end Command_Row_Action_Hint;

   function File_Tree_Row_Action_Hint
     (Is_Directory  : Boolean;
      Is_Expanded   : Boolean;
      Show_Shortcuts : Boolean) return String
   is
      pragma Unreferenced (Show_Shortcuts);
   begin
      if Is_Directory then
         if Is_Expanded then
            return "Enter collapses selected folder";
         else
            return "Enter expands selected folder";
         end if;
      else
         return "Enter opens selected file";
      end if;
   end File_Tree_Row_Action_Hint;

   function Open_Buffer_Row_Action_Hint
     (Is_Active      : Boolean;
      Can_Close      : Boolean;
      Show_Shortcuts : Boolean) return String
   is
      pragma Unreferenced (Show_Shortcuts);
      Hint : Unbounded_String :=
        To_Unbounded_String
          ((if Is_Active then "Enter keeps selected buffer active"
            else "Enter activates selected buffer"));
   begin
      if Can_Close then
         Append (Hint, ", close available");
      end if;
      return To_String (Hint);
   end Open_Buffer_Row_Action_Hint;

end Editor.Contextual_Help;
