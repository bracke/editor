with AUnit.Test_Cases;

package Test_Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality_Pass1305 is
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Test_Case);
end Test_Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality_Pass1305;
