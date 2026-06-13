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

   type Problem_Row is record
      Diagnostic_Index : Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.No_Diagnostic;
      Severity         : Problem_Row_Severity := Problem_Info;
      Row              : Natural := 0;
      Column           : Natural := 0;
      Message          : Ada.Strings.Unbounded.Unbounded_String;
      Source_File      : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Problems_View_State is record
      Selected_Row_Index : Natural := 0;
      Top_Row            : Natural := 1;
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

   function Format_Header
     (Config : Problems_View_Config;
      Count  : Natural) return String;

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
