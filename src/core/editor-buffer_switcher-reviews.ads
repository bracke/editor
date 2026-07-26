package Editor.Buffer_Switcher.Reviews is

   subtype Pending_Marked_Action_Kind is Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
   subtype Switcher_Review_Mode is Editor.Buffer_Switcher.Switcher_Review_Mode;
   subtype Switcher_Batch_State_Snapshot is Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;

   No_Pending_Marked_Action : constant Pending_Marked_Action_Kind := Editor.Buffer_Switcher.No_Pending_Marked_Action;
   Pending_Marked_Close : constant Pending_Marked_Action_Kind := Editor.Buffer_Switcher.Pending_Marked_Close;

   No_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.No_Review;
   Marked_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.Marked_Review;
   Pending_Marked_Close_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.Pending_Marked_Close_Review;
   Pruned_Pending_Close_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.Pruned_Pending_Close_Review;
   Dirty_Pending_Close_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.Dirty_Pending_Close_Review;
   Dirty_Prune_Preview_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.Dirty_Prune_Preview_Review;
   Removed_Dirty_Prune_Preview_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.Removed_Dirty_Prune_Preview_Review;
   Dirty_Prune_Apply_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.Dirty_Prune_Apply_Review;
   Removed_Dirty_Prune_Apply_Review : constant Switcher_Review_Mode := Editor.Buffer_Switcher.Removed_Dirty_Prune_Apply_Review;

end Editor.Buffer_Switcher.Reviews;
