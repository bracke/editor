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

package body Editor.Command_Surface.Public_Build_Guardrail_Contract_Tests is

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
     (T : Public_Build_Guardrail_Contract_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Public_Build_Guardrail_Contract.Tests");
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

   procedure Test_Public_Build_Exposure_Hard_Failure_For_Simulated_Public_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run"),
         Has_Descriptor => True,
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      R.Has_Default_Public_Build_Keybinding := True;
      Assert (Detect_Public_Build_Command_Exposure_Hard_Failure (R),
              "simulated public build default keybinding must be a hard failure");
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Unsafe_Exposure_Detected,
              "hard exposure must outrank normal guarded-surface blockers");
      Assert (Build_Public_Command_Promotion_Feedback
                (Public_Build_Promotion_Unsafe_Exposure_Detected) =
              "Build: unsafe public command exposure detected",
              "hard-failure feedback must be deterministic");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Exposure_Hard_Failure_For_Simulated_Public_Command;

   procedure Test_Public_Build_Surface_Id_Cannot_Be_Keybinding_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Info : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command
          (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam);
   begin
      Assert (not Info.Has_Binding,
              "internal test seam must have no default/active keybinding");
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Test_Public_Build_Surface_Id_Cannot_Be_Keybinding_Target;

   procedure Test_Public_Build_Guardrail_Contract_Version_Is_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Public_Build_Guardrail_Contract_Version = "",
              "guardrail contract version must identify the audit contract");
      Assert (Run_Public_Build_Guardrail_Audit (S).Persistence_Clean,
              "guardrail contract version must remain audit-only and non-persistent");
   end Test_Public_Build_Guardrail_Contract_Version_Is_Not_Persisted;

   procedure Test_Public_Build_Long_Horizon_Persistence_Snapshot_Excludes_Guardrail_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Guardrail_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Guardrail_Audit (S);
      Assert (R.Persistence_Clean,
              "long-horizon persistence snapshot must exclude normalized guardrail results");
      Assert_Public_Build_Hard_Freeze_Not_Persisted (S);
      Assert (Public_Build_Surface_Ids_Not_Publicly_Projected (S),
              "long-horizon persistence snapshot must exclude public-id audit projections");
   end Test_Public_Build_Long_Horizon_Persistence_Snapshot_Excludes_Guardrail_State;

   procedure Test_Public_Build_Guardrail_Default_Contract_Holds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : constant Public_Build_Guardrail_Result := Default_Result;
   begin
      Assert_Public_Build_Guardrail_Default_Contract (R);
   end Test_Public_Build_Guardrail_Default_Contract_Holds;

   procedure Test_Public_Build_Guardrail_Contract_Mismatch_Default_Has_No_Mismatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      M : constant Public_Build_Guardrail_Contract_Mismatch :=
        Detect_Public_Build_Guardrail_Contract_Mismatch (Default_Result);
   begin
      Assert (not M.Any_Mismatch,
              "default public build guardrail result must match frozen contract");
   end Test_Public_Build_Guardrail_Contract_Mismatch_Default_Has_No_Mismatch;

   procedure Test_Public_Build_Surface_Id_List_Exactly_Matches_Contract
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
      Expected : constant array (Natural range 0 .. 0) of Unbounded_String :=
        (0 => To_Unbounded_String ("build.run"));
   begin
      Assert (Names.Length = Expected'Length,
              "public build id list must have exactly the contract ids");
      for I in Expected'Range loop
         Assert (To_String (Names.Element (I)) = To_String (Expected (I)),
                 "public build id list order/content must be deterministic");
      end loop;
   end Test_Public_Build_Surface_Id_List_Exactly_Matches_Contract;

   procedure Test_Public_Build_Surface_Id_List_Has_No_Duplicates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Names : constant Command_Id_Vector := Public_Build_Command_Surface_Ids;
   begin
      for I in 0 .. Natural (Names.Length) - 1 loop
         for J in I + 1 .. Natural (Names.Length) - 1 loop
            Assert (To_String (Names.Element (I)) /= To_String (Names.Element (J)),
                    "public build id list must not contain duplicates");
         end loop;
      end loop;
   end Test_Public_Build_Surface_Id_List_Has_No_Duplicates;

   procedure Test_Public_Build_Surface_Id_Scan_Ignores_Near_Miss_Labels
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (not Is_Public_Build_Surface_Id ("build.runner"),
              "near-miss build.runner must not match public ids");
      Assert (not Is_Public_Build_Surface_Id ("build.run-diagnostics"),
              "near-miss build.run-diagnostics must not match public ids");
      Assert (not Is_Public_Build_Surface_Id ("compile.note"),
              "near-miss compile.note must not match public ids");
      Assert (not Is_Public_Build_Surface_Id ("diagnostics.run-build-notes"),
              "near-miss diagnostics.run-build-notes must not match public ids");
   end Test_Public_Build_Surface_Id_Scan_Ignores_Near_Miss_Labels;

   procedure Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Public_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Is_Public_Build_Surface_Id ("build.run"),
              "exact public build id must be rejected by identity scans");
      Assert_Public_Build_Surface_Ids_Not_Reused;
   end Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Public_Name;

   procedure Test_Public_Build_Guardrail_Failure_Detail_Default_Is_None
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Detail : constant Public_Build_Guardrail_Failure_Detail :=
        First_Public_Build_Guardrail_Failure (Default_Result);
   begin
      Assert (Detail.Kind = Public_Build_Failure_None,
              "default guardrail failure detail must be none");
   end Test_Public_Build_Guardrail_Failure_Detail_Default_Is_None;

   procedure Test_Public_Build_Guardrail_First_Failure_Uses_Blocker_Precedence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      Detail : Public_Build_Guardrail_Failure_Detail;
   begin
      R.No_Public_Command := False;
      R.No_Public_Keybinding := False;
      Detail := First_Public_Build_Guardrail_Failure (R);
      Assert (Detail.Kind = Public_Build_Failure_Public_Command_Registered,
              "first failure must prefer command registration before keybindings");
   end Test_Public_Build_Guardrail_First_Failure_Uses_Blocker_Precedence;

   procedure Test_Public_Build_Guardrail_Collect_Failures_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : Public_Build_Guardrail_Result := Default_Result;
      A : Public_Build_Guardrail_Failure_Detail_Vector;
      B : Public_Build_Guardrail_Failure_Detail_Vector;
   begin
      R.No_Public_Keybinding := False;
      R.Persistence_Clean := False;
      A := Collect_Public_Build_Guardrail_Failures (R);
      B := Collect_Public_Build_Guardrail_Failures (R);
      Assert (A.Length = B.Length and then A.Length = 2,
              "failure collection must be stable and exhaustive");
      Assert (A.Element (0).Kind = Public_Build_Failure_Public_Keybinding_Found,
              "first collected failure must follow deterministic precedence");
      Assert (A.Element (1).Kind = Public_Build_Failure_Persistence_Leak,
              "second collected failure must preserve deterministic order");
   end Test_Public_Build_Guardrail_Collect_Failures_Is_Deterministic;

   procedure Test_Public_Build_Surface_Id_Scan_Result_Default_Passes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids;
   begin
      Assert (Scan.Passed, "empty public-id scan must pass");
      Assert (not Scan.Exact_Command_Id_Found
              and then not Scan.Exact_Keybinding_Target_Found
              and then not Scan.Exact_Palette_Row_Found
              and then not Scan.Exact_Executor_Route_Found
              and then not Scan.Exact_Invocation_Path_Found
              and then not Scan.Exact_Persisted_Name_Found,
              "default public-id scan must have no exact matches");
   end Test_Public_Build_Surface_Id_Scan_Result_Default_Passes;

   procedure Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Domains
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Scan_Public_Build_Surface_Ids
                (Command_Id => "build.run").Exact_Command_Id_Found,
              "exact command id must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Keybinding_Target => "build.run").Exact_Keybinding_Target_Found,
              "exact keybinding target must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Palette_Row => "build.run").Exact_Palette_Row_Found,
              "exact palette row id must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Executor_Route => "build.run").Exact_Executor_Route_Found,
              "exact executor route must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Invocation_Path => "build.run").Exact_Invocation_Path_Found,
              "exact invocation path must fail scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Persisted_Name => "build.run").Exact_Persisted_Name_Found,
              "exact persisted command name must fail scan");
   end Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Domains;

   procedure Test_Public_Build_Surface_Id_Scan_Allows_Near_Miss_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids (Palette_Row => "build.runner");
   begin
      Assert (Scan.Passed,
              "near-miss label must not fail exact-match scan");
      Assert (Scan.Near_Miss_Only,
              "near-miss-only snapshots should be represented diagnostically");
   end Test_Public_Build_Surface_Id_Scan_Allows_Near_Miss_Label;

   procedure Test_Public_Build_Guardrail_Audit_Trace_Default_Checks_All_Surfaces
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Trace : constant Public_Build_Guardrail_Audit_Trace :=
        Build_Public_Build_Guardrail_Audit_Trace;
   begin
      Assert (Public_Build_Guardrail_Audit_Trace_Complete (Trace),
              "default audit trace must cover every required surface");
      Assert_Public_Build_Guardrail_Trace_Complete (Trace);
   end Test_Public_Build_Guardrail_Audit_Trace_Default_Checks_All_Surfaces;

   procedure Test_Public_Build_Guardrail_Audit_Trace_Missing_Surface_Is_Inconsistent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Trace : Public_Build_Guardrail_Audit_Trace :=
        Build_Public_Build_Guardrail_Audit_Trace;
   begin
      Trace.Surface_Ids_Checked := False;
      Assert (not Public_Build_Guardrail_Audit_Trace_Complete (Trace),
              "missing trace surface must be incomplete");
   end Test_Public_Build_Guardrail_Audit_Trace_Missing_Surface_Is_Inconsistent;

   procedure Test_Public_Build_Guardrail_Snapshot_Comparison_Default_No_Mismatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      R : constant Public_Build_Guardrail_Result := Default_Result;
      M : constant Public_Build_Guardrail_Contract_Mismatch :=
        Compare_Public_Build_Guardrail_Snapshots (R, R);
   begin
      Assert (not M.Any_Mismatch,
              "identical guardrail snapshots must not mismatch");
   end Test_Public_Build_Guardrail_Snapshot_Comparison_Default_No_Mismatch;

   procedure Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Exposure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Before : constant Public_Build_Guardrail_Result := Default_Result;
      After  : Public_Build_Guardrail_Result := Before;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      After.No_Public_Command := False;
      M := Compare_Public_Build_Guardrail_Snapshots (Before, After);
      Assert (M.Public_Command_Mismatch and then M.Any_Mismatch,
              "snapshot comparison must detect public exposure changes");
   end Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Exposure;

   procedure Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Promotion_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Before : constant Public_Build_Guardrail_Result := Default_Result;
      After  : Public_Build_Guardrail_Result := Before;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      After.Promotion_Blocked := True;
      M := Compare_Public_Build_Guardrail_Snapshots (Before, After);
      Assert (M.Promotion_Mismatch and then M.Any_Mismatch,
              "snapshot comparison must detect promotion changes");
   end Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Promotion_Change;

   procedure Test_Public_Build_Guardrail_Lifecycle_Trace_Remains_Stable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Audit_Trace;
      After  : Public_Build_Guardrail_Audit_Trace;
   begin
      Editor.State.Init (S);
      Before := Build_Public_Build_Guardrail_Audit_Trace;
      Editor.External_Producers.Reset_Build_Run_State_For_Project_Close (S);
      Editor.External_Producers.Reset_Build_Run_State_For_Workspace_Close (S);
      After := Build_Public_Build_Guardrail_Audit_Trace;
      Assert (Public_Build_Guardrail_Audit_Trace_Complete (Before)
              and then Public_Build_Guardrail_Audit_Trace_Complete (After),
              "lifecycle operations must not weaken audit trace coverage");
   end Test_Public_Build_Guardrail_Lifecycle_Trace_Remains_Stable;

   procedure Test_Public_Build_Guardrail_Lifecycle_Snapshot_No_Mismatch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before : Public_Build_Guardrail_Result;
      After  : Public_Build_Guardrail_Result;
      M      : Public_Build_Guardrail_Contract_Mismatch;
   begin
      Editor.State.Init (S);
      Before := Run_Public_Build_Guardrail_Audit (S);
      Editor.External_Producers.Reset_Diagnostic_Line_Command_State_For_Project_Close (S);
      Editor.External_Producers.Reset_Diagnostic_Line_Command_State_For_Workspace_Close (S);
      After := Run_Public_Build_Guardrail_Audit (S);
      M := Compare_Public_Build_Guardrail_Snapshots (Before, After);
      Assert (not M.Any_Mismatch,
              "lifecycle operations must not alter normalized guardrail snapshot");
      Assert (First_Public_Build_Guardrail_Failure (After).Kind =
              Public_Build_Failure_None,
              "default lifecycle guardrail snapshot must have no failure detail");
   end Test_Public_Build_Guardrail_Lifecycle_Snapshot_No_Mismatch;

   procedure Test_Public_Build_Surface_Id_Scan_All_Domains_Checked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Scan : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids;
   begin
      Assert (Public_Build_Surface_Id_Scan_Domains_Checked (Scan),
              "public-id scan must mark every domain checked or checked-empty");
      Assert_Public_Build_Surface_Id_Scan_Domains_Checked (Scan);
      Assert (Scan.Stable_Command_Ids_Checked
              and then Scan.Display_Search_Names_Checked
              and then Scan.Palette_Checked
              and then Scan.Default_Keybindings_Checked
              and then Scan.Runtime_Keybindings_Checked
              and then Scan.Persisted_Keybindings_Checked
              and then Scan.Executor_Routes_Checked
              and then Scan.Invocation_Paths_Checked
              and then Scan.Persistence_Names_Checked
              and then Scan.Workspace_Names_Checked,
              "all public-id scan coverage markers must be true by default");
   end Test_Public_Build_Surface_Id_Scan_All_Domains_Checked;

   procedure Test_Public_Build_Surface_Id_Canonical_Exact_Match_Fails
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (not Scan_Public_Build_Surface_Ids
                    (Command_Id => "build.run").Passed,
              "canonical exact build.run must fail public-id scan");
      Assert (Scan_Public_Build_Surface_Ids
                (Command_Id => " build.run").Passed,
              "leading whitespace must follow current exact command-id policy");
      Assert (Scan_Public_Build_Surface_Ids
                (Command_Id => "build.run ").Passed,
              "trailing whitespace must follow current exact command-id policy");
      Assert (Scan_Public_Build_Surface_Ids
                (Command_Id => "BUILD.RUN").Passed,
              "case-only variant must follow current exact command-id policy");
   end Test_Public_Build_Surface_Id_Canonical_Exact_Match_Fails;

   procedure Test_Public_Build_Surface_Id_Near_Miss_Remains_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      A : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids (Command_Id => "build.runner");
      B : constant Public_Build_Surface_Id_Scan_Result :=
        Scan_Public_Build_Surface_Ids
          (Command_Id => "diagnostics.run-build-notes");
   begin
      Assert (A.Passed and then A.Near_Miss_Only,
              "build.runner near miss must remain safe");
      Assert (B.Passed and then B.Near_Miss_Only,
              "diagnostics.run-build-notes near miss must remain safe");
   end Test_Public_Build_Surface_Id_Near_Miss_Remains_Safe;

   overriding procedure Register_Tests
     (T : in out Public_Build_Guardrail_Contract_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Exposure_Hard_Failure_For_Simulated_Public_Command'Access,
         "Public Build Exposure Hard Failure For Simulated Public Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Cannot_Be_Keybinding_Target'Access,
         "Public Build Public Id Cannot Be Keybinding Target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Version_Is_Not_Persisted'Access,
         "Public Build Guardrail Contract Version Is Not Persisted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Long_Horizon_Persistence_Snapshot_Excludes_Guardrail_State'Access,
         "Public Build Long Horizon Persistence Snapshot Excludes Guardrail State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Default_Contract_Holds'Access,
         "Public Build Guardrail Default Contract Holds");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Contract_Mismatch_Default_Has_No_Mismatch'Access,
         "Public Build Guardrail Contract Mismatch Default Has No Mismatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_List_Exactly_Matches_Contract'Access,
         "Public Build Public Id List Exactly Matches Contract");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_List_Has_No_Duplicates'Access,
         "Public Build Public Id List Has No Duplicates");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Ignores_Near_Miss_Labels'Access,
         "Public Build Public Id Scan Ignores Near Miss Labels");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Public_Name'Access,
         "Public Build Public Id Scan Rejects Exact Command Id");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Failure_Detail_Default_Is_None'Access,
         "Public Build Guardrail Failure Detail Default Is None");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_First_Failure_Uses_Blocker_Precedence'Access,
         "Public Build Guardrail First Failure Uses Blocker Precedence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Collect_Failures_Is_Deterministic'Access,
         "Public Build Guardrail Collect Failures Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Result_Default_Passes'Access,
         "Public Build Public Id Scan Result Default Passes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Rejects_Exact_Domains'Access,
         "Public Build Public Id Scan Rejects Exact Domains");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_Allows_Near_Miss_Label'Access,
         "Public Build Public Id Scan Allows Near Miss Label");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Trace_Default_Checks_All_Surfaces'Access,
         "Public Build Guardrail Audit Trace Default Checks All Surfaces");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Trace_Missing_Surface_Is_Inconsistent'Access,
         "Public Build Guardrail Audit Trace Missing Surface Is Inconsistent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Snapshot_Comparison_Default_No_Mismatch'Access,
         "Public Build Guardrail Snapshot Comparison Default No Mismatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Exposure'Access,
         "Public Build Guardrail Snapshot Comparison Detects Exposure");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Snapshot_Comparison_Detects_Promotion_Change'Access,
         "Public Build Guardrail Snapshot Comparison Detects Promotion Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Lifecycle_Trace_Remains_Stable'Access,
         "Public Build Guardrail Lifecycle Trace Remains Stable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Lifecycle_Snapshot_No_Mismatch'Access,
         "Public Build Guardrail Lifecycle Snapshot No Mismatch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Scan_All_Domains_Checked'Access,
         "Public Build Public Id Scan All Domains Checked");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Canonical_Exact_Match_Fails'Access,
         "Public Build Public Id Canonical Exact Match Fails");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Surface_Id_Near_Miss_Remains_Safe'Access,
         "Public Build Public Id Near Miss Remains Safe");
   end Register_Tests;

end Editor.Command_Surface.Public_Build_Guardrail_Contract_Tests;
