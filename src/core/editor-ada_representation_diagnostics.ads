with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Aspect_Inheritance_Rules;
with Editor.Ada_Freezing_Interactions;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Operational_Attribute_Rules;
with Editor.Ada_Record_Layout_Exact_Validation;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Record_Storage_Order_Rules;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Selected_Representation_Targets;
with Editor.Ada_Stream_Attribute_Profile_Conformance;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Representation_Diagnostics is

   --  Projection-only diagnostics for representation, operational property,
   --  layout, storage-order, aspect-inheritance, and freezing-interaction
   --  metadata.  This package consumes already-built snapshot-owned semantic
   --  models and emits deterministic diagnostics.  It performs no parsing,
   --  file IO, editor mutation, command registration, or rendering work.

   type Representation_Diagnostic_Id is new Natural;
   No_Representation_Diagnostic : constant Representation_Diagnostic_Id := 0;

   type Representation_Diagnostic_Severity is
     (Representation_Diagnostic_Severity_Info,
      Representation_Diagnostic_Warning,
      Representation_Diagnostic_Error);

   type Representation_Diagnostic_Kind is
     (Representation_Diagnostic_Target_Unresolved,
      Representation_Diagnostic_Freeze_Order_Error,
      Representation_Diagnostic_Static_Value_Error,
      Representation_Diagnostic_Target_Kind_Mismatch,
      Representation_Diagnostic_Record_Component_Error,
      Representation_Diagnostic_Enumeration_Error,
      Representation_Diagnostic_Address_Error,
      Representation_Diagnostic_Size_Alignment_Storage_Error,
      Representation_Diagnostic_Interfacing_Error,
      Representation_Diagnostic_Stream_Profile_Error,
      Representation_Diagnostic_Stream_Target_Type_Error,
      Representation_Diagnostic_Stream_Handler_Missing,
      Representation_Diagnostic_Stream_Handler_Ambiguous,
      Representation_Diagnostic_Stream_Handler_Arity_Mismatch,
      Representation_Diagnostic_Stream_Handler_Result_Mismatch,
      Representation_Diagnostic_Stream_Handler_Mode_Mismatch,
      Representation_Diagnostic_Stream_Handler_Unknown,
      Representation_Diagnostic_Operational_Error,
      Representation_Diagnostic_Record_Layout_Overlap,
      Representation_Diagnostic_Record_Layout_Static_Error,
      Representation_Diagnostic_Record_Layout_Size_Exceeded,
      Representation_Diagnostic_Record_Layout_Size_Padded,
      Representation_Diagnostic_Record_Layout_Alignment_Error,
      Representation_Diagnostic_Record_Layout_Component_Error_Exact,
      Representation_Diagnostic_Storage_Order_Conflict,
      Representation_Diagnostic_Operational_Duplicate,
      Representation_Diagnostic_Operational_Conflict,
      Representation_Diagnostic_Aspect_Inheritance_Conflict,
      Representation_Diagnostic_Private_View_Freezing,
      Representation_Diagnostic_Generic_Instance_Freezing,
      Representation_Diagnostic_Selected_Target_Limited_View,
      Representation_Diagnostic_Selected_Target_Private_View,
      Representation_Diagnostic_Selected_Target_Prefix_Missing,
      Representation_Diagnostic_Selected_Target_Prefix_Ambiguous,
      Representation_Diagnostic_Selected_Target_Prefix_Overflow,
      Representation_Diagnostic_Selected_Target_Selector_Missing,
      Representation_Diagnostic_Selected_Target_Selector_Ambiguous,
      Representation_Diagnostic_Selected_Target_Unresolved,
      Representation_Diagnostic_Unknown);

   type Representation_Diagnostic_Info is record
      Id       : Representation_Diagnostic_Id := No_Representation_Diagnostic;
      Kind     : Representation_Diagnostic_Kind := Representation_Diagnostic_Unknown;
      Severity : Representation_Diagnostic_Severity := Representation_Diagnostic_Warning;
      Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Related_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Property_Name : Ada.Strings.Unbounded.Unbounded_String;
      Message  : Ada.Strings.Unbounded.Unbounded_String;
      Start_Line   : Positive := 1;
      Start_Column : Positive := 1;
      End_Line     : Positive := 1;
      End_Column   : Positive := 1;
      Fingerprint  : Natural := 0;
   end record;

   type Representation_Diagnostic_Model is private;

   procedure Clear (Model : in out Representation_Diagnostic_Model);

   function Build
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model)
      return Representation_Diagnostic_Model;

   function Build_With_Selected_Targets
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model)
      return Representation_Diagnostic_Model;

   function Build_With_Selected_Targets
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Points.Freezing_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model)
      return Representation_Diagnostic_Model;

   function Build_With_Exact_Layout
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Exact_Layout : Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model)
      return Representation_Diagnostic_Model;

   function Build_With_Selected_Targets_And_Exact_Layout
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model;
      Exact_Layout : Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model)
      return Representation_Diagnostic_Model;



   function Build_With_Stream_Profile_Conformance
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Stream_Profiles : Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model)
      return Representation_Diagnostic_Model;

   function Build_With_Selected_Targets_Exact_Layout_And_Stream_Profiles
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model;
      Exact_Layout : Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model;
      Stream_Profiles : Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model)
      return Representation_Diagnostic_Model;

   function Has_Diagnostics (Model : Representation_Diagnostic_Model) return Boolean;
   function Diagnostic_Count (Model : Representation_Diagnostic_Model) return Natural;
   function Diagnostic_At
     (Model : Representation_Diagnostic_Model;
      Index : Positive) return Representation_Diagnostic_Info;

   function Error_Count (Model : Representation_Diagnostic_Model) return Natural;
   function Warning_Count (Model : Representation_Diagnostic_Model) return Natural;
   function Info_Count (Model : Representation_Diagnostic_Model) return Natural;
   function Count_Kind
     (Model : Representation_Diagnostic_Model;
      Kind  : Representation_Diagnostic_Kind) return Natural;

   function Exact_Record_Layout_Diagnostic_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Exact_Record_Layout_Size_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Exact_Record_Layout_Alignment_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Exact_Record_Layout_Component_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural;



   function Stream_Profile_Conformance_Diagnostic_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Stream_Profile_Target_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Stream_Profile_Handler_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Stream_Profile_Mode_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Selected_Target_Diagnostic_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Selected_Target_Limited_View_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Selected_Target_Private_View_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Selected_Target_Missing_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Selected_Target_Ambiguous_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Selected_Target_Selector_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural;

   function Fingerprint (Model : Representation_Diagnostic_Model) return Natural;

private
   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Representation_Diagnostic_Info);

   type Representation_Diagnostic_Model is record
      Diagnostics        : Diagnostic_Vectors.Vector;
      Error_Total        : Natural := 0;
      Warning_Total      : Natural := 0;
      Info_Total         : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Diagnostics;
