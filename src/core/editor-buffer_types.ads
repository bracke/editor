with Ada.Strings.Unbounded;

package Editor.Buffer_Types is

   type Buffer_Id is new Natural;
   No_Buffer : constant Buffer_Id := 0;

   type Buffer_Summary is record
      Id           : Buffer_Id := No_Buffer;
      Display_Name : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Is_Dirty     : Boolean := False;
      Is_Active    : Boolean := False;
      Has_Path     : Boolean := False;
      Path         : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Last_Save_Failed   : Boolean := False;
      Last_Reload_Failed : Boolean := False;
      Last_Revert_Failed : Boolean := False;
      Missing_Target_Surfaced    : Boolean := False;
      Unreadable_Target_Surfaced : Boolean := False;
      Unwritable_Target_Surfaced : Boolean := False;
      External_Change_Surfaced   : Boolean := False;
      Blocked_Close_Surfaced     : Boolean := False;
      Is_Pinned               : Boolean := False;
      Has_Group               : Boolean := False;
      Group_Name              : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Label               : Boolean := False;
      Label_Text              : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Note                : Boolean := False;
      Note_Text               : Ada.Strings.Unbounded.Unbounded_String := Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

end Editor.Buffer_Types;
