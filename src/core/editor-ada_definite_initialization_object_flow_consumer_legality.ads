with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Definite_Initialization_Flow_Legality;
with Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality is

   --  Pass1164 compiler-grade definite-initialization object-flow consumer
   --  legality.
   --
   --  This layer feeds the exact object-flow accessibility consumer result from
   --  Pass1163 into definite-initialization and flow-sensitive object-state
   --  legality.  It prevents read-before-write, out-parameter, return-object,
   --  component-initialization, exception-path, finalization, aggregate, and
   --  generic replay initialization conclusions from remaining confident when
   --  the matching object-flow/lifetime/discriminant/representation evidence is
   --  missing, mismatched, blocked, or indeterminate.

   package Init renames Editor.Ada_Definite_Initialization_Flow_Legality;
   package Obj_Flow renames Editor.Ada_Object_Flow_Accessibility_Consumer_Legality;

   type Initialization_Object_Flow_Row_Id is new Natural;
   No_Initialization_Object_Flow_Row : constant Initialization_Object_Flow_Row_Id := 0;

   type Initialization_Object_Flow_Status is
     (Initialization_Object_Flow_Not_Checked,
      Initialization_Object_Flow_Legal_Definite_Init_Accepted,
      Initialization_Object_Flow_Legal_Default_Init_Accepted,
      Initialization_Object_Flow_Legal_Explicit_Init_Accepted,
      Initialization_Object_Flow_Legal_Component_Init_Accepted,
      Initialization_Object_Flow_Legal_Out_Parameter_Accepted,
      Initialization_Object_Flow_Legal_Return_Object_Accepted,
      Initialization_Object_Flow_Legal_Exception_Path_Accepted,
      Initialization_Object_Flow_Legal_Finalization_Path_Accepted,
      Initialization_Object_Flow_Missing_Object_Flow_Row,
      Initialization_Object_Flow_Mismatched_Object_Flow_Kind,
      Initialization_Object_Flow_Return_Lifetime_Blocker,
      Initialization_Object_Flow_Allocator_Lifetime_Blocker,
      Initialization_Object_Flow_Access_Lifetime_Blocker,
      Initialization_Object_Flow_Generic_Lifetime_Blocker,
      Initialization_Object_Flow_Discriminant_Variant_Blocker,
      Initialization_Object_Flow_Representation_Blocker,
      Initialization_Object_Flow_Coverage_Blocker,
      Initialization_Object_Flow_Linked_Accessibility_Blocker,
      Initialization_Object_Flow_Linked_Generic_Replay_Blocker,
      Initialization_Object_Flow_Multiple_Object_Flow_Blockers,
      Initialization_Object_Flow_Preserved_Read_Before_Write,
      Initialization_Object_Flow_Preserved_Component_Read_Before_Write,
      Initialization_Object_Flow_Preserved_Partial_Component_Init,
      Initialization_Object_Flow_Preserved_Out_Parameter_Not_Assigned,
      Initialization_Object_Flow_Preserved_In_Out_Conditional_Assignment,
      Initialization_Object_Flow_Preserved_Return_Object_Not_Initialized,
      Initialization_Object_Flow_Preserved_Branch_Merge_Not_Definite,
      Initialization_Object_Flow_Preserved_Loop_Merge_Not_Definite,
      Initialization_Object_Flow_Preserved_Exception_Path_Loss,
      Initialization_Object_Flow_Preserved_Finalization_Uses_Uninitialized,
      Initialization_Object_Flow_Preserved_Use_After_Finalization,
      Initialization_Object_Flow_Preserved_Linked_Initialization_Error,
      Initialization_Object_Flow_Indeterminate);

   type Initialization_Object_Flow_Context_Info is record
      Id                         : Initialization_Object_Flow_Row_Id := No_Initialization_Object_Flow_Row;
      Kind                       : Init.Initialization_Context_Kind := Init.Initialization_Context_Unknown;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Initialization_Row         : Init.Initialization_Legality_Id := Init.No_Initialization_Legality;
      Initialization_Status      : Init.Initialization_Legality_Status := Init.Initialization_Legality_Not_Checked;
      Before_State               : Init.Object_State := Init.Object_State_Unknown;
      After_State                : Init.Object_State := Init.Object_State_Unknown;
      Flow                       : Init.Flow_State := Init.Flow_State_Unknown;
      Object_Flow_Row            : Obj_Flow.Object_Flow_Row_Id := Obj_Flow.No_Object_Flow_Row;
      Object_Flow_Status         : Obj_Flow.Object_Flow_Status := Obj_Flow.Object_Flow_Not_Checked;
      Object_Flow_Kind           : Obj_Flow.Object_Flow_Context_Kind := Obj_Flow.Object_Flow_Unknown;
      Object_Flow_Matches        : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Initialization_Fingerprint : Natural := 0;
      Object_Flow_Fingerprint    : Natural := 0;
   end record;

   type Initialization_Object_Flow_Info is record
      Id                         : Initialization_Object_Flow_Row_Id := No_Initialization_Object_Flow_Row;
      Context                    : Initialization_Object_Flow_Row_Id := No_Initialization_Object_Flow_Row;
      Kind                       : Init.Initialization_Context_Kind := Init.Initialization_Context_Unknown;
      Status                     : Initialization_Object_Flow_Status := Initialization_Object_Flow_Not_Checked;
      Node                       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Object_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Message                    : Ada.Strings.Unbounded.Unbounded_String;
      Detail                     : Ada.Strings.Unbounded.Unbounded_String;
      Initialization_Row         : Init.Initialization_Legality_Id := Init.No_Initialization_Legality;
      Initialization_Status      : Init.Initialization_Legality_Status := Init.Initialization_Legality_Not_Checked;
      Before_State               : Init.Object_State := Init.Object_State_Unknown;
      After_State                : Init.Object_State := Init.Object_State_Unknown;
      Flow                       : Init.Flow_State := Init.Flow_State_Unknown;
      Object_Flow_Row            : Obj_Flow.Object_Flow_Row_Id := Obj_Flow.No_Object_Flow_Row;
      Object_Flow_Status         : Obj_Flow.Object_Flow_Status := Obj_Flow.Object_Flow_Not_Checked;
      Object_Flow_Kind           : Obj_Flow.Object_Flow_Context_Kind := Obj_Flow.Object_Flow_Unknown;
      Object_Flow_Matches        : Natural := 0;
      Start_Line                 : Positive := 1;
      Start_Column               : Positive := 1;
      End_Line                   : Positive := 1;
      End_Column                 : Positive := 1;
      Source_Fingerprint         : Natural := 0;
      Initialization_Fingerprint : Natural := 0;
      Object_Flow_Fingerprint    : Natural := 0;
      Fingerprint                : Natural := 0;
   end record;

   type Initialization_Object_Flow_Context_Model is private;
   type Initialization_Object_Flow_Set is private;
   type Initialization_Object_Flow_Model is private;

   procedure Clear (Model : in out Initialization_Object_Flow_Context_Model);
   procedure Add_Context
     (Model : in out Initialization_Object_Flow_Context_Model;
      Info  : Initialization_Object_Flow_Context_Info);

   function Context_Count (Model : Initialization_Object_Flow_Context_Model) return Natural;
   function Context_At
     (Model : Initialization_Object_Flow_Context_Model;
      Index : Positive) return Initialization_Object_Flow_Context_Info;
   function Fingerprint (Model : Initialization_Object_Flow_Context_Model) return Natural;

   function Build
     (Contexts : Initialization_Object_Flow_Context_Model)
      return Initialization_Object_Flow_Model;

   function Row_Count (Model : Initialization_Object_Flow_Model) return Natural;
   function Row_At
     (Model : Initialization_Object_Flow_Model;
      Index : Positive) return Initialization_Object_Flow_Info;
   function First_For_Node
     (Model : Initialization_Object_Flow_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Initialization_Object_Flow_Info;
   function Rows_For_Status
     (Model  : Initialization_Object_Flow_Model;
      Status : Initialization_Object_Flow_Status) return Initialization_Object_Flow_Set;
   function Rows_For_Kind
     (Model : Initialization_Object_Flow_Model;
      Kind  : Init.Initialization_Context_Kind) return Initialization_Object_Flow_Set;
   function Rows_For_Object
     (Model : Initialization_Object_Flow_Model;
      Name  : String) return Initialization_Object_Flow_Set;

   function Set_Count (Results : Initialization_Object_Flow_Set) return Natural;
   function Set_At
     (Results : Initialization_Object_Flow_Set;
      Index   : Positive) return Initialization_Object_Flow_Info;

   function Count_Status
     (Model  : Initialization_Object_Flow_Model;
      Status : Initialization_Object_Flow_Status) return Natural;
   function Count_Kind
     (Model : Initialization_Object_Flow_Model;
      Kind  : Init.Initialization_Context_Kind) return Natural;

   function Legal_Count (Model : Initialization_Object_Flow_Model) return Natural;
   function Error_Count (Model : Initialization_Object_Flow_Model) return Natural;
   function Lifetime_Error_Count (Model : Initialization_Object_Flow_Model) return Natural;
   function Initialization_Error_Count (Model : Initialization_Object_Flow_Model) return Natural;
   function Representation_Error_Count (Model : Initialization_Object_Flow_Model) return Natural;
   function Coverage_Error_Count (Model : Initialization_Object_Flow_Model) return Natural;
   function Indeterminate_Count (Model : Initialization_Object_Flow_Model) return Natural;
   function Fingerprint (Model : Initialization_Object_Flow_Model) return Natural;

   function Has_Confident_Initialization_Flow
     (Info : Initialization_Object_Flow_Info) return Boolean;
   function Is_Lifetime_Error (Status : Initialization_Object_Flow_Status) return Boolean;
   function Is_Initialization_Error (Status : Initialization_Object_Flow_Status) return Boolean;
   function Is_Representation_Error (Status : Initialization_Object_Flow_Status) return Boolean;
   function Is_Coverage_Error (Status : Initialization_Object_Flow_Status) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Initialization_Object_Flow_Context_Info);
   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Initialization_Object_Flow_Info);

   type Initialization_Object_Flow_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Initialization_Object_Flow_Set is record
      Items : Row_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Initialization_Object_Flow_Model is record
      Rows : Row_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
