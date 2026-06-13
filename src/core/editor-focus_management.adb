with Editor.Build_Output_Details;
with Editor.Build_UI;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Guided_Prompts;
with Editor.Outline;
with Editor.Overlay_Focus;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Pending_Transitions;
with Editor.Project_Search_Bar;
with Editor.Project;

package body Editor.Focus_Management is

   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Project_Search_Bar.Project_Search_Bar_Field;
   use type Editor.Commands.Command_Id;
   use type Editor.Panels.Bottom_Panel_Content;

   function Pending_Confirmation_Owns_Focus
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions);
   end Pending_Confirmation_Owns_Focus;

   function Overlay_Input_Owns_Text
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus)
        or else Editor.Feature_Search_Results.Search_Input_Is_Active
          (S.Feature_Search_Results)
        or else Editor.Outline.Filter_Input_Is_Active (S.Outline);
   end Overlay_Input_Owns_Text;

   function Effective_Focus_Owner
     (S : Editor.State.State_Type) return Focus_Owner
   is
   begin
      if Pending_Confirmation_Owns_Focus (S) then
         return Focus_Pending_Confirmation;
      elsif Editor.Guided_Prompts.Is_Active (S.Guided_Prompt) then
         --  Guided prompts own input focus above normal overlays/panels.
         --  Confirmation prompts keep the existing pending-confirmation label
         --  so status summaries distinguish modal confirmation from ordinary
         --  text-entry prompts without adding a new persistence-visible state.
         if Editor.Guided_Prompts.Is_Confirmation (S.Guided_Prompt) then
            return Focus_Pending_Confirmation;
         else
            return Focus_Workspace_Prompt;
         end if;
      end if;

      case Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) is
         when Editor.Overlay_Focus.Command_Palette_Overlay =>
            return Focus_Command_Palette;
         when Editor.Overlay_Focus.Quick_Open_Overlay =>
            return Focus_Quick_Open;
         when Editor.Overlay_Focus.Project_Search_Bar_Overlay =>
            if Editor.Project_Search_Bar.Active_Field (S.Project_Search_Bar) =
              Editor.Project_Search_Bar.Project_Search_Replace_Field
            then
               return Focus_Project_Replace_Input;
            else
               return Focus_Project_Search_Query;
            end if;
         when Editor.Overlay_Focus.Buffer_Switcher_Overlay =>
            return Focus_Buffer_List;
         when Editor.Overlay_Focus.Active_Find_Prompt_Overlay
            | Editor.Overlay_Focus.Go_To_Line_Overlay
            | Editor.Overlay_Focus.File_Target_Prompt_Overlay =>
            return Focus_Workspace_Prompt;
         when Editor.Overlay_Focus.No_Overlay =>
            null;
      end case;

      if S.Latest_Build_Output_Details.Build_Output_Details_Focused then
         return Focus_Build_Output_Details;
      elsif S.Latest_Build_Result_Focused then
         return Focus_Build_Result_Summary;
      elsif S.Build_UI.Build_UI_Focused then
         return Focus_Build_UI;
      elsif S.Recent_Projects_Focused then
         return Focus_Recent_Projects;
      elsif Editor.Feature_Search_Results.Search_Input_Is_Active
        (S.Feature_Search_Results)
      then
         return Focus_Project_Search_Query;
      elsif Editor.Outline.Filter_Input_Is_Active (S.Outline) then
         return Focus_Outline_Filter;
      elsif Editor.Feature_Panel.Is_Focused (S.Feature_Panel) then
         case Editor.Feature_Panel.Active_Feature (S.Feature_Panel) is
            when Editor.Feature_Panel.Outline_Feature =>
               return Focus_Outline;
            when Editor.Feature_Panel.Diagnostics_Feature =>
               return Focus_Diagnostics;
            when Editor.Feature_Panel.Search_Results_Feature =>
               return Focus_Project_Search_Results;
            when others =>
               return Focus_Project_Search_Results;
         end case;
      end if;

      case Editor.Panel_Focus.Target (S.Panel_Focus) is
         when Editor.Panel_Focus.Editor_Text_Focus =>
            return Focus_Editor;
         when Editor.Panel_Focus.File_Tree_Focus =>
            return Focus_File_Tree;
         when Editor.Panel_Focus.Bottom_Panel_Focus =>
            case Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) is
               when Editor.Panel_Focus.Search_Results_Focus =>
                  return Focus_Project_Search_Results;
               when Editor.Panel_Focus.Problems_Focus =>
                  return Focus_Diagnostics;
               when Editor.Panel_Focus.No_Bottom_Focus =>
                  return Focus_None;
            end case;
      end case;
   end Effective_Focus_Owner;

   function Focus_Owner_Label
     (Owner : Focus_Owner) return String
   is
   begin
      case Owner is
         when Focus_None => return "None";
         when Focus_Editor => return "Editor";
         when Focus_Command_Palette => return "Command Palette";
         when Focus_Quick_Open => return "Quick Open";
         when Focus_Project_Search_Query => return "Project Search";
         when Focus_Project_Search_Results => return "Project Search Results";
         when Focus_Project_Replace_Input => return "Project Replace";
         when Focus_File_Tree => return "File Tree";
         when Focus_Outline => return "Outline";
         when Focus_Outline_Filter => return "Outline Filter";
         when Focus_Diagnostics => return "Diagnostics";
         when Focus_Build_UI => return "Build Output";
         when Focus_Build_Result_Summary => return "Build Result";
         when Focus_Build_Output_Details => return "Build Output";
         when Focus_Buffer_List => return "Buffer List";
         when Focus_Recent_Projects => return "Recent Projects";
         when Focus_Workspace_Prompt => return "Prompt";
         when Focus_Pending_Confirmation => return "Pending Confirmation";
      end case;
   end Focus_Owner_Label;

   function Active_Panel_Label
     (Owner : Focus_Owner) return String
   is
   begin
      case Owner is
         when Focus_Command_Palette => return "Command Palette";
         when Focus_Quick_Open => return "Quick Open";
         when Focus_Project_Search_Query
            | Focus_Project_Search_Results
            | Focus_Project_Replace_Input => return "Project Search";
         when Focus_File_Tree => return "File Tree";
         when Focus_Outline | Focus_Outline_Filter => return "Outline";
         when Focus_Diagnostics => return "Diagnostics";
         when Focus_Build_UI => return "Build Output";
         when Focus_Build_Result_Summary => return "Build Result";
         when Focus_Build_Output_Details => return "Build Output";
         when Focus_Buffer_List => return "Buffer List";
         when Focus_Recent_Projects => return "Recent Projects";
         when Focus_Workspace_Prompt => return "Prompt";
         when Focus_Pending_Confirmation => return "Pending Confirmation";
         when Focus_Editor => return "Editor";
         when Focus_None => return "None";
      end case;
   end Active_Panel_Label;

   function Input_Mode_Label
     (Owner : Focus_Owner) return String
   is
   begin
      if Owner = Focus_Pending_Confirmation then
         return "Modal";
      elsif Text_Input_Owner (Owner) then
         if Owner = Focus_Editor then
            return "Editor Text";
         else
            return "Overlay Text";
         end if;
      elsif Navigation_Panel_Owner (Owner) then
         return "Panel Navigation";
      elsif Owner = Focus_None then
         return "None";
      else
         return "Global Commands";
      end if;
   end Input_Mode_Label;

   function Overlay_Query_Active
     (S : Editor.State.State_Type) return Boolean
   is
      Owner : constant Focus_Owner := Effective_Focus_Owner (S);
   begin
      return Owner in Focus_Command_Palette
        | Focus_Quick_Open
        | Focus_Project_Search_Query
        | Focus_Project_Replace_Input
        | Focus_Outline_Filter
        | Focus_Workspace_Prompt
        | Focus_Buffer_List;
   end Overlay_Query_Active;

   function Editor_Text_Can_Edit
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Effective_Focus_Owner (S) = Focus_Editor;
   end Editor_Text_Can_Edit;

   function Panel_Navigation_Owns_Arrows
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Navigation_Panel_Owner (Effective_Focus_Owner (S));
   end Panel_Navigation_Owns_Arrows;

   function Focus_Priority_Rank
     (Owner : Focus_Owner) return Natural
   is
   begin
      case Owner is
         when Focus_Pending_Confirmation => return 1;
         when Focus_Command_Palette => return 2;
         when Focus_Quick_Open => return 3;
         when Focus_Project_Search_Query
            | Focus_Project_Replace_Input
            | Focus_Outline_Filter
            | Focus_Workspace_Prompt
            | Focus_Buffer_List => return 4;
         when Focus_File_Tree
            | Focus_Outline
            | Focus_Diagnostics
            | Focus_Project_Search_Results
            | Focus_Build_UI
            | Focus_Build_Result_Summary
            | Focus_Build_Output_Details
            | Focus_Recent_Projects => return 5;
         when Focus_Editor => return 6;
         when Focus_None => return 7;
      end case;
   end Focus_Priority_Rank;

   function Text_Input_Owner
     (Owner : Focus_Owner) return Boolean
   is
   begin
      case Owner is
         when Focus_Editor
            | Focus_Command_Palette
            | Focus_Quick_Open
            | Focus_Project_Search_Query
            | Focus_Project_Replace_Input
            | Focus_Outline_Filter
            | Focus_Workspace_Prompt
            | Focus_Buffer_List =>
            return True;
         when others =>
            return False;
      end case;
   end Text_Input_Owner;

   function Navigation_Panel_Owner
     (Owner : Focus_Owner) return Boolean
   is
   begin
      case Owner is
         when Focus_File_Tree
            | Focus_Outline
            | Focus_Diagnostics
            | Focus_Project_Search_Results
            | Focus_Build_UI
            | Focus_Build_Result_Summary
            | Focus_Build_Output_Details
            | Focus_Recent_Projects =>
            return True;
         when others =>
            return False;
      end case;
   end Navigation_Panel_Owner;

   function Global_Keybindings_May_Run
     (S : Editor.State.State_Type) return Boolean
   is
      Owner : constant Focus_Owner := Effective_Focus_Owner (S);
   begin
      return Owner = Focus_Editor or else Owner = Focus_None;
   end Global_Keybindings_May_Run;



   function Command_Is_Surface_Entry
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Open_Command_Palette
            | Editor.Commands.Command_Open_Quick_Open
            | Editor.Commands.Command_Toggle_Quick_Open
            | Editor.Commands.Command_Open_Buffer_Switcher
            | Editor.Commands.Command_Open_Project_Search_Bar
            | Editor.Commands.Command_Toggle_Project_Search_Bar
            | Editor.Commands.Command_Show_Search_Results_Panel
            | Editor.Commands.Command_Focus_Search_Results
            | Editor.Commands.Command_Toggle_Bottom_Panel_Focus
            | Editor.Commands.Command_Focus_File_Tree
            | Editor.Commands.Command_Show_Feature_Panel
            | Editor.Commands.Command_Toggle_Feature_Panel
            | Editor.Commands.Command_Focus_Feature_Panel
            | Editor.Commands.Command_Show_Outline
            | Editor.Commands.Command_Focus_Outline
            | Editor.Commands.Command_Focus_Outline_Filter
            | Editor.Commands.Command_Diagnostics_Show
            | Editor.Commands.Command_Toggle_Problems_Panel
            | Editor.Commands.Command_Focus_Problems
            | Editor.Commands.Command_Build_UI_Show
            | Editor.Commands.Command_Build_UI_Toggle
            | Editor.Commands.Command_Build_UI_Focus
            | Editor.Commands.Command_Show_Recent_Projects
            | Editor.Commands.Command_Goto_Line
            | Editor.Commands.Command_Goto_Line_Toggle
            | Editor.Commands.Command_Goto_Line_Prefill_Current
            | Editor.Commands.Command_Find_Show
            | Editor.Commands.Command_Find_Toggle
            | Editor.Commands.Command_Replace_Show
            | Editor.Commands.Command_Replace_Toggle
            | Editor.Commands.Command_Focus_Editor_Text =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Is_Surface_Entry;

   function Focus_Target_For_Surface_Command
     (Id : Editor.Commands.Command_Id) return Focus_Owner
   is
   begin
      case Id is
         when Editor.Commands.Command_Open_Command_Palette =>
            return Focus_Command_Palette;
         when Editor.Commands.Command_Open_Quick_Open
            | Editor.Commands.Command_Toggle_Quick_Open =>
            return Focus_Quick_Open;
         when Editor.Commands.Command_Open_Buffer_Switcher =>
            return Focus_Buffer_List;
         when Editor.Commands.Command_Open_Project_Search_Bar
            | Editor.Commands.Command_Toggle_Project_Search_Bar =>
            return Focus_Project_Search_Query;
         when Editor.Commands.Command_Show_Search_Results_Panel
            | Editor.Commands.Command_Focus_Search_Results =>
            return Focus_Project_Search_Results;
         when Editor.Commands.Command_Toggle_Bottom_Panel_Focus =>
            return Focus_Project_Search_Results;
         when Editor.Commands.Command_Focus_File_Tree =>
            return Focus_File_Tree;
         when Editor.Commands.Command_Show_Feature_Panel
            | Editor.Commands.Command_Toggle_Feature_Panel
            | Editor.Commands.Command_Focus_Feature_Panel
            | Editor.Commands.Command_Show_Outline
            | Editor.Commands.Command_Focus_Outline =>
            return Focus_Outline;
         when Editor.Commands.Command_Focus_Outline_Filter =>
            return Focus_Outline_Filter;
         when Editor.Commands.Command_Diagnostics_Show
            | Editor.Commands.Command_Toggle_Problems_Panel
            | Editor.Commands.Command_Focus_Problems =>
            return Focus_Diagnostics;
         when Editor.Commands.Command_Build_UI_Show
            | Editor.Commands.Command_Build_UI_Toggle
            | Editor.Commands.Command_Build_UI_Focus =>
            return Focus_Build_UI;
         when Editor.Commands.Command_Show_Recent_Projects =>
            return Focus_Recent_Projects;
         when Editor.Commands.Command_Goto_Line
            | Editor.Commands.Command_Goto_Line_Toggle
            | Editor.Commands.Command_Goto_Line_Prefill_Current
            | Editor.Commands.Command_Find_Show
            | Editor.Commands.Command_Find_Toggle
            | Editor.Commands.Command_Replace_Show
            | Editor.Commands.Command_Replace_Toggle =>
            return Focus_Workspace_Prompt;
         when Editor.Commands.Command_Focus_Editor_Text =>
            return Focus_Editor;
         when others =>
            return Focus_None;
      end case;
   end Focus_Target_For_Surface_Command;

   function Is_Editor_Text_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Move_Left
            | Editor.Commands.Command_Move_Right
            | Editor.Commands.Command_Move_Up
            | Editor.Commands.Command_Move_Down
            | Editor.Commands.Command_Move_Line_Start
            | Editor.Commands.Command_Move_Line_End
            | Editor.Commands.Command_Move_Document_Start
            | Editor.Commands.Command_Move_Document_End
            | Editor.Commands.Command_Move_Word_Left
            | Editor.Commands.Command_Move_Word_Right
            | Editor.Commands.Command_Page_Up
            | Editor.Commands.Command_Page_Down
            | Editor.Commands.Command_Select_Left
            | Editor.Commands.Command_Select_Right
            | Editor.Commands.Command_Select_Up
            | Editor.Commands.Command_Select_Down
            | Editor.Commands.Command_Select_Word_Left
            | Editor.Commands.Command_Select_Word_Right
            | Editor.Commands.Command_Select_Word
            | Editor.Commands.Command_Select_Line
            | Editor.Commands.Command_Start_Rectangular_Selection
            | Editor.Commands.Command_Clear_Rectangular_Selection
            | Editor.Commands.Command_Extend_Selection_Line_Up
            | Editor.Commands.Command_Extend_Selection_Line_Down
            | Editor.Commands.Command_Select_Line_Start
            | Editor.Commands.Command_Select_Line_End
            | Editor.Commands.Command_Select_Document_Start
            | Editor.Commands.Command_Select_Document_End
            | Editor.Commands.Command_Select_Page_Up
            | Editor.Commands.Command_Select_Page_Down
            | Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Undo
            | Editor.Commands.Command_Redo
            | Editor.Commands.Command_Edit_History_Clear
            | Editor.Commands.Command_Copy
            | Editor.Commands.Command_Cut
            | Editor.Commands.Command_Paste
            | Editor.Commands.Command_Clipboard_Clear
            | Editor.Commands.Command_Select_All
            | Editor.Commands.Command_Selection_Clear
            | Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret
            | Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Editor_Text_Command_Id;

   function Is_Quick_Open_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Open_Quick_Open
            .. Editor.Commands.Command_Quick_Open_Priority_Clear =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Quick_Open_Command_Id;

   function Is_Buffer_List_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Open_Buffer_Switcher
            .. Editor.Commands.Command_Buffer_Switcher_Mark_Summary =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Buffer_List_Command_Id;

   function Is_Project_Search_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Run_Project_Search
            .. Editor.Commands.Command_Project_Search_Replace_Clear_Preview
            | Editor.Commands.Command_Show_Search_Results_Panel
            | Editor.Commands.Command_Focus_Search_Results
            | Editor.Commands.Command_Search_Results_Move_Up
            | Editor.Commands.Command_Search_Results_Move_Down
            | Editor.Commands.Command_Search_Results_Page_Up
            | Editor.Commands.Command_Search_Results_Page_Down
            | Editor.Commands.Command_Search_Results_Open_Selected
            | Editor.Commands.Command_Search_Results_Search_Active_Buffer
            | Editor.Commands.Command_Search_Results_Focus_Query
            | Editor.Commands.Command_Search_Results_Repeat_Active_Buffer
            | Editor.Commands.Command_Search_Results_Query_History_Previous
            | Editor.Commands.Command_Search_Results_Query_History_Next
            | Editor.Commands.Command_Search_Results_Toggle_Case_Sensitive
            | Editor.Commands.Command_Show_Search_Results_Feature
            | Editor.Commands.Command_Clear_Search_Results_Feature =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Project_Search_Command_Id;

   function Is_Feature_Search_Query_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      --  The embedded Search Results query field shares the public
      --  Focus_Project_Search_Query owner label with the Project Search Bar,
      --  but it is not the Project Search Bar overlay.  Keep its command
      --  family narrow so Close/Toggle Project Search Bar and replace-preview
      --  commands cannot accidentally dismiss or mutate the embedded query.
      case Id is
         when Editor.Commands.Command_Search_Results_Search_Active_Buffer
            | Editor.Commands.Command_Search_Results_Focus_Query
            | Editor.Commands.Command_Search_Results_Repeat_Active_Buffer
            | Editor.Commands.Command_Search_Results_Query_History_Previous
            | Editor.Commands.Command_Search_Results_Query_History_Next
            | Editor.Commands.Command_Search_Results_Toggle_Case_Sensitive
            | Editor.Commands.Command_Search_Results_Move_Up
            | Editor.Commands.Command_Search_Results_Move_Down
            | Editor.Commands.Command_Search_Results_Page_Up
            | Editor.Commands.Command_Search_Results_Page_Down
            | Editor.Commands.Command_Search_Results_Open_Selected
            | Editor.Commands.Command_Show_Search_Results_Feature
            | Editor.Commands.Command_Clear_Search_Results_Feature
            | Editor.Commands.Command_Feature_Panel_Select_Next
            | Editor.Commands.Command_Feature_Panel_Select_Previous
            | Editor.Commands.Command_Feature_Panel_Open_Selected =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Feature_Search_Query_Command_Id;

   function Is_File_Tree_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Refresh_File_Tree
            | Editor.Commands.Command_Refresh_Project_Files
            | Editor.Commands.Command_Project_Files_Summary
            | Editor.Commands.Command_Reveal_Active_File_In_Tree
            | Editor.Commands.Command_Focus_File_Tree
            | Editor.Commands.Command_File_Tree_Move_Up
            | Editor.Commands.Command_File_Tree_Move_Down
            | Editor.Commands.Command_File_Tree_Page_Up
            | Editor.Commands.Command_File_Tree_Page_Down
            | Editor.Commands.Command_File_Tree_Open_Selected
            | Editor.Commands.Command_File_Tree_Create_File
            | Editor.Commands.Command_File_Tree_Create_Directory
            | Editor.Commands.Command_File_Tree_Rename_Selected
            | Editor.Commands.Command_File_Tree_Delete_Selected
            | Editor.Commands.Command_File_Tree_Expand_Selected
            | Editor.Commands.Command_File_Tree_Collapse_Selected
            | Editor.Commands.Command_File_Tree_Toggle_Selected
            | Editor.Commands.Command_File_Tree_Collapse_All
            | Editor.Commands.Command_File_Tree_Expand_To_Active_File =>
            return True;
         when others =>
            return False;
      end case;
   end Is_File_Tree_Command_Id;

   function Is_Outline_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Toggle_Feature_Panel
            | Editor.Commands.Command_Show_Feature_Panel
            | Editor.Commands.Command_Hide_Feature_Panel
            | Editor.Commands.Command_Focus_Feature_Panel
            | Editor.Commands.Command_Clear_Feature_Panel
            | Editor.Commands.Command_Feature_Panel_Select_Next
            | Editor.Commands.Command_Feature_Panel_Select_Previous
            | Editor.Commands.Command_Feature_Panel_Open_Selected
            | Editor.Commands.Command_Refresh_Outline
            | Editor.Commands.Command_Clear_Outline
            | Editor.Commands.Command_Show_Outline
            | Editor.Commands.Command_Focus_Outline
            | Editor.Commands.Command_Open_Selected_Outline_Item
            | Editor.Commands.Command_Select_Current_Outline_Symbol
            | Editor.Commands.Command_Reveal_Current_Outline_Symbol
            | Editor.Commands.Command_Next_Outline_Symbol
            | Editor.Commands.Command_Previous_Outline_Symbol
            | Editor.Commands.Command_Select_Next_Outline_Item
            | Editor.Commands.Command_Select_Previous_Outline_Item
            | Editor.Commands.Command_Focus_Outline_Filter
            | Editor.Commands.Command_Filter_Outline
            | Editor.Commands.Command_Clear_Outline_Filter
            | Editor.Commands.Command_Toggle_Outline_Filter
            | Editor.Commands.Command_Outline_Filter_History_Previous
            | Editor.Commands.Command_Outline_Filter_History_Next
            | Editor.Commands.Command_Clear_Outline_Filter_History =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Outline_Command_Id;

   function Is_Diagnostics_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Toggle_Problems_Panel
            | Editor.Commands.Command_Focus_Problems
            | Editor.Commands.Command_Problems_Move_Up
            | Editor.Commands.Command_Problems_Move_Down
            | Editor.Commands.Command_Problems_Page_Up
            | Editor.Commands.Command_Problems_Page_Down
            | Editor.Commands.Command_Problems_Open_Selected
            | Editor.Commands.Command_Problems_Focus_Editor
            | Editor.Commands.Command_Diagnostics_Show
            .. Editor.Commands.Command_Diagnostics_Toggle_Unknown_Source =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Diagnostics_Command_Id;

   function Is_Build_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Build_UI_Toggle
            .. Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Build_Command_Id;

   function Is_Recent_Projects_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Show_Recent_Projects
            | Editor.Commands.Command_Open_Selected_Recent_Project
            | Editor.Commands.Command_Clear_Recent_Projects
            | Editor.Commands.Command_Remove_Selected_Recent_Project
            | Editor.Commands.Command_Remove_Missing_Recent_Projects
            | Editor.Commands.Command_Select_Next_Recent_Project
            | Editor.Commands.Command_Select_Previous_Recent_Project =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Recent_Projects_Command_Id;


   function Is_Workspace_Prompt_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Goto_Line
            | Editor.Commands.Command_Goto_Line_Toggle
            | Editor.Commands.Command_Goto_Line_Prefill_Current
            | Editor.Commands.Command_Goto_Line_Query_Set
            | Editor.Commands.Command_Goto_Line_Query_Clear
            | Editor.Commands.Command_Close_Goto_Line
            | Editor.Commands.Command_Accept_Goto_Line
            | Editor.Commands.Command_Find_Show
            | Editor.Commands.Command_Find_Hide
            | Editor.Commands.Command_Find_Toggle
            | Editor.Commands.Command_Find_Query_Set
            | Editor.Commands.Command_Find_Query_Clear
            | Editor.Commands.Command_Find_Case_Toggle
            | Editor.Commands.Command_Find_Case_Clear
            | Editor.Commands.Command_Find_Whole_Word_Toggle
            | Editor.Commands.Command_Find_Whole_Word_Clear
            | Editor.Commands.Command_Find_From_Selection
            | Editor.Commands.Command_Find_From_Active_Word
            | Editor.Commands.Command_Active_Find_Next
            | Editor.Commands.Command_Active_Find_Previous
            | Editor.Commands.Command_Find_First
            | Editor.Commands.Command_Find_Last
            | Editor.Commands.Command_Find_Reveal_Current
            | Editor.Commands.Command_Replace_Show
            | Editor.Commands.Command_Replace_Hide
            | Editor.Commands.Command_Replace_Toggle
            | Editor.Commands.Command_Replace_Text_Set
            | Editor.Commands.Command_Replace_Text_Clear
            | Editor.Commands.Command_Replace_Current
            | Editor.Commands.Command_Replace_All =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Workspace_Prompt_Command_Id;

   function Is_Overlay_Local_Command_Id
     (Owner : Focus_Owner;
      Id    : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Owner is
         when Focus_Command_Palette =>
            return Id = Editor.Commands.Command_Open_Command_Palette
              or else Id = Editor.Commands.Command_Palette_Show_Command_Help;

         when Focus_Quick_Open =>
            return Is_Quick_Open_Command_Id (Id);

         when Focus_Buffer_List =>
            return Is_Buffer_List_Command_Id (Id);

         when Focus_Project_Search_Query | Focus_Project_Replace_Input =>
            return Is_Project_Search_Command_Id (Id);

         when Focus_Outline_Filter =>
            return Is_Outline_Command_Id (Id);

         when Focus_Workspace_Prompt =>
            return Is_Workspace_Prompt_Command_Id (Id);

         when others =>
            return False;
      end case;
   end Is_Overlay_Local_Command_Id;

   function Overlay_Focus_Owner
     (Owner : Focus_Owner) return Boolean
   is
   begin
      case Owner is
         when Focus_Command_Palette
            | Focus_Quick_Open
            | Focus_Project_Search_Query
            | Focus_Project_Replace_Input
            | Focus_Outline_Filter
            | Focus_Buffer_List
            | Focus_Workspace_Prompt =>
            return True;
         when others =>
            return False;
      end case;
   end Overlay_Focus_Owner;


   function Is_Status_Message_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Show_Messages
            | Editor.Commands.Command_Clear_Messages
            | Editor.Commands.Command_Clear_Selected_Message
            | Editor.Commands.Command_Copy_Selected_Message_Text
            | Editor.Commands.Command_Clear_Info_Messages
            | Editor.Commands.Command_Clear_Warning_Messages
            | Editor.Commands.Command_Clear_Error_Messages
            | Editor.Commands.Command_Toggle_Message_Info
            | Editor.Commands.Command_Toggle_Message_Warnings
            | Editor.Commands.Command_Toggle_Message_Errors
            | Editor.Commands.Command_Show_All_Messages
            | Editor.Commands.Command_Clear_Message_Filter
            | Editor.Commands.Command_Dismiss_Latest_Message
            | Editor.Commands.Command_Dismiss_All_Messages =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Status_Message_Command_Id;

   function Is_Safe_Global_Status_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      if Command_Is_Surface_Entry (Id) then
         return True;
      end if;

      if Is_Status_Message_Command_Id (Id) then
         return True;
      end if;

      case Id is
         when Editor.Commands.No_Command
            | Editor.Commands.Command_Cancel
            | Editor.Commands.Command_Focus_Editor_Text
            | Editor.Commands.Command_Open_Command_Palette
            | Editor.Commands.Command_Open_Quick_Open
            | Editor.Commands.Command_Toggle_Quick_Open
            | Editor.Commands.Command_Open_Buffer_Switcher
            | Editor.Commands.Command_Open_Project_Search_Bar
            | Editor.Commands.Command_Toggle_Project_Search_Bar
            | Editor.Commands.Command_Show_Recent_Projects
            | Editor.Commands.Command_Focus_File_Tree
            | Editor.Commands.Command_Toggle_Bottom_Panel_Focus
            | Editor.Commands.Command_Show_Search_Results_Panel
            | Editor.Commands.Command_Focus_Search_Results
            | Editor.Commands.Command_Focus_Problems
            | Editor.Commands.Command_Diagnostics_Show
            | Editor.Commands.Command_Toggle_Problems_Panel
            | Editor.Commands.Command_Build_UI_Show
            | Editor.Commands.Command_Build_UI_Toggle
            | Editor.Commands.Command_Build_UI_Focus
            | Editor.Commands.Command_Show_Feature_Panel
            | Editor.Commands.Command_Toggle_Feature_Panel
            | Editor.Commands.Command_Focus_Feature_Panel
            | Editor.Commands.Command_Show_Outline
            | Editor.Commands.Command_Focus_Outline
            | Editor.Commands.Command_Show_Messages
            | Editor.Commands.Command_Clear_Messages
            | Editor.Commands.Command_Dismiss_Latest_Message =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Safe_Global_Status_Command_Id;

   function Command_May_Run_In_Current_Focus
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return Boolean
   is
      Owner : constant Focus_Owner := Effective_Focus_Owner (S);
   begin
      if Owner = Focus_Pending_Confirmation then
         return Command_Allowed_While_Pending (Id);
      end if;

      if Overlay_Focus_Owner (Owner) then
         case Id is
            when Editor.Commands.No_Command
               | Editor.Commands.Command_Cancel =>
               return True;
            when others =>
               if Is_Status_Message_Command_Id (Id) then
                  return True;
               end if;

               if Owner in Focus_Project_Search_Query
                  | Focus_Project_Replace_Input
               then
                  if Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) =
                    Editor.Overlay_Focus.Project_Search_Bar_Overlay
                  then
                     return Is_Project_Search_Command_Id (Id)
                       or else Command_Closes_Focus_Owner (Id, Owner);
                  elsif Editor.Feature_Search_Results.Search_Input_Is_Active
                    (S.Feature_Search_Results)
                  then
                     return Is_Feature_Search_Query_Command_Id (Id);
                  else
                     return False;
                  end if;
               end if;

               return Is_Overlay_Local_Command_Id (Owner, Id)
                 or else Command_Closes_Focus_Owner (Id, Owner);
         end case;
      end if;

      if Is_Safe_Global_Status_Command_Id (Id) then
         return True;
      end if;

      case Owner is
         when Focus_Editor | Focus_None =>
            return True;

         when Focus_Command_Palette =>
            --  Arbitrary palette-selected commands are executed only after the
            --  palette accepts and dismisses itself.  While the palette itself
            --  owns input, only palette-local/open-close commands may run.
            return Id = Editor.Commands.Command_Open_Command_Palette
              or else Id = Editor.Commands.Command_Palette_Show_Command_Help;

         when Focus_Quick_Open =>
            return Is_Quick_Open_Command_Id (Id);

         when Focus_Buffer_List =>
            return Is_Buffer_List_Command_Id (Id);

         when Focus_Project_Search_Query
            | Focus_Project_Replace_Input
            | Focus_Project_Search_Results =>
            return Is_Project_Search_Command_Id (Id);

         when Focus_File_Tree =>
            return Is_File_Tree_Command_Id (Id);

         when Focus_Outline | Focus_Outline_Filter =>
            return Is_Outline_Command_Id (Id);

         when Focus_Diagnostics =>
            return Is_Diagnostics_Command_Id (Id);

         when Focus_Build_UI =>
            return Is_Build_Command_Id (Id);

         when Focus_Build_Result_Summary
            | Focus_Build_Output_Details =>
            return Is_Build_Command_Id (Id)
              and then not Is_Editor_Text_Command_Id (Id);

         when Focus_Recent_Projects =>
            return Is_Recent_Projects_Command_Id (Id);

         when Focus_Workspace_Prompt =>
            --  Prompt overlays own local text and confirmation input.  They
            --  should not permit stale panel activation or editor mutation from
            --  the previously focused surface, but retained prompt-local
            --  command families (find/go-to-line/replace field controls) remain
            --  valid while the prompt owns focus.
            return Is_Workspace_Prompt_Command_Id (Id);

         when Focus_Pending_Confirmation =>
            return Command_Allowed_While_Pending (Id);
      end case;
   end Command_May_Run_In_Current_Focus;

   function Activation_Returns_Focus_To_Editor
     (Owner : Focus_Owner) return Boolean
   is
   begin
      case Owner is
         when Focus_Quick_Open
            | Focus_File_Tree
            | Focus_Project_Search_Results
            | Focus_Outline
            | Focus_Diagnostics
            | Focus_Buffer_List
            | Focus_Recent_Projects =>
            return True;
         when others =>
            return False;
      end case;
   end Activation_Returns_Focus_To_Editor;

   function Escape_Returns_Focus_To_Editor
     (Owner : Focus_Owner) return Boolean
   is
   begin
      case Owner is
         when Focus_File_Tree
            | Focus_Project_Search_Results
            | Focus_Outline
            | Focus_Diagnostics
            | Focus_Build_UI
            | Focus_Build_Result_Summary
            | Focus_Build_Output_Details
            | Focus_Recent_Projects =>
            return True;
         when others =>
            return False;
      end case;
   end Escape_Returns_Focus_To_Editor;


   function Escape_Closes_Overlay
     (Owner : Focus_Owner) return Boolean
   is
   begin
      case Owner is
         when Focus_Command_Palette
            | Focus_Quick_Open
            | Focus_Project_Search_Query
            | Focus_Project_Replace_Input
            | Focus_Outline_Filter
            | Focus_Buffer_List
            | Focus_Workspace_Prompt =>
            return True;
         when others =>
            return False;
      end case;
   end Escape_Closes_Overlay;

   function Command_Is_Panel_Local_Navigation
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Quick_Open_Next_Result
            | Editor.Commands.Command_Quick_Open_Previous_Result
            | Editor.Commands.Command_Buffer_Switcher_Next_Result
            | Editor.Commands.Command_Buffer_Switcher_Previous_Result
            | Editor.Commands.Command_Search_Results_Move_Up
            | Editor.Commands.Command_Search_Results_Move_Down
            | Editor.Commands.Command_Search_Results_Page_Up
            | Editor.Commands.Command_Search_Results_Page_Down
            | Editor.Commands.Command_Move_Project_Search_Selection_Up
            | Editor.Commands.Command_Move_Project_Search_Selection_Down
            | Editor.Commands.Command_Next_Project_Search_Result
            | Editor.Commands.Command_Previous_Project_Search_Result
            | Editor.Commands.Command_First_Project_Search_Result
            | Editor.Commands.Command_Last_Project_Search_Result
            | Editor.Commands.Command_File_Tree_Move_Up
            | Editor.Commands.Command_File_Tree_Move_Down
            | Editor.Commands.Command_File_Tree_Page_Up
            | Editor.Commands.Command_File_Tree_Page_Down
            | Editor.Commands.Command_File_Tree_Expand_Selected
            | Editor.Commands.Command_File_Tree_Collapse_Selected
            | Editor.Commands.Command_File_Tree_Toggle_Selected
            | Editor.Commands.Command_Feature_Panel_Select_Next
            | Editor.Commands.Command_Feature_Panel_Select_Previous
            | Editor.Commands.Command_Select_Next_Outline_Item
            | Editor.Commands.Command_Select_Previous_Outline_Item
            | Editor.Commands.Command_Problems_Move_Up
            | Editor.Commands.Command_Problems_Move_Down
            | Editor.Commands.Command_Problems_Page_Up
            | Editor.Commands.Command_Problems_Page_Down
            | Editor.Commands.Command_Diagnostics_Select_Next
            | Editor.Commands.Command_Diagnostics_Select_Previous
            | Editor.Commands.Command_Build_Select_Next_Candidate
            | Editor.Commands.Command_Build_Select_Previous_Candidate
            | Editor.Commands.Command_Select_Next_Recent_Project
            | Editor.Commands.Command_Select_Previous_Recent_Project =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Is_Panel_Local_Navigation;

   function Command_Closes_Focused_Surface
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Cancel
            | Editor.Commands.Command_Close_Quick_Open
            | Editor.Commands.Command_Toggle_Quick_Open
            | Editor.Commands.Command_Close_Buffer_Switcher
            | Editor.Commands.Command_Close_Project_Search_Bar
            | Editor.Commands.Command_Toggle_Project_Search_Bar
            | Editor.Commands.Command_Hide_Feature_Panel
            | Editor.Commands.Command_Toggle_Feature_Panel
            | Editor.Commands.Command_Clear_Feature_Panel
            | Editor.Commands.Command_Clear_Search_Results_Feature
            | Editor.Commands.Command_Toggle_Problems_Panel
            | Editor.Commands.Command_Build_UI_Hide
            | Editor.Commands.Command_Build_UI_Toggle
            | Editor.Commands.Command_Find_Hide
            | Editor.Commands.Command_Find_Toggle
            | Editor.Commands.Command_Replace_Hide
            | Editor.Commands.Command_Replace_Toggle
            | Editor.Commands.Command_Close_Goto_Line
            | Editor.Commands.Command_Goto_Line_Toggle =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Closes_Focused_Surface;


   function Command_Toggles_Focus_Owner
     (Id    : Editor.Commands.Command_Id;
      Owner : Focus_Owner) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Toggle_Quick_Open =>
            return Owner = Focus_Quick_Open;

         when Editor.Commands.Command_Toggle_Project_Search_Bar =>
            return Owner in Focus_Project_Search_Query
              | Focus_Project_Replace_Input;

         when Editor.Commands.Command_Toggle_Feature_Panel =>
            return Owner in Focus_Outline | Focus_Outline_Filter
              | Focus_Diagnostics | Focus_Project_Search_Results;

         when Editor.Commands.Command_Toggle_Problems_Panel =>
            return Owner = Focus_Diagnostics;

         when Editor.Commands.Command_Build_UI_Toggle =>
            return Owner in Focus_Build_UI
              | Focus_Build_Result_Summary
              | Focus_Build_Output_Details;

         when Editor.Commands.Command_Find_Toggle
            | Editor.Commands.Command_Replace_Toggle
            | Editor.Commands.Command_Goto_Line_Toggle =>
            return Owner = Focus_Workspace_Prompt;

         when others =>
            return False;
      end case;
   end Command_Toggles_Focus_Owner;

   function Command_Closes_Focus_Owner
     (Id    : Editor.Commands.Command_Id;
      Owner : Focus_Owner) return Boolean
   is
   begin
      if Command_Toggles_Focus_Owner (Id, Owner) then
         return True;
      end if;

      case Id is
         when Editor.Commands.Command_Cancel =>
            return Escape_Closes_Overlay (Owner)
              or else Escape_Returns_Focus_To_Editor (Owner);

         when Editor.Commands.Command_Close_Quick_Open =>
            return Owner = Focus_Quick_Open;

         when Editor.Commands.Command_Close_Buffer_Switcher =>
            return Owner = Focus_Buffer_List;

         when Editor.Commands.Command_Close_Project_Search_Bar =>
            return Owner in Focus_Project_Search_Query
              | Focus_Project_Replace_Input;

         when Editor.Commands.Command_Find_Hide
            | Editor.Commands.Command_Replace_Hide
            | Editor.Commands.Command_Close_Goto_Line =>
            return Owner = Focus_Workspace_Prompt;

         when Editor.Commands.Command_Hide_Feature_Panel
            | Editor.Commands.Command_Clear_Feature_Panel =>
            return Owner in Focus_Outline | Focus_Outline_Filter
              | Focus_Diagnostics | Focus_Project_Search_Results;

         when Editor.Commands.Command_Clear_Search_Results_Feature =>
            return Owner = Focus_Project_Search_Results;

         when Editor.Commands.Command_Build_UI_Hide =>
            return Owner in Focus_Build_UI
              | Focus_Build_Result_Summary
              | Focus_Build_Output_Details;

         when others =>
            return False;
      end case;
   end Command_Closes_Focus_Owner;

   function Command_Returns_Focus_To_Editor
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Accept_Quick_Open
            | Editor.Commands.Command_Open_File
            | Editor.Commands.Command_Quick_Open_Create_From_Query
            | Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query
            | Editor.Commands.Command_Accept_Buffer_Switcher
            | Editor.Commands.Command_File_Tree_Open_Selected
            | Editor.Commands.Command_Search_Results_Open_Selected
            | Editor.Commands.Command_Open_Selected_Project_Search_Result
            | Editor.Commands.Command_Feature_Panel_Open_Selected
            | Editor.Commands.Command_Open_Selected_Outline_Item
            | Editor.Commands.Command_Problems_Open_Selected
            | Editor.Commands.Command_Diagnostics_Open_Selected
            | Editor.Commands.Command_Open_Selected_Recent_Project
            | Editor.Commands.Command_Accept_Goto_Line
            | Editor.Commands.Command_Problems_Focus_Editor
            | Editor.Commands.Command_Focus_Editor_Text =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Returns_Focus_To_Editor;

   function Focus_State_Is_Persistable
     (Owner : Focus_Owner) return Boolean
   is
      pragma Unreferenced (Owner);
   begin
      return False;
   end Focus_State_Is_Persistable;


   function Feature_Search_Input_Has_Valid_Parent
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return (not Editor.Feature_Search_Results.Search_Input_Is_Active
          (S.Feature_Search_Results))
        or else
          (Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
           and then Editor.Feature_Panel.Is_Focused (S.Feature_Panel)
           and then Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
             Editor.Feature_Panel.Search_Results_Feature);
   end Feature_Search_Input_Has_Valid_Parent;

   function Outline_Filter_Input_Has_Valid_Parent
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return (not Editor.Outline.Filter_Input_Is_Active (S.Outline))
        or else
          (Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
           and then Editor.Feature_Panel.Is_Focused (S.Feature_Panel)
           and then Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
             Editor.Feature_Panel.Outline_Feature);
   end Outline_Filter_Input_Has_Valid_Parent;

   function Focus_State_Has_No_Competing_Owners
     (S : Editor.State.State_Type) return Boolean
   is
      Explicit_Owner_Count : Natural := 0;

      procedure Count (Present : Boolean) is
      begin
         if Present then
            Explicit_Owner_Count := Explicit_Owner_Count + 1;
         end if;
      end Count;
   begin
      --  A pending confirmation is modal and deliberately supersedes any
      --  previous focus context retained for cancellation.  The one-owner
      --  invariant for normal input ownership is checked when no modal
      --  confirmation is active.
      if Pending_Confirmation_Owns_Focus (S) then
         return Effective_Focus_Owner (S) = Focus_Pending_Confirmation;
      end if;

      Count (Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus));
      Count (Editor.Feature_Search_Results.Search_Input_Is_Active
        (S.Feature_Search_Results));
      Count (Editor.Outline.Filter_Input_Is_Active (S.Outline));
      Count (Editor.Feature_Panel.Is_Focused (S.Feature_Panel)
        and then not Editor.Feature_Search_Results.Search_Input_Is_Active
          (S.Feature_Search_Results)
        and then not Editor.Outline.Filter_Input_Is_Active (S.Outline));
      Count (S.Build_UI.Build_UI_Focused);
      Count (S.Latest_Build_Result_Focused);
      Count (S.Latest_Build_Output_Details.Build_Output_Details_Focused);
      Count (S.Recent_Projects_Focused);

      --  Embedded text inputs are valid only when their parent Feature Panel
      --  surface remains visible and focused.  They are child owners, not
      --  independent surfaces that may float above an unrelated retained panel.
      if not Feature_Search_Input_Has_Valid_Parent (S) then
         return False;
      end if;

      if not Outline_Filter_Input_Has_Valid_Parent (S) then
         return False;
      end if;

      --  Panel_Focus always has a structural target and is therefore not
      --  counted as a competing transient owner.  It is the fallback owner
      --  when no overlay/input/build/recent marker is active, and it is also
      --  the retained previous target while overlays are open.
      return Explicit_Owner_Count <= 1;
   end Focus_State_Has_No_Competing_Owners;

   procedure Clear_Overlay_And_Local_Text_Focus
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus) then
         Editor.Overlay_Focus.Dismiss
           (S.Overlay_Focus, Editor.Overlay_Focus.Dismiss_Command);
      end if;

      S.Build_UI.Build_UI_Focused := False;
      S.Latest_Build_Result_Focused := False;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := False;
      S.Recent_Projects_Focused := False;

      if Editor.Feature_Search_Results.Search_Input_Is_Active
        (S.Feature_Search_Results)
      then
         Editor.Feature_Search_Results.Deactivate_Search_Query_Input
           (S.Feature_Search_Results);
      end if;

      if Editor.Outline.Filter_Input_Is_Active (S.Outline) then
         Editor.Outline.Deactivate_Filter_Input (S.Outline);
      end if;
   end Clear_Overlay_And_Local_Text_Focus;

   procedure Clear_Transient_Focus_Owners
     (S : in out Editor.State.State_Type)
   is
   begin
      --  Pointer and local-surface focus paths sometimes need to retain the
      --  structural parent surface they are about to focus while clearing
      --  stale overlay/build/recent child owners.  This is intentionally
      --  narrower than Restore_Focus_To_Editor and does not change
      --  Feature_Panel focus or Panel_Focus.
      Clear_Overlay_And_Local_Text_Focus (S);
   end Clear_Transient_Focus_Owners;

   procedure Restore_Focus_To_Editor
     (S : in out Editor.State.State_Type)
   is
   begin
      Clear_Overlay_And_Local_Text_Focus (S);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, False);
      S.Build_UI.Build_UI_Focused := False;
      S.Latest_Build_Result_Focused := False;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := False;
      S.Recent_Projects_Focused := False;
      Editor.Panel_Focus.Focus_Editor_Text (S.Panel_Focus);
   end Restore_Focus_To_Editor;


   function Previous_Focus_Target_Still_Valid
     (S      : Editor.State.State_Type;
      Target : Editor.Overlay_Focus.Previous_Focus_Target) return Boolean
   is
   begin
      case Target is
         when Editor.Overlay_Focus.Previous_Editor_Text =>
            return True;
         when Editor.Overlay_Focus.Previous_File_Tree =>
            return Editor.Project.Has_Project (S.Project)
              and then Editor.Panels.Is_Visible
                (S.Panels, Editor.Panels.File_Tree_Panel);
         when Editor.Overlay_Focus.Previous_Search_Results =>
            return Editor.Panels.Is_Visible
                (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content;
         when Editor.Overlay_Focus.Previous_Problems =>
            return Editor.Panels.Is_Visible
                (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Problems_Content;
         when Editor.Overlay_Focus.Previous_None =>
            return False;
      end case;
   end Previous_Focus_Target_Still_Valid;

   procedure Restore_Previous_Focus_Or_Editor
     (S : in out Editor.State.State_Type)
   is
      Previous : constant Editor.Overlay_Focus.Previous_Focus_Target :=
        Editor.Overlay_Focus.Previous_Focus (S.Overlay_Focus);
   begin
      Clear_Overlay_And_Local_Text_Focus (S);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, False);

      if not Previous_Focus_Target_Still_Valid (S, Previous) then
         Editor.Panel_Focus.Focus_Editor_Text (S.Panel_Focus);
         return;
      end if;

      case Previous is
         when Editor.Overlay_Focus.Previous_File_Tree =>
            Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
         when Editor.Overlay_Focus.Previous_Search_Results =>
            Editor.Panel_Focus.Focus_Bottom_Panel
              (S.Panel_Focus, Editor.Panel_Focus.Search_Results_Focus);
         when Editor.Overlay_Focus.Previous_Problems =>
            Editor.Panel_Focus.Focus_Bottom_Panel
              (S.Panel_Focus, Editor.Panel_Focus.Problems_Focus);
         when Editor.Overlay_Focus.Previous_Editor_Text
            | Editor.Overlay_Focus.Previous_None =>
            Editor.Panel_Focus.Focus_Editor_Text (S.Panel_Focus);
      end case;
   end Restore_Previous_Focus_Or_Editor;

   procedure Set_Focus_Owner
     (S     : in out Editor.State.State_Type;
      Owner : Focus_Owner)
   is
   begin
      if Owner = Focus_Pending_Confirmation then
         --  Pending confirmation focus is derived from Pending_Transitions;
         --  callers must create/cancel that modal payload through the
         --  canonical lifecycle path.  Do not fabricate it here.
         return;
      end if;

      Clear_Overlay_And_Local_Text_Focus (S);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, False);

      case Owner is
         when Focus_None | Focus_Editor =>
            Editor.Panel_Focus.Focus_Editor_Text (S.Panel_Focus);
         when Focus_Command_Palette =>
            Editor.Overlay_Focus.Activate
              (S.Overlay_Focus,
               Editor.Overlay_Focus.Command_Palette_Overlay,
               S.Panel_Focus);
         when Focus_Quick_Open =>
            Editor.Overlay_Focus.Activate
              (S.Overlay_Focus,
               Editor.Overlay_Focus.Quick_Open_Overlay,
               S.Panel_Focus);
         when Focus_Project_Search_Query =>
            Editor.Project_Search_Bar.Focus_Query_Field (S.Project_Search_Bar);
            Editor.Overlay_Focus.Activate
              (S.Overlay_Focus,
               Editor.Overlay_Focus.Project_Search_Bar_Overlay,
               S.Panel_Focus);
         when Focus_Project_Replace_Input =>
            Editor.Project_Search_Bar.Focus_Replace_Field (S.Project_Search_Bar);
            Editor.Overlay_Focus.Activate
              (S.Overlay_Focus,
               Editor.Overlay_Focus.Project_Search_Bar_Overlay,
               S.Panel_Focus);
         when Focus_Buffer_List =>
            Editor.Overlay_Focus.Activate
              (S.Overlay_Focus,
               Editor.Overlay_Focus.Buffer_Switcher_Overlay,
               S.Panel_Focus);
         when Focus_Workspace_Prompt =>
            Editor.Overlay_Focus.Activate
              (S.Overlay_Focus,
               Editor.Overlay_Focus.File_Target_Prompt_Overlay,
               S.Panel_Focus);
         when Focus_File_Tree =>
            Editor.Panels.Set_Visible
              (S.Panels, Editor.Panels.File_Tree_Panel, True);
            Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
         when Focus_Project_Search_Results =>
            Editor.Panels.Set_Bottom_Content
              (S.Panels, Editor.Panels.Search_Results_Content);
            Editor.Panels.Set_Visible
              (S.Panels, Editor.Panels.Bottom_Panel, True);
            Editor.Panel_Focus.Focus_Bottom_Panel
              (S.Panel_Focus, Editor.Panel_Focus.Search_Results_Focus);
         when Focus_Diagnostics =>
            Editor.Panels.Set_Bottom_Content
              (S.Panels, Editor.Panels.Problems_Content);
            Editor.Panels.Set_Visible
              (S.Panels, Editor.Panels.Bottom_Panel, True);
            Editor.Panel_Focus.Focus_Bottom_Panel
              (S.Panel_Focus, Editor.Panel_Focus.Problems_Focus);
         when Focus_Outline =>
            declare
               Accepted : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
                 (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
            begin
               pragma Unreferenced (Accepted);
               Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
               Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
            end;
         when Focus_Outline_Filter =>
            declare
               Accepted : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
                 (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
            begin
               pragma Unreferenced (Accepted);
               Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
               Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
               Editor.Outline.Activate_Filter_Input (S.Outline);
            end;
         when Focus_Build_UI =>
            Editor.Build_UI.Focus (S.Build_UI);
         when Focus_Build_Result_Summary =>
            --  The latest build result summary is display-only, but it still
            --  needs an explicit transient focus owner so local navigation,
            --  Escape policy, and status/render labels do not fall through to
            --  editor text focus.
            S.Latest_Build_Result_Focused := True;
         when Focus_Build_Output_Details =>
            Editor.Build_Output_Details.Focus_Output_Details
              (S.Latest_Build_Output_Details);
         when Focus_Recent_Projects =>
            --  Recent Projects has a list selection but no separate panel
            --  focus package.  Keep the focus marker in State as transient UI
            --  state and leave recent-project persistence untouched.
            S.Recent_Projects_Focused := True;
         when Focus_Pending_Confirmation =>
            null;
      end case;
   end Set_Focus_Owner;

   function Command_Focuses_Surface_After_Execution
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      --  Open/show/focus commands are deterministic surface-entry commands.
      --  Toggle commands are intentionally excluded here: after execution the
      --  focused surface may have been closed, and blindly applying the target
      --  would reopen or refocus a dismissed overlay/panel.
      case Id is
         when Editor.Commands.Command_Open_Command_Palette
            | Editor.Commands.Command_Open_Quick_Open
            | Editor.Commands.Command_Open_Buffer_Switcher
            | Editor.Commands.Command_Open_Project_Search_Bar
            | Editor.Commands.Command_Show_Search_Results_Panel
            | Editor.Commands.Command_Focus_Search_Results
            | Editor.Commands.Command_Focus_File_Tree
            | Editor.Commands.Command_Show_Feature_Panel
            | Editor.Commands.Command_Focus_Feature_Panel
            | Editor.Commands.Command_Show_Outline
            | Editor.Commands.Command_Focus_Outline
            | Editor.Commands.Command_Focus_Outline_Filter
            | Editor.Commands.Command_Diagnostics_Show
            | Editor.Commands.Command_Focus_Problems
            | Editor.Commands.Command_Build_UI_Show
            | Editor.Commands.Command_Build_UI_Focus
            | Editor.Commands.Command_Show_Recent_Projects
            | Editor.Commands.Command_Goto_Line
            | Editor.Commands.Command_Goto_Line_Prefill_Current
            | Editor.Commands.Command_Find_Show
            | Editor.Commands.Command_Replace_Show
            | Editor.Commands.Command_Focus_Editor_Text =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Focuses_Surface_After_Execution;

   procedure Apply_Command_Focus_Result
     (S            : in out Editor.State.State_Type;
      Id           : Editor.Commands.Command_Id;
      Owner_Before : Focus_Owner := Focus_None)
   is
      Target : constant Focus_Owner := Focus_Target_For_Surface_Command (Id);
      Closing_Owner : constant Focus_Owner :=
        (if Owner_Before = Focus_None then Effective_Focus_Owner (S)
         else Owner_Before);
   begin
      if Command_Returns_Focus_To_Editor (Id) then
         Restore_Focus_To_Editor (S);
      elsif Command_Closes_Focus_Owner (Id, Closing_Owner) then
         if Escape_Returns_Focus_To_Editor (Closing_Owner) then
            Restore_Focus_To_Editor (S);
         else
            Restore_Previous_Focus_Or_Editor (S);
         end if;
      elsif Command_Focuses_Surface_After_Execution (Id)
        and then Target /= Focus_None
      then
         if Target = Focus_Workspace_Prompt then
            --  Prompt entry commands are implemented by the canonical
            --  Executor and each prompt has a distinct overlay identity
            --  (go-to-line, active find/replace, or file-target prompt).
            --  The generic focus owner deliberately collapses those into
            --  Focus_Workspace_Prompt for priority/routing, but post-command
            --  focus policy must not fabricate File_Target_Prompt_Overlay
            --  after a Find or Go To Line command, nor open a prompt after a
            --  context-sensitive command reported unavailable.  Keep the
            --  Executor-created prompt overlay exactly as-is.
            null;
         else
            Set_Focus_Owner (S, Target);
         end if;
      end if;
   end Apply_Command_Focus_Result;

   function Command_Allowed_While_Pending
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.No_Command
            | Editor.Commands.Command_Cancel
            | Editor.Commands.Command_Cancel_Pending_Transition
            | Editor.Commands.Command_Retry_Pending_Transition
            | Editor.Commands.Command_Discard_Pending_Transition =>
            return True;
         when others =>
            return Is_Status_Message_Command_Id (Id);
      end case;
   end Command_Allowed_While_Pending;

   function Command_Is_Conflicting_While_Pending
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return not Command_Allowed_While_Pending (Id);
   end Command_Is_Conflicting_While_Pending;

   function Assert_Panel_Focus_Management_Coherent
     (S : Editor.State.State_Type) return Boolean
   is
      Owner : constant Focus_Owner := Effective_Focus_Owner (S);
   begin
      if not Focus_State_Has_No_Competing_Owners (S) then
         return False;
      end if;

      if Pending_Confirmation_Owns_Focus (S) then
         return Owner = Focus_Pending_Confirmation;
      elsif Overlay_Input_Owns_Text (S) then
         return Owner /= Focus_Editor;
      elsif Owner in Focus_Build_UI
         | Focus_Build_Result_Summary
         | Focus_Build_Output_Details
         | Focus_Recent_Projects
      then
         return True;
      elsif Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus) then
         return Owner = Focus_Editor;
      else
         return Owner /= Focus_Editor;
      end if;
   end Assert_Panel_Focus_Management_Coherent;

end Editor.Focus_Management;
