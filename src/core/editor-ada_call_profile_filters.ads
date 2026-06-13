with Ada.Containers.Vectors;
with Editor.Ada_Call_Candidates;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Call_Profile_Filters is

   --  Compiler-grade overload-resolution building block.  This package
   --  applies deterministic, syntax-owned arity and named-actual shape
   --  filtering to the pre-filter callable candidates.  It deliberately stops
   --  before expected-type propagation, formal-name checking, defaulted-formal
   --  legality, and full profile conformance.

   type Profile_Filter_Status is
     (Profile_Filter_Not_Checked,
      Profile_Filter_Candidate_Unresolved,
      Profile_Filter_No_Actual_Profile,
      Profile_Filter_No_Callable_Profile,
      Profile_Filter_Actual_Profile_Malformed,
      Profile_Filter_Callable_Profile_Malformed,
      Profile_Filter_Too_Many_Actuals,
      Profile_Filter_Named_Actuals_Present,
      Profile_Filter_Unknown_Named_Actual,
      Profile_Filter_Missing_Required_Formal,
      Profile_Filter_Formal_Name_Compatible,
      Profile_Filter_Arity_Compatible);

   type Profile_Filter_Id is new Natural;
   No_Profile_Filter : constant Profile_Filter_Id := 0;

   type Profile_Filter_Info is record
      Id                    : Profile_Filter_Id := No_Profile_Filter;
      Candidate             : Editor.Ada_Call_Candidates.Call_Candidate_Id :=
        Editor.Ada_Call_Candidates.No_Call_Candidate;
      Call_Node             : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Declaration           : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Actual_Profile        : Editor.Ada_Call_Profile_Shapes.Actual_Profile_Id :=
        Editor.Ada_Call_Profile_Shapes.No_Actual_Profile;
      Callable_Profile      : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id :=
        Editor.Ada_Call_Profile_Shapes.No_Callable_Profile;
      Formal_Count          : Natural := 0;
      Positional_Count      : Natural := 0;
      Named_Count           : Natural := 0;
      Total_Actual_Count    : Natural := 0;
      Required_Formal_Count : Natural := 0;
      Matched_Named_Count   : Natural := 0;
      Unknown_Named_Count   : Natural := 0;
      Defaulted_Formal_Count : Natural := 0;
      Status                : Profile_Filter_Status := Profile_Filter_Not_Checked;
      Start_Line            : Positive := 1;
      End_Line              : Positive := 1;
      Fingerprint           : Natural := 0;
   end record;

   type Profile_Filter_Model is private;

   procedure Clear (Model : in out Profile_Filter_Model);

   function Build
     (Candidates : Editor.Ada_Call_Candidates.Call_Candidate_Model;
      Shapes     : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
      return Profile_Filter_Model;

   function Has_Profile_Filters (Model : Profile_Filter_Model) return Boolean;
   function Profile_Filter_Count (Model : Profile_Filter_Model) return Natural;
   function Profile_Filter_At
     (Model : Profile_Filter_Model;
      Index : Positive) return Profile_Filter_Info;
   function Profile_Filter
     (Model : Profile_Filter_Model;
      Id    : Profile_Filter_Id) return Profile_Filter_Info;

   function Filter_Count_For_Node
     (Model : Profile_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Natural;

   function Filter_At_For_Node
     (Model : Profile_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id;
      Index : Positive) return Profile_Filter_Info;

   function Compatible_Count_For_Node
     (Model : Profile_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Natural;

   function Unknown_Named_Count_For_Node
     (Model : Profile_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Natural;

   function Fingerprint (Model : Profile_Filter_Model) return Natural;

private
   package Profile_Filter_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Profile_Filter_Info);

   type Profile_Filter_Model is record
      Filters            : Profile_Filter_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Call_Profile_Filters;
