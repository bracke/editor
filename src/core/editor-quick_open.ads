with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Editor.Input_Field;
with Editor.File_Tree;
with Editor.Project;
with Editor.Buffer_Types;
with Editor.Layout;

package Editor.Quick_Open is

   type Quick_Open_State is private;

   type Quick_Open_Config is record
      Max_Visible_Results      : Natural := 12;
      Max_Result_Count         : Natural := 100;
      Query_Field_Min_Columns  : Natural := 24;
      Overlay_Width_In_Columns : Natural := 72;
      Row_Height_In_Rows       : Natural := 1;
      Header_Height_In_Rows    : Natural := 1;
      Field_Height_In_Rows     : Natural := 1;
      Result_Padding_Columns   : Natural := 1;
   end record;

   type Quick_Open_Zone is
     (Outside_Quick_Open,
      Quick_Open_Background_Zone,
      Quick_Open_Query_Field_Zone,
      Quick_Open_Result_Row_Zone);

   type Quick_Open_Hit_Result is record
      Zone         : Quick_Open_Zone := Outside_Quick_Open;
      Result_Index : Natural := 0;
   end record;

   type Quick_Open_Match_Bucket is
     (No_Match,
      Basename_Exact,
      Basename_Prefix,
      Basename_Substring,
      Path_Segment_Prefix,
      Path_Prefix,
      Path_Segment_Substring,
      Path_Substring,
      Basename_Fuzzy,
      Path_Fuzzy);

   type Quick_Open_File_Kind_Filter is
     (All_Files,
      Ada_Files,
      Test_Files,
      Doc_Files,
      Other_Files);

   type Quick_Open_Create_Target_Status is
     (Quick_Open_Create_Target_Ok,
      Quick_Open_Create_Target_No_Query,
      Quick_Open_Create_Target_Invalid_Path);

   type Quick_Open_Priority_Mode is
     (Path,
      Open_Recent);

   type Quick_Open_Priority_Bucket is
     (Active_File,
      Open_Dirty_File,
      Open_Clean_File,
      Recent_File,
      Ordinary_File);

   type Quick_Open_Create_Target_Result is record
      Status : Quick_Open_Create_Target_Status := Quick_Open_Create_Target_No_Query;
      Project_Relative_Path : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Quick_Open_Result is record
      Node_Id       : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Display_Path  : Ada.Strings.Unbounded.Unbounded_String;
      Absolute_Path : Ada.Strings.Unbounded.Unbounded_String;
      Match_Bucket  : Quick_Open_Match_Bucket := No_Match;
   end record;

   type Quick_Open_Candidate_Snapshot is record
      Project_Relative_Path : Ada.Strings.Unbounded.Unbounded_String;
      Buffer_Identity       : Editor.Buffer_Types.Buffer_Id := Editor.Buffer_Types.No_Buffer;
      Basename              : Ada.Strings.Unbounded.Unbounded_String;
      Match_Bucket          : Quick_Open_Match_Bucket := No_Match;
      Priority_Bucket       : Quick_Open_Priority_Bucket := Ordinary_File;
      Display_Text          : Ada.Strings.Unbounded.Unbounded_String;
      Is_Open               : Boolean := False;
      Is_Active             : Boolean := False;
      Is_Dirty              : Boolean := False;
      Is_Recent             : Boolean := False;
      Recent_Rank           : Natural := 0;
      Is_Selected           : Boolean := False;
   end record;

   package Candidate_Snapshot_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Quick_Open_Candidate_Snapshot);

   type Quick_Open_Snapshot is record
      Visible             : Boolean := False;
      Query               : Ada.Strings.Unbounded.Unbounded_String;
      File_Kind_Filter    : Quick_Open_File_Kind_Filter := All_Files;
      Path_Scope          : Ada.Strings.Unbounded.Unbounded_String;
      Priority_Mode       : Quick_Open_Priority_Mode := Path;
      Header_Text         : Ada.Strings.Unbounded.Unbounded_String;
      Visible_Count       : Natural := 0;
      Known_Count         : Natural := 0;
      Total_Filtered_Count : Natural := 0;
      Has_Project         : Boolean := False;
      Has_Query           : Boolean := False;
      Candidates          : Candidate_Snapshot_Vectors.Vector;
      Selected_Index      : Natural := 0;
      Selected_Path       : Ada.Strings.Unbounded.Unbounded_String;
      Empty_Message       : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   procedure Clear
     (State : in out Quick_Open_State);

   procedure Mark_Stale
     (State : in out Quick_Open_State);

   function Results_Are_Stale
     (State : Quick_Open_State) return Boolean;

   procedure Open
     (State : in out Quick_Open_State);

   procedure Close
     (State : in out Quick_Open_State);

   function Is_Open
     (State : Quick_Open_State) return Boolean;

   function Query_Text
     (State : Quick_Open_State) return String;

   procedure Set_Query_Text
     (State : in out Quick_Open_State;
      Text  : String);

   function File_Kind_Filter
     (State : Quick_Open_State) return Quick_Open_File_Kind_Filter;

   function File_Kind_Filter_Name
     (Filter : Quick_Open_File_Kind_Filter) return String;

   procedure Set_File_Kind_Filter
     (State  : in out Quick_Open_State;
      Filter : Quick_Open_File_Kind_Filter);

   procedure Cycle_File_Kind_Next
     (State : in out Quick_Open_State);

   procedure Cycle_File_Kind_Previous
     (State : in out Quick_Open_State);

   procedure Clear_File_Kind_Filter
     (State : in out Quick_Open_State);

   function Path_Scope
     (State : Quick_Open_State) return String;

   function Create_Target_From_Query
     (State : Quick_Open_State) return Quick_Open_Create_Target_Result;

   function Priority_Mode
     (State : Quick_Open_State) return Quick_Open_Priority_Mode;

   procedure Toggle_Priority_Mode
     (State : in out Quick_Open_State);

   procedure Clear_Priority_Mode
     (State : in out Quick_Open_State);

   function Normalize_Quick_Open_Scope
     (Text : String) return String;

   procedure Set_Path_Scope
     (State : in out Quick_Open_State;
      Scope : String);

   procedure Clear_Path_Scope
     (State : in out Quick_Open_State);

   function Selected_Directory_Scope
     (State : Quick_Open_State;
      Found : out Boolean) return String;

   function Parent_Scope
     (Scope : String;
      Found : out Boolean) return String;

   function Directory_Scope_Of_Path
     (Path : String) return String;

   procedure Select_Path
     (State : in out Quick_Open_State;
      Path  : String;
      Found : out Boolean);

   procedure Set_Path_Scope_From_Selected
     (State : in out Quick_Open_State;
      Found : out Boolean);

   procedure Move_Path_Scope_To_Parent
     (State : in out Quick_Open_State;
      Found : out Boolean);

   function Known_Count
     (State : Quick_Open_State) return Natural;

   function Visible_Count
     (State : Quick_Open_State) return Natural;

   function Total_Filtered_Count
     (State : Quick_Open_State) return Natural;

   procedure Insert_Text
     (State : in out Quick_Open_State;
      Text  : String);

   procedure Backspace
     (State : in out Quick_Open_State);

   procedure Delete_Forward
     (State : in out Quick_Open_State);

   procedure Move_Cursor_Left
     (State : in out Quick_Open_State);

   procedure Move_Cursor_Right
     (State : in out Quick_Open_State);

   procedure Move_Cursor_Start
     (State : in out Quick_Open_State);

   procedure Move_Cursor_End
     (State : in out Quick_Open_State);

   procedure Select_All
     (State : in out Quick_Open_State);

   procedure Set_Cursor_From_Visible_Column
     (State           : in out Quick_Open_State;
      Visible_Column  : Natural;
      Visible_Columns : Natural);

   procedure Move_Selection_Down
     (State : in out Quick_Open_State);

   procedure Move_Selection_Up
     (State : in out Quick_Open_State);

   procedure Recompute_Results
     (State  : in out Quick_Open_State;
      Tree   : Editor.File_Tree.File_Tree_State;
      Config : Quick_Open_Config);

   procedure Recompute_Results
     (State   : in out Quick_Open_State;
      Project : Editor.Project.Project_State;
      Config  : Quick_Open_Config);

   function Result_Count
     (State : Quick_Open_State) return Natural;

   function Selected_Result_Index
     (State : Quick_Open_State) return Natural;

   function Top_Result_Index
     (State : Quick_Open_State) return Natural;

   function Query_Cursor
     (State : Quick_Open_State) return Natural;

   function Query_Snapshot
     (State           : Quick_Open_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot;

   function Selected_Result
     (State : Quick_Open_State;
      Found : out Boolean) return Quick_Open_Result;

   function Result_At
     (State : Quick_Open_State;
      Index : Natural) return Quick_Open_Result;

   function Build_Snapshot
     (State : Quick_Open_State) return Quick_Open_Snapshot;

   --  shared projection-surface contract predicates.  Quick Open
   --  remains an observation-only projection: query/filter/selection are local
   --  UI state, result rows are retained candidates, and no file lifecycle
   --  routes, prompt state, target history, repair cache, filesystem probe,
   --  or adjacent-surface projection import is owned here.
   function Quick_Open_No_Duplicate_Lifecycle_State
     (State : Quick_Open_State) return Boolean;

   function Quick_Open_No_Prompt_State
     (State : Quick_Open_State) return Boolean;

   function Quick_Open_Query_Selection_Source_Target_Boundary
     (State : Quick_Open_State) return Boolean;

   function Quick_Open_File_Lifecycle_Observation_Canonical
     (State : Quick_Open_State) return Boolean;

   function Quick_Open_File_Lifecycle_Observation_Frozen
     (State : Quick_Open_State) return Boolean;

   function Geometry
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Quick_Open_Config;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Editor.Layout.Rect;

   function Hit_Test
     (Body_Rect   : Editor.Layout.Rect;
      Config      : Quick_Open_Config;
      State       : Quick_Open_State;
      X           : Integer;
      Y           : Integer;
      Cell_Width  : Positive;
      Cell_Height : Positive) return Quick_Open_Hit_Result;

private
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Quick_Open_Result);

   type Quick_Open_State is record
      Opened         : Boolean := False;
      Query_Field    : Editor.Input_Field.Input_Field_State;
      Kind_Filter    : Quick_Open_File_Kind_Filter := All_Files;
      Scope          : Ada.Strings.Unbounded.Unbounded_String;
      Results        : Result_Vectors.Vector;
      Results_Stale  : Boolean := False;
      Project_Available : Boolean := False;
      Known_Total    : Natural := 0;
      Filtered_Total : Natural := 0;
      Selected_Index : Natural := 0;
      Top_Index      : Natural := 1;
      Visible_Window : Natural := 12;
      Priority       : Quick_Open_Priority_Mode := Path;
   end record;

end Editor.Quick_Open;
