with Ada.Strings.Unbounded;

package Editor.Clipboard is

   --  Canonical editor clipboard state for Phase 376: transient,
   --  session-local, plain text only.  Clipboard contents are not persisted,
   --  not Undo/Redo state, and not Navigation History state.

   procedure Set_Text
     (Text : Ada.Strings.Unbounded.Unbounded_String);

   function Get_Text
     return Ada.Strings.Unbounded.Unbounded_String;

   function Has_Text return Boolean;

   procedure Clear;

end Editor.Clipboard;
