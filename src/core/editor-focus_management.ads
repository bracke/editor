with Editor.Commands;
with Editor.State;

package Editor.Focus_Management is

   type Focus_Owner is
     (Focus_None,
      Focus_Editor,
      Focus_Command_Palette,
      Focus_Quick_Open,
      Focus_Project_Search_Query,
      Focus_Project_Search_Results,
      Focus_Project_Replace_Input,
      Focus_File_Tree,
      Focus_Outline,
      Focus_Outline_Filter,
      Focus_Diagnostics,
      Focus_Terminal,
      Focus_Build_UI,
      Focus_Build_Result_Summary,
      Focus_Build_Output_Details,
      Focus_Buffer_List,
      Focus_Recent_Projects,
      Focus_Workspace_Prompt,
      Focus_Pending_Confirmation);

   function Effective_Focus_Owner
     (S : Editor.State.State_Type) return Focus_Owner;

   function Focus_Owner_Label
     (Owner : Focus_Owner) return String;

   function Active_Panel_Label
     (Owner : Focus_Owner) return String;

   function Input_Mode_Label
     (Owner : Focus_Owner) return String;

   function Overlay_Query_Active
     (S : Editor.State.State_Type) return Boolean;

   function Editor_Text_Can_Edit
     (S : Editor.State.State_Type) return Boolean;

   function Overlay_Input_Owns_Text
     (S : Editor.State.State_Type) return Boolean;

   function Panel_Navigation_Owns_Arrows
     (S : Editor.State.State_Type) return Boolean;

   function Pending_Confirmation_Owns_Focus
     (S : Editor.State.State_Type) return Boolean;

   function Focus_Priority_Rank
     (Owner : Focus_Owner) return Natural;

   function Text_Input_Owner
     (Owner : Focus_Owner) return Boolean;

   function Navigation_Panel_Owner
     (Owner : Focus_Owner) return Boolean;

   function Global_Keybindings_May_Run
     (S : Editor.State.State_Type) return Boolean;

   function Command_Is_Surface_Entry
     (Id : Editor.Commands.Command_Id) return Boolean;

   function Focus_Target_For_Surface_Command
     (Id : Editor.Commands.Command_Id) return Focus_Owner;

   function Command_May_Run_In_Current_Focus
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return Boolean;

   function Activation_Returns_Focus_To_Editor
     (Owner : Focus_Owner) return Boolean;

   function Escape_Returns_Focus_To_Editor
     (Owner : Focus_Owner) return Boolean;

   function Escape_Closes_Overlay
     (Owner : Focus_Owner) return Boolean;

   function Command_Is_Panel_Local_Navigation
     (Id : Editor.Commands.Command_Id) return Boolean;

   function Command_Closes_Focused_Surface
     (Id : Editor.Commands.Command_Id) return Boolean;

   function Command_Returns_Focus_To_Editor
     (Id : Editor.Commands.Command_Id) return Boolean;

   function Focus_State_Is_Persistable
     (Owner : Focus_Owner) return Boolean;

   function Focus_State_Has_No_Competing_Owners
     (S : Editor.State.State_Type) return Boolean;

   procedure Set_Focus_Owner
     (S     : in out Editor.State.State_Type;
      Owner : Focus_Owner);

   procedure Restore_Focus_To_Editor
     (S : in out Editor.State.State_Type);

   procedure Clear_Transient_Focus_Owners
     (S : in out Editor.State.State_Type);


   procedure Restore_Previous_Focus_Or_Editor
     (S : in out Editor.State.State_Type);

   function Command_Focuses_Surface_After_Execution
     (Id : Editor.Commands.Command_Id) return Boolean;

   procedure Apply_Command_Focus_Result
     (S            : in out Editor.State.State_Type;
      Id           : Editor.Commands.Command_Id;
      Owner_Before : Focus_Owner := Focus_None);

   function Command_Closes_Focus_Owner
     (Id    : Editor.Commands.Command_Id;
      Owner : Focus_Owner) return Boolean;

   function Command_Toggles_Focus_Owner
     (Id    : Editor.Commands.Command_Id;
      Owner : Focus_Owner) return Boolean;

   function Command_Allowed_While_Pending
     (Id : Editor.Commands.Command_Id) return Boolean;

   function Command_Is_Conflicting_While_Pending
     (Id : Editor.Commands.Command_Id) return Boolean;

   function Assert_Panel_Focus_Management_Coherent
     (S : Editor.State.State_Type) return Boolean;

end Editor.Focus_Management;
