with Ada.Strings.Unbounded;

package Editor.Input_Field is

   type Input_Field_State is private;

   type Field_Selection_Mode is
     (No_Field_Selection,
      Field_Selection_Active);

   type Field_View is record
      First_Visible_Column  : Natural := 0;
      Visible_Columns       : Natural := 0;
      Cursor_Visible_Column : Natural := 0;
   end record;

   type Field_Snapshot is record
      Text                  : Ada.Strings.Unbounded.Unbounded_String;
      Visible_Text          : Ada.Strings.Unbounded.Unbounded_String;
      Cursor_Column         : Natural := 0;
      First_Visible_Column  : Natural := 0;
      Cursor_Visible_Column : Natural := 0;
      Has_Selection         : Boolean := False;
      Selection_Start       : Natural := 0;
      Selection_End         : Natural := 0;
   end record;

   procedure Clear
     (Field : in out Input_Field_State);

   function Text
     (Field : Input_Field_State) return String;

   procedure Set_Text
     (Field : in out Input_Field_State;
      Text  : String);

   function Is_Empty
     (Field : Input_Field_State) return Boolean;

   function Cursor_Column
     (Field : Input_Field_State) return Natural;

   procedure Set_Cursor_Column
     (Field  : in out Input_Field_State;
      Column : Natural);

   procedure Set_Cursor_From_Visible_Column
     (Field           : in out Input_Field_State;
      Visible_Column  : Natural;
      Visible_Columns : Natural);

   procedure Move_Cursor_Left
     (Field            : in out Input_Field_State;
      Extend_Selection : Boolean := False);

   procedure Move_Cursor_Right
     (Field            : in out Input_Field_State;
      Extend_Selection : Boolean := False);

   procedure Move_Cursor_Start
     (Field            : in out Input_Field_State;
      Extend_Selection : Boolean := False);

   procedure Move_Cursor_End
     (Field            : in out Input_Field_State;
      Extend_Selection : Boolean := False);

   procedure Insert_Text
     (Field : in out Input_Field_State;
      Text  : String);

   procedure Backspace
     (Field : in out Input_Field_State);

   procedure Delete_Forward
     (Field : in out Input_Field_State);

   procedure Select_All
     (Field : in out Input_Field_State);

   procedure Clear_Selection
     (Field : in out Input_Field_State);

   function Has_Selection
     (Field : Input_Field_State) return Boolean;

   function Selected_Text
     (Field : Input_Field_State) return String;

   function Snapshot
     (Field           : Input_Field_State;
      Visible_Columns : Natural) return Field_Snapshot;

private
   type Input_Field_State is record
      Value           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Cursor          : Natural := 0;
      Selection_Mode   : Field_Selection_Mode := No_Field_Selection;
      Selection_Anchor : Natural := 0;
      Selection_Start  : Natural := 0;
      Selection_End    : Natural := 0;
   end record;

end Editor.Input_Field;
