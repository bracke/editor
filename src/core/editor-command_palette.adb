with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Palette_Model; use Editor.Commands.Palette_Model;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Contextual_Help;
with Editor.Input_Field;
with Editor.Keybindings;
with Editor.Text_Helpers;
with Editor.Command_Palette.Filters;
with Editor.Command_Palette.Guikit_Model;
with Editor.Command_Palette.Help;
with Editor.Command_Palette.Rows;
with Editor.Command_Palette.State;

with Editor.Commands.Name_Metadata;



package body Editor.Command_Palette is

   use type Editor.Command_Ids.Command_Id;
   use type Editor.Commands.Descriptors.Command_Category;
   use type Editor.Commands.Descriptors.Command_Visibility;

   Palette_State_Ref : constant Editor.Command_Palette.State.Palette_State_Access :=
     Editor.Command_Palette.State.Mutable_Palette_State;
   Config_State_Ref : constant Editor.Command_Palette.State.Command_Palette_Config_Access :=
     Editor.Command_Palette.State.Mutable_Config;
   Filter_Field_Ref : constant Editor.Command_Palette.State.Input_Field_State_Access :=
     Editor.Command_Palette.State.Mutable_Filter_Field;

   Palette_State_Store : Palette_State renames Palette_State_Ref.all;
   Config_State : Command_Palette_Config renames Config_State_Ref.all;
   Filter_Field : Editor.Input_Field.Input_Field_State renames Filter_Field_Ref.all;
   procedure Sync_Query is
   begin
      Palette_State_Store.Query := To_Unbounded_String (Editor.Input_Field.Text (Filter_Field));
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
      Editor.Command_Palette.Filters.Clear_Transient_Filters;
   end Clear_Transient_Filters;

   function Transient_State_Clear return Boolean is
   begin
      return (not Palette_State_Store.Open)
        and then Palette_State_Store.Selected_Item = 0
        and then Palette_State_Store.Selected_Candidate_Index = 0
        and then Palette_State_Store.Selected_Command_Id = Editor.Command_Ids.No_Command
        and then Palette_State_Store.Top_Row = 1
        and then not Config_State.Show_Help_Row
        and then Editor.Command_Palette.Filters.Transient_Filters_Clear;
   end Transient_State_Clear;

   procedure Set_Availability_Filter
     (Filter : Command_Palette_Availability_Filter) is
   begin
      Editor.Command_Palette.Filters.Set_Availability_Filter (Filter);
      Clamp_Selection;
   end Set_Availability_Filter;

   function Current_Availability_Filter
      return Command_Palette_Availability_Filter is
   begin
      return Editor.Command_Palette.Filters.Current_Availability_Filter;
   end Current_Availability_Filter;

   procedure Set_Category_Filter_Label (Label : String) is
   begin
      Editor.Command_Palette.Filters.Set_Category_Filter_Label (Label);
      Clamp_Selection;
   end Set_Category_Filter_Label;

   procedure Clear_Category_Filter is
   begin
      Editor.Command_Palette.Filters.Clear_Category_Filter;
      Clamp_Selection;
   end Clear_Category_Filter;

   function Has_Category_Filter return Boolean is
   begin
      return Editor.Command_Palette.Filters.Has_Category_Filter;
   end Has_Category_Filter;

   function Current_Category_Filter_Label return String is
   begin
      return Editor.Command_Palette.Filters.Current_Category_Filter_Label;
   end Current_Category_Filter_Label;

   procedure Set_Destructive_Filter (Enabled : Boolean) is
   begin
      Editor.Command_Palette.Filters.Set_Destructive_Filter (Enabled);
      Clamp_Selection;
   end Set_Destructive_Filter;

   function Destructive_Filter_Enabled return Boolean is
   begin
      return Editor.Command_Palette.Filters.Destructive_Filter_Enabled;
   end Destructive_Filter_Enabled;

   procedure Set_Keybinding_Filter
     (Filter : Command_Palette_Keybinding_Filter) is
   begin
      Editor.Command_Palette.Filters.Set_Keybinding_Filter (Filter);
      Clamp_Selection;
   end Set_Keybinding_Filter;

   function Current_Keybinding_Filter return Command_Palette_Keybinding_Filter is
   begin
      return Editor.Command_Palette.Filters.Current_Keybinding_Filter;
   end Current_Keybinding_Filter;

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Candidate_Passes_Transient_Filters
     (Candidate : Editor.Commands.Palette_Model.Command_Palette_Candidate) return Boolean
     renames Editor.Command_Palette.Filters.Candidate_Passes_Transient_Filters;

   function Candidate_Is_Currently_Visible
     (Candidate : Editor.Commands.Palette_Model.Command_Palette_Candidate) return Boolean
   is
   begin
      return Candidate_Passes_Transient_Filters (Candidate)
        and then (Config_State.Show_Unavailable_Commands or else Candidate.Available);
   end Candidate_Is_Currently_Visible;

   procedure Visible_Candidates
     (Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
      Result     : out Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector)
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
     (Descriptor : Editor.Commands.Descriptors.Command_Descriptor) return Boolean
     renames Editor.Command_Palette.Filters.Descriptor_Passes_Transient_Metadata_Filters;

   function Starts_With (Text, Prefix : String) return Boolean
     renames Editor.Text_Helpers.Starts_With;

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
      Max_Columns : Natural) return String renames
     Editor.Command_Palette.Rows.Truncate_With_Ellipsis;

   function Layout_Command_Row
     (Row_Width_Columns : Natural;
      Label_Length      : Natural;
      Secondary_Length  : Natural;
      Keybinding_Length : Natural;
      Is_Selected       : Boolean;
      Is_Available      : Boolean) return Command_Palette_Row_Layout renames
     Editor.Command_Palette.Rows.Layout_Command_Row;

   function Project_Command_Row_Layout
     (Candidate   : Editor.Commands.Palette_Model.Command_Palette_Candidate;
      Is_Selected : Boolean;
      Row_Columns : Natural) return Command_Palette_Row_Layout renames
     Editor.Command_Palette.Rows.Project_Command_Row_Layout;

   function Build_Command_Help
     (Candidate : Editor.Commands.Palette_Model.Command_Palette_Candidate)
      return Command_Help_Snapshot
   is
   begin
      return Editor.Command_Palette.Help.Build_Command_Help
        (Candidate, Config_State);
   end Build_Command_Help;

   procedure Clear_Command_State_Contexts renames
     Editor.Command_Palette.Help.Clear_Command_State_Contexts;

   procedure Set_Command_State_Context
     (Command : Editor.Command_Ids.Command_Id;
      Text    : String) renames
     Editor.Command_Palette.Help.Set_Command_State_Context;

   function Related_Command_Is_Activation_Safe
     (Item : Related_Command_Help_Item) return Boolean renames
     Editor.Command_Palette.Help.Related_Command_Is_Activation_Safe;

   function Related_Command_Is_Canonical_Descriptor_Projection
     (Item : Related_Command_Help_Item) return Boolean renames
     Editor.Command_Palette.Help.Related_Command_Is_Canonical_Descriptor_Projection;

   function Assert_Related_Command_Help_Is_Coherent
     (Help : Command_Help_Snapshot) return Boolean renames
     Editor.Command_Palette.Help.Assert_Related_Command_Help_Is_Coherent;

   function Descriptor_Registry_Order
     (Id : Editor.Command_Ids.Command_Id) return Natural
   is
   begin
      return Editor.Command_Ids.Command_Id'Pos (Id)
        - Editor.Command_Ids.Command_Id'Pos (Editor.Command_Ids.Command_Id'First);
   end Descriptor_Registry_Order;

   function Candidate_Less
     (Left  : Editor.Commands.Palette_Model.Command_Palette_Candidate;
      Right : Editor.Commands.Palette_Model.Command_Palette_Candidate) return Boolean
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
         return Editor.Commands.Descriptors.Command_Category'Pos (Left.Category)
           < Editor.Commands.Descriptors.Command_Category'Pos (Right.Category);
      elsif Left.Registry_Order /= Right.Registry_Order then
         return Left.Registry_Order < Right.Registry_Order;
      else
         return L_Label < R_Label;
      end if;
   end Candidate_Less;

   procedure Sort_Candidates
     (Candidates : in out Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector)
   is
      J : Natural;
      V : Editor.Commands.Palette_Model.Command_Palette_Candidate;
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

      function Starts_With (Text, Prefix : String) return Boolean
        renames Editor.Text_Helpers.Starts_With;
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
     (Descriptor : Editor.Commands.Descriptors.Command_Descriptor;
      Query      : String) return Natural
   is
      Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command (Descriptor.Id);
   begin
      return Metadata_Match_Score
        (Label          => To_String (Descriptor.Name),
         Stable_Name    => Editor.Commands.Name_Metadata.Stable_Command_Name (Descriptor.Id),
         Category_Label => Editor.Commands.Descriptors.Discoverability_Category_Label
           (Descriptor.Id),
         Description    => To_String (Descriptor.Description),
         Keybinding     => To_String (Binding.Display),
         Query          => Query);
   end Descriptor_Match_Score;

   function Matches_Query
     (Descriptor : Editor.Commands.Descriptors.Command_Descriptor;
      Query      : String) return Boolean
   is
   begin
      return Descriptor_Match_Score (Descriptor, Query) > 0;
   end Matches_Query;

   procedure Set_Selected_From_Descriptor_Vector
     (Descriptors : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
      Index       : Natural)
   is
   begin
      if Descriptors.Length = 0 or else Index >= Natural (Descriptors.Length) then
         Palette_State_Store.Selected_Item := 0;
         Palette_State_Store.Selected_Candidate_Index := 0;
         Palette_State_Store.Selected_Command_Id := Editor.Command_Ids.No_Command;
      else
         Palette_State_Store.Selected_Item := Index;
         Palette_State_Store.Selected_Candidate_Index := Index;
         Palette_State_Store.Selected_Command_Id := Descriptors.Element (Index).Id;
      end if;
   end Set_Selected_From_Descriptor_Vector;

   procedure Set_Selected_From_Candidate_Vector
     (Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
      Index      : Natural)
   is
   begin
      if Candidates.Length = 0 or else Index >= Natural (Candidates.Length) then
         Palette_State_Store.Selected_Item := 0;
         Palette_State_Store.Selected_Candidate_Index := 0;
         Palette_State_Store.Selected_Command_Id := Editor.Command_Ids.No_Command;
      else
         Palette_State_Store.Selected_Item := Index;
         Palette_State_Store.Selected_Candidate_Index := Index;
         Palette_State_Store.Selected_Command_Id := Candidates.Element (Index).Id;
      end if;
   end Set_Selected_From_Candidate_Vector;

   procedure Reconcile_Selection
     (Candidates             : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
      Preferred_Command      : Editor.Command_Ids.Command_Id := Editor.Command_Ids.No_Command;
      Prefer_First_Available : Boolean := True)
   is
      Preferred : constant Editor.Command_Ids.Command_Id :=
        (if Preferred_Command /= Editor.Command_Ids.No_Command
         then Preferred_Command
         else Palette_State_Store.Selected_Command_Id);
      Visible : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
   begin
      Visible_Candidates (Candidates, Visible);

      if Visible.Length = 0 then
         Palette_State_Store.Selected_Item := 0;
         Palette_State_Store.Selected_Candidate_Index := 0;
         Palette_State_Store.Selected_Command_Id := Editor.Command_Ids.No_Command;
         return;
      end if;

      if Preferred /= Editor.Command_Ids.No_Command then
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
      Filtered : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
      Preferred : constant Editor.Command_Ids.Command_Id := Palette_State_Store.Selected_Command_Id;
   begin
      Filtered_Commands (Filtered);

      if Filtered.Length = 0 then
         Set_Selected_From_Descriptor_Vector (Filtered, 0);
         return;
      end if;

      if Preferred /= Editor.Command_Ids.No_Command then
         for I in 0 .. Natural (Filtered.Length) - 1 loop
            if Filtered.Element (I).Id = Preferred then
               Set_Selected_From_Descriptor_Vector (Filtered, I);
               return;
            end if;
         end loop;
      end if;

      if Palette_State_Store.Selected_Item >= Natural (Filtered.Length) then
         Set_Selected_From_Descriptor_Vector
           (Filtered, Natural (Filtered.Length) - 1);
      else
         Set_Selected_From_Descriptor_Vector (Filtered, Palette_State_Store.Selected_Item);
      end if;
   end Clamp_Selection;

   function Current return Palette_State is
   begin
      return Palette_State_Store;
   end Current;

   procedure Reset is
   begin
      Palette_State_Store.Open := False;
      Palette_State_Store.Query := Null_Unbounded_String;
      Editor.Input_Field.Clear (Filter_Field);
      Palette_State_Store.Selected_Item := 0;
      Palette_State_Store.Selected_Candidate_Index := 0;
      Palette_State_Store.Selected_Command_Id := Editor.Command_Ids.No_Command;
      Palette_State_Store.Top_Row := 1;
      Config_State := (others => <>);
      Clear_Transient_Filters;
      Clear_Command_State_Contexts;
   end Reset;

   procedure Open is
   begin
      Palette_State_Store.Open := True;
      Palette_State_Store.Selected_Item := 0;
      Palette_State_Store.Selected_Candidate_Index := 0;
      Palette_State_Store.Selected_Command_Id := Editor.Command_Ids.No_Command;
      Palette_State_Store.Top_Row := 1;
      Clear_Transient_Filters;
      Clear_Command_State_Contexts;
   end Open;

   procedure Open_With_Command
     (Command : Editor.Command_Ids.Command_Id)
   is
      D : Editor.Commands.Descriptors.Command_Descriptor;
   begin
      if Command = Editor.Command_Ids.No_Command then
         Open;
         return;
      end if;

      D := Editor.Commands.Descriptors.Descriptor (Command);
      if D.Visibility /= Editor.Commands.Descriptors.Palette_Command then
         Open;
         return;
      end if;

      Palette_State_Store.Open := True;
      Palette_State_Store.Query := To_Unbounded_String (Editor.Commands.Name_Metadata.Stable_Command_Name (Command));
      Editor.Input_Field.Clear (Filter_Field);
      Editor.Input_Field.Insert_Text (Filter_Field, To_String (Palette_State_Store.Query));
      Palette_State_Store.Selected_Item := 0;
      Palette_State_Store.Selected_Candidate_Index := 0;
      Palette_State_Store.Selected_Command_Id := Command;
      Palette_State_Store.Top_Row := 1;
      Config_State.Show_Help_Row := False;
      Clear_Transient_Filters;
   end Open_With_Command;

   procedure Close is
   begin
      Palette_State_Store.Open := False;
      Palette_State_Store.Selected_Item := 0;
      Palette_State_Store.Selected_Candidate_Index := 0;
      Palette_State_Store.Selected_Command_Id := Editor.Command_Ids.No_Command;
      Palette_State_Store.Top_Row := 1;
      Config_State.Show_Help_Row := False;
      Clear_Transient_Filters;
   end Close;

   procedure Toggle is
   begin
      if Palette_State_Store.Open then
         Close;
      else
         Open;
      end if;
   end Toggle;

   function Is_Open return Boolean is
   begin
      return Palette_State_Store.Open;
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
      Filtered : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
      Last     : Natural;
      Next     : Integer;
   begin
      Filtered_Commands (Filtered);
      if Filtered.Length = 0 then
         Set_Selected_From_Descriptor_Vector (Filtered, 0);
         return;
      end if;

      Last := Natural (Filtered.Length) - 1;
      Next := Integer (Palette_State_Store.Selected_Item) + Amount;
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
     (Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
      Amount     : Integer)
   is
      Visible : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
      Last    : Natural;
      Next    : Integer;
   begin
      Visible_Candidates (Candidates, Visible);
      if Visible.Length = 0 then
         Set_Selected_From_Candidate_Vector (Visible, 0);
         return;
      end if;

      Last := Natural (Visible.Length) - 1;
      if Palette_State_Store.Selected_Command_Id /= Editor.Command_Ids.No_Command then
         for I in 0 .. Natural (Visible.Length) - 1 loop
            if Visible.Element (I).Id = Palette_State_Store.Selected_Command_Id then
               Palette_State_Store.Selected_Item := I;
               exit;
            end if;
         end loop;
      end if;

      Next := Integer (Palette_State_Store.Selected_Item) + Amount;
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
         Filtered : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
      begin
         Filtered_Commands (Filtered);
         Set_Selected_From_Descriptor_Vector (Filtered, 0);
      end;
   end Select_First;

   procedure Select_Last is
      Filtered : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
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
     (Result : out Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector)
   is
      All_Commands : constant Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Descriptors.Palette_Commands;
      Query : constant String := To_String (Palette_State_Store.Query);
      Visible_Commands : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
      Matched_Commands : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
      Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
   begin
      Result.Clear;
      if All_Commands.Length = 0 then
         return;
      end if;

      --  command-palette search includes active keybinding labels. The
      --  high-level guikit fuzzy matcher handles the ranking and keeps empty
      --  queries stable while we continue to project the editor-specific
      --  descriptor metadata.
      for I in All_Commands.First_Index .. All_Commands.Last_Index loop
         declare
            D : constant Editor.Commands.Descriptors.Command_Descriptor := All_Commands.Element (I);
         begin
            if Descriptor_Passes_Transient_Metadata_Filters (D) then
               Visible_Commands.Append (D);
            end if;
         end;
      end loop;

      if Visible_Commands.Length = 0 then
         return;
      end if;

      Matched_Commands :=
        Editor.Command_Palette.Guikit_Model.Search_Descriptors
          (Descriptors      => Visible_Commands,
           Query            => To_String (Palette_State_Store.Query),
           Show_Keybindings => Current_Config.Show_Keybindings);

      for D of Matched_Commands loop
         declare
            Score : constant Natural := Descriptor_Match_Score (D, Query);
         begin
            if Score > 0 or else Query'Length = 0 then
               declare
                  Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
                    Editor.Keybindings.Primary_Binding_For_Command (D.Id);
               begin
                  Candidates.Append
                    (Editor.Commands.Palette_Model.Command_Palette_Candidate'
                      (Id                 => D.Id,
                       Label              => D.Name,
                       Description        => D.Description,
                       Category           => D.Category,
                       Category_Label     => To_Unbounded_String
                         (Editor.Commands.Descriptors.Discoverability_Category_Label (D.Id)),
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
         Result.Append (Editor.Commands.Descriptors.Descriptor (C.Id));
      end loop;

   end Filtered_Commands;

   function Selected_Command return Editor.Command_Ids.Command_Id is
      Filtered : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
   begin
      Filtered_Commands (Filtered);
      if Filtered.Length = 0 then
         return Editor.Command_Ids.No_Command;
      elsif Palette_State_Store.Selected_Item >= Natural (Filtered.Length) then
         return Filtered.Element (Natural (Filtered.Length) - 1).Id;
      else
         return Filtered.Element (Palette_State_Store.Selected_Item).Id;
      end if;
   end Selected_Command;

   function Has_Selected_Command return Boolean is
      Filtered : Editor.Commands.Descriptors.Command_Descriptor_Vectors.Vector;
   begin
      Filtered_Commands (Filtered);
      return Filtered.Length > 0
        and then Palette_State_Store.Selected_Item < Natural (Filtered.Length);
   end Has_Selected_Command;

   function Build_Snapshot
     (Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
      Config     : Command_Palette_Config) return Command_Palette_Snapshot
   is
      Result : Command_Palette_Snapshot;
      Visible_Candidates : Editor.Commands.Palette_Model.Command_Palette_Candidate_Vectors.Vector;
      Last_Category_Label : Unbounded_String := Null_Unbounded_String;
      Have_Category : Boolean := False;
      Query_Text : constant String := To_String (Palette_State_Store.Query);
      Query_Is_Empty : constant Boolean := Query_Text'Length = 0;
      Grouped : constant Boolean := Query_Is_Empty and then Config.Group_Empty_Query_By_Category;
      Selected_Visible_Index : Natural := 0;
      Have_Selected_Visible_Index : Boolean := False;
      Has_Filtered_Candidate : Boolean := False;

      function Reason_For (C : Editor.Commands.Palette_Model.Command_Palette_Candidate) return Unbounded_String is
      begin
         if C.Available then
            return Null_Unbounded_String;
         elsif Length (C.Reason) > 0 then
            return C.Reason;
         else
            return To_Unbounded_String ("Command not available here");
         end if;
      end Reason_For;

      function Selected_Secondary (C : Editor.Commands.Palette_Model.Command_Palette_Candidate)
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
        (C : Editor.Commands.Palette_Model.Command_Palette_Candidate) return Boolean is
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
         if Palette_State_Store.Selected_Command_Id /= Editor.Command_Ids.No_Command then
            for I in 0 .. Natural (Visible_Candidates.Length) - 1 loop
               if Visible_Candidates.Element (I).Id = Palette_State_Store.Selected_Command_Id then
                  Selected_Visible_Index := I;
                  Have_Selected_Visible_Index := True;
                  exit;
               end if;
            end loop;
         end if;

         if not Have_Selected_Visible_Index then
            if Palette_State_Store.Selected_Item < Natural (Visible_Candidates.Length) then
               Selected_Visible_Index := Palette_State_Store.Selected_Item;
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
                Category               => Editor.Commands.Descriptors.Internal_Category,
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
                Category               => Editor.Commands.Descriptors.Internal_Category,
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
            C : constant Editor.Commands.Palette_Model.Command_Palette_Candidate := Visible_Candidates.Element (I);
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
                Category               => Editor.Commands.Descriptors.Internal_Category,
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
      Index    : Natural) return Editor.Commands.Palette_Model.Command_Palette_Candidate is
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
      Selected_Candidate : Natural := Palette_State_Store.Selected_Item;
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
         Palette_State_Store.Top_Row := 1;
         return;
      end if;

      Max_Top :=
        (if Row_Count (Snapshot) > Visible_Row_Count
         then Row_Count (Snapshot) - Visible_Row_Count + 1
         else 1);

      if not Found then
         Palette_State_Store.Top_Row := Natural'Min (Palette_State_Store.Top_Row, Max_Top);
         Palette_State_Store.Top_Row := Natural'Max (Palette_State_Store.Top_Row, 1);
         return;
      end if;

      if Row_Index < Palette_State_Store.Top_Row then
         Palette_State_Store.Top_Row := Row_Index;
      elsif Row_Index >= Palette_State_Store.Top_Row + Visible_Row_Count then
         Palette_State_Store.Top_Row := Row_Index - Visible_Row_Count + 1;
      end if;

      Palette_State_Store.Top_Row := Natural'Min (Palette_State_Store.Top_Row, Max_Top);
      Palette_State_Store.Top_Row := Natural'Max (Palette_State_Store.Top_Row, 1);
   end Ensure_Selected_Row_Visible;

   procedure Clamp_Viewport
     (Snapshot          : Command_Palette_Snapshot;
      Visible_Row_Count : Natural)
   is
      Count   : constant Natural := Row_Count (Snapshot);
      Max_Top : Natural := 1;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         Palette_State_Store.Top_Row := 1;
         return;
      end if;

      if Count > Visible_Row_Count then
         Max_Top := Count - Visible_Row_Count + 1;
      end if;

      if Palette_State_Store.Top_Row = 0 then
         Palette_State_Store.Top_Row := 1;
      elsif Palette_State_Store.Top_Row > Max_Top then
         Palette_State_Store.Top_Row := Max_Top;
      end if;
   end Clamp_Viewport;

   procedure Scroll_By
     (Snapshot          : Command_Palette_Snapshot;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer)
   is
      Count   : constant Natural := Row_Count (Snapshot);
      Max_Top : Natural := 1;
      Desired : Integer := Integer (Palette_State_Store.Top_Row) + Step_Delta;
   begin
      if Count = 0 or else Visible_Row_Count = 0 then
         Palette_State_Store.Top_Row := 1;
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

      Palette_State_Store.Top_Row := Natural (Desired);
   end Scroll_By;

end Editor.Command_Palette;
