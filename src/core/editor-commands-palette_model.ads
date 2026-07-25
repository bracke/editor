with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Commands.Descriptors;

package Editor.Commands.Palette_Model is

   use Ada.Strings.Unbounded;

   type Command_Palette_Candidate is record
      Id             : Command_Id := No_Command;
      Label          : Unbounded_String := Null_Unbounded_String;
      Description    : Unbounded_String := Null_Unbounded_String;
      Category       : Descriptors.Command_Category :=
        Descriptors.Internal_Category;
      Category_Label : Unbounded_String := Null_Unbounded_String;
      Available      : Boolean := True;
      Reason         : Unbounded_String := Null_Unbounded_String;
      Has_Keybinding : Boolean := False;
      Keybinding_Display : Unbounded_String := Null_Unbounded_String;
      Reference_Summary : Unbounded_String := Null_Unbounded_String;
      Family : Descriptors.Command_Family_Id :=
        Descriptors.No_Command_Family;
      Effect_Classification : Descriptors.Command_Effect_Classification_Id :=
        Descriptors.No_Command_Effect;
      Match_Score    : Natural := 0;
      Registry_Order : Natural := 0;
   end record;

   package Command_Palette_Candidate_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Command_Palette_Candidate);

end Editor.Commands.Palette_Model;
