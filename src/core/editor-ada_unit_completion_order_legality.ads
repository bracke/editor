with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Elaboration_Dependence_Legality;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Unit_Completion_Order_Legality is

   --  Pass1114 compiler-grade unit completion and declaration-order layer.
   --  This package checks bounded, snapshot-owned metadata for package/body,
   --  subprogram/body, private declaration, completion, and before-use legality.
   --  It deliberately performs no parsing, file IO, command routing, rendering, or
   --  workspace mutation.  Callers provide immutable semantic facts collected by
   --  earlier compiler-grade building blocks.

   subtype Cross_Unit_Semantic_Status is
     Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Status;
   subtype Contract_Legality_Status is
     Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Status;
   subtype Elaboration_Legality_Status is
     Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Status;
   subtype Instance_Legality_Status is
     Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Status;
   subtype Accessibility_Legality_Status is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;

   type Completion_Context_Id is new Natural;
   No_Completion_Context : constant Completion_Context_Id := 0;

   type Completion_Legality_Id is new Natural;
   No_Completion_Legality : constant Completion_Legality_Id := 0;

   type Unit_Completion_Kind is
     (Completion_Context_Package_Body,
      Completion_Context_Subprogram_Body,
      Completion_Context_Task_Body,
      Completion_Context_Protected_Body,
      Completion_Context_Generic_Body,
      Completion_Context_Private_Type_Completion,
      Completion_Context_Private_Extension_Completion,
      Completion_Context_Deferred_Constant_Completion,
      Completion_Context_Incomplete_Type_Completion,
      Completion_Context_Body_Stub_Completion,
      Completion_Context_Separate_Body_Completion,
      Completion_Context_Declaration_Before_Use,
      Completion_Context_Private_Part_Ordering,
      Completion_Context_Body_Declaration_Order,
      Completion_Context_Unknown);

   type Completion_Subject_Kind is
     (Completion_Subject_Package,
      Completion_Subject_Subprogram,
      Completion_Subject_Task,
      Completion_Subject_Protected,
      Completion_Subject_Generic,
      Completion_Subject_Type,
      Completion_Subject_Object,
      Completion_Subject_Body_Stub,
      Completion_Subject_Separate,
      Completion_Subject_Declaration,
      Completion_Subject_Unknown);

   type Completion_Relation_State is
     (Completion_Relation_None,
      Completion_Relation_Matched,
      Completion_Relation_Missing_Body,
      Completion_Relation_Duplicate_Body,
      Completion_Relation_Ambiguous_Body,
      Completion_Relation_Kind_Mismatch,
      Completion_Relation_Profile_Mismatch,
      Completion_Relation_Mode_Mismatch,
      Completion_Relation_Result_Mismatch,
      Completion_Relation_Generic_Formal_Mismatch,
      Completion_Relation_Separate_Parent_Missing,
      Completion_Relation_Separate_Parent_Ambiguous,
      Completion_Relation_Unknown);

   type Completion_Order_State is
     (Completion_Order_Known_Before,
      Completion_Order_Known_After,
      Completion_Order_Same_Declaration,
      Completion_Order_Private_Part_Before_Full_View,
      Completion_Order_Full_View_Before_Private_View,
      Completion_Order_Body_Before_Spec,
      Completion_Order_Use_Before_Declaration,
      Completion_Order_Use_Before_Full_View,
      Completion_Order_Use_Before_Completion,
      Completion_Order_Frozen_Before_Completion,
      Completion_Order_Unknown);

   type Completion_Visibility_State is
     (Completion_Visibility_Local,
      Completion_Visibility_Spec_Visible,
      Completion_Visibility_Private_Part_Visible,
      Completion_Visibility_Body_Only,
      Completion_Visibility_With_Visible,
      Completion_Visibility_Use_Visible,
      Completion_Visibility_Limited_View,
      Completion_Visibility_Private_View,
      Completion_Visibility_Missing,
      Completion_Visibility_Ambiguous,
      Completion_Visibility_Unknown);

   type Completion_Legality_Status is
     (Completion_Legality_Not_Checked,
      Completion_Legality_Legal_Unit_Body,
      Completion_Legality_Legal_Subprogram_Body,
      Completion_Legality_Legal_Task_Body,
      Completion_Legality_Legal_Protected_Body,
      Completion_Legality_Legal_Generic_Body,
      Completion_Legality_Legal_Private_Type_Completion,
      Completion_Legality_Legal_Deferred_Constant_Completion,
      Completion_Legality_Legal_Incomplete_Type_Completion,
      Completion_Legality_Legal_Body_Stub_Completion,
      Completion_Legality_Legal_Declaration_Order,
      Completion_Legality_Missing_Body,
      Completion_Legality_Duplicate_Body,
      Completion_Legality_Ambiguous_Body,
      Completion_Legality_Body_Kind_Mismatch,
      Completion_Legality_Profile_Mismatch,
      Completion_Legality_Mode_Mismatch,
      Completion_Legality_Result_Mismatch,
      Completion_Legality_Generic_Formal_Mismatch,
      Completion_Legality_Private_Type_Not_Completed,
      Completion_Legality_Private_Extension_Not_Completed,
      Completion_Legality_Deferred_Constant_Not_Completed,
      Completion_Legality_Incomplete_Type_Not_Completed,
      Completion_Legality_Body_Stub_Not_Completed,
      Completion_Legality_Separate_Parent_Missing,
      Completion_Legality_Separate_Parent_Ambiguous,
      Completion_Legality_Body_Before_Spec,
      Completion_Legality_Use_Before_Declaration,
      Completion_Legality_Use_Before_Full_View,
      Completion_Legality_Use_Before_Completion,
      Completion_Legality_Frozen_Before_Completion,
      Completion_Legality_Private_Part_Order_Error,
      Completion_Legality_Limited_View_Barrier,
      Completion_Legality_Private_View_Barrier,
      Completion_Legality_Missing_Visible_Declaration,
      Completion_Legality_Ambiguous_Visible_Declaration,
      Completion_Legality_Linked_Cross_Unit_Error,
      Completion_Legality_Linked_Contract_Error,
      Completion_Legality_Linked_Elaboration_Error,
      Completion_Legality_Linked_Generic_Instance_Error,
      Completion_Legality_Linked_Accessibility_Error,
      Completion_Legality_Indeterminate);

   type Completion_Context_Info is record
      Id                    : Completion_Context_Id := No_Completion_Context;
      Kind                  : Unit_Completion_Kind := Completion_Context_Unknown;
      Subject               : Completion_Subject_Kind := Completion_Subject_Unknown;
      Relation              : Completion_Relation_State := Completion_Relation_Unknown;
      Order                 : Completion_Order_State := Completion_Order_Unknown;
      Visibility            : Completion_Visibility_State := Completion_Visibility_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Spec_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Declaration_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Completion_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Use_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Requires_Body         : Boolean := False;
      Body_Present          : Boolean := True;
      Requires_Completion   : Boolean := False;
      Completion_Present    : Boolean := True;
      Duplicate_Body        : Boolean := False;
      Ambiguous_Body        : Boolean := False;
      Body_Kind_Mismatch    : Boolean := False;
      Profile_Mismatch      : Boolean := False;
      Mode_Mismatch         : Boolean := False;
      Result_Mismatch       : Boolean := False;
      Generic_Formal_Mismatch : Boolean := False;
      Private_Type          : Boolean := False;
      Private_Extension     : Boolean := False;
      Deferred_Constant     : Boolean := False;
      Incomplete_Type       : Boolean := False;
      Body_Stub             : Boolean := False;
      Separate_Body         : Boolean := False;
      Frozen_Before_Completion : Boolean := False;
      Cross_Unit_Status     : Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Contract_Status       : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Elaboration_Status    : Elaboration_Legality_Status :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked;
      Instance_Status       : Instance_Legality_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Accessibility_Status  : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Completion_Legality_Info is record
      Id                    : Completion_Legality_Id := No_Completion_Legality;
      Context               : Completion_Context_Id := No_Completion_Context;
      Kind                  : Unit_Completion_Kind := Completion_Context_Unknown;
      Subject               : Completion_Subject_Kind := Completion_Subject_Unknown;
      Relation              : Completion_Relation_State := Completion_Relation_Unknown;
      Order                 : Completion_Order_State := Completion_Order_Unknown;
      Visibility            : Completion_Visibility_State := Completion_Visibility_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Spec_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Declaration_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Completion_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Use_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Status                : Completion_Legality_Status := Completion_Legality_Not_Checked;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Status     : Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Contract_Status       : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Elaboration_Status    : Elaboration_Legality_Status :=
        Editor.Ada_Elaboration_Dependence_Legality.Elaboration_Legality_Not_Checked;
      Instance_Status       : Instance_Legality_Status :=
        Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Not_Checked;
      Accessibility_Status  : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Completion_Context_Model is private;
   type Completion_Result_Set is private;
   type Completion_Legality_Model is private;

   procedure Clear (Model : in out Completion_Context_Model);
   procedure Add_Context
     (Model : in out Completion_Context_Model;
      Info  : Completion_Context_Info);

   function Context_Count (Model : Completion_Context_Model) return Natural;
   function Context_At
     (Model : Completion_Context_Model;
      Index : Positive) return Completion_Context_Info;
   function Fingerprint (Model : Completion_Context_Model) return Natural;

   function Build (Contexts : Completion_Context_Model) return Completion_Legality_Model;

   function Legality_Count (Model : Completion_Legality_Model) return Natural;
   function Legality_At
     (Model : Completion_Legality_Model;
      Index : Positive) return Completion_Legality_Info;

   function First_For_Node
     (Model : Completion_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Completion_Legality_Info;
   function Rows_For_Status
     (Model  : Completion_Legality_Model;
      Status : Completion_Legality_Status) return Completion_Result_Set;
   function Rows_For_Kind
     (Model : Completion_Legality_Model;
      Kind  : Unit_Completion_Kind) return Completion_Result_Set;
   function Rows_For_Subject
     (Model   : Completion_Legality_Model;
      Subject : Completion_Subject_Kind) return Completion_Result_Set;
   function Rows_For_Relation
     (Model    : Completion_Legality_Model;
      Relation : Completion_Relation_State) return Completion_Result_Set;
   function Rows_For_Order
     (Model : Completion_Legality_Model;
      Order : Completion_Order_State) return Completion_Result_Set;
   function Rows_For_Visibility
     (Model      : Completion_Legality_Model;
      Visibility : Completion_Visibility_State) return Completion_Result_Set;
   function Rows_For_Name
     (Model : Completion_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Completion_Result_Set;

   function Result_Count (Set : Completion_Result_Set) return Natural;
   function Result_At
     (Set   : Completion_Result_Set;
      Index : Positive) return Completion_Legality_Info;

   function Legal_Count (Model : Completion_Legality_Model) return Natural;
   function Error_Count (Model : Completion_Legality_Model) return Natural;
   function Completion_Error_Count (Model : Completion_Legality_Model) return Natural;
   function Body_Error_Count (Model : Completion_Legality_Model) return Natural;
   function Order_Error_Count (Model : Completion_Legality_Model) return Natural;
   function View_Barrier_Count (Model : Completion_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Completion_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Completion_Legality_Model) return Natural;
   function Count_Status
     (Model  : Completion_Legality_Model;
      Status : Completion_Legality_Status) return Natural;
   function Count_Kind
     (Model : Completion_Legality_Model;
      Kind  : Unit_Completion_Kind) return Natural;
   function Count_Subject
     (Model   : Completion_Legality_Model;
      Subject : Completion_Subject_Kind) return Natural;
   function Count_Relation
     (Model    : Completion_Legality_Model;
      Relation : Completion_Relation_State) return Natural;
   function Count_Order
     (Model : Completion_Legality_Model;
      Order : Completion_Order_State) return Natural;
   function Count_Visibility
     (Model      : Completion_Legality_Model;
      Visibility : Completion_Visibility_State) return Natural;
   function Fingerprint (Model : Completion_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Completion_Context_Info);
   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Completion_Legality_Info);

   type Completion_Context_Model is record
      Contexts    : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Completion_Result_Set is record
      Results : Result_Vectors.Vector;
   end record;

   type Completion_Legality_Model is record
      Rows        : Result_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Unit_Completion_Order_Legality;
