with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Language_Model;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;

package Editor.Ada_Representation_Legality is

   --  Compiler-grade representation legality foundation.  The model folds
   --  parser-owned representation clauses together with the freezing-point,
   --  static-expression, and type-graph models.  It intentionally produces
   --  conservative, deterministic classifications rather than mutating the
   --  language model or issuing diagnostics directly.

   type Representation_Legality_Status is
     (Representation_Legality_Ok,
      Representation_Legality_Target_Unresolved,
      Representation_Legality_Target_Ambiguous,
      Representation_Legality_Target_Not_Freezable,
      Representation_Legality_After_Freezing,
      Representation_Legality_At_Freezing_Point,
      Representation_Legality_Static_Value_Required,
      Representation_Legality_Static_Value_Malformed,
      Representation_Legality_Static_Value_Division_By_Zero,
      Representation_Legality_Static_Value_Not_Positive,
      Representation_Legality_Target_Kind_Mismatch,
      Representation_Legality_Record_Component_Unresolved,
      Representation_Legality_Record_Component_Duplicate,
      Representation_Legality_Record_Component_Static_Value_Required,
      Representation_Legality_Record_Component_Bit_Range_Reversed,
      Representation_Legality_Record_Component_Negative_Position,
      Representation_Legality_Enumeration_Target_Not_Enumeration,
      Representation_Legality_Enumeration_Literal_Unresolved,
      Representation_Legality_Enumeration_Literal_Duplicate,
      Representation_Legality_Enumeration_Value_Static_Required,
      Representation_Legality_Enumeration_Value_Duplicate,
      Representation_Legality_Enumeration_Value_Order,
      Representation_Legality_Enumeration_Incomplete,
      Representation_Legality_Address_Target_Incompatible,
      Representation_Legality_Address_Value_Null_Not_Allowed,
      Representation_Legality_Address_Value_Not_Static_Address,
      Representation_Legality_Address_Value_Incompatible,
      Representation_Legality_Address_Value_Malformed,
      Representation_Legality_Size_Target_Incompatible,
      Representation_Legality_Alignment_Target_Incompatible,
      Representation_Legality_Storage_Size_Target_Incompatible,
      Representation_Legality_Static_Value_Not_Integer,
      Representation_Legality_Interfacing_Target_Incompatible,
      Representation_Legality_Convention_Identifier_Required,
      Representation_Legality_Convention_Identifier_Unknown,
      Representation_Legality_Import_Export_Boolean_Value_Required,
      Representation_Legality_Link_Name_String_Value_Required,
      Representation_Legality_Import_Export_Conflict,
      Representation_Legality_Link_Name_Requires_Import_Export,
      Representation_Legality_Stream_Target_Incompatible,
      Representation_Legality_Stream_Subprogram_Required,
      Representation_Legality_Stream_Subprogram_Malformed,
      Representation_Legality_Stream_Subprogram_Profile_Unknown,
      Representation_Legality_Stream_Subprogram_Profile_Mismatch,
      Representation_Legality_Operational_Target_Incompatible,
      Representation_Legality_Operational_Boolean_Value_Required,
      Representation_Legality_Operational_Order_Value_Required,
      Representation_Legality_Unknown);

   type Address_Value_Status is
     (Address_Value_Not_Address_Clause,
      Address_Value_Static_Address,
      Address_Value_Null_Literal,
      Address_Value_Raw_Literal,
      Address_Value_Non_Static_Name,
      Address_Value_Malformed,
      Address_Value_Unknown);

   type Interfacing_Value_Status is
     (Interfacing_Value_Not_Interfacing_Clause,
      Interfacing_Value_Convention_Identifier,
      Interfacing_Value_Convention_Unknown_Identifier,
      Interfacing_Value_Static_Boolean_True,
      Interfacing_Value_Static_Boolean_False,
      Interfacing_Value_Static_String,
      Interfacing_Value_Malformed,
      Interfacing_Value_Unknown);

   type Stream_Subprogram_Status is
     (Stream_Subprogram_Not_Stream_Clause,
      Stream_Subprogram_Designator,
      Stream_Subprogram_Profile_Known_Compatible,
      Stream_Subprogram_Profile_Known_Mismatch,
      Stream_Subprogram_Profile_Unknown,
      Stream_Subprogram_Malformed,
      Stream_Subprogram_Unknown);

   type Operational_Value_Status is
     (Operational_Value_Not_Operational_Clause,
      Operational_Value_Static_Boolean_True,
      Operational_Value_Static_Boolean_False,
      Operational_Value_Order_High_Order_First,
      Operational_Value_Order_Low_Order_First,
      Operational_Value_Malformed,
      Operational_Value_Unknown);

   type Representation_Value_Status is
     (Representation_Value_Not_Required,
      Representation_Value_Static_Integer,
      Representation_Value_Static_Real,
      Representation_Value_Non_Static,
      Representation_Value_Malformed,
      Representation_Value_Division_By_Zero,
      Representation_Value_Unresolved,
      Representation_Value_Unsupported);

   type Representation_Legality_Info is record
      Clause_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target : Ada.Strings.Unbounded.Unbounded_String;
      Clause_Kind       : Editor.Ada_Language_Model.Representation_Clause_Kind :=
        Editor.Ada_Language_Model.Representation_Other_Clause;
      Source_Form       : Editor.Ada_Language_Model.Representation_Source_Form :=
        Editor.Ada_Language_Model.Representation_Source_Attribute_Definition;
      Item_Text         : Ada.Strings.Unbounded.Unbounded_String;
      Target            : Editor.Ada_Freezing_Points.Freezable_Id :=
        Editor.Ada_Freezing_Points.No_Freezable;
      Target_Freezable_Kind : Editor.Ada_Freezing_Points.Freezable_Kind :=
        Editor.Ada_Freezing_Points.Freezable_Unknown;
      Target_Type       : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Target_Category   : Editor.Ada_Type_Graph.Type_Category :=
        Editor.Ada_Type_Graph.Type_Category_Unknown;
      Freeze_Status     : Editor.Ada_Freezing_Points.Representation_Freezing_Status :=
        Editor.Ada_Freezing_Points.Representation_Target_Unresolved;
      Value_Status      : Representation_Value_Status := Representation_Value_Not_Required;
      Address_Status    : Address_Value_Status := Address_Value_Not_Address_Clause;
      Interfacing_Status : Interfacing_Value_Status := Interfacing_Value_Not_Interfacing_Clause;
      Stream_Status      : Stream_Subprogram_Status := Stream_Subprogram_Not_Stream_Clause;
      Stream_Designator  : Ada.Strings.Unbounded.Unbounded_String;
      Operational_Status : Operational_Value_Status := Operational_Value_Not_Operational_Clause;
      Convention_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Static_Integer    : Long_Long_Integer := 0;
      Static_Real       : Long_Float := 0.0;
      Status            : Representation_Legality_Status := Representation_Legality_Unknown;
      Source_Line       : Positive := 1;
      Fingerprint       : Natural := 0;
   end record;


   type Record_Component_Legality_Info is record
      Clause_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Clause     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Component : Ada.Strings.Unbounded.Unbounded_String;
      Storage_Unit_Text : Ada.Strings.Unbounded.Unbounded_String;
      First_Bit_Text    : Ada.Strings.Unbounded.Unbounded_String;
      Last_Bit_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Storage_Value_Status : Representation_Value_Status := Representation_Value_Not_Required;
      First_Bit_Value_Status : Representation_Value_Status := Representation_Value_Not_Required;
      Last_Bit_Value_Status  : Representation_Value_Status := Representation_Value_Not_Required;
      Static_Storage_Unit : Long_Long_Integer := 0;
      Static_First_Bit    : Long_Long_Integer := 0;
      Static_Last_Bit     : Long_Long_Integer := 0;
      Status            : Representation_Legality_Status := Representation_Legality_Unknown;
      Source_Line       : Positive := 1;
      Fingerprint       : Natural := 0;
   end record;


   type Enumeration_Representation_Legality_Info is record
      Clause_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Clause     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Literal_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Literal : Ada.Strings.Unbounded.Unbounded_String;
      Value_Text        : Ada.Strings.Unbounded.Unbounded_String;
      Value_Status      : Representation_Value_Status := Representation_Value_Not_Required;
      Static_Value      : Long_Long_Integer := 0;
      Expected_Position : Natural := 0;
      Status            : Representation_Legality_Status := Representation_Legality_Unknown;
      Source_Line       : Positive := 1;
      Fingerprint       : Natural := 0;
   end record;

   type Representation_Legality_Model is private;

   procedure Clear (Model : in out Representation_Legality_Model);

   function Build
     (Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions  : Editor.Ada_Declarative_Regions.Region_Model;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Freezing : Editor.Ada_Freezing_Points.Freezing_Model)
      return Representation_Legality_Model;

   function Build_With_Stream_Profiles
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Freezing   : Editor.Ada_Freezing_Points.Freezing_Model;
      Profiles   : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model)
      return Representation_Legality_Model;


   function Check_Count (Model : Representation_Legality_Model) return Natural;

   function Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Representation_Legality_Info;

   function Check_For_Clause
     (Model  : Representation_Legality_Model;
      Clause : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Legality_Info;

   function Record_Component_Check_Count
     (Model : Representation_Legality_Model) return Natural;

   function Record_Component_Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Record_Component_Legality_Info;

   function Enumeration_Representation_Check_Count
     (Model : Representation_Legality_Model) return Natural;

   function Enumeration_Representation_Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Enumeration_Representation_Legality_Info;

   function Ok_Count (Model : Representation_Legality_Model) return Natural;
   function Error_Count (Model : Representation_Legality_Model) return Natural;
   function Static_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Target_Kind_Mismatch_Count (Model : Representation_Legality_Model) return Natural;
   function After_Freezing_Count (Model : Representation_Legality_Model) return Natural;
   function Record_Component_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Record_Component_Duplicate_Count (Model : Representation_Legality_Model) return Natural;
   function Record_Component_Static_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Enumeration_Representation_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Enumeration_Representation_Duplicate_Literal_Count (Model : Representation_Legality_Model) return Natural;
   function Enumeration_Representation_Duplicate_Value_Count (Model : Representation_Legality_Model) return Natural;
   function Enumeration_Representation_Static_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Enumeration_Representation_Incomplete_Count (Model : Representation_Legality_Model) return Natural;
   function Address_Target_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Address_Value_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Address_Static_Value_Count (Model : Representation_Legality_Model) return Natural;
   function Size_Alignment_Storage_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Size_Alignment_Storage_Static_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Interfacing_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Interfacing_Target_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Interfacing_Value_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Import_Export_Conflict_Count (Model : Representation_Legality_Model) return Natural;
   function Link_Name_Requires_Import_Export_Count (Model : Representation_Legality_Model) return Natural;
   function Stream_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Stream_Target_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Stream_Profile_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Stream_Profile_Unknown_Count (Model : Representation_Legality_Model) return Natural;
   function Operational_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Operational_Target_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Operational_Value_Error_Count (Model : Representation_Legality_Model) return Natural;
   function Operational_Static_Boolean_Count (Model : Representation_Legality_Model) return Natural;
   function Operational_Order_Value_Count (Model : Representation_Legality_Model) return Natural;
   function Aspect_Source_Count (Model : Representation_Legality_Model) return Natural;
   function Attribute_Definition_Source_Count (Model : Representation_Legality_Model) return Natural;
   function Unified_Property_Count (Model : Representation_Legality_Model) return Natural;
   function Fingerprint (Model : Representation_Legality_Model) return Natural;

private
   package Check_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Legality_Info);

   package Record_Component_Check_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Record_Component_Legality_Info);

   package Enumeration_Check_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Enumeration_Representation_Legality_Info);

   type Representation_Legality_Model is record
      Checks             : Check_Vectors.Vector;
      Component_Checks   : Record_Component_Check_Vectors.Vector;
      Enumeration_Checks : Enumeration_Check_Vectors.Vector;
      Ok_Total           : Natural := 0;
      Error_Total        : Natural := 0;
      Static_Error_Total : Natural := 0;
      Kind_Error_Total   : Natural := 0;
      Freeze_Error_Total : Natural := 0;
      Component_Error_Total : Natural := 0;
      Component_Duplicate_Total : Natural := 0;
      Component_Static_Error_Total : Natural := 0;
      Enumeration_Error_Total : Natural := 0;
      Enumeration_Duplicate_Literal_Total : Natural := 0;
      Enumeration_Duplicate_Value_Total : Natural := 0;
      Enumeration_Static_Error_Total : Natural := 0;
      Enumeration_Incomplete_Total : Natural := 0;
      Address_Target_Error_Total : Natural := 0;
      Address_Value_Error_Total : Natural := 0;
      Address_Static_Value_Total : Natural := 0;
      Size_Alignment_Storage_Error_Total : Natural := 0;
      Size_Alignment_Storage_Static_Error_Total : Natural := 0;
      Interfacing_Error_Total : Natural := 0;
      Interfacing_Target_Error_Total : Natural := 0;
      Interfacing_Value_Error_Total : Natural := 0;
      Import_Export_Conflict_Total : Natural := 0;
      Link_Name_Requires_Import_Export_Total : Natural := 0;
      Stream_Error_Total : Natural := 0;
      Stream_Target_Error_Total : Natural := 0;
      Stream_Profile_Error_Total : Natural := 0;
      Stream_Profile_Unknown_Total : Natural := 0;
      Operational_Error_Total : Natural := 0;
      Operational_Target_Error_Total : Natural := 0;
      Operational_Value_Error_Total : Natural := 0;
      Operational_Static_Boolean_Total : Natural := 0;
      Operational_Order_Value_Total : Natural := 0;
      Aspect_Source_Total : Natural := 0;
      Attribute_Definition_Source_Total : Natural := 0;
      Unified_Property_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Legality;
