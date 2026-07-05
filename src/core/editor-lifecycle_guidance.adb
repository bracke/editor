with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Executor;
with Editor.Keybindings;
with Editor.Settings;
with Editor.Panel_Focus;
with Editor.File_Tree_View;
with Editor.File_Tree;
with Editor.Buffers;

package body Editor.Lifecycle_Guidance is

   use type Editor.Commands.Command_Visibility;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.File_Tree.File_Tree_Node_Id;

   function Available
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Editor.Commands.Is_Available
        (Editor.Executor.Command_Availability (S, Id));
   end Available;

   function Show_Shortcuts
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Settings.Command_Palette_Show_Keybindings (S.Settings);
   end Show_Shortcuts;

   function Shortcut_Text
     (Command        : Editor.Commands.Command_Id;
      Show_Shortcuts : Boolean) return String
   is
      Info : Editor.Keybindings.Command_Keybinding_Info;
   begin
      if not Show_Shortcuts
        or else not Editor.Commands.Is_Bindable_Command (Command)
        or else Editor.Commands.Is_Internal_Build_Test_Seam_Command (Command)
        or else Editor.Commands.Is_Public_Build_Command (Command)
      then
         return "";
      end if;

      Info := Editor.Keybindings.Primary_Binding_For_Command (Command);
      if Info.Has_Binding then
         return To_String (Info.Display);
      end if;
      return "";
   end Shortcut_Text;

   function With_Command_Shortcut
     (Text           : String;
      Command        : Editor.Commands.Command_Id;
      Show_Shortcuts : Boolean) return String
   is
      Shortcut : constant String := Shortcut_Text (Command, Show_Shortcuts);
   begin
      if Shortcut'Length = 0 then
         return Text;
      else
         return Text & " [" & Shortcut & "]";
      end if;
   end With_Command_Shortcut;

   function With_Enter
     (Text           : String;
      Show_Shortcuts : Boolean) return String
   is
   begin
      if Show_Shortcuts then
         return Text & " [Enter]";
      else
         return Text;
      end if;
   end With_Enter;

   function Save_As_Supported return Boolean is
   begin
      return Editor.Commands.Descriptor
        (Editor.Commands.Command_Save_File_As).Visibility =
          Editor.Commands.Palette_Command;
   end Save_As_Supported;

   function Status_Bar_Hint
     (S : Editor.State.State_Type) return String
   is
      Found : Boolean := False;
      Node_Id : Editor.File_Tree.File_Tree_Node_Id;
   begin
      if Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus)
        and then Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View) /= 0
      then
         Node_Id := Editor.File_Tree_View.Node_For_Row
           (S.File_Tree,
            Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View),
            Found);
         if Found then
            return File_Tree_Row_Hint (S, Editor.File_Tree.Node (S.File_Tree, Node_Id));
         end if;
      end if;

      if S.File_Info.Dirty then
         if S.File_Info.Missing_Target_Surfaced then
            return "Dirty file - backing file missing";
         elsif S.File_Info.External_Change_Surfaced then
            return "Dirty file - conflict pending";
         elsif S.File_Info.Unreadable_Target_Surfaced
           or else S.File_Info.Last_Reload_Failed
           or else S.File_Info.Last_Revert_Failed
         then
            return "Dirty file - backing file unreadable";
         elsif S.File_Info.Unwritable_Target_Surfaced then
            return "Dirty file - backing file not writable";
         elsif S.File_Info.Has_Path
           and then S.File_Info.Last_Save_Failed
           and then Available (S, Editor.Commands.Command_Save_File)
         then
            return With_Command_Shortcut
              ("Dirty file - retry save available",
               Editor.Commands.Command_Save_File, Show_Shortcuts (S));
         elsif S.File_Info.Blocked_Close_Surfaced then
            return With_Command_Shortcut
              ("Close blocked - save before close",
               Editor.Commands.Command_Save_File, Show_Shortcuts (S));
         elsif S.File_Info.Has_Path
           and then Available (S, Editor.Commands.Command_Save_File)
         then
            return With_Command_Shortcut
              ("Dirty file - save available",
               Editor.Commands.Command_Save_File, Show_Shortcuts (S));
         elsif S.File_Info.Has_Path then
            return "Dirty file - save first";
         else
            return "Untitled dirty buffer";
         end if;
      end if;

      if S.File_Info.Blocked_Close_Surfaced then
         return "Close block resolved - clean file";
      elsif S.File_Info.Missing_Target_Surfaced then
         return "Missing target surfaced";
      elsif S.File_Info.External_Change_Surfaced then
         return "External change surfaced";
      elsif S.File_Info.Unreadable_Target_Surfaced
        or else S.File_Info.Last_Reload_Failed
        or else S.File_Info.Last_Revert_Failed
      then
         return "Backing file unreadable";
      elsif S.File_Info.Unwritable_Target_Surfaced
        or else S.File_Info.Last_Save_Failed
      then
         return "Backing file not writable";
      elsif not S.File_Info.Has_Path then
         return "Untitled clean buffer";
      elsif Available (S, Editor.Commands.Command_Reload_Active_Buffer) then
         return With_Command_Shortcut
           ("Clean file - reload available", Editor.Commands.Command_Reload_Active_Buffer,
            Show_Shortcuts (S));
      else
         return "Clean file";
      end if;
   end Status_Bar_Hint;

   function Open_Buffer_Row_Hint
     (S       : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary) return String
   is
      Show : constant Boolean := Show_Shortcuts (S);
   begin
      if Summary.Id = Editor.Buffers.No_Buffer then
         return "";
      elsif Summary.Is_Dirty then
         if Summary.Is_Active then
            --  completeness: row guidance is a projection of the
            --  open-buffer summary snapshot.  Even for the active row, use the
            --  supplied summary for lifecycle recovery markers so a row built
            --  from the buffer registry cannot fall back to stale active-state
            --  hints when the registry summary already carries the precise
            --  missing/unreadable/unwritable/external-change condition.
            if Summary.Missing_Target_Surfaced then
               return "Unsaved - backing file missing; recover before close";
            elsif Summary.External_Change_Surfaced then
               return "Unsaved - conflict pending; resolve before close";
            elsif Summary.Unreadable_Target_Surfaced
              or else Summary.Last_Reload_Failed
              or else Summary.Last_Revert_Failed
            then
               return "Unsaved - backing file unreadable; recover before close";
            elsif Summary.Unwritable_Target_Surfaced then
               return "Unsaved - backing file not writable; recover before close";
            elsif Summary.Has_Path
              and then Summary.Last_Save_Failed
              and then Available (S, Editor.Commands.Command_Save_File)
            then
               return With_Command_Shortcut
                 ("Unsaved - retry save available; normal close blocked",
                  Editor.Commands.Command_Save_File, Show);
            elsif Summary.Blocked_Close_Surfaced then
               return With_Command_Shortcut
                 ("Unsaved - close blocked; save before close",
                  Editor.Commands.Command_Save_File, Show);
            elsif Summary.Has_Path
              and then Available (S, Editor.Commands.Command_Save_File)
            then
               return With_Command_Shortcut
                 ("Unsaved - save available; normal close blocked",
                  Editor.Commands.Command_Save_File, Show);
            elsif (not Summary.Has_Path)
              and then Save_As_Supported
              and then Available (S, Editor.Commands.Command_Save_File_As)
            then
               return With_Command_Shortcut
                 ("Unsaved - Save As available; normal close blocked",
                  Editor.Commands.Command_Save_File_As, Show);
            else
               return "Unsaved - normal close blocked";
            end if;
         else
            --  recovery markers describe why the dirty inactive
            --  buffer needs attention.  They must take precedence over the
            --  generic retry-save hint because save failures often set both
            --  Last_Save_Failed and a more specific missing/unwritable marker.
            if Summary.Missing_Target_Surfaced then
               return With_Enter ("Unsaved - backing file missing; focus to recover", Show);
            elsif Summary.External_Change_Surfaced then
               return With_Enter ("Unsaved - conflict pending; focus to resolve", Show);
            elsif Summary.Unreadable_Target_Surfaced
              or else Summary.Last_Reload_Failed
              or else Summary.Last_Revert_Failed
            then
               return With_Enter ("Unsaved - backing file unreadable; focus to recover", Show);
            elsif Summary.Unwritable_Target_Surfaced then
               return With_Enter ("Unsaved - backing file not writable; focus to recover", Show);
            elsif Summary.Last_Save_Failed and then Summary.Has_Path then
               return With_Enter ("Unsaved - focus to retry save; normal close blocked", Show);
            elsif Summary.Blocked_Close_Surfaced then
               return With_Enter ("Unsaved - close blocked for this buffer", Show);
            else
               return With_Enter ("Unsaved - focus before save; normal close blocked", Show);
            end if;
         end if;
      elsif Summary.Missing_Target_Surfaced then
         return With_Enter ("Backing file missing - focus to recover", Show);
      elsif Summary.External_Change_Surfaced then
         return With_Enter ("External change surfaced - focus to resolve", Show);
      elsif Summary.Unreadable_Target_Surfaced
        or else Summary.Last_Reload_Failed
        or else Summary.Last_Revert_Failed
      then
         return With_Enter ("Backing file unreadable - focus to recover", Show);
      elsif Summary.Unwritable_Target_Surfaced
        or else Summary.Last_Save_Failed
      then
         return With_Enter ("Backing file not writable - focus to recover", Show);
      elsif Summary.Is_Active then
         if Available (S, Editor.Commands.Command_Close_Active_Buffer) then
            return With_Command_Shortcut
              ("Active buffer - close available", Editor.Commands.Command_Close_Active_Buffer,
               Show);
         else
            return "Active buffer";
         end if;
      else
         return With_Enter ("Focus existing buffer", Show);
      end if;
   end Open_Buffer_Row_Hint;

   function File_Tree_Row_Hint
     (S    : Editor.State.State_Type;
      Node : Editor.File_Tree.File_Tree_Node_Summary) return String
   is
      Show : constant Boolean := Show_Shortcuts (S);
      Found_Open : Boolean := False;
      Open_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      if Node.Id = Editor.File_Tree.No_File_Tree_Node then
         return "";
      elsif Node.Kind = Editor.File_Tree.Directory_Node then
         if Node.Is_Expanded then
            return With_Enter ("Collapse folder", Show);
         else
            return With_Enter ("Expand folder", Show);
         end if;
      end if;

      Open_Id := Editor.Buffers.Global_Find_By_Path
        (To_String (Node.Absolute_Path), Found_Open);

      if Found_Open then
         Summary := Editor.Buffers.Global_Summary_For (Open_Id);
         if Summary.Missing_Target_Surfaced then
            return With_Enter ("Focus open buffer with missing backing file", Show);
         elsif Summary.External_Change_Surfaced and then Summary.Is_Dirty then
            return With_Enter ("Focus open buffer with conflict pending", Show);
         elsif Summary.External_Change_Surfaced then
            return With_Enter ("Focus open buffer with external change", Show);
         elsif Summary.Unreadable_Target_Surfaced
           or else Summary.Last_Reload_Failed
           or else Summary.Last_Revert_Failed
         then
            return With_Enter ("Focus open buffer with unreadable backing file", Show);
         elsif Summary.Unwritable_Target_Surfaced
           or else Summary.Last_Save_Failed
         then
            return With_Enter ("Focus open buffer with unwritable backing file", Show);
         elsif Summary.Is_Dirty then
            return With_Enter ("Focus existing unsaved buffer", Show);
         else
            return With_Enter ("Focus existing buffer", Show);
         end if;
      else
         return With_Enter ("Open file", Show);
      end if;
   end File_Tree_Row_Hint;

end Editor.Lifecycle_Guidance;
