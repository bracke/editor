with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Direct_Visibility is

   --  Compiler-grade name-resolution foundation over the parser-owned
   --  declarative-region model.  This package records declarations directly
   --  declared in each region and offers deterministic, case-insensitive Ada
   --  lookup through the current region and its enclosing regions.  It does
   --  not perform overload resolution, expected-type filtering, use-clause
   --  visibility, or legality checking.

   type Declaration_Kind is
     (Declaration_Package,
      Declaration_Subprogram,
      Declaration_Type,
      Declaration_Subtype,
      Declaration_Object,
      Declaration_Number,
      Declaration_Exception,
      Declaration_Generic,
      Declaration_Formal_Type,
      Declaration_Formal_Object,
      Declaration_Formal_Subprogram,
      Declaration_Formal_Package,
      Declaration_Task,
      Declaration_Protected,
      Declaration_Entry,
      Declaration_Renaming,
      Declaration_Instantiation,
      Declaration_Unknown);

   type Declaration_Id is new Natural;
   No_Declaration : constant Declaration_Id := 0;

   type Lookup_Status is
     (Lookup_Not_Found,
      Lookup_Found,
      Lookup_Ambiguous);

   type Declaration_Info is record
      Id          : Declaration_Id := No_Declaration;
      Kind        : Declaration_Kind := Declaration_Unknown;
      Name        : Ada.Strings.Unbounded.Unbounded_String;
      Normalized  : Ada.Strings.Unbounded.Unbounded_String;
      Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region      : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Start_Line  : Positive := 1;
      End_Line    : Positive := 1;
      Fingerprint : Natural := 0;
   end record;

   type Lookup_Result is record
      Status      : Lookup_Status := Lookup_Not_Found;
      Declaration : Declaration_Id := No_Declaration;
      Region      : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Match_Count : Natural := 0;
   end record;

   type Visibility_Model is private;

   procedure Clear (Model : in out Visibility_Model);

   function Build
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model)
      return Visibility_Model;

   function Has_Declarations (Model : Visibility_Model) return Boolean;
   function Declaration_Count (Model : Visibility_Model) return Natural;
   function Declaration_At
     (Model : Visibility_Model;
      Index : Positive) return Declaration_Info;
   function Declaration
     (Model : Visibility_Model;
      Id    : Declaration_Id) return Declaration_Info;

   function Direct_Declaration_Count
     (Model  : Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id) return Natural;

   function Direct_Declaration_At
     (Model  : Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Index  : Positive) return Declaration_Id;

   function Lookup_Direct
     (Model  : Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Lookup_Result;

   function Lookup_Visible
     (Model   : Visibility_Model;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Name    : String) return Lookup_Result;

   function Fingerprint (Model : Visibility_Model) return Natural;

private
   package Declaration_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Declaration_Info);

   type Visibility_Model is record
      Declarations       : Declaration_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Direct_Visibility;
