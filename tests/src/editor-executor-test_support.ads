with Editor.State;

package Editor.Executor.Test_Support is

   function Temp_Path (Name : String) return String;

   procedure Init_Executor_Test_State (S : out Editor.State.State_Type);

   procedure Use_Executor_Recent_Config;

   function Latest_Message_Text (S : Editor.State.State_Type) return String;

   procedure Move_Caret_To_Line
     (S    : in out Editor.State.State_Type;
      Line : Positive);

   function Active_Caret_Line (S : Editor.State.State_Type) return Natural;

   procedure Select_Diagnostic_By_Message
     (S       : in out Editor.State.State_Type;
      Message : String);

   procedure Remove_File_If_Exists (Path : String);
   procedure Remove_Dir_If_Exists (Path : String);
   procedure Remove_Tree_If_Exists (Path : String);

   procedure Write_Text_File (Path : String; Text : String);

   procedure Set_Buffer_Text
     (S    : in out Editor.State.State_Type;
      Text : String);

   function Buffer_Text (S : Editor.State.State_Type) return String;

   function Numbered_Lines
     (Count       : Positive;
      Needle_Line : Natural := 0) return String;

   function Back_Top_Line (S : Editor.State.State_Type) return Natural;
   function Forward_Top_Line (S : Editor.State.State_Type) return Natural;
   function Back_Top_Path (S : Editor.State.State_Type) return String;

   procedure Build_Fixture (Root : String);
   procedure Cleanup_Fixture (Root : String);

   procedure Build_Project_Search_Fixture (Root : String);
   procedure Cleanup_Project_Search_Fixture (Root : String);

   procedure Build_Project_Search_Multi_Fixture (Root : String);
   procedure Cleanup_Project_Search_Multi_Fixture (Root : String);

   procedure Build_Project_Search_Context_Fixture (Root : String);
   procedure Cleanup_Project_Search_Context_Fixture (Root : String);

end Editor.Executor.Test_Support;
