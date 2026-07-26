with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Commands.Descriptors;
with Editor.Commands.Name_Metadata;
with Editor.Keybindings;
with Editor.Text_Helpers;

package body Editor.Command_Palette.Help is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Descriptors.Command_Visibility;

   type Command_State_Context_Array is
     array (Editor.Commands.Command_Id) of Unbounded_String;
   Command_State_Contexts : Command_State_Context_Array :=
     (others => Null_Unbounded_String);

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Product_Facing_Classification_Label (Text : String) return String is
      Source : constant String := Lower (Text);
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Item : String) is
      begin
         if Length (Result) > 0 then
            Append (Result, ", ");
         end if;
         Append (Result, Item);
      end Add;
   begin
      if Ada.Strings.Fixed.Index (Source, "destructive") /= 0 then
         Add ("destructive");
      end if;
      if Ada.Strings.Fixed.Index (Source, "lifecycle") /= 0 then
         Add ("project/file safety");
      end if;
      if Ada.Strings.Fixed.Index (Source, "configuration") /= 0 then
         Add ("configuration");
      end if;
      if Ada.Strings.Fixed.Index (Source, "navigation") /= 0 then
         Add ("navigation");
      end if;
      if Ada.Strings.Fixed.Index (Source, "search") /= 0 then
         Add ("search");
      end if;
      if Ada.Strings.Fixed.Index (Source, "panel") /= 0 then
         Add ("panel");
      end if;
      if Ada.Strings.Fixed.Index (Source, "editing") /= 0 then
         Add ("editing");
      end if;
      if Ada.Strings.Fixed.Index (Source, "non-bindable") /= 0 then
         Add ("non-bindable");
      end if;
      if Length (Result) = 0 then
         Add ("command");
      end if;
      return To_String (Result);
   end Product_Facing_Classification_Label;

   function Related_Command_From_Descriptor
     (Command : Editor.Commands.Command_Id) return Related_Command_Help_Item
   is
      Stable : constant String := Editor.Commands.Name_Metadata.Stable_Command_Name (Command);
      D      : Editor.Commands.Descriptors.Command_Descriptor;
   begin
      if Command = Editor.Commands.No_Command
        or else Stable'Length = 0
      then
         return Empty_Related_Command_Help_Item;
      end if;

      D := Editor.Commands.Descriptors.Descriptor (Command);
      if D.Visibility /= Editor.Commands.Descriptors.Palette_Command then
         return Empty_Related_Command_Help_Item;
      end if;

      return
        (Command         => Command,
         Stable_Name     => To_Unbounded_String (Stable),
         Title           => D.Name,
         Visible         => True,
         Carries_Payload => False);
   end Related_Command_From_Descriptor;

   procedure Add_Related_Command
     (Help    : in out Command_Help_Snapshot;
      Command : Editor.Commands.Command_Id)
   is
      Item : constant Related_Command_Help_Item :=
        Related_Command_From_Descriptor (Command);
   begin
      if not Item.Visible
        or else Help.Related_Command_Count >= Max_Related_Command_Help_Items
      then
         return;
      end if;

      for I in 1 .. Help.Related_Command_Count loop
         if Help.Related_Commands (I).Command = Command
           or else To_String (Help.Related_Commands (I).Stable_Name) =
             To_String (Item.Stable_Name)
         then
            return;
         end if;
      end loop;

      Help.Related_Command_Count := Help.Related_Command_Count + 1;
      Help.Related_Commands (Help.Related_Command_Count) := Item;
   end Add_Related_Command;

   procedure Add_Related_Commands_For
     (Help : in out Command_Help_Snapshot;
      Id   : Editor.Commands.Command_Id)
   is
   begin
      case Id is
         when Editor.Commands.Command_Open_Project =>
            Add_Related_Command (Help, Editor.Commands.Command_Show_Recent_Projects);
            Add_Related_Command (Help, Editor.Commands.Command_Restore_Workspace_State);
         when Editor.Commands.Command_Restore_Workspace_State =>
            Add_Related_Command (Help, Editor.Commands.Command_Save_Workspace_State);
            Add_Related_Command (Help, Editor.Commands.Command_Clear_Workspace_State);
         when Editor.Commands.Command_Build_Run =>
            Add_Related_Command (Help, Editor.Commands.Command_Build_UI_Focus);
            Add_Related_Command (Help, Editor.Commands.Command_Build_Acknowledge_Consent);
            Add_Related_Command (Help, Editor.Commands.Command_Build_UI_Show);
         when Editor.Commands.Command_Build_UI_Show |
              Editor.Commands.Command_Build_UI_Focus =>
            Add_Related_Command (Help, Editor.Commands.Command_Build_Refresh_Candidates);
            Add_Related_Command (Help, Editor.Commands.Command_Build_Acknowledge_Consent);
            Add_Related_Command (Help, Editor.Commands.Command_Build_Run);
         when Editor.Commands.Command_Problems_Filter_All |
              Editor.Commands.Command_Problems_Filter_Errors |
              Editor.Commands.Command_Problems_Filter_Warnings |
              Editor.Commands.Command_Problems_Filter_Info |
              Editor.Commands.Command_Problems_Filter_Hints =>
            Add_Related_Command (Help, Editor.Commands.Command_Problems_Sort_By_Severity);
            Add_Related_Command (Help, Editor.Commands.Command_Problems_Group_By_Source);
            Add_Related_Command (Help, Editor.Commands.Command_Problems_Open_Selected);
         when Editor.Commands.Command_Problems_Sort_By_Location |
              Editor.Commands.Command_Problems_Sort_By_Severity |
              Editor.Commands.Command_Problems_Sort_By_Source |
              Editor.Commands.Command_Problems_Group_By_Severity |
              Editor.Commands.Command_Problems_Group_By_Source =>
            Add_Related_Command (Help, Editor.Commands.Command_Problems_Filter_All);
            Add_Related_Command (Help, Editor.Commands.Command_Problems_Filter_Errors);
            Add_Related_Command (Help, Editor.Commands.Command_Problems_Open_Selected);
         when Editor.Commands.Command_Refresh_Outline =>
            Add_Related_Command (Help, Editor.Commands.Command_Open_Selected_Outline_Item);
            Add_Related_Command (Help, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
            Add_Related_Command (Help, Editor.Commands.Command_Clear_Outline_Filter);
         when Editor.Commands.Command_Diagnostics_Show =>
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostics_Open_Selected);
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostic_Open_Source);
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostic_Show_Suppressed);
            Add_Related_Command (Help, Editor.Commands.Command_Problems_Filter_Errors);
         when Editor.Commands.Command_Diagnostics_Open_Selected |
              Editor.Commands.Command_Diagnostic_Open_Source |
              Editor.Commands.Command_Diagnostic_Apply_Quick_Fix |
              Editor.Commands.Command_Diagnostic_Suppress_Selected |
              Editor.Commands.Command_Diagnostic_Show_Suppressed |
              Editor.Commands.Command_Diagnostic_Restore_Last_Suppressed |
              Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed |
              Editor.Commands.Command_Diagnostic_Clear_Suppressed =>
            Add_Related_Command (Help, Editor.Commands.Command_Next_Diagnostic);
            Add_Related_Command (Help, Editor.Commands.Command_Previous_Diagnostic);
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostic_Apply_Quick_Fix);
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostic_Suppress_Selected);
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostic_Show_Suppressed);
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostic_Restore_Last_Suppressed);
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed);
            Add_Related_Command (Help, Editor.Commands.Command_Diagnostic_Clear_Suppressed);
         when Editor.Commands.Command_Refresh_File_Tree =>
            Add_Related_Command (Help, Editor.Commands.Command_Open_Quick_Open);
            Add_Related_Command (Help, Editor.Commands.Command_File_Tree_Open_Selected);
            Add_Related_Command (Help, Editor.Commands.Command_Open_Project);
         when Editor.Commands.Command_Keybindings_Assign_Selected =>
            Add_Related_Command (Help, Editor.Commands.Command_Keybindings_Remove_Selected);
            Add_Related_Command (Help, Editor.Commands.Command_Keybindings_Reset_To_Defaults);
         when Editor.Commands.Command_Reset_Settings_To_Defaults =>
            Add_Related_Command (Help, Editor.Commands.Command_Configuration_Audit);
         when others =>
            null;
      end case;
   end Add_Related_Commands_For;

   function Related_Command_Is_Activation_Safe
     (Item : Related_Command_Help_Item) return Boolean
   is
      Found    : Boolean := False;
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Name     : constant String := To_String (Item.Stable_Name);
   begin
      if not Item.Visible
        or else Item.Carries_Payload
        or else Item.Command = Editor.Commands.No_Command
        or else Name'Length = 0
        or else Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), " ") /= 0
        or else Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), ":") /= 0
        or else Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "/") /= 0
        or else Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "\") /= 0
        or else Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "?") /= 0
        or else Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "=") /= 0
      then
         return False;
      end if;

      Resolved := Editor.Commands.Name_Metadata.Command_Id_From_Stable_Name (Name, Found);
      return Found
        and then Resolved = Item.Command
        and then Editor.Commands.Descriptors.Descriptor (Item.Command).Visibility =
          Editor.Commands.Descriptors.Palette_Command
        and then To_String (Item.Title) =
          To_String (Editor.Commands.Descriptors.Descriptor (Item.Command).Name);
   end Related_Command_Is_Activation_Safe;

   function Related_Command_Is_Canonical_Descriptor_Projection
     (Item : Related_Command_Help_Item) return Boolean
   is
      Canonical : Related_Command_Help_Item;
   begin
      if not Item.Visible then
         return Item = Empty_Related_Command_Help_Item;
      end if;

      if not Related_Command_Is_Activation_Safe (Item) then
         return False;
      end if;

      Canonical := Related_Command_From_Descriptor (Item.Command);
      return Canonical.Visible
        and then Canonical.Command = Item.Command
        and then To_String (Canonical.Stable_Name) = To_String (Item.Stable_Name)
        and then To_String (Canonical.Title) = To_String (Item.Title)
        and then Canonical.Carries_Payload = Item.Carries_Payload;
   end Related_Command_Is_Canonical_Descriptor_Projection;

   function Assert_Related_Command_Help_Is_Coherent
     (Help : Command_Help_Snapshot) return Boolean
   is
   begin
      if Help.Related_Command_Count > Max_Related_Command_Help_Items then
         return False;
      end if;

      for I in 1 .. Help.Related_Command_Count loop
         if not Related_Command_Is_Canonical_Descriptor_Projection
           (Help.Related_Commands (I))
         then
            return False;
         end if;

         for J in I + 1 .. Help.Related_Command_Count loop
            if Help.Related_Commands (I).Command = Help.Related_Commands (J).Command
              or else To_String (Help.Related_Commands (I).Stable_Name) =
                To_String (Help.Related_Commands (J).Stable_Name)
            then
               return False;
            end if;
         end loop;
      end loop;

      for I in Help.Related_Command_Count + 1 .. Max_Related_Command_Help_Items loop
         if Help.Related_Commands (I) /= Empty_Related_Command_Help_Item then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Related_Command_Help_Is_Coherent;

   function Build_Command_Help
     (Candidate : Editor.Commands.Palette_Model.Command_Palette_Candidate;
      Config    : Command_Palette_Config) return Command_Help_Snapshot
   is
      D : constant Editor.Commands.Descriptors.Command_Descriptor :=
        Editor.Commands.Descriptors.Descriptor (Candidate.Id);
      Result : Command_Help_Snapshot;

      function Active_Keybinding_Label return Unbounded_String is
         Label : Unbounded_String := Null_Unbounded_String;
      begin
         for I in 1 .. Editor.Keybindings.Binding_Count_For_Command (Candidate.Id) loop
            if Length (Label) > 0 then
               Append (Label, ", ");
            end if;
            Append
              (Label,
               Editor.Keybindings.Format_Chord
                 (Editor.Keybindings.Binding_For_Command (Candidate.Id, I)));
         end loop;
         return Label;
      end Active_Keybinding_Label;
   begin
      Result.Title := D.Name;
      Result.Stable_Name := To_Unbounded_String
        (Editor.Commands.Name_Metadata.Stable_Command_Name (Candidate.Id));
      Result.Category_Label := To_Unbounded_String
        (Editor.Commands.Descriptors.Discoverability_Category_Label (Candidate.Id));
      Result.Description := D.Description;
      Result.Active_Keybinding_Count :=
        Editor.Keybindings.Binding_Count_For_Command (Candidate.Id);
      Result.Has_Active_Keybinding := Result.Active_Keybinding_Count > 0;
      Result.Unbound_Bindable := D.Bindable and then not Result.Has_Active_Keybinding;
      Result.Non_Bindable_Command := not D.Bindable;
      Result.Keybinding_Label :=
        (if not Config.Show_Keybindings
         then To_Unbounded_String ("Keybindings hidden")
         elsif Result.Has_Active_Keybinding
         then Active_Keybinding_Label
         elsif D.Bindable
         then To_Unbounded_String ("Unbound")
         else To_Unbounded_String ("Non-bindable"));
      Result.Bindability_Label :=
        To_Unbounded_String ((if D.Bindable then "Bindable" else "Non-bindable"));
      Result.Visibility_Label :=
        To_Unbounded_String
          ((case D.Visibility is
            when Editor.Commands.Descriptors.Palette_Command => "Visible in Command Palette",
            when Editor.Commands.Descriptors.Hidden_Command => "Hidden"));
      Result.Classification_Label := To_Unbounded_String
        (Product_Facing_Classification_Label
           (Editor.Commands.Descriptors.Classification_Label (Candidate.Id)));
      Result.Availability_Label :=
        To_Unbounded_String ((if Candidate.Available then "Available" else "Unavailable"));
      Result.Unavailable_Reason :=
        (if Candidate.Available then Null_Unbounded_String
         elsif Length (Candidate.Reason) > 0 then Candidate.Reason
         else To_Unbounded_String ("Command not available here"));
      Result.Surface_Relevance_Label := To_Unbounded_String
        (Editor.Commands.Descriptors.Surface_Relevance_Label (Candidate.Id));
      Result.State_Context_Label := Command_State_Contexts (Candidate.Id);
      Result.Guard_Label := To_Unbounded_String
        (Editor.Commands.Descriptors.Guard_Label (Candidate.Id));
      Add_Related_Commands_For (Result, Candidate.Id);
      return Result;
   end Build_Command_Help;

   procedure Clear_Command_State_Contexts is
   begin
      Command_State_Contexts := (others => Null_Unbounded_String);
   end Clear_Command_State_Contexts;

   procedure Set_Command_State_Context
     (Command : Editor.Commands.Command_Id;
      Text    : String)
   is
   begin
      if Command /= Editor.Commands.No_Command then
         Command_State_Contexts (Command) := To_Unbounded_String (Text);
      end if;
   end Set_Command_State_Context;

end Editor.Command_Palette.Help;
