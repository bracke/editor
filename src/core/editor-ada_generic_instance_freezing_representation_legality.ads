with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Freezing_Points;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Generic_Formal_Package_Substitutions;
with Editor.Ada_Generic_Instantiated_Body_Analysis;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tagged_Derived_Legality;

package Editor.Ada_Generic_Instance_Freezing_Representation_Legality is

   --  Wide compiler-grade semantic legality building block for Case 1105.
   --  This package connects generic instance/body substitutions with freezing
   --  and representation effects.  It deliberately consumes existing semantic
   --  models instead of projecting another UI surface: callers provide
   --  snapshot-owned generic, representation, assignment, return, conversion,
   --  and tagged facts, and this package classifies cross-layer legality
   --  without parsing, saving, reloading, compiling, or mutating editor state.

   type Instance_Context_Id is new Natural;
   No_Instance_Context : constant Instance_Context_Id := 0;

   type Instance_Legality_Id is new Natural;
   No_Instance_Legality : constant Instance_Legality_Id := 0;

   type Instance_Context_Kind is
     (Instance_Context_Generic_Instance,
      Instance_Context_Body_Substitution,
      Instance_Context_Formal_Package_Substitution,
      Instance_Context_Instance_Freezing,
      Instance_Context_Representation_Item,
      Instance_Context_Instance_Body_Expression,
      Instance_Context_Tagged_Derived_Effect,
      Instance_Context_Unknown);

   type Instance_Legality_Status is
     (Instance_Legality_Not_Checked,
      Instance_Legality_Legal_Instance,
      Instance_Legality_Legal_Body_Substitution,
      Instance_Legality_Legal_Default_Substitution,
      Instance_Legality_Legal_Formal_Package_Substitution,
      Instance_Legality_Legal_Boxed_Formal_Package,
      Instance_Legality_Legal_Instance_Freezing,
      Instance_Legality_Legal_Representation_Item,
      Instance_Legality_Body_Private_View_Barrier,
      Instance_Legality_Body_Limited_View_Barrier,
      Instance_Legality_Body_Cross_Unit_Unresolved,
      Instance_Legality_Body_Object_Mismatch,
      Instance_Legality_Body_Object_Unknown,
      Instance_Legality_Missing_Body_Contract,
      Instance_Legality_Body_Contract_Mismatch,
      Instance_Legality_Formal_Package_Mismatch,
      Instance_Legality_Formal_Package_Missing,
      Instance_Legality_Formal_Package_Wrong_Generic,
      Instance_Legality_Formal_Package_Unresolved,
      Instance_Legality_Formal_Package_Malformed,
      Instance_Legality_Instance_Freezes_Target,
      Instance_Legality_Representation_After_Instance_Freezing,
      Instance_Legality_Representation_Target_Unresolved,
      Instance_Legality_Representation_Target_Ambiguous,
      Instance_Legality_Representation_Target_Kind_Mismatch,
      Instance_Legality_Representation_Static_Error,
      Instance_Legality_Representation_Profile_Error,
      Instance_Legality_Representation_Operational_Error,
      Instance_Legality_Assignment_Error,
      Instance_Legality_Return_Error,
      Instance_Legality_Conversion_Access_Aggregate_Error,
      Instance_Legality_Tagged_Derived_Error,
      Instance_Legality_Unknown);

   type Instance_Context_Info is record
      Id                  : Instance_Context_Id := No_Instance_Context;
      Kind                : Instance_Context_Kind := Instance_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance            : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal              : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Body_Substitution   : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Substitution_Id :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.No_Instantiated_Body_Substitution;
      Formal_Package_Substitution : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Id :=
        Editor.Ada_Generic_Formal_Package_Substitutions.No_Formal_Package_Substitution;
      Freezable           : Editor.Ada_Freezing_Points.Freezable_Id :=
        Editor.Ada_Freezing_Points.No_Freezable;
      Linked_Assignment   : Editor.Ada_Assignment_Legality.Assignment_Context_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Context;
      Linked_Return       : Editor.Ada_Return_Legality.Return_Context_Id :=
        Editor.Ada_Return_Legality.No_Return_Context;
      Linked_Expression   : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Context_Id :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.No_Semantic_Context;
      Linked_Tagged       : Editor.Ada_Tagged_Derived_Legality.Tagged_Context_Id :=
        Editor.Ada_Tagged_Derived_Legality.No_Tagged_Context;
      Instance_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Instance_Name : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Body_Status         : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Status :=
        Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Not_Checked;
      Formal_Package_Status : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Status :=
        Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Not_Checked;
      Freeze_Status       : Editor.Ada_Freezing_Points.Freezing_Status :=
        Editor.Ada_Freezing_Points.Freezing_Not_Frozen;
      Representation_Status : Editor.Ada_Representation_Legality.Representation_Legality_Status :=
        Editor.Ada_Representation_Legality.Representation_Legality_Ok;
      Instance_Freezes_Target : Boolean := False;
      Representation_After_Instance_Freezing : Boolean := False;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Instance_Legality_Info is record
      Id                  : Instance_Legality_Id := No_Instance_Legality;
      Context             : Instance_Context_Id := No_Instance_Context;
      Kind                : Instance_Context_Kind := Instance_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Formal_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Representation_Node : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance            : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Formal              : Editor.Ada_Generic_Contracts.Generic_Formal_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Formal;
      Status              : Instance_Legality_Status := Instance_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Instance_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name : Ada.Strings.Unbounded.Unbounded_String;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Instance_Context_Model is private;
   type Instance_Result_Set is private;
   type Instance_Legality_Model is private;

   procedure Clear (Model : in out Instance_Context_Model);
   procedure Add_Context
     (Model   : in out Instance_Context_Model;
      Context : Instance_Context_Info);

   function Context_Count (Model : Instance_Context_Model) return Natural;
   function Context_At
     (Model : Instance_Context_Model;
      Index : Positive) return Instance_Context_Info;
   function Fingerprint (Model : Instance_Context_Model) return Natural;

   function Build
     (Contexts      : Instance_Context_Model;
      Bodies        : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model;
      Formal_Packages : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model;
      Freezing      : Editor.Ada_Freezing_Points.Freezing_Model;
      Representation : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Assignments   : Editor.Ada_Assignment_Legality.Assignment_Legality_Model;
      Returns       : Editor.Ada_Return_Legality.Return_Legality_Model;
      Expressions   : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
      Tagged_Model        : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model)
      return Instance_Legality_Model;

   function Build_Contexts_From_Models
     (Contracts       : Editor.Ada_Generic_Contracts.Generic_Contract_Model;
      Bodies          : Editor.Ada_Generic_Instantiated_Body_Analysis.Instantiated_Body_Model;
      Formal_Packages : Editor.Ada_Generic_Formal_Package_Substitutions.Formal_Package_Substitution_Model;
      Freezing        : Editor.Ada_Freezing_Points.Freezing_Model;
      Representation  : Editor.Ada_Representation_Legality.Representation_Legality_Model)
      return Instance_Context_Model;

   function Legality_Count (Model : Instance_Legality_Model) return Natural;
   function Legality_At
     (Model : Instance_Legality_Model;
      Index : Positive) return Instance_Legality_Info;

   function First_For_Context
     (Model   : Instance_Legality_Model;
      Context : Instance_Context_Id) return Instance_Legality_Info;
   function First_For_Instance
     (Model    : Instance_Legality_Model;
      Instance : Editor.Ada_Generic_Contracts.Generic_Instance_Id) return Instance_Legality_Info;
   function First_For_Node
     (Model : Instance_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Instance_Legality_Info;
   function Rows_For_Status
     (Model  : Instance_Legality_Model;
      Status : Instance_Legality_Status) return Instance_Result_Set;
   function Rows_For_Kind
     (Model : Instance_Legality_Model;
      Kind  : Instance_Context_Kind) return Instance_Result_Set;
   function Rows_For_Target
     (Model : Instance_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Instance_Result_Set;

   function Result_Count (Results : Instance_Result_Set) return Natural;
   function Result_At
     (Results : Instance_Result_Set;
      Index   : Positive) return Instance_Legality_Info;

   function Count_Status
     (Model  : Instance_Legality_Model;
      Status : Instance_Legality_Status) return Natural;
   function Count_Kind
     (Model : Instance_Legality_Model;
      Kind  : Instance_Context_Kind) return Natural;

   function Legal_Count (Model : Instance_Legality_Model) return Natural;
   function Error_Count (Model : Instance_Legality_Model) return Natural;
   function Warning_Count (Model : Instance_Legality_Model) return Natural;
   function Generic_Body_Error_Count (Model : Instance_Legality_Model) return Natural;
   function Formal_Package_Error_Count (Model : Instance_Legality_Model) return Natural;
   function Freezing_Error_Count (Model : Instance_Legality_Model) return Natural;
   function Representation_Error_Count (Model : Instance_Legality_Model) return Natural;
   function Linked_Semantic_Error_Count (Model : Instance_Legality_Model) return Natural;
   function Fingerprint (Model : Instance_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Instance_Context_Info);

   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Instance_Legality_Info);

   type Instance_Context_Model is record
      Entries           : Context_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

   type Instance_Result_Set is record
      Entries : Legality_Vectors.Vector;
   end record;

   type Instance_Legality_Model is record
      Entries                 : Legality_Vectors.Vector;
      Legal_Total             : Natural := 0;
      Error_Total             : Natural := 0;
      Warning_Total           : Natural := 0;
      Generic_Body_Error_Total : Natural := 0;
      Formal_Package_Error_Total : Natural := 0;
      Freezing_Error_Total    : Natural := 0;
      Representation_Error_Total : Natural := 0;
      Linked_Semantic_Error_Total : Natural := 0;
      Model_Fingerprint       : Natural := 0;
   end record;

end Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
