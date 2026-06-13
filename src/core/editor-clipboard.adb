with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Clipboard is

   Clipboard_Text     : Unbounded_String := Null_Unbounded_String;
   Clipboard_Has_Text : Boolean := False;

   procedure Set_Text (Text : Unbounded_String) is
   begin
      if Length (Text) = 0 then
         Clear;
      else
         Clipboard_Text := Text;
         Clipboard_Has_Text := True;
      end if;
   end Set_Text;

   function Get_Text return Unbounded_String is
   begin
      if Clipboard_Has_Text then
         return Clipboard_Text;
      else
         return Null_Unbounded_String;
      end if;
   end Get_Text;

   function Has_Text return Boolean is
   begin
      return Clipboard_Has_Text;
   end Has_Text;

   procedure Clear is
   begin
      Clipboard_Text := Null_Unbounded_String;
      Clipboard_Has_Text := False;
   end Clear;

end Editor.Clipboard;
