with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.Build_UI;
with Editor.Buffer_Switcher;
with Editor.Command_Execution;
with Editor.Cursors;
with Editor.Dirty_Guards;
with Editor.Executor;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.File_Tree.File_Tree_Node_Kind;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Guided_Prompts;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Navigation_History;
with Editor.Panels;
with Editor.Pending_Transitions;
use type Editor.Pending_Transitions.Pending_Transition_Kind;
with Editor.Project;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Quick_Open;
with Editor.Recent_Projects;
with Editor.Render_Cache;
with Editor.State;
with Editor.View;
with Editor.Workspace_Persistence;
use type Editor.Workspace_Persistence.Bottom_Content_Id;
use type Editor.Workspace_Persistence.Workspace_Persistence_Status;

package body Editor.Executor.Workspace_Commands is

   use Editor.Commands;

   function Workspace_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Command_Save_Workspace_State
            | Command_Restore_Workspace_State
            | Command_Clear_Workspace_State =>
            if not Editor.Project.Has_Project (S.Project) then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a workspace command");
      end case;
   end Workspace_Command_Availability;

   procedure Mark_Restore_Feedback_Current
     (S : in out Editor.State.State_Type)
   is
   begin
      S.Post_Restore_Feedback_Current := True;
   end Mark_Restore_Feedback_Current;

   procedure Clear_Restore_Feedback_Current
     (S : in out Editor.State.State_Type)
   is
   begin
      S.Post_Restore_Feedback_Current := False;
      S.Last_Restore_Summary_Available := False;
   end Clear_Restore_Feedback_Current;

   procedure Mark_Restore_Summary_Current
     (S       : in out Editor.State.State_Type;
      Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary)
   is
   begin
      S.Last_Restore_Summary := Summary;
      S.Last_Restore_Summary_Available := True;
   end Mark_Restore_Summary_Current;

   procedure Report_Restore_Success
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Report_Success (S, Text);
      Mark_Restore_Feedback_Current (S);
   end Report_Restore_Success;

   procedure Report_Restore_Warning
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Report_Warning (S, Text);
      Mark_Restore_Feedback_Current (S);
   end Report_Restore_Warning;


   function Restore_Summary_Message
      (Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Partial : Boolean) return String
   is
   begin
      if Partial then
         return "Workspace restored with missing entries skipped. "
           & Editor.Workspace_Persistence.Restore_Details_Label (Summary);
      else
         return "Workspace restored. "
           & Editor.Workspace_Persistence.Restore_Details_Label (Summary);
      end if;
   end Restore_Summary_Message;

   procedure Report_Workspace_Load_Status
     (S      : in out Editor.State.State_Type;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status)
   is
   begin
      case Status is
         when Editor.Workspace_Persistence.Workspace_Persistence_Not_Found =>
            Report_Info (S, "No workspace state");
         when Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format =>
            Report_Error (S, "Workspace could not be restored.");
         when Editor.Workspace_Persistence.Workspace_Persistence_Unsupported_Version =>
            Report_Error (S, "Workspace could not be restored.");
         when Editor.Workspace_Persistence.Workspace_Persistence_Read_Error
            | Editor.Workspace_Persistence.Workspace_Persistence_Write_Error =>
            Report_Error (S, "Load workspace state failed");
         when Editor.Workspace_Persistence.Workspace_Persistence_Ok
            | Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore =>
            null;
      end case;
   end Report_Workspace_Load_Status;


   function Join_Project_Path (Root : String; Relative : String) return String
   is
   begin
      if Root'Length = 0 then
         return Relative;
      elsif Relative'Length = 0 then
         return Root;
      elsif Root (Root'Last) = '/' then
         return Root & Relative;
      else
         return Root & "/" & Relative;
      end if;
   end Join_Project_Path;

   function Open_File_For_Workspace_Restore
     (S            : in out Editor.State.State_Type;
      Path         : String;
      Restored_Id  : out Editor.Buffers.Buffer_Id;
      Already_Open : out Boolean) return Boolean
   is
      Result : Editor.Files.File_Open_Result;
      Found  : Boolean := False;
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;

      function Current_State_Is_Disposable_Initial_Untitled return Boolean is
      begin
         return Editor.Buffers.Global_Count = 0
           and then not S.File_Info.Has_Path
           and then not S.File_Info.Dirty
           and then Editor.State.Current_Text (S) = "";
      end Current_State_Is_Disposable_Initial_Untitled;
   begin
      Restored_Id := Editor.Buffers.No_Buffer;
      Already_Open := False;
      if not Current_State_Is_Disposable_Initial_Untitled then
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      Id := Editor.Buffers.Global_Find_By_Path (Path, Found);
      if Found then
         Already_Open := True;
         Restored_Id := Id;
         Editor.Buffers.Global_Clear_Clean_Reopen_Lifecycle (Id);
         Editor.Buffers.Global_Set_Active_Buffer (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         return True;
      end if;

      --  A workspace restore may only create a file-backed buffer after a
      --  successful explicit read. Missing paths, directories, permission
      --  failures, decode failures, and other read errors all return False
      --  without creating partial, dirty, or untitled buffers.
      Result := Editor.Files.Open_File (Path);
      if Editor.Files.Is_Success (Result) then
         Editor.Buffers.Global_Add_File_Buffer
           (Path         => To_String (Result.Path),
            Display_Name => To_String (Result.Display_Name),
            Contents     => To_String (Result.Contents),
            New_Id       => Id);
         Restored_Id := Id;
         Editor.Buffers.Global_Clear_Clean_Reopen_Lifecycle (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         return True;
      else
         return False;
      end if;
   end Open_File_For_Workspace_Restore;

   function Workspace_Entry_Path
     (Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Item    : Editor.Workspace_Persistence.Workspace_File_Entry) return String
   is
      Path : constant String := To_String (Item.Path);
   begin
      if Item.Is_Project_Relative then
         return Join_Project_Path
           (Editor.Workspace_Persistence.Project_Root (Snapshot), Path);
      else
         return Path;
      end if;
   end Workspace_Entry_Path;

   function Workspace_Active_Path
     (Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot) return String
   is
      Path : constant String := Editor.Workspace_Persistence.Active_File_Path (Snapshot);
   begin
      if Editor.Workspace_Persistence.Active_File_Is_Project_Relative (Snapshot) then
         return Join_Project_Path
           (Editor.Workspace_Persistence.Project_Root (Snapshot), Path);
      else
         return Path;
      end if;
   end Workspace_Active_Path;

   procedure Restore_Caret_And_View_For_Current_Buffer
     (S     : in out Editor.State.State_Type;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry)
   is
      Last_Row   : constant Natural :=
        (if Editor.State.Line_Count (S) = 0 then 0 else Editor.State.Line_Count (S) - 1);
      Row        : constant Natural := Natural'Min (Item.Cursor_Row, Last_Row);
      Line_Start : constant Editor.Cursors.Cursor_Index := Editor.State.Line_Start (S, Row);
      Line_End   : constant Editor.Cursors.Cursor_Index := Editor.State.Line_End (S, Row);
      Col        : constant Natural := Natural'Min
        (Item.Cursor_Column, Natural (Line_End - Line_Start));
      Pos        : constant Editor.Cursors.Cursor_Index := Line_Start + Col;
      View_Row   : constant Natural := Natural'Min (Item.View_First_Row, Last_Row);
   begin
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => Pos,
          Anchor                => Pos,
          Virtual_Column        => Col,
          Anchor_Virtual_Column => Col));
      Editor.State.Normalize_Carets (S);
      Editor.View.Set_Scroll (0, View_Row);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Restore_Caret_And_View_For_Current_Buffer;

   function Matching_Entry
     (Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Path     : String;
      Found    : out Boolean) return Editor.Workspace_Persistence.Workspace_File_Entry
   is
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
   begin
      for I in 1 .. Editor.Workspace_Persistence.Open_File_Count (Snapshot) loop
         Item := Editor.Workspace_Persistence.Open_File (Snapshot, I);
         if Workspace_Entry_Path (Snapshot, Item) = Path
           or else To_String (Item.Path) = Path
         then
            Found := True;
            return Item;
         end if;
      end loop;
      Found := False;
      return Item;
   end Matching_Entry;

   function Restored_Feature_Panel
     (Feature : Editor.Workspace_Persistence.Workspace_Feature_Panel_Id)
      return Editor.Feature_Panel.Feature_Id
   is
   begin
      case Feature is
         when Editor.Workspace_Persistence.Workspace_Messages_Feature =>
            return Editor.Feature_Panel.Messages_Feature;
         when Editor.Workspace_Persistence.Workspace_Search_Results_Feature =>
            return Editor.Feature_Panel.Search_Results_Feature;
         when Editor.Workspace_Persistence.Workspace_Diagnostics_Feature =>
            return Editor.Feature_Panel.Diagnostics_Feature;
         when Editor.Workspace_Persistence.Workspace_Outline_Feature =>
            return Editor.Feature_Panel.Outline_Feature;
      end case;
   end Restored_Feature_Panel;

   function Restored_Quick_Open_Filter
     (Filter : Editor.Workspace_Persistence.Workspace_Quick_Open_File_Kind_Filter)
      return Editor.Quick_Open.Quick_Open_File_Kind_Filter
   is
   begin
      case Filter is
         when Editor.Workspace_Persistence.Workspace_Quick_Open_Ada_Files =>
            return Editor.Quick_Open.Ada_Files;
         when Editor.Workspace_Persistence.Workspace_Quick_Open_Test_Files =>
            return Editor.Quick_Open.Test_Files;
         when Editor.Workspace_Persistence.Workspace_Quick_Open_Doc_Files =>
            return Editor.Quick_Open.Doc_Files;
         when Editor.Workspace_Persistence.Workspace_Quick_Open_Other_Files =>
            return Editor.Quick_Open.Other_Files;
         when Editor.Workspace_Persistence.Workspace_Quick_Open_All_Files =>
            return Editor.Quick_Open.All_Files;
      end case;
   end Restored_Quick_Open_Filter;

   procedure Restore_Recent_Project_Selection
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot)
   is
      Target : constant String :=
        (if Editor.Workspace_Persistence.Has_Recent_Project_Path (Snapshot)
         then Editor.Workspace_Persistence.Recent_Project_Path (Snapshot)
         else "");
   begin
      if Target'Length = 0 then
         return;
      end if;

      for I in 1 .. Editor.Recent_Projects.Count (S.Recent_Projects) loop
         declare
            Item : constant Editor.Recent_Projects.Recent_Project_Entry :=
              Editor.Recent_Projects.Item (S.Recent_Projects, I);
         begin
            if To_String (Item.Root_Path) = Target then
               S.Recent_Project_Selected_Index := I;
               return;
            end if;
         end;
      end loop;
   end Restore_Recent_Project_Selection;

   procedure Restore_Workspace_Snapshot
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : out Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : out Editor.Workspace_Persistence.Workspace_Restore_Summary)
   is
      Partial        : Boolean := False;
      Restored_Files    : Natural := 0;
      Full_Path         : Unbounded_String;
      Found             : Boolean := False;
      Id                : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      First_Restored_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Already_Open      : Boolean := False;
      Node_Found     : Boolean := False;
      Node_Id        : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Item          : Editor.Workspace_Persistence.Workspace_File_Entry;
   begin
      Clear_Reopen_Candidate (S);
      Status := Editor.Workspace_Persistence.Workspace_Persistence_Ok;
      Summary := (others => <>);

      if Editor.Workspace_Persistence.Version (Snapshot) /= 1 then
         Status := Editor.Workspace_Persistence.Workspace_Persistence_Unsupported_Version;
         return;
      end if;

      if Editor.Workspace_Persistence.Has_Project_Root (Snapshot) then
         declare
            Root   : constant String := Editor.Workspace_Persistence.Project_Root (Snapshot);
            Result : constant Editor.Project.Project_Open_Result :=
              Editor.Project.Open_Project (Root);
         begin
            if Editor.Project.Has_Project (S.Project)
              and then Editor.Project.Root_Path (S.Project) /= Root
            then
               Status := Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format;
               return;
            elsif not Editor.Project.Is_Success (Result) then
               Status := Editor.Workspace_Persistence.Workspace_Persistence_Read_Error;
               return;
            end if;

            if not Editor.Project.Has_Project (S.Project) then
               Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project
                 (S, Root, Refresh_Build_Candidates => False);
               if not Editor.Project.Has_Project (S.Project) then
                  Status := Editor.Workspace_Persistence.Workspace_Persistence_Read_Error;
                  return;
               end if;
            end if;
         end;
      elsif not Editor.Project.Has_Project (S.Project) then
         Status := Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format;
         return;
      end if;

      --  Workspace restoration installs approved structural session state only.
      --  Before applying that structure, clear transient feature projections so
      --  stale Messages, Diagnostics, Search Results, Outline rows, and Feature
      --  Panel rows cannot survive a workspace lifecycle transition.
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (S);
      Editor.Navigation_History.Clear (S.Navigation_History);

      --  restart/reload dogfood: workspace restore applies only
      --  structural session state.  Clear adjacent transient workflow surfaces
      --  at the real restore boundary so Search, Quick Open, Outline rows,
      --  Diagnostics, Build candidates/results/output, and prompt state from
      --  the pre-restore interaction cannot survive as if they belonged to the
      --  restored session.
      Editor.Quick_Open.Clear (S.Quick_Open);
      Editor.Project_Search.Clear (S.Project_Search);
      Editor.Project_Search_Bar.Clear (S.Project_Search_Bar);
      Editor.Buffer_Switcher.Clear (S.Buffer_Switcher);
      Editor.Guided_Prompts.Clear (S.Guided_Prompt);
      Editor.Executor.File_Target_Prompt_Commands.Clear_File_Target_Prompt (S);
      S.Build_UI := Editor.Build_UI.Empty_State;
      S.Latest_Build_Result := Editor.Build_Result_Summary.Empty_Summary;
      S.Latest_Build_Result_Focused := False;
      S.Latest_Build_Output_Details :=
        Editor.Build_Output_Details.Empty_Output_Details;


      Summary.Expansions_Requested :=
        Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Snapshot);

      for I in 1 .. Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Snapshot) loop
         Node_Id := Editor.File_Tree.Find_By_Path
           (S.File_Tree,
            Editor.Workspace_Persistence.Expanded_File_Tree_Path (Snapshot, I),
            Node_Found);
         if Node_Found
           and then Editor.File_Tree.Node (S.File_Tree, Node_Id).Kind =
             Editor.File_Tree.Directory_Node
         then
            Editor.File_Tree.Set_Expanded (S.File_Tree, Node_Id, True);
            Summary.Expansions_Restored := Summary.Expansions_Restored + 1;
         else
            Summary.Expansions_Skipped := Summary.Expansions_Skipped + 1;
            Partial := True;
         end if;
      end loop;
      Editor.File_Tree.Rebuild_Visible_Rows (S.File_Tree);
      Validate_File_Tree_View (S);

      Summary.Files_Requested :=
        Editor.Workspace_Persistence.Open_File_Request_Count (Snapshot);

      declare
         Open_Count : constant Natural :=
           Editor.Workspace_Persistence.Open_File_Count (Snapshot);
         type Seen_Path_Array is array (Positive range <>) of Unbounded_String;
         Seen       : Seen_Path_Array (1 .. Natural'Max (Open_Count, 1));
         Seen_Count : Natural := 0;

         function Seen_Before (Path : String) return Boolean is
         begin
            for J in 1 .. Seen_Count loop
               if To_String (Seen (J)) = Path then
                  return True;
               end if;
            end loop;
            return False;
         end Seen_Before;

         procedure Remember (Path : String) is
         begin
            if Seen_Count < Seen'Length then
               Seen_Count := Seen_Count + 1;
               Seen (Seen_Count) := To_Unbounded_String (Path);
            end if;
         end Remember;
      begin
         for I in 1 .. Open_Count loop
            Item := Editor.Workspace_Persistence.Open_File (Snapshot, I);
            if Item.Is_Project_Relative then
               Full_Path := To_Unbounded_String (Workspace_Entry_Path (Snapshot, Item));
            else
               --  Project sessions restore only project-relative file buffers.
               Full_Path := Null_Unbounded_String;
            end if;

            if Length (Full_Path) > 0 and then Seen_Before (To_String (Full_Path)) then
               null;
            elsif Length (Full_Path) > 0 then
               Remember (To_String (Full_Path));
               if Open_File_For_Workspace_Restore
                 (S, To_String (Full_Path), Id, Already_Open)
               then
                  Restored_Files := Restored_Files + 1;
                  Summary.Files_Restored := Summary.Files_Restored + 1;
                  if First_Restored_Id = Editor.Buffers.No_Buffer then
                     First_Restored_Id := Id;
                  end if;

                  if (not Already_Open)
                    or else (not Editor.Buffers.Global_Summary_For (Id).Is_Dirty)
                  then
                     Restore_Caret_And_View_For_Current_Buffer (S, Item);
                  end if;
               else
                  Summary.Files_Skipped := Summary.Files_Skipped + 1;
                  Partial := True;
               end if;
            else
               Summary.Files_Skipped := Summary.Files_Skipped + 1;
               Partial := True;
            end if;
         end loop;
      end;

      if Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot) then
         Full_Path := To_Unbounded_String (Workspace_Active_Path (Snapshot));

         --  an active-file reference is structural selection state,
         --  not an implicit open-file request.  It may only select a buffer
         --  already restored by the workspace open-file list (or already open
         --  under the retained reuse policy).  A stale or out-of-set active
         --  reference falls back deterministically and must not open another
         --  file behind the open-file restore policy.
         Item := Matching_Entry (Snapshot, To_String (Full_Path), Found);
         if Found then
            Id := Editor.Buffers.Global_Find_By_Path (To_String (Full_Path), Found);
            Already_Open := Found;
         else
            Id := Editor.Buffers.No_Buffer;
            Already_Open := False;
         end if;

         if Found then
            Editor.Buffers.Global_Clear_Clean_Reopen_Lifecycle (Id);
            Editor.Buffers.Global_Set_Active_Buffer (Id);
            Editor.Buffers.Load_Global_Active_Into_State (S);
            if (not Already_Open)
              or else (not Editor.Buffers.Global_Summary_For (Id).Is_Dirty)
            then
               Restore_Caret_And_View_For_Current_Buffer (S, Item);
            end if;
         else
            if Summary.Files_Requested = 0 then
               Summary.Files_Skipped := Summary.Files_Skipped + 1;
            end if;
            if First_Restored_Id /= Editor.Buffers.No_Buffer then
               Editor.Buffers.Global_Set_Active_Buffer (First_Restored_Id);
               Editor.Buffers.Load_Global_Active_Into_State (S);
            end if;
            Partial := True;
         end if;
      elsif Restored_Files > 0 then
         if First_Restored_Id /= Editor.Buffers.No_Buffer then
            Editor.Buffers.Global_Set_Active_Buffer (First_Restored_Id);
            Editor.Buffers.Load_Global_Active_Into_State (S);
         end if;
      end if;

      declare
         Requested_File_Tree_Width : constant Natural :=
           Editor.Workspace_Persistence.File_Tree_Panel_Width (Snapshot);
         Requested_Bottom_Height : constant Natural :=
           Editor.Workspace_Persistence.Bottom_Panel_Height (Snapshot);
      begin
         Editor.Panels.Set_Visible
           (S.Panels,
            Editor.Panels.File_Tree_Panel,
            Editor.Workspace_Persistence.File_Tree_Panel_Visible (Snapshot));
         Editor.Panels.Set_Current_Size
           (S.Panels,
            Editor.Panels.File_Tree_Panel,
            Requested_File_Tree_Width);
         if Editor.Panels.Current_Size
              (S.Panels, Editor.Panels.File_Tree_Panel) /= Requested_File_Tree_Width
         then
            Summary.Panel_Values_Clamped := Summary.Panel_Values_Clamped + 1;
            Partial := True;
         end if;

         Editor.Panels.Set_Visible
           (S.Panels,
            Editor.Panels.Bottom_Panel,
            Editor.Workspace_Persistence.Bottom_Panel_Visible (Snapshot));
         Editor.Panels.Set_Current_Size
           (S.Panels,
            Editor.Panels.Bottom_Panel,
            Requested_Bottom_Height);
         if Editor.Panels.Current_Size
              (S.Panels, Editor.Panels.Bottom_Panel) /= Requested_Bottom_Height
         then
            Summary.Panel_Values_Clamped := Summary.Panel_Values_Clamped + 1;
            Partial := True;
         end if;

      Editor.Panels.Set_Bottom_Content
           (S.Panels,
            (if Editor.Workspace_Persistence.Active_Bottom_Content (Snapshot) =
                  Editor.Workspace_Persistence.Workspace_Search_Results_Content
             then Editor.Panels.Search_Results_Content
             else Editor.Panels.Problems_Content));
      end;

      Editor.Quick_Open.Set_Path_Scope
        (S.Quick_Open,
         Editor.Workspace_Persistence.Quick_Open_Path_Scope (Snapshot));
      Editor.Quick_Open.Set_File_Kind_Filter
        (S.Quick_Open,
         Restored_Quick_Open_Filter
           (Editor.Workspace_Persistence.Quick_Open_File_Kind_Filter (Snapshot)));
      if not Editor.Feature_Panel.Set_Active_Feature
        (S.Feature_Panel,
         Restored_Feature_Panel
           (Editor.Workspace_Persistence.Active_Feature_Panel (Snapshot)))
      then
         Partial := True;
      end if;
      Editor.Feature_Panel.Set_Visible
        (S.Feature_Panel,
         Editor.Workspace_Persistence.Feature_Panel_Visible (Snapshot));
      Restore_Recent_Project_Selection (S, Snapshot);

      if Editor.Workspace_Persistence.Open_File_Count (Snapshot) > 0
        and then Restored_Files = 0
      then
         Partial := True;
      end if;

      --  after structural restore, the next user action must see
      --  the restored state directly.  Pending dirty/restore transitions are
      --  transient decision state from the previous interaction and must not
      --  become post-restore command readiness or lifecycle guidance.
      Editor.Pending_Transitions.Clear (S.Pending_Transitions);
      Validate_File_Tree_View (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      --  Fix 4: workspace restore must finish with a deterministic
      --  product focus target.  When at least one file-backed buffer was
      --  restored, the user should continue in the editor at the valid active
      --  buffer.  If a restore attempted file entries but all were stale or
      --  missing, keep the workflow on the File Tree instead of leaving focus
      --  on a stale overlay/panel from before restore.
      if Restored_Files > 0 and then S.File_Info.Has_Path then
         Editor.Focus_Management.Restore_Focus_To_Editor (S);
      elsif Summary.Files_Requested > 0 then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_File_Tree);
      end if;

      if Partial then
         Status := Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore;
      else
         Status := Editor.Workspace_Persistence.Workspace_Persistence_Ok;
      end if;
   end Restore_Workspace_Snapshot;

   procedure Restore_Workspace_Snapshot
     (S        : in out Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : out Editor.Workspace_Persistence.Workspace_Persistence_Status)
   is
      Summary : Editor.Workspace_Persistence.Workspace_Restore_Summary;
   begin
      Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
   end Restore_Workspace_Snapshot;


   procedure Execute_Save_Workspace_State
     (S : in out Editor.State.State_Type)
   is
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Info (S, "No project open");
         return;
      end if;

      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Editor.Workspace_Persistence.Save_To_File_Atomically
        (Snapshot,
         Editor.Workspace_Persistence.Session_File_Path
           (Editor.Project.Root_Path (S.Project)),
         Status);

      if Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok then
         Report_Success (S, Editor.Dirty_Guards.Workspace_State_Saved_Message);
      else
         Report_Error (S, "Save workspace state failed");
      end if;
   end Execute_Save_Workspace_State;

   procedure Execute_Restore_Workspace_State
     (S : in out Editor.State.State_Type)
   is
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Load_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary        : Editor.Workspace_Persistence.Workspace_Restore_Summary;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Info (S, "No project open");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      declare
         Guard : constant Editor.Dirty_Guards.Dirty_Transition_Result :=
           Check_Dirty_Transition
             (S, Editor.Dirty_Guards.Restore_Workspace_Transition);
      begin
         if not Editor.Dirty_Guards.Is_Allowed (Guard) then
            Set_Pending_Dirty_Transition
              (S,
               Pending_Target_For
                 (Editor.Pending_Transitions.Pending_Restore_Workspace,
                  Path    => Editor.Project.Root_Path (S.Project),
                  Display => "workspace state"),
               Guard);
            return;
         end if;
      end;

      Editor.Workspace_Persistence.Load_From_File
        (Editor.Workspace_Persistence.Session_File_Path
           (Editor.Project.Root_Path (S.Project)),
         Snapshot,
         Load_Status);

      case Load_Status is
         when Editor.Workspace_Persistence.Workspace_Persistence_Ok
            | Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore =>
            if Editor.Workspace_Persistence.Has_Project_Root (Snapshot)
              and then Editor.Workspace_Persistence.Project_Root (Snapshot) /=
                Editor.Project.Root_Path (S.Project)
            then
               Report_Error (S, "Workspace could not be restored.");
               return;
            end if;

            Restore_Workspace_Snapshot (S, Snapshot, Restore_Status, Summary);
            if Restore_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok
              or else Restore_Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore
            then
               Editor.Pending_Transitions.Clear (S.Pending_Transitions);
            end if;
            if Load_Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore
              or else Restore_Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore
            then
               Mark_Restore_Summary_Current (S, Summary);
               Report_Restore_Warning (S, Restore_Summary_Message (Summary, True));
            elsif Restore_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok then
               Mark_Restore_Summary_Current (S, Summary);
               Report_Restore_Success (S, Restore_Summary_Message (Summary, False));
            else
               Report_Workspace_Load_Status (S, Restore_Status);
            end if;
         when Editor.Workspace_Persistence.Workspace_Persistence_Not_Found =>
            Report_Info (S, "No workspace state");
         when Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format =>
            Report_Error (S, "Workspace could not be restored.");
         when Editor.Workspace_Persistence.Workspace_Persistence_Unsupported_Version =>
            Report_Error (S, "Workspace could not be restored.");
         when Editor.Workspace_Persistence.Workspace_Persistence_Read_Error =>
            Report_Error (S, "Load workspace state failed");
         when Editor.Workspace_Persistence.Workspace_Persistence_Write_Error =>
            Report_Error (S, "Load workspace state failed");
      end case;
   end Execute_Restore_Workspace_State;

   procedure Execute_Clear_Workspace_State
     (S : in out Editor.State.State_Type)
   is
      Path : Unbounded_String;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Report_Info (S, "No project open");
         return;
      end if;

      Path := To_Unbounded_String
        (Editor.Workspace_Persistence.Session_File_Path
           (Editor.Project.Root_Path (S.Project)));

      if not Ada.Directories.Exists (To_String (Path)) then
         Invalidate_Pending_Transition_If_Stale (S);
         Report_Info (S, "No workspace state");
         return;
      end if;

      if not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         Editor.Pending_Transitions.Set_Pending
           (S.Pending_Transitions,
            Pending_Target_For
              (Editor.Pending_Transitions.Pending_Clear_Workspace_State,
               Path    => Editor.Project.Root_Path (S.Project),
               Display => "workspace state"),
            (Dirty_Count       => 0,
             Untitled_Count    => 0,
             File_Backed_Count => 0));
         Report_Warning (S, "Clear workspace state? Retry to confirm.");
         return;
      elsif Editor.Pending_Transitions.Target_Kind (S.Pending_Transitions) /=
        Editor.Pending_Transitions.Pending_Clear_Workspace_State
      then
         Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      elsif not Pending_Target_Is_Valid
        (S, Editor.Pending_Transitions.Target (S.Pending_Transitions))
      then
         Editor.Pending_Transitions.Clear (S.Pending_Transitions);
         Report_Info (S, "No workspace state");
         return;
      end if;

      begin
         Ada.Directories.Delete_File (To_String (Path));
         Editor.Pending_Transitions.Clear (S.Pending_Transitions);
         Report_Success (S, "Workspace cleared.");
      exception
         when others =>
            Report_Error (S, "Workspace could not be cleared.");
      end;
   end Execute_Clear_Workspace_State;

   function Execute_Workspace_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      case Id is
         when Command_Save_Workspace_State =>
            Execute_Save_Workspace_State (S);

         when Command_Restore_Workspace_State =>
            Execute_Restore_Workspace_State (S);

         when Command_Clear_Workspace_State =>
            Execute_Clear_Workspace_State (S);

         when others =>
            raise Program_Error with "unsupported workspace result command";
      end case;

      Editor.Render_Cache.Invalidate_All;

      if Id = Command_Restore_Workspace_State then
         declare
            Found : Boolean := False;
            Msg   : Editor.Messages.Editor_Message;
         begin
            Msg := Editor.Messages.Active_Message (S.Messages, Found);
            if Found
              and then Editor.Messages.Severity (Msg) =
                Editor.Messages.Error_Message
            then
               return Editor.Command_Execution.Failed (Id);
            end if;
         end;
      end if;

      return Editor.Command_Execution.Executed (Id);
   end Execute_Workspace_Result_Command;

   procedure Execute_Workspace_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
   begin
      case Kind is
         when Save_Workspace_State =>
            Execute_Save_Workspace_State (S);

         when Restore_Workspace_State =>
            Execute_Restore_Workspace_State (S);

         when Clear_Workspace_State =>
            Execute_Clear_Workspace_State (S);

         when others =>
            raise Program_Error with "unsupported workspace command kind";
      end case;
   end Execute_Workspace_Kind;

end Editor.Executor.Workspace_Commands;
