with Editor.Project;
with Editor.Recent_Projects;

package body Editor.Executor.Project_Lifecycle_Availability_Commands is

   function Project_Lifecycle_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Project return Boolean is
      begin
         return Editor.Project.Has_Project (S.Project);
      end Has_Project;
   begin
      case Id is
         when Editor.Commands.Command_Open_Project =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Switch_Project =>
            return Editor.Commands.Unavailable ("No target project selected");

         when Editor.Commands.Command_Close_Project
            | Editor.Commands.Command_Clear_Project =>
            if not Has_Project then
               return Editor.Commands.Unavailable ("No project open");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Show_Recent_Projects =>
            return Editor.Commands.Available;

         when Editor.Commands.Command_Clear_Recent_Projects =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent projects");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Open_Selected_Recent_Project =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent project selected");
            else
               declare
                  Total : constant Natural :=
                    Editor.Recent_Projects.Count (S.Recent_Projects);
                  Selected : constant Positive :=
                    (if S.Recent_Project_Selected_Index in 1 .. Total
                     then Positive (S.Recent_Project_Selected_Index)
                     else 1);
                  Item : constant Editor.Recent_Projects.Recent_Project_Entry :=
                    Editor.Recent_Projects.Item (S.Recent_Projects, Selected);
               begin
                  if not Editor.Recent_Projects.Is_Available (Item) then
                     return Editor.Commands.Unavailable
                       ("Selected recent project is unavailable");
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Remove_Selected_Recent_Project =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent project selected");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Remove_Missing_Recent_Projects =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent projects");
            end if;
            for Index in 1 .. Editor.Recent_Projects.Count (S.Recent_Projects) loop
               if not Editor.Recent_Projects.Is_Available
                 (Editor.Recent_Projects.Item (S.Recent_Projects, Index))
               then
                  return Editor.Commands.Available;
               end if;
            end loop;
            return Editor.Commands.Unavailable ("No unavailable recent projects");

         when Editor.Commands.Command_Select_Next_Recent_Project
            | Editor.Commands.Command_Select_Previous_Recent_Project =>
            if Editor.Recent_Projects.Count (S.Recent_Projects) = 0 then
               return Editor.Commands.Unavailable ("No recent projects");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a project lifecycle command");
      end case;
   end Project_Lifecycle_Command_Availability;

end Editor.Executor.Project_Lifecycle_Availability_Commands;
