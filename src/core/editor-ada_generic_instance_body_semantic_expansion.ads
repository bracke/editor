with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Lifetime_Legality;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Predicate_Invariant_Use_Site_Legality;
with Editor.Ada_Representation_Layout_Stream_Integration_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Instance_Body_Semantic_Expansion is

   --  Pass1125 compiler-grade generic-instance body expansion layer.  This
   --  package projects actual/formal instantiated-body substitutions into the
   --  widened semantic legality layers used by the editor: overload legality,
   --  accessibility/lifetime, contract aspects, dataflow Global/Depends,
   --  definite initialization, predicate/invariant use sites, and
   --  representation/layout/stream legality.  It does not rewrite generic
   --  bodies, invoke a compiler, parse from the renderer, save/reload files,
   --  mutate dirty state, or expose command/workspace/render side effects.

   subtype Instantiated_Body_Status is
     Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Status;
   subtype Overload_Legality_Status is
     Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;
   subtype Accessibility_Legality_Status is
     Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;
   subtype Contract_Legality_Status is
     Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Status;
   subtype Dataflow_Legality_Status is
     Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Status;
   subtype Initialization_Legality_Status is
     Editor.Ada_Definite_Initialization_Flow_Legality.Initialization_Legality_Status;
   subtype Predicate_Use_Legality_Status is
     Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Status;
   subtype Representation_Integration_Status is
     Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Status;

   type Generic_Body_Expansion_Context_Id is new Natural;
   No_Generic_Body_Expansion_Context : constant Generic_Body_Expansion_Context_Id := 0;

   type Generic_Body_Expansion_Id is new Natural;
   No_Generic_Body_Expansion : constant Generic_Body_Expansion_Id := 0;

   type Generic_Body_Expansion_Context_Kind is
     (Generic_Body_Expansion_Formal_Object,
      Generic_Body_Expansion_Formal_Type,
      Generic_Body_Expansion_Formal_Subprogram,
      Generic_Body_Expansion_Formal_Package,
      Generic_Body_Expansion_Default_Actual,
      Generic_Body_Expansion_Body_Declaration,
      Generic_Body_Expansion_Body_Statement,
      Generic_Body_Expansion_Body_Expression,
      Generic_Body_Expansion_Representation_Item,
      Generic_Body_Expansion_Unknown);

   type Generic_Body_Expansion_Status is
     (Generic_Body_Expansion_Not_Checked,
      Generic_Body_Expansion_Legal_Substitution,
      Generic_Body_Expansion_Legal_Default_Substitution,
      Generic_Body_Expansion_Legal_Overload,
      Generic_Body_Expansion_Legal_Accessibility,
      Generic_Body_Expansion_Legal_Contract,
      Generic_Body_Expansion_Legal_Dataflow,
      Generic_Body_Expansion_Legal_Initialization,
      Generic_Body_Expansion_Legal_Predicate_Invariant,
      Generic_Body_Expansion_Legal_Representation,
      Generic_Body_Expansion_Private_View_Barrier,
      Generic_Body_Expansion_Limited_View_Barrier,
      Generic_Body_Expansion_Cross_Unit_Unresolved,
      Generic_Body_Expansion_Object_Mismatch,
      Generic_Body_Expansion_Object_Unknown,
      Generic_Body_Expansion_Missing_Body_Contract,
      Generic_Body_Expansion_Contract_Mismatch,
      Generic_Body_Expansion_Overload_Error,
      Generic_Body_Expansion_Accessibility_Error,
      Generic_Body_Expansion_Contract_Error,
      Generic_Body_Expansion_Dataflow_Error,
      Generic_Body_Expansion_Initialization_Error,
      Generic_Body_Expansion_Predicate_Invariant_Error,
      Generic_Body_Expansion_Representation_Error,
      Generic_Body_Expansion_Multiple_Semantic_Blockers,
      Generic_Body_Expansion_Indeterminate);

   type Generic_Body_Expansion_Context_Info is record
      Id                     : Generic_Body_Expansion_Context_Id := No_Generic_Body_Expansion_Context;
      Kind                   : Generic_Body_Expansion_Context_Kind := Generic_Body_Expansion_Unknown;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Substitution           : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Id :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.No_Instantiated_Body_Substitution;
      Formal_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Subtype         : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Text            : Ada.Strings.Unbounded.Unbounded_String;
      Is_Default_Substitution : Boolean := False;
      Body_Status            : Instantiated_Body_Status :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Not_Checked;
      Overload_Status        : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Accessibility_Status   : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Contract_Status        : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Dataflow_Status        : Dataflow_Legality_Status :=
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Not_Checked;
      Initialization_Status  : Initialization_Legality_Status :=
        Editor.Ada_Definite_Initialization_Flow_Legality.Initialization_Legality_Not_Checked;
      Predicate_Status       : Predicate_Use_Legality_Status :=
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Not_Checked;
      Representation_Status  : Representation_Integration_Status :=
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
   end record;

   type Generic_Body_Expansion_Info is record
      Id                     : Generic_Body_Expansion_Id := No_Generic_Body_Expansion;
      Context                : Generic_Body_Expansion_Context_Id := No_Generic_Body_Expansion_Context;
      Kind                   : Generic_Body_Expansion_Context_Kind := Generic_Body_Expansion_Unknown;
      Status                 : Generic_Body_Expansion_Status := Generic_Body_Expansion_Not_Checked;
      Node                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Substitution           : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Id :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.No_Instantiated_Body_Substitution;
      Formal_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Text            : Ada.Strings.Unbounded.Unbounded_String;
      Message                : Ada.Strings.Unbounded.Unbounded_String;
      Detail                 : Ada.Strings.Unbounded.Unbounded_String;
      Body_Status            : Instantiated_Body_Status :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Not_Checked;
      Overload_Status        : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Accessibility_Status   : Accessibility_Legality_Status :=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Not_Checked;
      Contract_Status        : Contract_Legality_Status :=
        Editor.Ada_Contract_Aspect_Legality.Contract_Legality_Not_Checked;
      Dataflow_Status        : Dataflow_Legality_Status :=
        Editor.Ada_Dataflow_Global_Depends_Legality.Dataflow_Legality_Not_Checked;
      Initialization_Status  : Initialization_Legality_Status :=
        Editor.Ada_Definite_Initialization_Flow_Legality.Initialization_Legality_Not_Checked;
      Predicate_Status       : Predicate_Use_Legality_Status :=
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Not_Checked;
      Representation_Status  : Representation_Integration_Status :=
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked;
      Blocker_Count          : Natural := 0;
      Start_Line             : Positive := 1;
      Start_Column           : Positive := 1;
      End_Line               : Positive := 1;
      End_Column             : Positive := 1;
      Source_Fingerprint     : Natural := 0;
      Fingerprint            : Natural := 0;
   end record;

   type Generic_Body_Expansion_Context_Model is private;
   type Generic_Body_Expansion_Result_Set is private;
   type Generic_Body_Expansion_Model is private;

   procedure Clear (Model : in out Generic_Body_Expansion_Context_Model);
   procedure Add_Context
     (Model : in out Generic_Body_Expansion_Context_Model;
      Info  : Generic_Body_Expansion_Context_Info);
   function Context_Count (Model : Generic_Body_Expansion_Context_Model) return Natural;
   function Context_At
     (Model : Generic_Body_Expansion_Context_Model;
      Index : Positive) return Generic_Body_Expansion_Context_Info;
   function Fingerprint (Model : Generic_Body_Expansion_Context_Model) return Natural;

   function Build
     (Contexts : Generic_Body_Expansion_Context_Model) return Generic_Body_Expansion_Model;
   function Build_From_Instantiated_Bodies
     (Bodies : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model)
      return Generic_Body_Expansion_Model;

   function Row_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Row_At
     (Model : Generic_Body_Expansion_Model;
      Index : Positive) return Generic_Body_Expansion_Info;
   function First_For_Context
     (Model   : Generic_Body_Expansion_Model;
      Context : Generic_Body_Expansion_Context_Id) return Generic_Body_Expansion_Info;
   function First_For_Substitution
     (Model        : Generic_Body_Expansion_Model;
      Substitution : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Id)
      return Generic_Body_Expansion_Info;
   function Rows_For_Status
     (Model  : Generic_Body_Expansion_Model;
      Status : Generic_Body_Expansion_Status) return Generic_Body_Expansion_Result_Set;
   function Rows_For_Kind
     (Model : Generic_Body_Expansion_Model;
      Kind  : Generic_Body_Expansion_Context_Kind) return Generic_Body_Expansion_Result_Set;
   function Rows_For_Formal
     (Model       : Generic_Body_Expansion_Model;
      Formal_Name : String) return Generic_Body_Expansion_Result_Set;
   function Result_Count (Results : Generic_Body_Expansion_Result_Set) return Natural;
   function Result_At
     (Results : Generic_Body_Expansion_Result_Set;
      Index   : Positive) return Generic_Body_Expansion_Info;

   function Count_Status
     (Model  : Generic_Body_Expansion_Model;
      Status : Generic_Body_Expansion_Status) return Natural;
   function Legal_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Error_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function View_Barrier_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Overload_Error_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Accessibility_Error_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Contract_Error_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Dataflow_Error_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Initialization_Error_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Predicate_Error_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Representation_Error_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Multiple_Blocker_Count (Model : Generic_Body_Expansion_Model) return Natural;
   function Fingerprint (Model : Generic_Body_Expansion_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Body_Expansion_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Body_Expansion_Info);

   type Generic_Body_Expansion_Context_Model is record
      Entries           : Context_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

   type Generic_Body_Expansion_Result_Set is record
      Entries : Row_Vectors.Vector;
   end record;

   type Generic_Body_Expansion_Model is record
      Rows                       : Row_Vectors.Vector;
      Legal_Total                : Natural := 0;
      Error_Total                : Natural := 0;
      View_Barrier_Total         : Natural := 0;
      Overload_Error_Total       : Natural := 0;
      Accessibility_Error_Total  : Natural := 0;
      Contract_Error_Total       : Natural := 0;
      Dataflow_Error_Total       : Natural := 0;
      Initialization_Error_Total : Natural := 0;
      Predicate_Error_Total      : Natural := 0;
      Representation_Error_Total : Natural := 0;
      Multiple_Blocker_Total     : Natural := 0;
      Model_Fingerprint          : Natural := 0;
   end record;

end Editor.Ada_Generic_Instance_Body_Semantic_Expansion;
