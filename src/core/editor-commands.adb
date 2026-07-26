with Editor.Command_Kinds;
with Editor.Commands.Registry;
with Editor.Commands.Audit_Model; use Editor.Commands.Audit_Model;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Classification; use Editor.Commands.Classification;
with Editor.Commands.Editing_Ids;
with Editor.Commands.Navigation_Ids;
with Editor.Commands.Build_Terminal_Ids;
with Editor.Commands.Project_File_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Commands.Descriptor_Metadata;
with Editor.Commands.Audits;
with Editor.Commands.Reference_Metadata;
with Editor.Commands.Name_Metadata;
with Editor.Commands.Workflow_Messages;


package body Editor.Commands is

   function Is_Concrete_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Availability_Metadata.Is_Concrete_Command;

   function Requires_Context
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Availability_Metadata.Requires_Context;

   function Has_Availability_Handler
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Availability_Metadata.Has_Availability_Handler;

   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor
   is
   begin
      return Descriptor_Metadata.Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Name,
         Label         => Label,
         Description   => Description,
         Category      => Category,
         Visible       => Visible,
         Bindable      => Bindable,
         Destructive   => Destructive,
         Lifecycle     => Lifecycle,
         Configuration => Configuration);
   end Make_Command_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      return Descriptor_Metadata.Descriptor (Id);
   end Descriptor;

   function Label
     (Id : Command_Id) return String
   is
   begin
      return To_String (Descriptor (Id).Name);
   end Label;

   function Category
     (Id : Command_Id) return Command_Category
   is
   begin
      return Descriptor (Id).Category;
   end Category;

   function Category_Label
     (Category : Command_Category) return String
   is
   begin
      case Category is
         when File_Category =>
            return "File";
         when Project_Category =>
            return "Project";
         when Edit_Category =>
            return "Edit";
         when Selection_Category =>
            return "Selection";
         when Navigation_Category =>
            return "Navigation";
         when Search_Category =>
            return "Search";
         when Panel_Category =>
            return "Panels";
         when View_Category =>
            return "View";
         when Diagnostics_Category =>
            return "Diagnostics";
         when Bookmarks_Category =>
            return "Bookmarks";
         when Overlay_Category =>
            return "Overlays";
         when Message_Category =>
            return "Messages";
         when Theme_Category =>
            return "Theme";
         when Settings_Category =>
            return "Settings";
         when Workspace_Category =>
            return "Workspace";
         when Internal_Category =>
            return "Internal";
      end case;
   end Category_Label;

   function Discoverability_Category_Label
     (Id : Command_Id) return String
   is
      Stable : constant String := Name_Metadata.Stable_Command_Name (Id);
   begin
      if Ada.Strings.Fixed.Index (Stable, "build.") = Stable'First then
         return "Build";
      elsif Ada.Strings.Fixed.Index (Stable, "recent-projects.") = Stable'First then
         return "Recent Projects";
      elsif Ada.Strings.Fixed.Index (Stable, "file-tree.") = Stable'First then
         return "File Tree";
      elsif Ada.Strings.Fixed.Index (Stable, "outline.") = Stable'First then
         return "Outline";
      elsif Ada.Strings.Fixed.Index (Stable, "semantic.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "language.index.") = Stable'First
      then
         return "Language";
      elsif Ada.Strings.Fixed.Index (Stable, "buffer-switcher.") = Stable'First
        or else Stable = "switch-buffer"
      then
         return "Buffers";
      elsif Ada.Strings.Fixed.Index (Stable, "keybindings.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "keybinding.") = Stable'First
      then
         return "Keybindings";
      elsif Ada.Strings.Fixed.Index (Stable, "command-palette.") = Stable'First
        or else Stable = "open-command-palette"
      then
         return "Command Palette";
      else
         return Category_Label (Descriptor (Id).Category);
      end if;
   end Discoverability_Category_Label;

   function Classification_Label
     (Id : Command_Id) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Length (Result) > 0 then
            Result := Result & ", ";
         end if;
         Result := Result & Text;
      end Add;
   begin
      if Is_Destructive_Command (Id) then
         Add ("destructive");
      end if;
      if Is_Lifecycle_Command (Id) then
         Add ("lifecycle");
      end if;
      if Is_Configuration_Command (Id) then
         Add ("configuration");
      end if;
      if Editor.Commands.Navigation_Ids.Is_Navigation_Command (Id) then
         Add ("navigation");
      end if;
      if Is_Search_Command (Id) then
         Add ("search");
      end if;
      if Is_Panel_Focus_Command (Id) then
         Add ("panel");
      end if;
      if Editor.Commands.Editing_Ids.Is_Editing_Command (Id) then
         Add ("editing");
      end if;
      if Descriptor (Id).Visibility = Hidden_Command
        or else Descriptor (Id).Category = Internal_Category
      then
         Add ("internal");
      end if;
      if not Is_Bindable_Command (Id) then
         Add ("non-bindable");
      end if;
      if Length (Result) = 0 then
         Add ("command");
      end if;
      return To_String (Result);
   end Classification_Label;

   function Surface_Relevance_Label
     (Id : Command_Id) return String
   is
      Stable : constant String := Name_Metadata.Stable_Command_Name (Id);
   begin
      if Stable'Length = 0 then
         return "";
      elsif Ada.Strings.Fixed.Index (Stable, "file-tree.") = Stable'First then
         return "File Tree";
      elsif Ada.Strings.Fixed.Index (Stable, "diagnostics.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "problems.") = Stable'First
      then
         return "Diagnostics";
      elsif Ada.Strings.Fixed.Index (Stable, "build.") = Stable'First then
         return "Build";
      elsif Ada.Strings.Fixed.Index (Stable, "project-search.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "search-results.") = Stable'First
      then
         return "Project Search";
      elsif Ada.Strings.Fixed.Index (Stable, "outline.") = Stable'First then
         return "Outline";
      elsif Ada.Strings.Fixed.Index (Stable, "semantic.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "language.index.") = Stable'First
      then
         return "Language";
      elsif Ada.Strings.Fixed.Index (Stable, "quick-open.") = Stable'First then
         return "Quick Open";
      elsif Ada.Strings.Fixed.Index (Stable, "recent-projects.") = Stable'First then
         return "Recent Projects";
      elsif Ada.Strings.Fixed.Index (Stable, "buffer-switcher.") = Stable'First
        or else Stable = "switch-buffer"
      then
         return "Buffers";
      elsif Ada.Strings.Fixed.Index (Stable, "command-palette.") = Stable'First
        or else Stable = "open-command-palette"
      then
         return "Command Palette";
      elsif Ada.Strings.Fixed.Index (Stable, "keybindings.") = Stable'First
        or else Stable = "keybinding.validate"
      then
         return "Keybindings";
      else
         return "";
      end if;
   end Surface_Relevance_Label;

   function Guard_Label
     (Id : Command_Id) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Length (Result) > 0 then
            Result := Result & ", ";
         end if;
         Result := Result & Text;
      end Add;
   begin
      if Is_Destructive_Command (Id) then
         Add ("confirmation and dirty-file protection retained");
      end if;
      if Is_Lifecycle_Command (Id) then
         Add ("project/file safety protection retained");
      end if;
      if Is_Configuration_Command (Id) then
         Add ("configuration safety check retained");
      end if;
      if not Is_Bindable_Command (Id) then
         Add ("not keybindable");
      end if;
      if Length (Result) = 0 then
         Add ("no special safety check");
      end if;
      return To_String (Result);
   end Guard_Label;

   function Has_Discoverability_Metadata
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Audits.Has_Discoverability_Metadata;

   function Command_Discoverability_Coherent return Boolean
     renames Editor.Commands.Audits.Command_Discoverability_Coherent;

   function First_Command return Command_Id
   is
   begin
      return Command_Id'First;
   end First_Command;

   function Last_Command return Command_Id
   is
   begin
      return Command_Id'Last;
   end Last_Command;

   function Next_Command
     (Id    : Command_Id;
      Found : out Boolean) return Command_Id
   is
   begin
      if Id = Command_Id'Last then
         Found := False;
         return No_Command;
      end if;

      Found := True;
      return Command_Id'Succ (Id);
   end Next_Command;

   function First_Concrete_Command return Command_Id
   is
   begin
      return Command_Id'Succ (No_Command);
   end First_Concrete_Command;

   function Concrete_Command_Count return Natural
   is
   begin
      return Command_Count - 1;
   end Concrete_Command_Count;

   procedure For_Each_Command
     (Process : not null access procedure (Id : Command_Id))
   is
   begin
      for Id in Command_Id loop
         if Is_Concrete_Command (Id) then
            Process (Id);
         end if;
      end loop;
   end For_Each_Command;

   function Is_Valid_Command
     (Id : Command_Id) return Boolean
   is
      pragma Unreferenced (Id);
   begin
      return True;
   end Is_Valid_Command;

   function Trimmed
     (Text : String) return String
   is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Is_Placeholder_Label
     (Text : String) return Boolean
   is
      T : constant String := Trimmed (Text);
   begin
      return T = "TODO"
        or else T = "Command"
        or else T = "Unnamed";
   end Is_Placeholder_Label;

   function Has_Stable_User_Label
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      L : constant String := To_String (D.Name);
   begin
      return Id /= No_Command
        and then D.Id = Id
        and then L'Length > 0
        and then Trimmed (L) = L
        and then not Is_Placeholder_Label (L);
   end Has_Stable_User_Label;

   function Is_Test_Only_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return
        Editor.Commands.Build_Terminal_Ids.Is_Internal_Build_Test_Seam_Command (Id);
   end Is_Test_Only_Command;

   function Is_Destructive_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Clear_Workspace_State
            | Command_Clear_Recent_Projects
            | Command_Remove_Selected_Recent_Project
            | Command_Remove_Missing_Recent_Projects
            | Command_Reset_Settings_To_Defaults
            | Command_Keybindings_Reset_To_Defaults
            | Command_Close_Project
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Revert_Active_Buffer
            | Command_Delete_Buffer_File
            | Command_File_Tree_Delete_Selected
            | Command_Close_Other_Buffers
            | Command_Close_All_Buffers
            | Command_Close_All_Clean_Buffers
            | Command_Clear_Project
            | Command_Clear_Bookmarks
            | Command_Clear_All_Bookmarks
            | Command_Bookmark_Clear_All
            | Command_Clear_Project_Search
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_Buffer_Switcher_Selected_Close =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Destructive_Command;

   function Is_Lifecycle_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Open_Project
            | Command_Switch_Project
            | Command_Open_Selected_Recent_Project
            | Command_Close_Project
            | Command_Clear_Project
            | Command_Save_Workspace_State
            | Command_Restore_Workspace_State
            | Command_Clear_Workspace_State
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close
            | Command_Reopen_Closed_Buffer
            | Command_Close_Other_Buffers
            | Command_Close_All_Buffers
            | Command_Close_All_Clean_Buffers
            | Command_Pin_Buffer
            | Command_Unpin_Buffer
            | Command_Toggle_Buffer_Pin
            | Command_Set_Buffer_Label
            | Command_Clear_Buffer_Label
            | Command_Edit_Buffer_Label
            | Command_Show_Buffer_Label
            | Command_Set_Buffer_Note
            | Command_Clear_Buffer_Note
            | Command_Edit_Buffer_Note
            | Command_Show_Buffer_Note
            | Command_Assign_Buffer_Group
            | Command_Clear_Buffer_Group
            | Command_Switch_Buffer_Group
            | Command_Next_Buffer_Group
            | Command_Previous_Buffer_Group
            | Command_Show_All_Buffer_Groups
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File
            | Command_File_Tree_Create_File
            | Command_File_Tree_Create_Directory
            | Command_File_Tree_Rename_Selected
            | Command_File_Tree_Delete_Selected
            | Command_New_Buffer
            | Command_Switch_Buffer
            | Command_Next_Buffer
            | Command_Previous_Buffer
            | Command_Previous_Recent_Buffer
            | Command_Next_Recent_Buffer
            | Command_Cancel_Pending_Transition
            | Command_Retry_Pending_Transition
            | Command_Discard_Pending_Transition
            | Command_Show_Recent_Projects
            | Command_Clear_Recent_Projects
            | Command_Remove_Selected_Recent_Project
            | Command_Remove_Missing_Recent_Projects
            | Command_Select_Next_Recent_Project
            | Command_Select_Previous_Recent_Project
            | Command_Buffer_Switcher_Selected_Close
            | Command_Buffer_Switcher_Selected_Pin
            | Command_Buffer_Switcher_Selected_Unpin
            | Command_Buffer_Switcher_Selected_Toggle_Pin
            | Command_Buffer_Switcher_Selected_Group_Assign
            | Command_Buffer_Switcher_Selected_Group_Clear
            | Command_Buffer_Switcher_Selected_Label_Set
            | Command_Buffer_Switcher_Selected_Label_Clear
            | Command_Buffer_Switcher_Selected_Note_Set
            | Command_Buffer_Switcher_Selected_Note_Clear
            | Command_Buffer_Switcher_Mark_Confirm
            | Command_Accept_Quick_Open
            | Command_Quick_Open_Create_From_Query
            | Command_Quick_Open_Create_With_Parents_From_Query =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Lifecycle_Command;

   function Is_Configuration_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_Settings
            | Command_Reload_Settings
            | Command_Reset_Settings_To_Defaults
            | Command_Save_Keybindings
            | Command_Reload_Keybindings
            | Command_Validate_Keybindings
            | Command_Keybindings_Show
            | Command_Keybindings_Focus
            | Command_Keybindings_Assign_Selected
            | Command_Keybindings_Remove_Selected
            | Command_Keybindings_Reset_To_Defaults
            | Command_Keybindings_Filter_Conflicts
            | Command_Keybindings_Filter_Unbound
            | Command_Keybindings_Clear_Filter
            | Command_Keybindings_Cancel_Capture
            | Command_Startup_Show_Summary
            | Command_Configuration_Recover_Show
            | Command_Configuration_Audit
            | Command_Configuration_Reset_Settings
            | Command_Configuration_Reset_Keybindings
            | Command_Configuration_Reset_Workspace
            | Command_Configuration_Reset_Recent_Projects
            | Command_Configuration_Reset_All
            | Command_Configuration_Reset_All_Confirm
            | Command_Configuration_Reset_All_Cancel
            | Command_Configuration_Save_Clean_Settings
            | Command_Configuration_Save_Clean_Keybindings
            | Command_Configuration_Save_Clean_Workspace
            | Command_Configuration_Save_Clean_Recent_Projects
            | Command_Toggle_Theme
            | Command_Set_Theme_Light
            | Command_Set_Theme_Dark
            | Command_Toggle_Minimap
            | Command_Toggle_Scrollbars
            | Command_Toggle_Line_Numbers
            | Command_Toggle_Line_Number_Mode
            | Command_Set_Absolute_Line_Numbers
            | Command_Set_Relative_Line_Numbers
            | Command_Set_Hybrid_Line_Numbers
            | Command_Toggle_Current_Line_Highlight
            | Command_Toggle_Cursor_Blink
            | Command_Toggle_Syntax_Colouring
            | Command_Toggle_Diagnostics
            | Command_Toggle_Cursor_Style =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Configuration_Command;

   function Is_Global_Settings_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Settings;
   end Is_Global_Settings_Save_Command;

   function Is_Global_Keybindings_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Keybindings;
   end Is_Global_Keybindings_Save_Command;

   function Is_Search_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Classification.Is_Search_Command;

   function Is_Panel_Focus_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Classification.Is_Panel_Focus_Command;

   function Has_Descriptor
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
   begin
      return D.Id = Id;
   end Has_Descriptor;

   function Has_Stable_Name
     (Id : Command_Id) return Boolean
   is
      Name : constant String := Name_Metadata.Stable_Command_Name (Id);
   begin
      return Is_Bindable_Command (Id)
        and then Name'Length > 0
        and then Ada.Strings.Fixed.Index (Name, " ") = 0
        and then Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both) = Name;
   end Has_Stable_Name;

   function Is_Bindable_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Concrete_Command (Id)
        and then not Is_Test_Only_Command (Id)
        and then Descriptor (Id).Bindable;
   end Is_Bindable_Command;

   function Is_Internal_Command
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
   begin
      return D.Category = Internal_Category
        or else D.Visibility = Hidden_Command;
   end Is_Internal_Command;

   function Descriptor_Is_Complete
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Audits.Descriptor_Is_Complete;

   procedure Audit_Command
     (Id      : Command_Id;
      Failure : out Command_Audit_Failure;
      Found   : out Boolean)
     renames Editor.Commands.Audits.Audit_Command;

   function Audit_Command_Registry
      return Command_Audit_Failure_Vectors.Vector
     renames Editor.Commands.Audits.Audit_Command_Registry;

   function Command_Audit_Summary
     (Failures : Command_Audit_Failure_Vectors.Vector) return String
     renames Editor.Commands.Audits.Command_Audit_Summary;


   function Is_Visible_In_Palette
     (Id : Command_Id) return Boolean
   is
   begin
      return Descriptor (Id).Visibility = Palette_Command;
   end Is_Visible_In_Palette;

   function Visible_In_Command_Palette
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Visible_In_Palette (Id);
   end Visible_In_Command_Palette;

   function Palette_Command_Count return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Command_Count loop
         if Visible_In_Command_Palette (Command_At (I)) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Palette_Command_Count;

   function Palette_Command_At
     (Index : Positive) return Command_Id
   is
      Count : Natural := 0;
      Id    : Command_Id;
   begin
      pragma Assert
        (Index <= Palette_Command_Count,
         "Editor.Commands.Registry.Palette_Command_At index out of range");

      for I in 1 .. Command_Count loop
         Id := Command_At (I);
         if Visible_In_Command_Palette (Id) then
            Count := Count + 1;
            if Count = Index then
               return Id;
            end if;
         end if;
      end loop;

      return No_Command;
   end Palette_Command_At;

   function Command_Count return Natural
   is
   begin
      return Command_Ids.Command_Count;
   end Command_Count;

   function Command_At
     (Index : Positive) return Command_Id
   is
   begin
      return Command_Ids.Command_At (Index);
   end Command_At;

   function Palette_Commands return Command_Descriptor_Vectors.Vector is
      Result : Command_Descriptor_Vectors.Vector;
      D      : Command_Descriptor;
   begin
      for I in 1 .. Command_Count loop
         D := Descriptor (Command_At (I));
         if D.Visibility = Palette_Command then
            Result.Append (D);
         end if;
      end loop;

      return Result;
   end Palette_Commands;

end Editor.Commands;
