with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Call_Profile_Shapes is

   --  Compiler-grade overload-resolution foundation.  This package extracts
   --  deterministic callable-profile and actual-argument shape metadata from
   --  parser-owned Ada syntax trees.  It deliberately stops before type
   --  checking: later overload-resolution passes can use these records to
   --  reject candidates by arity and named-actual shape before expected-type
   --  and profile-conformance checks are applied.

   type Callable_Profile_Status is
     (Callable_Profile_Not_Callable,
      Callable_Profile_No_Profile,
      Callable_Profile_Found,
      Callable_Profile_Malformed);

   type Actual_Profile_Status is
     (Actual_Profile_Not_Call,
      Actual_Profile_No_Call_Name,
      Actual_Profile_No_Arguments,
      Actual_Profile_Found,
      Actual_Profile_Malformed);

   type Callable_Profile_Id is new Natural;
   No_Callable_Profile : constant Callable_Profile_Id := 0;

   type Actual_Profile_Id is new Natural;
   No_Actual_Profile : constant Actual_Profile_Id := 0;

   type Callable_Profile_Info is record
      Id              : Callable_Profile_Id := No_Callable_Profile;
      Node            : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Region          : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name            : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Parameter_Count         : Natural := 0;
      Defaulted_Parameter_Count : Natural := 0;
      Formal_Names            : Ada.Strings.Unbounded.Unbounded_String;
      Defaulted_Formal_Names  : Ada.Strings.Unbounded.Unbounded_String;
      Has_Result              : Boolean := False;
      Result_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Status          : Callable_Profile_Status := Callable_Profile_Not_Callable;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   type Actual_Profile_Info is record
      Id                 : Actual_Profile_Id := No_Actual_Profile;
      Node               : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Region             : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name               : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Positional_Count   : Natural := 0;
      Named_Count        : Natural := 0;
      Named_Actual_Names : Ada.Strings.Unbounded.Unbounded_String;
      Total_Actual_Count : Natural := 0;
      Status             : Actual_Profile_Status := Actual_Profile_Not_Call;
      Start_Line         : Positive := 1;
      End_Line           : Positive := 1;
      Fingerprint        : Natural := 0;
   end record;

   type Profile_Shape_Model is private;

   procedure Clear (Model : in out Profile_Shape_Model);

   function Build
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model)
      return Profile_Shape_Model;

   function Has_Callable_Profiles (Model : Profile_Shape_Model) return Boolean;
   function Callable_Profile_Count (Model : Profile_Shape_Model) return Natural;
   function Callable_Profile_At
     (Model : Profile_Shape_Model;
      Index : Positive) return Callable_Profile_Info;
   function Callable_Profile
     (Model : Profile_Shape_Model;
      Id    : Callable_Profile_Id) return Callable_Profile_Info;

   function Has_Actual_Profiles (Model : Profile_Shape_Model) return Boolean;
   function Actual_Profile_Count (Model : Profile_Shape_Model) return Natural;
   function Actual_Profile_At
     (Model : Profile_Shape_Model;
      Index : Positive) return Actual_Profile_Info;
   function Actual_Profile
     (Model : Profile_Shape_Model;
      Id    : Actual_Profile_Id) return Actual_Profile_Info;

   function Callable_Profile_For_Node
     (Model : Profile_Shape_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Callable_Profile_Info;

   function Actual_Profile_For_Node
     (Model : Profile_Shape_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Actual_Profile_Info;

   function Fingerprint (Model : Profile_Shape_Model) return Natural;

private
   package Callable_Profile_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Callable_Profile_Info);

   package Actual_Profile_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Actual_Profile_Info);

   type Profile_Shape_Model is record
      Callables          : Callable_Profile_Vectors.Vector;
      Actuals            : Actual_Profile_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Call_Profile_Shapes;
