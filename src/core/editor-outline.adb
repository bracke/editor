with Editor.Outline.Activation;
with Editor.Outline.Filtering;
with Editor.Outline.Projection;
with Editor.Outline.Selection;

package body Editor.Outline is

   function Invariant_Holds
     (Outline : Outline_State) return Boolean
     renames Projection.Invariant_Holds;

   function Debug_Summary
     (Outline : Outline_State) return String
     renames Projection.Debug_Summary;

   procedure Clear
     (Outline : in out Outline_State)
     renames Projection.Clear;

   procedure Reset_Outline_For_Buffer_Close
     (Outline      : in out Outline_State;
      Buffer_Token : Natural)
     renames Projection.Reset_Outline_For_Buffer_Close;

   procedure Reset_Outline_For_Project_Close
     (Outline : in out Outline_State)
     renames Projection.Reset_Outline_For_Project_Close;

   procedure Reset_Outline_For_Workspace_Close
     (Outline : in out Outline_State)
     renames Projection.Reset_Outline_For_Workspace_Close;

   procedure Reset_Outline_For_Unsupported_Content
     (Outline : in out Outline_State)
     renames Projection.Reset_Outline_For_Unsupported_Content;

   procedure Reset_Outline_For_Extraction_Failure
     (Outline : in out Outline_State;
      Message : String)
     renames Projection.Reset_Outline_For_Extraction_Failure;

   procedure Mark_No_Active_Buffer
     (Outline : in out Outline_State)
     renames Projection.Mark_No_Active_Buffer;

   procedure Assert_Outline_State_Consistent
     (Outline : Outline_State)
     renames Projection.Assert_Outline_State_Consistent;

   procedure Begin_Extraction
     (Outline  : in out Outline_State;
      Snapshot : Outline_Snapshot_Identity)
     renames Projection.Begin_Extraction;

   function Next_Request_Token
     (Outline : Outline_State) return Natural
     renames Projection.Next_Request_Token;

   function Snapshot_Is_Current
     (Outline  : Outline_State;
      Snapshot : Outline_Snapshot_Identity) return Boolean
     renames Projection.Snapshot_Is_Current;

   procedure Mark_Stale_Result
     (Outline : in out Outline_State;
      Message : String := "Outline result discarded: stale buffer snapshot")
     renames Projection.Mark_Stale_Result;

   procedure Mark_Extraction_Failed
     (Outline : in out Outline_State;
      Message : String := "Outline extraction failed")
     renames Projection.Mark_Extraction_Failed;

   procedure Mark_Unsupported
     (Outline : in out Outline_State;
      Message : String := "Outline unavailable for this buffer")
     renames Projection.Mark_Unsupported;

   procedure Reset_For_Project_Close
     (Outline : in out Outline_State)
     renames Projection.Reset_For_Project_Close;

   procedure Reset_For_Buffer_Change
     (Outline : in out Outline_State)
     renames Projection.Reset_For_Buffer_Change;

   procedure Mark_For_Buffer_Change
     (Outline : in out Outline_State)
     renames Projection.Mark_For_Buffer_Change;

   function Is_Current_For_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Boolean
     renames Projection.Is_Current_For_Buffer;

   function Is_Stale_For_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Boolean
     renames Projection.Is_Stale_For_Buffer;

   function Freshness_For_Active_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Outline_Freshness
     renames Projection.Freshness_For_Active_Buffer;

   function Source_Buffer_Token
     (Outline : Outline_State) return Natural
     renames Projection.Source_Buffer_Token;

   function Source_Buffer_Revision
     (Outline : Outline_State) return Natural
     renames Projection.Source_Buffer_Revision;

   function Refresh
     (Outline : in out Outline_State;
      Source  : Outline_Refresh_Source) return Outline_Refresh_Result
     renames Projection.Refresh;

   procedure Replace_Items
     (Outline : in out Outline_State;
      Items   : Outline_Item_Array)
     renames Projection.Replace_Items;

   procedure Select_Item
     (Outline : in out Outline_State;
      Index   : Natural)
     renames Selection.Select_Item;

   function Selected_Index
     (Outline : Outline_State) return Natural
     renames Selection.Selected_Index;

   procedure Activate_Filter_Input
     (Outline : in out Outline_State)
     renames Filtering.Activate_Filter_Input;

   procedure Deactivate_Filter_Input
     (Outline : in out Outline_State)
     renames Filtering.Deactivate_Filter_Input;

   function Filter_Input_Is_Active
     (Outline : Outline_State) return Boolean
     renames Filtering.Filter_Input_Is_Active;

   function Filter_Caret
     (Outline : Outline_State) return Natural
     renames Filtering.Filter_Caret;

   procedure Apply_Filter
     (Outline : in out Outline_State;
      Text    : String)
     renames Filtering.Apply_Filter;

   procedure Insert_Filter_Character
     (Outline : in out Outline_State;
      Ch      : Character)
     renames Filtering.Insert_Filter_Character;

   procedure Insert_Filter_Text
     (Outline : in out Outline_State;
      Text    : String)
     renames Filtering.Insert_Filter_Text;

   procedure Delete_Filter_Character_Backward
     (Outline : in out Outline_State)
     renames Filtering.Delete_Filter_Character_Backward;

   procedure Delete_Filter_Character_Forward
     (Outline : in out Outline_State)
     renames Filtering.Delete_Filter_Character_Forward;

   procedure Move_Filter_Caret_Left
     (Outline : in out Outline_State)
     renames Filtering.Move_Filter_Caret_Left;

   procedure Move_Filter_Caret_Right
     (Outline : in out Outline_State)
     renames Filtering.Move_Filter_Caret_Right;

   procedure Move_Filter_Caret_Start
     (Outline : in out Outline_State)
     renames Filtering.Move_Filter_Caret_Start;

   procedure Move_Filter_Caret_End
     (Outline : in out Outline_State)
     renames Filtering.Move_Filter_Caret_End;

   procedure Clear_Filter_Text
     (Outline : in out Outline_State)
     renames Filtering.Clear_Filter_Text;

   procedure Clear_Filter
     (Outline : in out Outline_State)
     renames Filtering.Clear_Filter;

   procedure Reset_Filter_State_For_Lifecycle
     (Outline : in out Outline_State)
     renames Filtering.Reset_Filter_State_For_Lifecycle;

   procedure Commit_Filter_To_History
     (Outline : in out Outline_State)
     renames Filtering.Commit_Filter_To_History;

   function Filter_History_Count
     (Outline : Outline_State) return Natural
     renames Filtering.Filter_History_Count;

   function Filter_History_Entry
     (Outline : Outline_State;
      Index   : Positive) return String
     renames Filtering.Filter_History_Entry;

   function Select_Previous_Filter_History_Entry
     (Outline : in out Outline_State) return Boolean
     renames Filtering.Select_Previous_Filter_History_Entry;

   function Select_Next_Filter_History_Entry
     (Outline : in out Outline_State) return Boolean
     renames Filtering.Select_Next_Filter_History_Entry;

   procedure Clear_Filter_History
     (Outline : in out Outline_State)
     renames Filtering.Clear_Filter_History;

   procedure Remember_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural)
     renames Filtering.Remember_Filter_For_Buffer;

   function Restore_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural) return Boolean
     renames Filtering.Restore_Filter_For_Buffer;

   procedure Forget_Filter_For_Buffer
     (Outline      : in out Outline_State;
      Buffer_Token : Natural)
     renames Filtering.Forget_Filter_For_Buffer;

   procedure Clear_All_Remembered_Filters
     (Outline : in out Outline_State)
     renames Filtering.Clear_All_Remembered_Filters;

   function Remembered_Filter_Count
     (Outline : Outline_State) return Natural
     renames Filtering.Remembered_Filter_Count;

   function Filter_Is_Active
     (Outline : Outline_State) return Boolean
     renames Filtering.Filter_Is_Active;

   function Filter_Text
     (Outline : Outline_State) return String
     renames Filtering.Filter_Text;

   function Filtered_Row_Count
     (Outline : Outline_State) return Natural
     renames Filtering.Filtered_Row_Count;

   function Rows_Generation
     (Outline : Outline_State) return Natural
     renames Filtering.Rows_Generation;

   function Filter_Generation
     (Outline : Outline_State) return Natural
     renames Filtering.Filter_Generation;

   function Projection_Generation
     (Outline : Outline_State) return Natural
     renames Filtering.Projection_Generation;

   function Visible_Row_For_Outline_Row
     (Outline           : Outline_State;
      Outline_Row_Index : Natural) return Natural
     renames Filtering.Visible_Row_For_Outline_Row;

   function Outline_Row_For_Visible_Row
     (Outline           : Outline_State;
      Visible_Row_Index : Natural) return Natural
     renames Filtering.Outline_Row_For_Visible_Row;

   function Has_Selected_Item
     (Outline : Outline_State) return Boolean
     renames Selection.Has_Selected_Item;

   procedure Clear_Current_Symbol
     (Outline : in out Outline_State)
     renames Selection.Clear_Current_Symbol;

   procedure Set_Current_Symbol_Index
     (Outline : in out Outline_State;
      Index   : Natural)
     renames Selection.Set_Current_Symbol_Index;

   function Current_Symbol_Index
     (Outline : Outline_State) return Natural
     renames Selection.Current_Symbol_Index;

   function Has_Current_Symbol
     (Outline : Outline_State) return Boolean
     renames Selection.Has_Current_Symbol;

   function Current_Symbol_Label
     (Outline : Outline_State) return String
     renames Selection.Current_Symbol_Label;

   function Current_Symbol_Line
     (Outline : Outline_State) return Natural
     renames Selection.Current_Symbol_Line;

   function Find_Current_Symbol_For_Cursor
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural
     renames Selection.Find_Current_Symbol_For_Cursor;

   procedure Update_Current_Symbol_For_Cursor
     (Outline      : in out Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1)
     renames Selection.Update_Current_Symbol_For_Cursor;

   function Outline_Header_Text
     (Outline : Outline_State) return String
     renames Selection.Outline_Header_Text;

   function Outline_Empty_State_Label
     (Outline : Outline_State) return String
     renames Selection.Outline_Empty_State_Label;

   function Is_Current_Symbol_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean
     renames Selection.Is_Current_Symbol_Row;

   function Is_Selectable_Target_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean
     renames Selection.Is_Selectable_Target_Row;

   function Has_Selectable_Filter_Match
     (Outline : Outline_State) return Boolean
     renames Selection.Has_Selectable_Filter_Match;

   function Navigable_Symbol_Count
     (Outline : Outline_State) return Natural
     renames Selection.Navigable_Symbol_Count;

   function Filtered_Navigable_Symbol_Count
     (Outline : Outline_State) return Natural
     renames Selection.Filtered_Navigable_Symbol_Count;

   function Can_Reveal_Current_Symbol
     (Outline             : Outline_State;
      Panel               : Editor.Feature_Panel.Feature_Panel_State;
      Active_Buffer_Token : Natural) return Boolean
     renames Selection.Can_Reveal_Current_Symbol;

   function Same_Outline_Target
     (Left, Right : Outline_Item) return Boolean
     renames Selection.Same_Outline_Target;

   function Same_Outline_Symbol
     (Left, Right : Outline_Item) return Boolean
     renames Selection.Same_Outline_Symbol;

   function Outline_Buffer_Identity_Matches
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean
     renames Selection.Outline_Buffer_Identity_Matches;

   function Has_Navigable_Symbol_For_Buffer
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean
     renames Selection.Has_Navigable_Symbol_For_Buffer;

   function Selection_Preservation_Score
     (Previous, Candidate : Outline_Item) return Natural
     renames Selection.Selection_Preservation_Score;

   function Find_Nearest_Item_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural
     renames Selection.Find_Nearest_Item_For_Position;

   function Find_Next_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural
     renames Selection.Find_Next_Symbol_For_Position;

   function Find_Previous_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural
     renames Selection.Find_Previous_Symbol_For_Position;

   function Select_Next_Selectable
     (Outline : in out Outline_State) return Boolean
     renames Selection.Select_Next_Selectable;

   function Select_Previous_Selectable
     (Outline : in out Outline_State) return Boolean
     renames Selection.Select_Previous_Selectable;

   procedure Set_Rows_From_Outline
     (Outline : Outline_State;
      Panel   : in out Editor.Feature_Panel.Feature_Panel_State)
     renames Projection.Set_Rows_From_Outline;

   function Item_Count
     (Outline : Outline_State) return Natural
     renames Projection.Item_Count;

   function Has_Items
     (Outline : Outline_State) return Boolean
     renames Projection.Has_Items;

   function Source_Class
     (Outline : Outline_State) return Outline_Source_Class
     renames Projection.Source_Class;

   function Last_Extraction_Source_Class
     (Outline : Outline_State) return Outline_Source_Class
     renames Projection.Last_Extraction_Source_Class;

   function Last_Extraction_Message
     (Outline : Outline_State) return String
     renames Projection.Last_Extraction_Message;

   function Last_Extraction_Buffer_Label
     (Outline : Outline_State) return String
     renames Projection.Last_Extraction_Buffer_Label;

   function Last_Extraction_Item_Count
     (Outline : Outline_State) return Natural
     renames Projection.Last_Extraction_Item_Count;

   function Item_Label
     (Outline : Outline_State;
      Index   : Positive) return String
     renames Projection.Item_Label;

   function Item_Detail
     (Outline : Outline_State;
      Index   : Positive) return String
     renames Projection.Item_Detail;

   function Item_Depth
     (Outline : Outline_State;
      Index   : Positive) return Natural
     renames Projection.Item_Depth;

   function Item_Kind
     (Outline : Outline_State;
      Index   : Positive) return Outline_Item_Kind
     renames Projection.Item_Kind;

   function Item_Target_Kind
     (Outline : Outline_State;
      Index   : Positive) return Outline_Target_Kind
     renames Projection.Item_Target_Kind;

   function Item_Buffer_Token
     (Outline : Outline_State;
      Index   : Positive) return Natural
     renames Projection.Item_Buffer_Token;

   function Item_Line
     (Outline : Outline_State;
      Index   : Positive) return Natural
     renames Projection.Item_Line;

   function Item_Column
     (Outline : Outline_State;
      Index   : Positive) return Natural
     renames Projection.Item_Column;

   function Feature_Row_Maps_To_Item
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State;
      Row     : Positive) return Boolean
     renames Activation.Feature_Row_Maps_To_Item;

   function Map_Panel_Row_To_Outline_Row
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Natural
     renames Activation.Map_Panel_Row_To_Outline_Row;

   function Validate_Outline_Row_For_Selection
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Boolean
     renames Activation.Validate_Outline_Row_For_Selection;

   function Validate_Outline_Row_For_Activation
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Active_Buffer_Token       : Natural;
      Expected_Panel_Generation : Natural := 0) return Boolean
     renames Activation.Validate_Outline_Row_For_Activation;

   function Summary
     (Outline : Outline_State) return Outline_Summary
     renames Projection.Summary;

   function Fingerprint
     (Outline : Outline_State) return Natural
     renames Projection.Fingerprint;

   function Message_Outline_Refreshed return String
     renames Activation.Message_Outline_Refreshed;

   function Message_Outline_Cleared return String
     renames Activation.Message_Outline_Cleared;

   function Message_Outline_Shown return String
     renames Activation.Message_Outline_Shown;

   function Message_Outline_Focused return String
     renames Activation.Message_Outline_Focused;

   function Message_Outline_Item_Has_No_Target return String
     renames Activation.Message_Outline_Item_Has_No_Target;

   function Message_Outline_Refresh_Failed return String
     renames Activation.Message_Outline_Refresh_Failed;

   function Message_Outline_No_Current_Symbol return String
     renames Activation.Message_Outline_No_Current_Symbol;

   function Message_Outline_Current_Symbol_Revealed return String
     renames Activation.Message_Outline_Current_Symbol_Revealed;

   function Message_Outline_No_Active_Buffer return String
     renames Activation.Message_Outline_No_Active_Buffer;

   function Message_Outline_Unsupported_Buffer return String
     renames Activation.Message_Outline_Unsupported_Buffer;

   function Message_Outline_No_Symbols return String
     renames Activation.Message_Outline_No_Symbols;

   function Message_Outline_No_Matching_Symbols return String
     renames Activation.Message_Outline_No_Matching_Symbols;

   function Message_Outline_No_Selected_Symbol return String
     renames Activation.Message_Outline_No_Selected_Symbol;

   function Message_Outline_Stale_Result_Discarded return String
     renames Activation.Message_Outline_Stale_Result_Discarded;

   function Projection_Invariant_Holds
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State) return Boolean
     renames Projection.Projection_Invariant_Holds;

   procedure Assert_Outline_Projection_Consistent
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State)
     renames Projection.Assert_Outline_Projection_Consistent;

   function Reason_No_Active_Buffer return String
     renames Activation.Reason_No_Active_Buffer;

   function Reason_No_Outline_Items return String
     renames Activation.Reason_No_Outline_Items;

   function Reason_No_Outline_Item_Selected return String
     renames Activation.Reason_No_Outline_Item_Selected;

   function Reason_Outline_Belongs_To_Another_Buffer return String
     renames Activation.Reason_Outline_Belongs_To_Another_Buffer;

   function Reason_Feature_Panel_Hidden return String
     renames Activation.Reason_Feature_Panel_Hidden;

   function Reason_Feature_Panel_Already_Shown return String
     renames Activation.Reason_Feature_Panel_Already_Shown;

   function Reason_Feature_Panel_Already_Focused return String
     renames Activation.Reason_Feature_Panel_Already_Focused;

end Editor.Outline;
