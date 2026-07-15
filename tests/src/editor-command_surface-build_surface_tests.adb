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

package body Editor.Command_Surface.Build_Surface_Tests is

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
     (T : Build_Surface_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Build_Surface.Tests");
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

   procedure Test_User_Opt_In_Build_Command_Is_Internal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam) =
              "build.run-user-opt-in-test-seam",
              "internal user opt-in build test-seam command id is stable");
      Assert (To_String (D.Name) = "Build: Run User Opt-In Test Command",
              "internal user opt-in build test label is stable");
      Assert (D.Category = Editor.Commands.Internal_Category,
              "user opt-in build test-seam command is internal");
      Assert (D.Visibility = Editor.Commands.Hidden_Command,
              "user opt-in build test-seam command is hidden from normal palette");
      Assert (not D.Bindable,
              "user opt-in build test-seam command has no default keybinding target");
      Assert (Editor.Commands.Requires_Context
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "user opt-in build test-seam command requires structured context");
   end Test_User_Opt_In_Build_Command_Is_Internal;

   procedure Test_User_Opt_In_Build_Command_Has_No_Default_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Info : Editor.Keybindings.Command_Keybinding_Info;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Info := Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Assert (not Info.Has_Binding,
              "internal user opt-in build test seam must not get a default keybinding");
   end Test_User_Opt_In_Build_Command_Has_No_Default_Keybinding;

   procedure Test_User_Opt_In_Build_Command_Bare_Route_Is_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
      R : Editor.Executor.Command_Execution_Result;
   begin
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Assert (not Editor.Commands.Is_Available (A),
              "bare user opt-in build command route is unavailable without structured context");
      Assert (Editor.Commands.Unavailable_Reason (A) =
              "Build: structured command context required",
              "bare user opt-in build command reports deterministic missing-context feedback");
      R := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Assert (R.Status = Editor.Executor.Command_Unavailable,
              "bare user opt-in build command cannot execute without context");
   end Test_User_Opt_In_Build_Command_Bare_Route_Is_Unavailable;

   procedure Test_User_Opt_In_Build_Command_Structured_Route_Reaches_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Context : constant Editor.External_Producers.User_Opt_In_Build_Command_Context :=
        Editor.External_Producers.Build_User_Opt_In_Command_Context
          (Tool              => Editor.External_Producers.GPRbuild_Tool,
           Program_Label     => "gprbuild",
           Working_Label     => "",
           Arguments         => Editor.External_Producers.Build_Process_Argument_Vector ("-q"),
           Consent           => Editor.External_Producers.Build_Consent_User_Confirmed,
           Allow_Diagnostics => True,
           Show_Diagnostics  => False);
      Result : Editor.External_Producers.Build_Command_Result;
   begin
      Result := Editor.Executor.Execute_User_Opt_In_Build_Command
        (S, Context,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Exit_Code => 0, Has_Exit_Code => True));
      Assert (Result.Build_Result.Status = Editor.External_Producers.Build_Run_Succeeded,
              "structured user opt-in build command route reaches executor boundary");
      Assert (To_String (Result.Command_Message) = "Build: succeeded",
              "structured user opt-in build command returns one primary result");
   end Test_User_Opt_In_Build_Command_Structured_Route_Reaches_Executor;

   procedure Test_Build_Command_Surface_Has_No_Public_Run_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Id : Editor.Commands.Command_Id;
      Stable : Unbounded_String;
      D : Editor.Commands.Command_Descriptor;
      Saw_Run : Boolean := False;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         Stable := To_Unbounded_String (Editor.Commands.Stable_Command_Name (Id));
         D := Editor.Commands.Descriptor (Id);

         if To_String (Stable) = "build.run" then
            Saw_Run := True;
            Assert (Id = Editor.Commands.Command_Build_Run,
                    "build.run must resolve to the guarded public build command");
            Assert (D.Visibility = Editor.Commands.Palette_Command,
                    "build.run is palette-visible through the guarded public surface");
            Assert (not D.Bindable,
                    "build.run must not be bindable by default");
         else
            Assert (To_String (Stable) /= "build.project"
                    and then To_String (Stable) /= "compile.project"
                    and then To_String (Stable) /= "diagnostics.run-build",
                    "reserved public build alias must remain absent: " &
                    To_String (Stable));
         end if;

         if Id = Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam then
            Assert (D.Visibility = Editor.Commands.Hidden_Command,
                    "internal build test seam must stay hidden from normal palette");
            Assert (D.Category = Editor.Commands.Internal_Category,
                    "internal build test seam must remain internal/test-only");
            Assert (not D.Bindable,
                    "internal build test seam must not be bindable by default");
            Assert (not Editor.Commands.Visible_In_Command_Palette (Id),
                    "normal command palette must exclude internal build test seam");
            Assert (not Editor.Keybindings.Primary_Binding_For_Command (Id).Has_Binding,
                    "internal build test seam must not have a default keybinding");
         end if;
      end loop;
      Assert (Saw_Run, "build.run must be present in the command surface");
   end Test_Build_Command_Surface_Has_No_Public_Run_Command;

   procedure Test_Build_Command_Route_Audit_Covers_Executor_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Test,
         Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "test harness route must target the concrete internal build command and then use Executor structured entrypoint");
   end Test_Build_Command_Route_Audit_Covers_Executor_Boundary;

   procedure Test_Build_Command_Route_Audit_Rejects_Bypass_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route_Failure
        (Audit,
         Editor.Command_Route_Audit.Route_From_Feature_Panel,
         Editor.Command_Route_Audit.Route_Bypassed_Executor,
         Expected => Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
         Actual   => Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
         Message  => "build command-like route must not bypass Executor availability, consent, preflight, or Diagnostics ingestion validation");
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
              "route audit must classify build command bypass attempts");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Command_Route_Audit.Last_Failure_Message (Audit),
                 "BYPASSED_EXECUTOR") > 0,
              "route audit must report executor-boundary bypass failures");
   end Test_Build_Command_Route_Audit_Rejects_Bypass_Routes;

   procedure Test_Build_Command_Classification_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            if Editor.Commands.Is_Public_Build_Command (Id) then
               Assert (Ada.Strings.Fixed.Index
                         (Editor.Commands.Stable_Command_Name (Id), "build.") = 1,
                       "public build commands must stay under the build namespace");
               Assert (not Editor.Commands.Is_Internal_Build_Test_Seam_Command (Id),
                       "internal test seams must not be public build commands");
            end if;
         end;
      end loop;
      Assert (Editor.Commands.Is_Internal_Build_Test_Seam_Command
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "user opt-in test seam must be classified as internal build test seam");
      Assert (not Editor.Commands.Is_Internal_Build_Test_Seam_Command
                (Editor.Commands.Command_Save_File),
              "non-build commands must not be classified as internal build test seams");
   end Test_Build_Command_Classification_Helpers;

   procedure Test_Command_Surface_Public_Public_Build_Id_Remains_Absent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
      Found : Boolean;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Names.Length = 1,
              "public build contract exposes only build.run");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("build.run", Found);
      Assert (Found and then Id = Editor.Commands.Command_Build_Run,
              "build.run must resolve to the guarded public command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("build.project", Found);
      Assert (not Found,
              "reserved build.project alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("compile.project", Found);
      Assert (not Found,
              "reserved compile.project alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("diagnostics.run-build", Found);
      Assert (not Found,
              "reserved diagnostics.run-build alias must remain absent");
   end Test_Command_Surface_Public_Public_Build_Id_Remains_Absent;

   procedure Test_Command_Surface_Near_Miss_Public_Build_Id_Remains_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Test_Seam_Id : constant String :=
        Editor.Commands.Stable_Command_Name
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Assert (Test_Seam_Id = "build.run-user-opt-in-test-seam",
              "internal test seam near-miss id must remain stable");
      Assert (not Is_Public_Build_Surface_Id (Test_Seam_Id),
              "internal test seam must not canonicalize to a public build id");
      Assert (not Editor.Commands.Is_Bindable_Command
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "internal build test seam must remain non-bindable");
      Assert (not Editor.Commands.Visible_In_Command_Palette
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "internal build test seam must remain excluded from normal palette");
   end Test_Command_Surface_Near_Miss_Public_Build_Id_Remains_Safe;

   procedure Test_Command_Surface_Public_Build_Guardrail_Manifest_Remains_Healthy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Review : Editor.Command_Surface.Command_Surface_Review;
      Manifest : Public_Build_Guardrail_Regression_Manifest;
   begin
      Editor.State.Init (S);
      Review := Editor.Command_Surface.Review_Command_Surface (S);
      Manifest := Build_Public_Build_Guardrail_Regression_Manifest (S);
      Assert (Review.Public_Build_Guardrail_Intact,
              "command surface review must keep public-build manifest as a healthy sentinel");
      Assert (Manifest.Manifest_Healthy,
              "public-build regression manifest remains healthy");
   end Test_Command_Surface_Public_Build_Guardrail_Manifest_Remains_Healthy;

   procedure Test_Lifecycle_Hints_Do_Not_Mention_Build
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id           => 2,
         Display_Name => To_Unbounded_String ("other.adb"),
         Is_Dirty     => False,
         Is_Active    => False,
         others       => <>);
      Text : Unbounded_String;
   begin
      Editor.State.Init (S);
      Text := To_Unbounded_String
        (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary) & " " &
         Editor.Lifecycle_Guidance.Status_Bar_Hint (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "build.run") = 0,
              "lifecycle affordance hints must not expose public build command names");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), ".gpr") = 0,
              "lifecycle affordance hints must not mention project-file probing");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "alire.toml") = 0,
              "lifecycle affordance hints must not mention Alire probing");
   end Test_Lifecycle_Hints_Do_Not_Mention_Build;

   procedure Test_Build_Run_Public_Descriptor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Build_Run);
   begin
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Build_Run) = "build.run",
              "build.run stable command name is registered");
      Assert (Editor.Commands.Is_Public_Build_Command
                (Editor.Commands.Command_Build_Run),
              "build.run is classified as public build command");
      Assert (D.Visibility = Editor.Commands.Palette_Command,
              "build.run is a public descriptor-owned palette command");
      Assert (D.Category = Editor.Commands.Project_Category,
              "build.run remains in the existing Project command category");
      Assert (not D.Bindable,
              "build.run has no default bindability while guarded");
      Assert (Editor.Build_Command.Assert_Build_Run_Descriptor_Stable,
              "build.run descriptor has no shell/cwd/request payload");
   end Test_Build_Run_Public_Descriptor;

   procedure Test_Build_Run_Readiness_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Root : constant String := Editor.Test_Temp.Base & "/editor_build_run_readiness";
      Gpr_Path : constant String := Root & "/demo.gpr";
      Project_Result : constant Editor.Project.Project_Open_Result :=
        (Status => Editor.Project.Project_Open_Ok,
         Root_Path => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String ("editor_build_run_readiness"),
         Error_Text => Null_Unbounded_String);
      Candidate : constant Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate
          (Root, "demo.gpr");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;

      procedure Prepare_Candidate_File is
         F : Ada.Text_IO.File_Type;
      begin
         if not Ada.Directories.Exists (Root) then
            Ada.Directories.Create_Directory (Root);
         end if;
         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Gpr_Path);
         Ada.Text_IO.Put_Line (F, "project Demo is end Demo;");
         Ada.Text_IO.Close (F);
      end Prepare_Candidate_File;

      procedure Cleanup_Candidate_File is
      begin
         if Ada.Directories.Exists (Gpr_Path) then
            Ada.Directories.Delete_File (Gpr_Path);
         end if;
         if Ada.Directories.Exists (Root) then
            Ada.Directories.Delete_Directory (Root);
         end if;
      exception
         when others =>
            null;
      end Cleanup_Candidate_File;
   begin
      Cleanup_Candidate_File;
      Prepare_Candidate_File;
      Editor.State.Init (S);
      Editor.Project.Apply_Open_Result (S.Project, Project_Result);
      Assert (Editor.Build_Command.Build_Run_Readiness (S) =
              Editor.Build_Command.Build_Run_Readiness_Request_Incomplete,
              "hidden build UI reports incomplete public build request");

      Editor.Build_UI.Show (S.Build_UI);
      Assert (Editor.Build_Command.Build_Run_Readiness (S) =
              Editor.Build_Command.Build_Run_Readiness_No_Candidate_Selected,
              "visible build UI with no selected candidate reports the specific preflight reason");

      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates
        (S.Build_UI, Candidates, "refresh succeeded: 1 candidates");
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI, To_String (Candidate.Candidate_Id));
      declare
         Status : constant Editor.Build_Command.Build_Run_Readiness_Status :=
           Editor.Build_Command.Build_Run_Readiness (S);
      begin
         Assert (Status in Editor.Build_Command.Build_Run_Readiness_Consent_Required
                         | Editor.Build_Command.Build_Run_Readiness_Execution_Backend_Disabled
                         | Editor.Build_Command.Build_Run_Readiness_Ready,
                 "build.run reports a post-candidate readiness gate: " &
                 Editor.Build_Command.Build_Run_Readiness_Status'Image (Status));
      end;

      Editor.Build_UI.Acknowledge_Consent (S.Build_UI);
      Assert (Editor.Build_Command.Validate_Build_Run_Invocation (S) =
              Editor.Build_Command.Build_Run_Readiness_Execution_Backend_Disabled,
              "valid structured request still refuses disabled backend");
      Cleanup_Candidate_File;
   exception
      when others =>
         Cleanup_Candidate_File;
         raise;
   end Test_Build_Run_Readiness_Reasons;

   procedure Test_Build_Run_Coherent_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Assert (Editor.Build_Command.Assert_Public_Build_Command_Registration_Coherent (S),
              "build.run public registration, guarded Executor route, palette/keybinding boundaries and persistence exclusions are coherent");
   end Test_Build_Run_Coherent_Audit;

   overriding procedure Register_Tests
     (T : in out Build_Surface_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_User_Opt_In_Build_Command_Is_Internal'Access,
         "User Opt-In Build Command Is Internal");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_User_Opt_In_Build_Command_Has_No_Default_Keybinding'Access,
         "User Opt-In Build Command Has No Default Keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_User_Opt_In_Build_Command_Bare_Route_Is_Unavailable'Access,
         "User Opt-In Build Command Bare Route Is Unavailable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_User_Opt_In_Build_Command_Structured_Route_Reaches_Executor'Access,
         "User Opt-In Build Command Structured Route Reaches Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Surface_Has_No_Public_Run_Command'Access,
         "Build Command Surface Has No Public Run Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Route_Audit_Covers_Executor_Boundary'Access,
         "Build Command Route Audit Covers Executor Boundary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Route_Audit_Rejects_Bypass_Routes'Access,
         "Build Command Route Audit Rejects Bypass Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Command_Classification_Helpers'Access,
         "Build Command Classification Helpers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Public_Public_Build_Id_Remains_Absent'Access,
         "Command Surface Public Public Build Id Remains Absent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Near_Miss_Public_Build_Id_Remains_Safe'Access,
         "Command Surface Near Miss Public Build Id Remains Safe");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Surface_Public_Build_Guardrail_Manifest_Remains_Healthy'Access,
         "Command Surface Public Build Guardrail Manifest Remains Healthy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Lifecycle_Hints_Do_Not_Mention_Build'Access,
         "Lifecycle Hints Do Not Mention Build");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Run_Public_Descriptor'Access,
         "Build Run Public Descriptor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Run_Readiness_Reasons'Access,
         "Build Run Readiness Reasons");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Build_Run_Coherent_Audit'Access,
         "Build Run Coherent Audit");
   end Register_Tests;

end Editor.Command_Surface.Build_Surface_Tests;
