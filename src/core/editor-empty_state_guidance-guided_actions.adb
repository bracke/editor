with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Command_Execution;
with Editor.Command_Palette;
with Editor.Commands.Workflow_Messages;
with Editor.Configuration_Recovery;
with Editor.Empty_State_Guidance.Surfaces;
with Editor.Messages;

package body Editor.Empty_State_Guidance.Guided_Actions is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;

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

   function Suggestion_Is_Selectable
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
   begin
      return Suggestion_Is_Activation_Safe (Suggestion)
        and then Suggestion.Activation_Mode /= Suggestion_Display_Only;
   end Suggestion_Is_Selectable;

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

   function Suggestion_Is_Activation_Safe
     (Suggestion : Empty_State_Suggested_Command) return Boolean
   is
   begin
      return Suggestion_Is_Descriptor_Consistent (Suggestion);
   end Suggestion_Is_Activation_Safe;

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
        Editor.Empty_State_Guidance.Surfaces.Build_All_Empty_State_Snapshots (S);
   begin
      if not Editor.Empty_State_Guidance.Assert_Empty_State_Array_Is_Display_Only
        (Snapshots)
      then
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
                 or else not Editor.Empty_State_Guidance.Assert_Suggested_Action_Metadata_Is_Current
                   (Snapshot.Suggestions (I))
                 or else not Editor.Empty_State_Guidance.Assert_Suggested_Action_Is_Canonical_Surface_Projection
                   (S, Snapshot.Surface, Snapshot.Suggestions (I))
                 or else not Editor.Empty_State_Guidance.Assert_Suggested_Action_Source_Label_Is_Surface_Owned
                   (Snapshot, Positive (I))
                 or else not Editor.Empty_State_Guidance.Assert_Suggested_Action_Availability_Label_Is_Current
                   (S, Snapshot.Suggestions (I))
                 or else not Editor.Empty_State_Guidance.Assert_Suggested_Action_Activation_Mode_Is_Coherent
                   (Snapshot.Suggestions (I))
               then
                  return False;
               end if;
            end loop;
         end;
      end loop;

      return True;
   end Assert_Guided_Action_Routing_Coherent;

end Editor.Empty_State_Guidance.Guided_Actions;
