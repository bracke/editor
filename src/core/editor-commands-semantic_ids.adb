with Editor.Command_Kinds;
package body Editor.Commands.Semantic_Ids is

   function Is_Semantic_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Refresh_Outline
            | Command_Refresh_Outline_Project_Index
            | Command_Goto_Declaration
            | Command_Goto_Body
            | Command_Goto_Spec
            | Command_Find_References
            | Command_Workspace_Symbols
            | Command_Show_Hover
            | Command_Show_Completions
            | Command_Semantic_Completion_Select_Next
            | Command_Semantic_Completion_Select_Previous
            | Command_Semantic_Completion_Accept
            | Command_Semantic_Popup_Dismiss
            | Command_Rename_Symbol_Preview
            | Command_Rename_Symbol_Apply
            | Command_Semantic_Refresh_Buffer
            | Command_Semantic_Refresh_Project_Index
            | Command_Language_Index_Clear
            | Command_Language_Index_Status
            | Command_Clear_Outline
            | Command_Show_Outline
            | Command_Focus_Outline
            | Command_Open_Selected_Outline_Item
            | Command_Select_Current_Outline_Symbol
            | Command_Reveal_Current_Outline_Symbol
            | Command_Next_Outline_Symbol
            | Command_Previous_Outline_Symbol
            | Command_Select_Next_Outline_Item
            | Command_Select_Previous_Outline_Item
            | Command_Focus_Outline_Filter
            | Command_Filter_Outline
            | Command_Clear_Outline_Filter
            | Command_Toggle_Outline_Filter
            | Command_Outline_Filter_History_Previous
            | Command_Outline_Filter_History_Next
            | Command_Clear_Outline_Filter_History =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Semantic_Command;

end Editor.Commands.Semantic_Ids;
