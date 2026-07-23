with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Representation_Legality_Diagnostics is

   function Has_Enabled_Import_Or_Export
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Target   : Editor.Ada_Language_Model.Symbol_Id) return Boolean;

   function Find_Operational_Handler
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : String) return Editor.Ada_Language_Model.Symbol_Id;

   function Has_Enumeration_Representation_Association
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Target   : Editor.Ada_Language_Model.Symbol_Id;
      Literal_Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Target_Has_Enumeration_Literals
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Target   : Editor.Ada_Language_Model.Symbol_Id) return Boolean;

   function Enumeration_Literal_Position
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Literal  : Editor.Ada_Language_Model.Symbol_Id) return Natural;

   function Line_Before
     (Left  : Editor.Ada_Language_Model.Source_Range;
      Right : Editor.Ada_Language_Model.Source_Range) return Boolean;

   function Is_Freezable_Representation_Target
     (S : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Targeted_Body_Completion
     (Target  : Editor.Ada_Language_Model.Symbol_Info;
      Trigger : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Generic_Formal_Freezing_Use
     (Target  : Editor.Ada_Language_Model.Symbol_Info;
      Trigger : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Is_Symbol_Freezing_Use
     (Target  : Editor.Ada_Language_Model.Symbol_Info;
      Trigger : Editor.Ada_Language_Model.Symbol_Info) return Boolean;

   function Freezing_Message
     (Kind : Editor.Ada_Language_Model.Freezing_Point_Kind) return String;

   function Find_Type_By_Name
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Name     : Ada.Strings.Unbounded.Unbounded_String)
      return Editor.Ada_Language_Model.Symbol_Id;

   function Static_Size_For_Target
     (Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Target   : Editor.Ada_Language_Model.Symbol_Id;
      Found    : out Boolean) return Natural;

   procedure Note_Freezing_Point
     (Analysis : in out Editor.Ada_Language_Model.Analysis_Result;
      Target   : Editor.Ada_Language_Model.Symbol_Info;
      Trigger  : Editor.Ada_Language_Model.Symbol_Info;
      Kind     : Editor.Ada_Language_Model.Freezing_Point_Kind;
      Reason   : String);

   procedure Build_Freezing_Point_Index
     (Analysis : in out Editor.Ada_Language_Model.Analysis_Result);

   function Is_Valid_Bit_Order_Value (Text : String) return Boolean;

   function Is_Valid_Scalar_Storage_Order_Value (Text : String) return Boolean;

   function Is_Representation_Item_Subject_To_Freezing
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;

   function Representation_Target_Is_Compatible
     (Clause : Editor.Ada_Language_Model.Representation_Clause_Info;
      Kind   : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Requires_Static_Natural_Value
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean;

   procedure Add_Representation_Legality_Diagnostics
     (Analysis : in out Editor.Ada_Language_Model.Analysis_Result);

end Editor.Ada_Declaration_Parser.Representation_Legality_Diagnostics;
