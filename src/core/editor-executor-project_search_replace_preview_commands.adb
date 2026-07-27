with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Focus_Management;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Render_Cache;
with Editor.State;

with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;

package body Editor.Executor.Project_Search_Replace_Preview_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Project_Search.Project_Replace_Preview_Status;
   use type Editor.Project_Search.Project_Search_Result_Id;
   use type Ada.Directories.File_Kind;

   function Image_Of (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Image_Of;

   procedure Show_Search_Results_Panel
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Search_Results_Content);
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, True);
      if Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel.Panel_Focus) then
         Editor.Focus_Management.Set_Focus_Owner
           (S, Editor.Focus_Management.Focus_Project_Search_Results);
      end if;
      Editor.Panels.Set_Current (S.Panels);
      Editor.Render_Cache.Invalidate_All;
   end Show_Search_Results_Panel;

   function Mark_Dirty_Open_Project_Replace_Targets_Stale
     (S : in out Editor.State.State_Type) return Natural
   is
      Row   : Editor.Project_Search.Project_Replace_Preview_Row;
      Count : Natural := 0;
   begin
      for I in 1 .. Editor.Project_Search.Replace_Preview_Count (S.Surface.Project_Search) loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (S.Surface.Project_Search, I);
         if Row.Search_Result_Id /= Editor.Project_Search.No_Project_Search_Result
           and then not Row.Stale
           and then not Row.Invalid
           and then Editor.Buffers.Global_File_Is_Dirty
             (To_String (Row.Absolute_Path))
         then
            Editor.Project_Search.Mark_Replace_Preview_Stale_For_Absolute_File
              (S.Surface.Project_Search, To_String (Row.Absolute_Path));
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Mark_Dirty_Open_Project_Replace_Targets_Stale;

   function Project_Search_Replace_Pending_Blocked
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions);
   end Project_Search_Replace_Pending_Blocked;

   procedure Report_Project_Search_Replace_Pending_Blocked
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Warning (S, "Command unavailable while confirmation is pending");
      Editor.Render_Cache.Invalidate_All;
   end Report_Project_Search_Replace_Pending_Blocked;

   procedure Execute_Project_Search_Replace_Preview
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Project_Search.Project_Replace_Preview_Status;
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Report_Warning (S, "No project open");
         Editor.Render_Cache.Invalidate_All;
         return;
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Project_Search_Replace_Pending_Blocked (S);
         return;
      end if;

      Editor.Project_Search.Generate_Replace_Preview (S.Surface.Project_Search, Status);
      if Status = Editor.Project_Search.Project_Replace_Preview_Ok
        and then Mark_Dirty_Open_Project_Replace_Targets_Stale (S) > 0
      then
         Status := Editor.Project_Search.Project_Replace_Search_Stale;
      end if;
      Show_Search_Results_Panel (S);
      case Status is
         when Editor.Project_Search.Project_Replace_Preview_Ok =>
            Report_Info
              (S, "Preview: "
               & Natural'Image (Editor.Project_Search.Included_Replacement_Count (S.Surface.Project_Search))
               & " replacements in"
               & Natural'Image (Editor.Project_Search.Included_Replacement_File_Count (S.Surface.Project_Search))
               & " files.");
         when Editor.Project_Search.Project_Replace_No_Search_Results =>
            Report_Info (S, "No search results to replace.");
         when Editor.Project_Search.Project_Replace_Search_Stale =>
            Report_Warning (S, "Search results are stale; rerun search.");
         when Editor.Project_Search.Project_Replace_Overlapping_Matches =>
            Report_Warning (S, "Replacement preview has overlapping matches; refine search.");
         when Editor.Project_Search.Project_Replace_Invalid_Replacement_Text =>
            Report_Warning (S, "Replacement text must be single-line.");
         when Editor.Project_Search.Project_Replace_Invalid_Target =>
            Report_Warning (S, "Replacement preview contains invalid target ranges; rerun search.");
         when others =>
            Report_Warning (S, "Replacement preview unavailable.");
      end case;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Preview;

   procedure Execute_Project_Search_Replace_Toggle_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Surface.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Surface.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Toggle_Selected_Replacement (S.Surface.Project_Search);
               Report_Info (S, "Replacement selection toggled");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Toggle_Selected;

   procedure Execute_Project_Search_Replace_Include_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Surface.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Surface.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Include_Selected_Replacement (S.Surface.Project_Search);
               Report_Info (S, "Replacement included");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_Selected;

   procedure Execute_Project_Search_Replace_Exclude_Selected
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Selected_Replace_Preview_Index (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At
                (S.Surface.Project_Search,
                 Editor.Project_Search.Selected_Replace_Preview_Index
                   (S.Surface.Project_Search));
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Exclude_Selected_Replacement (S.Surface.Project_Search);
               Report_Info (S, "Replacement excluded");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_Selected;

   procedure Execute_Project_Search_Replace_Include_File
     (S : in out Editor.State.State_Type)
   is
      Index : constant Natural :=
        Editor.Project_Search.Selected_Replace_Preview_Index (S.Surface.Project_Search);
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Index = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At (S.Surface.Project_Search, Index);
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Include_File_Replacements
                 (S.Surface.Project_Search, To_String (Row.Relative_Path));
               Report_Info (S, "Replacement file included");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_File;

   procedure Execute_Project_Search_Replace_Exclude_File
     (S : in out Editor.State.State_Type)
   is
      Index : constant Natural :=
        Editor.Project_Search.Selected_Replace_Preview_Index (S.Surface.Project_Search);
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Index = 0 then
         Report_Warning (S, "No replacement selected");
      else
         declare
            Row : constant Editor.Project_Search.Project_Replace_Preview_Row :=
              Editor.Project_Search.Replace_Preview_Row_At (S.Surface.Project_Search, Index);
         begin
            if Row.Search_Result_Id = Editor.Project_Search.No_Project_Search_Result then
               Report_Warning (S, "No replacement selected");
            elsif Row.Stale then
               Report_Warning (S, "Selected replacement is stale");
            elsif Row.Invalid then
               Report_Warning (S, "Selected replacement is invalid");
            else
               Editor.Project_Search.Exclude_File_Replacements
                 (S.Surface.Project_Search, To_String (Row.Relative_Path));
               Report_Info (S, "Replacement file excluded");
            end if;
         end;
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_File;

   procedure Execute_Project_Search_Replace_Include_All
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      elsif Editor.Project_Search.Eligible_Replacement_Count (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No eligible replacements");
      else
         Editor.Project_Search.Include_All_Replacements (S.Surface.Project_Search);
         Report_Info (S, "All eligible replacement preview rows included");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Include_All;

   procedure Execute_Project_Search_Replace_Exclude_All
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
         Report_Warning (S, "No project open");
      elsif Project_Search_Replace_Pending_Blocked (S) then
         Report_Warning (S, "Command unavailable while confirmation is pending");
      elsif Editor.Project_Search.Replace_Preview_Count (S.Surface.Project_Search) = 0 then
         Report_Warning (S, "No replacement preview");
      elsif Editor.Project_Search.Replace_Preview_Is_Stale (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement preview is stale; rerun search.");
      elsif not Editor.Project_Search.Replace_Text_Is_Valid (S.Surface.Project_Search) then
         Report_Warning (S, "Replacement text must be single-line.");
      else
         Editor.Project_Search.Exclude_All_Replacements (S.Surface.Project_Search);
         Report_Info (S, "All replacement preview rows excluded");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Project_Search_Replace_Exclude_All;

end Editor.Executor.Project_Search_Replace_Preview_Commands;
