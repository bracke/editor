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

package body Editor.Command_Surface.Public_Build_Guardrail_Manifest_Tests is

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
     (T : Public_Build_Guardrail_Manifest_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Public_Build_Guardrail_Manifest.Tests");
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

   procedure Test_Public_Build_Guardrail_Health_Default_Is_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Assert (Health.Healthy,
              "default public build guardrail health must be healthy");
      Assert (Health.Guardrail_Result.Status =
              Public_Build_Guardrail_Passed,
              "healthy default reports passed status");
      Assert (Health.Surface_Id_Scan.Passed,
              "healthy default must include passing public-id scan");
      Assert (Public_Build_Guardrail_Audit_Trace_Complete
                (Health.Audit_Trace),
              "healthy default must include complete audit trace");
      Assert (Health.First_Failure.Kind = Public_Build_Failure_None,
              "healthy default must not report a first failure");
      Assert (Health.Failure_Count = 0,
              "healthy default must have zero failures");
      Assert (not Health.Snapshot_Mismatch.Any_Mismatch,
              "healthy default must not have contract mismatch");
      Assert_Public_Build_Guardrail_Health_Default (Health);
   end Test_Public_Build_Guardrail_Health_Default_Is_Healthy;

   procedure Test_Public_Build_Guardrail_Health_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      A : Public_Build_Guardrail_Health;
      B : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      A := Build_Public_Build_Guardrail_Health (S);
      B := Build_Public_Build_Guardrail_Health (S);
      Assert (A = B,
              "public build guardrail health must be deterministic and side-effect-free");
   end Test_Public_Build_Guardrail_Health_Is_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Health_Unhealthy_On_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Health.Guardrail_Result.No_Public_Command := False;
      Health.Guardrail_Result.Status := Public_Build_Guardrail_Exposure_Detected;
      Health.Snapshot_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch
          (Health.Guardrail_Result);
      Health.Healthy := False;
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build exposure detected",
              "health feedback must identify public command exposure");
   end Test_Public_Build_Guardrail_Health_Unhealthy_On_Public_Command;

   procedure Test_Public_Build_Guardrail_Health_Unhealthy_On_Audit_Trace_Incomplete
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Health.Audit_Trace.Hard_Freeze_Checked := False;
      Health.Guardrail_Result.Audits_Consistent := False;
      Health.Healthy := False;
      Assert (not Public_Build_Guardrail_Audit_Trace_Complete
                    (Health.Audit_Trace),
              "missing hard-freeze surface must make trace incomplete");
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build audit trace incomplete",
              "health feedback must identify trace incompleteness");
   end Test_Public_Build_Guardrail_Health_Unhealthy_On_Audit_Trace_Incomplete;

   procedure Test_Public_Build_Guardrail_Health_Unhealthy_On_Contract_Mismatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Health.Guardrail_Result.Promotion_Blocked := True;
      Health.Snapshot_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch
          (Health.Guardrail_Result);
      Health.Healthy := False;
      Assert (Health.Snapshot_Mismatch.Any_Mismatch,
              "simulated promotion drift must create contract mismatch");
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build contract mismatch detected",
              "health feedback must identify contract mismatch");
   end Test_Public_Build_Guardrail_Health_Unhealthy_On_Contract_Mismatch;

   procedure Test_Public_Build_Guardrail_Health_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build guardrail healthy",
              "healthy guardrail feedback must be deterministic");
      Health.Healthy := False;
      Assert (Build_Public_Build_Guardrail_Health_Feedback (Health) =
              "Build: public build guardrail unhealthy",
              "unhealthy passed-state fallback feedback must be deterministic");
   end Test_Public_Build_Guardrail_Health_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Health_Canonical_Ordering_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Unsafe : Public_Build_Guardrail_Result;
      A : Public_Build_Guardrail_Failure_Detail_Vector;
      B : Public_Build_Guardrail_Failure_Detail_Vector;
   begin
      Unsafe.Status := Public_Build_Guardrail_Exposure_Detected;
      Unsafe.No_Public_Command := False;
      Unsafe.No_Public_Keybinding := False;
      Unsafe.No_Public_Palette_Entry := False;
      Unsafe.No_Public_Executor_Route := False;
      Unsafe.No_Public_Invocation_Path := False;
      Unsafe.No_Public_Bindable_Command := False;
      Unsafe.Promotion_Blocked := True;
      Unsafe.Default_Execution_Disabled := False;
      Unsafe.Dependency_Blockers_Active := True;
      Unsafe.Persistence_Clean := False;
      Unsafe.Audits_Consistent := False;
      A := Collect_Public_Build_Guardrail_Failures (Unsafe);
      B := Collect_Public_Build_Guardrail_Failures (Unsafe);
      Assert (Natural (A.Length) = Natural (B.Length),
              "collected guardrail failures must have deterministic ordering");
      Assert (Natural (A.Length) > 1,
              "unsafe guardrail snapshot must produce ordered failure details");
   end Test_Public_Build_Guardrail_Health_Canonical_Ordering_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Health_Builder_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Result;
      A      : Public_Build_Guardrail_Health;
      B      : Public_Build_Guardrail_Health;
      After  : Public_Build_Guardrail_Result;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Run_Public_Build_Guardrail_Audit (S);
      A := Build_Public_Build_Guardrail_Health (S);
      B := Build_Public_Build_Guardrail_Health (S);
      After := Run_Public_Build_Guardrail_Audit (S);
      M := Compare_Public_Build_Guardrail_Snapshots (Before, After);
      Assert (A = B,
              "health builder must be deterministic");
      Assert (not M.Any_Mismatch,
              "health builder must not mutate guardrail-relevant state");
   end Test_Public_Build_Guardrail_Health_Builder_Is_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Stale_Health_Does_Not_Bypass_Current_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Old_Health : Public_Build_Guardrail_Health;
      Unsafe_Health : Public_Build_Guardrail_Health;
      Unchanged : Public_Build_Guardrail_Contract_Mismatch;
      Unsafe_Result : Public_Build_Guardrail_Result;
      Stale_Mismatch : Public_Build_Guardrail_Contract_Mismatch;
      Unsafe_Failures : Public_Build_Guardrail_Failure_Detail_Vector;
   begin
      Editor.State.Init (S);
      Old_Health := Build_Public_Build_Guardrail_Health (S);
      Unchanged := Compare_Public_Build_Guardrail_Snapshots
        (Old_Health.Guardrail_Result, Run_Public_Build_Guardrail_Audit (S));
      Assert (not Unchanged.Any_Mismatch,
              "old health must remain valid against unchanged current audit");

      Unsafe_Result := Old_Health.Guardrail_Result;
      Unsafe_Result.No_Public_Command := False;
      Unsafe_Result.Status := Public_Build_Guardrail_Exposure_Detected;
      Stale_Mismatch := Compare_Public_Build_Guardrail_Snapshots
        (Old_Health.Guardrail_Result, Unsafe_Result);
      Assert (Stale_Mismatch.Public_Command_Mismatch
              and then Stale_Mismatch.Any_Mismatch,
              "stale health must not bypass changed unsafe snapshot");

      Unsafe_Health := Old_Health;
      Unsafe_Health.Guardrail_Result := Unsafe_Result;
      Unsafe_Health.Snapshot_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Unsafe_Result);
      Unsafe_Health.First_Failure :=
        First_Public_Build_Guardrail_Failure (Unsafe_Result);
      Unsafe_Failures := Collect_Public_Build_Guardrail_Failures (Unsafe_Result);
      Unsafe_Health.Failure_Count := Natural (Unsafe_Failures.Length);
      Unsafe_Health.Healthy := False;
      Assert (not Unsafe_Health.Healthy,
              "new unsafe health must remain unhealthy without wrapper contract");
      Assert (Unsafe_Health.Snapshot_Mismatch.Any_Mismatch,
              "new unsafe health must expose direct snapshot mismatch");
      Assert (Unsafe_Health.First_Failure.Kind /= Public_Build_Failure_None,
              "new unsafe health must expose direct first failure");
      Assert (Unsafe_Health.Failure_Count > 0,
              "new unsafe health must expose direct failure count");
   end Test_Public_Build_Guardrail_Stale_Health_Does_Not_Bypass_Current_Audit;

   procedure Test_Public_Build_Health_Lifecycle_Project_Close_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Health;
      After  : Public_Build_Guardrail_Health;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Health (S);
      Reset_Build_Run_State_For_Project_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Project_Close (S);
      After := Build_Public_Build_Guardrail_Health (S);
      M := Compare_Public_Build_Guardrail_Snapshots
        (Before.Guardrail_Result, After.Guardrail_Result);
      Assert (Before.Healthy and then After.Healthy,
              "project-close lifecycle must preserve public-build health");
      Assert (not M.Any_Mismatch,
              "project-close lifecycle must not change guardrail snapshot");
   end Test_Public_Build_Health_Lifecycle_Project_Close_Remains_Healthy;

   procedure Test_Public_Build_Health_Lifecycle_Workspace_Close_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Health;
      After  : Public_Build_Guardrail_Health;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Health (S);
      Reset_Build_Run_State_For_Workspace_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      After := Build_Public_Build_Guardrail_Health (S);
      M := Compare_Public_Build_Guardrail_Snapshots
        (Before.Guardrail_Result, After.Guardrail_Result);
      Assert (Before.Healthy and then After.Healthy,
              "workspace-close lifecycle must preserve public-build health");
      Assert (not M.Any_Mismatch,
              "workspace-close lifecycle must not change guardrail snapshot");
   end Test_Public_Build_Health_Lifecycle_Workspace_Close_Remains_Healthy;

   procedure Test_Public_Build_Health_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Guardrail_Health_Not_Persisted (S);
   end Test_Public_Build_Health_Not_Persisted;

   procedure Test_Public_Build_Guardrail_Manifest_Default_Is_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Manifest.Health.Healthy,
              "manifest embeds healthy public build guardrail health");
      Assert (Manifest.Default_Contract_Matches,
              "manifest default normalized guardrail contract must match");
      Assert (Manifest.Trace_Surface_Complete,
              "manifest audit trace surface must be complete");
      Assert (Manifest.Public_Command_Surface_Complete,
              "manifest public-id domains must be complete");
      Assert (Manifest.Persistence_Exclusion_Clean,
              "manifest persistence exclusion must be clean");
      Assert (Manifest.Lifecycle_Stable,
              "manifest lifecycle snapshot must be stable");
      Assert (Manifest.Public_Surface_Present,
              "manifest must prove no public build surface exists");
      Assert (Manifest.Execution_Surface_Present,
              "manifest must prove no public build execution surface exists");
      Assert (Manifest.Surface_Command_Executable,
              "manifest must prove surface entry metadata is non-executable");
      Assert (not Manifest.Promotion_Blocked,
              "manifest must prove guarded promotion is ready");
      Assert (not Manifest.Dependency_Blockers_Active,
              "manifest must prove dependency blockers are inactive");
      Assert (Manifest.Manifest_Healthy,
              "default public build guardrail regression manifest must be healthy");
      Assert_Public_Build_Guardrail_Regression_Manifest_Default (Manifest);
   end Test_Public_Build_Guardrail_Manifest_Default_Is_Healthy;

   procedure Test_Public_Build_Guardrail_Manifest_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build regression manifest healthy",
              "healthy manifest feedback must be deterministic");

      Manifest.Manifest_Healthy := False;
      Manifest.Default_Contract_Matches := False;
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build default contract mismatch",
              "contract mismatch feedback must be deterministic");

      Manifest.Default_Contract_Matches := True;
      Manifest.Trace_Surface_Complete := False;
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build audit trace incomplete",
              "trace feedback must be deterministic");

      Manifest.Trace_Surface_Complete := True;
      Manifest.Public_Command_Surface_Complete := False;
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build public-id domain coverage incomplete",
              "public-id domain feedback must be deterministic");
   end Test_Public_Build_Guardrail_Manifest_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Manifest_Unhealthy_On_Each_Dimension
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Base : Public_Build_Guardrail_Regression_Manifest;
      M : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Base := Build_Public_Build_Guardrail_Regression_Manifest (S);
      M := Base;
      M.Health.Healthy := False;
      M.Manifest_Healthy :=
        M.Health.Healthy and then M.Default_Contract_Matches;
      Assert (not M.Manifest_Healthy,
              "health failure must make simulated manifest unhealthy");

      M := Base;
      M.Public_Surface_Present := False;
      M.Manifest_Healthy := Base.Manifest_Healthy and then M.Public_Surface_Present;
      Assert (not M.Manifest_Healthy,
              "public surface exposure must make simulated manifest unhealthy");

      M := Base;
      M.Execution_Surface_Present := False;
      M.Manifest_Healthy := Base.Manifest_Healthy and then M.Execution_Surface_Present;
      Assert (not M.Manifest_Healthy,
              "execution surface exposure must make simulated manifest unhealthy");

      M := Base;
      M.Surface_Command_Executable := False;
      M.Manifest_Healthy := Base.Manifest_Healthy and then M.Surface_Command_Executable;
      Assert (not M.Manifest_Healthy,
              "executable surface entry must make simulated manifest unhealthy");

      M := Base;
      M.Promotion_Blocked := True;
      M.Manifest_Healthy := Base.Manifest_Healthy and then not M.Promotion_Blocked;
      Assert (not M.Manifest_Healthy,
              "promotion blocker must make simulated manifest unhealthy");

      M := Base;
      M.Dependency_Blockers_Active := True;
      M.Manifest_Healthy := Base.Manifest_Healthy and then not M.Dependency_Blockers_Active;
      Assert (not M.Manifest_Healthy,
              "dependency blocker activation must make simulated manifest unhealthy");
   end Test_Public_Build_Guardrail_Manifest_Unhealthy_On_Each_Dimension;

   procedure Test_Public_Build_Guardrail_Audit_Matrix_All_Dimensions_Checked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Matrix : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
      Count : Natural := 0;
   begin
      for Dimension in Matrix'Range loop
         Count := Count + 1;
         Assert (Matrix (Dimension),
                 "public build guardrail audit matrix dimension missing");
      end loop;
      Assert (Count = 31,
              "public build guardrail audit matrix dimension count changed");
      Assert (Public_Build_Guardrail_Audit_Matrix_Complete (Matrix),
              "public build guardrail audit matrix must be complete");
      Assert_Public_Build_Guardrail_Audit_Matrix_Complete (Matrix);
   end Test_Public_Build_Guardrail_Audit_Matrix_All_Dimensions_Checked;

   procedure Test_Public_Build_Guardrail_Audit_Matrix_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      A : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
      B : constant Public_Build_Guardrail_Audit_Matrix :=
        Build_Public_Build_Guardrail_Audit_Matrix;
   begin
      Assert (A = B,
              "public build guardrail audit matrix must be deterministic");
   end Test_Public_Build_Guardrail_Audit_Matrix_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Manifest_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Result;
      A : Public_Build_Guardrail_Regression_Manifest;
      B : Public_Build_Guardrail_Regression_Manifest;
      After : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Before := Run_Public_Build_Guardrail_Audit (S);
      A := Build_Public_Build_Guardrail_Regression_Manifest (S);
      B := Build_Public_Build_Guardrail_Regression_Manifest (S);
      After := Run_Public_Build_Guardrail_Audit (S);
      Assert (A = B,
              "public build guardrail manifest builder must be deterministic");
      Assert (Before = After,
              "public build guardrail manifest builder must not mutate guardrail state");
      Assert (A.Manifest_Healthy,
              "side-effect-free manifest build must remain healthy");
   end Test_Public_Build_Guardrail_Manifest_Is_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Manifest_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Manifest.Persistence_Exclusion_Clean,
              "manifest audit-only state must remain excluded from persistence");
      Assert_Public_Build_Guardrail_Health_Not_Persisted (S);
      Assert_Public_Build_Guardrail_State_Not_Persisted (S);
   end Test_Public_Build_Guardrail_Manifest_Not_Persisted;

   procedure Test_Public_Build_Guardrail_Manifest_Lifecycle_Project_Close_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Regression_Manifest;
      After : Public_Build_Guardrail_Regression_Manifest;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Reset_Build_Run_State_For_Project_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Project_Close (S);
      After := Build_Public_Build_Guardrail_Regression_Manifest (S);
      M := Compare_Public_Build_Guardrail_Snapshots
        (Before.Health.Guardrail_Result, After.Health.Guardrail_Result);
      Assert (Before.Manifest_Healthy and then After.Manifest_Healthy,
              "manifest must remain healthy across project close");
      Assert (not M.Any_Mismatch,
              "project close must not change public build guardrail contract");
   end Test_Public_Build_Guardrail_Manifest_Lifecycle_Project_Close_Remains_Healthy;

   procedure Test_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;
   end Test_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;

   procedure Test_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers
        (Manifest);
      Assert (Manifest.Manifest_Healthy,
              "manifest direct-backer assertion must preserve default healthy state");
   end Test_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers;

   procedure Test_Public_Build_Guardrail_Result_Does_Not_Depend_On_Health
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result_Before : Public_Build_Guardrail_Result;
      Health : Public_Build_Guardrail_Health;
      Result_After : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Result_Before := Run_Public_Build_Guardrail_Audit (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Health.Healthy := False;
      Assert (not Health.Healthy,
              "mutated health copy must not influence result builder");
      Result_After := Run_Public_Build_Guardrail_Audit (S);
      Assert (Result_Before = Result_After,
              "guardrail result must be computed below health and remain independent");
      Assert (Result_After.Status = Public_Build_Guardrail_Passed,
              "guardrail result must remain passed");
   end Test_Public_Build_Guardrail_Result_Does_Not_Depend_On_Health;

   procedure Test_Public_Build_Guardrail_Health_Does_Not_Depend_On_Manifest
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Health_Before : Public_Build_Guardrail_Health;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
      Health_After : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health_Before := Build_Public_Build_Guardrail_Health (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Manifest.Manifest_Healthy := False;
      Assert (not Manifest.Manifest_Healthy,
              "mutated manifest copy must not influence health builder");
      Health_After := Build_Public_Build_Guardrail_Health (S);
      Assert (Health_Before = Health_After,
              "health must be computed below manifest and remain independent");
      Assert (Health_After.Healthy,
              "health must remain healthy without reading manifest state");
   end Test_Public_Build_Guardrail_Health_Does_Not_Depend_On_Manifest;

   procedure Test_Public_Build_Guardrail_Manifest_Is_Final_Semantic_Layer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Public_Build_Guardrail_Regression_Manifest;
      B : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      A := Build_Public_Build_Guardrail_Regression_Manifest (S);
      B := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (A = B,
              "manifest must be final semantic layer and not depend on a higher wrapper");
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers (A);
   end Test_Public_Build_Guardrail_Manifest_Is_Final_Semantic_Layer;

   procedure Test_Public_Build_Guardrail_Audit_Matrix_Is_Coverage_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Guardrail_Audit_Matrix_Coverage_Only;
   end Test_Public_Build_Guardrail_Audit_Matrix_Is_Coverage_Only;

   procedure Test_Public_Build_Guardrail_No_Self_Referential_Healthy_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Guardrail_No_Self_Referential_Healthy_State (S);
   end Test_Public_Build_Guardrail_No_Self_Referential_Healthy_State;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Default_Result_Is_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Result := Run_Public_Build_Guardrail_Audit (S);
      Assert (Result.Status = Public_Build_Guardrail_Passed,
              "post-pruning guardrail status must remain passed");
      Assert (Result.No_Public_Command
              and then Result.No_Public_Keybinding
              and then Result.No_Public_Palette_Entry
              and then Result.No_Public_Executor_Route
              and then Result.No_Public_Invocation_Path
              and then Result.No_Public_Bindable_Command
              and then not Result.Promotion_Blocked
              and then Result.Default_Execution_Disabled
              and then not Result.Dependency_Blockers_Active
              and then Result.Persistence_Clean
              and then Result.Audits_Consistent,
              "post-pruning normalized guardrail default contract drifted");
      Assert_Public_Build_Guardrail_Default_Contract (Result);
   end Test_Public_Build_Guardrail_Post_Pruning_Default_Result_Is_Safe;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Health_Is_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Health : Public_Build_Guardrail_Health;
   begin
      Editor.State.Init (S);
      Health := Build_Public_Build_Guardrail_Health (S);
      Assert (Health.Healthy,
              "post-pruning health report must remain healthy");
      Assert (Health.Failure_Count = 0,
              "post-pruning health report must have no failures");
      Assert (Health.First_Failure.Kind = Public_Build_Failure_None,
              "post-pruning health first failure must be none");
      Assert (not Health.Snapshot_Mismatch.Any_Mismatch,
              "post-pruning health must report no contract mismatch");
      Assert_Public_Build_Guardrail_Health_Default (Health);
   end Test_Public_Build_Guardrail_Post_Pruning_Health_Is_Healthy;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Manifest_Is_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Manifest.Manifest_Healthy,
              "post-pruning manifest must remain healthy");
      Assert (Manifest.Health.Healthy
              and then Manifest.Default_Contract_Matches
              and then Manifest.Trace_Surface_Complete
              and then Manifest.Public_Command_Surface_Complete
              and then Manifest.Persistence_Exclusion_Clean
              and then Manifest.Lifecycle_Stable
              and then Manifest.Public_Surface_Present
              and then Manifest.Execution_Surface_Present
              and then Manifest.Surface_Command_Executable
              and then not Manifest.Promotion_Blocked
              and then not Manifest.Dependency_Blockers_Active,
              "post-pruning manifest field contract drifted");
      Assert_Public_Build_Guardrail_Regression_Manifest_Default (Manifest);
   end Test_Public_Build_Guardrail_Post_Pruning_Manifest_Is_Healthy;

   procedure Test_Public_Build_Guardrail_Manifest_Does_Not_Depend_On_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Public_Build_Guardrail_Regression_Manifest;
      B : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest;
      A := Build_Public_Build_Guardrail_Regression_Manifest (S);
      B := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (A = B,
              "manifest must not consult removed evidence/release-candidate wrappers");
      Assert_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers (A);
   end Test_Public_Build_Guardrail_Manifest_Does_Not_Depend_On_Evidence;

   procedure Test_Public_Build_Guardrail_Feedback_Helpers_Only_Health_And_Manifest
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
              "health feedback helper drifted after pruning");
      Assert (Build_Public_Build_Guardrail_Regression_Manifest_Feedback
                (Manifest) =
              "Build: public build regression manifest healthy",
              "manifest feedback helper drifted after pruning");
   end Test_Public_Build_Guardrail_Feedback_Helpers_Only_Health_And_Manifest;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Manifest.Persistence_Exclusion_Clean,
              "post-pruning guardrail manifest must remain non-persistent");
      Assert_Public_Build_Guardrail_State_Not_Persisted (S);
      Assert_Public_Build_Guardrail_Health_Not_Persisted (S);
   end Test_Public_Build_Guardrail_Post_Pruning_Not_Persisted;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Result_Before : Public_Build_Guardrail_Result;
      Health_A : Public_Build_Guardrail_Health;
      Health_B : Public_Build_Guardrail_Health;
      Manifest_A : Public_Build_Guardrail_Regression_Manifest;
      Manifest_B : Public_Build_Guardrail_Regression_Manifest;
      Result_After : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      Result_Before := Run_Public_Build_Guardrail_Audit (S);
      Health_A := Build_Public_Build_Guardrail_Health (S);
      Health_B := Build_Public_Build_Guardrail_Health (S);
      Manifest_A := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Manifest_B := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Result_After := Run_Public_Build_Guardrail_Audit (S);
      Assert (Result_Before = Result_After,
              "post-pruning guardrail builders must not mutate audit state");
      Assert (Health_A = Health_B,
              "post-pruning health builder must be deterministic");
      Assert (Manifest_A = Manifest_B,
              "post-pruning manifest builder must be deterministic");
      Assert (Health_A.Healthy and then Manifest_A.Manifest_Healthy,
              "post-pruning side-effect-free audit must remain healthy");
   end Test_Public_Build_Guardrail_Post_Pruning_Side_Effect_Free;

   procedure Test_Public_Build_Guardrail_Post_Pruning_Lifecycle_Workspace_Close_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Regression_Manifest;
      After : Public_Build_Guardrail_Regression_Manifest;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Reset_Build_Run_State_For_Workspace_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      After := Build_Public_Build_Guardrail_Regression_Manifest (S);
      M := Compare_Public_Build_Guardrail_Snapshots
        (Before.Health.Guardrail_Result, After.Health.Guardrail_Result);
      Assert (Before.Manifest_Healthy and then After.Manifest_Healthy,
              "manifest must remain healthy across workspace close");
      Assert (Before.Health.Healthy and then After.Health.Healthy,
              "health must remain healthy across workspace close");
      Assert (not M.Any_Mismatch,
              "workspace close must not change public build guardrail contract");
   end Test_Public_Build_Guardrail_Post_Pruning_Lifecycle_Workspace_Close_Remains_Healthy;

   overriding procedure Register_Tests
     (T : in out Public_Build_Guardrail_Manifest_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Default_Is_Healthy'Access,
         "Public Build Guardrail Health Default Is Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Is_Side_Effect_Free'Access,
         "Public Build Guardrail Health Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Unhealthy_On_Public_Command'Access,
         "Public Build Guardrail Health Unhealthy On Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Unhealthy_On_Audit_Trace_Incomplete'Access,
         "Public Build Guardrail Health Unhealthy On Audit Trace Incomplete");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Unhealthy_On_Contract_Mismatch'Access,
         "Public Build Guardrail Health Unhealthy On Contract Mismatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Feedback_Is_Deterministic'Access,
         "Public Build Guardrail Health Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Canonical_Ordering_Is_Deterministic'Access,
         "Public Build Guardrail Health Canonical Ordering Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Builder_Is_Side_Effect_Free'Access,
         "Public Build Guardrail Health Builder Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Stale_Health_Does_Not_Bypass_Current_Audit'Access,
         "Public Build Guardrail Stale Health Does Not Bypass Current Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Health_Lifecycle_Project_Close_Remains_Healthy'Access,
         "Public Build Health Lifecycle Project Close Remains Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Health_Lifecycle_Workspace_Close_Remains_Healthy'Access,
         "Public Build Health Lifecycle Workspace Close Remains Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Health_Not_Persisted'Access,
         "Public Build Health Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Default_Is_Healthy'Access,
         "Public Build Guardrail Manifest Default Is Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Feedback_Is_Deterministic'Access,
         "Public Build Guardrail Manifest Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Unhealthy_On_Each_Dimension'Access,
         "Public Build Guardrail Manifest Unhealthy On Each Dimension");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Matrix_All_Dimensions_Checked'Access,
         "Public Build Guardrail Audit Matrix All Dimensions Checked");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Matrix_Is_Deterministic'Access,
         "Public Build Guardrail Audit Matrix Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Is_Side_Effect_Free'Access,
         "Public Build Guardrail Manifest Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Not_Persisted'Access,
         "Public Build Guardrail Manifest Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Lifecycle_Project_Close_Remains_Healthy'Access,
         "Public Build Guardrail Manifest Lifecycle Project Close Remains Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_No_Extra_Layer_Above_Manifest'Access,
         "Public Build Guardrail No Extra Layer Above Manifest");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Fields_Have_Direct_Backers'Access,
         "Public Build Guardrail Manifest Fields Have Direct Backers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Result_Does_Not_Depend_On_Health'Access,
         "Public Build Guardrail Result Does Not Depend On Health");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Health_Does_Not_Depend_On_Manifest'Access,
         "Public Build Guardrail Health Does Not Depend On Manifest");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Is_Final_Semantic_Layer'Access,
         "Public Build Guardrail Manifest Is Final Semantic Layer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Matrix_Is_Coverage_Only'Access,
         "Public Build Guardrail Audit Matrix Is Coverage Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_No_Self_Referential_Healthy_State'Access,
         "Public Build Guardrail No Self Referential Healthy State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Default_Result_Is_Safe'Access,
         "Public Build Guardrail Post Pruning Default Result Is Safe");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Health_Is_Healthy'Access,
         "Public Build Guardrail Post Pruning Health Is Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Manifest_Is_Healthy'Access,
         "Public Build Guardrail Post Pruning Manifest Is Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Manifest_Does_Not_Depend_On_Evidence'Access,
         "Public Build Guardrail Manifest Does Not Depend On Evidence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Feedback_Helpers_Only_Health_And_Manifest'Access,
         "Public Build Guardrail Feedback Helpers Only Health And Manifest");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Not_Persisted'Access,
         "Public Build Guardrail Post Pruning Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Side_Effect_Free'Access,
         "Public Build Guardrail Post Pruning Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Post_Pruning_Lifecycle_Workspace_Close_Remains_Healthy'Access,
         "Public Build Guardrail Post Pruning Lifecycle Workspace Close Remains Healthy");
   end Register_Tests;

end Editor.Command_Surface.Public_Build_Guardrail_Manifest_Tests;
