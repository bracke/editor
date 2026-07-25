with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Descriptor_Factory;
with Editor.Commands.Descriptor_Metadata;
with Editor.Commands.Name_Metadata;

package body Editor.Commands.Descriptors is

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
      return Descriptor_Factory.Make_Command_Descriptor
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
      if Is_Navigation_Command (Id) then
         Add ("navigation");
      end if;
      if Is_Search_Command (Id) then
         Add ("search");
      end if;
      if Is_Panel_Focus_Command (Id) then
         Add ("panel");
      end if;
      if Is_Text_Editing_Command (Id) then
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

end Editor.Commands.Descriptors;
