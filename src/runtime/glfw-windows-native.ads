with System;

package Glfw.Windows.Native is
   procedure Set_Client_API_No_API;

   procedure Init_No_API
     (Object        : not null access Window'Class;
      Width, Height : Size;
      Title         : String);

   function Raw_Handle
     (Object : not null access Window'Class) return System.Address;
end Glfw.Windows.Native;
