with Ada.Containers.Vectors;
with Editor.Ada_Call_Candidates;
with Editor.Ada_Call_Profile_Filters;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Call_Resolution is

   --  Compiler-grade overload-resolution staging layer.  This package
   --  classifies call-shaped syntax nodes after candidate collection and
   --  profile-shape filtering.  It does not perform expected-type
   --  propagation, type checking, implicit conversion legality, or generic
   --  contract matching; it records deterministic resolution state for later
   --  compiler-grade passes and diagnostics.

   type Call_Resolution_Status is
     (Call_Resolution_Not_Checked,
      Call_Resolution_Missing_Call_Name,
      Call_Resolution_Unresolved_Name,
      Call_Resolution_Ambiguous_Pre_Profile,
      Call_Resolution_No_Actual_Filter,
      Call_Resolution_No_Viable_Profile,
      Call_Resolution_Unique_Profile_Match,
      Call_Resolution_Ambiguous_Profile_Match);

   type Call_Resolution_Id is new Natural;
   No_Call_Resolution : constant Call_Resolution_Id := 0;

   type Call_Resolution_Info is record
      Id                  : Call_Resolution_Id := No_Call_Resolution;
      Call_Node           : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Candidate           : Editor.Ada_Call_Candidates.Call_Candidate_Id :=
        Editor.Ada_Call_Candidates.No_Call_Candidate;
      Declaration         : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Candidate_Count     : Natural := 0;
      Filter_Count        : Natural := 0;
      Viable_Filter_Count : Natural := 0;
      Rejected_Count      : Natural := 0;
      Status              : Call_Resolution_Status :=
        Call_Resolution_Not_Checked;
      Start_Line          : Positive := 1;
      End_Line            : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Call_Resolution_Model is private;

   procedure Clear (Model : in out Call_Resolution_Model);

   function Build
     (Candidates : Editor.Ada_Call_Candidates.Call_Candidate_Model;
      Filters    : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model)
      return Call_Resolution_Model;

   function Has_Call_Resolutions (Model : Call_Resolution_Model) return Boolean;
   function Call_Resolution_Count (Model : Call_Resolution_Model) return Natural;
   function Call_Resolution_At
     (Model : Call_Resolution_Model;
      Index : Positive) return Call_Resolution_Info;
   function Call_Resolution
     (Model : Call_Resolution_Model;
      Id    : Call_Resolution_Id) return Call_Resolution_Info;

   function Resolution_For_Node
     (Model : Call_Resolution_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Call_Resolution_Info;

   function Count_Status
     (Model  : Call_Resolution_Model;
      Status : Call_Resolution_Status) return Natural;

   function Fingerprint (Model : Call_Resolution_Model) return Natural;

private
   package Call_Resolution_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Call_Resolution_Info);

   type Call_Resolution_Model is record
      Resolutions        : Call_Resolution_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Call_Resolution;
