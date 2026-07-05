with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Editor.File_Tree;
with Editor.Project;

package Editor.Project_Search is

   type Project_Search_Status is
     (Project_Search_Idle,
      Project_Search_Ok,
      Project_Search_No_Project,
      Project_Search_No_Files,
      Project_Search_Empty_Query,
      Project_Search_Read_Error,
      Project_Search_Invalid_Regex,
      Project_Search_Cancelled);

   type Project_Search_File_Kind_Filter is
     (Project_Search_Kind_All,
      Project_Search_Kind_Ada,
      Project_Search_Kind_Tests,
      Project_Search_Kind_Docs,
      Project_Search_Kind_Other);

   Max_Search_Result_Preview_Length : constant Natural := 160;
   Search_Result_Context_Before     : constant Natural := 48;

   type Project_Search_Options is record
      Case_Sensitive       : Boolean := False;
      Max_File_Count       : Natural := 20_000;
      Max_Result_Count     : Natural := 5_000;
      Max_Matches_Per_File : Natural := 5_000;
      Max_Line_Length      : Natural := Max_Search_Result_Preview_Length;
      Max_File_Size_Bytes  : Natural := 2 * 1024 * 1024;
      Regex_Max_Steps      : Natural := 100_000;
   end record;

   type Project_Search_Result_Id is new Natural;
   No_Project_Search_Result : constant Project_Search_Result_Id := 0;

   type Project_Search_Result_Direction is
     (Previous_Result,
      Next_Result);

   type Project_Search_Result_Key is record
      Project_Relative_Path : Ada.Strings.Unbounded.Unbounded_String;
      Line_Number           : Natural := 0;
      Result_Ordinal        : Natural := 0;
   end record;

   type Project_Search_Result is record
      Id            : Project_Search_Result_Id := No_Project_Search_Result;
      File_Node_Id  : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Relative_Path : Ada.Strings.Unbounded.Unbounded_String;
      Absolute_Path : Ada.Strings.Unbounded.Unbounded_String;
      Row                  : Natural := 0;
      Start_Column         : Natural := 0;
      End_Column           : Natural := 0;
      Match_Column         : Natural := 0;
      Original_Line_Length : Natural := 0;
      Line_Text            : Ada.Strings.Unbounded.Unbounded_String;
      Line_Preview         : Ada.Strings.Unbounded.Unbounded_String;
      Preview_Match_Start  : Natural := 0;
      Preview_Match_Length : Natural := 0;
   end record;
   type Project_Replace_Preview_Status is
     (Project_Replace_No_Preview,
      Project_Replace_Preview_Ok,
      Project_Replace_No_Search_Results,
      Project_Replace_Search_Stale,
      Project_Replace_Overlapping_Matches,
      Project_Replace_Invalid_Replacement_Text,
      Project_Replace_Invalid_Target);

   type Project_Replace_Preview_Row is record
      Search_Result_Id    : Project_Search_Result_Id := No_Project_Search_Result;
      Relative_Path        : Ada.Strings.Unbounded.Unbounded_String;
      Absolute_Path        : Ada.Strings.Unbounded.Unbounded_String;
      Row                  : Natural := 0;
      Start_Column         : Natural := 0;
      End_Column           : Natural := 0;
      Before_Excerpt       : Ada.Strings.Unbounded.Unbounded_String;
      After_Excerpt        : Ada.Strings.Unbounded.Unbounded_String;
      Match_Text           : Ada.Strings.Unbounded.Unbounded_String;
      Replacement_Excerpt  : Ada.Strings.Unbounded.Unbounded_String;
      Included             : Boolean := True;
      Stale                : Boolean := False;
      Invalid              : Boolean := False;
      Selected             : Boolean := False;
   end record;


   type Project_Search_File_Group is record
      File_Node_Id        : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Relative_Path       : Ada.Strings.Unbounded.Unbounded_String;
      Absolute_Path       : Ada.Strings.Unbounded.Unbounded_String;
      First_Result_Index  : Natural := 0;
      Result_Count        : Natural := 0;
   end record;

   type Read_File_Access is not null access function
     (Path : String;
      Text : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   type Project_Search_State is private;

   procedure Clear
     (State : in out Project_Search_State);

   procedure Clear_Results_Preserve_Query
     (State : in out Project_Search_State);

   function Query
     (State : Project_Search_State) return String;

   procedure Set_Query
     (State : in out Project_Search_State;
      Query : String);

   function Has_Query
     (State : Project_Search_State) return Boolean;

   function Status
     (State : Project_Search_State) return Project_Search_Status;

   procedure Set_Status
     (State  : in out Project_Search_State;
      Status : Project_Search_Status);

   function Result_Count
     (State : Project_Search_State) return Natural;

   function Has_Results
     (State : Project_Search_State) return Boolean;

   function File_Group_Count
     (State : Project_Search_State) return Natural;

   function Files_Searched
     (State : Project_Search_State) return Natural;

   function Files_With_Matches
     (State : Project_Search_State) return Natural;

   function Eligible_File_Count
     (State : Project_Search_State) return Natural;

   function Read_Error_Count
     (State : Project_Search_State) return Natural;

   function Skipped_File_Count
     (State : Project_Search_State) return Natural;

   function Skipped_Missing_Count
     (State : Project_Search_State) return Natural;

   function Skipped_Large_Count
     (State : Project_Search_State) return Natural;

   function Skipped_Binary_Count
     (State : Project_Search_State) return Natural;

   function Matches_Truncated_Count
     (State : Project_Search_State) return Natural;

   function Was_Truncated
     (State : Project_Search_State) return Boolean;

   function Results_Truncated
     (State : Project_Search_State) return Boolean;

   function Last_Run_Query
     (State : Project_Search_State) return String;

   function File_Kind_Filter
     (State : Project_Search_State) return Project_Search_File_Kind_Filter;

   function File_Kind_Filter_Image
     (Kind : Project_Search_File_Kind_Filter) return String;

   procedure Cycle_File_Kind_Filter
     (State : in out Project_Search_State;
      Forward : Boolean := True);

   procedure Clear_File_Kind_Filter
     (State : in out Project_Search_State);

   function Path_Scope
     (State : Project_Search_State) return String;

   function Include_Path_Filter
     (State : Project_Search_State) return String;

   function Exclude_Path_Filter
     (State : Project_Search_State) return String;

   function Normalize_Path_Scope
     (Scope : String;
      Valid : out Boolean) return String;

   procedure Set_Path_Scope
     (State : in out Project_Search_State;
      Scope : String;
      Valid : out Boolean);

   procedure Clear_Path_Scope
     (State : in out Project_Search_State);

   function Normalize_Path_Filter
     (Filter : String;
      Valid  : out Boolean) return String;

   procedure Set_Include_Path_Filter
     (State  : in out Project_Search_State;
      Filter : String;
      Valid  : out Boolean);

   procedure Set_Exclude_Path_Filter
     (State  : in out Project_Search_State;
      Filter : String;
      Valid  : out Boolean);

   procedure Clear_Include_Path_Filter
     (State : in out Project_Search_State);

   procedure Clear_Exclude_Path_Filter
     (State : in out Project_Search_State);

   function Case_Sensitive
     (State : Project_Search_State) return Boolean;

   procedure Set_Case_Sensitive
     (State : in out Project_Search_State;
      Value : Boolean);

   procedure Toggle_Case_Sensitive
     (State : in out Project_Search_State);

   function Whole_Word
     (State : Project_Search_State) return Boolean;

   procedure Set_Whole_Word
     (State : in out Project_Search_State;
      Value : Boolean);

   procedure Toggle_Whole_Word
     (State : in out Project_Search_State);

   function Regex_Enabled
     (State : Project_Search_State) return Boolean;

   function Regex_Error
     (State : Project_Search_State) return String;

   procedure Set_Regex_Enabled
     (State : in out Project_Search_State;
      Value : Boolean);

   procedure Toggle_Regex
     (State : in out Project_Search_State);

   procedure Clear_Regex
     (State : in out Project_Search_State);

   function Is_Stale
     (State : Project_Search_State) return Boolean;

   procedure Mark_Stale
     (State : in out Project_Search_State);

   procedure Mark_Stale_Unconditionally
     (State : in out Project_Search_State);

   procedure Clear_Stale
     (State : in out Project_Search_State);

   procedure Set_Replace_Text
     (State : in out Project_Search_State;
      Text  : String);

   function Replace_Text
     (State : Project_Search_State) return String;

   function Replace_Text_Is_Valid
     (State : Project_Search_State) return Boolean;

   function Replacement_Text_Is_Valid
     (Text : String) return Boolean;

   function Replace_Mode_Active
     (State : Project_Search_State) return Boolean;

   procedure Set_Replace_Mode_Active
     (State  : in out Project_Search_State;
      Active : Boolean);

   procedure Clear_Replace_Preview
     (State : in out Project_Search_State);

   procedure Generate_Replace_Preview
     (State : in out Project_Search_State;
      Status : out Project_Replace_Preview_Status);

   function Replace_Preview_Status
     (State : Project_Search_State) return Project_Replace_Preview_Status;

   function Replace_Preview_Count
     (State : Project_Search_State) return Natural;

   function Included_Replacement_Count
     (State : Project_Search_State) return Natural;

   function Eligible_Replacement_Count
     (State : Project_Search_State) return Natural;

   function Eligible_Replacement_File_Count
     (State : Project_Search_State) return Natural;

   function Included_Replacement_File_Count
     (State : Project_Search_State) return Natural;

   function Replace_Preview_Row_At
     (State : Project_Search_State;
      Index : Positive) return Project_Replace_Preview_Row;

   function Selected_Replace_Preview_Index
     (State : Project_Search_State) return Natural;

   procedure Set_Selected_Replace_Preview_Index
     (State : in out Project_Search_State;
      Index : Natural);

   procedure Toggle_Selected_Replacement
     (State : in out Project_Search_State);

   procedure Include_Selected_Replacement
     (State : in out Project_Search_State);

   procedure Exclude_Selected_Replacement
     (State : in out Project_Search_State);

   procedure Include_File_Replacements
     (State : in out Project_Search_State;
      Relative_Path : String);

   procedure Exclude_File_Replacements
     (State : in out Project_Search_State;
      Relative_Path : String);

   procedure Include_All_Replacements
     (State : in out Project_Search_State);

   procedure Exclude_All_Replacements
     (State : in out Project_Search_State);

   function Replace_Preview_Is_Stale
     (State : Project_Search_State) return Boolean;

   procedure Mark_Replace_Preview_Stale
     (State : in out Project_Search_State);

   procedure Mark_Replace_Preview_Stale_For_File
     (State : in out Project_Search_State;
      Relative_Path : String);

   procedure Mark_Replace_Preview_Stale_For_Absolute_File
     (State : in out Project_Search_State;
      Absolute_Path : String);

   function Included_Replacements_Overlap
     (State : Project_Search_State) return Boolean;

   function Apply_Included_Replacements_To_Text
     (State         : Project_Search_State;
      Relative_Path : String;
      Text          : String;
      Changed       : out Boolean;
      Replacement_Count : out Natural) return String;

   function Result_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result;

   function Find_Literal_Match_Column
     (Line           : String;
      Query          : String;
      Case_Sensitive : Boolean) return Natural;

   function Sanitize_Project_Search_Preview_Text
     (Line : String) return String;

   function Build_Project_Search_Line_Preview
     (Line         : String;
      Match_Column : Natural;
      Match_Length : Natural;
      Max_Length   : Natural := Max_Search_Result_Preview_Length) return String;

   procedure Build_Project_Search_Preview_Match_Range
     (Line                : String;
      Match_Column        : Natural;
      Match_Length        : Natural;
      Preview             : String;
      Preview_Match_Start : out Natural;
      Preview_Match_Length: out Natural);

   function Result_Key
     (State : Project_Search_State;
      Index : Positive) return Project_Search_Result_Key;

   function File_Group_At
     (State : Project_Search_State;
      Index : Positive) return Project_Search_File_Group;

   function Selected_Result_Index
     (State : Project_Search_State) return Natural;

   procedure Set_Selected_Result_Index
     (State : in out Project_Search_State;
      Index : Natural);

   procedure Ensure_Valid_Selection
     (State : in out Project_Search_State);

   function Can_Move_Next
     (State : Project_Search_State) return Boolean;

   function Can_Move_Previous
     (State : Project_Search_State) return Boolean;

   procedure Move_Selected_Result
     (State     : in out Project_Search_State;
      Direction : Project_Search_Result_Direction;
      Wrap      : Boolean := True);

   procedure Select_First_Result
     (State : in out Project_Search_State);

   procedure Select_Last_Result
     (State : in out Project_Search_State);

   function Select_First_Result_For_Path
     (State : in out Project_Search_State;
      Path  : String) return Boolean;

   function Selected_Result_Directory
     (State : Project_Search_State;
      Found : out Boolean) return String;

   function Directory_Scope_Of_Path
     (Path : String) return String;

   function Selected_Result
     (State : Project_Search_State;
      Found : out Boolean) return Project_Search_Result;

   procedure Move_Selection_Down
     (State : in out Project_Search_State);

   procedure Move_Selection_Up
     (State : in out Project_Search_State);

   procedure Search_Project
     (State   : in out Project_Search_State;
      Tree    : Editor.File_Tree.File_Tree_State;
      Reader  : Read_File_Access;
      Options : Project_Search_Options);

   procedure Search_Known_Project_Files
     (State   : in out Project_Search_State;
      Project : Editor.Project.Project_State;
      Options : Project_Search_Options);

   --  canonical cleanup predicates.  These helpers intentionally
   --  expose only structural invariants: Project Search owns query, selection,
   --  retained search results, and retained search options.  It does not own
   --  lifecycle target history, operation history, prompt state, filesystem
   --  probe caches, association repair caches, dirty caches, or imported
   --  Quick Open/Open Buffer Switcher projection truth.
   function Project_Search_No_Duplicate_Lifecycle_State
     (State : Project_Search_State) return Boolean;

   function Project_Search_No_Prompt_State
     (State : Project_Search_State) return Boolean;

   function Project_Search_Query_Selection_Source_Target_Boundary
     (State : Project_Search_State) return Boolean;

   function Project_Search_Project_Source_Boundary_Canonical
     (State : Project_Search_State) return Boolean;

   function Project_Search_File_Lifecycle_Observation_Canonical
     (State : Project_Search_State) return Boolean;

   --  final regression-freeze predicate.  This intentionally stays
   --  structural and observation-only: it freezes that Project Search derives
   --  lifecycle-visible state only from retained results/query/selection and
   --  owns no duplicate caches, prompt state, repair paths, alternate routes,
   --  target histories, operation histories, projection imports, or persistence
   --  adjacent lifecycle fields.
   function Project_Search_File_Lifecycle_Observation_Frozen
     (State : Project_Search_State) return Boolean;

private
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Project_Search_Result);

   package File_Group_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Project_Search_File_Group);

   package Replace_Preview_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Project_Replace_Preview_Row);

   type Project_Search_State is record
      Query_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Last_Query_Text : Ada.Strings.Unbounded.Unbounded_String;
      Last_Status     : Project_Search_Status := Project_Search_Idle;
      Results         : Result_Vectors.Vector;
      File_Groups     : File_Group_Vectors.Vector;
      Selected_Index          : Natural := 0;
      Kind_Filter             : Project_Search_File_Kind_Filter := Project_Search_Kind_All;
      Scope_Text              : Ada.Strings.Unbounded.Unbounded_String;
      Include_Filter_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Exclude_Filter_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Case_Sensitive_Search   : Boolean := False;
      Whole_Word_Search       : Boolean := False;
      Regex_Search            : Boolean := False;
      Last_Regex_Error        : Ada.Strings.Unbounded.Unbounded_String;
      Eligible_File_Total     : Natural := 0;
      Files_Searched_Count    : Natural := 0;
      Read_Error_Count        : Natural := 0;
      Skipped_Missing_Total    : Natural := 0;
      Skipped_Large_Total      : Natural := 0;
      Skipped_Binary_Total     : Natural := 0;
      Matches_Truncated_Total : Natural := 0;
      Truncated               : Boolean := False;
      Stale                   : Boolean := False;
      Replace_Text_Value      : Ada.Strings.Unbounded.Unbounded_String;
      Replace_Mode            : Boolean := False;
      Replace_Rows            : Replace_Preview_Row_Vectors.Vector;
      Replace_Selected_Index  : Natural := 0;
      Replace_Status_Value    : Project_Replace_Preview_Status := Project_Replace_No_Preview;
      Replace_Stale           : Boolean := False;
      Replace_Search_Token    : Natural := 0;
      Search_Token            : Natural := 0;
   end record;

end Editor.Project_Search;
