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

package body Editor.Command_Surface.Lifecycle_Surface_Tests is

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
     (T : Lifecycle_Surface_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Lifecycle_Surface.Tests");
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

   procedure Test_Failed_Reload_Reports_Command_Failed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Write_Invalid_File (Path : String) is
         F : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Path);
         Ada.Text_IO.Put_Line (F, "this is not a valid editor configuration file");
         Ada.Text_IO.Close (F);
      end Write_Invalid_File;

      S     : Editor.State.State_Type;
      R     : Editor.Executor.Command_Execution_Result;
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
      Settings_Path : constant String := Editor.Test_Temp.Base & "/editor-tests/invalid-settings.tmp";
      Keybindings_Path : constant String := Editor.Test_Temp.Base & "/editor-tests/invalid-keybindings.tmp";
   begin
      Ada.Directories.Create_Path (Editor.Test_Temp.Base & "/editor-tests");
      Ada.Environment_Variables.Set
        ("EDITOR_SETTINGS_PATH", Settings_Path);
      Ada.Environment_Variables.Set
        ("EDITOR_KEYBINDINGS_PATH", Keybindings_Path);

      Write_Invalid_File (Settings_Path);
      Write_Invalid_File (Keybindings_Path);

      Editor.State.Init (S);
      R := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reload_Settings);
      Assert (R.Status = Editor.Executor.Command_Failed,
              "invalid settings reload must report Command_Failed");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Severity (Msg) = Editor.Messages.Error_Message,
              "invalid settings reload must emit one error message");
      Assert (Editor.Messages.Text (Msg) = "Settings file is invalid.",
              "invalid settings reload must use canonical domain-specific message");

      Editor.Messages.Clear (S.Messages);
      Editor.Keybinding_Management.Reset_Transient_State;
      Found := False;
      R := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Reload_Keybindings);
      Assert (R.Status = Editor.Executor.Command_Failed,
              "invalid keybindings reload must report Command_Failed");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Severity (Msg) = Editor.Messages.Error_Message,
              "invalid keybindings reload must emit one error message");
      Assert (Editor.Messages.Text (Msg) = "Default keybindings active.",
              "invalid keybindings reload must use canonical domain-specific message");
   end Test_Failed_Reload_Reports_Command_Failed;

   procedure Test_File_Lifecycle_Availability_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Commands.Is_Available (A),
              "save with no open buffer must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No active buffer.",
              "save with no open buffer must explain the missing active buffer");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (A),
              "close with no open buffer must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No active buffer.",
              "close with no open buffer must explain that there is no active buffer");

      Editor.Buffers.Ensure_Global_Registry (S);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Commands.Is_Available (A),
              "save untitled without a target must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No file path for active buffer",
              "save untitled without save-as target must use No file path for active buffer");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (A),
              "reload untitled must be unavailable");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No file path for active buffer",
              "reload untitled must explain that no file path exists");
   end Test_File_Lifecycle_Availability_Reasons;

   procedure Test_Reload_Command_Palette_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("reload file");

      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         if Candidate.Id = Editor.Commands.Command_Reload_Active_Buffer then
            Found := True;
            Assert (not Candidate.Available,
                    "reload row must show current unavailable state for untitled buffer");
            Assert (To_String (Candidate.Reason) = "No file path for active buffer",
                    "reload row must expose the deterministic disabled reason");
         end if;
      end loop;

      Assert (Found,
              "reload must be visible as a command-palette lifecycle row");
   end Test_Reload_Command_Palette_Row;

   procedure Test_Status_Bar_Lifecycle_Hint_Is_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Text : Unbounded_String;
      Before_Dirty : Boolean;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      S.File_Info.Dirty := True;
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, False);
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Dirty := S.File_Info.Dirty;

      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "Untitled dirty buffer") > 0,
              "/241: dirty untitled buffer should expose untitled dirty lifecycle state");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "Save As available") = 0,
              "dirty untitled lifecycle hint must not advertise targetless Save As without canonical target acquisition");
      Assert (To_String (Before_Text) = Editor.State.Current_Text (S),
              "lifecycle hint projection must not mutate buffer text");
      Assert (S.File_Info.Dirty = Before_Dirty,
              "lifecycle hint projection must not mutate dirty state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "lifecycle hint projection must not post messages");
   end Test_Status_Bar_Lifecycle_Hint_Is_Projection;

   procedure Test_Dirty_Open_Buffer_Row_Save_Hint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary;
      Hint : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Editor.Test_Temp.Base & "/active.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("active.adb");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Summary := Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer);

      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "save available") > 0,
              "selected dirty active file row must expose save availability");
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "normal close blocked") > 0,
              "selected dirty row must not imply close discards edits");
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "discard") = 0,
              "unsupported destructive wording must be absent");
   end Test_Dirty_Open_Buffer_Row_Save_Hint;

   procedure Test_Open_Buffer_Row_Keybinding_Setting
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id           => 2,
         Display_Name => To_Unbounded_String ("other.adb"),
         Is_Dirty     => False,
         Is_Active    => False,
         others       => <>);
      With_Keys : Unbounded_String;
      Without_Keys : Unbounded_String;
   begin
      Editor.State.Init (S);
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, True);
      With_Keys := To_Unbounded_String
        (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary));
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, False);
      Without_Keys := To_Unbounded_String
        (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary));

      Assert (Ada.Strings.Fixed.Index (To_String (With_Keys), "[Enter]") > 0,
              "open-buffer row hint should name Enter when shortcut display is enabled");
      Assert (Ada.Strings.Fixed.Index (To_String (Without_Keys), "[Enter]") = 0,
              "open-buffer row hint must respect show-keybindings=false");
   end Test_Open_Buffer_Row_Keybinding_Setting;

   procedure Test_File_Tree_Open_And_Focus_Wording
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : Unbounded_String;
      Node : Editor.File_Tree.File_Tree_Node_Summary;
      Before_Open : Unbounded_String;
      After_Open : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Prepare_File_Tree (S, Path, Node);

      Before_Open := To_Unbounded_String
        (Editor.Lifecycle_Guidance.File_Tree_Row_Hint (S, Node));
      Assert (To_String (Before_Open) = "Open file [Enter]",
              "unopened File Tree file row must advertise open");

      S.File_Info.Has_Path := True;
      S.File_Info.Path := Path;
      S.File_Info.Display_Name := To_Unbounded_String ("a.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      After_Open := To_Unbounded_String
        (Editor.Lifecycle_Guidance.File_Tree_Row_Hint (S, Node));
      Assert (Ada.Strings.Fixed.Index (To_String (After_Open), "Focus existing unsaved buffer") > 0,
              "already-open dirty File Tree row must use focus wording");
      Assert (Ada.Strings.Fixed.Index (To_String (After_Open), "reload") = 0,
              "already-open dirty File Tree row must not imply reload");
      Assert (Ada.Strings.Fixed.Index (To_String (After_Open), "discard") = 0,
              "already-open dirty File Tree row must not imply discard");
   end Test_File_Tree_Open_And_Focus_Wording;

   procedure Test_Status_Bar_File_Tree_Focus_Hint
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : Unbounded_String;
      Node : Editor.File_Tree.File_Tree_Node_Summary;
      Row : Natural := 0;
      Found : Boolean := False;
      Hint : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Prepare_File_Tree (S, Path, Node);
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node.Id, Found);
      Assert (Found, "fixture must map scanned file to visible row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Path;
      S.File_Info.Display_Name := To_Unbounded_String ("a.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);

      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "Focus existing unsaved buffer") > 0,
              "Status Bar File Tree lifecycle hint should mirror selected file focus action");
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "reload") = 0,
              "Status Bar already-open file hint must not imply reload");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "Status Bar lifecycle hint must remain projection-only");
   end Test_Status_Bar_File_Tree_Focus_Hint;

   procedure Test_Status_Bar_Clean_Dirty_And_Retry_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Hint : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Editor.Test_Temp.Base & "/status.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("status.adb");
      S.File_Info.Dirty := False;
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, False);
      Editor.Buffers.Ensure_Global_Registry (S);

      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "Clean file") > 0,
              "clean file-backed active buffer should be readable in the Status Bar lifecycle hint");

      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := False;
      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "Dirty file") > 0,
              "dirty file-backed active buffer should be readable in the Status Bar lifecycle hint");
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "save available") > 0,
              "dirty file-backed Status Bar hint should retain safe save guidance");

      S.File_Info.Last_Save_Failed := True;
      Hint := To_Unbounded_String (Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Hint), "retry save available") > 0,
              "failed-save state should remain visibly retryable while the buffer is dirty and saveable");
      Assert (Editor.Messages.Count (S.Messages) = 0,
              "lifecycle hint projection must not post messages");
   end Test_Status_Bar_Clean_Dirty_And_Retry_State;

   procedure Test_Open_Buffer_Row_Label_Shows_Retry_Without_Hiding_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Editor.Test_Temp.Base & "/row.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("row.adb");
      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := True;
      Editor.Buffers.Ensure_Global_Registry (S);

      Summary := Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer);
      Assert (Summary.Is_Dirty,
              "retryable failed-save row must keep the dirty marker state visible");
      Assert (Ada.Strings.Fixed.Index (To_String (Summary.Display_Name), "retry save") > 0,
              "retryable failed-save row label should expose retry context");
      Assert (Ada.Strings.Fixed.Index (To_String (Summary.Display_Name), "row.adb") > 0,
              "retryable row label should preserve the stable buffer label");
   end Test_Open_Buffer_Row_Label_Shows_Retry_Without_Hiding_Dirty;

   overriding procedure Register_Tests
     (T : in out Lifecycle_Surface_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Reload_Reports_Command_Failed'Access,
         "Failed Reload Reports Command_Failed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Availability_Reasons'Access,
         "File Lifecycle Availability Reasons");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Command_Palette_Row'Access,
         "Reload Command Palette Row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_Lifecycle_Hint_Is_Projection'Access,
         "Status Bar Lifecycle Hint Is Projection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Open_Buffer_Row_Save_Hint'Access,
         "Dirty Open Buffer Row Save Hint");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Buffer_Row_Keybinding_Setting'Access,
         "Open Buffer Row Keybinding Setting");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Open_And_Focus_Wording'Access,
         "File Tree Open And Focus Wording");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_File_Tree_Focus_Hint'Access,
         "Status Bar File Tree Focus Hint");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_Clean_Dirty_And_Retry_State'Access,
         "Status Bar Clean Dirty And Retry State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Buffer_Row_Label_Shows_Retry_Without_Hiding_Dirty'Access,
         "Open Buffer Row Label Shows Retry Without Hiding Dirty");
   end Register_Tests;

end Editor.Command_Surface.Lifecycle_Surface_Tests;
