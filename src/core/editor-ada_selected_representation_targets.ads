with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Cross_Unit_Representation_Targets;
with Editor.Ada_Selected_Name_Resolution;

package Editor.Ada_Selected_Representation_Targets is

   --  Selected-name-aware representation target resolution.  This layer
   --  consumes the cross-unit representation-target projection and the
   --  selected-name resolver output, then records whether representation
   --  clauses whose targets are selected names can be associated with a
   --  resolved local or visible cross-unit selected-name prefix/selector.
   --  It performs no parsing, file IO, editor mutation, command registration,
   --  workspace mutation, or rendering-side work.

   type Selected_Representation_Target_Status is
     (Selected_Representation_Target_Local_Selected_Resolved,
      Selected_Representation_Target_Cross_Unit_Selected_Resolved,
      Selected_Representation_Target_Cross_Unit_Use_Selected_Resolved,
      Selected_Representation_Target_Limited_View,
      Selected_Representation_Target_Private_View,
      Selected_Representation_Target_Prefix_Missing,
      Selected_Representation_Target_Prefix_Ambiguous,
      Selected_Representation_Target_Prefix_Overflow,
      Selected_Representation_Target_Selector_Missing,
      Selected_Representation_Target_Selector_Ambiguous,
      Selected_Representation_Target_Not_Selected,
      Selected_Representation_Target_Unresolved,
      Selected_Representation_Target_Unknown);

   type Selected_Representation_Target_Id is new Natural;
   No_Selected_Representation_Target : constant Selected_Representation_Target_Id := 0;

   type Selected_Representation_Target_Info is record
      Id : Selected_Representation_Target_Id := No_Selected_Representation_Target;
      Representation_Target :
        Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Info;
      Selected_Name :
        Editor.Ada_Selected_Name_Resolution.Selected_Name_Id :=
          Editor.Ada_Selected_Name_Resolution.No_Selected_Name;
      Selected_Status :
        Editor.Ada_Selected_Name_Resolution.Selected_Name_Status :=
          Editor.Ada_Selected_Name_Resolution.Selected_Name_Not_Resolved;
      Target_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Prefix_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Selector_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Target_Unit_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Target_Path       : Ada.Strings.Unbounded.Unbounded_String;
      Candidate_Count   : Natural := 0;
      Status            : Selected_Representation_Target_Status :=
        Selected_Representation_Target_Unknown;
      Fingerprint       : Natural := 0;
   end record;

   type Selected_Representation_Target_Model is private;

   function Build
     (Representation_Targets :
        Editor.Ada_Cross_Unit_Representation_Targets.Cross_Unit_Representation_Target_Model;
      Selected_Names : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model)
      return Selected_Representation_Target_Model;

   function Target_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Target_At
     (Model : Selected_Representation_Target_Model;
      Index : Positive) return Selected_Representation_Target_Info;

   function First_For_Target
     (Model : Selected_Representation_Target_Model;
      Target_Name : String) return Selected_Representation_Target_Info;

   function Count_Status
     (Model  : Selected_Representation_Target_Model;
      Status : Selected_Representation_Target_Status) return Natural;

   function Resolved_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Local_Selected_Resolved_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Cross_Unit_Selected_Resolved_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Limited_View_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Private_View_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Missing_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Ambiguous_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Selector_Error_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Not_Selected_Count
     (Model : Selected_Representation_Target_Model) return Natural;

   function Fingerprint
     (Model : Selected_Representation_Target_Model) return Natural;

private
   package Target_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Selected_Representation_Target_Info);

   type Selected_Representation_Target_Model is record
      Items             : Target_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Selected_Representation_Targets;
