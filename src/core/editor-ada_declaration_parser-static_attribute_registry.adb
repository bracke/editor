with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Declaration_Parser.Static_Attribute_Registry is

   function Value
     (Store                : Registry;
      Normalized_Name      : String;
      Normalized_Attribute : String;
      Result               : out Natural) return Boolean
   is
   begin
      Result := 0;
      if Normalized_Name = "" or else Normalized_Attribute = "" then
         return False;
      end if;

      for I in 1 .. Store.Count loop
         if To_String (Store.Values (I).Normalized_Name) = Normalized_Name
           and then To_String (Store.Values (I).Normalized_Attribute) =
             Normalized_Attribute
         then
            Result := Store.Values (I).Value;
            return True;
         end if;
      end loop;

      return False;
   end Value;

   procedure Register
     (Store                : in out Registry;
      Normalized_Name      : String;
      Normalized_Attribute : String;
      Value                : Natural)
   is
   begin
      if Normalized_Name = "" or else Normalized_Attribute = "" then
         return;
      end if;

      for I in 1 .. Store.Count loop
         if To_String (Store.Values (I).Normalized_Name) = Normalized_Name
           and then To_String (Store.Values (I).Normalized_Attribute) =
             Normalized_Attribute
         then
            Store.Values (I).Value := Value;
            return;
         end if;
      end loop;

      if Store.Count >= Max_Static_Attribute_Values then
         return;
      end if;

      Store.Count := Store.Count + 1;
      Store.Values (Store.Count) :=
        (Normalized_Name      => To_Unbounded_String (Normalized_Name),
         Normalized_Attribute => To_Unbounded_String (Normalized_Attribute),
         Value                => Value);
   end Register;

end Editor.Ada_Declaration_Parser.Static_Attribute_Registry;
