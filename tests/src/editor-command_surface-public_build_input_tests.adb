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

package body Editor.Command_Surface.Public_Build_Input_Tests is

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
     (T : Public_Build_Input_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Public_Build_Input.Tests");
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

   procedure Test_Public_Build_Consent_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Status : Editor.External_Producers.Public_Build_Consent_Validation_Status;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Status := Editor.External_Producers.Validate_Public_Build_Consent
        (Valid_Test_Consent);
      Assert (Status = Editor.External_Producers.Public_Build_Consent_Valid_For_Internal_Test,
              "valid test-context consent must validate without side effects");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "consent validation must not post messages");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "consent validation must not switch feature focus");
   end Test_Public_Build_Consent_Validation_Is_Side_Effect_Free;

   procedure Test_Public_Build_Consent_Rejects_Missing_Acknowledgements
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Consent : Public_Build_Consent_Model := Valid_Test_Consent;
   begin
      Consent.Source := Public_Build_Consent_None;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_None,
              "missing consent source must reject deterministically");

      Consent := Valid_Test_Consent;
      Consent.User_Acknowledged_Execution := False;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_Missing_Execution_Acknowledgement,
              "missing execution acknowledgement must reject deterministically");

      Consent := Valid_Test_Consent;
      Consent.User_Acknowledged_No_Shell := False;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement,
              "missing no-shell acknowledgement must reject deterministically");

      Consent := Valid_Test_Consent;
      Consent.User_Acknowledged_External_Process := False;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_Missing_External_Process_Acknowledgement,
              "missing external-process acknowledgement must reject deterministically");

      Consent := Valid_Test_Consent;
      Consent.User_Acknowledged_Diagnostics_Output := False;
      Assert (Validate_Public_Build_Consent (Consent) =
              Public_Build_Consent_Rejected_Missing_Diagnostics_Acknowledgement,
              "missing diagnostics acknowledgement must reject deterministically");
   end Test_Public_Build_Consent_Rejects_Missing_Acknowledgements;

   procedure Test_Public_Build_Consent_Test_Context_Internal_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Validate_Public_Build_Consent (Valid_Test_Consent) =
              Public_Build_Consent_Valid_For_Internal_Test,
              "test-context consent must validate only for internal/test conversion");
      Assert (Classify_Public_Build_Consent_Safety (Valid_Test_Consent) =
              Public_Build_Input_Valid_For_Internal_Test,
              "test-context consent must classify as internal-test-only");
      Assert (Build_Execution_Consent_From_Public_Model (Valid_Test_Consent) =
              Build_Consent_User_Confirmed,
              "test-context consent may derive explicit user-confirmed consent for internal/test conversion");
   end Test_Public_Build_Consent_Test_Context_Internal_Only;

   procedure Test_Public_Build_Consent_User_Form_Not_Publicly_Exposable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Validate_Public_Build_Consent (Valid_User_Form_Consent) =
              Public_Build_Consent_Valid_But_Not_Public_UX,
              "user-form-shaped consent must validate structurally but not as public UX");
      Assert (Classify_Public_Build_Consent_Safety (Valid_User_Form_Consent) =
              Public_Build_Input_Valid_But_Not_Publicly_Exposable,
              "user-form-shaped consent must not be publicly exposable");
      Assert (Build_Execution_Consent_From_Public_Model (Valid_User_Form_Consent) =
              Build_Consent_User_Confirmed,
              "acknowledged user-form consent must convert to execution consent");
   end Test_Public_Build_Consent_User_Form_Not_Publicly_Exposable;

   procedure Test_Public_Build_Consent_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Build_Public_Build_Consent_Feedback
                (Public_Build_Consent_Rejected_None) =
              "Build: execution consent required",
              "missing consent feedback must be deterministic");
      Assert (Build_Public_Build_Consent_Feedback
                (Public_Build_Consent_Rejected_Missing_No_Shell_Acknowledgement) =
              "Build: no-shell acknowledgement required",
              "no-shell feedback must be deterministic");
      Assert (Build_Public_Build_Consent_Feedback
                (Public_Build_Consent_Valid_But_Not_Public_UX) =
              "Build: public consent UX not ready",
              "user-form consent feedback must not expose internals");
   end Test_Public_Build_Consent_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Input_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Status : Editor.External_Producers.Public_Build_Input_Validation_Status;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Status := Editor.External_Producers.Validate_Public_Build_Command_Input
        (Valid_Public_Input);
      Assert (Status = Editor.External_Producers.Public_Build_Input_Valid,
              "valid public input DTO must validate without side effects");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "public input validation must not post messages");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "public input validation must not switch feature focus");
   end Test_Public_Build_Input_Validation_Is_Side_Effect_Free;

   procedure Test_Public_Build_Input_Rejects_Invalid_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
   begin
      Input.Source := Public_Build_Input_None;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_No_Input,
              "public build input must reject no input source");

      Input := Valid_Public_Input;
      Input.Tool := No_Build_Tool;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_No_Tool,
              "public build input must reject missing tool");

      Input := Valid_Public_Input;
      Input.Tool := Custom_Build_Tool;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Custom_Tool,
              "public build input must reject custom tool");

      Input := Valid_Public_Input;
      Input.Program_Label := Null_Unbounded_String;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Program,
              "public build input must reject missing program label");

      Input := Valid_Public_Input;
      Input.Consent := Build_Consent_Not_Provided;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Consent,
              "public build input must reject missing consent");

      Input := Valid_Public_Input;
      Input.Consent_Model.User_Acknowledged_Execution := False;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Consent,
              "public build input must reject partial structured consent");

      Input := Valid_Public_Input;
      Input.Working_Context := Build_Unsupported_Working_Context;
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsupported_Working_Context,
              "public build input must reject unsupported working context");

      Input := Valid_Public_Input;
      Input.Arguments := Empty_Process_Arguments;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Opaque_Arguments,
              "public build input must require structured argv tokens");

      Input := Valid_Public_Input;
      Input.Arguments := Build_Process_Argument_Vector ("");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Opaque_Arguments,
              "empty helper arguments must not synthesize argv");

      Input := Valid_Public_Input;
      Input.Arguments := Build_Process_Argument_Vector ("-q", "", "--keep-going");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Empty_Argument,
              "public build input must reject empty structured argv entries");

      Input := Valid_Public_Input;
      Input.Program_Label := To_Unbounded_String ("gprbuild; rm -rf tmp");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Shell,
              "public build input must reject shell syntax in program labels");
   end Test_Public_Build_Input_Rejects_Invalid_Forms;

   procedure Test_Public_Build_Input_Validates_Structured_Argv
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Status : constant Editor.External_Producers.Public_Build_Input_Validation_Status :=
        Editor.External_Producers.Validate_Public_Build_Command_Input
          (Valid_Public_Input);
   begin
      Assert (Status = Editor.External_Producers.Public_Build_Input_Valid,
              "structured public build argv should validate in the test context model");
   end Test_Public_Build_Input_Validates_Structured_Argv;

   procedure Test_Public_Build_Input_Safety_Classification
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      No_Input : Public_Build_Command_Input := Valid_Public_Input;
      User_Form : Public_Build_Command_Input := Valid_Public_Input;
   begin
      No_Input.Source := Public_Build_Input_None;
      User_Form.Source := Public_Build_Input_User_Form;
      User_Form.Consent := Build_Consent_Not_Provided;
      User_Form.Consent_Model := Valid_User_Form_Consent;
      User_Form.Working_Context := Build_Explicit_Label_Working_Context ("workspace label");
      User_Form.Working_Context_Model := Valid_User_Form_Working_Context;

      Assert (Classify_Public_Build_Input_Safety (No_Input) =
              Public_Build_Input_Not_Valid,
              "no public input must classify as not valid");
      Assert (Classify_Public_Build_Input_Safety (Valid_Public_Input) =
              Public_Build_Input_Valid_For_Internal_Test,
              "valid test-context input must be internal-test-only");
      Assert (Classify_Public_Build_Input_Safety (User_Form) =
              Public_Build_Input_Valid_But_Not_Publicly_Exposable,
              "structural user-form input remains gated until implicit build source policy exists");
   end Test_Public_Build_Input_Safety_Classification;

   procedure Test_Public_Build_Input_No_State_Publicly_Exposable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
   begin
      Assert (Classify_Public_Build_Input_Safety (Input) /=
              Public_Build_Input_Publicly_Exposable,
              "test-context input must not be public-exposable");

      Input.Source := Public_Build_Input_User_Form;
      Input.Consent := Build_Consent_Not_Provided;
      Input.Consent_Model := Valid_User_Form_Consent;
      Input.Working_Context := Build_Explicit_Label_Working_Context ("workspace label");
      Input.Working_Context_Model := Valid_User_Form_Working_Context;
      Assert (Classify_Public_Build_Input_Safety (Input) /=
              Public_Build_Input_Publicly_Exposable,
              "user-form input must not be public-exposable in ");

      Input.Source := Public_Build_Input_None;
      Input.Working_Context := Build_Unsupported_Working_Context;
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Assert (Classify_Public_Build_Input_Safety (Input) /=
              Public_Build_Input_Publicly_Exposable,
              "invalid input must not be public-exposable");
   end Test_Public_Build_Input_No_State_Publicly_Exposable;

   procedure Test_Public_Build_Input_Working_Context_Guardrails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
   begin
      Input.Working_Context := Build_Unsupported_Working_Context;
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_None,
         Label  => Null_Unbounded_String,
         User_Acknowledged_Context => False);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsupported_Working_Context,
              "unsupported working context must reject validation");

      Input := Valid_Public_Input;
      Input.Working_Context := Build_Explicit_Label_Working_Context ("/tmp/project");
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_User_Form_Label,
         Label  => To_Unbounded_String ("/tmp/project"),
         User_Acknowledged_Context => True);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsafe_Working_Context,
              "explicit label context must not validate for execution");
      declare
         Request : constant Build_Run_Request :=
           Build_User_Opt_In_Request_From_Public_Input (Input);
      begin
         Assert (Request.Provenance = Build_Request_Unknown,
                 "explicit label context must not convert to executable request");
      end;

      Input := Valid_Public_Input;
      Input.Source := Public_Build_Input_User_Form;
      Input.Consent := Build_Consent_User_Confirmed;
      Input.Consent_Model := Valid_User_Form_Consent;
      Input.Working_Context_Model := Valid_Test_Working_Context;
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsupported_Working_Context,
              "test working context must be accepted only for test source");

      Input := Valid_Public_Input;
      Input.Working_Context := Build_Explicit_Label_Working_Context ("project:root");
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_Project_Derived,
         Label  => To_Unbounded_String ("project:root"),
         User_Acknowledged_Context => True);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsafe_Working_Context,
              "project-derived working labels must be rejected");
   end Test_Public_Build_Input_Working_Context_Guardrails;

   procedure Test_Public_Build_Input_Program_Label_Guardrails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
   begin
      Input.Program_Label := To_Unbounded_String ("   ");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Program,
              "blank-only program label must be rejected");

      Input.Program_Label := To_Unbounded_String ("bin/gprbuild");
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Valid,
              "path-like program labels remain metadata labels, not resolved paths");
   end Test_Public_Build_Input_Program_Label_Guardrails;

   procedure Test_Public_Build_Input_Argument_Guardrails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Arguments := Build_Process_Argument_Vector ("-gnat2022", "file name.adb");
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "whitespace argv token must remain structured and valid");
      Assert (To_String (Request.Structured_Arguments.Element (1)) = "file name.adb",
              "public input conversion must not split whitespace arguments");

      Input.Arguments := Build_Process_Argument_Vector ("""quoted arg""");
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (To_String (Request.Structured_Arguments.Element (0)) = """quoted arg""",
              "public input conversion must not parse quoted arguments");

      Input.Arguments := Build_Process_Argument_Vector ("-q; rm -rf tmp");
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "shell metacharacters in structured argv must remain inert text");
      Assert (To_String (Request.Structured_Arguments.Element (0)) = "-q; rm -rf tmp",
              "structured argv shell metacharacters must not be interpreted");

      Input.Arguments := Build_Process_Argument_Vector ("-q" & Character'Val (10));
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Control_Argument,
              "control-character argv entries must be rejected");
   end Test_Public_Build_Input_Argument_Guardrails;

   procedure Test_Public_Build_Input_Conversion_Consistency_Valid_Test_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : constant Public_Build_Command_Input := Valid_Public_Input;
      Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input (Input);
   begin
      Assert_Public_Build_Input_Conversion_Consistent (Input, Request);
   end Test_Public_Build_Input_Conversion_Consistency_Valid_Test_Context;

   procedure Test_Public_Build_Input_Conversion_Requires_Valid_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Source := Public_Build_Input_None;
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Request.Provenance = Build_Request_Unknown,
              "invalid public input must convert only to inert unknown provenance");
      Assert (Validate_Build_Run_Request_Status (Request) /= Build_Request_Valid,
              "invalid public input must not become an executable build request");
   end Test_Public_Build_Input_Conversion_Requires_Valid_Input;

   procedure Test_Public_Build_Input_Conversion_Rejects_Invalid_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Consent_Model.User_Acknowledged_External_Process := False;
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Missing_Consent,
              "partial consent model must reject public input validation");
      Assert (Request.Provenance = Build_Request_Unknown,
              "invalid consent must not convert to user-opt-in provenance");
   end Test_Public_Build_Input_Conversion_Rejects_Invalid_Consent;

   procedure Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Consent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Consent_Model := Valid_User_Form_Consent;
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Build_Execution_Consent_From_Public_Model (Input.Consent_Model) =
              Build_Consent_User_Confirmed,
              "acknowledged user-form consent converts to execution consent");
      Assert (Request.Provenance = Build_Request_Unknown,
              "non-public consent model does not convert the full request");
   end Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Consent;

   procedure Test_Public_Build_Input_Conversion_Uses_User_Opt_In_Provenance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input
          (Valid_Public_Input);
   begin
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "valid public input conversion must preserve user-opt-in provenance");
      Assert (Process_Argument_Count (Request.Structured_Arguments) = 1,
              "valid public input conversion must preserve structured argv");
      Assert (To_String (Request.Arguments)'Length = 0,
              "valid public input conversion must not carry opaque argument text");
   end Test_Public_Build_Input_Conversion_Uses_User_Opt_In_Provenance;

   procedure Test_Public_Build_Input_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Build_Public_Build_Input_Feedback
                (Public_Build_Input_Rejected_No_Input) =
              "Build: input required",
              "no-input feedback must be compact and deterministic");
      Assert (Build_Public_Build_Input_Feedback
                (Public_Build_Input_Rejected_Custom_Tool) =
              "Build: custom build tool not supported",
              "custom-tool feedback must not expose command internals");
      Assert (Build_Public_Build_Input_Feedback
                (Public_Build_Input_Rejected_Shell) =
              "Build: shell execution disabled",
              "shell feedback must be compact and deterministic");
   end Test_Public_Build_Input_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Input_Does_Not_Register_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Request : constant Editor.External_Producers.Build_Run_Request :=
        Editor.External_Producers.Build_User_Opt_In_Request_From_Public_Input
          (Valid_Public_Input);
      pragma Unreferenced (Request);
   begin
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
   end Test_Public_Build_Input_Does_Not_Register_Public_Command;

   procedure Test_Public_Build_Working_Context_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Status : Editor.External_Producers.Public_Build_Working_Context_Validation_Status;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Status := Editor.External_Producers.Validate_Public_Build_Working_Context
        (Valid_Test_Working_Context);
      Assert (Status = Editor.External_Producers.Public_Build_Working_Context_Valid_For_Internal_Test,
              "test working context must validate without side effects");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "working-context validation must not post messages");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "working-context validation must not switch feature focus");
   end Test_Public_Build_Working_Context_Validation_Is_Side_Effect_Free;

   procedure Test_Public_Build_Working_Context_Rejects_Invalid_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Context : Public_Build_Working_Context_Model;
   begin
      Context := (Source => Public_Build_Working_Context_None,
                  Label  => Null_Unbounded_String,
                  User_Acknowledged_Context => False);
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_None,
              "missing working context must reject deterministically");

      Context := (Source => Public_Build_Working_Context_Project_Derived,
                  Label  => To_Unbounded_String ("project:root"),
                  User_Acknowledged_Context => True);
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Project_Derived,
              "project-derived working context must reject deterministically");

      Context := (Source => Public_Build_Working_Context_User_Form_Label,
                  Label  => Null_Unbounded_String,
                  User_Acknowledged_Context => True);
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Missing_Label,
              "missing user-form working label must reject deterministically");

      Context := Valid_User_Form_Working_Context;
      Context.User_Acknowledged_Context := False;
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Missing_Acknowledgement,
              "missing working-context acknowledgement must reject deterministically");

      Context := Valid_User_Form_Working_Context;
      Context.Label := To_Unbounded_String ("bad" & Character'Val (10));
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Unsafe_Label,
              "control-character working labels must reject deterministically");

      Context := Valid_User_Form_Working_Context;
      Context.Label := To_Unbounded_String ("/tmp/project");
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Rejected_Unsafe_Label,
              "path-like working labels must reject until safe directory UX exists");
   end Test_Public_Build_Working_Context_Rejects_Invalid_Forms;

   procedure Test_Public_Build_Working_Context_Test_Context_Internal_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Context : constant Public_Build_Working_Context_Model :=
        Valid_Test_Working_Context;
      Converted : constant Editor.External_Producers.Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Context);
   begin
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Valid_For_Internal_Test,
              "test working context must validate for internal/test conversion only");
      Assert (Classify_Public_Build_Working_Context_Safety (Context) =
              Public_Build_Input_Valid_For_Internal_Test,
              "test working context must classify as internal-test-only");
      Assert (Converted.Kind = Build_Working_Context_Inherited_Test_Context,
              "test working context must convert only to inherited test context");
      Assert (Assert_Public_Build_Working_Context_Conversion_Consistent
                (Context, Converted),
              "test working-context conversion must be consistent");
   end Test_Public_Build_Working_Context_Test_Context_Internal_Only;

   procedure Test_Public_Build_Working_Context_User_Form_Not_Publicly_Exposable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Context : constant Public_Build_Working_Context_Model :=
        Valid_User_Form_Working_Context;
      Converted : constant Editor.External_Producers.Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Context);
   begin
      Assert (Validate_Public_Build_Working_Context (Context) =
              Public_Build_Working_Context_Valid_But_Not_Public_UX,
              "user-form working context must remain structurally valid but not UX-ready");
      Assert (Classify_Public_Build_Working_Context_Safety (Context) =
              Public_Build_Input_Valid_But_Not_Publicly_Exposable,
              "user-form working context must not classify as publicly exposable");
      Assert (Classify_Public_Build_Working_Context_Safety (Context) /=
              Public_Build_Input_Publicly_Exposable,
              "no working context may be publicly exposable in ");
      Assert (Converted.Kind = Build_Working_Context_Explicit_Label,
              "safe user-form working context converts to an explicit guarded label");
   end Test_Public_Build_Working_Context_User_Form_Not_Publicly_Exposable;

   procedure Test_Public_Build_Input_Conversion_Rejects_Project_Derived_Working_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Working_Context_Model :=
        (Source => Public_Build_Working_Context_Project_Derived,
         Label  => To_Unbounded_String ("project:root"),
         User_Acknowledged_Context => True);
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Validate_Public_Build_Command_Input (Input) =
              Public_Build_Input_Rejected_Unsafe_Working_Context,
              "project-derived public working context must reject input validation");
      Assert (Request.Provenance = Build_Request_Unknown,
              "project-derived working context must not convert to user-opt-in provenance");
   end Test_Public_Build_Input_Conversion_Rejects_Project_Derived_Working_Context;

   procedure Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Working_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : Public_Build_Command_Input := Valid_Public_Input;
      Request : Build_Run_Request;
   begin
      Input.Working_Context_Model := Valid_User_Form_Working_Context;
      Request := Build_User_Opt_In_Request_From_Public_Input (Input);
      Assert (Build_Working_Context_From_Public_Model
                (Input.Working_Context_Model).Kind = Build_Working_Context_Explicit_Label,
              "safe user-form working context converts to an explicit guarded label");
      Assert (Request.Provenance = Build_Request_Unknown,
              "non-public working context model does not convert the full request");
   end Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Working_Context;

   procedure Test_Public_Build_Input_Conversion_Valid_Test_Working_Context_Uses_Inherited_Test_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Input : constant Public_Build_Command_Input := Valid_Public_Input;
      Converted : constant Editor.External_Producers.Build_Working_Context :=
        Build_Working_Context_From_Public_Model (Input.Working_Context_Model);
      Request : constant Build_Run_Request :=
        Build_User_Opt_In_Request_From_Public_Input (Input);
   begin
      Assert (Converted.Kind = Build_Working_Context_Inherited_Test_Context,
              "valid test public working context must convert to inherited test context");
      Assert (To_String (Converted.Label)'Length = 0,
              "inherited test context conversion must not preserve a filesystem label");
      Assert (Request.Provenance = Build_Request_From_User_Opt_In,
              "valid test input with valid working context may convert internally");
   end Test_Public_Build_Input_Conversion_Valid_Test_Working_Context_Uses_Inherited_Test_Context;

   procedure Test_Public_Build_Working_Context_Feedback_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Build_Public_Build_Working_Context_Feedback
                (Public_Build_Working_Context_Rejected_None) =
              "Build: working context required",
              "missing context feedback must be stable");
      Assert (Build_Public_Build_Working_Context_Feedback
                (Public_Build_Working_Context_Rejected_Project_Derived) =
              "Build: project working context not supported",
              "project-derived context feedback must be stable");
      Assert (Build_Public_Build_Working_Context_Feedback
                (Public_Build_Working_Context_Valid_But_Not_Public_UX) =
              "Build: public working directory UX not ready",
              "user-form context feedback must report missing UX");
   end Test_Public_Build_Working_Context_Feedback_Is_Deterministic;

   procedure Test_Public_Build_Working_Context_Model_Does_Not_Register_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Status : constant Editor.External_Producers.Public_Build_Working_Context_Validation_Status :=
        Editor.External_Producers.Validate_Public_Build_Working_Context
          (Valid_User_Form_Working_Context);
      pragma Unreferenced (Status);
   begin
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
   end Test_Public_Build_Working_Context_Model_Does_Not_Register_Public_Command;

   overriding procedure Register_Tests
     (T : in out Public_Build_Input_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_Validation_Is_Side_Effect_Free'Access,
         "Public Build Consent Validation Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_Rejects_Missing_Acknowledgements'Access,
         "Public Build Consent Rejects Missing Acknowledgements");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_Test_Context_Internal_Only'Access,
         "Public Build Consent Test Context Internal Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_User_Form_Not_Publicly_Exposable'Access,
         "Public Build Consent User Form Not Publicly Exposable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Consent_Feedback_Is_Deterministic'Access,
         "Public Build Consent Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Validation_Is_Side_Effect_Free'Access,
         "Public Build Input Validation Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Rejects_Invalid_Forms'Access,
         "Public Build Input Rejects Invalid Forms");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Validates_Structured_Argv'Access,
         "Public Build Input Validates Structured Argv");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Safety_Classification'Access,
         "Public Build Input Safety Classification");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_No_State_Publicly_Exposable'Access,
         "Public Build Input No State Publicly Exposable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Working_Context_Guardrails'Access,
         "Public Build Input Working Context Guardrails");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Program_Label_Guardrails'Access,
         "Public Build Input Program Label Guardrails");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Argument_Guardrails'Access,
         "Public Build Input Argument Guardrails");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Consistency_Valid_Test_Context'Access,
         "Public Build Input Conversion Consistency Valid Test Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Requires_Valid_Input'Access,
         "Public Build Input Conversion Requires Valid Input");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Rejects_Invalid_Consent'Access,
         "Public Build Input Conversion Rejects Invalid Consent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Consent'Access,
         "Public Build Input Conversion Does Not Silently Upgrade Consent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Uses_User_Opt_In_Provenance'Access,
         "Public Build Input Conversion Uses User Opt-In Provenance");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Feedback_Is_Deterministic'Access,
         "Public Build Input Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Does_Not_Register_Public_Command'Access,
         "Public Build Input Does Not Register Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Validation_Is_Side_Effect_Free'Access,
         "Public Build Working Context Validation Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Rejects_Invalid_Forms'Access,
         "Public Build Working Context Rejects Invalid Forms");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Test_Context_Internal_Only'Access,
         "Public Build Working Context Test Context Internal Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_User_Form_Not_Publicly_Exposable'Access,
         "Public Build Working Context User Form Not Publicly Exposable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Rejects_Project_Derived_Working_Context'Access,
         "Public Build Input Conversion Rejects Project Derived Working Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Does_Not_Silently_Upgrade_Working_Context'Access,
         "Public Build Input Conversion Does Not Silently Upgrade Working Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Input_Conversion_Valid_Test_Working_Context_Uses_Inherited_Test_Context'Access,
         "Public Build Input Conversion Valid Test Working Context Uses Inherited Test Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Feedback_Is_Deterministic'Access,
         "Public Build Working Context Feedback Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Working_Context_Model_Does_Not_Register_Public_Command'Access,
         "Public Build Working Context Model Does Not Register Public Command");
   end Register_Tests;

end Editor.Command_Surface.Public_Build_Input_Tests;
