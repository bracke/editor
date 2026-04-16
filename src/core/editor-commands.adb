package body Editor.Commands is

   --  No runtime logic is required for this module in the current design.
   --  It exists purely as a type/contract definition layer.

   function "=" (L, R : Command) return Boolean is
   begin
      return L.Kind = R.Kind
        and then L.Pos = R.Pos
        and then L.Ch = R.Ch;
   end "=";

end Editor.Commands;