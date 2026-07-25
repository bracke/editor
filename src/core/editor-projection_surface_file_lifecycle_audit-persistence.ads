package Editor.Projection_Surface_File_Lifecycle_Audit.Persistence is

   function Cross_Surface_Import_Name
     (Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id) return String;

   function Cross_Surface_Import_Forbidden
     (Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id) return Boolean;

   function Operation_Name
     (Operation : File_Lifecycle_Operation) return String;

   function Observation_Expectation
     (Operation : File_Lifecycle_Operation)
      return Projection_Surface_Observation_Expectation;

   function Observation_Expectation_Coherent
     (Expectation : Projection_Surface_Observation_Expectation) return Boolean;

   function Surface_Operation_Observation_Coherent
     (Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation) return Boolean;

   function Lifecycle_Event_Name
     (Event : Projection_Surface_Lifecycle_Event) return String;

   function Lifecycle_Event_Expectation
     (Event : Projection_Surface_Lifecycle_Event)
      return Projection_Surface_Lifecycle_Event_Expectation;

   function Lifecycle_Event_Expectation_Coherent
     (Expectation : Projection_Surface_Lifecycle_Event_Expectation) return Boolean;

   function Surface_Lifecycle_Event_Coherent
     (Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event) return Boolean;

   function Workflow_Context_Name
     (Context : Projection_Surface_Workflow_Context) return String;

   function Reliability_Family_Name
     (Family : Projection_Surface_Reliability_Family) return String;

   function Reliability_Expectation
     (Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context)
      return Projection_Surface_Reliability_Expectation;

   function Reliability_Expectation_Coherent
     (Expectation : Projection_Surface_Reliability_Expectation) return Boolean;

   function Surface_Reliability_Coherent
     (Surface   : Projection_Surface_Id;
      Family    : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context   : Projection_Surface_Workflow_Context) return Boolean;

   function Final_Freeze_Expectation
     (Surface : Projection_Surface_Id)
      return Projection_Surface_Final_Freeze_Expectation;

   function Final_Freeze_Expectation_Coherent
     (Expectation : Projection_Surface_Final_Freeze_Expectation) return Boolean;

   function Surface_Final_Freeze_Coherent
     (Surface : Projection_Surface_Id) return Boolean;

   procedure Validate_Surface_Operation
     (Result   : in out Projection_Surface_Audit_Result;
      Surface  : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation);

   procedure Validate_Surface_Lifecycle_Event
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event);

   procedure Validate_Cross_Surface_Import
     (Result   : in out Projection_Surface_Audit_Result;
      Producer : Projection_Surface_Id;
      Consumer : Projection_Surface_Id);

   procedure Validate_Surface_Reliability
     (Result   : in out Projection_Surface_Audit_Result;
      Surface  : Projection_Surface_Id;
      Family   : Projection_Surface_Reliability_Family;
      Operation : File_Lifecycle_Operation;
      Context  : Projection_Surface_Workflow_Context);

   procedure Validate_Surface_Final_Freeze
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id);

   procedure Validate_All_Covered_Surfaces
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_Shared_Invariant_Coverage_Not_Reduced
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_Surface_Lifecycle_Operation_Semantics
     (Result    : in out Projection_Surface_Audit_Result;
      Surface   : Projection_Surface_Id;
      Operation : File_Lifecycle_Operation);

   procedure Assert_Surface_Lifecycle_Event_Semantics
     (Result  : in out Projection_Surface_Audit_Result;
      Surface : Projection_Surface_Id;
      Event   : Projection_Surface_Lifecycle_Event);

   procedure Assert_File_Lifecycle_Projection_Surface_Milestone_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_File_Lifecycle_Projection_Surface_Reliability_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_File_Lifecycle_Projection_Surface_Cleanup_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_File_Lifecycle_Projection_Surface_Final_Freeze_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   procedure Assert_Projection_Surface_Invariant_Adoption_Gate_Coherent
     (Result : in out Projection_Surface_Audit_Result);

   function Projection_Surface_Invariant_Adoption_Gate_Coherent
     return Boolean;

   function File_Lifecycle_Projection_Surface_Milestone_Coherent
     return Boolean;

   function File_Lifecycle_Projection_Surface_Reliability_Coherent
     return Boolean;

   function File_Lifecycle_Projection_Surface_Cleanup_Coherent
     return Boolean;

   function File_Lifecycle_Projection_Surface_Final_Freeze_Coherent
     return Boolean;

end Editor.Projection_Surface_File_Lifecycle_Audit.Persistence;
