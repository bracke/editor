with Interfaces.C;

package body Editor.Render_Layers is

   function Order
     (Layer : Render_Layer) return Natural
   is
   begin
      return Render_Layer'Pos (Layer);
   end Order;

   function To_C
     (Layer : Render_Layer) return Interfaces.C.int
   is
   begin
      return Interfaces.C.int (Order (Layer));
   end To_C;

   function C_First return Interfaces.C.int is
   begin
      return To_C (First_Render_Layer);
   end C_First;

   function C_Last return Interfaces.C.int is
   begin
      return To_C (Last_Render_Layer);
   end C_Last;

end Editor.Render_Layers;
