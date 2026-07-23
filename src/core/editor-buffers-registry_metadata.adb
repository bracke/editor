with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers.Path_And_Labeling;
with Editor.Buffers.Registry_Tagging;
with Editor.Project;
with Editor.State;

package body Editor.Buffers.Registry_Metadata is

   function Index_Of
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Natural
   is
   begin
      if Registry.Items.Is_Empty then
         return Natural'Last;
      end if;

      for I in Registry.Items.First_Index .. Registry.Items.Last_Index loop
         if Registry.Items (I).Id = Id then
            return I;
         end if;
      end loop;

      return Natural'Last;
   end Index_Of;

   function Bounded_Metadata_Label (Value : String) return String
      renames Editor.Buffers.Path_And_Labeling.Bounded_Metadata_Label;

   function Pure_Normalize_Path (Path : String) return String
     renames Editor.Buffers.Path_And_Labeling.Pure_Normalize_Path;

   function Pure_Relative_Path
     (Path : String;
      Root : String) return String
     renames Editor.Buffers.Path_And_Labeling.Pure_Relative_Path;

   function Lifecycle_Status_Label_For
     (File : File_Identity) return String
     renames Editor.Buffers.Path_And_Labeling.Lifecycle_Status_Label_For;

   function Parent_Name_Of (Path : String) return String is
      Last_Slash : Natural := 0;
      Prev_Slash : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = Character'Val (16#5C#) then
            Prev_Slash := Last_Slash;
            Last_Slash := I;
         end if;
      end loop;

      if Last_Slash = 0 then
         return "";
      elsif Prev_Slash = 0 then
         if Last_Slash = Path'First then
            return "/";
         else
            return Path (Path'First .. Last_Slash - 1);
         end if;
      elsif Prev_Slash + 1 <= Last_Slash - 1 then
         return Path (Prev_Slash + 1 .. Last_Slash - 1);
      else
         return "/";
      end if;
   end Parent_Name_Of;

   function Duplicate_Display_Name
     (Registry : Buffer_Registry;
      Name     : String) return Boolean
   is
      Seen : Natural := 0;
   begin
      for Item of Registry.Items loop
         if Item.State /= null
           and then To_String (Item.State.File_Info.Display_Name) = Name
         then
            Seen := Seen + 1;
            if Seen > 1 then
               return True;
            end if;
         end if;
      end loop;

      return False;
   end Duplicate_Display_Name;

   function Display_Name
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
      File : constant File_Identity := Buffer_File_Info (Registry, Id);
   begin
      if I = Natural'Last then
         return "<invalid buffer>";
      end if;

      return To_String (File.Display_Name);
   end Display_Name;

   function Display_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
      File : constant File_Identity := Buffer_File_Info (Registry, Id);
   begin
      if I = Natural'Last then
         return "<invalid buffer>";
      end if;

      declare
         Name : constant String := To_String (File.Display_Name);
      begin
        if not Duplicate_Display_Name (Registry, Name) then
           return Name;
         elsif File.Has_Path then
            declare
               Path   : constant String := To_String (File.Path);
               Parent : constant String := Parent_Name_Of (Path);
            begin
               if Parent'Length > 0 then
                  return Name & " — " & Parent;
               else
                  return Name & " — " & Path;
               end if;
            end;
         else
            return Name & " — buffer " & Buffer_Id'Image (Id);
         end if;
      end;
   end Display_Label;

   function Lifecycle_Display_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
   is
      I : constant Natural := Index_Of (Registry, Id);
      Base : constant String := Display_Label (Registry, Id);
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return Base;
      end if;

      declare
         File : constant File_Identity := Registry.Items (I).State.File_Info;
         Decorated : Unbounded_String := To_Unbounded_String (Base);
      begin
         if Registry.Items (I).Has_Label then
            Append (Decorated, " [label: " & To_String (Registry.Items (I).Label) & "]");
         end if;
         if Registry.Items (I).Pinned then
            Append (Decorated, " [Pinned]");
         end if;
         if Registry.Items (I).Has_Group then
            Append (Decorated, " [group: " & To_String (Registry.Items (I).Group) & "]");
         end if;
         if Registry.Items (I).Has_Note then
            Append (Decorated, " — " & To_String (Registry.Items (I).Note));
         end if;

         if File.Missing_Target_Surfaced then
            return To_String (Decorated) & " — missing target";
         elsif File.External_Change_Surfaced and then File.Dirty then
            return To_String (Decorated) & " — conflict pending";
         elsif File.External_Change_Surfaced then
            return To_String (Decorated) & " — external change";
         elsif File.Unreadable_Target_Surfaced
           or else File.Last_Reload_Failed
           or else File.Last_Revert_Failed
         then
            return To_String (Decorated) & " — unreadable target";
         elsif File.Unwritable_Target_Surfaced then
            return To_String (Decorated) & " — unwritable target";
         elsif File.Dirty and then File.Last_Save_Failed and then File.Has_Path then
            return To_String (Decorated) & " — retry save";
         elsif File.Blocked_Close_Surfaced then
            return To_String (Decorated) & " — close blocked";
         elsif not File.Has_Path then
            return To_String (Decorated) & " — untitled";
         else
            return To_String (Decorated);
         end if;
      end;
   end Lifecycle_Display_Label;

   function Summary_For
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Buffer_Summary
   is
      I : constant Natural := Index_Of (Registry, Id);
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return (Id           => No_Buffer,
                 Display_Name => Null_Unbounded_String,
                 Is_Dirty     => False,
                 Is_Active    => False,
                 Has_Path     => False,
                 Path         => Null_Unbounded_String,
                 Last_Save_Failed => False,
                 Last_Reload_Failed => False,
                 Last_Revert_Failed => False,
                 Missing_Target_Surfaced => False,
                 Unreadable_Target_Surfaced => False,
                 Unwritable_Target_Surfaced => False,
                 External_Change_Surfaced => False,
                 Blocked_Close_Surfaced  => False,
                 Is_Pinned               => False,
                 Has_Group               => False,
                 Group_Name              => Null_Unbounded_String,
                 Has_Label               => False,
                 Label_Text              => Null_Unbounded_String,
                 Has_Note                => False,
                 Note_Text               => Null_Unbounded_String);
      end if;

      return (Id           => Registry.Items (I).Id,
              Display_Name => To_Unbounded_String
                (Lifecycle_Display_Label (Registry, Registry.Items (I).Id)),
              Is_Dirty     => Registry.Items (I).State.File_Info.Dirty,
              Is_Active    => Registry.Items (I).Id = Registry.Active,
              Has_Path     => Registry.Items (I).State.File_Info.Has_Path,
              Path         => Registry.Items (I).State.File_Info.Path,
              Last_Save_Failed => Registry.Items (I).State.File_Info.Last_Save_Failed,
              Last_Reload_Failed => Registry.Items (I).State.File_Info.Last_Reload_Failed,
              Last_Revert_Failed => Registry.Items (I).State.File_Info.Last_Revert_Failed,
              Missing_Target_Surfaced => Registry.Items (I).State.File_Info.Missing_Target_Surfaced,
              Unreadable_Target_Surfaced => Registry.Items (I).State.File_Info.Unreadable_Target_Surfaced,
              Unwritable_Target_Surfaced => Registry.Items (I).State.File_Info.Unwritable_Target_Surfaced,
              External_Change_Surfaced => Registry.Items (I).State.File_Info.External_Change_Surfaced,
              Blocked_Close_Surfaced  => Registry.Items (I).State.File_Info.Blocked_Close_Surfaced,
              Is_Pinned               => Registry.Items (I).Pinned,
              Has_Group               => Registry.Items (I).Has_Group,
              Group_Name              => Registry.Items (I).Group,
              Has_Label               => Registry.Items (I).Has_Label,
              Label_Text              => Registry.Items (I).Label,
              Has_Note                => Registry.Items (I).Has_Note,
              Note_Text               => Registry.Items (I).Note);
   end Summary_For;

   function Summary_At
     (Registry : Buffer_Registry;
      Index    : Positive) return Buffer_Summary
   is
      Zero_Index : constant Natural := Index - 1;
   begin
      if Registry.Items.Is_Empty
        or else Zero_Index < Registry.Items.First_Index
        or else Zero_Index > Registry.Items.Last_Index
        or else Registry.Items (Zero_Index).State = null
      then
         return (Id           => No_Buffer,
                 Display_Name => Null_Unbounded_String,
                 Is_Dirty     => False,
                 Is_Active    => False,
                 Has_Path     => False,
                 Path         => Null_Unbounded_String,
                 Last_Save_Failed => False,
                 Last_Reload_Failed => False,
                 Last_Revert_Failed => False,
                 Missing_Target_Surfaced => False,
                 Unreadable_Target_Surfaced => False,
                 Unwritable_Target_Surfaced => False,
                 External_Change_Surfaced => False,
                 Blocked_Close_Surfaced  => False,
                 Is_Pinned               => False,
                 Has_Group               => False,
                 Group_Name              => Null_Unbounded_String,
                 Has_Label               => False,
                 Label_Text              => Null_Unbounded_String,
                 Has_Note                => False,
                 Note_Text               => Null_Unbounded_String);
      end if;

      return Summary_For (Registry, Registry.Items (Zero_Index).Id);
   end Summary_At;

   function Metadata_For
     (Registry   : Buffer_Registry;
      Project    : Editor.Project.Project_State;
      Id         : Buffer_Id;
      Selected_Id : Buffer_Id := No_Buffer) return Buffer_Metadata_Snapshot
   is
      I : constant Natural := Index_Of (Registry, Id);
      Result : Buffer_Metadata_Snapshot;
   begin
      if I = Natural'Last or else Registry.Items (I).State = null then
         return Result;
      end if;

      declare
         File        : constant File_Identity := Registry.Items (I).State.File_Info;
         Has_Project : constant Boolean := Editor.Project.Has_Project (Project);
         Root        : constant String :=
           (if Has_Project then Editor.Project.Root_Path (Project) else "");
         Path        : constant String := To_String (File.Path);
         Ownership   : constant Buffer_Ownership_Kind :=
           Classify_Buffer_Ownership (File.Has_Path, Path, Project);
         In_Project  : constant Boolean := Ownership = Buffer_Project_Owned;
      begin
         Result.Id := Registry.Items (I).Id;
         Result.Display_Label := To_Unbounded_String
           (Bounded_Metadata_Label (Lifecycle_Display_Label (Registry, Id)));
         Result.Has_File_Path := File.Has_Path;
         if File.Has_Path then
            Result.File_Path := To_Unbounded_String
              (Bounded_Metadata_Label (Pure_Normalize_Path (Path)));
         else
            Result.File_Path := Null_Unbounded_String;
            Result.Has_Scratch_Label := True;
            Result.Scratch_Label := To_Unbounded_String ("No backing file");
         end if;
         Result.Has_Project_Relative_Path := In_Project;
         if In_Project then
            Result.Project_Relative_Path := To_Unbounded_String
              (Bounded_Metadata_Label (Pure_Relative_Path (Path, Root)));
         elsif File.Has_Path and then Has_Project and then Path'Length > 0 then
            Result.Has_Outside_Project_Path_Label := True;
            Result.Outside_Project_Path_Label := To_Unbounded_String
              (Bounded_Metadata_Label (Pure_Normalize_Path (Path)));
         end if;
         Result.Is_Active := Registry.Items (I).Id = Registry.Active;
         Result.Is_Selected := Registry.Items (I).Id = Selected_Id;
         Result.Is_Dirty := File.Dirty;
         Result.Is_Clean := not File.Dirty;
         Result.Is_Scratch := not File.Has_Path;
         Result.Missing_Backing_File := File.Missing_Target_Surfaced;
         Result.External_Conflict := File.External_Change_Surfaced;
         Result.Stale_Backing_State := File.External_Change_Surfaced
           or else File.Missing_Target_Surfaced;
         Result.Unreadable := File.Unreadable_Target_Surfaced
           or else File.Last_Reload_Failed
           or else File.Last_Revert_Failed;
         Result.Unwritable := File.Unwritable_Target_Surfaced or else File.Last_Save_Failed;

         Result.Ownership := Ownership;
         Result.Ownership_Label := To_Unbounded_String (Ownership_Label (Result.Ownership));
         Result.Lifecycle_Status_Label := To_Unbounded_String (Lifecycle_Status_Label_For (File));

         if not File.Dirty then
            Result.Dirty_Category := Buffer_Not_Dirty;
         elsif File.Missing_Target_Surfaced then
            Result.Dirty_Category := Buffer_Dirty_Missing_File;
         elsif File.External_Change_Surfaced then
            Result.Dirty_Category := Buffer_Dirty_Conflicted_File;
         elsif File.Unwritable_Target_Surfaced or else File.Last_Save_Failed then
            Result.Dirty_Category := Buffer_Dirty_Unwritable_File;
         elsif not File.Has_Path then
            Result.Dirty_Category := Buffer_Dirty_Scratch;
         elsif Result.Ownership = Buffer_Project_Owned then
            Result.Dirty_Category := Buffer_Dirty_Project_File;
         else
            Result.Dirty_Category := Buffer_Dirty_Outside_Project_File;
         end if;

         if File.Blocked_Close_Surfaced then
            Result.Close_Eligibility := Buffer_Blocked_By_Pending_Confirmation;
         elsif not File.Dirty then
            Result.Close_Eligibility := Buffer_Closable_Clean;
         elsif File.Missing_Target_Surfaced or else File.External_Change_Surfaced then
            Result.Close_Eligibility := Buffer_Requires_Conflict_Resolution_Or_Discard;
         elsif (not File.Has_Path)
           or else File.Unwritable_Target_Surfaced
           or else File.Last_Save_Failed
           or else File.Unreadable_Target_Surfaced
           or else File.Last_Reload_Failed
           or else File.Last_Revert_Failed
         then
            Result.Close_Eligibility := Buffer_Requires_Save_As_Or_Discard;
         else
            Result.Close_Eligibility := Buffer_Requires_Dirty_Confirmation;
         end if;

         if File.Has_Path and then Path'Length > 0 and then not File.Missing_Target_Surfaced then
            Result.Workspace_Persistability := Buffer_Persistable_File_Reference;
         elsif not File.Has_Path then
            Result.Workspace_Persistability := Buffer_Not_Persistable_Scratch;
         else
            Result.Workspace_Persistability := Buffer_Not_Persistable_Invalid_Path;
         end if;
      end;

      return Result;
   end Metadata_For;

   function Is_Dirty
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      File : constant File_Identity := Buffer_File_Info (Registry, Id);
   begin
      return File.Dirty;
   end Is_Dirty;

   function Is_File_Backed
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
   is
      File : constant File_Identity := Buffer_File_Info (Registry, Id);
   begin
      return File.Has_Path;
   end Is_File_Backed;

   function Is_Buffer_Pinned
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
      renames Editor.Buffers.Registry_Tagging.Is_Buffer_Pinned;

   function Has_Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
      renames Editor.Buffers.Registry_Tagging.Has_Buffer_Label;

   function Buffer_Label
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
      renames Editor.Buffers.Registry_Tagging.Buffer_Label;

   procedure Set_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Label    : String)
      renames Editor.Buffers.Registry_Tagging.Set_Buffer_Label;

   procedure Clear_Buffer_Label
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
      renames Editor.Buffers.Registry_Tagging.Clear_Buffer_Label;

   function Has_Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
      renames Editor.Buffers.Registry_Tagging.Has_Buffer_Note;

   function Buffer_Note
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
      renames Editor.Buffers.Registry_Tagging.Buffer_Note;

   procedure Set_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Note     : String)
      renames Editor.Buffers.Registry_Tagging.Set_Buffer_Note;

   procedure Clear_Buffer_Note
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
      renames Editor.Buffers.Registry_Tagging.Clear_Buffer_Note;

   function Has_Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return Boolean
      renames Editor.Buffers.Registry_Tagging.Has_Buffer_Group;

   function Buffer_Group
     (Registry : Buffer_Registry;
      Id       : Buffer_Id) return String
      renames Editor.Buffers.Registry_Tagging.Buffer_Group;

   procedure Assign_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id;
      Name     : String)
      renames Editor.Buffers.Registry_Tagging.Assign_Buffer_Group;

   procedure Clear_Buffer_Group
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
      renames Editor.Buffers.Registry_Tagging.Clear_Buffer_Group;

   function Has_Buffer_Groups
     (Registry : Buffer_Registry) return Boolean
      renames Editor.Buffers.Registry_Tagging.Has_Buffer_Groups;

   function Has_Active_Buffer_Group
     (Registry : Buffer_Registry) return Boolean
      renames Editor.Buffers.Registry_Tagging.Has_Active_Buffer_Group;

   function Active_Buffer_Group
     (Registry : Buffer_Registry) return String
      renames Editor.Buffers.Registry_Tagging.Active_Buffer_Group;

   function First_Buffer_In_Group
     (Registry : Buffer_Registry;
      Name     : String) return Buffer_Id
      renames Editor.Buffers.Registry_Tagging.First_Buffer_In_Group;

   procedure Set_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Name     : String)
      renames Editor.Buffers.Registry_Tagging.Set_Active_Buffer_Group;

   procedure Clear_Active_Buffer_Group
     (Registry : in out Buffer_Registry)
      renames Editor.Buffers.Registry_Tagging.Clear_Active_Buffer_Group;

   procedure Cycle_Active_Buffer_Group
     (Registry : in out Buffer_Registry;
      Forward  : Boolean)
      renames Editor.Buffers.Registry_Tagging.Cycle_Active_Buffer_Group;

   procedure Pin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
      renames Editor.Buffers.Registry_Tagging.Pin_Buffer;

   procedure Unpin_Buffer
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
      renames Editor.Buffers.Registry_Tagging.Unpin_Buffer;

   procedure Toggle_Buffer_Pin
     (Registry : in out Buffer_Registry;
      Id       : Buffer_Id)
      renames Editor.Buffers.Registry_Tagging.Toggle_Buffer_Pin;

end Editor.Buffers.Registry_Metadata;
