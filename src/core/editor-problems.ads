with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Editor.Diagnostics;
with Editor.Layout;

package Editor.Problems is

   type Problems_View_Config is record
      Enabled_By_Default      : Boolean := False;
      Header_Height_In_Rows   : Natural := 1;
      Row_Height_In_Rows      : Natural := 1;
      Show_Header             : Boolean := True;
      Show_File_Name          : Boolean := False;
      Show_Severity           : Boolean := True;
      Show_Row_Column         : Boolean := True;
      Maximum_Message_Columns : Natural := 120;
   end record;

   type Problem_Row_Severity is
     (Problem_Error,
      Problem_Warning,
      Problem_Info,
      Problem_Hint);

   type Problems_Severity_Filter is
     (Problems_Show_All,
      Problems_Show_Errors,
      Problems_Show_Warnings,
      Problems_Show_Info,
      Problems_Show_Hints);

   type Problems_Group_Mode is
     (Problems_Group_By_Severity,
      Problems_Group_By_Source);

   type Problems_Sort_Mode is
     (Problems_Sort_By_Location,
      Problems_Sort_By_Severity,
      Problems_Sort_By_Source);

   type Problems_Header_Action is
     (Problems_Header_Filter_Action,
      Problems_Header_Sort_Action,
      Problems_Header_Group_Action);

   type Problem_Row is record
      Diagnostic_Index : Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.No_Diagnostic;
      Severity         : Problem_Row_Severity := Problem_Info;
      Row              : Natural := 0;
      Column           : Natural := 0;
      Message          : Ada.Strings.Unbounded.Unbounded_String;
      Source_File      : Ada.Strings.Unbounded.Unbounded_String;
      Has_Target       : Boolean := False;
      Quick_Fix_Label  : Ada.Strings.Unbounded.Unbounded_String;
      Quick_Fix_Detail : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Problems_View_State is record
      Selected_Row_Index : Natural := 0;
      Top_Row            : Natural := 1;
      Severity_Filter    : Problems_Severity_Filter := Problems_Show_All;
      Sort_Mode          : Problems_Sort_Mode := Problems_Sort_By_Location;
      Group_Mode         : Problems_Group_Mode := Problems_Group_By_Severity;
   end record;

   type Problems_Row_Direction is
     (Previous_Row,
      Next_Row);

   type Problems_Snapshot is private;

   procedure Clear_View
     (View : in out Problems_View_State);

   function Selected_Row_Index
     (View : Problems_View_State) return Natural;

   procedure Set_Selected_Row_Index
     (View  : in out Problems_View_State;
      Index : Natural);

   function Top_Row
     (View : Problems_View_State) return Natural;

   procedure Set_Top_Row
     (View : in out Problems_View_State;
      Row  : Natural);

   function Severity_Filter
     (View : Problems_View_State) return Problems_Severity_Filter;

   procedure Set_Severity_Filter
     (View   : in out Problems_View_State;
      Filter : Problems_Severity_Filter);

   function Severity_Filter_Label
     (Filter : Problems_Severity_Filter) return String;

   function Sort_Mode_Label
     (Sort : Problems_Sort_Mode) return String;

   function Group_Mode_Label
     (Group : Problems_Group_Mode) return String;

   function Header_Action_Hint
     (View : Problems_View_State) return String;

   function Header_Action_At_X
     (Panel_Width : Natural;
      X_Offset    : Natural) return Problems_Header_Action;

   function Header_Action_Label
     (View   : Problems_View_State;
      Action : Problems_Header_Action) return String;

   function Group_Label
     (Row  : Problem_Row;
      Mode : Problems_Group_Mode) return String;

   function Severity_Count
     (Snapshot : Problems_Snapshot;
      Severity : Problem_Row_Severity) return Natural;

   procedure Clear
     (Snapshot : in out Problems_Snapshot);

   function Row_Count
     (Snapshot : Problems_Snapshot) return Natural;

   function Row
     (Snapshot : Problems_Snapshot;
      Index    : Positive) return Problem_Row;

   function Build_Snapshot
     (Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector)
      return Problems_Snapshot;

   function Message_No_Problems return String;
   function Message_No_Visible_Problems return String;
   function Empty_State_Message
     (Visible_Count : Natural;
      Total_Count   : Natural) return String;

   function Format_Row
     (Config : Problems_View_Config;
      Row    : Problem_Row;
      Width  : Natural) return String;

   function Row_For_Diagnostic
     (Snapshot         : Problems_Snapshot;
      Diagnostic_Index : Editor.Diagnostics.Diagnostic_Index;
      Found            : out Boolean) return Natural;

   function Diagnostic_For_Row
     (Snapshot  : Problems_Snapshot;
      Row_Index : Natural;
      Found     : out Boolean)
      return Editor.Diagnostics.Diagnostic_Index;

   function Row_Has_Target
     (Row : Problem_Row) return Boolean;

   function Row_Target_Unavailable_Label
     (Row : Problem_Row) return String;

   function First_Diagnostic_Row
     (Snapshot : Problems_Snapshot;
      Found    : out Boolean) return Natural;

   function Last_Diagnostic_Row
     (Snapshot : Problems_Snapshot;
      Found    : out Boolean) return Natural;

   procedure Ensure_Valid_Selection
     (View     : in out Problems_View_State;
      Snapshot : Problems_Snapshot);

   procedure Move_Selection
     (View      : in out Problems_View_State;
      Snapshot  : Problems_Snapshot;
      Direction : Problems_Row_Direction;
      Wrap      : Boolean := True);

   procedure Ensure_Selected_Row_Visible
     (View              : in out Problems_View_State;
      Snapshot          : Problems_Snapshot;
      Visible_Row_Count : Natural);

   procedure Clamp_Viewport
     (View              : in out Problems_View_State;
      Snapshot          : Problems_Snapshot;
      Visible_Row_Count : Natural);

   procedure Scroll_By
     (View              : in out Problems_View_State;
      Snapshot          : Problems_Snapshot;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer);

   function Visible_Snapshot
     (Snapshot          : Problems_Snapshot;
      View              : Problems_View_State;
      Visible_Row_Count : Natural) return Problems_Snapshot;

   function Filtered_Snapshot
     (Snapshot : Problems_Snapshot;
      View     : Problems_View_State) return Problems_Snapshot;

   function Sorted_Snapshot
     (Snapshot : Problems_Snapshot;
      Sort     : Problems_Sort_Mode) return Problems_Snapshot;

   function Review_Snapshot
     (Snapshot : Problems_Snapshot;
      View     : Problems_View_State) return Problems_Snapshot;

   function Format_Header
     (Config : Problems_View_Config;
      Count  : Natural;
      Filter : Problems_Severity_Filter := Problems_Show_All) return String;

   function Truncate_Text
     (Text        : String;
      Max_Columns : Natural) return String;

   type Problems_Zone is
     (Outside_Problems,
      Problems_Background_Zone,
      Problems_Header_Zone,
      Problems_Row_Zone);

   type Problems_Hit_Result is record
      Zone             : Problems_Zone := Outside_Problems;
      Row              : Natural := 0;
      Diagnostic_Index : Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.No_Diagnostic;
   end record;

   function Hit_Test
     (Panel_Rect  : Editor.Layout.Rect;
      Config      : Problems_View_Config;
      Snapshot    : Problems_Snapshot;
      Cell_Height : Natural;
      X           : Integer;
      Y           : Integer) return Problems_Hit_Result;

private
   package Problem_Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Problem_Row);

   type Problems_Snapshot is record
      Rows : Problem_Row_Vectors.Vector;
   end record;

end Editor.Problems;
