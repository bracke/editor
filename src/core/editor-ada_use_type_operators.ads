with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Use_Visibility;

package Editor.Ada_Use_Type_Operators is

   --  Compiler-grade semantic foundation for Ada use-type visibility.
   --  The model consumes parser-owned syntax-tree, declarative-region,
   --  direct-visibility, and use-clause data and records which primitive
   --  operator/subprogram declarations are made potentially visible by
   --  ``use type`` and ``use all type`` clauses.  It is deterministic,
   --  snapshot-owned, renderer-free, and deliberately stops before expected
   --  type filtering, overload resolution, and full primitive-operation
   --  legality checks.

   type Primitive_Use_Kind is
     (Primitive_Use_Type_Operator,
      Primitive_Use_All_Type_Subprogram);

   type Primitive_Use_Status is
     (Primitive_Use_Unresolved_Type,
      Primitive_Use_Target_Not_Type,
      Primitive_Use_No_Primitive_Region,
      Primitive_Use_Found);

   type Primitive_Use_Id is new Natural;
   No_Primitive_Use : constant Primitive_Use_Id := 0;

   type Primitive_Use_Info is record
      Id                   : Primitive_Use_Id := No_Primitive_Use;
      Kind                 : Primitive_Use_Kind := Primitive_Use_Type_Operator;
      Status               : Primitive_Use_Status := Primitive_Use_Unresolved_Type;
      Clause               : Editor.Ada_Use_Visibility.Use_Clause_Id :=
        Editor.Ada_Use_Visibility.No_Use_Clause;
      Clause_Region        : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Type_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Type_Name : Ada.Strings.Unbounded.Unbounded_String;
      Type_Declaration     : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Primitive_Region     : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Primitive_Declaration : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Primitive_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Primitive : Ada.Strings.Unbounded.Unbounded_String;
      Is_Operator          : Boolean := False;
      Start_Line           : Positive := 1;
      End_Line             : Positive := 1;
      Fingerprint          : Natural := 0;
   end record;

   type Primitive_Use_Model is private;

   procedure Clear (Model : in out Primitive_Use_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model)
      return Primitive_Use_Model;

   function Has_Primitive_Uses (Model : Primitive_Use_Model) return Boolean;
   function Primitive_Use_Count (Model : Primitive_Use_Model) return Natural;
   function Primitive_Use_At
     (Model : Primitive_Use_Model;
      Index : Positive) return Primitive_Use_Info;
   function Primitive_Use
     (Model : Primitive_Use_Model;
      Id    : Primitive_Use_Id) return Primitive_Use_Info;

   function Lookup_Operator
     (Model  : Primitive_Use_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Editor.Ada_Direct_Visibility.Lookup_Result;

   function Fingerprint (Model : Primitive_Use_Model) return Natural;

private
   package Primitive_Use_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Primitive_Use_Info);

   type Primitive_Use_Model is record
      Uses               : Primitive_Use_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Use_Type_Operators;
