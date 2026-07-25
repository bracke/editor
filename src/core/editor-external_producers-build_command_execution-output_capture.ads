with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers.Build_Command_Execution;

package Editor.External_Producers.Build_Command_Execution.Output_Capture is

   function Build_Output_Capture_Path
     (Working_Directory : String;
      Program_Label     : String) return String;
   procedure Delete_File_If_Present (Path : String);
   function Read_Bounded_Output_File
     (Path      : String;
      Max_Bytes : Natural;
      Truncated : out Boolean) return Unbounded_String;

end Editor.External_Producers.Build_Command_Execution.Output_Capture;
