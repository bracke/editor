with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.State;

package Editor.Buffer_Switcher_Contextual_Hints is

   type Switcher_Contextual_Hint is record
      Command_Id      : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Label           : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Keybinding_Text : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Is_Enabled      : Boolean := False;
      Disabled_Reason : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Switcher_Contextual_Hint_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Switcher_Contextual_Hint);

   Default_Max_Hints : constant Positive := 5;

   function Build_Switcher_Contextual_Hints
     (S         : Editor.State.State_Type;
      Max_Hints : Positive := Default_Max_Hints)
      return Switcher_Contextual_Hint_Vectors.Vector;

   function Format_Switcher_Contextual_Hints
     (Hints : Switcher_Contextual_Hint_Vectors.Vector) return String;

   function Contextual_Hint_Text
     (S         : Editor.State.State_Type;
      Max_Hints : Positive := Default_Max_Hints) return String;

   function Hint_Command_Available
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return Boolean;

   function Hint_Keybinding_Text
     (Id               : Editor.Commands.Command_Id;
      Show_Keybindings : Boolean) return String;

end Editor.Buffer_Switcher_Contextual_Hints;
