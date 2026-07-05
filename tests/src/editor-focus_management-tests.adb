with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Build_UI_Actions;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Executor;
with Editor.Focus_Management;
with Editor.Overlay_Focus;
with Editor.Outline;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Pending_Transitions;
with Editor.Project_Search_Bar;
with Editor.State;

package body Editor.Focus_Management.Tests is

   use type Editor.Focus_Management.Focus_Owner;

   function Name
     (T : Focus_Management_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Focus_Management.Tests");
   end Name;

   procedure Test_Default_Editor_Owns_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "default state should give editor the effective focus owner");
      Assert
        (Editor.Focus_Management.Editor_Text_Can_Edit (S),
         "editor text can edit only when editor owns focus");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "default focus state should be coherent");
   end Test_Default_Editor_Owns_Focus;

   procedure Test_Overlay_Beats_Editor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Quick_Open,
         "Quick Open overlay should own focus above editor text");
      Assert
        (Editor.Focus_Management.Overlay_Input_Owns_Text (S),
         "active overlay should own text input");
      Assert
        (not Editor.Focus_Management.Editor_Text_Can_Edit (S),
         "editor text must not edit while overlay owns focus");
   end Test_Overlay_Beats_Editor;

   procedure Test_Panel_Arrows_Beat_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_File_Tree,
         "file tree should be the effective focus owner");
      Assert
        (Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "focused file tree should consume panel navigation arrows");
      Assert
        (not Editor.Focus_Management.Editor_Text_Can_Edit (S),
         "editor text must not edit while file tree owns focus");
   end Test_Panel_Arrows_Beat_Caret;

   procedure Test_Feature_Panel_Maps_To_Outline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      declare
         Switched : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
           (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
      begin
         Assert (Switched, "outline feature should be accepted");
      end;
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Outline,
         "focused outline feature panel should report Outline focus");
      Assert
        (Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "focused outline should own local navigation");
   end Test_Feature_Panel_Maps_To_Outline;

   procedure Test_Pending_Confirmation_Is_Modal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Target  : Editor.Pending_Transitions.Pending_Transition_Target;
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary;
   begin
      Target.Kind := Editor.Pending_Transitions.Pending_Close_Project;
      Summary.Dirty_Count := 1;
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Summary);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Pending_Confirmation,
         "pending confirmation should own focus above overlays and panels");
      Assert
        (not Editor.Focus_Management.Editor_Text_Can_Edit (S),
         "editor text must not edit while confirmation is pending");
      Assert
        (Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Cancel_Pending_Transition),
         "cancel pending transition should remain available");
      Assert
        (Editor.Focus_Management.Command_Is_Conflicting_While_Pending
           (Editor.Commands.Command_Open_Project),
         "project switching should be conflicting while confirmation is pending");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "modal pending focus should be coherent");
   end Test_Pending_Confirmation_Is_Modal;

   procedure Test_Pending_Confirmation_Blocks_File_Save_Mutations
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Target  : Editor.Pending_Transitions.Pending_Transition_Target;
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary;
   begin
      Target.Kind := Editor.Pending_Transitions.Pending_Close_Project;
      Summary.Dirty_Count := 1;
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Summary);

      Assert
        (not Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Save_File),
         "Save File must not bypass modal pending-confirmation focus");
      Assert
        (not Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Save_All),
         "Save All must not bypass modal pending-confirmation focus");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Save_File),
         "current-focus policy should reject Save File while confirmation owns focus");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Save_All),
         "current-focus policy should reject Save All while confirmation owns focus");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Cancel_Pending_Transition),
         "cancel remains the safe modal command");
   end Test_Pending_Confirmation_Blocks_File_Save_Mutations;


   procedure Test_Project_Search_Replace_Field_Owns_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Project_Search_Bar.Focus_Replace_Field (S.Project_Search_Bar);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Project_Search_Bar_Overlay,
         S.Panel_Focus);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Replace_Input,
         "project search replace field should be the effective text owner");
      Assert
        (Editor.Focus_Management.Text_Input_Owner
           (Editor.Focus_Management.Effective_Focus_Owner (S)),
         "project replace field should be classified as a text input owner");
      Assert
        (not Editor.Focus_Management.Editor_Text_Can_Edit (S),
         "replace input must not leak text into editor buffer");
   end Test_Project_Search_Replace_Field_Owns_Text;

   procedure Test_Focus_Priority_Rank_Is_Modal_First
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Focus_Priority_Rank
           (Editor.Focus_Management.Focus_Pending_Confirmation)
         < Editor.Focus_Management.Focus_Priority_Rank
           (Editor.Focus_Management.Focus_Command_Palette),
         "pending confirmation should outrank command palette focus");
      Assert
        (Editor.Focus_Management.Focus_Priority_Rank
           (Editor.Focus_Management.Focus_Command_Palette)
         < Editor.Focus_Management.Focus_Priority_Rank
           (Editor.Focus_Management.Focus_Quick_Open),
         "command palette should outrank Quick Open");
      Assert
        (Editor.Focus_Management.Focus_Priority_Rank
           (Editor.Focus_Management.Focus_File_Tree)
         < Editor.Focus_Management.Focus_Priority_Rank
           (Editor.Focus_Management.Focus_Editor),
         "focused panels should consume navigation before editor text");
   end Test_Focus_Priority_Rank_Is_Modal_First;

   procedure Test_Set_Focus_Owner_Routes_To_Structural_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Results);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Results,
         "setting search-results focus should update the canonical panel focus");
      Assert
        (Editor.Focus_Management.Navigation_Panel_Owner
           (Editor.Focus_Management.Effective_Focus_Owner (S)),
         "search results should be a panel navigation owner");
      Assert
        (not Editor.Focus_Management.Global_Keybindings_May_Run (S),
         "global editor keybindings should not run while a panel owns navigation");

      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "restore focus should return to editor deterministically");
      Assert
        (Editor.Focus_Management.Global_Keybindings_May_Run (S),
         "global keybindings may run again after editor focus is restored");
   end Test_Set_Focus_Owner_Routes_To_Structural_Surface;

   procedure Test_Set_Focus_Owner_Clears_Overlay_Text_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Quick_Open,
         "Quick Open should own focus after explicit focus request");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_File_Tree,
         "File Tree focus should replace overlay focus explicitly");
      Assert
        (not Editor.Focus_Management.Overlay_Input_Owns_Text (S),
         "switching to panel focus should clear overlay text ownership");
   end Test_Set_Focus_Owner_Clears_Overlay_Text_Focus;


   procedure Test_Build_UI_Focus_Uses_Build_Surface_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_UI);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Build_UI,
         "Build UI focus should use the retained Build UI focused flag");
      Assert
        (S.Build_UI.Build_UI_Visible,
         "focusing Build UI should make the Build UI visible");
      Assert
        (S.Build_UI.Build_UI_Focused,
         "focusing Build UI should set the Build UI focused flag");
      Assert
        (Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "focused Build UI should consume panel-local navigation");
      Assert
        (not Editor.Focus_Management.Global_Keybindings_May_Run (S),
         "global editor keybindings should not run while Build UI is focused");
   end Test_Build_UI_Focus_Uses_Build_Surface_State;

   procedure Test_Build_Output_Details_Focus_Uses_Output_Surface_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_Output_Details);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Build_Output_Details,
         "Build output details focus should use the retained output details focused flag");
      Assert
        (S.Latest_Build_Output_Details.Build_Output_Details_Visible,
         "focusing Build output details should make output details visible");
      Assert
        (S.Latest_Build_Output_Details.Build_Output_Details_Focused,
         "focusing Build output details should set output details focus");
      Assert
        (Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "focused Build output details should consume panel-local navigation");
   end Test_Build_Output_Details_Focus_Uses_Output_Surface_State;

   procedure Test_Activation_Escape_And_Persistence_Policies_Are_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Activation_Returns_Focus_To_Editor
           (Editor.Focus_Management.Focus_Quick_Open),
         "Quick Open activation should close/return to editor focus");
      Assert
        (Editor.Focus_Management.Activation_Returns_Focus_To_Editor
           (Editor.Focus_Management.Focus_Diagnostics),
         "Diagnostics activation should return to editor after target navigation");
      Assert
        (not Editor.Focus_Management.Activation_Returns_Focus_To_Editor
           (Editor.Focus_Management.Focus_Build_UI),
         "Build UI activation keeps Build workflow focus under retained policy");
      Assert
        (Editor.Focus_Management.Escape_Returns_Focus_To_Editor
           (Editor.Focus_Management.Focus_File_Tree),
         "Escape in focused File Tree should return focus to editor");
      Assert
        (not Editor.Focus_Management.Escape_Returns_Focus_To_Editor
           (Editor.Focus_Management.Focus_Command_Palette),
         "Command Palette Escape is close-overlay policy, not panel fallback policy");
      Assert
        (not Editor.Focus_Management.Focus_State_Is_Persistable
           (Editor.Focus_Management.Focus_Quick_Open),
         "overlay focus state must not be persisted");
      Assert
        (not Editor.Focus_Management.Focus_State_Is_Persistable
           (Editor.Focus_Management.Focus_Build_UI),
         "panel focus state remains transient even when visibility/layout is structural");
   end Test_Activation_Escape_And_Persistence_Policies_Are_Explicit;


   procedure Test_Build_Result_Summary_Focus_Uses_Transient_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_Result_Summary);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Build_Result_Summary,
         "Build result summary focus should use the transient summary focus flag");
      Assert
        (S.Latest_Build_Result_Focused,
         "focusing Build result summary should set only transient focus state");
      Assert
        (Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "focused Build result summary should consume panel-local navigation");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "Build result summary focus should be coherent even without editor text focus mutation");

      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Assert
        (not S.Latest_Build_Result_Focused,
         "restoring editor focus should clear Build result summary focus");
   end Test_Build_Result_Summary_Focus_Uses_Transient_State;

   procedure Test_Recent_Projects_Focus_Uses_Transient_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Recent_Projects);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Recent_Projects,
         "Recent Projects focus should use a transient focus marker");
      Assert
        (S.Recent_Projects_Focused,
         "focusing Recent Projects should not rely on selected row persistence");
      Assert
        (Editor.Focus_Management.Navigation_Panel_Owner
           (Editor.Focus_Management.Effective_Focus_Owner (S)),
         "Recent Projects should be treated as a panel navigation owner");
      Assert
        (not Editor.Focus_Management.Focus_State_Is_Persistable
           (Editor.Focus_Management.Focus_Recent_Projects),
         "Recent Projects focus must remain excluded from persistence");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Command_Palette);
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Command_Palette,
         "overlay focus should replace stale Recent Projects focus");
      Assert
        (not S.Recent_Projects_Focused,
         "switching to an overlay should clear Recent Projects focus");
   end Test_Recent_Projects_Focus_Uses_Transient_State;


   procedure Test_Status_Projection_Labels_Are_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Replace_Input);

      Assert
        (Editor.Focus_Management.Active_Panel_Label
           (Editor.Focus_Management.Effective_Focus_Owner (S)) =
         "Project Search",
         "replace-input focus should expose its active panel label");
      Assert
        (Editor.Focus_Management.Input_Mode_Label
           (Editor.Focus_Management.Effective_Focus_Owner (S)) =
         "Overlay Text",
         "replace-input focus should expose overlay text input mode");
      Assert
        (Editor.Focus_Management.Overlay_Query_Active (S),
         "replace-input focus should expose an active overlay/input marker");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Diagnostics);
      Assert
        (Editor.Focus_Management.Active_Panel_Label
           (Editor.Focus_Management.Effective_Focus_Owner (S)) =
         "Diagnostics",
         "diagnostics focus should expose its active panel label");
      Assert
        (Editor.Focus_Management.Input_Mode_Label
           (Editor.Focus_Management.Effective_Focus_Owner (S)) =
         "Panel Navigation",
         "diagnostics focus should expose panel navigation mode");
      Assert
        (not Editor.Focus_Management.Overlay_Query_Active (S),
         "panel navigation focus must not advertise overlay text ownership");
   end Test_Status_Projection_Labels_Are_Explicit;


   procedure Test_Buffer_List_Overlay_Owns_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Buffer_List);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Buffer_List,
         "Buffer List overlay should own effective focus");
      Assert
        (Editor.Focus_Management.Text_Input_Owner
           (Editor.Focus_Management.Effective_Focus_Owner (S)),
         "Buffer List overlay should be classified as a text input owner");
      Assert
        (Editor.Focus_Management.Overlay_Query_Active (S),
         "Buffer List filter/query should be visible as active overlay input");
      Assert
        (Editor.Focus_Management.Input_Mode_Label
           (Editor.Focus_Management.Effective_Focus_Owner (S)) =
         "Overlay Text",
         "Buffer List should expose overlay text input mode");
      Assert
        (not Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "Buffer List overlay arrows are handled by overlay dispatch, not editor caret focus");
      Assert
        (not Editor.Focus_Management.Editor_Text_Can_Edit (S),
         "Buffer List input must not leak typed text into the editor buffer");
   end Test_Buffer_List_Overlay_Owns_Text;

   procedure Test_Command_Eligibility_Is_Focus_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_File_Tree_Move_Down),
         "File Tree local navigation should be accepted when File Tree owns focus");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Insert_Newline),
         "editor text insertion should be blocked when File Tree owns focus");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Open_Quick_Open),
         "global surface-entry commands should remain available from File Tree focus");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Buffer_List);
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Accept_Buffer_Switcher),
         "Buffer List activation should be accepted in Buffer List focus");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_File_Tree_Open_Selected),
         "stale File Tree activation should not run from Buffer List focus");
   end Test_Command_Eligibility_Is_Focus_Local;


   procedure Test_Surface_Command_Families_Are_Focus_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_File_Tree_Create_File),
         "File Tree focus should allow File Tree-local create commands");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Diagnostics_Open_Selected),
         "File Tree focus must block stale Diagnostics activation");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Results);
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Project_Search_Replace_Toggle_Selected),
         "Project Search focus should allow replace-preview local commands");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_File_Tree_Open_Selected),
         "Project Search focus must block stale File Tree activation");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Recent_Projects);
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Open_Selected_Recent_Project),
         "Recent Projects focus should allow selected-project activation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Accept_Quick_Open),
         "Recent Projects focus must block stale Quick Open activation");
   end Test_Surface_Command_Families_Are_Focus_Local;

   procedure Test_Build_And_Output_Focus_Block_Stale_Editor_Or_Row_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_UI);
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Build_Toggle_Diagnostics_Ingestion),
         "Build UI focus should allow Build UI-local configuration commands");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Cut),
         "Build UI focus must block editor text mutation commands");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_Output_Details);
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Build_UI_Show),
         "Build Output focus should allow build-surface commands");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_File_Tree_Open_Selected),
         "Build Output focus must block stale File Tree activation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Insert_Newline),
         "Build Output focus must not permit editor newline insertion");
   end Test_Build_And_Output_Focus_Block_Stale_Editor_Or_Row_Input;

   procedure Test_Prompt_Focus_Blocks_Stale_Surface_Activation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Workspace_Prompt);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Workspace_Prompt,
         "workspace/file prompt should own prompt focus");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Cancel),
         "prompt focus should still allow safe cancel command routing");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Open_Selected_Outline_Item),
         "prompt focus must block stale Outline activation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Paste),
         "prompt focus must block editor paste mutation through command ids");
   end Test_Prompt_Focus_Blocks_Stale_Surface_Activation;


   procedure Test_Surface_Entry_Command_Targets_Are_Auditable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Command_Is_Surface_Entry
           (Editor.Commands.Command_Open_Quick_Open),
         "Quick Open opener should be classified as a surface-entry command");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Open_Quick_Open) =
         Editor.Focus_Management.Focus_Quick_Open,
         "Quick Open opener should have an auditable focus target");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Focus_File_Tree) =
         Editor.Focus_Management.Focus_File_Tree,
         "File Tree focus command should have an auditable focus target");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Build_UI_Focus) =
         Editor.Focus_Management.Focus_Build_UI,
         "Build UI focus command should have an auditable focus target");
      Assert
        (Editor.Focus_Management.Command_Is_Surface_Entry
           (Editor.Commands.Command_Terminal_Show),
         "Terminal show should be classified as a surface-entry command");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Terminal_Focus) =
         Editor.Focus_Management.Focus_Terminal,
         "Terminal focus command should have an auditable focus target");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Show_Recent_Projects) =
         Editor.Focus_Management.Focus_Recent_Projects,
         "Recent Projects show command should have an auditable focus target");
      Assert
        (not Editor.Focus_Management.Command_Is_Surface_Entry
           (Editor.Commands.Command_File_Tree_Open_Selected),
         "row activation should not be misclassified as surface entry");
   end Test_Surface_Entry_Command_Targets_Are_Auditable;

   procedure Test_Workspace_Prompt_Allows_Only_Prompt_Local_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Workspace_Prompt);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Goto_Line_Query_Set),
         "prompt focus should allow go-to-line query text commands");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Find_Query_Set),
         "prompt focus should allow find query text commands");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Replace_Text_Set),
         "prompt focus should allow replace prompt text commands");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Replace_Current),
         "prompt focus should allow replace-current while replace prompt owns focus");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Replace_All),
         "prompt focus should allow replace-all while replace prompt owns focus");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Accept_Quick_Open),
         "prompt focus must block stale Quick Open activation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Open_Quick_Open),
         "prompt focus must block opening another overlay on top of prompt input");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Insert_Newline),
         "prompt focus must block editor newline insertion");
   end Test_Workspace_Prompt_Allows_Only_Prompt_Local_Commands;

   procedure Test_Escape_Overlay_Close_Policy_Is_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Escape_Closes_Overlay
           (Editor.Focus_Management.Focus_Command_Palette),
         "Command Palette Escape should be an overlay close policy");
      Assert
        (Editor.Focus_Management.Escape_Closes_Overlay
           (Editor.Focus_Management.Focus_Quick_Open),
         "Quick Open Escape should be an overlay close policy");
      Assert
        (Editor.Focus_Management.Escape_Closes_Overlay
           (Editor.Focus_Management.Focus_Buffer_List),
         "Buffer List Escape should be an overlay close policy");
      Assert
        (Editor.Focus_Management.Escape_Closes_Overlay
           (Editor.Focus_Management.Focus_Workspace_Prompt),
         "prompt Escape should be an overlay close/cancel policy");
      Assert
        (not Editor.Focus_Management.Escape_Closes_Overlay
           (Editor.Focus_Management.Focus_File_Tree),
         "File Tree Escape should use panel fallback, not overlay close");
   end Test_Escape_Overlay_Close_Policy_Is_Explicit;

   procedure Test_Command_Level_Focus_Return_Policy_Is_Auditable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_Accept_Quick_Open),
         "Quick Open accept should be classified as returning focus to editor");
      Assert
        (Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_Quick_Open_Create_From_Query),
         "Quick Open create should be classified as returning focus to editor");
      Assert
        (Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query),
         "Quick Open create-with-parents should be classified as returning focus to editor");
      Assert
        (Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_File_Tree_Open_Selected),
         "File Tree row activation should be classified as returning focus to editor");
      Assert
        (Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_Diagnostics_Open_Selected),
         "Diagnostics row activation should be classified as returning focus to editor");
      Assert
        (Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_Open_Selected_Recent_Project),
         "Recent Projects activation should be classified as returning focus to editor");
      Assert
        (not Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_Build_Run),
         "Build run should keep the retained Build workflow focus policy");
   end Test_Command_Level_Focus_Return_Policy_Is_Auditable;

   procedure Test_Command_Level_Dismissal_And_Navigation_Policy_Is_Auditable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Command_Closes_Focused_Surface
           (Editor.Commands.Command_Close_Quick_Open),
         "Quick Open close should be classified as a focused-surface dismissal");
      Assert
        (Editor.Focus_Management.Command_Closes_Focused_Surface
           (Editor.Commands.Command_Close_Project_Search_Bar),
         "Project Search close should be classified as a focused-surface dismissal");
      Assert
        (Editor.Focus_Management.Command_Closes_Focused_Surface
           (Editor.Commands.Command_Build_UI_Hide),
         "Build UI hide should be classified as a focused-surface dismissal");
      Assert
        (not Editor.Focus_Management.Command_Closes_Focused_Surface
           (Editor.Commands.Command_File_Tree_Open_Selected),
         "row activation should not be misclassified as dismissal");

      Assert
        (Editor.Focus_Management.Command_Is_Panel_Local_Navigation
           (Editor.Commands.Command_File_Tree_Move_Down),
         "File Tree row movement should be panel-local navigation");
      Assert
        (Editor.Focus_Management.Command_Is_Panel_Local_Navigation
           (Editor.Commands.Command_Search_Results_Page_Down),
         "Search results paging should be panel-local navigation");
      Assert
        (Editor.Focus_Management.Command_Is_Panel_Local_Navigation
           (Editor.Commands.Command_Diagnostics_Select_Next),
         "Diagnostics selection movement should be panel-local navigation");
      Assert
        (not Editor.Focus_Management.Command_Is_Panel_Local_Navigation
           (Editor.Commands.Command_Move_Down),
         "editor caret movement must not be classified as panel-local navigation");
   end Test_Command_Level_Dismissal_And_Navigation_Policy_Is_Auditable;


   procedure Test_Restore_Previous_Focus_Or_Editor_Uses_Overlay_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Search_Results_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panel_Focus.Focus_Bottom_Panel
        (S.Panel_Focus, Editor.Panel_Focus.Search_Results_Focus);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Quick_Open,
         "Quick Open should own focus while the overlay is active");

      Editor.Focus_Management.Restore_Previous_Focus_Or_Editor (S);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Results,
         "overlay dismissal should restore previous Search Results focus when valid");
      Assert
        (not Editor.Focus_Management.Overlay_Input_Owns_Text (S),
         "restoring previous focus should clear overlay text ownership");

      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Command_Palette_Overlay,
         S.Panel_Focus);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);
      Editor.Focus_Management.Restore_Previous_Focus_Or_Editor (S);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "missing previous focus should fall back deterministically to editor");
   end Test_Restore_Previous_Focus_Or_Editor_Uses_Overlay_History;


   procedure Test_Apply_Command_Focus_Result_Makes_Return_Policy_Active
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Accept_Quick_Open);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "accepting Quick Open should actively restore editor focus");
      Assert
        (not Editor.Focus_Management.Overlay_Input_Owns_Text (S),
         "accepting Quick Open should clear overlay text ownership");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_File_Tree_Open_Selected);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "activating File Tree target should actively restore editor focus");
   end Test_Apply_Command_Focus_Result_Makes_Return_Policy_Active;

   procedure Test_Apply_Command_Focus_Result_Restores_Previous_On_Dismissal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Search_Results_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panel_Focus.Focus_Bottom_Panel
        (S.Panel_Focus, Editor.Panel_Focus.Search_Results_Focus);

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Quick_Open,
         "Quick Open overlay should own focus before dismissal");

      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Close_Quick_Open);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Results,
         "closing Quick Open should restore valid previous Search Results focus");
      Assert
        (not Editor.Focus_Management.Overlay_Input_Owns_Text (S),
         "closing Quick Open should remove overlay text ownership");

      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, False);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Close_Quick_Open);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "closing overlay with invalid previous focus should fall back to editor");
   end Test_Apply_Command_Focus_Result_Restores_Previous_On_Dismissal;

   procedure Test_Surface_Entry_Result_Focus_Is_Active_But_Toggles_Are_Not
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Open_Quick_Open);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Quick_Open,
         "executed Quick Open surface-entry command should actively focus Quick Open");
      Assert
        (Editor.Focus_Management.Command_Focuses_Surface_After_Execution
           (Editor.Commands.Command_Open_Quick_Open),
         "open surface commands should opt into post-execution focus application");

      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Toggle_Quick_Open);
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "toggle command from the focused overlay should close it and fall back safely");
      Assert
        (not Editor.Focus_Management.Command_Focuses_Surface_After_Execution
           (Editor.Commands.Command_Toggle_Quick_Open),
         "toggle commands must not force focus after execution because they may close the surface");

      Assert
        (Editor.Focus_Management.Command_Focuses_Surface_After_Execution
           (Editor.Commands.Command_Terminal_Focus),
         "Terminal focus should opt into post-execution focus application");
      Assert
        (not Editor.Focus_Management.Command_Focuses_Surface_After_Execution
           (Editor.Commands.Command_Terminal_Toggle),
         "Terminal toggle should not force focus after execution");

      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Focus_Editor_Text);
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "focus-editor command should actively restore editor focus");
   end Test_Surface_Entry_Result_Focus_Is_Active_But_Toggles_Are_Not;

   procedure Test_Surface_Entry_Targets_Cover_Toggle_And_Bottom_Panel_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Command_Is_Surface_Entry
           (Editor.Commands.Command_Toggle_Feature_Panel),
         "feature-panel toggle should be auditable as a surface-entry command even though result focus is conditional");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Toggle_Feature_Panel) =
         Editor.Focus_Management.Focus_Outline,
         "feature-panel toggle target should resolve to the retained feature-panel focus owner");
      Assert
        (not Editor.Focus_Management.Command_Is_Surface_Entry
           (Editor.Commands.Command_Toggle_Diagnostics),
         "diagnostics visibility setting toggle must not be treated as a diagnostics panel focus command");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Toggle_Diagnostics) =
         Editor.Focus_Management.Focus_None,
         "diagnostics visibility setting toggle must not claim a panel focus target");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Toggle_Problems_Panel) =
         Editor.Focus_Management.Focus_Diagnostics,
         "problems-panel toggle target should resolve to Diagnostics focus");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Toggle_Bottom_Panel_Focus) =
         Editor.Focus_Management.Focus_Project_Search_Results,
         "bottom-panel focus toggle has an explicit fallback focus target for audits");
      Assert
        (not Editor.Focus_Management.Command_Focuses_Surface_After_Execution
           (Editor.Commands.Command_Toggle_Bottom_Panel_Focus),
         "bottom-panel focus toggles are not force-applied after execution because the retained command decides the actual bottom content");
   end Test_Surface_Entry_Targets_Cover_Toggle_And_Bottom_Panel_Commands;


   procedure Test_Cancel_Focus_Result_Uses_Pre_Command_Owner
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Search_Results_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panel_Focus.Focus_Bottom_Panel
        (S.Panel_Focus, Editor.Panel_Focus.Search_Results_Focus);

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Editor.Focus_Management.Restore_Focus_To_Editor (S);

      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Cancel,
         Editor.Focus_Management.Focus_Editor);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "Cancel from editor focus must not restore stale overlay previous focus");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Cancel,
         Editor.Focus_Management.Focus_File_Tree);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "Cancel from a navigation panel should return directly to editor focus");
   end Test_Cancel_Focus_Result_Uses_Pre_Command_Owner;

   procedure Test_Close_Command_Matches_Owning_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Command_Closes_Focus_Owner
           (Editor.Commands.Command_Close_Quick_Open,
            Editor.Focus_Management.Focus_Quick_Open),
         "Quick Open close should dismiss Quick Open focus");
      Assert
        (not Editor.Focus_Management.Command_Closes_Focus_Owner
           (Editor.Commands.Command_Close_Quick_Open,
            Editor.Focus_Management.Focus_File_Tree),
         "Quick Open close must not be treated as a File Tree dismissal");
      Assert
        (Editor.Focus_Management.Command_Closes_Focus_Owner
           (Editor.Commands.Command_Cancel,
            Editor.Focus_Management.Focus_Project_Search_Query),
         "Cancel should close project-search overlay input focus");
      Assert
        (not Editor.Focus_Management.Command_Closes_Focus_Owner
           (Editor.Commands.Command_Cancel,
            Editor.Focus_Management.Focus_Editor),
         "Cancel from editor focus should not consume stale overlay history");
   end Test_Close_Command_Matches_Owning_Surface;

   procedure Test_Toggle_Close_Policy_Is_Owner_Scoped
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Command_Toggles_Focus_Owner
           (Editor.Commands.Command_Toggle_Quick_Open,
            Editor.Focus_Management.Focus_Quick_Open),
         "Quick Open toggle should be treated as closing only when Quick Open owns focus");
      Assert
        (not Editor.Focus_Management.Command_Toggles_Focus_Owner
           (Editor.Commands.Command_Toggle_Quick_Open,
            Editor.Focus_Management.Focus_Editor),
         "Quick Open toggle from editor is an open/focus action, not a close action");
      Assert
        (Editor.Focus_Management.Command_Toggles_Focus_Owner
           (Editor.Commands.Command_Toggle_Project_Search_Bar,
            Editor.Focus_Management.Focus_Project_Replace_Input),
         "Project Search toggle should close replace input only when that overlay owns focus");
      Assert
        (Editor.Focus_Management.Command_Toggles_Focus_Owner
           (Editor.Commands.Command_Build_UI_Toggle,
            Editor.Focus_Management.Focus_Build_Output_Details),
         "Build UI toggle should close build output focus when the build surface owns focus");
      Assert
        (Editor.Focus_Management.Command_Toggles_Focus_Owner
           (Editor.Commands.Command_Toggle_Feature_Panel,
            Editor.Focus_Management.Focus_Outline),
         "Feature Panel toggle should close focused Outline surface");
      Assert
        (not Editor.Focus_Management.Command_Toggles_Focus_Owner
           (Editor.Commands.Command_Toggle_Feature_Panel,
            Editor.Focus_Management.Focus_Quick_Open),
         "Feature Panel toggle must not be treated as closing an unrelated overlay owner");
   end Test_Toggle_Close_Policy_Is_Owner_Scoped;

   procedure Test_Overlay_Focus_Blocks_Cross_Surface_Entry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Quick_Open_Next_Result),
         "Quick Open focus should permit Quick Open local navigation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Open_Project_Search_Bar),
         "Quick Open focus must not allow jumping to Project Search overlay");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Open_Buffer_Switcher),
         "Quick Open focus must not allow jumping to Buffer List overlay");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Cancel),
         "Quick Open focus should still allow local cancellation");
   end Test_Overlay_Focus_Blocks_Cross_Surface_Entry;

   procedure Test_Pending_Confirmation_Allows_Only_Modal_And_Status_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Cancel_Pending_Transition),
         "pending modal focus should allow explicit cancel");
      Assert
        (Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Retry_Pending_Transition),
         "pending modal focus should allow the retained confirm/retry path");
      Assert
        (Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Discard_Pending_Transition),
         "pending modal focus should allow explicit discard-and-continue");
      Assert
        (Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Show_Messages),
         "pending modal focus should allow safe status inspection");
      Assert
        (not Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Save_File),
         "pending modal focus must not allow unrelated file mutation");
      Assert
        (not Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Open_Quick_Open),
         "pending modal focus must not allow opening another overlay");
   end Test_Pending_Confirmation_Allows_Only_Modal_And_Status_Commands;


   procedure Test_Prompt_Accept_And_Local_Dismissal_Return_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Go_To_Line_Overlay,
         S.Panel_Focus);

      Assert
        (Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_Accept_Goto_Line),
         "accepting a prompt navigation command should return focus to editor");

      Editor.Focus_Management.Apply_Command_Focus_Result
        (S,
         Editor.Commands.Command_Accept_Goto_Line,
         Editor.Focus_Management.Focus_Workspace_Prompt);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "accepted prompt navigation should clear overlay focus and restore editor");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Workspace_Prompt);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S,
         Editor.Commands.Command_Close_Goto_Line,
         Editor.Focus_Management.Focus_Workspace_Prompt);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor
         or else Editor.Focus_Management.Effective_Focus_Owner (S) =
           Editor.Focus_Management.Focus_File_Tree,
         "dismissed prompt should use valid previous focus or safe editor fallback");
   end Test_Prompt_Accept_And_Local_Dismissal_Return_Focus;


   procedure Test_Local_Navigation_Command_Ids_Are_Focus_Routed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Quick_Open_Next_Result),
         "Quick Open local next command should be valid only through Quick Open focus");
      Assert
        (Editor.Focus_Management.Command_Is_Panel_Local_Navigation
           (Editor.Commands.Command_Quick_Open_Next_Result),
         "Quick Open local result movement should be auditable panel-local navigation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Buffer_Switcher_Next_Result),
         "Quick Open focus should block stale Buffer List navigation commands");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Buffer_List);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Buffer_Switcher_Next_Result),
         "Buffer List local next command should be valid only through Buffer List focus");
      Assert
        (Editor.Focus_Management.Command_Is_Panel_Local_Navigation
           (Editor.Commands.Command_Buffer_Switcher_Next_Result),
         "Buffer List local result movement should be auditable panel-local navigation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Quick_Open_Next_Result),
         "Buffer List focus should block stale Quick Open navigation commands");
   end Test_Local_Navigation_Command_Ids_Are_Focus_Routed;


   procedure Test_Feature_Panel_Local_Navigation_Is_Focus_Routed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Outline);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Feature_Panel_Select_Next),
         "focused Feature Panel should accept its canonical next-selection command");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Feature_Panel_Select_Previous),
         "focused Feature Panel should accept its canonical previous-selection command");
      Assert
        (Editor.Focus_Management.Command_Is_Panel_Local_Navigation
           (Editor.Commands.Command_Feature_Panel_Select_Next),
         "Feature Panel next selection should be auditable panel-local navigation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_File_Tree_Move_Down),
         "focused Feature Panel should block stale File Tree navigation commands");
   end Test_Feature_Panel_Local_Navigation_Is_Focus_Routed;


   procedure Test_Project_Search_Bar_Enter_Command_Is_Focus_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Query);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Run_Project_Search_From_Bar),
         "Project Search query focus should accept the canonical run-from-bar command");
      Assert
        (not Editor.Focus_Management.Command_Returns_Focus_To_Editor
           (Editor.Commands.Command_Run_Project_Search_From_Bar),
         "running a Project Search from the bar should keep the query/results surface policy, not force editor focus");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Accept_Quick_Open),
         "Project Search query focus should block stale Quick Open activation commands");
   end Test_Project_Search_Bar_Enter_Command_Is_Focus_Local;


   procedure Test_Project_Search_Bar_Local_Options_Are_Focus_Routed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Query);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Next_Project_Search_Result),
         "Project Search query focus should accept canonical next-result command");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Previous_Project_Search_Result),
         "Project Search query focus should accept canonical previous-result command");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Project_Search_Kind_Next),
         "Project Search query focus should accept canonical kind cycling command");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Project_Search_Case_Toggle),
         "Project Search query focus should accept canonical option toggle commands");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Project_Search_Include_Filter_Clear),
         "Project Search query focus should accept canonical filter-clear command");
      Assert
        (Editor.Focus_Management.Command_Is_Panel_Local_Navigation
           (Editor.Commands.Command_Next_Project_Search_Result),
         "Project Search next-result should be auditable panel-local navigation");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Buffer_Switcher_Next_Result),
         "Project Search query focus should block stale Buffer List navigation");
   end Test_Project_Search_Bar_Local_Options_Are_Focus_Routed;


   procedure Test_Quick_Open_Local_Options_Are_Focus_Routed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Quick_Open_Kind_Next),
         "Quick Open focus should accept canonical kind cycling commands");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Quick_Open_Scope_Clear),
         "Quick Open focus should accept canonical scope commands");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Quick_Open_Priority_Toggle),
         "Quick Open focus should accept canonical priority commands");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_First_Project_Search_Result),
         "Quick Open focus should block stale Project Search first-result command");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Project_Search_Scope_Selected_Directory),
         "Quick Open focus should block stale Project Search scope command");
   end Test_Quick_Open_Local_Options_Are_Focus_Routed;


   procedure Test_Competing_Focus_Owner_Markers_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert
        (Editor.Focus_Management.Focus_State_Has_No_Competing_Owners (S),
         "default focus state should have no competing transient owners");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_UI);
      Assert
        (Editor.Focus_Management.Focus_State_Has_No_Competing_Owners (S),
         "single Build UI owner marker should be coherent");

      S.Recent_Projects_Focused := True;
      Assert
        (not Editor.Focus_Management.Focus_State_Has_No_Competing_Owners (S),
         "Build UI and Recent Projects focus markers must not coexist silently");
      Assert
        (not Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "coherence assertion should reject competing transient focus owners");

      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Assert
        (Editor.Focus_Management.Focus_State_Has_No_Competing_Owners (S),
         "restoring editor focus should clear competing transient owners");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "restored editor focus should be coherent again");
   end Test_Competing_Focus_Owner_Markers_Are_Rejected;


   procedure Test_Workspace_Prompt_Surface_Entry_Targets_Are_Auditable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert
        (Editor.Focus_Management.Command_Is_Surface_Entry
           (Editor.Commands.Command_Goto_Line),
         "Go To Line show should be a surface-entry command");
      Assert
        (Editor.Focus_Management.Command_Is_Surface_Entry
           (Editor.Commands.Command_Find_Show),
         "Find show should be a surface-entry command");
      Assert
        (Editor.Focus_Management.Command_Is_Surface_Entry
           (Editor.Commands.Command_Replace_Show),
         "Replace show should be a surface-entry command");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Goto_Line) =
         Editor.Focus_Management.Focus_Workspace_Prompt,
         "Go To Line should target the workspace/prompt focus owner");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Find_Show) =
         Editor.Focus_Management.Focus_Workspace_Prompt,
         "Find should target the workspace/prompt focus owner");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Replace_Show) =
         Editor.Focus_Management.Focus_Workspace_Prompt,
         "Replace should target the workspace/prompt focus owner");

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Goto_Line),
         "Quick Open must block cross-overlay Go To Line entry while it owns focus");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Find_Show),
         "Quick Open must block cross-overlay Find entry while it owns focus");
   end Test_Workspace_Prompt_Surface_Entry_Targets_Are_Auditable;


   procedure Test_Prompt_Surface_Focus_Result_Preserves_Executor_Overlay
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Go_To_Line_Overlay,
         S.Panel_Focus);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Goto_Line);

      Assert
        (Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay),
         "post-command focus policy must preserve Go To Line overlay identity");
      Assert
        (not Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.File_Target_Prompt_Overlay),
         "Go To Line focus policy must not fabricate a file-target prompt");

      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Active_Find_Prompt_Overlay,
         S.Panel_Focus);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Find_Show);

      Assert
        (Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay),
         "post-command focus policy must preserve active Find/Replace overlay identity");
      Assert
        (not Editor.Overlay_Focus.Is_Active
           (S.Overlay_Focus, Editor.Overlay_Focus.File_Target_Prompt_Overlay),
         "Find/Replace focus policy must not convert to file-target prompt");

      Editor.Focus_Management.Restore_Focus_To_Editor (S);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Goto_Line_Prefill_Current);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "post-command focus policy must not open prompt focus when Executor did not create one");
   end Test_Prompt_Surface_Focus_Result_Preserves_Executor_Overlay;


   procedure Test_Diagnostics_Setting_Toggle_Does_Not_Hijack_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Focus_Management.Apply_Command_Focus_Result
        (S, Editor.Commands.Command_Toggle_Diagnostics,
         Editor.Focus_Management.Focus_File_Tree);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_File_Tree,
         "settings-level diagnostics toggle must not move focus to Diagnostics panel");
      Assert
        (not Editor.Focus_Management.Command_Closes_Focus_Owner
           (Editor.Commands.Command_Toggle_Diagnostics,
            Editor.Focus_Management.Focus_Diagnostics),
         "settings-level diagnostics toggle must not close the focused Diagnostics panel");
      Assert
        (Editor.Focus_Management.Focus_Target_For_Surface_Command
           (Editor.Commands.Command_Toggle_Problems_Panel) =
         Editor.Focus_Management.Focus_Diagnostics,
         "problems-panel toggle remains the panel-level diagnostics focus command");
   end Test_Diagnostics_Setting_Toggle_Does_Not_Hijack_Focus;


   procedure Test_Status_Message_Commands_Remain_Safe_Under_Modal_And_Overlay_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Target  : Editor.Pending_Transitions.Pending_Transition_Target;
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);

      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Clear_Selected_Message),
         "Quick Open overlay should allow safe status/message commands");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Copy_Selected_Message_Text),
         "Quick Open overlay should allow copying selected message text");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Dismiss_All_Messages),
         "Quick Open overlay should allow dismissing message notifications");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Save_File),
         "Quick Open overlay should still block editor/file mutation commands");

      Target.Kind := Editor.Pending_Transitions.Pending_Close_Project;
      Summary.Dirty_Count := 1;
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Summary);

      Assert
        (Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Clear_Selected_Message),
         "pending confirmation should allow safe message cleanup commands");
      Assert
        (Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Dismiss_All_Messages),
         "pending confirmation should allow safe message dismissal commands");
      Assert
        (not Editor.Focus_Management.Command_Allowed_While_Pending
           (Editor.Commands.Command_Save_File),
         "pending confirmation should still block file save mutation commands");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Open_Quick_Open),
         "pending confirmation should still block opening another overlay");
   end Test_Status_Message_Commands_Remain_Safe_Under_Modal_And_Overlay_Focus;



   procedure Test_Embedded_Text_Inputs_Outrank_Panels
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      declare
         Switched : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
           (S.Feature_Panel, Editor.Feature_Panel.Search_Results_Feature);
      begin
         Assert (Switched, "search-results feature should be accepted");
      end;
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      Editor.Feature_Search_Results.Activate_Search_Query_Input
        (S.Feature_Search_Results);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Query,
         "feature search query input should outrank retained file-tree focus");
      Assert
        (Editor.Focus_Management.Overlay_Input_Owns_Text (S),
         "embedded feature search query should own text input");
      Assert
        (not Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "embedded text input should prevent retained panel arrows from moving rows");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_File_Tree_Move_Down),
         "feature search query focus should block stale file-tree navigation");
   end Test_Embedded_Text_Inputs_Outrank_Panels;

   procedure Test_Outline_Filter_Input_Outranks_Retained_Panel_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      Editor.Outline.Activate_Filter_Input (S.Outline);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Outline_Filter,
         "outline filter input should outrank retained file-tree focus");
      Assert
        (Editor.Focus_Management.Overlay_Input_Owns_Text (S),
         "outline filter should be treated as a text-input owner");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_File_Tree_Move_Down),
         "outline filter focus should block stale file-tree navigation");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Select_Next_Outline_Item),
         "outline filter focus should retain outline-local navigation commands");
   end Test_Outline_Filter_Input_Outranks_Retained_Panel_Focus;


   procedure Test_Feature_Search_Input_Retains_Parent_Search_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      declare
         Switched : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
           (S.Feature_Panel, Editor.Feature_Panel.Search_Results_Feature);
      begin
         Assert (Switched, "search-results feature should be accepted");
      end;
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      Editor.Feature_Search_Results.Activate_Search_Query_Input
        (S.Feature_Search_Results);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Query,
         "embedded feature search query should own text while active");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "feature search input plus its parent Search Results panel should be coherent");

      Editor.Feature_Search_Results.Deactivate_Search_Query_Input
        (S.Feature_Search_Results);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Results,
         "closing embedded feature search should return navigation focus to Search Results");
      Assert
        (Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "Search Results should own panel navigation after its query input closes");
   end Test_Feature_Search_Input_Retains_Parent_Search_Focus;

   procedure Test_Embedded_Search_Input_Without_Parent_Is_Incoherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      Editor.Feature_Search_Results.Activate_Search_Query_Input
        (S.Feature_Search_Results);

      Assert
        (not Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "embedded feature search input must not float above an unrelated focused panel");
   end Test_Embedded_Search_Input_Without_Parent_Is_Incoherent;

   procedure Test_Outline_Filter_Retains_Parent_Outline_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Outline_Filter);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Outline_Filter,
         "outline filter should own text while active");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "outline filter and its parent Outline panel should not be treated as competing owners");

      Editor.Outline.Deactivate_Filter_Input (S.Outline);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Outline,
         "closing the outline filter should return navigation focus to Outline, not editor text");
      Assert
        (Editor.Focus_Management.Panel_Navigation_Owns_Arrows (S),
         "Outline should own panel navigation after its filter input closes");
   end Test_Outline_Filter_Retains_Parent_Outline_Focus;


   procedure Test_Embedded_Search_Query_Rejects_Project_Search_Bar_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      declare
         Switched : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
           (S.Feature_Panel, Editor.Feature_Panel.Search_Results_Feature);
      begin
         Assert (Switched, "search-results feature should be accepted");
      end;

      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      Editor.Feature_Search_Results.Activate_Search_Query_Input
        (S.Feature_Search_Results);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Query,
         "embedded search query should report project-search query focus");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Search_Results_Search_Active_Buffer),
         "embedded search query should accept its Search Results query commands");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Search_Results_Query_History_Previous),
         "embedded search query should accept Search Results query history commands");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Close_Project_Search_Bar),
         "embedded search query must not accept Project Search Bar close");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Toggle_Project_Search_Bar),
         "embedded search query must not accept Project Search Bar toggle");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Project_Search_Replace_Preview),
         "embedded search query must not accept Project Search replace-preview commands");
   end Test_Embedded_Search_Query_Rejects_Project_Search_Bar_Commands;

   procedure Test_Project_Search_Bar_Query_Keeps_Project_Search_Command_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Query);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Query,
         "Project Search Bar query should own project-search query focus");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Close_Project_Search_Bar),
         "Project Search Bar focus should accept its close command");
      Assert
        (Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Project_Search_Replace_Preview),
         "Project Search Bar focus should retain project replace-preview commands");
      Assert
        (not Editor.Focus_Management.Command_May_Run_In_Current_Focus
           (S, Editor.Commands.Command_Quick_Open_Next_Result),
         "Project Search Bar focus should still reject stale Quick Open navigation");
   end Test_Project_Search_Bar_Query_Keeps_Project_Search_Command_Family;


   procedure Test_Clear_Transient_Focus_Allows_Feature_Panel_To_Take_Focus
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      S.Build_UI.Build_UI_Focused := True;
      S.Latest_Build_Result_Focused := True;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := True;
      S.Recent_Projects_Focused := True;
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);

      Editor.Focus_Management.Clear_Transient_Focus_Owners (S);
      declare
         Switched : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
           (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
      begin
         Assert (Switched, "outline feature should be accepted");
      end;
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Outline,
         "clearing transient owners should let a clicked Feature Panel own focus");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "feature panel focus should be coherent after stale transient owners are cleared");
      Assert
        (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
         "clearing transient owners should dismiss stale overlays");
      Assert
        (not S.Build_UI.Build_UI_Focused
         and then not S.Latest_Build_Result_Focused
         and then not S.Latest_Build_Output_Details.Build_Output_Details_Focused
         and then not S.Recent_Projects_Focused,
         "clearing transient owners should remove stale build/recent focus markers");
   end Test_Clear_Transient_Focus_Allows_Feature_Panel_To_Take_Focus;



   procedure Test_Build_UI_Actions_Use_Unified_Focus_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);
      S.Recent_Projects_Focused := True;
      S.Latest_Build_Result_Focused := True;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := True;

      Editor.Build_UI_Actions.Focus_Build_UI (S);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Build_UI,
         "Build UI public focus action should use the unified focus owner path");
      Assert
        (not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus),
         "Build UI public focus action should clear stale overlay focus");
      Assert
        (not S.Recent_Projects_Focused
         and then not S.Latest_Build_Result_Focused
         and then not S.Latest_Build_Output_Details.Build_Output_Details_Focused,
         "Build UI public focus action should clear stale competing transient owners");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "Build UI public focus action should leave coherent focus state");
   end Test_Build_UI_Actions_Use_Unified_Focus_Path;

   procedure Test_Build_UI_Hide_Clears_Build_Focus_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_Output_Details);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Build_Output_Details,
         "Build Output Details should own focus before hide");

      Editor.Build_UI_Actions.Hide_Build_UI (S);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Editor,
         "hiding a build-owned surface should restore editor focus");
      Assert
        (not S.Build_UI.Build_UI_Focused
         and then not S.Latest_Build_Result_Focused
         and then not S.Latest_Build_Output_Details.Build_Output_Details_Focused,
         "hiding Build UI should clear the build focus family");
      Assert
        (Editor.Focus_Management.Assert_Panel_Focus_Management_Coherent (S),
         "hiding Build UI should leave coherent focus state");
   end Test_Build_UI_Hide_Clears_Build_Focus_Family;

   procedure Test_Executor_Feature_Focus_Clears_Stale_Transient_Owners
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      S.Build_UI.Build_UI_Visible := True;
      S.Build_UI.Build_UI_Focused := True;
      S.Latest_Build_Result_Focused := True;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := True;
      S.Recent_Projects_Focused := True;

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Focus_Feature_Panel);

      Assert
        (not S.Build_UI.Build_UI_Focused
         and then not S.Latest_Build_Result_Focused
         and then not S.Latest_Build_Output_Details.Build_Output_Details_Focused
         and then not S.Recent_Projects_Focused,
         "executor feature-panel focus should clear stale transient owners");
      Assert
        (Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
         "feature panel should own local navigation after focus command");
      Assert
        (Editor.Focus_Management.Focus_State_Has_No_Competing_Owners (S),
         "feature focus command should leave a coherent single-owner state");
   end Test_Executor_Feature_Focus_Clears_Stale_Transient_Owners;

   procedure Test_Overlay_Dismissal_Clears_Stale_Transient_Owners
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Search_Results_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panel_Focus.Focus_Bottom_Panel
        (S.Panel_Focus, Editor.Panel_Focus.Search_Results_Focus);

      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);

      S.Build_UI.Build_UI_Focused := True;
      S.Latest_Build_Result_Focused := True;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := True;
      S.Recent_Projects_Focused := True;

      Editor.Executor.Dismiss_Active_Overlay
        (S, Editor.Overlay_Focus.Dismiss_Escape);

      Assert
        (not S.Build_UI.Build_UI_Focused
         and then not S.Latest_Build_Result_Focused
         and then not S.Latest_Build_Output_Details.Build_Output_Details_Focused
         and then not S.Recent_Projects_Focused,
         "overlay dismissal should clear stale transient owners before restoring previous focus");
      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Project_Search_Results,
         "overlay dismissal should restore valid previous Search Results focus");
      Assert
        (Editor.Focus_Management.Focus_State_Has_No_Competing_Owners (S),
         "overlay dismissal should leave a coherent single-owner focus state");
   end Test_Overlay_Dismissal_Clears_Stale_Transient_Owners;


   procedure Test_Overlay_Activation_Clears_Lower_Priority_Focus_Owners
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      declare
         Switched : constant Boolean := Editor.Feature_Panel.Set_Active_Feature
           (S.Feature_Panel, Editor.Feature_Panel.Outline_Feature);
      begin
         Assert (Switched, "outline feature should be accepted");
      end;

      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Set_Focused (S.Feature_Panel, True);
      S.Build_UI.Build_UI_Focused := True;
      S.Latest_Build_Result_Focused := True;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := True;
      S.Recent_Projects_Focused := True;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Goto_Line);

      Assert
        (Editor.Focus_Management.Effective_Focus_Owner (S) =
         Editor.Focus_Management.Focus_Workspace_Prompt,
         "opening a prompt overlay should make the prompt the effective focus owner");
      Assert
        (not Editor.Feature_Panel.Is_Focused (S.Feature_Panel),
         "overlay activation should clear explicit Feature Panel focus");
      Assert
        (not S.Build_UI.Build_UI_Focused
         and then not S.Latest_Build_Result_Focused
         and then not S.Latest_Build_Output_Details.Build_Output_Details_Focused
         and then not S.Recent_Projects_Focused,
         "overlay activation should clear stale lower-priority transient owners");
      Assert
        (Editor.Focus_Management.Focus_State_Has_No_Competing_Owners (S),
         "overlay activation should leave a single transient owner for coherence audits");
   end Test_Overlay_Activation_Clears_Lower_Priority_Focus_Owners;

   procedure Register_Tests
     (T : in out Focus_Management_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Default_Editor_Owns_Focus'Access,
         "default editor focus owner is explicit");
      Register_Routine
        (T, Test_Overlay_Beats_Editor'Access,
         "overlay input owns text above editor");
      Register_Routine
        (T, Test_Panel_Arrows_Beat_Caret'Access,
         "panel navigation owns arrows above caret");
      Register_Routine
        (T, Test_Feature_Panel_Maps_To_Outline'Access,
         "feature panel maps focused surface");
      Register_Routine
        (T, Test_Pending_Confirmation_Is_Modal'Access,
         "pending confirmation owns modal focus");
      Register_Routine
        (T, Test_Pending_Confirmation_Blocks_File_Save_Mutations'Access,
         "pending confirmation blocks file save mutations");
      Register_Routine
        (T, Test_Project_Search_Replace_Field_Owns_Text'Access,
         "project replace input owns text focus");
      Register_Routine
        (T, Test_Focus_Priority_Rank_Is_Modal_First'Access,
         "focus priority rank is explicit");
      Register_Routine
        (T, Test_Set_Focus_Owner_Routes_To_Structural_Surface'Access,
         "set focus owner routes to structural surfaces");
      Register_Routine
        (T, Test_Set_Focus_Owner_Clears_Overlay_Text_Focus'Access,
         "explicit focus clears stale overlay text ownership");
      Register_Routine
        (T, Test_Build_UI_Focus_Uses_Build_Surface_State'Access,
         "Build UI focus uses retained Build surface state");
      Register_Routine
        (T, Test_Build_Output_Details_Focus_Uses_Output_Surface_State'Access,
         "Build output focus uses retained output details state");
      Register_Routine
        (T, Test_Activation_Escape_And_Persistence_Policies_Are_Explicit'Access,
         "activation escape and persistence policies are explicit");
      Register_Routine
        (T, Test_Build_Result_Summary_Focus_Uses_Transient_State'Access,
         "Build result summary focus uses transient state");
      Register_Routine
        (T, Test_Recent_Projects_Focus_Uses_Transient_State'Access,
         "Recent Projects focus uses transient state");
      Register_Routine
        (T, Test_Status_Projection_Labels_Are_Explicit'Access,
         "status projection labels active panel and input mode");
      Register_Routine
        (T, Test_Buffer_List_Overlay_Owns_Text'Access,
         "Buffer List overlay owns text input");
      Register_Routine
        (T, Test_Command_Eligibility_Is_Focus_Local'Access,
         "command eligibility is focus-local");
      Register_Routine
        (T, Test_Surface_Command_Families_Are_Focus_Local'Access,
         "surface command families are focus-local");
      Register_Routine
        (T, Test_Build_And_Output_Focus_Block_Stale_Editor_Or_Row_Input'Access,
         "build/output focus blocks stale editor or row input");
      Register_Routine
        (T, Test_Prompt_Focus_Blocks_Stale_Surface_Activation'Access,
         "prompt focus blocks stale surface activation");
      Register_Routine
        (T, Test_Surface_Entry_Command_Targets_Are_Auditable'Access,
         "surface-entry commands expose focus targets");
      Register_Routine
        (T, Test_Workspace_Prompt_Allows_Only_Prompt_Local_Commands'Access,
         "workspace prompt focus allows only prompt-local commands");
      Register_Routine
        (T, Test_Escape_Overlay_Close_Policy_Is_Explicit'Access,
         "Escape overlay close policy is explicit");
      Register_Routine
        (T, Test_Command_Level_Focus_Return_Policy_Is_Auditable'Access,
         "command-level activation focus-return policy is explicit");
      Register_Routine
        (T, Test_Command_Level_Dismissal_And_Navigation_Policy_Is_Auditable'Access,
         "command-level dismissal and navigation policies are explicit");
      Register_Routine
        (T, Test_Restore_Previous_Focus_Or_Editor_Uses_Overlay_History'Access,
         "overlay dismissal restores previous focus or editor fallback");
      Register_Routine
        (T, Test_Apply_Command_Focus_Result_Makes_Return_Policy_Active'Access,
         "command results actively apply focus-return policy");
      Register_Routine
        (T, Test_Apply_Command_Focus_Result_Restores_Previous_On_Dismissal'Access,
         "command results actively restore previous focus on dismissal");
      Register_Routine
        (T, Test_Surface_Entry_Result_Focus_Is_Active_But_Toggles_Are_Not'Access,
         "surface-entry command results actively focus deterministic surfaces");
      Register_Routine
        (T, Test_Surface_Entry_Targets_Cover_Toggle_And_Bottom_Panel_Commands'Access,
         "surface-entry targets cover toggle and bottom-panel commands");
      Register_Routine
        (T, Test_Cancel_Focus_Result_Uses_Pre_Command_Owner'Access,
         "cancel focus results use pre-command focus owner");
      Register_Routine
        (T, Test_Close_Command_Matches_Owning_Surface'Access,
         "close commands match the owning focused surface");
      Register_Routine
        (T, Test_Toggle_Close_Policy_Is_Owner_Scoped'Access,
         "toggle-close policy is scoped to the pre-command focus owner");
      Register_Routine
        (T, Test_Overlay_Focus_Blocks_Cross_Surface_Entry'Access,
         "overlay focus blocks cross-surface entry commands");
      Register_Routine
        (T, Test_Pending_Confirmation_Allows_Only_Modal_And_Status_Commands'Access,
         "pending confirmation allows only modal and status commands");
      Register_Routine
        (T, Test_Prompt_Accept_And_Local_Dismissal_Return_Focus'Access,
         "prompt accept/dismiss applies focus result policy");
      Register_Routine
        (T, Test_Local_Navigation_Command_Ids_Are_Focus_Routed'Access,
         "local navigation command ids are focus-routed");
      Register_Routine
        (T, Test_Feature_Panel_Local_Navigation_Is_Focus_Routed'Access,
         "Feature Panel local navigation is focus-routed");
      Register_Routine
        (T, Test_Project_Search_Bar_Enter_Command_Is_Focus_Local'Access,
         "Project Search bar Enter routes through canonical command focus policy");
      Register_Routine
        (T, Test_Project_Search_Bar_Local_Options_Are_Focus_Routed'Access,
         "Project Search bar local options route through canonical focus policy");
      Register_Routine
        (T, Test_Quick_Open_Local_Options_Are_Focus_Routed'Access,
         "Quick Open local options route through canonical focus policy");
      Register_Routine
        (T, Test_Workspace_Prompt_Surface_Entry_Targets_Are_Auditable'Access,
         "workspace prompt surface-entry commands are focus-targeted and overlay-gated");
      Register_Routine
        (T, Test_Prompt_Surface_Focus_Result_Preserves_Executor_Overlay'Access,
         "prompt post-command focus preserves executor overlay identity");
      Register_Routine
        (T, Test_Competing_Focus_Owner_Markers_Are_Rejected'Access,
         "coherence rejects competing transient focus-owner markers");
      Register_Routine
        (T, Test_Diagnostics_Setting_Toggle_Does_Not_Hijack_Focus'Access,
         "diagnostics settings toggle does not hijack panel focus");
      Register_Routine
        (T, Test_Status_Message_Commands_Remain_Safe_Under_Modal_And_Overlay_Focus'Access,
         "modal and overlay focus allow safe status/message commands only");
      Register_Routine
        (T, Test_Embedded_Text_Inputs_Outrank_Panels'Access,
         "embedded feature search input outranks retained panel focus");
      Register_Routine
        (T, Test_Outline_Filter_Input_Outranks_Retained_Panel_Focus'Access,
         "outline filter input outranks retained panel focus");
      Register_Routine
        (T, Test_Feature_Search_Input_Retains_Parent_Search_Focus'Access,
         "embedded search input returns to parent Search Results focus");
      Register_Routine
        (T, Test_Embedded_Search_Input_Without_Parent_Is_Incoherent'Access,
         "embedded search input requires its parent panel focus");
      Register_Routine
        (T, Test_Outline_Filter_Retains_Parent_Outline_Focus'Access,
         "outline filter returns to parent Outline focus");
      Register_Routine
        (T, Test_Embedded_Search_Query_Rejects_Project_Search_Bar_Commands'Access,
         "embedded search query rejects Project Search Bar commands");
      Register_Routine
        (T, Test_Project_Search_Bar_Query_Keeps_Project_Search_Command_Family'Access,
         "Project Search Bar query keeps its own command family");
      Register_Routine
        (T, Test_Clear_Transient_Focus_Allows_Feature_Panel_To_Take_Focus'Access,
         "pointer focus clears stale transient owners before Feature Panel focus");
      Register_Routine
        (T, Test_Build_UI_Actions_Use_Unified_Focus_Path'Access,
         "Build UI public focus action uses unified focus owner path");
      Register_Routine
        (T, Test_Build_UI_Hide_Clears_Build_Focus_Family'Access,
         "Build UI hide clears build focus family");
      Register_Routine
        (T, Test_Executor_Feature_Focus_Clears_Stale_Transient_Owners'Access,
         "executor feature-panel focus clears stale transient owners");
      Register_Routine
        (T, Test_Overlay_Dismissal_Clears_Stale_Transient_Owners'Access,
         "overlay dismissal clears stale transient owners before restoring focus");
      Register_Routine
        (T, Test_Overlay_Activation_Clears_Lower_Priority_Focus_Owners'Access,
         "overlay activation clears lower-priority transient focus owners");
   end Register_Tests;

end Editor.Focus_Management.Tests;
