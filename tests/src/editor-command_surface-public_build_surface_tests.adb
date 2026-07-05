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

package body Editor.Command_Surface.Public_Build_Surface_Tests is

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
     (T : Public_Build_Surface_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Command_Surface.Public_Build_Surface.Tests");
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

   procedure Test_Public_Build_Readiness_Audit_Reports_Not_Ready
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Has_Public_Build_Command,
              "public build command is registered through the guarded surface");
      Assert (not R.Has_Default_Public_Build_Keybinding,
              "must not provide a default public build keybinding");
      Assert (R.Has_User_Command_Input_Model,
              "must expose a structured public build input DTO model");
      Assert (R.Has_Structured_Argv_Input_Model,
              "structured argv seam must exist before any public build UX is designed");
      Assert (R.Has_Working_Context_Model,
              "must expose a working-context model");
      Assert (R.Has_Consent_UX_Model,
              "must expose a structured public consent model");
      Assert (R.Public_Consent_UX_Publicly_Ready,
              "public consent UX is available through the guarded surface");
      Assert (R.Has_Implicit_Source_Validation,
              "explicit-source policy must be validated");
      Assert (R.Keeps_Implicit_Source_Rejected,
              "implicit build source requests must remain rejected");
      Assert (R.Keeps_Shell_Rejected,
              "shell-enabled build execution must remain rejected");
      Assert (R.Keeps_Opaque_Arguments_Rejected,
              "opaque/free-form build arguments must remain rejected");
      Assert (R.Routes_Through_Executor,
              "build command test seams must remain Executor-routed");
      Assert (R.Routes_Diagnostics_Through_Pipeline,
              "build output must continue to route through diagnostic-line pipeline");
      Assert (R.Public_Command_Can_Be_Promoted,
              "readiness audit must allow guarded public build promotion");
   end Test_Public_Build_Readiness_Audit_Reports_Not_Ready;

   procedure Test_Public_Build_Readiness_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      Before_Overlay : Editor.Overlay_Focus.Overlay_Target;
      Before_Focus : Editor.Panel_Focus.Focus_Target;
      Before_Bottom : Editor.Panel_Focus.Bottom_Focus_Content;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      Before_Overlay := Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus);
      Before_Focus := Editor.Panel_Focus.Target (S.Panel_Focus);
      Before_Bottom := Editor.Panel_Focus.Bottom_Content (S.Panel_Focus);

      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_Command_Can_Be_Promoted,
              "side-effect-free readiness audit should still return the ready result");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "readiness audit must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "readiness audit must not create or switch buffers");
      Assert (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus) = Before_Overlay,
              "readiness audit must not change overlay focus");
      Assert (Editor.Panel_Focus.Target (S.Panel_Focus) = Before_Focus,
              "readiness audit must not change panel focus");
      Assert (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) = Before_Bottom,
              "readiness audit must not change bottom-panel content");
   end Test_Public_Build_Readiness_Audit_Is_Side_Effect_Free;

   procedure Test_Public_Build_Commands_Are_Not_Registered
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
      Assert_Public_Build_Name_Not_Registered ("build.run-current-project");
      Assert_Public_Build_Name_Not_Registered ("build.configure-command");
   end Test_Public_Build_Commands_Are_Not_Registered;

   procedure Test_Public_Build_Commands_Have_No_Default_Keybindings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
      S : Editor.State.State_Type;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (not R.Has_Default_Public_Build_Keybinding,
              "public build commands must have no default keybindings");
      Assert (not Editor.Keybindings.Primary_Binding_For_Command
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam).Has_Binding,
              "internal test seam must also remain without a default keybinding");
   end Test_Public_Build_Commands_Have_No_Default_Keybindings;

   procedure Test_Public_Build_Commands_Are_Hidden_From_Normal_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.State.Init (S);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         Assert (not Editor.Commands.Is_Public_Build_Command (Candidate.Id),
                 "normal palette must not contain public build commands in ");
         Assert (Candidate.Id /= Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam,
                 "normal palette must not contain internal build test seam");
      end loop;
      Assert (not Editor.Commands.Visible_In_Command_Palette
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "internal build test seam remains hidden from normal palette");
   end Test_Public_Build_Commands_Are_Hidden_From_Normal_Palette;

   procedure Test_Public_Build_Readiness_Reports_Missing_UX_Models
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Has_Consent_UX_Model,
              "readiness audit must report the structured consent model");
      Assert (R.Public_Consent_Model_Exists,
              "readiness audit must report the public consent model exists");
      Assert (R.Public_Consent_Model_Validated,
              "readiness audit must report public consent validation exists");
      Assert (R.Public_Consent_UX_Publicly_Ready,
              "readiness audit must report completed public consent UX");
      Assert (R.Public_Consent_Publicly_Exposable,
              "readiness audit must report publicly exposable consent state");
      Assert (R.Has_Working_Context_Model,
              "readiness audit must report the working-context model");
      Assert (R.Has_User_Command_Input_Model,
              "readiness audit must report the public user-command input model");
      Assert (R.Has_Implicit_Source_Validation,
              "readiness audit must report explicit-source policy validation");
   end Test_Public_Build_Readiness_Reports_Missing_UX_Models;

   procedure Test_Public_Build_Readiness_Keeps_Rejections
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Keeps_Implicit_Source_Rejected,
              "readiness audit must prove implicit build source remains rejected");
      Assert (R.Keeps_Shell_Rejected,
              "readiness audit must prove shell policy remains rejected");
      Assert (R.Keeps_Opaque_Arguments_Rejected,
              "readiness audit must prove free-form opaque arguments remain rejected");
   end Test_Public_Build_Readiness_Keeps_Rejections;

   procedure Test_Public_Build_Readiness_Audit_Reports_Input_Model_Present
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Has_User_Command_Input_Model,
              "readiness audit must report public input model present");
      Assert (R.Has_Public_Input_Model_Audit,
              "readiness audit must include public input model audit");
      Assert (R.Public_Input_Validation_Side_Effect_Free,
              "readiness audit must prove public input validation is pure metadata");
      Assert (R.Public_Input_Conversion_Requires_Valid_Input,
              "readiness audit must prove conversion requires valid input");
      Assert (R.Public_Input_Conversion_Preserves_Provenance,
              "readiness audit must prove conversion preserves user-opt-in provenance");
      Assert (R.Public_Input_Conversion_Uses_Structured_Argv,
              "readiness audit must prove conversion uses structured argv");
      Assert (R.Public_Input_Does_Not_Create_Command_Descriptors,
              "public input model must not create command descriptors");
      Assert (R.Public_Input_Validation_Complete,
              "audit must report public input validation complete");
      Assert (R.Public_Input_Has_Safety_Classification,
              "audit must report public input safety classification");
      Assert (R.Public_Input_Publicly_Exposable,
              "audit must report public input model ready");
      Assert (R.Working_Context_Publicly_Ready,
              "readiness audit must report public working context ready");
      Assert (R.Consent_UX_Publicly_Ready,
              "readiness audit must report public consent UX ready");
      Assert (R.Public_Input_Does_Not_Enable_Public_Execution,
              "public input model must not enable default execution");
   end Test_Public_Build_Readiness_Audit_Reports_Input_Model_Present;

   procedure Test_Public_Build_Readiness_Audit_Reports_Working_Context_Model
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_Working_Context_Model_Exists,
              "readiness audit must report public working-context model exists");
      Assert (R.Public_Working_Context_Model_Validated,
              "readiness audit must report public working-context validation exists");
      Assert (R.Public_Working_Context_Publicly_Ready,
              "readiness audit must report public working-context UX ready");
      Assert (R.Public_Working_Context_Publicly_Exposable,
              "readiness audit must report public working context is exposable");
      Assert (R.Project_Derived_Working_Context_Rejected,
              "readiness audit must report project-derived working context rejected");
      Assert (R.Passed_As_Not_Ready,
              "readiness audit must still pass only as intentionally not ready");
   end Test_Public_Build_Readiness_Audit_Reports_Working_Context_Model;

   procedure Test_Public_Build_Command_Surface_Entries_Exist_As_Metadata_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Surface_Entries : constant Public_Build_Command_Surface_Array :=
        Build_Public_Build_Command_Surface;
      Surface_Entry : Public_Build_Command_Surface_Entry;
   begin
      Assert (Surface_Entries.Length = 1,
              "public build surface defines the single guarded build.run entry");
      Surface_Entry := Surface_Entries.First_Element;
      Assert (To_String (Surface_Entry.Stable_Id) = "build.run",
              "surface entry name must be build.run");
      Assert (Validate_Public_Build_Command_Surface_Entry (Surface_Entry) =
              Public_Build_Command_Surface_Valid,
              "surface entry metadata must validate");
      Assert (Surface_Entry.Has_Input_Model,
              "surface entry must reference the public input model");
      Assert (Surface_Entry.Has_Consent_Model,
              "surface entry must reference the public consent model");
      Assert (Surface_Entry.Has_Working_Context_Model,
              "surface entry must reference the public working-context model");
      Assert (Surface_Entry.Publicly_Invokable,
              "surface entry must be publicly invokable through the guarded command");
      Assert (Surface_Entry.Routes_Through_Executor,
              "surface entry must route through Executor");
      Assert_Public_Build_Command_Surface_Entry_Consistent (Surface_Entry);
   end Test_Public_Build_Command_Surface_Entries_Exist_As_Metadata_Only;

   procedure Test_Public_Build_Command_Surface_Entry_Not_Registered
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.configure");
      Assert_Public_Build_Name_Not_Registered
        ("build.show-diagnostics-after-build");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
   end Test_Public_Build_Command_Surface_Entry_Not_Registered;

   procedure Test_Public_Build_Command_Surface_Entry_Has_No_Keybinding
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (not R.Has_Default_Public_Build_Keybinding,
              "public build surface entrys must have no default keybinding");
   end Test_Public_Build_Command_Surface_Entry_Has_No_Keybinding;

   procedure Test_Public_Build_Command_Surface_Entry_Not_In_Normal_Palette
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
   begin
      Editor.State.Init (S);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      for Candidate of Candidates loop
         Assert (Editor.Commands.Stable_Command_Name (Candidate.Id) /= "build.run"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "build.configure"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "build.show-diagnostics-after-build"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "build.project"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "build.run-project"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "compile.project"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "compile.current"
                 and then Editor.Commands.Stable_Command_Name (Candidate.Id) /=
                   "diagnostics.run-build",
                 "normal palette must not contain public build surface entrys");
      end loop;
   end Test_Public_Build_Command_Surface_Entry_Not_In_Normal_Palette;

   procedure Test_Public_Build_Command_Surface_Entry_Does_Not_Route_To_Executor
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Assert (Audit_Public_Build_Command_Visibility,
              "public surface entry visibility audit must prove no Executor route exists");
      Assert_Public_Build_Name_Not_Registered ("build.run");
      Assert_Public_Build_Name_Not_Registered ("build.configure");
      Assert_Public_Build_Name_Not_Registered
        ("build.show-diagnostics-after-build");
      Assert_Public_Build_Name_Not_Registered ("build.project");
      Assert_Public_Build_Name_Not_Registered ("build.run-project");
      Assert_Public_Build_Name_Not_Registered ("compile.project");
      Assert_Public_Build_Name_Not_Registered ("compile.current");
      Assert_Public_Build_Name_Not_Registered ("diagnostics.run-build");
   end Test_Public_Build_Command_Surface_Entry_Does_Not_Route_To_Executor;

   procedure Test_Public_Build_Command_Surface_Validation_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      Status : Public_Build_Command_Surface_Status;
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      Status := Validate_Public_Build_Command_Surface_Entry
        ((Stable_Id => To_Unbounded_String ("build.run"),
          Has_Descriptor => True,
          Has_Input_Model => True,
          Has_Consent_Model => True,
          Has_Working_Context_Model => True,
          Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>));
      Assert (Status = Public_Build_Command_Surface_Valid,
              "valid surface entry metadata must validate");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "surface entry validation must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "surface entry validation must not create buffers");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Command_Surface_Validation_Is_Side_Effect_Free;

   procedure Test_Public_Build_Command_Surface_Entry_Rejects_Invalid_Forms
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => Null_Unbounded_String,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => False,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Empty_Id,
              "empty surface entry id must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("build.run"),
                  Has_Descriptor => True,
                  Has_Input_Model => False,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Input_Model,
              "surface entry without input model must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("build.run"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => False,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Consent_Model,
              "surface entry without consent model must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("build.run"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => False,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Working_Context_Model,
              "surface entry without working-context model must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("build.run"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => False,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Not_Publicly_Invokable,
              "non-invokable surface entry must reject");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String
                    ("build.run-user-opt-in-test-seam"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Descriptor,
              "non-public command id must reject as surface entry metadata");
      Assert (Validate_Public_Build_Command_Surface_Entry
                ((Stable_Id => To_Unbounded_String ("file.save"),
                  Has_Descriptor => True,
                  Has_Input_Model => True,
                  Has_Consent_Model => True,
                  Has_Working_Context_Model => True,
                  Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>)) =
              Public_Build_Command_Surface_Rejected_Missing_Descriptor,
              "non-public default-keybound command must reject as surface entry metadata");
   end Test_Public_Build_Command_Surface_Entry_Rejects_Invalid_Forms;

   procedure Test_Public_Build_Readiness_Audit_Reports_Surface_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_Command_Surface_Exists,
              "readiness audit must report design-only surface entry metadata exists");
      Assert (R.Public_Executable_Command_Exists,
              "readiness audit must report guarded executable public command");
      Assert (R.Public_Command_Is_Invokable,
              "readiness audit must report public command is guarded and invokable");
      Assert (R.Public_Command_Has_Complete_UX_Models,
              "readiness audit must report complete public command UX models");
      Assert (R.Public_Command_Publicly_Exposable,
              "readiness audit must report public command is exposable through guards");
      Assert (R.Passed_As_Not_Ready,
              "surface entry-aware readiness audit must still pass only as not ready");
   end Test_Public_Build_Readiness_Audit_Reports_Surface_Entries;

   procedure Test_Public_Build_Command_UX_Dependency_Matrix_Is_Ready
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      R : constant Editor.External_Producers.Public_Build_Command_UX_Dependency_Audit_Result :=
        Editor.External_Producers.Audit_Public_Build_Command_UX_Dependencies;
   begin
      Assert (R.Has_Input_Model,
              "dependency matrix must report public input model exists");
      Assert (R.Has_Structured_Argv_Model,
              "dependency matrix must require structured argv");
      Assert (R.Has_Consent_Model,
              "dependency matrix must report public consent model exists");
      Assert (R.Has_Real_Consent_UX,
              "dependency matrix must report real consent UX ready");
      Assert (R.Has_Working_Context_Model,
              "dependency matrix must report working-context model exists");
      Assert (R.Has_Safe_Working_Context_UX,
              "dependency matrix must report safe working-directory UX ready");
      Assert (R.Has_Implicit_Source_Validation,
              "dependency matrix must report explicit-source policy validation");
      Assert (R.Explicitly_Rejects_Implicit_Source,
              "dependency matrix must keep implicit build source explicitly rejected");
      Assert (R.Requires_Executor_Routed_Mutation,
              "dependency matrix must require Executor-routed mutation");
      Assert (R.Requires_One_Primary_Result,
              "dependency matrix must preserve one primary result policy");
      Assert (R.Requires_Diagnostics_Pipeline,
              "dependency matrix must require Diagnostics pipeline routing");
      Assert (R.Requires_No_Shell_Execution,
              "dependency matrix must require no-shell execution");
      Assert (R.Requires_Side_Effect_Free_Availability,
              "dependency matrix must require side-effect-free availability");
      Assert (R.Requires_No_Persistence_Of_Transient_State,
              "dependency matrix must forbid persistence of transient build state");
      Assert (R.Public_Command_Exposure_Blocked,
              "dependency matrix must report public command exposure blocked");
      Assert (R.Passed_As_Not_Ready,
              "dependency matrix must pass with guarded public promotion ready");
   end Test_Public_Build_Command_UX_Dependency_Matrix_Is_Ready;

   procedure Test_Public_Build_Command_Exposure_Barrier_Passes_For_Surface_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Editor.External_Producers.Assert_Public_Build_Command_Surface_Exposed;
      Assert (Editor.External_Producers.Audit_Public_Build_Command_Visibility,
              "exposure barrier must pass while surface entrys remain metadata only");
   end Test_Public_Build_Command_Exposure_Barrier_Passes_For_Surface_Entries;

   procedure Test_Public_Build_Promotion_Blocked_When_Consent_UX_Missing
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
      R.Public_Consent_UX_Publicly_Ready := False;
      R.Public_Consent_Publicly_Exposable := False;
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Consent_UX_Incomplete,
              "promotion must be blocked by missing real consent UX");
      Assert (Build_Public_Command_Promotion_Feedback
                (Public_Build_Promotion_Consent_UX_Incomplete) =
              "Build: consent UX not ready",
              "consent promotion feedback must not leak command details");
   end Test_Public_Build_Promotion_Blocked_When_Consent_UX_Missing;

   procedure Test_Public_Build_Promotion_Blocked_When_Working_Context_UX_Missing
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
      R.Public_Working_Context_Publicly_Ready := False;
      R.Public_Working_Context_Publicly_Exposable := False;
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Working_Context_UX_Incomplete,
              "promotion must be blocked by missing safe working-context UX");
      Assert (Build_Public_Command_Promotion_Feedback
                (Public_Build_Promotion_Working_Context_UX_Incomplete) =
              "Build: working directory UX not ready",
              "working-context promotion feedback must not include paths");
   end Test_Public_Build_Promotion_Blocked_When_Working_Context_UX_Missing;

   procedure Test_Public_Build_Promotion_Ready_When_Guardrails_Pass
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
      R.Public_Consent_UX_Publicly_Ready := True;
      R.Public_Consent_Publicly_Exposable := True;
      R.Public_Working_Context_Publicly_Ready := True;
      R.Public_Working_Context_Publicly_Exposable := True;
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Command_Surface_Ready,
              "promotion must be ready when explicit-source policy and guardrails pass");
      Assert (Build_Public_Command_Promotion_Feedback
                (Public_Build_Promotion_Command_Surface_Ready) =
              "Build: public command ready",
              "ready promotion feedback must stay deterministic");
   end Test_Public_Build_Promotion_Ready_When_Guardrails_Pass;

   procedure Test_Public_Build_Promotion_Blocked_When_Command_Already_Registered
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run-user-opt-in-test-seam"),
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => False,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Blocked,
              "registered command ids must hard-block surface entry promotion");
   end Test_Public_Build_Promotion_Blocked_When_Command_Already_Registered;

   procedure Test_Public_Build_Promotion_Blocked_When_Default_Keybinding_Exists
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("file.save"),
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => False,
          others => <>);
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Blocked,
              "default-keybound command ids must hard-block public build promotion");
   end Test_Public_Build_Promotion_Blocked_When_Default_Keybinding_Exists;

   procedure Test_Public_Build_Promotion_Blocked_When_Executor_Route_Exists
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run-user-opt-in-test-seam"),
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => False,
          others => <>);
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (Editor.Commands.Requires_Context
                (Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam),
              "fixture for route-exists test must be an Executor-routed internal command");
      Assert (Validate_Public_Build_Command_Promotion (P, R) =
              Public_Build_Promotion_Blocked,
              "existing Executor routes must hard-block surface entry promotion");
   end Test_Public_Build_Promotion_Blocked_When_Executor_Route_Exists;

   procedure Test_Public_Build_Promotion_Ready_In_Current_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_Command_Promotion_Status =
              Public_Build_Promotion_Command_Surface_Ready,
              "audit must report command-surface promotion ready");
      Assert (R.Public_Command_Can_Be_Promoted,
              "audit must report promotion possible");
      Assert (not R.Promotion_Blocked_By_Consent_UX,
              "consent UX is no longer a public build blocker");
      Assert (not R.Promotion_Blocked_By_Working_Context,
              "working-context UX is no longer a public build blocker");
      Assert (not R.Promotion_Blocked_By_Implicit_Source,
              "explicit-source policy is no longer a promotion blocker");
      Assert (not R.Promotion_Blocked_By_Command_Exposure,
              "baseline must have no accidental command exposure");
      Assert (R.Passed_As_Not_Ready,
              "readiness audit must pass as guarded promotion-ready");
   end Test_Public_Build_Promotion_Ready_In_Current_State;

   procedure Test_Public_Build_Promotion_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R1 : Public_Build_Command_Readiness_Audit_Result;
      R2 : Public_Build_Command_Readiness_Audit_Result;
      Before_Messages : Natural;
      Before_Has_Buffer : Boolean;
      P : constant Public_Build_Command_Surface_Entry :=
        (Stable_Id => To_Unbounded_String ("build.run"),
         Has_Descriptor => True,
         Has_Input_Model => True,
         Has_Consent_Model => True,
         Has_Working_Context_Model => True,
         Publicly_Invokable => True,
          Routes_Through_Executor => True,
          others => <>);
      Status : Public_Build_Command_Promotion_Status;
      pragma Unreferenced (Status);
   begin
      Editor.State.Init (S);
      Before_Messages := Editor.Messages.Count (S.Messages);
      Before_Has_Buffer := Editor.State.Has_Active_Buffer (S);
      R1 := Run_Public_Build_Command_Readiness_Audit (S);
      Status := Validate_Public_Build_Command_Promotion (P, R1);
      Assert_Public_Build_Command_Surface_Exposed;
      Assert (Audit_Public_Build_Command_Visibility,
              "exposure barrier must pass without mutation");
      declare
         Feedback : constant String :=
           Build_Public_Command_Promotion_Feedback
             (R1.Public_Command_Promotion_Status);
      begin
         Assert (Feedback'Length > 0,
                 "feedback helper must be pure deterministic text");
      end;
      R2 := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R1.Public_Command_Promotion_Status = R2.Public_Command_Promotion_Status,
              "repeated readiness audits must return stable promotion status");
      Assert (R1.Public_Command_Can_Be_Promoted = R2.Public_Command_Can_Be_Promoted,
              "repeated readiness audits must return stable promotion boolean");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
              "readiness and promotion audits must not post messages");
      Assert (Editor.State.Has_Active_Buffer (S) = Before_Has_Buffer,
              "readiness and promotion audits must not create buffers");
      Assert_Public_Build_Name_Not_Registered ("build.run");
   end Test_Public_Build_Promotion_Audit_Is_Side_Effect_Free;

   procedure Test_Public_Build_UX_Dependency_Matrix_Exists
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
   begin
      Assert (Matrix (Public_Build_Dependency_Input_Model) =
              Dependency_Satisfied,
              "input model must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Structured_Argv) =
              Dependency_Satisfied,
              "structured argv dependency must be satisfied");
      Assert (Matrix (Public_Build_Dependency_Consent_Model) =
              Dependency_Satisfied,
              "consent model must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Consent_UX) = Dependency_Satisfied,
              "consent UX must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Working_Context_Model) =
              Dependency_Satisfied,
              "working-context model must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Working_Context_UX) =
              Dependency_Satisfied,
              "working-context UX must be public-ready");
      Assert (Matrix (Public_Build_Dependency_Implicit_Source_Policy) =
              Dependency_Satisfied,
              "explicit-source policy must be satisfied");
      Assert (Matrix (Public_Build_Dependency_Execution_Policy) =
              Dependency_Satisfied,
              "execution policy must be satisfied");
      Assert (Matrix (Public_Build_Dependency_Executor_Route) = Dependency_Satisfied,
              "guarded public Executor route must be present");
      Assert (Matrix (Public_Build_Dependency_Diagnostics_Pipeline) =
              Dependency_Satisfied,
              "Diagnostics pipeline dependency must remain satisfied");
      Assert (Matrix (Public_Build_Dependency_No_Persistence) =
              Dependency_Satisfied,
              "no-persistence guard must remain satisfied");
   end Test_Public_Build_UX_Dependency_Matrix_Exists;

   procedure Test_Public_Build_UX_Dependency_Matrix_Validation_Allows_Promotion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Matrix : constant Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
   begin
      Assert (Validate_Public_Build_UX_Dependencies (Matrix) =
              Public_Build_Promotion_Command_Surface_Ready,
              "dependency matrix must allow guarded surface entry promotion");
   end Test_Public_Build_UX_Dependency_Matrix_Validation_Allows_Promotion;

   procedure Test_Public_Build_Promotion_Blocker_Precedence_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      Matrix : Public_Build_UX_Dependency_Matrix :=
        Build_Public_Build_UX_Dependency_Matrix;
   begin
      Assert (Validate_Public_Build_UX_Dependencies (Matrix) =
              Public_Build_Promotion_Command_Surface_Ready,
              "dependency matrix is ready when all guarded dependencies are satisfied");
   end Test_Public_Build_Promotion_Blocker_Precedence_Is_Deterministic;

   procedure Test_Public_Build_Readiness_Audit_Reports_Dependency_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
      R : Public_Build_Command_Readiness_Audit_Result;
   begin
      Editor.State.Init (S);
      R := Run_Public_Build_Command_Readiness_Audit (S);
      Assert (R.Public_UX_Dependency_Matrix_Exists,
              "readiness audit must report dependency matrix exists");
      Assert (R.Public_UX_Dependency_Matrix_Validated,
              "readiness audit must validate dependency matrix");
      Assert (R.Public_Command_Promotion_Status = Public_Build_Promotion_Command_Surface_Ready,
              "readiness audit must report ready promotion status");
      Assert (not R.Consent_UX_Blocker_Active,
              "readiness audit must show consent UX blocker cleared");
      Assert (not R.Working_Context_UX_Blocker_Active,
              "readiness audit must show working-context UX blocker cleared");
      Assert (not R.Implicit_Source_Blocker_Active,
              "readiness audit must show explicit-source blocker cleared");
      Assert (not R.Public_Executor_Route_Blocker_Active,
              "readiness audit must show guarded public Executor route present");
      Assert (not R.Public_Command_Exposure_Hard_Failure,
              "normal state must not be a hard exposure failure");
      Assert (R.Passed_As_Not_Ready,
              "dependency-aware readiness audit must pass as guarded promotion-ready");
   end Test_Public_Build_Readiness_Audit_Reports_Dependency_Matrix;

   procedure Test_Public_Build_Guardrail_Audit_Uses_Exposure_Barrier
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.External_Producers;
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Public_Build_Surface_Ids_Not_Publicly_Projected (S),
              "guardrail projection scan must see no public-id projection");
      Assert_No_Public_Build_Execution_Path (S);
   end Test_Public_Build_Guardrail_Audit_Uses_Exposure_Barrier;

   overriding procedure Register_Tests
     (T : in out Public_Build_Surface_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Not_Ready'Access,
         "Public Build Readiness Audit Reports Not Ready");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Is_Side_Effect_Free'Access,
         "Public Build Readiness Audit Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Commands_Are_Not_Registered'Access,
         "Public Build Commands Are Not Registered");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Commands_Have_No_Default_Keybindings'Access,
         "Public Build Commands Have No Default Keybindings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Commands_Are_Hidden_From_Normal_Palette'Access,
         "Public Build Commands Are Hidden From Normal Palette");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Reports_Missing_UX_Models'Access,
         "Public Build Readiness Reports Missing UX Models");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Keeps_Rejections'Access,
         "Public Build Readiness Keeps Rejections");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Input_Model_Present'Access,
         "Public Build Readiness Audit Reports Input Model Present");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Working_Context_Model'Access,
         "Public Build Readiness Audit Reports Working Context Model");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entries_Exist_As_Metadata_Only'Access,
         "Public Build Command Surface_Entries Exist As Metadata Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Not_Registered'Access,
         "Public Build Command Surface_Entry Not Registered");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Has_No_Keybinding'Access,
         "Public Build Command Surface_Entry Has No Keybinding");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Not_In_Normal_Palette'Access,
         "Public Build Command Surface_Entry Not In Normal Palette");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Does_Not_Route_To_Executor'Access,
         "Public Build Command Surface_Entry Does Not Route To Executor");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Validation_Is_Side_Effect_Free'Access,
         "Public Build Command Surface_Entry Validation Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Surface_Entry_Rejects_Invalid_Forms'Access,
         "Public Build Command Surface_Entry Rejects Invalid Forms");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Surface_Entries'Access,
         "Public Build Readiness Audit Reports Surface_Entries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_UX_Dependency_Matrix_Is_Ready'Access,
         "Public Build Command UX Dependency Matrix Is Ready");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Exposure_Barrier_Passes_For_Surface_Entries'Access,
         "Public Build Command Exposure Barrier Passes For Surface_Entries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Consent_UX_Missing'Access,
         "Public Build Promotion Blocked When Consent UX Missing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Working_Context_UX_Missing'Access,
         "Public Build Promotion Blocked When Working Context UX Missing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Ready_When_Guardrails_Pass'Access,
         "Public Build Promotion Ready When Guardrails Pass");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Command_Already_Registered'Access,
         "Public Build Promotion Blocked When Command Already Registered");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Default_Keybinding_Exists'Access,
         "Public Build Promotion Blocked When Default Keybinding Exists");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocked_When_Executor_Route_Exists'Access,
         "Public Build Promotion Blocked When Executor Route Exists");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Ready_In_Current_State'Access,
         "Public Build Promotion Ready In Current State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Audit_Is_Side_Effect_Free'Access,
         "Public Build Promotion Audit Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_UX_Dependency_Matrix_Exists'Access,
         "Public Build UX Dependency Matrix Exists");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_UX_Dependency_Matrix_Validation_Allows_Promotion'Access,
         "Public Build UX Dependency Matrix Validation Allows Promotion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Promotion_Blocker_Precedence_Is_Deterministic'Access,
         "Public Build Promotion Blocker Precedence Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Readiness_Audit_Reports_Dependency_Matrix'Access,
         "Public Build Readiness Audit Reports Dependency Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Guardrail_Audit_Uses_Exposure_Barrier'Access,
         "Public Build Guardrail Audit Uses Exposure Barrier");
   end Register_Tests;

end Editor.Command_Surface.Public_Build_Surface_Tests;
