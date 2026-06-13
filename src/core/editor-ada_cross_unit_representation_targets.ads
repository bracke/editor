with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Visibility;
with Editor.Ada_Representation_Legality;

package Editor.Ada_Cross_Unit_Representation_Targets is

   --  Cross-unit representation target resolution layer.  This package
   --  projects local representation-legality target failures through the
   --  already snapshot-owned cross-unit visibility model.  It records whether
   --  a representation target that was not resolved locally can be associated
   --  with a visible library-unit prefix, without reparsing target files or
   --  mutating editor state.

   type Cross_Unit_Representation_Target_Status is
     (Cross_Unit_Representation_Target_Local_Resolved,
      Cross_Unit_Representation_Target_Prefix_Resolved,
      Cross_Unit_Representation_Target_Prefix_Limited_View,
      Cross_Unit_Representation_Target_Prefix_Private_View,
      Cross_Unit_Representation_Target_Prefix_Missing,
      Cross_Unit_Representation_Target_Prefix_Ambiguous,
      Cross_Unit_Representation_Target_Prefix_Overflow,
      Cross_Unit_Representation_Target_No_Cross_Unit_Prefix,
      Cross_Unit_Representation_Target_Unknown);

   type Cross_Unit_Representation_Target_Info is record
      Clause_Node       : Editor.Ada_Representation_Legality.Representation_Legality_Info;
      Source_Unit_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target : Ada.Strings.Unbounded.Unbounded_String;
      Prefix_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Selector_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Path       : Ada.Strings.Unbounded.Unbounded_String;
      Visibility_Status : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Status :=
        Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Not_Found;
      Candidate_Count   : Natural := 0;
      Status            : Cross_Unit_Representation_Target_Status :=
        Cross_Unit_Representation_Target_Unknown;
      Fingerprint       : Natural := 0;
   end record;

   package Target_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Cross_Unit_Representation_Target_Info);

   type Cross_Unit_Representation_Target_Model is private;

   function Build
     (Source_Unit_Name : String;
      Legality         : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Visibility       : Editor.Ada_Cross_Unit_Visibility.Cross_Unit_Visibility_Model)
      return Cross_Unit_Representation_Target_Model;

   function Target_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

   function Target_At
     (Model : Cross_Unit_Representation_Target_Model;
      Index : Positive) return Cross_Unit_Representation_Target_Info;

   function Prefix_Resolved_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

   function Local_Resolved_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

   function Missing_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

   function Ambiguous_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

   function Limited_View_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

   function Private_View_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

   function No_Cross_Unit_Prefix_Count
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

   function Fingerprint
     (Model : Cross_Unit_Representation_Target_Model) return Natural;

private
   type Cross_Unit_Representation_Target_Model is record
      Items             : Target_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Cross_Unit_Representation_Targets;
