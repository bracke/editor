with Editor.Unicode;

package Editor.UTF8 is
   type UTF8_Error_Mode is (Reject, Replace);

   Invalid_UTF8 : exception;

   procedure Decode_UTF8
     (Bytes      : String;
      Visit      : not null access procedure
        (Code : Editor.Unicode.Code_Point);
      On_Invalid : UTF8_Error_Mode := Replace);

   function Encode_UTF8
     (Code : Editor.Unicode.Code_Point) return String;

   function Code_Point_Count
     (Bytes      : String;
      On_Invalid : UTF8_Error_Mode := Replace) return Natural;

   function Byte_Offset_For_Code_Point_Index
     (Bytes : String;
      Index : Natural) return Natural;
end Editor.UTF8;
