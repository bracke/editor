with Ada.Containers;
with Ada.Strings.Unbounded;
with Ada_Regexp;

package Editor.Project_Search.Utilities is

   type Preserved_Result_Key is record
      Has_Value  : Boolean := False;
      Path       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Row        : Natural := 0;
      Occurrence : Natural := 0;
   end record;

   function Read_Search_File
     (Path : String;
      Text : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Capture_Selected_Key
     (State : Editor.Project_Search.Project_Search_State)
      return Preserved_Result_Key;

   procedure Restore_Selected_Key
     (State : in out Editor.Project_Search.Project_Search_State;
      Key   : Preserved_Result_Key);

   function Contains_Newline (Text : String) return Boolean;

   procedure Reset_Results
     (State  : in out Editor.Project_Search.Project_Search_State;
      Status : Editor.Project_Search.Project_Search_Status :=
        Editor.Project_Search.Project_Search_Idle);

   procedure Preserve_Results_For_Precondition_Failure
     (State  : in out Editor.Project_Search.Project_Search_State;
      Status : Editor.Project_Search.Project_Search_Status;
      Query  : String);

   procedure Begin_Search_Run
     (State             : in out Editor.Project_Search.Project_Search_State;
      Query             : String;
      Project_Open      : Boolean;
      File_Total        : Natural;
      No_Project_Status : Editor.Project_Search.Project_Search_Status;
      No_Files_Status   : Editor.Project_Search.Project_Search_Status;
      Previous_Key      : out Preserved_Result_Key;
      Effective_Options : in out Editor.Project_Search.Project_Search_Options;
      Regex_Compile     : out Ada_Regexp.Compile_Result;
      Ready             : out Boolean);

   procedure Finalize_Search_Run
     (State             : in out Editor.Project_Search.Project_Search_State;
      Previous_Key      : Preserved_Result_Key;
      Effective_Options : Editor.Project_Search.Project_Search_Options;
      Eligible          : Natural;
      Scanned           : Natural;
      Processed         : Natural);

   function Fold_Case (Text : String) return String;

   function Replacement_Text_Is_Valid
     (Text : String) return Boolean;

   function Find_Literal_Match_Column
     (Line           : String;
      Query          : String;
      Case_Sensitive : Boolean) return Natural;

   function Sanitize_Project_Search_Preview_Text
     (Line : String) return String;

   procedure Compute_Project_Search_Preview_Window
     (Line_Length    : Natural;
      Match_Column   : Natural;
      Match_Length   : Natural;
      Max_Length     : Natural;
      Window_Start   : out Natural;
      Window_End     : out Natural;
      Left_Ellipsis  : out Boolean;
      Right_Ellipsis : out Boolean);

   function Build_Project_Search_Line_Preview
     (Line         : String;
      Match_Column : Natural;
      Match_Length : Natural;
      Max_Length   : Natural := Editor.Project_Search.Max_Search_Result_Preview_Length)
      return String;

   procedure Build_Project_Search_Preview_Match_Range
     (Line                 : String;
      Match_Column         : Natural;
      Match_Length         : Natural;
      Preview              : String;
      Preview_Match_Start  : out Natural;
      Preview_Match_Length : out Natural);

   procedure Internal_Clear_Replace_Preview
     (State : in out Editor.Project_Search.Project_Search_State);

end Editor.Project_Search.Utilities;
