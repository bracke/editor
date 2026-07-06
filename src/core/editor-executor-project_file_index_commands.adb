with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Executor;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.File_Tree;
use type Editor.File_Tree.File_Tree_Node_Id;
use type Editor.File_Tree.File_Tree_Scan_Status;
with Editor.File_Tree_View;
with Editor.Focus_Management;
with Editor.Project;
use type Editor.Project.Project_File_Refresh_Status;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Project_File_Index_Commands is

   function Natural_Image_Trimmed (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Natural_Image_Trimmed;

   function File_Count_Text (Count : Natural) return String is
   begin
      if Count = 1 then
         return "1 file";
      else
         return Natural_Image_Trimmed (Count) & " files";
      end if;
   end File_Count_Text;

   function Format_Project_File_Refresh_Message
     (Result : Editor.Project.Project_File_Refresh_Result) return String
   is
      Text : Unbounded_String := To_Unbounded_String
        ("Project files refreshed: " & File_Count_Text (Result.Total_Count));
   begin
      if Result.Added_Count > 0 then
         Append (Text, "; added " & Natural_Image_Trimmed (Result.Added_Count));
      end if;
      if Result.Removed_Count > 0 then
         Append (Text, "; removed " & Natural_Image_Trimmed (Result.Removed_Count));
      end if;
      if Result.Ignored_Path_Count > 0 then
         Append
           (Text,
            "; excluded " & Natural_Image_Trimmed (Result.Ignored_Path_Count)
            & (if Result.Ignored_Path_Count = 1 then " ignored path" else " ignored paths"));
      end if;
      if Result.Invalid_Ignore_Pattern_Count > 0 then
         Append
           (Text,
            "; ignored " & Natural_Image_Trimmed (Result.Invalid_Ignore_Pattern_Count)
            & (if Result.Invalid_Ignore_Pattern_Count = 1 then " invalid pattern" else " invalid patterns"));
      end if;
      if Result.Skipped_Directory_Count > 0 then
         Append
           (Text,
            "; skipped " & Natural_Image_Trimmed (Result.Skipped_Directory_Count)
            & (if Result.Skipped_Directory_Count = 1 then " directory" else " directories"));
      end if;
      return To_String (Text);
   end Format_Project_File_Refresh_Message;

   function Format_Project_File_Summary_Message
     (S : Editor.State.State_Type) return String
   is
      Count : constant Natural := Editor.Project.Known_File_Count (S.Project);
   begin
      if not Editor.Project.Has_Project (S.Project) then
         return "No project open";
      elsif Count = 0 then
         return "No project open.";
      elsif Editor.Project.Has_Last_Refresh_Summary (S.Project) then
         declare
            Summary : constant Editor.Project.Project_File_Refresh_Result :=
              Editor.Project.Last_Refresh_Summary (S.Project);
            Text : Unbounded_String := To_Unbounded_String
              ("Project files: " & Natural_Image_Trimmed (Count) & " known files");
         begin
            if Summary.Added_Count > 0 or else Summary.Removed_Count > 0 then
               Append (Text, "; last refresh");
               if Summary.Added_Count > 0 then
                  Append (Text, " added " & Natural_Image_Trimmed (Summary.Added_Count));
               end if;
               if Summary.Removed_Count > 0 then
                  if Summary.Added_Count > 0 then
                     Append (Text, ",");
                  end if;
                  Append (Text, " removed " & Natural_Image_Trimmed (Summary.Removed_Count));
               end if;
            end if;
            if Summary.Ignored_Path_Count > 0 then
               Append
                 (Text,
                  (if Summary.Added_Count > 0 or else Summary.Removed_Count > 0 then ";" else "; last refresh")
                  & " excluded " & Natural_Image_Trimmed (Summary.Ignored_Path_Count)
                  & (if Summary.Ignored_Path_Count = 1 then " ignored path" else " ignored paths"));
            end if;
            if Summary.Invalid_Ignore_Pattern_Count > 0 then
               Append
                 (Text,
                  "; last refresh ignored "
                  & Natural_Image_Trimmed (Summary.Invalid_Ignore_Pattern_Count)
                  & (if Summary.Invalid_Ignore_Pattern_Count = 1 then " invalid pattern" else " invalid patterns"));
            end if;
            return To_String (Text);
         end;
      else
         return "Project files: " & Natural_Image_Trimmed (Count) & " known files";
      end if;
   end Format_Project_File_Summary_Message;

   function File_Tree_Refresh_Failure_Message
     (Result : Editor.File_Tree.File_Tree_Scan_Result) return String
   is
   begin
      case Result.Status is
         when Editor.File_Tree.File_Tree_Scan_Ok =>
            return "ok";
         when Editor.File_Tree.File_Tree_No_Project =>
            return "No project open";
         when Editor.File_Tree.File_Tree_Invalid_Root
            | Editor.File_Tree.File_Tree_Root_Not_Found
            | Editor.File_Tree.File_Tree_Root_Not_Directory =>
            return "Project root unavailable";
         when Editor.File_Tree.File_Tree_Permission_Denied =>
            return "Permission denied";
         when Editor.File_Tree.File_Tree_Read_Error =>
            return "File Tree unavailable";
      end case;
   end File_Tree_Refresh_Failure_Message;

   procedure Execute_Refresh_Project_Files
     (S : in out Editor.State.State_Type)
   is
      Result : Editor.Project.Project_File_Refresh_Result;
   begin
      Editor.Project.Refresh_Known_Files (S.Project, Result);
      if Result.Status = Editor.Project.Project_File_Refresh_Ok then
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         if Editor.Quick_Open.Is_Open (S.Quick_Open) then
            Editor.Executor.Recompute_Quick_Open (S);
         end if;
         Editor.Project_Search.Clear_Results_Preserve_Query (S.Project_Search);
         Editor.Executor.Shared_Services.Report_Success
           (S, Format_Project_File_Refresh_Message (Result));
      else
         Editor.Executor.Shared_Services.Report_Error
           (S, "Could not refresh project files: "
            & (if Length (Result.Failure_Reason) > 0
               then To_String (Result.Failure_Reason)
               else "filesystem error"));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Refresh_Project_Files;

   procedure Execute_Project_Files_Summary
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Shared_Services.Report_Info (S, Format_Project_File_Summary_Message (S));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Files_Summary;

   procedure Execute_Reveal_Active_File_In_Tree
     (S : in out Editor.State.State_Type)
   is
      Path       : Unbounded_String := Null_Unbounded_String;
      Found      : Boolean := False;
      Node       : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Parent     : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Row_Found  : Boolean := False;
      Row        : Natural := 0;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      if S.Active_Buffer_Token = Natural (Editor.Buffers.Global_Active_Buffer) then
         Editor.Buffers.Sync_Global_Active_From_State (S);
      elsif Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer then
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;

      if Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      elsif not S.File_Info.Has_Path or else Length (S.File_Info.Path) = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "Active buffer has no file path");
         return;
      elsif not Editor.Project.Has_Project (S.Project) then
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      end if;

      Path := S.File_Info.Path;
      if not Ada.Directories.Exists (To_String (Path)) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Active file no longer exists");
         return;
      elsif not Editor.Project.Is_Under_Project (S.Project, To_String (Path)) then
         Editor.Executor.Shared_Services.Report_Info (S, "Active file is outside the current project");
         return;
      elsif Editor.File_Tree.Is_Empty (S.File_Tree) then
         Editor.Executor.Shared_Services.Report_Info (S, "File Tree unavailable");
         return;
      end if;

      declare
         Relative_Path : constant String :=
           Editor.Project.Relative_Path (S.Project, To_String (Path));
      begin
         Node := Editor.File_Tree.Find_By_Path (S.File_Tree, Relative_Path, Found);
      end;
      if not Found or else Node = Editor.File_Tree.No_File_Tree_Node then
         Editor.Executor.Shared_Services.Report_Info (S, "File Tree refresh required");
         return;
      end if;

      Parent := Editor.File_Tree.Node (S.File_Tree, Node).Parent;
      while Parent /= Editor.File_Tree.No_File_Tree_Node loop
         Editor.File_Tree.Set_Expanded (S.File_Tree, Parent, True);
         Parent := Editor.File_Tree.Node (S.File_Tree, Parent).Parent;
      end loop;
      Editor.File_Tree.Rebuild_Visible_Rows (S.File_Tree);

      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      if Row_Found then
         Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
         Editor.File_Tree_View.Ensure_Selected_Row_Visible
           (S.File_Tree_View, S.File_Tree, Editor.File_Tree.Visible_Row_Count (S.File_Tree));
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_File_Tree);
         Editor.Executor.Shared_Services.Report_Success (S, "Active file revealed in File Tree");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "File Tree row unavailable");
      end if;
   end Execute_Reveal_Active_File_In_Tree;

   procedure Execute_Refresh_File_Tree
     (S : in out Editor.State.State_Type)
   is
      Tree   : Editor.File_Tree.File_Tree_State;
      Result : Editor.File_Tree.File_Tree_Scan_Result;
      Selected_Found : Boolean := False;
      Selected_Node  : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Selected_Path  : Unbounded_String := Null_Unbounded_String;
      Restored_Row   : Natural := 0;
      Selection_Disappeared : Boolean := False;
      Default_Collapsed_Load : constant Boolean :=
        Editor.File_Tree.Is_Empty (S.File_Tree)
        or else Editor.File_Tree.Expanded_Node_Count (S.File_Tree) <= 1;
   begin
      if not Editor.Project.Has_Project (S.Project) then
         Editor.File_Tree.Clear (S.File_Tree);
         Editor.File_Tree_View.Clear_View (S.File_Tree_View);
         Editor.Executor.Shared_Services.Report_Warning (S, "No project open");
         return;
      end if;

      Selected_Node := Editor.File_Tree_View.Node_For_Row
        (S.File_Tree,
         Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View),
         Selected_Found);
      if Selected_Found then
         Selected_Path := Editor.File_Tree.Node
           (S.File_Tree, Selected_Node).Relative_Path;
      end if;

      Tree := Editor.File_Tree.Scan_Project
        (Editor.Project.Root_Path (S.Project));
      Result := Editor.File_Tree.Scan_Status (Tree);

      if Result.Status = Editor.File_Tree.File_Tree_Scan_Ok then
         Editor.File_Tree.Preserve_Expanded_Paths_From
           (Tree   => Tree,
            Source => S.File_Tree);
         if Default_Collapsed_Load
           and then (Length (Selected_Path) = 0
                     or else To_String (Selected_Path) = ".")
         then
            Editor.File_Tree.Expand_File_Ancestors (Tree);
         end if;

         S.File_Tree := Tree;
         Editor.Executor.Populate_Project_Known_Files_From_File_Tree (S);

         if Length (Selected_Path) > 0 then
            declare
               New_Found : Boolean := False;
               New_Node  : constant Editor.File_Tree.File_Tree_Node_Id :=
                 Editor.File_Tree.Find_By_Path
                   (S.File_Tree, To_String (Selected_Path), New_Found);
               Row_Found : Boolean := False;
            begin
               if New_Found then
                  Restored_Row := Editor.File_Tree_View.Row_For_Node
                    (S.File_Tree, New_Node, Row_Found);
                  if Row_Found then
                     Editor.File_Tree_View.Set_Selected_Row_Index
                       (S.File_Tree_View, Restored_Row);
                  else
                     Editor.File_Tree_View.Clear_View (S.File_Tree_View);
                     Selection_Disappeared := True;
                  end if;
               else
                  Editor.File_Tree_View.Clear_View (S.File_Tree_View);
                  Selection_Disappeared := True;
               end if;
            end;
         end if;

         Editor.Executor.Validate_File_Tree_View (S);
         if Selection_Disappeared then
            Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 0);
            Editor.File_Tree_View.Set_Top_Row (S.File_Tree_View, 1);
         end if;
         Editor.Project_Search.Mark_Stale (S.Project_Search);
         if Editor.Quick_Open.Is_Open (S.Quick_Open) then
            Editor.Executor.Recompute_Quick_Open (S);
         end if;

         if Ada.Strings.Fixed.Index
           (To_String (Result.Error_Text), "limit reached") /= 0
         then
            Editor.Executor.Shared_Services.Report_Warning (S, "File Tree refresh limit reached");
         elsif Selection_Disappeared then
            Editor.Executor.Shared_Services.Report_Warning
              (S, "File tree refreshed; selected path no longer exists");
         elsif Length (Result.Error_Text) > 0 then
            Editor.Executor.Shared_Services.Report_Warning
              (S, "File tree refreshed with warnings: " &
                    To_String (Result.Error_Text));
         else
            Editor.Executor.Shared_Services.Report_Success (S, "File tree refreshed");
         end if;
      else
         Editor.File_Tree.Clear (S.File_Tree);
         Editor.File_Tree_View.Clear_View (S.File_Tree_View);
         Editor.Project.Clear_Known_Files (S.Project);
         Editor.Project_Search.Mark_Stale (S.Project_Search);
         if Editor.Quick_Open.Is_Open (S.Quick_Open) then
            Editor.Executor.Recompute_Quick_Open (S);
         end if;
         Editor.Executor.Shared_Services.Report_Error
           (S, "File tree refresh failed: " & File_Tree_Refresh_Failure_Message (Result));
      end if;
   end Execute_Refresh_File_Tree;

end Editor.Executor.Project_File_Index_Commands;
