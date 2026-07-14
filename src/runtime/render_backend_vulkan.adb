with GNAT.OS_Lib;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Interfaces;
with Interfaces.C;
with Interfaces.C.Strings;
with System;

with Editor.C_API;
with Editor.Font_Bridge;
with Editor.Render_Layers;
with Editor.Render_Packet;
with Vk;

package body Render_Backend_Vulkan is
   package C_Strings renames Interfaces.C.Strings;

   use type C.int;
   use type C.unsigned;
   use type C.unsigned_char;
   use type C.C_float;
   use type C.long;
   use type Interfaces.Integer_32;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type Ada.Directories.File_Size;
   use type System.Address;
   use type Vk.Image_Layout_T;
   use type Vk.Result_T;

   VK_TRUE : constant Interfaces.Unsigned_32 := 1;
   UINT32_MAX : constant Interfaces.Unsigned_32 := Interfaces.Unsigned_32'Last;
   UINT64_MAX : constant Interfaces.Unsigned_64 := Interfaces.Unsigned_64'Last;
   ERROR_OUT_OF_DATE_KHR : constant Vk.Result_T := -1_000_001_004;
   SUBOPTIMAL_KHR : constant Vk.Result_T := 1_000_001_003;
   WHOLE_SIZE : constant Interfaces.Unsigned_64 := Interfaces.Unsigned_64'Last;

   type Rect_Vertex is record
      X : C.C_float;
      Y : C.C_float;
      R : C.C_float;
      G : C.C_float;
      B : C.C_float;
   end record
     with Convention => C;

   type Push_Constants is record
      Width : C.C_float;
      Height : C.C_float;
   end record
     with Convention => C;

   type Glyph_Vertex is record
      X : C.C_float;
      Y : C.C_float;
      U : C.C_float;
      V : C.C_float;
      R : C.C_float;
      G : C.C_float;
      B : C.C_float;
   end record
     with Convention => C;

   Max_Rect_Vertices : constant Natural :=
     Editor.Render_Packet.Max_Rectangles * 6;
   Rect_Vertex_Size : constant Interfaces.Unsigned_64 :=
     Rect_Vertex'Size / 8;
   Max_Rect_Vertex_Bytes : constant Interfaces.Unsigned_64 :=
     Interfaces.Unsigned_64 (Max_Rect_Vertices) * Rect_Vertex_Size;
   Max_Glyph_Vertices : constant Natural := Editor.Render_Packet.Max_Glyphs * 6;
   Glyph_Vertex_Size : constant Interfaces.Unsigned_64 :=
     Glyph_Vertex'Size / 8;
   Max_Glyph_Vertex_Bytes : constant Interfaces.Unsigned_64 :=
     Interfaces.Unsigned_64 (Max_Glyph_Vertices) * Glyph_Vertex_Size;

   type Rect_Vertex_Array is array (Natural range <>) of Rect_Vertex;
   pragma Convention (C, Rect_Vertex_Array);
   type Glyph_Vertex_Array is array (Natural range <>) of Glyph_Vertex;
   pragma Convention (C, Glyph_Vertex_Array);

   type Shader_Stage_Array is
     array (Positive range <>) of Vk.Pipeline_Shader_Stage_Create_Info_T;
   pragma Convention (C, Shader_Stage_Array);
   type Vertex_Attr_Array is
     array (Positive range <>) of Vk.Vertex_Input_Attribute_Description_T;
   pragma Convention (C, Vertex_Attr_Array);
   type Dynamic_State_Array is array (Positive range <>) of Vk.Dynamic_State_T;
   pragma Convention (C, Dynamic_State_Array);
   type Buffer_Array is array (Positive range <>) of Vk.Buffer_T;
   pragma Convention (C, Buffer_Array);
   type Device_Size_Array is array (Positive range <>) of Interfaces.Unsigned_64;
   pragma Convention (C, Device_Size_Array);
   type Descriptor_Set_Layout_Array is
     array (Positive range <>) of Vk.Descriptor_Set_Layout_T;
   pragma Convention (C, Descriptor_Set_Layout_Array);
   type Descriptor_Set_Array is array (Positive range <>) of Vk.Descriptor_Set_T;
   pragma Convention (C, Descriptor_Set_Array);

   function Memcpy
     (Dest : System.Address;
      Src  : System.Address;
      Size : Interfaces.C.size_t) return System.Address
     with Import, Convention => C, External_Name => "memcpy";


   function Glfw_Get_Required_Instance_Extensions
     (Count : System.Address) return System.Address
     with Import, Convention => C,
     External_Name => "glfwGetRequiredInstanceExtensions";

   function Glfw_Create_Window_Surface
     (Instance  : Vk.Instance_T;
      Window    : System.Address;
      Allocator : System.Address;
      Surface   : System.Address) return Vk.Result_T
     with Import, Convention => C, External_Name => "glfwCreateWindowSurface";

   type Image_Array is array (Positive range <>) of Vk.Image_T;
   pragma Convention (C, Image_Array);
   type Image_Array_Access is access all Image_Array;

   type Image_View_Array is array (Positive range <>) of Vk.Image_View_T;
   pragma Convention (C, Image_View_Array);
   type Image_View_Array_Access is access all Image_View_Array;

   type Framebuffer_Array is array (Positive range <>) of Vk.Framebuffer_T;
   pragma Convention (C, Framebuffer_Array);
   type Framebuffer_Array_Access is access all Framebuffer_Array;

   type Command_Buffer_Array is array (Positive range <>) of Vk.Command_Buffer_T;
   pragma Convention (C, Command_Buffer_Array);
   type Command_Buffer_Array_Access is access all Command_Buffer_Array;

   type Physical_Device_Array is array (Positive range <>) of Vk.Physical_Device_T;
   pragma Convention (C, Physical_Device_Array);
   type Physical_Device_Array_Access is access all Physical_Device_Array;

   type Queue_Family_Array is array (Positive range <>) of Vk.Queue_Family_Properties_T;
   pragma Convention (C, Queue_Family_Array);
   type Queue_Family_Array_Access is access all Queue_Family_Array;

   type Surface_Format_Array is array (Positive range <>) of Vk.Surface_Format_KHR_T;
   pragma Convention (C, Surface_Format_Array);
   type Surface_Format_Array_Access is access all Surface_Format_Array;

   procedure Free_Images is new Ada.Unchecked_Deallocation
     (Image_Array, Image_Array_Access);
   procedure Free_Image_Views is new Ada.Unchecked_Deallocation
     (Image_View_Array, Image_View_Array_Access);
   procedure Free_Framebuffers is new Ada.Unchecked_Deallocation
     (Framebuffer_Array, Framebuffer_Array_Access);
   procedure Free_Command_Buffers is new Ada.Unchecked_Deallocation
     (Command_Buffer_Array, Command_Buffer_Array_Access);
   procedure Free_Physical_Devices is new Ada.Unchecked_Deallocation
     (Physical_Device_Array, Physical_Device_Array_Access);
   procedure Free_Queue_Families is new Ada.Unchecked_Deallocation
     (Queue_Family_Array, Queue_Family_Array_Access);
   procedure Free_Surface_Formats is new Ada.Unchecked_Deallocation
     (Surface_Format_Array, Surface_Format_Array_Access);

   type Backend_Record is record
      Window : System.Address := System.Null_Address;
      Instance : Vk.Instance_T := System.Null_Address;
      Surface : Vk.Surface_KHR_T := System.Null_Address;
      Physical_Device : Vk.Physical_Device_T := System.Null_Address;
      Device : Vk.Device_T := System.Null_Address;
      Graphics_Queue_Family : Interfaces.Unsigned_32 := UINT32_MAX;
      Graphics_Queue : Vk.Queue_T := System.Null_Address;
      Swapchain : Vk.Swapchain_KHR_T := System.Null_Address;
      Swapchain_Format : Vk.Format_T := 0;
      Swapchain_Extent : Vk.Extent2_D_T := (width => 0, height => 0);
      Image_Count : Interfaces.Unsigned_32 := 0;
      Images : Image_Array_Access := null;
      Image_Views : Image_View_Array_Access := null;
      Framebuffers : Framebuffer_Array_Access := null;
      Command_Pool : Vk.Command_Pool_T := System.Null_Address;
      Command_Buffers : Command_Buffer_Array_Access := null;
      Render_Pass : Vk.Render_Pass_T := System.Null_Address;
      Rect_Pipeline_Layout : Vk.Pipeline_Layout_T := System.Null_Address;
      Rect_Pipeline : Vk.Pipeline_T := System.Null_Address;
      Text_Descriptor_Set_Layout : Vk.Descriptor_Set_Layout_T :=
        System.Null_Address;
      Text_Descriptor_Pool : Vk.Descriptor_Pool_T := System.Null_Address;
      Text_Descriptor_Set : Vk.Descriptor_Set_T := System.Null_Address;
      Text_Pipeline_Layout : Vk.Pipeline_Layout_T := System.Null_Address;
      Text_Pipeline : Vk.Pipeline_T := System.Null_Address;
      Vertex_Buffer : Vk.Buffer_T := System.Null_Address;
      Vertex_Buffer_Memory : Vk.Device_Memory_T := System.Null_Address;
      Glyph_Vertex_Buffer : Vk.Buffer_T := System.Null_Address;
      Glyph_Vertex_Buffer_Memory : Vk.Device_Memory_T := System.Null_Address;
      Font_Atlas_Image : Vk.Image_T := System.Null_Address;
      Font_Atlas_Image_Memory : Vk.Device_Memory_T := System.Null_Address;
      Font_Atlas_Image_View : Vk.Image_View_T := System.Null_Address;
      Font_Atlas_Sampler : Vk.Sampler_T := System.Null_Address;
      Font_Atlas_Width_Value : C.int := 0;
      Font_Atlas_Height_Value : C.int := 0;
      Image_Available_Semaphore : Vk.Semaphore_T := System.Null_Address;
      Render_Finished_Semaphore : Vk.Semaphore_T := System.Null_Address;
      In_Flight_Fence : Vk.Fence_T := System.Null_Address;
      Current_Image_Index : Interfaces.Unsigned_32 := 0;
      Frame_Active : Boolean := False;
      Frame_Rendered : Boolean := False;
      Swapchain_Needs_Recreate : Boolean := True;
      Swapchain_Recreate_Count_Value : C.unsigned := 0;
      Font_Atlas_Upload_Count_Value : C.unsigned := 0;
      Font_Atlas_Last_Upload_Width_Value : C.unsigned := 0;
      Font_Atlas_Last_Upload_Height_Value : C.unsigned := 0;
      Font_Atlas_Last_Upload_Nonzero_Bytes_Value : C.unsigned := 0;
      Font_Atlas_Last_Upload_Checksum_Value : C.unsigned := 0;
      Last_Visual_Rect_Count_Value : C.unsigned := 0;
      Last_Visual_Glyph_Count_Value : C.unsigned := 0;
      Last_Visual_Geometry_Checksum_Value : C.unsigned := 0;
      Last_Visual_Color_Checksum_Value : C.unsigned := 0;
   end record;

   type Backend_Access is access all Backend_Record;

   function To_Address is new Ada.Unchecked_Conversion
     (Backend_Access, System.Address);
   function To_Backend is new Ada.Unchecked_Conversion
     (System.Address, Backend_Access);
   function Chars_Ptr_To_Address is new Ada.Unchecked_Conversion
     (C_Strings.chars_ptr, System.Address);

   procedure Free is new Ada.Unchecked_Deallocation
     (Backend_Record, Backend_Access);

   function To_C_Int (Value : Boolean) return C.int is
     (if Value then 1 else 0);

   procedure Put_Error (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
   end Put_Error;

   function Result_Name (Result : Vk.Result_T) return String is
   begin
      return Vk.Result_T'Image (Result);
   end Result_Name;

   function Failed
     (Where  : String;
      Result : Vk.Result_T) return Boolean
   is
   begin
      if Result = Vk.SUCCESS then
         return False;
      end if;

      Put_Error (Where & " -> " & Result_Name (Result));
      return True;
   end Failed;

   function Mix_U32
     (Checksum : Interfaces.Unsigned_32;
      Value    : Interfaces.Unsigned_32) return Interfaces.Unsigned_32
   is
   begin
      return (Checksum xor Value) * 16_777_619;
   end Mix_U32;

   function Mix_Float_1000
     (Checksum : Interfaces.Unsigned_32;
      Value    : C.C_float) return Interfaces.Unsigned_32
   is
      Scaled : constant Integer := Integer (Float (Value) * 1000.0);
   begin
      return Mix_U32 (Checksum, Interfaces.Unsigned_32 (Scaled));
   end Mix_Float_1000;

   procedure Capture_Visual_Contract
     (Backend : in out Backend_Record;
      Packet  : Editor.Render_Packet.Render_Packet)
   is
      Geometry : Interfaces.Unsigned_32 := 2_166_136_261;
      Color    : Interfaces.Unsigned_32 := 2_166_136_261;
   begin
      Backend.Last_Visual_Rect_Count_Value :=
        C.unsigned (Packet.Rect_Count);
      Backend.Last_Visual_Glyph_Count_Value :=
        C.unsigned (Packet.Glyph_Count);

      for I in 0 .. Integer (Packet.Rect_Count) - 1 loop
         declare
            R : constant Editor.Render_Packet.Rect_Command :=
              Packet.Rects (I);
         begin
            Geometry := Mix_U32
              (Geometry, Interfaces.Unsigned_32 (R.Layer));
            Geometry := Mix_Float_1000 (Geometry, R.X);
            Geometry := Mix_Float_1000 (Geometry, R.Y);
            Geometry := Mix_Float_1000 (Geometry, R.W);
            Geometry := Mix_Float_1000 (Geometry, R.H);
            Color := Mix_U32
              (Color, Interfaces.Unsigned_32 (R.Layer));
            Color := Mix_Float_1000 (Color, R.R);
            Color := Mix_Float_1000 (Color, R.G);
            Color := Mix_Float_1000 (Color, R.B);
         end;
      end loop;

      for I in 0 .. Integer (Packet.Glyph_Count) - 1 loop
         declare
            G : constant Editor.Render_Packet.Glyph_Command :=
              Packet.Glyphs (I);
         begin
            Geometry := Mix_U32
              (Geometry, Interfaces.Unsigned_32 (G.Layer));
            Geometry := Mix_Float_1000 (Geometry, G.X);
            Geometry := Mix_Float_1000 (Geometry, G.Y);
            Geometry := Mix_Float_1000 (Geometry, G.W);
            Geometry := Mix_Float_1000 (Geometry, G.H);
            Geometry := Mix_Float_1000 (Geometry, G.U0);
            Geometry := Mix_Float_1000 (Geometry, G.V0);
            Geometry := Mix_Float_1000 (Geometry, G.U1);
            Geometry := Mix_Float_1000 (Geometry, G.V1);
            Color := Mix_U32
              (Color, Interfaces.Unsigned_32 (G.Layer));
            Color := Mix_Float_1000 (Color, G.R);
            Color := Mix_Float_1000 (Color, G.G);
            Color := Mix_Float_1000 (Color, G.B);
         end;
      end loop;

      Backend.Last_Visual_Geometry_Checksum_Value :=
        C.unsigned (Geometry);
      Backend.Last_Visual_Color_Checksum_Value :=
        C.unsigned (Color);
   end Capture_Visual_Contract;

   procedure Capture_Font_Atlas_Upload
     (Backend : in out Backend_Record)
   is
      Width  : constant C.int := Editor.Font_Bridge.Atlas_Width;
      Height : constant C.int := Editor.Font_Bridge.Atlas_Height;
      Count  : constant Natural :=
        Natural'Max (0, Integer (Width) * Integer (Height));
      type Byte_Array is array (0 .. Count - 1) of C.unsigned_char;
      pragma Convention (C, Byte_Array);
      type Byte_Array_Access is access all Byte_Array;
      function To_Bytes is new Ada.Unchecked_Conversion
        (System.Address, Byte_Array_Access);
      Bytes : constant Byte_Array_Access :=
        To_Bytes (Editor.Font_Bridge.Atlas_Pixels);
      Nonzero : C.unsigned := 0;
      Checksum : Interfaces.Unsigned_32 := 2_166_136_261;
   begin
      if Count = 0 or else Bytes = null then
         Backend.Font_Atlas_Last_Upload_Width_Value := 0;
         Backend.Font_Atlas_Last_Upload_Height_Value := 0;
         Backend.Font_Atlas_Last_Upload_Nonzero_Bytes_Value := 0;
         Backend.Font_Atlas_Last_Upload_Checksum_Value := 0;
         return;
      end if;

      for B of Bytes.all loop
         if B /= 0 then
            Nonzero := Nonzero + 1;
         end if;
         Checksum := Mix_U32 (Checksum, Interfaces.Unsigned_32 (B));
      end loop;

      Backend.Font_Atlas_Last_Upload_Width_Value := C.unsigned (Width);
      Backend.Font_Atlas_Last_Upload_Height_Value := C.unsigned (Height);
      Backend.Font_Atlas_Last_Upload_Nonzero_Bytes_Value := Nonzero;
      Backend.Font_Atlas_Last_Upload_Checksum_Value :=
        C.unsigned (Checksum);
      Backend.Font_Atlas_Upload_Count_Value :=
        Backend.Font_Atlas_Upload_Count_Value + 1;
      Editor.Font_Bridge.Clear_Atlas_Dirty;
   end Capture_Font_Atlas_Upload;

   function Shader_Path
     (Dir  : String;
      Name : String) return String
   is
   begin
      if Dir'Length = 0 then
         return Name;
      elsif Dir (Dir'Last) = '/' then
         return Dir & Name;
      else
         return Dir & "/" & Name;
      end if;
   end Shader_Path;

   function File_Readable_And_Nonempty (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path)
        and then Ada.Directories.Size (Path) > 0;
   exception
      when others =>
         return False;
   end File_Readable_And_Nonempty;

   --  Where this program is.
   --
   --  This read /proc/self/exe with readlink -- which is Linux, not even POSIX, and it is
   --  why the editor would not link on Windows: undefined reference to readlink. Ada
   --  already knows the program's own name, and GNAT will make it absolute; both do it on
   --  every host, and no separator has to be assumed either.
   function Executable_Dir return String is
      Full_Path : constant String :=
        GNAT.OS_Lib.Normalize_Pathname (Ada.Command_Line.Command_Name);
   begin
      if Full_Path = "" then
         return "";
      end if;

      return Ada.Directories.Containing_Directory (Full_Path);
   exception
      when others =>
         return "";
   end Executable_Dir;

   function First_Readable_Shader_Path
     (Name               : String;
      Emit_Missing_Error : Boolean := False) return String
   is
      Env_Dir : constant String :=
        Ada.Environment_Variables.Value ("EDITOR_SHADER_DIR", "");
      Env_Only : constant String :=
        Ada.Environment_Variables.Value ("EDITOR_SHADER_DIR_ONLY", "");
      Shader_Dir_Only : constant Boolean :=
        Env_Only'Length > 0 and then Env_Only /= "0";
      Exe_Dir : constant String := Executable_Dir;
      Fallback_Exe_1 : constant String := Exe_Dir;
      Fallback_Exe_2 : constant String := Shader_Path (Exe_Dir, "shaders");
      Fallback_Exe_3 : constant String :=
        Shader_Path (Exe_Dir, "../share/editor/shaders");
      Fallback_Cwd_1 : constant String := "src/runtime/shaders";
      Fallback_Cwd_2 : constant String := "./shaders";
      Fallback_Cwd_3 : constant String := "../share/editor/shaders";
      Fallback_System_1 : constant String := "/usr/local/share/editor/shaders";
      Fallback_System_2 : constant String := "/usr/share/editor/shaders";
   begin
      if Env_Dir'Length > 0
        and then File_Readable_And_Nonempty (Shader_Path (Env_Dir, Name))
      then
         return Shader_Path (Env_Dir, Name);
      end if;

      if Shader_Dir_Only then
         if Emit_Missing_Error then
            Put_Error
              ("runtime asset error: shader '" & Name
               & "' not found in EDITOR_SHADER_DIR while "
               & "EDITOR_SHADER_DIR_ONLY is set; fallback shader lookup "
               & "disabled for packaging validation");
         end if;
         return "";
      end if;

      if Fallback_Exe_1'Length > 0
        and then File_Readable_And_Nonempty (Shader_Path (Fallback_Exe_1, Name))
      then
         return Shader_Path (Fallback_Exe_1, Name);
      elsif Fallback_Exe_2'Length > 0
        and then File_Readable_And_Nonempty (Shader_Path (Fallback_Exe_2, Name))
      then
         return Shader_Path (Fallback_Exe_2, Name);
      elsif Fallback_Exe_3'Length > 0
        and then File_Readable_And_Nonempty (Shader_Path (Fallback_Exe_3, Name))
      then
         return Shader_Path (Fallback_Exe_3, Name);
      elsif File_Readable_And_Nonempty (Shader_Path (Fallback_Cwd_1, Name)) then
         return Shader_Path (Fallback_Cwd_1, Name);
      elsif File_Readable_And_Nonempty (Shader_Path (Fallback_Cwd_2, Name)) then
         return Shader_Path (Fallback_Cwd_2, Name);
      elsif File_Readable_And_Nonempty (Shader_Path (Fallback_Cwd_3, Name)) then
         return Shader_Path (Fallback_Cwd_3, Name);
      elsif File_Readable_And_Nonempty
        (Shader_Path (Fallback_System_1, Name))
      then
         return Shader_Path (Fallback_System_1, Name);
      elsif File_Readable_And_Nonempty
        (Shader_Path (Fallback_System_2, Name))
      then
         return Shader_Path (Fallback_System_2, Name);
      else
         if Emit_Missing_Error then
            Put_Error
              ("runtime asset error: shader '" & Name
               & "' not found in EDITOR_SHADER_DIR, executable-relative "
               & "shader locations, source-tree shader locations, or system "
               & "shader locations");
         end if;
         return "";
      end if;
   end First_Readable_Shader_Path;

   function Find_Shader (Name : String) return Boolean is
   begin
      return First_Readable_Shader_Path
        (Name, Emit_Missing_Error => True)'Length > 0;
   end Find_Shader;

   function Resolve_Shader_Path (Name : String) return String is
   begin
      return First_Readable_Shader_Path
        (Name, Emit_Missing_Error => False);
   end Resolve_Shader_Path;

   function Find_Memory_Type
     (Backend     : Backend_Record;
      Type_Filter : Interfaces.Unsigned_32;
      Properties  : Vk.Memory_Property_Flags_T;
      Index       : out Interfaces.Unsigned_32) return Boolean
   is
      Mem : aliased Vk.Physical_Device_Memory_Properties_T;
   begin
      Vk.Get_Physical_Device_Memory_Properties
        (Backend.Physical_Device, Mem'Address);

      for I in 0 .. Integer (Mem.memory_Type_Count) - 1 loop
         if (Type_Filter and Interfaces.Shift_Left (1, I)) /= 0
           and then (Mem.memory_Types (I).property_Flags and Properties)
             = Properties
         then
            Index := Interfaces.Unsigned_32 (I);
            return True;
         end if;
      end loop;

      Put_Error ("find_memory_type: no suitable memory type");
      return False;
   end Find_Memory_Type;

   function Create_Buffer
     (Backend    : in out Backend_Record;
      Size       : Interfaces.Unsigned_64;
      Usage      : Vk.Buffer_Usage_Flags_T;
      Properties : Vk.Memory_Property_Flags_T;
      Buffer     : in out Vk.Buffer_T;
      Memory     : in out Vk.Device_Memory_T) return Boolean
   is
      Info : aliased Vk.Buffer_Create_Info_T :=
        (s_Type                   => Vk.STRUCTURE_TYPE_BUFFER_CREATE_INFO,
         p_Next                   => System.Null_Address,
         flags                    => 0,
         size                     => Size,
         usage                    => Usage,
         sharing_Mode             => Vk.SHARING_MODE_EXCLUSIVE,
         queue_Family_Index_Count => 0,
         p_Queue_Family_Indices   => System.Null_Address);
      Req : aliased Vk.Memory_Requirements_T;
      Memory_Type_Index : Interfaces.Unsigned_32 := 0;
      Res : Vk.Result_T;
   begin
      Res := Vk.Create_Buffer
        (Backend.Device, Info'Address, System.Null_Address, Buffer'Address);
      if Failed ("vkCreateBuffer", Res) then
         return False;
      end if;

      Vk.Get_Buffer_Memory_Requirements
        (Backend.Device, Buffer, Req'Address);

      if not Find_Memory_Type
        (Backend, Req.memory_Type_Bits, Properties, Memory_Type_Index)
      then
         return False;
      end if;

      declare
         Alloc : aliased Vk.Memory_Allocate_Info_T :=
           (s_Type            => Vk.STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            p_Next            => System.Null_Address,
            allocation_Size   => Req.size,
            memory_Type_Index => Memory_Type_Index);
      begin
         Res := Vk.Allocate_Memory
           (Backend.Device, Alloc'Address, System.Null_Address, Memory'Address);
         if Failed ("vkAllocateMemory(buffer)", Res) then
            return False;
         end if;
      end;

      Res := Vk.Bind_Buffer_Memory (Backend.Device, Buffer, Memory, 0);
      return not Failed ("vkBindBufferMemory", Res);
   end Create_Buffer;

   function Create_Image
     (Backend    : in out Backend_Record;
      Width      : Interfaces.Unsigned_32;
      Height     : Interfaces.Unsigned_32;
      Format     : Vk.Format_T;
      Usage      : Vk.Image_Usage_Flags_T;
      Properties : Vk.Memory_Property_Flags_T;
      Image      : in out Vk.Image_T;
      Memory     : in out Vk.Device_Memory_T) return Boolean
   is
      Info : aliased Vk.Image_Create_Info_T :=
        (s_Type                   => Vk.STRUCTURE_TYPE_IMAGE_CREATE_INFO,
         p_Next                   => System.Null_Address,
         flags                    => 0,
         image_Type               => Vk.IMAGE_TYPE_2D,
         format                   => Format,
         extent                   => (width => Width, height => Height, depth => 1),
         mip_Levels               => 1,
         array_Layers             => 1,
         samples                  => Vk.SAMPLE_COUNT_1_BIT,
         tiling                   => Vk.IMAGE_TILING_OPTIMAL,
         usage                    => Usage,
         sharing_Mode             => Vk.SHARING_MODE_EXCLUSIVE,
         queue_Family_Index_Count => 0,
         p_Queue_Family_Indices   => System.Null_Address,
         initial_Layout           => Vk.IMAGE_LAYOUT_UNDEFINED);
      Req : aliased Vk.Memory_Requirements_T;
      Memory_Type_Index : Interfaces.Unsigned_32 := 0;
      Res : Vk.Result_T;
   begin
      Res := Vk.Create_Image
        (Backend.Device, Info'Address, System.Null_Address, Image'Address);
      if Failed ("vkCreateImage(font atlas)", Res) then
         return False;
      end if;

      Vk.Get_Image_Memory_Requirements
        (Backend.Device, Image, Req'Address);

      if not Find_Memory_Type
        (Backend, Req.memory_Type_Bits, Properties, Memory_Type_Index)
      then
         return False;
      end if;

      declare
         Alloc : aliased Vk.Memory_Allocate_Info_T :=
           (s_Type            => Vk.STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            p_Next            => System.Null_Address,
            allocation_Size   => Req.size,
            memory_Type_Index => Memory_Type_Index);
      begin
         Res := Vk.Allocate_Memory
           (Backend.Device, Alloc'Address, System.Null_Address, Memory'Address);
         if Failed ("vkAllocateMemory(image)", Res) then
            return False;
         end if;
      end;

      Res := Vk.Bind_Image_Memory (Backend.Device, Image, Memory, 0);
      return not Failed ("vkBindImageMemory", Res);
   end Create_Image;

   function Begin_One_Time_Command
     (Backend : Backend_Record;
      Cmd     : in out Vk.Command_Buffer_T) return Boolean
   is
      Alloc : aliased Vk.Command_Buffer_Allocate_Info_T :=
        (s_Type               => Vk.STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
         p_Next               => System.Null_Address,
         command_Pool         => Backend.Command_Pool,
         level                => Vk.COMMAND_BUFFER_LEVEL_PRIMARY,
         command_Buffer_Count => 1);
      Begin_Info : aliased Vk.Command_Buffer_Begin_Info_T :=
        (s_Type             => Vk.STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
         p_Next             => System.Null_Address,
         flags              => Vk.COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
         p_Inheritance_Info => System.Null_Address);
      Res : Vk.Result_T;
   begin
      Res := Vk.Allocate_Command_Buffers
        (Backend.Device, Alloc'Address, Cmd'Address);
      if Failed ("vkAllocateCommandBuffers(one-time)", Res) then
         return False;
      end if;

      Res := Vk.Begin_Command_Buffer (Cmd, Begin_Info'Address);
      return not Failed ("vkBeginCommandBuffer(one-time)", Res);
   end Begin_One_Time_Command;

   function End_One_Time_Command
     (Backend : Backend_Record;
      Cmd     : aliased in out Vk.Command_Buffer_T) return Boolean
   is
      Submit : aliased Vk.Submit_Info_T :=
        (s_Type                => Vk.STRUCTURE_TYPE_SUBMIT_INFO,
         p_Next                => System.Null_Address,
         wait_Semaphore_Count  => 0,
         p_Wait_Semaphores     => System.Null_Address,
         p_Wait_Dst_Stage_Mask => System.Null_Address,
         command_Buffer_Count  => 1,
         p_Command_Buffers     => Cmd'Address,
         signal_Semaphore_Count => 0,
         p_Signal_Semaphores   => System.Null_Address);
      Res : Vk.Result_T;
   begin
      Res := Vk.End_Command_Buffer (Cmd);
      if Failed ("vkEndCommandBuffer(one-time)", Res) then
         return False;
      end if;

      Res := Vk.Queue_Submit
        (Backend.Graphics_Queue, 1, Submit'Address, System.Null_Address);
      if Failed ("vkQueueSubmit(one-time)", Res) then
         return False;
      end if;

      Res := Vk.Queue_Wait_Idle (Backend.Graphics_Queue);
      if Failed ("vkQueueWaitIdle(one-time)", Res) then
         return False;
      end if;

      Vk.Free_Command_Buffers
        (Backend.Device, Backend.Command_Pool, 1, Cmd'Address);
      return True;
   end End_One_Time_Command;

   procedure Transition_Image
     (Cmd        : Vk.Command_Buffer_T;
      Image      : Vk.Image_T;
      Old_Layout : Vk.Image_Layout_T;
      New_Layout : Vk.Image_Layout_T)
   is
      Src_Access : Vk.Access_Flags_T := 0;
      Dst_Access : Vk.Access_Flags_T := 0;
      Src_Stage  : Vk.Pipeline_Stage_Flags_T := Vk.PIPELINE_STAGE_TOP_OF_PIPE_BIT;
      Dst_Stage  : Vk.Pipeline_Stage_Flags_T := Vk.PIPELINE_STAGE_TRANSFER_BIT;
   begin
      if Old_Layout = Vk.IMAGE_LAYOUT_UNDEFINED
        and then New_Layout = Vk.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
      then
         Dst_Access := Vk.ACCESS_TRANSFER_WRITE_BIT;
      elsif Old_Layout = Vk.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
        and then New_Layout = Vk.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
      then
         Src_Access := Vk.ACCESS_TRANSFER_WRITE_BIT;
         Dst_Access := Vk.ACCESS_SHADER_READ_BIT;
         Src_Stage := Vk.PIPELINE_STAGE_TRANSFER_BIT;
         Dst_Stage := Vk.PIPELINE_STAGE_FRAGMENT_SHADER_BIT;
      end if;

      declare
         Barrier : aliased Vk.Image_Memory_Barrier_T :=
           (s_Type               => Vk.STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            p_Next               => System.Null_Address,
            src_Access_Mask      => Src_Access,
            dst_Access_Mask      => Dst_Access,
            old_Layout           => Old_Layout,
            new_Layout           => New_Layout,
            src_Queue_Family_Index => UINT32_MAX,
            dst_Queue_Family_Index => UINT32_MAX,
            image                => Image,
            subresource_Range    =>
              (aspect_Mask      => Vk.IMAGE_ASPECT_COLOR_BIT,
               base_Mip_Level   => 0,
               level_Count      => 1,
               base_Array_Layer => 0,
               layer_Count      => 1));
      begin
         Vk.Cmd_Pipeline_Barrier
           (Cmd, Src_Stage, Dst_Stage, 0, 0, System.Null_Address,
            0, System.Null_Address, 1, Barrier'Address);
      end;
   end Transition_Image;

   function Create_Text_Descriptors
     (Backend : in out Backend_Record) return Boolean
   is
      Binding : aliased Vk.Descriptor_Set_Layout_Binding_T :=
        (binding            => 0,
         descriptor_Type    => Vk.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
         descriptor_Count   => 1,
         stage_Flags        => Vk.SHADER_STAGE_FRAGMENT_BIT,
         p_Immutable_Samplers => System.Null_Address);
      Layout_Info : aliased Vk.Descriptor_Set_Layout_Create_Info_T :=
        (s_Type        => Vk.STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
         p_Next        => System.Null_Address,
         flags         => 0,
         binding_Count => 1,
         p_Bindings    => Binding'Address);
      Pool_Size : aliased Vk.Descriptor_Pool_Size_T :=
        (type_F => Vk.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
         descriptor_Count => 1);
      Pool_Info : aliased Vk.Descriptor_Pool_Create_Info_T :=
        (s_Type          => Vk.STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
         p_Next          => System.Null_Address,
         flags           => 0,
         max_Sets        => 1,
         pool_Size_Count => 1,
         p_Pool_Sizes    => Pool_Size'Address);
      Layouts : aliased Descriptor_Set_Layout_Array (1 .. 1);
      Alloc : aliased Vk.Descriptor_Set_Allocate_Info_T :=
        (s_Type               => Vk.STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
         p_Next               => System.Null_Address,
         descriptor_Pool      => System.Null_Address,
         descriptor_Set_Count => 1,
         p_Set_Layouts        => Layouts'Address);
      Sampler_Info : aliased Vk.Sampler_Create_Info_T :=
        (s_Type                   => Vk.STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
         p_Next                   => System.Null_Address,
         flags                    => 0,
         mag_Filter               => Vk.FILTER_LINEAR,
         min_Filter               => Vk.FILTER_LINEAR,
         mipmap_Mode              => Vk.SAMPLER_MIPMAP_MODE_NEAREST,
         address_Mode_U           => Vk.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
         address_Mode_V           => Vk.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
         address_Mode_W           => Vk.SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
         mip_Lod_Bias             => 0.0,
         anisotropy_Enable        => 0,
         max_Anisotropy           => 1.0,
         compare_Enable           => 0,
         compare_Op               => Vk.COMPARE_OP_ALWAYS,
         min_Lod                  => 0.0,
         max_Lod                  => 0.0,
         border_Color             => Vk.BORDER_COLOR_INT_OPAQUE_BLACK,
         unnormalized_Coordinates => 0);
      Res : Vk.Result_T;
   begin
      Res := Vk.Create_Descriptor_Set_Layout
        (Backend.Device,
         Layout_Info'Address,
         System.Null_Address,
         Backend.Text_Descriptor_Set_Layout'Address);
      if Failed ("vkCreateDescriptorSetLayout(text)", Res) then
         return False;
      end if;

      Res := Vk.Create_Descriptor_Pool
        (Backend.Device,
         Pool_Info'Address,
         System.Null_Address,
         Backend.Text_Descriptor_Pool'Address);
      if Failed ("vkCreateDescriptorPool(text)", Res) then
         return False;
      end if;

      Layouts (1) := Backend.Text_Descriptor_Set_Layout;
      Alloc.descriptor_Pool := Backend.Text_Descriptor_Pool;
      Res := Vk.Allocate_Descriptor_Sets
        (Backend.Device, Alloc'Address, Backend.Text_Descriptor_Set'Address);
      if Failed ("vkAllocateDescriptorSets(text)", Res) then
         return False;
      end if;

      Res := Vk.Create_Sampler
        (Backend.Device,
         Sampler_Info'Address,
         System.Null_Address,
         Backend.Font_Atlas_Sampler'Address);
      return not Failed ("vkCreateSampler(font atlas)", Res);
   end Create_Text_Descriptors;

   procedure Destroy_Font_Atlas_Image (Backend : in out Backend_Record) is
   begin
      if Backend.Font_Atlas_Image_View /= System.Null_Address then
         Vk.Destroy_Image_View
           (Backend.Device, Backend.Font_Atlas_Image_View, System.Null_Address);
         Backend.Font_Atlas_Image_View := System.Null_Address;
      end if;
      if Backend.Font_Atlas_Image /= System.Null_Address then
         Vk.Destroy_Image
           (Backend.Device, Backend.Font_Atlas_Image, System.Null_Address);
         Backend.Font_Atlas_Image := System.Null_Address;
      end if;
      if Backend.Font_Atlas_Image_Memory /= System.Null_Address then
         Vk.Free_Memory
           (Backend.Device, Backend.Font_Atlas_Image_Memory, System.Null_Address);
         Backend.Font_Atlas_Image_Memory := System.Null_Address;
      end if;
      Backend.Font_Atlas_Width_Value := 0;
      Backend.Font_Atlas_Height_Value := 0;
   end Destroy_Font_Atlas_Image;

   function Create_Font_Atlas_Image
     (Backend : in out Backend_Record;
      Width   : C.int;
      Height  : C.int) return Boolean
   is
      Image : Vk.Image_T := System.Null_Address;
      Memory : Vk.Device_Memory_T := System.Null_Address;
      View_Info : aliased Vk.Image_View_Create_Info_T :=
        (s_Type            => Vk.STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
         p_Next            => System.Null_Address,
         flags             => 0,
         image             => System.Null_Address,
         view_Type         => Vk.IMAGE_VIEW_TYPE_2D,
         format            => Vk.FORMAT_R8_UNORM,
         components        =>
           (r => Vk.COMPONENT_SWIZZLE_IDENTITY,
            g => Vk.COMPONENT_SWIZZLE_IDENTITY,
            b => Vk.COMPONENT_SWIZZLE_IDENTITY,
            a => Vk.COMPONENT_SWIZZLE_IDENTITY),
         subresource_Range =>
           (aspect_Mask      => Vk.IMAGE_ASPECT_COLOR_BIT,
            base_Mip_Level   => 0,
            level_Count      => 1,
            base_Array_Layer => 0,
            layer_Count      => 1));
      Res : Vk.Result_T;
   begin
      Destroy_Font_Atlas_Image (Backend);
      if not Create_Image
        (Backend,
         Interfaces.Unsigned_32 (Width),
         Interfaces.Unsigned_32 (Height),
         Vk.FORMAT_R8_UNORM,
         Vk.IMAGE_USAGE_TRANSFER_DST_BIT or Vk.IMAGE_USAGE_SAMPLED_BIT,
         Vk.MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
         Image,
         Memory)
      then
         return False;
      end if;

      Backend.Font_Atlas_Image := Image;
      Backend.Font_Atlas_Image_Memory := Memory;
      View_Info.image := Backend.Font_Atlas_Image;
      Res := Vk.Create_Image_View
        (Backend.Device,
         View_Info'Address,
         System.Null_Address,
         Backend.Font_Atlas_Image_View'Address);
      if Failed ("vkCreateImageView(font atlas)", Res) then
         return False;
      end if;

      Backend.Font_Atlas_Width_Value := Width;
      Backend.Font_Atlas_Height_Value := Height;
      return True;
   end Create_Font_Atlas_Image;

   procedure Update_Font_Atlas_Descriptor (Backend : in out Backend_Record) is
      Image_Info : aliased Vk.Descriptor_Image_Info_T :=
        (sampler      => Backend.Font_Atlas_Sampler,
         image_View   => Backend.Font_Atlas_Image_View,
         image_Layout => Vk.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
      Write : aliased Vk.Write_Descriptor_Set_T :=
        (s_Type                 => Vk.STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
         p_Next                 => System.Null_Address,
         dst_Set                => Backend.Text_Descriptor_Set,
         dst_Binding            => 0,
         dst_Array_Element      => 0,
         descriptor_Count       => 1,
         descriptor_Type        => Vk.DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
         p_Image_Info           => Image_Info'Address,
         p_Buffer_Info          => System.Null_Address,
         p_Texel_Buffer_View    => System.Null_Address);
   begin
      Vk.Update_Descriptor_Sets
        (Backend.Device, 1, Write'Address, 0, System.Null_Address);
   end Update_Font_Atlas_Descriptor;

   function Upload_Font_Atlas (Backend : in out Backend_Record) return Boolean is
      Width  : constant C.int := Editor.Font_Bridge.Atlas_Width;
      Height : constant C.int := Editor.Font_Bridge.Atlas_Height;
      Count  : constant Natural :=
        Natural'Max (0, Integer (Width) * Integer (Height));
      Size   : constant Interfaces.Unsigned_64 := Interfaces.Unsigned_64 (Count);
      Staging_Buffer : Vk.Buffer_T := System.Null_Address;
      Staging_Memory : Vk.Device_Memory_T := System.Null_Address;
      Mapped : aliased System.Address := System.Null_Address;
      Cmd : aliased Vk.Command_Buffer_T := System.Null_Address;
      Copy_Result : System.Address;
      pragma Unreferenced (Copy_Result);
      Res : Vk.Result_T;
   begin
      if Count = 0 or else Editor.Font_Bridge.Atlas_Pixels = System.Null_Address
      then
         return False;
      end if;

      if Backend.Font_Atlas_Image = System.Null_Address
        or else Backend.Font_Atlas_Width_Value /= Width
        or else Backend.Font_Atlas_Height_Value /= Height
      then
         if not Create_Font_Atlas_Image (Backend, Width, Height) then
            return False;
         end if;
      end if;

      if not Create_Buffer
        (Backend,
         Size,
         Vk.BUFFER_USAGE_TRANSFER_SRC_BIT,
         Vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT
           or Vk.MEMORY_PROPERTY_HOST_COHERENT_BIT,
         Staging_Buffer,
         Staging_Memory)
      then
         return False;
      end if;

      Res := Vk.Map_Memory
        (Backend.Device, Staging_Memory, 0, Size, 0, Mapped'Address);
      if Failed ("vkMapMemory(font atlas)", Res) then
         return False;
      end if;

      Copy_Result :=
        Memcpy
          (Mapped,
           Editor.Font_Bridge.Atlas_Pixels,
           Interfaces.C.size_t (Size));
      Vk.Unmap_Memory (Backend.Device, Staging_Memory);

      if not Begin_One_Time_Command (Backend, Cmd) then
         return False;
      end if;

      Transition_Image
        (Cmd,
         Backend.Font_Atlas_Image,
         Vk.IMAGE_LAYOUT_UNDEFINED,
         Vk.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);

      declare
         Region : aliased Vk.Buffer_Image_Copy_T :=
           (buffer_Offset       => 0,
            buffer_Row_Length   => 0,
            buffer_Image_Height => 0,
            image_Subresource   =>
              (aspect_Mask      => Vk.IMAGE_ASPECT_COLOR_BIT,
               mip_Level        => 0,
               base_Array_Layer => 0,
               layer_Count      => 1),
            image_Offset        => (x => 0, y => 0, z => 0),
            image_Extent        =>
              (width  => Interfaces.Unsigned_32 (Width),
               height => Interfaces.Unsigned_32 (Height),
               depth  => 1));
      begin
         Vk.Cmd_Copy_Buffer_To_Image
           (Cmd,
            Staging_Buffer,
            Backend.Font_Atlas_Image,
            Vk.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            1,
            Region'Address);
      end;

      Transition_Image
        (Cmd,
         Backend.Font_Atlas_Image,
         Vk.IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
         Vk.IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

      if not End_One_Time_Command (Backend, Cmd) then
         return False;
      end if;

      Update_Font_Atlas_Descriptor (Backend);
      Vk.Destroy_Buffer (Backend.Device, Staging_Buffer, System.Null_Address);
      Vk.Free_Memory (Backend.Device, Staging_Memory, System.Null_Address);
      return True;
   end Upload_Font_Atlas;

   function Create_Shader_Module
     (Backend : Backend_Record;
      Name    : String;
      Module  : in out Vk.Shader_Module_T) return Boolean
   is
      Path : constant String := Resolve_Shader_Path (Name);
   begin
      if Path'Length = 0 then
         Put_Error ("runtime asset error: shader '" & Name & "' not found");
         return False;
      end if;

      declare
         package SIO renames Ada.Streams.Stream_IO;
         File : SIO.File_Type;
         Size : constant Natural := Natural (Ada.Directories.Size (Path));
         Data : aliased Ada.Streams.Stream_Element_Array
           (1 .. Ada.Streams.Stream_Element_Offset (Size));
         Last : Ada.Streams.Stream_Element_Offset;
         Info : aliased Vk.Shader_Module_Create_Info_T :=
           (s_Type    => Vk.STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
            p_Next    => System.Null_Address,
            flags     => 0,
            code_Size => Interfaces.C.size_t (Size),
            p_Code    => Data'Address);
         Res : Vk.Result_T;
      begin
         SIO.Open (File, SIO.In_File, Path);
         SIO.Read (File, Data, Last);
         SIO.Close (File);
         if Natural (Last) /= Size then
            Put_Error ("Failed to read full shader file: " & Path);
            return False;
         end if;

         Res := Vk.Create_Shader_Module
           (Backend.Device,
            Info'Address,
            System.Null_Address,
            Module'Address);
         return not Failed ("vkCreateShaderModule(" & Path & ")", Res);
      end;
   exception
      when others =>
         Put_Error ("Failed to open file: " & Path);
         return False;
   end Create_Shader_Module;

   function Create_Rect_Pipeline
     (Backend : in out Backend_Record) return Boolean
   is
      Vert : Vk.Shader_Module_T := System.Null_Address;
      Frag : Vk.Shader_Module_T := System.Null_Address;
      Main_Name : C_Strings.chars_ptr := C_Strings.New_String ("main");
      Push_Range : aliased Vk.Push_Constant_Range_T :=
        (stage_Flags => Vk.SHADER_STAGE_VERTEX_BIT,
         offset      => 0,
         size        => Interfaces.Unsigned_32 (Push_Constants'Size / 8));
      Layout_Info : aliased Vk.Pipeline_Layout_Create_Info_T :=
        (s_Type                    => Vk.STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
         p_Next                    => System.Null_Address,
         flags                     => 0,
         set_Layout_Count          => 0,
         p_Set_Layouts             => System.Null_Address,
         push_Constant_Range_Count => 1,
         p_Push_Constant_Ranges    => Push_Range'Address);
      Binding : aliased Vk.Vertex_Input_Binding_Description_T :=
        (binding    => 0,
         stride     => Interfaces.Unsigned_32 (Rect_Vertex_Size),
         input_Rate => Vk.VERTEX_INPUT_RATE_VERTEX);
      Attrs : aliased Vertex_Attr_Array (1 .. 2) :=
        (1 => (location => 0,
               binding  => 0,
               format   => Vk.FORMAT_R32G32_SFLOAT,
               offset   => 0),
         2 => (location => 1,
               binding  => 0,
               format   => Vk.FORMAT_R32G32B32_SFLOAT,
               offset   => 8));
      Vertex_Input : aliased Vk.Pipeline_Vertex_Input_State_Create_Info_T :=
        (s_Type                             =>
           Vk.STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
         p_Next                             => System.Null_Address,
         flags                              => 0,
         vertex_Binding_Description_Count   => 1,
         p_Vertex_Binding_Descriptions      => Binding'Address,
         vertex_Attribute_Description_Count => 2,
         p_Vertex_Attribute_Descriptions    => Attrs'Address);
      IA : aliased Vk.Pipeline_Input_Assembly_State_Create_Info_T :=
        (s_Type                   =>
           Vk.STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
         p_Next                   => System.Null_Address,
         flags                    => 0,
         topology                 => Vk.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
         primitive_Restart_Enable => 0);
      Viewport_State : aliased Vk.Pipeline_Viewport_State_Create_Info_T :=
        (s_Type         => Vk.STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
         p_Next         => System.Null_Address,
         flags          => 0,
         viewport_Count => 1,
         p_Viewports    => System.Null_Address,
         scissor_Count  => 1,
         p_Scissors     => System.Null_Address);
      Raster : aliased Vk.Pipeline_Rasterization_State_Create_Info_T :=
        (s_Type                     =>
           Vk.STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
         p_Next                     => System.Null_Address,
         flags                      => 0,
         depth_Clamp_Enable         => 0,
         rasterizer_Discard_Enable  => 0,
         polygon_Mode               => Vk.POLYGON_MODE_FILL,
         cull_Mode                  => Vk.CULL_MODE_NONE,
         front_Face                 => Vk.FRONT_FACE_CLOCKWISE,
         depth_Bias_Enable          => 0,
         depth_Bias_Constant_Factor => 0.0,
         depth_Bias_Clamp           => 0.0,
         depth_Bias_Slope_Factor    => 0.0,
         line_Width                 => 1.0);
      MSAA : aliased Vk.Pipeline_Multisample_State_Create_Info_T :=
        (s_Type                  =>
           Vk.STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
         p_Next                  => System.Null_Address,
         flags                   => 0,
         rasterization_Samples   => Vk.SAMPLE_COUNT_1_BIT,
         sample_Shading_Enable   => 0,
         min_Sample_Shading      => 0.0,
         p_Sample_Mask           => System.Null_Address,
         alpha_To_Coverage_Enable => 0,
         alpha_To_One_Enable     => 0);
      Blend_Attachment : aliased Vk.Pipeline_Color_Blend_Attachment_State_T :=
        (blend_Enable           => 0,
         src_Color_Blend_Factor => Vk.BLEND_FACTOR_ONE,
         dst_Color_Blend_Factor => Vk.BLEND_FACTOR_ZERO,
         color_Blend_Op         => Vk.BLEND_OP_ADD,
         src_Alpha_Blend_Factor => Vk.BLEND_FACTOR_ONE,
         dst_Alpha_Blend_Factor => Vk.BLEND_FACTOR_ZERO,
         alpha_Blend_Op         => Vk.BLEND_OP_ADD,
         color_Write_Mask       =>
           Vk.COLOR_COMPONENT_R_BIT or Vk.COLOR_COMPONENT_G_BIT
           or Vk.COLOR_COMPONENT_B_BIT or Vk.COLOR_COMPONENT_A_BIT);
      Blend : aliased Vk.Pipeline_Color_Blend_State_Create_Info_T :=
        (s_Type            =>
           Vk.STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
         p_Next            => System.Null_Address,
         flags             => 0,
         logic_Op_Enable   => 0,
         logic_Op          => Vk.LOGIC_OP_CLEAR,
         attachment_Count  => 1,
         p_Attachments     => Blend_Attachment'Address,
         blend_Constants   => (0.0, 0.0, 0.0, 0.0));
      Dyn_States : aliased Dynamic_State_Array (1 .. 2) :=
        (1 => Vk.DYNAMIC_STATE_VIEWPORT, 2 => Vk.DYNAMIC_STATE_SCISSOR);
      Dynamic : aliased Vk.Pipeline_Dynamic_State_Create_Info_T :=
        (s_Type              => Vk.STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
         p_Next              => System.Null_Address,
         flags               => 0,
         dynamic_State_Count => 2,
         p_Dynamic_States    => Dyn_States'Address);
      Res : Vk.Result_T;
   begin
      if Backend.Rect_Pipeline /= System.Null_Address then
         C_Strings.Free (Main_Name);
         return True;
      end if;

      if not Create_Shader_Module (Backend, "rect.vert.spv", Vert)
        or else not Create_Shader_Module (Backend, "rect.frag.spv", Frag)
      then
         C_Strings.Free (Main_Name);
         return False;
      end if;

      Res := Vk.Create_Pipeline_Layout
        (Backend.Device,
         Layout_Info'Address,
         System.Null_Address,
         Backend.Rect_Pipeline_Layout'Address);
      if Failed ("vkCreatePipelineLayout(rect)", Res) then
         C_Strings.Free (Main_Name);
         return False;
      end if;

      declare
         Stages : aliased Shader_Stage_Array (1 .. 2) :=
           (1 => (s_Type => Vk.STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                  p_Next => System.Null_Address,
                  flags => 0,
                  stage => Vk.SHADER_STAGE_VERTEX_BIT,
                  module => Vert,
                  p_Name => Chars_Ptr_To_Address (Main_Name),
                  p_Specialization_Info => System.Null_Address),
            2 => (s_Type => Vk.STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                  p_Next => System.Null_Address,
                  flags => 0,
                  stage => Vk.SHADER_STAGE_FRAGMENT_BIT,
                  module => Frag,
                  p_Name => Chars_Ptr_To_Address (Main_Name),
                  p_Specialization_Info => System.Null_Address));
         Pipeline_Info : aliased Vk.Graphics_Pipeline_Create_Info_T :=
           (s_Type                 => Vk.STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            p_Next                 => System.Null_Address,
            flags                  => 0,
            stage_Count            => 2,
            p_Stages               => Stages'Address,
            p_Vertex_Input_State   => Vertex_Input'Address,
            p_Input_Assembly_State => IA'Address,
            p_Tessellation_State   => System.Null_Address,
            p_Viewport_State       => Viewport_State'Address,
            p_Rasterization_State  => Raster'Address,
            p_Multisample_State    => MSAA'Address,
            p_Depth_Stencil_State  => System.Null_Address,
            p_Color_Blend_State    => Blend'Address,
            p_Dynamic_State        => Dynamic'Address,
            layout                 => Backend.Rect_Pipeline_Layout,
            render_Pass            => Backend.Render_Pass,
            subpass                => 0,
            base_Pipeline_Handle   => System.Null_Address,
            base_Pipeline_Index    => -1);
      begin
      Res := Vk.Create_Graphics_Pipelines
        (Backend.Device,
         System.Null_Address,
         1,
         Pipeline_Info'Address,
            System.Null_Address,
            Backend.Rect_Pipeline'Address);
      end;

      Vk.Destroy_Shader_Module (Backend.Device, Vert, System.Null_Address);
      Vk.Destroy_Shader_Module (Backend.Device, Frag, System.Null_Address);
      C_Strings.Free (Main_Name);
      return not Failed ("vkCreateGraphicsPipelines(rect)", Res);
   end Create_Rect_Pipeline;

   function Create_Text_Pipeline
     (Backend : in out Backend_Record) return Boolean
   is
      Vert : Vk.Shader_Module_T := System.Null_Address;
      Frag : Vk.Shader_Module_T := System.Null_Address;
      Main_Name : C_Strings.chars_ptr := C_Strings.New_String ("main");
      Set_Layouts : aliased Descriptor_Set_Layout_Array (1 .. 1) :=
        (1 => Backend.Text_Descriptor_Set_Layout);
      Push_Range : aliased Vk.Push_Constant_Range_T :=
        (stage_Flags => Vk.SHADER_STAGE_VERTEX_BIT,
         offset      => 0,
         size        => Interfaces.Unsigned_32 (Push_Constants'Size / 8));
      Layout_Info : aliased Vk.Pipeline_Layout_Create_Info_T :=
        (s_Type                    => Vk.STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
         p_Next                    => System.Null_Address,
         flags                     => 0,
         set_Layout_Count          => 1,
         p_Set_Layouts             => Set_Layouts'Address,
         push_Constant_Range_Count => 1,
         p_Push_Constant_Ranges    => Push_Range'Address);
      Binding : aliased Vk.Vertex_Input_Binding_Description_T :=
        (binding    => 0,
         stride     => Interfaces.Unsigned_32 (Glyph_Vertex_Size),
         input_Rate => Vk.VERTEX_INPUT_RATE_VERTEX);
      Attrs : aliased Vertex_Attr_Array (1 .. 3) :=
        (1 => (location => 0,
               binding  => 0,
               format   => Vk.FORMAT_R32G32_SFLOAT,
               offset   => 0),
         2 => (location => 1,
               binding  => 0,
               format   => Vk.FORMAT_R32G32_SFLOAT,
               offset   => 8),
         3 => (location => 2,
               binding  => 0,
               format   => Vk.FORMAT_R32G32B32_SFLOAT,
               offset   => 16));
      Vertex_Input : aliased Vk.Pipeline_Vertex_Input_State_Create_Info_T :=
        (s_Type                             =>
           Vk.STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
         p_Next                             => System.Null_Address,
         flags                              => 0,
         vertex_Binding_Description_Count   => 1,
         p_Vertex_Binding_Descriptions      => Binding'Address,
         vertex_Attribute_Description_Count => 3,
         p_Vertex_Attribute_Descriptions    => Attrs'Address);
      IA : aliased Vk.Pipeline_Input_Assembly_State_Create_Info_T :=
        (s_Type                   =>
           Vk.STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
         p_Next                   => System.Null_Address,
         flags                    => 0,
         topology                 => Vk.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
         primitive_Restart_Enable => 0);
      Viewport_State : aliased Vk.Pipeline_Viewport_State_Create_Info_T :=
        (s_Type         => Vk.STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
         p_Next         => System.Null_Address,
         flags          => 0,
         viewport_Count => 1,
         p_Viewports    => System.Null_Address,
         scissor_Count  => 1,
         p_Scissors     => System.Null_Address);
      Raster : aliased Vk.Pipeline_Rasterization_State_Create_Info_T :=
        (s_Type                     =>
           Vk.STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
         p_Next                     => System.Null_Address,
         flags                      => 0,
         depth_Clamp_Enable         => 0,
         rasterizer_Discard_Enable  => 0,
         polygon_Mode               => Vk.POLYGON_MODE_FILL,
         cull_Mode                  => Vk.CULL_MODE_NONE,
         front_Face                 => Vk.FRONT_FACE_CLOCKWISE,
         depth_Bias_Enable          => 0,
         depth_Bias_Constant_Factor => 0.0,
         depth_Bias_Clamp           => 0.0,
         depth_Bias_Slope_Factor    => 0.0,
         line_Width                 => 1.0);
      MSAA : aliased Vk.Pipeline_Multisample_State_Create_Info_T :=
        (s_Type                  =>
           Vk.STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
         p_Next                  => System.Null_Address,
         flags                   => 0,
         rasterization_Samples   => Vk.SAMPLE_COUNT_1_BIT,
         sample_Shading_Enable   => 0,
         min_Sample_Shading      => 0.0,
         p_Sample_Mask           => System.Null_Address,
         alpha_To_Coverage_Enable => 0,
         alpha_To_One_Enable     => 0);
      Blend_Attachment : aliased Vk.Pipeline_Color_Blend_Attachment_State_T :=
        (blend_Enable           => 1,
         src_Color_Blend_Factor => Vk.BLEND_FACTOR_SRC_ALPHA,
         dst_Color_Blend_Factor => Vk.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
         color_Blend_Op         => Vk.BLEND_OP_ADD,
         src_Alpha_Blend_Factor => Vk.BLEND_FACTOR_ONE,
         dst_Alpha_Blend_Factor => Vk.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
         alpha_Blend_Op         => Vk.BLEND_OP_ADD,
         color_Write_Mask       =>
           Vk.COLOR_COMPONENT_R_BIT or Vk.COLOR_COMPONENT_G_BIT
           or Vk.COLOR_COMPONENT_B_BIT or Vk.COLOR_COMPONENT_A_BIT);
      Blend : aliased Vk.Pipeline_Color_Blend_State_Create_Info_T :=
        (s_Type            =>
           Vk.STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
         p_Next            => System.Null_Address,
         flags             => 0,
         logic_Op_Enable   => 0,
         logic_Op          => Vk.LOGIC_OP_CLEAR,
         attachment_Count  => 1,
         p_Attachments     => Blend_Attachment'Address,
         blend_Constants   => (0.0, 0.0, 0.0, 0.0));
      Dyn_States : aliased Dynamic_State_Array (1 .. 2) :=
        (1 => Vk.DYNAMIC_STATE_VIEWPORT, 2 => Vk.DYNAMIC_STATE_SCISSOR);
      Dynamic : aliased Vk.Pipeline_Dynamic_State_Create_Info_T :=
        (s_Type              => Vk.STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
         p_Next              => System.Null_Address,
         flags               => 0,
         dynamic_State_Count => 2,
         p_Dynamic_States    => Dyn_States'Address);
      Res : Vk.Result_T;
   begin
      if Backend.Text_Pipeline /= System.Null_Address then
         C_Strings.Free (Main_Name);
         return True;
      end if;

      if not Create_Shader_Module (Backend, "text.vert.spv", Vert)
        or else not Create_Shader_Module (Backend, "text.frag.spv", Frag)
      then
         C_Strings.Free (Main_Name);
         return False;
      end if;

      Res := Vk.Create_Pipeline_Layout
        (Backend.Device,
         Layout_Info'Address,
         System.Null_Address,
         Backend.Text_Pipeline_Layout'Address);
      if Failed ("vkCreatePipelineLayout(text)", Res) then
         C_Strings.Free (Main_Name);
         return False;
      end if;

      declare
         Stages : aliased Shader_Stage_Array (1 .. 2) :=
           (1 => (s_Type => Vk.STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                  p_Next => System.Null_Address,
                  flags => 0,
                  stage => Vk.SHADER_STAGE_VERTEX_BIT,
                  module => Vert,
                  p_Name => Chars_Ptr_To_Address (Main_Name),
                  p_Specialization_Info => System.Null_Address),
            2 => (s_Type => Vk.STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                  p_Next => System.Null_Address,
                  flags => 0,
                  stage => Vk.SHADER_STAGE_FRAGMENT_BIT,
                  module => Frag,
                  p_Name => Chars_Ptr_To_Address (Main_Name),
                  p_Specialization_Info => System.Null_Address));
         Pipeline_Info : aliased Vk.Graphics_Pipeline_Create_Info_T :=
           (s_Type                 => Vk.STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            p_Next                 => System.Null_Address,
            flags                  => 0,
            stage_Count            => 2,
            p_Stages               => Stages'Address,
            p_Vertex_Input_State   => Vertex_Input'Address,
            p_Input_Assembly_State => IA'Address,
            p_Tessellation_State   => System.Null_Address,
            p_Viewport_State       => Viewport_State'Address,
            p_Rasterization_State  => Raster'Address,
            p_Multisample_State    => MSAA'Address,
            p_Depth_Stencil_State  => System.Null_Address,
            p_Color_Blend_State    => Blend'Address,
            p_Dynamic_State        => Dynamic'Address,
            layout                 => Backend.Text_Pipeline_Layout,
            render_Pass            => Backend.Render_Pass,
            subpass                => 0,
            base_Pipeline_Handle   => System.Null_Address,
            base_Pipeline_Index    => -1);
      begin
         Res := Vk.Create_Graphics_Pipelines
           (Backend.Device,
            System.Null_Address,
            1,
            Pipeline_Info'Address,
            System.Null_Address,
            Backend.Text_Pipeline'Address);
      end;

      Vk.Destroy_Shader_Module (Backend.Device, Vert, System.Null_Address);
      Vk.Destroy_Shader_Module (Backend.Device, Frag, System.Null_Address);
      C_Strings.Free (Main_Name);
      return not Failed ("vkCreateGraphicsPipelines(text)", Res);
   end Create_Text_Pipeline;

   procedure Destroy_Swapchain_Frame_Resources
     (Backend : in out Backend_Record)
   is
   begin
      if Backend.Device = System.Null_Address then
         return;
      end if;

      if Backend.Command_Pool /= System.Null_Address
        and then Backend.Command_Buffers /= null
        and then Backend.Image_Count > 0
      then
         Vk.Free_Command_Buffers
           (Backend.Device,
            Backend.Command_Pool,
            Backend.Image_Count,
            Backend.Command_Buffers (1)'Address);
      end if;
      Free_Command_Buffers (Backend.Command_Buffers);

      if Backend.Framebuffers /= null then
         for F of Backend.Framebuffers.all loop
            if F /= System.Null_Address then
               Vk.Destroy_Framebuffer
                 (Backend.Device, F, System.Null_Address);
            end if;
         end loop;
      end if;
      Free_Framebuffers (Backend.Framebuffers);

      if Backend.Image_Views /= null then
         for V of Backend.Image_Views.all loop
            if V /= System.Null_Address then
               Vk.Destroy_Image_View
                 (Backend.Device, V, System.Null_Address);
            end if;
         end loop;
      end if;
      Free_Image_Views (Backend.Image_Views);
      Free_Images (Backend.Images);
      Backend.Image_Count := 0;
   end Destroy_Swapchain_Frame_Resources;

   function Create_Instance_And_Surface
     (Backend : in out Backend_Record) return Boolean
   is
      Extension_Count : aliased Interfaces.Unsigned_32 := 0;
      Extensions : constant System.Address :=
        Glfw_Get_Required_Instance_Extensions (Extension_Count'Address);
      App_Info : aliased Vk.Application_Info_T :=
        (s_Type              => Vk.STRUCTURE_TYPE_APPLICATION_INFO,
         p_Next              => System.Null_Address,
         p_Application_Name  => System.Null_Address,
         application_Version => 0,
         p_Engine_Name       => System.Null_Address,
         engine_Version      => 0,
         api_Version         => 0);
      Info : aliased Vk.Instance_Create_Info_T :=
        (s_Type                     => Vk.STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
         p_Next                     => System.Null_Address,
         flags                      => 0,
         p_Application_Info         => App_Info'Address,
         enabled_Layer_Count        => 0,
         pp_Enabled_Layer_Names     => System.Null_Address,
         enabled_Extension_Count    => Extension_Count,
         pp_Enabled_Extension_Names => Extensions);
      Res : Vk.Result_T;
   begin
      if Extensions = System.Null_Address or else Extension_Count = 0 then
         Put_Error ("glfwGetRequiredInstanceExtensions returned no extensions");
         return False;
      end if;

      Res := Vk.Create_Instance
        (Info'Address, System.Null_Address, Backend.Instance'Address);
      if Failed ("vkCreateInstance", Res) then
         return False;
      end if;

      Res := Glfw_Create_Window_Surface
        (Backend.Instance,
         Backend.Window,
         System.Null_Address,
         Backend.Surface'Address);
      if Failed ("glfwCreateWindowSurface", Res) then
         return False;
      end if;

      return True;
   end Create_Instance_And_Surface;

   function Pick_Physical_Device
     (Backend : in out Backend_Record) return Boolean
   is
      Count : aliased Interfaces.Unsigned_32 := 0;
      Res : Vk.Result_T;
      Devices : Physical_Device_Array_Access;
   begin
      Res := Vk.Enumerate_Physical_Devices
        (Backend.Instance, Count'Address, System.Null_Address);
      if Failed ("vkEnumeratePhysicalDevices(count)", Res) then
         return False;
      end if;

      if Count = 0 then
         Put_Error ("No Vulkan physical devices found");
         return False;
      end if;

      Devices := new Physical_Device_Array (1 .. Positive (Count));
      Res := Vk.Enumerate_Physical_Devices
        (Backend.Instance, Count'Address, Devices (1)'Address);
      if Failed ("vkEnumeratePhysicalDevices(devices)", Res) then
         Free_Physical_Devices (Devices);
         return False;
      end if;

      Backend.Physical_Device := Devices (1);
      Free_Physical_Devices (Devices);
      return True;
   end Pick_Physical_Device;

   function Pick_Queue_Family
     (Backend : in out Backend_Record) return Boolean
   is
      Count : aliased Interfaces.Unsigned_32 := 0;
      Families : Queue_Family_Array_Access;
      Present_Supported : aliased Interfaces.Unsigned_32 := 0;
      Res : Vk.Result_T;
   begin
      Vk.Get_Physical_Device_Queue_Family_Properties
        (Backend.Physical_Device, Count'Address, System.Null_Address);

      if Count = 0 then
         Put_Error ("No Vulkan queue families found");
         return False;
      end if;

      Families := new Queue_Family_Array (1 .. Positive (Count));
      Vk.Get_Physical_Device_Queue_Family_Properties
        (Backend.Physical_Device, Count'Address, Families (1)'Address);

      Backend.Graphics_Queue_Family := UINT32_MAX;
      for I in Families'Range loop
         Present_Supported := 0;
         Res := Vk.Get_Physical_Device_Surface_Support_KHR
           (Backend.Physical_Device,
            Interfaces.Unsigned_32 (I - 1),
            Backend.Surface,
            Present_Supported'Address);

         if Res = Vk.SUCCESS
           and then Present_Supported /= 0
           and then (Families (I).queue_Flags and Vk.QUEUE_GRAPHICS_BIT) /= 0
         then
            Backend.Graphics_Queue_Family := Interfaces.Unsigned_32 (I - 1);
            exit;
         end if;
      end loop;

      Free_Queue_Families (Families);

      if Backend.Graphics_Queue_Family = UINT32_MAX then
         Put_Error ("No suitable graphics/present queue family");
         return False;
      end if;

      return True;
   end Pick_Queue_Family;

   function Create_Device_And_Queue
     (Backend : in out Backend_Record) return Boolean
   is
      Queue_Priority : aliased C.C_float := 1.0;
      Queue_Info : aliased Vk.Device_Queue_Create_Info_T :=
        (s_Type                 => Vk.STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
         p_Next                 => System.Null_Address,
         flags                  => 0,
         queue_Family_Index     => Backend.Graphics_Queue_Family,
         queue_Count            => 1,
         p_Queue_Priorities     => Queue_Priority'Address);
      Swapchain_Extension : C_Strings.chars_ptr :=
        C_Strings.New_String ("VK_KHR_swapchain");
      type Chars_Ptr_Array is array (Positive range <>) of C_Strings.chars_ptr;
      pragma Convention (C, Chars_Ptr_Array);
      Device_Extensions : aliased Chars_Ptr_Array (1 .. 1) :=
        (1 => Swapchain_Extension);
      Device_Info : aliased Vk.Device_Create_Info_T :=
        (s_Type                     => Vk.STRUCTURE_TYPE_DEVICE_CREATE_INFO,
         p_Next                     => System.Null_Address,
         flags                      => 0,
         queue_Create_Info_Count    => 1,
         p_Queue_Create_Infos       => Queue_Info'Address,
         enabled_Layer_Count        => 0,
         pp_Enabled_Layer_Names     => System.Null_Address,
         enabled_Extension_Count    => 1,
         pp_Enabled_Extension_Names => Device_Extensions'Address,
         p_Enabled_Features         => System.Null_Address);
      Res : Vk.Result_T;
   begin
      Res := Vk.Create_Device
        (Backend.Physical_Device,
         Device_Info'Address,
         System.Null_Address,
         Backend.Device'Address);
      C_Strings.Free (Swapchain_Extension);

      if Failed ("vkCreateDevice", Res) then
         return False;
      end if;

      Vk.Get_Device_Queue
        (Backend.Device,
         Backend.Graphics_Queue_Family,
         0,
         Backend.Graphics_Queue'Address);
      return Backend.Graphics_Queue /= System.Null_Address;
   end Create_Device_And_Queue;

   function Query_Surface_Format
     (Backend : in out Backend_Record) return Boolean
   is
      Count : aliased Interfaces.Unsigned_32 := 0;
      Formats : Surface_Format_Array_Access;
      Res : Vk.Result_T;
   begin
      Res := Vk.Get_Physical_Device_Surface_Formats_KHR
        (Backend.Physical_Device,
         Backend.Surface,
         Count'Address,
         System.Null_Address);
      if Failed ("vkGetPhysicalDeviceSurfaceFormatsKHR(count)", Res) then
         return False;
      end if;

      if Count = 0 then
         Put_Error ("No Vulkan surface formats found");
         return False;
      end if;

      Formats := new Surface_Format_Array (1 .. Positive (Count));
      Res := Vk.Get_Physical_Device_Surface_Formats_KHR
        (Backend.Physical_Device,
         Backend.Surface,
         Count'Address,
         Formats (1)'Address);
      if Failed ("vkGetPhysicalDeviceSurfaceFormatsKHR(formats)", Res) then
         Free_Surface_Formats (Formats);
         return False;
      end if;

      Backend.Swapchain_Format := Formats (1).format;
      Free_Surface_Formats (Formats);
      return True;
   end Query_Surface_Format;

   function Create_Command_And_Sync_Objects
     (Backend : in out Backend_Record) return Boolean
   is
      Pool_Info : aliased Vk.Command_Pool_Create_Info_T :=
        (s_Type             => Vk.STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
         p_Next             => System.Null_Address,
         flags              => Vk.COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
         queue_Family_Index => Backend.Graphics_Queue_Family);
      Semaphore_Info : aliased Vk.Semaphore_Create_Info_T :=
        (s_Type => Vk.STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
         p_Next => System.Null_Address,
         flags  => 0);
      Fence_Info : aliased Vk.Fence_Create_Info_T :=
        (s_Type => Vk.STRUCTURE_TYPE_FENCE_CREATE_INFO,
         p_Next => System.Null_Address,
         flags  => Vk.FENCE_CREATE_SIGNALED_BIT);
      Res : Vk.Result_T;
   begin
      Res := Vk.Create_Command_Pool
        (Backend.Device,
         Pool_Info'Address,
         System.Null_Address,
         Backend.Command_Pool'Address);
      if Failed ("vkCreateCommandPool", Res) then
         return False;
      end if;

      Res := Vk.Create_Semaphore
        (Backend.Device,
         Semaphore_Info'Address,
         System.Null_Address,
         Backend.Image_Available_Semaphore'Address);
      if Failed ("vkCreateSemaphore(image_available)", Res) then
         return False;
      end if;

      Res := Vk.Create_Semaphore
        (Backend.Device,
         Semaphore_Info'Address,
         System.Null_Address,
         Backend.Render_Finished_Semaphore'Address);
      if Failed ("vkCreateSemaphore(render_finished)", Res) then
         return False;
      end if;

      Res := Vk.Create_Fence
        (Backend.Device,
         Fence_Info'Address,
         System.Null_Address,
         Backend.In_Flight_Fence'Address);
      if Failed ("vkCreateFence", Res) then
         return False;
      end if;

      return True;
   end Create_Command_And_Sync_Objects;

   function Create_Render_Pass_For_Format
     (Backend : in out Backend_Record) return Boolean
   is
      Color_Attachment : aliased Vk.Attachment_Description_T :=
        (flags           => 0,
         format          => Backend.Swapchain_Format,
         samples         => Vk.SAMPLE_COUNT_1_BIT,
         load_Op         => Vk.ATTACHMENT_LOAD_OP_CLEAR,
         store_Op        => Vk.ATTACHMENT_STORE_OP_STORE,
         stencil_Load_Op => Vk.ATTACHMENT_LOAD_OP_CLEAR,
         stencil_Store_Op => Vk.ATTACHMENT_STORE_OP_STORE,
         initial_Layout  => Vk.IMAGE_LAYOUT_UNDEFINED,
         final_Layout    => 1_000_001_002);
      Color_Ref : aliased Vk.Attachment_Reference_T :=
        (attachment => 0, layout => Vk.IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL);
      Subpass : aliased Vk.Subpass_Description_T :=
        (flags                     => 0,
         pipeline_Bind_Point       => Vk.PIPELINE_BIND_POINT_GRAPHICS,
         input_Attachment_Count    => 0,
         p_Input_Attachments       => System.Null_Address,
         color_Attachment_Count    => 1,
         p_Color_Attachments       => Color_Ref'Address,
         p_Resolve_Attachments     => System.Null_Address,
         p_Depth_Stencil_Attachment => System.Null_Address,
         preserve_Attachment_Count => 0,
         p_Preserve_Attachments    => System.Null_Address);
      Info : aliased Vk.Render_Pass_Create_Info_T :=
        (s_Type           => Vk.STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
         p_Next           => System.Null_Address,
         flags            => 0,
         attachment_Count => 1,
         p_Attachments    => Color_Attachment'Address,
         subpass_Count    => 1,
         p_Subpasses      => Subpass'Address,
         dependency_Count => 0,
         p_Dependencies   => System.Null_Address);
      Res : Vk.Result_T;
   begin
      if Backend.Render_Pass /= System.Null_Address then
         return True;
      end if;

      Res := Vk.Create_Render_Pass
        (Backend.Device,
         Info'Address,
         System.Null_Address,
         Backend.Render_Pass'Address);
      return not Failed ("vkCreateRenderPass", Res);
   end Create_Render_Pass_For_Format;

   function Choose_Extent
     (Caps   : Vk.Surface_Capabilities_KHR_T;
      Width  : C.int;
      Height : C.int) return Vk.Extent2_D_T
   is
      Result : Vk.Extent2_D_T;
   begin
      if Caps.current_Extent.width /= UINT32_MAX then
         return Caps.current_Extent;
      end if;

      Result :=
        (width  => Interfaces.Unsigned_32 (Integer'Max (1, Integer (Width))),
         height => Interfaces.Unsigned_32 (Integer'Max (1, Integer (Height))));

      if Result.width < Caps.min_Image_Extent.width then
         Result.width := Caps.min_Image_Extent.width;
      end if;
      if Result.height < Caps.min_Image_Extent.height then
         Result.height := Caps.min_Image_Extent.height;
      end if;
      if Caps.max_Image_Extent.width > 0
        and then Result.width > Caps.max_Image_Extent.width
      then
         Result.width := Caps.max_Image_Extent.width;
      end if;
      if Caps.max_Image_Extent.height > 0
        and then Result.height > Caps.max_Image_Extent.height
      then
         Result.height := Caps.max_Image_Extent.height;
      end if;

      return Result;
   end Choose_Extent;

   function Recreate_Swapchain
     (Backend : in out Backend_Record;
      Width   : C.int;
      Height  : C.int) return Boolean
   is
      Caps : aliased Vk.Surface_Capabilities_KHR_T;
      Old_Swapchain : constant Vk.Swapchain_KHR_T := Backend.Swapchain;
      Image_Count : aliased Interfaces.Unsigned_32;
      Res : Vk.Result_T;
   begin
      if Failed
        ("vkGetPhysicalDeviceSurfaceCapabilitiesKHR",
         Vk.Get_Physical_Device_Surface_Capabilities_KHR
           (Backend.Physical_Device, Backend.Surface, Caps'Address))
      then
         return False;
      end if;

      Backend.Swapchain_Extent := Choose_Extent (Caps, Width, Height);
      if Backend.Swapchain_Extent.width = 0
        or else Backend.Swapchain_Extent.height = 0
      then
         Backend.Swapchain_Needs_Recreate := True;
         return False;
      end if;

      Image_Count := Caps.min_Image_Count + 1;
      if Caps.max_Image_Count > 0 and then Image_Count > Caps.max_Image_Count then
         Image_Count := Caps.max_Image_Count;
      end if;

      declare
         Info : aliased Vk.Swapchain_Create_Info_KHR_T :=
           (s_Type                   => 1_000_001_000,
            p_Next                   => System.Null_Address,
            flags                    => 0,
            surface                  => Backend.Surface,
            min_Image_Count          => Image_Count,
            image_Format             => Backend.Swapchain_Format,
            image_Color_Space        => Vk.COLOR_SPACE_SRGB_NONLINEAR_KHR,
            image_Extent             => Backend.Swapchain_Extent,
            image_Array_Layers       => 1,
            image_Usage              => Vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
            image_Sharing_Mode       => Vk.SHARING_MODE_EXCLUSIVE,
            queue_Family_Index_Count => 0,
            p_Queue_Family_Indices   => System.Null_Address,
            pre_Transform            => Caps.current_Transform,
            composite_Alpha          => Vk.COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
            present_Mode             => Vk.PRESENT_MODE_FIFO_KHR,
            clipped                  => VK_TRUE,
            old_Swapchain            => Old_Swapchain);
      begin
         Res := Vk.Device_Wait_Idle (Backend.Device);
         if Failed ("vkDeviceWaitIdle", Res) then
            return False;
         end if;

         Destroy_Swapchain_Frame_Resources (Backend);

         Res := Vk.Create_Swapchain_KHR
           (Backend.Device,
            Info'Address,
            System.Null_Address,
            Backend.Swapchain'Address);
         if Failed ("vkCreateSwapchainKHR", Res) then
            return False;
         end if;
      end;

      if Old_Swapchain /= System.Null_Address then
         Vk.Destroy_Swapchain_KHR
           (Backend.Device, Old_Swapchain, System.Null_Address);
      end if;

      Res := Vk.Get_Swapchain_Images_KHR
        (Backend.Device,
         Backend.Swapchain,
         Image_Count'Address,
         System.Null_Address);
      if Failed ("vkGetSwapchainImagesKHR(count)", Res) then
         return False;
      end if;

      Backend.Image_Count := Image_Count;
      Backend.Images := new Image_Array (1 .. Positive (Image_Count));
      Backend.Image_Views := new Image_View_Array (1 .. Positive (Image_Count));
      Backend.Framebuffers := new Framebuffer_Array (1 .. Positive (Image_Count));
      Backend.Command_Buffers :=
        new Command_Buffer_Array (1 .. Positive (Image_Count));

      for I in Backend.Image_Views'Range loop
         Backend.Image_Views (I) := System.Null_Address;
         Backend.Framebuffers (I) := System.Null_Address;
         Backend.Command_Buffers (I) := System.Null_Address;
      end loop;

      Res := Vk.Get_Swapchain_Images_KHR
        (Backend.Device,
         Backend.Swapchain,
         Backend.Image_Count'Address,
         Backend.Images (1)'Address);
      if Failed ("vkGetSwapchainImagesKHR(images)", Res) then
         return False;
      end if;

      if not Create_Render_Pass_For_Format (Backend) then
         return False;
      end if;

      if not Create_Rect_Pipeline (Backend) then
         return False;
      end if;

      if not Create_Text_Pipeline (Backend) then
         return False;
      end if;

      for I in Backend.Images'Range loop
         declare
            View_Info : aliased Vk.Image_View_Create_Info_T :=
              (s_Type            => Vk.STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
               p_Next            => System.Null_Address,
               flags             => 0,
               image             => Backend.Images (I),
               view_Type         => Vk.IMAGE_VIEW_TYPE_2D,
               format            => Backend.Swapchain_Format,
               components        => (r => 0, g => 0, b => 0, a => 0),
               subresource_Range =>
                 (aspect_Mask      => Vk.IMAGE_ASPECT_COLOR_BIT,
                  base_Mip_Level   => 0,
                  level_Count      => 1,
                  base_Array_Layer => 0,
                  layer_Count      => 1));
         begin
            Res := Vk.Create_Image_View
              (Backend.Device,
               View_Info'Address,
               System.Null_Address,
               Backend.Image_Views (I)'Address);
            if Failed ("vkCreateImageView(swapchain)", Res) then
               return False;
            end if;
         end;
      end loop;

      for I in Backend.Image_Views'Range loop
         declare
            Attachment : aliased Vk.Image_View_T := Backend.Image_Views (I);
            Fb_Info : aliased Vk.Framebuffer_Create_Info_T :=
              (s_Type           => Vk.STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
               p_Next           => System.Null_Address,
               flags            => 0,
               render_Pass      => Backend.Render_Pass,
               attachment_Count => 1,
               p_Attachments    => Attachment'Address,
               width            => Backend.Swapchain_Extent.width,
               height           => Backend.Swapchain_Extent.height,
               layers           => 1);
         begin
            Res := Vk.Create_Framebuffer
              (Backend.Device,
               Fb_Info'Address,
               System.Null_Address,
               Backend.Framebuffers (I)'Address);
            if Failed ("vkCreateFramebuffer", Res) then
               return False;
            end if;
         end;
      end loop;

      declare
         Cmd_Alloc : aliased Vk.Command_Buffer_Allocate_Info_T :=
           (s_Type               => Vk.STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            p_Next               => System.Null_Address,
            command_Pool         => Backend.Command_Pool,
            level                => Vk.COMMAND_BUFFER_LEVEL_PRIMARY,
            command_Buffer_Count => Backend.Image_Count);
      begin
         Res := Vk.Allocate_Command_Buffers
           (Backend.Device, Cmd_Alloc'Address, Backend.Command_Buffers (1)'Address);
         if Failed ("vkAllocateCommandBuffers", Res) then
            return False;
         end if;
      end;

      Backend.Swapchain_Needs_Recreate := False;
      Backend.Swapchain_Recreate_Count_Value :=
        Backend.Swapchain_Recreate_Count_Value + 1;
      Put_Error
        ("runtime: swapchain recreated ("
         & Integer'Image (Integer (Backend.Swapchain_Extent.width)) & "x"
         & Integer'Image (Integer (Backend.Swapchain_Extent.height)) & ")");
      return True;
   end Recreate_Swapchain;

   procedure Push_Rect
     (Verts : in out Rect_Vertex_Array;
      Count : in out Natural;
      R     : Editor.Render_Packet.Rect_Command)
   is
      X0 : constant C.C_float := R.X;
      Y0 : constant C.C_float := R.Y;
      X1 : constant C.C_float := R.X + R.W;
      Y1 : constant C.C_float := R.Y + R.H;
      V0 : constant Rect_Vertex :=
        (X => X0, Y => Y0, R => R.R, G => R.G, B => R.B);
      V1 : constant Rect_Vertex :=
        (X => X1, Y => Y0, R => R.R, G => R.G, B => R.B);
      V2 : constant Rect_Vertex :=
        (X => X1, Y => Y1, R => R.R, G => R.G, B => R.B);
      V3 : constant Rect_Vertex :=
        (X => X0, Y => Y1, R => R.R, G => R.G, B => R.B);
   begin
      if Count + 6 > Verts'Length then
         raise Constraint_Error with "rect vertex overflow";
      end if;

      Verts (Count) := V0;
      Count := Count + 1;
      Verts (Count) := V1;
      Count := Count + 1;
      Verts (Count) := V2;
      Count := Count + 1;
      Verts (Count) := V2;
      Count := Count + 1;
      Verts (Count) := V3;
      Count := Count + 1;
      Verts (Count) := V0;
      Count := Count + 1;
   end Push_Rect;

   procedure Push_Glyph
     (Verts : in out Glyph_Vertex_Array;
      Count : in out Natural;
      G     : Editor.Render_Packet.Glyph_Command)
   is
      X0 : constant C.C_float := G.X;
      Y0 : constant C.C_float := G.Y;
      X1 : constant C.C_float := G.X + G.W;
      Y1 : constant C.C_float := G.Y + G.H;
      V0 : constant Glyph_Vertex :=
        (X => X0, Y => Y0, U => G.U0, V => G.V0, R => G.R, G => G.G, B => G.B);
      V1 : constant Glyph_Vertex :=
        (X => X1, Y => Y0, U => G.U1, V => G.V0, R => G.R, G => G.G, B => G.B);
      V2 : constant Glyph_Vertex :=
        (X => X1, Y => Y1, U => G.U1, V => G.V1, R => G.R, G => G.G, B => G.B);
      V3 : constant Glyph_Vertex :=
        (X => X0, Y => Y1, U => G.U0, V => G.V1, R => G.R, G => G.G, B => G.B);
   begin
      if Count + 6 > Verts'Length then
         raise Constraint_Error with "glyph vertex overflow";
      end if;

      Verts (Count) := V0;
      Count := Count + 1;
      Verts (Count) := V1;
      Count := Count + 1;
      Verts (Count) := V2;
      Count := Count + 1;
      Verts (Count) := V2;
      Count := Count + 1;
      Verts (Count) := V3;
      Count := Count + 1;
      Verts (Count) := V0;
      Count := Count + 1;
   end Push_Glyph;

   function Record_Command_Buffer
     (Backend : in out Backend_Record;
      Packet  : Editor.Render_Packet.Render_Packet) return Boolean
   is
      Cmd : constant Vk.Command_Buffer_T :=
        Backend.Command_Buffers (Integer (Backend.Current_Image_Index) + 1);
      Begin_Info : aliased Vk.Command_Buffer_Begin_Info_T :=
        (s_Type             => Vk.STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
         p_Next             => System.Null_Address,
         flags              => 0,
         p_Inheritance_Info => System.Null_Address);
      Clear : aliased Vk.Clear_Value_T :=
        (Kind  => 0,
         color =>
           (Kind    => 0,
            float32 => (0.10, 0.10, 0.12, 1.0)));
      Rp_Begin : aliased Vk.Render_Pass_Begin_Info_T :=
        (s_Type            => Vk.STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
         p_Next            => System.Null_Address,
         render_Pass       => Backend.Render_Pass,
         framebuffer       =>
           Backend.Framebuffers (Integer (Backend.Current_Image_Index) + 1),
         render_Area       =>
           (offset => (x => 0, y => 0), extent => Backend.Swapchain_Extent),
         clear_Value_Count => 1,
         p_Clear_Values    => Clear'Address);
      Res : Vk.Result_T;
   begin
      Res := Vk.Reset_Command_Buffer (Cmd, 0);
      if Failed ("vkResetCommandBuffer", Res) then
         return False;
      end if;

      Res := Vk.Begin_Command_Buffer (Cmd, Begin_Info'Address);
      if Failed ("vkBeginCommandBuffer", Res) then
         return False;
      end if;

      Vk.Cmd_Begin_Render_Pass
        (Cmd, Rp_Begin'Address, Vk.SUBPASS_CONTENTS_INLINE);

      declare
         Viewport : aliased Vk.Viewport_T :=
           (x => 0.0,
            y => 0.0,
            width => C.C_float (Backend.Swapchain_Extent.width),
            height => C.C_float (Backend.Swapchain_Extent.height),
            min_Depth => 0.0,
            max_Depth => 1.0);
         Scissor : aliased Vk.Rect2_D_T :=
           (offset => (x => 0, y => 0), extent => Backend.Swapchain_Extent);
         PC : aliased Push_Constants :=
           (Width  => C.C_float (Backend.Swapchain_Extent.width),
            Height => C.C_float (Backend.Swapchain_Extent.height));
      begin
         Vk.Cmd_Set_Viewport (Cmd, 0, 1, Viewport'Address);
         Vk.Cmd_Set_Scissor (Cmd, 0, 1, Scissor'Address);

         for Layer in
           Integer (Editor.Render_Layers.C_First) ..
             Integer (Editor.Render_Layers.C_Last)
         loop
            declare
               Verts : aliased Rect_Vertex_Array (0 .. Max_Rect_Vertices - 1);
               Vert_Count : Natural := 0;
            begin
               for I in 0 .. Integer (Packet.Rect_Count) - 1 loop
                  if Integer (Packet.Rects (I).Layer) = Layer then
                     Push_Rect (Verts, Vert_Count, Packet.Rects (I));
                  end if;
               end loop;

               if Vert_Count > 0 then
                  declare
                     Mapped : aliased System.Address := System.Null_Address;
                     Copy_Bytes : constant Interfaces.Unsigned_64 :=
                       Interfaces.Unsigned_64 (Vert_Count) * Rect_Vertex_Size;
                     Buffers : aliased Buffer_Array (1 .. 1) :=
                       (1 => Backend.Vertex_Buffer);
                     Offsets : aliased Device_Size_Array (1 .. 1) := (1 => 0);
                     Copy_Result : System.Address;
                     pragma Unreferenced (Copy_Result);
                  begin
                     Res := Vk.Map_Memory
                       (Backend.Device,
                        Backend.Vertex_Buffer_Memory,
                        0,
                        Copy_Bytes,
                        0,
                        Mapped'Address);
                     if Failed ("vkMapMemory(rect vertices)", Res) then
                        Vk.Cmd_End_Render_Pass (Cmd);
                        return False;
                     end if;

                     Copy_Result :=
                       Memcpy
                         (Mapped,
                          Verts (0)'Address,
                          Interfaces.C.size_t (Copy_Bytes));
                     Vk.Unmap_Memory
                       (Backend.Device, Backend.Vertex_Buffer_Memory);

                     Vk.Cmd_Bind_Pipeline
                       (Cmd,
                        Vk.PIPELINE_BIND_POINT_GRAPHICS,
                        Backend.Rect_Pipeline);
                     Vk.Cmd_Bind_Vertex_Buffers
                       (Cmd, 0, 1, Buffers'Address, Offsets'Address);
                     Vk.Cmd_Push_Constants
                       (Cmd,
                        Backend.Rect_Pipeline_Layout,
                        Vk.SHADER_STAGE_VERTEX_BIT,
                        0,
                        Interfaces.Unsigned_32 (Push_Constants'Size / 8),
                        PC'Address);
                     Vk.Cmd_Draw
                       (Cmd,
                        Interfaces.Unsigned_32 (Vert_Count),
                        1,
                        0,
                        0);
                  end;
               end if;

               declare
                  G_Verts : aliased Glyph_Vertex_Array
                    (0 .. Max_Glyph_Vertices - 1);
                  Glyph_Vert_Count : Natural := 0;
               begin
                  for I in 0 .. Integer (Packet.Glyph_Count) - 1 loop
                     if Integer (Packet.Glyphs (I).Layer) = Layer then
                        Push_Glyph
                          (G_Verts, Glyph_Vert_Count, Packet.Glyphs (I));
                     end if;
                  end loop;

                  if Glyph_Vert_Count > 0
                    and then Backend.Text_Descriptor_Set /= System.Null_Address
                    and then Backend.Font_Atlas_Image_View /=
                      System.Null_Address
                  then
                     declare
                        Mapped : aliased System.Address := System.Null_Address;
                        Copy_Bytes : constant Interfaces.Unsigned_64 :=
                          Interfaces.Unsigned_64 (Glyph_Vert_Count) *
                            Glyph_Vertex_Size;
                        Buffers : aliased Buffer_Array (1 .. 1) :=
                          (1 => Backend.Glyph_Vertex_Buffer);
                        Offsets : aliased Device_Size_Array (1 .. 1) := (1 => 0);
                        Sets : aliased Descriptor_Set_Array (1 .. 1) :=
                          (1 => Backend.Text_Descriptor_Set);
                        Copy_Result : System.Address;
                        pragma Unreferenced (Copy_Result);
                     begin
                        Res := Vk.Map_Memory
                          (Backend.Device,
                           Backend.Glyph_Vertex_Buffer_Memory,
                           0,
                           Copy_Bytes,
                           0,
                           Mapped'Address);
                        if Failed ("vkMapMemory(glyph vertices)", Res) then
                           Vk.Cmd_End_Render_Pass (Cmd);
                           return False;
                        end if;

                        Copy_Result :=
                          Memcpy
                            (Mapped,
                             G_Verts (0)'Address,
                             Interfaces.C.size_t (Copy_Bytes));
                        Vk.Unmap_Memory
                          (Backend.Device, Backend.Glyph_Vertex_Buffer_Memory);

                        Vk.Cmd_Bind_Pipeline
                          (Cmd,
                           Vk.PIPELINE_BIND_POINT_GRAPHICS,
                           Backend.Text_Pipeline);
                        Vk.Cmd_Bind_Descriptor_Sets
                          (Cmd,
                           Vk.PIPELINE_BIND_POINT_GRAPHICS,
                           Backend.Text_Pipeline_Layout,
                           0,
                           1,
                           Sets'Address,
                           0,
                           System.Null_Address);
                        Vk.Cmd_Bind_Vertex_Buffers
                          (Cmd, 0, 1, Buffers'Address, Offsets'Address);
                        Vk.Cmd_Push_Constants
                          (Cmd,
                           Backend.Text_Pipeline_Layout,
                           Vk.SHADER_STAGE_VERTEX_BIT,
                           0,
                           Interfaces.Unsigned_32 (Push_Constants'Size / 8),
                           PC'Address);
                        Vk.Cmd_Draw
                          (Cmd,
                           Interfaces.Unsigned_32 (Glyph_Vert_Count),
                           1,
                           0,
                           0);
                     end;
                  end if;
               end;
            end;
         end loop;
      end;

      Vk.Cmd_End_Render_Pass (Cmd);

      Res := Vk.End_Command_Buffer (Cmd);
      return not Failed ("vkEndCommandBuffer", Res);
   end Record_Command_Buffer;

   function Create (Window : System.Address) return System.Address is
      Backend : Backend_Access := new Backend_Record;
   begin
      Backend.Window := Window;

      if not Create_Instance_And_Surface (Backend.all)
        or else not Pick_Physical_Device (Backend.all)
        or else not Pick_Queue_Family (Backend.all)
        or else not Create_Device_And_Queue (Backend.all)
        or else not Query_Surface_Format (Backend.all)
        or else not Create_Command_And_Sync_Objects (Backend.all)
        or else not Create_Text_Descriptors (Backend.all)
        or else not Create_Buffer
          (Backend.all,
           Max_Rect_Vertex_Bytes,
           Vk.BUFFER_USAGE_VERTEX_BUFFER_BIT,
           Vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT
             or Vk.MEMORY_PROPERTY_HOST_COHERENT_BIT,
           Backend.Vertex_Buffer,
           Backend.Vertex_Buffer_Memory)
        or else not Create_Buffer
          (Backend.all,
           Max_Glyph_Vertex_Bytes,
           Vk.BUFFER_USAGE_VERTEX_BUFFER_BIT,
           Vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT
             or Vk.MEMORY_PROPERTY_HOST_COHERENT_BIT,
           Backend.Glyph_Vertex_Buffer,
           Backend.Glyph_Vertex_Buffer_Memory)
      then
         Destroy (To_Address (Backend));
         return System.Null_Address;
      end if;

      return To_Address (Backend);
   end Create;

   function Begin_Frame
     (Backend : System.Address;
      Width   : C.int;
      Height  : C.int) return C.int
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      if B = null then
         Put_Error ("render_backend_begin_frame: backend is null");
         return 0;
      end if;

      B.Frame_Active := False;
      B.Frame_Rendered := False;

      if Width <= 0 or else Height <= 0 then
         B.Swapchain_Needs_Recreate := True;
         return 1;
      end if;

      if B.Swapchain_Needs_Recreate
        or else B.Swapchain = System.Null_Address
      then
         if not Recreate_Swapchain (B.all, Width, Height) then
            if Width <= 0 or else Height <= 0 then
               return 1;
            end if;
            Put_Error
              ("render_backend_begin_frame: swapchain recreation failed");
            return 0;
         end if;
      end if;

      declare
         Res : Vk.Result_T;
      begin
         Res := Vk.Wait_For_Fences
           (B.Device, 1, B.In_Flight_Fence'Address, VK_TRUE, UINT64_MAX);
         if Failed ("vkWaitForFences", Res) then
            return 0;
         end if;

         Res := Vk.Acquire_Next_Image_KHR
           (B.Device,
            B.Swapchain,
            UINT64_MAX,
            B.Image_Available_Semaphore,
            System.Null_Address,
            B.Current_Image_Index'Address);

         if Res = ERROR_OUT_OF_DATE_KHR then
            B.Swapchain_Needs_Recreate := True;
            return 1;
         elsif Res = SUBOPTIMAL_KHR then
            B.Swapchain_Needs_Recreate := True;
         elsif Failed ("vkAcquireNextImageKHR", Res) then
            return 0;
         end if;
      end;

      B.Frame_Active := True;
      return 1;
   end Begin_Frame;

   function Draw_Editor (Backend : System.Address) return C.int is
      B : constant Backend_Access := To_Backend (Backend);
      Packet : Editor.Render_Packet.Render_Packet;
   begin
      if B = null then
         Put_Error ("render_backend_draw_editor: backend is null");
         return 0;
      end if;

      if not B.Frame_Active then
         return 1;
      end if;

      Editor.C_API.Editor_Get_Render_Packet (Packet);

      if Packet.Rect_Count < 0
        or else Integer (Packet.Rect_Count) >
          Editor.Render_Packet.Max_Rectangles
      then
         Put_Error ("Invalid rect_count:" & C.int'Image (Packet.Rect_Count));
         B.Frame_Active := False;
         return 0;
      end if;

      if Packet.Glyph_Count < 0
        or else Integer (Packet.Glyph_Count) > Editor.Render_Packet.Max_Glyphs
      then
         Put_Error
           ("Invalid glyph_count:" & C.int'Image (Packet.Glyph_Count));
         B.Frame_Active := False;
         return 0;
      end if;

      for I in 0 .. Integer (Packet.Rect_Count) - 1 loop
         if Packet.Rects (I).Layer < Editor.Render_Layers.C_First
           or else Packet.Rects (I).Layer > Editor.Render_Layers.C_Last
         then
            Put_Error
              ("Invalid rect layer:"
               & C.int'Image (Packet.Rects (I).Layer));
            B.Frame_Active := False;
            return 0;
         end if;
      end loop;

      for I in 0 .. Integer (Packet.Glyph_Count) - 1 loop
         if Packet.Glyphs (I).Layer < Editor.Render_Layers.C_First
           or else Packet.Glyphs (I).Layer > Editor.Render_Layers.C_Last
         then
            Put_Error
              ("Invalid glyph layer:"
               & C.int'Image (Packet.Glyphs (I).Layer));
            B.Frame_Active := False;
            return 0;
         end if;
      end loop;

      Capture_Visual_Contract (B.all, Packet);
      if Editor.Font_Bridge.Atlas_Dirty /= 0 then
         if not Upload_Font_Atlas (B.all) then
            B.Frame_Active := False;
            return 0;
         end if;
         Capture_Font_Atlas_Upload (B.all);
      end if;

      if not Record_Command_Buffer (B.all, Packet) then
         B.Frame_Active := False;
         return 0;
      end if;

      return 1;
   end Draw_Editor;

   function End_Frame (Backend : System.Address) return C.int is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      if B = null then
         Put_Error ("render_backend_end_frame: backend is null");
         return 0;
      end if;

      if not B.Frame_Active then
         return 1;
      end if;

      declare
         Wait_Stage : aliased Vk.Pipeline_Stage_Flags_T :=
           Vk.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
         Cmd : aliased Vk.Command_Buffer_T :=
           B.Command_Buffers (Integer (B.Current_Image_Index) + 1);
         Submit : aliased Vk.Submit_Info_T :=
           (s_Type                  => Vk.STRUCTURE_TYPE_SUBMIT_INFO,
            p_Next                  => System.Null_Address,
            wait_Semaphore_Count    => 1,
            p_Wait_Semaphores       => B.Image_Available_Semaphore'Address,
            p_Wait_Dst_Stage_Mask   => Wait_Stage'Address,
            command_Buffer_Count    => 1,
            p_Command_Buffers       => Cmd'Address,
            signal_Semaphore_Count  => 1,
            p_Signal_Semaphores     => B.Render_Finished_Semaphore'Address);
         Swapchain : aliased Vk.Swapchain_KHR_T := B.Swapchain;
         Present : aliased Vk.Present_Info_KHR_T :=
           (s_Type               => 1_000_001_001,
            p_Next               => System.Null_Address,
            wait_Semaphore_Count => 1,
            p_Wait_Semaphores    => B.Render_Finished_Semaphore'Address,
            swapchain_Count      => 1,
            p_Swapchains         => Swapchain'Address,
            p_Image_Indices      => B.Current_Image_Index'Address,
            p_Results            => System.Null_Address);
         Res : Vk.Result_T;
      begin
         Res := Vk.Reset_Fences
           (B.Device, 1, B.In_Flight_Fence'Address);
         if Failed ("vkResetFences", Res) then
            B.Frame_Active := False;
            return 0;
         end if;

         Res := Vk.Queue_Submit
           (B.Graphics_Queue, 1, Submit'Address, B.In_Flight_Fence);
         if Failed ("vkQueueSubmit", Res) then
            B.Frame_Active := False;
            return 0;
         end if;

         Res := Vk.Queue_Present_KHR (B.Graphics_Queue, Present'Address);
         if Res = ERROR_OUT_OF_DATE_KHR or else Res = SUBOPTIMAL_KHR then
            B.Swapchain_Needs_Recreate := True;
         elsif Failed ("vkQueuePresentKHR", Res) then
            B.Frame_Active := False;
            return 0;
         end if;
      end;

      B.Frame_Active := False;
      B.Frame_Rendered := True;
      return 1;
   end End_Frame;

   procedure Request_Swapchain_Recreate (Backend : System.Address) is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      if B /= null then
         B.Swapchain_Needs_Recreate := True;
      end if;
   end Request_Swapchain_Recreate;

   function Frame_Was_Rendered (Backend : System.Address) return C.int is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then To_C_Int (B.Frame_Rendered) else 0);
   end Frame_Was_Rendered;

   function Swapchain_Recreate_Count
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then B.Swapchain_Recreate_Count_Value else 0);
   end Swapchain_Recreate_Count;

   function Font_Atlas_Upload_Count
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then B.Font_Atlas_Upload_Count_Value else 0);
   end Font_Atlas_Upload_Count;

   function Font_Atlas_Last_Upload_Width
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then B.Font_Atlas_Last_Upload_Width_Value else 0);
   end Font_Atlas_Last_Upload_Width;

   function Font_Atlas_Last_Upload_Height
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then B.Font_Atlas_Last_Upload_Height_Value else 0);
   end Font_Atlas_Last_Upload_Height;

   function Font_Atlas_Last_Upload_Nonzero_Bytes
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return
        (if B /= null
         then B.Font_Atlas_Last_Upload_Nonzero_Bytes_Value
         else 0);
   end Font_Atlas_Last_Upload_Nonzero_Bytes;

   function Font_Atlas_Last_Upload_Checksum
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return
        (if B /= null then B.Font_Atlas_Last_Upload_Checksum_Value else 0);
   end Font_Atlas_Last_Upload_Checksum;

   function Font_Atlas_Dirty (Backend : System.Address) return C.int is
      pragma Unreferenced (Backend);
   begin
      return Editor.Font_Bridge.Atlas_Dirty;
   end Font_Atlas_Dirty;

   function Last_Visual_Rect_Count
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then B.Last_Visual_Rect_Count_Value else 0);
   end Last_Visual_Rect_Count;

   function Last_Visual_Glyph_Count
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then B.Last_Visual_Glyph_Count_Value else 0);
   end Last_Visual_Glyph_Count;

   function Last_Visual_Geometry_Checksum
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then B.Last_Visual_Geometry_Checksum_Value else 0);
   end Last_Visual_Geometry_Checksum;

   function Last_Visual_Color_Checksum
     (Backend : System.Address) return C.unsigned
   is
      B : constant Backend_Access := To_Backend (Backend);
   begin
      return (if B /= null then B.Last_Visual_Color_Checksum_Value else 0);
   end Last_Visual_Color_Checksum;

   function Validate_Required_Shader_Assets return C.int is
   begin
      if not Find_Shader ("rect.vert.spv") then
         Put_Error
           ("runtime asset check: required shader asset missing: "
            & "rect.vert.spv");
         return 0;
      end if;

      if not Find_Shader ("rect.frag.spv") then
         Put_Error
           ("runtime asset check: required shader asset missing: "
            & "rect.frag.spv");
         return 0;
      end if;

      if not Find_Shader ("text.vert.spv") then
         Put_Error
           ("runtime asset check: required shader asset missing: "
            & "text.vert.spv");
         return 0;
      end if;

      if not Find_Shader ("text.frag.spv") then
         Put_Error
           ("runtime asset check: required shader asset missing: "
            & "text.frag.spv");
         return 0;
      end if;

      Put_Error ("runtime asset check: required shader assets found");
      return 1;
   end Validate_Required_Shader_Assets;

   procedure Destroy (Backend : System.Address) is
      B : Backend_Access := To_Backend (Backend);
   begin
      if B = null then
         return;
      end if;

      if B.Device /= System.Null_Address then
         declare
            Ignored : constant Vk.Result_T := Vk.Device_Wait_Idle (B.Device);
            pragma Unreferenced (Ignored);
         begin
            null;
         end;
      end if;

      if B.In_Flight_Fence /= System.Null_Address then
         Vk.Destroy_Fence (B.Device, B.In_Flight_Fence, System.Null_Address);
         B.In_Flight_Fence := System.Null_Address;
      end if;

      if B.Image_Available_Semaphore /= System.Null_Address then
         Vk.Destroy_Semaphore
           (B.Device, B.Image_Available_Semaphore, System.Null_Address);
         B.Image_Available_Semaphore := System.Null_Address;
      end if;

      if B.Render_Finished_Semaphore /= System.Null_Address then
         Vk.Destroy_Semaphore
           (B.Device, B.Render_Finished_Semaphore, System.Null_Address);
         B.Render_Finished_Semaphore := System.Null_Address;
      end if;

      Destroy_Swapchain_Frame_Resources (B.all);

      if B.Swapchain /= System.Null_Address then
         Vk.Destroy_Swapchain_KHR
           (B.Device, B.Swapchain, System.Null_Address);
         B.Swapchain := System.Null_Address;
      end if;

      Destroy_Font_Atlas_Image (B.all);

      if B.Font_Atlas_Sampler /= System.Null_Address then
         Vk.Destroy_Sampler
           (B.Device, B.Font_Atlas_Sampler, System.Null_Address);
         B.Font_Atlas_Sampler := System.Null_Address;
      end if;

      if B.Text_Descriptor_Pool /= System.Null_Address then
         Vk.Destroy_Descriptor_Pool
           (B.Device, B.Text_Descriptor_Pool, System.Null_Address);
         B.Text_Descriptor_Pool := System.Null_Address;
         B.Text_Descriptor_Set := System.Null_Address;
      end if;

      if B.Text_Descriptor_Set_Layout /= System.Null_Address then
         Vk.Destroy_Descriptor_Set_Layout
           (B.Device, B.Text_Descriptor_Set_Layout, System.Null_Address);
         B.Text_Descriptor_Set_Layout := System.Null_Address;
      end if;

      if B.Command_Pool /= System.Null_Address then
         Vk.Destroy_Command_Pool
           (B.Device, B.Command_Pool, System.Null_Address);
         B.Command_Pool := System.Null_Address;
      end if;

      if B.Vertex_Buffer /= System.Null_Address then
         Vk.Destroy_Buffer (B.Device, B.Vertex_Buffer, System.Null_Address);
         B.Vertex_Buffer := System.Null_Address;
      end if;

      if B.Vertex_Buffer_Memory /= System.Null_Address then
         Vk.Free_Memory
           (B.Device, B.Vertex_Buffer_Memory, System.Null_Address);
         B.Vertex_Buffer_Memory := System.Null_Address;
      end if;

      if B.Glyph_Vertex_Buffer /= System.Null_Address then
         Vk.Destroy_Buffer
           (B.Device, B.Glyph_Vertex_Buffer, System.Null_Address);
         B.Glyph_Vertex_Buffer := System.Null_Address;
      end if;

      if B.Glyph_Vertex_Buffer_Memory /= System.Null_Address then
         Vk.Free_Memory
           (B.Device, B.Glyph_Vertex_Buffer_Memory, System.Null_Address);
         B.Glyph_Vertex_Buffer_Memory := System.Null_Address;
      end if;

      if B.Rect_Pipeline /= System.Null_Address then
         Vk.Destroy_Pipeline (B.Device, B.Rect_Pipeline, System.Null_Address);
         B.Rect_Pipeline := System.Null_Address;
      end if;

      if B.Rect_Pipeline_Layout /= System.Null_Address then
         Vk.Destroy_Pipeline_Layout
           (B.Device, B.Rect_Pipeline_Layout, System.Null_Address);
         B.Rect_Pipeline_Layout := System.Null_Address;
      end if;

      if B.Text_Pipeline /= System.Null_Address then
         Vk.Destroy_Pipeline (B.Device, B.Text_Pipeline, System.Null_Address);
         B.Text_Pipeline := System.Null_Address;
      end if;

      if B.Text_Pipeline_Layout /= System.Null_Address then
         Vk.Destroy_Pipeline_Layout
           (B.Device, B.Text_Pipeline_Layout, System.Null_Address);
         B.Text_Pipeline_Layout := System.Null_Address;
      end if;

      if B.Render_Pass /= System.Null_Address then
         Vk.Destroy_Render_Pass
           (B.Device, B.Render_Pass, System.Null_Address);
         B.Render_Pass := System.Null_Address;
      end if;

      if B.Device /= System.Null_Address then
         Vk.Destroy_Device (B.Device, System.Null_Address);
         B.Device := System.Null_Address;
      end if;

      if B.Surface /= System.Null_Address then
         Vk.Destroy_Surface_KHR
           (B.Instance, B.Surface, System.Null_Address);
         B.Surface := System.Null_Address;
      end if;

      if B.Instance /= System.Null_Address then
         Vk.Destroy_Instance (B.Instance, System.Null_Address);
         B.Instance := System.Null_Address;
      end if;

      Free (B);
   end Destroy;
end Render_Backend_Vulkan;
