package body Editor.Missing_Stale_Recovery.Facade_Contract_Policies is

   function Stale_State_After_Content_Change
     (Surface : Target_Surface) return Target_Availability_State
   is
   begin
      case Surface is
         when File_Tree_Surface | Quick_Open_Surface =>
            return Target_Refresh_Required;
         when Project_Search_Surface | Diagnostics_Surface =>
            return Target_Stale;
         when Replace_Preview_Surface =>
            return Target_Preview_Stale;
         when Outline_Surface =>
            return Target_Refresh_Required;
         when Build_Surface =>
            return Target_Candidate_Stale;
         when Workspace_Surface | Recent_Project_Surface | Buffer_Surface =>
            return Target_Reload_Required;
      end case;
   end Stale_State_After_Content_Change;

   function Navigation_Allowed (Result : Target_Validation_Result) return Boolean is
   begin
      return Result.State = Target_Available;
   end Navigation_Allowed;

   function Replace_Apply_Allowed (Result : Target_Validation_Result) return Boolean is
   begin
      return Result.Surface = Replace_Preview_Surface
        and then Result.State = Target_Available;
   end Replace_Apply_Allowed;

   function Build_Run_Allowed (Result : Target_Validation_Result) return Boolean is
   begin
      return Result.Surface = Build_Surface
        and then Result.State = Target_Available;
   end Build_Run_Allowed;

   function Recovery_State_Is_Persistable (State : Target_Availability_State) return Boolean
   is
      pragma Unreferenced (State);
   begin
      return False;
   end Recovery_State_Is_Persistable;

   function Persistence_Field_Allowed
     (Field : Recovery_Persistence_Field) return Boolean
   is
   begin
      case Field is
         when Persist_Workspace_Structural_Reference
            | Persist_Recent_Project_Reference
            | Persist_Settings_Global_Preference
            | Persist_Keybinding_Command_Name =>
            return True;
         when Persist_Stale_Target_Payload
            | Persist_Recovery_Command_Payload
            | Persist_Missing_Target_Cache
            | Persist_Validated_Target_Cache
            | Persist_Command_Outcome_Message
            | Persist_Surface_Stale_Selection =>
            return False;
      end case;
   end Persistence_Field_Allowed;

end Editor.Missing_Stale_Recovery.Facade_Contract_Policies;
