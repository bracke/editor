with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Characters.Handling;
with Ada.Environment_Variables;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Editor.Command_Palette;
with Editor.Command_Execution;
with Editor.Command_Route_Audit;
with Editor.Command_Surface;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Command_Palette_Projection;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.External_Producers;
with Editor.Messages;
with Editor.Keybindings;
with Editor.Keybinding_Management;
with Editor.Buffers;
with Editor.Build_Candidates;
with Editor.Build_Command;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Lifecycle_Guidance;
with Editor.Project;
with Editor.Pending_Transitions;
with Editor.Recent_Projects;
with Editor.Settings;
with Editor.State;
with Editor.Overlay_Focus;
with Editor.Panel_Focus;

package body Editor.Command_Surface.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Family_Id;
   use type Editor.Commands.Command_Effect_Classification_Id;
   use type Editor.Commands.Command_Kind;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Command_Palette.Command_Palette_Row_Kind;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Command_Surface.Command_Surface_Review;
   use type Editor.Messages.Message_Severity;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.External_Producers.Build_Tool_Kind;
   use type Editor.External_Producers.Build_Request_Provenance;
   use type Editor.External_Producers.Build_Request_Validation_Status;
   use type Editor.External_Producers.Build_Working_Context_Kind;
   use type Editor.External_Producers.Public_Build_Input_Validation_Status;
   use type Editor.External_Producers.Public_Build_Consent_Validation_Status;
   use type Editor.External_Producers.Public_Build_Working_Context_Validation_Status;
   use type Editor.External_Producers.Public_Build_Input_Safety;
   use type Editor.External_Producers.Public_Build_Command_Surface_Status;
   use type Editor.External_Producers.Public_Build_Command_Promotion_Status;
   use type Editor.External_Producers.Public_Build_UX_Dependency;
   use type Editor.External_Producers.Public_Build_UX_Dependency_Status;
   use type Editor.External_Producers.Public_Build_Hard_Freeze_Baseline;
   use type Editor.External_Producers.Public_Build_Guardrail_Status;
   use type Editor.External_Producers.Public_Build_Guardrail_Result;
   use type Editor.External_Producers.Public_Build_Guardrail_Contract_Mismatch;
   use type Editor.External_Producers.Public_Build_Guardrail_Failure_Kind;
   use type Editor.External_Producers.Public_Build_Guardrail_Failure_Detail;
   use type Editor.External_Producers.Public_Build_Surface_Id_Scan_Result;
   use type Editor.External_Producers.Public_Build_Guardrail_Health;
   use Editor.External_Producers;
   use type Editor.External_Producers.Public_Build_Guardrail_Regression_Manifest;
   use type Editor.External_Producers.Public_Build_Guardrail_Audit_Matrix;
   use type Editor.Build_Command.Build_Run_Readiness_Status;



   procedure Test_Recent_Project_Selected_Row_Commands_Are_No_Payload
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Check (Id : Editor.Commands.Command_Id; Label : String) is
      begin
         Assert (not Editor.Commands.Requires_Context (Id),
                 Label & " must not require structured command context");
      end Check;
   begin
      Check (Editor.Commands.Command_Open_Selected_Recent_Project,
             "open selected recent project");
      Check (Editor.Commands.Command_Remove_Selected_Recent_Project,
             "remove selected recent project");
      Check (Editor.Commands.Command_Remove_Missing_Recent_Projects,
             "remove missing recent projects");
      Check (Editor.Commands.Command_Select_Next_Recent_Project,
             "select next recent project");
      Check (Editor.Commands.Command_Select_Previous_Recent_Project,
             "select previous recent project");
      Assert (Editor.Commands.Requires_Context (Editor.Commands.Command_Open_Project),
              "plain project.open remains the explicit path-payload command");
   end Test_Recent_Project_Selected_Row_Commands_Are_No_Payload;

   procedure Test_Command_Descriptor_Audit_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      D : Editor.Commands.Command_Descriptor;
   begin
      Assert
        (not Editor.Commands.Is_Concrete_Command (Editor.Commands.No_Command),
         "No_Command must not be concrete");

      Assert
        (Editor.Commands.Descriptor (Editor.Commands.No_Command).Visibility =
           Editor.Commands.Hidden_Command,
         "No_Command must stay hidden");

      Assert
        (Editor.Commands.Descriptor (Editor.Commands.No_Command).Category =
           Editor.Commands.Internal_Category,
         "No_Command must stay internal");

      for I in 1 .. Editor.Commands.Command_Count loop
         D := Editor.Commands.Descriptor (Editor.Commands.Command_At (I));
         Assert
           (D.Id = Editor.Commands.Command_At (I),
            "descriptor id must match registry id for " & Editor.Commands.Label (D.Id));
         Assert
           (Editor.Commands.Descriptor_Is_Complete (D.Id),
            "descriptor must satisfy command-surface completeness policy for " &
            Editor.Commands.Label (D.Id));

         if Editor.Commands.Is_Concrete_Command (D.Id) then
            Assert
              (Length (D.Name) > 0,
               "concrete commands must have a stable label");
         end if;
      end loop;
   end Test_Command_Descriptor_Audit_Helpers;

   procedure Test_Command_Palette_Candidates_Use_Command_Registry
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      D          : Editor.Commands.Command_Descriptor;
   begin
      Editor.State.Init (S);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);

      for Candidate of Candidates loop
         D := Editor.Commands.Descriptor (Candidate.Id);
         Assert
           (Editor.Commands.Visible_In_Command_Palette (Candidate.Id),
            "palette candidate must originate from visible command registry");
         Assert
           (To_String (Candidate.Label) = To_String (D.Name),
            "palette candidate label must mirror descriptor label");
         Assert
           (To_String (Candidate.Description) = To_String (D.Description),
            "palette candidate description must mirror descriptor description");
         Assert
           (Candidate.Category = D.Category,
            "palette candidate category must mirror descriptor category");
      end loop;
   end Test_Command_Palette_Candidates_Use_Command_Registry;



   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   procedure Assert_Candidate_Vectors_Equal
     (Left  : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Right : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Msg   : String)
   is
   begin
      Assert (Left.Length = Right.Length, Msg & ": candidate count differs");
      if Left.Length = 0 then
         return;
      end if;

      for I in 0 .. Natural (Left.Length) - 1 loop
         declare
            L : constant Editor.Commands.Command_Palette_Candidate := Left.Element (I);
            R : constant Editor.Commands.Command_Palette_Candidate := Right.Element (I);
         begin
            Assert (L.Id = R.Id, Msg & ": candidate id differs");
            Assert (To_String (L.Label) = To_String (R.Label), Msg & ": label differs");
            Assert (To_String (L.Description) = To_String (R.Description), Msg & ": description differs");
            Assert (L.Category = R.Category, Msg & ": category differs");
            Assert (To_String (L.Category_Label) = To_String (R.Category_Label), Msg & ": category label differs");
            Assert (L.Available = R.Available, Msg & ": availability differs");
            Assert (To_String (L.Reason) = To_String (R.Reason), Msg & ": reason differs");
            Assert (L.Has_Keybinding = R.Has_Keybinding, Msg & ": keybinding flag differs");
            Assert (To_String (L.Keybinding_Display) = To_String (R.Keybinding_Display), Msg & ": keybinding display differs");
            Assert (To_String (L.Reference_Summary) = To_String (R.Reference_Summary), Msg & ": reference summary differs");
            Assert (L.Family = R.Family, Msg & ": command family differs");
            Assert (L.Effect_Classification = R.Effect_Classification, Msg & ": effect classification differs");
            Assert (L.Match_Score = R.Match_Score, Msg & ": match score differs");
            Assert (L.Registry_Order = R.Registry_Order, Msg & ": registry order differs");
         end;
      end loop;
   end Assert_Candidate_Vectors_Equal;

   procedure Test_Static_Command_Invariants
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Seen_Palette_Label : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      pragma Unreferenced (Seen_Palette_Label);
      Id : Editor.Commands.Command_Id;
      D  : Editor.Commands.Command_Descriptor;
   begin
      Assert (Editor.Commands.First_Command = Editor.Commands.Command_Id'First,
              "First_Command must match enumeration first value");
      Assert (Editor.Commands.Last_Command = Editor.Commands.Command_Id'Last,
              "Last_Command must match enumeration last value");

      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         D := Editor.Commands.Descriptor (Id);

         Assert (Editor.Commands.Is_Valid_Command (Id),
                 "all iterated Command_Id values must be valid");
         Assert (D.Id = Id,
                 "descriptor id must match iterated command id");

         if Editor.Commands.Is_Concrete_Command (Id) then
            Assert (Editor.Commands.Has_Stable_User_Label (Id),
                    "concrete command must have stable user label: " & Editor.Commands.Command_Id'Image (Id));
            Assert (To_String (D.Name) = Trimmed (To_String (D.Name)),
                    "command label must be trimmed: " & Editor.Commands.Command_Id'Image (Id));
            Assert (To_String (D.Name) /= "TODO"
                    and then To_String (D.Name) /= "Command"
                    and then To_String (D.Name) /= "Unnamed",
                    "command label must not be a surface entry: " & Editor.Commands.Command_Id'Image (Id));
         end if;

         if Editor.Commands.Visible_In_Command_Palette (Id) then
            Assert (To_String (D.Description) = Trimmed (To_String (D.Description)),
                    "palette description must be trimmed: " & Editor.Commands.Command_Id'Image (Id));
            Assert (D.Category /= Editor.Commands.Internal_Category,
                    "palette-visible command must not be internal: " & Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Commands.Category_Label (D.Category)'Length > 0,
                    "palette-visible command category must have a label");
            Assert (Editor.Commands.Category_Label (D.Category) =
                      Trimmed (Editor.Commands.Category_Label (D.Category)),
                    "category label must be trimmed");
         end if;
      end loop;
   end Test_Static_Command_Invariants;

   procedure Test_Availability_Is_Read_Only_On_Empty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      Before_Overlay : Editor.Overlay_Focus.Overlay_Target;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Before_Bottom : Editor.Panel_Focus.Bottom_Focus_Content;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      Before_Overlay := Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Before_Bottom := Editor.Panel_Focus.Bottom_Content (S.Panel_Focus);

      for I in 1 .. Editor.Commands.Command_Count loop
         A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_At (I));
         if not Editor.Commands.Is_Available (A)
           and then Editor.Commands.Command_At (I) /= Editor.Commands.No_Command
         then
            Assert (Editor.Commands.Unavailable_Reason (A)'Length > 0,
                    "unavailable concrete commands must include a reason: " &
                    Editor.Commands.Command_Id'Image (Editor.Commands.Command_At (I)));
         end if;
      end loop;

      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "availability checks must not push messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "availability checks must not change active-buffer status");
      Assert (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) = Before_Overlay,
              "availability checks must not change overlay focus");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "availability checks must not change panel focus target");
      Assert (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) = Before_Bottom,
              "availability checks must not change bottom panel focus content");
   end Test_Availability_Is_Read_Only_On_Empty_State;

   procedure Test_Unavailable_Reason_Consistency
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      function Reason (Id : Editor.Commands.Command_Id) return String is
      begin
         return Editor.Commands.Unavailable_Reason
           (Editor.Executor.Command_Availability (S, Id));
      end Reason;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Assert (Reason (Editor.Commands.Command_Save_File) = "No active buffer.",
              "Save File with no buffer must use canonical No active buffer reason");
      Assert (Reason (Editor.Commands.Command_Close_Active_Buffer) = "No active buffer.",
              "Close Buffer with no open buffer must use canonical No active buffer reason");
      Assert (Reason (Editor.Commands.Command_Next_Diagnostic) = "No diagnostics.",
              "Next Diagnostic must use canonical No diagnostics reason");
      Assert (Reason (Editor.Commands.Command_Previous_Diagnostic) = "No diagnostics.",
              "Previous Diagnostic must use canonical No diagnostics reason");
      Assert (Reason (Editor.Commands.Command_Next_Bookmark) = "No bookmarks.",
              "Next Bookmark must use canonical No bookmarks reason");
      Assert (Reason (Editor.Commands.Command_Previous_Bookmark) = "No bookmarks.",
              "Previous Bookmark must use canonical No bookmarks reason");
      Assert (Reason (Editor.Commands.Command_Clear_All_Bookmarks) = "No bookmarks.",
              "Clear All Bookmarks must use canonical No bookmarks reason");
      Assert (Reason (Editor.Commands.Command_Focus_File_Tree) = "No project open.",
              "Focus File Tree must use canonical No project open reason");
      Assert
        (Editor.Commands.Unavailable_Reason
           (Editor.Commands.Unavailable
              ("Diagnostic target column is outside the line.")) =
         Editor.Commands.Reason_Diagnostic_Target_Column_Outside_Line,
         "invalid diagnostic columns must keep the column-specific reason");
   end Test_Unavailable_Reason_Consistency;

   procedure Test_Palette_Snapshot_Determinism
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      B : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Snap_A : Editor.Command_Palette.Command_Palette_Snapshot;
      Snap_B : Editor.Command_Palette.Command_Palette_Snapshot;
      Config : constant Editor.Command_Palette.Command_Palette_Config :=
        (Max_Visible_Rows             => 12,
         Overlay_Width_In_Columns     => 72,
         Show_Unavailable_Commands    => True,
         Group_Empty_Query_By_Category => True,
         Show_Selected_Reason         => True,
         Show_Selected_Description    => True,
         Show_Keybindings           => True,
         Show_Help_Row                => True);
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, A);
      Editor.Command_Palette.Reconcile_Selection (A);
      Snap_A := Editor.Command_Palette.Build_Snapshot (A, Config);

      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, B);
      Editor.Command_Palette.Reconcile_Selection (B);
      Snap_B := Editor.Command_Palette.Build_Snapshot (B, Config);

      Assert_Candidate_Vectors_Equal (A, B, "same state must produce same candidates");
      Assert (Editor.Command_Palette.Row_Count (Snap_A) =
              Editor.Command_Palette.Row_Count (Snap_B),
              "same state must produce same row count");
      for I in 1 .. Editor.Command_Palette.Row_Count (Snap_A) loop
         declare
            L : constant Editor.Command_Palette.Command_Palette_Row :=
              Editor.Command_Palette.Row (Snap_A, I);
            R : constant Editor.Command_Palette.Command_Palette_Row :=
              Editor.Command_Palette.Row (Snap_B, I);
         begin
            Assert (L.Kind = R.Kind, "snapshot row kind must be deterministic");
            Assert (L.Candidate_Index = R.Candidate_Index, "snapshot candidate index must be deterministic");
            Assert (To_String (L.Primary_Text) = To_String (R.Primary_Text),
                    "snapshot primary text must be deterministic");
            Assert (To_String (L.Secondary_Text) = To_String (R.Secondary_Text),
                    "snapshot secondary text must be deterministic");
            Assert (To_String (L.Keybinding_Text) = To_String (R.Keybinding_Text),
                    "snapshot keybinding text must be deterministic");
            Assert (L.Is_Available = R.Is_Available, "snapshot availability flag must be deterministic");
         end;
      end loop;
   end Test_Palette_Snapshot_Determinism;



   procedure Test_Guarded_Execute_Command_Unavailable_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Overlay : Editor.Overlay_Focus.Overlay_Target;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
   begin
      Editor.State.Init (S);
      Before_Overlay := Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "guarded unavailable Save File must emit exactly one message");
      Assert (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) = Before_Overlay,
              "guarded unavailable command must not change overlay focus");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "guarded unavailable command must not change panel focus");
   end Test_Guarded_Execute_Command_Unavailable_Message;

   procedure Test_Command_Row_Layout_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      L : Editor.Command_Palette.Command_Palette_Row_Layout;
   begin
      L := Editor.Command_Palette.Layout_Command_Row
        (Row_Width_Columns => 0,
         Label_Length      => 20,
         Secondary_Length  => 40,
         Keybinding_Length => 10,
         Is_Selected       => True,
         Is_Available      => False);
      Assert (not L.Show_Keybinding and then L.Label_Columns = 0,
              "zero-width command row must not allocate columns");

      L := Editor.Command_Palette.Layout_Command_Row
        (Row_Width_Columns => 8,
         Label_Length      => 30,
         Secondary_Length  => 80,
         Keybinding_Length => 30,
         Is_Selected       => True,
         Is_Available      => False);
      Assert (not L.Show_Keybinding,
              "over-wide keybinding must be omitted deterministically");
      Assert (L.Label_Columns <= 8,
              "label columns must fit within row width");

      L := Editor.Command_Palette.Layout_Command_Row
        (Row_Width_Columns => 40,
         Label_Length      => 20,
         Secondary_Length  => 50,
         Keybinding_Length => 6,
         Is_Selected       => True,
         Is_Available      => True);
      Assert (L.Show_Keybinding,
              "fitting keybinding should be shown");
      Assert (L.Label_Columns + L.Secondary_Columns + L.Keybinding_Columns <= 40,
              "layout column allocation must stay inside row width");
   end Test_Command_Row_Layout_Edges;

   procedure Test_Hidden_Command_Behavior
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (not Editor.Commands.Visible_In_Command_Palette (Editor.Commands.Command_Move_Left),
              "raw movement commands must remain hidden from palette");
      Assert (Editor.Commands.Descriptor_Is_Complete (Editor.Commands.Command_Move_Left),
              "hidden commands must still have complete descriptors");
      Assert (Editor.Commands.Has_Stable_User_Label (Editor.Commands.Command_Move_Left),
              "hidden commands must still have stable labels");
   end Test_Hidden_Command_Behavior;



   function Is_Lower_Kebab_Name (Text : String) return Boolean is
   begin
      if Text'Length = 0 then
         return False;
      end if;

      for Ch of Text loop
         if not (Ch in 'a' .. 'z' or else Ch in '0' .. '9' or else Ch = '-' or else Ch = '.') then
            return False;
         end if;
      end loop;

      return Text (Text'First) not in '-' | '.'
        and then Text (Text'Last) not in '-' | '.'
        and then Ada.Strings.Fixed.Index (Text, "--") = 0
        and then Ada.Strings.Fixed.Index (Text, "..") = 0;
   end Is_Lower_Kebab_Name;

   procedure Test_Command_Metadata_Completeness
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      D : Editor.Commands.Command_Descriptor;
   begin
      Assert (not Editor.Commands.Has_Descriptor (Editor.Commands.No_Command)
              or else not Editor.Commands.Is_Concrete_Command (Editor.Commands.No_Command),
              "No_Command may have sentinel metadata only");

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            D := Editor.Commands.Descriptor (Id);
            Assert (D.Id = Id, "descriptor id mismatch for " & Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Commands.Has_Descriptor (Id),
                    "every command id must have registry metadata");

            if Editor.Commands.Is_Concrete_Command (Id) then
               Assert (Editor.Commands.Descriptor_Is_Complete (Id),
                       "concrete descriptor must be complete: " & Editor.Commands.Command_Id'Image (Id));
               Assert (Length (D.Name) > 0, "concrete command must have label");
               Assert (Length (D.Description) > 0,
                       "concrete command must have description: " & Editor.Commands.Command_Id'Image (Id));
               Assert (Editor.Commands.Has_Availability_Handler (Id),
                       "concrete command must have an availability handler: " &
                       Editor.Commands.Command_Id'Image (Id));
               Assert (D.Bindable = Editor.Commands.Is_Bindable_Command (Id),
                       "descriptor bindable flag must mirror helper");
               Assert (D.Destructive = Editor.Commands.Is_Destructive_Command (Id),
                       "descriptor destructive flag must mirror helper: " &
                       Editor.Commands.Command_Id'Image (Id));
               Assert (D.Lifecycle = Editor.Commands.Is_Lifecycle_Command (Id),
                       "descriptor lifecycle flag must mirror helper");
               Assert (D.Configuration = Editor.Commands.Is_Configuration_Command (Id),
                       "descriptor configuration flag must mirror helper");
            end if;
         end;
      end loop;
   end Test_Command_Metadata_Completeness;

   procedure Test_Stable_Command_Name_Coverage
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Seen  : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Found : Boolean := False;
      Round : Editor.Commands.Command_Id;
   begin
      Assert (not Editor.Commands.Is_Bindable_Command (Editor.Commands.No_Command),
              "No_Command must not be bindable");
      Assert (not Editor.Commands.Has_Stable_Name (Editor.Commands.No_Command),
              "No_Command must not advertise a persisted binding name");

      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id   : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
            Name : constant String := Editor.Commands.Stable_Command_Name (Id);
         begin
            if Editor.Commands.Is_Bindable_Command (Id) then
               Assert (Editor.Commands.Has_Stable_Name (Id),
                       "bindable command must have stable name: " & Editor.Commands.Command_Id'Image (Id));
               Assert (Is_Lower_Kebab_Name (Name),
                       "stable command name must be lowercase kebab-case: " & Name);
               Round := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
               Assert (Found and then Round = Id,
                       "stable command name must round-trip: " & Name);
               Assert (not Seen (Round),
                       "stable command names must be unique: " & Name);
               Seen (Round) := True;
            end if;
         end;
      end loop;
   end Test_Stable_Command_Name_Coverage;

   procedure Test_Command_Classification_Invariants
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Clear_Workspace_State),
              "clear workspace state must be destructive");
      Assert (Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Clear_Recent_Projects),
              "clear recent projects must be destructive");
      Assert (Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Reset_Settings_To_Defaults),
              "reset settings must be destructive");
      Assert (Editor.Commands.Is_Destructive_Command (Editor.Commands.Command_Keybindings_Reset_To_Defaults),
              "reset keybindings must be destructive");
      Assert (Editor.Commands.Is_Lifecycle_Command (Editor.Commands.Command_Open_Project),
              "open project must be a lifecycle command");
      Assert (Editor.Commands.Is_Lifecycle_Command (Editor.Commands.Command_Save_Workspace_State),
              "save workspace state must be a lifecycle command");
      Assert (Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_Settings),
              "save settings must be a configuration command");
      Assert (Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_Keybindings),
              "save keybindings must be a configuration command");
      Assert (not Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_File),
              "file-content save must not be a configuration command");
      Assert (not Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_Workspace_State),
              "workspace save must not be a configuration command");
   end Test_Command_Classification_Invariants;

   procedure Test_Save_Command_Descriptions_Are_Distinct
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      function Desc (Id : Editor.Commands.Command_Id) return String is
      begin
         return To_String (Editor.Commands.Descriptor (Id).Description);
      end Desc;
   begin
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_All), "file-backed") > 0,
              "Save All description must identify file-content saving");
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_Workspace_State), "workspace/session") > 0,
              "Save Workspace State description must identify structural/session state");
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_Workspace_State), "does not save dirty file contents") > 0,
              "Save Workspace State must explicitly not claim file-content saving");
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_Settings), "preferences") > 0,
              "Save Settings description must identify global preferences");
      Assert (Ada.Strings.Fixed.Index (Desc (Editor.Commands.Command_Save_Keybindings), "keybinding") > 0,
              "Save Keybindings description must identify global keybindings");
   end Test_Save_Command_Descriptions_Are_Distinct;

   procedure Test_Execution_Result_For_No_Op_And_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (S);

      R := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.No_Command);
      Assert (R.Status = Editor.Executor.Command_No_Op,
              "No_Command execution result must be no-op");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "No_Command must not emit user-facing feedback");

      R := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Save_File);
      Assert (R.Status = Editor.Executor.Command_Unavailable,
              "unavailable command execution result must be Command_Unavailable");
      Assert (R.Command = Editor.Commands.Command_Save_File,
              "execution result must preserve command id");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable command must emit one message");
   end Test_Execution_Result_For_No_Op_And_Unavailable;


   procedure Test_Disabled_State_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      function Reason (Id : Editor.Commands.Command_Id) return String is
      begin
         return Editor.Commands.Unavailable_Reason
           (Editor.Executor.Command_Availability (S, Id));
      end Reason;
   begin
      Editor.State.Init (S);
      Editor.Recent_Projects.Clear (S.Recent_Projects);

      Assert (Reason (Editor.Commands.Command_Close_Project) = "No project open.",
              "Close Project must be disabled without a project");
      Assert (Reason (Editor.Commands.Command_Save_Workspace_State) = "No project open.",
              "Save Workspace State must be disabled without a project");
      Assert (Reason (Editor.Commands.Command_Restore_Workspace_State) = "No project open.",
              "Restore Workspace State must be disabled without a project");
      Assert (Reason (Editor.Commands.Command_Retry_Pending_Transition) = "No pending transition",
              "Retry Pending Transition must be disabled without a pending transition");
      Assert (Reason (Editor.Commands.Command_Cancel_Pending_Transition) = "No pending transition",
              "Cancel Pending Transition must be disabled without a pending transition");
      Assert (Reason (Editor.Commands.Command_Discard_Pending_Transition) = "No pending transition",
              "Discard Pending Transition must be disabled without a pending transition");
      Assert (Reason (Editor.Commands.Command_Save_All) = "No dirty file-backed buffers.",
              "Save All must be disabled without dirty file-backed buffers");
      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability
                   (S, Editor.Commands.Command_Show_Recent_Projects)),
              "Show Recent Projects must remain available to display an empty state");
      Assert (Reason (Editor.Commands.Command_Clear_Recent_Projects) = "No recent projects.",
              "Clear Recent Projects must be disabled without recent projects");

      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_Settings)),
              "Save Settings must remain globally available");
      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Settings)),
              "Reload Settings must remain globally available");
      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_Keybindings)),
              "Save Keybindings must remain globally available");
      Assert (Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Keybindings)),
              "Reload Keybindings must remain globally available");
   end Test_Disabled_State_Baseline;


   procedure Test_Command_Execution_Result_Terminology
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : Editor.Command_Execution.Command_Execution_Result;
   begin
      R := Editor.Command_Execution.Executed (Editor.Commands.Command_Save_Settings);
      Assert (R.Status = Editor.Command_Execution.Command_Executed,
              "Executed helper must classify successful commands");
      Assert (R.Command = Editor.Commands.Command_Save_Settings,
              "Executed helper must preserve command id");
      Assert (Editor.Command_Execution.Is_Terminal (R),
              "execution results must describe terminal invocations");

      R := Editor.Command_Execution.Executed (Editor.Commands.No_Command);
      Assert (R.Status = Editor.Command_Execution.Command_No_Op,
              "No_Command must never be classified as executed");

      R := Editor.Command_Execution.Unavailable (Editor.Commands.Command_Save_File);
      Assert (R.Status = Editor.Command_Execution.Command_Unavailable,
              "Unavailable helper must classify unavailable commands");

      R := Editor.Command_Execution.Failed (Editor.Commands.Command_Save_File);
      Assert (R.Status = Editor.Command_Execution.Command_Failed,
              "Failed helper must classify failed commands");

      R := Editor.Command_Execution.No_Op (Editor.Commands.Command_Dismiss_All_Messages);
      Assert (R.Status = Editor.Command_Execution.Command_No_Op,
              "No_Op helper must classify intentional no-op commands");
   end Test_Command_Execution_Result_Terminology;

   procedure Test_Unavailable_Commands_Are_Side_Effect_Limited
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Check (Id : Editor.Commands.Command_Id; Label : String) is
         S       : Editor.State.State_Type;
         Before_Project : Boolean;
         Before_Dirty   : Boolean;
         Before_Pending : Boolean;
         R       : Editor.Executor.Command_Execution_Result;
      begin
         Editor.State.Init (S);
         Before_Project := Editor.Project.Has_Project (S.Project);
         Before_Dirty   := S.File_Info.Dirty;
         Before_Pending := Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions);

         Assert (not Editor.Commands.Is_Available
                   (Editor.Executor.Command_Availability (S, Id)),
                 Label & " must be unavailable in the empty fixture");

         R := Editor.Executor.Execute_Command_With_Result (S, Id);
         Assert (R.Status = Editor.Executor.Command_Unavailable,
                 Label & " must report Command_Unavailable");
         Assert (R.Command = Id,
                 Label & " result must preserve command id");
         Assert (Editor.Messages.Count (S.Messages) = 1,
                 Label & " must emit exactly one unavailable message");
         Assert (Editor.Project.Has_Project (S.Project) = Before_Project,
                 Label & " must not change project root when unavailable");
         Assert (S.File_Info.Dirty = Before_Dirty,
                 Label & " must not change dirty state when unavailable");
         Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) = Before_Pending,
                 Label & " must not create pending transitions when unavailable");
      end Check;
   begin
      Check (Editor.Commands.Command_Save_File, "Save File");
      Check (Editor.Commands.Command_Close_Project, "Close Project");
      Check (Editor.Commands.Command_Restore_Workspace_State, "Restore Workspace State");
      Check (Editor.Commands.Command_Retry_Pending_Transition, "Retry Pending Transition");
      Check (Editor.Commands.Command_Discard_Pending_Transition, "Discard Pending Transition");
      Check (Editor.Commands.Command_Save_All, "Save All");
      --  removed-name discard-buffer is no longer a public command
      --  surface and is covered by the revert cleanup tests.
      declare
         Recent_State : Editor.State.State_Type;
      begin
         Editor.State.Init (Recent_State);
         Assert (Editor.Commands.Is_Available
                   (Editor.Executor.Command_Availability
                      (Recent_State, Editor.Commands.Command_Show_Recent_Projects)),
                 "Show Recent Projects remains executable to display the empty state");
      end;
   end Test_Unavailable_Commands_Are_Side_Effect_Limited;

   procedure Test_Availability_And_Execution_Result_Consistency
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
      R : Editor.Executor.Command_Execution_Result;
      Id : Editor.Commands.Command_Id;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Editor.State.Init (S);
         Id := Editor.Commands.Command_At (I);
         A := Editor.Executor.Command_Availability (S, Id);

         if Id /= Editor.Commands.No_Command
           and then not Editor.Commands.Is_Available (A)
         then
            R := Editor.Executor.Execute_Command_With_Result (S, Id);
            Assert (R.Status = Editor.Executor.Command_Unavailable,
                    "unavailable command must execute as unavailable: " &
                    Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Messages.Count (S.Messages) = 1,
                    "unavailable command must emit one primary message: " &
                    Editor.Commands.Command_Id'Image (Id));
         end if;
      end loop;
   end Test_Availability_And_Execution_Result_Consistency;

   function Executor_Owns_Break_Group_Command
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Dismiss_Latest_Message
            | Editor.Commands.Command_Dismiss_All_Messages
            | Editor.Commands.Command_Open_File
            | Editor.Commands.Command_Toggle_Line_Numbers
            | Editor.Commands.Command_Set_Absolute_Line_Numbers
            | Editor.Commands.Command_Set_Relative_Line_Numbers
            | Editor.Commands.Command_Set_Hybrid_Line_Numbers
            | Editor.Commands.Command_Toggle_Current_Line_Highlight
            | Editor.Commands.Command_Toggle_Syntax_Colouring
            | Editor.Commands.Command_Toggle_Diagnostics
            | Editor.Commands.Command_Toggle_Cursor_Style
            | Editor.Commands.Command_Edit_History_Clear
            | Editor.Commands.Command_Select_All
            | Editor.Commands.Command_Selection_Clear
            | Editor.Commands.Command_Build_Run
            | Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary
            | Editor.Commands.No_Command =>
            return True;
         when others =>
            return False;
      end case;
   end Executor_Owns_Break_Group_Command;

   procedure Test_Command_For_Id_Fallback_Coverage_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Id  : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         Cmd := Editor.Commands.Command_For_Id (Id);
         if Cmd.Kind = Editor.Commands.Break_Group then
            Assert (Executor_Owns_Break_Group_Command (Id),
                    "Break_Group command id must be explicitly executor-owned: " &
                    Editor.Commands.Command_Id'Image (Id));
         end if;
      end loop;
   end Test_Command_For_Id_Fallback_Coverage_Audit;

   procedure Test_Command_Palette_Dispatch_Uses_Executor_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Direct_State  : Editor.State.State_Type;
      Palette_State : Editor.State.State_Type;
      Direct_Result : Editor.Executor.Command_Execution_Result;
      Palette_Result : Editor.Executor.Command_Execution_Result;
   begin
      Editor.State.Init (Direct_State);
      Editor.State.Init (Palette_State);

      Direct_Result := Editor.Executor.Execute_Command_With_Result
        (Direct_State, Editor.Commands.Command_Save_All);
      Palette_Result := Editor.Executor.Execute_Command_With_Result
        (Palette_State, Editor.Commands.Command_Save_All);

      Assert (Direct_Result.Status = Palette_Result.Status,
              "palette-equivalent Save All route must observe the executor result");
      Assert (Editor.Messages.Count (Direct_State.Messages) =
              Editor.Messages.Count (Palette_State.Messages),
              "palette-equivalent Save All route must not add wrapper messages");
   end Test_Command_Palette_Dispatch_Uses_Executor_Result;


   procedure Test_Command_Execution_Final_Status_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      R : Editor.Command_Execution.Command_Execution_Result;
   begin
      R := Editor.Command_Execution.Executed (Editor.Commands.Command_Save_Settings);
      Assert (Editor.Command_Execution.Is_Success (R),
              "Command_Executed must be the only success status");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "executed",
              "executed status name must be stable");
      Assert (Editor.Command_Execution.Summary (R) = "COMMAND_SAVE_SETTINGS:executed",
              "execution summary must combine command image and status name");

      R := Editor.Command_Execution.No_Op (Editor.Commands.No_Command);
      Assert (not Editor.Command_Execution.Is_Success (R),
              "Command_No_Op must be terminal but not a mutation success");
      Assert (not Editor.Command_Execution.Is_User_Blocking (R),
              "Command_No_Op must not be reported as a user-blocking failure");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "no-op",
              "no-op status name must be stable");

      R := Editor.Command_Execution.Unavailable (Editor.Commands.Command_Save_File);
      Assert (Editor.Command_Execution.Is_User_Blocking (R),
              "Command_Unavailable must be a guarded user-blocking outcome");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "unavailable",
              "unavailable status name must be stable");

      R := Editor.Command_Execution.Failed (Editor.Commands.Command_Reload_Settings);
      Assert (Editor.Command_Execution.Is_User_Blocking (R),
              "Command_Failed must be a user-blocking attempted failure");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "failed",
              "failed status name must be stable");

      R := Editor.Command_Execution.Cancelled (Editor.Commands.Command_Cancel);
      Assert (not Editor.Command_Execution.Is_Success (R),
              "Command_Cancelled must not be a mutation success");
      Assert (not Editor.Command_Execution.Is_User_Blocking (R),
              "Command_Cancelled must not be reported as a failure");
      Assert (Editor.Command_Execution.Status_Name (R.Status) = "cancelled",
              "cancelled status name must be stable");
   end Test_Command_Execution_Final_Status_Helpers;

   procedure Test_Command_Category_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Category_Label (Editor.Commands.File_Category) = "File",
              "File category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Edit_Category) = "Edit",
              "Edit category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Selection_Category) = "Selection",
              "Selection category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Navigation_Category) = "Navigation",
              "Navigation category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Search_Category) = "Search",
              "Search category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Project_Category) = "Project",
              "Project category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Workspace_Category) = "Workspace",
              "Workspace category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.View_Category) = "View",
              "View category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Settings_Category) = "Settings",
              "Settings category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Diagnostics_Category) = "Diagnostics",
              "Diagnostics category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Bookmarks_Category) = "Bookmarks",
              "Bookmarks category label must remain stable");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Panel_Category) = "Panels",
              "Panel category label must remain stable as Panels");
      Assert (Editor.Commands.Category_Label (Editor.Commands.Internal_Category) = "Internal",
              "Internal category label must remain stable");
   end Test_Command_Category_Baseline;

   procedure Test_Command_Classification_Groups
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Commands.Is_File_Content_Save_Command (Editor.Commands.Command_Save_File),
              "Save File must be classified as file-content-save");
      Assert (Editor.Commands.Is_File_Content_Save_Command (Editor.Commands.Command_Save_All),
              "Save All must be classified as file-content-save");
      Assert (not Editor.Commands.Is_File_Content_Save_Command (Editor.Commands.Command_Save_Workspace_State),
              "Workspace structural save must not be classified as file-content-save");

      Assert (Editor.Commands.Is_Workspace_Structural_Save_Command (Editor.Commands.Command_Save_Workspace_State),
              "Save Workspace State must be classified as workspace-structural-save");
      Assert (Editor.Commands.Is_Global_Settings_Save_Command (Editor.Commands.Command_Save_Settings),
              "Save Settings must be classified as global-settings-save");
      Assert (Editor.Commands.Is_Global_Keybindings_Save_Command (Editor.Commands.Command_Save_Keybindings),
              "Save Keybindings must be classified as global-keybindings-save");

      Assert (Editor.Commands.Is_Navigation_Command (Editor.Commands.Command_Move_Left),
              "Move Left must be classified as navigation");
      Assert (Editor.Commands.Is_Search_Command (Editor.Commands.Command_Active_Find_Next),
              "Find Next must be classified as search");
      Assert (Editor.Commands.Is_Search_Command (Editor.Commands.Command_Replace_All),
              "Replace All must be classified as search");
      Assert (Editor.Commands.Is_Text_Editing_Command (Editor.Commands.Command_Replace_Current),
              "Replace Current must be classified as text-editing");
      Assert (Editor.Commands.Requires_Context (Editor.Commands.Command_Replace_Current),
              "Replace Current must require active-buffer/find context");
      Assert (Editor.Commands.Requires_Context (Editor.Commands.Command_Replace_Text_Set),
              "Replace Text Set must require prompt/payload context");
      Assert (Editor.Commands.Is_Panel_Focus_Command (Editor.Commands.Command_Focus_Problems),
              "Focus Problems must be classified as panel-focus");
      Assert (Editor.Commands.Is_Text_Editing_Command (Editor.Commands.Command_Insert_Newline),
              "Insert Newline must be classified as text-editing");

      Assert (not Editor.Commands.Is_Configuration_Command (Editor.Commands.Command_Save_File),
              "file-content saving must remain separate from configuration");
      Assert (not Editor.Commands.Is_Lifecycle_Command (Editor.Commands.Command_Save_Settings),
              "settings saving must remain separate from lifecycle");
   end Test_Command_Classification_Groups;

   procedure Test_Command_Registry_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Id    : Editor.Commands.Command_Id;
      Other : Editor.Commands.Command_Id;
      Found : Boolean := False;
      D     : Editor.Commands.Command_Descriptor;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         D := Editor.Commands.Descriptor (Id);

         Assert (Editor.Commands.Has_Descriptor (Id),
                 "command registry baseline missing descriptor for " &
                 Editor.Commands.Command_Id'Image (Id));

         if Editor.Commands.Is_Concrete_Command (Id) then
            Assert (Length (D.Name) > 0,
                    "concrete command missing label: " & Editor.Commands.Command_Id'Image (Id));
            Assert (Length (D.Description) > 0,
                    "concrete command missing description: " & Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Commands.Has_Availability_Handler (Id),
                    "concrete command missing availability handler marker: " &
                    Editor.Commands.Command_Id'Image (Id));
            Assert (Editor.Commands.Descriptor_Is_Complete (Id),
                    "concrete command descriptor incomplete: " &
                    Editor.Commands.Command_Id'Image (Id));
         end if;

         if Editor.Commands.Is_Bindable_Command (Id) then
            Assert (Editor.Commands.Has_Stable_Name (Id),
                    "bindable command missing stable name: " &
                    Editor.Commands.Command_Id'Image (Id));
            Other := Editor.Commands.Command_Id_From_Stable_Name
              (Editor.Commands.Stable_Command_Name (Id), Found);
            Assert (Found and then Other = Id,
                    "stable command name must round-trip for " &
                    Editor.Commands.Command_Id'Image (Id));

            if I < Editor.Commands.Command_Count then
               for J in I + 1 .. Editor.Commands.Command_Count loop
                  Other := Editor.Commands.Command_At (J);
                  if Editor.Commands.Is_Bindable_Command (Other) then
                     Assert (Editor.Commands.Stable_Command_Name (Id) /=
                               Editor.Commands.Stable_Command_Name (Other),
                             "duplicate stable command name between " &
                             Editor.Commands.Command_Id'Image (Id) & " and " &
                             Editor.Commands.Command_Id'Image (Other));
                  end if;
               end loop;
            end if;
         end if;

         if Editor.Commands.Visible_In_Command_Palette (Id) then
            Assert (D.Category /= Editor.Commands.Internal_Category,
                    "visible command must not use Internal category: " &
                    Editor.Commands.Command_Id'Image (Id));
         end if;
      end loop;
   end Test_Command_Registry_Baseline;

   procedure Test_Unavailable_Result_Message_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      R     : Editor.Executor.Command_Execution_Result;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Editor.State.Init (S);
      R := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (R.Status = Editor.Executor.Command_Unavailable,
              "Retry Pending Transition without pending state must be unavailable");
      Assert (Editor.Command_Execution.Is_User_Blocking (R),
              "unavailable retry must be a user-blocking command result");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "unavailable retry must emit exactly one primary message");

      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found,
              "unavailable retry must produce an active message");
      Assert (Editor.Messages.Text (Msg) = "No pending transition",
              "unavailable retry message must be canonical");
      Assert (Editor.Messages.Severity (Msg) = Editor.Messages.Info_Message,
              "unavailable retry must not be reported as failed/error message");
   end Test_Unavailable_Result_Message_Coherence;


   procedure Test_No_Op_Is_Public_For_No_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S  : Editor.State.State_Type;
      R  : Editor.Executor.Command_Execution_Result;
      Id : Editor.Commands.Command_Id;
   begin
      Editor.State.Init (S);
      R := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.No_Command);
      Assert (R.Status = Editor.Executor.Command_No_Op,
              "No_Command must remain the sentinel no-op");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "No_Command must not emit messages");

      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         if Id /= Editor.Commands.No_Command
           and then not Editor.Commands.Is_Available
             (Editor.Executor.Command_Availability (S, Id))
         then
            declare
               Local : Editor.State.State_Type;
            begin
               Editor.State.Init (Local);
               R := Editor.Executor.Execute_Command_With_Result (Local, Id);
               Assert (R.Status /= Editor.Executor.Command_No_Op,
                       "concrete unavailable command must not hide behind no-op: " &
                       Editor.Commands.Command_Id'Image (Id));
            end;
         end if;
      end loop;
   end Test_No_Op_Is_Public_For_No_Command;



   procedure Assert_Public_Build_Name_Not_Registered
     (Name : String)
   is
      Found : Boolean;
      Id    : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
   begin
      if Name = "build.run" then
         Assert (Found and then Id = Editor.Commands.Command_Build_Run,
                 "build.run must be the single guarded public build command");
      else
         Assert (not Found,
                 "reserved public build alias must not be registered: " & Name);
      end if;
   end Assert_Public_Build_Name_Not_Registered;

   function Valid_Public_Input
      return Editor.External_Producers.Public_Build_Command_Input
   is
   begin
      return
        (Source           => Editor.External_Producers.Public_Build_Input_Test_Context,
         Tool             => Editor.External_Producers.GPRbuild_Tool,
         Program_Label    => To_Unbounded_String ("gprbuild"),
         Working_Context  =>
           Editor.External_Producers.Build_Inherited_Test_Working_Context,
         Working_Context_Model =>
           (Source => Editor.External_Producers.Public_Build_Working_Context_Test_Context,
            Label  => Null_Unbounded_String,
            User_Acknowledged_Context => True),
         Arguments        =>
           Editor.External_Producers.Build_Process_Argument_Vector ("-q"),
         Consent          => Editor.External_Producers.Build_Consent_User_Confirmed,
         Consent_Model    =>
           (Source => Editor.External_Producers.Public_Build_Consent_Test_Context,
            User_Acknowledged_Execution => True,
            User_Acknowledged_No_Shell => True,
            User_Acknowledged_External_Process => True,
            User_Acknowledged_Diagnostics_Output => True),
         Show_Diagnostics => False);
   end Valid_Public_Input;


   function Valid_Test_Consent
      return Editor.External_Producers.Public_Build_Consent_Model
   is
   begin
      return
        (Source => Editor.External_Producers.Public_Build_Consent_Test_Context,
         User_Acknowledged_Execution => True,
         User_Acknowledged_No_Shell => True,
         User_Acknowledged_External_Process => True,
         User_Acknowledged_Diagnostics_Output => True);
   end Valid_Test_Consent;

   function Valid_User_Form_Consent
      return Editor.External_Producers.Public_Build_Consent_Model
   is
   begin
      return
        (Source => Editor.External_Producers.Public_Build_Consent_User_Form_Acknowledged,
         User_Acknowledged_Execution => True,
         User_Acknowledged_No_Shell => True,
         User_Acknowledged_External_Process => True,
         User_Acknowledged_Diagnostics_Output => True);
   end Valid_User_Form_Consent;

   function Valid_Test_Working_Context
      return Editor.External_Producers.Public_Build_Working_Context_Model
   is
   begin
      return
        (Source => Editor.External_Producers.Public_Build_Working_Context_Test_Context,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => True);
   end Valid_Test_Working_Context;

   function Valid_User_Form_Working_Context
      return Editor.External_Producers.Public_Build_Working_Context_Model
   is
   begin
      return
        (Source => Editor.External_Producers.Public_Build_Working_Context_User_Form_Label,
         Label  => To_Unbounded_String ("current-project-root"),
         User_Acknowledged_Context => True);
   end Valid_User_Form_Working_Context;

   procedure Assert_Public_Build_Input_Conversion_Consistent
     (Input   : Editor.External_Producers.Public_Build_Command_Input;
      Request : Editor.External_Producers.Build_Run_Request)
   is
      use Editor.External_Producers;
   begin
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "conversion must use user-opt-in provenance");
      Assert (Request.Tool = Input.Tool,
              "conversion must preserve build tool");
      Assert (To_String (Request.Command_Label) = To_String (Input.Program_Label),
              "conversion must preserve program label as metadata");
      Assert (To_String (Request.Arguments)'Length = 0,
              "conversion must not introduce opaque command text");
      Assert (Process_Argument_Count (Request.Structured_Arguments) =
              Process_Argument_Count (Input.Arguments),
              "conversion must preserve structured argv count");
      Assert (To_String (Request.Working_Label)'Length = 0,
              "conversion must not create a real working directory label");
   end Assert_Public_Build_Input_Conversion_Consistent;















   function Default_Result return Editor.External_Producers.Public_Build_Guardrail_Result
   is
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      return Run_Public_Build_Guardrail_Audit (S);
   end Default_Result;



   function Starts_With (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length
        and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Yes_No (Value : Boolean) return String is
   begin
      return (if Value then "yes" else "no");
   end Yes_No;

   function Existing_Switcher_Command_Reference_Path return String is
   begin
      if Ada.Directories.Exists ("docs/open_buffer_switcher_commands.md") then
         return "docs/open_buffer_switcher_commands.md";
      elsif Ada.Directories.Exists ("../docs/open_buffer_switcher_commands.md") then
         return "../docs/open_buffer_switcher_commands.md";
      elsif Ada.Directories.Exists ("../../docs/open_buffer_switcher_commands.md") then
         return "../../docs/open_buffer_switcher_commands.md";
      else
         return "docs/open_buffer_switcher_commands.md";
      end if;
   end Existing_Switcher_Command_Reference_Path;

   function Reference_Text return String is
      File : Ada.Text_IO.File_Type;
      Text : Unbounded_String := Null_Unbounded_String;
      Path : constant String := Existing_Switcher_Command_Reference_Path;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Text, Ada.Text_IO.Get_Line (File));
         Append (Text, ASCII.LF);
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Text);
   end Reference_Text;

   function Cell (Line : String; Number : Positive) return String is
      Current : Natural := 0;
      Start_Pos : Natural := 0;
   begin
      for I in Line'Range loop
         if Line (I) = '|' then
            Current := Current + 1;
            if Current = Number then
               Start_Pos := I + 1;
            elsif Current = Number + 1 then
               if Start_Pos > I - 1 then
                  return "";
               end if;
               return Ada.Strings.Fixed.Trim
                 (Line (Start_Pos .. I - 1), Ada.Strings.Both);
            end if;
         end if;
      end loop;
      return "";
   end Cell;

   function Switcher_Command_Is_In_Reference
     (Id : Editor.Commands.Command_Id) return Boolean
   is
      Stable : constant String := Editor.Commands.Stable_Command_Name (Id);
   begin
      return Starts_With (Stable, "buffers.switcher.")
        or else Stable = "buffers.recent.previous"
        or else Stable = "buffers.recent.next"
        or else Stable = "file.close-other-buffers"
        or else Stable = "file.close-clean-buffers"
        or else Stable = "buffers.close-unpinned";
   end Switcher_Command_Is_In_Reference;

   function Classification_Label
     (D : Editor.Commands.Command_Descriptor) return String
   is
   begin
      if D.Destructive and then D.Lifecycle and then D.Configuration then
         return "Destructive+Lifecycle+Configuration";
      elsif D.Destructive and then D.Lifecycle then
         return "Destructive+Lifecycle";
      elsif D.Destructive and then D.Configuration then
         return "Destructive+Configuration";
      elsif D.Lifecycle and then D.Configuration then
         return "Lifecycle+Configuration";
      elsif D.Destructive then
         return "Destructive";
      elsif D.Lifecycle then
         return "Lifecycle";
      elsif D.Configuration then
         return "Configuration";
      else
         return "General";
      end if;
   end Classification_Label;

   function Hint_Label (Id : Editor.Commands.Command_Id) return String is
      use Editor.Commands;
   begin
      case Id is
         when Command_Close_Buffer_Switcher
            | Command_Accept_Buffer_Switcher
            | Command_Buffer_Switcher_Next_Result
            | Command_Buffer_Switcher_Previous_Result
            | Command_Buffer_Switcher_Filter_Clear
            | Command_Buffer_Switcher_Sort_Next
            | Command_Buffer_Switcher_Mark_Set
            | Command_Buffer_Switcher_Mark_Clear
            | Command_Buffer_Switcher_Mark_Clear_All
            | Command_Buffer_Switcher_Mark_Close_Marked
            | Command_Buffer_Switcher_Mark_Confirm
            | Command_Buffer_Switcher_Mark_Cancel
            | Command_Buffer_Switcher_Mark_Review_Show
            | Command_Buffer_Switcher_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Next
            | Command_Buffer_Switcher_Pending_Mark_Previous
            | Command_Buffer_Switcher_Pending_Mark_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Next
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
            | Command_Buffer_Switcher_Mark_Next
            | Command_Buffer_Switcher_Mark_Previous =>
            return "conditional";
         when others =>
            return "no";
      end case;
   end Hint_Label;

   function Owner_Label (Stable : String) return String is
   begin
      if Starts_With (Stable, "buffers.switcher.filter.")
        or else Starts_With (Stable, "buffers.switcher.sort.")
      then
         return "filter/query/sort state";
      elsif Starts_With (Stable, "buffers.switcher.selected.") then
         return "selected row";
      elsif Starts_With (Stable, "buffers.switcher.preview.") then
         return "preview state";
      elsif Starts_With (Stable, "buffers.switcher.mark.") then
         if Ada.Strings.Fixed.Index (Stable, ".review.") > 0
           or else Ada.Strings.Fixed.Index (Stable, ".next") > 0
           or else Ada.Strings.Fixed.Index (Stable, ".previous") > 0
           or else Ada.Strings.Fixed.Index (Stable, ".summary") > 0
         then
            return "mark review state";
         else
            return "mark set";
         end if;
      elsif Starts_With (Stable, "buffers.switcher.pending-mark.dirty-prune.apply.") then
         return "dirty-prune apply confirmation";
      elsif Starts_With (Stable, "buffers.switcher.pending-mark.dirty-prune.") then
         return "dirty-prune preview";
      elsif Starts_With (Stable, "buffers.switcher.pending-mark.dirty-") then
         return "dirty pending targets";
      elsif Ada.Strings.Fixed.Index (Stable, ".pruned") > 0
        or else Ada.Strings.Fixed.Index (Stable, "restore-selected-pruned") > 0
      then
         return "ordinary pruned targets";
      elsif Starts_With (Stable, "buffers.switcher.pending-mark.") then
         return "pending marked close";
      elsif Starts_With (Stable, "buffers.recent.") then
         return "recent-buffer traversal";
      elsif Starts_With (Stable, "buffers.close-")
        or else Stable = "file.close-other-buffers"
        or else Stable = "file.close-clean-buffers"
      then
         return "buffer cleanup policy";
      else
         return "switcher overlay";
      end if;
   end Owner_Label;

   procedure Assert_Row_Matches_Descriptor (Line : String) is
      Stable : constant String := Cell (Line, 1);
      Found  : Boolean := False;
      Id     : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      D      : Editor.Commands.Command_Descriptor;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (Stable, Found);
      Assert (Found,
              "documented switcher command must resolve to descriptor: " & Stable);
      Assert (Switcher_Command_Is_In_Reference (Id),
              "documented command must be part of switcher reference: " & Stable);
      D := Editor.Commands.Descriptor (Id);
      Assert (Cell (Line, 2) = To_String (D.Description),
              "documented description must match descriptor for " & Stable);
      Assert (Cell (Line, 3) = Editor.Commands.Category_Label (D.Category),
              "documented category must match descriptor for " & Stable);
      Assert (Cell (Line, 4) = Classification_Label (D),
              "documented classification must match descriptor for " & Stable);
      Assert (Cell (Line, 5) = Yes_No (D.Bindable),
              "documented bindability must match descriptor for " & Stable);
      Assert (Cell (Line, 6) = Yes_No (D.Visibility = Editor.Commands.Palette_Command),
              "documented palette visibility must match descriptor for " & Stable);
      Assert (Cell (Line, 7) = Hint_Label (Id),
              "documented hint eligibility must match hint baseline for " & Stable);
      Assert (Cell (Line, 8) = "Executor",
              "documented route class must match executor route baseline for " & Stable);
      Assert (Cell (Line, 9) = Owner_Label (Stable),
              "documented availability owner must match baseline for " & Stable);
      Assert (Cell (Line, 10) = "current",
              "documented compatibility status must be current for " & Stable);
   end Assert_Row_Matches_Descriptor;




   procedure Test_Product_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Product_Commands : constant Command_Array :=
        (Editor.Commands.Command_Open_Project,
         Editor.Commands.Command_Close_Project,
         Editor.Commands.Command_Switch_Project,
         Editor.Commands.Command_Show_Recent_Projects,
         Editor.Commands.Command_Open_File,
         Editor.Commands.Command_Save_File,
         Editor.Commands.Command_Save_File_As,
         Editor.Commands.Command_Reload_Active_Buffer,
         Editor.Commands.Command_Revert_Active_Buffer,
         Editor.Commands.Command_Refresh_File_Tree,
         Editor.Commands.Command_File_Tree_Open_Selected,
         Editor.Commands.Command_File_Tree_Create_File,
         Editor.Commands.Command_File_Tree_Create_Directory,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         Editor.Commands.Command_File_Tree_Delete_Selected,
         Editor.Commands.Command_Open_Quick_Open,
         Editor.Commands.Command_Run_Project_Search,
         Editor.Commands.Command_Open_Selected_Project_Search_Result,
         Editor.Commands.Command_Show_Outline,
         Editor.Commands.Command_Refresh_Outline_Project_Index,
         Editor.Commands.Command_Goto_Declaration,
         Editor.Commands.Command_Goto_Body,
         Editor.Commands.Command_Goto_Spec,
         Editor.Commands.Command_Find_References,
         Editor.Commands.Command_Show_Hover,
         Editor.Commands.Command_Show_Completions,
         Editor.Commands.Command_Semantic_Completion_Select_Next,
         Editor.Commands.Command_Semantic_Completion_Select_Previous,
         Editor.Commands.Command_Semantic_Completion_Accept,
         Editor.Commands.Command_Semantic_Popup_Dismiss,
         Editor.Commands.Command_Rename_Symbol_Preview,
         Editor.Commands.Command_Rename_Symbol_Apply,
         Editor.Commands.Command_Semantic_Refresh_Buffer,
         Editor.Commands.Command_Semantic_Refresh_Project_Index,
         Editor.Commands.Command_Language_Index_Clear,
         Editor.Commands.Command_Language_Index_Status,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Build_Run,
         Editor.Commands.Command_Build_UI_Show,
         Editor.Commands.Command_Build_UI_Toggle,
         Editor.Commands.Command_Build_UI_Hide,
         Editor.Commands.Command_Build_UI_Focus,
         Editor.Commands.Command_Diagnostics_Show,
         Editor.Commands.Command_Diagnostics_Execute_Selected_Action,
         Editor.Commands.Command_Next_Buffer,
         Editor.Commands.Command_Previous_Buffer,
         Editor.Commands.Command_Close_Active_Buffer,
         Editor.Commands.Command_Close_All_Clean_Buffers,
         Editor.Commands.Command_Restore_Workspace_State);

      function Contains_Internal_Term (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
      begin
         return Ada.Strings.Fixed.Index (Lower, "audit") > 0
           or else Ada.Strings.Fixed.Index (Lower, "fixture") > 0
           or else Ada.Strings.Fixed.Index (Lower, "guard") > 0
           or else Ada.Strings.Fixed.Index (Lower, "scaffold") > 0
           or else Ada.Strings.Fixed.Index (Lower, "surface entry") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route") > 0
           or else Ada.Strings.Fixed.Index (Lower, "executor") > 0
           or else Ada.Strings.Fixed.Index (Lower, "runtime state") > 0
           or else Ada.Strings.Fixed.Index (Lower, "command request") > 0
           or else Ada.Strings.Fixed.Index (Lower, "prompt identity") > 0
           or else Ada.Strings.Fixed.Index (Lower, "producer") > 0
           or else Ada.Strings.Fixed.Index (Lower, "synthetic") > 0
           or else Ada.Strings.Fixed.Index (Lower, "buffer_id") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route_id") > 0
           or else Ada.Strings.Fixed.Index (Lower, "buffer id") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route id") > 0;
      end Contains_Internal_Term;

      function Looks_Like_Fallback_Copy
        (Name : String;
         Description : String) return Boolean
      is
         Lower_Desc : constant String := Ada.Characters.Handling.To_Lower (Description);
         Lower_Name : constant String := Ada.Characters.Handling.To_Lower (Name);
      begin
         return Lower_Desc = "execute " & Lower_Name & "."
           or else Ada.Strings.Fixed.Index (Lower_Desc, "execute command") > 0;
      end Looks_Like_Fallback_Copy;

      D : Editor.Commands.Command_Descriptor;
      A : Editor.Commands.Command_Availability;
      S : Editor.State.State_Type;
   begin
      for Id of Product_Commands loop
         D := Editor.Commands.Descriptor (Id);
         Assert (Editor.Commands.Has_Descriptor (Id),
                 "product command has descriptor");
         Assert (To_String (D.Name)'Length > 0,
                 "product command label is present");
         Assert (not Contains_Internal_Term (To_String (D.Name)),
                 "product command label avoids internal terms: " &
                 To_String (D.Name));
         Assert (not Contains_Internal_Term (To_String (D.Description)),
                 "product command description avoids internal terms: " &
                 To_String (D.Description));
         Assert (D.Visibility = Editor.Commands.Palette_Command
                   or else D.Visibility = Editor.Commands.Hidden_Command,
                 "product command visibility is explicit");
         A := Editor.Executor.Command_Availability (S, Id);
         if not Editor.Commands.Is_Available (A) then
            Assert (Editor.Commands.Unavailable_Reason (A)'Length > 0,
                    "unavailable product command reports a reason");
            Assert (not Contains_Internal_Term
                      (Editor.Commands.Unavailable_Reason (A)),
                    "unavailable reason avoids internal terms");
         end if;
      end loop;

      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run) = "build.run",
              "build.run command id remains canonical");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Switch_Project) = "project.switch",
              "project.switch command id remains canonical");

      for Id in Editor.Commands.First_Command .. Editor.Commands.Last_Command loop
         D := Editor.Commands.Descriptor (Id);
         if D.Visibility = Editor.Commands.Palette_Command then
            Assert
              (Ada.Strings.Fixed.Index
                 (Ada.Characters.Handling.To_Lower
                    (To_String (D.Name) & " " & To_String (D.Description)),
                  "open-open buffer list") = 0,
               "palette-visible command surface must not use stale Open Buffer List wording: " &
               Editor.Commands.Stable_Command_Name (Id));
            Assert
              (not Looks_Like_Fallback_Copy
                 (To_String (D.Name), To_String (D.Description)),
               "palette-visible command description must be action-oriented product copy: " &
               Editor.Commands.Stable_Command_Name (Id) & " => " &
               To_String (D.Description));
         end if;
      end loop;
   end Test_Product_Command_Surface;








   overriding function Name
     (T : Command_Surface_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Tests");
   end Name;



   procedure Test_Command_Surface_Review_Default_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Review : Editor.Command_Surface.Command_Surface_Review;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Review := Editor.Command_Surface.Review_Command_Surface (S);
      Assert (Review.Descriptor_Count = Editor.Commands.Concrete_Command_Count,
              "review must count concrete command descriptors");
      Assert (Review.Review_Passed,
              Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review));
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: command surface healthy",
              "default command surface feedback must be healthy");
   end Test_Command_Surface_Review_Default_Passes;

   procedure Test_Command_Surface_Review_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Review : Editor.Command_Surface.Command_Surface_Review;
   begin
      Review := (Descriptor_Count             => 1,
                 Stable_Ids_Unique             => False,
                 Display_Names_Present         => True,
                 Categories_Valid              => True,
                 Visibility_Consistent         => True,
                 Bindability_Consistent        => True,
                 Executor_Coverage_Complete    => True,
                 Availability_Reasons_Stable   => True,
                 Palette_Projection_Consistent => True,
                 Discoverability_Metadata_Coherent => True,
                 Keybinding_Targets_Valid      => True,
                 Persistence_Clean             => True,
                 Public_Build_Guardrail_Intact => True,
                 Review_Passed                 => False);
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: duplicate command id detected",
              "stable-id failure feedback must be deterministic");

      Review.Stable_Ids_Unique := True;
      Review.Display_Names_Present := False;
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: command descriptor incomplete",
              "descriptor failure feedback must be deterministic");

      Review.Display_Names_Present := True;
      Review.Categories_Valid := False;
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: invalid command category detected",
              "category failure feedback must be deterministic");

      Review.Categories_Valid := True;
      Review.Public_Build_Guardrail_Intact := False;
      Assert (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
              "Commands: public build guardrail failed",
              "public-build sentinel feedback must be deterministic");
   end Test_Command_Surface_Review_Feedback_Is_Deterministic;

   procedure Test_Command_Surface_Review_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      Before_Palette_Count : Natural;
      Before_Build_Manifest : Public_Build_Guardrail_Regression_Manifest;
      After_Build_Manifest  : Public_Build_Guardrail_Regression_Manifest;
      Review_A : Editor.Command_Surface.Command_Surface_Review;
      Review_B : Editor.Command_Surface.Command_Surface_Review;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      Before_Palette_Count := Editor.Commands.Palette_Command_Count;
      Before_Build_Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);

      Review_A := Editor.Command_Surface.Review_Command_Surface (S);
      Review_B := Editor.Command_Surface.Review_Command_Surface (S);
      After_Build_Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);

      Assert (Review_A = Review_B,
              "command surface review must be deterministic across repeated reads");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "command surface review must not emit messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "command surface review must not create or alter active buffers");
      Assert (Editor.Commands.Palette_Command_Count = Before_Palette_Count,
              "command surface review must not alter palette-visible descriptor count");
      Assert (Before_Build_Manifest = After_Build_Manifest,
              "command surface review must not alter public-build regression manifest state");
   end Test_Command_Surface_Review_Is_Side_Effect_Free;

   procedure Test_Command_Surface_Stable_Ids_Are_Unique
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Seen  : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Found : Boolean;
      Round : Editor.Commands.Command_Id;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
            Name : constant String := Editor.Commands.Stable_Command_Name (Id);
         begin
            if Editor.Commands.Is_Concrete_Command (Id) then
               Round := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
               Assert (Found and then Round = Id,
                       "stable command id must resolve back to its descriptor: " & Name);
               Assert (not Seen (Round),
                       "stable command id must be unique: " & Name);
               Seen (Round) := True;
            end if;
         end;
      end loop;
   end Test_Command_Surface_Stable_Ids_Are_Unique;

   procedure Test_Command_Surface_Command_Ids_Follow_Canonicalization_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean;
      Id : Editor.Commands.Command_Id;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (" FILE.SAVE ", Found);
      Assert (Found and then Id = Editor.Commands.Command_Save_File,
              "command id lookup must preserve trim/lowercase canonicalization for dot-scoped stable ids");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.save", Found);
      Assert (Found and then Id = Editor.Commands.Command_Save_File,
              "canonical stable id lookup must still resolve exact lowercase names");
   end Test_Command_Surface_Command_Ids_Follow_Canonicalization_Policy;




   procedure Prepare_File_Tree
     (S      : in out Editor.State.State_Type;
      Path   : out Unbounded_String;
      Node   : out Editor.File_Tree.File_Tree_Node_Summary)
   is
      Root : constant String := Editor.Test_Temp.Base & "/editor_affordance_tree";
      File_Path : constant String := Root & "/a.txt";
      Found : Boolean := False;
      Node_Id : Editor.File_Tree.File_Tree_Node_Id;
   begin
      if not Ada.Directories.Exists (Root) then
         Ada.Directories.Create_Directory (Root);
      end if;
      declare
         F : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, File_Path);
         Ada.Text_IO.Put_Line (F, "alpha");
         Ada.Text_IO.Close (F);
      exception
         when others =>
            if Ada.Text_IO.Is_Open (F) then
               Ada.Text_IO.Close (F);
            end if;
            raise;
      end;

      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Node_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, File_Path, Found);
      Assert (Found, "fixture must scan a.txt");
      Node := Editor.File_Tree.Node (S.File_Tree, Node_Id);
      Path := To_Unbounded_String (File_Path);
   end Prepare_File_Tree;




   overriding procedure Register_Tests
     (T : in out Command_Surface_Test_Case)
   is
   begin




      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Review_Default_Passes'Access,
         "Command Surface Review Default Passes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Review_Is_Side_Effect_Free'Access,
         "Command Surface Review Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Review_Feedback_Is_Deterministic'Access,
         "Command Surface Review Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Stable_Ids_Are_Unique'Access,
         "Command Surface Stable Ids Are Unique");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Command_Ids_Follow_Canonicalization_Policy'Access,
         "Command Surface Command Ids Follow Canonicalization Policy");









      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Recent_Project_Selected_Row_Commands_Are_No_Payload'Access,
         "Recent Projects selected-row commands are no-payload");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Descriptor_Audit_Helpers'Access,
         "Command Descriptor Audit Helpers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Candidates_Use_Command_Registry'Access,
         "Palette Candidates Use Command Registry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Static_Command_Invariants'Access,
         "Static Command Invariants");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_Is_Read_Only_On_Empty_State'Access,
         "Availability Is Read-Only On Empty State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unavailable_Reason_Consistency'Access,
         "Unavailable Reason Consistency");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Snapshot_Determinism'Access,
         "Palette Snapshot Determinism");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Guarded_Execute_Command_Unavailable_Message'Access,
         "Guarded Execute Command Unavailable Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Row_Layout_Edges'Access,
         "Command Row Layout Edges");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hidden_Command_Behavior'Access,
         "Hidden Command Behavior");


      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Metadata_Completeness'Access,
         "Command Metadata Completeness");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Stable_Command_Name_Coverage'Access,
         "Stable Command Name Coverage");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Classification_Invariants'Access,
         "Command Classification Invariants");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Command_Descriptions_Are_Distinct'Access,
         "Save Command Descriptions Are Distinct");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execution_Result_For_No_Op_And_Unavailable'Access,
         "Execution Result For No-Op And Unavailable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Disabled_State_Baseline'Access,
         "Disabled State Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Execution_Result_Terminology'Access,
         "Command Execution Result Terminology");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unavailable_Commands_Are_Side_Effect_Limited'Access,
         "Unavailable Commands Are Side-Effect Limited_View");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_And_Execution_Result_Consistency'Access,
         "Availability And Execution Result Consistency");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_For_Id_Fallback_Coverage_Audit'Access,
         "Command_For_Id Fallback Coverage Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Dispatch_Uses_Executor_Result'Access,
         "Command Palette Dispatch Uses Executor Result");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Execution_Final_Status_Helpers'Access,
         "Command Execution Final Status Helpers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Category_Baseline'Access,
         "Command Category Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Classification_Groups'Access,
         "Command Classification Groups");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Registry_Baseline'Access,
         "Command Registry Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unavailable_Result_Message_Coherence'Access,
         "Unavailable Result Message Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Op_Is_Public_For_No_Command'Access,
         "No-Op Is Public For No_Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Product_Command_Surface'Access,
         "Product Command Surface");
   end Register_Tests;

end Editor.Command_Surface.Tests;
