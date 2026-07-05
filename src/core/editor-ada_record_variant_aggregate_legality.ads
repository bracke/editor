with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Predicate_Invariant_Use_Site_Legality;
with Editor.Ada_Representation_Layout_Stream_Integration_Legality;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Record_Variant_Aggregate_Legality is

   --  Case 1127 record/variant/discriminant aggregate semantic closure.
   --
   --  This package connects aggregate structural legality, discriminant and
   --  variant coverage, predicate/invariant use-site checks, and
   --  representation/layout integration.  It is snapshot-owned and bounded:
   --  callers feed already-extracted semantic facts; this package performs no
   --  parsing, rendering, compiler invocation, editor mutation, or file IO.

   subtype Semantic_Legality_Status is
     Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
   subtype Predicate_Use_Legality_Status is
     Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Status;
   subtype Representation_Integration_Status is
     Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Status;

   type Record_Aggregate_Context_Id is new Natural;
   No_Record_Aggregate_Context : constant Record_Aggregate_Context_Id := 0;

   type Record_Aggregate_Legality_Id is new Natural;
   No_Record_Aggregate_Legality : constant Record_Aggregate_Legality_Id := 0;

   type Record_Aggregate_Context_Kind is
     (Record_Aggregate_Context_Record_Aggregate,
      Record_Aggregate_Context_Extension_Aggregate,
      Record_Aggregate_Context_Variant_Aggregate,
      Record_Aggregate_Context_Array_Aggregate,
      Record_Aggregate_Context_Discriminant_Constraint,
      Record_Aggregate_Context_Component_Association,
      Record_Aggregate_Context_Representation_Layout_Use,
      Record_Aggregate_Context_Unknown);

   type Record_Aggregate_Legality_Status is
     (Record_Aggregate_Legality_Not_Checked,
      Record_Aggregate_Legality_Legal_Record_Aggregate,
      Record_Aggregate_Legality_Legal_Extension_Aggregate,
      Record_Aggregate_Legality_Legal_Variant_Aggregate,
      Record_Aggregate_Legality_Legal_Discriminant_Constraint,
      Record_Aggregate_Legality_Legal_Defaulted_Discriminants,
      Record_Aggregate_Legality_Legal_Layout_Compatible,
      Record_Aggregate_Legality_Missing_Component,
      Record_Aggregate_Legality_Duplicate_Component,
      Record_Aggregate_Legality_Component_Type_Mismatch,
      Record_Aggregate_Legality_Positional_After_Named,
      Record_Aggregate_Legality_Missing_Discriminant,
      Record_Aggregate_Legality_Duplicate_Discriminant,
      Record_Aggregate_Legality_Discriminant_Type_Mismatch,
      Record_Aggregate_Legality_Unconstrained_Without_Discriminants,
      Record_Aggregate_Legality_Variant_Choice_Missing,
      Record_Aggregate_Legality_Variant_Choice_Duplicate,
      Record_Aggregate_Legality_Variant_Choice_Overlap,
      Record_Aggregate_Legality_Variant_Coverage_Incomplete,
      Record_Aggregate_Legality_Variant_Choice_Unreachable,
      Record_Aggregate_Legality_Variant_Layout_Hole,
      Record_Aggregate_Legality_Variant_Layout_Overlap,
      Record_Aggregate_Legality_Discriminant_Layout_Error,
      Record_Aggregate_Legality_Linked_Aggregate_Error,
      Record_Aggregate_Legality_Linked_Predicate_Invariant_Error,
      Record_Aggregate_Legality_Linked_Representation_Error,
      Record_Aggregate_Legality_Private_View_Barrier,
      Record_Aggregate_Legality_Limited_View_Barrier,
      Record_Aggregate_Legality_Cross_Unit_Unresolved_View,
      Record_Aggregate_Legality_Indeterminate);

   type Record_Aggregate_Context_Info is record
      Id                  : Record_Aggregate_Context_Id := No_Record_Aggregate_Context;
      Kind                : Record_Aggregate_Context_Kind := Record_Aggregate_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Aggregate_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Node           : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Component_Count     : Natural := 0;
      Expected_Component_Count : Natural := 0;
      Missing_Component_Count  : Natural := 0;
      Duplicate_Component_Count : Natural := 0;
      Component_Type_Mismatch_Count : Natural := 0;
      Positional_After_Named : Boolean := False;
      Discriminant_Count : Natural := 0;
      Expected_Discriminant_Count : Natural := 0;
      Missing_Discriminant_Count : Natural := 0;
      Duplicate_Discriminant_Count : Natural := 0;
      Discriminant_Type_Mismatch_Count : Natural := 0;
      Type_Is_Unconstrained : Boolean := False;
      Has_Defaulted_Discriminants : Boolean := False;
      Variant_Choice_Count : Natural := 0;
      Expected_Variant_Choice_Count : Natural := 0;
      Duplicate_Variant_Choice_Count : Natural := 0;
      Overlapping_Variant_Choice_Count : Natural := 0;
      Unreachable_Variant_Choice_Count : Natural := 0;
      Variant_Coverage_Complete : Boolean := True;
      Variant_Layout_Hole : Boolean := False;
      Variant_Layout_Overlap : Boolean := False;
      Discriminant_Layout_Error : Boolean := False;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Cross_Unit_Unresolved : Boolean := False;
      Aggregate_Status : Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Predicate_Status : Predicate_Use_Legality_Status :=
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Not_Checked;
      Representation_Status : Representation_Integration_Status :=
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
   end record;

   type Record_Aggregate_Legality_Info is record
      Id                  : Record_Aggregate_Legality_Id := No_Record_Aggregate_Legality;
      Context             : Record_Aggregate_Context_Id := No_Record_Aggregate_Context;
      Kind                : Record_Aggregate_Context_Kind := Record_Aggregate_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Aggregate_Node      : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Type_Name           : Ada.Strings.Unbounded.Unbounded_String;
      Status              : Record_Aggregate_Legality_Status := Record_Aggregate_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Aggregate_Status    : Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Predicate_Status    : Predicate_Use_Legality_Status :=
        Editor.Ada_Predicate_Invariant_Use_Site_Legality.Predicate_Use_Legality_Not_Checked;
      Representation_Status : Representation_Integration_Status :=
        Editor.Ada_Representation_Layout_Stream_Integration_Legality.Representation_Integration_Not_Checked;
      Component_Count     : Natural := 0;
      Expected_Component_Count : Natural := 0;
      Discriminant_Count  : Natural := 0;
      Expected_Discriminant_Count : Natural := 0;
      Variant_Choice_Count : Natural := 0;
      Expected_Variant_Choice_Count : Natural := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Record_Aggregate_Context_Model is private;
   type Record_Aggregate_Result_Set is private;
   type Record_Aggregate_Legality_Model is private;

   procedure Clear (Model : in out Record_Aggregate_Context_Model);
   procedure Add_Context
     (Model : in out Record_Aggregate_Context_Model;
      Info  : Record_Aggregate_Context_Info);

   function Context_Count (Model : Record_Aggregate_Context_Model) return Natural;
   function Context_At
     (Model : Record_Aggregate_Context_Model;
      Index : Positive) return Record_Aggregate_Context_Info;
   function Fingerprint (Model : Record_Aggregate_Context_Model) return Natural;

   function Build
     (Contexts : Record_Aggregate_Context_Model) return Record_Aggregate_Legality_Model;

   function Legality_Count (Model : Record_Aggregate_Legality_Model) return Natural;
   function Legality_At
     (Model : Record_Aggregate_Legality_Model;
      Index : Positive) return Record_Aggregate_Legality_Info;
   function First_For_Node
     (Model : Record_Aggregate_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Record_Aggregate_Legality_Info;
   function Rows_For_Status
     (Model  : Record_Aggregate_Legality_Model;
      Status : Record_Aggregate_Legality_Status) return Record_Aggregate_Result_Set;
   function Rows_For_Kind
     (Model : Record_Aggregate_Legality_Model;
      Kind  : Record_Aggregate_Context_Kind) return Record_Aggregate_Result_Set;
   function Rows_For_Type
     (Model     : Record_Aggregate_Legality_Model;
      Type_Name : String) return Record_Aggregate_Result_Set;

   function Result_Count (Results : Record_Aggregate_Result_Set) return Natural;
   function Result_At
     (Results : Record_Aggregate_Result_Set;
      Index   : Positive) return Record_Aggregate_Legality_Info;

   function Count_Status
     (Model  : Record_Aggregate_Legality_Model;
      Status : Record_Aggregate_Legality_Status) return Natural;
   function Count_Kind
     (Model : Record_Aggregate_Legality_Model;
      Kind  : Record_Aggregate_Context_Kind) return Natural;

   function Legal_Count (Model : Record_Aggregate_Legality_Model) return Natural;
   function Error_Count (Model : Record_Aggregate_Legality_Model) return Natural;
   function Variant_Error_Count (Model : Record_Aggregate_Legality_Model) return Natural;
   function Discriminant_Error_Count (Model : Record_Aggregate_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Record_Aggregate_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Record_Aggregate_Legality_Model) return Natural;
   function Fingerprint (Model : Record_Aggregate_Legality_Model) return Natural;

   function Has_Legality (Info : Record_Aggregate_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Record_Aggregate_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Record_Aggregate_Legality_Info);

   type Record_Aggregate_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Record_Aggregate_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Record_Aggregate_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Variant_Error_Total : Natural := 0;
      Discriminant_Error_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Record_Variant_Aggregate_Legality;
