with Ada.Characters.Handling;
with Ada.Containers.Vectors;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Keybinding_Config;

package body Editor.Keybinding_Management is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Keybinding_Config.Keybinding_Config_Status;

   type Editor_State is record
      Visible  : Boolean := False;
      Focused  : Boolean := False;
      Filter   : Keybinding_Filter := Filter_All;
      Query    : Unbounded_String := Null_Unbounded_String;
      Selected : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Capture  : Keybinding_Capture_State := Capture_Inactive;
      Pending_Chord : Editor.Keybindings.Key_Chord :=
        (Key => Editor.Keybindings.Key_Left,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
      Pending_Target : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Pending_Existing : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Has_Pending : Boolean := False;
      Has_Selected_Chord : Boolean := False;
      Pending_Reset : Boolean := False;
      Selected_Chord : Editor.Keybindings.Key_Chord :=
        (Key => Editor.Keybindings.Key_Left,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
      Last_Message : Unbounded_String := Null_Unbounded_String;
   end record;

   State : Editor_State;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Keybinding_Row_Snapshot);

   package Chord_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Keybinding_Chord_Row_Snapshot);

   function Same_Chord
     (L : Editor.Keybindings.Key_Chord;
      R : Editor.Keybindings.Key_Chord) return Boolean
   is
   begin
      return Editor.Keybindings.Format_Chord (L) =
        Editor.Keybindings.Format_Chord (R);
   end Same_Chord;

   procedure Set_Message (Text : String) is
   begin
      State.Last_Message := To_Unbounded_String (Text);
   end Set_Message;

   function Lower (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
   end Lower;

   function Contains (Haystack : String; Needle : String) return Boolean is
      H : constant String := Lower (Haystack);
      N : constant String := Lower (Needle);
   begin
      return N'Length = 0 or else Ada.Strings.Fixed.Index (H, N) /= 0;
   end Contains;

   function Category_Label
     (Category : Editor.Commands.Command_Category) return String
   is
   begin
      case Category is
         when Editor.Commands.File_Category        => return "File";
         when Editor.Commands.Edit_Category        => return "Edit";
         when Editor.Commands.Selection_Category   => return "Selection";
         when Editor.Commands.Navigation_Category  => return "Navigation";
         when Editor.Commands.Search_Category      => return "Search";
         when Editor.Commands.Project_Category     => return "Project";
         when Editor.Commands.Panel_Category       => return "Panel";
         when Editor.Commands.View_Category        => return "View";
         when Editor.Commands.Diagnostics_Category => return "Diagnostics";
         when Editor.Commands.Bookmarks_Category   => return "Bookmarks";
         when Editor.Commands.Overlay_Category     => return "Overlay";
         when Editor.Commands.Message_Category     => return "Message";
         when Editor.Commands.Theme_Category       => return "Theme";
         when Editor.Commands.Settings_Category    => return "Settings";
         when Editor.Commands.Workspace_Category   => return "Workspace";
         when Editor.Commands.Internal_Category    => return "Internal";
      end case;
   end Category_Label;

   function Active_Chord_For
     (Command : Editor.Commands.Command_Id;
      Found   : out Boolean) return Editor.Keybindings.Key_Chord
   is
   begin
      if Editor.Keybindings.Binding_Count_For_Command (Command) > 0 then
         Found := True;
         return Editor.Keybindings.Binding_For_Command (Command, 1);
      end if;
      Found := False;
      return (Key => Editor.Keybindings.Key_Left,
              Modifiers => (Ctrl => False, Shift => False,
                            Alt => False, Meta => False));
   end Active_Chord_For;

   function Active_Chord_List_For
     (Command : Editor.Commands.Command_Id) return Unbounded_String
   is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      for I in 1 .. Editor.Keybindings.Binding_Count_For_Command (Command) loop
         if Length (Result) > 0 then
            Append (Result, ", ");
         end if;
         Append
           (Result,
            Editor.Keybindings.Format_Chord
              (Editor.Keybindings.Binding_For_Command (Command, I)));
      end loop;
      return Result;
   end Active_Chord_List_For;

   function Default_Chord_For
     (Command : Editor.Commands.Command_Id;
      Found   : out Boolean) return Editor.Keybindings.Key_Chord
   is
      Defaults : Editor.Keybinding_Config.Keybinding_Config_Model;
   begin
      Editor.Keybinding_Config.Set_Defaults (Defaults);
      return Editor.Keybinding_Config.Chord_For (Defaults, Command, Found);
   end Default_Chord_For;

   function Is_Default_Chord
     (Command : Editor.Commands.Command_Id;
      Chord   : Editor.Keybindings.Key_Chord) return Boolean
   is
      Found_Default : Boolean := False;
      Default       : constant Editor.Keybindings.Key_Chord :=
        Default_Chord_For (Command, Found_Default);
   begin
      return Found_Default and then Same_Chord (Default, Chord);
   end Is_Default_Chord;

   function Conflicts_With_Default
     (Command : Editor.Commands.Command_Id;
      Active  : Editor.Keybindings.Key_Chord;
      Has_Active : Boolean) return Boolean
   is
      Found_Default : Boolean := False;
      Default       : constant Editor.Keybindings.Key_Chord :=
        Default_Chord_For (Command, Found_Default);
   begin
      if not Has_Active or else not Found_Default then
         return False;
      end if;
      return Editor.Keybindings.Format_Chord (Active) /=
        Editor.Keybindings.Format_Chord (Default);
   end Conflicts_With_Default;

   function Row_For
     (Command : Editor.Commands.Command_Id) return Keybinding_Row_Snapshot
   is
      D             : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Command);
      Has_Active    : Boolean := False;
      Has_Default   : Boolean := False;
      Active        : constant Editor.Keybindings.Key_Chord :=
        Active_Chord_For (Command, Has_Active);
      Default       : constant Editor.Keybindings.Key_Chord :=
        Default_Chord_For (Command, Has_Default);
      Assignable    : constant Boolean :=
        D.Visibility = Editor.Commands.Palette_Command
        and then Editor.Keybindings.Is_Normal_Assignable_Command (Command);
      R             : Keybinding_Row_Snapshot;
   begin
      R.Command := Command;
      R.Command_Title := D.Name;
      R.Stable_Command_Name :=
        To_Unbounded_String (Editor.Commands.Stable_Command_Name (Command));
      R.Category_Label := To_Unbounded_String (Category_Label (D.Category));
      R.Description := D.Description;
      R.Has_Active_Chord := Has_Active;
      R.Active_Chord_Count :=
        Editor.Keybindings.Binding_Count_For_Command (Command);
      R.Active_Chords := Active_Chord_List_For (Command);
      if Has_Active then
         R.Active_Chord := To_Unbounded_String (Editor.Keybindings.Format_Chord (Active));
      end if;
      R.Has_Default_Chord := Has_Default;
      if Has_Default then
         R.Default_Chord := To_Unbounded_String (Editor.Keybindings.Format_Chord (Default));
      end if;
      R.Bindable := Assignable;
      R.Non_Bindable := not Assignable;
      R.Conflicting := Conflicts_With_Default (Command, Active, Has_Active);
      R.Selected := Command = State.Selected;
      if Has_Active and then Has_Default then
         if R.Conflicting then
            R.Source_Label := To_Unbounded_String ("user override");
         else
            R.Source_Label := To_Unbounded_String ("default");
         end if;
      elsif Has_Active then
         R.Source_Label := To_Unbounded_String ("user");
      elsif Has_Default then
         R.Source_Label := To_Unbounded_String ("default unbound");
      else
         R.Source_Label := To_Unbounded_String ("unbound");
      end if;
      return R;
   end Row_For;

   function Matches_Query (R : Keybinding_Row_Snapshot) return Boolean is
      Q : constant String := To_String (State.Query);
   begin
      return Q'Length = 0
        or else Contains (To_String (R.Command_Title), Q)
        or else Contains (To_String (R.Stable_Command_Name), Q)
        or else Contains (To_String (R.Category_Label), Q)
        or else Contains (To_String (R.Description), Q)
        or else Contains (To_String (R.Active_Chord), Q)
        or else Contains (To_String (R.Active_Chords), Q)
        or else Contains (To_String (R.Default_Chord), Q);
   end Matches_Query;

   function Matches_Filter (R : Keybinding_Row_Snapshot) return Boolean is
   begin
      case State.Filter is
         when Filter_All =>
            return True;
         when Filter_Bound =>
            return R.Has_Active_Chord;
         when Filter_Unbound =>
            return R.Bindable and then not R.Has_Active_Chord;
         when Filter_Conflicts =>
            return R.Conflicting;
         when Filter_Non_Bindable =>
            return R.Non_Bindable;
      end case;
   end Matches_Filter;

   function Include_Command (Command : Editor.Commands.Command_Id) return Boolean is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Command);
   begin
      if not Editor.Commands.Is_Concrete_Command (Command) then
         return False;
      end if;

      if D.Visibility = Editor.Commands.Hidden_Command then
         return False;
      end if;

      return True;
   end Include_Command;

   function Chord_Row_For
     (Command : Editor.Commands.Command_Id;
      Chord   : Editor.Keybindings.Key_Chord) return Keybinding_Chord_Row_Snapshot
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Command);
      R : Keybinding_Chord_Row_Snapshot;
      Existing : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Resolved : constant Editor.Keybindings.Binding_Result :=
        Editor.Keybindings.Resolve (Chord, Existing);
   begin
      R.Chord_Label := To_Unbounded_String (Editor.Keybindings.Format_Chord (Chord));
      R.Command := Command;
      R.Command_Title := D.Name;
      R.Stable_Command_Name :=
        To_Unbounded_String (Editor.Commands.Stable_Command_Name (Command));
      R.Category_Label := To_Unbounded_String (Category_Label (D.Category));
      R.Default_Chord := Is_Default_Chord (Command, Chord);
      R.User_Override := not R.Default_Chord;
      R.Conflicting := Resolved = Editor.Keybindings.Bound_Command
        and then Existing /= Command;
      R.Selected := State.Has_Selected_Chord and then Same_Chord (State.Selected_Chord, Chord);
      return R;
   end Chord_Row_For;

   function Matches_Chord_Row (R : Keybinding_Chord_Row_Snapshot) return Boolean is
      Q : constant String := To_String (State.Query);
   begin
      return Q'Length = 0
        or else Contains (To_String (R.Chord_Label), Q)
        or else Contains (To_String (R.Command_Title), Q)
        or else Contains (To_String (R.Stable_Command_Name), Q)
        or else Contains (To_String (R.Category_Label), Q);
   end Matches_Chord_Row;

   function Build_Chord_Rows return Chord_Row_Vectors.Vector is
      Rows : Chord_Row_Vectors.Vector;
   begin
      for Command in Editor.Commands.Command_Id loop
         if Include_Command (Command) then
            for I in 1 .. Editor.Keybindings.Binding_Count_For_Command (Command) loop
               declare
                  R : constant Keybinding_Chord_Row_Snapshot :=
                    Chord_Row_For
                      (Command, Editor.Keybindings.Binding_For_Command (Command, I));
               begin
                  if Matches_Chord_Row (R) then
                     case State.Filter is
                        when Filter_All | Filter_Bound =>
                           Rows.Append (R);
                        when Filter_Conflicts =>
                           if R.Conflicting then
                              Rows.Append (R);
                           end if;
                        when Filter_Unbound | Filter_Non_Bindable =>
                           null;
                     end case;
                  end if;
               end;
            end loop;
         end if;
      end loop;
      return Rows;
   end Build_Chord_Rows;

   function Build_Rows return Row_Vectors.Vector is
      Rows : Row_Vectors.Vector;

      procedure Visit (Command : Editor.Commands.Command_Id) is
         R : Keybinding_Row_Snapshot;
      begin
         if Include_Command (Command) then
            R := Row_For (Command);
            if Matches_Query (R) and then Matches_Filter (R) then
               Rows.Append (R);
            end if;
         end if;
      end Visit;
   begin
      Editor.Commands.For_Each_Command (Visit'Access);
      return Rows;
   end Build_Rows;


   procedure Refresh_Selection_For_Current_View is
      Rows             : constant Row_Vectors.Vector := Build_Rows;
      Chord_Rows       : constant Chord_Row_Vectors.Vector := Build_Chord_Rows;
      Command_Visible  : Boolean := State.Selected = Editor.Commands.No_Command;
      Chord_Visible    : Boolean := not State.Has_Selected_Chord;
      Selected_Label   : constant String :=
        (if State.Has_Selected_Chord
         then Editor.Keybindings.Format_Chord (State.Selected_Chord)
         else "");
   begin
      if State.Selected /= Editor.Commands.No_Command
        and then Natural (Rows.Length) > 0
      then
         for I in 0 .. Natural (Rows.Length) - 1 loop
            if Rows.Element (I).Command = State.Selected then
               Command_Visible := True;
               exit;
            end if;
         end loop;
      end if;

      if State.Has_Selected_Chord and then Natural (Chord_Rows.Length) > 0 then
         for I in 0 .. Natural (Chord_Rows.Length) - 1 loop
            if To_String (Chord_Rows.Element (I).Chord_Label) = Selected_Label then
               Chord_Visible := True;
               exit;
            end if;
         end loop;
      end if;

      if not Command_Visible then
         State.Selected := Editor.Commands.No_Command;
      end if;
      if not Chord_Visible then
         State.Has_Selected_Chord := False;
      end if;
   end Refresh_Selection_For_Current_View;

   function Selected_Command_Is_Visible return Boolean is
      Rows : constant Row_Vectors.Vector := Build_Rows;
   begin
      if State.Selected = Editor.Commands.No_Command
        or else Natural (Rows.Length) = 0
      then
         return False;
      end if;
      for I in 0 .. Natural (Rows.Length) - 1 loop
         if Rows.Element (I).Command = State.Selected then
            return True;
         end if;
      end loop;
      return False;
   end Selected_Command_Is_Visible;

   function Selected_Chord_Is_Visible return Boolean is
      Rows : constant Chord_Row_Vectors.Vector := Build_Chord_Rows;
      Selected_Label : constant String :=
        (if State.Has_Selected_Chord
         then Editor.Keybindings.Format_Chord (State.Selected_Chord)
         else "");
   begin
      if not State.Has_Selected_Chord or else Natural (Rows.Length) = 0 then
         return False;
      end if;
      for I in 0 .. Natural (Rows.Length) - 1 loop
         if To_String (Rows.Element (I).Chord_Label) = Selected_Label then
            return True;
         end if;
      end loop;
      return False;
   end Selected_Chord_Is_Visible;

   procedure Show is
   begin
      State.Visible := True;
   end Show;

   procedure Focus is
   begin
      State.Visible := True;
      State.Focused := True;
   end Focus;

   procedure Hide is
   begin
      State.Focused := False;
      State.Visible := False;
      State.Capture := Capture_Inactive;
      State.Has_Pending := False;
      State.Pending_Reset := False;
      State.Pending_Target := Editor.Commands.No_Command;
      State.Pending_Existing := Editor.Commands.No_Command;
      State.Has_Selected_Chord := False;
   end Hide;

   procedure Reset_Transient_State is
   begin
      --  Phase 565: reset all keybinding-management UI state without touching
      --  runtime keybindings or keybinding persistence diagnostics. This is
      --  used by lifecycle/input resets where filter/query/selection/capture
      --  state must not survive as workspace, settings, or project state.
      State.Visible := False;
      State.Focused := False;
      State.Filter := Filter_All;
      State.Query := Null_Unbounded_String;
      State.Selected := Editor.Commands.No_Command;
      State.Capture := Capture_Inactive;
      State.Pending_Chord :=
        (Key => Editor.Keybindings.Key_Left,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
      State.Pending_Target := Editor.Commands.No_Command;
      State.Pending_Existing := Editor.Commands.No_Command;
      State.Has_Pending := False;
      State.Has_Selected_Chord := False;
      State.Pending_Reset := False;
      State.Selected_Chord :=
        (Key => Editor.Keybindings.Key_Left,
         Modifiers => (Ctrl => False, Shift => False, Alt => False, Meta => False));
      State.Last_Message := Null_Unbounded_String;
   end Reset_Transient_State;

   function Is_Visible return Boolean is (State.Visible);
   function Is_Focused return Boolean is (State.Focused);

   procedure Set_Query (Query : String) is
   begin
      State.Query := To_Unbounded_String (Query);
      Refresh_Selection_For_Current_View;
   end Set_Query;

   procedure Clear_Query is
   begin
      State.Query := Null_Unbounded_String;
      Refresh_Selection_For_Current_View;
   end Clear_Query;

   function Query return String is (To_String (State.Query));

   procedure Set_Filter (Filter : Keybinding_Filter) is
   begin
      State.Filter := Filter;
      Refresh_Selection_For_Current_View;
   end Set_Filter;

   procedure Clear_Filter is
   begin
      State.Filter := Filter_All;
      Refresh_Selection_For_Current_View;
   end Clear_Filter;

   function Current_Filter return Keybinding_Filter is (State.Filter);

   procedure Select_Command (Command : Editor.Commands.Command_Id) is
   begin
      State.Selected := Command;
      State.Has_Selected_Chord := False;
   end Select_Command;

   procedure Select_Row_By_Delta (Step_Delta : Integer) is
      Rows    : constant Row_Vectors.Vector := Build_Rows;
      Count   : constant Natural := Natural (Rows.Length);
      Current : Natural := 0;
      Target  : Natural := 0;
   begin
      if Count = 0 then
         State.Selected := Editor.Commands.No_Command;
         State.Has_Selected_Chord := False;
         Set_Message ("No matching commands.");
         return;
      end if;

      for I in 1 .. Count loop
         if Rows.Element (I - 1).Command = State.Selected then
            Current := I;
            exit;
         end if;
      end loop;

      if Current = 0 then
         if Step_Delta < 0 then
            Target := Count;
         else
            Target := 1;
         end if;
      elsif Step_Delta < 0 then
         if Current = 1 then
            Target := 1;
         else
            Target := Current - 1;
         end if;
      elsif Step_Delta > 0 then
         if Current = Count then
            Target := Count;
         else
            Target := Current + 1;
         end if;
      else
         Target := Current;
      end if;

      State.Selected := Rows.Element (Target - 1).Command;
      State.Has_Selected_Chord := False;
      Set_Message ("Keybinding row selected.");
   end Select_Row_By_Delta;

   procedure Select_Next_Row is
   begin
      Select_Row_By_Delta (1);
   end Select_Next_Row;

   procedure Select_Previous_Row is
   begin
      Select_Row_By_Delta (-1);
   end Select_Previous_Row;

   procedure Clear_Selection is
   begin
      State.Selected := Editor.Commands.No_Command;
      State.Capture := Capture_Inactive;
      State.Has_Pending := False;
      State.Pending_Reset := False;
      State.Pending_Target := Editor.Commands.No_Command;
      State.Pending_Existing := Editor.Commands.No_Command;
      State.Has_Selected_Chord := False;
   end Clear_Selection;

   function Selected_Command return Editor.Commands.Command_Id is (State.Selected);

   function Row_Count return Natural is
      Rows : constant Row_Vectors.Vector := Build_Rows;
   begin
      return Natural (Rows.Length);
   end Row_Count;

   function Row_At (Index : Positive) return Keybinding_Row_Snapshot is
      Rows : constant Row_Vectors.Vector := Build_Rows;
   begin
      if Index > Natural (Rows.Length) then
         return (others => <>);
      end if;
      return Rows.Element (Index - 1);
   end Row_At;

   function Chord_Row_Count return Natural is
      Rows : constant Chord_Row_Vectors.Vector := Build_Chord_Rows;
   begin
      return Natural (Rows.Length);
   end Chord_Row_Count;

   function Chord_Row_At (Index : Positive) return Keybinding_Chord_Row_Snapshot is
      Rows : constant Chord_Row_Vectors.Vector := Build_Chord_Rows;
   begin
      if Index > Natural (Rows.Length) then
         return (others => <>);
      end if;
      return Rows.Element (Index - 1);
   end Chord_Row_At;

   procedure Select_Chord
     (Text   : String;
      Status : out Keybinding_Action_Status)
   is
      Found : Boolean := False;
      Chord : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Parse_Chord (Text, Found);
      Existing : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      if not Found then
         Status := Keybinding_Action_Invalid_Shortcut;
         return;
      end if;
      if Editor.Keybindings.Resolve (Chord, Existing) /= Editor.Keybindings.Bound_Command then
         Status := Keybinding_Action_No_Keybinding_Selected;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;
      State.Selected := Existing;
      State.Selected_Chord := Chord;
      State.Has_Selected_Chord := True;
      Status := Keybinding_Action_Ok;
      Set_Message ("Keybinding selected.");
   end Select_Chord;

   procedure Clear_Chord_Selection is
   begin
      State.Has_Selected_Chord := False;
   end Clear_Chord_Selection;

   function Has_Selected_Chord return Boolean is (State.Has_Selected_Chord);

   function Selected_Chord_Label return String is
   begin
      if not State.Has_Selected_Chord then
         return "";
      end if;
      return Editor.Keybindings.Format_Chord (State.Selected_Chord);
   end Selected_Chord_Label;

   function Last_Load_Diagnostics_Label return String is
      Ignored : constant Natural := Editor.Keybinding_Config.Last_Load_Ignored_Count;
      Details : Unbounded_String := Null_Unbounded_String;

      procedure Append_Count
        (Kind  : Editor.Keybinding_Config.Keybinding_Config_Diagnostic_Kind;
         Label : String)
      is
         Count : constant Natural :=
           Editor.Keybinding_Config.Last_Load_Diagnostic_Count (Kind);
      begin
         if Count > 0 then
            if Length (Details) > 0 then
               Append (Details, ", ");
            end if;
            Append (Details, Label & Natural'Image (Count));
         end if;
      end Append_Count;
   begin
      if Ignored = 0 then
         return "No ignored keybinding load entries.";
      end if;

      Append_Count (Editor.Keybinding_Config.Unknown_Command, "unknown commands:");
      Append_Count (Editor.Keybinding_Config.Invalid_Command_Name, "non-bindable commands:");
      Append_Count (Editor.Keybinding_Config.Invalid_Chord, "invalid chords:");
      Append_Count (Editor.Keybinding_Config.Unsupported_Payload, "payloads:");
      Append_Count (Editor.Keybinding_Config.Duplicate_Chord, "duplicate chords:");
      if Length (Details) = 0 then
         return "Ignored" & Natural'Image (Ignored) & " keybinding entries.";
      end if;
      return "Ignored" & Natural'Image (Ignored) & " keybinding entries ("
        & To_String (Details) & ").";
   end Last_Load_Diagnostics_Label;

   function Summary return Keybinding_List_Summary is
      Result : Keybinding_List_Summary;

      procedure Visit (Command : Editor.Commands.Command_Id) is
         R : Keybinding_Row_Snapshot;
      begin
         if Include_Command (Command) then
            R := Row_For (Command);
            if Matches_Query (R) and then Matches_Filter (R) then
               Result.Row_Count := Result.Row_Count + 1;
               if R.Has_Active_Chord then
                  Result.Bound_Command_Count := Result.Bound_Command_Count + 1;
               end if;
               if R.Bindable and then not R.Has_Active_Chord then
                  Result.Unbound_Bindable_Count := Result.Unbound_Bindable_Count + 1;
               end if;
               if R.Non_Bindable then
                  Result.Non_Bindable_Command_Count :=
                    Result.Non_Bindable_Command_Count + 1;
               end if;
               if R.Conflicting then
                  Result.Conflict_Count := Result.Conflict_Count + 1;
               end if;
            end if;
         end if;
      end Visit;
   begin
      Editor.Commands.For_Each_Command (Visit'Access);
      Result.Chord_Row_Count := Chord_Row_Count;
      declare
         Validation : constant Editor.Keybindings.Keybinding_Validation_Result :=
           Editor.Keybindings.Validate;
         VSummary : constant Editor.Keybindings.Keybinding_Validation_Summary :=
           Editor.Keybindings.Summary (Validation);
      begin
         Result.Runtime_Validation_Conflicts := VSummary.Conflict_Count;
         Result.Runtime_Validation_Invalids := VSummary.Invalid_Count;
         if VSummary.Conflict_Count > Result.Conflict_Count then
            Result.Conflict_Count := VSummary.Conflict_Count;
         end if;
      end;
      Result.Last_Load_Ignored_Count :=
        Editor.Keybinding_Config.Last_Load_Ignored_Count;
      Result.Last_Load_Unknown_Commands :=
        Editor.Keybinding_Config.Last_Load_Diagnostic_Count
          (Editor.Keybinding_Config.Unknown_Command);
      Result.Last_Load_Non_Bindable :=
        Editor.Keybinding_Config.Last_Load_Diagnostic_Count
          (Editor.Keybinding_Config.Invalid_Command_Name);
      Result.Last_Load_Invalid_Chords :=
        Editor.Keybinding_Config.Last_Load_Diagnostic_Count
          (Editor.Keybinding_Config.Invalid_Chord);
      Result.Last_Load_Payloads :=
        Editor.Keybinding_Config.Last_Load_Diagnostic_Count
          (Editor.Keybinding_Config.Unsupported_Payload);
      Result.Last_Load_Duplicate_Chords :=
        Editor.Keybinding_Config.Last_Load_Diagnostic_Count
          (Editor.Keybinding_Config.Duplicate_Chord);
      Result.Capture := State.Capture;
      Result.Has_Pending_Conflict := State.Has_Pending;
      Result.Pending_Conflict_Command := State.Pending_Existing;
      if State.Has_Pending then
         Result.Pending_Conflict_Chord :=
           To_Unbounded_String (Editor.Keybindings.Format_Chord (State.Pending_Chord));
      end if;
      Result.Has_Pending_Reset := State.Pending_Reset;
      return Result;
   end Summary;

   function Current_Capture_State return Keybinding_Capture_State is (State.Capture);

   function Build_Surface_Snapshot return Keybinding_Surface_Snapshot is
      Result : Keybinding_Surface_Snapshot;
   begin
      Result.Visible := State.Visible;
      Result.Focused := State.Focused;
      Result.Query_Present := Length (State.Query) > 0;
      Result.Filter := State.Filter;
      Result.Selected_Command := State.Selected;
      Result.Has_Selected_Chord := State.Has_Selected_Chord;
      if State.Has_Selected_Chord then
         Result.Selected_Chord_Label :=
           To_Unbounded_String (Editor.Keybindings.Format_Chord (State.Selected_Chord));
      end if;
      Result.Row_Count := Row_Count;
      Result.Chord_Row_Count := Chord_Row_Count;
      declare
         Rows : constant Row_Vectors.Vector := Build_Rows;
      begin
         Result.Display_Row_Count :=
           Natural'Min (Natural (Rows.Length), Max_Surface_Rows);
         for I in 1 .. Result.Display_Row_Count loop
            Result.Display_Rows (I) := Rows.Element (I - 1);
         end loop;
      end;
      declare
         Chord_Rows : constant Chord_Row_Vectors.Vector := Build_Chord_Rows;
      begin
         Result.Display_Chord_Row_Count :=
           Natural'Min (Natural (Chord_Rows.Length), Max_Surface_Rows);
         for I in 1 .. Result.Display_Chord_Row_Count loop
            Result.Display_Chord_Rows (I) := Chord_Rows.Element (I - 1);
         end loop;
      end;
      Result.Capture := State.Capture;
      Result.Has_Pending_Conflict := State.Has_Pending;
      Result.Has_Pending_Reset := State.Pending_Reset;
      Result.Last_Load_Ignored_Count :=
        Editor.Keybinding_Config.Last_Load_Ignored_Count;
      Result.Last_Load_Diagnostic_Label :=
        To_Unbounded_String (Last_Load_Diagnostics_Label);
      Result.Latest_Message := State.Last_Message;
      return Result;
   end Build_Surface_Snapshot;

   function Selection_Assignable return Boolean is
   begin
      return State.Selected /= Editor.Commands.No_Command
        and then Include_Command (State.Selected)
        and then Editor.Keybindings.Is_Normal_Assignable_Command (State.Selected);
   end Selection_Assignable;

   procedure Begin_Assign_Selected (Status : out Keybinding_Action_Status) is
   begin
      if State.Pending_Reset then
         Status := Keybinding_Action_Confirmation_Pending;
         Set_Message (Action_Status_Label (Status));
      elsif State.Selected = Editor.Commands.No_Command
        or else not Selected_Command_Is_Visible
      then
         Status := Keybinding_Action_No_Command_Selected;
         Set_Message (Action_Status_Label (Status));
      elsif not Selection_Assignable then
         Status := Keybinding_Action_Command_Not_Bindable;
         Set_Message (Action_Status_Label (Status));
      else
         State.Capture := Capture_Active;
         State.Has_Pending := False;
         State.Pending_Target := State.Selected;
         State.Pending_Existing := Editor.Commands.No_Command;
         Status := Keybinding_Action_Ok;
         Set_Message ("Keybinding capture started.");
      end if;
   end Begin_Assign_Selected;

   procedure Cancel_Capture (Status : out Keybinding_Action_Status) is
   begin
      if State.Capture = Capture_Inactive then
         Status := Keybinding_Action_Cancelled;
         Set_Message (Action_Status_Label (Status));
      else
         State.Capture := Capture_Inactive;
         State.Has_Pending := False;
         State.Pending_Target := Editor.Commands.No_Command;
         State.Pending_Existing := Editor.Commands.No_Command;
         Status := Keybinding_Action_Cancelled;
         Set_Message (Action_Status_Label (Status));
      end if;
   end Cancel_Capture;

   function Has_Pending_Conflict return Boolean is (State.Has_Pending);

   function Pending_Conflict_Command return Editor.Commands.Command_Id is
     (State.Pending_Existing);

   function Pending_Conflict_Chord return String is
   begin
      if not State.Has_Pending then
         return "";
      end if;
      return Editor.Keybindings.Format_Chord (State.Pending_Chord);
   end Pending_Conflict_Chord;

   procedure Confirm_Pending_Assignment
     (Status : out Keybinding_Action_Status)
   is
      Chord  : constant Editor.Keybindings.Key_Chord := State.Pending_Chord;
      Target : constant Editor.Commands.Command_Id := State.Pending_Target;
      Change : Editor.Keybindings.Keybinding_Change_Status;
   begin
      if not State.Has_Pending then
         Status := Keybinding_Action_No_Keybinding_Selected;
         Set_Message (Action_Status_Label (Status));
         return;
      elsif State.Pending_Reset then
         Status := Keybinding_Action_Confirmation_Pending;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;

      --  Confirmation applies the already captured target/chord pair, not the
      --  currently visible keybinding-list selection.  This keeps transient
      --  filter/query changes from turning an explicit replacement
      --  confirmation into a stale-row failure while still relying on the
      --  keybinding core to reject hidden, internal, public-build, or otherwise
      --  non-bindable targets before mutation.
      Editor.Keybindings.Assign (Chord, Target, Change);
      case Change is
         when Editor.Keybindings.Keybinding_Change_Ok =>
            State.Selected := Target;
            State.Capture := Capture_Inactive;
            State.Has_Pending := False;
            State.Pending_Target := Editor.Commands.No_Command;
            State.Pending_Existing := Editor.Commands.No_Command;
            State.Has_Selected_Chord := False;
            Status := Keybinding_Action_Ok;
            Set_Message ("Keybinding assigned.");
         when Editor.Keybindings.Keybinding_Change_Invalid_Target =>
            Status := Keybinding_Action_No_Command_Selected;
            Set_Message (Action_Status_Label (Status));
         when Editor.Keybindings.Keybinding_Change_Non_Bindable_Target
            | Editor.Keybindings.Keybinding_Change_Internal_Target
            | Editor.Keybindings.Keybinding_Change_Public_Build_Target =>
            Status := Keybinding_Action_Command_Not_Bindable;
            Set_Message (Action_Status_Label (Status));
         when Editor.Keybindings.Keybinding_Change_Table_Full =>
            Status := Keybinding_Action_IO_Failed;
            Set_Message (Action_Status_Label (Status));
      end case;
   end Confirm_Pending_Assignment;

   procedure Assign_Selected
     (Chord            : Editor.Keybindings.Key_Chord;
      Confirm_Conflict : Boolean;
      Status           : out Keybinding_Action_Status)
   is
      Existing : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Change   : Editor.Keybindings.Keybinding_Change_Status;
   begin
      if State.Pending_Reset or else State.Has_Pending then
         Status := Keybinding_Action_Confirmation_Pending;
         Set_Message (Action_Status_Label (Status));
         return;
      elsif State.Selected = Editor.Commands.No_Command
        or else not Selected_Command_Is_Visible
      then
         Status := Keybinding_Action_No_Command_Selected;
         Set_Message (Action_Status_Label (Status));
         return;
      elsif not Selection_Assignable then
         Status := Keybinding_Action_Command_Not_Bindable;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;

      if Editor.Keybindings.Resolve (Chord, Existing) = Editor.Keybindings.Bound_Command
        and then Existing /= State.Selected
        and then not Confirm_Conflict
      then
         State.Capture := Capture_Conflict_Pending;
         State.Pending_Chord := Chord;
         State.Pending_Target := State.Selected;
         State.Pending_Existing := Existing;
         State.Has_Pending := True;
         Status := Keybinding_Action_Shortcut_Already_Assigned;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;

      Editor.Keybindings.Assign (Chord, State.Selected, Change);
      case Change is
         when Editor.Keybindings.Keybinding_Change_Ok =>
            State.Capture := Capture_Inactive;
            State.Has_Pending := False;
            State.Pending_Target := Editor.Commands.No_Command;
            State.Pending_Existing := Editor.Commands.No_Command;
            State.Has_Selected_Chord := False;
            Set_Message ("Keybinding assigned.");
            Status := Keybinding_Action_Ok;
         when Editor.Keybindings.Keybinding_Change_Invalid_Target =>
            Status := Keybinding_Action_No_Command_Selected;
            Set_Message (Action_Status_Label (Status));
         when Editor.Keybindings.Keybinding_Change_Non_Bindable_Target
            | Editor.Keybindings.Keybinding_Change_Internal_Target
            | Editor.Keybindings.Keybinding_Change_Public_Build_Target =>
            Status := Keybinding_Action_Command_Not_Bindable;
            Set_Message (Action_Status_Label (Status));
         when Editor.Keybindings.Keybinding_Change_Table_Full =>
            Status := Keybinding_Action_IO_Failed;
            Set_Message (Action_Status_Label (Status));
      end case;
   end Assign_Selected;

   procedure Capture_Assignment
     (Text             : String;
      Confirm_Conflict : Boolean;
      Status           : out Keybinding_Action_Status)
   is
      Found : Boolean := False;
      Chord : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Parse_Chord (Text, Found);
   begin
      if State.Capture = Capture_Inactive then
         Status := Keybinding_Action_No_Command_Selected;
         Set_Message (Action_Status_Label (Status));
         return;
      elsif not Found then
         Status := Keybinding_Action_Invalid_Shortcut;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;
      Assign_Selected (Chord, Confirm_Conflict, Status);
   end Capture_Assignment;

   procedure Remove_Selected (Status : out Keybinding_Action_Status) is
   begin
      if State.Pending_Reset then
         Status := Keybinding_Action_Confirmation_Pending;
         Set_Message (Action_Status_Label (Status));
      elsif State.Capture /= Capture_Inactive then
         Status := Keybinding_Action_Confirmation_Pending;
         Set_Message (Action_Status_Label (Status));
      elsif State.Has_Selected_Chord then
         if not Selected_Chord_Is_Visible then
            State.Has_Selected_Chord := False;
            Status := Keybinding_Action_No_Keybinding_Selected;
            Set_Message (Action_Status_Label (Status));
            return;
         end if;
         Editor.Keybindings.Unbind (State.Selected_Chord);
         State.Has_Selected_Chord := False;
         State.Capture := Capture_Inactive;
         State.Has_Pending := False;
         Status := Keybinding_Action_Ok;
         Set_Message ("Keybinding removed.");
      elsif State.Selected = Editor.Commands.No_Command
        or else not Selected_Command_Is_Visible
      then
         Status := Keybinding_Action_No_Command_Selected;
         Set_Message (Action_Status_Label (Status));
      elsif not Selection_Assignable then
         Status := Keybinding_Action_Command_Not_Bindable;
         Set_Message (Action_Status_Label (Status));
      elsif Editor.Keybindings.Binding_Count_For_Command (State.Selected) = 0 then
         Status := Keybinding_Action_No_Keybinding_Selected;
         Set_Message (Action_Status_Label (Status));
      else
         Editor.Keybindings.Unbind_Command (State.Selected);
         State.Capture := Capture_Inactive;
         State.Has_Pending := False;
         State.Pending_Target := Editor.Commands.No_Command;
         State.Pending_Existing := Editor.Commands.No_Command;
         Status := Keybinding_Action_Ok;
         Set_Message ("Keybinding removed.");
      end if;
   end Remove_Selected;

   procedure Request_Reset_To_Defaults (Status : out Keybinding_Action_Status) is
   begin
      if State.Capture /= Capture_Inactive then
         Status := Keybinding_Action_Confirmation_Pending;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;

      State.Has_Pending := False;
      State.Pending_Target := Editor.Commands.No_Command;
      State.Pending_Existing := Editor.Commands.No_Command;
      State.Pending_Reset := True;
      Status := Keybinding_Action_Reset_Confirmation_Pending;
      Set_Message (Action_Status_Label (Status));
   end Request_Reset_To_Defaults;

   procedure Confirm_Reset_To_Defaults (Status : out Keybinding_Action_Status) is
   begin
      if not State.Pending_Reset then
         Status := Keybinding_Action_No_Keybinding_Selected;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;
      Reset_To_Defaults (Status);
   end Confirm_Reset_To_Defaults;

   procedure Cancel_Reset_To_Defaults (Status : out Keybinding_Action_Status) is
   begin
      if State.Pending_Reset then
         State.Pending_Reset := False;
      end if;
      Status := Keybinding_Action_Cancelled;
      Set_Message (Action_Status_Label (Status));
   end Cancel_Reset_To_Defaults;

   function Has_Pending_Reset return Boolean is (State.Pending_Reset);

   procedure Reset_To_Defaults (Status : out Keybinding_Action_Status) is
   begin
      Editor.Keybindings.Reset_To_Defaults;
      State.Capture := Capture_Inactive;
      State.Has_Pending := False;
      State.Pending_Reset := False;
      State.Pending_Target := Editor.Commands.No_Command;
      State.Pending_Existing := Editor.Commands.No_Command;
      State.Has_Selected_Chord := False;
      Status := Keybinding_Action_Ok;
      Set_Message ("Keybindings reset to defaults.");
   end Reset_To_Defaults;

   procedure Save (Path : String; Status : out Keybinding_Action_Status) is
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Save_Status : Editor.Keybinding_Config.Keybinding_Config_Status;
   begin
      if State.Pending_Reset or else State.Capture /= Capture_Inactive then
         Status := Keybinding_Action_Confirmation_Pending;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;
      Editor.Keybinding_Config.Build_From_Runtime (Config);
      Editor.Keybinding_Config.Save_To_File (Config, Path, Save_Status);
      if Save_Status = Editor.Keybinding_Config.Keybinding_Config_Ok then
         Status := Keybinding_Action_Ok;
         Set_Message ("Keybindings saved.");
      else
         Status := Keybinding_Action_IO_Failed;
         Set_Message (Action_Status_Label (Status));
      end if;
   end Save;

   procedure Load (Path : String; Status : out Keybinding_Action_Status) is
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Load_Status : Editor.Keybinding_Config.Keybinding_Config_Status;
   begin
      if State.Pending_Reset or else State.Capture /= Capture_Inactive then
         Status := Keybinding_Action_Confirmation_Pending;
         Set_Message (Action_Status_Label (Status));
         return;
      end if;
      Editor.Keybinding_Config.Load_From_File (Path, Config, Load_Status);
      if Load_Status = Editor.Keybinding_Config.Keybinding_Config_Ok
        or else Load_Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load
      then
         Editor.Keybinding_Config.Apply_To_Runtime (Config);
         Status := Keybinding_Action_Ok;
         if Load_Status = Editor.Keybinding_Config.Keybinding_Config_Partial_Load then
            Set_Message ("Keybindings loaded with ignored invalid entries. "
                         & Last_Load_Diagnostics_Label);
         else
            Set_Message ("Keybindings loaded.");
         end if;
      else
         Status := Keybinding_Action_IO_Failed;
         Set_Message (Editor.Keybinding_Config.Status_Label (Load_Status));
      end if;
   end Load;

   function Action_Status_Label (Status : Keybinding_Action_Status) return String is
   begin
      case Status is
         when Keybinding_Action_Ok =>
            return "Keybinding operation completed.";
         when Keybinding_Action_No_Command_Selected =>
            return "No command selected.";
         when Keybinding_Action_Command_Not_Bindable =>
            return "Command is not bindable.";
         when Keybinding_Action_Invalid_Shortcut =>
            return "Invalid shortcut.";
         when Keybinding_Action_Shortcut_Already_Assigned =>
            return "Shortcut is already assigned.";
         when Keybinding_Action_No_Keybinding_Selected =>
            return "No keybinding selected.";
         when Keybinding_Action_Reset_Confirmation_Pending =>
            return "Reset keybindings requires confirmation.";
         when Keybinding_Action_Confirmation_Pending =>
            return "Command unavailable while confirmation is pending.";
         when Keybinding_Action_Cancelled =>
            return "Keybinding assignment cancelled.";
         when Keybinding_Action_IO_Failed =>
            return "Keybinding operation failed.";
      end case;
   end Action_Status_Label;

   function Latest_Message return String is (To_String (State.Last_Message));

   function Assert_Keybinding_Surface_Render_Is_Observational return Boolean is
      Before : constant Keybinding_Surface_Snapshot := Build_Surface_Snapshot;
      Count_Before : constant Natural :=
        Editor.Keybindings.Binding_Count_For_Command (Editor.Commands.Command_Save_File);
      After  : Keybinding_Surface_Snapshot;
      Count_After : Natural;
   begin
      After := Build_Surface_Snapshot;
      Count_After :=
        Editor.Keybindings.Binding_Count_For_Command (Editor.Commands.Command_Save_File);
      return Before.Row_Count = After.Row_Count
        and then Before.Chord_Row_Count = After.Chord_Row_Count
        and then Before.Display_Row_Count = After.Display_Row_Count
        and then Before.Display_Chord_Row_Count = After.Display_Chord_Row_Count
        and then Before.Capture = After.Capture
        and then Before.Has_Pending_Conflict = After.Has_Pending_Conflict
        and then Before.Has_Pending_Reset = After.Has_Pending_Reset
        and then Count_Before = Count_After;
   end Assert_Keybinding_Surface_Render_Is_Observational;

   function Assert_Keybinding_Editor_State_Not_Persisted return Boolean is
      Snapshot : constant Keybinding_Surface_Snapshot := Build_Surface_Snapshot;
   begin
      --  The editor state handled by this package is intentionally transient:
      --  rows, query, filters, selections, capture, conflict/reset prompts, and
      --  messages are derived or UI-local. The only Phase 565 persisted data is
      --  still owned by Editor.Keybinding_Config: normalized chord -> stable
      --  command name plus supported unbind markers. This predicate gives tests
      --  and audits a named invariant without writing any file.
      return Snapshot.Row_Count = Row_Count
        and then Snapshot.Chord_Row_Count = Chord_Row_Count
        and then Snapshot.Display_Row_Count <= Max_Surface_Rows
        and then Snapshot.Display_Chord_Row_Count <= Max_Surface_Rows;
   end Assert_Keybinding_Editor_State_Not_Persisted;

   function Assert_Keybinding_Management_Coherent return Boolean is
      Before : constant Keybinding_List_Summary := Summary;
      Status : Keybinding_Action_Status;
      Found  : Boolean := False;
      Parsed : constant Editor.Keybindings.Key_Chord :=
        Editor.Keybindings.Parse_Chord ("Shift+Ctrl+P", Found);
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Resolved : Editor.Keybindings.Binding_Result;
      Validation : constant Editor.Keybindings.Keybinding_Validation_Result :=
        Editor.Keybindings.Validate;
   begin
      if Before.Row_Count = 0 then
         return False;
      end if;
      if not Found or else Editor.Keybindings.Format_Chord (Parsed) /= "Ctrl+Shift+P" then
         return False;
      end if;
      if Editor.Keybindings.Status (Validation) /= Editor.Keybindings.Valid_Keybindings then
         return False;
      end if;
      Select_Command (Editor.Commands.Command_Find_Show);
      Begin_Assign_Selected (Status);
      if Status /= Keybinding_Action_Ok then
         return False;
      end if;
      Cancel_Capture (Status);
      if Status /= Keybinding_Action_Cancelled then
         return False;
      end if;
      Resolved := Editor.Keybindings.Resolve (Parsed, Actual);
      return Resolved = Editor.Keybindings.No_Binding
        or else Resolved = Editor.Keybindings.Bound_Command;
   end Assert_Keybinding_Management_Coherent;

end Editor.Keybinding_Management;
