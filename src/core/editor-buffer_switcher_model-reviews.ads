with Ada.Strings.Unbounded;

package Editor.Buffer_Switcher_Model.Reviews is

   type Pending_Marked_Action_Kind is
     (No_Pending_Marked_Action,
      Pending_Marked_Close);

   type Switcher_Review_Mode is
     (No_Review,
      Marked_Review,
      Pending_Marked_Close_Review,
      Pruned_Pending_Close_Review,
      Dirty_Pending_Close_Review,
      Dirty_Prune_Preview_Review,
      Removed_Dirty_Prune_Preview_Review,
      Dirty_Prune_Apply_Review,
      Removed_Dirty_Prune_Apply_Review);

   type Switcher_Batch_State_Snapshot is record
      Active_Review_Mode : Switcher_Review_Mode := No_Review;
      Review_Display_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Review_Empty_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Marked_Count : Natural := 0;
      Pending_Close_Count : Natural := 0;
      Dirty_Pending_Close_Count : Natural := 0;
      Pruned_Pending_Close_Count : Natural := 0;
      Dirty_Prune_Preview_Count : Natural := 0;
      Applicable_Dirty_Prune_Preview_Count : Natural := 0;
      Removed_Dirty_Prune_Preview_Count : Natural := 0;
      Open_Removed_Dirty_Prune_Preview_Count : Natural := 0;
      Stale_Dirty_Prune_Preview_Count : Natural := 0;
      Dirty_Prune_Apply_Count : Natural := 0;
      Applicable_Dirty_Prune_Apply_Count : Natural := 0;
      Removed_Dirty_Prune_Apply_Count : Natural := 0;
      Open_Removed_Dirty_Prune_Apply_Count : Natural := 0;
      Stale_Dirty_Prune_Apply_Count : Natural := 0;
      Has_Pending_Marked_Close : Boolean := False;
      Has_Dirty_Prune_Preview : Boolean := False;
      Has_Dirty_Prune_Apply_Confirmation : Boolean := False;
      Header_Badge_Text : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Footer_Badge_Text : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

end Editor.Buffer_Switcher_Model.Reviews;
