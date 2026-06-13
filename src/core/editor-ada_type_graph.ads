with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Type_Graph is

   --  Compiler-grade type-system foundation.  This package derives a stable,
   --  parser-owned type graph from type/subtype/formal-type declarations and
   --  direct visibility.  It intentionally stops at declaration-derived type
   --  relationships; private-view completion, full constraint legality,
   --  implicit conversions, and cross-unit closure are layered later.

   type Type_Category is
     (Type_Category_Unknown,
      Type_Category_Integer,
      Type_Category_Modular,
      Type_Category_Floating,
      Type_Category_Fixed,
      Type_Category_Array,
      Type_Category_Record,
      Type_Category_Access,
      Type_Category_Interface,
      Type_Category_Derived,
      Type_Category_Subtype,
      Type_Category_Private,
      Type_Category_Formal);

   type Type_Relation_Status is
     (Type_Relation_No_Base,
      Type_Relation_Base_Resolved,
      Type_Relation_Base_Unresolved,
      Type_Relation_Base_Ambiguous);

   type Type_View_Status is
     (Type_View_Ordinary,
      Type_View_Private_Partial,
      Type_View_Private_Full,
      Type_View_Private_Completion_Unresolved);

   type Type_Id is new Natural;
   No_Type : constant Type_Id := 0;

   type Type_Info is record
      Id                : Type_Id := No_Type;
      Declaration       : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Node              : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region            : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name              : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Category          : Type_Category := Type_Category_Unknown;
      Base_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Base   : Ada.Strings.Unbounded.Unbounded_String;
      Base_Declaration  : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Base_Type         : Type_Id := No_Type;
      Relation_Status   : Type_Relation_Status := Type_Relation_No_Base;
      View_Status       : Type_View_Status := Type_View_Ordinary;
      Partial_View      : Type_Id := No_Type;
      Full_View         : Type_Id := No_Type;
      Start_Line        : Positive := 1;
      End_Line          : Positive := 1;
      Fingerprint       : Natural := 0;
   end record;

   type Compatibility_Status is
     (Type_Compatibility_Not_Checked,
      Type_Compatibility_Exact_Type,
      Type_Compatibility_Subtype_Of,
      Type_Compatibility_Derived_From,
      Type_Compatibility_Class_Wide,
      Type_Compatibility_Known_Different_Root,
      Type_Compatibility_Indeterminate);

   type Type_Model is private;

   procedure Clear (Model : in out Type_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
      return Type_Model;

   function Has_Types (Model : Type_Model) return Boolean;
   function Type_Count (Model : Type_Model) return Natural;
   function Type_At (Model : Type_Model; Index : Positive) return Type_Info;
   function Type_Node (Model : Type_Model; Id : Type_Id) return Type_Info;

   function Type_For_Declaration
     (Model       : Type_Model;
      Declaration : Editor.Ada_Direct_Visibility.Declaration_Id) return Type_Id;

   function Lookup_Type
     (Model  : Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Type_Id;

   function Is_Derived_From
     (Model    : Type_Model;
      Derived  : Type_Id;
      Ancestor : Type_Id) return Boolean;

   function Compatibility
     (Model    : Type_Model;
      Expected : Type_Id;
      Actual   : Type_Id) return Compatibility_Status;

   function Class_Wide_Compatibility
     (Model         : Type_Model;
      Expected_Root : Type_Id;
      Actual        : Type_Id) return Compatibility_Status;

   function Fingerprint (Model : Type_Model) return Natural;

private
   package Type_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Type_Info);

   type Type_Model is record
      Types              : Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Type_Graph;
