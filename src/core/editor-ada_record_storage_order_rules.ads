with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Record_Storage_Order_Rules is

   --  Compiler-grade storage-order interaction foundation for record
   --  representation clauses.  The model consumes already staged
   --  representation-legality and record-layout metadata and records the
   --  deterministic interaction between component clauses, Bit_Order, and
   --  Scalar_Storage_Order.  It is projection metadata only and performs no
   --  parsing, file IO, rendering mutation, or diagnostic emission.

   type Storage_Order_Rule_Status is
     (Storage_Order_Rule_No_Explicit_Order,
      Storage_Order_Rule_Bit_Order_Applied,
      Storage_Order_Rule_Scalar_Storage_Order_Applied,
      Storage_Order_Rule_Bit_And_Scalar_Order_Applied,
      Storage_Order_Rule_Order_Conflict,
      Storage_Order_Rule_Operational_Error,
      Storage_Order_Rule_Layout_Error,
      Storage_Order_Rule_Unknown);

   type Storage_Order_Value is
     (Storage_Order_None,
      Storage_Order_High_Order_First,
      Storage_Order_Low_Order_First,
      Storage_Order_Unknown);

   type Storage_Order_Rule_Info is record
      Component_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Clause        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Bit_Order_Clause     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Scalar_Order_Clause  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Bit_Order            : Storage_Order_Value := Storage_Order_None;
      Scalar_Order         : Storage_Order_Value := Storage_Order_None;
      Layout_Status        : Editor.Ada_Record_Layout_Validation.Record_Layout_Status :=
        Editor.Ada_Record_Layout_Validation.Record_Layout_Unknown;
      Status               : Storage_Order_Rule_Status := Storage_Order_Rule_Unknown;
      Source_Line          : Positive := 1;
      Fingerprint          : Natural := 0;
   end record;

   type Storage_Order_Rule_Model is private;

   procedure Clear (Model : in out Storage_Order_Rule_Model);

   function Build
     (Legality : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout   : Editor.Ada_Record_Layout_Validation.Record_Layout_Model)
      return Storage_Order_Rule_Model;

   function Rule_Count (Model : Storage_Order_Rule_Model) return Natural;

   function Rule_At
     (Model : Storage_Order_Rule_Model;
      Index : Positive) return Storage_Order_Rule_Info;

   function Explicit_Order_Component_Count (Model : Storage_Order_Rule_Model) return Natural;
   function Bit_Order_Component_Count (Model : Storage_Order_Rule_Model) return Natural;
   function Scalar_Storage_Order_Component_Count (Model : Storage_Order_Rule_Model) return Natural;
   function Order_Conflict_Count (Model : Storage_Order_Rule_Model) return Natural;
   function Operational_Error_Count (Model : Storage_Order_Rule_Model) return Natural;
   function Layout_Error_Count (Model : Storage_Order_Rule_Model) return Natural;
   function Unknown_Count (Model : Storage_Order_Rule_Model) return Natural;
   function Fingerprint (Model : Storage_Order_Rule_Model) return Natural;

private
   package Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Storage_Order_Rule_Info);

   type Storage_Order_Rule_Model is record
      Rules                       : Rule_Vectors.Vector;
      Explicit_Order_Component_Total : Natural := 0;
      Bit_Order_Component_Total      : Natural := 0;
      Scalar_Order_Component_Total   : Natural := 0;
      Order_Conflict_Total          : Natural := 0;
      Operational_Error_Total       : Natural := 0;
      Layout_Error_Total            : Natural := 0;
      Unknown_Total                 : Natural := 0;
      Result_Fingerprint            : Natural := 0;
   end record;

end Editor.Ada_Record_Storage_Order_Rules;
