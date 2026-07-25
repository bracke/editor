package Editor.Outline.Filtering is

   procedure Reset_Filter_History_Cursor (Outline : in out Outline_State);
   procedure Clear_Filtered_Projection (Outline : in out Outline_State);
   function Row_Matches_Filter
     (Outline : Outline_State;
      Index   : Positive) return Boolean;
   procedure Reconcile_Filtered_Selection (Outline : in out Outline_State);

   procedure Activate_Filter_Input
     (Outline : in out Outline_State);
   procedure Deactivate_Filter_Input
     (Outline : in out Outline_State);
   function Filter_Input_Is_Active
     (Outline : Outline_State) return Boolean;
   function Filter_Caret
     (Outline : Outline_State) return Natural;
   procedure Apply_Filter
     (Outline : in out Outline_State;
      Text    : String);
   procedure Insert_Filter_Character
     (Outline : in out Outline_State;
      Ch      : Character);
   procedure Insert_Filter_Text
     (Outline : in out Outline_State;
      Text    : String);
   procedure Delete_Filter_Character_Backward
     (Outline : in out Outline_State);
   procedure Delete_Filter_Character_Forward
     (Outline : in out Outline_State);
   procedure Move_Filter_Caret_Left
     (Outline : in out Outline_State);
   procedure Move_Filter_Caret_Right
     (Outline : in out Outline_State);
   procedure Move_Filter_Caret_Start
     (Outline : in out Outline_State);
   procedure Move_Filter_Caret_End
     (Outline : in out Outline_State);
   procedure Clear_Filter_Text
     (Outline : in out Outline_State);
   procedure Clear_Filter
     (Outline : in out Outline_State);
   procedure Reset_Filter_State_For_Lifecycle
     (Outline : in out Outline_State);
   procedure Commit_Filter_To_History
     (Outline : in out Outline_State);
   function Filter_History_Count
     (Outline : Outline_State) return Natural;
   function Filter_History_Entry
     (Outline : Outline_State;
      Index   : Positive) return String;
   function Select_Previous_Filter_History_Entry
     (Outline : in out Outline_State) return Boolean;
   function Select_Next_Filter_History_Entry
     (Outline : in out Outline_State) return Boolean;
   procedure Clear_Filter_History
     (Outline : in out Outline_State);
   procedure Remember_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural);
   function Restore_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural) return Boolean;
   procedure Forget_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural);
   procedure Clear_All_Remembered_Filters
     (Outline : in out Outline_State);
   function Remembered_Filter_Count
     (Outline : Outline_State) return Natural;
   function Filter_Is_Active
     (Outline : Outline_State) return Boolean;
   function Filter_Text
     (Outline : Outline_State) return String;
   function Filtered_Row_Count
     (Outline : Outline_State) return Natural;
   function Rows_Generation
     (Outline : Outline_State) return Natural;
   function Filter_Generation
     (Outline : Outline_State) return Natural;
   function Projection_Generation
     (Outline : Outline_State) return Natural;
   function Visible_Row_For_Outline_Row
     (Outline           : Outline_State;
      Outline_Row_Index : Natural) return Natural;
   function Outline_Row_For_Visible_Row
     (Outline           : Outline_State;
      Visible_Row_Index : Natural) return Natural;

end Editor.Outline.Filtering;
