with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Staticness_Range_Predicate_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Contract_Aspect_Legality is

   --  Pass1112 compiler-grade contract/aspect legality layer.
   --  This package consolidates Ada contract and semantic aspect legality for
   --  preconditions, postconditions, predicates, invariants, assertions,
   --  contract cases, Global/Depends-style data-flow aspects, and linked
   --  legality outcomes from the widened semantic layers.  The model is
   --  deterministic, bounded, and snapshot-owned.  It performs no parsing, file
   --  IO, dirty-state mutation, command/keybinding/workspace/render mutation,
   --  compiler invocation, or external analysis.

   subtype Assignment_Legality_Status is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   subtype Return_Legality_Status is
     Editor.Ada_Return_Legality.Return_Legality_Status;
   subtype Static_Legality_Status is
     Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Status;
   subtype Accessibility_Legality_Status is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;
   subtype Overload_Legality_Status is
     Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;
   subtype Cross_Unit_Semantic_Status is
     Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Status;

   type Contract_Context_Id is new Natural;
   No_Contract_Context : constant Contract_Context_Id := 0;

   type Contract_Legality_Id is new Natural;
   No_Contract_Legality : constant Contract_Legality_Id := 0;

   type Contract_Context_Kind is
     (Contract_Context_Precondition,
      Contract_Context_Postcondition,
      Contract_Context_Type_Invariant,
      Contract_Context_Default_Initial_Condition,
      Contract_Context_Static_Predicate,
      Contract_Context_Dynamic_Predicate,
      Contract_Context_Assertion,
      Contract_Context_Contract_Case,
      Contract_Context_Global_Aspect,
      Contract_Context_Depends_Aspect,
      Contract_Context_Refined_Global,
      Contract_Context_Refined_Depends,
      Contract_Context_Initial_Condition,
      Contract_Context_Generic_Formal_Contract,
      Contract_Context_Unknown);

   type Contract_Subject_Kind is
     (Contract_Subject_Subprogram,
      Contract_Subject_Package,
      Contract_Subject_Type,
      Contract_Subject_Subtype,
      Contract_Subject_Object,
      Contract_Subject_Task,
      Contract_Subject_Protected,
      Contract_Subject_Generic,
      Contract_Subject_Generic_Instance,
      Contract_Subject_Unknown);

   type Boolean_Expression_State is
     (Boolean_Expression_Compatible,
      Boolean_Expression_Non_Boolean,
      Boolean_Expression_Unresolved,
      Boolean_Expression_Unknown);

   type Aspect_Placement is
     (Aspect_Placement_Declaration,
      Aspect_Placement_Body,
      Aspect_Placement_Private_Part,
      Aspect_Placement_Completion,
      Aspect_Placement_Generic_Declaration,
      Aspect_Placement_Generic_Body,
      Aspect_Placement_Generic_Instance,
      Aspect_Placement_Unknown);

   type Flow_Contract_State is
     (Flow_Contract_Not_Applicable,
      Flow_Contract_Resolved,
      Flow_Contract_Duplicate_Item,
      Flow_Contract_Unknown_Global,
      Flow_Contract_Unknown_Dependency,
      Flow_Contract_Mode_Mismatch,
      Flow_Contract_Missing_Refinement,
      Flow_Contract_Illegal_Refinement,
      Flow_Contract_Unresolved);

   type Contract_Legality_Status is
     (Contract_Legality_Not_Checked,
      Contract_Legality_Legal_Precondition,
      Contract_Legality_Legal_Postcondition,
      Contract_Legality_Legal_Invariant,
      Contract_Legality_Legal_Predicate,
      Contract_Legality_Legal_Assertion,
      Contract_Legality_Legal_Contract_Case,
      Contract_Legality_Legal_Flow_Aspect,
      Contract_Legality_Non_Boolean_Condition,
      Contract_Legality_Unresolved_Condition,
      Contract_Legality_Static_Predicate_Non_Static,
      Contract_Legality_Static_Predicate_Failed,
      Contract_Legality_Predicate_Range_Error,
      Contract_Legality_Invariant_Subject_Illegal,
      Contract_Legality_Postcondition_Subject_Illegal,
      Contract_Legality_Precondition_Subject_Illegal,
      Contract_Legality_Contract_Case_Choice_Overlap,
      Contract_Legality_Contract_Case_Choice_Incomplete,
      Contract_Legality_Contract_Case_Result_Non_Boolean,
      Contract_Legality_Aspect_Placement_Error,
      Contract_Legality_Duplicate_Aspect,
      Contract_Legality_Private_View_Barrier,
      Contract_Legality_Limited_View_Barrier,
      Contract_Legality_Cross_Unit_Unresolved,
      Contract_Legality_Flow_Duplicate_Item,
      Contract_Legality_Flow_Unknown_Global,
      Contract_Legality_Flow_Unknown_Dependency,
      Contract_Legality_Flow_Mode_Mismatch,
      Contract_Legality_Flow_Missing_Refinement,
      Contract_Legality_Flow_Illegal_Refinement,
      Contract_Legality_Linked_Assignment_Error,
      Contract_Legality_Linked_Return_Error,
      Contract_Legality_Linked_Staticness_Error,
      Contract_Legality_Linked_Accessibility_Error,
      Contract_Legality_Linked_Overload_Error,
      Contract_Legality_Linked_Cross_Unit_Error,
      Contract_Legality_Indeterminate);

   type Contract_Context_Info is record
      Id                     : Contract_Context_Id := No_Contract_Context;
      Kind                   : Contract_Context_Kind := Contract_Context_Unknown;
      Subject                : Contract_Subject_Kind := Contract_Subject_Unknown;
      Placement              : Aspect_Placement := Aspect_Placement_Unknown;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subject_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Boolean_State          : Boolean_Expression_State := Boolean_Expression_Unknown;
      Requires_Static        : Boolean := False;
      Static_Expression      : Boolean := False;
      Predicate_Known_False  : Boolean := False;
      Range_Error            : Boolean := False;
      Duplicate_Aspect       : Boolean := False;
      Illegal_Placement      : Boolean := False;
      Private_View_Barrier   : Boolean := False;
      Limited_View_Barrier   : Boolean := False;
      Cross_Unit_Unresolved  : Boolean := False;
      Contract_Case_Overlap  : Boolean := False;
      Contract_Case_Incomplete : Boolean := False;
      Contract_Case_Result_Boolean : Boolean := True;
      Flow_State             : Flow_Contract_State := Flow_Contract_Not_Applicable;
      Assignment_Status      : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Status          : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Static_Status          : Static_Legality_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Accessibility_Status   : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Overload_Status        : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Cross_Unit_Status      : Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
   end record;

   type Contract_Legality_Info is record
      Id                     : Contract_Legality_Id := No_Contract_Legality;
      Context                : Contract_Context_Id := No_Contract_Context;
      Kind                   : Contract_Context_Kind := Contract_Context_Unknown;
      Subject                : Contract_Subject_Kind := Contract_Subject_Unknown;
      Placement              : Aspect_Placement := Aspect_Placement_Unknown;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subject_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                 : Contract_Legality_Status := Contract_Legality_Not_Checked;
      Message                : Ada.Strings.Unbounded.Unbounded_String;
      Detail                 : Ada.Strings.Unbounded.Unbounded_String;
      Boolean_State          : Boolean_Expression_State := Boolean_Expression_Unknown;
      Flow_State             : Flow_Contract_State := Flow_Contract_Not_Applicable;
      Assignment_Status      : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Status          : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Static_Status          : Static_Legality_Status :=
        Editor.Ada_Staticness_Range_Predicate_Legality.Static_Legality_Not_Checked;
      Accessibility_Status   : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Overload_Status        : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Cross_Unit_Status      : Cross_Unit_Semantic_Status :=
        Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Not_Checked;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

   type Contract_Context_Model is private;
   type Contract_Result_Set is private;
   type Contract_Legality_Model is private;

   procedure Clear (Model : in out Contract_Context_Model);
   procedure Add_Context
     (Model : in out Contract_Context_Model;
      Info  : Contract_Context_Info);

   function Context_Count (Model : Contract_Context_Model) return Natural;
   function Context_At
     (Model : Contract_Context_Model;
      Index : Positive) return Contract_Context_Info;
   function Fingerprint (Model : Contract_Context_Model) return Natural;

   function Build (Contexts : Contract_Context_Model) return Contract_Legality_Model;

   function Legality_Count (Model : Contract_Legality_Model) return Natural;
   function Legality_At
     (Model : Contract_Legality_Model;
      Index : Positive) return Contract_Legality_Info;

   function First_For_Node
     (Model : Contract_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Contract_Legality_Info;
   function Rows_For_Status
     (Model  : Contract_Legality_Model;
      Status : Contract_Legality_Status) return Contract_Result_Set;
   function Rows_For_Kind
     (Model : Contract_Legality_Model;
      Kind  : Contract_Context_Kind) return Contract_Result_Set;
   function Rows_For_Subject
     (Model   : Contract_Legality_Model;
      Subject : Contract_Subject_Kind) return Contract_Result_Set;
   function Rows_For_Placement
     (Model     : Contract_Legality_Model;
      Placement : Aspect_Placement) return Contract_Result_Set;
   function Rows_For_Flow_State
     (Model : Contract_Legality_Model;
      State : Flow_Contract_State) return Contract_Result_Set;

   function Result_Count (Results : Contract_Result_Set) return Natural;
   function Result_At
     (Results : Contract_Result_Set;
      Index   : Positive) return Contract_Legality_Info;

   function Count_Status
     (Model  : Contract_Legality_Model;
      Status : Contract_Legality_Status) return Natural;
   function Count_Kind
     (Model : Contract_Legality_Model;
      Kind  : Contract_Context_Kind) return Natural;
   function Count_Subject
     (Model   : Contract_Legality_Model;
      Subject : Contract_Subject_Kind) return Natural;
   function Count_Placement
     (Model     : Contract_Legality_Model;
      Placement : Aspect_Placement) return Natural;
   function Count_Flow_State
     (Model : Contract_Legality_Model;
      State : Flow_Contract_State) return Natural;

   function Legal_Count (Model : Contract_Legality_Model) return Natural;
   function Error_Count (Model : Contract_Legality_Model) return Natural;
   function Boolean_Error_Count (Model : Contract_Legality_Model) return Natural;
   function Static_Error_Count (Model : Contract_Legality_Model) return Natural;
   function Flow_Error_Count (Model : Contract_Legality_Model) return Natural;
   function View_Barrier_Count (Model : Contract_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Contract_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Contract_Legality_Model) return Natural;
   function Fingerprint (Model : Contract_Legality_Model) return Natural;

   function Has_Legality (Info : Contract_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Contract_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Contract_Legality_Info);

   type Contract_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Contract_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Contract_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Boolean_Error_Total : Natural := 0;
      Static_Error_Total : Natural := 0;
      Flow_Error_Total : Natural := 0;
      View_Barrier_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Contract_Aspect_Legality;
