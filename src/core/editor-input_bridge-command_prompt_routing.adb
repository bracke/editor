with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Executor;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Guided_Prompts;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Command_Prompt_Routing is

   use type Editor.Commands.Command_Id;
   use type Editor.File_Tree.File_Tree_Node_Id;

   function Command_Starts_Guided_Prompt
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Open_Project
            | Editor.Commands.Command_Switch_Project
            | Editor.Commands.Command_Restore_Workspace_State
            | Editor.Commands.Command_Save_Workspace_State
            | Editor.Commands.Command_Run_Project_Search
            | Editor.Commands.Command_Run_Project_Search_From_Bar
            | Editor.Commands.Command_Project_Search_Replace_Preview
            | Editor.Commands.Command_Keybindings_Assign_Selected
            | Editor.Commands.Command_File_Tree_Create_File
            | Editor.Commands.Command_File_Tree_Create_Directory
            | Editor.Commands.Command_File_Tree_Rename_Selected
            | Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply
            | Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_File_Tree_Delete_Selected
            | Editor.Commands.Command_Project_Search_Replace_All_Included
            | Editor.Commands.Command_Reset_Settings_To_Defaults
            | Editor.Commands.Command_Configuration_Reset_Settings
            | Editor.Commands.Command_Configuration_Reset_Keybindings
            | Editor.Commands.Command_Configuration_Reset_Workspace
            | Editor.Commands.Command_Configuration_Reset_Recent_Projects
            | Editor.Commands.Command_Configuration_Reset_All
            | Editor.Commands.Command_Keybindings_Reset_To_Defaults
            | Editor.Commands.Command_Clear_Workspace_State
            | Editor.Commands.Command_Close_Project
            | Editor.Commands.Command_Clear_Project
            | Editor.Commands.Command_Clear_Recent_Projects
            | Editor.Commands.Command_Close_All_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Diagnostics_Clear =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Starts_Guided_Prompt;

   function Command_Starts_Confirmation_Prompt
     (Id : Editor.Commands.Command_Id) return Boolean is
   begin
      case Id is
         when Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_File_Tree_Delete_Selected
            | Editor.Commands.Command_Project_Search_Replace_All_Included
            | Editor.Commands.Command_Reset_Settings_To_Defaults
            | Editor.Commands.Command_Configuration_Reset_Settings
            | Editor.Commands.Command_Configuration_Reset_Keybindings
            | Editor.Commands.Command_Configuration_Reset_Workspace
            | Editor.Commands.Command_Configuration_Reset_Recent_Projects
            | Editor.Commands.Command_Configuration_Reset_All
            | Editor.Commands.Command_Keybindings_Reset_To_Defaults
            | Editor.Commands.Command_Clear_Workspace_State
            | Editor.Commands.Command_Close_Project
            | Editor.Commands.Command_Clear_Project
            | Editor.Commands.Command_Clear_Recent_Projects
            | Editor.Commands.Command_Close_Active_Buffer
            | Editor.Commands.Command_Close_All_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Diagnostics_Clear =>
            return True;
         when others =>
            return False;
      end case;
   end Command_Starts_Confirmation_Prompt;

   procedure Start_Guided_Prompt_For_Command
     (S           : in out Editor.State.State_Type;
      Id          : Editor.Commands.Command_Id;
      Report_Info : not null access procedure (Text : String))
   is
   begin
      case Id is
         when Editor.Commands.Command_Open_Project =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.Project_Open_Prompt,
               Id,
               "Open Project",
               "Enter project path.",
               "Project",
               Previous_Focus => "editor",
               Confirm_Label => "Open",
               Lifecycle_Command => True);
            Report_Info ("Enter project path.");
         when Editor.Commands.Command_Switch_Project =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.Project_Switch_Prompt,
               Id,
               "Switch Project",
               "Enter target project path.",
               "Project",
               Previous_Focus => "editor",
               Confirm_Label => "Switch",
               Lifecycle_Command => True);
            Report_Info ("Enter project path.");
         when Editor.Commands.Command_Restore_Workspace_State =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.Workspace_Load_Prompt,
               Id,
               "Load Workspace",
               "Enter workspace path or reference.",
               "Workspace",
               Confirm_Label => "Load",
               Lifecycle_Command => True);
            Report_Info ("Enter workspace path.");
         when Editor.Commands.Command_Save_Workspace_State =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.Workspace_Save_Prompt,
               Id,
               "Save Workspace",
               "Enter workspace path or confirm the default workspace target.",
               "Workspace",
               Confirm_Label => "Save");
            Report_Info ("Enter workspace path.");
         when Editor.Commands.Command_Run_Project_Search
            | Editor.Commands.Command_Run_Project_Search_From_Bar =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.Search_Query_Prompt,
               Id,
               "Project Search",
               "Enter search text.",
               "Project Search",
               Confirm_Label => "Search");
            Report_Info ("Enter search text.");
         when Editor.Commands.Command_Project_Search_Replace_Preview =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.Replace_Text_Prompt,
               Id,
               "Replacement Text",
               "Enter replacement text for the current project search.",
               "Project Search Replace",
               Confirm_Label => "Preview");
            Report_Info ("Enter replacement text.");
         when Editor.Commands.Command_Keybindings_Assign_Selected =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.Keybinding_Capture_Prompt,
               Id,
               "Assign Keybinding",
               "Press one key chord to assign to the selected bindable command.",
               "Keybindings",
               Confirm_Label => "Assign");
            Report_Info ("Press keybinding chord.");
         when Editor.Commands.Command_File_Tree_Create_File =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
               Id,
               "Create File",
               "Enter a file name or project-relative path inside the active project.",
               "File Tree",
               Confirm_Label => "Create");
            Report_Info ("Enter file name.");
         when Editor.Commands.Command_File_Tree_Create_Directory =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.File_Tree_Create_Directory_Prompt,
               Id,
               "Create Directory",
               "Enter a directory name or project-relative path inside the active project.",
               "File Tree",
               Confirm_Label => "Create");
            Report_Info ("Enter directory name.");
         when Editor.Commands.Command_File_Tree_Rename_Selected =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.File_Tree_Rename_Prompt,
               Id,
               "Rename File or Directory",
               "Enter a new name for the selected file or directory.",
               "File Tree",
               Confirm_Label => "Rename");
            declare
               Selected_Row : constant Natural :=
                 Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View);
               Found       : Boolean := False;
               Node_Id     : Editor.File_Tree.File_Tree_Node_Id :=
                 Editor.File_Tree.No_File_Tree_Node;
               Summary     : Editor.File_Tree.File_Tree_Node_Summary;
            begin
               if Selected_Row > 0 then
                  Node_Id := Editor.File_Tree_View.Node_For_Row
                    (S.File_Tree, Selected_Row, Found);
               end if;

               if Found and then Node_Id /= Editor.File_Tree.No_File_Tree_Node then
                  Summary := Editor.File_Tree.Node (S.File_Tree, Node_Id);
                  Editor.Guided_Prompts.Update_Input
                    (S.Guided_Prompt, To_String (Summary.Name));
               end if;
            end;
            Report_Info ("Enter new name.");
         when Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply =>
            declare
               Symbol : constant String :=
                 Editor.Executor.Current_Semantic_Symbol_Name (S);
            begin
               Editor.Guided_Prompts.Start
                 (S.Guided_Prompt,
                  Editor.Guided_Prompts.Semantic_Rename_Prompt,
                  Id,
                  "Rename Symbol",
                  "Enter the new Ada identifier for the selected symbol.",
                  "Ada Semantics",
                  Confirm_Label =>
                    (if Id = Editor.Commands.Command_Rename_Symbol_Apply
                     then "Rename"
                     else "Preview"));
               if Symbol'Length > 0 then
                  Editor.Guided_Prompts.Update_Input (S.Guided_Prompt, Symbol);
               end if;
            end;
            Report_Info ("Enter new symbol name.");
         when Editor.Commands.Command_File_Tree_Delete_Selected =>
            declare
               Selected_Row : constant Natural :=
                 Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View);
               Found       : Boolean := False;
               Node_Id     : Editor.File_Tree.File_Tree_Node_Id :=
                 Editor.File_Tree.No_File_Tree_Node;
               Summary     : Editor.File_Tree.File_Tree_Node_Summary;
               Kind_Label  : Unbounded_String := To_Unbounded_String ("item");
               Path_Label  : Unbounded_String :=
                 To_Unbounded_String ("selected File Tree item");
               Impact      : Unbounded_String := Null_Unbounded_String;
            begin
               if Selected_Row > 0 then
                  Node_Id := Editor.File_Tree_View.Node_For_Row
                    (S.File_Tree, Selected_Row, Found);
               end if;

               if Found and then Node_Id /= Editor.File_Tree.No_File_Tree_Node then
                  Summary := Editor.File_Tree.Node (S.File_Tree, Node_Id);
                  Kind_Label :=
                    To_Unbounded_String (Editor.File_Tree.Kind_Label (Summary.Kind));
                  Path_Label := Summary.Absolute_Path;
                  if Editor.Buffers.Global_Has_Dirty_File_Under_Path
                    (To_String (Summary.Absolute_Path))
                  then
                     Impact := To_Unbounded_String
                       (" Dirty open buffer content will block deletion.");
                  elsif Editor.Buffers.Global_Has_File_Under_Path
                    (To_String (Summary.Absolute_Path))
                  then
                     Impact := To_Unbounded_String
                       (" Clean open buffers under this target will be closed after successful deletion.");
                  end if;
               end if;

               Editor.Guided_Prompts.Start
                 (S.Guided_Prompt,
                  Editor.Guided_Prompts.Confirmation_Prompt,
                  Id,
                  "Delete File or Directory",
                  "Confirm deletion of the selected " & To_String (Kind_Label) & ": " &
                    To_String (Path_Label) & "." & To_String (Impact),
                  "File Tree",
                  Confirm_Label => "Delete",
                  Requires_Confirmation => True,
                  Destructive => True,
                  Affected_Count => 1);
               Report_Info ("Confirmation required.");
            end;
         when Editor.Commands.Command_Delete_Buffer_File
            | Editor.Commands.Command_Revert_Active_Buffer
            | Editor.Commands.Command_Project_Search_Replace_All_Included
            | Editor.Commands.Command_Reset_Settings_To_Defaults
            | Editor.Commands.Command_Configuration_Reset_Settings
            | Editor.Commands.Command_Configuration_Reset_Keybindings
            | Editor.Commands.Command_Configuration_Reset_Workspace
            | Editor.Commands.Command_Configuration_Reset_Recent_Projects
            | Editor.Commands.Command_Configuration_Reset_All
            | Editor.Commands.Command_Keybindings_Reset_To_Defaults
            | Editor.Commands.Command_Clear_Workspace_State
            | Editor.Commands.Command_Close_Project
            | Editor.Commands.Command_Clear_Project
            | Editor.Commands.Command_Clear_Recent_Projects
            | Editor.Commands.Command_Close_All_Buffers
            | Editor.Commands.Command_Close_All_Clean_Buffers
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Diagnostics_Clear =>
            Editor.Guided_Prompts.Start
              (S.Guided_Prompt,
               Editor.Guided_Prompts.Confirmation_Prompt,
               Id,
               "Confirm Action",
               "Confirm the pending action.",
               "Confirmation",
               Confirm_Label => "Confirm",
               Requires_Confirmation => True,
               Destructive => True,
               Lifecycle_Command => True,
               Affected_Count => 1);
            Report_Info ("Confirmation required.");
         when others =>
            null;
      end case;

      Editor.Render_Cache.Invalidate_All;
   end Start_Guided_Prompt_For_Command;

end Editor.Input_Bridge.Command_Prompt_Routing;
