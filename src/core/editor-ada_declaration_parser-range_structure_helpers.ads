with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Range_Structure_Helpers is

   function Same_Text
     (Left, Right : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Text_Names_Target
     (Text : Ada.Strings.Unbounded.Unbounded_String;
      Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Same_Local_Representation_Target
     (Current, Previous : Editor.Ada_Language_Model.Representation_Clause_Info)
      return Boolean;

   function Ranges_Overlap
     (Left_First, Left_Last, Right_First, Right_Last : Natural) return Boolean;

   function Contains_Range_Dots (Expr : String) return Boolean;

   function Global_First_Bit (Unit, First_Bit : Natural) return Natural;

   function Global_Last_Bit (Unit, Last_Bit : Natural) return Natural;

   function Find_Type_By_Name
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : Ada.Strings.Unbounded.Unbounded_String) return Editor.Ada_Language_Model.Symbol_Id;

   function Static_Size_For_Target
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Target   : Editor.Ada_Language_Model.Symbol_Id;
      Found    : out Boolean) return Natural;

   function Is_Local_Name_Start (C : Character) return Boolean;

   function Is_Local_Name_Char (C : Character) return Boolean;

end Editor.Ada_Declaration_Parser.Range_Structure_Helpers;
