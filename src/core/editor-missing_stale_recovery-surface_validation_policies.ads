package Editor.Missing_Stale_Recovery.Surface_Validation_Policies is

   function Surface_Requires_Execution_Validation
     (Surface : Target_Surface) return Boolean;
   function Selected_Stale_Target_Selection_Action
     (Surface : Target_Surface) return String;
   function Failed_Recovery_Operation_May_Fabricate_State
     (Surface : Target_Surface) return Boolean;

   function Replace_All_May_Apply
     (Summary : Replace_Apply_Validation_Summary) return Boolean;

   function Build_Candidate_Material_Identity_Matches
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean;

   function Build_Candidate_Refresh_Requires_Reconsent
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean;

   function Diagnostic_Line_Only_Navigation_Column
     (Line : Natural;
      Column : Natural) return Natural;

   function Search_Result_Content_State
     (Target_Exists             : Boolean;
      Line_Available            : Boolean;
      Match_Still_Present       : Boolean;
      File_Touched_Since_Search : Boolean) return Target_Availability_State;

   function Replace_Apply_Summary_Message
     (Summary : Replace_Apply_Validation_Summary) return String;

   function Quick_Open_Session_Recent_Boost_Allowed
     (Path : String;
      Project_Root : String := "") return Boolean;

   function Build_Request_Consent_Remains_Valid
     (Candidate_Result : Target_Validation_Result) return Boolean;

   function Replace_Apply_Skipped_Report_Allowed
     (Command_Reached_Validation : Boolean;
      Summary                    : Replace_Apply_Validation_Summary) return Boolean;

   function Validate_Quick_Open_Result_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Search_Result_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Replace_Preview_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Outline_Target
     (Active_Buffer_Matches : Boolean;
      Stale                 : Boolean;
      Line                  : Natural;
      Column                : Natural;
      Last_Line             : Natural;
      Last_Line_Column      : Natural) return Target_Validation_Result;

   function Validate_Diagnostic_Target
     (Path       : String;
      Has_Source : Boolean;
      Line       : Natural;
      Column     : Natural;
      Last_Line  : Natural;
      Last_Line_Column : Natural;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Build_Working_Context_Target
     (Working_Root : String) return Target_Validation_Result;

   function Validate_Build_Candidate_Target
     (Candidate_Path : String;
      Working_Root   : String;
      Stale          : Boolean := False) return Target_Validation_Result;

end Editor.Missing_Stale_Recovery.Surface_Validation_Policies;
