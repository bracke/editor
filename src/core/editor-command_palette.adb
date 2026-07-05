with Ada.Characters.Handling;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Contextual_Help;
with Editor.Input_Field;
with Editor.Keybindings;

package body Editor.Command_Palette is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;

   State : Palette_State;
   Config_State : Command_Palette_Config;
   Filter_Field : Editor.Input_Field.Input_Field_State;
   Availability_Filter_State : Command_Palette_Availability_Filter :=
     Palette_All_Commands;
   Category_Filter_Active : Boolean := False;
   Category_Filter_Label_State : Unbounded_String := Null_Unbounded_String;
   Destructive_Filter_State : Boolean := False;
   Keybinding_Filter_State : Command_Palette_Keybinding_Filter :=
     Palette_All_Keybinding_States;
   type Command_State_Context_Array is
     array (Editor.Commands.Command_Id) of Unbounded_String;
   Command_State_Contexts : Command_State_Context_Array :=
     (others => Null_Unbounded_String);

   procedure Sync_Query is
   begin
      State.Query := To_Unbounded_String (Editor.Input_Field.Text (Filter_Field));
   end Sync_Query;

   procedure Clamp_Selection;

   function Current_Config return Command_Palette_Config is
   begin
      return Config_State;
   end Current_Config;

   procedure Set_Current_Config (Config : Command_Palette_Config) is
   begin
      Config_State := Config;
      --  Set_Current_Config is used by settings/application code
      --  for persisted display preferences. Selected-command help/details is
      --  transient command-palette state, so it must not be imported through
      --  this broader configuration record. Use Set_Show_Help_Row or the
      --  Executor-routed command-palette.show-command-help action for the
      --  runtime help toggle.
      Config_State.Show_Help_Row := False;
   end Set_Current_Config;

   procedure Set_Show_Unavailable_Commands (Enabled : Boolean) is
   begin
      Config_State.Show_Unavailable_Commands := Enabled;
   end Set_Show_Unavailable_Commands;

   procedure Set_Show_Keybindings (Enabled : Boolean) is
   begin
      Config_State.Show_Keybindings := Enabled;
   end Set_Show_Keybindings;

   procedure Set_Show_Help_Row (Enabled : Boolean) is
   begin
      Config_State.Show_Help_Row := Enabled;
   end Set_Show_Help_Row;

   procedure Toggle_Show_Help_Row is
   begin
      Config_State.Show_Help_Row := not Config_State.Show_Help_Row;
   end Toggle_Show_Help_Row;

   procedure Clear_Transient_Filters is
   begin
      Availability_Filter_State := Palette_All_Commands;
      Category_Filter_Active := False;
      Category_Filter_Label_State := Null_Unbounded_String;
      Destructive_Filter_State := False;
      Keybinding_Filter_State := Palette_All_Keybinding_States;
   end Clear_Transient_Filters;

   function Transient_State_Clear return Boolean is
   begin
      return (not State.Open)
        and then Length (State.Query) = 0
        and then Editor.Input_Field.Text (Filter_Field)'Length = 0
        and then State.Selected_Item = 0
        and then State.Selected_Candidate_Index = 0
        and then State.Selected_Command_Id = Editor.Commands.No_Command
        and then State.Top_Row = 1
        and then not Config_State.Show_Help_Row
        and then Availability_Filter_State = Palette_All_Commands
        and then not Category_Filter_Active
        and then Length (Category_Filter_Label_State) = 0
        and then not Destructive_Filter_State
        and then Keybinding_Filter_State = Palette_All_Keybinding_States;
   end Transient_State_Clear;

   procedure Set_Availability_Filter
     (Filter : Command_Palette_Availability_Filter) is
   begin
      Availability_Filter_State := Filter;
      Clamp_Selection;
   end Set_Availability_Filter;

   function Current_Availability_Filter
      return Command_Palette_Availability_Filter is
   begin
      return Availability_Filter_State;
   end Current_Availability_Filter;

   procedure Set_Category_Filter_Label (Label : String) is
   begin
      Category_Filter_Active := Label'Length > 0;
      Category_Filter_Label_State := To_Unbounded_String (Label);
      Clamp_Selection;
   end Set_Category_Filter_Label;

   procedure Clear_Category_Filter is
   begin
      Category_Filter_Active := False;
      Category_Filter_Label_State := Null_Unbounded_String;
      Clamp_Selection;
   end Clear_Category_Filter;

   function Has_Category_Filter return Boolean is
   begin
      return Category_Filter_Active;
   end Has_Category_Filter;

   function Current_Category_Filter_Label return String is
   begin
      return To_String (Category_Filter_Label_State);
   end Current_Category_Filter_Label;

   procedure Set_Destructive_Filter (Enabled : Boolean) is
   begin
      Destructive_Filter_State := Enabled;
      Clamp_Selection;
   end Set_Destructive_Filter;

   function Destructive_Filter_Enabled return Boolean is
   begin
      return Destructive_Filter_State;
   end Destructive_Filter_Enabled;

   procedure Set_Keybinding_Filter
     (Filter : Command_Palette_Keybinding_Filter) is
   begin
      Keybinding_Filter_State := Filter;
      Clamp_Selection;
   end Set_Keybinding_Filter;

   function Current_Keybinding_Filter return Command_Palette_Keybinding_Filter is
   begin
      return Keybinding_Filter_State;
   end Current_Keybinding_Filter;

   function Lower (S : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower (S);
   end Lower;

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

   function Candidate_Passes_Transient_Filters
     (Candidate : Editor.Commands.Command_Palette_Candidate) return Boolean
   is
      Category_Text : constant String := To_String (Candidate.Category_Label);
   begin
      case Availability_Filter_State is
         when Palette_All_Commands =>
            null;
         when Palette_Available_Only =>
            if not Candidate.Available then
               return False;
            end if;
         when Palette_Unavailable_Only =>
            if Candidate.Available then
               return False;
            end if;
      end case;

      if Category_Filter_Active
        and then Lower (Category_Text) /= Lower (To_String (Category_Filter_Label_State))
      then
         return False;
      end if;

      if Destructive_Filter_State
        and then not Editor.Commands.Is_Destructive_Command (Candidate.Id)
      then
         return False;
      end if;

      case Keybinding_Filter_State is
         when Palette_All_Keybinding_States =>
            null;
         when Palette_Bound_Commands_Only =>
            if not Candidate.Has_Keybinding then
               return False;
            end if;
         when Palette_Unbound_Bindable_Commands_Only =>
            declare
               D : constant Editor.Commands.Command_Descriptor :=
                 Editor.Commands.Descriptor (Candidate.Id);
            begin
               if (not D.Bindable) or else Candidate.Has_Keybinding then
                  return False;
               end if;
            end;
      end case;

      return True;
   end Candidate_Passes_Transient_Filters;

   function Candidate_Is_Currently_Visible
     (Candidate : Editor.Commands.Command_Palette_Candidate) return Boolean
   is
   begin
      return Candidate_Passes_Transient_Filters (Candidate)
        and then (Config_State.Show_Unavailable_Commands or else Candidate.Available);
   end Candidate_Is_Currently_Visible;

   procedure Visible_Candidates
     (Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Result     : out Editor.Commands.Command_Palette_Candidate_Vectors.Vector)
   is
   begin
      Result.Clear;
      for C of Candidates loop
         if Candidate_Is_Currently_Visible (C) then
            Result.Append (C);
         end if;
      end loop;
   end Visible_Candidates;

   function Descriptor_Passes_Transient_Metadata_Filters
     (Descriptor : Editor.Commands.Command_Descriptor) return Boolean
   is
      Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command (Descriptor.Id);
      Category_Text : constant String :=
        Editor.Commands.Discoverability_Category_Label (Descriptor.Id);
   begin
      if Category_Filter_Active
        and then Lower (Category_Text) /= Lower (To_String (Category_Filter_Label_State))
      then
         return False;
      end if;

      if Destructive_Filter_State
        and then not Editor.Commands.Is_Destructive_Command (Descriptor.Id)
      then
         return False;
      end if;

      case Keybinding_Filter_State is
         when Palette_All_Keybinding_States =>
            null;
         when Palette_Bound_Commands_Only =>
            if (not Descriptor.Bindable) or else not Binding.Has_Binding then
               return False;
            end if;
         when Palette_Unbound_Bindable_Commands_Only =>
            if (not Descriptor.Bindable) or else Binding.Has_Binding then
               return False;
            end if;
      end case;

      return True;
   end Descriptor_Passes_Transient_Metadata_Filters;

   function Starts_With (Text, Prefix : String) return Boolean is
   begin
      return Prefix'Length <= Text'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Word_Initial_Or_Subsequence_Match (Text, Query : String) return Boolean is
      J         : Natural := Query'First;
      At_Word   : Boolean := True;
      Hit_Word  : Boolean := False;
   begin
      if Query'Length = 0 then
         return True;
      end if;

      for I in Text'Range loop
         if At_Word and then J <= Query'Last and then Text (I) = Query (J) then
            Hit_Word := True;
         end if;

         if J <= Query'Last and then Text (I) = Query (J) then
            J := J + 1;
            if J > Query'Last then
               return True;
            end if;
         end if;

         At_Word := Text (I) = ' ' or else Text (I) = '-' or else Text (I) = '_';
      end loop;

      return Hit_Word and then Query'Length = 1;
   end Word_Initial_Or_Subsequence_Match;

   function Match_Score
     (Label          : String;
      Category_Label : String;
      Description    : String;
      Query          : String) return Natural
   is
      L : constant String := Lower (Label);
      C : constant String := Lower (Category_Label);
      D : constant String := Lower (Description);
      Q : constant String := Lower (Query);
   begin
      if Q'Length = 0 then
         return 1;
      elsif L = Q then
         return 600;
      elsif Starts_With (L, Q) then
         return 500;
      elsif Ada.Strings.Fixed.Index (L, Q) /= 0 then
         return 400;
      elsif Word_Initial_Or_Subsequence_Match (L, Q) then
         return 300;
      elsif Ada.Strings.Fixed.Index (C, Q) /= 0 then
         return 200;
      elsif Ada.Strings.Fixed.Index (D, Q) /= 0 then
         return 100;
      else
         return 0;
      end if;
   end Match_Score;

   function Truncate_With_Ellipsis
     (Text        : String;
      Max_Columns : Natural) return String
   is
   begin
      if Max_Columns = 0 then
         return "";
      elsif Text'Length <= Max_Columns then
         return Text;
      elsif Max_Columns = 1 then
         return "~";
      else
         declare
            Prefix : constant String :=
              Text (Text'First .. Text'First + Max_Columns - 2);
            Last   : Integer := Prefix'Last;
         begin
            if Last >= Prefix'First
              and then (Prefix (Last) = '.' or else Prefix (Last) = ' ')
            then
               Last := Last - 1;
            end if;
            if Last < Prefix'First then
               return "~";
            else
               return Prefix (Prefix'First .. Last) & "~";
            end if;
         end;
      end if;
   end Truncate_With_Ellipsis;

   function Fit_Text
     (Text        : String;
      Max_Columns : Natural) return String
   is
   begin
      return Truncate_With_Ellipsis (Text, Max_Columns);
   end Fit_Text;

   function Layout_Command_Row
     (Row_Width_Columns : Natural;
      Label_Length      : Natural;
      Secondary_Length  : Natural;
      Keybinding_Length : Natural;
      Is_Selected       : Boolean;
      Is_Available      : Boolean) return Command_Palette_Row_Layout
   is
      pragma Unreferenced (Is_Available);
      Result : Command_Palette_Row_Layout;
      Binding_Gap : constant Natural := 2;
      Secondary_Gap : constant Natural := 3;
      Main_Columns : Natural := Row_Width_Columns;
      Wants_Secondary : constant Boolean := Is_Selected and then Secondary_Length > 0;
   begin
      if Row_Width_Columns = 0 then
         return Result;
      end if;

      Result.Show_Keybinding :=
        Keybinding_Length > 0
        and then Row_Width_Columns >= Keybinding_Length + Binding_Gap + 2;

      if Result.Show_Keybinding then
         Result.Keybinding_Start_Column := Row_Width_Columns - Keybinding_Length;
         Result.Keybinding_Column := Result.Keybinding_Start_Column;
         Result.Keybinding_Columns := Keybinding_Length;
         Main_Columns := Result.Keybinding_Start_Column - Binding_Gap;
      end if;

      Result.Label_Start_Column := 0;

      if Main_Columns = 0 then
         return Result;
      end if;

      if Wants_Secondary and then Main_Columns > Secondary_Gap + 1 then
         declare
            Full_Label_With_Gap : constant Natural := Label_Length + Secondary_Gap;
            Minimum_Label       : constant Natural :=
              (if Label_Length = 0 then 0 else 1);
         begin
            Result.Show_Secondary := True;

            if Full_Label_With_Gap + Secondary_Length <= Main_Columns then
               Result.Label_Columns := Label_Length;
               Result.Secondary_Start_Column := Full_Label_With_Gap;
               Result.Secondary_Columns := Secondary_Length;
            elsif Label_Length + Secondary_Gap < Main_Columns then
               Result.Label_Columns := Label_Length;
               Result.Secondary_Start_Column := Full_Label_With_Gap;
               Result.Secondary_Columns := Main_Columns - Full_Label_With_Gap;
            else
               Result.Label_Columns :=
                 Natural'Max
                   (Minimum_Label,
                    Natural'Min
                      (Label_Length,
                       Main_Columns - Secondary_Gap - 1));
               Result.Secondary_Start_Column :=
                 Result.Label_Columns + Secondary_Gap;
               Result.Secondary_Columns :=
                 Main_Columns - Result.Secondary_Start_Column;
            end if;

            if Result.Secondary_Columns = 0 then
               Result.Show_Secondary := False;
               Result.Secondary_Start_Column := 0;
               Result.Label_Columns := Natural'Min (Label_Length, Main_Columns);
            end if;
         end;
      else
         Result.Label_Columns := Natural'Min (Label_Length, Main_Columns);
      end if;

      return Result;
   end Layout_Command_Row;

   function Project_Command_Row_Layout
     (Candidate   : Editor.Commands.Command_Palette_Candidate;
      Is_Selected : Boolean;
      Row_Columns : Natural) return Command_Palette_Row_Layout
   is
      Label_Text : constant String := To_String (Candidate.Label);
      Binding_Text : constant String :=
        (if Candidate.Has_Keybinding
         then To_String (Candidate.Keybinding_Display)
         else "");
      Secondary_Text : constant String :=
        (if Is_Selected and then not Candidate.Available
         then (if Length (Candidate.Reason) > 0
               then To_String (Candidate.Reason)
               else "Command not available here")
         elsif Is_Selected and then Candidate.Available
            and then Length (Candidate.Description) > 0
         then To_String (Candidate.Description)
         else "");
      Result : Command_Palette_Row_Layout :=
        Layout_Command_Row
          (Row_Width_Columns => Row_Columns,
           Label_Length      => Label_Text'Length,
           Secondary_Length  => Secondary_Text'Length,
           Keybinding_Length => Binding_Text'Length,
           Is_Selected       => Is_Selected,
           Is_Available      => Candidate.Available);
      Main : Unbounded_String := Null_Unbounded_String;
   begin
      if Result.Label_Columns > 0 then
         Main := To_Unbounded_String
           (Truncate_With_Ellipsis (Label_Text, Result.Label_Columns));
      end if;

      if Result.Show_Secondary then
         Main := Main & " - "
           & Truncate_With_Ellipsis (Secondary_Text, Result.Secondary_Columns);
      end if;

      Result.Visible_Text := Main;
      if Result.Show_Keybinding then
         Result.Keybinding_Text := To_Unbounded_String (Binding_Text);
      end if;

      return Result;
   end Project_Command_Row_Layout;


   function Related_Command_From_Descriptor
     (Command : Editor.Commands.Command_Id) return Related_Command_Help_Item
   is
      Stable : constant String := Editor.Commands.Stable_Command_Name (Command);
      D      : Editor.Commands.Command_Descriptor;
   begin
      if Command = Editor.Commands.No_Command
        or else Stable'Length = 0
      then
         return Empty_Related_Command_Help_Item;
      end if;

      D := Editor.Commands.Descriptor (Command);
      if D.Visibility /= Editor.Commands.Palette_Command then
         return Empty_Related_Command_Help_Item;
      end if;

      --  related-command help uses the same safe pattern as
      --  guided empty-state actions: descriptor projection only, stable
      --  command name only, and no target/result/chord/recovery payload.
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

      Resolved := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      return Found
        and then Resolved = Item.Command
        and then Editor.Commands.Descriptor (Item.Command).Visibility =
          Editor.Commands.Palette_Command
        and then To_String (Item.Title) =
          To_String (Editor.Commands.Descriptor (Item.Command).Name);
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
     (Candidate : Editor.Commands.Command_Palette_Candidate)
      return Command_Help_Snapshot
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Candidate.Id);
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
        (Editor.Commands.Stable_Command_Name (Candidate.Id));
      Result.Category_Label := To_Unbounded_String
        (Editor.Commands.Discoverability_Category_Label (Candidate.Id));
      Result.Description := D.Description;
      Result.Active_Keybinding_Count :=
        Editor.Keybindings.Binding_Count_For_Command (Candidate.Id);
      Result.Has_Active_Keybinding := Result.Active_Keybinding_Count > 0;
      Result.Unbound_Bindable := D.Bindable and then not Result.Has_Active_Keybinding;
      Result.Non_Bindable_Command := not D.Bindable;
      Result.Keybinding_Label :=
        (if not Config_State.Show_Keybindings
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
            when Editor.Commands.Palette_Command => "Visible in Command Palette",
            when Editor.Commands.Hidden_Command => "Hidden"));
      Result.Classification_Label := To_Unbounded_String
        (Product_Facing_Classification_Label
           (Editor.Commands.Classification_Label (Candidate.Id)));
      Result.Availability_Label :=
        To_Unbounded_String ((if Candidate.Available then "Available" else "Unavailable"));
      Result.Unavailable_Reason :=
        (if Candidate.Available then Null_Unbounded_String
         elsif Length (Candidate.Reason) > 0 then Candidate.Reason
         else To_Unbounded_String ("Command not available here"));
      Result.Surface_Relevance_Label := To_Unbounded_String
        (Editor.Commands.Surface_Relevance_Label (Candidate.Id));
      Result.State_Context_Label := Command_State_Contexts (Candidate.Id);
      Result.Guard_Label := To_Unbounded_String
        (Editor.Commands.Guard_Label (Candidate.Id));
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

   function Descriptor_Registry_Order
     (Id : Editor.Commands.Command_Id) return Natural
   is
   begin
      return Editor.Commands.Command_Id'Pos (Id)
        - Editor.Commands.Command_Id'Pos (Editor.Commands.Command_Id'First);
   end Descriptor_Registry_Order;

   function Candidate_Less
     (Left  : Editor.Commands.Command_Palette_Candidate;
      Right : Editor.Commands.Command_Palette_Candidate) return Boolean
   is
      L_Label : constant String := To_String (Left.Label);
      R_Label : constant String := To_String (Right.Label);
      L_Category_Label : constant String := To_String (Left.Category_Label);
      R_Category_Label : constant String := To_String (Right.Category_Label);
   begin
      if Left.Match_Score /= Right.Match_Score then
         return Left.Match_Score > Right.Match_Score;
      elsif Left.Match_Score = 1 and then L_Category_Label /= R_Category_Label then
         --  Empty-query candidates all use the baseline score. Keep the
         --  refined discoverability category label ahead of availability so
         --  grouped projection cannot merge Build/File Tree/Outline commands
         --  into broader generic enum headers.
         return L_Category_Label < R_Category_Label;
      elsif Left.Available /= Right.Available then
         return Left.Available;
      elsif L_Category_Label /= R_Category_Label then
         return L_Category_Label < R_Category_Label;
      elsif Left.Category /= Right.Category then
         return Editor.Commands.Command_Category'Pos (Left.Category)
           < Editor.Commands.Command_Category'Pos (Right.Category);
      elsif Left.Registry_Order /= Right.Registry_Order then
         return Left.Registry_Order < Right.Registry_Order;
      else
         return L_Label < R_Label;
      end if;
   end Candidate_Less;

   procedure Sort_Candidates
     (Candidates : in out Editor.Commands.Command_Palette_Candidate_Vectors.Vector)
   is
      J : Natural;
      V : Editor.Commands.Command_Palette_Candidate;
   begin
      if Candidates.Length < 2 then
         return;
      end if;

      for I in 1 .. Natural (Candidates.Length) - 1 loop
         V := Candidates.Element (I);
         J := I;
         while J > 0 and then Candidate_Less (V, Candidates.Element (J - 1)) loop
            Candidates.Replace_Element (J, Candidates.Element (J - 1));
            J := J - 1;
         end loop;
         Candidates.Replace_Element (J, V);
      end loop;
   end Sort_Candidates;


   function Common_User_Term_Score
     (Stable_Name    : String;
      Category_Label : String;
      Query          : String) return Natural
   is
      Stable : constant String := Lower (Stable_Name);
      Cat    : constant String := Lower (Category_Label);
      Q      : constant String := Lower (Query);

      function Starts_With (Text, Prefix : String) return Boolean is
      begin
         return Prefix'Length <= Text'Length
           and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
      end Starts_With;
   begin
      if Q'Length = 0 then
         return 0;
      elsif Q = "run tests" or else Q = "run test"
        or else Q = "test project" or else Q = "project tests"
      then
         if Stable = "project.test" then
            return 900;
         elsif Stable = "build.run" then
            return 520;
         elsif Ada.Strings.Fixed.Index (Stable, "test") /= 0 then
            return 260;
         end if;
      elsif Q = "compile" or else Q = "make" or else Q = "run build" then
         if Stable = "build.run" then
            return 900;
         elsif Starts_With (Stable, "build.") then
            return 300;
         end if;
      elsif Q = "open file" or else Q = "find file"
        or else Q = "quick open" or else Q = "go to file"
      then
         if Stable = "quick-open.show" then
            return 900;
         elsif Starts_With (Stable, "quick-open.")
           or else Starts_With (Stable, "file-tree.")
         then
            return 260;
         end if;
      elsif Q = "show diagnostics" or else Q = "show problems"
        or else Q = "open diagnostics" or else Q = "open problems"
        or else Q = "issues" or else Q = "show issues"
      then
         if Stable = "diagnostics.show" then
            return 900;
         elsif Stable = "problems.focus" then
            return 700;
         elsif Starts_With (Stable, "diagnostics.")
           or else Starts_With (Stable, "problems.")
         then
            return 260;
         end if;
      elsif Q = "filter errors" or else Q = "only errors" then
         if Stable = "problems.filter.errors" then
            return 900;
         elsif Starts_With (Stable, "problems.") then
            return 300;
         end if;
      elsif Q = "sort problems" or else Q = "sort diagnostics" then
         if Stable = "problems.sort.severity" then
            return 900;
         elsif Starts_With (Stable, "problems.sort.") then
            return 300;
         end if;
      elsif Q = "group problems" or else Q = "group diagnostics" then
         if Stable = "problems.group.source" then
            return 900;
         elsif Starts_With (Stable, "problems.group.") then
            return 300;
         end if;
      elsif Q = "refresh project" or else Q = "reload project"
        or else Q = "refresh files" or else Q = "refresh file tree"
      then
         if Stable = "file-tree.refresh" then
            return 900;
         elsif Starts_With (Stable, "file-tree.")
         then
            return 520;
         elsif Ada.Strings.Fixed.Index (Stable, "refresh") /= 0 then
            return 260;
         end if;
      elsif Q = "restore workspace" or else Q = "restore session"
        or else Q = "open session" or else Q = "open workspace"
        or else Q = "load workspace"
      then
         if Stable = "workspace.restore" then
            return 900;
         elsif Starts_With (Stable, "workspace.") then
            return 260;
         end if;
      elsif Q = "open" then
         if Stable = "project.open" then
            return 700;
         elsif Ada.Strings.Fixed.Index (Stable, "open") /= 0
           or else Starts_With (Stable, "quick-open.")
         then
            return 260;
         end if;
      elsif Q = "command" or else Q = "palette" or else Q = "commands" then
         if Stable = "command-palette.open"
           or else Stable = "open-command-palette"
           or else Starts_With (Stable, "command-palette.")
         then
            return 260;
         end if;
      elsif Q = "save" then
         if Stable = "file.save" then
            return 700;
         elsif Ada.Strings.Fixed.Index (Stable, "save") /= 0 then
            return 260;
         end if;
      elsif Q = "file" or else Q = "files" or else Q = "tree" then
         if Stable = "quick-open.show" then
            return 700;
         elsif Starts_With (Stable, "file-tree.")
           or else Starts_With (Stable, "quick-open.")
           or else Cat = "file"
         then
            return 260;
         end if;
      elsif Q = "build" then
         if Stable = "build.run" then
            return 700;
         elsif Starts_With (Stable, "build.") or else Cat = "build" then
            return 260;
         end if;
      elsif Q = "run" then
         if Stable = "project.run" then
            return 700;
         elsif Stable = "build.run"
           or else Stable = "terminal.run-selected-task"
         then
            return 520;
         elsif Ada.Strings.Fixed.Index (Stable, "run") /= 0 then
            return 260;
         end if;
      elsif Q = "test" or else Q = "tests" then
         if Stable = "project.test" then
            return 700;
         elsif Ada.Strings.Fixed.Index (Stable, "test") /= 0 then
            return 260;
         end if;
      elsif Q = "terminal" or else Q = "task" or else Q = "tasks" then
         if Stable = "terminal.show" then
            return 700;
         elsif Stable = "terminal.run-selected-task" then
            return 520;
         elsif Starts_With (Stable, "terminal.") then
            return 260;
         end if;
      elsif Q = "rename" or else Q = "refactor" then
         if Stable = "semantic.rename-symbol-preview" then
            return 700;
         elsif Stable = "semantic.rename-symbol-apply"
           or else Stable = "file.rename-buffer-file"
           or else Stable = "file-tree.rename-selected"
         then
            return 520;
         elsif Ada.Strings.Fixed.Index (Stable, "rename") /= 0 then
            return 260;
         end if;
      elsif Q = "format" or else Q = "formatter" then
         if Stable = "edit.format-buffer" then
            return 700;
         elsif Starts_With (Stable, "edit.format.")
           or else Ada.Strings.Fixed.Index (Stable, "format") /= 0
         then
            return 260;
         end if;
      elsif Q = "search" or else Q = "find" then
         if Stable = "project.search.show" then
            return 700;
         elsif Stable = "project.search.run"
           or else Stable = "project.search.query.clear"
         then
            return 520;
         elsif Starts_With (Stable, "project-search.")
           or else Starts_With (Stable, "search-results.")
           or else Starts_With (Stable, "project.search.")
           or else Cat = "search"
         then
            return 260;
         end if;
      elsif Q = "outline" or else Q = "symbol" or else Q = "symbols" then
         if Stable = "outline.refresh" then
            return 700;
         elsif Starts_With (Stable, "outline.") or else Cat = "outline" then
            return 260;
         end if;
      elsif Q = "diagnostic" or else Q = "diagnostics"
        or else Q = "problem" or else Q = "problems"
      then
         if Stable = "diagnostics.show" then
            return 700;
         elsif (Q = "problem" or else Q = "problems")
           and then Starts_With (Stable, "problems.filter.")
         then
            return 520;
         elsif Starts_With (Stable, "diagnostics.")
           or else Starts_With (Stable, "problems.")
         then
            return 260;
         end if;
      elsif Q = "error" or else Q = "errors" then
         if Stable = "problems.filter.errors"
           or else Stable = "diagnostics.filter-errors"
         then
            return 700;
         elsif Starts_With (Stable, "problems.")
           or else Starts_With (Stable, "diagnostics.")
         then
            return 260;
         end if;
      elsif Q = "warning" or else Q = "warnings" then
         if Stable = "problems.filter.warnings"
           or else Stable = "diagnostics.filter-warnings"
         then
            return 700;
         elsif Starts_With (Stable, "problems.")
           or else Starts_With (Stable, "diagnostics.")
         then
            return 260;
         end if;
      elsif Q = "info" or else Q = "information" or else Q = "notes" then
         if Stable = "problems.filter.info"
           or else Stable = "diagnostics.filter-info-notes"
         then
            return 700;
         elsif Starts_With (Stable, "problems.")
           or else Starts_With (Stable, "diagnostics.")
         then
            return 260;
         end if;
      elsif Q = "hint" or else Q = "hints" then
         if Stable = "problems.filter.hints" then
            return 700;
         elsif Starts_With (Stable, "problems.")
           or else Starts_With (Stable, "diagnostics.")
         then
            return 260;
         end if;
      elsif Q = "buffer" or else Q = "buffers" then
         if Starts_With (Stable, "buffer-switcher.")
           or else Stable = "switch-buffer"
           or else Cat = "buffers"
         then
            return 260;
         end if;
      elsif Q = "navigation" or else Q = "navigate"
        or else Q = "back" or else Q = "forward"
      then
         if Stable = "navigation.back" then
            return 700;
         elsif Starts_With (Stable, "navigation.") or else Cat = "navigation" then
            return 260;
         end if;
      elsif Q = "workspace" or else Q = "session" then
         if Stable = "workspace.save"
           or else Ada.Strings.Fixed.Index (Stable, "save-workspace-state") /= 0
         then
            return 700;
         elsif Stable = "workspace.restore" then
            return 520;
         elsif Starts_With (Stable, "workspace.")
           or else Ada.Strings.Fixed.Index (Stable, "workspace") /= 0
         then
            return 260;
         end if;
      elsif Q = "restore" then
         if Stable = "workspace.restore" then
            return 700;
         elsif Stable = "configuration.recover-show"
           or else Stable = "startup.show-summary"
           or else Stable = "configuration.audit"
         then
            return 520;
         elsif Ada.Strings.Fixed.Index (Stable, "restore") /= 0
           or else Ada.Strings.Fixed.Index (Stable, "recover") /= 0
         then
            return 260;
         end if;
      elsif Q = "recovery" or else Q = "recover" then
         if Stable = "configuration.recover-show" then
            return 700;
         elsif Stable = "workspace.restore"
           or else Stable = "startup.show-summary"
           or else Stable = "configuration.audit"
         then
            return 520;
         elsif Ada.Strings.Fixed.Index (Stable, "recover") /= 0
           or else Ada.Strings.Fixed.Index (Stable, "restore") /= 0
         then
            return 260;
         end if;
      elsif Q = "setting" or else Q = "settings"
        or else Q = "preference" or else Q = "preferences"
      then
         if Stable = "configuration.reset-settings"
           or else Ada.Strings.Fixed.Index (Stable, "reset-settings") /= 0
         then
            return 700;
         elsif Stable = "configuration.reset-keybindings"
           or else Ada.Strings.Fixed.Index (Stable, "reset-keybindings") /= 0
         then
            return 520;
         elsif Cat = "settings" or else Ada.Strings.Fixed.Index (Stable, "settings") /= 0 then
            return 260;
         end if;
      end if;

      return 0;
   end Common_User_Term_Score;

   function Metadata_Match_Score
     (Label          : String;
      Stable_Name    : String;
      Category_Label : String;
      Description    : String;
      Keybinding     : String;
      Query          : String) return Natural
   is
      Label_Score : constant Natural :=
        Match_Score (Label, Category_Label, Description, Query);
      Stable_Id_Score : constant Natural :=
        Match_Score (Stable_Name, "", "", Query);
      Keybinding_Score : constant Natural :=
        (if (not Current_Config.Show_Keybindings)
           or else Keybinding'Length = 0
         then 0
         else Natural'Min
           (150, Match_Score (Keybinding, "", "", Query)));
      User_Term_Score : constant Natural :=
        Common_User_Term_Score
          (Stable_Name, Category_Label, Query);
   begin
      return Natural'Max
        (Natural'Max
           (Natural'Max (Label_Score, Stable_Id_Score), Keybinding_Score),
         User_Term_Score);
   end Metadata_Match_Score;

   function Descriptor_Match_Score
     (Descriptor : Editor.Commands.Command_Descriptor;
      Query      : String) return Natural
   is
      Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command (Descriptor.Id);
   begin
      return Metadata_Match_Score
        (Label          => To_String (Descriptor.Name),
         Stable_Name    => Editor.Commands.Stable_Command_Name (Descriptor.Id),
         Category_Label => Editor.Commands.Discoverability_Category_Label
           (Descriptor.Id),
         Description    => To_String (Descriptor.Description),
         Keybinding     => To_String (Binding.Display),
         Query          => Query);
   end Descriptor_Match_Score;

   function Matches_Query
     (Descriptor : Editor.Commands.Command_Descriptor;
      Query      : String) return Boolean
   is
   begin
      return Descriptor_Match_Score (Descriptor, Query) > 0;
   end Matches_Query;

   procedure Set_Selected_From_Descriptor_Vector
     (Descriptors : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Index       : Natural)
   is
   begin
      if Descriptors.Length = 0 or else Index >= Natural (Descriptors.Length) then
         State.Selected_Item := 0;
         State.Selected_Candidate_Index := 0;
         State.Selected_Command_Id := Editor.Commands.No_Command;
      else
         State.Selected_Item := Index;
         State.Selected_Candidate_Index := Index;
         State.Selected_Command_Id := Descriptors.Element (Index).Id;
      end if;
   end Set_Selected_From_Descriptor_Vector;

   procedure Set_Selected_From_Candidate_Vector
     (Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Index      : Natural)
   is
   begin
      if Candidates.Length = 0 or else Index >= Natural (Candidates.Length) then
         State.Selected_Item := 0;
         State.Selected_Candidate_Index := 0;
         State.Selected_Command_Id := Editor.Commands.No_Command;
      else
         State.Selected_Item := Index;
         State.Selected_Candidate_Index := Index;
         State.Selected_Command_Id := Candidates.Element (Index).Id;
      end if;
   end Set_Selected_From_Candidate_Vector;

   procedure Reconcile_Selection
     (Candidates             : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Preferred_Command      : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Prefer_First_Available : Boolean := True)
   is
      Preferred : constant Editor.Commands.Command_Id :=
        (if Preferred_Command /= Editor.Commands.No_Command
         then Preferred_Command
         else State.Selected_Command_Id);
      Visible : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Visible_Candidates (Candidates, Visible);

      if Visible.Length = 0 then
         State.Selected_Item := 0;
         State.Selected_Candidate_Index := 0;
         State.Selected_Command_Id := Editor.Commands.No_Command;
         return;
      end if;

      if Preferred /= Editor.Commands.No_Command then
         for I in 0 .. Natural (Visible.Length) - 1 loop
            if Visible.Element (I).Id = Preferred then
               Set_Selected_From_Candidate_Vector (Visible, I);
               return;
            end if;
         end loop;
      end if;

      if Prefer_First_Available then
         for I in 0 .. Natural (Visible.Length) - 1 loop
            if Visible.Element (I).Available then
               Set_Selected_From_Candidate_Vector (Visible, I);
               return;
            end if;
         end loop;
      end if;

      Set_Selected_From_Candidate_Vector (Visible, 0);
   end Reconcile_Selection;

   procedure Clamp_Selection is
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Preferred : constant Editor.Commands.Command_Id := State.Selected_Command_Id;
   begin
      Filtered_Commands (Filtered);

      if Filtered.Length = 0 then
         Set_Selected_From_Descriptor_Vector (Filtered, 0);
         return;
      end if;

      if Preferred /= Editor.Commands.No_Command then
         for I in 0 .. Natural (Filtered.Length) - 1 loop
            if Filtered.Element (I).Id = Preferred then
               Set_Selected_From_Descriptor_Vector (Filtered, I);
               return;
            end if;
         end loop;
      end if;

      if State.Selected_Item >= Natural (Filtered.Length) then
         Set_Selected_From_Descriptor_Vector
           (Filtered, Natural (Filtered.Length) - 1);
      else
         Set_Selected_From_Descriptor_Vector (Filtered, State.Selected_Item);
      end if;
   end Clamp_Selection;

   function Current return Palette_State is
   begin
      return State;
   end Current;

   procedure Reset is
   begin
      State.Open := False;
      State.Query := Null_Unbounded_String;
      Editor.Input_Field.Clear (Filter_Field);
      State.Selected_Item := 0;
      State.Selected_Candidate_Index := 0;
      State.Selected_Command_Id := Editor.Commands.No_Command;
      State.Top_Row := 1;
      Config_State := (others => <>);
      Clear_Transient_Filters;
      Clear_Command_State_Contexts;
   end Reset;

   procedure Open is
   begin
      State.Open := True;
      State.Query := Null_Unbounded_String;
      Editor.Input_Field.Clear (Filter_Field);
      State.Selected_Item := 0;
      State.Selected_Candidate_Index := 0;
      State.Selected_Command_Id := Editor.Commands.No_Command;
      State.Top_Row := 1;
      Config_State.Show_Help_Row := False;
      Clear_Transient_Filters;
      Clear_Command_State_Contexts;
   end Open;

   procedure Open_With_Command
     (Command : Editor.Commands.Command_Id)
   is
      D : Editor.Commands.Command_Descriptor;
   begin
      if Command = Editor.Commands.No_Command then
         Open;
         return;
      end if;

      D := Editor.Commands.Descriptor (Command);
      if D.Visibility /= Editor.Commands.Palette_Command then
         Open;
         return;
      end if;

      State.Open := True;
      State.Query := To_Unbounded_String (Editor.Commands.Stable_Command_Name (Command));
      Editor.Input_Field.Clear (Filter_Field);
      Editor.Input_Field.Insert_Text (Filter_Field, To_String (State.Query));
      State.Selected_Item := 0;
      State.Selected_Candidate_Index := 0;
      State.Selected_Command_Id := Command;
      State.Top_Row := 1;
      Config_State.Show_Help_Row := False;
      Clear_Transient_Filters;
   end Open_With_Command;

   procedure Close is
   begin
      State.Open := False;
      State.Query := Null_Unbounded_String;
      Editor.Input_Field.Clear (Filter_Field);
      State.Selected_Item := 0;
      State.Selected_Candidate_Index := 0;
      State.Selected_Command_Id := Editor.Commands.No_Command;
      State.Top_Row := 1;
      Config_State.Show_Help_Row := False;
      Clear_Transient_Filters;
   end Close;

   procedure Toggle is
   begin
      if State.Open then
         Close;
      else
         Open;
      end if;
   end Toggle;

   function Is_Open return Boolean is
   begin
      return State.Open;
   end Is_Open;

   procedure Append_Character
     (Ch : Character)
   is
   begin
      if Ch >= ' ' and then Ch <= '~' then
         Editor.Input_Field.Insert_Text (Filter_Field, String'(1 => Ch));
         Sync_Query;
         Clamp_Selection;
      end if;
   end Append_Character;

   procedure Insert_Text
     (Text : String) is
   begin
      Editor.Input_Field.Insert_Text (Filter_Field, Text);
      Sync_Query;
      Clamp_Selection;
   end Insert_Text;

   procedure Backspace is
   begin
      Editor.Input_Field.Backspace (Filter_Field);
      Sync_Query;
      Clamp_Selection;
   end Backspace;

   procedure Delete_Forward is
   begin
      Editor.Input_Field.Delete_Forward (Filter_Field);
      Sync_Query;
      Clamp_Selection;
   end Delete_Forward;

   function Query_Snapshot
     (Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot is
   begin
      return Editor.Input_Field.Snapshot (Filter_Field, Visible_Columns);
   end Query_Snapshot;

   procedure Move_Cursor_Left is
   begin
      Editor.Input_Field.Move_Cursor_Left (Filter_Field);
   end Move_Cursor_Left;

   procedure Move_Cursor_Right is
   begin
      Editor.Input_Field.Move_Cursor_Right (Filter_Field);
   end Move_Cursor_Right;

   procedure Move_Cursor_Start is
   begin
      Editor.Input_Field.Move_Cursor_Start (Filter_Field);
   end Move_Cursor_Start;

   procedure Move_Cursor_End is
   begin
      Editor.Input_Field.Move_Cursor_End (Filter_Field);
   end Move_Cursor_End;

   procedure Select_All is
   begin
      Editor.Input_Field.Select_All (Filter_Field);
   end Select_All;

   procedure Set_Cursor_From_Visible_Column
     (Visible_Column  : Natural;
      Visible_Columns : Natural) is
   begin
      Editor.Input_Field.Set_Cursor_From_Visible_Column
        (Filter_Field, Visible_Column, Visible_Columns);
   end Set_Cursor_From_Visible_Column;

   function Query_Cursor return Natural is
   begin
      return Editor.Input_Field.Cursor_Column (Filter_Field);
   end Query_Cursor;

   procedure Move_Selection_By (Amount : Integer) is
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
      Last     : Natural;
      Next     : Integer;
   begin
      Filtered_Commands (Filtered);
      if Filtered.Length = 0 then
         Set_Selected_From_Descriptor_Vector (Filtered, 0);
         return;
      end if;

      Last := Natural (Filtered.Length) - 1;
      Next := Integer (State.Selected_Item) + Amount;
      if Next < 0 then
         Next := 0;
      elsif Next > Integer (Last) then
         Next := Integer (Last);
      end if;
      Set_Selected_From_Descriptor_Vector (Filtered, Natural (Next));
   end Move_Selection_By;

   procedure Move_Selection_Up is
   begin
      Move_Selection_By (-1);
   end Move_Selection_Up;

   procedure Move_Selection_Down is
   begin
      Move_Selection_By (1);
   end Move_Selection_Down;

   procedure Move_Selection_By_Candidates
     (Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Amount     : Integer)
   is
      Visible : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Last    : Natural;
      Next    : Integer;
   begin
      Visible_Candidates (Candidates, Visible);
      if Visible.Length = 0 then
         Set_Selected_From_Candidate_Vector (Visible, 0);
         return;
      end if;

      Last := Natural (Visible.Length) - 1;
      if State.Selected_Command_Id /= Editor.Commands.No_Command then
         for I in 0 .. Natural (Visible.Length) - 1 loop
            if Visible.Element (I).Id = State.Selected_Command_Id then
               State.Selected_Item := I;
               exit;
            end if;
         end loop;
      end if;

      Next := Integer (State.Selected_Item) + Amount;
      if Next < 0 then
         Next := 0;
      elsif Next > Integer (Last) then
         Next := Integer (Last);
      end if;
      Set_Selected_From_Candidate_Vector (Visible, Natural (Next));
   end Move_Selection_By_Candidates;

   procedure Select_First is
   begin
      declare
         Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
      begin
         Filtered_Commands (Filtered);
         Set_Selected_From_Descriptor_Vector (Filtered, 0);
      end;
   end Select_First;

   procedure Select_Last is
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
   begin
      Filtered_Commands (Filtered);
      if Filtered.Length = 0 then
         Select_First;
      else
         Set_Selected_From_Descriptor_Vector
           (Filtered, Natural (Filtered.Length) - 1);
      end if;
   end Select_Last;

   procedure Filtered_Commands
     (Result : out Editor.Commands.Command_Descriptor_Vectors.Vector)
   is
      All_Commands : constant Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
      Q : constant String := To_String (State.Query);
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      --  command-palette search includes active keybinding labels.
      --  Keybindings are intentionally not a persisted palette cache input and
      --  can change while the query text stays the same, so this projection must
      --  be rebuilt on each request instead of reusing the older query-only
      --  descriptor cache.
      Result.Clear;
      for D of All_Commands loop
         declare
            Score : constant Natural := Descriptor_Match_Score (D, Q);
         begin
            if Score > 0 and then Descriptor_Passes_Transient_Metadata_Filters (D) then
               declare
                  Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
                    Editor.Keybindings.Primary_Binding_For_Command (D.Id);
               begin
                  Candidates.Append
                    (Editor.Commands.Command_Palette_Candidate'
                      (Id                 => D.Id,
                      Label              => D.Name,
                      Description        => D.Description,
                      Category           => D.Category,
                      Category_Label     => To_Unbounded_String
                        (Editor.Commands.Discoverability_Category_Label (D.Id)),
                      Available          => True,
                      Reason             => Null_Unbounded_String,
                      Has_Keybinding     => D.Bindable and then Binding.Has_Binding,
                      Keybinding_Display => Binding.Display,
                      Reference_Summary  => D.Summary,
                      Family             => D.Family,
                      Effect_Classification => D.Effect_Classification,
                      Match_Score        => Score,
                      Registry_Order     => Descriptor_Registry_Order (D.Id)));
               end;
            end if;
         end;
      end loop;

      Sort_Candidates (Candidates);

      for C of Candidates loop
         Result.Append (Editor.Commands.Descriptor (C.Id));
      end loop;

   end Filtered_Commands;

   function Selected_Command return Editor.Commands.Command_Id is
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
   begin
      Filtered_Commands (Filtered);
      if Filtered.Length = 0 then
         return Editor.Commands.No_Command;
      elsif State.Selected_Item >= Natural (Filtered.Length) then
         return Filtered.Element (Natural (Filtered.Length) - 1).Id;
      else
         return Filtered.Element (State.Selected_Item).Id;
      end if;
   end Selected_Command;

   function Has_Selected_Command return Boolean is
      Filtered : Editor.Commands.Command_Descriptor_Vectors.Vector;
   begin
      Filtered_Commands (Filtered);
      return Filtered.Length > 0
        and then State.Selected_Item < Natural (Filtered.Length);
   end Has_Selected_Command;

   function Build_Snapshot
     (Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config     : Command_Palette_Config) return Command_Palette_Snapshot
   is
      Result : Command_Palette_Snapshot;
      Visible_Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Last_Category_Label : Unbounded_String := Null_Unbounded_String;
      Have_Category : Boolean := False;
      Query_Text : constant String := To_String (State.Query);
      Query_Is_Empty : constant Boolean := Query_Text'Length = 0;
      Grouped : constant Boolean := Query_Is_Empty and then Config.Group_Empty_Query_By_Category;
      Selected_Visible_Index : Natural := 0;
      Have_Selected_Visible_Index : Boolean := False;
      Has_Filtered_Candidate : Boolean := False;

      function Reason_For (C : Editor.Commands.Command_Palette_Candidate) return Unbounded_String is
      begin
         if C.Available then
            return Null_Unbounded_String;
         elsif Length (C.Reason) > 0 then
            return C.Reason;
         else
            return To_Unbounded_String ("Command not available here");
         end if;
      end Reason_For;

      function Selected_Secondary (C : Editor.Commands.Command_Palette_Candidate)
        return Unbounded_String is
      begin
         if not C.Available and then Config.Show_Selected_Reason then
            return Reason_For (C);
         elsif C.Available and then Config.Show_Selected_Description then
            return C.Description;
         else
            return Null_Unbounded_String;
         end if;
      end Selected_Secondary;

      function Candidate_Visible_For_Config
        (C : Editor.Commands.Command_Palette_Candidate) return Boolean is
      begin
         return Candidate_Passes_Transient_Filters (C)
           and then (Config.Show_Unavailable_Commands or else C.Available);
      end Candidate_Visible_For_Config;
   begin
      for C of Candidates loop
         if Candidate_Passes_Transient_Filters (C) then
            Has_Filtered_Candidate := True;
            if Candidate_Visible_For_Config (C) then
               Visible_Candidates.Append (C);
            end if;
         end if;
      end loop;

      Result.Candidates := Visible_Candidates;

      if Visible_Candidates.Length > 0 then
         if State.Selected_Command_Id /= Editor.Commands.No_Command then
            for I in 0 .. Natural (Visible_Candidates.Length) - 1 loop
               if Visible_Candidates.Element (I).Id = State.Selected_Command_Id then
                  Selected_Visible_Index := I;
                  Have_Selected_Visible_Index := True;
                  exit;
               end if;
            end loop;
         end if;

         if not Have_Selected_Visible_Index then
            if State.Selected_Item < Natural (Visible_Candidates.Length) then
               Selected_Visible_Index := State.Selected_Item;
            else
               Selected_Visible_Index := Natural (Visible_Candidates.Length) - 1;
            end if;
            Have_Selected_Visible_Index := True;
         end if;
      end if;

      if Visible_Candidates.Length = 0 then
         declare
            Empty_Text : constant Unbounded_String :=
              To_Unbounded_String
                ((if Has_Filtered_Candidate and then not Config.Show_Unavailable_Commands
                  then
                    (if Query_Is_Empty
                     then "No available commands"
                     else "No available commands match " & '"' & Query_Text & '"')
                  elsif Query_Is_Empty
                  then "No commands"
                  else "No commands match " & '"' & Query_Text & '"'));
         begin
            Result.Rows.Append
              (Command_Palette_Row'
                (Kind                   => Command_Palette_Empty_Row,
                Candidate_Index        => 0,
                Category               => Editor.Commands.Internal_Category,
                Primary_Text           => Empty_Text,
                Secondary_Text         =>
                  To_Unbounded_String
                    ((if Query_Is_Empty
                      then Editor.Contextual_Help.Command_Palette_No_Match_Detail (True)
                      else Editor.Contextual_Help.Command_Palette_No_Match_Detail (False))),
                Keybinding_Text        => Null_Unbounded_String,
                Has_Keybinding         => False,
                Is_Selected            => False,
                Is_Available           => True,
                Is_Detail_For_Selected => False));
         end;
         return Result;
      end if;

      if Query_Is_Empty and then Config.Show_Help_Row
        and then Config.Max_Visible_Rows > 3
      then
         declare
            Help_Text : constant Unbounded_String :=
              To_Unbounded_String ("Type to search commands");
         begin
            Result.Rows.Append
              (Command_Palette_Row'
                (Kind                   => Command_Palette_Help_Row,
                Candidate_Index        => 0,
                Category               => Editor.Commands.Internal_Category,
                Primary_Text           => Help_Text,
                Secondary_Text         => Null_Unbounded_String,
                Keybinding_Text        => Null_Unbounded_String,
                Has_Keybinding         => False,
                Is_Selected            => False,
                Is_Available           => True,
                Is_Detail_For_Selected => False));
         end;
      end if;

      for I in 0 .. Natural (Visible_Candidates.Length) - 1 loop
         declare
            C : constant Editor.Commands.Command_Palette_Candidate := Visible_Candidates.Element (I);
            Selected : constant Boolean :=
              Have_Selected_Visible_Index and then I = Selected_Visible_Index;
            Secondary : constant Unbounded_String :=
              (if Selected then Selected_Secondary (C) else Null_Unbounded_String);
         begin
            if Grouped
                 and then (not Have_Category
                           or else C.Category_Label /= Last_Category_Label)
               then
                  Result.Rows.Append
              (Command_Palette_Row'
                (Kind                   => Command_Palette_Header_Row,
                      Candidate_Index        => 0,
                      Category               => C.Category,
                      Primary_Text           => C.Category_Label,
                      Secondary_Text         => Null_Unbounded_String,
                      Keybinding_Text        => Null_Unbounded_String,
                      Has_Keybinding         => False,
                      Is_Selected            => False,
                      Is_Available           => True,
                      Is_Detail_For_Selected => False));
                  Last_Category_Label := C.Category_Label;
                  Have_Category := True;
               end if;

               Result.Rows.Append
              (Command_Palette_Row'
                (Kind                   => Command_Palette_Command_Row,
                   Candidate_Index        => I,
                   Category               => C.Category,
                   Primary_Text           => C.Label,
                   Secondary_Text         => Secondary,
                   Keybinding_Text        =>
                     (if Config.Show_Keybindings then C.Keybinding_Display else Null_Unbounded_String),
                   Has_Keybinding         => Config.Show_Keybindings and then C.Has_Keybinding,
                   Is_Selected            => Selected,
                   Is_Available           => C.Available,
                   Is_Detail_For_Selected => False));

               if Selected and then Config.Show_Help_Row then
                  declare
                     Help : constant Command_Help_Snapshot := Build_Command_Help (C);
                     Surface_Text : constant Unbounded_String :=
                       (if Length (Help.Surface_Relevance_Label) > 0
                        then To_Unbounded_String (" | surface: ")
                          & Help.Surface_Relevance_Label
                        else Null_Unbounded_String);
                     Keybinding_Text : constant Unbounded_String :=
                       (if Config.Show_Keybindings
                        then Help.Keybinding_Label
                        else To_Unbounded_String ("Keybindings hidden"));
                     Help_Text : constant Unbounded_String :=
                       Help.Stable_Name & " | "
                       & Help.Category_Label & " | "
                       & Keybinding_Text & " | "
                       & Help.Availability_Label & " | "
                       & Help.Classification_Label
                       & Surface_Text;
                     Help_Detail : constant Unbounded_String :=
                       (if Length (Help.Unavailable_Reason) > 0
                        then Help.Description & " - " & Help.Unavailable_Reason
                          & " - " & Help.Guard_Label
                        else Help.Description & " - " & Help.Guard_Label);
                  begin
                     Result.Rows.Append
              (Command_Palette_Row'
                (Kind                   => Command_Palette_Help_Row,
                         Candidate_Index        => I,
                         Category               => C.Category,
                                  Primary_Text           => Help_Text,
                         Secondary_Text         => Help_Detail,
                         Keybinding_Text        => Null_Unbounded_String,
                         Has_Keybinding         => False,
                         Is_Selected            => False,
                         Is_Available           => C.Available,
                         Is_Detail_For_Selected => True));

                     if Length (Help.State_Context_Label) > 0 then
                        Result.Rows.Append
              (Command_Palette_Row'
                (Kind                   => Command_Palette_State_Context_Row,
                         Candidate_Index        => I,
                         Category               => C.Category,
                                  Primary_Text           =>
                                    To_Unbounded_String ("State"),
                         Secondary_Text         => Help.State_Context_Label,
                         Keybinding_Text        => Null_Unbounded_String,
                         Has_Keybinding         => False,
                         Is_Selected            => False,
                         Is_Available           => C.Available,
                         Is_Detail_For_Selected => True));
                     end if;
                  end;
               end if;
         end;
      end loop;

      if Result.Rows.Length = 0 then
         declare
            Empty_Text : constant Unbounded_String :=
              To_Unbounded_String
                ((if Query_Is_Empty
                  then "No available commands"
                  else "No available commands match " & '"' & Query_Text & '"'));
         begin
            Result.Rows.Append
              (Command_Palette_Row'
                (Kind                   => Command_Palette_Empty_Row,
                Candidate_Index        => 0,
                Category               => Editor.Commands.Internal_Category,
                Primary_Text           => Empty_Text,
                Secondary_Text         =>
                  To_Unbounded_String
                    ((if Query_Is_Empty
                      then Editor.Contextual_Help.Command_Palette_No_Match_Detail (True)
                      else Editor.Contextual_Help.Command_Palette_No_Match_Detail (False))),
                Keybinding_Text        => Null_Unbounded_String,
                Has_Keybinding         => False,
                Is_Selected            => False,
                Is_Available           => True,
                Is_Detail_For_Selected => False));
         end;
      end if;

      return Result;
   end Build_Snapshot;

   function Row_Count
     (Snapshot : Command_Palette_Snapshot) return Natural is
   begin
      return Natural (Snapshot.Rows.Length);
   end Row_Count;

   function Row
     (Snapshot : Command_Palette_Snapshot;
      Index    : Positive) return Command_Palette_Row is
   begin
      pragma Assert (Index <= Row_Count (Snapshot),
                     "Editor.Command_Palette.Row index out of range");
      return Snapshot.Rows.Element (Index - 1);
   end Row;

   function Candidate_Count
     (Snapshot : Command_Palette_Snapshot) return Natural is
   begin
      return Natural (Snapshot.Candidates.Length);
   end Candidate_Count;

   function Candidate
     (Snapshot : Command_Palette_Snapshot;
      Index    : Natural) return Editor.Commands.Command_Palette_Candidate is
   begin
      pragma Assert (Index < Candidate_Count (Snapshot),
                     "Editor.Command_Palette.Candidate index out of range");
      return Snapshot.Candidates.Element (Index);
   end Candidate;

   function Candidate_For_Row
     (Snapshot  : Command_Palette_Snapshot;
      Row_Index : Natural;
      Found     : out Boolean) return Natural
   is
   begin
      if Row_Index = 0 or else Row_Index > Row_Count (Snapshot) then
         Found := False;
         return 0;
      end if;

      declare
         R : constant Command_Palette_Row := Snapshot.Rows.Element (Row_Index - 1);
      begin
         Found := R.Kind = Command_Palette_Command_Row;
         return R.Candidate_Index;
      end;
   end Candidate_For_Row;

   function Row_For_Candidate
     (Snapshot        : Command_Palette_Snapshot;
      Candidate_Index : Natural;
      Found           : out Boolean) return Natural
   is
   begin
      for I in 0 .. Natural (Snapshot.Rows.Length) - 1 loop
         declare
            R : constant Command_Palette_Row := Snapshot.Rows.Element (I);
         begin
            if R.Kind = Command_Palette_Command_Row
              and then R.Candidate_Index = Candidate_Index
            then
               Found := True;
               return I + 1;
            end if;
         end;
      end loop;
      Found := False;
      return 0;
   end Row_For_Candidate;

   procedure Ensure_Selected_Row_Visible
     (Snapshot          : Command_Palette_Snapshot;
      Visible_Row_Count : Natural)
   is
      Found : Boolean := False;
      Selected_Candidate : Natural := State.Selected_Item;
      Row_Index : Natural := 0;
      Max_Top : Natural := 1;
   begin
      --  snapshot selection may be resolved by stable command id
      --  after transient filters hide or reorder candidates.  Viewport
      --  reconciliation must therefore follow the rendered selected row, not
      --  a stale numeric state index that might point at a different visible
      --  command.
      for I in 0 .. Natural (Snapshot.Rows.Length) - 1 loop
         declare
            R : constant Command_Palette_Row := Snapshot.Rows.Element (I);
         begin
            if R.Kind = Command_Palette_Command_Row and then R.Is_Selected then
               Selected_Candidate := R.Candidate_Index;
               exit;
            end if;
         end;
      end loop;

      Row_Index := Row_For_Candidate (Snapshot, Selected_Candidate, Found);
      if Row_Count (Snapshot) = 0 or else Visible_Row_Count = 0 then
         State.Top_Row := 1;
         return;
      end if;

      Max_Top :=
        (if Row_Count (Snapshot) > Visible_Row_Count
         then Row_Count (Snapshot) - Visible_Row_Count + 1
         else 1);

      if not Found then
         State.Top_Row := Natural'Min (State.Top_Row, Max_Top);
         State.Top_Row := Natural'Max (State.Top_Row, 1);
         return;
      end if;

      if Row_Index < State.Top_Row then
         State.Top_Row := Row_Index;
      elsif Row_Index >= State.Top_Row + Visible_Row_Count then
         State.Top_Row := Row_Index - Visible_Row_Count + 1;
      end if;

      State.Top_Row := Natural'Min (State.Top_Row, Max_Top);
      State.Top_Row := Natural'Max (State.Top_Row, 1);
   end Ensure_Selected_Row_Visible;

   procedure Clamp_Viewport
     (Snapshot          : Command_Palette_Snapshot;
      Visible_Row_Count : Natural)
   is
      Count   : constant Natural := Row_Count (Snapshot);
      Max_Top : Natural := 1;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         State.Top_Row := 1;
         return;
      end if;

      if Count > Visible_Row_Count then
         Max_Top := Count - Visible_Row_Count + 1;
      end if;

      if State.Top_Row = 0 then
         State.Top_Row := 1;
      elsif State.Top_Row > Max_Top then
         State.Top_Row := Max_Top;
      end if;
   end Clamp_Viewport;

   procedure Scroll_By
     (Snapshot          : Command_Palette_Snapshot;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer)
   is
      Count   : constant Natural := Row_Count (Snapshot);
      Max_Top : Natural := 1;
      Desired : Integer := Integer (State.Top_Row) + Step_Delta;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         State.Top_Row := 1;
         return;
      end if;

      if Count > Visible_Row_Count then
         Max_Top := Count - Visible_Row_Count + 1;
      end if;

      if Desired < 1 then
         Desired := 1;
      elsif Desired > Integer (Max_Top) then
         Desired := Integer (Max_Top);
      end if;

      State.Top_Row := Natural (Desired);
   end Scroll_By;

end Editor.Command_Palette;
