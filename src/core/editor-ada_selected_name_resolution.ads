with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Cross_Unit_Lookup_Integration;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Use_Visibility;

package Editor.Ada_Selected_Name_Resolution is

   --  Compiler-grade selected-name resolution foundation.  This package
   --  resolves package/object-prefix selected names from parser-owned syntax
   --  tree nodes using the declarative-region, direct-visibility, and
   --  use-visibility models.  It records deterministic prefix and selector
   --  metadata for later overload, type, and legality layers without reading
   --  files, mutating editor state, or involving renderer-side parsing.

   type Selected_Name_Status is
     (Selected_Name_Not_Resolved,
      Selected_Name_Prefix_Not_Found,
      Selected_Name_Prefix_Ambiguous,
      Selected_Name_Prefix_Has_No_Region,
      Selected_Name_Selector_Not_Found,
      Selected_Name_Selector_Ambiguous,
      Selected_Name_Found,
      Selected_Name_Cross_Unit_Prefix_Found,
      Selected_Name_Cross_Unit_Use_Prefix_Found,
      Selected_Name_Cross_Unit_Limited_Prefix,
      Selected_Name_Cross_Unit_Private_Prefix,
      Selected_Name_Cross_Unit_Prefix_Missing,
      Selected_Name_Cross_Unit_Prefix_Ambiguous,
      Selected_Name_Cross_Unit_Prefix_Overflow);

   type Selected_Name_Id is new Natural;
   No_Selected_Name : constant Selected_Name_Id := 0;

   type Selected_Name_Info is record
      Id                   : Selected_Name_Id := No_Selected_Name;
      Node                 : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Region               : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Prefix               : Ada.Strings.Unbounded.Unbounded_String;
      Selector             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Prefix    : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Selector  : Ada.Strings.Unbounded.Unbounded_String;
      Prefix_Declaration   : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Prefix_Region        : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Selector_Declaration : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Cross_Unit_Lookup    : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Id :=
        Editor.Ada_Cross_Unit_Lookup_Integration.No_Cross_Unit_Lookup;
      Cross_Unit_Status    : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Status :=
        Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Not_Found;
      Cross_Unit_Target    : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Path      : Ada.Strings.Unbounded.Unbounded_String;
      Status               : Selected_Name_Status := Selected_Name_Not_Resolved;
      Start_Line           : Positive := 1;
      End_Line             : Positive := 1;
      Fingerprint          : Natural := 0;
   end record;

   type Selected_Name_Model is private;

   procedure Clear (Model : in out Selected_Name_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model)
      return Selected_Name_Model;

   function Build_With_Cross_Unit
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Cross_Unit : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model)
      return Selected_Name_Model;

   function Has_Selected_Names (Model : Selected_Name_Model) return Boolean;
   function Selected_Name_Count (Model : Selected_Name_Model) return Natural;
   function Selected_Name_At
     (Model : Selected_Name_Model;
      Index : Positive) return Selected_Name_Info;
   function Selected_Name
     (Model : Selected_Name_Model;
      Id    : Selected_Name_Id) return Selected_Name_Info;

   function Selected_Name_For_Node
     (Model : Selected_Name_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Selected_Name_Info;

   function Resolve_Selected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Selected_Name_Info;

   function Resolve_Selected_With_Cross_Unit
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Uses       : Editor.Ada_Use_Visibility.Use_Visibility_Model;
      Cross_Unit : Editor.Ada_Cross_Unit_Lookup_Integration.Cross_Unit_Lookup_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String) return Selected_Name_Info;

   function Fingerprint (Model : Selected_Name_Model) return Natural;

private
   package Selected_Name_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Selected_Name_Info);

   type Selected_Name_Model is record
      Names              : Selected_Name_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Selected_Name_Resolution;
