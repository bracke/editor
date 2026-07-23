package Editor.Buffer_Switcher.Review_Operations is

   procedure Set_Switcher_Review_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Editor.Buffer_Switcher.Switcher_Review_Mode);

   procedure Clear_Switcher_Review_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Editor.Buffer_Switcher.Switcher_Review_Mode);

   procedure Toggle_Switcher_Review_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Editor.Buffer_Switcher.Switcher_Review_Mode);

   function Has_Switcher_Review_Mode
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Editor.Buffer_Switcher.Switcher_Review_Mode) return Boolean;

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

end Editor.Buffer_Switcher.Review_Operations;
