with Editor.State;
with Editor.Cursors;

package Editor.Navigation is

   use Editor.Cursors;


   type Navigation_Direction is
     (Backward,
      Forward);

   type Navigation_Unit is
     (Character_Unit,
      Word_Unit,
      Line_Unit,
      Page_Unit,
      Document_Unit,
      Line_Boundary_Unit);

   type Selection_Mode is
     (Move_Caret,
      Extend_Selection);

   type Navigation_Target is record
      Row    : Natural := 0;
      Column : Natural := 0;
   end record;

   type Navigation_Result is record
      Target                  : Navigation_Target;
      Preserve_Virtual_Column : Boolean := False;
      Found                   : Boolean := True;
   end record;

   function Clamp_Position
     (S      : Editor.State.State_Type;
      Row    : Natural;
      Column : Natural) return Navigation_Target;

   function Move_Character
     (S         : Editor.State.State_Type;
      Row       : Natural;
      Column    : Natural;
      Direction : Navigation_Direction) return Navigation_Result;

   function Move_Word
     (S         : Editor.State.State_Type;
      Row       : Natural;
      Column    : Natural;
      Direction : Navigation_Direction) return Navigation_Result;

   function Move_Line
     (S                       : Editor.State.State_Type;
      Row                     : Natural;
      Column                  : Natural;
      Direction               : Navigation_Direction;
      Preferred_Visual_Column : Natural) return Navigation_Result;

   function Move_Page
     (S                       : Editor.State.State_Type;
      Row                     : Natural;
      Column                  : Natural;
      Direction               : Navigation_Direction;
      Page_Row_Count          : Natural;
      Preferred_Visual_Column : Natural) return Navigation_Result;

   function Move_Document_Boundary
     (S         : Editor.State.State_Type;
      Direction : Navigation_Direction) return Navigation_Result;

   function Move_Line_Boundary
     (S         : Editor.State.State_Type;
      Row       : Natural;
      Column    : Natural;
      Direction : Navigation_Direction) return Navigation_Result;

   function Buffer_Length
     (S : Editor.State.State_Type) return Natural;

   function Has_Row
     (S   : Editor.State.State_Type;
      Row : Natural) return Boolean;

   function Line_Length
     (S   : Editor.State.State_Type;
      Row : Natural) return Natural;

   procedure Line_Column_For_Index
     (S     : Editor.State.State_Type;
      Index : Natural;
      Row   : out Natural;
      Col   : out Natural);

   function Index_For_Line_Column
     (S   : Editor.State.State_Type;
      Row : Natural;
      Col : Natural) return Natural;

   function Index_For_Point
     (S : Editor.State.State_Type;
      X : Natural;
      Y : Natural) return Cursor_Index;

   function Line_Start_Index
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural;

   function Line_End_Index
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural;

   function Document_Start
     (S : Editor.State.State_Type) return Natural;

   function Document_End
     (S : Editor.State.State_Type) return Natural;

   function Rows_Per_Page return Positive;

   procedure Vertical_Target_Info
     (S                : Editor.State.State_Type;
      Old_Caret        : Cursor_Index;
      Delta_Rows       : Integer;
      Preferred_Column : Natural;
      Target           : out Cursor_Index;
      Virtual_Column   : out Natural);

   function Vertical_Target
     (S                : Editor.State.State_Type;
      Old_Caret        : Cursor_Index;
      Delta_Rows       : Integer;
      Preferred_Column : Natural) return Cursor_Index;

   function Previous_Word_Start
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural;

   function Next_Word_Start
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural;

   function Next_Word_End
     (S     : Editor.State.State_Type;
      Index : Natural) return Natural;

   procedure Selectable_Run_At
     (S            : Editor.State.State_Type;
      Index        : Natural;
      Has_Run      : out Boolean;
      Start_Index  : out Natural;
      End_Index    : out Natural);

end Editor.Navigation;