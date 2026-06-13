with Editor.Input_Field;
with Ada.Strings.Unbounded;

package Editor.Go_To_Line is

   type Go_To_Line_State is private;

   type Go_To_Line_Validation_Status is
     (Go_To_Line_Valid,
      Go_To_Line_Empty,
      Go_To_Line_Invalid,
      Go_To_Line_Out_Of_Range);

   type Go_To_Line_Validation_Result is record
      Status     : Go_To_Line_Validation_Status := Go_To_Line_Empty;
      Line       : Natural := 0;
      Has_Column : Boolean := False;
      Column     : Natural := 0;
      --  Column is one-based when Has_Column is true.
   end record;

   procedure Clear (State : in out Go_To_Line_State);
   procedure Open (State : in out Go_To_Line_State);
   procedure Close (State : in out Go_To_Line_State);
   function Is_Open (State : Go_To_Line_State) return Boolean;

   function Text (State : Go_To_Line_State) return String;
   function Has_Error (State : Go_To_Line_State) return Boolean;
   function Error_Text (State : Go_To_Line_State) return String;
   procedure Set_Error (State : in out Go_To_Line_State; Text : String);
   procedure Clear_Error (State : in out Go_To_Line_State);
   procedure Set_Text (State : in out Go_To_Line_State; Text : String);
   procedure Insert_Text (State : in out Go_To_Line_State; Text : String);
   procedure Backspace (State : in out Go_To_Line_State);
   procedure Delete_Forward (State : in out Go_To_Line_State);
   procedure Move_Cursor_Left (State : in out Go_To_Line_State);
   procedure Move_Cursor_Right (State : in out Go_To_Line_State);
   procedure Move_Cursor_Start (State : in out Go_To_Line_State);
   procedure Move_Cursor_End (State : in out Go_To_Line_State);
   procedure Select_All (State : in out Go_To_Line_State);
   function Cursor_Column (State : Go_To_Line_State) return Natural;

   function Validate
     (State      : Go_To_Line_State;
      Line_Count : Natural) return Go_To_Line_Validation_Result;

   function Snapshot
     (State           : Go_To_Line_State;
      Visible_Columns : Natural) return Editor.Input_Field.Field_Snapshot;

private
   type Go_To_Line_State is record
      Opened : Boolean := False;
      Field  : Editor.Input_Field.Input_Field_State;
      Error  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

end Editor.Go_To_Line;
