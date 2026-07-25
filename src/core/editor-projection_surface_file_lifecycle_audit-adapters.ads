package Editor.Projection_Surface_File_Lifecycle_Audit.Adapters is

   function Expected_Canonical_Source_Count
     (Surface : Projection_Surface_Id) return Natural;

   function Expected_Forbidden_Field_Count
     (Surface : Projection_Surface_Id) return Natural;

   function Expected_Forbidden_Route_Count
     (Surface : Projection_Surface_Id) return Natural;

   function Expected_Forbidden_Render_Field_Count
     (Surface : Projection_Surface_Id) return Natural;

   function Canonical_Source_Name
     (Surface : Projection_Surface_Id;
      Index   : Positive) return String;

   function Forbidden_Lifecycle_Field_Name
     (Index : Positive) return String;

   function Forbidden_Lifecycle_Route_Name
     (Index : Positive) return String;

   function Forbidden_Rendered_Field_Name
     (Index : Positive) return String;

   function Adapter_For_Surface
     (Surface : Projection_Surface_Id) return Projection_Surface_Adapter;

   function Adapter_Supports_Shared_Harness
     (Adapter : Projection_Surface_Adapter) return Boolean;

   procedure Validate_Adapter
     (Result  : in out Projection_Surface_Audit_Result;
      Adapter : Projection_Surface_Adapter);

end Editor.Projection_Surface_File_Lifecycle_Audit.Adapters;
