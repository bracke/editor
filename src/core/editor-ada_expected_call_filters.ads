with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;
with Editor.Ada_Call_Profile_Filters;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Call_Resolution;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Expected_Type_Contexts;
with Editor.Ada_Implicit_Conversions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Subtype_Compatibility;
with Editor.Ada_Type_Graph;

package Editor.Ada_Expected_Call_Filters is

   --  Compiler-grade overload-resolution building block.  This model applies
   --  expected-subtype context metadata to profile-filtered call candidates.
   --  It can optionally consult the declaration-derived type graph for exact,
   --  subtype, derived, and known-different-root relationships.  It does not
   --  yet prove private-view completion, class-wide/interface compatibility,
   --  implicit conversion legality, or full profile conformance.

   type Expected_Call_Filter_Status is
     (Expected_Call_Filter_Not_Checked,
      Expected_Call_Filter_No_Expected_Context,
      Expected_Call_Filter_Context_Not_Found,
      Expected_Call_Filter_No_Call_Resolution,
      Expected_Call_Filter_No_Unique_Profile,
      Expected_Call_Filter_No_Profile_Filter,
      Expected_Call_Filter_No_Callable_Profile,
      Expected_Call_Filter_Callable_Has_No_Result,
      Expected_Call_Filter_Result_Subtype_Matches,
      Expected_Call_Filter_Result_Subtype_Compatible,
      Expected_Call_Filter_Result_Subtype_Mismatch,
      Expected_Call_Filter_Result_Subtype_Indeterminate);

   type Expected_Call_Filter_Id is new Natural;
   No_Expected_Call_Filter : constant Expected_Call_Filter_Id := 0;

   type Expected_Call_Filter_Info is record
      Id                  : Expected_Call_Filter_Id := No_Expected_Call_Filter;
      Call_Node           : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Context             : Editor.Ada_Expected_Type_Contexts.Expected_Context_Id :=
        Editor.Ada_Expected_Type_Contexts.No_Expected_Context;
      Resolution          : Editor.Ada_Call_Resolution.Call_Resolution_Id :=
        Editor.Ada_Call_Resolution.No_Call_Resolution;
      Profile_Filter      : Editor.Ada_Call_Profile_Filters.Profile_Filter_Id :=
        Editor.Ada_Call_Profile_Filters.No_Profile_Filter;
      Callable_Profile    : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id :=
        Editor.Ada_Call_Profile_Shapes.No_Callable_Profile;
      Declaration         : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Expected_Subtype    : Ada.Strings.Unbounded.Unbounded_String;
      Result_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Expected : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Result   : Ada.Strings.Unbounded.Unbounded_String;
      Status              : Expected_Call_Filter_Status :=
        Expected_Call_Filter_Not_Checked;
      Compatibility       : Editor.Ada_Subtype_Compatibility.Compatibility_Status :=
        Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Not_Checked;
      Type_Compatibility  : Editor.Ada_Type_Graph.Compatibility_Status :=
        Editor.Ada_Type_Graph.Type_Compatibility_Not_Checked;
      Implicit_Conversion : Editor.Ada_Implicit_Conversions.Implicit_Conversion_Status :=
        Editor.Ada_Implicit_Conversions.Implicit_Conversion_Not_Checked;
      Start_Line          : Positive := 1;
      End_Line            : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Expected_Call_Filter_Model is private;

   procedure Clear (Model : in out Expected_Call_Filter_Model);

   function Build
     (Contexts   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Filters    : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model;
      Shapes     : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model)
      return Expected_Call_Filter_Model;

   function Build_With_Type_Graph
     (Contexts   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Filters    : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model;
      Shapes     : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model)
      return Expected_Call_Filter_Model;

   function Has_Expected_Call_Filters
     (Model : Expected_Call_Filter_Model) return Boolean;

   function Expected_Call_Filter_Count
     (Model : Expected_Call_Filter_Model) return Natural;

   function Expected_Call_Filter_At
     (Model : Expected_Call_Filter_Model;
      Index : Positive) return Expected_Call_Filter_Info;

   function Expected_Call_Filter
     (Model : Expected_Call_Filter_Model;
      Id    : Expected_Call_Filter_Id) return Expected_Call_Filter_Info;

   function Expected_Call_Filter_For_Node
     (Model : Expected_Call_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expected_Call_Filter_Info;

   function Count_Status
     (Model  : Expected_Call_Filter_Model;
      Status : Expected_Call_Filter_Status) return Natural;

   function Fingerprint (Model : Expected_Call_Filter_Model) return Natural;

private
   package Expected_Call_Filter_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Expected_Call_Filter_Info);

   type Expected_Call_Filter_Model is record
      Filters            : Expected_Call_Filter_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Expected_Call_Filters;
