package Editor.Missing_Stale_Recovery.Target_Messages is

   function Trim (Text : String) return String;

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result;

   function Exists (Path : String) return Boolean;

   function Is_Directory (Path : String) return Boolean;

   function Is_Ordinary_File (Path : String) return Boolean;

   function Canonical (Path : String) return String;

   function Is_Inside_Project
     (Project_Root : String; Path : String) return Boolean;

   function Label (State : Target_Availability_State) return String;

   function Availability_Reason
     (State : Target_Availability_State) return String;

   function Surface_Label (Surface : Target_Surface) return String;

   function Outcome_Label (Result : Target_Validation_Result) return String;

   function Target_Outcome_Message
     (Result : Target_Validation_Result) return String;

   function Render_Marker_Label
     (Result : Target_Validation_Result) return String;

   function Workspace_Recovery_Message
     (Summary : Workspace_Recovery_Summary) return String;

   function Recent_Project_Recovery_Message
     (Missing_Count : Natural; Removed_Count : Natural) return String;

end Editor.Missing_Stale_Recovery.Target_Messages;
