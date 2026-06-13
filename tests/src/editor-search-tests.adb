with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Text_Buffer;
with Editor.UTF8;
with Editor.Unicode;

package body Editor.Search.Tests is

   overriding function Name
     (T : Search_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Search");
   end Name;

   procedure Test_Empty_Query_Returns_No_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      M : Editor.Search.Search_Match;
   begin
      Text_Buffer.Set_Text (B, "abc");
      M := Editor.Search.Find_Next_In_Buffer
        (B, "", 0, (Case_Sensitive => True, Wrap => True));
      Assert (not Editor.Search.Has_Match (M),
              "Empty query must never create a zero-length match");
   end Test_Empty_Query_Returns_No_Match;

   procedure Test_Forward_Search_Finds_First_Literal
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      M : Editor.Search.Search_Match;
   begin
      Text_Buffer.Set_Text (B, "abc abc");
      M := Editor.Search.Find_Next_In_Buffer
        (B, "abc", 0, (Case_Sensitive => True, Wrap => True));
      Assert (M.Start_Index = 0 and then M.End_Index = 3,
              "Forward search must return exclusive end index for first literal match");
   end Test_Forward_Search_Finds_First_Literal;

   procedure Test_Forward_Search_From_Middle_Finds_Later
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      M : Editor.Search.Search_Match;
   begin
      Text_Buffer.Set_Text (B, "abc abc");
      M := Editor.Search.Find_Next_In_Buffer
        (B, "abc", 1, (Case_Sensitive => True, Wrap => True));
      Assert (M.Start_Index = 4 and then M.End_Index = 7,
              "Forward search from the middle must find the later match first");
   end Test_Forward_Search_From_Middle_Finds_Later;

   procedure Test_Backward_Search_Finds_Previous
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      M : Editor.Search.Search_Match;
   begin
      Text_Buffer.Set_Text (B, "abc def abc");
      M := Editor.Search.Find_Previous_In_Buffer
        (B, "abc", 7, (Case_Sensitive => True, Wrap => True));
      Assert (M.Start_Index = 0 and then M.End_Index = 3,
              "Backward search must find the previous literal match");
   end Test_Backward_Search_Finds_Previous;

   procedure Test_Case_Insensitive_ASCII_Search
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      M : Editor.Search.Search_Match;
   begin
      Text_Buffer.Set_Text (B, "xx AbC yy");
      M := Editor.Search.Find_Next_In_Buffer
        (B, "abc", 0, (Case_Sensitive => False, Wrap => True));
      Assert (M.Start_Index = 3 and then M.End_Index = 6,
              "ASCII case-insensitive search must fold A-Z only");
   end Test_Case_Insensitive_ASCII_Search;

   procedure Test_Wrap_Search_Works
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      M : Editor.Search.Search_Match;
   begin
      Text_Buffer.Set_Text (B, "abc def");
      M := Editor.Search.Find_Next_In_Buffer
        (B, "abc", 4, (Case_Sensitive => True, Wrap => True));
      Assert (M.Start_Index = 0 and then M.End_Index = 3,
              "Forward search must wrap when enabled");
   end Test_Wrap_Search_Works;

   procedure Test_No_Wrap_Search_Returns_No_Match_At_End
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      M : Editor.Search.Search_Match;
   begin
      Text_Buffer.Set_Text (B, "abc def");
      M := Editor.Search.Find_Next_In_Buffer
        (B, "abc", 4, (Case_Sensitive => True, Wrap => False));
      Assert (not Editor.Search.Has_Match (M),
              "No-wrap forward search must not restart at buffer beginning");
   end Test_No_Wrap_Search_Returns_No_Match_At_End;

   procedure Test_Search_Across_Rope_Leaf_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      M : Editor.Search.Search_Match;
   begin
      Text_Buffer.Insert_Range (B, 0, 'x', 4_094);
      Text_Buffer.Insert (B, Text_Buffer.Length (B), Ch => 'a');
      Text_Buffer.Insert (B, Text_Buffer.Length (B), Ch => 'b');
      Text_Buffer.Insert (B, Text_Buffer.Length (B), Ch => 'c');
      Text_Buffer.Insert_Range (B, Text_Buffer.Length (B), 'y', 4_094);

      Assert (Text_Buffer.Leaf_Count (B) > 1,
              "Test setup must create more than one rope leaf");

      M := Editor.Search.Find_Next_In_Buffer
        (B, "abc", 4_094, (Case_Sensitive => True, Wrap => False));
      Assert (M.Start_Index = 4_094 and then M.End_Index = 4_097,
              "Search must compare through rope leaf boundaries without flattening");
   end Test_Search_Across_Rope_Leaf_Boundary;

   overriding procedure Register_Tests
     (T : in out Search_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty_Query_Returns_No_Match'Access,
         "Empty Query Returns No Match");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Forward_Search_Finds_First_Literal'Access,
         "Forward Search Finds First Literal");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Forward_Search_From_Middle_Finds_Later'Access,
         "Forward Search From Middle Finds Later Match");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Backward_Search_Finds_Previous'Access,
         "Backward Search Finds Previous Match");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Case_Insensitive_ASCII_Search'Access,
         "Case Insensitive ASCII Search");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrap_Search_Works'Access,
         "Wrap Search Works");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Wrap_Search_Returns_No_Match_At_End'Access,
         "No Wrap Search Returns No Match At End");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Search_Across_Rope_Leaf_Boundary'Access,
         "Search Across Rope Leaf Boundary");


   end Register_Tests;

end Editor.Search.Tests;
