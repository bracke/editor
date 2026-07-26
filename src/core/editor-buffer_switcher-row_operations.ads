with Editor.Buffer_Switcher.Audits;
with Editor.Buffer_Switcher.Config;
with Editor.Buffer_Switcher.Filters;
with Editor.Buffer_Switcher.Rows;
limited with Editor.Buffers;
with Editor.Buffer_Types;
with Editor.Input_Field;
with Editor.Layout;
with Editor.Project;
with Editor.Recent_Buffers;

package Editor.Buffer_Switcher.Row_Operations is

   function Lower (Text : String) return String;

   function Contains (Text, Part : String) return Boolean;

   function Matches_Metadata_Filter
     (Summary : Editor.Buffer_Types.Buffer_Summary;
      Filter  : Editor.Buffer_Switcher.Filters.Switcher_Metadata_Filter) return Boolean;

   function Matches_Buffer_State_Filter
     (Row    : Editor.Buffer_Switcher.Rows.Buffer_Switcher_Row;
      Filter : Editor.Buffer_Switcher.Filters.Switcher_Metadata_Filter) return Boolean;

   procedure Clamp_Window
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Recompute_Rows
     (State    : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Config   : Editor.Buffer_Switcher.Config.Buffer_Switcher_Config);

   procedure Recompute_Rows
     (State    : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Config   : Editor.Buffer_Switcher.Config.Buffer_Switcher_Config);

   procedure Recompute_Rows
     (State    : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Project  : Editor.Project.Project_State;
      Config   : Editor.Buffer_Switcher.Config.Buffer_Switcher_Config);

   procedure Move_Selection_Down
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Move_Selection_Up
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Show_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Preview
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Preview
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   procedure Set_Preview_Target
     (State       : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Target      : Editor.Buffer_Types.Buffer_Id;
      Anchor_Line : Natural);

   procedure Clear_Preview_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Preview_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Editor.Buffer_Types.Buffer_Id;

   function Preview_Anchor_Line
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Preview_Scroll_Offset
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   procedure Scroll_Preview_Next_Line
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Scroll_Preview_Previous_Line
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Center_Preview_On_Line
     (State       : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Anchor_Line : Natural);

   procedure Select_Buffer_Or_Row
     (State          : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Preferred_Id   : Editor.Buffer_Types.Buffer_Id;
      Fallback_Index : Natural);

   function Select_Next_Marked_Buffer
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Previous_Marked_Buffer
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Next_Pending_Marked_Buffer
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Previous_Pending_Marked_Buffer
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Next_Pruned_Pending_Marked_Buffer
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Previous_Pruned_Pending_Marked_Buffer
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Next_Dirty_Pending_Marked_Buffer
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Previous_Dirty_Pending_Marked_Buffer
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Next_Dirty_Prune_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Previous_Dirty_Prune_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Next_Removed_Dirty_Prune_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Previous_Removed_Dirty_Prune_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Next_Dirty_Prune_Apply_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Previous_Dirty_Prune_Apply_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Next_Removed_Dirty_Prune_Apply_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Select_Previous_Removed_Dirty_Prune_Apply_Target
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Row_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Selected_Row_Index
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Top_Row_Index
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Row_At
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Index : Positive) return Editor.Buffer_Switcher.Rows.Buffer_Switcher_Row;

   function Row_For_Buffer
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id;
      Found : out Boolean) return Editor.Buffer_Switcher.Rows.Buffer_Switcher_Row;

   function Selected_Row
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Found : out Boolean) return Editor.Buffer_Switcher.Rows.Buffer_Switcher_Row;

   function Audit_Selected_Buffer_List_State
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry)
      return Editor.Buffer_Switcher.Audits.Selected_Buffer_List_Audit;

   function Query_Snapshot
     (State           : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot;

   function Geometry
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Editor.Buffer_Switcher.Config.Buffer_Switcher_Config;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Editor.Layout.Rect;

end Editor.Buffer_Switcher.Row_Operations;
