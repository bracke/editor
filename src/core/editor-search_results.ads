with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Editor.Project_Search;
with Editor.Layout;
with Editor.Buffers;

package Editor.Search_Results is

   type Search_Results_View_Config is record
      Header_Height_In_Rows : Natural := 1;
      Row_Height_In_Rows    : Natural := 1;
      Show_Header           : Boolean := True;
      Show_File_Group_Rows  : Boolean := True;
      Max_Snippet_Columns   : Natural := 160;
      Indent_Result_Columns : Natural := 2;
   end record;

   type Search_Results_Row_Kind is
     (Search_Results_Header_Row,
      Search_Results_File_Row,
      Search_Results_Match_Row,
      Search_Results_Empty_Row);

   type Search_Results_Row is record
      Kind         : Search_Results_Row_Kind := Search_Results_Empty_Row;
      Result_Index : Natural := 0;
      File_Index   : Natural := 0;
      Text         : Ada.Strings.Unbounded.Unbounded_String;
      Project_Relative_Path : Ada.Strings.Unbounded.Unbounded_String;
      Line_Number  : Natural := 0;
      Line_Preview         : Ada.Strings.Unbounded.Unbounded_String;
      Match_Column         : Natural := 0;
      Preview_Match_Start  : Natural := 0;
      Preview_Match_Length : Natural := 0;
      Display_Text         : Ada.Strings.Unbounded.Unbounded_String;
      Is_Open              : Boolean := False;
      Is_Active    : Boolean := False;
      Is_Dirty     : Boolean := False;
      Is_Selected  : Boolean := False;
   end record;

   type Search_Results_Zone is
     (Outside_Search_Results,
      Search_Results_Background_Zone,
      Search_Results_Header_Zone,
      Search_Results_File_Row_Zone,
      Search_Results_Match_Row_Zone);

   type Search_Results_Hit_Result is record
      Zone         : Search_Results_Zone := Outside_Search_Results;
      Row_Index    : Natural := 0;
      Result_Index : Natural := 0;
   end record;

   type Search_Results_Row_Direction is
     (Previous_Row,
      Next_Row);

   type Search_Results_View_State is record
      Top_Row : Natural := 1;
   end record;

   type Search_Results_Snapshot is private;

   procedure Clear
     (Snapshot : in out Search_Results_Snapshot);

   function Build_Snapshot
     (Search : Editor.Project_Search.Project_Search_State;
      Config : Search_Results_View_Config) return Search_Results_Snapshot;

   function Build_Snapshot
     (Search  : Editor.Project_Search.Project_Search_State;
      Config  : Search_Results_View_Config;
      Buffers : Editor.Buffers.Buffer_Registry) return Search_Results_Snapshot;

   function Row_Count
     (Snapshot : Search_Results_Snapshot) return Natural;

   function Row
     (Snapshot : Search_Results_Snapshot;
      Index    : Positive) return Search_Results_Row;

   function Format_Header
     (Search : Editor.Project_Search.Project_Search_State) return String;

   function Format_File_Row
     (Group : Editor.Project_Search.Project_Search_File_Group) return String;

   function Format_Result_Row
     (Result : Editor.Project_Search.Project_Search_Result;
      Width  : Natural) return String;

   function Format_Result_Snippet
     (Result          : Editor.Project_Search.Project_Search_Result;
      Max_Columns     : Natural;
      Context_Columns : Natural := 40) return String;

   function Row_For_Result
     (Snapshot     : Search_Results_Snapshot;
      Result_Index : Natural;
      Found        : out Boolean) return Natural;

   function Result_For_Row
     (Snapshot  : Search_Results_Snapshot;
      Row_Index : Natural;
      Found     : out Boolean) return Natural;

   function First_Result_In_File_Group
     (Snapshot : Search_Results_Snapshot;
      File_Row : Natural;
      Found    : out Boolean) return Natural;

   procedure Ensure_Selected_Row_Visible
     (View_State        : in out Search_Results_View_State;
      Snapshot          : Search_Results_Snapshot;
      Selected_Result   : Natural;
      Visible_Row_Count : Natural);

   procedure Clamp_Viewport
     (View_State        : in out Search_Results_View_State;
      Snapshot          : Search_Results_Snapshot;
      Visible_Row_Count : Natural);

   procedure Scroll_By
     (View_State        : in out Search_Results_View_State;
      Snapshot          : Search_Results_Snapshot;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer);

   procedure Move_Row_Selection
     (View_State : in out Search_Results_View_State;
      Search     : in out Editor.Project_Search.Project_Search_State;
      Snapshot   : Search_Results_Snapshot;
      Direction  : Search_Results_Row_Direction);

   function Visible_Snapshot
     (Snapshot          : Search_Results_Snapshot;
      View_State        : Search_Results_View_State;
      Visible_Row_Count : Natural) return Search_Results_Snapshot;

   function Truncate_Text
     (Text        : String;
      Max_Columns : Natural) return String;

   function Hit_Test
     (Panel_Rect  : Editor.Layout.Rect;
      Config      : Search_Results_View_Config;
      Snapshot    : Search_Results_Snapshot;
      Cell_Height : Natural;
      X           : Integer;
      Y           : Integer) return Search_Results_Hit_Result;

private
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Search_Results_Row);

   type Search_Results_Snapshot is record
      Project_Search_Visible          : Boolean := False;
      Project_Search_Query            : Ada.Strings.Unbounded.Unbounded_String;
      Project_Search_File_Kind_Filter : Editor.Project_Search.Project_Search_File_Kind_Filter :=
        Editor.Project_Search.Project_Search_Kind_All;
      Project_Search_Path_Scope       : Ada.Strings.Unbounded.Unbounded_String;
      Project_Search_Case_Sensitive   : Boolean := False;
      Project_Search_Result_Count     : Natural := 0;
      Project_Search_Matched_File_Count : Natural := 0;
      Project_Search_Eligible_File_Count : Natural := 0;
      Project_Search_Searched_File_Count : Natural := 0;
      Project_Search_Skipped_File_Count  : Natural := 0;
      Project_Search_Truncated           : Boolean := False;
      Project_Search_Selected_Index   : Natural := 0;
      Project_Search_Empty_Message    : Ada.Strings.Unbounded.Unbounded_String;
      Project_Search_Header_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Rows : Row_Vectors.Vector;
   end record;

end Editor.Search_Results;
