with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.External_Producers.Diagnostic_Text_Lines is

   package Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String);

   subtype Array_Type is Vectors.Vector;

end Editor.External_Producers.Diagnostic_Text_Lines;
