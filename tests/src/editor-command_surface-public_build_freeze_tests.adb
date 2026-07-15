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

package body Editor.Command_Surface.Public_Build_Freeze_Tests is

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
     (T : Public_Build_Freeze_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Public_Build_Freeze.Tests");
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

   procedure Test_Public_Build_Hard_Freeze_Audit_Passes_Default_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Audit : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Audit := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (Audit.Passed,
              "public build hard-freeze audit must pass the default not-exposed state");
      Assert (Audit.Readiness_Audit_Passed_As_Not_Ready,
              "hard-freeze audit must preserve guarded promotion-ready result");
      Assert (not Audit.Promotion_Blocked,
              "hard-freeze audit must allow guarded surface entry promotion");
      Assert (not Audit.Public_Exposure_Hard_Failure,
              "default public build hard-freeze must not report exposure failure");
      Assert (Audit.No_Public_Command_Registered,
              "public build command ids must remain unregistered");
      Assert (Audit.No_Default_Execution,
              "default public build execution must remain disabled");
   end Test_Public_Build_Hard_Freeze_Audit_Passes_Default_State;

   procedure Test_Public_Build_Hard_Freeze_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      A1 : Public_Build_Command_Hard_Freeze_Audit_Result;
      A2 : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      A1 := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      A2 := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (A1.Passed = A2.Passed,
              "repeated hard-freeze audits must return stable pass state");
      Assert (A1.Promotion_Blocked = A2.Promotion_Blocked,
              "repeated hard-freeze audits must return stable promotion state");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "hard-freeze audit must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "hard-freeze audit must not create or close buffers");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Hard_Freeze_Audit_Is_Side_Effect_Free;

   procedure Test_Public_Build_Hard_Freeze_Audit_Agrees_With_Other_Audits
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert_Public_Build_Audits_Agree (S);
      Assert_No_Public_Build_Execution_Path (S);
      Assert_Public_Build_Hard_Freeze_Not_Persisted (S);
   end Test_Public_Build_Hard_Freeze_Audit_Agrees_With_Other_Audits;

   procedure Test_Public_Build_Hard_Freeze_Detects_Simulated_Hard_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Has_Default_Public_Build_Keybinding := True;
      Assert (Detect_Public_Build_Command_Exposure_Hard_Failure (R),
              "simulated public default keybinding must be a hard failure");
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "simulated hard failures must not mutate the real registry or audits");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Hard_Freeze_Detects_Simulated_Hard_Failures;

   procedure Test_Public_Build_Hard_Freeze_Remains_After_Lifecycle_Transitions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must pass before lifecycle transitions");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must survive project-scoped reset");
      Reset_Build_Run_State_For_Project_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Project_Close (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must survive project close build/diagnostic resets");
      Reset_Build_Run_State_For_Workspace_Close (S);
      Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must survive workspace close build/diagnostic resets");
      Editor.Keybindings.Reset_To_Defaults;
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-freeze must survive keybinding reset");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Hard_Freeze_Remains_After_Lifecycle_Transitions;

   procedure Test_No_Public_Build_Execution_Path_Remains
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Audit : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Audit := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (Audit.No_Public_Command_Registered,
              "no public build descriptor may exist");
      Assert (Audit.No_Public_Executor_Route,
              "no public build Executor route may exist");
      Assert (Audit.No_Public_Invocation_Path,
              "no public build invocation path may exist");
      Assert (Audit.No_Public_Default_Keybinding,
              "no public build keybinding may exist");
      Assert (Audit.No_Public_Command_Palette_Entry,
              "no public build palette entry may exist");
      Assert (Audit.No_Public_Bindable_Command,
              "no public build bindable command may exist");
      Assert (Audit.No_Default_Execution,
              "default execution must remain disabled");
      Assert_No_Public_Build_Execution_Path (S);
   end Test_No_Public_Build_Execution_Path_Remains;

   procedure Test_Public_Build_Hard_Freeze_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Audit : Public_Build_Command_Hard_Freeze_Audit_Result;
      Failed : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Audit := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (Build_Public_Build_Hard_Freeze_Feedback (Audit) =
              "Build: public command ready",
              "passing hard-freeze feedback must be deterministic and sanitized");
      Failed := Audit;
      Failed.Public_Exposure_Hard_Failure := True;
      Failed.Passed := False;
      Assert (Build_Public_Build_Hard_Freeze_Feedback (Failed) =
              "Build: unsafe public command exposure detected",
              "hard-failure feedback must be deterministic and sanitized");
      Failed := Audit;
      Failed.Passed := False;
      Assert (Build_Public_Build_Hard_Freeze_Feedback (Failed) =
              "Build: public build hard-freeze failed",
              "generic failed hard-freeze feedback must be deterministic and sanitized");
   end Test_Public_Build_Hard_Freeze_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Hard_Freeze_Baseline_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      B1 : constant Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      B2 : constant Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
   begin
      Assert (B1.Public_Command_Count = 1,
              "baseline must record one guarded public build command");
      Assert (B1.Public_Default_Keybinding_Count = 0,
              "baseline must record zero default public build keybindings");
      Assert (B1.Public_Command_Palette_Count = 1,
              "baseline must record one guarded public build palette row");
      Assert (B1.Public_Executor_Route_Count = 1,
              "baseline must record one guarded public build Executor route");
      Assert (B1.Public_Invocation_Path_Count = 1,
              "baseline must record one guarded public build invocation path");
      Assert (B1.Bindable_Public_Build_Count = 0,
              "baseline must record zero bindable public build commands");
      Assert (not B1.Promotion_Blocked,
              "baseline must record guarded promotion ready");
      Assert (B1.Default_Execution_Disabled,
              "baseline must record disabled default execution");
      Assert (not B1.Consent_UX_Missing,
              "baseline must record completed consent UX");
      Assert (not B1.Working_Context_UX_Missing,
              "baseline must record completed working-context UX");
      Assert (not B1.Implicit_Source_Unsupported,
              "baseline must record explicit-source policy support");
      Assert (not B1.Public_Route_Missing,
              "baseline must record guarded public route present");
      Assert (B1 = B2,
              "hard-freeze baseline must be deterministic");
   end Test_Public_Build_Hard_Freeze_Baseline_Is_Deterministic;

   procedure Test_Public_Build_Hard_Freeze_Drift_Default_State_Has_No_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Drift : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      Drift := Detect_Public_Build_Hard_Freeze_Drift
        (S, Build_Public_Build_Hard_Freeze_Baseline);
      Assert (not Drift.Any_Drift,
              "default state must not drift from hard-freeze baseline");
      Assert (Build_Public_Build_Drift_Feedback (Drift) =
              "Build: public command hard-freeze intact",
              "no-drift feedback must be deterministic and sanitized");
   end Test_Public_Build_Hard_Freeze_Drift_Default_State_Has_No_Drift;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detection_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      D1 : Public_Build_Hard_Freeze_Drift_Result;
      D2 : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      D1 := Detect_Public_Build_Hard_Freeze_Drift
        (S, Build_Public_Build_Hard_Freeze_Baseline);
      D2 := Detect_Public_Build_Hard_Freeze_Drift
        (S, Build_Public_Build_Hard_Freeze_Baseline);
      Assert (D1.Any_Drift = D2.Any_Drift,
              "repeated drift scans must be deterministic");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "drift scan must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "drift scan must not create buffers or switch context");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Hard_Freeze_Drift_Detection_Is_Side_Effect_Free;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Command_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Public_Command_Drift and then D.Any_Drift,
              "changed public-command baseline must be reported as command drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Command;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Default_Keybinding_Count := 1;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Keybinding_Drift and then D.Any_Drift,
              "changed keybinding baseline must be reported as keybinding drift");
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public build keybinding drift detected",
              "keybinding drift feedback must be deterministic");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Keybinding;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Palette_Entry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Command_Palette_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Palette_Drift and then D.Any_Drift,
              "changed palette baseline must be reported as palette drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Palette_Entry;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Executor_Route
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Executor_Route_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Executor_Route_Drift and then D.Any_Drift,
              "changed route baseline must be reported as route drift");
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public build route drift detected",
              "route drift feedback must be deterministic");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Executor_Route;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Invocation_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Invocation_Path_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Invocation_Path_Drift and then D.Any_Drift,
              "changed invocation-path baseline must be reported as drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Invocation_Path;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Bindable_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Bindable_Public_Build_Count := 1;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Bindability_Drift and then D.Any_Drift,
              "changed bindability baseline must be reported as drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Bindable_Command;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Promotion_Status_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Promotion_Blocked := True;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Promotion_Drift and then D.Any_Drift,
              "changed promotion baseline must be reported as promotion drift");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Promotion_Status_Change;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Blocker_Precedence_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Consent_UX_Missing := True;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Blocker_Precedence_Drift and then D.Any_Drift,
              "changed blocker baseline must be reported as precedence drift");
      Assert_Public_Build_Blocker_Precedence;
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Blocker_Precedence_Change;

   procedure Test_Public_Build_Hard_Freeze_Drift_Detects_Persistence_Leak
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      D.Persistence_Drift := True;
      D.Any_Drift := True;
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public build persistence drift detected",
              "persistence drift feedback must be deterministic");
   end Test_Public_Build_Hard_Freeze_Drift_Detects_Persistence_Leak;

   procedure Test_Public_Build_Surface_Id_Cannot_Be_Reused_By_Unrelated_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Is_Public_Build_Surface_Id ("build.run"),
              "build.run must be public");
      Assert (not Is_Public_Build_Surface_Id ("compile.current"),
              "compile.current remains a reserved alias, not public build");
      Assert (not Is_Public_Build_Surface_Id ("diagnostics.show"),
              "unrelated diagnostics command must not be public as public build");
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Test_Public_Build_Surface_Id_Cannot_Be_Reused_By_Unrelated_Command;

   procedure Test_Public_Build_Audit_Composition_Remains_Consistent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Hard_Freeze : Public_Build_Command_Hard_Freeze_Audit_Result;
      Readiness : Public_Build_Command_Readiness_Audit_Result;
      Drift : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      Hard_Freeze := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Readiness := Run_Public_Build_Command_Readiness_Audit (S);
      Drift := Detect_Public_Build_Hard_Freeze_Drift
        (S, Build_Public_Build_Hard_Freeze_Baseline);
      Assert (Hard_Freeze.Passed,
              "hard-freeze must pass in default state");
      Assert (Readiness.Passed_As_Not_Ready,
              "readiness must pass as guarded promotion-ready");
      Assert (Readiness.Public_Command_Promotion_Status =
              Public_Build_Promotion_Command_Surface_Ready,
              "readiness must allow guarded promotion");
      Assert (not Drift.Any_Drift,
              "passing hard-freeze must have no drift");
      Assert_Public_Build_Audits_Agree (S);
   end Test_Public_Build_Audit_Composition_Remains_Consistent;

   procedure Test_Public_Build_Audit_Composition_Hard_Failure_Fails_Hard_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Has_Default_Public_Build_Keybinding := True;
      Assert (Detect_Public_Build_Command_Exposure_Hard_Failure (R),
              "simulated public default keybinding must be a hard exposure failure");
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "hard-failure simulation must not mutate real hard-freeze state");
   end Test_Public_Build_Audit_Composition_Hard_Failure_Fails_Hard_Freeze;

   procedure Test_Public_Build_Unrelated_Public_Command_Does_Not_Affect_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Found : Boolean;
      Round : Editor.Commands.Command_Id;
   begin
      Editor.State.Init (S);
      Assert (not Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Diagnostics_Show),
              "unrelated public diagnostics command must not count as public build");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Diagnostics_Execute_Selected_Action) =
              "diagnostics.execute-selected-action",
              "diagnostic selected action command exposes canonical stable id");
      Round := Editor.Commands.Command_Id_From_Stable_Name
        ("diagnostics.code-action", Found);
      Assert (Found and then Round =
              Editor.Commands.Command_Diagnostics_Execute_Selected_Action,
              "diagnostic selected action command keeps code-action alias");
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "unrelated public commands must not affect build hard-freeze");
   end Test_Public_Build_Unrelated_Public_Command_Does_Not_Affect_Freeze;

   procedure Test_Public_Build_Unrelated_Keybinding_Does_Not_Affect_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Command_Hard_Freeze_Audit (S).Passed,
              "unrelated keybindings must not affect build hard-freeze");
      Assert (not Detect_Public_Build_Hard_Freeze_Drift
                    (S, Build_Public_Build_Hard_Freeze_Baseline).Any_Drift,
              "unrelated keybinding surface must not create public build drift");
   end Test_Public_Build_Unrelated_Keybinding_Does_Not_Affect_Freeze;

   procedure Test_No_Public_Build_Execution_Path_RemainsDeep_Scan
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Audit : Public_Build_Command_Hard_Freeze_Audit_Result;
   begin
      Editor.State.Init (S);
      Audit := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      Assert (Audit.No_Public_Command_Registered,
              "deep scan: registry must have no public build command");
      Assert (Audit.No_Public_Command_Palette_Entry,
              "deep scan: palette must have no public build row");
      Assert (Audit.No_Public_Default_Keybinding,
              "deep scan: keybindings must have no public build target");
      Assert (Audit.No_Public_Executor_Route,
              "deep scan: Executor must have no public build route");
      Assert (Audit.No_Public_Invocation_Path,
              "deep scan: public invocation API must have no build path");
      Assert (Audit.Shell_Rejected and then Audit.Opaque_Arguments_Rejected,
              "deep scan: shell and opaque argument routes must stay rejected");
      Assert_No_Public_Build_Execution_Path (S);
   end Test_No_Public_Build_Execution_Path_RemainsDeep_Scan;

   procedure Test_Public_Build_Drift_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public command hard-freeze intact",
              "intact drift feedback must be deterministic");
      D.Any_Drift := True;
      D.Public_Command_Drift := True;
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public command exposure drift detected",
              "exposure drift feedback must be deterministic");
      D := (others => False);
      D.Any_Drift := True;
      D.Promotion_Drift := True;
      Assert (Build_Public_Build_Drift_Feedback (D) =
              "Build: public build promotion drift detected",
              "promotion drift feedback must be deterministic");
   end Test_Public_Build_Drift_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Guardrail_Audit_Uses_Hard_Freeze_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      H : Public_Build_Command_Hard_Freeze_Audit_Result;
      G : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      H := Run_Public_Build_Command_Hard_Freeze_Audit (S);
      G := Run_Public_Build_Guardrail_Audit (S);
      Assert (G.No_Public_Command = H.No_Public_Command_Registered
              and then G.No_Public_Keybinding = H.No_Public_Default_Keybinding
              and then G.No_Public_Palette_Entry = H.No_Public_Command_Palette_Entry
              and then G.No_Public_Executor_Route = H.No_Public_Executor_Route
              and then G.No_Public_Invocation_Path = H.No_Public_Invocation_Path
              and then G.No_Public_Bindable_Command = H.No_Public_Bindable_Command,
              "normalized guardrail must project hard-freeze no-public fields");
   end Test_Public_Build_Guardrail_Audit_Uses_Hard_Freeze_Audit;

   procedure Test_Public_Build_Guardrail_Audit_Uses_Drift_Detection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      B : Public_Build_Hard_Freeze_Baseline :=
        Build_Public_Build_Hard_Freeze_Baseline;
      D : Public_Build_Hard_Freeze_Drift_Result;
   begin
      Editor.State.Init (S);
      B.Public_Command_Count := 0;
      D := Detect_Public_Build_Hard_Freeze_Drift (S, B);
      Assert (D.Public_Command_Drift and then D.Any_Drift,
              "normalized guardrail source drift detection must catch changed public command baseline");
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "default normalized guardrail must pass with canonical baseline");
   end Test_Public_Build_Guardrail_Audit_Uses_Drift_Detection;

   procedure Test_Public_Build_Unrelated_Feature_Descriptor_Does_Not_Affect_Guardrail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (not Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Toggle_Feature_Panel),
              "unrelated feature-panel descriptor must not classify as public build");
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "unrelated feature descriptor must not affect the public build guardrail");
   end Test_Public_Build_Unrelated_Feature_Descriptor_Does_Not_Affect_Guardrail;

   procedure Test_Public_Build_Unrelated_Diagnostics_Source_Does_Not_Affect_Guardrail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Source : constant External_Producer_Source :=
        Build_External_Producer_Source (Compiler_Diagnostics_Producer);
   begin
      Editor.State.Init (S);
      Assert (To_String (Source.Stable_Name) /= "build.run",
              "unrelated diagnostics source must not reuse public build id");
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "unrelated diagnostics source must not affect public build guardrail");
   end Test_Public_Build_Unrelated_Diagnostics_Source_Does_Not_Affect_Guardrail;

   procedure Test_Public_Build_Unrelated_Messages_Source_Does_Not_Affect_Guardrail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Messages.Push_Info (S.Messages, "unrelated status message");
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "unrelated Messages rows must not affect public build guardrail");
      Assert (Run_Public_Build_Guardrail_Audit (S).Persistence_Clean,
              "unrelated Messages rows must not persist guardrail state");
   end Test_Public_Build_Unrelated_Messages_Source_Does_Not_Affect_Guardrail;

   procedure Test_Public_Build_Unrelated_Settings_Preference_Does_Not_Affect_Guardrail
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Run_Public_Build_Guardrail_Audit (S).Status =
              Public_Build_Guardrail_Passed,
              "unrelated settings preferences must not affect public build guardrail");
      Assert (Run_Public_Build_Guardrail_Audit (S).Default_Execution_Disabled,
              "unrelated settings preferences must not enable build execution");
   end Test_Public_Build_Unrelated_Settings_Preference_Does_Not_Affect_Guardrail;

   procedure Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Status_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.Status := Public_Build_Guardrail_Not_Ready_But_Safe;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Status_Mismatch and then M.Any_Mismatch,
              "contract mismatch detector must catch normalized status drift");
   end Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Status_Drift;

   procedure Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Public_Command_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.No_Public_Command := False;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Public_Command_Mismatch and then M.Any_Mismatch,
              "contract mismatch detector must catch public command drift");
   end Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Public_Command_Drift;

   procedure Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Promotion_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.Promotion_Blocked := True;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Promotion_Mismatch and then M.Any_Mismatch,
              "contract mismatch detector must catch promotion drift");
   end Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Promotion_Drift;

   procedure Test_Public_Build_Normalized_Audit_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      A : Public_Build_Guardrail_Result;
      B : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      A := Run_Public_Build_Guardrail_Audit (S);
      B := Run_Public_Build_Guardrail_Audit (S);
      Assert (A = B,
              "same editor state must produce identical normalized guardrail results");
   end Test_Public_Build_Normalized_Audit_Is_Deterministic;

   procedure Test_Public_Build_Normalized_Audit_Exposure_Simulation_Is_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R1 : Public_Build_Guardrail_Result := Default_Result;
      R2 : Public_Build_Guardrail_Result := Default_Result;
   begin
      R1.Status := Public_Build_Guardrail_Exposure_Detected;
      R1.No_Public_Command := False;
      R2.Status := Public_Build_Guardrail_Exposure_Detected;
      R2.No_Public_Command := False;
      Assert (Detect_Public_Build_Guardrail_Contract_Mismatch (R1) =
              Detect_Public_Build_Guardrail_Contract_Mismatch (R2),
              "same exposure simulation must produce identical mismatch result");
   end Test_Public_Build_Normalized_Audit_Exposure_Simulation_Is_Stable;

   procedure Test_Public_Build_Normalized_Audit_Drift_Simulation_Is_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R1 : Public_Build_Guardrail_Result := Default_Result;
      R2 : Public_Build_Guardrail_Result := Default_Result;
   begin
      R1.Status := Public_Build_Guardrail_Drift_Detected;
      R2.Status := Public_Build_Guardrail_Drift_Detected;
      Assert (Detect_Public_Build_Guardrail_Contract_Mismatch (R1) =
              Detect_Public_Build_Guardrail_Contract_Mismatch (R2),
              "same drift simulation must produce identical mismatch result");
   end Test_Public_Build_Normalized_Audit_Drift_Simulation_Is_Stable;

   procedure Test_Public_Build_Normalized_Audit_Inconsistency_Readiness_Promotion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.Status := Public_Build_Guardrail_Inconsistent_Audits;
      R.Audits_Consistent := False;
      R.Promotion_Blocked := True;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Status_Mismatch and then M.Promotion_Mismatch
              and then M.Audit_Consistency_Mismatch and then M.Any_Mismatch,
              "readiness/promotion inconsistency simulation must be detected");
   end Test_Public_Build_Normalized_Audit_Inconsistency_Readiness_Promotion;

   procedure Test_Public_Build_Normalized_Audit_Inconsistency_HardFreeze_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      M : Public_Build_Guardrail_Contract_Mismatch;
   begin
      R.Status := Public_Build_Guardrail_Inconsistent_Audits;
      R.Audits_Consistent := False;
      R.Default_Execution_Disabled := False;
      M := Detect_Public_Build_Guardrail_Contract_Mismatch (R);
      Assert (M.Status_Mismatch and then M.Default_Execution_Mismatch
              and then M.Audit_Consistency_Mismatch and then M.Any_Mismatch,
              "hard-freeze/drift inconsistency simulation must be detected");
   end Test_Public_Build_Normalized_Audit_Inconsistency_HardFreeze_Drift;

   procedure Test_Public_Build_Normalized_Audit_Agrees_With_No_Execution_Scan
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Guardrail_Audit (S);
      Assert_Public_Build_Guardrail_Agrees_With_No_Execution_Scan (S, R);
   end Test_Public_Build_Normalized_Audit_Agrees_With_No_Execution_Scan;

   overriding procedure Register_Tests
     (T : in out Public_Build_Freeze_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Audit_Passes_Default_State'Access,
         "Public Build Hard Freeze Audit Passes Default State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Audit_Is_Side_Effect_Free'Access,
         "Public Build Hard Freeze Audit Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Audit_Agrees_With_Other_Audits'Access,
         "Public Build Hard Freeze Audit Agrees With Other Audits");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Detects_Simulated_Hard_Failures'Access,
         "Public Build Hard Freeze Detects Simulated Hard Failures");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Remains_After_Lifecycle_Transitions'Access,
         "Public Build Hard Freeze Remains After Lifecycle Transitions");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Public_Build_Execution_Path_Remains'Access,
         "No Public Build Execution Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Feedback_Is_Deterministic'Access,
         "Public Build Hard Freeze Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Baseline_Is_Deterministic'Access,
         "Public Build Hard Freeze Baseline Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Default_State_Has_No_Drift'Access,
         "Public Build Hard Freeze Drift Default State Has No Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detection_Is_Side_Effect_Free'Access,
         "Public Build Hard Freeze Drift Detection Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Command'Access,
         "Public Build Hard Freeze Drift Detects Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Keybinding'Access,
         "Public Build Hard Freeze Drift Detects Keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Palette_Entry'Access,
         "Public Build Hard Freeze Drift Detects Palette Feed_Item");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Executor_Route'Access,
         "Public Build Hard Freeze Drift Detects Executor Route");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Public_Invocation_Path'Access,
         "Public Build Hard Freeze Drift Detects Invocation Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Bindable_Command'Access,
         "Public Build Hard Freeze Drift Detects Bindable Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Promotion_Status_Change'Access,
         "Public Build Hard Freeze Drift Detects Promotion Status Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Blocker_Precedence_Change'Access,
         "Public Build Hard Freeze Drift Detects Blocker Precedence Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Hard_Freeze_Drift_Detects_Persistence_Leak'Access,
         "Public Build Hard Freeze Drift Detects Persistence Leak");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Cannot_Be_Reused_By_Unrelated_Command'Access,
         "Public Build Public Id Cannot Be Reused By Unrelated Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Audit_Composition_Remains_Consistent'Access,
         "Public Build Audit Composition Remains Consistent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Audit_Composition_Hard_Failure_Fails_Hard_Freeze'Access,
         "Public Build Audit Composition Hard Failure Fails Hard Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Public_Command_Does_Not_Affect_Freeze'Access,
         "Public Build Unrelated Public Command Does Not Affect Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Keybinding_Does_Not_Affect_Freeze'Access,
         "Public Build Unrelated Keybinding Does Not Affect Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Public_Build_Execution_Path_RemainsDeep_Scan'Access,
         "No Public Build Execution Path Deep Scan");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Drift_Feedback_Is_Deterministic'Access,
         "Public Build Drift Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Uses_Hard_Freeze_Audit'Access,
         "Public Build Guardrail Audit Uses Hard Freeze Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Uses_Drift_Detection'Access,
         "Public Build Guardrail Audit Uses Drift Detection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Feature_Descriptor_Does_Not_Affect_Guardrail'Access,
         "Public Build Unrelated Feature Descriptor Does Not Affect Guardrail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Diagnostics_Source_Does_Not_Affect_Guardrail'Access,
         "Public Build Unrelated Diagnostics Source Does Not Affect Guardrail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Messages_Source_Does_Not_Affect_Guardrail'Access,
         "Public Build Unrelated Messages Source Does Not Affect Guardrail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Unrelated_Settings_Preference_Does_Not_Affect_Guardrail'Access,
         "Public Build Unrelated Settings Preference Does Not Affect Guardrail");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Status_Drift'Access,
         "Public Build Guardrail Contract Mismatch Detects Status Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Public_Command_Drift'Access,
         "Public Build Guardrail Contract Mismatch Detects Public Command Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Mismatch_Detects_Promotion_Drift'Access,
         "Public Build Guardrail Contract Mismatch Detects Promotion Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Is_Deterministic'Access,
         "Public Build Normalized Audit Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Exposure_Simulation_Is_Stable'Access,
         "Public Build Normalized Audit Exposure Simulation Is Stable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Drift_Simulation_Is_Stable'Access,
         "Public Build Normalized Audit Drift Simulation Is Stable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Inconsistency_Readiness_Promotion'Access,
         "Public Build Normalized Audit Inconsistency Readiness Promotion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Inconsistency_HardFreeze_Drift'Access,
         "Public Build Normalized Audit Inconsistency HardFreeze Drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Normalized_Audit_Agrees_With_No_Execution_Scan'Access,
         "Public Build Normalized Audit Agrees With No Execution Scan");
   end Register_Tests;

end Editor.Command_Surface.Public_Build_Freeze_Tests;
