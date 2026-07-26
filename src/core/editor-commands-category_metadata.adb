with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Classification;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Editor.Commands.Editing_Ids;
with Editor.Commands.Navigation_Ids;
with Editor.Commands.Stable_Names;

package body Editor.Commands.Category_Metadata is

   use type Editor.Commands.Descriptors.Command_Category;
   use type Editor.Commands.Descriptors.Command_Visibility;

   function Category
     (Id : Command_Id) return Editor.Commands.Descriptors.Command_Category
   is
   begin
      return Descriptor (Id).Category;
   end Category;

   function Category_Label
     (Category : Editor.Commands.Descriptors.Command_Category) return String
   is
      use all type Editor.Commands.Descriptors.Command_Category;
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
      Stable : constant String := Stable_Names.Stable_Command_Name (Id);
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
      if Editor.Commands.Classification.Is_Destructive_Command (Id) then
         Add ("destructive");
      end if;
      if Editor.Commands.Classification.Is_Lifecycle_Command (Id) then
         Add ("lifecycle");
      end if;
      if Editor.Commands.Classification.Is_Configuration_Command (Id) then
         Add ("configuration");
      end if;
      if Editor.Commands.Navigation_Ids.Is_Navigation_Command (Id) then
         Add ("navigation");
      end if;
      if Editor.Commands.Classification.Is_Search_Command (Id) then
         Add ("search");
      end if;
      if Editor.Commands.Classification.Is_Panel_Focus_Command (Id) then
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
      if not Editor.Commands.Classification.Is_Bindable_Command (Id) then
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
      Stable : constant String := Stable_Names.Stable_Command_Name (Id);
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
      if Editor.Commands.Classification.Is_Destructive_Command (Id) then
         Add ("confirmation and dirty-file protection retained");
      end if;
      if Editor.Commands.Classification.Is_Lifecycle_Command (Id) then
         Add ("project/file safety protection retained");
      end if;
      if Editor.Commands.Classification.Is_Configuration_Command (Id) then
         Add ("configuration safety check retained");
      end if;
      if not Editor.Commands.Classification.Is_Bindable_Command (Id) then
         Add ("not keybindable");
      end if;
      if Length (Result) = 0 then
         Add ("no special safety check");
      end if;
      return To_String (Result);
   end Guard_Label;

end Editor.Commands.Category_Metadata;
