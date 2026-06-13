with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;

package Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality is

   --  Pass1170 compiler-grade representation/freezing consumer legality.
   --
   --  This layer replaces the older Global/Depends-only tasking flow bridge for
   --  representation/freezing with the richer Pass1169 tasking/protected
   --  contract predicate/dataflow evidence.  Representation clauses,
   --  operational attributes, stream attributes, record layouts,
   --  generic-instance representation effects, private/full-view timing, and
   --  tasking-driven freezing effects cannot remain confidently legal when
   --  tasking evidence is blocked by predicate/invariant propagation,
   --  definite-initialization, refined dataflow, lifetime/accessibility,
   --  discriminant/variant, representation/freezing, or repaired coverage facts.

   package Freezing renames Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
   package Tasking_CPD renames Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;

   type Representation_Tasking_CPD_Row_Id is new Natural;
   No_Representation_Tasking_CPD_Row : constant Representation_Tasking_CPD_Row_Id := 0;

   type Representation_Tasking_CPD_Context_Kind is
     (Representation_Tasking_CPD_Representation_Clause,
      Representation_Tasking_CPD_Operational_Attribute,
      Representation_Tasking_CPD_Stream_Attribute,
      Representation_Tasking_CPD_Record_Layout,
      Representation_Tasking_CPD_Generic_Instance_Effect,
      Representation_Tasking_CPD_Private_Full_View,
      Representation_Tasking_CPD_Task_Activation_Effect,
      Representation_Tasking_CPD_Task_Termination_Effect,
      Representation_Tasking_CPD_Protected_Read_Effect,
      Representation_Tasking_CPD_Protected_Write_Effect,
      Representation_Tasking_CPD_Protected_Call_Effect,
      Representation_Tasking_CPD_Entry_Barrier_Effect,
      Representation_Tasking_CPD_Accept_Body_Effect,
      Representation_Tasking_CPD_Requeue_Effect,
      Representation_Tasking_CPD_Select_Effect,
      Representation_Tasking_CPD_Abortable_Finalization_Effect,
      Representation_Tasking_CPD_Unknown);

   type Representation_Tasking_CPD_Status is
     (Representation_Tasking_CPD_Not_Checked,
      Representation_Tasking_CPD_Legal_Representation_Clause_Accepted,
      Representation_Tasking_CPD_Legal_Operational_Attribute_Accepted,
      Representation_Tasking_CPD_Legal_Stream_Attribute_Accepted,
      Representation_Tasking_CPD_Legal_Record_Layout_Accepted,
      Representation_Tasking_CPD_Legal_Generic_Instance_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Private_Full_View_Accepted,
      Representation_Tasking_CPD_Legal_Task_Activation_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Task_Termination_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Protected_Read_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Protected_Write_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Protected_Call_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Entry_Barrier_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Accept_Body_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Requeue_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Select_Effect_Accepted,
      Representation_Tasking_CPD_Legal_Abortable_Finalization_Effect_Accepted,
      Representation_Tasking_CPD_Base_Freezing_Error,
      Representation_Tasking_CPD_Missing_Tasking_CPD_Row,
      Representation_Tasking_CPD_Missing_Elaboration_Predicate_Row,
      Representation_Tasking_CPD_Missing_Contract_Predicate_Row,
      Representation_Tasking_CPD_Base_Contract_Error,
      Representation_Tasking_CPD_Base_Elaboration_Error,
      Representation_Tasking_CPD_Base_Tasking_Effect_Error,
      Representation_Tasking_CPD_Predicate_Propagation_Blocker,
      Representation_Tasking_CPD_Read_Before_Write_Blocker,
      Representation_Tasking_CPD_Component_Read_Before_Write_Blocker,
      Representation_Tasking_CPD_Partial_Initialization_Blocker,
      Representation_Tasking_CPD_Missing_Out_Assignment_Blocker,
      Representation_Tasking_CPD_Conditional_In_Out_Blocker,
      Representation_Tasking_CPD_Return_Object_Initialization_Blocker,
      Representation_Tasking_CPD_Branch_Loop_Merge_Blocker,
      Representation_Tasking_CPD_Exception_Finalization_Path_Blocker,
      Representation_Tasking_CPD_Use_After_Finalization_Blocker,
      Representation_Tasking_CPD_Lifetime_Accessibility_Blocker,
      Representation_Tasking_CPD_Discriminant_Variant_Blocker,
      Representation_Tasking_CPD_Representation_Freezing_Blocker,
      Representation_Tasking_CPD_Global_Depends_Blocker,
      Representation_Tasking_CPD_Call_Propagation_Blocker,
      Representation_Tasking_CPD_Generic_Flow_Blocker,
      Representation_Tasking_CPD_Tasking_Protected_Flow_Blocker,
      Representation_Tasking_CPD_Coverage_Blocker,
      Representation_Tasking_CPD_Multiple_Tasking_CPD_Blockers,
      Representation_Tasking_CPD_Tasking_CPD_Indeterminate,
      Representation_Tasking_CPD_Indeterminate);

   type Representation_Tasking_CPD_Context_Info is record
      Id                    : Representation_Tasking_CPD_Row_Id := No_Representation_Tasking_CPD_Row;
      Kind                  : Representation_Tasking_CPD_Context_Kind := Representation_Tasking_CPD_Unknown;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Select_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Freezing_Row          : Freezing.Freezing_Propagation_Id := Freezing.No_Freezing_Propagation;
      Freezing_Status       : Freezing.Freezing_Propagation_Status := Freezing.Freezing_Propagation_Not_Checked;
      Tasking_CPD_Row       : Tasking_CPD.Tasking_Contract_Predicate_Row_Id :=
        Tasking_CPD.No_Tasking_Contract_Predicate_Row;
      Tasking_CPD_Status    : Tasking_CPD.Tasking_Contract_Predicate_Status :=
        Tasking_CPD.Tasking_Contract_Predicate_Not_Checked;
      Tasking_CPD_Matches   : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
   end record;

   type Representation_Tasking_CPD_Info is record
      Id                    : Representation_Tasking_CPD_Row_Id := No_Representation_Tasking_CPD_Row;
      Context               : Representation_Tasking_CPD_Row_Id := No_Representation_Tasking_CPD_Row;
      Kind                  : Representation_Tasking_CPD_Context_Kind := Representation_Tasking_CPD_Unknown;
      Status                : Representation_Tasking_CPD_Status := Representation_Tasking_CPD_Not_Checked;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Task_Node             : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Protected_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Entry_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Select_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Object_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Entry_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Message               : Ada.Strings.Unbounded.Unbounded_String;
      Detail                : Ada.Strings.Unbounded.Unbounded_String;
      Freezing_Row          : Freezing.Freezing_Propagation_Id := Freezing.No_Freezing_Propagation;
      Freezing_Status       : Freezing.Freezing_Propagation_Status := Freezing.Freezing_Propagation_Not_Checked;
      Tasking_CPD_Row       : Tasking_CPD.Tasking_Contract_Predicate_Row_Id :=
        Tasking_CPD.No_Tasking_Contract_Predicate_Row;
      Tasking_CPD_Status    : Tasking_CPD.Tasking_Contract_Predicate_Status :=
        Tasking_CPD.Tasking_Contract_Predicate_Not_Checked;
      Tasking_CPD_Matches   : Natural := 0;
      Start_Line            : Positive := 1;
      Start_Column          : Positive := 1;
      End_Line              : Positive := 1;
      End_Column            : Positive := 1;
      Source_Fingerprint    : Natural := 0;
      Fingerprint           : Natural := 0;
   end record;

   type Representation_Tasking_CPD_Context_Model is private;
   type Representation_Tasking_CPD_Set is private;
   type Representation_Tasking_CPD_Model is private;

   procedure Clear (Model : in out Representation_Tasking_CPD_Context_Model);
   procedure Add_Context
     (Model : in out Representation_Tasking_CPD_Context_Model;
      Info  : Representation_Tasking_CPD_Context_Info);

   function Context_Count (Model : Representation_Tasking_CPD_Context_Model) return Natural;
   function Context_At
     (Model : Representation_Tasking_CPD_Context_Model;
      Index : Positive) return Representation_Tasking_CPD_Context_Info;
   function Fingerprint (Model : Representation_Tasking_CPD_Context_Model) return Natural;

   function Build
     (Contexts : Representation_Tasking_CPD_Context_Model) return Representation_Tasking_CPD_Model;

   function Row_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Row_At
     (Model : Representation_Tasking_CPD_Model;
      Index : Positive) return Representation_Tasking_CPD_Info;
   function First_For_Node
     (Model : Representation_Tasking_CPD_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Tasking_CPD_Info;
   function Rows_For_Status
     (Model  : Representation_Tasking_CPD_Model;
      Status : Representation_Tasking_CPD_Status) return Representation_Tasking_CPD_Set;
   function Rows_For_Kind
     (Model : Representation_Tasking_CPD_Model;
      Kind  : Representation_Tasking_CPD_Context_Kind) return Representation_Tasking_CPD_Set;

   function Set_Count (Set : Representation_Tasking_CPD_Set) return Natural;
   function Set_At
     (Set   : Representation_Tasking_CPD_Set;
      Index : Positive) return Representation_Tasking_CPD_Info;

   function Count_Status
     (Model  : Representation_Tasking_CPD_Model;
      Status : Representation_Tasking_CPD_Status) return Natural;
   function Count_Kind
     (Model : Representation_Tasking_CPD_Model;
      Kind  : Representation_Tasking_CPD_Context_Kind) return Natural;

   function Legal_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Error_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Freezing_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Initialization_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Predicate_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Dataflow_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Coverage_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Tasking_Error_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Indeterminate_Count (Model : Representation_Tasking_CPD_Model) return Natural;
   function Fingerprint (Model : Representation_Tasking_CPD_Model) return Natural;

   function Is_Legal (Status : Representation_Tasking_CPD_Status) return Boolean;
   function Is_Initialization_Error (Status : Representation_Tasking_CPD_Status) return Boolean;
   function Is_Predicate_Error (Status : Representation_Tasking_CPD_Status) return Boolean;
   function Is_Dataflow_Error (Status : Representation_Tasking_CPD_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Representation_Tasking_CPD_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Representation_Tasking_CPD_Info);

   type Representation_Tasking_CPD_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Representation_Tasking_CPD_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Representation_Tasking_CPD_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Freezing_Error_Total : Natural := 0;
      Initialization_Error_Total : Natural := 0;
      Predicate_Error_Total : Natural := 0;
      Dataflow_Error_Total : Natural := 0;
      Coverage_Error_Total : Natural := 0;
      Tasking_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
