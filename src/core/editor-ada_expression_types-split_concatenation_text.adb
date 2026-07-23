with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Expression_Types.Cross_Unit_Selected_Subtype_Refinement;
with Editor.Ada_Expression_Types.Access_Text_Helpers;
with Editor.Ada_Expression_Types.Inference_Support;
with Editor.Ada_Expression_Types.Call_Inference;
with Editor.Ada_Expression_Types.Call_Text_Helpers;
with Editor.Ada_Expression_Types.Model_Accessors;
with Editor.Ada_Expression_Types.Operator_Helpers;
with Editor.Ada_Expression_Types.Statistics;
with Editor.Ada_Use_Type_Operators;
with Editor.Ada_Expression_Types.Status_Helpers;

separate (Editor.Ada_Expression_Types)
   procedure Split_Concatenation_Text
     (Text  : String;
      Left  : out Ada.Strings.Unbounded.Unbounded_String;
      Right : out Ada.Strings.Unbounded.Unbounded_String)
   is
      T : constant String := Trim (Text);
      Depth : Natural := 0;
   begin
      Left := To_Unbounded_String ("");
      Right := To_Unbounded_String ("");
      for I in T'Range loop
         if T (I) = '(' then
            Depth := Depth + 1;
         elsif T (I) = ')' and then Depth > 0 then
            Depth := Depth - 1;
         elsif T (I) = '&' and then Depth = 0 then
            if I > T'First then
               Left := To_Unbounded_String (Trim (T (T'First .. I - 1)));
            end if;
            if I < T'Last then
               Right := To_Unbounded_String (Trim (T (I + 1 .. T'Last)));
            end if;
            return;
         end if;
      end loop;
   end Split_Concatenation_Text;
