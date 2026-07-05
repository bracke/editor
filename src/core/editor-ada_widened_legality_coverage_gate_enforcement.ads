with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_AST_Semantic_Coverage_Audit;
with Editor.Ada_Coverage_Gated_Semantic_Results;
with Editor.Ada_Semantic_Coverage_Gates;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement is

   --  Case 1137 coverage-gate enforcement for widened Ada legality engines.
   --
   --  Case 1136 preserved coverage-gated semantic results.  This package is the
   --  enforcing consumer used by widened legality engines before a row is
   --  allowed to remain a confident semantic conclusion.  It maps every gated
   --  semantic conclusion family to the corresponding widened legality engine
   --  and classifies whether the engine may preserve the result, must degrade
   --  it to indeterminate, must require cross-unit closure, or must suppress or
   --  block the result because parser/AST/metadata/consumer coverage is not
   --  sufficient.
   --
   --  Inputs are snapshot-owned semantic rows.  The package performs no
   --  parsing, file IO, dirty-state mutation, command/keybinding/workspace or
   --  render mutation, and no compiler invocation.

   package Gates renames Editor.Ada_Semantic_Coverage_Gates;
   package Gated renames Editor.Ada_Coverage_Gated_Semantic_Results;
   package Audit renames Editor.Ada_AST_Semantic_Coverage_Audit;

   type Enforcement_Row_Id is new Natural;
   No_Enforcement_Row : constant Enforcement_Row_Id := 0;

   type Widened_Legality_Engine is
     (Engine_Assignment,
      Engine_Return,
      Engine_Conversion_Access_Aggregate,
      Engine_Call_Overload,
      Engine_Staticness_Range_Predicate,
      Engine_Accessibility_Lifetime,
      Engine_Contract_Aspect,
      Engine_Dataflow_Global_Depends,
      Engine_Generic_Instance_Body,
      Engine_Record_Variant_Aggregate,
      Engine_Elaboration,
      Engine_Tasking_Protected,
      Engine_Representation_Freezing,
      Engine_Exception_Finalization,
      Engine_Integrated_Closure,
      Engine_Unknown);

   type Enforcement_Status is
     (Enforcement_Not_Checked,
      Enforcement_Confident_Result_Allowed,
      Enforcement_Original_Error_Preserved,
      Enforcement_Degraded_To_Indeterminate,
      Enforcement_Cross_Unit_Closure_Required,
      Enforcement_Legal_Result_Suppressed,
      Enforcement_Derived_Result_Suppressed,
      Enforcement_Parser_AST_Blocker,
      Enforcement_Metadata_Blocker,
      Enforcement_Consumer_Integration_Blocker,
      Enforcement_Unsafe_Result_Blocked);

   type Enforcement_Context_Info is record
      Id                  : Enforcement_Row_Id := No_Enforcement_Row;
      Engine              : Widened_Legality_Engine := Engine_Unknown;
      Gated_Result_Id     : Gated.Gated_Result_Id := Gated.No_Gated_Result;
      Conclusion          : Gates.Semantic_Conclusion_Kind := Gates.Conclusion_Unknown;
      Original_State      : Gated.Original_Result_State := Gated.Original_Result_Not_Checked;
      Gated_Status        : Gated.Gated_Result_Status := Gated.Gated_Result_Not_Checked;
      Gate_Status         : Gates.Gate_Status := Gates.Gate_Not_Checked;
      Gate_Action         : Gates.Gate_Action := Gates.Gate_Block_Unsafe_Result;
      Construct           : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer            : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Semantic_Row_Id     : Natural := 0;
      Construct_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Source_Message      : Ada.Strings.Unbounded.Unbounded_String;
      Source_Detail       : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint  : Natural := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
   end record;

   type Enforcement_Info is record
      Id                  : Enforcement_Row_Id := No_Enforcement_Row;
      Engine              : Widened_Legality_Engine := Engine_Unknown;
      Status              : Enforcement_Status := Enforcement_Not_Checked;
      Gated_Result_Id     : Gated.Gated_Result_Id := Gated.No_Gated_Result;
      Conclusion          : Gates.Semantic_Conclusion_Kind := Gates.Conclusion_Unknown;
      Original_State      : Gated.Original_Result_State := Gated.Original_Result_Not_Checked;
      Gated_Status        : Gated.Gated_Result_Status := Gated.Gated_Result_Not_Checked;
      Gate_Status         : Gates.Gate_Status := Gates.Gate_Not_Checked;
      Gate_Action         : Gates.Gate_Action := Gates.Gate_Block_Unsafe_Result;
      Construct           : Audit.Ada_Construct_Kind := Audit.Construct_Unknown;
      Consumer            : Audit.Semantic_Consumer_Family := Audit.Consumer_None;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Parent_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Semantic_Row_Id     : Natural := 0;
      Construct_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint  : Natural := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Enforcement_Context_Model is private;
   type Enforcement_Set is private;
   type Enforcement_Model is private;

   function Engine_For
     (Conclusion : Gates.Semantic_Conclusion_Kind;
      Consumer   : Audit.Semantic_Consumer_Family)
      return Widened_Legality_Engine;

   function Enforced_Status_For
     (Gated_Status : Gated.Gated_Result_Status)
      return Enforcement_Status;

   procedure Clear (Model : in out Enforcement_Context_Model);
   procedure Add_Context
     (Model   : in out Enforcement_Context_Model;
      Context : Enforcement_Context_Info);

   procedure Add_From_Gated_Result
     (Model : in out Enforcement_Context_Model;
      Row   : Gated.Gated_Result_Info);

   function Build (Contexts : Enforcement_Context_Model) return Enforcement_Model;
   function Build_From_Gated_Results
     (Results : Gated.Gated_Result_Model) return Enforcement_Model;

   function Row_Count (Model : Enforcement_Model) return Natural;
   function Row_At
     (Model : Enforcement_Model;
      Index : Positive) return Enforcement_Info;

   function First_For_Node
     (Model : Enforcement_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Enforcement_Info;

   function Rows_For_Engine
     (Model  : Enforcement_Model;
      Engine : Widened_Legality_Engine) return Enforcement_Set;
   function Rows_For_Status
     (Model  : Enforcement_Model;
      Status : Enforcement_Status) return Enforcement_Set;
   function Rows_For_Conclusion
     (Model      : Enforcement_Model;
      Conclusion : Gates.Semantic_Conclusion_Kind) return Enforcement_Set;

   function Set_Count (Set : Enforcement_Set) return Natural;
   function Set_At
     (Set   : Enforcement_Set;
      Index : Positive) return Enforcement_Info;

   function Count_Engine
     (Model  : Enforcement_Model;
      Engine : Widened_Legality_Engine) return Natural;
   function Count_Status
     (Model  : Enforcement_Model;
      Status : Enforcement_Status) return Natural;
   function Count_Conclusion
     (Model      : Enforcement_Model;
      Conclusion : Gates.Semantic_Conclusion_Kind) return Natural;

   function Confident_Count (Model : Enforcement_Model) return Natural;
   function Preserved_Error_Count (Model : Enforcement_Model) return Natural;
   function Degraded_Count (Model : Enforcement_Model) return Natural;
   function Suppressed_Count (Model : Enforcement_Model) return Natural;
   function Repair_Blocker_Count (Model : Enforcement_Model) return Natural;
   function Cross_Unit_Required_Count (Model : Enforcement_Model) return Natural;
   function Unsafe_Blocker_Count (Model : Enforcement_Model) return Natural;
   function Fingerprint (Model : Enforcement_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Enforcement_Context_Info);
   package Info_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Enforcement_Info);

   type Enforcement_Context_Model is record
      Items       : Context_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Enforcement_Set is record
      Items : Info_Vectors.Vector;
   end record;

   type Enforcement_Model is record
      Items       : Info_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
