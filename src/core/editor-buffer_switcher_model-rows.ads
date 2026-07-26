with Ada.Strings.Unbounded;
with Editor.Buffer_Types;

package Editor.Buffer_Switcher_Model.Rows is

   type Buffer_Project_Ownership_Kind is
     (Buffer_Project_Unknown,
      Buffer_Project_Owned,
      Buffer_Project_Outside,
      Buffer_Project_Scratch,
      Buffer_Project_No_Project);

   type Buffer_Switcher_Row is record
      Id           : Editor.Buffer_Types.Buffer_Id := Editor.Buffer_Types.No_Buffer;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String;
      Is_Dirty     : Boolean := False;
      Is_Active    : Boolean := False;
      Has_Path     : Boolean := False;
      Path          : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Project_Ownership : Buffer_Project_Ownership_Kind := Buffer_Project_Unknown;
      Project_Ownership_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Lifecycle_Status_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Workspace_Persistability_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Close_Eligibility_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stale_Backing_State : Boolean := False;
      Is_Project_Owned  : Boolean := False;
      Is_Outside_Project : Boolean := False;
      Is_File_Backed : Boolean := False;
      Is_Unbacked    : Boolean := False;
      Last_Save_Failed   : Boolean := False;
      Last_Reload_Failed : Boolean := False;
      Last_Revert_Failed : Boolean := False;
      Missing_Target_Surfaced    : Boolean := False;
      Unreadable_Target_Surfaced : Boolean := False;
      Unwritable_Target_Surfaced : Boolean := False;
      External_Change_Surfaced   : Boolean := False;
      Blocked_Close_Surfaced     : Boolean := False;
      Is_Pinned    : Boolean := False;
      Has_Group    : Boolean := False;
      Group_Name   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Label    : Boolean := False;
      Label_Text   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Note     : Boolean := False;
      Is_Marked    : Boolean := False;
      Is_Pending_Close_Target : Boolean := False;
      Is_Ordinary_Pruned_Target : Boolean := False;
      Is_Dirty_Prune_Preview_Target : Boolean := False;
      Is_Removed_Dirty_Prune_Preview_Target : Boolean := False;
      Is_Dirty_Prune_Apply_Target : Boolean := False;
      Is_Removed_Dirty_Prune_Apply_Target : Boolean := False;
   end record;

end Editor.Buffer_Switcher_Model.Rows;
