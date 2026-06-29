with Interfaces.C;
with System.Address_To_Access_Conversions;

with Glfw.API;
with Glfw.Enums;

package body Glfw.Windows.Native is
   use type System.Address;

   package Conv is new System.Address_To_Access_Conversions (Window'Class);

   procedure Set_Client_API_No_API is
   begin
      Glfw.API.Window_Hint
        (Glfw.Enums.Client_API, Interfaces.C.int (0));
   end Set_Client_API_No_API;

   procedure Init_No_API
     (Object        : not null access Window'Class;
      Width, Height : Size;
      Title         : String)
   is
      C_Title : constant Interfaces.C.char_array :=
        Interfaces.C.To_C (Title);
   begin
      if Object.Handle /= System.Null_Address then
         raise Operation_Exception with "Window has already been initialized";
      end if;

      Object.Handle :=
        Glfw.API.Create_Window
          (Interfaces.C.int (Width),
           Interfaces.C.int (Height),
           C_Title,
           System.Null_Address,
           System.Null_Address);

      if Object.Handle = System.Null_Address then
         raise Creation_Error;
      end if;

      Glfw.API.Set_Window_User_Pointer
        (Object.Handle,
         Conv.To_Address (Conv.Object_Pointer'(Object.all'Unchecked_Access)));
   end Init_No_API;

   function Raw_Handle
     (Object : not null access Window'Class) return System.Address is
   begin
      return Object.Handle;
   end Raw_Handle;
end Glfw.Windows.Native;
