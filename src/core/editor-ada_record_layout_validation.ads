with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Record_Layout_Validation is

   --  Compiler-grade record-layout validation layer.  This model consumes the
   --  parser-owned representation-legality model and derives deterministic
   --  physical bit-span checks for record component clauses.  It is projection
   --  metadata only: it performs no parsing, file IO, rendering mutation, or
   --  diagnostic emission.

   type Record_Layout_Status is
     (Record_Layout_Ok,
      Record_Layout_Overlap,
      Record_Layout_Static_Error,
      Record_Layout_Component_Error,
      Record_Layout_Size_Exceeded,
      Record_Layout_Alignment_Warning,
      Record_Layout_Unknown);

   type Record_Layout_Info is record
      Component_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Clause        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Start_Bit            : Long_Long_Integer := 0;
      End_Bit              : Long_Long_Integer := 0;
      Overlap_Component    : Ada.Strings.Unbounded.Unbounded_String;
      Overlap_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status               : Record_Layout_Status := Record_Layout_Unknown;
      Source_Line          : Positive := 1;
      Fingerprint          : Natural := 0;
   end record;

   type Record_Layout_Model is private;

   procedure Clear (Model : in out Record_Layout_Model);

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model)
      return Record_Layout_Model;

   function Check_Count (Model : Record_Layout_Model) return Natural;

   function Check_At
     (Model : Record_Layout_Model;
      Index : Positive) return Record_Layout_Info;

   function Overlap_Count (Model : Record_Layout_Model) return Natural;
   function Valid_Span_Count (Model : Record_Layout_Model) return Natural;
   function Static_Error_Count (Model : Record_Layout_Model) return Natural;
   function Component_Error_Count (Model : Record_Layout_Model) return Natural;
   function Size_Exceeded_Count (Model : Record_Layout_Model) return Natural;
   function Alignment_Warning_Count (Model : Record_Layout_Model) return Natural;
   function Fingerprint (Model : Record_Layout_Model) return Natural;

private
   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Record_Layout_Info);

   type Record_Layout_Model is record
      Checks                  : Check_Vectors.Vector;
      Overlap_Total           : Natural := 0;
      Valid_Span_Total        : Natural := 0;
      Static_Error_Total      : Natural := 0;
      Component_Error_Total   : Natural := 0;
      Size_Exceeded_Total     : Natural := 0;
      Alignment_Warning_Total : Natural := 0;
      Result_Fingerprint      : Natural := 0;
   end record;

end Editor.Ada_Record_Layout_Validation;
