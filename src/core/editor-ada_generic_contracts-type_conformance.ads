with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Type_Graph;

package Editor.Ada_Generic_Contracts.Type_Conformance is

   type Profile_Type_Conformance_Status is
     (Profile_Type_Conformance_Not_Checked,
      Profile_Type_Conformance_Compatible,
      Profile_Type_Conformance_Mismatch,
      Profile_Type_Conformance_Unknown);

   function Type_Id_For_Profile_Subtype
     (Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Editor.Ada_Type_Graph.Type_Id;

   function Type_Graph_Profile_Subtypes_Conform
     (Types             : Editor.Ada_Type_Graph.Type_Model;
      Formal_Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtypes : String;
      Actual_Subtypes   : String)
      return Editor.Ada_Generic_Contracts.Type_Conformance.Profile_Type_Conformance_Status;

   function Type_Graph_Result_Subtype_Conforms
     (Types             : Editor.Ada_Type_Graph.Type_Model;
      Formal_Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Actual_Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expected_Subtype : String;
      Actual_Subtype   : String)
      return Editor.Ada_Generic_Contracts.Type_Conformance.Profile_Type_Conformance_Status;

end Editor.Ada_Generic_Contracts.Type_Conformance;
