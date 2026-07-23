package Editor.Buffer_Switcher.Dirty_Prune_Operations is

   procedure Prepare_Dirty_Pending_Marked_Close_Prune
     (State    : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Count    : out Natural);

   function Has_Dirty_Pending_Marked_Close_Prune
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Dirty_Pending_Marked_Close_Prune_Target_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   function Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   function Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Boolean;

   procedure Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
     (State     : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Cleared   : out Natural;
      Remaining : out Natural);

   function Is_Dirty_Pending_Marked_Close_Prune_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   procedure Remove_Dirty_Pending_Marked_Close_Prune_Target
     (State     : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffer_Types.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural);

   function Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   function Last_Removed_Dirty_Pending_Marked_Close_Prune_Target_Name
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   function Is_Removed_Dirty_Pending_Marked_Close_Prune_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   procedure Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
     (State        : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffer_Types.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural);

   procedure Cancel_Dirty_Pending_Marked_Close_Prune
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Apply_Dirty_Pending_Marked_Close_Prune
     (State     : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Applied   : out Natural;
      Remaining : out Natural);

   procedure Prepare_Dirty_Pending_Marked_Close_Prune_Apply
     (State      : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry   : Editor.Buffers.Buffer_Registry;
      Count      : out Natural;
      Applicable : out Natural);

   function Has_Dirty_Pending_Marked_Close_Prune_Apply
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   function Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   procedure Clear_Stale_Dirty_Pending_Marked_Close_Prune_Apply_Targets
     (State     : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Cleared   : out Natural;
      Remaining : out Natural);

   function Is_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   procedure Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State     : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Id        : Editor.Buffer_Types.Buffer_Id;
      Removed   : out Boolean;
      Remaining : out Natural);

   function Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   function Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Name
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   function Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   procedure Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
     (State        : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry     : Editor.Buffers.Buffer_Registry;
      Restored     : out Boolean;
      Target       : out Editor.Buffer_Types.Buffer_Id;
      Display_Name : out Ada.Strings.Unbounded.Unbounded_String;
      Remaining    : out Natural);

   procedure Confirm_Dirty_Pending_Marked_Close_Prune_Apply
     (State     : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry  : Editor.Buffers.Buffer_Registry;
      Applied   : out Natural;
      Skipped   : out Natural;
      Remaining : out Natural);

   procedure Cancel_Dirty_Pending_Marked_Close_Prune_Apply
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

end Editor.Buffer_Switcher.Dirty_Prune_Operations;
