package Editor.Missing_Stale_Recovery.Project_Workspace_Policies is

   function Recent_Missing_Marker_Is_Snapshot_Derived return Boolean;
   function Recent_Missing_Marker_May_Delete_Files return Boolean;
   function Recent_Missing_Marker_May_Clear_Workspace return Boolean;

   function File_Tree_Expanded_Path_Restore_State
     (Path : String) return Target_Availability_State;

   function Validate_File_Tree_Mutation_Target
     (Kind         : File_Tree_Mutation_Kind;
      Path         : String;
      Project_Root : String := "";
      Parent_Path  : String := "") return Target_Validation_Result;

   function Workspace_Active_File_Fallback_Policy
     (Active_File_Missing      : Boolean;
      Reopened_File_Count      : Natural) return Workspace_Active_File_Fallback;

   function Workspace_Active_File_Fallback_Label
     (Fallback : Workspace_Active_File_Fallback) return String;

   function File_Tree_Mutation_Requires_Execution_Validation
     (Kind : File_Tree_Mutation_Kind) return Boolean;

   function Project_Transition_Clears_Build_Transient
     (Field : Transient_Surface_Field) return Boolean;

   function Validate_Project_Target
     (Project_Path : String;
      Require_Directory : Boolean := True) return Target_Validation_Result;

   function Validate_Workspace_Project_Target
     (Project_Path : String) return Target_Validation_Result;

   function Validate_Workspace_File_Target
     (Path : String) return Target_Validation_Result;

   function Validate_Recent_Project_Target
     (Project_Path : String) return Target_Validation_Result;

   function Validate_File_Tree_Node_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result;

end Editor.Missing_Stale_Recovery.Project_Workspace_Policies;
