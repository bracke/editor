with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Record_Layout_Exact_Validation;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Stream_Attribute_Profile_Conformance;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Unit_Completion_Order_Legality;

package Editor.Ada_Representation_Layout_Stream_Integration_Legality is

   --  Pass1117 compiler-grade representation integration layer.  This package
   --  ties representation clauses/aspects, exact record layout checks, stream
   --  attribute handler conformance, generic-instance freezing effects,
   --  accessibility/lifetime constraints, staticness/range checks,
   --  completion/order legality, contract/aspect legality, and
   --  exception/finalization legality into one bounded snapshot-owned semantic
   --  result.  It performs no parsing, file IO, save/reload, dirty-state
   --  mutation, command/keybinding/workspace/render mutation, or compiler
   --  invocation.

   subtype Representation_Status is
     Editor.Ada_Representation_Legality.Representation_Legality_Status;
   subtype Exact_Layout_Status is
     Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Status;
   subtype Stream_Status is
     Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Status;
   subtype Generic_Instance_Status is
     Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Status;
   subtype Accessibility_Status is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;
   subtype Staticness_Status is
     Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status;
   subtype Completion_Status is
     Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Status;
   subtype Contract_Status is
     Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Status;
   subtype Exception_Status is
     Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Status;

   type Representation_Integration_Context_Id is new Natural;
   No_Representation_Integration_Context : constant Representation_Integration_Context_Id := 0;

   type Representation_Integration_Id is new Natural;
   No_Representation_Integration : constant Representation_Integration_Id := 0;

   type Representation_Integration_Context_Kind is
     (Representation_Context_Clause,
      Representation_Context_Aspect,
      Representation_Context_Record_Layout,
      Representation_Context_Variant_Record_Layout,
      Representation_Context_Stream_Attribute,
      Representation_Context_Operational_Attribute,
      Representation_Context_Address_Clause,
      Representation_Context_Size_Alignment,
      Representation_Context_Convention_Import_Export,
      Representation_Context_Generic_Instance_Effect,
      Representation_Context_Controlled_Finalization_Effect,
      Representation_Context_Unknown);

   type Layout_State is
     (Layout_None,
      Layout_Exact,
      Layout_Padded,
      Layout_Size_Exceeded,
      Layout_Alignment_Compatible,
      Layout_Alignment_Error,
      Layout_Component_Error,
      Layout_Variant_Hole,
      Layout_Variant_Overlap,
      Layout_Discriminant_Error,
      Layout_Unknown);

   type Stream_State is
     (Stream_None,
      Stream_Profile_Compatible,
      Stream_Handler_Missing,
      Stream_Handler_Malformed,
      Stream_Handler_Ambiguous,
      Stream_Profile_Mismatch,
      Stream_Result_Mismatch,
      Stream_Mode_Mismatch,
      Stream_Target_Error,
      Stream_Profile_Unknown,
      Stream_Unknown);

   type Representation_Integration_Status is
     (Representation_Integration_Not_Checked,
      Representation_Integration_Legal_Representation_Item,
      Representation_Integration_Legal_Record_Layout,
      Representation_Integration_Legal_Stream_Attribute,
      Representation_Integration_Legal_Operational_Attribute,
      Representation_Integration_Legal_Convention,
      Representation_Integration_Legal_Generic_Instance_Effect,
      Representation_Integration_Legal_Finalization_Effect,
      Representation_Integration_Target_Unresolved,
      Representation_Integration_Target_Ambiguous,
      Representation_Integration_Target_Kind_Mismatch,
      Representation_Integration_After_Freezing,
      Representation_Integration_Static_Value_Error,
      Representation_Integration_Address_Error,
      Representation_Integration_Convention_Error,
      Representation_Integration_Operational_Error,
      Representation_Integration_Record_Size_Exceeded,
      Representation_Integration_Record_Padded,
      Representation_Integration_Record_Alignment_Error,
      Representation_Integration_Record_Component_Error,
      Representation_Integration_Variant_Layout_Hole,
      Representation_Integration_Variant_Layout_Overlap,
      Representation_Integration_Discriminant_Layout_Error,
      Representation_Integration_Stream_Handler_Missing,
      Representation_Integration_Stream_Handler_Malformed,
      Representation_Integration_Stream_Handler_Ambiguous,
      Representation_Integration_Stream_Profile_Mismatch,
      Representation_Integration_Stream_Result_Mismatch,
      Representation_Integration_Stream_Mode_Mismatch,
      Representation_Integration_Stream_Profile_Unknown,
      Representation_Integration_Generic_Instance_Freezing_Error,
      Representation_Integration_Generic_Instance_Representation_Error,
      Representation_Integration_Accessibility_Error,
      Representation_Integration_Staticness_Error,
      Representation_Integration_Completion_Order_Error,
      Representation_Integration_Contract_Error,
      Representation_Integration_Exception_Finalization_Error,
      Representation_Integration_Private_View_Barrier,
      Representation_Integration_Limited_View_Barrier,
      Representation_Integration_Cross_Unit_Unresolved,
      Representation_Integration_Indeterminate);

   type Representation_Integration_Context_Info is record
      Id                  : Representation_Integration_Context_Id :=
        No_Representation_Integration_Context;
      Kind                : Representation_Integration_Context_Kind :=
        Representation_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Handler_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Layout_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target   : Ada.Strings.Unbounded.Unbounded_String;
      Handler_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Layout              : Layout_State := Layout_None;
      Stream              : Stream_State := Stream_None;
      Representation      : Representation_Status :=
        Editor.Ada_Representation_Legality.Representation_Legality_Ok;
      Exact_Layout        : Exact_Layout_Status :=
        Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Unknown;
      Stream_Profile      : Stream_Status :=
        Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Unknown;
      Generic_Instance    : Generic_Instance_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Accessibility       : Accessibility_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Staticness          : Staticness_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Completion          : Completion_Status :=
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked;
      Contract            : Contract_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Exception_Finalization : Exception_Status :=
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Not_Checked;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Cross_Unit_Unresolved : Boolean := False;
      Variant_Hole        : Boolean := False;
      Variant_Overlap     : Boolean := False;
      Discriminant_Error  : Boolean := False;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
   end record;

   type Representation_Integration_Info is record
      Id                  : Representation_Integration_Id := No_Representation_Integration;
      Context             : Representation_Integration_Context_Id :=
        No_Representation_Integration_Context;
      Kind                : Representation_Integration_Context_Kind :=
        Representation_Context_Unknown;
      Status              : Representation_Integration_Status :=
        Representation_Integration_Not_Checked;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Handler_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Layout_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target   : Ada.Strings.Unbounded.Unbounded_String;
      Handler_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Layout              : Layout_State := Layout_None;
      Stream              : Stream_State := Stream_None;
      Representation      : Representation_Status :=
        Editor.Ada_Representation_Legality.Representation_Legality_Ok;
      Exact_Layout        : Exact_Layout_Status :=
        Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Unknown;
      Stream_Profile      : Stream_Status :=
        Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Unknown;
      Generic_Instance    : Generic_Instance_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Accessibility       : Accessibility_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Staticness          : Staticness_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Completion          : Completion_Status :=
        Editor.Ada_Unit_Completion_Order_Legality.Completion_Legality_Not_Checked;
      Contract            : Contract_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Exception_Finalization : Exception_Status :=
        Editor.Ada_Exception_Finalization_Legality.Exception_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Representation_Integration_Context_Model is private;
   type Representation_Integration_Result_Set is private;
   type Representation_Integration_Model is private;

   procedure Clear (Model : in out Representation_Integration_Context_Model);
   procedure Add_Context
     (Model : in out Representation_Integration_Context_Model;
      Info  : Representation_Integration_Context_Info);

   function Context_Count
     (Model : Representation_Integration_Context_Model) return Natural;
   function Context_At
     (Model : Representation_Integration_Context_Model;
      Index : Positive) return Representation_Integration_Context_Info;
   function Fingerprint
     (Model : Representation_Integration_Context_Model) return Natural;

   function Build
     (Contexts : Representation_Integration_Context_Model)
      return Representation_Integration_Model;

   function Legality_Count
     (Model : Representation_Integration_Model) return Natural;
   function Legality_At
     (Model : Representation_Integration_Model;
      Index : Positive) return Representation_Integration_Info;

   function First_For_Node
     (Model : Representation_Integration_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Integration_Info;
   function Rows_For_Status
     (Model  : Representation_Integration_Model;
      Status : Representation_Integration_Status)
      return Representation_Integration_Result_Set;
   function Rows_For_Kind
     (Model : Representation_Integration_Model;
      Kind  : Representation_Integration_Context_Kind)
      return Representation_Integration_Result_Set;
   function Rows_For_Target
     (Model  : Representation_Integration_Model;
      Target : Ada.Strings.Unbounded.Unbounded_String)
      return Representation_Integration_Result_Set;
   function Rows_For_Layout
     (Model : Representation_Integration_Model;
      State : Layout_State) return Representation_Integration_Result_Set;
   function Rows_For_Stream
     (Model : Representation_Integration_Model;
      State : Stream_State) return Representation_Integration_Result_Set;

   function Result_Count
     (Set : Representation_Integration_Result_Set) return Natural;
   function Result_At
     (Set   : Representation_Integration_Result_Set;
      Index : Positive) return Representation_Integration_Info;

   function Legal_Count (Model : Representation_Integration_Model) return Natural;
   function Error_Count (Model : Representation_Integration_Model) return Natural;
   function Layout_Error_Count (Model : Representation_Integration_Model) return Natural;
   function Stream_Error_Count (Model : Representation_Integration_Model) return Natural;
   function Freezing_Error_Count (Model : Representation_Integration_Model) return Natural;
   function View_Barrier_Count (Model : Representation_Integration_Model) return Natural;
   function Linked_Error_Count (Model : Representation_Integration_Model) return Natural;
   function Indeterminate_Count (Model : Representation_Integration_Model) return Natural;
   function Count_Status
     (Model  : Representation_Integration_Model;
      Status : Representation_Integration_Status) return Natural;
   function Count_Kind
     (Model : Representation_Integration_Model;
      Kind  : Representation_Integration_Context_Kind) return Natural;
   function Count_Layout
     (Model : Representation_Integration_Model;
      State : Layout_State) return Natural;
   function Count_Stream
     (Model : Representation_Integration_Model;
      State : Stream_State) return Natural;
   function Fingerprint (Model : Representation_Integration_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Integration_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Integration_Info);

   type Representation_Integration_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Representation_Integration_Result_Set is record
      Results : Result_Vectors.Vector;
   end record;

   type Representation_Integration_Model is record
      Rows        : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Layout_Stream_Integration_Legality;
