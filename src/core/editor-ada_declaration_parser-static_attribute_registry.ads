with Ada.Strings.Unbounded;

package Editor.Ada_Declaration_Parser.Static_Attribute_Registry is

   type Registry is private;

   function Value
     (Store                : Registry;
      Normalized_Name      : String;
      Normalized_Attribute : String;
      Result               : out Natural) return Boolean;

   procedure Register
     (Store                : in out Registry;
      Normalized_Name      : String;
      Normalized_Attribute : String;
      Value                : Natural);

private

   Max_Static_Attribute_Values : constant Positive := 256;

   type Static_Attribute_Value_Info is record
      Normalized_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Attribute : Ada.Strings.Unbounded.Unbounded_String;
      Value                : Natural := 0;
   end record;

   type Static_Attribute_Value_Table is
     array (Positive range 1 .. Max_Static_Attribute_Values)
       of Static_Attribute_Value_Info;

   type Registry is record
      Values : Static_Attribute_Value_Table;
      Count  : Natural := 0;
   end record;

end Editor.Ada_Declaration_Parser.Static_Attribute_Registry;
