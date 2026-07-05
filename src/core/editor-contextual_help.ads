with Editor.Commands;
with Editor.Feature_Panel;

package Editor.Contextual_Help is

   --  lightweight contextual help projection helpers.
   --
   --  These helpers format transient UI text from existing command metadata,
   --  active keybindings, availability/focus facts supplied by callers, and
   --  already-projected rows. They do not mutate editor state, register
   --  commands, execute commands, inspect project metadata, or persist text.

   function Shortcut_Text
     (Command        : Editor.Commands.Command_Id;
      Show_Shortcuts : Boolean) return String;

   function With_Shortcut
     (Text           : String;
      Command        : Editor.Commands.Command_Id;
      Show_Shortcuts : Boolean) return String;

   function Empty_Messages_Detail return String;
   function Empty_Diagnostics_Detail return String;
   function Empty_Search_Results_Detail
     (Has_Query : Boolean) return String;
   function Empty_Outline_Detail
     (Has_Active_Buffer : Boolean := True) return String;
   function Empty_File_Tree_Text
     (Has_Project : Boolean) return String;
   function Empty_Open_Buffers_Text return String;
   function Command_Palette_No_Match_Detail
     (Query_Is_Empty : Boolean) return String;

   function Focus_Hint
     (Focus_Label    : String;
      Show_Shortcuts : Boolean) return String;

   function Keyboard_Action_Hint
     (Focus_Label    : String;
      Show_Shortcuts : Boolean) return String;

   function Row_Accessible_Label
     (Row : Editor.Feature_Panel.Feature_Panel_Render_Row) return String;

   function Command_Row_Accessible_Label
     (Label          : String;
      Category_Label : String;
      Description    : String;
      Available      : Boolean;
      Reason         : String) return String;

   function File_Tree_Row_Accessible_Label
     (Display_Label : String;
      Is_Directory  : Boolean;
      Is_Selected   : Boolean) return String;

   function Selected_Row_Action_Hint
     (Row            : Editor.Feature_Panel.Feature_Panel_Render_Row;
      Show_Shortcuts : Boolean) return String;

   function Command_Row_Action_Hint
     (Command         : Editor.Commands.Command_Id;
      Available       : Boolean;
      Disabled_Reason : String;
      Show_Shortcuts  : Boolean) return String;

   function File_Tree_Row_Action_Hint
     (Is_Directory  : Boolean;
      Is_Expanded   : Boolean;
      Show_Shortcuts : Boolean) return String;

   function Open_Buffer_Row_Action_Hint
     (Is_Active      : Boolean;
      Can_Close      : Boolean;
      Show_Shortcuts : Boolean) return String;

   function Truncate
     (Text        : String;
      Max_Columns : Natural) return String;

end Editor.Contextual_Help;
