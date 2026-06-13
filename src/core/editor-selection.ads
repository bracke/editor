with Ada.Strings.Unbounded;
with Editor.State;
with Editor.Unicode;
with Editor.Cursors; use Editor.Cursors;

package Editor.Selection is

   type Text_Position is record
      Row    : Natural := 0;
      Column : Natural := 0;
   end record;

   type Text_Range is record
      Start_Position : Text_Position;
      End_Position   : Text_Position;
      Is_Empty       : Boolean := True;
   end record;

   type Selection_Shape is
     (No_Selection,
      Linear_Selection,
      Line_Selection,
      Rectangular_Selection,
      Multi_Selection);

   type Rectangular_Range is record
      Start_Row    : Natural := 0;
      End_Row      : Natural := 0;
      Start_Column : Natural := 0;
      End_Column   : Natural := 0;
      Is_Empty     : Boolean := True;
   end record;

   type Rectangular_Selection_Target is record
      Found : Boolean := False;
      Selection_Range : Rectangular_Range;
   end record;

   type Selection_Target is record
      Found : Boolean := False;
      Selection_Range : Text_Range;
   end record;

   type Selection_Validation_Status is
     (Selection_Ok,
      Selection_No_Active_Buffer,
      Selection_No_Caret,
      Selection_Empty,
      Selection_Invalid);

   type Active_Selection_Range is record
      Low  : Cursor_Index := 0;
      High : Cursor_Index := 0;
   end record;

   function Is_Before
     (Left  : Text_Position;
      Right : Text_Position) return Boolean;

   function Is_Equal
     (Left  : Text_Position;
      Right : Text_Position) return Boolean;

   function Normalize_Range
     (Left  : Text_Position;
      Right : Text_Position) return Text_Range;

   --  Normalize a grid-cell rectangular selection. Rows are inclusive and
   --  columns are half-open: Start_Column .. End_Column - 1. A non-empty
   --  one-column rectangle therefore has End_Column = Start_Column + 1.
   function Normalize_Rectangular_Range
     (Anchor : Text_Position;
      Cursor : Text_Position) return Rectangular_Range;

   function Rectangular_Row_Span
     (Selection_Range : Rectangular_Range;
      Row   : Natural) return Rectangular_Selection_Target;

   function Validate_Active_Selection_Range
     (S     : Editor.State.State_Type;
      Selection_Range : out Active_Selection_Range) return Selection_Validation_Status;

   function Normalize_Active_Selection
     (S : Editor.State.State_Type) return Active_Selection_Range;

   function Extract_Selected_Text
     (S : Editor.State.State_Type) return Ada.Strings.Unbounded.Unbounded_String;

   --  Return the active normalized linear selection length in buffer code
   --  points. Invalid, absent, rectangular-only, or empty selections return 0.
   function Selected_Character_Count
     (S : Editor.State.State_Type) return Natural;

   --  Return the number of logical lines touched by the active normalized
   --  linear selection. A selection that ends exactly at column zero on the
   --  next line counts the preceding selected line only.
   function Selected_Line_Count
     (S : Editor.State.State_Type) return Natural;

   function Is_Selection_Word_Character
     (Code : Editor.Unicode.Code_Point) return Boolean;

   function Select_All_Range_For_Buffer
     (S : Editor.State.State_Type) return Active_Selection_Range;

   function Current_Word_Range_At_Caret
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Active_Selection_Range;

   procedure Apply_Active_Buffer_Selection
     (S      : in out Editor.State.State_Type;
      Anchor : Cursor_Index;
      Pos    : Cursor_Index);

   function Line_Range
     (S   : Editor.State.State_Type;
      Row : Natural) return Selection_Target;

   function Line_Range_At
     (S   : Editor.State.State_Type;
      Row : Natural) return Selection_Target;

   function Lines_Range
     (S         : Editor.State.State_Type;
      Start_Row : Natural;
      End_Row   : Natural) return Selection_Target;

   function Extend_Line_Range
     (S          : Editor.State.State_Type;
      Anchor     : Text_Position;
      Target_Row : Natural) return Selection_Target;

   function Word_Range_At
     (S      : Editor.State.State_Type;
      Row    : Natural;
      Column : Natural) return Selection_Target;

   function Word_Range_Around_Caret
     (S      : Editor.State.State_Type;
      Row    : Natural;
      Column : Natural) return Selection_Target;

   function Has_Selection
     (S : Editor.State.State_Type) return Boolean;

   function Is_Rectangular_Selection
     (S : Editor.State.State_Type) return Boolean;

   function Is_Line_Selection
     (S     : Editor.State.State_Type;
      Selection_Range : Text_Range) return Boolean;

   function Active_Selection_Shape
     (S : Editor.State.State_Type) return Selection_Shape;

end Editor.Selection;
