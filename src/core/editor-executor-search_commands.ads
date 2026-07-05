with Editor.Commands;
with Editor.State;

package Editor.Executor.Search_Commands is

   function Project_Search_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Show_Search_Results_Panel
     (S : in out Editor.State.State_Type);

   function Search_Results_Visible_Row_Count return Natural;

   procedure Ensure_Search_Result_Visible
     (S : in out Editor.State.State_Type);

   procedure Execute_Focus_Search_Results
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Move_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Move_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Page_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Page_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Open_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Search_Results_Close_Or_Hide
     (S : in out Editor.State.State_Type);

   procedure Execute_Run_Project_Search
     (S     : in out Editor.State.State_Type;
      Query : String);

   procedure Execute_Rerun_Project_Search
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Toggle_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Close_Project_Search_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Run_Project_Search_From_Bar
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Bar_Insert_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   procedure Execute_Project_Search_Bar_Backspace
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Bar_Delete_Forward
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_From_Selection
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_From_Active_Word
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Active_Directory
     (S : in out Editor.State.State_Type);

   procedure Execute_Clear_Project_Search
     (S : in out Editor.State.State_Type);

   procedure Execute_Open_Project_Search_Result
     (S            : in out Editor.State.State_Type;
      Result_Index : Natural);

   procedure Execute_Open_Selected_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Move_Project_Search_Selection_Down
     (S : in out Editor.State.State_Type);

   procedure Execute_Move_Project_Search_Selection_Up
     (S : in out Editor.State.State_Type);

   procedure Execute_Next_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Previous_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_First_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Last_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Reveal_Active_Project_Search_Result
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Scope_Selected_Directory
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind_Next
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind_Previous
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Scope_Set
     (S     : in out Editor.State.State_Type;
      Scope : String);

   procedure Execute_Project_Search_Scope_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Case_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Case_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Whole_Word_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Whole_Word_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Regex_Toggle
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Regex_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Include_Filter_Set
     (S      : in out Editor.State.State_Type;
      Filter : String);

   procedure Execute_Project_Search_Exclude_Filter_Set
     (S      : in out Editor.State.State_Type;
      Filter : String);

   procedure Execute_Project_Search_Include_Filter_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Exclude_Filter_Clear
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Preview
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Toggle_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Include_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Exclude_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Include_File
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Exclude_File
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Include_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Exclude_All
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Selected
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_All_Included
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Replace_Clear_Preview
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Search_Commands;
