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

package body Editor.Command_Surface.Product_Surface_Tests is

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
     (T : Product_Surface_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Product_Surface.Tests");
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

   procedure Test_Configuration_Command_Domain_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Settings_Path : constant String := "/tmp/editor-tests/command-surface-settings.tmp";
      Keybindings_Path : constant String := "/tmp/editor-tests/command-surface-keybindings.tmp";

      procedure Check (Id : Editor.Commands.Command_Id; Label : String) is
         S              : Editor.State.State_Type;
         Before_Project : Boolean;
         Before_Dirty   : Boolean;
         Before_Pending : Boolean;
         R              : Editor.Executor.Command_Execution_Result;
      begin
         Editor.State.Init (S);
         Before_Project := Editor.Project.Has_Project (S.Project);
         Before_Dirty := S.File_Info.Dirty;
         Before_Pending := Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions);

         R := Editor.Executor.Execute_Command_With_Result (S, Id);
         Assert (R.Status /= Editor.Executor.Command_Unavailable,
                 Label & " must be executable in the empty global fixture");
         Assert (Editor.Project.Has_Project (S.Project) = Before_Project,
                 Label & " must not mutate project root state");
         Assert (S.File_Info.Dirty = Before_Dirty,
                 Label & " must not mutate file dirty state");
         Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) = Before_Pending,
                 Label & " must not create or clear pending transitions");
      end Check;
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      Ada.Environment_Variables.Set
        ("EDITOR_SETTINGS_PATH", Settings_Path);
      Ada.Environment_Variables.Set
        ("EDITOR_KEYBINDINGS_PATH", Keybindings_Path);

      Check (Editor.Commands.Command_Save_Settings, "Save Settings");
      Check (Editor.Commands.Command_Reload_Settings, "Reload Settings");
      Check (Editor.Commands.Command_Save_Keybindings, "Save Keybindings");
      Check (Editor.Commands.Command_Reload_Keybindings, "Reload Keybindings");
      Check (Editor.Commands.Command_Validate_Keybindings, "Validate Keybindings");
   end Test_Configuration_Command_Domain_Isolation;

   procedure Test_Switcher_Command_Reference_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Line : Unbounded_String;
      In_Table : Boolean := False;
      Documented_Count : Natural := 0;
      Expected_Count : Natural := 0;
      Seen : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Found : Boolean;
      Id : Editor.Commands.Command_Id;
   begin
      declare
         Text : constant String := Reference_Text;
         Pos  : Positive := Text'First;
         Next : Natural;
      begin
         while Pos <= Text'Last loop
            Next := Pos;
            while Next <= Text'Last and then Text (Next) /= ASCII.LF loop
               Next := Next + 1;
            end loop;

            if Next > Text'Last then
               Line := To_Unbounded_String (Text (Pos .. Text'Last));
               Pos := Text'Last + 1;
            elsif Next = Pos then
               Line := Null_Unbounded_String;
               Pos := Next + 1;
            else
               Line := To_Unbounded_String (Text (Pos .. Next - 1));
               Pos := Next + 1;
            end if;
         if To_String (Line) = "<!-- switcher-command-table:start -->" then
            In_Table := True;
         elsif To_String (Line) = "<!-- switcher-command-table:end -->" then
            In_Table := False;
         elsif In_Table
           and then (Starts_With (To_String (Line), "| buffers.")
                     or else Starts_With (To_String (Line), "| file.close-"))
         then
            Assert_Row_Matches_Descriptor (To_String (Line));
            Id := Editor.Commands.Command_Id_From_Stable_Name (Cell (To_String (Line), 1), Found);
            Assert (Found and then not Seen (Id),
                    "documented switcher command names must be unique");
            Seen (Id) := True;
            Documented_Count := Documented_Count + 1;
         end if;
         end loop;
      end;

      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         if Switcher_Command_Is_In_Reference (Id) then
            Expected_Count := Expected_Count + 1;
            Assert (Seen (Id),
                    "every switcher descriptor in the frozen baseline must be documented: " &
                    Editor.Commands.Stable_Command_Name (Id));
         end if;
      end loop;

      Assert (Documented_Count = Expected_Count,
              "command reference must neither omit nor invent switcher commands");
   end Test_Switcher_Command_Reference_Metadata;

   procedure Test_Switcher_Command_Reference_Content
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Text : constant String := Reference_Text;
   begin
      Assert (Ada.Strings.Fixed.Index (Text, "# Open Buffer Switcher Commands") > 0,
              "reference must contain canonical command-name heading");
      Assert (Ada.Strings.Fixed.Index (Text, "## Stable Name Rules") > 0,
              "reference must contain stable-name section");
      Assert (Ada.Strings.Fixed.Index (Text, "Only current Open Buffer Switcher command names are accepted.") > 0,
              "reference must state current-name acceptance baseline");
      Assert (Ada.Strings.Fixed.Index (Text, "## Route Classes") > 0,
              "reference must explain route classes");
      Assert (Ada.Strings.Fixed.Index (Text, "## Availability Owner Notes") > 0,
              "reference must document availability-owner rules");
      Assert (Ada.Strings.Fixed.Index (Text, "Availability checks may report unavailable state") > 0,
              "reference must state availability checks do not repair or mutate workflow state");
      Assert (Ada.Strings.Fixed.Index (Text, "## Persistence Boundaries") > 0,
              "reference must document persistence boundaries");
      Assert (Ada.Strings.Fixed.Index (Text, "## Contextual Hints") > 0,
              "reference must document contextual-hint policy");
      Assert (Ada.Strings.Fixed.Index (Text, "## Keybindings") > 0,
              "reference must document keybinding persistence policy");
      Assert (Ada.Strings.Fixed.Index (Text, "## Command Palette") > 0,
              "reference must document Command Palette behavior");
      Assert (Ada.Strings.Fixed.Index (Text, "## Read-Only Derivation Is Not a Command Surface") > 0,
              "reference must distinguish read-only derivation from commands");
      Assert (Ada.Strings.Fixed.Index (Text, "## Mutation Notes") > 0,
              "reference must document mutation boundaries");
      Assert (Ada.Strings.Fixed.Index (Text, "## Optional Absent Commands") > 0,
              "reference must contain optional absent-command section");
      Assert (Ada.Strings.Fixed.Index (Text, "No optional absent switcher commands are documented") > 0,
              "reference must make optional absent-command baseline explicit");
      Assert (Ada.Strings.Fixed.Index (Text, "## Accepted Command Names") > 0,
              "reference must contain accepted-command-name section");
      Assert (Ada.Strings.Fixed.Index (Text, "| batch-state snapshot") = 0
              and then Ada.Strings.Fixed.Index (Text, "| row marker derivation") = 0
              and then Ada.Strings.Fixed.Index (Text, "| contextual hint derivation") = 0
              and then Ada.Strings.Fixed.Index (Text, "| header/footer badge formatting") = 0
              and then Ada.Strings.Fixed.Index (Text, "| message formatting") = 0
              and then Ada.Strings.Fixed.Index (Text, "| render packet emission") = 0
              and then Ada.Strings.Fixed.Index (Text, "| availability checks") = 0,
              "display-only helpers must not be documented as command table rows");
   end Test_Switcher_Command_Reference_Content;

   procedure Test_Configuration_Command_Surface_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Review : Editor.Command_Surface.Command_Surface_Review;
   begin
      Editor.State.Init (S);
      Review := Editor.Command_Surface.Review_Command_Surface (S);

      Assert
        (Editor.Command_Surface.Assert_Configuration_Command_Surface_Coherent (S),
         "milestone helper must pass on a clean state");
      Assert
        (Review.Stable_Ids_Unique,
         "visible command ids must be stable canonical names");
      Assert
        (Review.Palette_Projection_Consistent,
         "palette projection must exclude internal/demo/public-build test-seam commands");
      Assert
        (Review.Discoverability_Metadata_Coherent,
         "discoverability metadata must be coherent in command-surface review");
      Assert
        (Review.Keybinding_Targets_Valid,
         "active keybindings must target bindable canonical commands only");
      Assert
        (Review.Availability_Reasons_Stable,
         "availability checks must be stable and side-effect-free");
      Assert
        (Editor.Command_Surface.Build_Command_Surface_Review_Feedback (Review) =
           "Commands: command surface healthy",
         "coherent command surface should have a user-readable healthy summary");
   end Test_Configuration_Command_Surface_Coherent;

   procedure Test_Switch_Project_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D      : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Switch_Project);
      Found  : Boolean := False;
      Id     : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Id_From_Stable_Name ("project.switch", Found);
      S      : Editor.State.State_Type;
      Avail  : constant Editor.Commands.Command_Availability :=
        Editor.Executor.Command_Availability
          (S, Editor.Commands.Command_Switch_Project);
   begin
      Assert (D.Id = Editor.Commands.Command_Switch_Project,
              "switch project descriptor must exist");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Switch_Project) = "project.switch",
              "switch project stable name must be canonical");
      Assert (Found and then Id = Editor.Commands.Command_Switch_Project,
              "switch project stable name must round-trip");
      Assert (Editor.Commands.Requires_Context
                (Editor.Commands.Command_Switch_Project),
              "switch project requires explicit input context");
      Assert (Editor.Commands.Is_Lifecycle_Command
                (Editor.Commands.Command_Switch_Project),
              "switch project is a lifecycle command");
      Assert (not Editor.Commands.Is_Destructive_Command
                (Editor.Commands.Command_Switch_Project),
              "switch project must not be classified as destructive by itself");
      Assert (not Editor.Commands.Is_Available (Avail),
              "switch project has no keybinding/palette path payload");
      Assert (Editor.Commands.Unavailable_Reason (Avail) = "No target project selected",
              "switch project unavailable reason must name missing target");
   end Test_Switch_Project_Command_Surface;

   procedure Test_IDE_Grade_Language_Command_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Expected_Command is record
         Name : Ada.Strings.Unbounded.Unbounded_String;
         Id   : Editor.Commands.Command_Id;
      end record;
      type Expected_Command_Array is array (Positive range <>) of Expected_Command;
      Expected : constant Expected_Command_Array :=
        ((To_Unbounded_String ("outline.refresh"),
          Editor.Commands.Command_Refresh_Outline),
         (To_Unbounded_String ("outline.clear"),
          Editor.Commands.Command_Clear_Outline),
         (To_Unbounded_String ("outline.show"),
          Editor.Commands.Command_Show_Outline),
         (To_Unbounded_String ("outline.focus"),
          Editor.Commands.Command_Focus_Outline),
         (To_Unbounded_String ("outline.open-selected"),
          Editor.Commands.Command_Open_Selected_Outline_Item),
         (To_Unbounded_String ("outline.refresh-project-index"),
          Editor.Commands.Command_Refresh_Outline_Project_Index),
         (To_Unbounded_String ("outline.goto-declaration"),
          Editor.Commands.Command_Goto_Declaration),
         (To_Unbounded_String ("outline.goto-body"),
         Editor.Commands.Command_Goto_Body),
         (To_Unbounded_String ("outline.goto-spec"),
          Editor.Commands.Command_Goto_Spec),
         (To_Unbounded_String ("semantic.find-references"),
          Editor.Commands.Command_Find_References),
         (To_Unbounded_String ("semantic.show-hover"),
         Editor.Commands.Command_Show_Hover),
         (To_Unbounded_String ("semantic.show-completions"),
         Editor.Commands.Command_Show_Completions),
         (To_Unbounded_String ("semantic.rename-symbol-preview"),
          Editor.Commands.Command_Rename_Symbol_Preview),
         (To_Unbounded_String ("semantic.rename-symbol-apply"),
          Editor.Commands.Command_Rename_Symbol_Apply),
         (To_Unbounded_String ("semantic.refresh-buffer"),
          Editor.Commands.Command_Semantic_Refresh_Buffer),
         (To_Unbounded_String ("semantic.refresh-project-index"),
          Editor.Commands.Command_Semantic_Refresh_Project_Index),
         (To_Unbounded_String ("language.index.clear"),
          Editor.Commands.Command_Language_Index_Clear),
         (To_Unbounded_String ("language.index.status"),
          Editor.Commands.Command_Language_Index_Status));
      Found : Boolean;
      Round : Editor.Commands.Command_Id;
      D     : Editor.Commands.Command_Descriptor;
   begin
      for E of Expected loop
         Round := Editor.Commands.Command_Id_From_Stable_Name
           (To_String (E.Name), Found);
         Assert (Found and then Round = E.Id,
                 "IDE-grade language command must resolve by canonical id: " &
                 To_String (E.Name));
         Assert (Editor.Commands.Stable_Command_Name (E.Id) = To_String (E.Name),
                 "IDE-grade language command must expose canonical stable id: " &
                 To_String (E.Name));
         D := Editor.Commands.Descriptor (E.Id);
         Assert (D.Visibility = Editor.Commands.Palette_Command,
                 "IDE-grade language command must be palette-visible: " &
                 To_String (E.Name));
         Assert (To_String (D.Name)'Length > 0
                   and then To_String (D.Description)'Length > 0,
                 "IDE-grade language command descriptor must be user-facing: " &
                 To_String (E.Name));
      end loop;

      Round := Editor.Commands.Command_Id_From_Stable_Name
        ("refactor.rename-symbol", Found);
      Assert (Found and then Round = Editor.Commands.Command_Rename_Symbol_Preview,
              "Refactor rename alias should resolve to semantic rename preview");
      Round := Editor.Commands.Command_Id_From_Stable_Name
        ("refactor.rename-symbol-preview", Found);
      Assert (Found and then Round = Editor.Commands.Command_Rename_Symbol_Preview,
              "Refactor rename preview alias should resolve to semantic rename preview");
      Round := Editor.Commands.Command_Id_From_Stable_Name
        ("refactor.rename-symbol-apply", Found);
      Assert (Found and then Round = Editor.Commands.Command_Rename_Symbol_Apply,
              "Refactor rename apply alias should resolve to semantic rename apply");

      declare
         Hidden_Expected : constant Expected_Command_Array :=
           ((To_Unbounded_String ("semantic.completion.select-next"),
             Editor.Commands.Command_Semantic_Completion_Select_Next),
            (To_Unbounded_String ("semantic.completion.select-previous"),
             Editor.Commands.Command_Semantic_Completion_Select_Previous),
            (To_Unbounded_String ("semantic.completion.accept"),
             Editor.Commands.Command_Semantic_Completion_Accept),
            (To_Unbounded_String ("semantic.popup.dismiss"),
             Editor.Commands.Command_Semantic_Popup_Dismiss));
      begin
         for E of Hidden_Expected loop
            Round := Editor.Commands.Command_Id_From_Stable_Name
              (To_String (E.Name), Found);
            Assert (Found and then Round = E.Id,
                    "IDE-grade popup command must resolve by canonical id: " &
                    To_String (E.Name));
            Assert (Editor.Commands.Stable_Command_Name (E.Id) = To_String (E.Name),
                    "IDE-grade popup command must expose canonical stable id: " &
                    To_String (E.Name));
            D := Editor.Commands.Descriptor (E.Id);
            Assert (D.Visibility = Editor.Commands.Hidden_Command,
                    "IDE-grade popup command must stay hidden: " &
                    To_String (E.Name));
            Assert (To_String (D.Name)'Length > 0
                      and then To_String (D.Description)'Length > 0,
                    "IDE-grade popup command descriptor must be user-facing: " &
                    To_String (E.Name));
         end loop;
      end;

      --  descriptor-specific project-refresh checks must live
      --  outside the expected-command enumeration loop.

      D := Editor.Commands.Descriptor
        (Editor.Commands.Command_Refresh_Outline_Project_Index);
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (D.Description), "known project Ada source files") > 0,
         "outline project-index refresh must describe project-file indexing");

      D := Editor.Commands.Descriptor
        (Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (D.Description), "known project Ada files") > 0
           or else Ada.Strings.Fixed.Index
             (To_String (D.Description), "known project Ada source files") > 0,
         "semantic project-index refresh must describe project-file indexing");

      --  body/spec navigation must be a real indexed target
      --  command surface, not a permanently reserved unavailable placeholder.
      D := Editor.Commands.Descriptor (Editor.Commands.Command_Goto_Body);
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (D.Description), "body target") > 0
         and then Ada.Strings.Fixed.Index
           (Ada.Characters.Handling.To_Lower (To_String (D.Description)),
            "reserved") = 0,
         "outline.goto-body must describe real indexed body navigation");

      D := Editor.Commands.Descriptor (Editor.Commands.Command_Goto_Spec);
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (D.Description), "spec target") > 0
         and then Ada.Strings.Fixed.Index
           (Ada.Characters.Handling.To_Lower (To_String (D.Description)),
            "reserved") = 0,
         "outline.goto-spec must describe real indexed spec navigation");

      Round := Editor.Commands.Command_Id_From_Stable_Name ("refresh-outline", Found);
      Assert (not Found, "legacy refresh-outline spelling must not resolve");
      Round := Editor.Commands.Command_Id_From_Stable_Name ("clear-outline", Found);
      Assert (not Found, "legacy clear-outline spelling must not resolve");
      Round := Editor.Commands.Command_Id_From_Stable_Name ("show-outline", Found);
      Assert (not Found, "legacy show-outline spelling must not resolve");
      Round := Editor.Commands.Command_Id_From_Stable_Name ("focus-outline", Found);
      Assert (not Found, "legacy focus-outline spelling must not resolve");
      Round := Editor.Commands.Command_Id_From_Stable_Name ("open-selected-outline-item", Found);
      Assert (not Found, "legacy open-selected-outline-item spelling must not resolve");
   end Test_IDE_Grade_Language_Command_Surface;

   procedure Test_File_Command_Reference_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      File_Commands : constant Command_Array :=
        (Editor.Commands.Command_Save_File,
         Editor.Commands.Command_Save_File_As,
         Editor.Commands.Command_Close_Active_Buffer,
         Editor.Commands.Command_Reopen_Closed_Buffer,
         Editor.Commands.Command_Reload_Active_Buffer,
         Editor.Commands.Command_Revert_Active_Buffer,
         Editor.Commands.Command_Rename_Buffer_File,
         Editor.Commands.Command_Delete_Buffer_File,
         Editor.Commands.Command_Copy_Buffer_File,
         Editor.Commands.Command_Move_Buffer_File);
      Prompt_Commands : constant Command_Array :=
        (Editor.Commands.Command_Confirm_Close_Save,
         Editor.Commands.Command_Confirm_Close_Discard,
         Editor.Commands.Command_Cancel_Close,
         Editor.Commands.Command_File_Conflict_Keep_Buffer,
         Editor.Commands.Command_File_Conflict_Reload_From_Disk,
         Editor.Commands.Command_File_Conflict_Overwrite_Disk,
         Editor.Commands.Command_File_Conflict_Cancel);

      function Contains_Internal_Term (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
      begin
         return Ada.Strings.Fixed.Index (Lower, "metadata") > 0
           or else Ada.Strings.Fixed.Index (Lower, "projection") > 0
           or else Ada.Strings.Fixed.Index (Lower, "payload") > 0
           or else Ada.Strings.Fixed.Index (Lower, "lifecycle") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route") > 0
           or else Ada.Strings.Fixed.Index (Lower, "producer") > 0
           or else Ada.Strings.Fixed.Index (Lower, "fixture") > 0
           or else Ada.Strings.Fixed.Index (Lower, "scaffold") > 0
           or else Ada.Strings.Fixed.Index (Lower, "surface entry") > 0
           or else Ada.Strings.Fixed.Index (Lower, "synthetic") > 0;
      end Contains_Internal_Term;

      Text : Unbounded_String;
   begin
      Assert (Editor.Commands.Command_Family_Label
                (Editor.Commands.File_Lifecycle_Family) = "File Operations",
              "file command family label is product-facing");

      for Id of File_Commands loop
         Text := To_Unbounded_String
           (Editor.Commands.Reference_Summary (Id) & " " &
            Editor.Commands.Reference_Availability_Summary (Id) & " " &
            Editor.Commands.Reference_Mutation_Summary (Id) & " " &
            Editor.Commands.Reference_Filesystem_Effect_Summary (Id) & " " &
            Editor.Commands.Reference_State_Preservation_Summary (Id) & " " &
            Editor.Commands.Reference_Non_Goal_Summary (Id));

         Assert (Editor.Commands.Has_Command_Reference (Id),
                 "file command reference exists");
         Assert (Length (Text) > 0,
                 "file command reference text is present");
         Assert (not Contains_Internal_Term (To_String (Text)),
                 "file command reference avoids internal wording: " &
                 To_String (Text));
      end loop;

      for Id of Prompt_Commands loop
         Assert (not Editor.Commands.Has_Command_Reference (Id),
                 "prompt-only file command must not expand public reference surface");
      end loop;
   end Test_File_Command_Reference_Surface;

   procedure Test_Project_Search_Product_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Project_Search_Commands : constant Command_Array :=
        (Editor.Commands.Command_Run_Project_Search,
         Editor.Commands.Command_Rerun_Project_Search,
         Editor.Commands.Command_Open_Project_Search_Bar,
         Editor.Commands.Command_Toggle_Project_Search_Bar,
         Editor.Commands.Command_Close_Project_Search_Bar,
         Editor.Commands.Command_Run_Project_Search_From_Bar,
         Editor.Commands.Command_Project_Search_From_Selection,
         Editor.Commands.Command_Project_Search_From_Active_Word,
         Editor.Commands.Command_Project_Search_Active_Directory,
         Editor.Commands.Command_Project_Search_From_Selection,
         Editor.Commands.Command_Clear_Project_Search,
         Editor.Commands.Command_Open_Selected_Project_Search_Result,
         Editor.Commands.Command_Move_Project_Search_Selection_Up,
         Editor.Commands.Command_Move_Project_Search_Selection_Down,
         Editor.Commands.Command_Next_Project_Search_Result,
         Editor.Commands.Command_Previous_Project_Search_Result,
         Editor.Commands.Command_First_Project_Search_Result,
         Editor.Commands.Command_Last_Project_Search_Result,
         Editor.Commands.Command_Reveal_Active_Project_Search_Result,
         Editor.Commands.Command_Project_Search_Scope_Selected_Directory,
         Editor.Commands.Command_Project_Search_Kind_Next,
         Editor.Commands.Command_Project_Search_Kind_Previous,
         Editor.Commands.Command_Project_Search_Kind_Clear,
         Editor.Commands.Command_Project_Search_Scope_Set,
         Editor.Commands.Command_Project_Search_Scope_Clear,
         Editor.Commands.Command_Project_Search_Case_Toggle,
         Editor.Commands.Command_Project_Search_Case_Clear,
         Editor.Commands.Command_Project_Search_Whole_Word_Toggle,
         Editor.Commands.Command_Project_Search_Whole_Word_Clear,
         Editor.Commands.Command_Project_Search_Regex_Toggle,
         Editor.Commands.Command_Project_Search_Regex_Clear,
         Editor.Commands.Command_Project_Search_Include_Filter_Set,
         Editor.Commands.Command_Project_Search_Exclude_Filter_Set,
         Editor.Commands.Command_Project_Search_Include_Filter_Clear,
         Editor.Commands.Command_Project_Search_Exclude_Filter_Clear,
         Editor.Commands.Command_Project_Search_Replace_Preview,
         Editor.Commands.Command_Project_Search_Replace_Selected,
         Editor.Commands.Command_Project_Search_Replace_All_Included,
         Editor.Commands.Command_Project_Search_Replace_Clear_Preview,
         Editor.Commands.Command_Show_Search_Results_Panel,
         Editor.Commands.Command_Focus_Search_Results,
         Editor.Commands.Command_Search_Results_Move_Up,
         Editor.Commands.Command_Search_Results_Move_Down,
         Editor.Commands.Command_Search_Results_Open_Selected);

      function Contains_Project_Search_Leak (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
      begin
         return Ada.Strings.Fixed.Index (Lower, "transient") > 0
           or else Ada.Strings.Fixed.Index (Lower, "executor") > 0
           or else Ada.Strings.Fixed.Index (Lower, "compatibility") > 0
           or else Ada.Strings.Fixed.Index (Lower, "bottom panel") > 0
           or else Ada.Strings.Fixed.Index (Lower, "metadata") > 0
           or else Ada.Strings.Fixed.Index (Lower, "lifecycle") > 0
           or else Ada.Strings.Fixed.Index (Lower, "route") > 0
           or else Ada.Strings.Fixed.Index (Lower, "producer") > 0
           or else Ada.Strings.Fixed.Index (Lower, ":") > 0;
      end Contains_Project_Search_Leak;

      D : Editor.Commands.Command_Descriptor;
   begin
      for Id of Project_Search_Commands loop
         D := Editor.Commands.Descriptor (Id);
         Assert (To_String (D.Name)'Length > 0,
                 "Project Search command label is present");
         Assert (To_String (D.Description)'Length > 0,
                 "Project Search command description is present: " &
                 To_String (D.Name));
         Assert (not Contains_Project_Search_Leak (To_String (D.Name)),
                 "Project Search label avoids implementation wording: " &
                 To_String (D.Name));
         Assert (not Contains_Project_Search_Leak (To_String (D.Description)),
                 "Project Search description avoids implementation wording: " &
                 To_String (D.Description));
      end loop;
   end Test_Project_Search_Product_Surface;

   procedure Test_Find_And_Goto_Product_Surface
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Find_And_Goto_Commands : constant Command_Array :=
        (Editor.Commands.Command_Goto_Line,
         Editor.Commands.Command_Goto_Line_Toggle,
         Editor.Commands.Command_Goto_Line_Prefill_Current,
         Editor.Commands.Command_Goto_Line_Query_Set,
         Editor.Commands.Command_Goto_Line_Query_Clear,
         Editor.Commands.Command_Close_Goto_Line,
         Editor.Commands.Command_Accept_Goto_Line,
         Editor.Commands.Command_Find_Show,
         Editor.Commands.Command_Find_Hide,
         Editor.Commands.Command_Find_Toggle,
         Editor.Commands.Command_Find_Query_Set,
         Editor.Commands.Command_Find_Query_Clear,
         Editor.Commands.Command_Find_Case_Toggle,
         Editor.Commands.Command_Find_Case_Clear,
         Editor.Commands.Command_Find_Whole_Word_Toggle,
         Editor.Commands.Command_Find_Whole_Word_Clear,
         Editor.Commands.Command_Find_From_Selection,
         Editor.Commands.Command_Find_From_Active_Word,
         Editor.Commands.Command_Active_Find_Next,
         Editor.Commands.Command_Active_Find_Previous,
         Editor.Commands.Command_Find_First,
         Editor.Commands.Command_Find_Last,
         Editor.Commands.Command_Find_Reveal_Current,
         Editor.Commands.Command_Replace_Show,
         Editor.Commands.Command_Replace_Hide,
         Editor.Commands.Command_Replace_Toggle,
         Editor.Commands.Command_Replace_Text_Set,
         Editor.Commands.Command_Replace_Text_Clear,
         Editor.Commands.Command_Replace_Current,
         Editor.Commands.Command_Replace_All);

      function Contains_Find_Surface_Leak (Text : String) return Boolean is
         Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
      begin
         return Ada.Strings.Fixed.Index (Lower, "transient") > 0
           or else Ada.Strings.Fixed.Index (Lower, "metadata") > 0
           or else Ada.Strings.Fixed.Index (Lower, "projection") > 0
           or else Ada.Strings.Fixed.Index (Lower, "payload") > 0
           or else Ada.Strings.Fixed.Index (Lower, "active-buffer find") > 0
           or else Ada.Strings.Fixed.Index (Lower, "active-buffer replace") > 0;
      end Contains_Find_Surface_Leak;

      D : Editor.Commands.Command_Descriptor;
   begin
      for Id of Find_And_Goto_Commands loop
         D := Editor.Commands.Descriptor (Id);
         Assert (To_String (D.Name)'Length > 0,
                 "Find/Go to Line command label is present");
         Assert (To_String (D.Description)'Length > 0,
                 "Find/Go to Line command description is present: " &
                 To_String (D.Name));
         Assert (not Contains_Find_Surface_Leak (To_String (D.Name)),
                 "Find/Go to Line label avoids implementation wording: " &
                 To_String (D.Name));
         Assert (not Contains_Find_Surface_Leak (To_String (D.Description)),
                 "Find/Go to Line description avoids implementation wording: " &
                 To_String (D.Description));
      end loop;
   end Test_Find_And_Goto_Product_Surface;

   overriding procedure Register_Tests
     (T : in out Product_Surface_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Configuration_Command_Domain_Isolation'Access,
         "Configuration Command Domain Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Switcher_Command_Reference_Metadata'Access,
         "Switcher Command Reference Metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Switcher_Command_Reference_Content'Access,
         "Switcher Command Reference Content");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Configuration_Command_Surface_Coherent'Access,
         "Configuration Command Surface Coherent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Switch_Project_Command_Surface'Access,
         "Switch Project Command Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_IDE_Grade_Language_Command_Surface'Access,
         "IDE Grade Language Command Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Command_Reference_Surface'Access,
         "File Command Reference Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Search_Product_Surface'Access,
         "Project Search Product Surface");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Find_And_Goto_Product_Surface'Access,
         "Find and Go to Line Product Surface");
   end Register_Tests;

end Editor.Command_Surface.Product_Surface_Tests;
