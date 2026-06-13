with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain;
with Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Refined_Global_Depends_Conformance_Legality;
with Editor.Ada_Renaming_Alias_Visibility_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Final_Effects_Legality;
with Editor.Ada_Unit_Completion_Order_Legality;

package Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality is

   --  Pass1186 compiler-grade cross-unit final semantic closure legality.
   --
   --  This layer extends cross-unit closure across the widened legality engines
   --  and the repaired final-consumer chain.  It preserves dependency blockers
   --  and semantic blocker families from overload/type precision, generic replay
   --  backmapping, discriminant/variant consumers, final accessibility scope,
   --  final elaboration, final tasking/protected effects, representation/freezing
   --  CPD evidence, contract/predicate/dataflow evidence, refined
   --  Global/Depends conformance, unit completion/order, renaming/alias/use
   --  visibility, exception/finalization, and integrated semantic closure.  The
   --  model is deterministic, bounded, and snapshot-owned; it performs no file
   --  IO, parsing, rendering, command, keybinding, workspace, or dirty-state
   --  mutation.

   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   package Contract_CPD renames Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
   package Cross_Unit renames Editor.Ada_Cross_Unit_Semantic_Closure;
   package Dataflow_Init renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
   package Disc_Consumer renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   package Elab_Final renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   package Exceptions renames Editor.Ada_Exception_Finalization_Legality;
   package Generic_Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   package Integrated renames Editor.Ada_Integrated_Semantic_Closure;
   package Consumer_Chain renames Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain;
   package Integrated_Backmap renames Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping;
   package Overload_Edge renames Editor.Ada_Overload_Type_Edge_Precision_Legality;
   package Refined renames Editor.Ada_Refined_Global_Depends_Conformance_Legality;
   package Renaming renames Editor.Ada_Renaming_Alias_Visibility_Legality;
   package Rep_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   package Tasking_Final renames Editor.Ada_Tasking_Protected_Final_Effects_Legality;
   package Completion renames Editor.Ada_Unit_Completion_Order_Legality;

   type Cross_Unit_Final_Row_Id is new Natural;
   No_Cross_Unit_Final_Row : constant Cross_Unit_Final_Row_Id := 0;

   type Cross_Unit_Final_Context_Kind is
     (Cross_Unit_Final_Local,
      Cross_Unit_Final_With_Use,
      Cross_Unit_Final_Private_Full_View,
      Cross_Unit_Final_Limited_View,
      Cross_Unit_Final_Child_Private_Child,
      Cross_Unit_Final_Separate_Body,
      Cross_Unit_Final_Body_Spec,
      Cross_Unit_Final_Generic_Instance,
      Cross_Unit_Final_Generic_Backmapping,
      Cross_Unit_Final_Representation,
      Cross_Unit_Final_Elaboration,
      Cross_Unit_Final_Overload_Type,
      Cross_Unit_Final_Dispatching_Primitive,
      Cross_Unit_Final_Accessibility,
      Cross_Unit_Final_Discriminant_Variant,
      Cross_Unit_Final_Predicate_Invariant,
      Cross_Unit_Final_Contract_Dataflow,
      Cross_Unit_Final_Refined_Global_Depends,
      Cross_Unit_Final_Tasking_Protected,
      Cross_Unit_Final_Exception_Finalization,
      Cross_Unit_Final_Renaming_Visibility,
      Cross_Unit_Final_AST_Repair,
      Cross_Unit_Final_Coverage_Gate,
      Cross_Unit_Final_Unknown);

   type Cross_Unit_Dependency_State is
     (Dependency_Local_Only,
      Dependency_With_Visible,
      Dependency_Use_Visible,
      Dependency_Private_Full_View,
      Dependency_Limited_View,
      Dependency_Child_Visible,
      Dependency_Private_Child_Visible,
      Dependency_Separate_Body_Visible,
      Dependency_Generic_Instance_Visible,
      Dependency_Representation_Visible,
      Dependency_Elaboration_Visible,
      Dependency_Tasking_Protected_Visible,
      Dependency_Missing,
      Dependency_Ambiguous,
      Dependency_Overflow,
      Dependency_Stale,
      Dependency_Unknown);

   type Cross_Unit_Final_Status is
     (Cross_Unit_Final_Not_Checked,
      Cross_Unit_Final_Accepted,
      Cross_Unit_Final_Local_Accepted,
      Cross_Unit_Final_With_Use_Accepted,
      Cross_Unit_Final_Private_Full_View_Accepted,
      Cross_Unit_Final_Limited_View_Accepted,
      Cross_Unit_Final_Child_Private_Child_Accepted,
      Cross_Unit_Final_Separate_Body_Accepted,
      Cross_Unit_Final_Generic_Instance_Accepted,
      Cross_Unit_Final_Representation_Accepted,
      Cross_Unit_Final_Elaboration_Accepted,
      Cross_Unit_Final_Tasking_Protected_Accepted,
      Cross_Unit_Final_Missing_Dependency,
      Cross_Unit_Final_Ambiguous_Dependency,
      Cross_Unit_Final_Dependency_Overflow,
      Cross_Unit_Final_Stale_Dependency,
      Cross_Unit_Final_Limited_View_Barrier,
      Cross_Unit_Final_Private_View_Barrier,
      Cross_Unit_Final_Child_Visibility_Blocker,
      Cross_Unit_Final_Separate_Body_Blocker,
      Cross_Unit_Final_Body_Spec_Completion_Blocker,
      Cross_Unit_Final_Generic_Body_Unavailable,
      Cross_Unit_Final_Generic_Backmapping_Blocker,
      Cross_Unit_Final_Representation_Target_Blocker,
      Cross_Unit_Final_Representation_Freezing_Blocker,
      Cross_Unit_Final_Elaboration_Dependence_Blocker,
      Cross_Unit_Final_Overload_Type_Edge_Blocker,
      Cross_Unit_Final_Dispatching_Inherited_Primitive_Blocker,
      Cross_Unit_Final_Accessibility_Lifetime_Blocker,
      Cross_Unit_Final_Discriminant_Variant_Blocker,
      Cross_Unit_Final_Predicate_Invariant_Blocker,
      Cross_Unit_Final_Contract_Dataflow_Blocker,
      Cross_Unit_Final_Refined_Global_Depends_Blocker,
      Cross_Unit_Final_Tasking_Protected_Final_Effect_Blocker,
      Cross_Unit_Final_Exception_Finalization_Blocker,
      Cross_Unit_Final_Renaming_Alias_Visibility_Blocker,
      Cross_Unit_Final_AST_Repair_Blocker,
      Cross_Unit_Final_Coverage_Gate_Blocker,
      Cross_Unit_Final_Integrated_Closure_Blocker,
      Cross_Unit_Final_Multiple_Blockers,
      Cross_Unit_Final_Indeterminate);

   type Cross_Unit_Final_Context_Info is record
      Id                         : Cross_Unit_Final_Row_Id := No_Cross_Unit_Final_Row;
      Kind                       : Cross_Unit_Final_Context_Kind := Cross_Unit_Final_Unknown;
      Dependency                 : Cross_Unit_Dependency_State := Dependency_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Dependency_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Integrated_Status          : Integrated.Integrated_Closure_Status := Integrated.Integrated_Closure_Not_Checked;
      Overload_Row               : Overload_Edge.Overload_Type_Edge_Row_Id := Overload_Edge.No_Overload_Type_Edge_Row;
      Overload_Status            : Overload_Edge.Overload_Type_Edge_Status := Overload_Edge.Overload_Type_Edge_Not_Checked;
      Generic_Backmap_Row        : Generic_Backmap.Generic_Backmap_Row_Id := Generic_Backmap.No_Generic_Backmap_Row;
      Generic_Backmap_Status     : Generic_Backmap.Generic_Backmap_Status := Generic_Backmap.Generic_Backmap_Not_Checked;
      Discriminant_Row           : Disc_Consumer.Discriminant_Consumer_Row_Id := Disc_Consumer.No_Discriminant_Consumer_Row;
      Discriminant_Status        : Disc_Consumer.Discriminant_Consumer_Status := Disc_Consumer.Discriminant_Consumer_Not_Checked;
      Accessibility_Row          : Access_Final.Master_Scope_Final_Row_Id := Access_Final.No_Master_Scope_Final_Row;
      Accessibility_Status       : Access_Final.Master_Scope_Final_Status := Access_Final.Master_Scope_Final_Not_Checked;
      Elaboration_Row            : Elab_Final.Final_Elaboration_Row_Id := Elab_Final.No_Final_Elaboration_Row;
      Elaboration_Status         : Elab_Final.Final_Elaboration_Status := Elab_Final.Final_Elaboration_Not_Checked;
      Tasking_Row                : Tasking_Final.Final_Tasking_Row_Id := Tasking_Final.No_Final_Tasking_Row;
      Tasking_Status             : Tasking_Final.Final_Tasking_Status := Tasking_Final.Final_Tasking_Not_Checked;
      Representation_Row         : Rep_CPD.Representation_Tasking_CPD_Row_Id := Rep_CPD.No_Representation_Tasking_CPD_Row;
      Representation_Status      : Rep_CPD.Representation_Tasking_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Not_Checked;
      Contract_Row               : Contract_CPD.Contract_Predicate_Row_Id := Contract_CPD.No_Contract_Predicate_Row;
      Contract_Status            : Contract_CPD.Contract_Predicate_Status := Contract_CPD.Contract_Predicate_Not_Checked;
      Dataflow_Row               : Dataflow_Init.Dataflow_Init_Row_Id := Dataflow_Init.No_Dataflow_Init_Row;
      Dataflow_Status            : Dataflow_Init.Dataflow_Init_Status := Dataflow_Init.Dataflow_Init_Not_Checked;
      Refined_Row                : Refined.Refined_Conformance_Id := Refined.No_Refined_Conformance;
      Refined_Status             : Refined.Refined_Conformance_Status := Refined.Refined_Conformance_Not_Checked;
      Completion_Row             : Completion.Completion_Legality_Id := Completion.No_Completion_Legality;
      Completion_Status          : Completion.Completion_Legality_Status := Completion.Completion_Legality_Not_Checked;
      Renaming_Row               : Renaming.Renaming_Legality_Id := Renaming.No_Renaming_Legality;
      Renaming_Status            : Renaming.Renaming_Legality_Status := Renaming.Renaming_Legality_Not_Checked;
      Exception_Row              : Exceptions.Exception_Legality_Id := Exceptions.No_Exception_Legality;
      Exception_Status           : Exceptions.Exception_Legality_Status := Exceptions.Exception_Legality_Not_Checked;
      Missing_Dependency         : Boolean := False;
      Ambiguous_Dependency       : Boolean := False;
      Dependency_Overflow        : Boolean := False;
      Stale_Dependency           : Boolean := False;
      Private_View_Barrier       : Boolean := False;
      Limited_View_Barrier       : Boolean := False;
      Child_Visibility_Blocked   : Boolean := False;
      Separate_Body_Blocked      : Boolean := False;
      Requires_Overload          : Boolean := False;
      Requires_Generic_Backmap   : Boolean := False;
      Requires_Discriminant      : Boolean := False;
      Requires_Accessibility     : Boolean := False;
      Requires_Elaboration       : Boolean := False;
      Requires_Tasking           : Boolean := False;
      Requires_Representation    : Boolean := False;
      Requires_Contract          : Boolean := False;
      Requires_Dataflow          : Boolean := False;
      Requires_Refined           : Boolean := False;
      Requires_Completion        : Boolean := False;
      Requires_Renaming          : Boolean := False;
      Requires_Exception         : Boolean := False;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
   end record;

   type Cross_Unit_Final_Info is record
      Id                         : Cross_Unit_Final_Row_Id := No_Cross_Unit_Final_Row;
      Context                    : Cross_Unit_Final_Row_Id := No_Cross_Unit_Final_Row;
      Kind                       : Cross_Unit_Final_Context_Kind := Cross_Unit_Final_Unknown;
      Dependency                 : Cross_Unit_Dependency_State := Dependency_Unknown;
      Status                     : Cross_Unit_Final_Status := Cross_Unit_Final_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Dependency_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint         : Natural := 0;
      Closure_Fingerprint        : Natural := 0;
      Consumer_Fingerprint       : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Cross_Unit_Final_Context_Model is private;
   type Cross_Unit_Final_Set is private;
   type Cross_Unit_Final_Model is private;

   procedure Clear (Model : in out Cross_Unit_Final_Context_Model);
   procedure Add_Context (Model : in out Cross_Unit_Final_Context_Model; Info : Cross_Unit_Final_Context_Info);
   function Context_Count (Model : Cross_Unit_Final_Context_Model) return Natural;
   function Context_At (Model : Cross_Unit_Final_Context_Model; Index : Positive) return Cross_Unit_Final_Context_Info;
   function Fingerprint (Model : Cross_Unit_Final_Context_Model) return Natural;

   function Build (Contexts : Cross_Unit_Final_Context_Model) return Cross_Unit_Final_Model;
   function Row_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Row_At (Model : Cross_Unit_Final_Model; Index : Positive) return Cross_Unit_Final_Info;
   function First_For_Node (Model : Cross_Unit_Final_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_Final_Info;
   function Rows_For_Status (Model : Cross_Unit_Final_Model; Status : Cross_Unit_Final_Status) return Cross_Unit_Final_Set;
   function Rows_For_Kind (Model : Cross_Unit_Final_Model; Kind : Cross_Unit_Final_Context_Kind) return Cross_Unit_Final_Set;
   function Rows_For_Unit (Model : Cross_Unit_Final_Model; Unit_Name : String) return Cross_Unit_Final_Set;
   function Set_Count (Set : Cross_Unit_Final_Set) return Natural;
   function Set_At (Set : Cross_Unit_Final_Set; Index : Positive) return Cross_Unit_Final_Info;
   function Count_Status (Model : Cross_Unit_Final_Model; Status : Cross_Unit_Final_Status) return Natural;
   function Count_Kind (Model : Cross_Unit_Final_Model; Kind : Cross_Unit_Final_Context_Kind) return Natural;
   function Legal_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Dependency_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function View_Barrier_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Generic_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Representation_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Elaboration_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Tasking_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Type_Access_Discriminant_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Contract_Dataflow_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Completion_Visibility_Exception_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Coverage_Error_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Indeterminate_Count (Model : Cross_Unit_Final_Model) return Natural;
   function Fingerprint (Model : Cross_Unit_Final_Model) return Natural;

   function Is_Legal (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Dependency_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_View_Barrier (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Generic_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Representation_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Elaboration_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Tasking_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Type_Access_Discriminant_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Contract_Dataflow_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Completion_Visibility_Exception_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Coverage_Error (Status : Cross_Unit_Final_Status) return Boolean;
   function Is_Indeterminate (Status : Cross_Unit_Final_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Cross_Unit_Final_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Cross_Unit_Final_Info);

   type Cross_Unit_Final_Context_Model is record
      Contexts : Context_Vectors.Vector;
   end record;

   type Cross_Unit_Final_Set is record
      Rows : Row_Vectors.Vector;
   end record;

   type Cross_Unit_Final_Model is record
      Rows : Row_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
