with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Generic_Contracts;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Generic_Renaming_Visibility is

   --  Compiler-grade generic renaming and nested instantiation visibility
   --  foundation.  This parser/snapshot-owned model records generic renaming
   --  declarations and generic instantiations whose target is a renamed
   --  generic, including nested instantiations inside generic formal/body
   --  regions.  It does not expand templates; it exposes deterministic
   --  lookup-facing metadata for later contract matching layers.

   type Generic_Renaming_Status is
     (Generic_Renaming_Target_Resolved,
      Generic_Renaming_Target_Unresolved,
      Generic_Renaming_Target_Ambiguous,
      Generic_Renaming_Target_Not_Generic,
      Generic_Renaming_Malformed,
      Generic_Renaming_Unknown);

   type Nested_Generic_Instantiation_Status is
     (Nested_Generic_Instantiation_Direct_Target,
      Nested_Generic_Instantiation_Renamed_Target,
      Nested_Generic_Instantiation_Target_Unresolved,
      Nested_Generic_Instantiation_Target_Ambiguous,
      Nested_Generic_Instantiation_Target_Not_Generic,
      Nested_Generic_Instantiation_Malformed,
      Nested_Generic_Instantiation_Unknown);

   type Generic_Renaming_Id is new Natural;
   No_Generic_Renaming : constant Generic_Renaming_Id := 0;

   type Generic_Renaming_Info is record
      Id                  : Generic_Renaming_Id := No_Generic_Renaming;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region              : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Declaration          : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Name                : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target   : Ada.Strings.Unbounded.Unbounded_String;
      Target_Declaration  : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Target_Region       : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Target_Formal_Count : Natural := 0;
      Candidate_Count     : Natural := 0;
      Status              : Generic_Renaming_Status := Generic_Renaming_Unknown;
      Start_Line          : Positive := 1;
      End_Line            : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Nested_Generic_Instantiation_Info is record
      Instance            : Editor.Ada_Generic_Contracts.Generic_Instance_Id :=
        Editor.Ada_Generic_Contracts.No_Generic_Instance;
      Instance_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Region     : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Instance_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name         : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target   : Ada.Strings.Unbounded.Unbounded_String;
      Renaming            : Generic_Renaming_Id := No_Generic_Renaming;
      Resolved_Generic    : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Formal_Region       : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Actual_Count        : Natural := 0;
      Formal_Count        : Natural := 0;
      Is_Nested           : Boolean := False;
      Candidate_Count     : Natural := 0;
      Status              : Nested_Generic_Instantiation_Status :=
        Nested_Generic_Instantiation_Unknown;
      Start_Line          : Positive := 1;
      End_Line            : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Generic_Renaming_Visibility_Model is private;

   procedure Clear (Model : in out Generic_Renaming_Visibility_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Contracts  : Editor.Ada_Generic_Contracts.Generic_Contract_Model)
      return Generic_Renaming_Visibility_Model;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Contracts  : Editor.Ada_Generic_Contracts.Generic_Contract_Model)
      return Generic_Renaming_Visibility_Model;

   function Renaming_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural;

   function Renaming_At
     (Model : Generic_Renaming_Visibility_Model;
      Index : Positive) return Generic_Renaming_Info;

   function Renaming_For_Name
     (Model  : Generic_Renaming_Visibility_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Generic_Renaming_Info;

   function Nested_Instantiation_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural;

   function Nested_Instantiation_At
     (Model : Generic_Renaming_Visibility_Model;
      Index : Positive) return Nested_Generic_Instantiation_Info;

   function Renaming_Resolved_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural;
   function Renaming_Error_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural;
   function Nested_Renamed_Instance_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural;
   function Nested_Direct_Instance_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural;
   function Nested_Instance_Error_Count
     (Model : Generic_Renaming_Visibility_Model) return Natural;
   function Fingerprint
     (Model : Generic_Renaming_Visibility_Model) return Natural;

private
   package Renaming_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Renaming_Info);

   package Nested_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Nested_Generic_Instantiation_Info);

   type Generic_Renaming_Visibility_Model is record
      Renamings             : Renaming_Vectors.Vector;
      Nested_Instantiations : Nested_Vectors.Vector;
      Renaming_Resolved_Total : Natural := 0;
      Renaming_Error_Total    : Natural := 0;
      Nested_Renamed_Total    : Natural := 0;
      Nested_Direct_Total     : Natural := 0;
      Nested_Error_Total      : Natural := 0;
      Result_Fingerprint     : Natural := 0;
   end record;

end Editor.Ada_Generic_Renaming_Visibility;
