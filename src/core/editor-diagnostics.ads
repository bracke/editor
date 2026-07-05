with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Cursors;

package Editor.Diagnostics is

   type Diagnostic_Severity is
     (Hint,
      Information,
      Note,
      Warning,
      Error,
      Unknown);

   type Diagnostic_Index is new Natural;
   No_Diagnostic : constant Diagnostic_Index := 0;

   type Diagnostic_Range is record
      Start_Index  : Editor.Cursors.Cursor_Index;
      End_Index    : Editor.Cursors.Cursor_Index;
      Severity     : Diagnostic_Severity;
      Message      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Location : Boolean := False;
      Start_Row    : Natural := 0;
      Start_Column : Natural := 0;
      Quick_Fix_Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Detail : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   subtype Diagnostic is Diagnostic_Range;

   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Diagnostic_Range);

   type Diagnostic_Target is record
      Found  : Boolean := False;
      Row    : Natural := 0;
      Column : Natural := 0;
      Index  : Diagnostic_Index := No_Diagnostic;
   end record;

   procedure Add
     (Diagnostics : in out Diagnostic_Vectors.Vector;
      Start_Index : Editor.Cursors.Cursor_Index;
      End_Index   : Editor.Cursors.Cursor_Index;
      Severity    : Diagnostic_Severity;
      Message     : String := "";
      Quick_Fix_Label  : String := "";
      Quick_Fix_Detail : String := "");

   procedure Add
     (Diagnostics  : in out Diagnostic_Vectors.Vector;
      Start_Index  : Editor.Cursors.Cursor_Index;
      End_Index    : Editor.Cursors.Cursor_Index;
      Start_Row    : Natural;
      Start_Column : Natural;
      Severity     : Diagnostic_Severity;
      Message      : String := "";
      Quick_Fix_Label  : String := "";
      Quick_Fix_Detail : String := "");

   procedure Clear
     (Diagnostics : in out Diagnostic_Vectors.Vector);

   function Diagnostic_Count
     (State : Diagnostic_Vectors.Vector) return Natural;

   function Diagnostic_At
     (State : Diagnostic_Vectors.Vector;
      Index : Positive) return Diagnostic;

   function Ordered_Diagnostic_Count
     (State : Diagnostic_Vectors.Vector) return Natural;

   function Ordered_Diagnostic_Index_At
     (State            : Diagnostic_Vectors.Vector;
      Ordered_Position : Positive) return Diagnostic_Index;

   function Is_Valid_Diagnostic_Index
     (State : Diagnostic_Vectors.Vector;
      Index : Diagnostic_Index) return Boolean;

   function First_Diagnostic
     (State : Diagnostic_Vectors.Vector;
      Found : out Boolean) return Diagnostic_Index;

   function Last_Diagnostic
     (State : Diagnostic_Vectors.Vector;
      Found : out Boolean) return Diagnostic_Index;

   function Next_Diagnostic_After
     (State  : Diagnostic_Vectors.Vector;
      Row    : Natural;
      Column : Natural;
      Wrap   : Boolean := True;
      Found  : out Boolean) return Diagnostic_Index;

   function Previous_Diagnostic_Before
     (State  : Diagnostic_Vectors.Vector;
      Row    : Natural;
      Column : Natural;
      Wrap   : Boolean := True;
      Found  : out Boolean) return Diagnostic_Index;

   function Dominant_Diagnostic_On_Row
     (State : Diagnostic_Vectors.Vector;
      Row   : Natural;
      Found : out Boolean) return Diagnostic_Index;

   function Target_For_Diagnostic
     (State : Diagnostic_Vectors.Vector;
      Index : Diagnostic_Index) return Diagnostic_Target;

end Editor.Diagnostics;
