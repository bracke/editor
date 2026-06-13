with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Project_Index;

package Editor.Ada_Cross_Unit_Closure is

   type Cross_Unit_Link_Kind is
     (Cross_Unit_Spec_To_Body,
      Cross_Unit_Body_To_Spec,
      Cross_Unit_Child_To_Parent,
      Cross_Unit_Parent_To_Child,
      Cross_Unit_Separate_To_Parent,
      Cross_Unit_With_Dependency,
      Cross_Unit_Limited_With_Dependency,
      Cross_Unit_Private_With_Dependency,
      Cross_Unit_Use_Dependency);

   type Cross_Unit_Link_Status is
     (Cross_Unit_Link_Resolved,
      Cross_Unit_Link_Missing,
      Cross_Unit_Link_Ambiguous,
      Cross_Unit_Link_Overflow,
      Cross_Unit_Link_Not_Applicable);

   type Cross_Unit_Link_Info is record
      Kind              : Cross_Unit_Link_Kind := Cross_Unit_Spec_To_Body;
      Status            : Cross_Unit_Link_Status := Cross_Unit_Link_Not_Applicable;
      Source_Unit_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Source_Role       : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Source_Path       : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Role       : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Target_Path       : Ada.Strings.Unbounded.Unbounded_String;
      Clause_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Is_Limited_With   : Boolean := False;
      Is_Private_With   : Boolean := False;
      Candidate_Count   : Natural := 0;
      Fingerprint       : Natural := 0;
   end record;

   package Cross_Unit_Link_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_Link_Info);

   type Spec_Body_Consistency_Status is
     (Spec_Body_Consistency_Confirmed,
      Spec_Body_Consistency_Missing_Counterpart,
      Spec_Body_Consistency_Ambiguous_Counterpart,
      Spec_Body_Consistency_Overflow,
      Spec_Body_Consistency_Role_Mismatch,
      Spec_Body_Consistency_Name_Mismatch,
      Spec_Body_Consistency_Not_Applicable);

   type Spec_Body_Consistency_Info is record
      Status           : Spec_Body_Consistency_Status :=
        Spec_Body_Consistency_Not_Applicable;
      Spec_Unit_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Path        : Ada.Strings.Unbounded.Unbounded_String;
      Spec_Role        : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Body_Unit_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Body_Path        : Ada.Strings.Unbounded.Unbounded_String;
      Body_Role        : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Candidate_Count  : Natural := 0;
      Fingerprint      : Natural := 0;
   end record;

   package Spec_Body_Consistency_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Spec_Body_Consistency_Info);



   type Child_Unit_Legality_Status is
     (Child_Unit_Legality_Public_Child_Resolved,
      Child_Unit_Legality_Private_Child_Resolved,
      Child_Unit_Legality_Missing_Parent,
      Child_Unit_Legality_Ambiguous_Parent,
      Child_Unit_Legality_Overflow,
      Child_Unit_Legality_Parent_Role_Mismatch,
      Child_Unit_Legality_Not_Applicable);

   type Child_Unit_Legality_Info is record
      Status           : Child_Unit_Legality_Status :=
        Child_Unit_Legality_Not_Applicable;
      Child_Unit_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Child_Path       : Ada.Strings.Unbounded.Unbounded_String;
      Child_Role       : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Parent_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Path      : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Role      : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Is_Private_Child : Boolean := False;
      Candidate_Count  : Natural := 0;
      Fingerprint      : Natural := 0;
   end record;

   package Child_Unit_Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Child_Unit_Legality_Info);



   type Separate_Body_Legality_Status is
     (Separate_Body_Legality_Parent_Resolved,
      Separate_Body_Legality_Missing_Parent,
      Separate_Body_Legality_Ambiguous_Parent,
      Separate_Body_Legality_Overflow,
      Separate_Body_Legality_Parent_Role_Mismatch,
      Separate_Body_Legality_Target_Name_Missing,
      Separate_Body_Legality_Not_Applicable);

   type Separate_Body_Legality_Info is record
      Status             : Separate_Body_Legality_Status :=
        Separate_Body_Legality_Not_Applicable;
      Separate_Unit_Name : Ada.Strings.Unbounded.Unbounded_String;
      Separate_Path      : Ada.Strings.Unbounded.Unbounded_String;
      Separate_Role      : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Parent_Unit_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Path        : Ada.Strings.Unbounded.Unbounded_String;
      Parent_Role        : Editor.Ada_Project_Index.Indexed_Unit_Role :=
        Editor.Ada_Project_Index.Unit_Any;
      Parent_Name_Text   : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Count    : Natural := 0;
      Fingerprint        : Natural := 0;
   end record;

   package Separate_Body_Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Separate_Body_Legality_Info);

   type Cross_Unit_Closure_Model is private;

   function Build
     (Index : Editor.Ada_Project_Index.Index_State)
      return Cross_Unit_Closure_Model;

   function Link_Count (Model : Cross_Unit_Closure_Model) return Natural;

   function Link_At
     (Model : Cross_Unit_Closure_Model;
      Index : Positive) return Cross_Unit_Link_Info;

   function Resolved_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Missing_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Ambiguous_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Overflow_Count (Model : Cross_Unit_Closure_Model) return Natural;

   function Spec_Body_Link_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Child_Parent_Link_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Parent_Child_Link_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Separate_Parent_Link_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function With_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Limited_With_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Private_With_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Use_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural;
   function Context_Dependency_Count (Model : Cross_Unit_Closure_Model) return Natural;

   function Spec_Body_Consistency_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Spec_Body_Consistency_At
     (Model : Cross_Unit_Closure_Model;
      Index : Positive) return Spec_Body_Consistency_Info;

   function Spec_Body_Consistent_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Spec_Body_Inconsistent_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Spec_Body_Missing_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Spec_Body_Ambiguous_Count
     (Model : Cross_Unit_Closure_Model) return Natural;


   function Child_Unit_Legality_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Child_Unit_Legality_At
     (Model : Cross_Unit_Closure_Model;
      Index : Positive) return Child_Unit_Legality_Info;

   function Child_Unit_Resolved_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Private_Child_Unit_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Child_Unit_Parent_Error_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Child_Unit_Missing_Parent_Count
     (Model : Cross_Unit_Closure_Model) return Natural;



   function Separate_Body_Legality_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Separate_Body_Legality_At
     (Model : Cross_Unit_Closure_Model;
      Index : Positive) return Separate_Body_Legality_Info;

   function Separate_Body_Resolved_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Separate_Body_Parent_Error_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Separate_Body_Missing_Parent_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Separate_Body_Ambiguous_Parent_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Separate_Body_Target_Name_Missing_Count
     (Model : Cross_Unit_Closure_Model) return Natural;

   function Fingerprint (Model : Cross_Unit_Closure_Model) return Natural;

private
   type Cross_Unit_Closure_Model is record
      Links : Cross_Unit_Link_Vectors.Vector;
      Spec_Body_Consistency : Spec_Body_Consistency_Vectors.Vector;
      Child_Unit_Legality : Child_Unit_Legality_Vectors.Vector;
      Separate_Body_Legality : Separate_Body_Legality_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Cross_Unit_Closure;
