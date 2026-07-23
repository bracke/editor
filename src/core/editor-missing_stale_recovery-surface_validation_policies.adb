with Ada.Strings.Unbounded;
with Editor.Missing_Stale_Recovery.File_Lifecycle_Policies;
with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Surface_Validation_Policies is

   function Trim (Text : String) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Trim;

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Target_Messages.Make;

   function Canonical (Path : String) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Canonical;

   function Is_Directory (Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Directory;

   function Is_Ordinary_File (Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Ordinary_File;

   function Is_Inside_Project
     (Project_Root : String; Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Inside_Project;

   function Surface_Requires_Execution_Validation
     (Surface : Target_Surface) return Boolean
   is
      pragma Unreferenced (Surface);
   begin
      return True;
   end Surface_Requires_Execution_Validation;

   function Selected_Stale_Target_Selection_Action
     (Surface : Target_Surface) return String
   is
   begin
      case Surface is
         when File_Tree_Surface =>
            return "clear or mark selected File Tree node stale";
         when Quick_Open_Surface =>
            return "clear stale Quick Open selection";
         when Project_Search_Surface =>
            return "mark Search result stale until rerun";
         when Replace_Preview_Surface =>
            return "clear stale replace preview or require rerun";
         when Outline_Surface =>
            return "mark Outline stale until refresh";
         when Diagnostics_Surface =>
            return "keep diagnostic non-navigable until target validates";
         when Build_Surface =>
            return "invalidate selected build request consent";
         when Workspace_Surface | Recent_Project_Surface | Buffer_Surface =>
            return "report missing target without fabricating state";
      end case;
   end Selected_Stale_Target_Selection_Action;

   function Failed_Recovery_Operation_May_Fabricate_State
     (Surface : Target_Surface) return Boolean
   is
      pragma Unreferenced (Surface);
   begin
      return False;
   end Failed_Recovery_Operation_May_Fabricate_State;

   function Replace_All_May_Apply
     (Summary : Replace_Apply_Validation_Summary) return Boolean
   is
   begin
      return Summary.Missing_Targets = 0
        and then Summary.Stale_Targets = 0
        and then Summary.Out_Of_Range_Targets = 0;
   end Replace_All_May_Apply;

   function Build_Candidate_Material_Identity_Matches
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean
   is
   begin
      return Canonical (Old_Candidate_Path) = Canonical (New_Candidate_Path)
        and then Canonical (Old_Working_Root) = Canonical (New_Working_Root);
   end Build_Candidate_Material_Identity_Matches;

   function Build_Candidate_Refresh_Requires_Reconsent
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean
   is
   begin
      return not Build_Candidate_Material_Identity_Matches
        (Old_Candidate_Path, Old_Working_Root, New_Candidate_Path, New_Working_Root);
   end Build_Candidate_Refresh_Requires_Reconsent;

   function Diagnostic_Line_Only_Navigation_Column
     (Line : Natural;
      Column : Natural) return Natural
   is
   begin
      if Line = 0 then
         return 0;
      elsif Column = 0 then
         return 1;
      else
         return Column;
      end if;
   end Diagnostic_Line_Only_Navigation_Column;

   function Search_Result_Content_State
     (Target_Exists             : Boolean;
      Line_Available            : Boolean;
      Match_Still_Present       : Boolean;
      File_Touched_Since_Search : Boolean) return Target_Availability_State
   is
   begin
      if not Target_Exists then
         return Target_Missing;
      elsif not Line_Available then
         return Target_Line_Out_Of_Range;
      elsif File_Touched_Since_Search or else not Match_Still_Present then
         return Target_Stale;
      else
         return Target_Available;
      end if;
   end Search_Result_Content_State;

   function Replace_Apply_Summary_Message
     (Summary : Replace_Apply_Validation_Summary) return String
   is
   begin
      if Summary.Missing_Targets = 0
        and then Summary.Stale_Targets = 0
        and then Summary.Out_Of_Range_Targets = 0
      then
         return "Replace preview targets validated.";
      elsif Summary.Applied_Targets = 0 then
         return "Replace preview is stale; rerun search.";
      else
         return "Replace applied to available targets; stale or missing targets were skipped.";
      end if;
   end Replace_Apply_Summary_Message;

   function Quick_Open_Session_Recent_Boost_Allowed
     (Path : String;
      Project_Root : String := "") return Boolean
   is
      Result : constant Target_Validation_Result :=
        Validate_Quick_Open_Result_Target (Path, Project_Root);
   begin
      return Result.State = Target_Available;
   end Quick_Open_Session_Recent_Boost_Allowed;

   function Build_Request_Consent_Remains_Valid
     (Candidate_Result : Target_Validation_Result) return Boolean
   is
   begin
      return Candidate_Result.Surface = Build_Surface
        and then Candidate_Result.State = Target_Available;
   end Build_Request_Consent_Remains_Valid;

   function Replace_Apply_Skipped_Report_Allowed
     (Command_Reached_Validation : Boolean;
      Summary                    : Replace_Apply_Validation_Summary) return Boolean
   is
   begin
      if Summary.Missing_Targets = 0
        and then Summary.Stale_Targets = 0
        and then Summary.Out_Of_Range_Targets = 0
      then
         return True;
      end if;

      return Command_Reached_Validation;
   end Replace_Apply_Skipped_Report_Allowed;

   function Validate_Quick_Open_Result_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result
   is
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Quick_Open_Surface, Target_Outside_Project, Path);
      elsif not Is_Ordinary_File (Path) then
         return Make (Quick_Open_Surface, Target_Stale, Path);
      else
         return Make (Quick_Open_Surface, Target_Available, Path);
      end if;
   end Validate_Quick_Open_Result_Target;

   function Validate_Search_Result_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result
   is
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Project_Search_Surface, Target_Outside_Project, Path, Line);
      elsif Stale then
         return Make (Project_Search_Surface, Target_Stale, Path, Line);
      elsif not Is_Ordinary_File (Path) then
         return Make (Project_Search_Surface, Target_Missing, Path, Line);
      elsif Line = 0 or else Last_Line = 0 or else Line > Last_Line then
         return Make (Project_Search_Surface, Target_Line_Out_Of_Range, Path, Line);
      else
         return Make (Project_Search_Surface, Target_Available, Path, Line);
      end if;
   end Validate_Search_Result_Target;

   function Validate_Replace_Preview_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result
   is
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Replace_Preview_Surface, Target_Outside_Project, Path, Line);
      elsif Stale then
         return Make (Replace_Preview_Surface, Target_Preview_Stale, Path, Line);
      elsif not Is_Ordinary_File (Path) then
         return Make (Replace_Preview_Surface, Target_Missing, Path, Line);
      elsif Line = 0 or else Last_Line = 0 or else Line > Last_Line then
         return Make (Replace_Preview_Surface, Target_Line_Out_Of_Range, Path, Line);
      else
         return Make (Replace_Preview_Surface, Target_Available, Path, Line);
      end if;
   end Validate_Replace_Preview_Target;

   function Validate_Outline_Target
     (Active_Buffer_Matches : Boolean;
      Stale                 : Boolean;
      Line                  : Natural;
      Column                : Natural;
      Last_Line             : Natural;
      Last_Line_Column      : Natural) return Target_Validation_Result
   is
      Result : Target_Validation_Result;
   begin
      if not Active_Buffer_Matches then
         return Make (Outline_Surface, Target_Stale, Line => Line, Column => Column);
      elsif Stale then
         return Make (Outline_Surface, Target_Refresh_Required, Line => Line, Column => Column);
      end if;
      Result := Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_Line_Column_Target
        (Line, Column, Last_Line, Last_Line_Column);
      Result.Surface := Outline_Surface;
      return Result;
   end Validate_Outline_Target;

   function Validate_Diagnostic_Target
     (Path       : String;
      Has_Source : Boolean;
      Line       : Natural;
      Column     : Natural;
      Last_Line  : Natural;
      Last_Line_Column : Natural;
      Project_Root : String := "") return Target_Validation_Result
   is
      Result : Target_Validation_Result;
   begin
      if not Has_Source then
         return Make (Diagnostics_Surface, Target_Source_Less, Path, Line, Column);
      elsif Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Diagnostics_Surface, Target_Outside_Project, Path, Line, Column);
      elsif not Is_Ordinary_File (Path) then
         return Make (Diagnostics_Surface, Target_Missing, Path, Line, Column);
      end if;
      if Line = 0 or else Last_Line = 0 or else Line > Last_Line then
         return Make (Diagnostics_Surface, Target_Line_Out_Of_Range, Path, Line, Column);
      end if;

      Result := Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_Line_Column_Target
        (Line, Diagnostic_Line_Only_Navigation_Column (Line, Column),
         Last_Line, Last_Line_Column);
      Result.Surface := Diagnostics_Surface;
      Result.Path := Ada.Strings.Unbounded.To_Unbounded_String (Path);
      return Result;
   end Validate_Diagnostic_Target;

   function Validate_Build_Working_Context_Target
     (Working_Root : String) return Target_Validation_Result
   is
   begin
      if Trim (Working_Root)'Length = 0 or else not Is_Directory (Working_Root) then
         return Make (Build_Surface, Target_Working_Directory_Missing, Working_Root);
      else
         return Make (Build_Surface, Target_Available, Working_Root);
      end if;
   end Validate_Build_Working_Context_Target;

   function Validate_Build_Candidate_Target
     (Candidate_Path : String;
      Working_Root   : String;
      Stale          : Boolean := False) return Target_Validation_Result
   is
   begin
      if Stale then
         return Make (Build_Surface, Target_Candidate_Stale, Candidate_Path);
      elsif Trim (Working_Root)'Length = 0 or else not Is_Directory (Working_Root) then
         return Make (Build_Surface, Target_Working_Directory_Missing, Working_Root);
      elsif not Is_Ordinary_File (Candidate_Path) then
         return Make (Build_Surface, Target_Missing, Candidate_Path);
      elsif not Is_Inside_Project (Working_Root, Candidate_Path) then
         return Make (Build_Surface, Target_Outside_Project, Candidate_Path);
      else
         return Make (Build_Surface, Target_Available, Candidate_Path);
      end if;
   end Validate_Build_Candidate_Target;

end Editor.Missing_Stale_Recovery.Surface_Validation_Policies;
