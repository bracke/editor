with Editor.Buffers;
with Editor.Buffer_Types;
with Editor.Buffer_Switcher.Reviews;
package Editor.Buffer_Switcher.Review_Operations is

   procedure Set_Switcher_Review_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Editor.Buffer_Switcher.Reviews.Switcher_Review_Mode);

   procedure Clear_Switcher_Review_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Editor.Buffer_Switcher.Reviews.Switcher_Review_Mode);

   procedure Toggle_Switcher_Review_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Editor.Buffer_Switcher.Reviews.Switcher_Review_Mode);

   function Has_Switcher_Review_Mode
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Editor.Buffer_Switcher.Reviews.Switcher_Review_Mode) return Boolean;

   procedure Clear_Dirty_Prune_Apply_Review_Modes
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Clear_Dirty_Prune_Preview_Review_Modes
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Clear_Pending_Marked_Review_Modes
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Show_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Marked_Review
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Marked_Review_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Show_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Pending_Marked_Review
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Pending_Marked_Review_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Show_Pruned_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Pruned_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Pruned_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Pruned_Pending_Marked_Review
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Pruned_Pending_Marked_Review_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Show_Dirty_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Dirty_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Dirty_Pending_Marked_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Dirty_Pending_Marked_Review
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Dirty_Pending_Marked_Review_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Show_Dirty_Prune_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Dirty_Prune_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Dirty_Prune_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Dirty_Prune_Review
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Dirty_Prune_Review_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Show_Removed_Dirty_Prune_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Removed_Dirty_Prune_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Removed_Dirty_Prune_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Removed_Dirty_Prune_Review
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Removed_Dirty_Prune_Review_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Show_Dirty_Prune_Apply_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Dirty_Prune_Apply_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Dirty_Prune_Apply_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Dirty_Prune_Apply_Review
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Dirty_Prune_Apply_Review_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Show_Removed_Dirty_Prune_Apply_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Hide_Removed_Dirty_Prune_Apply_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   procedure Toggle_Removed_Dirty_Prune_Apply_Review
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Has_Removed_Dirty_Prune_Apply_Review
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   function Removed_Dirty_Prune_Apply_Review_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String;

   procedure Toggle_Mark
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id);

   procedure Set_Mark
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id);

   procedure Clear_Mark
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id);

   procedure Clear_All_Marks
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State);

   function Is_Marked
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id    : Editor.Buffer_Types.Buffer_Id) return Boolean;

   function Marked_Count
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Natural;

   function Open_Marked_Count
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return Natural;

   function Has_Marks
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean;

   procedure Invert_Visible_Marks
     (State          : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Marked_Count   : out Natural;
      Unmarked_Count : out Natural);

   procedure Mark_Visible_Marks
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Count : out Natural);

   procedure Clear_Visible_Marks
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Count : out Natural);

   procedure Prune_Marks
     (State    : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry);

   function Build_Switcher_Batch_State_Snapshot
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry)
      return Editor.Buffer_Switcher.Reviews.Switcher_Batch_State_Snapshot;

   function Header_Badge_Text
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String;

   function Footer_Badge_Text
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String;

   function Count_Badge_Text
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry) return String;

end Editor.Buffer_Switcher.Review_Operations;
