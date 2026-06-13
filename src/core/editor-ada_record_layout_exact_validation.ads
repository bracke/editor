with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Record_Layout_Exact_Validation is

   --  Compiler-grade exact record-layout validation layer.  This model folds
   --  component bit-span metadata together with Size and Alignment clauses and
   --  derives deterministic whole-record layout checks.  It is metadata only:
   --  no parsing, file IO, buffer mutation, rendering work, or diagnostics are
   --  performed here.

   type Exact_Record_Layout_Status is
     (Exact_Record_Layout_Ok,
      Exact_Record_Layout_Size_Clause_Exceeded,
      Exact_Record_Layout_Size_Clause_Exact,
      Exact_Record_Layout_Size_Clause_Padded,
      Exact_Record_Layout_Alignment_Compatible,
      Exact_Record_Layout_Alignment_Not_Power_Of_Two,
      Exact_Record_Layout_Alignment_Static_Error,
      Exact_Record_Layout_Alignment_Target_Error,
      Exact_Record_Layout_Component_Error,
      Exact_Record_Layout_Unknown);

   type Exact_Record_Layout_Info is record
      Target_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target    : Ada.Strings.Unbounded.Unbounded_String;
      Clause_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Line          : Positive := 1;
      Required_Bits        : Long_Long_Integer := 0;
      Declared_Size_Bits   : Long_Long_Integer := 0;
      Declared_Alignment   : Long_Long_Integer := 0;
      Component_Count      : Natural := 0;
      Layout_Fingerprint   : Natural := 0;
      Clause_Fingerprint   : Natural := 0;
      Status               : Exact_Record_Layout_Status := Exact_Record_Layout_Unknown;
      Fingerprint          : Natural := 0;
   end record;

   type Exact_Record_Layout_Model is private;

   procedure Clear (Model : in out Exact_Record_Layout_Model);

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout   : Editor.Ada_Record_Layout_Validation.Record_Layout_Model)
      return Exact_Record_Layout_Model;

   function Check_Count (Model : Exact_Record_Layout_Model) return Natural;

   function Check_At
     (Model : Exact_Record_Layout_Model;
      Index : Positive) return Exact_Record_Layout_Info;

   function First_For_Target
     (Model  : Exact_Record_Layout_Model;
      Target : String) return Exact_Record_Layout_Info;

   function Count_Status
     (Model  : Exact_Record_Layout_Model;
      Status : Exact_Record_Layout_Status) return Natural;

   function Ok_Count (Model : Exact_Record_Layout_Model) return Natural;
   function Size_Exact_Count (Model : Exact_Record_Layout_Model) return Natural;
   function Size_Padded_Count (Model : Exact_Record_Layout_Model) return Natural;
   function Size_Exceeded_Count (Model : Exact_Record_Layout_Model) return Natural;
   function Alignment_Compatible_Count (Model : Exact_Record_Layout_Model) return Natural;
   function Alignment_Error_Count (Model : Exact_Record_Layout_Model) return Natural;
   function Component_Error_Count (Model : Exact_Record_Layout_Model) return Natural;
   function Fingerprint (Model : Exact_Record_Layout_Model) return Natural;

private
   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Exact_Record_Layout_Info);

   type Counter_Array is array (Exact_Record_Layout_Status) of Natural;

   type Exact_Record_Layout_Model is record
      Checks             : Info_Vectors.Vector;
      Status_Counts      : Counter_Array := (others => 0);
      Ok_Total           : Natural := 0;
      Size_Exact_Total   : Natural := 0;
      Size_Padded_Total  : Natural := 0;
      Size_Exceeded_Total : Natural := 0;
      Alignment_Compatible_Total : Natural := 0;
      Alignment_Error_Total : Natural := 0;
      Component_Error_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Record_Layout_Exact_Validation;
