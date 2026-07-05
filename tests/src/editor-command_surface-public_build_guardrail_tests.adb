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

package body Editor.Command_Surface.Public_Build_Guardrail_Tests is

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



   overriding function Name
     (T : Public_Build_Guardrail_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Public_Build_Guardrail.Tests");
   end Name;

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

   procedure Prepare_File_Tree
     (S      : in out Editor.State.State_Type;
      Path   : out Unbounded_String;
      Node   : out Editor.File_Tree.File_Tree_Node_Summary)
   is
      Root : constant String := "/tmp/editor_affordance_tree";
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

   procedure Test_Public_Build_Command_Not_Ready_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (Editor.External_Producers.Build_Public_Command_Not_Ready_Feedback (R) =
              "Build: public command not ready",
              "ready baseline feedback must fall back to generic not-ready helper text");
      R.Public_Consent_UX_Publicly_Ready := False;
      Assert (Editor.External_Producers.Build_Public_Command_Not_Ready_Feedback (R) =
              "Build: consent UX not ready",
              "feedback must report missing consent UX when simulated");
      R.Public_Consent_UX_Publicly_Ready := True;
      R.Public_Working_Context_Publicly_Ready := False;
      Assert (Editor.External_Producers.Build_Public_Command_Not_Ready_Feedback (R) =
              "Build: working directory UX not ready",
              "feedback must report missing working-directory UX without paths");
      R.Public_Working_Context_Publicly_Ready := True;
      Assert (Editor.External_Producers.Build_Public_Command_Not_Ready_Feedback (R) =
              "Build: public command not ready",
              "feedback must not probe project files in the ready baseline");
   end Test_Public_Build_Command_Not_Ready_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Repeated_Audits_Are_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R1 : Public_Build_Command_Readiness_Audit_Result;
      R2 : Public_Build_Command_Readiness_Audit_Result;
      Matrix1 : Public_Build_UX_Dependency_Matrix;
      Matrix2 : Public_Build_UX_Dependency_Matrix;
      Before_Messages : Natural;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      R1 := Run_Public_Build_Command_Readiness_Audit (S);
      R2 := Run_Public_Build_Command_Readiness_Audit (S);
      Matrix1 := Build_Public_Build_UX_Dependency_Matrix;
      Matrix2 := Build_Public_Build_UX_Dependency_Matrix;
      Assert (R1.Public_Command_Promotion_Status = R2.Public_Command_Promotion_Status,
              "repeated readiness audits must keep promotion status stable");
      Assert (R1.Primary_Promotion_Blocker = R2.Primary_Promotion_Blocker,
              "repeated readiness audits must keep primary blocker stable");
      for Dependency in Public_Build_UX_Dependency loop
         Assert (Matrix1 (Dependency) = Matrix2 (Dependency),
                 "repeated dependency matrix builds must be stable");
      end loop;
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "repeated audits must not post messages");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Repeated_Audits_Are_Stable;

   procedure Test_Public_Build_Blocker_Summary_Is_Deterministic_For_Current_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S1 : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
      S2 : constant Public_Build_Blocker_Summary :=
        Build_Public_Build_Blocker_Summary;
   begin
      Assert (not S1.Consent_UX_Missing,
              "blocker summary must show consent UX ready");
      Assert (not S1.Working_Context_UX_Missing,
              "blocker summary must show working-context UX ready");
      Assert (not S1.Implicit_Source_Unsupported,
              "blocker summary must report explicit-source policy support");
      Assert (not S1.Public_Route_Missing,
              "blocker summary must show guarded public route present");
      Assert (not S1.Public_Command_Not_Registered,
              "blocker summary must show guarded public command registered");
      Assert (S1.Default_Execution_Disabled,
              "blocker summary must report default execution disabled");
      Assert (Validate_Public_Build_UX_Dependencies
                (Build_Public_Build_UX_Dependency_Matrix) =
              Public_Build_Promotion_Command_Surface_Ready,
              "blocker summary must agree with ready dependency matrix");
      Assert (S1.Primary_Blocker = S2.Primary_Blocker,
              "blocker summary primary blocker must be deterministic");
   end Test_Public_Build_Blocker_Summary_Is_Deterministic_For_Current_State;

   procedure Test_Public_Build_Guardrail_Audit_Default_State_Passed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Result : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Result := Run_Public_Build_Guardrail_Audit (S);
      Assert (Result.Status = Public_Build_Guardrail_Passed,
              "default guardrail status must pass");
      Assert (Result.No_Public_Command,
              "normalized guardrail must report no public build command");
      Assert (Result.No_Public_Keybinding,
              "normalized guardrail must report no public build keybinding");
      Assert (Result.No_Public_Palette_Entry,
              "normalized guardrail must report no public build palette row");
      Assert (Result.No_Public_Executor_Route,
              "normalized guardrail must report no public build Executor route");
      Assert (Result.No_Public_Invocation_Path,
              "normalized guardrail must report no public invocation path");
      Assert (Result.No_Public_Bindable_Command,
              "normalized guardrail must report no bindable public build command");
      Assert (not Result.Promotion_Blocked,
              "normalized guardrail must report guarded promotion ready");
      Assert (Result.Default_Execution_Disabled,
              "normalized guardrail must report disabled default execution");
      Assert (not Result.Dependency_Blockers_Active,
              "normalized guardrail must report no active public UX blockers");
      Assert (Result.Persistence_Clean,
              "normalized guardrail must report clean persistence");
      Assert (Result.Audits_Consistent,
              "normalized guardrail must report consistent audits");
   end Test_Public_Build_Guardrail_Audit_Default_State_Passed;

   procedure Test_Public_Build_Guardrail_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Result;
      After  : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Before := Run_Public_Build_Guardrail_Audit (S);
      After := Run_Public_Build_Guardrail_Audit (S);
      Assert (Before.Status = After.Status
              and then Before.No_Public_Command = After.No_Public_Command
              and then Before.No_Public_Keybinding = After.No_Public_Keybinding
              and then Before.No_Public_Palette_Entry = After.No_Public_Palette_Entry
              and then Before.No_Public_Executor_Route = After.No_Public_Executor_Route
              and then Before.No_Public_Invocation_Path = After.No_Public_Invocation_Path
              and then Before.No_Public_Bindable_Command = After.No_Public_Bindable_Command
              and then Before.Promotion_Blocked = After.Promotion_Blocked
              and then Before.Default_Execution_Disabled = After.Default_Execution_Disabled
              and then Before.Dependency_Blockers_Active = After.Dependency_Blockers_Active
              and then Before.Persistence_Clean = After.Persistence_Clean
              and then Before.Audits_Consistent = After.Audits_Consistent,
              "guardrail audit must be deterministic and side-effect-free");
   end Test_Public_Build_Guardrail_Audit_Is_Side_Effect_Free;

   procedure Test_Public_Build_Surface_Command_Id_List_Is_Centralized
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
   begin
      Assert (Names.Length = 1,
              "central public build public-id list must contain every public id");
      for Name of Names loop
         Assert (Is_Public_Build_Surface_Id (To_String (Name)),
                 "public-id classifier must use the centralized list");
      end loop;
      Assert (not Is_Public_Build_Surface_Id ("diagnostics.run-build"),
              "diagnostics.run-build remains reserved, not public");
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Test_Public_Build_Surface_Command_Id_List_Is_Centralized;

   procedure Test_Public_Build_Surface_Command_Id_Not_Palette_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Guardrail_Audit (S).No_Public_Palette_Entry,
              "public build ids must not appear as normal palette rows");
   end Test_Public_Build_Surface_Command_Id_Not_Palette_Row;

   procedure Test_Public_Build_Surface_Command_Id_Not_Persisted_Command_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Guardrail_Audit (S).Persistence_Clean,
              "public build ids and guardrail data must not persist");
      Assert_Public_Build_Hard_Freeze_Not_Persisted (S);
   end Test_Public_Build_Surface_Command_Id_Not_Persisted_Command_Name;

   procedure Test_Public_Build_Internal_Test_Seam_Not_Counted_As_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Guardrail_Audit (S);
      Assert (R.No_Public_Command,
              "internal build test seam must be excluded from public build command counts");
      Assert (not Is_Public_Build_Surface_Id
                (Editor.Commands.Stable_Command_Name
                   (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam)),
              "internal test-seam id must not match the public build id list");
   end Test_Public_Build_Internal_Test_Seam_Not_Counted_As_Public_Command;

   procedure Test_Public_Build_Internal_Test_Seam_Still_Hidden_From_Normal_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Assert (D.Visibility = Editor.Commands.Hidden_Command,
              "internal build test seam must remain hidden from normal palette");
      Assert (not D.Bindable,
              "internal build test seam must not gain a default public keybinding target");
   end Test_Public_Build_Internal_Test_Seam_Still_Hidden_From_Normal_Palette;

   procedure Test_Public_Build_Guardrail_State_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Guardrail_State_Not_Persisted (S);
   end Test_Public_Build_Guardrail_State_Not_Persisted;

   procedure Test_Public_Build_Internal_Test_Seam_Public_Leak_Reported_Separately
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Detail : constant Public_Build_Guardrail_Failure_Detail :=
        Build_Public_Build_Internal_Test_Seam_Exposure_Detail
          (Palette_Row => "build.run-user-opt-in-test-seam");
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids
          (Palette_Row => "build.run-user-opt-in-test-seam");
   begin
      Assert (Detail.Kind = Public_Build_Failure_Internal_Test_Seam_Exposure,
              "internal test-seam leakage must be classified separately");
      Assert (Scan.Passed,
              "internal test-seam id must not be treated as public id exposure");
   end Test_Public_Build_Internal_Test_Seam_Public_Leak_Reported_Separately;

   procedure Test_Public_Build_Guardrail_Feedback_Helpers_Are_Not_Duplicated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build guardrail healthy",
              "health remains the only health feedback helper");
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build regression manifest healthy",
              "manifest remains the only manifest-level feedback helper");
   end Test_Public_Build_Guardrail_Feedback_Helpers_Are_Not_Duplicated;

   procedure Test_Public_Build_Guardrail_Evidence_Pack_Production_API_Absent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;
   end Test_Public_Build_Guardrail_Evidence_Pack_Production_API_Absent;

   procedure Test_Public_Build_Guardrail_Release_Candidate_Production_API_Absent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;
   end Test_Public_Build_Guardrail_Release_Candidate_Production_API_Absent;

   overriding procedure Register_Tests
     (T : in out Public_Build_Guardrail_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Not_Ready_Feedback_Is_Deterministic'Access,
         "Public Build Command Not Ready Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Repeated_Audits_Are_Stable'Access,
         "Public Build Repeated Audits Are Stable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Blocker_Summary_Is_Deterministic_For_Current_State'Access,
         "Public Build Blocker Summary Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Default_State_Passed'Access,
         "Public Build Guardrail Audit Default State Passed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Is_Side_Effect_Free'Access,
         "Public Build Guardrail Audit Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Command_Id_List_Is_Centralized'Access,
         "Public Build Public Command Id List Is Centralized");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Command_Id_Not_Palette_Row'Access,
         "Public Build Public Command Id Not Palette Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Command_Id_Not_Persisted_Command_Name'Access,
         "Public Build Public Command Id Not Persisted Command Name");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Internal_Test_Seam_Not_Counted_As_Public_Command'Access,
         "Public Build Internal Test Seam Not Counted As Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Internal_Test_Seam_Still_Hidden_From_Normal_Palette'Access,
         "Public Build Internal Test Seam Still Hidden From Normal Palette");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_State_Not_Persisted'Access,
         "Public Build Guardrail State Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Internal_Test_Seam_Public_Leak_Reported_Separately'Access,
         "Public Build Internal Test Seam Public Leak Reported Separately");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Feedback_Helpers_Are_Not_Duplicated'Access,
         "Public Build Guardrail Feedback Helpers Are Not Duplicated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Evidence_Pack_Production_API_Absent'Access,
         "Public Build Guardrail Evidence Pack Production API Absent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Release_Candidate_Production_API_Absent'Access,
         "Public Build Guardrail Release Candidate Production API Absent");
   end Register_Tests;

end Editor.Command_Surface.Public_Build_Guardrail_Tests;
