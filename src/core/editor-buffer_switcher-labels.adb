with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;

package body Editor.Buffer_Switcher.Labels is
   use type Editor.Buffer_Switcher.Buffer_Project_Ownership_Kind;


   use type Editor.Buffers.Buffer_Ownership_Kind;

   function Path_Base_Name (Path : String) return String is
      Last_Sep : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = '\' then
            Last_Sep := I;
         end if;
      end loop;

      if Last_Sep = 0 then
         return Path;
      elsif Last_Sep >= Path'Last then
         return Path;
      else
         return Path (Last_Sep + 1 .. Path'Last);
      end if;
   end Path_Base_Name;

   function Parent_Hint (Path : String) return String is
      Last_Sep : Natural := 0;
      Prev_Sep : Natural := 0;
   begin
      for I in Path'Range loop
         if Path (I) = '/' or else Path (I) = '\' then
            Prev_Sep := Last_Sep;
            Last_Sep := I;
         end if;
      end loop;

      if Last_Sep = 0 then
         return "";
      elsif Prev_Sep = 0 then
         if Last_Sep > Path'First then
            return Path (Path'First .. Last_Sep - 1);
         else
            return "";
         end if;
      elsif Prev_Sep + 1 <= Last_Sep - 1 then
         return Path (Prev_Sep + 1 .. Last_Sep - 1);
      else
         return "";
      end if;
   end Parent_Hint;

   function Short_Path_Label (Path : String) return String is
      Base   : constant String := Path_Base_Name (Path);
      Parent : constant String := Parent_Hint (Path);
   begin
      if Parent'Length = 0 then
         return Base;
      else
         return Parent & "/" & Base;
      end if;
   end Short_Path_Label;

   procedure Apply_Buffer_List_Display_Label
     (Row     : in out Buffer_Switcher_Row;
      Project : Editor.Project.Project_State)
   is
      Path_Text : constant String := To_String (Row.Path);
   begin
      if not Row.Has_Path then
         null;
      elsif Row.Project_Ownership = Buffer_Project_Owned then
         Row.Display_Label := To_Unbounded_String
           (Editor.Project.Relative_Path (Project, Path_Text));
      else
         Row.Display_Label := To_Unbounded_String (Short_Path_Label (Path_Text));
      end if;
   end Apply_Buffer_List_Display_Label;

   function Metadata_Display_Label
     (Metadata : Editor.Buffers.Buffer_Metadata_Snapshot) return Unbounded_String
   is
   begin
      if Metadata.Has_Project_Relative_Path then
         return Metadata.Project_Relative_Path;
      elsif Metadata.Has_Outside_Project_Path_Label then
         return To_Unbounded_String
           (Short_Path_Label (To_String (Metadata.Outside_Project_Path_Label)));
      elsif Metadata.Has_File_Path then
         if Metadata.Ownership = Editor.Buffers.Buffer_Missing_Project_Context then
            return To_Unbounded_String (Path_Base_Name (To_String (Metadata.File_Path)));
         else
            return To_Unbounded_String
              (Short_Path_Label (To_String (Metadata.File_Path)));
         end if;
      elsif Metadata.Has_Scratch_Label then
         return To_Unbounded_String ("Untitled");
      else
         return Metadata.Display_Label;
      end if;
   end Metadata_Display_Label;

   function Buffer_Row_State_Markers
     (Row : Buffer_Switcher_Row) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Length (Result) /= 0 then
            Append (Result, " ");
         end if;
         Append (Result, Text);
      end Add;
   begin
      if Row.Is_Active then
         Add ("active");
      end if;
      if Row.Is_Dirty then
         Add ("dirty");
      end if;
      if Row.Is_File_Backed then
         Add ("file");
      elsif Row.Is_Unbacked then
         Add ("scratch");
      end if;
      if Row.Is_Project_Owned then
         Add ("project");
      elsif Row.Is_Outside_Project then
         Add ("outside-project");
      elsif Row.Project_Ownership = Buffer_Project_No_Project then
         Add ("no-project");
      end if;
      if Row.Missing_Target_Surfaced then
         Add ("missing");
      end if;
      if Row.Unreadable_Target_Surfaced
        or else Row.Last_Reload_Failed
        or else Row.Last_Revert_Failed
      then
         Add ("unreadable");
      end if;
      if Row.Unwritable_Target_Surfaced or else Row.Last_Save_Failed then
         Add ("unwritable");
      end if;
      if Row.External_Change_Surfaced then
         if Row.Is_Outside_Project then
            Add ("conflict");
         end if;
         Add ("external-change");
      end if;
      if Row.Blocked_Close_Surfaced then
         Add ("guarded");
      end if;
      return To_String (Result);
   end Buffer_Row_State_Markers;

   function Buffer_Row_Metadata_Render_Label
     (Row : Buffer_Switcher_Row) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Text'Length = 0 then
            return;
         end if;
         if Length (Result) /= 0 then
            Append (Result, "; ");
         end if;
         Append (Result, Text);
      end Add;
   begin
      Add (To_String (Row.Project_Ownership_Label));
      Add (To_String (Row.Lifecycle_Status_Label));
      Add (To_String (Row.Workspace_Persistability_Label));
      Add (To_String (Row.Close_Eligibility_Label));
      if Row.Stale_Backing_State then
         Add ("Stale backing state");
      end if;
      return To_String (Result);
   end Buffer_Row_Metadata_Render_Label;

   function Buffer_Project_Ownership_Label
     (Kind : Buffer_Project_Ownership_Kind) return String
   is
   begin
      case Kind is
         when Buffer_Project_Unknown =>
            return "project unknown";
         when Buffer_Project_Owned =>
            return "project";
         when Buffer_Project_Outside =>
            return "outside project";
         when Buffer_Project_Scratch =>
            return "scratch";
         when Buffer_Project_No_Project =>
            return "no project";
      end case;
   end Buffer_Project_Ownership_Label;

   procedure Apply_Project_Ownership
     (Row     : in out Buffer_Switcher_Row;
      Project : Editor.Project.Project_State)
   is
      Canonical : constant Editor.Buffers.Buffer_Ownership_Kind :=
        Editor.Buffers.Classify_Buffer_Ownership
          (Has_Path => Row.Has_Path,
           Path     => To_String (Row.Path),
           Project  => Project);
   begin
      case Canonical is
         when Editor.Buffers.Buffer_Project_Owned =>
            Row.Project_Ownership := Buffer_Project_Owned;
         when Editor.Buffers.Buffer_Outside_Project =>
            Row.Project_Ownership := Buffer_Project_Outside;
         when Editor.Buffers.Buffer_Scratch_Unbacked =>
            Row.Project_Ownership := Buffer_Project_Scratch;
         when Editor.Buffers.Buffer_Missing_Project_Context =>
            Row.Project_Ownership := Buffer_Project_No_Project;
         when Editor.Buffers.Buffer_Unknown_File_Backed =>
            Row.Project_Ownership := Buffer_Project_Unknown;
      end case;
      Row.Is_Project_Owned := Canonical = Editor.Buffers.Buffer_Project_Owned;
      Row.Is_Outside_Project := Canonical = Editor.Buffers.Buffer_Outside_Project;
      Row.Is_File_Backed := Row.Has_Path;
      Row.Is_Unbacked := Canonical = Editor.Buffers.Buffer_Scratch_Unbacked;
      Row.Project_Ownership_Label :=
        To_Unbounded_String (Buffer_Project_Ownership_Label (Row.Project_Ownership));
   end Apply_Project_Ownership;

end Editor.Buffer_Switcher.Labels;
