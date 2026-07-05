package Test_Slice_Rules is
   Max_Slice_Length : constant Positive := 32;

   type Changed_File_Filter_Category is
     (Changed_File_Actionable,
      Changed_File_Archive,
      Changed_File_Generated,
      Changed_File_Empty);

   function Slice_For (Path : String) return String;

   function Companion_Slice_For (Path : String) return String;

   function Additional_Companion_Slice_For (Path : String) return String;

   function Unit_Test_Command (Slice : String) return String;

   function Run_Next_Command_Line (Command : String) return String;

   function Is_Changed_File_Set_Argument (Argument : String) return Boolean;

   function Is_Actionable_Changed_File (Path : String) return Boolean;

   function Changed_File_Category
     (Path : String) return Changed_File_Filter_Category;

   function Product_Smoke_Command_For (Path : String) return String;

   function Workflow_Gate_Command_For (Path : String) return String;
end Test_Slice_Rules;
