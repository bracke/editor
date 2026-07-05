with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Project;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Quick_Open;
with Editor.Project_Search;
with Editor.Outline;
with Editor.Diagnostics;
with Editor.Recent_Projects;
with Editor.Build_UI;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Executor;
with Editor.Command_Execution;
with Editor.Command_Palette;
with Editor.Configuration_Audit;
with Editor.Configuration_Recovery;
with Editor.Feature_Diagnostics;
with Editor.Keybindings;
with Editor.Messages;

package body Editor.Empty_State_Guidance is

   use type Editor.File_Tree.File_Tree_Node_Id;

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.File_Tree.File_Tree_Scan_Status;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Project_Search.Project_Replace_Preview_Status;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.Build_UI.Build_Candidate_Refresh_Status;
   use type Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status;
   use type Editor.Build_Output_Details.Build_Output_Details_Kind;
   use type Editor.Feature_Diagnostics.Diagnostic_Severity;

   function Safe_Stable_Command_Name (Name : String) return Boolean is
   begin
      return Name'Length > 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), " ") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), ":") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "/") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "\") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "?") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Name), "=") = 0;
   end Safe_Stable_Command_Name;

   function Has_Active_Buffer (S : Editor.State.State_Type) return Boolean is
   begin
      return S.Active_Buffer_Token /= 0 or else S.File_Info.Has_Path;
   end Has_Active_Buffer;

   function Suggested_Action_Guard_Label
     (Command : Editor.Commands.Command_Id) return String
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Command);
   begin
      if Command = Editor.Commands.Command_Build_Acknowledge_Consent then
         return "Consent required";
      elsif D.Target_Prompt_Capable or else D.Requires_Explicit_Target then
         return "Requires input";
      elsif D.Destructive then
         return "Requires confirmation";
      elsif D.Lifecycle then
         return "Project/file safety check";
      elsif D.Configuration then
         return "Configuration safety check";
      else
         return "";
      end if;
   end Suggested_Action_Guard_Label;

   function Suggested_Action_Label_With_Guard
     (Base    : String;
      Command : Editor.Commands.Command_Id) return String
   is
      Guard : constant String := Suggested_Action_Guard_Label (Command);
   begin
      if Guard'Length = 0 then
         return Base;
      elsif Base'Length = 0 then
         return Guard;
      else
         return Base & "; " & Guard;
      end if;
   end Suggested_Action_Label_With_Guard;

   function Pending_Confirmation_Blocks_Suggestion
     (Command : Editor.Commands.Command_Id) return Boolean
   is
   begin
      if not Editor.Configuration_Recovery.Has_Pending_Reset_All_Confirmation then
         return False;
      end if;

      return Command /= Editor.Commands.Command_Configuration_Reset_All_Confirm
        and then Command /= Editor.Commands.Command_Configuration_Reset_All_Cancel;
   end Pending_Confirmation_Blocks_Suggestion;

   function Command_Is_Visible_In_Guidance
     (Command : Editor.Commands.Command_Id) return Boolean
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Command);
   begin
      return D.Visibility = Editor.Commands.Palette_Command
        or else Command = Editor.Commands.Command_Open_Command_Palette;
   end Command_Is_Visible_In_Guidance;

   procedure Set_Text
     (Snapshot  : in out Empty_State_Snapshot;
      Surface   : Empty_State_Surface;
      Kind      : Empty_State_Kind;
      Primary   : String;
      Secondary : String := "";
      Severity  : Empty_State_Severity := Empty_Info)
   is
   begin
      Snapshot.Surface := Surface;
      Snapshot.Kind := Kind;
      Snapshot.Primary_Message :=
        To_Unbounded_String (Editor.Commands.Normalize_Workflow_Message (Primary));
      Snapshot.Secondary_Explanation :=
        To_Unbounded_String (Editor.Commands.Normalize_Workflow_Message (Secondary));
      Snapshot.Severity := Severity;
   end Set_Text;

   function Canonical_Surface_Suggestion
     (S       : Editor.State.State_Type;
      Surface : Empty_State_Surface;
      Command : Editor.Commands.Command_Id)
      return Empty_State_Suggested_Command
   is
      Suggestion : Empty_State_Suggested_Command :=
        Command_Suggestion_From_Descriptor (S, Command);
   begin
      --  keeps every surface-specific guided action on one
      --  construction path: descriptor projection first, then the emitting
      --  surface label only.  No caller may attach paths, row ids, result ids,
      --  recovery domains, setting values, or other hidden payload state.
      if Suggestion.Visible then
         Suggestion.Surface_Source_Label :=
           To_Unbounded_String (Empty_State_Surface_Label (Surface));
      end if;
      return Suggestion;
   end Canonical_Surface_Suggestion;

   procedure Add_Suggestion
     (Snapshot : in out Empty_State_Snapshot;
      S        : Editor.State.State_Type;
      Command  : Editor.Commands.Command_Id)
   is
      Suggestion : Empty_State_Suggested_Command :=
        Canonical_Surface_Suggestion (S, Snapshot.Surface, Command);
   begin
      if not Suggestion.Visible
        or else Snapshot.Suggestion_Count >= Max_Empty_State_Suggestions
      then
         return;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Command = Suggestion.Command
           or else To_String (Snapshot.Suggestions (I).Stable_Name) =
             To_String (Suggestion.Stable_Name)
         then
            return;
         end if;
      end loop;

      Snapshot.Suggestion_Count := Snapshot.Suggestion_Count + 1;
      Snapshot.Suggestions (Snapshot.Suggestion_Count) := Suggestion;
   end Add_Suggestion;


   function Build_All_Empty_State_Snapshots
     (S : Editor.State.State_Type) return Empty_State_Snapshot_Array
   is
   begin
      return
        (Build_Main_Empty_State (S),
         Build_File_Tree_Empty_State (S),
         Build_Quick_Open_Empty_State (S),
         Build_Project_Search_Empty_State (S),
         Build_Outline_Empty_State (S),
         Build_Diagnostics_Empty_State (S),
         Build_Build_UI_Empty_State (S),
         Build_Recent_Projects_Empty_State (S),
         Build_Config_Recovery_Empty_State (S));
   end Build_All_Empty_State_Snapshots;

   function Contains_Command_Suggestion
     (Snapshot : Empty_State_Snapshot;
      Command  : Editor.Commands.Command_Id) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Command = Command then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Command_Suggestion;

   function Selected_Diagnostic_Is_Source_Less
     (S : Editor.State.State_Type) return Boolean
   is
      D : Editor.Diagnostics.Diagnostic;
   begin
      if not S.Active_Diagnostic.Has_Active
        or else not Editor.Diagnostics.Is_Valid_Diagnostic_Index
          (S.Diagnostics, S.Active_Diagnostic.Index)
      then
         return False;
      end if;

      D := Editor.Diagnostics.Diagnostic_At
        (S.Diagnostics, Positive (S.Active_Diagnostic.Index));
      return not D.Has_Location;
   end Selected_Diagnostic_Is_Source_Less;

   function File_Tree_Selection_Is_Stale
     (S : Editor.State.State_Type) return Boolean
   is
      Found : Boolean := False;
      Selected_Row : constant Natural :=
        Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View);
      Node_Id : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
   begin
      if Selected_Row = 0 then
         return False;
      end if;

      Node_Id := Editor.File_Tree_View.Node_For_Row
        (S.File_Tree, Selected_Row, Found);
      return not Found
        or else Node_Id = Editor.File_Tree.No_File_Tree_Node
        or else not Editor.File_Tree.Contains (S.File_Tree, Node_Id);
   end File_Tree_Selection_Is_Stale;

   function Quick_Open_Selection_Is_Stale
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot) return Boolean
   is
   begin
      return Snapshot.Selected_Index > 0
        and then (Snapshot.Visible_Count = 0
                  or else Snapshot.Selected_Index > Snapshot.Visible_Count);
   end Quick_Open_Selection_Is_Stale;

   function Feature_Diagnostics_Has_Stale_Target
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) loop
         if Editor.Feature_Diagnostics.Item_Is_Stale
           (S.Feature_Diagnostics, Positive (I))
         then
            return True;
         end if;
      end loop;
      return False;
   end Feature_Diagnostics_Has_Stale_Target;

   function Feature_Diagnostics_Selected_Source_Less
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Feature_Diagnostics.Has_Selected_Diagnostic
          (S.Feature_Diagnostics, S.Feature_Panel)
        and then Editor.Feature_Diagnostics.Selected_Diagnostic_Target_Unavailable_Label
          (S.Feature_Diagnostics, S.Feature_Panel) = "No source target";
   end Feature_Diagnostics_Selected_Source_Less;

   function Feature_Diagnostics_Selected_Unavailable_Reason
     (S : Editor.State.State_Type) return String
   is
      Reason : constant String :=
        Editor.Feature_Diagnostics.Selected_Diagnostic_Open_Unavailable_Reason
          (S.Feature_Diagnostics, S.Feature_Panel);
   begin
      if not Editor.Feature_Diagnostics.Has_Selected_Diagnostic
        (S.Feature_Diagnostics, S.Feature_Panel)
        or else Feature_Diagnostics_Selected_Source_Less (S)
        or else Reason'Length = 0
      then
         return "";
      end if;

      return Reason;
   end Feature_Diagnostics_Selected_Unavailable_Reason;


   function Command_Suggestion_From_Descriptor
     (S       : Editor.State.State_Type;
      Command : Editor.Commands.Command_Id)
      return Empty_State_Suggested_Command
   is
      R : Empty_State_Suggested_Command;
   begin
      if Command = Editor.Commands.No_Command then
         return R;
      end if;

      declare
         D : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Command);
         A : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability (S, Command);
         Stable : constant String := Editor.Commands.Stable_Command_Name (Command);
      begin
         if not Command_Is_Visible_In_Guidance (Command)
           or else Stable'Length = 0
           or else not Safe_Stable_Command_Name (Stable)
         then
            return R;
         end if;

         R.Command := Command;
         R.Stable_Name := To_Unbounded_String (Stable);
         R.Title := D.Name;
         R.Short_Explanation := D.Description;
         R.Surface_Source_Label := To_Unbounded_String ("empty-state guidance");
         R.Available := Editor.Commands.Is_Available (A);
         R.Visible := True;
         R.Carries_Payload := False;
         R.Activation_Mode := Suggestion_Execute_Through_Executor;

         if Command = Editor.Commands.Command_Open_Command_Palette then
            --  Opening the palette from guidance is itself palette entry, not
            --  a hidden execution shortcut.  This remains payload-free and
            --  lets the user review availability before choosing a command.
            R.Activation_Mode := Suggestion_Open_In_Command_Palette;
         end if;

         R.Availability_Label :=
           To_Unbounded_String
             (Suggested_Action_Label_With_Guard
                ((if R.Available then "Available" else "Unavailable"), Command));
         if not R.Available then
            R.Unavailable_Reason :=
              To_Unbounded_String (Editor.Commands.Unavailable_Reason (A));
            if Length (R.Unavailable_Reason) > 0 then
               R.Availability_Label :=
                 To_Unbounded_String
                   (Suggested_Action_Label_With_Guard
                      ("Unavailable: " & To_String (R.Unavailable_Reason),
                       Command));
            end if;
         end if;
      end;

      return R;
   end Command_Suggestion_From_Descriptor;

   function Stable_Name_Is_Display_Only
     (Name : String) return Boolean
   is
      Found    : Boolean := False;
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      if not Safe_Stable_Command_Name (Name) then
         return False;
      end if;

      Resolved := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      if not Found or else Resolved = Editor.Commands.No_Command then
         return False;
      end if;

      return Command_Is_Visible_In_Guidance (Resolved);
   end Stable_Name_Is_Display_Only;

   function Suggestion_Is_Descriptor_Consistent
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
      Found    : Boolean := False;
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Name     : constant String := To_String (Suggestion.Stable_Name);
   begin
      if not Suggestion.Visible
        or else Suggestion.Command = Editor.Commands.No_Command
        or else Suggestion.Carries_Payload
        or else not Stable_Name_Is_Display_Only (Name)
      then
         return False;
      end if;

      Resolved := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      if not Found
        or else Resolved /= Suggestion.Command
        or else not Command_Is_Visible_In_Guidance (Suggestion.Command)
        or else To_String (Suggestion.Title) /=
          To_String (Editor.Commands.Descriptor (Suggestion.Command).Name)
        or else To_String (Suggestion.Short_Explanation) /=
          To_String (Editor.Commands.Descriptor (Suggestion.Command).Description)
      then
         return False;
      end if;

      return Name = Editor.Commands.Stable_Command_Name (Suggestion.Command);
   end Suggestion_Is_Descriptor_Consistent;

   function Suggestion_Is_Activation_Safe
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
   begin
      return Suggestion_Is_Descriptor_Consistent (Suggestion);
   end Suggestion_Is_Activation_Safe;

   function Suggestion_Is_Selectable
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
   begin
      return Suggestion_Is_Activation_Safe (Suggestion)
        and then Suggestion.Activation_Mode /= Suggestion_Display_Only;
   end Suggestion_Is_Selectable;

   function Suggested_Action_Availability_Label
     (Suggestion : Empty_State_Suggested_Command) return String
   is
   begin
      if Length (Suggestion.Availability_Label) > 0 then
         return To_String (Suggestion.Availability_Label);
      elsif Suggestion.Available then
         return Suggested_Action_Label_With_Guard ("Available", Suggestion.Command);
      elsif Length (Suggestion.Unavailable_Reason) > 0 then
         return Suggested_Action_Label_With_Guard
           ("Unavailable: " & To_String (Suggestion.Unavailable_Reason),
            Suggestion.Command);
      else
         return Suggested_Action_Label_With_Guard ("Unavailable", Suggestion.Command);
      end if;
   end Suggested_Action_Availability_Label;

   function Suggested_Action_Select_Next
     (Snapshot      : Empty_State_Snapshot;
      Current_Index : Natural) return Natural
   is
      Start : Natural := Current_Index;
      Probe : Natural := 0;
   begin
      if Snapshot.Suggestion_Count = 0 then
         return 0;
      end if;

      if Start = 0 or else Start > Snapshot.Suggestion_Count then
         Start := Snapshot.Suggestion_Count;
      end if;

      for Step in 1 .. Snapshot.Suggestion_Count loop
         Probe := ((Start + Step - 1) mod Snapshot.Suggestion_Count) + 1;
         if Suggestion_Is_Selectable (Snapshot.Suggestions (Probe)) then
            return Probe;
         end if;
      end loop;

      return 0;
   end Suggested_Action_Select_Next;

   function Suggested_Action_Select_Previous
     (Snapshot      : Empty_State_Snapshot;
      Current_Index : Natural) return Natural
   is
      Start : Natural := Current_Index;
      Probe : Natural := 0;
   begin
      if Snapshot.Suggestion_Count = 0 then
         return 0;
      end if;

      if Start = 0 or else Start > Snapshot.Suggestion_Count then
         Start := 1;
      end if;

      for Step in 1 .. Snapshot.Suggestion_Count loop
         Probe := ((Start + Snapshot.Suggestion_Count - Step - 1)
                   mod Snapshot.Suggestion_Count) + 1;
         if Suggestion_Is_Selectable (Snapshot.Suggestions (Probe)) then
            return Probe;
         end if;
      end loop;

      return 0;
   end Suggested_Action_Select_Previous;

   function Suggested_Action_Selected_Index
     (Snapshot : Empty_State_Snapshot) return Natural
   is
      Found : Natural := 0;
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Selected then
            if Found /= 0 then
               return 0;
            end if;

            if not Suggestion_Is_Selectable (Snapshot.Suggestions (I)) then
               return 0;
            end if;

            Found := I;
         end if;
      end loop;

      for I in Snapshot.Suggestion_Count + 1 .. Max_Empty_State_Suggestions loop
         if Snapshot.Suggestions (I).Selected then
            return 0;
         end if;
      end loop;

      return Found;
   end Suggested_Action_Selected_Index;

   procedure Mark_Selected_Suggestion
     (Snapshot : in out Empty_State_Snapshot;
      Index    : Natural)
   is
   begin
      for I in 1 .. Max_Empty_State_Suggestions loop
         Snapshot.Suggestions (I).Selected :=
           Index /= 0
           and then I = Index
           and then I <= Snapshot.Suggestion_Count
           and then Suggestion_Is_Selectable (Snapshot.Suggestions (I));
      end loop;
   end Mark_Selected_Suggestion;

   function Open_Suggested_Command_In_Command_Palette
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean
   is
      Suggestion : Empty_State_Suggested_Command;
      Found      : Boolean := False;
      Resolved   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return False;
      end if;

      Suggestion := Snapshot.Suggestions (Index);
      if not Assert_Suggested_Action_Index_Is_Activatable (Snapshot, Index)
        or else not Suggestion_Is_Selectable (Suggestion)
      then
         return False;
      end if;

      Resolved := Editor.Commands.Command_Id_From_Stable_Name
        (To_String (Suggestion.Stable_Name), Found);
      if not Found
        or else Resolved = Editor.Commands.No_Command
        or else Resolved /= Suggestion.Command
      then
         return False;
      end if;

      if Pending_Confirmation_Blocks_Suggestion (Resolved) then
         return False;
      end if;

      if Resolved = Editor.Commands.Command_Open_Command_Palette then
         Editor.Command_Palette.Open;
         return Editor.Command_Palette.Is_Open;
      else
         Editor.Command_Palette.Open_With_Command (Resolved);
         return Editor.Command_Palette.Is_Open
           and then Editor.Command_Palette.Selected_Command = Resolved;
      end if;
   end Open_Suggested_Command_In_Command_Palette;

   function Open_Selected_Suggested_Command_In_Command_Palette
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Selected : constant Natural := Suggested_Action_Selected_Index (Snapshot);
   begin
      if Selected = 0 then
         return False;
      end if;

      return Open_Suggested_Command_In_Command_Palette
        (Snapshot, Positive (Selected));
   end Open_Selected_Suggested_Command_In_Command_Palette;

   function Execute_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Index    : Positive)
      return Editor.Executor.Command_Execution_Result
   is
      Suggestion : Empty_State_Suggested_Command;
      Found      : Boolean := False;
      Resolved   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      A          : Editor.Commands.Command_Availability;
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      end if;

      Suggestion := Snapshot.Suggestions (Index);
      if not Assert_Suggested_Action_Index_Is_Activatable (Snapshot, Index)
        or else not Suggestion_Is_Activation_Safe (Suggestion)
      then
         return Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      end if;

      Resolved := Editor.Commands.Command_Id_From_Stable_Name
        (To_String (Suggestion.Stable_Name), Found);
      if not Found
        or else Resolved = Editor.Commands.No_Command
        or else Resolved /= Suggestion.Command
      then
         return Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      end if;

      if Suggestion.Activation_Mode /= Suggestion_Execute_Through_Executor then
         return Editor.Command_Execution.No_Op (Resolved);
      end if;

      if Pending_Confirmation_Blocks_Suggestion (Resolved) then
         Editor.Messages.Push_Info
           (S.Messages, "Finish the pending confirmation before using guided actions");
         return Editor.Command_Execution.Unavailable (Resolved);
      end if;

      A := Editor.Executor.Command_Availability (S, Resolved);
      if not Editor.Commands.Is_Available (A) then
         --  Preserve the normal unavailable-command reporting path: guided
         --  execution observes availability first, then delegates to Executor
         --  so the user sees the canonical unavailable reason/message.
         return Editor.Executor.Execute_Command_With_Result (S, Resolved);
      end if;

      return Editor.Executor.Execute_Command_With_Result (S, Resolved);
   end Execute_Suggested_Command;

   function Activate_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot;
      Index    : Positive)
      return Editor.Executor.Command_Execution_Result
   is
      Suggestion : Empty_State_Suggested_Command;
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      end if;

      Suggestion := Snapshot.Suggestions (Index);
      if not Assert_Suggested_Action_Index_Is_Activatable (Snapshot, Index)
        or else not Suggestion_Is_Activation_Safe (Suggestion)
      then
         return Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      end if;

      if Pending_Confirmation_Blocks_Suggestion (Suggestion.Command) then
         Editor.Messages.Push_Info
           (S.Messages, "Finish the pending confirmation before using guided actions");
         return Editor.Command_Execution.Unavailable (Suggestion.Command);
      end if;

      case Suggestion.Activation_Mode is
         when Suggestion_Display_Only =>
            return Editor.Command_Execution.No_Op (Suggestion.Command);
         when Suggestion_Open_In_Command_Palette =>
            if Open_Suggested_Command_In_Command_Palette (Snapshot, Index) then
               return Editor.Command_Execution.Executed
                 (Editor.Commands.Command_Open_Command_Palette);
            else
               return Editor.Command_Execution.Failed
                 (Editor.Commands.Command_Open_Command_Palette);
            end if;
         when Suggestion_Execute_Through_Executor =>
            return Execute_Suggested_Command (S, Snapshot, Index);
      end case;
   end Activate_Suggested_Command;

   function Execute_Selected_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot)
      return Editor.Executor.Command_Execution_Result
   is
      Selected : constant Natural := Suggested_Action_Selected_Index (Snapshot);
   begin
      if Selected = 0 then
         return Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      end if;

      return Execute_Suggested_Command (S, Snapshot, Positive (Selected));
   end Execute_Selected_Suggested_Command;

   function Activate_Selected_Suggested_Command
     (S        : in out Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot)
      return Editor.Executor.Command_Execution_Result
   is
      Selected : constant Natural := Suggested_Action_Selected_Index (Snapshot);
   begin
      if Selected = 0 then
         return Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      end if;

      return Activate_Suggested_Command (S, Snapshot, Positive (Selected));
   end Activate_Selected_Suggested_Command;

   function Assert_Guided_Action_Routing_Coherent
     (S : Editor.State.State_Type) return Boolean
   is
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      if not Assert_Empty_State_Array_Is_Display_Only (Snapshots) then
         return False;
      end if;

      for Surface_Index in Snapshots'Range loop
         declare
            Snapshot : constant Empty_State_Snapshot := Snapshots (Surface_Index);
         begin
            for I in 1 .. Snapshot.Suggestion_Count loop
               if not Suggestion_Is_Activation_Safe (Snapshot.Suggestions (I))
                 or else Snapshot.Suggestions (I).Carries_Payload
                 or else Length (Snapshot.Suggestions (I).Stable_Name) = 0
                 or else not Safe_Stable_Command_Name
                   (To_String (Snapshot.Suggestions (I).Stable_Name))
                 or else Length (Snapshot.Suggestions (I).Title) = 0
                 or else Length (Snapshot.Suggestions (I).Availability_Label) = 0
                 or else not Assert_Suggested_Action_Metadata_Is_Current
                   (Snapshot.Suggestions (I))
                 or else not Assert_Suggested_Action_Is_Canonical_Surface_Projection
                   (S, Snapshot.Surface, Snapshot.Suggestions (I))
                 or else not Assert_Suggested_Action_Source_Label_Is_Surface_Owned
                   (Snapshot, Positive (I))
                 or else not Assert_Suggested_Action_Availability_Label_Is_Current
                   (S, Snapshot.Suggestions (I))
                 or else not Assert_Suggested_Action_Activation_Mode_Is_Coherent
                   (Snapshot.Suggestions (I))
               then
                  return False;
               end if;
            end loop;
         end;
      end loop;

      return True;
   end Assert_Guided_Action_Routing_Coherent;



   function Empty_State_Surface_Count return Natural
   is
      Count : Natural := 0;
   begin
      for Surface in Empty_State_Surface loop
         Count := Count + 1;
      end loop;
      return Count;
   end Empty_State_Surface_Count;

   function Empty_State_Surface_For_Slot
     (Index : Positive) return Empty_State_Surface
   is
   begin
      case Index is
         when 1 => return Main_Surface;
         when 2 => return File_Tree_Surface;
         when 3 => return Quick_Open_Surface;
         when 4 => return Project_Search_Surface;
         when 5 => return Outline_Surface;
         when 6 => return Diagnostics_Surface;
         when 7 => return Build_Surface;
         when 8 => return Recent_Projects_Surface;
         when others => return Configuration_Recovery_Surface;
      end case;
   end Empty_State_Surface_For_Slot;

   function Empty_State_Slot_For_Surface
     (Surface : Empty_State_Surface) return Positive
   is
   begin
      case Surface is
         when Main_Surface => return 1;
         when File_Tree_Surface => return 2;
         when Quick_Open_Surface => return 3;
         when Project_Search_Surface => return 4;
         when Outline_Surface => return 5;
         when Diagnostics_Surface => return 6;
         when Build_Surface => return 7;
         when Recent_Projects_Surface => return 8;
         when Configuration_Recovery_Surface => return 9;
      end case;
   end Empty_State_Slot_For_Surface;

   function Assert_Empty_State_Surface_Model_Is_Closed return Boolean
   is
      Count : Natural := 0;
      Seen  : array (Positive range 1 .. Max_Empty_State_Surfaces) of Boolean :=
        (others => False);
   begin
      --  Keep the enum, the aggregate slot count, and the two mapping helpers
      --  locked together.  This catches future surface additions that update
      --  one representation but forget the render-facing aggregate contract.
      for Surface in Empty_State_Surface loop
         declare
            Slot : constant Positive := Empty_State_Slot_For_Surface (Surface);
         begin
            Count := Count + 1;
            if Slot not in 1 .. Max_Empty_State_Surfaces
              or else Seen (Slot)
              or else Empty_State_Surface_For_Slot (Slot) /= Surface
            then
               return False;
            end if;
            Seen (Slot) := True;
         end;
      end loop;

      if Count /= Max_Empty_State_Surfaces
        or else Empty_State_Surface_Count /= Max_Empty_State_Surfaces
      then
         return False;
      end if;

      for Slot in 1 .. Max_Empty_State_Surfaces loop
         if not Seen (Slot)
           or else Empty_State_Slot_For_Surface
             (Empty_State_Surface_For_Slot (Slot)) /= Slot
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Surface_Model_Is_Closed;

   function Empty_State_Surface_Label
     (Surface : Empty_State_Surface) return String
   is
   begin
      case Surface is
         when Main_Surface =>
            return "Main";
         when File_Tree_Surface =>
            return "File Tree";
         when Quick_Open_Surface =>
            return "Quick Open";
         when Project_Search_Surface =>
            return "Project Search";
         when Outline_Surface =>
            return "Outline";
         when Diagnostics_Surface =>
            return "Diagnostics";
         when Build_Surface =>
            return "Build";
         when Recent_Projects_Surface =>
            return "Recent Projects";
         when Configuration_Recovery_Surface =>
            return "Configuration Recovery";
      end case;
   end Empty_State_Surface_Label;

   function Empty_State_Kind_Label
     (Kind : Empty_State_Kind) return String
   is
   begin
      case Kind is
         when First_Run_State => return "first run";
         when Ready_State => return "ready";
         when No_Project_State => return "no project";
         when No_Active_Buffer_State => return "no active buffer";
         when Unsupported_Buffer_State => return "unsupported buffer";
         when Different_Buffer_State => return "different buffer";
         when No_Files_State => return "no files";
         when Not_Refreshed_State => return "not refreshed";
         when Refresh_Required_State => return "refresh required";
         when No_Results_State => return "no results";
         when No_Candidates_State => return "no candidates";
         when No_Recent_Projects_State => return "no recent projects";
         when No_Diagnostics_State => return "no diagnostics";
         when Filtered_None_State => return "filtered none";
         when Source_Less_Selected_State => return "source-less selected";
         when No_Build_Diagnostics_State => return "no build diagnostics";
         when No_Query_State => return "no query";
         when No_Matches_State => return "no matches";
         when No_Symbols_State => return "no symbols";
         when Stale_State => return "stale";
         when Missing_Target_State => return "missing target";
         when Missing_Root_State => return "missing root";
         when Empty_Project_State => return "empty project";
         when Limit_Reached_State => return "limit reached";
         when Replace_Preview_Empty_State => return "replace preview empty";
         when Consent_Required_State => return "consent required";
         when No_Selected_Candidate_State => return "no selected candidate";
         when Request_Invalid_State => return "request invalid";
         when No_Result_State => return "no result";
         when No_Output_State => return "no output";
         when Diagnostics_Disabled_State => return "diagnostics disabled";
         when Selected_Unavailable_State => return "selected unavailable";
         when Only_Missing_Projects_State => return "only missing projects";
         when Clean_State => return "clean";
         when Configuration_Warning_State => return "configuration warning";
         when Safe_Defaults_State => return "safe defaults";
         when Audit_Not_Run_State => return "audit not run";
         when Unavailable_State => return "unavailable";
      end case;
   end Empty_State_Kind_Label;

   function Empty_State_Severity_Label
     (Severity : Empty_State_Severity) return String
   is
   begin
      case Severity is
         when Empty_Info => return "info";
         when Empty_Warning => return "warning";
         when Empty_Error => return "error";
      end case;
   end Empty_State_Severity_Label;

   function Empty_State_Should_Render
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      --  Ready surfaces are normal UI state, not empty-state guidance cards.
      --  The snapshot may still contain side-effect-free status details for
      --  diagnostics/debug assertions, but renderers should only draw guidance
      --  cards for explicit first-use, empty, stale, warning, or unavailable
      --  states.
      return Snapshot.Kind /= Ready_State;
   end Empty_State_Should_Render;

   function Empty_State_Renderable_Count
     (Snapshots : Empty_State_Snapshot_Array) return Natural
   is
      Count : Natural := 0;
   begin
      for I in Snapshots'Range loop
         if Empty_State_Should_Render (Snapshots (I)) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Empty_State_Renderable_Count;


   function Empty_State_Snapshots_Equivalent
     (Left  : Empty_State_Snapshot;
      Right : Empty_State_Snapshot) return Boolean
   is
   begin
      if Left.Surface /= Right.Surface
        or else Left.Kind /= Right.Kind
        or else Left.Severity /= Right.Severity
        or else To_String (Left.Primary_Message) /= To_String (Right.Primary_Message)
        or else To_String (Left.Secondary_Explanation) /=
          To_String (Right.Secondary_Explanation)
        or else Left.Suggestion_Count /= Right.Suggestion_Count
      then
         return False;
      end if;

      for I in 1 .. Max_Empty_State_Suggestions loop
         if Left.Suggestions (I).Command /= Right.Suggestions (I).Command
           or else To_String (Left.Suggestions (I).Stable_Name) /=
             To_String (Right.Suggestions (I).Stable_Name)
           or else To_String (Left.Suggestions (I).Title) /=
             To_String (Right.Suggestions (I).Title)
           or else To_String (Left.Suggestions (I).Short_Explanation) /=
             To_String (Right.Suggestions (I).Short_Explanation)
           or else To_String (Left.Suggestions (I).Surface_Source_Label) /=
             To_String (Right.Suggestions (I).Surface_Source_Label)
           or else To_String (Left.Suggestions (I).Availability_Label) /=
             To_String (Right.Suggestions (I).Availability_Label)
           or else Left.Suggestions (I).Activation_Mode /=
             Right.Suggestions (I).Activation_Mode
           or else Left.Suggestions (I).Selected /= Right.Suggestions (I).Selected
           or else Left.Suggestions (I).Available /= Right.Suggestions (I).Available
           or else To_String (Left.Suggestions (I).Unavailable_Reason) /=
             To_String (Right.Suggestions (I).Unavailable_Reason)
           or else Left.Suggestions (I).Visible /= Right.Suggestions (I).Visible
           or else Left.Suggestions (I).Carries_Payload /=
             Right.Suggestions (I).Carries_Payload
         then
            return False;
         end if;
      end loop;

      return True;
   end Empty_State_Snapshots_Equivalent;

   function Assert_Empty_State_Severity_Is_Semantic
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      case Snapshot.Kind is
         when Configuration_Warning_State
            | Safe_Defaults_State
            | Stale_State
            | Different_Buffer_State
            | Missing_Target_State
            | Missing_Root_State
            | Limit_Reached_State
            | Request_Invalid_State
            | Selected_Unavailable_State
            | Only_Missing_Projects_State
            | Unavailable_State =>
            return Snapshot.Severity = Empty_Warning
              or else Snapshot.Severity = Empty_Error;

         when Ready_State
            | First_Run_State
            | No_Project_State
            | No_Active_Buffer_State
            | Unsupported_Buffer_State
            | No_Files_State
            | Not_Refreshed_State
            | Refresh_Required_State
            | No_Results_State
            | No_Candidates_State
            | No_Recent_Projects_State
            | No_Diagnostics_State
            | Filtered_None_State
            | Source_Less_Selected_State
            | No_Build_Diagnostics_State
            | No_Query_State
            | No_Matches_State
            | No_Symbols_State
            | Empty_Project_State
            | Replace_Preview_Empty_State
            | Consent_Required_State
            | No_Selected_Candidate_State
            | No_Result_State
            | No_Output_State
            | Diagnostics_Disabled_State
            | Clean_State
            | Audit_Not_Run_State =>
            return Snapshot.Severity = Empty_Info;
      end case;
   end Assert_Empty_State_Severity_Is_Semantic;

   function Empty_State_Display_Line
     (Snapshot : Empty_State_Snapshot) return String
   is
      Surface : constant String := Empty_State_Surface_Label (Snapshot.Surface);
      Kind    : constant String := Empty_State_Kind_Label (Snapshot.Kind);
      Primary : constant String := To_String (Snapshot.Primary_Message);
      Secondary : constant String := To_String (Snapshot.Secondary_Explanation);
      Severity : constant String := Empty_State_Severity_Label (Snapshot.Severity);
      Prefix : constant String := Surface & " [" & Severity & "; " & Kind & "]: ";
   begin
      if Secondary'Length = 0 then
         return Prefix & Primary;
      end if;
      return Prefix & Primary & " " & Secondary;
   end Empty_State_Display_Line;

   function Suggestion_Display_Line
     (Suggestion : Empty_State_Suggested_Command) return String
   is
      Title : constant String := To_String (Suggestion.Title);
      Stable : constant String := To_String (Suggestion.Stable_Name);
      Reason : constant String := To_String (Suggestion.Unavailable_Reason);
      Prefix : constant String := Title & " [" & Stable & "]";
   begin
      if not Suggestion.Visible then
         return "";
      elsif Suggestion.Available then
         return Prefix;
      elsif Reason'Length > 0 then
         declare
            Available_Reason_Chars : constant Natural :=
              (if Prefix'Length >= 140 then 0 else 140 - Prefix'Length);
            Max_Reason : constant Natural :=
              Natural'Min (Reason'Length, Available_Reason_Chars);
         begin
            if Max_Reason = 0 then
               return Prefix & " unavailable";
            else
               return Prefix & " unavailable: " &
                 Reason (Reason'First .. Reason'First + Max_Reason - 1);
            end if;
         end;
      else
         return Prefix & " unavailable";
      end if;
   end Suggestion_Display_Line;

   function Assert_Empty_State_Text_Is_Deterministic_And_Compact
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Surface_Label : constant String := Empty_State_Surface_Label (Snapshot.Surface);
      Kind_Label    : constant String := Empty_State_Kind_Label (Snapshot.Kind);
      Severity_Label : constant String := Empty_State_Severity_Label (Snapshot.Severity);
      Display_Line : constant String := Empty_State_Display_Line (Snapshot);
   begin
      if Surface_Label'Length = 0
        or else Kind_Label'Length = 0
        or else Severity_Label'Length = 0
        or else Display_Line'Length = 0
        or else Display_Line'Length > 280
        or else Length (Snapshot.Primary_Message) = 0
        or else Length (Snapshot.Primary_Message) > 80
        or else Length (Snapshot.Secondary_Explanation) > 180
      then
         return False;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         declare
            Line : constant String := Suggestion_Display_Line (Snapshot.Suggestions (I));
         begin
            if Line'Length = 0 or else Line'Length > 160 then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Assert_Empty_State_Text_Is_Deterministic_And_Compact;

   function Assert_Empty_State_Display_Line_Is_Labelled
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Line     : constant Unbounded_String :=
        To_Unbounded_String (Empty_State_Display_Line (Snapshot));
      Surface  : constant String := Empty_State_Surface_Label (Snapshot.Surface);
      Kind     : constant String := Empty_State_Kind_Label (Snapshot.Kind);
      Severity : constant String := Empty_State_Severity_Label (Snapshot.Severity);
   begin
      --  Render-facing display text must carry all classification fields so a
      --  backend can render deterministic compact guidance without consulting
      --  mutable editor state or guessing which surface/kind produced it.
      return Index (Line, Surface) /= 0
        and then Index (Line, Kind) /= 0
        and then Index (Line, Severity) /= 0;
   end Assert_Empty_State_Display_Line_Is_Labelled;

   function Assert_Empty_State_Display_Line_Has_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Line : constant String := Empty_State_Display_Line (Snapshot);
   begin
      --  The final render-facing line is the string most likely to be copied
      --  into backends and snapshots.  Keep it free of path, URI, query, and
      --  payload delimiters as an explicit guard in addition to checking the
      --  individual fields.
      return Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), "/") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), "\") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), ":/") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), "?path=") = 0
        and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Line), "=") = 0;
   end Assert_Empty_State_Display_Line_Has_No_Target_Text;


   function Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      function Text_Is_Target_Free (Text : String) return Boolean is
      begin
         return Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "/") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "\") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), ":/") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "?path=") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "=") = 0;
      end Text_Is_Target_Free;
   begin
      --  Suggestions are rendered separately from the card line by several UI
      --  surfaces.  Guard those final render-facing strings too, not only the
      --  raw snapshot fields, so unavailable reasons cannot smuggle target or
      --  payload-looking text into an empty-state card.
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Text_Is_Target_Free
           (Suggestion_Display_Line (Snapshot.Suggestions (I)))
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text;

   function Assert_Empty_State_Array_Suggestion_Budget
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
      Total : Natural := 0;
   begin
      --  Aggregate guidance must remain compact at the array level, not just
      --  per surface.  This prevents a first-use screen from becoming a dense
      --  command list while preserving the bounded per-card suggestion limit.
      for I in Snapshots'Range loop
         if Snapshots (I).Suggestion_Count > Max_Empty_State_Suggestions then
            return False;
         end if;
         Total := Total + Snapshots (I).Suggestion_Count;
      end loop;

      return Total <= Max_Empty_State_Surfaces * Max_Empty_State_Suggestions;
   end Assert_Empty_State_Array_Suggestion_Budget;

   function Assert_Empty_State_Snapshot_Has_No_Target_Text
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      function Text_Is_Target_Free (Text : String) return Boolean is
      begin
         return Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "/") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "\") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), ":/") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "?path=") = 0
           and then Ada.Strings.Unbounded.Index (To_Unbounded_String (Text), "=") = 0;
      end Text_Is_Target_Free;
   begin
      if not Text_Is_Target_Free (To_String (Snapshot.Primary_Message))
        or else not Text_Is_Target_Free (To_String (Snapshot.Secondary_Explanation))
      then
         return False;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Text_Is_Target_Free (To_String (Snapshot.Suggestions (I).Stable_Name))
           or else not Text_Is_Target_Free (To_String (Snapshot.Suggestions (I).Title))
           or else not Text_Is_Target_Free (To_String (Snapshot.Suggestions (I).Unavailable_Reason))
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Snapshot_Has_No_Target_Text;

   function Build_Main_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Has_Project : constant Boolean := Editor.Project.Has_Project (S.Project);
      Has_Buffer  : constant Boolean := Has_Active_Buffer (S);
      Recent_Count : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
   begin
      if not Has_Project and then not Has_Buffer and then Recent_Count = 0 then
         Set_Text
           (Snapshot, Main_Surface, First_Run_State,
            "Start by opening a project.",
            "No project, buffer, workspace, or recent project is active. "
            & "Missing optional configuration files are normal on first run.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Restore_Workspace_State);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Show_Recent_Projects);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Command_Palette);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Recover_Show);
      elsif not Has_Project then
         Set_Text
           (Snapshot, Main_Surface, No_Project_State,
            "No project open.",
            "Open a project, restore workspace state, inspect recent projects, "
            & "or review configuration before editing.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Show_Recent_Projects);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Restore_Workspace_State);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Audit);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Reload_Settings);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Keybindings_Show);
      elsif not Has_Buffer then
         Set_Text (Snapshot, Main_Surface, No_Active_Buffer_State, "Project open; no file selected.",
                   "Use File Tree, Quick Open, Project Search, or Build candidate discovery to continue.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Focus_File_Tree);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Quick_Open);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project_Search_Bar);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_Project_Files);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      else
         Set_Text (Snapshot, Main_Surface, Ready_State, "Ready.");
      end if;
      return Snapshot;
   end Build_Main_Empty_State;

   function Build_File_Tree_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Scan : constant Editor.File_Tree.File_Tree_Scan_Result := Editor.File_Tree.Scan_Status (S.File_Tree);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Set_Text
           (Snapshot, File_Tree_Surface, No_Project_State,
            "No project open.", "Open a project before using File Tree.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
      elsif Scan.Status = Editor.File_Tree.File_Tree_No_Project then
         Set_Text (Snapshot, File_Tree_Surface, Not_Refreshed_State, "File Tree has not been refreshed.",
                   "Refresh builds the in-memory tree; this empty state does not scan the filesystem.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_File_Tree);
      elsif Scan.Status /= Editor.File_Tree.File_Tree_Scan_Ok then
         Set_Text (Snapshot, File_Tree_Surface, Missing_Root_State, "Project root unavailable.",
                   "File Tree target is stale; refresh after the project root is available.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_File_Tree);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
      elsif File_Tree_Selection_Is_Stale (S) then
         Set_Text (Snapshot, File_Tree_Surface, Stale_State,
                   "File Tree target is stale; refresh required.",
                   "The selected row no longer maps to a live File Tree node.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_File_Tree);
      elsif Editor.File_Tree.Is_Empty (S.File_Tree) then
         Set_Text (Snapshot, File_Tree_Surface, Not_Refreshed_State, "File Tree has not been refreshed.",
                   "No tree nodes are present and no placeholder nodes are created.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_File_Tree);
      elsif Editor.File_Tree.File_Node_Count (S.File_Tree) = 0 then
         Set_Text (Snapshot, File_Tree_Surface, Empty_Project_State, "No files found in project.",
                   "The tree contains no file rows and no placeholder nodes are created.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_File_Tree);
      else
         Set_Text (Snapshot, File_Tree_Surface, Ready_State, "File Tree ready.");
      end if;
      Add_Suggestion (Snapshot, S, Editor.Commands.Command_Reveal_Active_File_In_Tree);
      return Snapshot;
   end Build_File_Tree_Empty_State;

   function Build_Quick_Open_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Quick : constant Editor.Quick_Open.Quick_Open_Snapshot := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Set_Text (Snapshot, Quick_Open_Surface, No_Project_State, "Open a project to use Quick Open.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
      elsif Quick.Known_Count = 0 then
         Set_Text (Snapshot, Quick_Open_Surface, No_Candidates_State, "No project files available.",
                   "Refresh project files or File Tree before opening by name.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_File_Tree);
      elsif not Quick.Has_Query then
         Set_Text (Snapshot, Quick_Open_Surface, No_Query_State, "Type to search project files.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Quick_Open_Query_Clear);
      elsif Quick_Open_Selection_Is_Stale (Quick) then
         Set_Text (Snapshot, Quick_Open_Surface, Stale_State, "Selected result is stale.",
                   "Clear or update the query before opening a file.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Quick_Open_Query_Clear);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_File_Tree);
      elsif Quick.Visible_Count = 0 then
         Set_Text (Snapshot, Quick_Open_Surface, No_Matches_State, "No matching files.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Quick_Open_Query_Clear);
      else
         Set_Text (Snapshot, Quick_Open_Surface, Ready_State, "Quick Open ready.");
      end if;
      return Snapshot;
   end Build_Quick_Open_Empty_State;

   function Build_Project_Search_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Status : constant Editor.Project_Search.Project_Search_Status := Editor.Project_Search.Status (S.Project_Search);
      Replace_Status : constant Editor.Project_Search.Project_Replace_Preview_Status :=
        Editor.Project_Search.Replace_Preview_Status (S.Project_Search);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Set_Text (Snapshot, Project_Search_Surface, No_Project_State, "Open a project to search files.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
      elsif not Editor.Project_Search.Has_Query (S.Project_Search) then
         Set_Text (Snapshot, Project_Search_Surface, No_Query_State, "Enter a query and run Project Search.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project_Search_Bar);
      elsif Editor.Project_Search.Is_Stale (S.Project_Search) then
         Set_Text (Snapshot, Project_Search_Surface, Stale_State,
                   "Search results are stale.",
                   "Rerun Project Search before opening or replacing matches.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Rerun_Project_Search);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project_Search_Bar);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Clear_Project_Search);
      elsif Replace_Status = Editor.Project_Search.Project_Replace_Search_Stale
        or else Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search)
      then
         Set_Text (Snapshot, Project_Search_Surface, Stale_State,
                   "Replacement preview is stale.",
                   "Regenerate the preview before applying replacements.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Replace_Preview);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Replace_Clear_Preview);
      elsif Replace_Status = Editor.Project_Search.Project_Replace_No_Preview
        and then Editor.Project_Search.Result_Count (S.Project_Search) > 0
      then
         Set_Text (Snapshot, Project_Search_Surface, Replace_Preview_Empty_State, "No replacement preview.",
                   "Create a replace preview explicitly before applying replacements.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Replace_Preview);
      elsif Status = Editor.Project_Search.Project_Search_Idle then
         Set_Text (Snapshot, Project_Search_Surface, Not_Refreshed_State, "Project Search has not run.",
                   "Run search explicitly; this empty state does not compute matches.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Run_Project_Search);
      elsif Status = Editor.Project_Search.Project_Search_No_Files then
         Set_Text (Snapshot, Project_Search_Surface, No_Files_State, "No project files available.",
                   "Refresh File Tree or project files before searching.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_File_Tree);
      elsif Status = Editor.Project_Search.Project_Search_Invalid_Regex then
         Set_Text (Snapshot, Project_Search_Surface, Unavailable_State, "Project Search query is invalid.",
                   "Edit the query or disable regex mode.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project_Search_Bar);
      elsif Status = Editor.Project_Search.Project_Search_Read_Error then
         Set_Text
           (Snapshot, Project_Search_Surface, Unavailable_State,
            "Project Search could not read one or more files.",
            "Results are not repaired or re-run by this guidance.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Run_Project_Search);
      elsif Editor.Project_Search.Was_Truncated (S.Project_Search)
        or else Editor.Project_Search.Results_Truncated (S.Project_Search)
      then
         Set_Text (Snapshot, Project_Search_Surface, Limit_Reached_State, "Search limit reached.",
                   "Refine the query or scope and run Project Search again.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project_Search_Bar);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Scope_Clear);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Include_Filter_Clear);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Exclude_Filter_Clear);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Run_Project_Search);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Clear_Project_Search);
      elsif Editor.Project_Search.Result_Count (S.Project_Search) = 0 then
         Set_Text (Snapshot, Project_Search_Surface, No_Results_State,
                   "No Project Search matches.",
                   "Clear scope/filter options or adjust the query, then run Project Search again.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project_Search_Bar);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Scope_Clear);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Kind_Clear);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Include_Filter_Clear);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Exclude_Filter_Clear);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Run_Project_Search);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Clear_Project_Search);
      else
         Set_Text (Snapshot, Project_Search_Surface, Ready_State, "Project Search ready.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Selected_Project_Search_Result);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Next_Project_Search_Result);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Previous_Project_Search_Result);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Project_Search_Replace_Preview);
      end if;
      return Snapshot;
   end Build_Project_Search_Empty_State;

   function Build_Outline_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Source : constant Editor.Outline.Outline_Source_Class := Editor.Outline.Source_Class (S.Outline);
   begin
      if not Has_Active_Buffer (S) then
         Set_Text (Snapshot, Outline_Surface, No_Active_Buffer_State, "Open a file to use Outline.");
         if Editor.Project.Has_Project (S.Project) then
            Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Quick_Open);
            Add_Suggestion (Snapshot, S, Editor.Commands.Command_Focus_File_Tree);
         else
            Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
         end if;
      elsif Source = Editor.Outline.No_Outline then
         Set_Text (Snapshot, Outline_Surface, Not_Refreshed_State, "Refresh Outline to extract symbols.",
                   "No parsing is triggered by this guidance.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_Outline);
      elsif Source = Editor.Outline.Unsupported_Content then
         Set_Text (Snapshot, Outline_Surface, Unsupported_Buffer_State,
                   "Outline is unavailable for this buffer.",
                   "Open a supported source file or refresh after changing buffers.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_Outline);
      elsif Source = Editor.Outline.Extraction_Failed then
         Set_Text (Snapshot, Outline_Surface, Unavailable_State,
                   "Outline refresh failed.",
                   "Refresh explicitly after fixing the buffer or extractor input.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_Outline);
      elsif Source = Editor.Outline.Extracted_Outline
        and then not Editor.Outline.Outline_Buffer_Identity_Matches
          (S.Outline, S.Active_Buffer_Token)
      then
         Set_Text (Snapshot, Outline_Surface, Different_Buffer_State,
                   "Outline belongs to another buffer.",
                   "Refresh Outline for the active buffer before navigating.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_Outline);
      elsif Source = Editor.Outline.Stale_Extracted_Outline then
         Set_Text (Snapshot, Outline_Surface, Stale_State, "Outline is stale; refresh required.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_Outline);
      elsif not Editor.Outline.Has_Items (S.Outline) then
         Set_Text (Snapshot, Outline_Surface, No_Symbols_State, "No symbols found.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Refresh_Outline);
      else
         Set_Text (Snapshot, Outline_Surface, Ready_State, "Outline ready.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Reveal_Current_Outline_Symbol);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Clear_Outline_Filter);
      end if;
      return Snapshot;
   end Build_Outline_Empty_State;

   function Build_Diagnostics_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Feature_Total : constant Natural :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Feature_Visible : constant Natural :=
        Editor.Feature_Diagnostics.Visible_Row_Count (S.Feature_Diagnostics);
   begin
      if Feature_Total > 0 and then Feature_Visible = 0 then
         Set_Text
           (Snapshot, Diagnostics_Surface, Filtered_None_State,
            "No diagnostics match current filter.",
            "Clear the filter explicitly; guidance does not delete or rewrite diagnostic rows.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Clear_Filter);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Show_All);
      elsif Feature_Diagnostics_Selected_Source_Less (S) then
         Set_Text (Snapshot, Diagnostics_Surface, Source_Less_Selected_State,
                   "Selected diagnostic has no source target.",
                   "Navigation is unavailable until a diagnostic carries a source location.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Clear_Selected);
      elsif Feature_Diagnostics_Selected_Unavailable_Reason (S)'Length > 0 then
         Set_Text
           (Snapshot, Diagnostics_Surface, Selected_Unavailable_State,
            Feature_Diagnostics_Selected_Unavailable_Reason (S),
            "Clear the selected diagnostic or run the producer again after fixing the target.",
            Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Clear_Selected);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      elsif Feature_Diagnostics_Has_Stale_Target (S) then
         Set_Text (Snapshot, Diagnostics_Surface, Stale_State,
                   "Some diagnostics may be stale.",
                   "Clear stale diagnostics or run the producer again explicitly.",
                   Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Clear);
      elsif S.Latest_Build_Result.Has_Diagnostics_Count
        and then S.Latest_Build_Result.Diagnostics_Count_If_Available = 0
      then
         Set_Text (Snapshot, Diagnostics_Surface, No_Build_Diagnostics_State,
                   "Build completed with no diagnostics.",
                   "Inspect Build Output for command details or run build again after changes.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      elsif Feature_Total = 0
        and then Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0
      then
         Set_Text (Snapshot, Diagnostics_Surface, No_Diagnostics_State,
                   "No diagnostics yet.",
                   "Run build or diagnostics-producing commands to populate this panel.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Clear_Filter);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      elsif S.Active_Diagnostic.Has_Active
        and then not Editor.Diagnostics.Is_Valid_Diagnostic_Index
          (S.Diagnostics, S.Active_Diagnostic.Index)
      then
         Set_Text (Snapshot, Diagnostics_Surface, Stale_State, "Some diagnostics may be stale.", "", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Clear);
      elsif Selected_Diagnostic_Is_Source_Less (S) then
         Set_Text (Snapshot, Diagnostics_Surface, Source_Less_Selected_State,
                   "Selected diagnostic has no source target.",
                   "Navigation is unavailable until a diagnostic carries a source location.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Clear_Selected);
      else
         Set_Text (Snapshot, Diagnostics_Surface, Ready_State, "Diagnostics ready.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Clear_Filter);
      end if;
      Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Run);
      return Snapshot;
   end Build_Diagnostics_Empty_State;

   function Build_Build_UI_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Candidate_Count : constant Natural := Editor.Build_UI.Candidate_Count (S.Build_UI);
      Validation : constant Editor.Build_UI.Public_Build_UI_Validation_Status :=
        Editor.Build_UI.Validate_Build_UI_State (S.Build_UI);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Set_Text (Snapshot, Build_Surface, No_Project_State, "Open a project to build.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
      elsif Candidate_Count = 0
        and then S.Build_UI.Candidate_Refresh_Status = Editor.Build_UI.Build_Candidate_Refresh_Not_Requested
      then
         Set_Text (Snapshot, Build_Surface, Not_Refreshed_State, "Refresh build candidates.",
                   "Candidate discovery is explicit; this guidance does not scan or run anything.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Refresh_Candidates);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      elsif Candidate_Count = 0 then
         Set_Text (Snapshot, Build_Surface, No_Candidates_State, "No build candidates found.",
                   "Refresh build candidates explicitly; this guidance does not scan or run anything.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Refresh_Candidates);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      elsif Validation = Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale then
         Set_Text (Snapshot, Build_Surface, Stale_State, "Selected build candidate is stale.",
                   "Refresh candidates before running build.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Refresh_Candidates);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      elsif Validation = Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected then
         Set_Text (Snapshot, Build_Surface, No_Selected_Candidate_State, "Select a build candidate.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Select_First_Candidate);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      elsif Validation = Editor.Build_UI.Build_UI_Rejected_Missing_Consent
        or else Validation = Editor.Build_UI.Build_UI_Rejected_Stale_Consent
      then
         Set_Text (Snapshot, Build_Surface, Consent_Required_State, "Consent required before running build.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Acknowledge_Consent);
      elsif Validation /= Editor.Build_UI.Build_UI_Valid then
         Set_Text
         (Snapshot, Build_Surface, Request_Invalid_State,
            "Build request is invalid.",
            Editor.Build_UI.Validation_Message (Validation), Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Refresh_Candidates);
      elsif S.Latest_Build_Result.Diagnostics_Ingestion_Status =
        Editor.Build_Result_Summary.Diagnostics_Ingestion_Disabled
      then
         Set_Text (Snapshot, Build_Surface, Diagnostics_Disabled_State, "Diagnostics ingestion is disabled.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Toggle_Diagnostics_Ingestion);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Show);
      elsif not S.Latest_Build_Result.Has_Result then
         Set_Text (Snapshot, Build_Surface, No_Result_State, "No build has run.",
                   "Run build or inspect output details after an explicit build request.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Run);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Show);
      elsif S.Latest_Build_Output_Details.Has_Output_Details
        and then S.Latest_Build_Output_Details.Kind = Editor.Build_Output_Details.Build_Output_Details_None
      then
         Set_Text (Snapshot, Build_Surface, No_Output_State, "No output captured.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
      else
         Set_Text (Snapshot, Build_Surface, Ready_State, "Build Output ready.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_Run);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Build_UI_Show);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Diagnostics_Show);
      end if;
      return Snapshot;
   end Build_Build_UI_Empty_State;

   function Build_Recent_Projects_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Total : constant Natural := Editor.Recent_Projects.Count (S.Recent_Projects);
      Missing : constant Natural := Editor.Recent_Projects.Unavailable_Count (S.Recent_Projects);
   begin
      if Total = 0 then
         Set_Text (Snapshot, Recent_Projects_Surface, No_Recent_Projects_State, "No recent projects.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Restore_Workspace_State);
      elsif S.Recent_Project_Selected_Index in 1 .. Total
        and then not Editor.Recent_Projects.Is_Available
          (Editor.Recent_Projects.Item
             (S.Recent_Projects, Positive (S.Recent_Project_Selected_Index)))
      then
         Set_Text (Snapshot, Recent_Projects_Surface, Selected_Unavailable_State,
                   "Recent project is unavailable.",
                   "Remove missing entries or open a project explicitly.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Remove_Selected_Recent_Project);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Remove_Missing_Recent_Projects);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Project);
      elsif Missing = Total then
         Set_Text (Snapshot, Recent_Projects_Surface, Only_Missing_Projects_State, "Some recent projects are missing.",
                   "Missing entries are not removed until a command does it.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Remove_Missing_Recent_Projects);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Clear_Recent_Projects);
      else
         Set_Text (Snapshot, Recent_Projects_Surface, Ready_State, "Recent Projects ready.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Open_Selected_Recent_Project);
      end if;
      return Snapshot;
   end Build_Recent_Projects_Empty_State;

   function Build_Config_Recovery_Empty_State (S : Editor.State.State_Type) return Empty_State_Snapshot is
      Snapshot : Empty_State_Snapshot;
      Summary : constant Editor.Configuration_Audit.Configuration_State_Summary :=
        Editor.Configuration_Audit.Configuration_State_Summary_For (S);
   begin
      if Summary.Has_Pending_Transition then
         Set_Text
           (Snapshot, Configuration_Recovery_Surface,
            Configuration_Warning_State, "Configuration warnings available.",
            "Pending transition state is runtime-only; run audit or recovery view "
            & "explicitly.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Audit);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Recover_Show);
      elsif Summary.Message_Count > 0 then
         Set_Text
           (Snapshot, Configuration_Recovery_Surface, Safe_Defaults_State,
            "Safe defaults are active for one or more domains.",
            "Inspect recovery details explicitly; guidance does not reset or save "
            & "configuration.", Empty_Warning);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Audit);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Recover_Show);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Reset_Settings);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Reset_Keybindings);
      else
         Set_Text (Snapshot, Configuration_Recovery_Surface, Clean_State, "Configuration is clean.",
                   "Run configuration audit when you want an explicit domain report.");
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Audit);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Recover_Show);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Reset_Settings);
         Add_Suggestion (Snapshot, S, Editor.Commands.Command_Configuration_Reset_Keybindings);
      end if;
      return Snapshot;
   end Build_Config_Recovery_Empty_State;

   function Assert_Empty_State_Is_Display_Only (Snapshot : Empty_State_Snapshot) return Boolean is
   begin
      return Snapshot.Suggestion_Count <= Max_Empty_State_Suggestions
        and then Assert_Empty_State_Suggestions_Have_No_Payloads (Snapshot)
        and then Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned (Snapshot)
        and then Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean (Snapshot)
        and then Assert_Empty_State_Suggestion_Tail_Is_Clean (Snapshot)
        and then Assert_Non_Ready_Empty_State_Is_Actionable (Snapshot)
        and then Assert_Ready_Empty_State_Is_Suppressed (Snapshot)
        and then Assert_Empty_State_Suggestions_Are_Visible_Descriptor_Matches (Snapshot)
        and then Assert_Selected_Suggested_Action_Is_Actionable (Snapshot)
        and then Assert_Empty_State_Severity_Is_Semantic (Snapshot)
        and then Assert_Empty_State_Display_Line_Is_Labelled (Snapshot)
        and then Assert_Empty_State_Display_Line_Has_No_Target_Text (Snapshot)
        and then Assert_Empty_State_Suggestion_Display_Lines_Have_No_Target_Text (Snapshot)
        and then Assert_Empty_State_Text_Is_Deterministic_And_Compact (Snapshot)
        and then Assert_Empty_State_Snapshot_Has_No_Target_Text (Snapshot);
   end Assert_Empty_State_Is_Display_Only;

   function Assert_Empty_State_Array_Is_Display_Only
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
      Renderable : Natural := 0;
   begin
      --  Aggregate guidance is the render-facing contract for .  The
      --  array must be canonical, complete, bounded, and each member must obey
      --  the same no-payload/display-only invariants as an individual card.
      if Snapshots'Length /= Max_Empty_State_Surfaces
        or else not Assert_Empty_State_Surface_Model_Is_Closed
        or else not Assert_All_Empty_State_Surfaces_Are_Present_Once (Snapshots)
        or else not Assert_All_Empty_State_Surfaces_In_Canonical_Order (Snapshots)
        or else not Assert_Empty_State_Array_Uses_Canonical_Slots (Snapshots)
        or else not Assert_Empty_State_Array_Suggestion_Budget (Snapshots)
      then
         return False;
      end if;

      for I in Snapshots'Range loop
         if not Assert_Empty_State_Is_Display_Only (Snapshots (I)) then
            return False;
         end if;

         if Empty_State_Should_Render (Snapshots (I)) then
            Renderable := Renderable + 1;
         end if;
      end loop;

      return Renderable = Empty_State_Renderable_Count (Snapshots)
        and then Renderable <= Max_Empty_State_Surfaces;
   end Assert_Empty_State_Array_Is_Display_Only;

   function Assert_Empty_State_Suggestions_Have_No_Payloads (Snapshot : Empty_State_Snapshot) return Boolean is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Carries_Payload
           or else Length (Snapshot.Suggestions (I).Stable_Name) = 0
           or else Length (Snapshot.Suggestions (I).Title) = 0
           or else not Suggestion_Is_Descriptor_Consistent
             (Snapshot.Suggestions (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Have_No_Payloads;

   function Assert_Suggested_Actions_Store_Command_Names_Only
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Command = Editor.Commands.No_Command
           or else not Safe_Stable_Command_Name
             (To_String (Snapshot.Suggestions (I).Stable_Name))
           or else To_String (Snapshot.Suggestions (I).Stable_Name) /=
             Editor.Commands.Stable_Command_Name (Snapshot.Suggestions (I).Command)
           or else Snapshot.Suggestions (I).Carries_Payload
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Suggested_Actions_Store_Command_Names_Only;

   function Assert_Suggested_Action_Open_Palette_Carries_No_Payload
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return False;
      end if;

      return Suggestion_Is_Activation_Safe (Snapshot.Suggestions (Index))
        and then not Snapshot.Suggestions (Index).Carries_Payload
        and then Safe_Stable_Command_Name
          (To_String (Snapshot.Suggestions (Index).Stable_Name));
   end Assert_Suggested_Action_Open_Palette_Carries_No_Payload;

   function Assert_Suggested_Action_Activation_Mode_Is_Coherent
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
   begin
      if not Suggestion.Visible then
         return True;
      end if;

      if not Suggestion_Is_Activation_Safe (Suggestion)
        or else Suggestion.Carries_Payload
        or else Length (Suggestion.Availability_Label) = 0
      then
         return False;
      end if;

      case Suggestion.Activation_Mode is
         when Suggestion_Display_Only =>
            return not Suggestion.Selected;
         when Suggestion_Open_In_Command_Palette
            | Suggestion_Execute_Through_Executor =>
            return True;
      end case;
   end Assert_Suggested_Action_Activation_Mode_Is_Coherent;

   function Assert_Suggested_Action_Source_Label_Is_Surface_Owned
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean
   is
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return False;
      end if;

      return Length (Snapshot.Suggestions (Index).Surface_Source_Label) > 0
        and then To_String (Snapshot.Suggestions (Index).Surface_Source_Label) =
          Empty_State_Surface_Label (Snapshot.Surface);
   end Assert_Suggested_Action_Source_Label_Is_Surface_Owned;

   function Assert_Suggested_Action_Metadata_Is_Current
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
      Found    : Boolean := False;
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Name     : constant String := To_String (Suggestion.Stable_Name);
   begin
      if not Suggestion.Visible then
         return True;
      end if;

      if not Safe_Stable_Command_Name (Name) then
         return False;
      end if;

      Resolved := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      if not Found
        or else Resolved /= Suggestion.Command
        or else Suggestion.Command = Editor.Commands.No_Command
      then
         return False;
      end if;

      declare
         D : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Suggestion.Command);
      begin
         return Command_Is_Visible_In_Guidance (Suggestion.Command)
           and then Name = Editor.Commands.Stable_Command_Name (Suggestion.Command)
           and then To_String (Suggestion.Title) = To_String (D.Name)
           and then To_String (Suggestion.Short_Explanation) = To_String (D.Description)
           and then not Suggestion.Carries_Payload;
      end;
   end Assert_Suggested_Action_Metadata_Is_Current;

   function Assert_Suggested_Action_Availability_Label_Is_Current
     (S          : Editor.State.State_Type;
      Suggestion : Empty_State_Suggested_Command) return Boolean
   is
      Current : Empty_State_Suggested_Command;
   begin
      if not Suggestion.Visible then
         return True;
      end if;

      if Suggestion.Command = Editor.Commands.No_Command then
         return False;
      end if;

      Current := Command_Suggestion_From_Descriptor (S, Suggestion.Command);
      return Current.Visible
        and then Current.Available = Suggestion.Available
        and then To_String (Current.Unavailable_Reason) =
          To_String (Suggestion.Unavailable_Reason)
        and then Suggested_Action_Availability_Label (Current) =
          Suggested_Action_Availability_Label (Suggestion);
   end Assert_Suggested_Action_Availability_Label_Is_Current;

   function Assert_Suggested_Action_Is_Canonical_Surface_Projection
     (S          : Editor.State.State_Type;
      Surface    : Empty_State_Surface;
      Suggestion : Empty_State_Suggested_Command) return Boolean
   is
      Canonical : Empty_State_Suggested_Command;
   begin
      if not Suggestion.Visible then
         return True;
      end if;

      if Suggestion.Command = Editor.Commands.No_Command then
         return False;
      end if;

      Canonical := Canonical_Surface_Suggestion
        (S, Surface, Suggestion.Command);

      return Canonical.Visible
        and then Canonical.Command = Suggestion.Command
        and then To_String (Canonical.Stable_Name) =
          To_String (Suggestion.Stable_Name)
        and then To_String (Canonical.Title) = To_String (Suggestion.Title)
        and then To_String (Canonical.Short_Explanation) =
          To_String (Suggestion.Short_Explanation)
        and then To_String (Canonical.Surface_Source_Label) =
          To_String (Suggestion.Surface_Source_Label)
        and then To_String (Canonical.Availability_Label) =
          To_String (Suggestion.Availability_Label)
        and then Canonical.Activation_Mode = Suggestion.Activation_Mode
        and then Canonical.Available = Suggestion.Available
        and then To_String (Canonical.Unavailable_Reason) =
          To_String (Suggestion.Unavailable_Reason)
        and then Canonical.Visible = Suggestion.Visible
        and then Canonical.Carries_Payload = Suggestion.Carries_Payload;
   end Assert_Suggested_Action_Is_Canonical_Surface_Projection;

   function Assert_Empty_State_Suggestions_Are_Canonical_Surface_Projections
     (S        : Editor.State.State_Type;
      Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Assert_Suggested_Action_Is_Canonical_Surface_Projection
           (S, Snapshot.Surface, Snapshot.Suggestions (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Are_Canonical_Surface_Projections;

   function Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Assert_Suggested_Action_Source_Label_Is_Surface_Owned
           (Snapshot, Positive (I))
         then
            return False;
         end if;
      end loop;

      for I in Snapshot.Suggestion_Count + 1 .. Max_Empty_State_Suggestions loop
         if Length (Snapshot.Suggestions (I).Surface_Source_Label) > 0
           or else Snapshot.Suggestions (I).Selected
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Suggestion_Source_Labels_Are_Surface_Owned;

   function Assert_Selected_Suggested_Action_Is_Actionable
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Selected : constant Natural := Suggested_Action_Selected_Index (Snapshot);
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if Snapshot.Suggestions (I).Selected then
            return Selected = I
              and then Suggestion_Is_Selectable (Snapshot.Suggestions (I));
         end if;
      end loop;

      return Selected = 0;
   end Assert_Selected_Suggested_Action_Is_Actionable;

   function Assert_Suggested_Action_Index_Is_Activatable
     (Snapshot : Empty_State_Snapshot;
      Index    : Positive) return Boolean
   is
      Selected : constant Natural := Suggested_Action_Selected_Index (Snapshot);
      Markers  : Natural := 0;
   begin
      if Index > Snapshot.Suggestion_Count
        or else Index > Max_Empty_State_Suggestions
      then
         return False;
      end if;

      for I in 1 .. Max_Empty_State_Suggestions loop
         if Snapshot.Suggestions (I).Selected then
            Markers := Markers + 1;
         end if;
      end loop;

      if Markers > 1 then
         return False;
      elsif Markers = 1 and then Selected /= Index then
         return False;
      end if;

      return Suggestion_Is_Activation_Safe (Snapshot.Suggestions (Index))
        and then not Snapshot.Suggestions (Index).Carries_Payload
        and then Length (Snapshot.Suggestions (Index).Availability_Label) > 0
        and then Assert_Suggested_Action_Activation_Mode_Is_Coherent
          (Snapshot.Suggestions (Index));
   end Assert_Suggested_Action_Index_Is_Activatable;

   function Assert_Empty_State_Suggestion_Tail_Is_Clean
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      if Snapshot.Suggestion_Count > Max_Empty_State_Suggestions then
         return False;
      end if;

      for I in Snapshot.Suggestion_Count + 1 .. Max_Empty_State_Suggestions loop
         if Snapshot.Suggestions (I).Command /= Editor.Commands.No_Command
           or else Length (Snapshot.Suggestions (I).Stable_Name) /= 0
           or else Length (Snapshot.Suggestions (I).Title) /= 0
           or else Length (Snapshot.Suggestions (I).Short_Explanation) /= 0
           or else Length (Snapshot.Suggestions (I).Surface_Source_Label) /= 0
           or else Length (Snapshot.Suggestions (I).Availability_Label) /= 0
           or else Snapshot.Suggestions (I).Activation_Mode /=
             Empty_Command_Suggestion.Activation_Mode
           or else Snapshot.Suggestions (I).Selected
           or else Snapshot.Suggestions (I).Available
           or else Length (Snapshot.Suggestions (I).Unavailable_Reason) /= 0
           or else Snapshot.Suggestions (I).Visible
           or else Snapshot.Suggestions (I).Carries_Payload
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Suggestion_Tail_Is_Clean;

   function Assert_Unavailable_Suggested_Action_Does_Not_Execute
     (Suggestion : Empty_State_Suggested_Command;
      Result     : Editor.Executor.Command_Execution_Result) return Boolean
   is
   begin
      if Suggestion.Available then
         return True;
      end if;

      return Result.Command = Suggestion.Command
        and then Result.Status = Editor.Executor.Command_Unavailable;
   end Assert_Unavailable_Suggested_Action_Does_Not_Execute;

   function Assert_Keybindings_Have_No_Suggestion_Payloads return Boolean
   is
   begin
      --  Keybindings expose command ids and chords only.  A suggestion cannot
      --  inject file/project/result/candidate context because no such field
      --  exists in the keybinding lookup contract.  Lock this to the absence
      --  of dedicated suggestion commands in the currently bound command set.
      for I in 1 .. Editor.Keybindings.Bound_Command_Count loop
         declare
            Command : constant Editor.Commands.Command_Id :=
              Editor.Keybindings.Bound_Command_At (Positive (I));
            Stable : constant String := Editor.Commands.Stable_Command_Name (Command);
         begin
            if Stable'Length = 0
              or else Ada.Strings.Unbounded.Index
                (To_Unbounded_String (Stable), "suggestion.") /= 0
            then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Assert_Keybindings_Have_No_Suggestion_Payloads;

   function Assert_First_Run_Guidance_Fabricates_No_Project
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Project.Has_Project (Before.Project) =
        Editor.Project.Has_Project (After.Project)
        and then Before.Active_Buffer_Token = After.Active_Buffer_Token
        and then Before.File_Info.Has_Path = After.File_Info.Has_Path
        and then Editor.Recent_Projects.Count (Before.Recent_Projects) =
          Editor.Recent_Projects.Count (After.Recent_Projects);
   end Assert_First_Run_Guidance_Fabricates_No_Project;

   function Assert_Render_Empty_State_Construction_Is_Observational
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_First_Run_Guidance_Fabricates_No_Project (Before, After)
        and then Editor.Diagnostics.Diagnostic_Count (Before.Diagnostics) =
          Editor.Diagnostics.Diagnostic_Count (After.Diagnostics)
        and then Editor.File_Tree.File_Node_Count (Before.File_Tree) =
          Editor.File_Tree.File_Node_Count (After.File_Tree)
        and then Editor.Project_Search.Result_Count (Before.Project_Search) =
          Editor.Project_Search.Result_Count (After.Project_Search)
        and then Editor.Build_UI.Candidate_Count (Before.Build_UI) =
          Editor.Build_UI.Candidate_Count (After.Build_UI)
        and then Editor.Feature_Diagnostics.Row_Count (Before.Feature_Diagnostics) =
          Editor.Feature_Diagnostics.Row_Count (After.Feature_Diagnostics)
        and then Editor.Feature_Diagnostics.Visible_Row_Count (Before.Feature_Diagnostics) =
          Editor.Feature_Diagnostics.Visible_Row_Count (After.Feature_Diagnostics);
   end Assert_Render_Empty_State_Construction_Is_Observational;

   function Assert_Empty_State_Not_Persisted
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean
   is
   begin
      return Assert_Render_Empty_State_Construction_Is_Observational (Before, After)
        and then Editor.Recent_Projects.Count (Before.Recent_Projects) =
          Editor.Recent_Projects.Count (After.Recent_Projects)
        and then Editor.Build_UI.Candidate_Count (Before.Build_UI) =
          Editor.Build_UI.Candidate_Count (After.Build_UI)
        and then Editor.Feature_Diagnostics.Row_Count (Before.Feature_Diagnostics) =
          Editor.Feature_Diagnostics.Row_Count (After.Feature_Diagnostics)
        and then Editor.Feature_Diagnostics.Visible_Row_Count (Before.Feature_Diagnostics) =
          Editor.Feature_Diagnostics.Visible_Row_Count (After.Feature_Diagnostics);
   end Assert_Empty_State_Not_Persisted;

   function Assert_Empty_State_Suggestions_Are_Descriptor_Derived
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      D : Editor.Commands.Command_Descriptor;
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Snapshot.Suggestions (I).Visible
           or else Snapshot.Suggestions (I).Command = Editor.Commands.No_Command
         then
            return False;
         end if;

         D := Editor.Commands.Descriptor (Snapshot.Suggestions (I).Command);
         if not Command_Is_Visible_In_Guidance (Snapshot.Suggestions (I).Command)
           or else To_String (Snapshot.Suggestions (I).Title) /= To_String (D.Name)
           or else To_String (Snapshot.Suggestions (I).Stable_Name) /=
             Editor.Commands.Stable_Command_Name (Snapshot.Suggestions (I).Command)
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Are_Descriptor_Derived;

   function Assert_Empty_State_Suggestions_Are_Stable_Names_Only
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         declare
            Name : constant String := To_String (Snapshot.Suggestions (I).Stable_Name);
         begin
            if Snapshot.Suggestions (I).Carries_Payload
              or else not Stable_Name_Is_Display_Only (Name)
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Are_Stable_Names_Only;

   function Assert_Empty_State_Suggestions_Resolve_From_Stable_Names
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
      Found    : Boolean := False;
      Resolved : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         Resolved := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (Snapshot.Suggestions (I).Stable_Name), Found);
         if not Found
           or else Resolved = Editor.Commands.No_Command
           or else Resolved /= Snapshot.Suggestions (I).Command
           or else not Suggestion_Is_Descriptor_Consistent
             (Snapshot.Suggestions (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Resolve_From_Stable_Names;

   function Assert_Empty_State_Suggestions_Are_Visible_Descriptor_Matches
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      for I in 1 .. Snapshot.Suggestion_Count loop
         if not Suggestion_Is_Descriptor_Consistent (Snapshot.Suggestions (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Empty_State_Suggestions_Are_Visible_Descriptor_Matches;

   function Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      if Snapshot.Suggestion_Count > Max_Empty_State_Suggestions then
         return False;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         for J in I + 1 .. Snapshot.Suggestion_Count loop
            if Snapshot.Suggestions (I).Command = Snapshot.Suggestions (J).Command
              or else To_String (Snapshot.Suggestions (I).Stable_Name) =
                To_String (Snapshot.Suggestions (J).Stable_Name)
            then
               return False;
            end if;
         end loop;
      end loop;

      if Snapshot.Suggestion_Count < Max_Empty_State_Suggestions then
         for I in Snapshot.Suggestion_Count + 1 .. Max_Empty_State_Suggestions loop
            if Snapshot.Suggestions (I).Command /= Editor.Commands.No_Command
              or else Snapshot.Suggestions (I).Visible
              or else Snapshot.Suggestions (I).Carries_Payload
              or else Length (Snapshot.Suggestions (I).Stable_Name) /= 0
              or else Length (Snapshot.Suggestions (I).Title) /= 0
              or else Length (Snapshot.Suggestions (I).Unavailable_Reason) /= 0
            then
               return False;
            end if;
         end loop;
      end if;

      return True;
   end Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean;

   function Assert_Non_Ready_Empty_State_Is_Actionable
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      --  Ready snapshots may legitimately be pure status. Every other Phase
      --  569 guidance card should point at at least one descriptor-derived
      --  command, even if that command is currently unavailable and shows its
      --  normal availability reason. This keeps empty states useful without
      --  adding payloads or implicit actions.
      if Snapshot.Kind = Ready_State then
         return True;
      end if;

      if Snapshot.Suggestion_Count = 0 then
         return False;
      end if;

      for I in 1 .. Snapshot.Suggestion_Count loop
         if Suggestion_Is_Descriptor_Consistent (Snapshot.Suggestions (I)) then
            return True;
         end if;
      end loop;

      return False;
   end Assert_Non_Ready_Empty_State_Is_Actionable;

   function Assert_Ready_Empty_State_Is_Suppressed
     (Snapshot : Empty_State_Snapshot) return Boolean
   is
   begin
      if Snapshot.Kind = Ready_State then
         return not Empty_State_Should_Render (Snapshot);
      end if;

      return Empty_State_Should_Render (Snapshot);
   end Assert_Ready_Empty_State_Is_Suppressed;

   function Assert_All_Empty_State_Surfaces_In_Canonical_Order
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
   begin
      if Snapshots'Length /= Max_Empty_State_Surfaces
        or else not Assert_Empty_State_Surface_Model_Is_Closed
      then
         return False;
      end if;

      for I in Snapshots'Range loop
         if Snapshots (I).Surface /= Empty_State_Surface_For_Slot (I) then
            return False;
         end if;
      end loop;

      return True;
   end Assert_All_Empty_State_Surfaces_In_Canonical_Order;

   function Assert_Empty_State_Array_Uses_Canonical_Slots
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
   begin
      if Snapshots'Length /= Max_Empty_State_Surfaces
        or else not Assert_Empty_State_Surface_Model_Is_Closed
      then
         return False;
      end if;

      for I in Snapshots'Range loop
         if Snapshots (I).Surface /= Empty_State_Surface_For_Slot (I)
           or else Empty_State_Slot_For_Surface (Snapshots (I).Surface) /= I
         then
            return False;
         end if;
      end loop;

      return True;
   end Assert_Empty_State_Array_Uses_Canonical_Slots;

   function Assert_Empty_State_Activation_Uses_Executor
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Command : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Result.Command = Command
        and then Result.Status /= Editor.Executor.Command_No_Op
        and then Assert_First_Run_Guidance_Fabricates_No_Project (Before, After);
   end Assert_Empty_State_Activation_Uses_Executor;

   function Assert_Major_Empty_State_Surface_Coverage
     (S : Editor.State.State_Type) return Boolean
   is
      Snapshots : constant Empty_State_Snapshot_Array :=
        Build_All_Empty_State_Snapshots (S);
   begin
      if not Assert_Empty_State_Surface_Model_Is_Closed
        or else not Assert_All_Empty_State_Surfaces_Are_Present_Once (Snapshots)
        or else not Assert_All_Empty_State_Surfaces_In_Canonical_Order (Snapshots)
        or else not Assert_Empty_State_Array_Uses_Canonical_Slots (Snapshots)
        or else not Assert_Empty_State_Array_Suggestion_Budget (Snapshots)
      then
         return False;
      end if;

      for I in Snapshots'Range loop
         if Length (Snapshots (I).Primary_Message) = 0
           or else not Assert_Empty_State_Is_Display_Only (Snapshots (I))
           or else not Assert_Empty_State_Suggestions_Are_Descriptor_Derived (Snapshots (I))
           or else not Assert_Empty_State_Suggestions_Are_Stable_Names_Only (Snapshots (I))
           or else not Assert_Empty_State_Suggestions_Resolve_From_Stable_Names (Snapshots (I))
           or else not Assert_Empty_State_Suggestions_Are_Unique_And_Tail_Clean (Snapshots (I))
         then
            return False;
         end if;
      end loop;
      return True;
   end Assert_Major_Empty_State_Surface_Coverage;

   function Assert_All_Empty_State_Surfaces_Are_Present_Once
     (Snapshots : Empty_State_Snapshot_Array) return Boolean
   is
      Seen : array (Empty_State_Surface) of Boolean := (others => False);
   begin
      if Snapshots'Length /= Max_Empty_State_Surfaces then
         return False;
      end if;

      for I in Snapshots'Range loop
         if Seen (Snapshots (I).Surface) then
            return False;
         end if;
         Seen (Snapshots (I).Surface) := True;
      end loop;

      for Surface in Empty_State_Surface loop
         if not Seen (Surface) then
            return False;
         end if;
      end loop;

      return True;
   end Assert_All_Empty_State_Surfaces_Are_Present_Once;

   function Assert_First_Use_Empty_State_Guidance_Coherent return Boolean is
      S : Editor.State.State_Type;
      Main : constant Empty_State_Snapshot := Build_Main_Empty_State (S);
      File_Tree : constant Empty_State_Snapshot := Build_File_Tree_Empty_State (S);
      Quick : constant Empty_State_Snapshot := Build_Quick_Open_Empty_State (S);
      Search : constant Empty_State_Snapshot := Build_Project_Search_Empty_State (S);
      Outline : constant Empty_State_Snapshot := Build_Outline_Empty_State (S);
      Diagnostics : constant Empty_State_Snapshot := Build_Diagnostics_Empty_State (S);
      Build : constant Empty_State_Snapshot := Build_Build_UI_Empty_State (S);
      Recent : constant Empty_State_Snapshot := Build_Recent_Projects_Empty_State (S);
      Config : constant Empty_State_Snapshot := Build_Config_Recovery_Empty_State (S);
   begin
      return Assert_Empty_State_Surface_Model_Is_Closed
        and then Main.Kind = First_Run_State
        and then File_Tree.Kind = No_Project_State
        and then Quick.Kind = No_Project_State
        and then Search.Kind = No_Project_State
        and then Outline.Kind = No_Active_Buffer_State
        and then Diagnostics.Kind = No_Diagnostics_State
        and then Build.Kind = No_Project_State
        and then Recent.Kind = No_Recent_Projects_State
        and then Config.Kind = Clean_State
        and then Assert_All_Empty_State_Surfaces_Are_Present_Once
          (Build_All_Empty_State_Snapshots (S))
        and then Assert_All_Empty_State_Surfaces_In_Canonical_Order
          (Build_All_Empty_State_Snapshots (S))
        and then Assert_Empty_State_Array_Uses_Canonical_Slots
          (Build_All_Empty_State_Snapshots (S))
        and then Empty_State_Renderable_Count
          (Build_All_Empty_State_Snapshots (S)) > 0
        and then Assert_Empty_State_Is_Display_Only (Main)
        and then Assert_Empty_State_Is_Display_Only (File_Tree)
        and then Assert_Empty_State_Is_Display_Only (Quick)
        and then Assert_Empty_State_Is_Display_Only (Search)
        and then Assert_Empty_State_Is_Display_Only (Outline)
        and then Assert_Empty_State_Is_Display_Only (Diagnostics)
        and then Assert_Empty_State_Is_Display_Only (Build)
        and then Assert_Empty_State_Is_Display_Only (Recent)
        and then Assert_Empty_State_Is_Display_Only (Config)
        and then Assert_Major_Empty_State_Surface_Coverage (S);
   end Assert_First_Use_Empty_State_Guidance_Coherent;

end Editor.Empty_State_Guidance;
