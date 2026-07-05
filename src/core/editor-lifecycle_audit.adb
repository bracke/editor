with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.File_Tree;
with Editor.Messages;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Recent_Projects;
with Editor.Search_Results;
with Editor.Settings;
with Editor.Command_Palette;

package body Editor.Lifecycle_Audit is

   use type Editor.Buffers.Buffer_Id;

   function Count_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Count_Image;

   function Pending_Kind_Image
     (Kind : Editor.Pending_Transitions.Pending_Transition_Kind) return String
   is
   begin
      case Kind is
         when Editor.Pending_Transitions.No_Pending_Transition =>
            return "none";
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            return "close-buffer";
         when Editor.Pending_Transitions.Pending_Close_All_Buffers =>
            return "close-all-buffers";
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return "close-other-buffers";
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
            return "reload-active-buffer";
         when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            return "revert-active-buffer";
         when Editor.Pending_Transitions.Pending_Close_Project =>
            return "close-project";
         when Editor.Pending_Transitions.Pending_Open_Project =>
            return "open-project";
         when Editor.Pending_Transitions.Pending_Switch_Project =>
            return "switch-project";
         when Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return "open-recent-project";
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return "restore-workspace";
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return "clear-workspace-state";
         when Editor.Pending_Transitions.Pending_Clear_Project =>
            return "clear-project";
      end case;
   end Pending_Kind_Image;

   procedure Clear
     (Result : in out Lifecycle_Audit_Result)
   is
   begin
      Result.Failures.Clear;
   end Clear;

   procedure Add_Failure
     (Result  : in out Lifecycle_Audit_Result;
      Message : String)
   is
   begin
      Result.Failures.Append (To_Unbounded_String (Message));
   end Add_Failure;

   function Status
     (Result : Lifecycle_Audit_Result) return Lifecycle_Audit_Status
   is
   begin
      if Result.Failures.Is_Empty then
         return Lifecycle_Audit_Ok;
      else
         return Lifecycle_Audit_Failed;
      end if;
   end Status;

   function Failure_Count
     (Result : Lifecycle_Audit_Result) return Natural
   is
   begin
      return Natural (Result.Failures.Length);
   end Failure_Count;

   function Failure
     (Result : Lifecycle_Audit_Result;
      Index  : Positive) return String
   is
   begin
      if Index > Natural (Result.Failures.Length) then
         return "";
      end if;

      return To_String (Result.Failures (Natural (Index - 1)));
   end Failure;

   function Summary
     (Result : Lifecycle_Audit_Result) return String
   is
   begin
      if Result.Failures.Is_Empty then
         return "Lifecycle audit ok";
      elsif Natural (Result.Failures.Length) = 1 then
         return "Lifecycle audit failed: " & To_String (Result.Failures (0));
      else
         return "Lifecycle audit failed: "
           & Count_Image (Natural (Result.Failures.Length)) & " failures";
      end if;
   end Summary;

   function State_Summary
     (State : Editor.State.State_Type) return Lifecycle_State_Summary
   is
      Registry_Count : constant Natural := Editor.Buffers.Global_Count;
      Dirty_Count    : Natural := 0;
      File_Dirty     : Natural := 0;
      Untitled_Dirty : Natural := 0;
      Buffer_Count   : Natural := Registry_Count;
      Active_Exists  : Boolean := False;
      Search_View    : constant Editor.Search_Results.Search_Results_Snapshot :=
        Editor.Search_Results.Build_Snapshot (State.Project_Search, (others => <>));
      Pending_Kind   : constant Editor.Pending_Transitions.Pending_Transition_Kind :=
        Editor.Pending_Transitions.Target_Kind (State.Pending_Transitions);
   begin
      if Registry_Count > 0 then
         Dirty_Count := Editor.Buffers.Global_Dirty_Buffer_Count;
         File_Dirty := Editor.Buffers.Global_Dirty_File_Backed_Buffer_Count;
         Untitled_Dirty := Editor.Buffers.Global_Dirty_Untitled_Buffer_Count;
         Active_Exists := Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer;
      else
         Buffer_Count := (if Editor.State.Has_Active_Buffer (State) then 1 else 0);
         Dirty_Count := (if State.File_Info.Dirty then 1 else 0);
         File_Dirty :=
           (if State.File_Info.Dirty and then State.File_Info.Has_Path then 1 else 0);
         Untitled_Dirty :=
           (if State.File_Info.Dirty and then not State.File_Info.Has_Path then 1 else 0);
         Active_Exists := Editor.State.Has_Active_Buffer (State);
      end if;

      return
        (Has_Project                 => Editor.Project.Has_Project (State.Project),
         Project_Display             => To_Unbounded_String (Editor.Project.Display_Name (State.Project)),
         Buffer_Count                => Buffer_Count,
         Dirty_Buffer_Count          => Dirty_Count,
         Dirty_File_Backed_Count     => File_Dirty,
         Dirty_Untitled_Count        => Untitled_Dirty,
         Active_Buffer_Exists        => Active_Exists,
         File_Tree_Node_Count        => Editor.File_Tree.Node_Count (State.File_Tree),
         File_Tree_Expansion_Count   => Editor.File_Tree.Expanded_Node_Count (State.File_Tree),
         Project_Search_Result_Count => Editor.Project_Search.Result_Count (State.Project_Search),
         Search_Results_Row_Count    => Editor.Search_Results.Row_Count (Search_View),
         Recent_Project_Count        => Editor.Recent_Projects.Count (State.Recent_Projects),
         Has_Pending_Transition      => Editor.Pending_Transitions.Has_Pending (State.Pending_Transitions),
         Pending_Kind_Name           => To_Unbounded_String (Pending_Kind_Image (Pending_Kind)),
         Message_Count               => Editor.Messages.Count (State.Messages));
   end State_Summary;


   function Settings_Lifecycle_Summary_For
     (State : Editor.State.State_Type) return Settings_Lifecycle_Summary
   is
      Normalized : Editor.Settings.Settings_Model := State.Settings;
      Palette    : constant Editor.Command_Palette.Command_Palette_Config :=
        Editor.Command_Palette.Current_Config;
      Dirty_Count : Natural := 0;
   begin
      if Editor.Buffers.Global_Count > 0 then
         Dirty_Count := Editor.Buffers.Global_Dirty_Buffer_Count;
      else
         Dirty_Count := (if State.File_Info.Dirty then 1 else 0);
      end if;

      --  Normalize the local copy only: the audit projection must never repair
      --  or apply the live editor settings model.
      Editor.Settings.Normalize (Normalized);

      return
        (Theme_Id                      => To_Unbounded_String (Editor.Settings.Theme_Id (Normalized)),
         Line_Number_Mode              => To_Unbounded_String (Editor.Settings.Line_Number_Mode_Name (Normalized)),
         Cursor_Style                  => To_Unbounded_String (Editor.Settings.Cursor_Style_Name (Normalized)),
         Cursor_Blink_Enabled          => Editor.Settings.Cursor_Blink (Normalized),
         Minimap_Visible               => Editor.Settings.Minimap_Visible (Normalized),
         Scrollbars_Visible            => Editor.Settings.Scrollbars_Visible (Normalized),
         Command_Palette_Show_Bindings => Palette.Show_Keybindings,
         Has_Project                   => Editor.Project.Has_Project (State.Project),
         Dirty_Buffer_Count            => Dirty_Count,
         Has_Pending_Transition        => Editor.Pending_Transitions.Has_Pending (State.Pending_Transitions),
         Recent_Project_Count          => Editor.Recent_Projects.Count (State.Recent_Projects));
   end Settings_Lifecycle_Summary_For;

   procedure Check_Equal
     (Result  : in out Lifecycle_Audit_Result;
      Name    : String;
      Before  : Natural;
      After   : Natural;
      Context : String)
   is
   begin
      if Before /= After then
         Add_Failure
           (Result,
            Context & ": " & Name & " changed from "
            & Count_Image (Before) & " to " & Count_Image (After));
      end if;
   end Check_Equal;

   procedure Check_Equal
     (Result  : in out Lifecycle_Audit_Result;
      Name    : String;
      Before  : Boolean;
      After   : Boolean;
      Context : String)
   is
   begin
      if Before /= After then
         Add_Failure
           (Result,
            Context & ": " & Name & " changed");
      end if;
   end Check_Equal;

   procedure Check_Equal
     (Result  : in out Lifecycle_Audit_Result;
      Name    : String;
      Before  : Unbounded_String;
      After   : Unbounded_String;
      Context : String)
   is
   begin
      if Before /= After then
         Add_Failure
           (Result,
            Context & ": " & Name & " changed from '"
            & To_String (Before) & "' to '" & To_String (After) & "'");
      end if;
   end Check_Equal;

   procedure Expect_No_Core_Lifecycle_Mutation
     (Result  : in out Lifecycle_Audit_Result;
      Before  : Lifecycle_State_Summary;
      After   : Lifecycle_State_Summary;
      Context : String)
   is
   begin
      Check_Equal (Result, "has project", Before.Has_Project, After.Has_Project, Context);
      Check_Equal (Result, "project display", Before.Project_Display, After.Project_Display, Context);
      Check_Equal (Result, "buffer count", Before.Buffer_Count, After.Buffer_Count, Context);
      Check_Equal (Result, "dirty buffer count", Before.Dirty_Buffer_Count, After.Dirty_Buffer_Count, Context);
      Check_Equal
        (Result, "dirty file-backed count",
         Before.Dirty_File_Backed_Count,
         After.Dirty_File_Backed_Count, Context);
      Check_Equal (Result, "dirty untitled count", Before.Dirty_Untitled_Count, After.Dirty_Untitled_Count, Context);
      Check_Equal (Result, "active buffer", Before.Active_Buffer_Exists, After.Active_Buffer_Exists, Context);
      Check_Equal (Result, "file tree nodes", Before.File_Tree_Node_Count, After.File_Tree_Node_Count, Context);
      Check_Equal
        (Result, "file tree expansions",
         Before.File_Tree_Expansion_Count,
         After.File_Tree_Expansion_Count, Context);
      Check_Equal
        (Result, "project-search results",
         Before.Project_Search_Result_Count,
         After.Project_Search_Result_Count, Context);
      Check_Equal
        (Result, "search-results rows",
         Before.Search_Results_Row_Count,
         After.Search_Results_Row_Count, Context);
      Check_Equal (Result, "recent projects", Before.Recent_Project_Count, After.Recent_Project_Count, Context);
      Check_Equal (Result, "pending transition", Before.Has_Pending_Transition, After.Has_Pending_Transition, Context);
      Check_Equal (Result, "pending kind", Before.Pending_Kind_Name, After.Pending_Kind_Name, Context);
   end Expect_No_Core_Lifecycle_Mutation;

end Editor.Lifecycle_Audit;
