with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;

package Editor.Ada_Expression_Types.Status_Helpers is

   function Trim (Text : String) return String;

   function Normalize (Text : String) return String;

   function Contains (Text : String; Pattern : String) return Boolean;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural;

   function Hash_Text (Text : String) return Natural;

   function Conditional_Status_Text
     (Status : Editor.Ada_Expression_Types.Conditional_Type_Inference_Status)
      return String;

   function Membership_Range_Status_Text
     (Status : Editor.Ada_Expression_Types.Membership_Range_Inference_Status)
      return String;

   function Target_Name_Status_Text
     (Status : Editor.Ada_Expression_Types.Target_Name_Inference_Status)
      return String;

   function Indexed_Slice_Status_Text
     (Status : Editor.Ada_Expression_Types.Indexed_Slice_Inference_Status)
      return String;

   function Boolean_Context_Status_Text
     (Status : Editor.Ada_Expression_Types.Boolean_Context_Inference_Status)
      return String;

   function Raise_No_Return_Status_Text
     (Status : Editor.Ada_Expression_Types.Raise_No_Return_Inference_Status)
      return String;

   function Allocator_Status_Text
     (Status : Editor.Ada_Expression_Types.Allocator_Type_Inference_Status)
      return String;

   function Universal_Numeric_Status_Text
     (Status : Editor.Ada_Expression_Types.Universal_Numeric_Resolution_Status)
      return String;

   function Dispatching_Call_Status_Text
     (Status : Editor.Ada_Expression_Types.Dispatching_Call_Inference_Status)
      return String;

   function Call_Actual_Type_Status_Text
     (Status : Editor.Ada_Expression_Types.Call_Actual_Type_Resolution_Status)
      return String;

   function Parameter_Association_Status_Text
     (Status : Editor.Ada_Expression_Types.Parameter_Association_Inference_Status)
      return String;

   function Dereference_Access_Status_Text
     (Status : Editor.Ada_Expression_Types.Dereference_Access_Inference_Status)
      return String;

   function Attribute_Status_Text
     (Status : Editor.Ada_Expression_Types.Attribute_Type_Inference_Status)
      return String;

   function Operator_Status_Text
     (Status : Editor.Ada_Expression_Types.Operator_Type_Inference_Status)
      return String;

   function Concatenation_Status_Text
     (Status : Editor.Ada_Expression_Types.Concatenation_Type_Inference_Status)
      return String;

   function Aggregate_Status_Text
     (Status : Editor.Ada_Expression_Types.Aggregate_Type_Inference_Status)
      return String;

   function Conversion_Status_Text
     (Status : Editor.Ada_Expression_Types.Conversion_Type_Inference_Status)
      return String;

   function Expected_Status_Text
     (Status : Editor.Ada_Expression_Types.Expected_Type_Propagation_Status)
      return String;

   function Status_Text
     (Status : Editor.Ada_Expression_Types.Expression_Type_Status) return String;

end Editor.Ada_Expression_Types.Status_Helpers;
