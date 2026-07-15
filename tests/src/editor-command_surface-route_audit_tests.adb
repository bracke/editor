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

package body Editor.Command_Surface.Route_Audit_Tests is

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
     (T : Route_Audit_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Route_Audit.Tests");
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

   procedure Test_Command_Palette_Route_Audit_Rejects_Payloads
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Command_Palette_Route
        (Result                   => Audit,
         Command                  => Editor.Commands.Command_Open_Command_Palette,
         Routed_Through_Executor  => True,
         Used_Stable_Command_Name => True,
         Carried_Payload          => False);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "canonical palette route by stable command name must pass");

      Editor.Command_Route_Audit.Record_Command_Palette_Route
        (Result                   => Audit,
         Command                  => Editor.Commands.Command_Open_Command_Palette,
         Routed_Through_Executor  => True,
         Used_Stable_Command_Name => True,
         Carried_Payload          => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 1,
              "palette routes carrying row-specific payloads must fail audit");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Command_Route_Audit.Last_Failure_Message (Audit),
                 "payload") > 0,
              "payload audit failure must be user-readable");
   end Test_Command_Palette_Route_Audit_Rejects_Payloads;

   procedure Test_Command_UI_Route_Audit_Covers_Panel_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;

      procedure Check
        (Source  : Editor.Command_Route_Audit.Route_Source;
         Command : Editor.Commands.Command_Id)
      is
      begin
         Editor.Command_Route_Audit.Record_Command_UI_Route
           (Result                   => Audit,
            Source                   => Source,
            Command                  => Command,
            Dispatch_Count           => 1,
            Routed_Through_Executor  => True,
            Used_Stable_Command_Name => True,
            Availability_Checked     => True,
            Carried_Payload          => False);
      end Check;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Check (Editor.Command_Route_Audit.Route_From_Problems,
             Editor.Commands.Command_Problems_Open_Selected);
      Check (Editor.Command_Route_Audit.Route_From_Feature_Panel,
             Editor.Commands.Command_Build_Run);
      Check (Editor.Command_Route_Audit.Route_From_File_Tree,
             Editor.Commands.Command_File_Tree_Open_Selected);
      Check (Editor.Command_Route_Audit.Route_From_Search_Results,
             Editor.Commands.Command_Search_Results_Open_Selected);
      Check (Editor.Command_Route_Audit.Route_From_Command_Palette,
             Editor.Commands.Command_Accept_Quick_Open);
      Check (Editor.Command_Route_Audit.Route_From_Pending_Bar,
             Editor.Commands.Command_Retry_Pending_Transition);
      Check (Editor.Command_Route_Audit.Route_From_Recent_Project_Picker,
             Editor.Commands.Command_Open_Selected_Recent_Project);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "command-like UI route audit should accept canonical executor routes: "
              & Editor.Command_Route_Audit.Summary (Audit));
   end Test_Command_UI_Route_Audit_Covers_Panel_Actions;

   procedure Test_Command_UI_Route_Audit_Rejects_Bypass_And_Duplicate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Command_UI_Route
        (Result                   => Audit,
         Source                   => Editor.Command_Route_Audit.Route_From_Problems,
         Command                  => Editor.Commands.Command_Problems_Open_Selected,
         Dispatch_Count           => 2,
         Routed_Through_Executor  => False,
         Used_Stable_Command_Name => False,
         Availability_Checked     => False,
         Carried_Payload          => True);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 5,
              "bad command-like UI route should report duplicate, executor, stable-id, availability, and payload failures");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Command_Route_Audit.Summary (Audit),
                 "ROUTE_DISPATCHED_MORE_THAN_ONCE") > 0,
              "route audit summary should classify duplicate dispatch");
   end Test_Command_UI_Route_Audit_Rejects_Bypass_And_Duplicate;

   procedure Test_Palette_Command_Traversal_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Seen : array (Editor.Commands.Command_Id) of Boolean := (others => False);
      Id   : Editor.Commands.Command_Id;
      D    : Editor.Commands.Command_Descriptor;
   begin
      Assert
        (Editor.Commands.Palette_Command_Count =
           Natural (Editor.Commands.Palette_Commands.Length),
         "palette traversal count must match descriptor vector count");

      for I in 1 .. Editor.Commands.Palette_Command_Count loop
         Id := Editor.Commands.Palette_Command_At (I);
         D := Editor.Commands.Descriptor (Id);

         Assert
           (Editor.Commands.Visible_In_Command_Palette (Id),
            "Palette_Command_At must return only palette-visible ids");
         Assert
           (not Seen (Id),
            "Palette_Command_At must not return duplicate command ids");
         Seen (Id) := True;
         Assert
           (Length (D.Name) > 0,
            "palette-visible commands must have labels");
         Assert
           (Length (D.Description) > 0,
            "palette-visible commands must have descriptions");
         Assert
           (D.Category /= Editor.Commands.Internal_Category,
            "palette-visible commands must not use Internal category");
      end loop;

      for I in 1 .. Editor.Commands.Command_Count loop
         Id := Editor.Commands.Command_At (I);
         if not Editor.Commands.Visible_In_Command_Palette (Id) then
            Assert
              (not Seen (Id),
               "hidden commands must not appear in palette traversal");
         end if;
      end loop;
   end Test_Palette_Command_Traversal_Audit;

   procedure Test_Keybinding_Validation_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Keybindings.Keybinding_Validation_Result;
      Info   : Editor.Keybindings.Command_Keybinding_Info;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Result := Editor.Keybindings.Validate;
      Assert
        (Editor.Keybindings.Status (Result) = Editor.Keybindings.Valid_Keybindings,
         "default keybindings must validate");
      Assert
        (not Editor.Keybindings.Has_Invalid_Command_Targets (Result),
         "default keybindings must target concrete command ids");
      Assert
        (not Editor.Keybindings.Has_Duplicate_Chords (Result),
         "default keybindings must not contain duplicate chords");

      Info := Editor.Keybindings.Primary_Binding_For_Command
        (Editor.Commands.Command_Save_File);
      Assert (Info.Has_Binding, "Save File must expose its primary binding");
      Assert
        (To_String (Info.Display) = "Ctrl+S",
         "Save File primary binding must be Ctrl+S");
   end Test_Keybinding_Validation_Audit;

   procedure Test_Concrete_Command_Traversal
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Count : Natural := 0;
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.First_Concrete_Command;

      procedure Count_Command
        (Current : Editor.Commands.Command_Id)
      is
      begin
         Assert
           (Editor.Commands.Is_Concrete_Command (Current),
            "For_Each_Command must not yield No_Command");
         Count := Count + 1;
      end Count_Command;
   begin
      Assert
        (Editor.Commands.First_Concrete_Command /= Editor.Commands.No_Command,
         "first concrete command must exclude No_Command");
      Assert
        (Editor.Commands.Concrete_Command_Count = Editor.Commands.Command_Count - 1,
         "concrete command count must exclude exactly No_Command");

      while Found or else Id = Editor.Commands.First_Concrete_Command loop
         Assert
           (Editor.Commands.Is_Concrete_Command (Id),
            "Next_Command concrete walk must stay on concrete ids");
         Count := Count + 1;
         Id := Editor.Commands.Next_Command (Id, Found);
         exit when not Found;
      end loop;

      Assert
        (Count = Editor.Commands.Concrete_Command_Count,
         "Next_Command walk must cover every concrete command exactly once");

      Count := 0;
      Editor.Commands.For_Each_Command (Count_Command'Access);
      Assert
        (Count = Editor.Commands.Concrete_Command_Count,
         "For_Each_Command must cover every concrete command exactly once");
   end Test_Concrete_Command_Traversal;

   procedure Test_Command_Audit_Registry_Is_Actionable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Failures : constant Editor.Commands.Command_Audit_Failure_Vectors.Vector :=
        Editor.Commands.Audit_Command_Registry;
      Summary  : constant String := Editor.Commands.Command_Audit_Summary (Failures);
   begin
      Assert
        (Failures.Length = 0,
         "static command audit must pass: " & Summary);
   end Test_Command_Audit_Registry_Is_Actionable;

   procedure Test_Command_Descriptor_Construction_Helper
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Make_Command_Descriptor
          (Id            => Editor.Commands.Command_Save_Settings,
           Stable_Name   => "save-settings",
           Label         => "Save Settings",
           Description   => "Write global editor preferences.",
           Category      => Editor.Commands.Settings_Category,
           Visible       => True,
           Bindable      => True,
           Destructive   => False,
           Lifecycle     => False,
           Configuration => True);
   begin
      Assert (D.Id = Editor.Commands.Command_Save_Settings,
              "descriptor helper must preserve command id");
      Assert (To_String (D.Name) = "Save Settings",
              "descriptor helper must preserve explicit label");
      Assert (To_String (D.Description) = "Write global editor preferences.",
              "descriptor helper must preserve explicit description");
      Assert (D.Category = Editor.Commands.Settings_Category,
              "descriptor helper must preserve explicit category");
      Assert (D.Visibility = Editor.Commands.Palette_Command,
              "descriptor helper must use explicit visibility");
      Assert (D.Bindable and then D.Configuration,
              "descriptor helper must preserve explicit bindability/classification");
   end Test_Command_Descriptor_Construction_Helper;

   procedure Test_Route_Audit_Actionable_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Result : Editor.Command_Route_Audit.Route_Audit_Result;
      Text   : Unbounded_String;
   begin
      Editor.Command_Route_Audit.Clear (Result);
      Editor.Command_Route_Audit.Record_Route
        (Result  => Result,
         Source  => Editor.Command_Route_Audit.Route_From_Keybinding,
         Command => Editor.Commands.No_Command);
      Text := To_Unbounded_String (Editor.Command_Route_Audit.Summary (Result));

      Assert
        (Editor.Command_Route_Audit.Failure_Count (Result) = 1,
         "route audit must flag non-concrete routed command");
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (Text), "ROUTE_TARGETED_NON_CONCRETE_COMMAND") > 0,
         "route audit summary must include failure kind: " & To_String (Text));
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (Text), "ROUTE_FROM_KEYBINDING") > 0,
         "route audit summary must include route source: " & To_String (Text));

      Editor.Command_Route_Audit.Record_Route_Failure
        (Result   => Result,
         Source   => Editor.Command_Route_Audit.Route_From_Command_Palette,
         Kind     => Editor.Command_Route_Audit.Route_Dispatched_Wrong_Command,
         Expected => Editor.Commands.Command_Save_File,
         Actual   => Editor.Commands.Command_Save_All,
         Message  => "accept dispatched the wrong command id");
      Text := To_Unbounded_String
        (Editor.Command_Route_Audit.Last_Failure_Message (Result));
      Assert
        (Ada.Strings.Fixed.Index
           (To_String (Text), "COMMAND_SAVE_FILE") > 0
         and then Ada.Strings.Fixed.Index
           (To_String (Text), "COMMAND_SAVE_ALL") > 0,
         "typed route failure must identify expected and actual commands: " &
         To_String (Text));
   end Test_Route_Audit_Actionable_Failures;

   overriding procedure Register_Tests
     (T : in out Route_Audit_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Route_Audit_Rejects_Payloads'Access,
         "Command Palette Route Audit Rejects Payloads");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_UI_Route_Audit_Covers_Panel_Actions'Access,
         "Command UI Route Audit Covers Panel Actions");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_UI_Route_Audit_Rejects_Bypass_And_Duplicate'Access,
         "Command UI Route Audit Rejects Bypass And Duplicate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_Command_Traversal_Audit'Access,
         "Palette Command Traversal Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keybinding_Validation_Audit'Access,
         "Keybinding Validation Audit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Concrete_Command_Traversal'Access,
         "Concrete Command Traversal");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Audit_Registry_Is_Actionable'Access,
         "Command Audit Registry Is Actionable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Descriptor_Construction_Helper'Access,
         "Command Descriptor Construction Helper");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Route_Audit_Actionable_Failures'Access,
         "Route Audit Actionable Failures");
   end Register_Tests;

end Editor.Command_Surface.Route_Audit_Tests;
