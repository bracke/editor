with Editor.Command_Ids; use Editor.Command_Ids;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Command_Execution;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Focus_Management;
with Editor.Messages;
with Editor.Recent_Projects;
use type Editor.Recent_Projects.Recent_Project_Status;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Project_Lifecycle_Recent_Commands is

   use type Editor.Messages.Message_Severity;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Warning
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Warning;

   procedure Save_Recent_Projects_Best_Effort
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Recent_Projects.Recent_Project_Status;
   begin
      Editor.Recent_Projects.Save_To_File
        (S.Project_Runtime.Recent_Projects,
         Editor.Recent_Projects.Recent_Projects_File_Path,
         Status);
      if Status /= Editor.Recent_Projects.Recent_Project_Ok then
         Report_Warning (S, "Save recent projects failed");
      end if;
   end Save_Recent_Projects_Best_Effort;

   function Result_After_Command
     (S               : Editor.State.State_Type;
      Command         : Editor.Command_Ids.Command_Id;
      Before_Messages : Natural)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      if Editor.Messages.Count (S.Panel.Messages) > Before_Messages then
         Msg := Editor.Messages.Active_Message (S.Panel.Messages, Found);
         if Found then
            if Editor.Messages.Severity (Msg) =
              Editor.Messages.Error_Message
            then
               return Editor.Command_Execution.Failed (Command);
            elsif Editor.Messages.Severity (Msg) =
              Editor.Messages.Warning_Message
            then
               return Editor.Command_Execution.Unavailable (Command);
            end if;
         end if;
      end if;

      return Editor.Command_Execution.Executed (Command);
   end Result_After_Command;

   procedure Ensure_Recent_Project_Selection
     (S : in out Editor.State.State_Type)
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects);
   begin
      if Total = 0 then
         S.Project_Runtime.Recent_Project_Selected_Index := 0;
      elsif S.Project_Runtime.Recent_Project_Selected_Index not in 1 .. Total then
         S.Project_Runtime.Recent_Project_Selected_Index := 1;
      end if;
   end Ensure_Recent_Project_Selection;

   function Selected_Recent_Project_Index
     (S : Editor.State.State_Type) return Natural
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects);
   begin
      if Total = 0 then
         return 0;
      elsif S.Project_Runtime.Recent_Project_Selected_Index in 1 .. Total then
         return S.Project_Runtime.Recent_Project_Selected_Index;
      else
         return 1;
      end if;
   end Selected_Recent_Project_Index;

   procedure Report_Selected_Recent_Project
     (S      : in out Editor.State.State_Type;
      Prefix : String)
   is
      Item : Editor.Recent_Projects.Recent_Project_Entry;
   begin
      if Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects) = 0 then
         Report_Info (S, "No recent projects");
         return;
      end if;

      Ensure_Recent_Project_Selection (S);
      Item := Editor.Recent_Projects.Item
        (S.Project_Runtime.Recent_Projects, Selected_Recent_Project_Index (S));
      Report_Info
        (S,
         Prefix & ": " & To_String (Item.Display_Name)
         & " — " & Editor.Recent_Projects.Path_Label (Item)
         & (if Editor.Recent_Projects.Is_Available (Item)
            then " — " & Editor.Recent_Projects.Last_Opened_Label (Item)
            else " — " & Editor.Recent_Projects.Unavailable_Label (Item)));
   end Report_Selected_Recent_Project;

   procedure Execute_Select_Next_Recent_Project
     (S : in out Editor.State.State_Type)
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects);
   begin
      if Total = 0 then
         Report_Info (S, "No recent projects");
         S.Project_Runtime.Recent_Project_Selected_Index := 0;
         return;
      end if;

      if S.Project_Runtime.Recent_Project_Selected_Index not in 1 .. Total then
         S.Project_Runtime.Recent_Project_Selected_Index := 1;
      elsif S.Project_Runtime.Recent_Project_Selected_Index >= Total then
         S.Project_Runtime.Recent_Project_Selected_Index := 1;
      else
         S.Project_Runtime.Recent_Project_Selected_Index := S.Project_Runtime.Recent_Project_Selected_Index + 1;
      end if;
      Report_Selected_Recent_Project (S, "Selected recent project");
   end Execute_Select_Next_Recent_Project;

   procedure Execute_Select_Previous_Recent_Project
     (S : in out Editor.State.State_Type)
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects);
   begin
      if Total = 0 then
         Report_Info (S, "No recent projects");
         S.Project_Runtime.Recent_Project_Selected_Index := 0;
         return;
      end if;

      if S.Project_Runtime.Recent_Project_Selected_Index not in 1 .. Total then
         S.Project_Runtime.Recent_Project_Selected_Index := Total;
      elsif S.Project_Runtime.Recent_Project_Selected_Index <= 1 then
         S.Project_Runtime.Recent_Project_Selected_Index := Total;
      else
         S.Project_Runtime.Recent_Project_Selected_Index := S.Project_Runtime.Recent_Project_Selected_Index - 1;
      end if;
      Report_Selected_Recent_Project (S, "Selected recent project");
   end Execute_Select_Previous_Recent_Project;

   procedure Execute_Show_Recent_Projects
     (S : in out Editor.State.State_Type)
   is
      Total : constant Natural := Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects);
      Summary : Unbounded_String := Null_Unbounded_String;
      Selected : Natural := 0;
   begin
      if Total = 0 then
         Report_Info (S, "No recent projects");
         return;
      end if;

      Editor.Recent_Projects.Refresh_Availability (S.Project_Runtime.Recent_Projects);
      Ensure_Recent_Project_Selection (S);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Recent_Projects);
      Selected := Selected_Recent_Project_Index (S);
      Append
        (Summary,
         "Recent projects: "
         & Ada.Strings.Fixed.Trim (Natural'Image (Total), Ada.Strings.Both));
      if Editor.Recent_Projects.Available_Count (S.Project_Runtime.Recent_Projects) = 0 then
         Append (Summary, "; No available recent projects");
         if Editor.Recent_Projects.Unavailable_Count (S.Project_Runtime.Recent_Projects) > 0 then
            Append (Summary, "; project path no longer exists");
         end if;
      elsif Editor.Recent_Projects.Unavailable_Count (S.Project_Runtime.Recent_Projects) > 0 then
         Append
           (Summary,
            "; unavailable: "
            & Ada.Strings.Fixed.Trim
              (Natural'Image
                 (Editor.Recent_Projects.Unavailable_Count (S.Project_Runtime.Recent_Projects)),
               Ada.Strings.Both));
      end if;
      for Index in 1 .. Total loop
         declare
            Item : constant Editor.Recent_Projects.Recent_Project_Entry :=
              Editor.Recent_Projects.Item (S.Project_Runtime.Recent_Projects, Index);
         begin
            Append
              (Summary,
               "; " & Editor.Recent_Projects.Row_Label
                 (Item, Is_Selected => Index = Selected));
         end;
      end loop;

      Report_Info (S, To_String (Summary));
   end Execute_Show_Recent_Projects;

   procedure Execute_Clear_Recent_Projects
     (S : in out Editor.State.State_Type)
   is
      Status : Editor.Recent_Projects.Recent_Project_Status;
   begin
      Editor.Recent_Projects.Clear (S.Project_Runtime.Recent_Projects);
      S.Project_Runtime.Recent_Project_Selected_Index := 0;
      Editor.Recent_Projects.Save_To_File
        (S.Project_Runtime.Recent_Projects,
         Editor.Recent_Projects.Recent_Projects_File_Path,
         Status);
      if Status /= Editor.Recent_Projects.Recent_Project_Ok then
         Report_Warning (S, "Save recent projects failed");
      end if;
      Report_Info (S, "Cleared recent projects");
   end Execute_Clear_Recent_Projects;

   procedure Execute_Remove_Selected_Recent_Project
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Recent_Projects.Count (S.Project_Runtime.Recent_Projects) = 0 then
         Report_Info (S, "No recent project selected");
         return;
      end if;

      Ensure_Recent_Project_Selection (S);
      Editor.Recent_Projects.Remove_At
        (S.Project_Runtime.Recent_Projects, Selected_Recent_Project_Index (S));
      Ensure_Recent_Project_Selection (S);
      Save_Recent_Projects_Best_Effort (S);
      Report_Info (S, "Removed recent project");
   end Execute_Remove_Selected_Recent_Project;

   procedure Execute_Remove_Missing_Recent_Projects
     (S : in out Editor.State.State_Type)
   is
      Removed : Natural := 0;
   begin
      Removed := Editor.Recent_Projects.Remove_Missing (S.Project_Runtime.Recent_Projects);
      if Removed = 0 then
         Report_Info (S, "No unavailable recent projects");
         return;
      end if;

      Ensure_Recent_Project_Selection (S);
      Save_Recent_Projects_Best_Effort (S);
      Report_Info
        (S,
         "Removed " & Ada.Strings.Fixed.Trim (Natural'Image (Removed), Ada.Strings.Both)
         & (if Removed = 1 then " unavailable recent project"
            else " unavailable recent projects"));
   end Execute_Remove_Missing_Recent_Projects;

   function Execute_Project_Lifecycle_Recent_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Panel.Messages);
   begin
      case Id is
         when Editor.Command_Ids.Command_Show_Recent_Projects =>
            Execute_Show_Recent_Projects (S);
         when Editor.Command_Ids.Command_Clear_Recent_Projects =>
            Execute_Clear_Recent_Projects (S);
         when Editor.Command_Ids.Command_Remove_Selected_Recent_Project =>
            Execute_Remove_Selected_Recent_Project (S);
         when Editor.Command_Ids.Command_Remove_Missing_Recent_Projects =>
            Execute_Remove_Missing_Recent_Projects (S);
         when Editor.Command_Ids.Command_Select_Next_Recent_Project =>
            Execute_Select_Next_Recent_Project (S);
         when Editor.Command_Ids.Command_Select_Previous_Recent_Project =>
            Execute_Select_Previous_Recent_Project (S);
         when others =>
            raise Program_Error with
              "unsupported recent-project result command";
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (S, Id, Before_Messages);
   end Execute_Project_Lifecycle_Recent_Result_Command;

end Editor.Executor.Project_Lifecycle_Recent_Commands;
