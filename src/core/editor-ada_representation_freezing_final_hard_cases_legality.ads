with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
with Editor.Ada_Representation_Operational_AST_Repair_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Final_Effects_Legality;

package Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality is

   --  Case 1191 compiler-grade representation/freezing final hard-case legality.
   --
   --  This layer closes the remaining hard representation/freezing cases that
   --  need evidence from final consumers rather than a local representation row
   --  alone.  It preserves blockers for private/full-view cross-unit freezing,
   --  generic formal freezing, inherited operational attributes, stream
   --  attributes on limited/private views, record layout with discriminants,
   --  variants and finalization, and implicit freezing order across units.

   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   package Cross_Final renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   package Disc_Consumer renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   package Elab_Final renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   package Generic_Cycles renames Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality;
   package Rep_AST renames Editor.Ada_Representation_Operational_AST_Repair_Legality;
   package Rep_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   package Task_Final renames Editor.Ada_Tasking_Protected_Final_Effects_Legality;

   type Final_Representation_Row_Id is new Natural;
   No_Final_Representation_Row : constant Final_Representation_Row_Id := 0;

   type Final_Representation_Context_Kind is
     (Final_Representation_Private_Full_View_Freezing,
      Final_Representation_Limited_View_Stream_Attribute,
      Final_Representation_Generic_Formal_Freezing,
      Final_Representation_Inherited_Operational_Attribute,
      Final_Representation_Derived_Type_Operational_Attribute,
      Final_Representation_Record_Layout_Discriminant_Finalization,
      Final_Representation_Variant_Record_Layout,
      Final_Representation_Stream_Attribute_Private_View,
      Final_Representation_Implicit_Freezing_Order,
      Final_Representation_Generic_Instance_Representation,
      Final_Representation_Representation_Item,
      Final_Representation_Operational_Item,
      Final_Representation_Unknown);

   type Final_Representation_Status is
     (Final_Representation_Not_Checked,
      Final_Representation_Legal_Private_Full_View_Freezing_Accepted,
      Final_Representation_Legal_Limited_View_Stream_Attribute_Accepted,
      Final_Representation_Legal_Generic_Formal_Freezing_Accepted,
      Final_Representation_Legal_Inherited_Operational_Attribute_Accepted,
      Final_Representation_Legal_Derived_Type_Operational_Attribute_Accepted,
      Final_Representation_Legal_Record_Layout_Discriminant_Finalization_Accepted,
      Final_Representation_Legal_Variant_Record_Layout_Accepted,
      Final_Representation_Legal_Stream_Attribute_Private_View_Accepted,
      Final_Representation_Legal_Implicit_Freezing_Order_Accepted,
      Final_Representation_Legal_Generic_Instance_Representation_Accepted,
      Final_Representation_Legal_Representation_Item_Accepted,
      Final_Representation_Legal_Operational_Item_Accepted,
      Final_Representation_Missing_Representation_CPD_Row,
      Final_Representation_Representation_CPD_Blocker,
      Final_Representation_Representation_CPD_Indeterminate,
      Final_Representation_Missing_Cross_Unit_Final_Row,
      Final_Representation_Cross_Unit_Dependency_Blocker,
      Final_Representation_Private_View_Barrier,
      Final_Representation_Limited_View_Barrier,
      Final_Representation_Missing_Generic_Cycle_Row,
      Final_Representation_Generic_Cycle_Blocker,
      Final_Representation_Generic_Replay_Blocker,
      Final_Representation_Missing_AST_Repair_Row,
      Final_Representation_AST_Repair_Blocker,
      Final_Representation_AST_Repair_Indeterminate,
      Final_Representation_Missing_Discriminant_Row,
      Final_Representation_Discriminant_Variant_Blocker,
      Final_Representation_Missing_Accessibility_Row,
      Final_Representation_Accessibility_Finalization_Blocker,
      Final_Representation_Missing_Elaboration_Row,
      Final_Representation_Elaboration_Order_Blocker,
      Final_Representation_Missing_Tasking_Row,
      Final_Representation_Tasking_Final_Effect_Blocker,
      Final_Representation_Generic_Formal_Freezing_Blocker,
      Final_Representation_Inherited_Operational_Attribute_Blocker,
      Final_Representation_Stream_Attribute_View_Blocker,
      Final_Representation_Private_Full_View_Freezing_Blocker,
      Final_Representation_Implicit_Freezing_Order_Blocker,
      Final_Representation_Record_Layout_Finalization_Blocker,
      Final_Representation_Variant_Discriminant_Layout_Blocker,
      Final_Representation_Source_Fingerprint_Mismatch,
      Final_Representation_Multiple_Blockers,
      Final_Representation_Indeterminate);

   type Final_Representation_Context_Info is record
      Id                         : Final_Representation_Row_Id := No_Final_Representation_Row;
      Kind                       : Final_Representation_Context_Kind := Final_Representation_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Freezing_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Representation_Status      : Rep_CPD.Representation_Tasking_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Not_Checked;
      Cross_Unit_Status          : Cross_Final.Cross_Unit_Final_Status := Cross_Final.Cross_Unit_Final_Not_Checked;
      Generic_Cycle_Status       : Generic_Cycles.Nested_Generic_Closure_Status := Generic_Cycles.Nested_Generic_Not_Checked;
      AST_Repair_Status          : Rep_AST.Representation_Operational_AST_Repair_Status := Rep_AST.Representation_Operational_AST_Not_Checked;
      Discriminant_Status        : Disc_Consumer.Discriminant_Consumer_Status := Disc_Consumer.Discriminant_Consumer_Not_Checked;
      Accessibility_Status       : Access_Final.Master_Scope_Final_Status := Access_Final.Master_Scope_Final_Not_Checked;
      Elaboration_Status         : Elab_Final.Final_Elaboration_Status := Elab_Final.Final_Elaboration_Not_Checked;
      Tasking_Status             : Task_Final.Final_Tasking_Status := Task_Final.Final_Tasking_Not_Checked;
      Requires_Cross_Unit        : Boolean := False;
      Requires_Generic_Cycle     : Boolean := False;
      Requires_AST_Repair        : Boolean := False;
      Requires_Discriminant      : Boolean := False;
      Requires_Accessibility     : Boolean := False;
      Requires_Elaboration       : Boolean := False;
      Requires_Tasking           : Boolean := False;
      Generic_Formal_Freezing_Error : Boolean := False;
      Inherited_Operational_Attribute_Error : Boolean := False;
      Stream_Attribute_View_Error : Boolean := False;
      Private_Full_View_Freezing_Error : Boolean := False;
      Implicit_Freezing_Order_Error : Boolean := False;
      Record_Layout_Finalization_Error : Boolean := False;
      Variant_Discriminant_Layout_Error : Boolean := False;
      Source_Fingerprint         : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Final_Representation_Info is record
      Id                         : Final_Representation_Row_Id := No_Final_Representation_Row;
      Context                    : Final_Representation_Row_Id := No_Final_Representation_Row;
      Kind                       : Final_Representation_Context_Kind := Final_Representation_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Freezing_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status                     : Final_Representation_Status := Final_Representation_Not_Checked;
      Target_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Unit_Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Component_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Count              : Natural := 0;
      Source_Fingerprint         : Natural := 0;
      Fingerprint                : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
   end record;

   type Final_Representation_Context_Model is private;
   type Final_Representation_Model is private;
   type Final_Representation_Set is private;

   procedure Clear (Model : in out Final_Representation_Context_Model);
   procedure Add_Context (Model : in out Final_Representation_Context_Model; Info : Final_Representation_Context_Info);
   function Context_Count (Model : Final_Representation_Context_Model) return Natural;
   function Context_At (Model : Final_Representation_Context_Model; Index : Positive) return Final_Representation_Context_Info;
   function Fingerprint (Model : Final_Representation_Context_Model) return Natural;

   function Build (Contexts : Final_Representation_Context_Model) return Final_Representation_Model;
   function Row_Count (Model : Final_Representation_Model) return Natural;
   function Row_At (Model : Final_Representation_Model; Index : Positive) return Final_Representation_Info;
   function First_For_Node (Model : Final_Representation_Model; Node : Editor.Ada_Syntax_Tree.Node_Id) return Final_Representation_Info;
   function Rows_For_Status (Model : Final_Representation_Model; Status : Final_Representation_Status) return Final_Representation_Set;
   function Rows_For_Kind (Model : Final_Representation_Model; Kind : Final_Representation_Context_Kind) return Final_Representation_Set;
   function Set_Count (Set : Final_Representation_Set) return Natural;
   function Set_At (Set : Final_Representation_Set; Index : Positive) return Final_Representation_Info;
   function Count_Status (Model : Final_Representation_Model; Status : Final_Representation_Status) return Natural;
   function Count_Kind (Model : Final_Representation_Model; Kind : Final_Representation_Context_Kind) return Natural;

   function Legal_Count (Model : Final_Representation_Model) return Natural;
   function Error_Count (Model : Final_Representation_Model) return Natural;
   function Cross_Unit_Error_Count (Model : Final_Representation_Model) return Natural;
   function Generic_Error_Count (Model : Final_Representation_Model) return Natural;
   function AST_Repair_Error_Count (Model : Final_Representation_Model) return Natural;
   function Discriminant_Error_Count (Model : Final_Representation_Model) return Natural;
   function Accessibility_Error_Count (Model : Final_Representation_Model) return Natural;
   function Elaboration_Error_Count (Model : Final_Representation_Model) return Natural;
   function Tasking_Error_Count (Model : Final_Representation_Model) return Natural;
   function Freezing_Order_Error_Count (Model : Final_Representation_Model) return Natural;
   function Indeterminate_Count (Model : Final_Representation_Model) return Natural;
   function Fingerprint (Model : Final_Representation_Model) return Natural;

   function Is_Legal (Status : Final_Representation_Status) return Boolean;
   function Is_Cross_Unit_Error (Status : Final_Representation_Status) return Boolean;
   function Is_Generic_Error (Status : Final_Representation_Status) return Boolean;
   function Is_AST_Repair_Error (Status : Final_Representation_Status) return Boolean;
   function Is_Discriminant_Error (Status : Final_Representation_Status) return Boolean;
   function Is_Accessibility_Error (Status : Final_Representation_Status) return Boolean;
   function Is_Elaboration_Error (Status : Final_Representation_Status) return Boolean;
   function Is_Tasking_Error (Status : Final_Representation_Status) return Boolean;
   function Is_Freezing_Order_Error (Status : Final_Representation_Status) return Boolean;
   function Is_Indeterminate (Status : Final_Representation_Status) return Boolean;
   function Has_Error (Info : Final_Representation_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Final_Representation_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Final_Representation_Info);

   type Final_Representation_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Final_Representation_Set is record
      Items : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Final_Representation_Model is record
      Items : Row_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Cross_Unit_Error_Total : Natural := 0;
      Generic_Error_Total : Natural := 0;
      AST_Repair_Error_Total : Natural := 0;
      Discriminant_Error_Total : Natural := 0;
      Accessibility_Error_Total : Natural := 0;
      Elaboration_Error_Total : Natural := 0;
      Tasking_Error_Total : Natural := 0;
      Freezing_Order_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality;
