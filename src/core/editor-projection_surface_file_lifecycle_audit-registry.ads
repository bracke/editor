package Editor.Projection_Surface_File_Lifecycle_Audit.Registry is

   function Classification_Name
     (Classification : Projection_Surface_Classification) return String;

   function Surface_Classification
     (Surface : Projection_Surface_Id) return Projection_Surface_Classification;

   function Registration_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Registration;

   function Surface_Is_Registered
     (Surface : Projection_Surface_Id) return Boolean;

   function Projection_Surface_Registration_Coherent
     (Registration : Projection_Surface_Registration) return Boolean;

   function Projection_Surface_Inspection_Lifecycle_Sensitive
     (Inspection : Projection_Surface_Inspection) return Boolean;

   function Projection_Surface_Inspection_Coherent
     (Inspection : Projection_Surface_Inspection) return Boolean;

   function Build_Future_Surface_Projection_Surface_Adapter
     (Surface        : Projection_Surface_Id;
      Classification : Projection_Surface_Classification)
      return Projection_Surface_Adapter;

   procedure Validate_Projection_Surface_Registration
     (Result       : in out Projection_Surface_Audit_Result;
      Registration : Projection_Surface_Registration);

   procedure Validate_Projection_Surface_Inspection
     (Result     : in out Projection_Surface_Audit_Result;
      Inspection : Projection_Surface_Inspection);

end Editor.Projection_Surface_File_Lifecycle_Audit.Registry;
