with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Executor.Quick_Open_Commands;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Project;
with Editor.Quick_Open;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Quick_Open_Scope_Commands is

   function Quick_Open_Scope_Has_Parent_Traversal (Text : String) return Boolean is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
      Segment : Unbounded_String := Null_Unbounded_String;

      function Segment_Is_Parent return Boolean is
      begin
         return To_String (Segment) = "..";
      end Segment_Is_Parent;
   begin
      for Ch of Trimmed loop
         if Ch = '/' or else Ch = '\' then
            if Segment_Is_Parent then
               return True;
            end if;
            Segment := Null_Unbounded_String;
         else
            Append (Segment, Ch);
         end if;
      end loop;
      return Segment_Is_Parent;
   end Quick_Open_Scope_Has_Parent_Traversal;

   procedure Execute_Quick_Open_Scope_Set
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
      Scope : constant String := Editor.Quick_Open.Normalize_Quick_Open_Scope (Text);
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
            Editor.Executor.Shared_Services.Report_Info (S, "No project open");
         elsif Quick_Open_Scope_Has_Parent_Traversal (Text) then
            Editor.Executor.Shared_Services.Report_Info (S, "Invalid Quick Open scope");
         else
            Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, Text);
            Editor.Executor.Quick_Open_Commands.Recompute_Quick_Open (S);
            if Scope'Length = 0 then
               Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope cleared");
            else
               Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope: " & Scope);
            end if;
         end if;
      end if;
   end Execute_Quick_Open_Scope_Set;

   procedure Execute_Quick_Open_Scope_Clear
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
            Editor.Executor.Shared_Services.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif Editor.Quick_Open.Path_Scope (S.Quick_Open)'Length = 0 then
            Editor.Executor.Shared_Services.Report_Info (S, "No Quick Open scope");
         else
            Editor.Quick_Open.Clear_Path_Scope (S.Quick_Open);
            Editor.Executor.Quick_Open_Commands.Recompute_Quick_Open (S);
            Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope cleared");
         end if;
      end if;
   end Execute_Quick_Open_Scope_Clear;

   procedure Execute_Quick_Open_Scope_From_Selected
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Scope : constant String :=
        Editor.Quick_Open.Selected_Directory_Scope (S.Quick_Open, Found);
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
            Editor.Executor.Shared_Services.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif not Found then
            Editor.Executor.Shared_Services.Report_Info (S, "No Quick Open selection");
         else
            Editor.Quick_Open.Set_Path_Scope_From_Selected (S.Quick_Open, Found);
            Editor.Executor.Quick_Open_Commands.Recompute_Quick_Open (S);
            if Scope'Length = 0 then
               Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope cleared");
            else
               Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope: " & Scope);
            end if;
         end if;
      end if;
   end Execute_Quick_Open_Scope_From_Selected;

   procedure Execute_Quick_Open_Scope_Parent
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Parent : constant String :=
        Editor.Quick_Open.Parent_Scope
          (Editor.Quick_Open.Path_Scope (S.Quick_Open), Found);
   begin
      if Editor.Quick_Open.Is_Open (S.Quick_Open) then
         if not Editor.Project.Has_Project (S.Project_Runtime.Project) then
            Editor.Executor.Shared_Services.Report_Info (S, "No project open");
            Editor.Render_Cache.Invalidate_All;
            return;
         elsif not Found then
            Editor.Executor.Shared_Services.Report_Info (S, "No Quick Open scope");
         else
            Editor.Quick_Open.Move_Path_Scope_To_Parent (S.Quick_Open, Found);
            Editor.Executor.Quick_Open_Commands.Recompute_Quick_Open (S);
            if Parent'Length = 0 then
               Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope cleared");
            else
               Editor.Executor.Shared_Services.Report_Info (S, "Quick Open scope: " & Parent);
            end if;
         end if;
      end if;
   end Execute_Quick_Open_Scope_Parent;

end Editor.Executor.Quick_Open_Scope_Commands;
