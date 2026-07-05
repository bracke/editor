with Editor.State;

package Editor.Files.Test_Helpers is

   function Temp_Path (Name : String) return String;

   procedure Write_Bytes (Path : String; Bytes : String);

   function Read_Bytes (Path : String) return String;

   function Buffer_Text (S : Editor.State.State_Type) return String;

   procedure Insert_Text_At
     (S    : in out Editor.State.State_Type;
      Pos  : Natural;
      Text : String);

   procedure Execute_Revert_And_Confirm
     (S : in out Editor.State.State_Type);

   procedure Remove_If_Exists (Path : String);

end Editor.Files.Test_Helpers;
