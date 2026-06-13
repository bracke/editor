with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Type_Graph;

package Editor.Ada_Generic_Contracts is

   --  Compiler-grade generic-contract foundation.  This package records the
   --  formal declarations that make up a generic contract and the shallow
   --  actual shape of generic instantiations.  It is deterministic and
   --  snapshot-owned; later passes layer formal/actual type conformance,
   --  overload matching, default legality, and body contract-model visibility
   --  on top of these records.

   type Generic_Formal_Kind is
     (Generic_Formal_Type,
      Generic_Formal_Object,
      Generic_Formal_Subprogram,
      Generic_Formal_Package,
      Generic_Formal_Unknown);

   type Generic_Actual_Kind is
     (Generic_Actual_Type,
      Generic_Actual_Object,
      Generic_Actual_Subprogram,
      Generic_Actual_Package,
      Generic_Actual_Unknown,
      Generic_Actual_Malformed);

   type Generic_Formal_Status is
     (Generic_Formal_Record_Valid,
      Generic_Formal_Missing_Name,
      Generic_Formal_Unsupported);

   type Generic_Formal_Id is new Natural;
   No_Generic_Formal : constant Generic_Formal_Id := 0;

   type Generic_Formal_Info is record
      Id              : Generic_Formal_Id := No_Generic_Formal;
      Declaration     : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region          : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name            : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Kind            : Generic_Formal_Kind := Generic_Formal_Unknown;
      Has_Default     : Boolean := False;
      Default_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Parameter_Count : Natural := 0;
      Formal_Parameter_Subtypes : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Parameter_Modes : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Parameter_Names : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Parameter_Defaults : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Subprogram_Convention : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Has_Result      : Boolean := False;
      Formal_Result_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Package_Generic_Name : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Package_Normalized_Generic : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Package_Has_Box : Boolean := False;
      Status          : Generic_Formal_Status := Generic_Formal_Unsupported;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   type Generic_Instance_Status is
     (Generic_Instance_Record_Valid,
      Generic_Instance_Missing_Name,
      Generic_Instance_Malformed_Actuals,
      Generic_Instance_Unsupported);

   type Generic_Instance_Id is new Natural;
   No_Generic_Instance : constant Generic_Instance_Id := 0;

   type Generic_Instance_Info is record
      Id                  : Generic_Instance_Id := No_Generic_Instance;
      Declaration         : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region              : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name                : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Generic_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Generic  : Ada.Strings.Unbounded.Unbounded_String;
      Positional_Actuals  : Natural := 0;
      Named_Actuals       : Natural := 0;
      Total_Actuals       : Natural := 0;
      Named_Actual_Names  : Ada.Strings.Unbounded.Unbounded_String;
      Positional_Actual_Kinds : Ada.Strings.Unbounded.Unbounded_String;
      Named_Actual_Kinds  : Ada.Strings.Unbounded.Unbounded_String;
      Positional_Actual_Texts : Ada.Strings.Unbounded.Unbounded_String;
      Named_Actual_Texts  : Ada.Strings.Unbounded.Unbounded_String;
      Status              : Generic_Instance_Status := Generic_Instance_Unsupported;
      Start_Line          : Positive := 1;
      End_Line            : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Generic_Actual_Match_Status is
     (Generic_Actual_Match_Valid,
      Generic_Actual_Match_Instance_Malformed,
      Generic_Actual_Match_Generic_Not_Found,
      Generic_Actual_Match_Generic_Ambiguous,
      Generic_Actual_Match_Target_Not_Generic,
      Generic_Actual_Match_No_Formal_Region,
      Generic_Actual_Match_Too_Many_Positionals,
      Generic_Actual_Match_Unknown_Named_Actual,
      Generic_Actual_Match_Duplicate_Named_Actual,
      Generic_Actual_Match_Missing_Required_Formal,
      Generic_Actual_Match_Formal_Kind_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Profile_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Mode_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Null_Exclusion_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Access_Profile_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Convention_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Default_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Name_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Result_Mismatch,
      Generic_Actual_Match_Formal_Subprogram_Profile_Ambiguous,
      Generic_Actual_Match_Formal_Package_Contract_Mismatch,
      Generic_Actual_Match_Formal_Package_Contract_Unknown,
      Generic_Actual_Match_Formal_Object_Default_Illegal,
      Generic_Actual_Match_Formal_Object_Default_Unknown);

   type Generic_Formal_Actual_Kind_Match is
     (Generic_Formal_Actual_Kind_Matches,
      Generic_Formal_Actual_Kind_Mismatch,
      Generic_Formal_Actual_Kind_Unknown,
      Generic_Formal_Actual_Kind_Missing);

   type Generic_Actual_Match_Id is new Natural;
   No_Generic_Actual_Match : constant Generic_Actual_Match_Id := 0;

   type Generic_Actual_Match_Info is record
      Id                       : Generic_Actual_Match_Id := No_Generic_Actual_Match;
      Instance                 : Generic_Instance_Id := No_Generic_Instance;
      Instance_Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Instance_Region          : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Generic_Declaration      : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Generic_Formal_Region    : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Formal_Count             : Natural := 0;
      Required_Formals         : Natural := 0;
      Positional_Actuals       : Natural := 0;
      Named_Actuals            : Natural := 0;
      Matched_Formals          : Natural := 0;
      Defaulted_Formals        : Natural := 0;
      Unknown_Named_Actuals    : Natural := 0;
      Duplicate_Named_Actuals  : Natural := 0;
      Missing_Required_Formals : Natural := 0;
      Kind_Compatible_Formals  : Natural := 0;
      Kind_Mismatched_Formals  : Natural := 0;
      Kind_Unknown_Formals     : Natural := 0;
      Subprogram_Profile_Compatible_Formals : Natural := 0;
      Subprogram_Profile_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Unknown_Formals : Natural := 0;
      Subprogram_Profile_Mode_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Null_Exclusion_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Access_Profile_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Convention_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Default_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Class_Wide_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Name_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Result_Compatible_Formals : Natural := 0;
      Subprogram_Profile_Result_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Result_Unknown_Formals : Natural := 0;
      Subprogram_Profile_Type_Compatible_Formals : Natural := 0;
      Subprogram_Profile_Type_Mismatched_Formals : Natural := 0;
      Subprogram_Profile_Type_Unknown_Formals : Natural := 0;
      Subprogram_Profile_Overload_Candidates : Natural := 0;
      Subprogram_Profile_Overload_Selected_Formals : Natural := 0;
      Subprogram_Profile_Overload_Ambiguous_Formals : Natural := 0;
      Subprogram_Profile_Overload_Unresolved_Formals : Natural := 0;
      Formal_Package_Compatible_Formals : Natural := 0;
      Formal_Package_Mismatched_Formals : Natural := 0;
      Formal_Package_Unknown_Formals : Natural := 0;
      Formal_Package_Unresolved_Formals : Natural := 0;
      Formal_Package_Ambiguous_Formals : Natural := 0;
      Formal_Package_Not_Instance_Formals : Natural := 0;
      Formal_Package_Wrong_Generic_Formals : Natural := 0;
      Formal_Package_Contract_Unknown_Formals : Natural := 0;
      Formal_Package_Malformed_Formals : Natural := 0;
      Default_Expression_Checked_Formals : Natural := 0;
      Default_Expression_Static_Formals : Natural := 0;
      Default_Expression_Illegal_Formals : Natural := 0;
      Default_Expression_Unknown_Formals : Natural := 0;
      Default_Expression_Unresolved_Formals : Natural := 0;
      Default_Expression_Nonstatic_Formals : Natural := 0;
      Default_Expression_Malformed_Formals : Natural := 0;
      Default_Expression_Division_By_Zero_Formals : Natural := 0;
      Status                   : Generic_Actual_Match_Status :=
        Generic_Actual_Match_Generic_Not_Found;
      Start_Line               : Positive := 1;
      End_Line                 : Positive := 1;
      Fingerprint              : Natural := 0;
   end record;


   type Generic_Body_Contract_Visibility_Status is
     (Generic_Body_Contract_Visible,
      Generic_Body_Contract_Body_Not_Found,
      Generic_Body_Contract_No_Formal_Region,
      Generic_Body_Contract_Unsupported);

   type Generic_Body_Contract_Visibility_Id is new Natural;
   No_Generic_Body_Contract_Visibility : constant Generic_Body_Contract_Visibility_Id := 0;

   type Generic_Body_Contract_Visibility_Info is record
      Id                 : Generic_Body_Contract_Visibility_Id :=
        No_Generic_Body_Contract_Visibility;
      Generic_Declaration : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Generic_Node       : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Generic_Formal_Region : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Body_Declaration   : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Body_Node          : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Body_Region        : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name               : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Count       : Natural := 0;
      Visible_Formals    : Natural := 0;
      Shadowed_Formals   : Natural := 0;
      Shadowed_Formal_Names : Ada.Strings.Unbounded.Unbounded_String;
      Status             : Generic_Body_Contract_Visibility_Status :=
        Generic_Body_Contract_Unsupported;
      Start_Line         : Positive := 1;
      End_Line           : Positive := 1;
      Fingerprint        : Natural := 0;
   end record;

   type Generic_Contract_Model is private;

   procedure Clear (Model : in out Generic_Contract_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model)
      return Generic_Contract_Model;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model)
      return Generic_Contract_Model;

   function Build_With_Static
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model)
      return Generic_Contract_Model;

   function Build_With_Type_Graph
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model)
      return Generic_Contract_Model;

   function Build_With_Static_And_Type_Graph
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model)
      return Generic_Contract_Model;

   function Has_Formals (Model : Generic_Contract_Model) return Boolean;
   function Formal_Count (Model : Generic_Contract_Model) return Natural;
   function Formal_At
     (Model : Generic_Contract_Model;
      Index : Positive) return Generic_Formal_Info;
   function Formal
     (Model : Generic_Contract_Model;
      Id    : Generic_Formal_Id) return Generic_Formal_Info;

   function Formal_Count_In_Region
     (Model  : Generic_Contract_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id) return Natural;

   function Defaulted_Formal_Count_In_Region
     (Model  : Generic_Contract_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id) return Natural;

   function Has_Instances (Model : Generic_Contract_Model) return Boolean;
   function Instance_Count (Model : Generic_Contract_Model) return Natural;
   function Instance_At
     (Model : Generic_Contract_Model;
      Index : Positive) return Generic_Instance_Info;
   function Instance
     (Model : Generic_Contract_Model;
      Id    : Generic_Instance_Id) return Generic_Instance_Info;

   function Actual_Match_Count (Model : Generic_Contract_Model) return Natural;
   function Actual_Match_At
     (Model : Generic_Contract_Model;
      Index : Positive) return Generic_Actual_Match_Info;
   function Actual_Match_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Generic_Actual_Match_Info;

   function Kind_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Mode_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Null_Exclusion_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Access_Profile_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Convention_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Default_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Class_Wide_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Name_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Result_Compatible_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Result_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Result_Unknown_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Type_Compatible_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Type_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Type_Unknown_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Overload_Selected_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Overload_Ambiguous_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Subprogram_Profile_Overload_Unresolved_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Formal_Package_Compatible_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Formal_Package_Mismatch_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Formal_Package_Unknown_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Default_Expression_Static_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Default_Expression_Illegal_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;

   function Default_Expression_Unknown_Count_For_Instance
     (Model    : Generic_Contract_Model;
      Instance : Generic_Instance_Id) return Natural;


   function Body_Contract_Visibility_Count
     (Model : Generic_Contract_Model) return Natural;
   function Body_Contract_Visibility_At
     (Model : Generic_Contract_Model;
      Index : Positive) return Generic_Body_Contract_Visibility_Info;
   function Body_Contract_Visibility_For_Body
     (Model       : Generic_Contract_Model;
      Body_Region : Editor.Ada_Declarative_Regions.Region_Id)
      return Generic_Body_Contract_Visibility_Info;

   function Body_Formal_Visible
     (Model       : Generic_Contract_Model;
      Body_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name        : String) return Boolean;

   function Body_Formal
     (Model       : Generic_Contract_Model;
      Body_Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name        : String) return Generic_Formal_Info;

   function Fingerprint (Model : Generic_Contract_Model) return Natural;

private
   package Formal_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Formal_Info);

   package Instance_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Instance_Info);

   package Actual_Match_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Actual_Match_Info);

   package Body_Contract_Visibility_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Generic_Body_Contract_Visibility_Info);

   type Generic_Contract_Model is record
      Formals            : Formal_Vectors.Vector;
      Instances          : Instance_Vectors.Vector;
      Actual_Matches     : Actual_Match_Vectors.Vector;
      Body_Contract_Visibility : Body_Contract_Visibility_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Generic_Contracts;
