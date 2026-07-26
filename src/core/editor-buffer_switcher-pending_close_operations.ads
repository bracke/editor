with Editor.Buffer_Switcher.Reviews;
with Editor.Buffer_Switcher.Rows;
package Editor.Buffer_Switcher.Pending_Close_Operations is

   function Is_Pending_Marked_Close_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   function Build_Switcher_Row_Markers
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Row   : Editor.Buffer_Switcher.Rows.Buffer_Switcher_Row)
      return Editor.Buffer_Switcher.Rows.Buffer_Switcher_Row;

   function Has_Pruned_Pending_Marked_Close_Targets
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Pruned_Pending_Marked_Close_Target_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Open_Pruned_Pending_Marked_Close_Target_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   function Last_Pruned_Pending_Marked_Close_Target_Name
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   function Is_Pruned_Pending_Marked_Close_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   procedure Clear_Pending_Marked_Action
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Pending_Marked_Action
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State)
      return Editor.Buffer_Switcher.Reviews.Pending_Marked_Action_Kind;

   function Pending_Marked_Target_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Pending_Marked_Dirty_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Pending_Marked_Target_At
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Index : Positive) return Editor.Buffer_Types.Buffer_Id;

   procedure Prepare_Pending_Marked_Close
     (State       : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry    : Editor.Buffers.Buffer_Registry;
      Count       : out Natural;
      Dirty_Count : out Natural);

   function Pending_Marked_Open_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   function Pending_Marked_Open_Dirty_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   procedure Remove_Pending_Marked_Close_Target
     (State     : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffer_Types.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural);

   procedure Restore_Last_Pruned_Pending_Marked_Close_Target
     (State        : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffer_Types.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural);

   procedure Restore_Pruned_Pending_Marked_Close_Target
     (State        : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Id           : Editor.Buffer_Types.Buffer_Id;
      Restored     : out Boolean;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural);

end Editor.Buffer_Switcher.Pending_Close_Operations;
